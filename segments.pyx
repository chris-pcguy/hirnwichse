
from misc import ChemuException

include "globals.pxi"
include "cpu_globals.pxi"


cdef class Segment:
    def __init__(self, Segments segments, unsigned short segmentId, unsigned short segmentIndex):
        self.segments = segments
        self.segmentId = segmentId
        self.isValid = False
        self.segSize = OP_SIZE_WORD
        self.loadSegment(segmentIndex)
    cdef void loadSegment(self, unsigned short segmentIndex):
        cdef GdtEntry gdtEntry
        self.segmentIndex = segmentIndex
        if (not self.segments.isInProtectedMode()):
            self.base = segmentIndex
            self.base <<= 4
            self.isValid = True
            return
        gdtEntry = (<GdtEntry>(<Gdt>self.segments.gdt).getEntry(segmentIndex))
        if (gdtEntry is None):
            self.isValid = False
            return
        self.base = gdtEntry.base
        self.limit = gdtEntry.limit
        self.accessByte = gdtEntry.accessByte
        self.flags = gdtEntry.flags
        self.segSize = gdtEntry.segSize
        self.isValid = True
        self.segPresent = gdtEntry.segPresent
        self.segIsCodeSeg = gdtEntry.segIsCodeSeg
        self.segIsRW = gdtEntry.segIsRW
        self.segIsConforming = gdtEntry.segIsConforming
        self.segDPL = gdtEntry.segDPL
    cdef unsigned char getSegSize(self):
        return self.segSize
    cdef unsigned char isSegPresent(self):
        return self.segPresent
    cdef unsigned char isCodeSeg(self):
        return self.segIsCodeSeg
    ### isSegReadableWritable:
    ### if codeseg, return True if readable, else False
    ### if dataseg, return True if writable, else False
    cdef unsigned char isSegReadableWritable(self):
        return self.segIsRW
    cdef unsigned char isSysSeg(self):
        return (not (self.accessByte & GDT_ACCESS_NORMAL_SEGMENT))
    cdef unsigned char isSegConforming(self):
        return self.segIsConforming
    cdef unsigned char getSegDPL(self):
        return self.segDPL


cdef class GdtEntry:
    def __init__(self, Gdt gdt, unsigned long int entryData):
        self.gdt = gdt
        self.parseEntryData(entryData)
    cdef void parseEntryData(self, unsigned long int entryData):
        self.accessByte = <unsigned char>(entryData>>40)
        self.flags  = (entryData>>52)&0xf
        self.base  = (entryData>>16)&0xffffff
        self.limit = entryData&0xffff
        self.base  |= (<unsigned char>(entryData>>56))<<24
        self.limit |= ((entryData>>48)&0xf)<<16
        # segment size: 1==32bit; 0==16bit; entrySize is 4 for 32bit and 2 for 16bit
        self.segSize = OP_SIZE_DWORD if (self.flags & GDT_FLAG_SIZE) else OP_SIZE_WORD
        self.segPresent = (self.accessByte & GDT_ACCESS_PRESENT)!=0
        self.segIsCodeSeg = (self.accessByte & GDT_ACCESS_EXECUTABLE)!=0
        self.segIsRW = (self.accessByte & GDT_ACCESS_READABLE_WRITABLE)!=0
        self.segIsConforming = (self.accessByte & GDT_ACCESS_CONFORMING)!=0
        self.segDPL = ((self.accessByte & GDT_ACCESS_DPL)>>5)&3
        if (self.flags & GDT_FLAG_LONGMODE): # TODO: int-mode isn't implemented yet...
            self.gdt.segments.main.exitError("Did you just tried to use int-mode?!? Maybe I'll implement it in a few decades...")
    cdef unsigned char isAddressInLimit(self, unsigned int address, unsigned int size):
        cdef unsigned int limit
        limit = self.limit
        if (self.flags & GDT_FLAG_USE_4K):
            limit <<= 12
        # TODO: handle the direction bit here.
        ## address is an offset.
        if ((address+size)>limit):
            return False
        return True

