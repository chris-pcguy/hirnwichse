
cdef class Channel:
    cpdef public object controller, isadma, main, dmaReadFromMem, dmaWriteToMem
    cdef public unsigned char channelMasked, transferDirection, autoInit, addressDecrement, transferMode, page, DRQ, DACK
    cdef public unsigned short baseAddress, baseCount, currentAddress, currentCount
    cdef unsigned char channelNum
    ###

cdef class Controller:
    cpdef public object isadma, main
    cpdef public tuple channel
    cpdef unsigned char flipFlop, firstChannel, master, ctrlDisabled, cmdReg
    cpdef public unsigned char statusReg
    cpdef reset(self)
    cpdef doCommand(self, unsigned char data)
    cpdef doManualRequest(self, unsigned char data)
    cpdef setFlipFlop(self, unsigned char flipFlop)
    cpdef setTransferMode(self, unsigned char transferModeByte)
    cpdef maskChannel(self, unsigned char channel, unsigned char maskIt)
    cpdef maskChannels(self, unsigned char maskByte)
    cpdef getChannelMasks(self)
    cpdef setPageByte(self, unsigned char channel, unsigned char data)
    cpdef setAddrByte(self, unsigned char channel, unsigned char data)
    cpdef setCountByte(self, unsigned char channel, unsigned char data)
    cpdef getPageByte(self, unsigned char channel)
    cpdef getAddrByte(self, unsigned char channel)
    cpdef getCountByte(self, unsigned char channel)
    cpdef setAddrWord(self, unsigned char channel, unsigned short data)
    cpdef setCountWord(self, unsigned char channel, unsigned short data)
    cpdef getAddrWord(self, unsigned char channel)
    cpdef getCountWord(self, unsigned char channel)
    cpdef getStatus(self)
    cpdef controlHRQ(self)
    cpdef run(self)

cdef class ISADMA:
    cpdef public object main
    cpdef public tuple controller
    cpdef list extPageReg # extPageReg is unused.
    cpdef unsigned char HLDA, TC
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned short data, unsigned char dataSize)
    cpdef getTC(self)
    cpdef setDRQ(self, unsigned char channel, unsigned char val)
    cpdef raiseHLDA(self)
    cpdef run(self)



