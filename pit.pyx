import threading

include "globals.pxi"



cdef class PitChannel:
    cdef public object main, pit, ps2, counterModeTimer
    cdef public unsigned char channelId, counterFormat, counterMode, counterWriteMode, counterFlipFlop
    cdef public unsigned long counterValue
    def __init__(self, object main, object pit, unsigned char channelId):
        self.main = main
        self.pit = pit
        self.ps2 = self.pit.ps2
        self.channelId = channelId
        self.reset()
    cpdef public reset(self):
        self.counterFormat = 0 # 0 == binary; 1 == BCD
        self.counterMode = 0 # 0-5 valid, 6,7 not
        self.counterWriteMode = 0 # 1 == LSB ; 2 == MSB ; 3 == LSB;MSB
        self.counterValue = 0
        self.counterFlipFlop = False
        self.counterModeTimer = None
    cpdef public object createTimer(self, float timerValue, object timerFunc):
        cdef object timerThread
        timerThread = threading.Timer(timerValue, timerFunc)
        return timerThread
    cpdef public mode0Func(self):
        self.counterValue = 0
        if (self.channelId == 2 and self.ps2.ppcbT2Both):
            self.ps2.ppcbT2Out = True
        if (self.channelId == 0): # just raise IRQ on channel0
            self.main.platform.pic.raiseIrq(0)
        else:
            self.main.printMsg("runTimer: counterMode {0:d} used channelId {1:d}.".format(self.counterMode, self.channelId))
    cpdef public mode2Func(self):
        cdef float timerValue
        if (not self.counterValue or self.counterMode != 2):
            return
        timerValue = 1.0/(1193182.0/self.counterValue)
        if (self.channelId == 0): # just raise IRQ on channel0
            self.main.platform.pic.raiseIrq(0)
        else:
            self.main.printMsg("runTimer: counterMode {0:d} used channelId {1:d}.".format(self.counterMode, self.channelId))
        if (self.counterModeTimer and self.counterMode == 2):
            self.counterModeTimer = self.createTimer(timerValue, self.mode2Func)
    cpdef public runTimer(self):
        cdef float timerValue
        if (self.counterValue == 0):
            self.counterValue = 65536 # 0x10000
        timerValue = 1.0/(1193182.0/self.counterValue)
        if (self.counterMode == 0): # mode 0
            if (self.channelId == 2 and self.ps2.ppcbT2Both):
                self.ps2.ppcbT2Out = False
            if (self.counterModeTimer):
                self.counterModeTimer.cancel()
            self.counterModeTimer = self.createTimer(timerValue, self.mode0Func)
            self.counterModeTimer.run()
        elif (self.counterMode == 2): # mode 2
            if (self.counterModeTimer):
                self.counterModeTimer.cancel()
            self.counterModeTimer = self.createTimer(timerValue, self.mode2Func)
            self.counterModeTimer.start()
        else:
            self.main.exitError("runTimer: counterMode {0:d} not supported yet.".format(self.counterMode))
            return

cdef class Pit:
    cdef public object main, ps2
    cdef public tuple channels
    cdef public unsigned char channel
    def __init__(self, object main, object ps2):
        self.main = main
        self.ps2 = ps2
        self.channels = (PitChannel(self.main, self, 0), PitChannel(self.main, self, 1),\
                         PitChannel(self.main, self, 2)) # channel 0-2
        self.reset()
    cpdef public reset(self):
        self.channel = 0
    cpdef public unsigned char inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char channel, retVal
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channel = ioPortAddr&3
                if (self.channels[channel].counterWriteMode == 1): # LSB
                    retVal = self.channels[channel].counterValue&0xff
                elif (self.channels[channel].counterWriteMode == 2): # MSB
                    retVal = (self.channels[channel].counterValue>>8)&0xff
                elif (self.channels[channel].counterWriteMode == 3): # LSB;MSB
                    if (not self.channels[channel].counterFlipFlop):
                        retVal = self.channels[channel].counterValue&0xff
                    else:
                        retVal = (self.channels[channel].counterValue>>8)&0xff
                    self.channels[channel].counterFlipFlop = not self.channels[channel].counterFlipFlop
                else:
                    self.main.exitError("inPort: unknown counterWriteMode: {0:d}.", self.channels[channel].counterWriteMode)
                return retVal
            elif (ioPortAddr == 0x43):
                retVal  = self.channel<<6
                retVal |= self.channels[self.channel].counterWriteMode<<4
                retVal |= self.channels[self.channel].counterMode<<1
                retVal |= self.channels[self.channel].counterFormat
                return retVal&0xff
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cpdef public outPort(self, unsigned short ioPortAddr, unsigned char data, unsigned char dataSize):
        cdef unsigned char channel, bcd, modeNumber, counterWriteMode
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channel = ioPortAddr&3
                if (self.channels[channel].counterModeTimer):
                    self.channels[channel].counterModeTimer.cancel()
                if (self.channels[channel].counterWriteMode == 1): # LSB
                    self.channels[channel].counterValue = (self.channels[channel].counterValue&0xff00)|(data&0xff)
                elif (self.channels[channel].counterWriteMode == 2): # MSB
                    self.channels[channel].counterValue = ((data&0xff)<<8)|(self.channels[channel].counterValue&0xff)
                elif (self.channels[channel].counterWriteMode == 3): # LSB;MSB
                    if (not self.channels[channel].counterFlipFlop):
                        self.channels[channel].counterValue = (self.channels[channel].counterValue&0xff00)|(data&0xff)
                    else:
                        self.channels[channel].counterValue = (self.channels[channel].counterValue&0xff)|((data&0xff)<<8)
                    self.channels[channel].counterFlipFlop = not self.channels[channel].counterFlipFlop
                if (self.channels[channel].counterWriteMode in (1, 2)): # LSB or MSB
                    self.channels[channel].counterFlipFlop = False
                if (not self.channels[channel].counterFlipFlop):
                    self.channels[channel].runTimer()
            elif (ioPortAddr == 0x43):
                bcd = data&1
                modeNumber = (data>>1)&7
                counterWriteMode = (data>>4)&3
                self.channel = (data>>6)&3
                if (self.channel == 2):
                    self.ps2.ppcbT2Out = False
                if (self.channels[self.channel].counterModeTimer):
                    self.channels[self.channel].counterModeTimer.cancel()
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
                self.channels[self.channel].counterFormat = bcd
                self.channels[self.channel].counterMode = modeNumber
                self.channels[self.channel].counterWriteMode = counterWriteMode
                self.channels[self.channel].counterFlipFlop = False
                
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cpdef public run(self):
        self.main.platform.addReadHandlers((0x40, 0x41, 0x42, 0x43), self.inPort)
        self.main.platform.addWriteHandlers((0x40, 0x41, 0x42, 0x43), self.outPort)


