
include "globals.pxi"


DEF CONTROLLER_MASTER = 0
DEF CONTROLLER_SLAVE  = 1


DEF DMA_MODE_DEMAND = 0
DEF DMA_MODE_SINGLE = 1
DEF DMA_MODE_BLOCK = 2
DEF DMA_MODE_CASCADE = 3

DEF DMA_REQREG_REQUEST = 0x4
DEF DMA_CMD_DISABLE = 0x4

cpdef tuple DMA_CHANNEL_INDEX = (2, 3, 1, 0, 0, 0, 0)

cdef class Channel:
    cpdef public object controller, isadma, main, dmaReadFromMem, dmaWriteToMem
    cdef public unsigned char channelMasked, transferDirection, autoInit, addressDecrement, transferMode, page, DRQ, DACK
    cdef public short baseAddress, baseCount, currentAddress, currentCount
    cdef unsigned char channelNum
    def __init__(self, object controller, unsigned char channelNum):
        self.controller = controller
        self.isadma = self.controller.isadma
        self.main = self.isadma.main
        self.dmaReadFromMem = self.dmaWriteToMem = None
        self.channelNum = channelNum
        self.channelMasked = True
        self.page = 0
        self.baseAddress = self.baseCount = self.currentAddress = self.currentCount = 0 
        self.transferDirection = 3
        self.autoInit = False
        self.addressDecrement = 0 # if True, address-count, then data[::-1]
        self.transferMode = 0
        self.DRQ = False
        self.DACK = False
    ###

cdef class Controller:
    cpdef public object isadma, main
    cpdef public tuple channel
    cpdef unsigned char flipFlop, firstChannel, master, ctrlDisabled, cmdReg
    cpdef public unsigned char statusReg
    def __init__(self, object isadma, unsigned char master):
        self.master = master
        self.firstChannel = 0
        self.ctrlDisabled = False
        self.cmdReg = 0
        self.statusReg = 0
        if (not self.master):
            self.firstChannel = 4
        self.isadma = isadma
        self.main = self.isadma.main
        self.channel = (Channel(self, self.firstChannel), Channel(self, self.firstChannel+1), Channel(self, self.firstChannel+2), Channel(self, self.firstChannel+3))
    cpdef reset(self):
        self.flipFlop = False
    cpdef doCommand(self, unsigned char data):
        self.cmdReg = data
        self.ctrlDisabled = (data & DMA_CMD_DISABLE)!=0
        self.controlHRQ()
    cpdef doManualRequest(self, unsigned char data):
        cdef unsigned char channel = data & 3
        if ((data & DMA_REQREG_REQUEST) != 0): # set request bit
            self.statusReg |= (1 << (channel+4))
        else: # clear it
            self.statusReg &= ~(1 << (channel+4))
        self.controlHRQ()
    cpdef setFlipFlop(self, unsigned char flipFlop):
        self.flipFlop = flipFlop
    cpdef setTransferMode(self, unsigned char transferModeByte):
        cdef unsigned char channel = transferModeByte&3
        self.channel[channel].transferDirection = (transferModeByte>>2)&3
        self.channel[channel].autoInit = (transferModeByte&0x10)!=0
        self.channel[channel].addressDecrement = (transferModeByte&0x20)!=0
        self.channel[channel].transferMode = (transferModeByte>>6)&3
        if ((self.master or (not self.master and channel != 0)) and self.channel[channel].transferMode != DMA_MODE_SINGLE):
            self.main.exitError("ISADMA::setTransferMode: transferMode: {0:d} not supported yet.", self.channel[channel].transferMode)
    cpdef maskChannel(self, unsigned char channel, unsigned char maskIt):
        self.channel[channel].channelMasked = (maskIt!=False)
        self.controlHRQ()
    cpdef maskChannels(self, unsigned char maskByte):
        self.channel[0].channelMasked = (maskByte&1)!=0
        self.channel[1].channelMasked = (maskByte&2)!=0
        self.channel[2].channelMasked = (maskByte&4)!=0
        self.channel[3].channelMasked = (maskByte&8)!=0
        self.controlHRQ()
    cpdef getChannelMasks(self):
        cdef unsigned char retVal
        retVal = (self.channel[0].channelMasked!=0)
        retVal |= (self.channel[1].channelMasked!=0)<<1
        retVal |= (self.channel[2].channelMasked!=0)<<2
        retVal |= (self.channel[3].channelMasked!=0)<<3
        return retVal
    cpdef setPageByte(self, unsigned char channel, unsigned char data):
        self.channel[channel].page = data
    cpdef setAddrByte(self, unsigned char channel, unsigned char data):
        if (self.flipFlop):
            self.channel[channel].baseAddress = (self.channel[channel].baseAddress&0xff) | ( data<<8)
            self.channel[channel].currentAddress = self.channel[channel].baseAddress
        else:
            self.channel[channel].baseAddress = (self.channel[channel].baseAddress&0xff00) | data
            self.channel[channel].currentAddress = self.channel[channel].baseAddress
        self.setFlipFlop(not self.flipFlop)
    cpdef setCountByte(self, unsigned char channel, unsigned char data):
        if (self.flipFlop):
            self.channel[channel].baseCount = (self.channel[channel].baseCount&0xff) | (data<<8)
            self.channel[channel].currentCount = self.channel[channel].baseCount
        else:
            self.channel[channel].baseCount = (self.channel[channel].baseCount&0xff00) | data
            self.channel[channel].currentCount = self.channel[channel].baseCount
        self.setFlipFlop(not self.flipFlop)
    cpdef getPageByte(self, unsigned char channel):
        return self.channel[channel].page&0xff
    cpdef getAddrByte(self, unsigned char channel):
        cdef unsigned char retVal
        if (self.flipFlop):
            retVal = (self.channel[channel].currentAddress>>8)&0xff
        else:
            retVal = self.channel[channel].currentAddress&0xff
        self.setFlipFlop(not self.flipFlop)
        return retVal
    cpdef getCountByte(self, unsigned char channel):
        cdef unsigned char retVal
        if (self.flipFlop):
            retVal = (self.channel[channel].currentCount>>8)&0xff
        else:
            retVal = self.channel[channel].currentCount&0xff
        self.setFlipFlop(not self.flipFlop)
        return retVal
    cpdef setAddrWord(self, unsigned char channel, unsigned short data):
        self.channel[channel].baseAddress = data
        self.channel[channel].currentAddress = self.channel[channel].baseAddress
    cpdef setCountWord(self, unsigned char channel, unsigned short data):
        self.channel[channel].baseCount = data
        self.channel[channel].currentCount = self.channel[channel].baseCount
    cpdef getAddrWord(self, unsigned char channel):
        cdef unsigned short retVal
        retVal = self.channel[channel].currentAddress&0xffff
        return retVal
    cpdef getCountWord(self, unsigned char channel):
        cdef unsigned short retVal
        retVal = self.channel[channel].currentCount&0xffff
        return retVal
    cpdef getStatus(self):
        cdef unsigned char status
        status = self.statusReg
        self.statusReg &= 0xf0
        return status
    cpdef controlHRQ(self):
        if (self.ctrlDisabled):
            return
        if ((self.statusReg & 0xf0) == 0):
            if (not self.master):
                self.main.cpu.setHRQ(False)
            else:
                self.isadma.setDRQ(4, False)
            return
        for channel in range(4):
            if ((self.statusReg & (1 << (channel+4))) and (not self.channel[channel].channelMasked)):
                if (not self.master):
                    self.main.cpu.setHRQ(True)
                else:
                    self.isadma.setDRQ(4, True)
                return
    cpdef run(self):
        self.reset()

