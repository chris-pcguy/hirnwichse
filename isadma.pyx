

include "globals.pxi"

# This file contains (much) code from the Bochs Emulator (c) by it's developers



cdef class IsaDmaChannel:
    def __init__(self, IsaDmaController controller, unsigned char channelNum):
        self.controller = controller
        self.isadma = self.controller.isadma
        self.main = self.isadma.main
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
    cdef run(self):
        self.dmaMemActionInstance = None
        self.readFromMem = self.writeToMem = NULL

cdef class IsaDmaController:
    def __init__(self, IsaDma isadma, unsigned char master):
        self.master = master
        self.firstChannel = 0
        self.ctrlDisabled = False
        self.cmdReg = 0
        self.statusReg = 0
        if (not self.master):
            self.firstChannel = 4
        self.isadma = isadma
        self.main = self.isadma.main
        self.channel = (IsaDmaChannel(self, self.firstChannel), IsaDmaChannel(self, self.firstChannel+1), IsaDmaChannel(self, self.firstChannel+2), IsaDmaChannel(self, self.firstChannel+3))
    cdef reset(self):
        self.flipFlop = False
    cdef doCommand(self, unsigned char data):
        self.cmdReg = data
        self.ctrlDisabled = (data & DMA_CMD_DISABLE)!=0
        self.controlHRQ()
    cdef doManualRequest(self, unsigned char data):
        cdef unsigned char channel = data & 3
        if ((data & DMA_REQREG_REQUEST) != 0): # set request bit
            self.statusReg |= (1 << (channel+4))
        else: # clear it
            self.statusReg &= ~(1 << (channel+4))
        self.controlHRQ()
    cdef setFlipFlop(self, unsigned char flipFlop):
        self.flipFlop = flipFlop
    cdef setTransferMode(self, unsigned char transferModeByte):
        cdef unsigned char channel = transferModeByte&3
        (<IsaDmaChannel>self.channel[channel]).transferDirection = (transferModeByte>>2)&3
        (<IsaDmaChannel>self.channel[channel]).autoInit = (transferModeByte&0x10)!=0
        (<IsaDmaChannel>self.channel[channel]).addressDecrement = (transferModeByte&0x20)!=0
        (<IsaDmaChannel>self.channel[channel]).transferMode = (transferModeByte>>6)&3
        if ((self.master or (not self.master and channel != 0)) and (<IsaDmaChannel>self.channel[channel]).transferMode != DMA_MODE_SINGLE):
            self.main.exitError("ISADMA::setTransferMode: transferMode: {0:d} not supported yet.", (<IsaDmaChannel>self.channel[channel]).transferMode)
    cdef maskChannel(self, unsigned char channel, unsigned char maskIt):
        (<IsaDmaChannel>self.channel[channel]).channelMasked = (maskIt!=False)
        self.controlHRQ()
    cdef maskChannels(self, unsigned char maskByte):
        (<IsaDmaChannel>self.channel[0]).channelMasked = (maskByte&1)!=0
        (<IsaDmaChannel>self.channel[1]).channelMasked = (maskByte&2)!=0
        (<IsaDmaChannel>self.channel[2]).channelMasked = (maskByte&4)!=0
        (<IsaDmaChannel>self.channel[3]).channelMasked = (maskByte&8)!=0
        self.controlHRQ()
    cdef unsigned char getChannelMasks(self):
        cdef unsigned char retVal
        retVal = ((<IsaDmaChannel>self.channel[0]).channelMasked!=0)
        retVal |= ((<IsaDmaChannel>self.channel[1]).channelMasked!=0)<<1
        retVal |= ((<IsaDmaChannel>self.channel[2]).channelMasked!=0)<<2
        retVal |= ((<IsaDmaChannel>self.channel[3]).channelMasked!=0)<<3
        return retVal
    cdef setPageByte(self, unsigned char channel, unsigned char data):
        (<IsaDmaChannel>self.channel[channel]).page = data
    cdef setAddrByte(self, unsigned char channel, unsigned char data):
        if (self.flipFlop):
            (<IsaDmaChannel>self.channel[channel]).baseAddress = ((<unsigned char>(<IsaDmaChannel>self.channel[channel]).baseAddress) | (data<<8))
            (<IsaDmaChannel>self.channel[channel]).currentAddress = (<IsaDmaChannel>self.channel[channel]).baseAddress
        else:
            (<IsaDmaChannel>self.channel[channel]).baseAddress = ((<IsaDmaChannel>self.channel[channel]).baseAddress&0xff00) | data
            (<IsaDmaChannel>self.channel[channel]).currentAddress = (<IsaDmaChannel>self.channel[channel]).baseAddress
        self.setFlipFlop(not self.flipFlop)
    cdef setCountByte(self, unsigned char channel, unsigned char data):
        if (self.flipFlop):
            (<IsaDmaChannel>self.channel[channel]).baseCount = ((<unsigned char>(<IsaDmaChannel>self.channel[channel]).baseCount) | (data<<8))
            (<IsaDmaChannel>self.channel[channel]).currentCount = (<IsaDmaChannel>self.channel[channel]).baseCount
        else:
            (<IsaDmaChannel>self.channel[channel]).baseCount = ((<IsaDmaChannel>self.channel[channel]).baseCount&0xff00) | data
            (<IsaDmaChannel>self.channel[channel]).currentCount = (<IsaDmaChannel>self.channel[channel]).baseCount
        self.setFlipFlop(not self.flipFlop)
    cdef unsigned char getPageByte(self, unsigned char channel):
        return <unsigned char>((<IsaDmaChannel>self.channel[channel]).page)
    cdef unsigned char getAddrByte(self, unsigned char channel):
        cdef unsigned char retVal
        if (self.flipFlop):
            retVal = <unsigned char>((<IsaDmaChannel>self.channel[channel]).currentAddress>>8)
        else:
            retVal = <unsigned char>((<IsaDmaChannel>self.channel[channel]).currentAddress)
        self.setFlipFlop(not self.flipFlop)
        return retVal
    cdef unsigned char getCountByte(self, unsigned char channel):
        cdef unsigned char retVal
        if (self.flipFlop):
            retVal = <unsigned char>((<IsaDmaChannel>self.channel[channel]).currentCount>>8)
        else:
            retVal = <unsigned char>((<IsaDmaChannel>self.channel[channel]).currentCount)
        self.setFlipFlop(not self.flipFlop)
        return retVal
    cdef setAddrWord(self, unsigned char channel, unsigned short data):
        (<IsaDmaChannel>self.channel[channel]).baseAddress = data
        (<IsaDmaChannel>self.channel[channel]).currentAddress = data
    cdef setCountWord(self, unsigned char channel, unsigned short data):
        (<IsaDmaChannel>self.channel[channel]).baseCount = data
        (<IsaDmaChannel>self.channel[channel]).currentCount = (<IsaDmaChannel>self.channel[channel]).baseCount
    cdef unsigned short getAddrWord(self, unsigned char channel):
        return (<IsaDmaChannel>self.channel[channel]).currentAddress
    cdef unsigned short getCountWord(self, unsigned char channel):
        return (<IsaDmaChannel>self.channel[channel]).currentCount
    cdef unsigned char getStatus(self):
        cdef unsigned char status
        status = self.statusReg
        self.statusReg &= 0xf0
        return status
    cdef controlHRQ(self):
        cdef unsigned char channel
        if (self.ctrlDisabled):
            return
        if ((self.statusReg & 0xf0) == 0):
            if (not self.master):
                if (self.isadma.cpuInstance is not None and self.isadma.setHRQ is not NULL):
                    self.isadma.setHRQ(self.isadma.cpuInstance, False)
            else:
                self.isadma.setDRQ(4, False)
            return
        for channel in range(4):
            if ((self.statusReg & (1 << (channel+4))) and (not (<IsaDmaChannel>self.channel[channel]).channelMasked)):
                if (not self.master):
                    if (self.isadma.cpuInstance is not None and self.isadma.setHRQ is not NULL):
                        self.isadma.setHRQ(self.isadma.cpuInstance, True)
                else:
                    self.isadma.setDRQ(4, True)
                return
    cdef run(self):
        cdef IsaDmaChannel isaDmaChannel
        for isaDmaChannel in self.channel:
            isaDmaChannel.run()
        self.reset()

