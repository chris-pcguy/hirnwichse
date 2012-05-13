
from time import time, sleep

include "globals.pxi"


cdef class PitChannel:
    def __init__(self, object main, Pit pit, unsigned char channelId):
        self.main = main
        self.pit = pit
        self.channelId = channelId
        self.bcdMode = 0 # 0 == binary; 1 == BCD
        self.counterMode = 0 # 0-5 valid, 6,7 not
        self.counterWriteMode = 0 # 1 == LSB ; 2 == MSB ; 3 == LSB;MSB
        self.counterValue = self.counterStartValue = 0
        self.counterFlipFlop = self.timerEnabled = False
        self.timerThread = None
        self.tempTimerValue = 0.0
    cpdef mode0Func(self):
        self.main.notice("mode0Func: entered function.")
        self.timerEnabled = False
        sleep(self.tempTimerValue)
        if (self.channelId == 0): # just raise IRQ on channel0
            (<Pic>self.main.platform.pic).raiseIrq(0)
        elif (self.channelId == 2 and (<PS2>self.main.platform.ps2).ppcbT2Gate):
            (<PS2>self.main.platform.ps2).ppcbT2Out = True
        else:
            self.main.notice("mode0Func: counterMode {0:d} used channelId {1:d}.", self.counterMode, self.channelId)
        self.main.notice("mode0Func: left function.")
    cpdef mode2Func(self): # TODO
        self.main.notice("mode2Func: entered function.")
        if (not self.counterValue or self.counterMode not in (2, 3)):
            self.main.notice("mode2Func: channelId {0:d}: counterValue{1:d} == 0 or counterMode{2:d} not in (2, 3) .", self.channelId, self.counterValue, self.counterMode)
            return
        self.counterValue = 0
        if (not self.counterValue):
            self.counterValue = self.counterStartValue
            sleep(self.tempTimerValue)
            if (self.channelId == 0): # just raise IRQ on channel0
                (<Pic>self.main.platform.pic).raiseIrq(0)
            elif (self.channelId == 2 and (<PS2>self.main.platform.ps2).ppcbT2Gate):
                (<PS2>self.main.platform.ps2).ppcbT2Out = True
            else:
                self.main.notice("mode2Func: counterMode {0:d} used channelId {1:d}.", self.counterMode, self.channelId)
        ##if (self.counterModeTimer and self.counterMode in (2, 3) and (not self.main.quitEmu)):
        ##    self.counterModeTimer = self.main.misc.createThread(self.mode2Func, True)
        ##self.timerEnabled = True
        self.main.notice("mode2Func: left function.")
    cpdef timerFunc(self): # TODO
        self.main.notice("timerFunc: entered function. (id: {0:d})", self.channelId)
        while (not self.main.quitEmu):
            if (self.timerEnabled):
                if (self.counterMode == 0):
                    self.mode0Func()
                elif (self.counterMode in (2, 3)):
                    self.mode2Func()
                else:
                    self.main.exitError("timerFunc: counterMode {0:d} is unknown.", self.counterMode)
                    return
            else:
                sleep(0.0001)
            #if (self.main.platform.vga.ui):
            #    self.main.platform.vga.ui.pumpEvents()
        self.main.notice("timerFunc: left function. (id: {0:d})", self.channelId)
    cpdef runTimer(self):
        self.main.notice("runTimer: entered function. (id: {0:d})", self.channelId)
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
        if (self.counterMode == 0):
            self.tempTimerValue = 1.0/(1193182.0/self.counterValue)
        elif (self.counterMode in (2, 3)):
            self.tempTimerValue = 1193.182/self.counterValue
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
        self.main.notice("runTimer: left function. (id: {0:d})", self.channelId)
    cpdef run(self):
        self.timerThread = self.main.misc.createThread(self.timerFunc, True)

cdef class Pit:
    def __init__(self, object main):
        self.main = main
        self.channels = (PitChannel(self.main, self, 0), PitChannel(self.main, self, 1),\
                         PitChannel(self.main, self, 2)) # channel 0-2
    cpdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cpdef PitChannel channel
        cpdef unsigned char channelId, retVal
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channelId = ioPortAddr&3
                channel = self.channels[channelId]
                if (channel.counterWriteMode == 1): # LSB
                    retVal = <unsigned char>channel.counterValue
                elif (channel.counterWriteMode == 2): # MSB
                    retVal = <unsigned char>(<unsigned short>channel.counterValue>>8)
                elif (channel.counterWriteMode == 3): # LSB;MSB
                    if (not channel.counterFlipFlop):
                        retVal = <unsigned char>channel.counterValue
                    else:
                        retVal = <unsigned char>(<unsigned short>channel.counterValue>>8)
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
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cpdef outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cpdef PitChannel channel
        cpdef unsigned char channelId, bcd, modeNumber, counterWriteMode
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channelId = ioPortAddr&3
                channel = self.channels[channelId]
                if (channel.counterWriteMode == 3): # LSB;MSB
                    if (not channel.counterFlipFlop):
                        channel.counterStartValue = data&BITMASK_BYTE
                    else:
                        channel.counterStartValue |= (data&BITMASK_BYTE)<<8
                    channel.counterFlipFlop = not channel.counterFlipFlop
                elif (channel.counterWriteMode in (1, 2)): # 1==LSB/2==MSB
                    channel.counterStartValue = data&BITMASK_BYTE
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
                    self.main.exitError("outPort: read-back not supported.")
                    return
                if (bcd): # BCD
                    self.main.exitError("outPort: BCD not supported yet.")
                    return
                if (counterWriteMode == 0):
                    self.main.exitError("outPort: latch-count not supported.")
                    return
                if (modeNumber in (6,7)):
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
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
    cpdef run(self):
        cpdef PitChannel channel
        for channel in self.channels:
            channel.run()
        #self.main.platform.addHandlers((0x40, 0x41, 0x42, 0x43), self)


