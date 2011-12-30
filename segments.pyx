
import misc

include "globals.pxi"


cdef class Gdt:
    def __init__(self, Segments segments):
        self.segments = segments
    cdef reset(self):
        self.table.csResetData()
    cdef loadTablePosition(self, unsigned long long tableBase, unsigned short tableLimit):
        self.tableBase, self.tableLimit = tableBase, tableLimit
        if (self.tableLimit >= GDT_HARD_LIMIT):
            self.segments.main.exitError("GDT::loadTablePosition: tableLimit {0:#06x} >= GDT_HARD_LIMIT {1:#06x}.",\
               self.tableLimit, GDT_HARD_LIMIT)
            return
        self.tableLimit += 1 # move the increment up could cause an overflow
    cdef loadTableData(self):
        self.table.csWrite(0, (<Mm>self.segments.main.mm).mmPhyRead(self.tableBase, self.tableLimit), self.tableLimit)
    cdef tuple getBaseLimit(self):
        return self.tableBase, self.tableLimit
    cdef tuple getEntry(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned long base, limit
        cdef unsigned char accessByte, flags
        if (not num):
            self.segments.main.exitError("GDT::getEntry: num == 0!")
            return None
        entryData = self.table.csReadValueUnsigned((num&0xfff8), 8)
        limit = entryData&BITMASK_WORD
        base  = (entryData>>16)&0xffffff
        accessByte = (entryData>>40)&BITMASK_BYTE
        flags  = (entryData>>52)&0xf
        limit |= (( entryData>>48)&0xf)<<16
        base  |= ( (entryData>>56)&BITMASK_BYTE)<<24
        return base, limit, accessByte, flags
    cdef unsigned char getSegSize(self, unsigned short num):
        cdef tuple entryRet
        cdef unsigned long base, limit
        cdef unsigned char accessByte, flags
        entryRet = self.getEntry(num)
        base, limit, accessByte, flags = entryRet
        if (flags & GDT_FLAG_SIZE):
            return OP_SIZE_DWORD
        return OP_SIZE_WORD
    cdef unsigned char getSegAccess(self, unsigned short num):
        cdef tuple entryRet
        cdef unsigned char accessByte
        entryRet = self.getEntry(num)
        accessByte = entryRet[2]
        return accessByte
    cdef unsigned char isSegPresent(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_PRESENT)!=0
    cdef unsigned char isCodeSeg(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_EXECUTABLE)!=0
    ### isSegReadableWritable:
    ### if codeseg, return True if readable, else False
    ### if dataseg, return True if writable, else False
    cdef unsigned char isSegReadableWritable(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_READABLE_WRITABLE)!=0
    cdef unsigned char isSegConforming(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_CONFORMING)!=0
    cdef unsigned char getSegDPL(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_DPL)&3
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment):
        if (num == 0 or \
            (isStackSegment and ( num&3 != self.segments.main.cpu.registers.cpl or self.getSegDPL(num) != self.segments.main.cpu.registers.cpl)) or \
            0):
            raise misc.ChemuException(CPU_EXCEPTION_GP, num)
        elif (not self.isSegPresent(num)):
            if (isStackSegment):
                raise misc.ChemuException(CPU_EXCEPTION_SS, num)
            else:
                raise misc.ChemuException(CPU_EXCEPTION_NP, num)
    cdef unsigned char checkReadAllowed(self, unsigned short num, unsigned char doException):
        if (num&0xfff8 == 0 or (self.isCodeSeg(num) and not self.isSegReadableWritable(num))):
            if (doException):
                raise misc.ChemuException(CPU_EXCEPTION_GP, 0)
            return False
        return True
    cdef unsigned char checkWriteAllowed(self, unsigned short num, unsigned char doException):
        if (num&0xfff8 == 0 or self.isCodeSeg(num) or not self.isSegReadableWritable(num)):
            if (doException):
                raise misc.ChemuException(CPU_EXCEPTION_GP, 0)
            return False
        return True
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment, unsigned char doException):
        cdef unsigned char numSegDPL = self.getSegDPL(num)
        if (num&0xfff8 == 0 and loadStackSegment):
            if (doException):
                raise misc.ChemuException(CPU_EXCEPTION_GP, num)
            return False
        elif (not self.isSegPresent(num)):
            if (doException):
                if (loadStackSegment):
                    raise misc.ChemuException(CPU_EXCEPTION_SS, num)
                else:
                    raise misc.ChemuException(CPU_EXCEPTION_NP, num)
            return False
        elif (loadStackSegment):
            if ((num&3 != self.segments.main.cpu.registers.cpl or numSegDPL != self.segments.main.cpu.registers.cpl) or \
                (not self.isCodeSeg(num) and not self.isSegReadableWritable(num))):
                  if (doException):
                      raise misc.ChemuException(CPU_EXCEPTION_GP, num)
                  return False
        else: # not loadStackSegment
            if ( ((not self.isCodeSeg(num) or not self.isSegConforming(num)) and (num&3 > numSegDPL and self.segments.main.cpu.registers.cpl > numSegDPL)) or \
                 (self.isCodeSeg(num) and not self.isSegReadableWritable(num)) ):
                if (doException):
                    raise misc.ChemuException(CPU_EXCEPTION_GP, num)
                return False
        return True
    cdef run(self):
        self.table = ConfigSpace(GDT_HARD_LIMIT)
        self.table.run()


