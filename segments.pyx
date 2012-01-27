
from misc import ChemuException

include "globals.pxi"

cdef class Segment:
    def __init__(self, Segments segments, unsigned short segmentId, unsigned short segmentIndex):
        self.segments = segments
        self.segmentId = segmentId
        self.isValid = False
        self.loadSegment(segmentIndex)
    cdef loadSegment(self, unsigned short segmentIndex):
        cdef GdtEntry gdtEntry
        if (not self.segments.isInProtectedMode()):
            self.base = segmentIndex
            self.base <<= 4
            self.limit = 0xffff
            self.accessByte = (GDT_ACCESS_PRESENT | GDT_ACCESS_NORMAL_SEGMENT | GDT_ACCESS_READABLE_WRITABLE)
            if (self.segmentId == CPU_SEGMENT_CS):
                self.accessByte |= GDT_ACCESS_EXECUTABLE
                self.segIsCodeSeg = True
            else:
                self.segIsCodeSeg = False
            self.flags = 0
            self.isValid = True
            self.segSize = OP_SIZE_WORD
            self.segPresent = True
            self.segIsRW = True
            self.segIsConforming = False
            self.segDPL = 0
            return
        gdtEntry = (<GdtEntry>(<Gdt>self.segments.gdt).getEntry(segmentIndex))
        if (gdtEntry is None):
            self.base = 0
            self.limit = 0
            self.accessByte = 0
            self.flags = 0
            self.isValid = False
            self.segSize = 0
            self.segPresent = False
            self.segIsCodeSeg = False
            self.segIsRW = False
            self.segIsConforming = False
            self.segDPL = 0
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
    cdef unsigned char isSegConforming(self):
        return self.segIsConforming
    cdef unsigned char getSegDPL(self):
        return self.segDPL
    cdef unsigned char isAddressInLimit(self, unsigned long address, unsigned long size):
        cdef unsigned long limit
        limit = self.limit
        if (self.flags & GDT_FLAG_USE_4K):
            limit *= 4096
        # TODO: handle the direction bit here.
        if ((address < self.base) or ((address+size)>(self.base+limit))):
            return False
        return True



cdef class GdtEntry:
    def __init__(self, unsigned long long entryData):
        self.parseEntryData(entryData)
    cdef parseEntryData(self, unsigned long long entryData):
        self.accessByte = (entryData>>40)&BITMASK_BYTE
        self.flags  = (entryData>>52)&0xf
        self.base  = ( (entryData>>56)&BITMASK_BYTE)<<24
        self.limit = (( entryData>>48)&0xf)<<16
        self.base  |= (entryData>>16)&0xffffff
        self.limit |= entryData&BITMASK_WORD
        if (self.flags & GDT_FLAG_SIZE): # segment size: 1==32bit; 0==16bit; entrySize is 4 for 32bit and 2 for 16bit
            self.segSize = OP_SIZE_DWORD
        else:
            self.segSize = OP_SIZE_WORD
        self.segPresent = (self.accessByte&GDT_ACCESS_PRESENT)!=0
        self.segIsCodeSeg = (self.accessByte&GDT_ACCESS_EXECUTABLE)!=0
        self.segIsRW = (self.accessByte&GDT_ACCESS_READABLE_WRITABLE)!=0
        self.segIsConforming = (self.accessByte&GDT_ACCESS_CONFORMING)!=0
        self.segDPL = (self.accessByte&GDT_ACCESS_DPL)>>5
        if (self.flags & GDT_FLAG_LONGMODE): # TODO: long-mode isn't implemented yet...
            self.main.exitError("Do you just tried to use long-mode?!? It will take a VERY LONG TIME until it get implemented...")

cdef class IdtEntry:
    def __init__(self, unsigned long long entryData):
        self.parseEntryData(entryData)
    cdef parseEntryData(self, unsigned long long entryData):
        self.entryEip = ((entryData>>48)&BITMASK_WORD)<<16 # interrupt eip: upper word
        self.entryEip |= entryData&BITMASK_WORD # interrupt eip: lower word
        self.entrySegment = (entryData>>16)&BITMASK_WORD # interrupt segment
        self.entryType = (entryData>>40)&0x7 # interrupt type
        self.entryNeededDPL = (entryData>>45)&0x3 # interrupt: Need this DPL
        self.entryPresent = (entryData>>47)&1 # is interrupt present
        if ((entryData>>43)&1): # interrupt size: 1==32bit; 0==16bit; entrySize is 4 for 32bit and 2 for 16bit
            self.entrySize = OP_SIZE_DWORD
        else:
            self.entrySize = OP_SIZE_WORD

