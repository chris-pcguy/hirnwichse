import misc

CONTROLLER_MASTER = 0
CONTROLLER_SLAVE  = 1

cdef class Channel:
    cdef public object controller, isadma, main
    cdef public unsigned char channelMasked, transferDirection, autoInit, countDirection, transferMode, page
    cdef public unsigned long startAddress, transferBytes
    def __init__(self, object controller):
        self.controller = controller
        self.isadma = self.controller.isadma
        self.main = self.isadma.main
        self.channelMasked = False
        self.page = 0
        self.startAddress = 0
        self.transferBytes = 0 # count of bytes to transfer - 1
        
        self.transferDirection = 3
        self.autoInit = 0
        self.countDirection = 0 # if True, address-count, then data[::-1]
        self.transferMode = 0
    def handleTransfer(self, bytes data, unsigned char write): # if write==True: read data from ram and write it to device
        cdef unsigned long address
        if (not self.countDirection):
            address = (self.page<<16)|self.startAddress
        else:
            address = ((self.page<<16)|self.startAddress)-self.transferBytes
        if (write):
            data = self.main.mm.mmPhyRead(address, self.transferBytes+1)
        if (self.countDirection):
            data = data[::-1]
        if (write):
            return data
        self.main.mm.mmPhyWrite(address, data, self.transferBytes+1)
        


cdef class Controller:
    cdef public object isadma, main
    cdef tuple channel
    cdef unsigned char flipFlop
    def __init__(self, object isadma):
        self.isadma = isadma
        self.main = self.isadma.main
        self.channel = (Channel(self), Channel(self), Channel(self), Channel(self))
        self.reset()
    def reset(self):
        self.flipFlop = False
    def handleTransfer(self, unsigned char channel, bytes data, unsigned char write): # if write==True: read data from ram and write it to device
        if (channel not in (0, 1, 2, 3)):
            self.main.exitError("ISADMA: handleTransfer: invalid channel! (channel: {0:d})", channel)
            return
        return self.channel[channel].handleTransfer(data, write)
    def setFlipFlop(self, unsigned char flipFlop):
        self.flipFlop = flipFlop
    def setTransferMode(self, unsigned char transferModeByte):
        channel = transferModeByte&3
        self.channel[channel].transferDirection = (transferModeByte>>2)&3
        self.channel[channel].autoInit = (transferModeByte&0x10)==0x10
        self.channel[channel].countDirection = (transferModeByte&0x20)==0x20
        self.channel[channel].transferMode = (transferModeByte>>6)&3
    def maskChannel(self, unsigned char channel, unsigned char maskIt):
        self.channel[channel].channelMasked = maskIt
    def maskChannels(self, unsigned char maskByte):
        self.channel[0].channelMasked = maskByte&1
        self.channel[1].channelMasked = maskByte&2
        self.channel[2].channelMasked = maskByte&4
        self.channel[3].channelMasked = maskByte&8
    def setPageByte(self, unsigned char channel, unsigned char data):
        self.channel[channel].page = data&0xff
    def setAddrByte(self, unsigned char channel, unsigned char data):
        if (self.flipFlop):
            self.channel[channel].startAddress = (self.channel[channel].startAddress&0xff)|((data&0xff)<<8)
        else:
            self.channel[channel].startAddress = (self.channel[channel].startAddress&0xff00)|(data&0xff)
        self.flipFlop = not self.flipFlop
    def setCountByte(self, unsigned char channel, unsigned char data):
        if (self.flipFlop):
            self.channel[channel].transferBytes = (self.channel[channel].transferBytes&0xff)|((data&0xff)<<8)
        else:
            self.channel[channel].transferBytes = (self.channel[channel].transferBytes&0xff00)|(data&0xff)
        self.flipFlop = not self.flipFlop


