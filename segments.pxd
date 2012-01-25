
from mm cimport Mm, ConfigSpace

cdef class Segment:
    cdef Segments segments
    cdef unsigned char accessByte, flags, isValid, segSize, segPresent, segIsCodeSeg, segIsRW, segIsConforming, segDPL
    cdef unsigned short segmentId
    cdef unsigned long base, limit
    cdef loadSegment(self, unsigned short segmentIndex)
    cdef unsigned char getSegSize(self)
    cdef unsigned char isSegPresent(self)
    cdef unsigned char isCodeSeg(self)
    cdef unsigned char isSegReadableWritable(self)
    cdef unsigned char isSegConforming(self)
    cdef unsigned char getSegDPL(self)
    cdef unsigned char isAddressInLimit(self, unsigned long address, unsigned long size)

cdef class GdtEntry:
    cdef unsigned char accessByte, flags, segSize, segPresent, segIsCodeSeg, segIsRW, segIsConforming, segDPL
    cdef unsigned long base, limit
    cdef parseEntryData(self, unsigned long long entryData)

cdef class IdtEntry:
    cdef unsigned char entryType, entrySize, entryNeededDPL, entryPresent
    cdef unsigned short entrySegment
    cdef unsigned long entryEip
    cdef parseEntryData(self, unsigned long long entryData)


cdef class Gdt:
    cdef Segments segments
    cdef ConfigSpace table
    cdef unsigned short tableLimit
    cdef unsigned long tableBase
    cdef reset(self)
    cdef loadTablePosition(self, unsigned long tableBase, unsigned short tableLimit)
    cdef loadTableData(self)
    cdef getBaseLimit(self, unsigned long *retTableBase, unsigned short *retTableLimit)
    cdef GdtEntry getEntry(self, unsigned short num)
    cdef unsigned char getSegSize(self, unsigned short num)
    cdef unsigned char getSegAccess(self, unsigned short num)
    cdef unsigned char isSegPresent(self, unsigned short num)
    cdef unsigned char isCodeSeg(self, unsigned short num)
    cdef unsigned char isSegReadableWritable(self, unsigned short num)
    cdef unsigned char isSegConforming(self, unsigned short num)
    cdef unsigned char getSegDPL(self, unsigned short num)
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment)
    cdef unsigned char checkReadAllowed(self, unsigned short num)
    cdef unsigned char checkWriteAllowed(self, unsigned short num)
    cdef checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment)
    cdef run(self)

cdef class Idt:
    cdef Segments segments
    cdef ConfigSpace table
    cdef unsigned short tableLimit
    cdef unsigned long tableBase
    cdef reset(self)
    cdef loadTable(self, unsigned long tableBase, unsigned short tableLimit)
    cdef getBaseLimit(self, unsigned long *retTableBase, unsigned short *retTableLimit)
    cdef IdtEntry getEntry(self, unsigned char num)
    cdef unsigned char isEntryPresent(self, unsigned char num)
    cdef unsigned char getEntryNeededDPL(self, unsigned char num)
    cdef unsigned char getEntrySize(self, unsigned char num)
    cdef getEntryRealMode(self, unsigned char num, unsigned short *entrySegment, unsigned short *entryEip)
    cdef run(self)

cdef class Segments:
    cpdef object main
    cdef Gdt gdt, ldt
    cdef Idt idt
    cdef Segment cs, ds, es, fs, gs, ss
    cdef unsigned char A20Active, protectedModeOn
    cdef unsigned short ldtr
    cdef reset(self)
    cdef unsigned char isInProtectedMode(self)
    cdef unsigned char getA20State(self)
    cdef setA20State(self, unsigned char state)
    cdef Segment getSegmentInstance(self, unsigned short segmentId)
    cdef GdtEntry getEntry(self, unsigned short num)
    cdef unsigned char getSegAccess(self, unsigned short num)
    cdef unsigned char isCodeSeg(self, unsigned short num)
    cdef unsigned char isSegReadableWritable(self, unsigned short num)
    cdef unsigned char isSegConforming(self, unsigned short num)
    cdef unsigned char getSegDPL(self, unsigned short num)
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment)
    cdef unsigned char checkReadAllowed(self, unsigned short num)
    cdef unsigned char checkWriteAllowed(self, unsigned short num)
    cdef checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment)
    cdef run(self)



