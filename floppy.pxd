
from cmos cimport Cmos
from isadma cimport IsaDma, IsaDmaChannel
from pic cimport Pic


cdef class FloppyMedia:
    cdef FloppyDrive floppyDrive
    cdef unsigned long sectors
    cdef unsigned char tracks, heads, sectorsPerTrack, mediaType
    cdef setDataForMedia(self, unsigned char mediaType)


cdef class FloppyDrive:
    cpdef public object main
    cpdef object fp
    cdef FloppyController controller
    cdef FloppyMedia media
    cdef bytes filename
    cdef unsigned char driveId, isLoaded, isWriteProtected, DIR, cylinder, head, sector, eot
    cdef unsigned char getIsLoaded(self)
    cdef unsigned long ChsToSector(self, unsigned char cylinder, unsigned char head, unsigned char sector)
    cdef unsigned char getDiskType(self, unsigned long size)
    cdef loadDrive(self, bytes filename)
    cdef bytes readBytes(self, unsigned long offset, unsigned long size)
    cdef bytes readSectors(self, unsigned long sector, unsigned long count) # count in sectors
    cdef writeSectors(self, unsigned long sector, bytes data)


cdef class FloppyController:
    cpdef public object main, _pyroDaemon, pyroURI_FDC, pyroFDC
    cdef Floppy fdc
    cdef tuple drive
    cdef public str _pyroId
    cdef bytes command, result, fdcBuffer
    cdef unsigned long fdcBufferIndex
    cdef unsigned char controllerId, msr, DOR, st0, st1, st2, st3, TC, resetSensei, pendingIrq, dataRate, multiTrack
    cdef reset(self, unsigned char hwReset)
    cdef bytes floppyXfer(self, unsigned char drive, unsigned long offset, unsigned long size, unsigned char toFloppy)
    cdef addCommand(self, unsigned char command)
    cdef addToCommand(self, unsigned char command)
    cdef addToResult(self, unsigned char result)
    cdef clearCommand(self)
    cdef clearResult(self)
    cdef setDor(self, unsigned char data)
    cdef setMsr(self, unsigned char data)
    cdef doCmdReset(self)
    cdef resetChangeline(self)
    cdef incrementSector(self)
    cdef getTC(self)
    cdef handleResult(self)
    cdef handleIdle(self)
    cdef handleCommand(self)
    cpdef readFromMem(self, unsigned char data)
    cpdef unsigned char writeToMem(self)
    cdef raiseFloppyIrq(self)
    cdef lowerFloppyIrq(self)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef run(self)

cdef class Floppy:
    cpdef public object main
    cdef tuple controller
    cpdef setupDMATransfer(self, object classInstance)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef run(self)