cdef class ISADma:
    cdef public object main
    cdef tuple ioMasterControllerPorts, ioSlaveControllerPorts, controller
    def __init__(self, object main):
        self.main = main
        self.controller = (Controller(self), Controller(self))
        self.ioMasterControllerPorts = (0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,
                                      0x0d,0x0f,0x81,0x82,0x83,0x87)
        self.ioSlaveControllerPorts = (0x89,0x8a,0x8b,0x8f,0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,
                                      0xd0,0xd2,0xd4,0xd6,0xd8,0xda,0xde)
    def handleTransfer(self, unsigned char channel, bytes data, unsigned char write): # if write==True: read data from ram and write it to device
        cdef unsigned char controller = 0
        if (channel not in (0, 1, 2, 3, 4, 5, 6, 7)):
            self.main.exitError("ISADMA: handleTransfer: invalid channel! (channel: {0:d})", channel)
            return
        if (channel >= 4):
            channel -= 4
            controller = 1
        return self.controller[controller].handleTransfer(channel, data, write)
    def inPortMaster(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            self.main.printMsg("ISADMA: inPortMaster: dataSize misc.OP_SIZE_BYTE: ioPortAddr not handled. (ioPortAddr: {0:#06x})", ioPortAddr)
        elif (dataSize == misc.OP_SIZE_WORD):
            self.main.printMsg("ISADMA: inPortMaster: dataSize misc.OP_SIZE_WORD: ioPortAddr not handled. (ioPortAddr: {0:#06x})", ioPortAddr)
        else:
            self.main.exitError("ISADMA: inPortMaster: dataSize {0:d} not supported.", dataSize)
        return 0
    def inPortSlave(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            self.main.printMsg("ISADMA: inPortSlave: dataSize misc.OP_SIZE_BYTE: ioPortAddr not handled. (ioPortAddr: {0:#06x})", ioPortAddr)
        elif (dataSize == misc.OP_SIZE_WORD):
            self.main.printMsg("ISADMA: inPortSlave: dataSize misc.OP_SIZE_WORD: ioPortAddr not handled. (ioPortAddr: {0:#06x})", ioPortAddr)
        else:
            self.main.exitError("ISADMA: inPortSlave: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPortMaster(self, unsigned short ioPortAddr, unsigned short data, unsigned char dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            if (ioPortAddr == 0x0c):
                self.controller[0].setFlipFlop(False)
            elif (ioPortAddr == 0x0d):
                self.controller[0].reset()
            elif (ioPortAddr == 0x0a):
                self.controller[0].maskChannel(data&3, data&4)
            elif (ioPortAddr == 0x0b):
                self.controller[0].setTransferMode(data&0xff)
            elif (ioPortAddr == 0x0f):
                self.controller[0].maskChannels(data&0xff)
            elif (ioPortAddr in (0x87, 0x83, 0x81, 0x82)):
                channelNum = (ioPortAddr&7)//2
                self.controller[0].setPageByte(channelNum, data&0xff)
            elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06)):
                channelNum = (ioPortAddr&7)//2
                self.controller[0].setAddrByte(channelNum, data&0xff)
            elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07)):
                channelNum = (ioPortAddr&7)//2
                self.controller[0].setCountByte(channelNum, data&0xff)
            else:
                self.main.printMsg("ISADMA: outPortMaster: dataSize misc.OP_SIZE_BYTE: ioPortAddr not handled. (ioPortAddr: {0:#06x}, data: {1:#04x})", ioPortAddr, data)
        elif (dataSize == misc.OP_SIZE_WORD):
            self.main.printMsg("ISADMA: outPortMaster: dataSize misc.OP_SIZE_WORD: ioPortAddr not handled. (ioPortAddr: {0:#06x}, data: {1:#06x})", ioPortAddr, data)
        else:
            self.main.exitError("ISADMA: outPortMaster: dataSize {0:d} not supported. (ioPortAddr: {1:#06x}, data: {2:#04x})", dataSize, ioPortAddr, data)
        return
    def outPortSlave(self, unsigned short ioPortAddr, unsigned short data, unsigned char dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            if (ioPortAddr == 0xd8):
                self.controller[1].setFlipFlop(False)
            elif (ioPortAddr == 0xda):
                self.controller[1].reset()
            elif (ioPortAddr == 0xd4):
                self.controller[1].maskChannel(data&3, data&4)
            elif (ioPortAddr == 0xd6):
                self.controller[1].setTransferMode(data&0xff)
            elif (ioPortAddr == 0xde):
                self.controller[1].maskChannels(data&0xff)
            elif (ioPortAddr in (0x8f, 0x8b, 0x89, 0x8a)):
                channelNum = (ioPortAddr&7)//2
                self.controller[1].setPageByte(channelNum, data&0xff)
            elif (ioPortAddr in (0xc0, 0xc2, 0xc4, 0xc6)):
                channelNum = (ioPortAddr&7)//2
                self.controller[1].setAddrByte(channelNum, data&0xff)
            elif (ioPortAddr in (0xc1, 0xc3, 0xc5, 0xc7)):
                channelNum = (ioPortAddr&7)//2
                self.controller[1].setCountByte(channelNum, data&0xff)
            else:
                self.main.printMsg("ISADMA: outPortSlave: dataSize misc.OP_SIZE_BYTE: ioPortAddr not handled. (ioPortAddr: {0:#06x}, data: {1:#04x})", ioPortAddr, data)
        elif (dataSize == misc.OP_SIZE_WORD):
            self.main.printMsg("ISADMA: outPortSlave: dataSize misc.OP_SIZE_WORD: ioPortAddr not handled. (ioPortAddr: {0:#06x}, data: {1:#06x})", ioPortAddr, data)
        else:
            self.main.exitError("ISADMA: outPortSlave: dataSize {0:d} not supported. (ioPortAddr: {1:#06x}, data: {2:#06x})", dataSize, ioPortAddr, data)
        return
    def run(self):
        self.main.platform.addReadHandlers(self.ioMasterControllerPorts, self.inPortMaster)
        self.main.platform.addReadHandlers(self.ioSlaveControllerPorts,  self.inPortSlave)
        self.main.platform.addWriteHandlers(self.ioMasterControllerPorts, self.outPortMaster)
        self.main.platform.addWriteHandlers(self.ioSlaveControllerPorts, self.outPortSlave)


