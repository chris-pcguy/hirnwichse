
from libc.stdint cimport *
from cpython.ref cimport PyObject, Py_INCREF

from hirnwichse_main cimport Hirnwichse

cdef class PicChannel:
    cdef Pic pic
    cdef uint8_t master, cmdByte, irqBasePort, mappedSlavesOnMasterMask, \
                        slaveOnThisMasterIrq, needRegister, step, inInit, irq, \
                        imr, intr, isr, irr, autoEOI, rotateOnAutoEOI, lowestPriority, \
                        polled, specialMask, IRQ_in, edgeLevel
    cdef void reset(self) nogil
    cdef void clearHighestInterrupt(self) nogil
    cdef void servicePicChannel(self) nogil
    cdef void raiseIrq(self, uint8_t irq) nogil
    cdef void lowerIrq(self, uint8_t irq) nogil
    cdef uint8_t getCmdByte(self) nogil
    cdef void setCmdByte(self, uint8_t cmdByte) nogil
    cdef uint8_t getIrqBasePort(self) nogil
    cdef void setIrqBasePort(self, uint8_t irqBasePort) nogil
    cdef void setMasterSlaveMap(self, uint8_t value) nogil
    cdef void setFlags(self, uint8_t flags) nogil
    cdef void setNeededRegister(self, uint8_t needRegister) nogil
    cdef uint8_t getNeededRegister(self) nogil
    cdef void run(self) nogil

cdef class Pic:
    cdef Hirnwichse main
    cdef PyObject *channels[2]
    cdef void setMode(self, uint8_t channel, uint8_t edgeLevel) nogil
    cdef void raiseIrq(self, uint8_t irq) nogil
    cdef void lowerIrq(self, uint8_t irq) nogil
    cdef uint8_t isClear(self, uint8_t irq)
    cdef uint8_t IAC(self)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil
    cdef void run(self) nogil