cdef class IsaDma:
    def __init__(self, object main):
        self.main = main
        self.controller = (IsaDmaController(self, True), IsaDmaController(self, False))
        self.HLDA = self.TC = False
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char ma_sl, channelNum
        ma_sl = (ioPortAddr>=0xc0)
        channelNum = (ioPortAddr>>(1+ma_sl))&3
        if (ioPortAddr in (0x00, 0x02, 0x04, 0x06, 0xc0, 0xc4, 0xc8, 0xcc)):
            if (dataSize == OP_SIZE_BYTE):
                return (<IsaDmaController>self.controller[ma_sl]).getAddrByte(channelNum)
            elif (dataSize == OP_SIZE_WORD):
                return (<IsaDmaController>self.controller[ma_sl]).getAddrWord(channelNum)
            else:
                self.main.exitError("ISADma::inPort: unknown dataSize. (ioPortAddr: {0:#06x}, dataSize: {1:d})", ioPortAddr, dataSize)
        elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07, 0xc2, 0xc6, 0xca, 0xce)):
            if (dataSize == OP_SIZE_BYTE):
                return (<IsaDmaController>self.controller[ma_sl]).getCountByte(channelNum)
            elif (dataSize == OP_SIZE_WORD):
                return (<IsaDmaController>self.controller[ma_sl]).getCountWord(channelNum)
            else:
                self.main.exitError("ISADma::inPort: unknown dataSize. (ioPortAddr: {0:#06x}, dataSize: {1:d})", ioPortAddr, dataSize)
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x08,0xd0)):
            return (<IsaDmaController>self.controller[ma_sl]).getStatus()
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x0d,0xda)):
            return 0
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x0f,0xde)):
            return (0xf0 | (<IsaDmaController>self.controller[ma_sl]).getChannelMasks())
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x81, 0x82, 0x83, 0x87)):
            channelNum = DMA_CHANNEL_INDEX[ioPortAddr - 0x81]
            return (<IsaDmaController>self.controller[0]).getPageByte(channelNum)
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x89, 0x8a, 0x8b, 0x8f)):
            channelNum = DMA_CHANNEL_INDEX[ioPortAddr - 0x89]
            return (<IsaDmaController>self.controller[1]).getPageByte(channelNum)
        elif (ioPortAddr in DMA_EXT_PAGE_REG_PORTS):
            return <unsigned char>self.extPageReg[ioPortAddr&0xf]
        else:
            self.main.exitError("ISADma::inPort: unknown ioPortAddr. (ioPortAddr: {0:#06x}, dataSize: {1:d})", ioPortAddr, dataSize)
        return 0
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
        cdef unsigned char ma_sl, channelNum
        ma_sl = (ioPortAddr>=0xc0)
        channelNum = (ioPortAddr>>(1+ma_sl))&3
        if (dataSize == OP_SIZE_WORD and ioPortAddr == 0x0b):
            self.outPort(ioPortAddr, <unsigned char>data, OP_SIZE_BYTE)
            self.outPort(ioPortAddr+1, <unsigned char>(data>>8), OP_SIZE_BYTE)
            return
        elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06, 0xc0, 0xc4, 0xc8, 0xcc)):
            if (dataSize == OP_SIZE_BYTE):
                (<IsaDmaController>self.controller[ma_sl]).setAddrByte(channelNum, <unsigned char>data)
            elif (dataSize == OP_SIZE_WORD):
                (<IsaDmaController>self.controller[ma_sl]).setAddrWord(channelNum, data)
            else:
                self.main.exitError("ISADma::outPort: unknown dataSize. (ioPortAddr: {0:#06x}, data: {1:#06x}, dataSize: {2:d})", ioPortAddr, data, dataSize)
        elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07, 0xc2, 0xc6, 0xca, 0xce)):
            if (dataSize == OP_SIZE_BYTE):
                (<IsaDmaController>self.controller[ma_sl]).setCountByte(channelNum, <unsigned char>data)
            elif (dataSize == OP_SIZE_WORD):
                (<IsaDmaController>self.controller[ma_sl]).setCountWord(channelNum, data)
            else:
                self.main.exitError("ISADma::outPort: unknown dataSize. (ioPortAddr: {0:#06x}, data: {1:#06x}, dataSize: {2:d})", ioPortAddr, data, dataSize)
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x08, 0xd0)):
            (<IsaDmaController>self.controller[ma_sl]).doCommand(<unsigned char>data)
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x09, 0xd2)):
            (<IsaDmaController>self.controller[ma_sl]).doManualRequest(<unsigned char>data)
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x0a, 0xd4)):
            (<IsaDmaController>self.controller[ma_sl]).maskChannel(data&3, data&4)
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x0b, 0xd6)):
            (<IsaDmaController>self.controller[ma_sl]).setTransferMode(<unsigned char>data)
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x0c, 0xd8)):
            (<IsaDmaController>self.controller[ma_sl]).setFlipFlop(False)
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x0d, 0xda)):
            (<IsaDmaController>self.controller[ma_sl]).reset()
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x0e, 0xdc)): # clear all mask registers
            (<IsaDmaController>self.controller[ma_sl]).maskChannels(0)
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x0f, 0xde)):
            (<IsaDmaController>self.controller[ma_sl]).maskChannels(<unsigned char>data)
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x81, 0x82, 0x83, 0x87)):
            channelNum = DMA_CHANNEL_INDEX[ioPortAddr - 0x81]
            (<IsaDmaController>self.controller[0]).setPageByte(channelNum, <unsigned char>data)
        elif (dataSize == OP_SIZE_BYTE and ioPortAddr in (0x89, 0x8a, 0x8b, 0x8f)):
            channelNum = DMA_CHANNEL_INDEX[ioPortAddr - 0x89]
            (<IsaDmaController>self.controller[1]).setPageByte(channelNum, <unsigned char>data)
        elif (ioPortAddr in DMA_EXT_PAGE_REG_PORTS):
            self.extPageReg[ioPortAddr&0xf] = <unsigned char>data
        else:
            self.main.exitError("ISADma::outPort: unknown ioPortAddr. (ioPortAddr: {0:#06x}, data: {1:#06x}, dataSize: {2:d})", ioPortAddr, data, dataSize)
    cdef getTC(self):
        return self.TC
    cdef setDRQ(self, unsigned char channel, unsigned char val):
        cdef unsigned long dmaBase, dmaRoof
        cdef unsigned char ma_sl
        cdef IsaDmaController currController
        cdef IsaDmaChannel currChannel
        if (channel > 7):
            self.main.exitError("ISADMA::setDRQ: channel > 7")
            return
        ma_sl = (channel > 3)
        currController = (<IsaDmaController>self.controller[ma_sl])
        currChannel = (<IsaDmaChannel>currController.channel[channel&3])
        currChannel.DRQ = val
        channel &= 3
        if (not val):
            currController.statusReg &= ~(1 << (channel+4))
            currController.controlHRQ()
            return
        currController.statusReg |= (1 << (channel+4))
        if (currChannel.transferMode not in (DMA_MODE_DEMAND, DMA_MODE_SINGLE, DMA_MODE_CASCADE)):
            self.main.exitError("ISADMA::setDRQ: transferMode {0:d} not handled.", currChannel.transferMode)
            return
        dmaBase = ((currChannel.page << 16) | (currChannel.baseAddress << ma_sl))
        if (not currChannel.addressDecrement):
            dmaRoof = dmaBase + (currChannel.baseCount << ma_sl)
        else:
            dmaRoof = dmaBase - (currChannel.baseCount << ma_sl)
        if ( (dmaBase & (0x7fff0000 << ma_sl)) != (dmaRoof & (0x7fff0000 << ma_sl))):
            self.main.exitError("ISADMA::setDRQ: request outside 64k boundary.")
            return
        currController.controlHRQ()
    cdef raiseHLDA(self):
        cdef unsigned char ma_sl, channel, countExpired, i
        cdef unsigned short data
        cdef unsigned long phyAddr
        cdef IsaDmaController currController
        cdef IsaDmaChannel currChannel
        ma_sl = channel = countExpired = 0
        self.HLDA = True
        for i in range(4):
            if (((<IsaDmaController>self.controller[1]).statusReg & (1 << (channel+4))) and \
                (not (<IsaDmaChannel>(<IsaDmaController>self.controller[1]).channel[channel]).channelMasked)):
                    ma_sl = True
                    break
            channel = i
        if (channel == 0):
            (<IsaDmaChannel>(<IsaDmaController>self.controller[1]).channel[0]).DACK = True
            for i in range(4):
                if (((<IsaDmaController>self.controller[0]).statusReg & (1 << (channel+4))) and \
                    (not (<IsaDmaChannel>(<IsaDmaController>self.controller[0]).channel[channel]).channelMasked)):
                        ma_sl = False
                        break
                channel = i
        if (channel >= 4):
            return
        currController = (<IsaDmaController>self.controller[ma_sl])
        currChannel = (<IsaDmaChannel>currController.channel[channel])
        phyAddr = ((currChannel.page << 16) | \
                   (currChannel.currentAddress << ma_sl))
        (<IsaDmaChannel>(<IsaDmaController>self.controller[ma_sl]).channel[channel]).DACK = True
        if (currChannel.addressDecrement):
            currChannel.currentAddress = <unsigned short>(currChannel.currentAddress-1)
        else:
            currChannel.currentAddress = <unsigned short>(currChannel.currentAddress+1)
        currChannel.currentCount = <unsigned short>(currChannel.currentCount-1)
        if (currChannel.currentCount == BITMASK_WORD):
            currController.statusReg |= (1 << channel)
            self.TC = True
            countExpired = True
            if (not currChannel.autoInit):
                currChannel.channelMasked = True
            else:
                currChannel.currentAddress = currChannel.baseAddress
                currChannel.currentCount = currChannel.baseCount

        if (currChannel.transferDirection == 1): # IODEV -> MEM
            if (currChannel.dmaMemActionInstance is not None and currChannel.writeToMem is not NULL):
                data = <unsigned short>currChannel.writeToMem(currChannel.dmaMemActionInstance)
            else:
                self.main.exitError("ISADMA::raiseHLDA: no dmaWrite handler for channel {0:d}", channel)
                return
            if (not ma_sl):
                data = <unsigned char>data
            (<Mm>self.main.mm).mmPhyWriteValue(phyAddr, data, ma_sl+1)
        elif (currChannel.transferDirection == 2): # MEM -> IODEV
            data = (<Mm>self.main.mm).mmPhyReadValueUnsigned(phyAddr, ma_sl+1)
            if (currChannel.dmaMemActionInstance is not None and currChannel.readFromMem is not NULL):
                currChannel.readFromMem(currChannel.dmaMemActionInstance, data)
            else:
                self.main.exitError("ISADMA::raiseHLDA: no dmaRead handler for channel {0:d}", channel)
                return
        elif (currChannel.transferDirection == 0): # Verify
            if (currChannel.dmaMemActionInstance is not None and currChannel.writeToMem is not NULL):
                data = <unsigned short>currChannel.writeToMem(currChannel.dmaMemActionInstance)
            else:
                self.main.exitError("ISADMA::raiseHLDA: no dmaWrite handler for channel {0:d}", channel)
                return
        else:
            self.main.exitError("ISADMA::raiseHLDA: transferDirection 3 is unknown.")
            return

        if (countExpired):
            self.TC = False
            self.HLDA = False
            if (self.cpuInstance is not None and self.setHRQ is not NULL):
                self.setHRQ(self.cpuInstance, False)
            (<IsaDmaChannel>(<IsaDmaController>self.controller[ma_sl]).channel[channel]).DACK = False
            if (not ma_sl):
                self.setDRQ(4, False)
                (<IsaDmaChannel>(<IsaDmaController>self.controller[1]).channel[0]).DACK = False
    cdef setDmaMemActions(self, unsigned char controllerId, unsigned char channelId, object classInstance, ReadFromMem readFromMem, WriteToMem writeToMem):
        cdef IsaDmaController controller
        cdef IsaDmaChannel channel
        controller = (<IsaDmaController>self.controller[controllerId])
        channel = (<IsaDmaChannel>controller.channel[channelId])
        channel.dmaMemActionInstance = classInstance
        channel.readFromMem = readFromMem
        channel.writeToMem = writeToMem
    cdef run(self):
        cdef IsaDmaController controller
        self.cpuInstance = None
        self.setHRQ = NULL
        memset(self.extPageReg, 0, 16)
        for controller in self.controller:
            controller.run()
        #self.main.platform.addHandlers(DMA_MASTER_CONTROLLER_PORTS, self)
        #self.main.platform.addHandlers(DMA_SLAVE_CONTROLLER_PORTS, self)
        #self.main.platform.addHandlers(DMA_EXT_PAGE_REG_PORTS, self)