cdef class ISADma:
    cpdef public object main
    cpdef public tuple controller
    cpdef tuple ioMasterControllerPorts, ioSlaveControllerPorts, extPageRegPorts
    cpdef list extPageReg # extPageReg is unused.
    cpdef unsigned char HLDA, TC
    def __init__(self, object main):
        self.main = main
        self.controller = (Controller(self, True), Controller(self, False))
        self.ioMasterControllerPorts = (0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,
                                      0x0d,0xe,0x0f,0x81,0x82,0x83,0x87)
        self.ioSlaveControllerPorts = (0x89,0x8a,0x8b,0x8f,0xc0,0xc1,0xc2,0xc3,0xc4,0xc5,0xc6,0xc7,
                                      0xd0,0xd2,0xd4,0xd6,0xd8,0xda,0xdc,0xde)
        self.extPageRegPorts = (0x80, 0x84, 0x85, 0x86, 0x88, 0x8c, 0x8d, 0x8e)
        self.extPageReg = [0]*16
        self.HLDA = self.TC = False
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char ma_sl, channelNum
        ma_sl = (ioPortAddr>=0xc0)
        channelNum = (ioPortAddr>>(1+ma_sl))&3
        if (dataSize != OP_SIZE_BYTE):
            self.main.exitError("ISADma::inPort: invalid dataSize. (ioPortAddr: {0:#06x}, dataSize: {1:d})", ioPortAddr, dataSize)
        elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06, 0xc0, 0xc4, 0xc8, 0xcc)):
            return self.controller[ma_sl].getAddrByte(channelNum)
        elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07, 0xc2, 0xc6, 0xca, 0xce)):
            return self.controller[ma_sl].getCountByte(channelNum)
        elif (ioPortAddr in (0x08,0xd0)):
            return self.controller[ma_sl].getStatus()
        elif (ioPortAddr in (0x0d,0xda)):
            return 0
        elif (ioPortAddr in (0x0f,0xde)):
            return (0xf0 | self.controller[ma_sl].getChannelMasks())
        elif (ioPortAddr in (0x81, 0x82, 0x83, 0x87)):
            channelNum = DMA_CHANNEL_INDEX[ioPortAddr - 0x81]
            return self.controller[0].getPageByte(channelNum)
        elif (ioPortAddr in (0x89, 0x8a, 0x8b, 0x8f)):
            channelNum = DMA_CHANNEL_INDEX[ioPortAddr - 0x89]
            return self.controller[1].getPageByte(channelNum)
        elif (ioPortAddr in self.extPageRegPorts):
            return self.extPageReg[ioPortAddr&0xf]
        else:
            self.main.exitError("ISADma::inPort: unknown ioPortAddr. (ioPortAddr: {0:#06x}, dataSize: {1:d})", ioPortAddr, dataSize)
        return 0
    cpdef outPort(self, unsigned short ioPortAddr, unsigned short data, unsigned char dataSize):
        cdef unsigned char ma_sl, channelNum
        ma_sl = (ioPortAddr>=0xc0)
        channelNum = (ioPortAddr>>(1+ma_sl))&3
        if (dataSize != OP_SIZE_BYTE):
            if (ioPortAddr == 0x0b and dataSize == OP_SIZE_WORD):
                self.outPort(ioPortAddr, data&0xff, OP_SIZE_BYTE)
                self.outPort(ioPortAddr+1, (data>>8)&0xff, OP_SIZE_BYTE)
                return
            else:
                self.main.exitError("ISADma::outPort: unknown dataSize. (ioPortAddr: {0:#06x}, data: {1:#06x}, dataSize: {2:d})", ioPortAddr, data, dataSize)
        elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06, 0xc0, 0xc4, 0xc8, 0xcc)):
            self.controller[ma_sl].setAddrByte(channelNum, data&0xff)
        elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07, 0xc2, 0xc6, 0xca, 0xce)):
            self.controller[ma_sl].setCountByte(channelNum, data&0xff)
        elif (ioPortAddr in (0x08, 0xd0)):
            self.controller[ma_sl].doCommand(data&0xff)
        elif (ioPortAddr in (0x09, 0xd2)):
            self.controller[ma_sl].doManualRequest(data&0xff)
        elif (ioPortAddr in (0x0a, 0xd4)):
            self.controller[ma_sl].maskChannel(data&3, data&4)
        elif (ioPortAddr in (0x0b, 0xd6)):
            self.controller[ma_sl].setTransferMode(data&0xff)
        elif (ioPortAddr in (0x0c, 0xd8)):
            self.controller[ma_sl].setFlipFlop(False)
        elif (ioPortAddr in (0x0d, 0xda)):
            self.controller[ma_sl].reset()
        elif (ioPortAddr in (0x0e, 0xdc)): # clear all mask registers
            self.controller[ma_sl].maskChannels(0)
        elif (ioPortAddr in (0x0f, 0xde)):
            self.controller[ma_sl].maskChannels(data&0xff)
        elif (ioPortAddr in (0x81, 0x82, 0x83, 0x87)):
            channelNum = DMA_CHANNEL_INDEX[ioPortAddr - 0x81]
            self.controller[0].setPageByte(channelNum, data&0xff)
        elif (ioPortAddr in (0x89, 0x8a, 0x8b, 0x8f)):
            channelNum = DMA_CHANNEL_INDEX[ioPortAddr - 0x89]
            self.controller[1].setPageByte(channelNum, data&0xff)
        elif (ioPortAddr in self.extPageRegPorts):
            self.extPageReg[ioPortAddr&0xf] = data&0xff
        else:
            self.main.exitError("ISADma::outPort: unknown ioPortAddr. (ioPortAddr: {0:#06x}, data: {1:#06x}, dataSize: {2:d})", ioPortAddr, data, dataSize)
    cpdef setDRQ(self, unsigned char channel, unsigned char val):
        cdef unsigned long dmaBase, dmaRoof, ma_sl
        cpdef object currController, currChannel
        if (channel > 7):
            self.main.exitError("ISADMA::setDRQ: channel > 7")
            return
        ma_sl = (channel > 3)
        currController = self.controller[ma_sl]
        currChannel = currController.channel[channel&3]
        currChannel.DRQ = val
        channel &= 3
        if (not val):
            currController.statusReg &= ~(1 << (channel+4))
            currController.controlHRQ()
            return
        currController.statusReg |= (1 << (channel+4))
        if (currChannel.transferMode == DMA_MODE_BLOCK):
            self.main.exitError("ISADMA::setDRQ: transferMode DMA_MODE_BLOCK not handled.")
            return
        dmaBase = ((currChannel.page << 16) | (currChannel.baseAddress << (not self.master)))
        if (currChannel.addressDecrement):
            dmaRoof = dmaBase - (currChannel.baseCount << (not self.master))
        else:
            dmaRoof = dmaBase + (currChannel.baseCount << (not self.master))
        if ( (dmaBase & (0x7fff0000 << (not self.master))) != (dmaRoof & (0x7fff0000 << (not self.master)))):
            self.main.exitError("ISADMA::setDRQ: request outside 64k boundary.")
            return
        currController.controlHRQ()
    cpdef raiseHLDA(self):
        cdef unsigned char ma_sl, channel, countExpired, data
        cdef unsigned long phyAddr
        cpdef object currController, currChannel
        ma_sl = channel = countExpired = 0
        self.HLDA = True
        for i in range(4):
            if ((self.controller[1].statusReg & (1 << (channel+4))) and \
                (not self.controller[1].channel[channel].channelMasked)):
                    ma_sl = 1
                    break
            channel = i
        if (channel == 0):
            self.controller[1].channel[0].DACK = True
            for i in range(4):
                if ((self.controller[0].statusReg & (1 << (channel+4))) and \
                    (not self.controller[0].channel[channel].channelMasked)):
                        ma_sl = 0
                        break
                channel = i
        if (channel >= 4):
            return
        currController = self.controller[ma_sl]
        currChannel = currController.channel[channel]
        phyAddr = ((currChannel.page << 16) | \
                   (currChannel.currentAddress << ma_sl))
        self.controller[ma_sl].channel[channel].DACK = True
        if (currChannel.addressDecrement):
            currChannel.currentAddress -= 1
        else:
            currChannel.currentAddress += 1
        if (currChannel.currentCount == 0): # TODO: HACK: cython won't allow unsigned overflow
            currChannel.currentCount = 0xffff
        else:
            currChannel.currentCount -= 1
        if (currChannel.currentCount == 0xffff):
            currController.statusReg |= (1 << channel)
            self.TC = True
            countExpired = True
            if (not currChannel.autoInit):
                currChannel.channelMasked = True
            else:
                currChannel.currentAddress = currChannel.baseAddress
                currChannel.currentCount = currChannel.baseCount
        
        if (currChannel.transferDirection == 1): # IODEV -> MEM
            if (currChannel.dmaWriteToMem != None):
                currChannel.dmaWriteToMem(&data)
            else:
                self.main.exitError("ISADMA::raiseHLDA: no dmaWrite handler for channel {0:d}", channel)
                return
            data &= 0xff # TODO: is this correct?
            self.main.mm.mmPhyWriteValue(phyAddr, data, ma_sl+1)
        elif (currChannel.transferDirection == 2): # MEM -> IODEV
            data = self.main.mm.mmPhyReadValue(phyAddr, ma_sl+1, False)&0xff
            if (currChannel.dmaReadFromMem != None):
                currChannel.dmaReadFromMem(&data)
            else: # TODO: is this correct?
                self.main.exitError("ISADMA::raiseHLDA: no dmaRead handler for channel {0:d}", channel)
                return
        elif (currChannel.transferDirection == 0): # Verify
            if (currChannel.dmaWriteToMem != None):
                currChannel.dmaWriteToMem(&data)
            else:
                self.main.exitError("ISADMA::raiseHLDA: no dmaWrite handler for channel {0:d}", channel)
                return
        else:
            self.main.exitError("ISADMA::raiseHLDA: transferDirection 3 is unknown.")
            return
        
        if (countExpired):
            self.TC = False
            self.HLDA = False
            self.main.cpu.setHRQ(False)
            self.controller[ma_sl].channel[channel].DACK = False
            if (not ma_sl):
                self.setDRQ(4, False)
                self.controller[1].channel[0].DACK = False
    cpdef run(self):
        for controller in self.controller:
            controller.run()
        self.main.platform.addReadHandlers(self.ioMasterControllerPorts, self)
        self.main.platform.addReadHandlers(self.ioSlaveControllerPorts, self)
        self.main.platform.addReadHandlers(self.extPageRegPorts, self)
        self.main.platform.addWriteHandlers(self.ioMasterControllerPorts, self)
        self.main.platform.addWriteHandlers(self.ioSlaveControllerPorts, self)
        self.main.platform.addWriteHandlers(self.extPageRegPorts, self)


