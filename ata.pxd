

cdef class AtaDrive:
    cpdef object main
    cdef AtaChannel ataChannel
    cdef unsigned char driveId
    cdef void reset(self)
    cdef void run(self)


cdef class AtaChannel:
    cpdef object main
    cdef Ata ata
    cdef tuple drives
    cdef unsigned char channelId, driveId
    cdef void reset(self)
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