cdef class IdtEntry:
    def __init__(self, unsigned long int entryData):
        self.parseEntryData(entryData)
    cdef void parseEntryData(self, unsigned long int entryData):
        self.entryEip = entryData&0xffff # interrupt eip: lower word
        self.entryEip |= ((entryData>>48)&0xffff)<<16 # interrupt eip: upper word
        self.entrySegment = (entryData>>16)&0xffff # interrupt segment
        self.entryType = (entryData>>40)&0xf # interrupt type
        self.entryNeededDPL = (entryData>>45)&0x3 # interrupt: Need this DPL
        self.entryPresent = (entryData>>47)&1 # is interrupt present
        if (self.entryType in (TABLE_ENTRY_SYSTEM_TYPE_LDT, TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE, \
          TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY, \
          TABLE_ENTRY_SYSTEM_TYPE_32BIT_CALL_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE, \
          TABLE_ENTRY_SYSTEM_TYPE_32BIT_TRAP_GATE)):
            self.entrySize = OP_SIZE_DWORD
        else:
            self.entrySize = OP_SIZE_WORD


cdef class Gdt:
    def __init__(self, Segments segments):
        self.segments = segments
        self.tableBase = self.tableLimit = 0
    cdef void loadTablePosition(self, unsigned int tableBase, unsigned short tableLimit):
        if (tableLimit > GDT_HARD_LIMIT):
            self.segments.main.exitError("Gdt::loadTablePosition: tableLimit {0:#06x} > GDT_HARD_LIMIT {1:#06x}.",\
              tableLimit, GDT_HARD_LIMIT)
            return
        self.tableBase, self.tableLimit = tableBase, tableLimit
    cdef void getBaseLimit(self, unsigned int *retTableBase, unsigned short *retTableLimit):
        retTableBase[0] = self.tableBase
        retTableLimit[0] = self.tableLimit
    cdef GdtEntry getEntry(self, unsigned short num):
        cdef unsigned long int entryData
        num &= 0xfff8
        if (not num):
            ##self.segments.main.debug("GDT::getEntry: num == 0!")
            return None
        entryData = (<Mm>self.segments.main.mm).mmPhyReadValueUnsigned(self.tableBase+num, 8)
        return GdtEntry(self, entryData)
    cdef unsigned char getSegSize(self, unsigned short num):
        return self.getEntry(num).segSize
    cdef unsigned char getSegType(self, unsigned short num):
        return ((<Mm>self.segments.main.mm).mmPhyReadValueUnsigned(num+5, \
          OP_SIZE_BYTE) & TABLE_ENTRY_SYSTEM_TYPE_MASK)
    cdef void setSegType(self, unsigned short num, unsigned char segmentType):
        (<Mm>self.segments.main.mm).mmPhyWriteValue(num+5, (((<Mm>self.segments.main.mm).\
          mmPhyReadValueUnsigned(num+5, OP_SIZE_BYTE) & (~TABLE_ENTRY_SYSTEM_TYPE_MASK)) | \
            (segmentType & TABLE_ENTRY_SYSTEM_TYPE_MASK)), OP_SIZE_BYTE)
    cdef unsigned char isSegPresent(self, unsigned short num):
        return self.getEntry(num).segPresent
    cdef unsigned char isCodeSeg(self, unsigned short num):
        return self.getEntry(num).segIsCodeSeg
    ### isSegReadableWritable:
    ### if codeseg, return True if readable, else False
    ### if dataseg, return True if writable, else False
    cdef unsigned char isSegReadableWritable(self, unsigned short num):
        return self.getEntry(num).segIsRW
    cdef unsigned char isSegConforming(self, unsigned short num):
        return self.getEntry(num).segIsConforming
    cdef unsigned char getSegDPL(self, unsigned short num):
        return self.getEntry(num).segDPL
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment):
        cdef unsigned char cpl
        cdef GdtEntry gdtEntry
        if (not (num&0xfff8) or num > self.tableLimit):
            if (not (num&0xfff8)):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            else:
                raise ChemuException(CPU_EXCEPTION_GP, num)
        cpl = self.segments.cs.segmentIndex&3
        gdtEntry = self.getEntry(num)
        if (not gdtEntry or (isStackSegment and ( num&3 != cpl or \
          gdtEntry.segDPL != cpl))):# or 0):
            raise ChemuException(CPU_EXCEPTION_GP, num)
        elif (not gdtEntry.segPresent):
            if (isStackSegment):
                raise ChemuException(CPU_EXCEPTION_SS, num)
            else:
                raise ChemuException(CPU_EXCEPTION_NP, num)
        return True
    cdef unsigned char checkReadAllowed(self, unsigned short num): # for VERR
        cdef unsigned char rpl
        cdef GdtEntry gdtEntry
        rpl = num&3
        num &= 0xfff8
        if (num == 0 or num > self.tableLimit):
            return False
        gdtEntry = self.getEntry(num)
        if (not gdtEntry):
            return False
        if (((self.getSegType(num) == 0) or not gdtEntry.segIsConforming) and \
          ((self.segments.cs.segmentIndex&3 > gdtEntry.segDPL) or (rpl > gdtEntry.segDPL))):
            return False
        if (gdtEntry.segIsCodeSeg and not gdtEntry.segIsRW):
            return False
        return True
    cdef unsigned char checkWriteAllowed(self, unsigned short num): # for VERW
        cdef unsigned char rpl
        cdef GdtEntry gdtEntry
        rpl = num&3
        num &= 0xfff8
        if (num == 0 or num > self.tableLimit):
            return False
        gdtEntry = self.getEntry(num)
        if (not gdtEntry):
            return False
        if (((self.getSegType(num) == 0) or not gdtEntry.segIsConforming) and \
          ((self.segments.cs.segmentIndex&3 > gdtEntry.segDPL) or (rpl > gdtEntry.segDPL))):
            return False
        if (not gdtEntry.segIsCodeSeg and gdtEntry.segIsRW):
            return True
        return False
    cdef void checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment):
        cdef unsigned char numSegDPL, cpl
        cdef GdtEntry gdtEntry
        if (not (num&0xfff8) or num > self.tableLimit):
            if (loadStackSegment):
                if (not (num&0xfff8)):
                    raise ChemuException(CPU_EXCEPTION_GP, 0)
                else:
                    raise ChemuException(CPU_EXCEPTION_GP, num)
            return
        gdtEntry = self.getEntry(num)
        if (not gdtEntry):
            if (loadStackSegment):
                raise ChemuException(CPU_EXCEPTION_GP, num)
            return
        cpl = self.segments.cs.segmentIndex&3
        numSegDPL = gdtEntry.segDPL
        if (not gdtEntry.segPresent):
            if (loadStackSegment):
                raise ChemuException(CPU_EXCEPTION_SS, num)
            else:
                raise ChemuException(CPU_EXCEPTION_NP, num)
        elif (loadStackSegment):
            if ((num&3 != cpl or numSegDPL != cpl) or \
              (not gdtEntry.segIsCodeSeg and not gdtEntry.segIsRW)):
                raise ChemuException(CPU_EXCEPTION_GP, num)
        else: # not loadStackSegment
            if ( ((not gdtEntry.segIsCodeSeg or not gdtEntry.segIsConforming) and (num&3 > numSegDPL and \
              cpl > numSegDPL)) or (gdtEntry.segIsCodeSeg and not gdtEntry.segIsRW) ):
                raise ChemuException(CPU_EXCEPTION_GP, num)


