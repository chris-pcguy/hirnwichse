
from cmos cimport Cmos
from ata cimport Ata
from isadma cimport IsaDma, IsaDmaChannel, ReadFromMem, WriteToMem
from pic cimport Pic


cdef class FloppyMedia:
    cdef FloppyDrive floppyDrive
    cdef unsigned int sectors
    cdef unsigned char tracks, heads, sectorsPerTrack, mediaType
    cdef void setDataForMedia(self, unsigned char mediaType)


cdef class FloppyDrive:
    cpdef object main
    cpdef object fp
    cdef FloppyController controller
    cdef FloppyMedia media
    cdef bytes filename
    cdef unsigned char driveId, isLoaded, isWriteProtected, DIR, cylinder, head, sector, eot
    cdef unsigned int ChsToSector(self, unsigned char cylinder, unsigned char head, unsigned char sector)
    cdef unsigned char getDiskType(self, unsigned int size)
    cdef void loadDrive(self, bytes filename)
    cdef bytes readBytes(self, unsigned int offset, unsigned int size)
    cdef bytes readSectors(self, unsigned int sector, unsigned int count) # count in sectors
    cdef void writeBytes(self, unsigned int offset, unsigned int size, bytes data)
    cdef void writeSectors(self, unsigned int sector, unsigned int count, bytes data)


cdef class FloppyController:
    cpdef object main
    cdef Floppy fdc
    cdef tuple drive
    cdef bytes command, result, fdcBuffer
    cdef unsigned int fdcBufferIndex
    cdef unsigned char controllerId, msr, DOR, st0, st1, st2, st3, TC, resetSensei, pendingIrq, dataRate, multiTrack
    cdef void reset(self, unsigned char hwReset)
    cdef bytes floppyXfer(self, unsigned char drive, unsigned int sector, unsigned int count, bytes data, unsigned char toFloppy)
    cdef void addCommand(self, unsigned char command)
    cdef inline void addToCommand(self, unsigned char command)
    cdef inline void addToResult(self, unsigned char result)
    cdef inline void clearCommand(self)
    cdef inline void clearResult(self)
    cdef void setDor(self, unsigned char data)
    cdef inline void setMsr(self, unsigned char data)
    cdef void doCmdReset(self)
    cdef void resetChangeline(self)
    cdef void incrementSector(self)
    cdef unsigned char getTC(self)
    cdef void handleResult(self)
    cdef void handleIdle(self)
    cdef void handleCommand(self)
    cdef void readFromMem(self, unsigned char data)
    cdef unsigned char writeToMem(self)
    cdef void raiseFloppyIrq(self)
    cdef void lowerFloppyIrq(self)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)

cdef class Floppy:
    cpdef object main
    cdef tuple controller
    cdef void setupDMATransfer(self, FloppyController classInstance)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)



