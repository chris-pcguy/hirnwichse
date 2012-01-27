
ctypedef void (*DmaReadFromMem)(self, unsigned char)
ctypedef unsigned char (*DmaWriteToMem)(self)
ctypedef void (*SetHRQ)(self, unsigned char)


cdef class IsaDmaChannel:
    cpdef object main, dmaReadFromMem, dmaWriteToMem
    cdef IsaDmaController controller
    cdef IsaDma isadma
    cdef unsigned char channelNum, channelMasked, transferDirection, autoInit, addressDecrement, transferMode, page, DRQ, DACK
    cdef unsigned short baseAddress, baseCount, currentAddress, currentCount
    cdef run(self)
    ###

cdef class IsaDmaController:
    cpdef object main
    cdef IsaDma isadma
    cdef tuple channel
    cdef unsigned char flipFlop, firstChannel, master, ctrlDisabled, cmdReg, statusReg
    cdef reset(self)
    cdef doCommand(self, unsigned char data)
    cdef doManualRequest(self, unsigned char data)
    cdef setFlipFlop(self, unsigned char flipFlop)
    cdef setTransferMode(self, unsigned char transferModeByte)
    cdef maskChannel(self, unsigned char channel, unsigned char maskIt)
    cdef maskChannels(self, unsigned char maskByte)
    cdef unsigned char getChannelMasks(self)
    cdef setPageByte(self, unsigned char channel, unsigned char data)
    cdef setAddrByte(self, unsigned char channel, unsigned char data)
    cdef setCountByte(self, unsigned char channel, unsigned char data)
    cdef unsigned char getPageByte(self, unsigned char channel)
    cdef unsigned char getAddrByte(self, unsigned char channel)
    cdef unsigned char getCountByte(self, unsigned char channel)
    cdef setAddrWord(self, unsigned char channel, unsigned short data)
    cdef setCountWord(self, unsigned char channel, unsigned short data)
    cdef unsigned short getAddrWord(self, unsigned char channel)
    cdef unsigned short getCountWord(self, unsigned char channel)
    cdef unsigned char getStatus(self)
    cdef controlHRQ(self)
    cdef run(self)

cdef class IsaDma:
    cpdef public object main, _pyroDaemon
    cpdef public str _pyroId
    cdef tuple controller
    cdef unsigned char extPageReg[16], HLDA, TC # extPageReg is unused.
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cpdef getTC(self)
    cpdef setDRQ(self, unsigned char channel, unsigned char val)
    cdef raiseHLDA(self)
    cpdef setDmaMemActions(self, unsigned char controllerId, unsigned char channelId, object classInstance)
    cdef run(self)



