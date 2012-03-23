
from time import sleep

include "globals.pxi"


cdef class PitChannel:
    def __init__(self, object main, Pit pit, unsigned char channelId):
        self.main = main
        self.pit = pit
        self.channelId = channelId
    cdef void reset(self):
        self.counterFormat = 0 # 0 == binary; 1 == BCD
        self.counterMode = 0 # 0-5 valid, 6,7 not
        self.counterWriteMode = 0 # 1 == LSB ; 2 == MSB ; 3 == LSB;MSB
        self.counterValue = self.counterStartValue = 0
        self.counterFlipFlop = False
        self.counterModeTimer = None
        self.tempTimerValue = 0.0
    cpdef mode0Func(self):
        sleep(self.tempTimerValue)
        if (self.channelId == 0): # just raise IRQ on channel0
            (<Pic>self.main.platform.pic).raiseIrq(0)
        elif (self.channelId == 2 and ((<PS2>self.main.platform.ps2).ppcbT2Nibble & PPCB_T2_ENABLE)):
            (<PS2>self.main.platform.ps2).ppcbT2Done = True
        else:
            self.main.printMsg("mode0Func: counterMode {0:d} used channelId {1:d}.".format(self.counterMode, self.channelId))
    cpdef mode2Func(self): # TODO
        if (not self.counterValue or self.counterMode not in (2, 3)):
            self.main.printMsg("mode2Func: channelId {0:d}: counterValue{1:d} == 0 or counterMode{2:d} not in (2, 3) .".format(self.channelId, self.counterValue, self.counterMode))
            return
        if (self.counterMode == 2):
            self.counterValue = <unsigned int>(self.counterValue-1)
        elif (self.counterMode == 3):
            self.counterValue = <unsigned int>(self.counterValue-2)
        else:
            self.main.exitError("mode2Func: counterMode {0:d} is unknown.", self.counterMode)
        if (not self.counterValue):
            self.counterValue = self.counterStartValue
        sleep(self.tempTimerValue)
        if (self.channelId == 0):# or (self.counterMode == 3 and self.channelId == 2)): # just raise IRQ on channel0
            (<Pic>self.main.platform.pic).raiseIrq(0)
        elif (self.channelId != 2):
            self.main.printMsg("mode2Func: counterMode {0:d} used channelId {1:d}.".format(self.counterMode, self.channelId))
        if (self.counterModeTimer and self.counterMode in (2, 3) and (not self.main.quitEmu)):
            self.counterModeTimer = self.main.misc.createThread(self.mode2Func, True)
    cpdef runTimer(self):
        if (self.channelId == 1):
            self.main.exitError("PitChannel::runTimer: PIT-Channel 1 is ancient.")
            return
        if (self.counterValue == 0):
            self.counterValue = 0x10000
        if (self.counterFormat != 0):
            self.counterValue = self.main.misc.bcdToDec(self.counterValue)
        if (self.counterMode == 3 and self.counterValue%2 == 1):
            self.counterValue -= 1
        self.counterStartValue = self.counterValue
        self.tempTimerValue = 1.0/(1193182.0/self.counterStartValue)
        if (self.tempTimerValue < 0.01): # TODO
            self.tempTimerValue = 0.01
        if (self.counterMode == 0): # mode 0
            if (self.channelId == 2 and ((<PS2>self.main.platform.ps2).ppcbT2Nibble & PPCB_T2_ENABLE)):
                (<PS2>self.main.platform.ps2).ppcbT2Done = False
            if (self.counterModeTimer):
                self.counterModeTimer = None
            if (not self.main.quitEmu):
                self.counterModeTimer = self.main.misc.createThread(self.mode0Func, True)
        elif (self.counterMode in (2, 3)): # mode 2/3
            if (self.counterMode == 2 and self.channelId == 2):
                self.main.exitError("runTimer: is it ok to use mode-{0:d} with channelId-{1:d} and cpu clock measures?", self.counterMode, self.channelId)
                return
            if (self.counterMode == 3 and self.channelId == 2 and ((<PS2>self.main.platform.ps2).ppcbT2Nibble & PPCB_T2_ENABLE)):
                (<PS2>self.main.platform.ps2).ppcbT2Done = False
            if (self.counterModeTimer):
                self.counterModeTimer = None
            if (not self.main.quitEmu):
                self.counterModeTimer = self.main.misc.createThread(self.mode2Func, True)
        else:
            self.main.exitError("runTimer: counterMode {0:d} not supported yet. (channelId: {1:d})".format(self.counterMode, self.channelId))
            return
    cdef void run(self):
        self.reset()