cdef class Idt:
    def __init__(self, Segments segments):
        self.segments = segments
        self.tableBase = self.tableLimit = 0
    cdef void loadTable(self, unsigned int tableBase, unsigned short tableLimit):
        if (tableLimit > IDT_HARD_LIMIT):
            self.segments.main.exitError("Idt::loadTablePosition: tableLimit {0:#06x} > IDT_HARD_LIMIT {1:#06x}.",\
              tableLimit, IDT_HARD_LIMIT)
            return
        self.tableBase, self.tableLimit = tableBase, tableLimit
        if (self.segments.protectedModeOn and not self.tableLimit and self.tableBase):
            self.segments.main.exitError("Idt::loadTable: tableLimit is zero.")
            return
    cdef void getBaseLimit(self, unsigned int *retTableBase, unsigned short *retTableLimit):
        retTableBase[0] = self.tableBase
        retTableLimit[0] = self.tableLimit
    cdef IdtEntry getEntry(self, unsigned char num):
        if (not self.tableLimit):
            self.segments.main.exitError("Idt::getEntry: tableLimit is zero.")
        return IdtEntry(<unsigned long int>(<Mm>self.segments.main.mm).mmPhyReadValueUnsigned(self.tableBase+(num*8), 8))
    cdef unsigned char isEntryPresent(self, unsigned char num):
        return self.getEntry(num).entryPresent
    cdef unsigned char getEntryNeededDPL(self, unsigned char num):
        return self.getEntry(num).entryNeededDPL
    cdef unsigned char getEntrySize(self, unsigned char num):
        # interrupt size: 1==32bit; 0==16bit; return 4 for 32bit, 2 for 16bit
        return self.getEntry(num).entrySize
    cdef void getEntryRealMode(self, unsigned char num, unsigned short *entrySegment, unsigned short *entryEip):
        cdef unsigned short offset
        offset = num*4 # Don't use ConfigSpace here.
        entryEip[0] = (<Mm>self.segments.main.mm).mmPhyReadValueUnsigned(offset, 2)
        entrySegment[0] = (<Mm>self.segments.main.mm).mmPhyReadValueUnsigned(offset+2, 2)




