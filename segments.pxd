

cdef class Gdt:
    cdef Segments segments
    cdef unsigned char needFlush, setGdtLoadedTo, gdtLoaded
    cdef unsigned long long tableBase
    cdef unsigned long tableLimit
    cdef loadTable(self, unsigned long long tableBase, unsigned long tableLimit)
    cdef tuple getBaseLimit(self)
    cdef tuple getEntry(self, unsigned short num)
    cdef unsigned char getSegSize(self, unsigned short num)
    cdef unsigned char getSegAccess(self, unsigned short num)
    cdef unsigned char isSegPresent(self, unsigned short num)
    cdef unsigned char isCodeSeg(self, unsigned short num)
    cdef unsigned char isSegReadableWritable(self, unsigned short num)
    cdef unsigned char isSegConforming(self, unsigned short num)
    cdef unsigned char getSegDPL(self, unsigned short num)
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment)
    cdef unsigned char checkReadAllowed(self, unsigned short num, unsigned char doException)
    cdef unsigned char checkWriteAllowed(self, unsigned short num, unsigned char doException)
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment, unsigned char doException)

cdef class Idt:
    cdef Segments segments
    cdef unsigned long long tableBase
    cdef unsigned long tableLimit
    cdef loadTable(self, unsigned long long tableBase, unsigned long tableLimit)
    cdef tuple getBaseLimit(self)
    cdef tuple getEntry(self, unsigned short num)
    cdef unsigned char isEntryPresent(self, unsigned short num)
    cdef unsigned char getEntryNeededDPL(self, unsigned short num)
    cdef unsigned char getEntrySize(self, unsigned short num)
    cdef tuple getEntryRealMode(self, unsigned short num)
    cdef run(self, unsigned long long tableBase, unsigned long tableLimit)

cdef class Segments:
    cpdef object main
    cdef Gdt gdt, ldt
    cdef Idt idt
    cdef reset(self)
    cdef tuple getEntry(self, unsigned short num)
    cdef unsigned char getSegAccess(self, unsigned short num)
    cdef unsigned char isCodeSeg(self, unsigned short num)
    cdef unsigned char isSegReadableWritable(self, unsigned short num)
    cdef unsigned char isSegConforming(self, unsigned short num)
    cdef unsigned char getSegDPL(self, unsigned short num)
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment)
    cdef unsigned char checkReadAllowed(self, unsigned short num, unsigned char doException)
    cdef unsigned char checkWriteAllowed(self, unsigned short num, unsigned char doException)
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment, unsigned char doException)
    cdef run(self)