cdef class Gdt:
    def __init__(self, Segments segments):
        self.segments = segments
    cdef reset(self):
        self.table.csResetData()
    cdef loadTablePosition(self, unsigned long tableBase, unsigned short tableLimit):
        self.tableBase, self.tableLimit = tableBase, tableLimit
    cdef loadTableData(self):
        self.table.csWrite(0, (<Mm>self.segments.main.mm).mmPhyRead(self.tableBase, \
                            (<unsigned long>self.tableLimit+1)), (<unsigned long>self.tableLimit+1))
    cdef getBaseLimit(self, unsigned long *retTableBase, unsigned short *retTableLimit):
        retTableBase[0] = self.tableBase
        retTableLimit[0] = self.tableLimit
    cdef GdtEntry getEntry(self, unsigned short num):
        cdef unsigned long long entryData
        if (not num):
            self.segments.main.debug("GDT::getEntry: num == 0!")
            return None
        entryData = self.table.csReadValueUnsigned((num&0xfff8), 8)
        return GdtEntry(entryData)
    cdef unsigned char getSegSize(self, unsigned short num):
        return self.getEntry(num).segSize
    cdef unsigned char getSegAccess(self, unsigned short num):
        return self.getEntry(num).accessByte
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
        if (num == 0 or \
            (isStackSegment and ( num&3 != self.segments.main.cpu.registers.cpl or self.getSegDPL(num) != self.segments.main.cpu.registers.cpl)) or \
            0):
            raise ChemuException(CPU_EXCEPTION_GP, num)
        elif (not self.isSegPresent(num)):
            if (isStackSegment):
                raise ChemuException(CPU_EXCEPTION_SS, num)
            else:
                raise ChemuException(CPU_EXCEPTION_NP, num)
    cdef unsigned char checkReadAllowed(self, unsigned short num):
        if (num&0xfff8 == 0 or (self.isCodeSeg(num) and not self.isSegReadableWritable(num))):
            return False
        return True
    cdef unsigned char checkWriteAllowed(self, unsigned short num):
        if (num&0xfff8 == 0 or self.isCodeSeg(num) or not self.isSegReadableWritable(num)):
            return False
        return True
    cdef checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment):
        cdef unsigned char numSegDPL = self.getSegDPL(num)
        if (num&0xfff8 == 0):
            if (loadStackSegment):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
        elif (not self.isSegPresent(num)):
            if (loadStackSegment):
                raise ChemuException(CPU_EXCEPTION_SS, num)
            else:
                raise ChemuException(CPU_EXCEPTION_NP, num)
        elif (loadStackSegment):
            if ((num&3 != self.segments.main.cpu.registers.cpl or numSegDPL != self.segments.main.cpu.registers.cpl) or \
                (not self.isCodeSeg(num) and not self.isSegReadableWritable(num))):
                  raise ChemuException(CPU_EXCEPTION_GP, num)
        else: # not loadStackSegment
            if ( ((not self.isCodeSeg(num) or not self.isSegConforming(num)) and (num&3 > numSegDPL and \
                self.segments.main.cpu.registers.cpl > numSegDPL)) or \
                (self.isCodeSeg(num) and not self.isSegReadableWritable(num)) ):
                  raise ChemuException(CPU_EXCEPTION_GP, num)
    cdef run(self):
        self.table = ConfigSpace((<unsigned long>GDT_HARD_LIMIT+1), self.segments.main)
        self.table.run()


