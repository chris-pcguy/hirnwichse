import misc, time

CALCWITHTHIS = 3000 / 3579545 # so, reload_value * CALCWITHTHIS


class PitChannel:
    def __init__(self, main, pit, channelId):
        self.main = main
        self.pit = pit
        self.channelId = channelId
        self.reset()
    def reset(self):
        self.counterFormat = 0 # 0 == binary; 1 == BCD
        self.counterMode = 0 # 0-5 valid, 6,7 not
        self.counterWriteMode = 0 # 1 == LSB ; 2 == MSB ; 3 == LSB;MSB
        self.counterValue = 0
        self.counterFlipFlop = False
    def runTimer(self):
        self.ps2 = self.main.platform.ps2
        if (self.counterValue == 0):
            self.counterValue = 65536 # 0x10000
        if (self.counterMode == 0): # mode 0
            if (self.ps2.ppcbT2Gate):
                self.ps2.ppcbT2Out = False
            ####time.sleep(self.counterValue*CALCWITHTHIS)
            time.sleep(1/(1193182/self.counterValue))
            self.counterValue = 0
            if (self.ps2.ppcbT2Gate):
                self.ps2.ppcbT2Out = True
            if (self.channelId == 0): # on mode0, just raise IRQ on channel0.
                self.main.platform.pic.raiseIrq(0)
            else:
                self.main.printMsg("runTimer: counterMode {0:d} used channelId {1:d}.".format(self.counterMode, self.channelId))
        elif (self.counterMode == 2): # mode 2
            if (self.ps2.ppcbT2Gate):
                self.ps2.ppcbT2Out = False
            ####time.sleep(self.counterValue*CALCWITHTHIS)
            time.sleep(1/(1193182/self.counterValue))
            if (self.ps2.ppcbT2Gate):
                self.ps2.ppcbT2Out = True
            if (self.channelId == 0): # on mode2, just raise IRQ on channel0?
                self.main.platform.pic.raiseIrq(0)
            else:
                self.main.printMsg("runTimer: counterMode {0:d} used channelId {1:d}.".format(self.counterMode, self.channelId))
        else:
            self.main.exitError("runTimer: counterMode {0:d} not supported yet.".format(self.counterMode))
            return

class Pit:
    def __init__(self, main):
        self.main = main
        self.channels = (PitChannel(self.main, self, 0), PitChannel(self.main, self, 1),\
                         PitChannel(self.main, self, 2)) # channel 0-2
        self.reset()
    def reset(self):
        self.channel = 0
    def inPort(self, ioPortAddr, dataSize):
        retVal = 0
        if (dataSize == misc.OP_SIZE_8BIT):
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
                return retVal&0xff
            elif (ioPortAddr == 0x43):
                retVal  = self.channel<<6
                retVal |= self.channels[self.channel].counterWriteMode<<4
                retVal |= self.channels[self.channel].counterMode<<1
                retVal |= self.channels[self.channel].counterFormat
                return retVal&0xff
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, ioPortAddr, data, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channel = ioPortAddr&3
                if (self.channels[channel].counterWriteMode == 1): # LSB
                    self.channels[channel].counterValue = (self.channels[channel].counterValue&0xff00)|(data&0xff)
                elif (self.channels[channel].counterWriteMode == 2): # MSB
                    self.channels[channel].counterValue = ((data&0xff)<<8)|(self.channels[channel].counterValue&0xff)
                elif (self.channels[channel].counterWriteMode == 3): # LSB;MSB
                    if (not self.channels[channel].counterFlipFlop):
                        self.channels[channel].counterValue = (self.channels[channel].counterValue&0xff00)|(data&0xff)
                    else:
                        self.channels[channel].counterValue = ((data&0xff)<<8)|(self.channels[channel].counterValue&0xff)
                    self.channels[channel].counterFlipFlop = not self.channels[channel].counterFlipFlop
                if (not self.channels[channel].counterFlipFlop):
                    self.channels[channel].runTimer()
            elif (ioPortAddr == 0x43):
                bcd = data&1
                modeNumber = (data>>1)&7
                counterWriteMode = (data>>4)&3
                self.channel = (data>>6)&3
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
    def run(self):
        self.main.platform.addReadHandlers((0x40, 0x41, 0x42, 0x43), self.inPort)
        self.main.platform.addWriteHandlers((0x40, 0x41, 0x42, 0x43), self.outPort)


