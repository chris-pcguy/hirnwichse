
from mm cimport Mm, ConfigSpace

include "globals.pxi"
include "cpu_globals.pxi"


cdef class Segment:
    cdef Segments segments
    cdef unsigned char accessByte, flags, isValid, segSize, segPresent, segIsCodeSeg, \
        segIsRW, segIsConforming, segIsNormal, segUse4K, segDPL, useGDT
    cdef unsigned short segmentIndex
    cdef unsigned int base, limit
    cdef void loadSegment(self, unsigned short segmentIndex, unsigned char protectedModeOn)
    cdef unsigned char getSegSize(self)
    cdef unsigned char isSegPresent(self)
    cdef unsigned char isCodeSeg(self)
    cdef unsigned char isSegReadableWritable(self)
    cdef unsigned char isSegConforming(self)
    cdef unsigned char isSysSeg(self)
    cdef unsigned char getSegDPL(self)
    cdef unsigned char isAddressInLimit(self, unsigned int address, unsigned int size)

cdef class GdtEntry:
    cdef Gdt gdt
    cdef unsigned char accessByte, flags, segSize, segPresent, segIsCodeSeg, segIsRW, \
        segIsConforming, segIsNormal, segUse4K, segDPL
    cdef unsigned int base, limit
    cdef void parseEntryData(self, unsigned long int entryData)
    cdef unsigned char isAddressInLimit(self, unsigned int address, unsigned int size)

cdef class IdtEntry:
    cdef unsigned char entryType, entrySize, entryNeededDPL, entryPresent
    cdef unsigned short entrySegment
    cdef unsigned int entryEip
    cdef void parseEntryData(self, unsigned long int entryData)


cdef class Gdt:
    cdef Segments segments
    cdef unsigned short tableLimit
    cdef unsigned int tableBase
    cdef inline void loadTablePosition(self, unsigned int tableBase, unsigned short tableLimit):
        if (tableLimit > GDT_HARD_LIMIT):
            self.segments.main.exitError("Gdt::loadTablePosition: tableLimit {0:#06x} > GDT_HARD_LIMIT {1:#06x}.", \
              tableLimit, GDT_HARD_LIMIT)
            return
        self.tableBase, self.tableLimit = tableBase, tableLimit
    cdef inline void getBaseLimit(self, unsigned int *retTableBase, unsigned short *retTableLimit):
        retTableBase[0] = self.tableBase
        retTableLimit[0] = self.tableLimit
    cdef GdtEntry getEntry(self, unsigned short num)
    cdef inline unsigned char getSegSize(self, unsigned short num):
        return self.getEntry(num).segSize
    cdef inline unsigned char getSegType(self, unsigned short num):
        return ((<Mm>self.segments.main.mm).mmPhyReadValueUnsignedByte(self.tableBase+num+5) & TABLE_ENTRY_SYSTEM_TYPE_MASK)
    cdef inline void setSegType(self, unsigned short num, unsigned char segmentType):
        (<Mm>self.segments.main.mm).mmPhyWriteValue(self.tableBase+num+5, ((((<Mm>self.segments.main.mm).\
          mmPhyReadValueUnsignedByte(self.tableBase+num+5) & (~TABLE_ENTRY_SYSTEM_TYPE_MASK)) | \
            (segmentType & TABLE_ENTRY_SYSTEM_TYPE_MASK))&BITMASK_BYTE), OP_SIZE_BYTE)
    cdef inline unsigned char isSegPresent(self, unsigned short num):
        return self.getEntry(num).segPresent
    cdef inline unsigned char isCodeSeg(self, unsigned short num):
        return self.getEntry(num).segIsCodeSeg
    ### isSegReadableWritable:
    ### if codeseg, return True if readable, else False
    ### if dataseg, return True if writable, else False
    cdef inline unsigned char isSegReadableWritable(self, unsigned short num):
        return self.getEntry(num).segIsRW
    cdef inline unsigned char isSegConforming(self, unsigned short num):
        return self.getEntry(num).segIsConforming
    cdef inline unsigned char getSegDPL(self, unsigned short num):
        return self.getEntry(num).segDPL
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment)
    cdef unsigned char checkReadAllowed(self, unsigned short num)
    cdef unsigned char checkWriteAllowed(self, unsigned short num)
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned short segId)

cdef class Idt:
    cdef Segments segments
    cdef unsigned short tableLimit
    cdef unsigned int tableBase
    cdef void loadTable(self, unsigned int tableBase, unsigned short tableLimit)
    cdef inline void getBaseLimit(self, unsigned int *retTableBase, unsigned short *retTableLimit):
        retTableBase[0] = self.tableBase
        retTableLimit[0] = self.tableLimit
    cdef IdtEntry getEntry(self, unsigned char num)
    cdef unsigned char isEntryPresent(self, unsigned char num)
    cdef unsigned char getEntryNeededDPL(self, unsigned char num)
    cdef unsigned char getEntrySize(self, unsigned char num)
    cdef void getEntryRealMode(self, unsigned char num, unsigned short *entrySegment, unsigned short *entryEip)

cdef class Paging:
    cdef Segments segments
    cdef unsigned char instrFetch
    cdef unsigned short pageOffset
    cdef void setInstrFetch(self)
    cdef unsigned int pageDirectoryOffset, pageTableOffset, pageDirectoryBaseAddress, pageDirectoryEntry, pageTableEntry
    cdef unsigned char doPF(self, unsigned int virtualAddress, unsigned char written) except 1
    cdef void invalidateTables(self, unsigned int pageDirectoryBaseAddress)
    cdef unsigned char readAddresses(self, unsigned int virtualAddress, unsigned char written) except -1
    cdef unsigned char writeAccessAllowed(self, unsigned int virtualAddress) except -1
    cdef unsigned char everyRingAccessAllowed(self, unsigned int virtualAddress) except -1
    cdef unsigned int getPhysicalAddress(self, unsigned int virtualAddress, unsigned char written) except? 0
    
cdef class Segments:
    cpdef object main
    cdef Gdt gdt, ldt
    cdef Idt idt
    cdef Paging paging
    cdef Segment cs, ds, es, fs, gs, ss, tss
    cdef tuple segs
    cdef unsigned short ldtr
    cdef void reset(self)
    cdef Segment getSegmentInstance(self, unsigned short segmentId, unsigned char checkForValidness)
    cdef GdtEntry getEntry(self, unsigned short num)
    cdef unsigned char isCodeSeg(self, unsigned short num)
    cdef unsigned char isSegReadableWritable(self, unsigned short num)
    cdef unsigned char isSegConforming(self, unsigned short num)
    cdef unsigned char isSegPresent(self, unsigned short num)
    cdef unsigned char getSegDPL(self, unsigned short num)
    cdef unsigned char getSegType(self, unsigned short num)
    cdef void setSegType(self, unsigned short num, unsigned char segmentType)
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment)
    cdef unsigned char checkReadAllowed(self, unsigned short num)
    cdef unsigned char checkWriteAllowed(self, unsigned short num)
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned short segId)
    cdef unsigned char inLimit(self, unsigned short num)
    cdef void run(self)



