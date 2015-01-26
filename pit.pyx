
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"

import time


DEF READBACK_DONT_LATCH_COUNT  = 0x20
DEF READBACK_DONT_LATCH_STATUS = 0x10

cdef class PitChannel:
    def __init__(self, object main, Pit pit, unsigned char channelId):
        self.main = main
        self.pit = pit
        self.channelId = channelId
        self.bcdMode = 0 # 0 == binary; 1 == BCD
        self.counterMode = 0 # 0-5 valid, 6,7 not
        self.counterWriteMode = 0 # 1 == LSB ; 2 == MSB ; 3 == LSB;MSB
        self.readBackStatusValue = 0
        self.counterValue = self.counterStartValue = self.counterLatchValue = 0
        self.counterFlipFlop = self.timerEnabled = self.readBackStatusIssued = False
        self.tempTimerValue = 0.0
    cpdef readBackCount(self):
        self.counterLatchValue = self.counterValue
    cpdef readBackStatus(self):
        self.readBackStatusValue = self.bcdMode
        self.readBackStatusValue |= self.counterMode<<1
        self.readBackStatusValue |= self.counterWriteMode<<4
    cpdef mode0Func(self):
        self.timerEnabled = False
        usleep(int(self.tempTimerValue))
        self.counterValue = 0
        if (self.channelId == 0): # just raise IRQ on channel0
            (<Pic>self.main.platform.pic).raiseIrq(0)
        elif (self.channelId == 2 and (<PS2>self.main.platform.ps2).ppcbT2Gate):
            (<PS2>self.main.platform.ps2).ppcbT2Out = True
        else:
            self.main.notice("mode0Func: counterMode {0:d} used channelId {1:d}.", self.counterMode, self.channelId)
    cpdef mode2Func(self): # TODO
        while (self.timerEnabled and self.counterValue and self.counterMode in (2, 3) and (not self.main.quitEmu)):
            #IF 1:
            #if (not self.counterValue or self.counterMode not in (2, 3)):
            #    self.main.notice("mode2Func: channelId {0:d}: counterValue{1:d} == 0 or counterMode{2:d} not in (2, 3) .", self.channelId, self.counterValue, self.counterMode)
            #    return
            ##self.counterValue = 0
            ##if (not self.counterValue):
            if (self.channelId == 0):
                (<Pic>self.main.platform.pic).lowerIrq(0)
            elif (self.channelId == 2 and (<PS2>self.main.platform.ps2).ppcbT2Gate):
                (<PS2>self.main.platform.ps2).ppcbT2Out = False
            #self.tempTimerValue *= 1000000
            #with nogil:
            #    usleep(int(self.tempTimerValue))
            time.sleep(self.tempTimerValue/5e3) # TODO: FIXME: HACK
            self.counterValue = 1
            if (self.channelId == 0): # just raise IRQ on channel0
                #self.main.notice("mode2Func: raiseIrq(0)")
                (<Pic>self.main.platform.pic).raiseIrq(0)
            elif (self.channelId == 2 and (<PS2>self.main.platform.ps2).ppcbT2Gate):
                (<PS2>self.main.platform.ps2).ppcbT2Out = True
            else:
                self.main.notice("mode2Func: counterMode {0:d} used channelId {1:d}.", self.counterMode, self.channelId)
            self.counterValue = self.counterStartValue
            #if (self.timerEnabled and self.counterValue and self.counterMode in (2, 3) and (not self.main.quitEmu)):
            #    self.main.misc.createThread(self.mode2Func, True)
            ##self.timerEnabled = True
    cpdef timerFunc(self): # TODO
        if (self.timerEnabled):
            if (self.counterMode == 0):
                self.mode0Func()
            elif (self.counterMode in (2, 3)):
                self.mode2Func()
            else:
                self.main.exitError("timerFunc: counterMode {0:d} is unknown.", self.counterMode)
                return
    cpdef runTimer(self):
        if (self.channelId == 1):
            self.main.exitError("PitChannel::runTimer: PIT-Channel 1 is ancient.")
            return
        if (self.counterStartValue == 0):
            if (self.bcdMode):
                self.counterStartValue = 10000
            else:
                self.counterStartValue = 0x10000
        elif (self.bcdMode):
            self.counterStartValue = self.main.misc.bcdToDec(self.counterStartValue)
        if (self.counterMode == 3):
            self.counterStartValue &= 0xffffe
            if (self.counterStartValue == 0):
                self.main.exitError("runTimer: counterValue is 0")
                return
        self.counterValue = self.counterStartValue
        self.tempTimerValue = 1.0/(1.193182/self.counterValue)
        if (self.counterMode not in (0, 2, 3)):
            self.main.exitError("runTimer: counterMode {0:d} not supported yet. (channelId: {1:d})", self.counterMode, self.channelId)
            return
        elif (self.counterMode == 2 and self.channelId == 2):
            self.main.exitError("runTimer: is it ok to use mode-{0:d} with channelId-{1:d} and cpu clock measures?", \
              self.counterMode, self.channelId)
            return
        if (self.channelId == 0):
            (<Pic>self.main.platform.pic).lowerIrq(0)
        elif (self.channelId == 2 and (<PS2>self.main.platform.ps2).ppcbT2Gate):
            (<PS2>self.main.platform.ps2).ppcbT2Out = False
        self.timerEnabled = True
        if (self.timerEnabled and not self.main.quitEmu):
            self.main.misc.createThread(self.timerFunc, True)