cdef class Tss:
    def __init__(self, Segments segments):
        self.segments = segments
        self.tableBase = self.tableLimit = 0
    cdef void loadTablePosition(self, unsigned int tableBase, unsigned short tableLimit):
        self.tableBase, self.tableLimit = tableBase, tableLimit
    cdef void getBaseLimit(self, unsigned int *retTableBase, unsigned short *retTableLimit):
        retTableBase[0] = self.tableBase
        retTableLimit[0] = self.tableLimit



cdef class Segments:
    def __init__(self, object main):
        self.main = main
        self.ldtr = self.tr = 0
    cdef void reset(self):
        self.ldtr = self.tr = 0
        self.A20Active = True # enable A20-line by default.
        self.protectedModeOn = False
    cdef unsigned char isInProtectedMode(self):
        return self.protectedModeOn
    cdef unsigned char getA20State(self):
        return self.A20Active
    cdef void setA20State(self, unsigned char state):
        self.A20Active = state
    cdef Segment getSegmentInstance(self, unsigned short segmentId, unsigned char checkForValidness):
        cdef Segment segment
        if (segmentId == CPU_SEGMENT_CS):
            segment = self.cs
        elif (segmentId == CPU_SEGMENT_DS):
            segment = self.ds
        elif (segmentId == CPU_SEGMENT_ES):
            segment = self.es
        elif (segmentId == CPU_SEGMENT_FS):
            segment = self.fs
        elif (segmentId == CPU_SEGMENT_GS):
            segment = self.gs
        elif (segmentId == CPU_SEGMENT_SS):
            segment = self.ss
        else:
            self.main.exitError("Segments::getSegmentInstance: invalid segmentId {0:d}", segmentId)
            raise ValueError("Segments::getSegmentInstance: invalid segmentId {0:d}".format(segmentId))
        if (checkForValidness and not segment.isValid):
            self.main.notice("Segments::getSegmentInstance: segment with ID {0:d} isn't valid.", segmentId)
            raise ChemuException(CPU_EXCEPTION_GP, segment.segmentIndex)
        return segment
    cdef GdtEntry getEntry(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return <GdtEntry>self.ldt.getEntry(num)
        return <GdtEntry>self.gdt.getEntry(num)
    cdef unsigned char isCodeSeg(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.isCodeSeg(num)
        return self.gdt.isCodeSeg(num)
    cdef unsigned char isSegReadableWritable(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.isSegReadableWritable(num)
        return self.gdt.isSegReadableWritable(num)
    cdef unsigned char isSegConforming(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.isSegConforming(num)
        return self.gdt.isSegConforming(num)
    cdef unsigned char getSegDPL(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.getSegDPL(num)
        return self.gdt.getSegDPL(num)
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkAccessAllowed(num, isStackSegment)
        return self.gdt.checkAccessAllowed(num, isStackSegment)
    cdef unsigned char checkReadAllowed(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkReadAllowed(num)
        return self.gdt.checkReadAllowed(num)
    cdef unsigned char checkWriteAllowed(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkWriteAllowed(num)
        return self.gdt.checkWriteAllowed(num)
    cdef void checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment):
        if (num & SELECTOR_USE_LDT):
            self.ldt.checkSegmentLoadAllowed(num, loadStackSegment)
            return
        self.gdt.checkSegmentLoadAllowed(num, loadStackSegment)
    cdef void run(self):
        self.gdt = Gdt(self)
        self.ldt = Gdt(self)
        self.idt = Idt(self)
        self.tss = Tss(self)
        self.cs = Segment(self, CPU_SEGMENT_CS, 0)
        self.ds = Segment(self, CPU_SEGMENT_DS, 0)
        self.es = Segment(self, CPU_SEGMENT_ES, 0)
        self.fs = Segment(self, CPU_SEGMENT_FS, 0)
        self.gs = Segment(self, CPU_SEGMENT_GS, 0)
        self.ss = Segment(self, CPU_SEGMENT_SS, 0)



