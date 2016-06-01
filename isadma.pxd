
from libc.stdint cimport *
from cpython.ref cimport PyObject, Py_INCREF

ctypedef void (*ReadFromMem)(self, uint8_t)
ctypedef uint8_t (*WriteToMem)(self)

from libc.string cimport memset

from hirnwichse_main cimport Hirnwichse

cdef class IsaDmaChannel:
    cdef Hirnwichse main
    cdef object dmaMemActionInstance
    cdef ReadFromMem readFromMem
    cdef WriteToMem writeToMem
    cdef IsaDmaController controller
    cdef IsaDma isadma
    cdef uint8_t channelNum, channelMasked, transferDirection, autoInit, addressDecrement, transferMode, page, DRQ, DACK
    cdef uint16_t baseAddress, baseCount, currentAddress, currentCount
    cdef void run(self) nogil
    ###

cdef class IsaDmaController:
    cdef Hirnwichse main
    cdef IsaDma isadma
    cdef PyObject *channel[4]
    cdef uint8_t flipFlop, firstChannel, master, ctrlDisabled, cmdReg, statusReg
    cdef void reset(self) nogil
    cdef void doCommand(self, uint8_t data) nogil
    cdef void doManualRequest(self, uint8_t data) nogil
    cdef void setFlipFlop(self, uint8_t flipFlop) nogil
    cdef void setTransferMode(self, uint8_t transferModeByte) nogil
    cdef void maskChannel(self, uint8_t channel, uint8_t maskIt) nogil
    cdef void maskChannels(self, uint8_t maskByte) nogil
    cdef uint8_t getChannelMasks(self) nogil
    cdef void setPageByte(self, uint8_t channel, uint8_t data) nogil
    cdef void setAddrByte(self, uint8_t channel, uint8_t data) nogil
    cdef void setCountByte(self, uint8_t channel, uint8_t data) nogil
    cdef uint8_t getPageByte(self, uint8_t channel) nogil
    cdef uint8_t getAddrByte(self, uint8_t channel) nogil
    cdef uint8_t getCountByte(self, uint8_t channel) nogil
    cdef uint8_t getStatus(self) nogil
    cdef void controlHRQ(self) nogil
    cdef void run(self) nogil

cdef class IsaDma:
    cdef Hirnwichse main
    cdef PyObject *controller[2]
    cdef uint8_t extPageReg[16]
    cdef uint8_t HLDA, TC # extPageReg is unused.
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil
    cdef uint8_t getTC(self) nogil
    cdef void setDRQ(self, uint8_t channel, uint8_t val)
    cdef void raiseHLDA(self)
    cdef void setDmaMemActions(self, uint8_t controllerId, uint8_t channelId, object classInstance, ReadFromMem readFromMem, WriteToMem writeToMem)
    cdef void run(self)



