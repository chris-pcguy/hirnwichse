import misc

CONTROLLER_MASTER = 0
CONTROLLER_SLAVE  = 1

class Channel:
    def __init__(self, controller):
        self.controller = controller
        self.isadma = self.controller.isadma
        self.main = self.isadma.main
        self.channelMasked = False
        self.startAddress = 0
        self.transferBytes = 0 # count of bytes to transfer - 1

class Controller:
    def __init__(self, isadma):
        self.isadma = isadma
        ##print(dir(self), dir(self.isadma))
        self.main = self.isadma.main
        self.channel = (Channel(self), Channel(self), Channel(self), Channel(self))
        self.reset()
    def reset(self):
        self.flipFlop = False
        self.transferModeChannel = -1
        self.transferModeTransferDirection = -1
        self.transferModeAutoInitialize = 0
        self.transferModeCountDirection = 0
        self.transferModeMode = -1
    def setTransferMode(self, transferModeByte):
        self.transferModeChannel = transferModeByte&3
        self.transferModeTransferDirection = (transferModeByte>>2)&3
        self.transferModeAutoInitialize = (transferModeByte&0x10)==0x10
        self.transferModeCountDirectionDown = (transferModeByte&0x20)==0x20
        self.transferModeMode = (transferModeByte>>6)&3
    def maskChannel(self, channelNum, maskIt):
        self.channel[channelNum].channelMasked = maskIt
    def maskChannels(self, maskByte):
        self.channel[0].channelMasked = maskByte&1
        self.channel[1].channelMasked = maskByte&2
        self.channel[2].channelMasked = maskByte&4
        self.channel[3].channelMasked = maskByte&8
    def setAddrByte(self, channelNum, data):
        if (self.flipFlop):
            self.startAddress = ((data&0xff)<<8)|(self.startAddress&0xff)
        else:
            self.startAddress = (self.startAddress&0xff00)|(data&0xff)
    def setCountByte(self, channelNum, data):
        if (self.flipFlop):
            self.transferBytes = ((data&0xff)<<8)|(self.transferBytes&0xff)
        else:
            self.transferBytes = (self.transferBytes&0xff00)|(data&0xff)


class ISADma:
    def __init__(self, main):
        self.main = main
        self.ioMasterControllerPorts = (0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,
                                      0x0d,0x0f,0x81,0x82,0x83,0x87)
        self.ioSlaveControllerPorts = (0x89,0x8a,0x8b,0x8f,0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,
                                      0xd0,0xd2,0xd4,0xd6,0xd8,0xda,0xde)
        self.controller = (Controller(self), Controller(self))
    def inPortMaster(self, ioPortAddr, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            self.main.printMsg("ISADMA: inPortMaster: dataSize misc.OP_SIZE_8BIT: ioPortAddr not handled. (ioPortAddr: {0:#06x})", ioPortAddr)
        elif (dataSize == misc.OP_SIZE_16BIT):
            self.main.printMsg("ISADMA: inPortMaster: dataSize misc.OP_SIZE_16BIT: ioPortAddr not handled. (ioPortAddr: {0:#06x})", ioPortAddr)
        else:
            self.main.exitError("ISADMA: inPortMaster: dataSize {0:d} not supported.", dataSize)
        return 0
    def inPortSlave(self, ioPortAddr, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            self.main.printMsg("ISADMA: inPortSlave: dataSize misc.OP_SIZE_8BIT: ioPortAddr not handled. (ioPortAddr: {0:#06x})", ioPortAddr)
        elif (dataSize == misc.OP_SIZE_16BIT):
            self.main.printMsg("ISADMA: inPortSlave: dataSize misc.OP_SIZE_16BIT: ioPortAddr not handled. (ioPortAddr: {0:#06x})", ioPortAddr)
        else:
            self.main.exitError("ISADMA: inPortSlave: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPortMaster(self, ioPortAddr, data, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr == 0x0c):
                self.controller[0].flipFlop = False
            elif (ioPortAddr == 0x0d):
                self.controller[0].reset()
            elif (ioPortAddr == 0x0a):
                self.controller[0].maskChannel(data&3, data&4)
            elif (ioPortAddr == 0x0b):
                self.controller[0].setTransferMode(data&0xff)
            elif (ioPortAddr == 0x0f):
                self.controller[0].maskChannels(data&0xff)
            elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06)):
                channelNum = (ioPortAddr&7)//2
                self.controller[0].setAddrByte(channelNum, data&0xff)
            elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07)):
                channelNum = (ioPortAddr&7)//2
                self.controller[0].setCountByte(channelNum, data&0xff)
            else:
                self.main.printMsg("ISADMA: outPortMaster: dataSize misc.OP_SIZE_8BIT: ioPortAddr not handled. (ioPortAddr: {0:#06x}, data: {1:#04x})", ioPortAddr, data)
        elif (dataSize == misc.OP_SIZE_16BIT):
            self.main.printMsg("ISADMA: outPortMaster: dataSize misc.OP_SIZE_16BIT: ioPortAddr not handled. (ioPortAddr: {0:#06x}, data: {1:#06x})", ioPortAddr, data)
        else:
            self.main.exitError("ISADMA: outPortMaster: dataSize {0:d} not supported. (ioPortAddr: {1:#06x}, data: {2:#04x})", dataSize, ioPortAddr, data)
        return
    def outPortSlave(self, ioPortAddr, data, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr == 0xd8):
                self.controller[1].flipFlop = False
            elif (ioPortAddr == 0xda):
                self.controller[1].reset()
            elif (ioPortAddr == 0xd4):
                self.controller[1].maskChannel(data&3, data&4)
            elif (ioPortAddr == 0xd6):
                self.controller[1].setTransferMode(data&0xff)
            elif (ioPortAddr == 0xde):
                self.controller[1].maskChannels(data&0xff)
            elif (ioPortAddr in (0xc0, 0xc2, 0xc4, 0xc6)):
                channelNum = (ioPortAddr&7)//2
                self.controller[1].setAddrByte(channelNum, data&0xff)
            elif (ioPortAddr in (0xc1, 0xc3, 0xc5, 0xc7)):
                channelNum = (ioPortAddr&7)//2
                self.controller[1].setCountByte(channelNum, data&0xff)
            else:
                self.main.printMsg("ISADMA: outPortSlave: dataSize misc.OP_SIZE_8BIT: ioPortAddr not handled. (ioPortAddr: {0:#06x}, data: {1:#04x})", ioPortAddr, data)
        elif (dataSize == misc.OP_SIZE_16BIT):
            self.main.printMsg("ISADMA: outPortSlave: dataSize misc.OP_SIZE_16BIT: ioPortAddr not handled. (ioPortAddr: {0:#06x}, data: {1:#06x})", ioPortAddr, data)
        else:
            self.main.exitError("ISADMA: outPortSlave: dataSize {0:d} not supported. (ioPortAddr: {1:#06x}, data: {2:#06x})", dataSize, ioPortAddr, data)
        return
    def run(self):
        self.main.platform.addReadHandlers(self.ioMasterControllerPorts, self.inPortMaster)
        self.main.platform.addReadHandlers(self.ioSlaveControllerPorts,  self.inPortSlave)
        self.main.platform.addWriteHandlers(self.ioMasterControllerPorts, self.outPortMaster)
        self.main.platform.addWriteHandlers(self.ioSlaveControllerPorts, self.outPortSlave)


