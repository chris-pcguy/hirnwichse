
include "globals.pxi"
include "cpu_globals.pxi"

from hirnwichse_main cimport Hirnwichse
#from mm cimport Mm, ConfigSpace
from mm cimport ConfigSpace
from registers cimport Registers
from cpython.ref cimport PyObject


cdef class Segment:
    cdef Segments segments
    cdef unsigned char accessByte, flags, isValid, segSize, segPresent, segIsCodeSeg, segIsRW, segIsConforming, \
        segIsNormal, segUse4K, segDPL, useGDT, readChecked, writeChecked, anotherLimit, segIsGDTandNormal
    cdef unsigned short segmentIndex, segId
    cdef unsigned int base, limit
    cdef unsigned char loadSegment(self, unsigned short segmentIndex, unsigned char doInit) except BITMASK_BYTE_CONST
    cdef inline unsigned char isAddressInLimit(self, unsigned int address, unsigned int size) nogil except BITMASK_BYTE_CONST # TODO: copied from GdtEntry::isAddressInLimit until a better solution is found... so never.

cdef class GdtEntry:
    cdef Segments segments
    cdef unsigned char accessByte, flags, segSize, segPresent, segIsCodeSeg, segIsRW, segIsConforming, \
        segIsNormal, segUse4K, segDPL, anotherLimit
    cdef unsigned int base, limit
    cdef void parseEntryData(self, unsigned long int entryData) nogil
    cdef inline unsigned char isAddressInLimit(self, unsigned int address, unsigned int size) nogil except BITMASK_BYTE_CONST

cdef:
    struct IdtEntry:
        unsigned char entryType, entrySize, entryNeededDPL, entryPresent
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
    cdef GdtEntry getEntry(self, unsigned short num)
    cdef unsigned char getSegType(self, unsigned short num) nogil except? BITMASK_BYTE_CONST
    cdef unsigned char setSegType(self, unsigned short num, unsigned char segmentType) nogil except BITMASK_BYTE_CONST
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment) except BITMASK_BYTE_CONST
    cdef unsigned char checkReadAllowed(self, unsigned short num) except BITMASK_BYTE_CONST
    cdef unsigned char checkWriteAllowed(self, unsigned short num) except BITMASK_BYTE_CONST
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned short segId) except BITMASK_BYTE_CONST

cdef class Idt:
    cdef Segments segments
    cdef unsigned short tableLimit
    cdef unsigned int tableBase
    cdef void loadTable(self, unsigned int tableBase, unsigned short tableLimit) nogil
    cdef inline void getBaseLimit(self, unsigned int *retTableBase, unsigned short *retTableLimit) nogil:
        retTableBase[0] = self.tableBase
        retTableLimit[0] = self.tableLimit
    cdef void parseIdtEntryData(self, IdtEntry *idtEntry, unsigned long int entryData) nogil

    cdef IdtEntry *getEntry(self, unsigned char num) nogil
    cdef unsigned char isEntryPresent(self, unsigned char num)
    cdef unsigned char getEntryNeededDPL(self, unsigned char num)
    cdef unsigned char getEntrySize(self, unsigned char num)
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
    cdef unsigned char readAddresses(self, unsigned int virtualAddress, unsigned char written) nogil except BITMASK_BYTE_CONST
    cdef unsigned char accessAllowed(self, unsigned int virtualAddress, unsigned char written, unsigned char refresh) nogil except BITMASK_BYTE_CONST
    cdef unsigned char setFlags(self, unsigned int virtualAddress, unsigned int dataSize, unsigned char written) nogil except BITMASK_BYTE_CONST
    cdef unsigned int getPhysicalAddress(self, unsigned int virtualAddress, unsigned int dataSize, unsigned char written) nogil except? BITMASK_BYTE_CONST
    
cdef class Segments:
    cdef Hirnwichse main
    cdef Gdt gdt, ldt
    cdef Idt idt
    cdef Paging paging
    cdef Registers registers
    cdef Segment cs, ds, es, fs, gs, ss, tss
    cdef unsigned short ldtr
    cdef void reset(self) nogil
    cdef inline GdtEntry getEntry(self, unsigned short num)
    cdef inline unsigned char getSegType(self, unsigned short num) nogil except? BITMASK_BYTE_CONST
    cdef inline unsigned char setSegType(self, unsigned short num, unsigned char segmentType) nogil except BITMASK_BYTE_CONST
    cdef inline unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment) except BITMASK_BYTE_CONST
    cdef inline unsigned char checkReadAllowed(self, unsigned short num)
    cdef inline unsigned char checkWriteAllowed(self, unsigned short num)
    cdef inline unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned short segId) except BITMASK_BYTE_CONST
    cdef inline unsigned char inLimit(self, unsigned short num) nogil
    cdef void run(self)



