
cdef class FloppyMedia:
    cpdef public object floppyDrive
    cdef public unsigned char tracks, heads, sectorsPerTrack, mediaType
    cdef public unsigned long sectors
    cpdef setDataForMedia(self, unsigned char mediaType)


cdef class FloppyDrive:
    cpdef public object main, fp, controller, media
    cdef public bytes filename
    cdef public unsigned char driveId, isLoaded, isWriteProtected, DIR, cylinder, head, sector, eot
    cpdef unsigned long ChsToSector(self, unsigned char cylinder, unsigned char head, unsigned char sector)
    cpdef unsigned char getDiskType(self, unsigned long size)
    cpdef loadDrive(self, bytes filename)
    cpdef bytes readBytes(self, unsigned long offset, unsigned long size)
    cpdef bytes readSectors(self, unsigned long sector, unsigned long count) # count in sectors
    cpdef writeSectors(self, unsigned long sector, bytes data)
    

cdef class FloppyController:
    cpdef public object main, fdcDma, isaDma, fdc
    cdef bytes command, result, fdcBuffer
    cdef public tuple drive
    cdef unsigned char controllerId, msr, DOR, st0, st1, st2, st3, TC, resetSensei, pendingIrq, dataRate, multiTrack
    cdef unsigned long fdcBufferIndex
    cpdef reset(self, unsigned char hwReset)
    cpdef floppyXfer(self, unsigned char drive, unsigned long offset, unsigned long size, unsigned char toFloppy)
    cpdef addCommand(self, unsigned char command)
    cpdef addToCommand(self, unsigned char command)
    cpdef addToResult(self, unsigned char result)
    cpdef clearCommand(self)
    cpdef clearResult(self)
    cpdef setDor(self, unsigned char data)
    cpdef setMsr(self, unsigned char data)
    cpdef doCmdReset(self)
    cpdef resetChangeline(self)
    cpdef incrementSector(self)
    cpdef getTC(self)
    cpdef handleResult(self)
    cpdef handleIdle(self)
    cpdef handleCommand(self)
    cpdef setupDMATransfer(self)
    cpdef writeToDrive(self, unsigned char data)
    cpdef unsigned char readFromDrive(self)
    cpdef raiseFloppyIrq(self)
    cpdef lowerFloppyIrq(self)
    cpdef unsigned char inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned char data, unsigned char dataSize)
    cpdef run(self)

cdef class Floppy:
    cpdef public object main
    cdef public tuple controller
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cpdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cpdef run(self)