cdef class Idt:
    def __init__(self, Segments segments):
        self.segments = segments
    cdef reset(self):
        self.table.csResetData()
    cdef loadTable(self, unsigned long tableBase, unsigned short tableLimit):
        self.tableBase, self.tableLimit = tableBase, tableLimit
        if (self.tableLimit > IDT_HARD_LIMIT):
            self.segments.main.exitError("IDT::loadTablePosition: tableLimit {0:#06x} > IDT_HARD_LIMIT {1:#06x}.",\
               self.tableLimit, IDT_HARD_LIMIT)
            return
        self.table.csWrite(0, (<Mm>self.segments.main.mm).mmPhyRead(self.tableBase, \
                            (<unsigned long>self.tableLimit+1)), (<unsigned long>self.tableLimit+1))
    cdef getBaseLimit(self, unsigned long *retTableBase, unsigned short *retTableLimit):
        retTableBase[0] = self.tableBase
        retTableLimit[0] = self.tableLimit
    cdef IdtEntry getEntry(self, unsigned char num):
        cdef unsigned long long entryData
        entryData = self.table.csReadValueUnsigned((num*8), 8)
        return IdtEntry(entryData)
    cdef unsigned char isEntryPresent(self, unsigned char num):
        return (<unsigned char>self.table.csReadValueUnsigned((num*8)+2, 1)>>7)&1 # is interrupt present
    cdef unsigned char getEntryNeededDPL(self, unsigned char num):
        return (<unsigned char>self.table.csReadValueUnsigned((num*8)+2, 1)>>5)&0x3 # interrupt: Need this DPL
    cdef unsigned char getEntrySize(self, unsigned char num):
        # interrupt size: 1==32bit; 0==16bit; return 4 for 32bit, 2 for 16bit
        if ((<unsigned char>self.table.csReadValueUnsigned((num*8)+2, 1)>>3)&1):
            return OP_SIZE_DWORD
        return OP_SIZE_WORD
    cdef getEntryRealMode(self, unsigned char num, unsigned short *entrySegment, unsigned short *entryEip):
        cdef unsigned short offset
        offset = num*4 # Don't use ConfigSpace here.
        entryEip[0] = (<Mm>self.segments.main.mm).mmPhyReadValueUnsigned(offset, 2)
        entrySegment[0] = (<Mm>self.segments.main.mm).mmPhyReadValueUnsigned(offset+2, 2)
    cdef run(self):
        self.table = ConfigSpace((<unsigned long>IDT_HARD_LIMIT+1), self.segments.main)
        self.table.run()

cdef class Segments:
    def __init__(self, object main):
        self.main = main
        self.ldtr = 0
    cdef reset(self):
        self.gdt.reset()
        self.ldt.reset()
        self.idt.reset()
        self.ldtr = 0
        self.A20Active = True # enable A20-line by default.
        self.protectedModeOn = False
    cdef unsigned char isInProtectedMode(self):
        return self.protectedModeOn
    cdef unsigned char getA20State(self):
        return self.A20Active
    cdef setA20State(self, unsigned char state):
        self.A20Active = state
    cdef Segment getSegmentInstance(self, unsigned short segmentId):
        if (segmentId == CPU_SEGMENT_CS):
            if (not (<Segment>self.cs).isValid):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            return self.cs
        elif (segmentId == CPU_SEGMENT_DS):
            if (not (<Segment>self.ds).isValid):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            return self.ds
        elif (segmentId == CPU_SEGMENT_ES):
            if (not (<Segment>self.es).isValid):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            return self.es
        elif (segmentId == CPU_SEGMENT_FS):
            if (not (<Segment>self.fs).isValid):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            return self.fs
        elif (segmentId == CPU_SEGMENT_GS):
            if (not (<Segment>self.gs).isValid):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            return self.gs
        elif (segmentId == CPU_SEGMENT_SS):
            if (not (<Segment>self.ss).isValid):
                raise ChemuException(CPU_EXCEPTION_SS, 0)
            return self.ss
        else:
            self.main.exitError("invalid segmentId {0:d}", segmentId)
            raise ValueError("invalid segmentId {0:d}".format(segmentId))
    cdef GdtEntry getEntry(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return <GdtEntry>self.ldt.getEntry(num)
        return <GdtEntry>self.gdt.getEntry(num)
    cdef unsigned char getSegAccess(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.getSegAccess(num)
        return self.gdt.getSegAccess(num)
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
    cdef checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment):
        if (num & SELECTOR_USE_LDT):
            self.ldt.checkSegmentLoadAllowed(num, loadStackSegment)
            return
        self.gdt.checkSegmentLoadAllowed(num, loadStackSegment)
    cdef run(self):
        self.gdt = Gdt(self)
        self.ldt = Gdt(self)
        self.idt = Idt(self)
        self.gdt.run()
        self.ldt.run()
        self.idt.run()
        self.cs = Segment(self, CPU_SEGMENT_CS, 0)
        self.ds = Segment(self, CPU_SEGMENT_DS, 0)
        self.es = Segment(self, CPU_SEGMENT_ES, 0)
        self.fs = Segment(self, CPU_SEGMENT_FS, 0)
        self.gs = Segment(self, CPU_SEGMENT_GS, 0)
        self.ss = Segment(self, CPU_SEGMENT_SS, 0)