cdef class Pit:
    def __init__(self, object main):
        self.main = main
        self.channels = (PitChannel(self.main, self, 0), PitChannel(self.main, self, 1),\
                         PitChannel(self.main, self, 2)) # channel 0-2
    cpdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef PitChannel channel
        cdef unsigned char channelId, retVal
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channelId = ioPortAddr&3
                channel = self.channels[channelId]
                if (channel.readBackStatusIssued):
                    channel.readBackStatusIssued = False
                    retVal = channel.readBackStatusValue
                elif (channel.counterWriteMode == 1): # LSB
                    retVal = <unsigned char>channel.counterValue
                elif (channel.counterWriteMode == 2): # MSB
                    retVal = <unsigned char>(channel.counterValue>>8)
                elif (channel.counterWriteMode in (0, 3)): # LSB;MSB
                    if (not channel.counterFlipFlop):
                        if (channel.counterWriteMode == 0): # TODO?
                            channel.counterLatchValue = channel.counterValue
                        retVal = <unsigned char>channel.counterValue
                    else:
                        if (channel.counterWriteMode == 0):
                            retVal = <unsigned char>(channel.counterLatchValue>>8)
                        else:
                            retVal = <unsigned char>(channel.counterValue>>8)
                    channel.counterFlipFlop = not channel.counterFlipFlop
                else:
                    self.main.exitError("inPort: unknown counterWriteMode: {0:d}.", channel.counterWriteMode)
                return retVal
            elif (ioPortAddr == 0x43):
                self.main.notice("inPort: read from PIT command port 0x43 is ignored.")
                return 0
            else:
                self.main.exitError("inPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
        else:
            self.main.exitError("inPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        return 0
    cpdef outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef PitChannel channel
        cdef unsigned char channelId, bcd, modeNumber, counterWriteMode, i
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channelId = ioPortAddr&3
                channel = self.channels[channelId]
                if (channel.counterWriteMode in (0, 3)): # LSB;MSB
                    if (not channel.counterFlipFlop):
                        channel.counterStartValue = <unsigned char>data
                    else:
                        channel.counterStartValue |= (<unsigned char>data)<<8
                    channel.counterFlipFlop = not channel.counterFlipFlop
                elif (channel.counterWriteMode in (1, 2)): # 1==LSB/2==MSB
                    channel.counterStartValue = <unsigned char>data
                    if (channel.counterWriteMode == 2): # MSB
                        channel.counterStartValue <<= 8
                    channel.counterFlipFlop = False
                if (not channel.counterFlipFlop):
                    channel.runTimer()
            elif (ioPortAddr == 0x43):
                bcd = data&1
                modeNumber = (data>>1)&7
                counterWriteMode = (data>>4)&3
                channelId = (data>>6)&3
                if (channelId == 3):
                    if (bcd): # not bcd, reserved!
                        self.main.exitError("outPort: reserved should be clear.")
                        return
                    if (not (data&READBACK_DONT_LATCH_STATUS)):
                        self.main.exitError("outPort: latch status isn't supported yet.")
                        return
                    if (modeNumber): # not modeNumber, channels!
                        for i in range(3):
                            if ((data & (2 << i)) != 0):
                                channel = self.channels[i]
                                if (not (data&READBACK_DONT_LATCH_COUNT)):
                                    channel.readBackCount()
                                if (not (data&READBACK_DONT_LATCH_STATUS)):
                                    channel.readBackStatus()
                                    channel.readBackStatusIssued = True
                    #self.main.exitError("outPort: read-back not supported.")
                    return
                if (bcd): # BCD
                    self.main.exitError("outPort: BCD not supported yet.")
                    return
                if (modeNumber in (6, 7)):
                    modeNumber -= 4
                channel = self.channels[channelId]
                channel.timerEnabled = False
                channel.bcdMode = bcd
                channel.counterMode = modeNumber
                channel.counterWriteMode = counterWriteMode
                channel.counterFlipFlop = False
            else:
                self.main.exitError("outPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
        else:
            self.main.exitError("outPort: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", ioPortAddr, dataSize, data)
    cpdef run(self):
        pass
        #self.main.platform.addHandlers((0x40, 0x41, 0x42, 0x43), self)


