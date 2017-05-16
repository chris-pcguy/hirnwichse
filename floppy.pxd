
from libc.stdint cimport *

from hirnwichse_main cimport Hirnwichse
from cmos cimport Cmos
from ata cimport Ata
from isadma cimport IsaDma, IsaDmaChannel, ReadFromMem, WriteToMem
from pic cimport Pic


cdef class FloppyMedia:
    cdef FloppyDrive floppyDrive
    cdef uint32_t sectors
    cdef uint8_t tracks, heads, sectorsPerTrack, mediaType
    cdef void setDataForMedia(self, uint8_t mediaType)

cdef class FloppyDrive:
    cdef object fp
    cdef FloppyController controller
    cdef FloppyMedia media
    cdef bytes filename
    cdef uint8_t driveId, isLoaded, isWriteProtected, DIR, cylinder, head, sector, eot
    cdef void reset(self)
    cdef uint32_t ChsToSector(self, uint8_t cylinder, uint8_t head, uint8_t sector)
    cdef uint8_t getDiskType(self, uint32_t size)
    cdef void loadDrive(self, bytes filename)
    cdef bytes readBytes(self, uint32_t offset, uint32_t size)
    cdef bytes readSectors(self, uint32_t sector, uint32_t count) # count in sectors
    cdef void writeBytes(self, uint32_t offset, uint32_t size, bytes data)
    cdef void writeSectors(self, uint32_t sector, uint32_t count, bytes data)

cdef class FloppyController:
    cdef Hirnwichse main
    cdef Floppy fdc
    cdef tuple drive
    cdef bytes command, result, fdcBuffer
    cdef uint32_t fdcBufferIndex
    cdef uint8_t controllerId, msr, DOR, st0, st1, st2, st3, TC, resetSensei, pendingIrq, dataRate, multiTrack, config, precomp, lock, perpMode
    cdef void reset(self, uint8_t hwReset)
    cdef bytes floppyXfer(self, uint8_t drive, uint32_t sector, uint32_t count, bytes data, uint8_t toFloppy)
    cdef void addCommand(self, uint8_t command)
    cdef inline void addToCommand(self, uint8_t command)
    cdef inline void addToResult(self, uint8_t result)
    cdef inline void clearCommand(self)
    cdef inline void clearResult(self)
    cdef void setDor(self, uint8_t data)
    cdef inline void setMsr(self, uint8_t data)
    cdef void doCmdReset(self)
    cdef void resetChangeline(self)
    cdef void incrementSector(self)
    cdef uint8_t getTC(self)
    cdef void handleResult(self)
    cdef void handleIdle(self)
    cdef void handleCommand(self)
    cdef void readFromMem(self, uint8_t data)
    cdef uint8_t writeToMem(self)
    cdef void raiseFloppyIrq(self)
    cdef void lowerFloppyIrq(self)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize)
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef void run(self)

cdef class Floppy:
    cdef Hirnwichse main
    cdef tuple controller
    cdef void setupDMATransfer(self, FloppyController classInstance)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize)
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef void run(self)