cdef class Pit:
    def __init__(self, object main):
        self.main = main
        self.channels = (PitChannel(self.main, self, 0), PitChannel(self.main, self, 1),\
                         PitChannel(self.main, self, 2)) # channel 0-2
    cdef void reset(self):
        cdef PitChannel channel
        self.channel = 0
        for channel in self.channels:
            channel.run()
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char channel, retVal
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channel = ioPortAddr&3
                if ((<PitChannel>self.channels[channel]).counterWriteMode == 1): # LSB
                    retVal = <unsigned char>(<PitChannel>self.channels[channel]).counterValue
                elif ((<PitChannel>self.channels[channel]).counterWriteMode == 2): # MSB
                    retVal = <unsigned char>((<PitChannel>self.channels[channel]).counterValue>>8)
                elif ((<PitChannel>self.channels[channel]).counterWriteMode == 3): # LSB;MSB
                    if (not (<PitChannel>self.channels[channel]).counterFlipFlop):
                        retVal = <unsigned char>(<PitChannel>self.channels[channel]).counterValue
                    else:
                        retVal = <unsigned char>((<PitChannel>self.channels[channel]).counterValue>>8)
                    (<PitChannel>self.channels[channel]).counterFlipFlop = not (<PitChannel>self.channels[channel]).counterFlipFlop
                else:
                    self.main.exitError("inPort: unknown counterWriteMode: {0:d}.", (<PitChannel>self.channels[channel]).counterWriteMode)
                return retVal
            elif (ioPortAddr == 0x43):
                retVal  = self.channel<<6
                retVal |= (<PitChannel>self.channels[self.channel]).counterWriteMode<<4
                retVal |= (<PitChannel>self.channels[self.channel]).counterMode<<1
                retVal |= (<PitChannel>self.channels[self.channel]).counterFormat
                return <unsigned char>retVal
            else:
                self.main.exitError("inPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef unsigned char channel, bcd, modeNumber, counterWriteMode
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channel = ioPortAddr&3
                if ((<PitChannel>self.channels[channel]).counterModeTimer):
                    (<PitChannel>self.channels[channel]).counterModeTimer = None
                if ((<PitChannel>self.channels[channel]).counterWriteMode in (1, 2)): # 1==LSB/2==MSB
                    (<PitChannel>self.channels[channel]).counterValue = <unsigned char>data
                    if ((<PitChannel>self.channels[channel]).counterWriteMode == 2): # MSB
                        (<PitChannel>self.channels[channel]).counterValue <<= 8
                elif ((<PitChannel>self.channels[channel]).counterWriteMode == 3): # LSB;MSB
                    if (not (<PitChannel>self.channels[channel]).counterFlipFlop):
                        (<PitChannel>self.channels[channel]).counterValue = (((<PitChannel>self.channels[channel]).counterValue&0xff00)|(<unsigned char>data))
                    else:
                        (<PitChannel>self.channels[channel]).counterValue = ((<unsigned char>(<PitChannel>self.channels[channel]).counterValue)|((<unsigned char>data)<<8))
                    (<PitChannel>self.channels[channel]).counterFlipFlop = not (<PitChannel>self.channels[channel]).counterFlipFlop
                if ((<PitChannel>self.channels[channel]).counterWriteMode in (1, 2)): # LSB or MSB
                    (<PitChannel>self.channels[channel]).counterFlipFlop = False
                if (not (<PitChannel>self.channels[channel]).counterFlipFlop):
                    (<PitChannel>self.channels[channel]).runTimer()
            elif (ioPortAddr == 0x43):
                bcd = data&1
                modeNumber = (data>>1)&7
                counterWriteMode = (data>>4)&3
                self.channel = (data>>6)&3
                if ((<PitChannel>self.channels[self.channel]).counterModeTimer):
                    (<PitChannel>self.channels[self.channel]).counterModeTimer = None
                if (bcd): # BCD
                    self.main.exitError("outPort: BCD not supported yet.")
                    return
                if (counterWriteMode == 0):
                    self.main.exitError("outPort: latch-count not supported.")
                    return
                if (modeNumber in (6,7)):
                    modeNumber -= 4
                if (self.channel == 3):
                    self.main.exitError("outPort: read-back not supported.")
                    return
                (<PitChannel>self.channels[self.channel]).counterFormat = bcd
                (<PitChannel>self.channels[self.channel]).counterMode = modeNumber
                (<PitChannel>self.channels[self.channel]).counterWriteMode = counterWriteMode
                (<PitChannel>self.channels[self.channel]).counterFlipFlop = False
            else:
                self.main.exitError("outPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cdef void run(self):
        self.reset()
        #self.main.platform.addHandlers((0x40, 0x41, 0x42, 0x43), self)


