
include "globals.pxi"


CONTROLLER_MASTER = 0
CONTROLLER_SLAVE  = 1


DMA_TRANSFER_ON_DEMAND = 0
DMA_SINGLE_TRANSFER = 1
DMA_BLOCK_TRANSFER = 2
DMA_CASCADE_MODE = 3

DMA_CMD_DISABLE = 0x4

cdef class Channel:
    cdef public object controller, isadma, main
    cdef public unsigned char channelMasked, transferDirection, autoInit, countDirection, transferMode, page
    cdef public long startAddress, transferBytes
    cdef unsigned char channelNum, TC
    def __init__(self, object controller, unsigned char channelNum):
        self.controller = controller
        self.isadma = self.controller.isadma
        self.main = self.isadma.main
        self.channelNum = channelNum
        self.channelMasked = False
        self.page = 0
        self.startAddress = 0
        self.transferBytes = 0 # count of bytes to transfer - 1
        
        self.transferDirection = 3
        self.autoInit = False
        self.countDirection = 0 # if True, address-count, then data[::-1]
        self.transferMode = 0
        self.TC = False
    def handleTransfer(self, bytes data, unsigned char write): # if write==True: read data from ram and write it to device
        cdef unsigned long address, count
        self.TC = False
        count = (self.transferBytes&0xffff)+1
        if (not self.countDirection):
            address = ( (self.page<<16)|self.startAddress )&0xfffff
        else:
            address = ( ((self.page<<16)|self.startAddress)-(count-1) )&0xfffff
        if (write):
            data = self.main.mm.mmPhyRead(address, count)
        if (self.countDirection):
            data = data[::-1]
        if (not write):
            self.main.mm.mmPhyWrite(address, data, count)
        if (not self.autoInit):
            if (not self.countDirection):
                self.startAddress = (self.startAddress+count)&0xffff
            else:
                self.startAddress = (self.startAddress-count)&0xffff
            self.transferBytes = 0xffff
        self.TC = True
        return data
    def getTC(self):
        return self.TC
    def setTC(self, unsigned char newTC):
        self.TC = newTC


