
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
    cdef void run(self)
    ###

cdef class IsaDmaController:
    cdef Hirnwichse main
    cdef IsaDma isadma
    cdef PyObject *channel[4]
    cdef uint8_t flipFlop, firstChannel, master, ctrlDisabled, cmdReg, statusReg
    cdef void reset(self)
    cdef void doCommand(self, uint8_t data)
    cdef void doManualRequest(self, uint8_t data)
    cdef void setFlipFlop(self, uint8_t flipFlop)
    cdef void setTransferMode(self, uint8_t transferModeByte)
    cdef void maskChannel(self, uint8_t channel, uint8_t maskIt)
    cdef void maskChannels(self, uint8_t maskByte)
    cdef uint8_t getChannelMasks(self)
    cdef void setPageByte(self, uint8_t channel, uint8_t data)
    cdef void setAddrByte(self, uint8_t channel, uint8_t data)
    cdef void setCountByte(self, uint8_t channel, uint8_t data)
    cdef uint8_t getPageByte(self, uint8_t channel)
    cdef uint8_t getAddrByte(self, uint8_t channel)
    cdef uint8_t getCountByte(self, uint8_t channel)
    cdef uint8_t getStatus(self)
    cdef void controlHRQ(self)
    cdef void run(self)

cdef class IsaDma:
    cdef Hirnwichse main
    cdef PyObject *controller[2]
    cdef uint8_t extPageReg[16]
    cdef uint8_t HLDA, TC # extPageReg is unused.
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize)
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef uint8_t getTC(self)
    cdef void setDRQ(self, uint8_t channel, uint8_t val)
    cdef void raiseHLDA(self)
    cdef void setDmaMemActions(self, uint8_t controllerId, uint8_t channelId, object classInstance, ReadFromMem readFromMem, WriteToMem writeToMem)
    cdef void run(self)



