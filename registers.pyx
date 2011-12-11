
import misc, mm
cimport mm

include "globals.pxi"


cdef class Gdt:
    def __init__(self, object segments):
        self.segments = segments
        self.registers = self.segments.registers
        self.main = self.segments.main
        self.setGdtLoadedTo = False # used only if needFlush == True
        self.gdtLoaded = False
        self.needFlush = False # flush with farJMP (opcode 0xEA)
    cpdef loadTable(self, unsigned long long tableBase, unsigned long tableLimit):
        self.tableBase, self.tableLimit = tableBase, tableLimit
        self.needFlush = False
        #self.gdtLoaded = True
    cpdef tuple getBaseLimit(self):
        return self.tableBase, self.tableLimit
    cpdef tuple getEntry(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned long base, limit
        cdef unsigned char accessByte, flags
        entryData = (<mm.Mm>self.main.mm).mmPhyReadValueUnsigned(self.tableBase+(num&0xfff8), 8)
        limit = entryData&BITMASK_WORD
        base  = (entryData>>16)&0xffffff
        accessByte = (entryData>>40)&BITMASK_BYTE
        flags  = (entryData>>52)&0xf
        limit |= (( entryData>>48)&0xf)<<16
        base  |= ( (entryData>>56)&BITMASK_BYTE)<<24
        return base, limit, accessByte, flags
    cpdef unsigned char getSegSize(self, unsigned short num):
        cdef tuple entryRet
        cdef unsigned long base, limit
        cdef unsigned char accessByte, flags
        if (self.segments.cpu.isInProtectedMode()):
            entryRet = self.getEntry(num)
            base, limit, accessByte, flags = entryRet
            if (flags & GDT_FLAG_SIZE):
                return OP_SIZE_DWORD
        return OP_SIZE_WORD
    cpdef unsigned char getSegAccess(self, unsigned short num):
        cdef tuple entryRet
        cdef unsigned char accessByte
        entryRet = self.getEntry(num)
        accessByte = entryRet[2]
        return accessByte
    cpdef unsigned char isSegPresent(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_PRESENT)!=0
    cpdef unsigned char isCodeSeg(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_EXECUTABLE)!=0
    ### isSegReadableWritable:
    ### if codeseg, return True if readable, else False
    ### if dataseg, return True if writable, else False
    cpdef unsigned char isSegReadableWritable(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_READABLE_WRITABLE)!=0
    cpdef unsigned char isSegConforming(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_CONFORMING)!=0
    cpdef unsigned char getSegDPL(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_DPL)&3
    cpdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment):
        if (num == 0 or \
            (isStackSegment and ( num&3 != self.registers.cpl or self.getSegDPL(num) != self.registers.cpl)) or \
            0):
            raise misc.ChemuException(CPU_EXCEPTION_GP, num)
        elif (not self.isSegPresent(num)):
            if (isStackSegment):
                raise misc.ChemuException(CPU_EXCEPTION_SS, num)
            else:
                raise misc.ChemuException(CPU_EXCEPTION_NP, num)
    cpdef unsigned char checkReadAllowed(self, unsigned short num, unsigned char doException):
        if (num&0xfff8 == 0 or (self.isCodeSeg(num) and not self.isSegReadableWritable(num))):
            if (doException):
                raise misc.ChemuException(CPU_EXCEPTION_GP, 0)
            return False
        return True
    cpdef unsigned char checkWriteAllowed(self, unsigned short num, unsigned char doException):
        if (num&0xfff8 == 0 or self.isCodeSeg(num) or not self.isSegReadableWritable(num)):
            if (doException):
                raise misc.ChemuException(CPU_EXCEPTION_GP, 0)
            return False
        return True
    cpdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment, unsigned char doException):
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
            if ((num&3 != self.registers.cpl or numSegDPL != self.registers.cpl) or \
                (not self.isCodeSeg(num) and not self.isSegReadableWritable(num))):
                  if (doException):
                      raise misc.ChemuException(CPU_EXCEPTION_GP, num)
                  return False
        else: # not loadStackSegment
            if ( ((not self.isCodeSeg(num) or not self.isSegConforming(num)) and (num&3 > numSegDPL and self.registers.cpl > numSegDPL)) or \
                 (self.isCodeSeg(num) and not self.isSegReadableWritable(num)) ):
                if (doException):
                    raise misc.ChemuException(CPU_EXCEPTION_GP, num)
                return False
        return True