cdef class Controller:
    cdef public object isadma, main
    cdef tuple channel
    cdef unsigned char flipFlop, firstChannel, master
    def __init__(self, object isadma, unsigned char master):
        self.master = master
        self.firstChannel = 0
        if (not self.master):
            self.firstChannel = 4
        self.isadma = isadma
        self.main = self.isadma.main
        self.channel = (Channel(self, self.firstChannel), Channel(self, self.firstChannel+1), Channel(self, self.firstChannel+2), Channel(self, self.firstChannel+3))
        self.reset()
    def reset(self):
        self.flipFlop = False
    def doCommand(self, unsigned char data):
        if ((data & DMA_CMD_DISABLE) != 0):
            self.main.exitError("ISADMA_CTRL::doCommand: non-DMA transfer not supported yet.")
            return
    def handleTransfer(self, unsigned char channel, bytes data, unsigned char write): # if write==True: read data from ram and write it to device
        if (channel not in (0, 1, 2, 3)):
            self.main.exitError("ISADMA_CTRL::handleTransfer: invalid channel! (channel: {0:d})", channel)
            return
        if (not self.master and channel == 0):
            self.main.exitError("ISADMA_CTRL::handleTransfer: channel 4 (slave, channel 0) is for cascade mode only!")
            return
        return self.channel[channel].handleTransfer(data, write)
    def setFlipFlop(self, unsigned char flipFlop):
        self.flipFlop = flipFlop
    def setTransferMode(self, unsigned char transferModeByte):
        channel = transferModeByte&3
        self.channel[channel].transferDirection = (transferModeByte>>2)&3
        self.channel[channel].autoInit = (transferModeByte&0x10)!=0
        self.channel[channel].countDirection = (transferModeByte&0x20)!=0
        self.channel[channel].transferMode = (transferModeByte>>6)&3
        if ((self.master or (not self.master and channel != 0)) and self.channel[channel].transferMode != DMA_SINGLE_TRANSFER):
            self.main.exitError("ISADMA::setTransferMode: transferMode: {0:d} not supported yet.", self.channel[channel].transferMode)
    def maskChannel(self, unsigned char channel, unsigned char maskIt):
        self.channel[channel].channelMasked = maskIt
    def maskChannels(self, unsigned char maskByte):
        self.channel[0].channelMasked = maskByte&1
        self.channel[1].channelMasked = maskByte&2
        self.channel[2].channelMasked = maskByte&4
        self.channel[3].channelMasked = maskByte&8
    def setPageByte(self, unsigned char channel, unsigned char data):
        self.channel[channel].page = data
    def setAddrByte(self, unsigned char channel, unsigned char data):
        if (self.flipFlop):
            self.channel[channel].startAddress = (self.channel[channel].startAddress&0xff)| ( data<<8)
        else:
            self.channel[channel].startAddress = (self.channel[channel].startAddress&0xff00) | data
        self.setFlipFlop(not self.flipFlop)
    def setCountByte(self, unsigned char channel, unsigned char data):
        if (self.flipFlop):
            self.channel[channel].transferBytes = (self.channel[channel].transferBytes&0xff) | (data<<8)
        else:
            self.channel[channel].transferBytes = (self.channel[channel].transferBytes&0xff00) | data
        self.setFlipFlop(not self.flipFlop)
    def getPageByte(self, unsigned char channel):
        return self.channel[channel].page&0xff
    def getAddrByte(self, unsigned char channel):
        cdef unsigned char retVal
        if (self.flipFlop):
            retVal = (self.channel[channel].startAddress>>8)&0xff
        else:
            retVal = self.channel[channel].startAddress&0xff
        self.setFlipFlop(not self.flipFlop)
        return retVal
    def getCountByte(self, unsigned char channel):
        cdef unsigned char retVal
        if (self.flipFlop):
            retVal = (self.channel[channel].transferBytes>>8)&0xff
        else:
            retVal = self.channel[channel].transferBytes&0xff
        self.setFlipFlop(not self.flipFlop)
        return retVal
    def setAddrWord(self, unsigned char channel, unsigned short data):
        self.channel[channel].startAddress = data
    def setCountWord(self, unsigned char channel, unsigned short data):
        self.channel[channel].transferBytes = data
    def getAddrWord(self, unsigned char channel):
        cdef unsigned short retVal
        retVal = self.channel[channel].startAddress&0xffff
        return retVal
    def getCountWord(self, unsigned char channel):
        cdef unsigned short retVal
        retVal = self.channel[channel].transferBytes&0xffff
        return retVal
    def getStatus(self):
        cdef unsigned char status, allTC
        allTC = ( (self.channel[0].getTC()<<3) |
                  (self.channel[1].getTC()<<2) |
                  (self.channel[2].getTC()<<1) |
                   self.channel[3].getTC() )
        status = allTC
        self.deleteTC()
        return status
    def deleteTC(self):
        self.channel[0].setTC(False)
        self.channel[1].setTC(False)
        self.channel[2].setTC(False)
        self.channel[3].setTC(False)


