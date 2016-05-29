
include "globals.pxi"
include "cpu_globals.pxi"

from hirnwichse_main cimport Hirnwichse
#from mm cimport Mm, ConfigSpace
from mm cimport ConfigSpace
from registers cimport Registers


cdef extern from "hirnwichse_segs.h":
    struct GdtEntry:
        unsigned char accessByte
        unsigned char flags
        unsigned char segSize
        unsigned char segPresent
        unsigned char segIsCodeSeg
        unsigned char segIsRW
        unsigned char segIsConforming
        unsigned char segIsNormal
        unsigned char segUse4K
        unsigned char segDPL
        unsigned char anotherLimit
        unsigned int base
        unsigned int limit

    struct Segment:
        GdtEntry gdtEntry
        unsigned char isValid
        unsigned char useGDT
        unsigned char readChecked
        unsigned char writeChecked
        unsigned char segIsGDTandNormal
        unsigned short segmentIndex
        unsigned short segId

    struct IdtEntry:
        unsigned char entryType
        unsigned char entrySize
        unsigned char entryNeededDPL
        unsigned char entryPresent
        unsigned short entrySegment
        unsigned int entryEip


cdef class Gdt:
    cdef Segments segments
    cdef unsigned short tableLimit
    cdef unsigned int tableBase
    cdef void loadTablePosition(self, unsigned int tableBase, unsigned short tableLimit) nogil
    cdef inline void getBaseLimit(self, unsigned int *retTableBase, unsigned short *retTableLimit) nogil:
        retTableBase[0] = self.tableBase
        retTableLimit[0] = self.tableLimit
    cdef unsigned char getEntry(self, GdtEntry *gdtEntry, unsigned short num) nogil except BITMASK_BYTE_CONST
    cdef unsigned char getSegType(self, unsigned short num) nogil except? BITMASK_BYTE_CONST
    cdef unsigned char setSegType(self, unsigned short num, unsigned char segmentType) nogil except BITMASK_BYTE_CONST
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment) nogil except BITMASK_BYTE_CONST
    cdef unsigned char checkReadAllowed(self, unsigned short num) nogil except BITMASK_BYTE_CONST
    cdef unsigned char checkWriteAllowed(self, unsigned short num) nogil except BITMASK_BYTE_CONST
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned short segId) nogil except BITMASK_BYTE_CONST

cdef class Idt:
    cdef Segments segments
    cdef unsigned short tableLimit
    cdef unsigned int tableBase
    cdef void loadTable(self, unsigned int tableBase, unsigned short tableLimit) nogil
    cdef inline void getBaseLimit(self, unsigned int *retTableBase, unsigned short *retTableLimit) nogil:
        retTableBase[0] = self.tableBase
        retTableLimit[0] = self.tableLimit
    cdef void parseIdtEntryData(self, IdtEntry *idtEntry, unsigned long int entryData) nogil
    cdef unsigned char getEntry(self, IdtEntry *idtEntry, unsigned char num) nogil except BITMASK_BYTE_CONST
    cdef unsigned char isEntryPresent(self, unsigned char num) nogil except BITMASK_BYTE_CONST
    cdef unsigned char getEntryNeededDPL(self, unsigned char num) nogil except BITMASK_BYTE_CONST
    cdef unsigned char getEntrySize(self, unsigned char num) nogil except BITMASK_BYTE_CONST
    cdef void getEntryRealMode(self, unsigned char num, unsigned short *entrySegment, unsigned short *entryEip) nogil

cdef class Paging:
    cdef Segments segments
    cdef ConfigSpace tlbDirectories, tlbTables
    cdef unsigned char instrFetch, implicitSV
    cdef unsigned short pageOffset
    cdef unsigned int pageDirectoryOffset, pageTableOffset, pageDirectoryBaseAddress, pageDirectoryEntry, pageTableEntry
    cdef void invalidateTables(self, unsigned int pageDirectoryBaseAddress, unsigned char noGlobal) nogil
    cdef void invalidateTable(self, unsigned int virtualAddress) nogil
    cdef void invalidatePage(self, unsigned int virtualAddress) nogil
    cdef unsigned char doPF(self, unsigned int virtualAddress, unsigned char written) nogil except BITMASK_BYTE_CONST
    cdef unsigned char setFlags(self, unsigned int virtualAddress, unsigned int dataSize, unsigned char written) nogil except BITMASK_BYTE_CONST
    cdef unsigned int getPhysicalAddress(self, unsigned int virtualAddress, unsigned int dataSize, unsigned char written) nogil except? BITMASK_BYTE_CONST
    
cdef class Segments:
    cdef Hirnwichse main
    cdef Gdt gdt, ldt
    cdef Idt idt
    cdef Paging paging
    cdef Registers registers
    cdef Segment cs, ds, es, fs, gs, ss, tss
    cdef inline unsigned char isAddressInLimit(self, GdtEntry *gdtEntry, unsigned int address, unsigned int size) nogil except BITMASK_BYTE_CONST
    cdef void parseGdtEntryData(self, GdtEntry *gdtEntry, unsigned long int entryData) nogil
    cdef unsigned char loadSegment(self, Segment *segment, unsigned short segmentIndex, unsigned char doInit) nogil except BITMASK_BYTE_CONST
    cdef inline unsigned char getEntry(self, GdtEntry *gdtEntry, unsigned short num) nogil except BITMASK_BYTE_CONST
    cdef inline unsigned char getSegType(self, unsigned short num) nogil except? BITMASK_BYTE_CONST
    cdef inline unsigned char setSegType(self, unsigned short num, unsigned char segmentType) nogil except BITMASK_BYTE_CONST
    cdef inline unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment) nogil except BITMASK_BYTE_CONST
    cdef inline unsigned char checkReadAllowed(self, unsigned short num) nogil except BITMASK_BYTE_CONST
    cdef inline unsigned char checkWriteAllowed(self, unsigned short num) nogil except BITMASK_BYTE_CONST
    cdef inline unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned short segId) nogil except BITMASK_BYTE_CONST
    cdef inline unsigned char inLimit(self, unsigned short num) nogil
    cdef void run(self)



