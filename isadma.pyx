
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

# This file contains (much) code from the Bochs Emulator (c) by it's developers

include "globals.pxi"


DEF DMA_MODE_DEMAND = 0
DEF DMA_MODE_SINGLE = 1
DEF DMA_MODE_BLOCK = 2
DEF DMA_MODE_CASCADE = 3

DEF DMA_REQREG_REQUEST = 0x4
DEF DMA_CMD_DISABLE = 0x4

cdef uint8_t[7] DMA_CHANNEL_INDEX = (2, 3, 1, 0, 0, 0, 0)



cdef class IsaDmaChannel:
    def __init__(self, IsaDmaController controller, uint8_t channelNum):
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
    cdef void run(self) nogil:
        with gil:
            self.dmaMemActionInstance = None
        self.readFromMem = self.writeToMem = NULL

cdef class IsaDmaController:
    def __init__(self, IsaDma isadma, uint8_t master):
        cdef IsaDmaChannel channel0, channel1, channel2, channel3
        self.master = master
        self.firstChannel = 0
        self.ctrlDisabled = False
        self.cmdReg = 0
        self.statusReg = 0
        if (not self.master):
            self.firstChannel = 4
        self.isadma = isadma
        self.main = self.isadma.main
        channel0 = IsaDmaChannel(self, self.firstChannel)
        channel1 = IsaDmaChannel(self, self.firstChannel+1)
        channel2 = IsaDmaChannel(self, self.firstChannel+2)
        channel3 = IsaDmaChannel(self, self.firstChannel+3)
        self.channel[0] = <PyObject*>channel0
        self.channel[1] = <PyObject*>channel1
        self.channel[2] = <PyObject*>channel2
        self.channel[3] = <PyObject*>channel3
        Py_INCREF(channel0)
        Py_INCREF(channel1)
        Py_INCREF(channel2)
        Py_INCREF(channel3)
    cdef void reset(self) nogil:
        self.flipFlop = False
    cdef void doCommand(self, uint8_t data) nogil:
        self.cmdReg = data
        self.ctrlDisabled = (data & DMA_CMD_DISABLE)!=0
        self.controlHRQ()
    cdef void doManualRequest(self, uint8_t data) nogil:
        cdef uint8_t channel = data & 3
        if ((data & DMA_REQREG_REQUEST) != 0): # set request bit
            self.statusReg |= (1 << (channel+4))
        else: # clear it
            self.statusReg &= ~(1 << (channel+4))
        self.controlHRQ()
    cdef void setFlipFlop(self, uint8_t flipFlop) nogil:
        self.flipFlop = flipFlop
    cdef void setTransferMode(self, uint8_t transferModeByte) nogil:
        cdef uint8_t channel = transferModeByte&3
        (<IsaDmaChannel>self.channel[channel]).transferDirection = (transferModeByte>>2)&3
        (<IsaDmaChannel>self.channel[channel]).autoInit = (transferModeByte&0x10)!=0
        (<IsaDmaChannel>self.channel[channel]).addressDecrement = (transferModeByte&0x20)!=0
        (<IsaDmaChannel>self.channel[channel]).transferMode = (transferModeByte>>6)&3
        if ((transferModeByte&0x20)!=0):
            with gil:
                self.main.notice("IsaDmaController::setTransferMode: maybe TODO: addressDecrement is set.")
        if ((self.master or (not self.master and channel != 0)) and (<IsaDmaChannel>self.channel[channel]).transferMode != DMA_MODE_SINGLE):
            with gil:
                self.main.exitError("ISADMA::setTransferMode: transferMode: {0:d} not supported yet.", (<IsaDmaChannel>self.channel[channel]).transferMode)
    cdef void maskChannel(self, uint8_t channel, uint8_t maskIt) nogil:
        (<IsaDmaChannel>self.channel[channel]).channelMasked = (maskIt!=False)
        self.controlHRQ()
    cdef void maskChannels(self, uint8_t maskByte) nogil:
        (<IsaDmaChannel>self.channel[0]).channelMasked = (maskByte&1)!=0
        (<IsaDmaChannel>self.channel[1]).channelMasked = (maskByte&2)!=0
        (<IsaDmaChannel>self.channel[2]).channelMasked = (maskByte&4)!=0
        (<IsaDmaChannel>self.channel[3]).channelMasked = (maskByte&8)!=0
        self.controlHRQ()
    cdef uint8_t getChannelMasks(self) nogil:
        cdef uint8_t retVal
        retVal = ((<IsaDmaChannel>self.channel[0]).channelMasked!=0)
        retVal |= ((<IsaDmaChannel>self.channel[1]).channelMasked!=0)<<1
        retVal |= ((<IsaDmaChannel>self.channel[2]).channelMasked!=0)<<2
        retVal |= ((<IsaDmaChannel>self.channel[3]).channelMasked!=0)<<3
        return retVal
    cdef void setPageByte(self, uint8_t channel, uint8_t data) nogil:
        (<IsaDmaChannel>self.channel[channel]).page = data
    cdef void setAddrByte(self, uint8_t channel, uint8_t data) nogil:
        if (self.flipFlop):
            (<IsaDmaChannel>self.channel[channel]).baseAddress = (<uint8_t>((<IsaDmaChannel>self.channel[channel]).baseAddress) | (data<<8))
            (<IsaDmaChannel>self.channel[channel]).currentAddress = (<IsaDmaChannel>self.channel[channel]).baseAddress
        else:
            (<IsaDmaChannel>self.channel[channel]).baseAddress = ((<IsaDmaChannel>self.channel[channel]).baseAddress&0xff00) | data
            (<IsaDmaChannel>self.channel[channel]).currentAddress = (<IsaDmaChannel>self.channel[channel]).baseAddress
        self.setFlipFlop(not self.flipFlop)
    cdef void setCountByte(self, uint8_t channel, uint8_t data) nogil:
        if (self.flipFlop):
            (<IsaDmaChannel>self.channel[channel]).baseCount = (<uint8_t>((<IsaDmaChannel>self.channel[channel]).baseCount) | (data<<8))
            (<IsaDmaChannel>self.channel[channel]).currentCount = (<IsaDmaChannel>self.channel[channel]).baseCount
        else:
            (<IsaDmaChannel>self.channel[channel]).baseCount = ((<IsaDmaChannel>self.channel[channel]).baseCount&0xff00) | data
            (<IsaDmaChannel>self.channel[channel]).currentCount = (<IsaDmaChannel>self.channel[channel]).baseCount
        self.setFlipFlop(not self.flipFlop)
    cdef uint8_t getPageByte(self, uint8_t channel) nogil:
        return (<IsaDmaChannel>self.channel[channel]).page
    cdef uint8_t getAddrByte(self, uint8_t channel) nogil:
        cdef uint8_t retVal
        if (self.flipFlop):
            retVal = <uint8_t>((<IsaDmaChannel>self.channel[channel]).currentAddress>>8)
        else:
            retVal = <uint8_t>((<IsaDmaChannel>self.channel[channel]).currentAddress)
        self.setFlipFlop(not self.flipFlop)
        return retVal
    cdef uint8_t getCountByte(self, uint8_t channel) nogil:
        cdef uint8_t retVal
        if (self.flipFlop):
            retVal = <uint8_t>((<IsaDmaChannel>self.channel[channel]).currentCount>>8)
        else:
            retVal = <uint8_t>((<IsaDmaChannel>self.channel[channel]).currentCount)
        self.setFlipFlop(not self.flipFlop)
        return retVal
    cdef uint8_t getStatus(self) nogil:
        cdef uint8_t status
        status = self.statusReg
        self.statusReg &= 0xf0
        return status
    cdef void controlHRQ(self) nogil:
        cdef uint8_t channel
        if (self.ctrlDisabled):
            return
        if ((self.statusReg & 0xf0) == 0):
            if (not self.master):
                self.isadma.main.cpu.setHRQ(False)
            else:
                with gil:
                    self.isadma.setDRQ(4, False)
            return
        for channel in range(4):
            if ((self.statusReg & (1 << (channel+4))) and (not (<IsaDmaChannel>self.channel[channel]).channelMasked)):
                if (not self.master):
                    self.isadma.main.cpu.setHRQ(True)
                else:
                    with gil:
                        self.isadma.setDRQ(4, True)
                return
    cdef void run(self) nogil:
        (<IsaDmaChannel>self.channel[0]).run()
        (<IsaDmaChannel>self.channel[1]).run()
        (<IsaDmaChannel>self.channel[2]).run()
        (<IsaDmaChannel>self.channel[3]).run()
        self.reset()