cdef class Idt:
    def __init__(self, Segments segments):
        self.segments = segments
    cdef reset(self):
        self.table.csResetData()
    cdef loadTable(self, unsigned long long tableBase, unsigned short tableLimit):
        self.tableBase, self.tableLimit = tableBase, tableLimit
        if (self.tableLimit >= IDT_HARD_LIMIT):
            self.segments.main.exitError("IDT::loadTablePosition: tableLimit {0:#06x} >= IDT_HARD_LIMIT {1:#06x}.",\
               self.tableLimit, IDT_HARD_LIMIT)
            return
        self.tableLimit += 1 # move the increment up could cause an overflow
        self.table.csWrite(0, (<Mm>self.segments.main.mm).mmPhyRead(self.tableBase, self.tableLimit), self.tableLimit)
    cdef tuple getBaseLimit(self):
        return self.tableBase, self.tableLimit
    cdef tuple getEntry(self, unsigned char num):
        cdef unsigned long long entryData
        cdef unsigned long entryEip
        cdef unsigned short entrySegment
        cdef unsigned char entryType, entrySize, entryNeededDPL, entryPresent
        entryData = (<Mm>self.segments.main.mm).mmPhyReadValueUnsigned((num*8), 8)
        entryEip = ((entryData>>48)&BITMASK_WORD) # interrupt eip: upper word
        entryEip <<= 16
        entryEip |= entryData&BITMASK_WORD # interrupt eip: lower word
        entrySegment = (entryData>>16)&BITMASK_WORD # interrupt segment
        entryType = (entryData>>40)&0x7 # interrupt type
        entryNeededDPL = (entryData>>45)&0x3 # interrupt: Need this DPL
        entryPresent = (entryData>>47)&1 # is interrupt present
        entrySize = (entryData>>43)&1 # interrupt size: 1==32bit; 0==16bit; entrySize is 4 for 32bit, 2 for 16bit
        if (entrySize!=0): entrySize = OP_SIZE_DWORD
        else: entrySize = OP_SIZE_WORD
        return entrySegment, entryEip, entryType, entrySize, entryNeededDPL, entryPresent
    cdef unsigned char isEntryPresent(self, unsigned char num):
        cdef unsigned long long entryData
        cdef unsigned char entryPresent
        entryData = self.table.csReadValueUnsigned((num*8), 8)
        entryPresent = (entryData>>47)&1 # is interrupt present
        return entryPresent
    cdef unsigned char getEntryNeededDPL(self, unsigned char num):
        cdef unsigned long long entryData
        cdef unsigned char entryPresent
        entryData = self.table.csReadValueUnsigned((num*8), 8)
        entryNeededDPL = (entryData>>45)&0x3 # interrupt: Need this DPL
        return entryNeededDPL
    cdef unsigned char getEntrySize(self, unsigned char num):
        cdef unsigned long long entryData
        cdef unsigned char entrySize
        entryData = self.table.csReadValueUnsigned((num*8), 8)
        entrySize = (entryData>>43)&1 # interrupt size: 1==32bit; 0==16bit; return 4 for 32bit, 2 for 16bit
        if (entrySize!=0): entrySize = OP_SIZE_DWORD
        else: entrySize = OP_SIZE_WORD
        return entrySize
    cdef tuple getEntryRealMode(self, unsigned char num):
        cdef unsigned short offset, entrySegment, entryEip
        offset = num*4 # Don't use ConfigSpace here.
        entryEip = (<Mm>self.segments.main.mm).mmPhyReadValueUnsigned(offset, 2)
        entrySegment = (<Mm>self.segments.main.mm).mmPhyReadValueUnsigned(offset+2, 2)
        return entrySegment, entryEip
    cdef run(self):
        self.table = ConfigSpace(IDT_HARD_LIMIT)
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
    cdef tuple getEntry(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.getEntry(num)
        return self.gdt.getEntry(num)
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
    cdef unsigned char checkReadAllowed(self, unsigned short num, unsigned char doException):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkReadAllowed(num, doException)
        return self.gdt.checkReadAllowed(num, doException)
    cdef unsigned char checkWriteAllowed(self, unsigned short num, unsigned char doException):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkWriteAllowed(num, doException)
        return self.gdt.checkWriteAllowed(num, doException)
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment, unsigned char doException):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkSegmentLoadAllowed(num, loadStackSegment, doException)
        return self.gdt.checkSegmentLoadAllowed(num, loadStackSegment, doException)
    cdef run(self):
        self.gdt = Gdt(self)
        self.ldt = Gdt(self)
        self.idt = Idt(self)
        self.gdt.run()
        self.ldt.run()
        self.idt.run()



