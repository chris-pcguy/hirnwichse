
from libc.stdint cimport *
from cpython.ref cimport PyObject, Py_INCREF

from hirnwichse_main cimport Hirnwichse
from pic cimport Pic
from posix.unistd cimport usleep

cdef class SerialPort:
    cdef Serial serial
    cdef Hirnwichse main
    cdef bytes serialFilename, data
    cdef object sock, fp
    cdef uint8_t serialIndex, dlab, dataBits, stopBits, parity, interruptEnableRegister, interruptIdentificationFifoControl, modemControlRegister, lineStatusRegister, oldModemStatusRegister, scratchRegister, irq, isDev
    cdef uint16_t divisor
    cdef void reset(self) nogil
    cdef void setFlags(self)
    cdef void setBits(self)
    cdef void handleIrqs(self)
    cdef void quitFunc(self)
    cdef void raiseIrq(self)
    cdef void readData(self)
    cdef void writeData(self, bytes data)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize)
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef void run(self)

cdef class Serial:
    cdef Hirnwichse main
    cdef PyObject *ports[4]
    cdef void reset(self) nogil
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize)
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef void run(self)