cdef class ISADma:
    cdef public object main
    cdef tuple ioMasterControllerPorts, ioSlaveControllerPorts, controller
    def __init__(self, object main):
        self.main = main
        self.controller = (Controller(self, True), Controller(self, False))
        self.ioMasterControllerPorts = (0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,
                                      0x0d,0x0f,0x81,0x82,0x83,0x87)
        self.ioSlaveControllerPorts = (0x89,0x8a,0x8b,0x8f,0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,
                                      0xd0,0xd2,0xd4,0xd6,0xd8,0xda,0xde)
    def handleTransfer(self, unsigned char channel, bytes data, unsigned char write): # if write==True: read data from ram and write it to device
        cdef unsigned char controller = 0
        if (channel not in (0, 1, 2, 3, 4, 5, 6, 7)):
            self.main.exitError("ISADMA::handleTransfer: invalid channel! (channel: {0:d})", channel)
            return
        if (channel >= 4):
            channel -= 4
            controller = 1
        return self.controller[controller].handleTransfer(channel, data, write)
    def getPageChannelByPort(self, unsigned short ioPortAddr):
        cdef unsigned char channel
        if (ioPortAddr in (0x87, 0x8f)):
            channel = 0
        elif (ioPortAddr in (0x83, 0x8b)):
            channel = 1
        elif (ioPortAddr in (0x81, 0x89)):
            channel = 2
        elif (ioPortAddr in (0x82, 0x8a)):
            channel = 3
        else:
            self.main.exitError("ISADMA::getPageChannelByPort: unknown ioPortAddr: {0:#06x}.", ioPortAddr)
            return
        return channel
    def inPortMaster(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            channelNum = (ioPortAddr&7)//2
            if (ioPortAddr == 0x08):
                return self.controller[0].getStatus()
            elif (ioPortAddr in (0x87, 0x83, 0x81, 0x82)):
                channelNum = self.getPageChannelByPort(ioPortAddr)
                return self.controller[0].getPageByte(channelNum)
            elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06)):
                return self.controller[0].getAddrByte(channelNum)
            elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07)):
                return self.controller[0].getCountByte(channelNum)
            else:
                self.main.printMsg("ISADMA: inPortMaster: dataSize OP_SIZE_BYTE: ioPortAddr not handled. (ioPortAddr: {0:#06x})", ioPortAddr)
        elif (dataSize == OP_SIZE_WORD):
            channelNum = (ioPortAddr&7)//2
            if (ioPortAddr in (0x87, 0x83, 0x81, 0x82)):
                channelNum = self.getPageChannelByPort(ioPortAddr)
                return self.controller[0].getPageByte(channelNum)
            elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06)):
                return self.controller[0].getAddrWord(channelNum)
            elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07)):
                return self.controller[0].getCountWord(channelNum)
            else:
                self.main.printMsg("ISADMA: inPortMaster: dataSize OP_SIZE_WORD: ioPortAddr not handled. (ioPortAddr: {0:#06x})", ioPortAddr)
        else:
            self.main.exitError("ISADMA: inPortMaster: dataSize {0:d} not supported.", dataSize)
        return 0
    def inPortSlave(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            channelNum = (ioPortAddr&7)//2
            if (ioPortAddr == 0xd0):
                return self.controller[1].getStatus()
            elif (ioPortAddr in (0x8f, 0x8b, 0x89, 0x8a)):
                channelNum = self.getPageChannelByPort(ioPortAddr)
                return self.controller[1].getPageByte(channelNum)
            elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06)):
                return self.controller[1].getAddrByte(channelNum)
            elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07)):
                return self.controller[1].getCountByte(channelNum)
            else:
                self.main.printMsg("ISADMA: inPortSlave: dataSize OP_SIZE_BYTE: ioPortAddr not handled. (ioPortAddr: {0:#06x})", ioPortAddr)
        elif (dataSize == OP_SIZE_WORD):
            channelNum = (ioPortAddr&7)//2
            if (ioPortAddr in (0x8f, 0x8b, 0x89, 0x8a)):
                channelNum = self.getPageChannelByPort(ioPortAddr)
                return self.controller[1].getPageByte(channelNum)
            elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06)):
                return self.controller[1].getAddrWord(channelNum)
            elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07)):
                return self.controller[1].getCountWord(channelNum)
            else:
                self.main.printMsg("ISADMA: inPortSlave: dataSize OP_SIZE_WORD: ioPortAddr not handled. (ioPortAddr: {0:#06x})", ioPortAddr)
        else:
            self.main.exitError("ISADMA: inPortSlave: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPortMaster(self, unsigned short ioPortAddr, unsigned short data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            channelNum = (ioPortAddr&7)//2
            if (ioPortAddr == 0x08):
                self.controller[0].doCommand(data&0xff)
            elif (ioPortAddr == 0x0c):
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
                channelNum = self.getPageChannelByPort(ioPortAddr)
                self.controller[0].setPageByte(channelNum, data&0xff)
            elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06)):
                self.controller[0].setAddrByte(channelNum, data&0xff)
            elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07)):
                self.controller[0].setCountByte(channelNum, data&0xff)
            else:
                self.main.printMsg("ISADMA: outPortMaster: dataSize OP_SIZE_BYTE: ioPortAddr not handled. (ioPortAddr: {0:#06x}, data: {1:#04x})", ioPortAddr, data)
        elif (dataSize == OP_SIZE_WORD):
            channelNum = (ioPortAddr&7)//2
            if (ioPortAddr in (0x87, 0x83, 0x81, 0x82)):
                channelNum = self.getPageChannelByPort(ioPortAddr)
                self.controller[0].setPageByte(channelNum, data&0xff)
            elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06)):
                self.controller[0].setAddrWord(channelNum, data&0xffff)
            elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07)):
                self.controller[0].setCountWord(channelNum, data&0xffff)
            else:
                self.main.printMsg("ISADMA: outPortMaster: dataSize OP_SIZE_WORD: ioPortAddr not handled. (ioPortAddr: {0:#06x}, data: {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("ISADMA: outPortMaster: dataSize {0:d} not supported. (ioPortAddr: {1:#06x}, data: {2:#04x})", dataSize, ioPortAddr, data)
        return
    def outPortSlave(self, unsigned short ioPortAddr, unsigned short data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            channelNum = (ioPortAddr&7)//2
            if (ioPortAddr == 0xd0):
                self.controller[1].doCommand(data&0xff)
            elif (ioPortAddr == 0xd8):
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
                channelNum = self.getPageChannelByPort(ioPortAddr)
                self.controller[1].setPageByte(channelNum, data&0xff)
            elif (ioPortAddr in (0xc0, 0xc2, 0xc4, 0xc6)):
                self.controller[1].setAddrByte(channelNum, data&0xff)
            elif (ioPortAddr in (0xc1, 0xc3, 0xc5, 0xc7)):
                self.controller[1].setCountByte(channelNum, data&0xff)
            else:
                self.main.printMsg("ISADMA: outPortSlave: dataSize OP_SIZE_BYTE: ioPortAddr not handled. (ioPortAddr: {0:#06x}, data: {1:#04x})", ioPortAddr, data)
        elif (dataSize == OP_SIZE_WORD):
            channelNum = (ioPortAddr&7)//2
            if (ioPortAddr in (0x8f, 0x8b, 0x89, 0x8a)):
                channelNum = self.getPageChannelByPort(ioPortAddr)
                self.controller[1].setPageByte(channelNum, data&0xff)
            elif (ioPortAddr in (0xc0, 0xc2, 0xc4, 0xc6)):
                self.controller[1].setAddrWord(channelNum, data&0xffff)
            elif (ioPortAddr in (0xc1, 0xc3, 0xc5, 0xc7)):
                self.controller[1].setCountWord(channelNum, data&0xffff)
            else:
                self.main.printMsg("ISADMA: outPortSlave: dataSize OP_SIZE_WORD: ioPortAddr not handled. (ioPortAddr: {0:#06x}, data: {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("ISADMA: outPortSlave: dataSize {0:d} not supported. (ioPortAddr: {1:#06x}, data: {2:#06x})", dataSize, ioPortAddr, data)
        return
    def run(self):
        self.main.platform.addReadHandlers(self.ioMasterControllerPorts, self.inPortMaster)
        self.main.platform.addReadHandlers(self.ioSlaveControllerPorts,  self.inPortSlave)
        self.main.platform.addWriteHandlers(self.ioMasterControllerPorts, self.outPortMaster)
        self.main.platform.addWriteHandlers(self.ioSlaveControllerPorts, self.outPortSlave)


