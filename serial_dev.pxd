
from hirnwichse_main cimport Hirnwichse
from pic cimport Pic
from posix.unistd cimport usleep

cdef class SerialPort:
    cdef Serial serial
    cdef Hirnwichse main
    cdef bytes serialFilename, data
    cpdef object sock, fp
    cdef unsigned char serialIndex, dlab, dataBits, stopBits, parity, interruptEnableRegister, interruptIdentificationFifoControl, modemControlRegister, lineStatusRegister, oldModemStatusRegister, scratchRegister, irq, isDev
    cdef unsigned short divisor
    cdef void reset(self)
    cpdef setFlags(self)
    cpdef setBits(self)
    cpdef handleIrqs(self)
    cpdef quitFunc(self)
    cdef void raiseIrq(self)
    cdef void readData(self)
    cdef void writeData(self, bytes data)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)

cdef class Serial:
    cdef Hirnwichse main
    cdef tuple ports
    cdef void reset(self)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)