cdef class Idt:
    def __init__(self, object segments):
        self.segments = segments
        self.main = self.segments.main
    cpdef loadTable(self, unsigned long long tableBase, unsigned long tableLimit):
        self.tableBase, self.tableLimit = tableBase, tableLimit
    cpdef tuple getBaseLimit(self):
        return self.tableBase, self.tableLimit
    cpdef tuple getEntry(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned long entryEip
        cdef unsigned short entrySegment
        cdef unsigned char entryType, entrySize, entryNeededDPL, entryPresent
        entryData = (<mm.Mm>self.main.mm).mmPhyReadValueUnsigned(self.tableBase+(num*8), 8)
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
    cpdef unsigned char isEntryPresent(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned char entryPresent
        entryData = (<mm.Mm>self.main.mm).mmPhyReadValueUnsigned(self.tableBase+(num*8), 8)
        entryPresent = (entryData>>47)&1 # is interrupt present
        return entryPresent
    cpdef unsigned char getEntryNeededDPL(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned char entryPresent
        entryData = (<mm.Mm>self.main.mm).mmPhyReadValueUnsigned(self.tableBase+(num*8), 8)
        entryNeededDPL = (entryData>>45)&0x3 # interrupt: Need this DPL
        return entryNeededDPL
    cpdef unsigned char getEntrySize(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned char entrySize
        entryData = (<mm.Mm>self.main.mm).mmPhyReadValueUnsigned(self.tableBase+(num*8), 8)
        entrySize = (entryData>>43)&1 # interrupt size: 1==32bit; 0==16bit; return 4 for 32bit, 2 for 16bit
        if (entrySize!=0): entrySize = OP_SIZE_DWORD
        else: entrySize = OP_SIZE_WORD
        return entrySize
    cpdef tuple getEntryRealMode(self, unsigned short num):
        cdef unsigned short offset, entrySegment, entryEip
        offset = num*4
        entryEip = (<mm.Mm>self.main.mm).mmPhyReadValueUnsigned(offset, 2)
        entrySegment = (<mm.Mm>self.main.mm).mmPhyReadValueUnsigned(offset+2, 2)
        return entrySegment, entryEip
    cpdef run(self, unsigned long long tableBase, unsigned long tableLimit):
        self.loadTable(tableBase, tableLimit)

cdef class Segments:
    def __init__(self, object main, object cpu, object registers):
        self.main, self.cpu, self.registers = main, cpu, registers
    cpdef reset(self):
        self.gdt = Gdt(self)
        self.ldt = Gdt(self)
        self.idt = Idt(self)
        self.idt.run(0, 0x3ff)
    cpdef unsigned long getBaseAddr(self, unsigned short segId): # segId == segments regId
        cdef unsigned long segValue = self.registers.segRead(segId)
        if (self.cpu.isInProtectedMode()): # protected mode enabled
            return self.gdt.getEntry(segValue)[0]
        #else: # real mode
        return segValue<<4
    cpdef unsigned long getRealAddr(self, unsigned short segId, long long offsetAddr):
        cdef long long addr
        addr = self.getBaseAddr(segId)
        if (not self.cpu.isInProtectedMode()):
            if (self.cpu.getA20State()): # A20 Active? if True == on, else off
                offsetAddr &= 0x1fffff
            else:
                offsetAddr &= 0xfffff
        addr += offsetAddr
        return addr&BITMASK_DWORD
    cpdef unsigned char getSegSize(self, unsigned short segId): # segId == segments regId
        cdef unsigned short segVal
        if (self.cpu.isInProtectedMode()): # protected mode enabled
            segVal = self.registers.segRead(segId)
            if (segVal & SELECTOR_USE_LDT):
                return self.ldt.getSegSize(segVal)
            return self.gdt.getSegSize(segVal)
        #else: # real mode
        return OP_SIZE_WORD
    cpdef unsigned char isSegPresent(self, unsigned short segId): # segId == segments regId
        cdef unsigned short segVal
        if (self.cpu.isInProtectedMode()): # protected mode enabled
            segVal = self.registers.segRead(segId)
            if (segVal & SELECTOR_USE_LDT):
                return self.ldt.getSegSize(segVal)
            return self.gdt.getSegSize(segVal)
        #else: # real mode
        return True
    cpdef unsigned char getOpSegSize(self, unsigned short segId): # segId == segments regId
        cdef unsigned char segSize = self.getSegSize(segId)
        if (segSize == OP_SIZE_WORD):
            return ((self.registers.operandSizePrefix and OP_SIZE_DWORD) or OP_SIZE_WORD)
        elif (segSize == OP_SIZE_DWORD):
            return ((self.registers.operandSizePrefix and OP_SIZE_WORD) or OP_SIZE_DWORD)
        else:
            self.main.exitError("getOpSegSize: segSize is not valid. ({0:d})", segSize)
    cpdef unsigned char getAddrSegSize(self, unsigned short segId): # segId == segments regId
        cdef unsigned char segSize = self.getSegSize(segId)
        if (segSize == OP_SIZE_WORD):
            return ((self.registers.addressSizePrefix and OP_SIZE_DWORD) or OP_SIZE_WORD)
        elif (segSize == OP_SIZE_DWORD):
            return ((self.registers.addressSizePrefix and OP_SIZE_WORD) or OP_SIZE_DWORD)
        else:
            self.main.exitError("getAddrSegSize: segSize is not valid. ({0:d})", segSize)
    cpdef tuple getOpAddrSegSize(self, unsigned short segId): # segId == segments regId
        cdef unsigned char opSize, addrSize, segSize
        segSize = self.getSegSize(segId)
        if (segSize == OP_SIZE_WORD):
            opSize   = ((self.registers.operandSizePrefix and OP_SIZE_DWORD) or OP_SIZE_WORD)
            addrSize = ((self.registers.addressSizePrefix and OP_SIZE_DWORD) or OP_SIZE_WORD)
        elif (segSize == OP_SIZE_DWORD):
            opSize   = ((self.registers.operandSizePrefix and OP_SIZE_WORD) or OP_SIZE_DWORD)
            addrSize = ((self.registers.addressSizePrefix and OP_SIZE_WORD) or OP_SIZE_DWORD)
        else:
            self.main.exitError("getOpAddrSegSize: segSize is not valid. ({0:d})", segSize)
        return opSize, addrSize
    cpdef unsigned char getSegAccess(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.getSegAccess(num)
        return self.gdt.getSegAccess(num)
    cpdef unsigned char isCodeSeg(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.isCodeSeg(num)
        return self.gdt.isCodeSeg(num)
    cpdef unsigned char isSegReadableWritable(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.isSegReadableWritable(num)
        return self.gdt.isSegReadableWritable(num)
    cpdef unsigned char isSegConforming(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.isSegConforming(num)
        return self.gdt.isSegConforming(num)
    cpdef unsigned char getSegDPL(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.getSegDPL(num)
        return self.gdt.getSegDPL(num)
    cpdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkAccessAllowed(num, isStackSegment)
        return self.gdt.checkAccessAllowed(num, isStackSegment)
    cpdef unsigned char checkReadAllowed(self, unsigned short num, unsigned char doException):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkReadAllowed(num, doException)
        return self.gdt.checkReadAllowed(num, doException)
    cpdef unsigned char checkWriteAllowed(self, unsigned short num, unsigned char doException):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkWriteAllowed(num, doException)
        return self.gdt.checkWriteAllowed(num, doException)
    cpdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment, unsigned char doException):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkSegmentLoadAllowed(num, loadStackSegment, doException)
        return self.gdt.checkSegmentLoadAllowed(num, loadStackSegment, doException)
    cpdef run(self):
        self.reset()

cdef class Registers:
    def __init__(self, object main, object cpu):
        self.main, self.cpu = main, cpu
    cpdef reset(self):
        self.regs = bytearray(CPU_REGISTER_LENGTH)
        self.segments = Segments(self.main, self.cpu, self)
        self.segments.run()
        self.regWrite(CPU_REGISTER_EFLAGS, 0x2)
        self.segWrite(CPU_SEGMENT_CS, 0xf000)
        self.regWrite(CPU_REGISTER_EIP, 0xfff0)
        self.regWrite(CPU_REGISTER_CR0, 0x60000034)
        self.cpl = self.iopl = 0
        self.resetPrefixes()
    cpdef resetPrefixes(self):
        self.lockPrefix = self.repPrefix = self.operandSizePrefix = self.addressSizePrefix = False
        self.segmentOverridePrefix = 0
    cpdef unsigned short getRegSize(self, unsigned short regId): # return size in bits
        if (regId in CPU_REGISTER_QWORD):
            return OP_SIZE_QWORD
        elif (regId in CPU_REGISTER_DWORD):
            return OP_SIZE_DWORD
        elif (regId in CPU_REGISTER_WORD):
            return OP_SIZE_WORD
        elif (regId in CPU_REGISTER_BYTE):
            return OP_SIZE_BYTE
        self.main.exitError("regId is unknown! ({0:d})", regId)
    cpdef unsigned short segRead(self, unsigned short segId): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as a byteorder here, IT WON'T WORK!!!!
        cdef unsigned short aregId, segValue
        if (not segId and not (segId in CPU_REGISTER_SREG)):
            self.main.exitError("segRead: segId is not a segment! ({0:d})", segId)
            return 0
        aregId = (segId//5)*8
        segValue = int.from_bytes(bytes=self.regs[aregId+6:aregId+8], byteorder="big")
        return segValue
    cpdef unsigned short segWrite(self, unsigned short segId, unsigned short segValue): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as a byteorder here, IT WON'T WORK!!!!
        cdef unsigned short aregId
        if (not segId and not (segId in CPU_REGISTER_SREG)):
            self.main.exitError("segWrite: segId is not a segment! ({0:d})", segId)
            return 0
        aregId = (segId//5)*8
        self.regs[aregId+6:aregId+8] = segValue.to_bytes(length=2, byteorder="big")
        return segValue
    cpdef long long regRead(self, unsigned short regId, unsigned char signed): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        cdef unsigned short aregId
        cdef long long regValue
        if (regId == CPU_REGISTER_NONE):
            return 0
        if (regId < CPU_MIN_REGISTER or regId >= CPU_MAX_REGISTER):
            self.main.exitError("regRead: regId is reserved! ({0:d})", regId)
            return 0
        aregId = (regId//5)*8
        if (regId in CPU_REGISTER_QWORD):
            regValue = int.from_bytes(bytes=self.regs[aregId:aregId+8], byteorder="big", signed=signed)
        elif (regId in CPU_REGISTER_DWORD):
            regValue = int.from_bytes(bytes=self.regs[aregId+4:aregId+8], byteorder="big", signed=signed)
        elif (regId in CPU_REGISTER_WORD):
            regValue = int.from_bytes(bytes=self.regs[aregId+6:aregId+8], byteorder="big", signed=signed)
        elif (regId in CPU_REGISTER_HBYTE):
            regValue = int.from_bytes(bytes=self.regs[aregId+6:aregId+7], byteorder="big", signed=signed)
        elif (regId in CPU_REGISTER_LBYTE):
            regValue = int.from_bytes(bytes=self.regs[aregId+7:aregId+8], byteorder="big", signed=signed)
        else:
            self.main.exitError("regRead: regId is unknown! ({0:d})", regId)
        return regValue
    cpdef unsigned long regWrite(self, unsigned short regId, unsigned long value): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        cdef unsigned short aregId
        if (regId < CPU_MIN_REGISTER or regId >= CPU_MAX_REGISTER):
            self.main.exitError("regWrite: regId is reserved! ({0:d})", regId)
            return 0
        aregId = (regId//5)*8
        if (regId in CPU_REGISTER_QWORD):
            self.regs[aregId:aregId+8] = value.to_bytes(length=8, byteorder="big")
        elif (regId in CPU_REGISTER_DWORD):
            self.regs[aregId+4:aregId+8] = value.to_bytes(length=4, byteorder="big")
        elif (regId in CPU_REGISTER_WORD):
            self.regs[aregId+6:aregId+8] = value.to_bytes(length=2, byteorder="big")
        elif (regId in CPU_REGISTER_HBYTE):
            self.regs[aregId+6] = value
        elif (regId in CPU_REGISTER_LBYTE):
            self.regs[aregId+7] = value
        else:
            self.main.exitError("regWrite: regId is unknown! ({0:d})", regId)
        return value # return value is unsigned!!
    cpdef unsigned long regAdd(self, unsigned short regId, long long value):
        cdef unsigned long newVal = self.regRead(regId, False)
        newVal = (newVal+value)&self.main.misc.getBitMaskFF(self.getRegSize(regId))
        return self.regWrite(regId, newVal)
    cpdef unsigned long regAdc(self, unsigned short regId, unsigned long value):
        cdef unsigned char withCarry = self.getEFLAG( FLAG_CF )!=0
        return self.regAdd(regId, value+withCarry)
    cpdef unsigned long regSub(self, unsigned short regId, unsigned long value):
        cdef unsigned long newVal = self.regRead(regId, False)
        newVal = (newVal-value)&self.main.misc.getBitMaskFF(self.getRegSize(regId))
        return self.regWrite(regId, newVal)
    cpdef unsigned long regSbb(self, unsigned short regId, unsigned long value):
        cdef unsigned char withCarry = self.getEFLAG( FLAG_CF )!=0
        return self.regSub(regId, value+withCarry)
    cpdef unsigned long regXor(self, unsigned short regId, unsigned long value):
        cdef unsigned long newVal
        newVal = (self.regRead(regId, False)^value)&self.main.misc.getBitMaskFF(self.getRegSize(regId))
        return self.regWrite(regId, newVal)
    cpdef unsigned long regAnd(self, unsigned short regId, unsigned long value):
        cdef unsigned long newVal
        newVal = (self.regRead(regId, False)&value)&self.main.misc.getBitMaskFF(self.getRegSize(regId))
        return self.regWrite(regId, newVal)
    cpdef unsigned long regOr (self, unsigned short regId, unsigned long value):
        cdef unsigned long newVal
        newVal = (self.regRead(regId, False)|value)&self.main.misc.getBitMaskFF(self.getRegSize(regId))
        return self.regWrite(regId, newVal)
    cpdef unsigned long regNeg(self, unsigned short regId):
        cdef unsigned long newVal
        newVal = (-self.regRead(regId, False))&self.main.misc.getBitMaskFF(self.getRegSize(regId))
        return self.regWrite(regId, newVal)
    cpdef unsigned long regNot(self, unsigned short regId):
        cdef unsigned long newVal
        newVal = (~self.regRead(regId, False))&self.main.misc.getBitMaskFF(self.getRegSize(regId))
        return self.regWrite(regId, newVal)
    cpdef unsigned long regWriteWithOp(self, unsigned short regId, unsigned long value, unsigned char valueOp):
        if (valueOp == OPCODE_SAVE):
            return self.regWrite(regId, value)
        elif (valueOp == OPCODE_ADD):
            return self.regAdd(regId, value)
        elif (valueOp == OPCODE_ADC):
            return self.regAdc(regId, value)
        elif (valueOp == OPCODE_SUB):
            return self.regSub(regId, value)
        elif (valueOp == OPCODE_SBB):
            return self.regSbb(regId, value)
        elif (valueOp == OPCODE_AND):
            return self.regAnd(regId, value)
        elif (valueOp == OPCODE_OR):
            return self.regOr(regId, value)
        elif (valueOp == OPCODE_XOR):
            return self.regXor(regId, value)
        elif (valueOp == OPCODE_NEG):
            value = (-value)&self.main.misc.getBitMaskFF(self.getRegSize(regId))
            return self.regWrite(regId, value)
        elif (valueOp == OPCODE_NOT):
            value = (~value)&self.main.misc.getBitMaskFF(self.getRegSize(regId))
            return self.regWrite(regId, value)
        else:
            self.main.printMsg("REGISTERS::regWriteWithOp: unknown valueOp {0:d}.", valueOp)
    cpdef unsigned long valSetBit(self, unsigned long value, unsigned char bit, unsigned char state):
        if (state):
            return ( value | (1<<bit) )
        return ( value & (~(1<<bit)) )
    cpdef unsigned char valGetBit(self, unsigned long value, unsigned char bit): # return True if bit is set, otherwise False
        return (value&(1<<bit))!=0
    cpdef unsigned long getEFLAG(self, unsigned long flags):
        return self.getFlag(CPU_REGISTER_EFLAGS, flags)
    cpdef unsigned long setEFLAG(self, unsigned long flags, unsigned char flagState):
        if (flagState):
            return self.regOr(CPU_REGISTER_EFLAGS, flags)
        return self.regAnd(CPU_REGISTER_EFLAGS, ~flags)
    cpdef unsigned long getFlag(self, unsigned short regId, unsigned long flags):
        return (self.regRead(regId, False)&flags)
    cpdef unsigned short getWordAsDword(self, unsigned short regWord, unsigned char wantRegSize):
        if (regWord in CPU_REGISTER_BYTE):
            # regWord should be LBYTE...
            if (regWord in CPU_REGISTER_HBYTE):
                regWord += 1
            if (wantRegSize == OP_SIZE_WORD):
                return regWord-2
            elif (wantRegSize == OP_SIZE_DWORD):
                return regWord-3
            elif (wantRegSize == OP_SIZE_QWORD):
                return regWord-4
        elif (regWord in CPU_REGISTER_WORD):
            if (wantRegSize == OP_SIZE_BYTE):
                return regWord+2
            elif (wantRegSize == OP_SIZE_DWORD):
                return regWord-1
            elif (wantRegSize == OP_SIZE_QWORD):
                return regWord-2
        elif (regWord in CPU_REGISTER_DWORD):
            if (wantRegSize == OP_SIZE_BYTE):
                return regWord+3
            elif (wantRegSize == OP_SIZE_WORD):
                return regWord+1
            elif (wantRegSize == OP_SIZE_QWORD):
                return regWord-1
        return regWord
    cpdef setSZP(self, unsigned long value, unsigned char regSize):
        self.setEFLAG(FLAG_SF, (value&self.main.misc.getBitMask80(regSize))!=0)
        self.setEFLAG(FLAG_ZF, value==0)
        self.setEFLAG(FLAG_PF, PARITY_TABLE[value&BITMASK_BYTE])
    cpdef setSZP_O0(self, unsigned long value, unsigned char regSize):
        self.setSZP(value, regSize)
        self.setEFLAG(FLAG_OF, False)
    cpdef setSZP_C0_O0_A0(self, unsigned long value, unsigned char regSize):
        self.setSZP_O0(value, regSize)
        self.setEFLAG(FLAG_CF | FLAG_AF, False)
    cpdef unsigned long long getRMValueFull(self, tuple rmNames, unsigned char rmSize):
        cdef unsigned long rmMask
        cdef unsigned long long rmValueFull
        rmMask = self.main.misc.getBitMaskFF(rmSize)
        rmValueFull = (self.regRead(rmNames[0], False)+self.regRead(rmNames[1], False)+rmNames[2])&rmMask
        return rmValueFull
    cpdef long long modRMLoad(self, tuple rmOperands, unsigned char regSize, unsigned char signed, unsigned char allowOverride): # imm == unsigned ; disp == signed; regSize in bits
        cdef unsigned char addrSize, mod
        cdef long long returnInt
        cdef tuple rmNames
        mod, rmNames = rmOperands[0:2]
        addrSize = self.segments.getAddrSegSize(CPU_SEGMENT_CS)
        returnInt = self.getRMValueFull(rmNames[0], addrSize)
        if (mod in (0, 1, 2)):
            if (signed):
                returnInt = (<mm.Mm>self.main.mm).mmReadValueSigned(returnInt, regSize, rmNames[1], allowOverride)
            else:
                returnInt = (<mm.Mm>self.main.mm).mmReadValueUnsigned(returnInt, regSize, rmNames[1], allowOverride)
        else:
            returnInt = self.regRead(rmNames[0][0], signed)
        return returnInt
    cpdef unsigned long long modRMSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value, unsigned char allowOverride, unsigned char valueOp): # imm == unsigned ; disp == signed; stdAllowOverride==True, stdValueOp==OPCODE_SAVE
        cdef unsigned char addrSize, mod
        cdef unsigned short regName
        cdef long long rmValueFull
        cdef tuple rmNames
        mod, rmNames, regName = rmOperands
        addrSize = self.segments.getAddrSegSize(CPU_SEGMENT_CS)
        rmValueFull = self.getRMValueFull(rmNames[0], addrSize)
        if (mod in (0, 1, 2)):
            return (<mm.Mm>self.main.mm).mmWriteValueWithOp(rmValueFull, value, regSize, rmNames[1], allowOverride, valueOp)
        else:
            return self.regWriteWithOp(rmNames[0][0], value, valueOp)
    cpdef unsigned short modSegLoad(self, tuple rmOperands, unsigned char regSize): # imm == unsigned ; disp == signed
        cdef unsigned short regName
        cdef unsigned long returnInt
        regName = rmOperands[2]
        returnInt  = self.segRead(regName)
        return returnInt
    cpdef unsigned short modSegSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value): # imm == unsigned ; disp == signed
        cdef unsigned short regName
        regName = rmOperands[2]
        if (regName == CPU_SEGMENT_CS):
            raise misc.ChemuException(CPU_EXCEPTION_UD)
        if (self.cpu.isInProtectedMode()):
            self.segments.checkSegmentLoadAllowed(value, regName == CPU_SEGMENT_SS, True)
        return self.segWrite(regName, value)
    cpdef long long modRLoad(self, tuple rmOperands, unsigned char regSize, unsigned char signed): # imm == unsigned ; disp == signed
        cdef unsigned short regName
        cdef long long returnInt
        regName = rmOperands[2]
        returnInt  = self.regRead(regName, signed)
        return returnInt
    cpdef unsigned long long modRSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value, unsigned char valueOp): # imm == unsigned ; disp == signed
        cdef unsigned short regName
        regName = rmOperands[2]
        return self.regWriteWithOp(regName, value, valueOp)
    cpdef unsigned short getRegValueWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize):
        cdef unsigned short regName = CPU_REGISTER_NONE
        if (modRMflags & MODRM_FLAGS_SREG):
            regName = CPU_REGISTER_SREG[reg]
        elif (modRMflags & MODRM_FLAGS_CREG):
            regName = CPU_REGISTER_CREG[reg]
        elif (modRMflags & MODRM_FLAGS_DREG):
            if (reg in (4, 5)):
                if (self.getFlag( CPU_REGISTER_CR4, CR4_FLAG_DE )):
                    raise misc.ChemuException(CPU_EXCEPTION_UD)
                else:
                    if (reg == 4):
                        reg = 6
                    elif (reg == 5):
                        reg = 7
            regName = CPU_REGISTER_DREG[reg]
        else:
            if (operSize == OP_SIZE_BYTE):
                regName = CPU_REGISTER_BYTE[reg]
            elif (operSize == OP_SIZE_WORD):
                regName = CPU_REGISTER_WORD[reg]
            elif (operSize == OP_SIZE_DWORD):
                regName = CPU_REGISTER_DWORD[reg]
            else:
                self.main.exitError("getRegValueWithFlags: operSize not in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)")
        if (not regName):
            raise misc.ChemuException(CPU_EXCEPTION_UD)
        return regName
    cdef tuple sibOperands(self, unsigned char mod):
        cdef unsigned char sibByte, base, index, ss
        cdef unsigned short rmBase, rmNameSegId, indexReg
        cdef unsigned long long rmIndex
        sibByte = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        base    = (sibByte)&7
        index   = (sibByte>>3)&7
        ss      = (sibByte>>6)&3
        rmBase  = CPU_REGISTER_NONE
        rmNameSegId = CPU_SEGMENT_DS
        indexReg = MODRM_SIB_INDEX_REGS[index]
        rmIndex = (self.regRead( indexReg, False ) * (1 << ss))&BITMASK_DWORD

        if (mod == 0 and base == 5):
            rmIndex += self.cpu.getCurrentOpcodeAdd(OP_SIZE_DWORD, False)
        else:
            rmBase = self.getRegValueWithFlags(0, base, OP_SIZE_DWORD)
            if (rmBase in (CPU_REGISTER_ESP, CPU_REGISTER_EBP)):
                rmNameSegId = CPU_SEGMENT_SS
        return rmBase, rmNameSegId, rmIndex
    cpdef tuple modRMOperands(self, unsigned char regSize, unsigned char modRMflags): # imm == unsigned ; disp == signed ; regSize in bytes
        cdef unsigned char modRMByte, rm, reg, mod, addrSegSize
        cdef unsigned short rmNameSegId, rmName0, rmName1, regName
        cdef long long rmName2
        addrSegSize = self.segments.getAddrSegSize(CPU_SEGMENT_CS)
        modRMByte = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        rm  = modRMByte&0x7
        reg = (modRMByte>>3)&0x7
        mod = (modRMByte>>6)&0x3

        rmNameSegId = self.segmentOverridePrefix or CPU_SEGMENT_DS
        rmName0 = rmName1 = rmName2 = 0
        regName  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
        if (addrSegSize == OP_SIZE_WORD):
            if (mod in (0, 1, 2)): # rm: source ; reg: dest
                if (rm in (0, 1, 7)):
                    rmName0 = CPU_REGISTER_BX
                elif (rm in (2, 3) or (rm == 6 and mod in (1,2))):
                    rmName0 = CPU_REGISTER_BP
                    rmNameSegId = CPU_SEGMENT_SS
                elif (rm == 4):
                    rmName0 = CPU_REGISTER_SI
                elif (rm == 5):
                    rmName0 = CPU_REGISTER_DI
                if (rm in (0, 2)):
                    rmName1 = CPU_REGISTER_SI
                elif (rm in (1, 3)):
                    rmName1 = CPU_REGISTER_DI
                if (mod == 0 and rm == 6):
                    rmName2 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_WORD, False)
                elif (mod == 2):
                    rmName2 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_WORD, True)
                elif (mod == 1):
                    rmName2 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, True)
            elif (mod == 3): # reg: source ; rm: dest
                if (regSize == OP_SIZE_BYTE):
                    rmName0  = CPU_REGISTER_BYTE[rm] # dest
                elif (regSize == OP_SIZE_WORD):
                    rmName0  = CPU_REGISTER_WORD[rm] # dest
                elif (regSize == OP_SIZE_DWORD):
                    rmName0  = CPU_REGISTER_DWORD[rm] # dest
                else:
                    self.main.exitError("modRMOperands: mod==3; regSize {0:d} not in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)", regSize)
            else:
                self.main.exitError("modRMOperands: mod not in (0,1,2)")
        elif (addrSegSize == OP_SIZE_DWORD):
            if (mod in (0, 1, 2)): # rm: source ; reg: dest
                if (rm == 0):
                    rmName0 = CPU_REGISTER_EAX
                elif (rm == 1):
                    rmName0 = CPU_REGISTER_ECX
                elif (rm == 2):
                    rmName0 = CPU_REGISTER_EDX
                elif (rm == 3):
                    rmName0 = CPU_REGISTER_EBX
                elif (rm == 4): # SIB
                    rmName0, rmNameSegId, rmName2 = self.sibOperands(mod)
                elif (rm == 5):
                    if (mod == 0):
                        rmName2 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_DWORD, False)
                    else:
                        rmName0 = CPU_REGISTER_EBP
                        rmNameSegId = CPU_SEGMENT_SS
                elif (rm == 6):
                    rmName0 = CPU_REGISTER_ESI
                elif (rm == 7):
                    rmName0 = CPU_REGISTER_EDI
                if (mod == 1):
                    rmName2 += self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, True)
                elif (mod == 2):
                    rmName2 += self.cpu.getCurrentOpcodeAdd(OP_SIZE_DWORD, True)
            elif (mod == 3): # reg: source ; rm: dest
                if (regSize == OP_SIZE_BYTE):
                    rmName0  = CPU_REGISTER_BYTE[rm] # dest
                elif (regSize == OP_SIZE_WORD):
                    rmName0  = CPU_REGISTER_WORD[rm] # dest
                elif (regSize == OP_SIZE_DWORD):
                    rmName0  = CPU_REGISTER_DWORD[rm] # dest
                else:
                    self.main.exitError("modRMOperands: mod==3; regSize {0:d} not in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)", regSize)
            else:
                self.main.exitError("modRMOperands: mod not in (0,1,2)")
        else:
            self.main.exitError("modRMOperands: AddrSegSize(CS) not in (OP_SIZE_WORD, OP_SIZE_DWORD)")
        return mod, ((rmName0, rmName1, rmName2), rmNameSegId), regName
    cpdef tuple modRMOperandsResetEip(self, unsigned char regSize, unsigned char modRMflags):
        oldEip = self.regRead( CPU_REGISTER_EIP, False )
        rmOperands = self.modRMOperands(regSize, modRMflags)
        self.regWrite( CPU_REGISTER_EIP, oldEip )
        return rmOperands
    cpdef unsigned char getCond(self, unsigned char index):
        if (index == 0x0): # O
            return self.getEFLAG( FLAG_OF )!=0
        elif (index == 0x1): # NO
            return self.getEFLAG( FLAG_OF )==0
        elif (index == 0x2): # C
            return self.getEFLAG( FLAG_CF )!=0
        elif (index == 0x3): # NC
            return self.getEFLAG( FLAG_CF )==0
        elif (index == 0x4): # E
            return self.getEFLAG( FLAG_ZF )!=0
        elif (index == 0x5): # NE
            return self.getEFLAG( FLAG_ZF )==0
        elif (index == 0x6): # NA
            return self.getEFLAG( FLAG_CF_ZF )!=0
        elif (index == 0x7): # A
            return self.getEFLAG( FLAG_CF_ZF )==0
        elif (index == 0x8): # S
            return self.getEFLAG( FLAG_SF )!=0
        elif (index == 0x9): # NS
            return self.getEFLAG( FLAG_SF )==0
        elif (index == 0xa): # P
            return self.getEFLAG( FLAG_PF )!=0
        elif (index == 0xb): # NP
            return self.getEFLAG( FLAG_PF )==0
        elif (index == 0xc): # L
            return (self.getEFLAG( FLAG_SF_OF ) in ( FLAG_SF, FLAG_OF ))
        elif (index == 0xd): # GE
            return (self.getEFLAG( FLAG_SF_OF ) in ( 0, (FLAG_SF_OF) ))
        elif (index == 0xe): # LE
            return (self.getEFLAG( FLAG_ZF )!=0 or (self.getEFLAG( FLAG_SF | FLAG_OF ) in ( FLAG_SF, FLAG_OF )) )
        elif (index == 0xf): # G
            return (self.getEFLAG( FLAG_ZF )==0 and (self.getEFLAG( FLAG_SF_OF ) in ( 0, (FLAG_SF_OF) )) )
        else:
            self.main.exitError("getCond: index {0:#x} invalid.", index)
    cpdef setFullFlags(self, long long reg0, long long reg1, unsigned char regSize, unsigned char method, unsigned char signed): # regSize in bits
        cdef unsigned char unsignedOverflow, signedOverflow, isResZero, afFlag, reg0Nibble, reg1Nibble, regSumNibble
        cdef unsigned long bitMask, bitMaskHalf
        cdef unsigned long long doubleBitMask, regSumu, regSumMasked, regSumuMasked
        cdef long long regSum
        unsignedOverflow = False
        signedOverflow = False
        isResZero = False
        afFlag = False
        bitMask = self.main.misc.getBitMaskFF(regSize)
        bitMaskHalf = self.main.misc.getBitMask80(regSize)

        if (method in (OPCODE_ADD, OPCODE_ADC)):
            if (method == OPCODE_ADC and self.getEFLAG(FLAG_CF)!=0):
                reg0 += 1
            regSum = reg0+reg1
            regSumMasked = regSum&bitMask
            isResZero = regSumMasked==0
            unsignedOverflow = (regSumMasked < reg0 or regSumMasked < reg1)
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&BITMASK_BYTE])
            self.setEFLAG(FLAG_ZF, isResZero)
            reg0Nibble = reg0&0xf
            reg1Nibble = reg1&0xf
            regSumNibble = regSum&0xf
            if ( (((reg0Nibble)+(reg1Nibble))>regSumNibble) or reg0>bitMask or reg1>bitMask):
                afFlag = True
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSum &= bitMaskHalf
            signedOverflow = ( ((not reg0 and not reg1) and regSum) or ((reg0 and reg1) and not regSum) )!=False
            self.setEFLAG(FLAG_AF, afFlag)
            self.setEFLAG(FLAG_CF, unsignedOverflow)
            self.setEFLAG(FLAG_OF, (not isResZero and signedOverflow))
            self.setEFLAG(FLAG_SF, regSum!=0)
        elif (method in (OPCODE_SUB, OPCODE_SBB)):
            if (method == OPCODE_SBB and self.getEFLAG(FLAG_CF)!=0):
                reg0 -= 1
            regSum = reg0-reg1
            regSumMasked = regSum&bitMask
            isResZero = regSumMasked==0
            unsignedOverflow = ( regSum<0 )
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&BITMASK_BYTE])
            self.setEFLAG(FLAG_ZF, isResZero)
            reg0Nibble = reg0&0xf
            reg1Nibble = reg1&0xf
            regSumNibble = regSum&0xf
            if ( ((reg0Nibble-reg1Nibble) < regSumNibble) and reg1!=0):
                afFlag = True
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSum &= bitMaskHalf
            signedOverflow = ( ((reg0 and not reg1) and not regSum) or ((not reg0 and reg1) and regSum) )!=False
            self.setEFLAG(FLAG_AF, afFlag)
            self.setEFLAG(FLAG_CF, unsignedOverflow )
            self.setEFLAG(FLAG_OF, (not isResZero and signedOverflow))
            self.setEFLAG(FLAG_SF, regSum!=0)
        elif (method == OPCODE_MUL):
            doubleBitMask = self.main.misc.getBitMaskFF(regSize*2)
            regSum = reg0*reg1
            reg0 = abs(reg0)
            reg1 = abs(reg1)
            regSumu = reg0*reg1
            regSumMasked = regSum&doubleBitMask
            regSumuMasked = regSumu&doubleBitMask
            isResZero = regSumMasked==0
            signedOverflow = not ((signed and ((regSize != OP_SIZE_BYTE and regSumu <= bitMask) or (regSize == OP_SIZE_BYTE and regSumu <= 0x7f))) or \
                   (not signed and ((regSumu <= bitMask))))
            self.setEFLAG(FLAG_CF, signedOverflow)
            self.setEFLAG(FLAG_OF, signedOverflow)
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&BITMASK_BYTE])
            self.setEFLAG(FLAG_ZF, isResZero)
            self.setEFLAG(FLAG_SF, (regSum&bitMaskHalf)!=0)
        elif (method == OPCODE_DIV):
            pass
        else:
            self.main.exitError("setFullFlags: method not (add, sub, mul or div). (method: {0:d})", method)
    cpdef checkMemAccessRights(self, unsigned short segId, unsigned char write):
        cdef unsigned short segVal
        if (not self.cpu.isInProtectedMode()):
            return
        segVal = self.segRead(segId)
        if (not self.segments.isSegPresent(segVal) ):
            if (segId == CPU_SEGMENT_SS):
                raise misc.ChemuException(CPU_EXCEPTION_SS, segVal)
            else:
                raise misc.ChemuException(CPU_EXCEPTION_NP, segVal)
        if ( segVal == 0 ):
            if (segId == CPU_SEGMENT_SS):
                raise misc.ChemuException(CPU_EXCEPTION_SS, segVal)
            else:
                raise misc.ChemuException(CPU_EXCEPTION_GP, segVal)
        if (write):
            if (self.segments.isCodeSeg(segVal) or not self.segments.isSegReadableWritable(segVal) ):
                if (segId == CPU_SEGMENT_SS):
                    raise misc.ChemuException(CPU_EXCEPTION_SS, segVal)
                else:
                    raise misc.ChemuException(CPU_EXCEPTION_GP, segVal)
        else:
            if (self.segments.isCodeSeg(segVal) and not self.segments.isSegReadableWritable(segVal) ):
                raise misc.ChemuException(CPU_EXCEPTION_GP, segVal)
    cpdef run(self):
        self.reset()


