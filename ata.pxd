
from pic cimport Pic


cdef class AtaDrive:
    cpdef object main
    cdef AtaChannel ataChannel
    cdef unsigned char driveId, sectorCountFlipFlop, sectorHighFlipFlop, sectorMiddleFlipFlop, sectorLowFlipFlop, isPresent
    cdef unsigned int sectorCount
    cdef unsigned long int sector
    cdef void reset(self)
    cdef void run(self)


cdef class AtaChannel:
    cpdef object main
    cdef Ata ata
    cdef tuple drives
    cdef unsigned char channelId, driveId, useLBA, useLBA48, irqEnabled, doReset, driveBusy, resetInProgress, \
        driveReady, drq, seekComplete, err, irq
    cdef void reset(self, unsigned char swReset)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)


cdef class Ata:
    cpdef object main
    cdef tuple channels
    cdef void reset(self)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)


