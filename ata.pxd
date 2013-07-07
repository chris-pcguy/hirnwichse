
from cmos cimport Cmos
from pic cimport Pic
from mm cimport ConfigSpace

cdef class AtaDrive:
    cpdef object main, fp
    cdef AtaController ataController
    cdef ConfigSpace configSpace
    cdef unsigned char driveId, sectorCountFlipFlop, sectorHighFlipFlop, sectorMiddleFlipFlop, sectorLowFlipFlop, isLoaded, \
        isWriteProtected
    cdef unsigned int sectorCount
    cdef unsigned long int sector, diskSize
    cdef bytes filename
    cdef void reset(self)
    cdef inline unsigned short readValue(self, unsigned char index)
    cdef inline void writeValue(self, unsigned char index, unsigned short value)
    cdef void loadDrive(self, bytes filename)
    cdef void run(self)


cdef class AtaController:
    cpdef object main
    cdef Ata ata
    cdef tuple drive
    cdef bytes result
    cdef unsigned char controllerId, driveId, useLBA, useLBA48, irqEnabled, doReset, driveBusy, resetInProgress, \
        driveReady, drq, seekComplete, err, irq
    cdef void reset(self, unsigned char swReset)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)


cdef class Ata:
    cpdef object main
    cdef tuple controller
    cdef void reset(self)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)