cdef class IsaDma:
    def __init__(self, Hirnwichse main):
        cdef IsaDmaController master, slave
        self.main = main
        master = IsaDmaController(self, True)
        self.controller[0] = <PyObject*>master
        slave = IsaDmaController(self, False)
        self.controller[1] = <PyObject*>slave
        self.HLDA = self.TC = False
        Py_INCREF(master)
        Py_INCREF(slave)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil:
        cdef uint8_t ma_sl, channelNum
        cdef uint32_t retVal
        ma_sl = (ioPortAddr>=0xc0)
        channelNum = (ioPortAddr>>(1+ma_sl))&3
        if (dataSize == OP_SIZE_WORD):
            retVal = self.inPort(ioPortAddr, OP_SIZE_BYTE)
            retVal |= (<uint32_t>self.inPort(ioPortAddr+1, OP_SIZE_BYTE))<<8
            return retVal
        elif (dataSize != OP_SIZE_BYTE):
            with gil:
                self.main.exitError("ISADma::inPort: unknown dataSize. (ioPortAddr: {0:#06x}, dataSize: {1:d})", ioPortAddr, dataSize)
            return 0
        elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06, 0xc0, 0xc4, 0xc8, 0xcc)):
            return (<IsaDmaController>self.controller[ma_sl]).getAddrByte(channelNum)
        elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07, 0xc2, 0xc6, 0xca, 0xce)):
            return (<IsaDmaController>self.controller[ma_sl]).getCountByte(channelNum)
        elif (ioPortAddr in (0x08,0xd0)):
            return (<IsaDmaController>self.controller[ma_sl]).getStatus()
        elif (ioPortAddr in (0x0d,0xda)):
            return 0
        elif (ioPortAddr in (0x0f,0xde)):
            return (0xf0 | (<IsaDmaController>self.controller[ma_sl]).getChannelMasks())
        elif (ioPortAddr in (0x81, 0x82, 0x83, 0x87)):
            channelNum = DMA_CHANNEL_INDEX[ioPortAddr - 0x81]
            return (<IsaDmaController>self.controller[0]).getPageByte(channelNum)
        elif (ioPortAddr in (0x89, 0x8a, 0x8b, 0x8f)):
            channelNum = DMA_CHANNEL_INDEX[ioPortAddr - 0x89]
            return (<IsaDmaController>self.controller[1]).getPageByte(channelNum)
        elif (ioPortAddr in DMA_EXT_PAGE_REG_PORTS):
            return self.extPageReg[ioPortAddr&0xf]
        else:
            with gil:
                self.main.exitError("ISADma::inPort: unknown ioPortAddr. (ioPortAddr: {0:#06x}, dataSize: {1:d})", ioPortAddr, dataSize)
        return 0
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil:
        cdef uint8_t ma_sl, channelNum
        ma_sl = (ioPortAddr>=0xc0)
        channelNum = (ioPortAddr>>(1+ma_sl))&3
        if (dataSize == OP_SIZE_WORD):
            self.outPort(ioPortAddr, <uint8_t>data, OP_SIZE_BYTE)
            self.outPort(ioPortAddr+1, <uint8_t>(data>>8), OP_SIZE_BYTE)
            return
        elif (dataSize != OP_SIZE_BYTE):
            with gil:
                self.main.exitError("ISADma::outPort: unknown dataSize. (ioPortAddr: {0:#06x}, data: {1:#06x}, dataSize: {2:d})", ioPortAddr, data, dataSize)
            return
        elif (ioPortAddr in (0x00, 0x02, 0x04, 0x06, 0xc0, 0xc4, 0xc8, 0xcc)):
            (<IsaDmaController>self.controller[ma_sl]).setAddrByte(channelNum, <uint8_t>data)
        elif (ioPortAddr in (0x01, 0x03, 0x05, 0x07, 0xc2, 0xc6, 0xca, 0xce)):
            (<IsaDmaController>self.controller[ma_sl]).setCountByte(channelNum, <uint8_t>data)
        elif (ioPortAddr in (0x08, 0xd0)):
            (<IsaDmaController>self.controller[ma_sl]).doCommand(<uint8_t>data)
        elif (ioPortAddr in (0x09, 0xd2)):
            (<IsaDmaController>self.controller[ma_sl]).doManualRequest(<uint8_t>data)
        elif (ioPortAddr in (0x0a, 0xd4)):
            (<IsaDmaController>self.controller[ma_sl]).maskChannel(data&3, data&4)
        elif (ioPortAddr in (0x0b, 0xd6)):
            (<IsaDmaController>self.controller[ma_sl]).setTransferMode(<uint8_t>data)
        elif (ioPortAddr in (0x0c, 0xd8)):
            (<IsaDmaController>self.controller[ma_sl]).setFlipFlop(False)
        elif (ioPortAddr in (0x0d, 0xda)):
            (<IsaDmaController>self.controller[ma_sl]).reset()
        elif (ioPortAddr in (0x0e, 0xdc)): # clear all mask registers
            (<IsaDmaController>self.controller[ma_sl]).maskChannels(0)
        elif (ioPortAddr in (0x0f, 0xde)):
            (<IsaDmaController>self.controller[ma_sl]).maskChannels(<uint8_t>data)
        elif (ioPortAddr in (0x81, 0x82, 0x83, 0x87)):
            channelNum = DMA_CHANNEL_INDEX[ioPortAddr - 0x81]
            (<IsaDmaController>self.controller[0]).setPageByte(channelNum, <uint8_t>data)
        elif (ioPortAddr in (0x89, 0x8a, 0x8b, 0x8f)):
            channelNum = DMA_CHANNEL_INDEX[ioPortAddr - 0x89]
            (<IsaDmaController>self.controller[1]).setPageByte(channelNum, <uint8_t>data)
        elif (ioPortAddr in DMA_EXT_PAGE_REG_PORTS):
            self.extPageReg[ioPortAddr&0xf] = <uint8_t>data
        else:
            with gil:
                self.main.exitError("ISADma::outPort: unknown ioPortAddr. (ioPortAddr: {0:#06x}, data: {1:#06x}, dataSize: {2:d})", ioPortAddr, data, dataSize)
    cdef uint8_t getTC(self) nogil:
        return self.TC
    cdef void setDRQ(self, uint8_t channel, uint8_t val):
        cdef uint32_t dmaBase, dmaRoof
        cdef uint8_t ma_sl
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
    cdef void raiseHLDA(self):
        cdef uint8_t ma_sl, channel, countExpired, i
        cdef uint16_t data
        cdef uint32_t phyAddr
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
                   <uint16_t>(currChannel.currentAddress << ma_sl))
        (<IsaDmaChannel>(<IsaDmaController>self.controller[ma_sl]).channel[channel]).DACK = True
        if (currChannel.addressDecrement):
            currChannel.currentAddress = (currChannel.currentAddress-1)
        else:
            currChannel.currentAddress = (currChannel.currentAddress+1)
        currChannel.currentCount = (currChannel.currentCount-1)
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
            if (currChannel.dmaMemActionInstance and currChannel.writeToMem is not NULL):
                data = currChannel.writeToMem(currChannel.dmaMemActionInstance)
            else:
                self.main.exitError("ISADMA::raiseHLDA: no dmaWrite handler for channel {0:d}", channel)
                return
            if (ma_sl):
                self.main.mm.mmPhyWriteValue(phyAddr, <uint16_t>data, OP_SIZE_WORD)
            else:
                self.main.mm.mmPhyWriteValue(phyAddr, <uint8_t>data, OP_SIZE_BYTE)
        elif (currChannel.transferDirection == 2): # MEM -> IODEV
            if (ma_sl):
                data = self.main.mm.mmPhyReadValueUnsignedWord(phyAddr)
            else:
                data = self.main.mm.mmPhyReadValueUnsignedByte(phyAddr)
            if (currChannel.dmaMemActionInstance and currChannel.readFromMem is not NULL):
                currChannel.readFromMem(currChannel.dmaMemActionInstance, data)
            else:
                self.main.exitError("ISADMA::raiseHLDA: no dmaRead handler for channel {0:d}", channel)
                return
        elif (currChannel.transferDirection == 0): # Verify
            if (currChannel.dmaMemActionInstance and currChannel.writeToMem is not NULL):
                data = currChannel.writeToMem(currChannel.dmaMemActionInstance)
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
            (<IsaDmaChannel>(<IsaDmaController>self.controller[ma_sl]).channel[channel]).DACK = False
            if (not ma_sl):
                self.setDRQ(4, False)
                (<IsaDmaChannel>(<IsaDmaController>self.controller[1]).channel[0]).DACK = False
    cdef void setDmaMemActions(self, uint8_t controllerId, uint8_t channelId, object classInstance, ReadFromMem readFromMem, WriteToMem writeToMem):
        cdef IsaDmaController controller
        cdef IsaDmaChannel channel
        controller = (<IsaDmaController>self.controller[controllerId])
        channel = (<IsaDmaChannel>controller.channel[channelId])
        channel.dmaMemActionInstance = classInstance
        channel.readFromMem = readFromMem
        channel.writeToMem = writeToMem
    cdef void run(self):
        with nogil:
            memset(self.extPageReg, 0, 16)
        (<IsaDmaController>self.controller[0]).run()
        (<IsaDmaController>self.controller[1]).run()



