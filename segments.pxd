
include "globals.pxi"
include "cpu_globals.pxi"

from libc.stdint cimport *

from hirnwichse_main cimport Hirnwichse
#from mm cimport Mm, ConfigSpace
from mm cimport ConfigSpace
from registers cimport Registers


cdef extern from "hirnwichse_segs.h":
    struct GdtEntry:
        uint8_t accessByte
        uint8_t flags
        uint8_t segSize
        uint8_t segPresent
        uint8_t segIsCodeSeg
        uint8_t segIsRW
        uint8_t segIsConforming
        uint8_t segIsNormal
        uint8_t segUse4K
        uint8_t segDPL
        uint8_t anotherLimit
        uint32_t base
        uint32_t limit

    struct Segment:
        GdtEntry gdtEntry
        uint8_t isValid
        uint8_t useGDT
        uint8_t readChecked
        uint8_t writeChecked
        uint8_t segIsGDTandNormal
        uint16_t segmentIndex
        uint16_t segId

    struct IdtEntry:
        uint8_t entryType
        uint8_t entrySize
        uint8_t entryNeededDPL
        uint8_t entryPresent
        uint16_t entrySegment
        uint32_t entryEip


cdef class Gdt:
    cdef Segments segments
    cdef uint16_t tableLimit
    cdef uint32_t tableBase
    cdef void loadTablePosition(self, uint32_t tableBase, uint16_t tableLimit)
    cdef uint8_t getEntry(self, GdtEntry *gdtEntry, uint16_t num) except BITMASK_BYTE_CONST
    cdef uint8_t getSegType(self, uint16_t num) except? BITMASK_BYTE_CONST
    cdef uint8_t setSegType(self, uint16_t num, uint8_t segmentType) except BITMASK_BYTE_CONST
    cdef uint8_t checkAccessAllowed(self, uint16_t num, uint8_t isStackSegment) except BITMASK_BYTE_CONST
    cdef uint8_t checkReadAllowed(self, uint16_t num) except BITMASK_BYTE_CONST
    cdef uint8_t checkWriteAllowed(self, uint16_t num) except BITMASK_BYTE_CONST
    cdef uint8_t checkSegmentLoadAllowed(self, uint16_t num, uint16_t segId) except BITMASK_BYTE_CONST

cdef class Idt:
    cdef Segments segments
    cdef uint16_t tableLimit
    cdef uint32_t tableBase
    cdef void loadTable(self, uint32_t tableBase, uint16_t tableLimit)
    cdef uint8_t getEntry(self, IdtEntry *idtEntry, uint8_t num) except BITMASK_BYTE_CONST

cdef class Paging:
    cdef Segments segments
    cdef ConfigSpace tlbDirectories, tlbTables
    cdef uint8_t instrFetch, implicitSV
    cdef uint16_t pageOffset
    cdef uint32_t pageDirectoryOffset, pageTableOffset, pageDirectoryBaseAddress, pageDirectoryEntry, pageTableEntry
    cdef void invalidateTables(self, uint32_t pageDirectoryBaseAddress, uint8_t noGlobal)
    cdef void invalidateTable(self, uint32_t virtualAddress)
    cdef void invalidatePage(self, uint32_t virtualAddress)
    cdef uint8_t doPF(self, uint32_t virtualAddress, uint8_t written) except BITMASK_BYTE_CONST
    cdef uint8_t setFlags(self, uint32_t virtualAddress, uint32_t dataSize, uint8_t written)
    cdef uint32_t getPhysicalAddress(self, uint32_t virtualAddress, uint32_t dataSize, uint8_t written) except? BITMASK_BYTE_CONST
    
cdef class Segments:
    cdef Hirnwichse main
    cdef Gdt gdt, ldt
    cdef Idt idt
    cdef Paging paging
    cdef Registers registers
    cdef Segment cs, ds, es, fs, gs, ss, tss
    cdef uint8_t loadSegment(self, Segment *segment, uint16_t segmentIndex, uint8_t doInit) except BITMASK_BYTE_CONST
    cdef inline uint8_t getEntry(self, GdtEntry *gdtEntry, uint16_t num) except BITMASK_BYTE_CONST
    cdef inline uint8_t getSegType(self, uint16_t num) except? BITMASK_BYTE_CONST
    cdef inline uint8_t setSegType(self, uint16_t num, uint8_t segmentType) except BITMASK_BYTE_CONST
    cdef inline uint8_t checkAccessAllowed(self, uint16_t num, uint8_t isStackSegment) except BITMASK_BYTE_CONST
    cdef inline uint8_t checkReadAllowed(self, uint16_t num) except BITMASK_BYTE_CONST
    cdef inline uint8_t checkWriteAllowed(self, uint16_t num) except BITMASK_BYTE_CONST
    cdef inline uint8_t checkSegmentLoadAllowed(self, uint16_t num, uint16_t segId) except BITMASK_BYTE_CONST
    cdef inline uint8_t inLimit(self, uint16_t num)
    cdef void run(self)



