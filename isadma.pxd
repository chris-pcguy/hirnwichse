
ctypedef void (*ReadFromMem)(self, unsigned char)
ctypedef unsigned char (*WriteToMem)(self)

from hirnwichse_main cimport Hirnwichse
from libc.string cimport memset


cdef class IsaDmaChannel:
    cdef Hirnwichse main
    cdef object dmaMemActionInstance
    cdef ReadFromMem readFromMem
    cdef WriteToMem writeToMem
    cdef IsaDmaController controller
    cdef IsaDma isadma
    cdef unsigned char channelNum, channelMasked, transferDirection, autoInit, addressDecrement, transferMode, page, DRQ, DACK
    cdef unsigned short baseAddress, baseCount, currentAddress, currentCount
    cdef void run(self)
    ###

cdef class IsaDmaController:
    cdef Hirnwichse main
    cdef IsaDma isadma
    cdef tuple channel
    cdef unsigned char flipFlop, firstChannel, master, ctrlDisabled, cmdReg, statusReg
    cdef void reset(self) nogil
    cdef void doCommand(self, unsigned char data)
    cdef void doManualRequest(self, unsigned char data)
    cdef void setFlipFlop(self, unsigned char flipFlop) nogil
    cdef void setTransferMode(self, unsigned char transferModeByte)
    cdef void maskChannel(self, unsigned char channel, unsigned char maskIt)
    cdef void maskChannels(self, unsigned char maskByte)
    cdef unsigned char getChannelMasks(self)
    cdef void setPageByte(self, unsigned char channel, unsigned char data)
    cdef void setAddrByte(self, unsigned char channel, unsigned char data)
    cdef void setCountByte(self, unsigned char channel, unsigned char data)
    cdef unsigned char getPageByte(self, unsigned char channel)
    cdef unsigned char getAddrByte(self, unsigned char channel)
    cdef unsigned char getCountByte(self, unsigned char channel)
    cdef unsigned char getStatus(self) nogil
    cdef void controlHRQ(self)
    cdef void run(self)

cdef class IsaDma:
    cdef Hirnwichse main
    cdef tuple controller
    cdef unsigned char extPageReg[16]
    cdef unsigned char HLDA, TC # extPageReg is unused.
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef unsigned char getTC(self) nogil
    cdef void setDRQ(self, unsigned char channel, unsigned char val)
    cdef void raiseHLDA(self)
    cdef void setDmaMemActions(self, unsigned char controllerId, unsigned char channelId, object classInstance, ReadFromMem readFromMem, WriteToMem writeToMem)
    cdef void run(self)



