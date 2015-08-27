
include "globals.pxi"
include "cpu_globals.pxi"

from hirnwichse_main cimport Hirnwichse
#from mm cimport Mm, ConfigSpace
from mm cimport ConfigSpace
from registers cimport Registers


cdef class Segment:
    cdef Segments segments
    cdef unsigned char accessByte, flags, isValid, segSize, segPresent, segIsCodeSeg, segIsRW, \
        segIsConforming, segIsNormal, segUse4K, segDPL, useGDT, readChecked, writeChecked, anotherLimit
    cdef unsigned short segmentIndex, segId
    cdef unsigned int base, limit
    cdef unsigned char loadSegment(self, unsigned short segmentIndex, unsigned char doInit) except BITMASK_BYTE
    cdef unsigned char isAddressInLimit(self, unsigned int address, unsigned int size) except BITMASK_BYTE

cdef class GdtEntry:
    cdef Gdt gdt
    cdef unsigned char accessByte, flags, segSize, segPresent, segIsCodeSeg, segIsRW, \
        segIsConforming, segIsNormal, segUse4K, segDPL
    cdef unsigned int base, limit
    cdef void parseEntryData(self, unsigned long int entryData)
    cdef unsigned char isAddressInLimit(self, unsigned int address, unsigned int size) except BITMASK_BYTE

cdef class IdtEntry:
    cdef unsigned char entryType, entrySize, entryNeededDPL, entryPresent
    cdef unsigned short entrySegment
    cdef unsigned int entryEip
    cdef void parseEntryData(self, unsigned long int entryData) nogil


cdef class Gdt:
    cdef Segments segments
    cdef unsigned short tableLimit
    cdef unsigned int tableBase
    cdef void loadTablePosition(self, unsigned int tableBase, unsigned short tableLimit)
    cdef inline void getBaseLimit(self, unsigned int *retTableBase, unsigned short *retTableLimit) nogil:
        retTableBase[0] = self.tableBase
        retTableLimit[0] = self.tableLimit
    cdef GdtEntry getEntry(self, unsigned short num)
    cdef unsigned char getSegType(self, unsigned short num)
    cdef void setSegType(self, unsigned short num, unsigned char segmentType)
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment) except BITMASK_BYTE
    cdef unsigned char checkReadAllowed(self, unsigned short num)
    cdef unsigned char checkWriteAllowed(self, unsigned short num)
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned short segId) except BITMASK_BYTE

cdef class Idt:
    cdef Segments segments
    cdef unsigned short tableLimit
    cdef unsigned int tableBase
    cdef void loadTable(self, unsigned int tableBase, unsigned short tableLimit)
    cdef inline void getBaseLimit(self, unsigned int *retTableBase, unsigned short *retTableLimit) nogil:
        retTableBase[0] = self.tableBase
        retTableLimit[0] = self.tableLimit
    cdef IdtEntry getEntry(self, unsigned char num)
    cdef unsigned char isEntryPresent(self, unsigned char num)
    cdef unsigned char getEntryNeededDPL(self, unsigned char num)
    cdef unsigned char getEntrySize(self, unsigned char num)
    cdef void getEntryRealMode(self, unsigned char num, unsigned short *entrySegment, unsigned short *entryEip)

cdef class Paging:
    cdef Segments segments
    cdef ConfigSpace tlbDirectories, tlbTables
    cdef unsigned char instrFetch, implicitSV
    cdef unsigned short pageOffset
    cdef unsigned int pageDirectoryOffset, pageTableOffset, pageDirectoryBaseAddress, pageDirectoryEntry, pageTableEntry
    cdef inline void setInstrFetch(self) nogil:
        self.instrFetch = True
    cdef void invalidateTables(self, unsigned int pageDirectoryBaseAddress, unsigned char noGlobal)
    cdef void invalidateTable(self, unsigned int virtualAddress)
    cdef void invalidatePage(self, unsigned int virtualAddress)
    cdef unsigned char doPF(self, unsigned int virtualAddress, unsigned char written) except BITMASK_BYTE
    cdef unsigned char readAddresses(self, unsigned int virtualAddress, unsigned char written) except BITMASK_BYTE
    cdef unsigned char accessAllowed(self, unsigned int virtualAddress, unsigned char written, unsigned char refresh) except BITMASK_BYTE
    cdef unsigned char setFlags(self, unsigned int virtualAddress, unsigned int dataSize, unsigned char written) except BITMASK_BYTE
    cdef unsigned int getPhysicalAddress(self, unsigned int virtualAddress, unsigned int dataSize, unsigned char written) except? BITMASK_BYTE
    
cdef class Segments:
    cdef Hirnwichse main
    cdef Gdt gdt, ldt
    cdef Idt idt
    cdef Paging paging
    cdef Registers registers
    cdef Segment cs, ds, es, fs, gs, ss, tss
    cdef tuple segs
    cdef unsigned short ldtr
    cdef void reset(self) nogil
    cdef Segment getSegment(self, unsigned short segmentId, unsigned char checkForValidness)
    cdef GdtEntry getEntry(self, unsigned short num)
    cdef unsigned char getSegType(self, unsigned short num)
    cdef void setSegType(self, unsigned short num, unsigned char segmentType)
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment) except BITMASK_BYTE
    cdef unsigned char checkReadAllowed(self, unsigned short num)
    cdef unsigned char checkWriteAllowed(self, unsigned short num)
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned short segId) except BITMASK_BYTE
    cdef unsigned char inLimit(self, unsigned short num) nogil
    cdef void run(self)



