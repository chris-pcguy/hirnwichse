import misc

include "globals.pxi"


cdef class Gdt:
    cdef public object main
    cdef public unsigned char needFlush, setGdtLoadedTo, gdtLoaded
    cdef unsigned long long tableBase
    cdef unsigned long tableLimit
    def __init__(self, object main):
        self.main = main
        self.setGdtLoadedTo = False # used only if needFlush == True
        self.gdtLoaded = False
        self.needFlush = False # flush with farJMP (opcode 0xEA)
    cpdef public loadTable(self, unsigned long long tableBase, unsigned long tableLimit):
        self.tableBase, self.tableLimit = tableBase, tableLimit
        self.needFlush = False
        #self.gdtLoaded = True
    cpdef public tuple getBaseLimit(self):
        return self.tableBase, self.tableLimit
    cpdef public tuple getEntry(self, unsigned short num):
        cdef unsigned long long entryData, base
        cdef unsigned long limit
        cdef unsigned char flags, accessByte
        if ((num & GDT_USE_LDT)!=0):
            self.main.exitError("GDT::getEntry: LDT not supported yet, exiting...")
            return
        entryData = self.main.mm.mmPhyReadValue(self.tableBase+(num&0xfff8), 8)
        limit = entryData&0xffff
        base  = (entryData>>16)&0xffffff
        accessByte = (entryData>>40)&0xff
        flags  = (entryData>>52)&0xf
        limit |= (( entryData>>48)&0xf)<<16
        base  |= ( (entryData>>56)&0xff)<<24
        return base, limit, accessByte, flags
    cpdef public unsigned char getSegSize(self, unsigned short num):
        cdef tuple entryRet
        cdef unsigned long long base
        cdef unsigned long limit
        cdef unsigned char accessByte, flags
        entryRet = self.getEntry(num)
        base, limit, accessByte, flags = entryRet
        if (flags & GDT_FLAG_SIZE):
            return OP_SIZE_DWORD
        return OP_SIZE_WORD
    cpdef public unsigned char getSegAccess(self, unsigned short num):
        cdef tuple entryRet
        cdef unsigned char accessByte
        entryRet = self.getEntry(num)
        accessByte = entryRet[2]
        return accessByte
    cpdef public unsigned char isSegPresent(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_PRESENT)!=0
    cpdef public unsigned char isCodeSeg(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_EXECUTABLE)!=0
    cpdef public unsigned char isSegReadableWritable(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_READABLE_WRITABLE)!=0
    cpdef public unsigned char getSegDPL(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_DPL)&3
    
    
    


cdef class Idt:
    cdef public object main
    cdef public unsigned long long tableBase
    cdef public unsigned long tableLimit
    def __init__(self, object main, unsigned long long tableBase, unsigned long tableLimit):
        self.main = main
        self.loadTable(tableBase, tableLimit)
    cpdef public loadTable(self, unsigned long long tableBase, unsigned long tableLimit):
        self.tableBase, self.tableLimit = tableBase, tableLimit
    cpdef public tuple getBaseLimit(self):
        return self.tableBase, self.tableLimit
    cpdef public tuple getEntry(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned long entryEip
        cdef unsigned short entrySegment
        cdef unsigned char entryType, entrySize, entryNeededDPL, entryPresent
        entryData = self.main.mm.mmPhyReadValue(self.tableBase+(num*8), 8)
        entryEip = entryData&0xffff # interrupt eip: lower word
        entrySegment = (entryData>>16)&0xffff # interrupt segment
        entryEip |= ((entryData>>48)&0xffff)<<16 # interrupt eip: upper word
        entryType = (entryData>>40)&0x7 # interrupt type
        entryNeededDPL = (entryData>>45)&0x3 # interrupt: Need this DPL
        entryPresent = (entryData>>47)&1 # is interrupt present
        entrySize = (entryData>>43)&1 # interrupt size: 1==32bit; 0==16bit; return 4 for 32bit, 2 for 16bit
        if (entrySize!=0): entrySize = OP_SIZE_DWORD
        else: entrySize = OP_SIZE_WORD
        return entrySegment, entryEip, entryType, entrySize, entryNeededDPL, entryPresent
    cpdef public unsigned char isEntryPresent(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned char entryPresent
        entryData = self.main.mm.mmPhyReadValue(self.tableBase+(num*8), 8)
        entryPresent = (entryData>>47)&1 # is interrupt present
        return entryPresent
    cpdef public unsigned char getEntryNeededDPL(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned char entryPresent
        entryData = self.main.mm.mmPhyReadValue(self.tableBase+(num*8), 8)
        entryNeededDPL = (entryData>>45)&0x3 # interrupt: Need this DPL
        return entryNeededDPL
    cpdef public unsigned char getEntrySize(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned char entrySize
        entryData = self.main.mm.mmPhyReadValue(self.tableBase+(num*8), 8)
        entrySize = (entryData>>43)&1 # interrupt size: 1==32bit; 0==16bit; return 4 for 32bit, 2 for 16bit
        if (entrySize!=0): entrySize = OP_SIZE_DWORD
        else: entrySize = OP_SIZE_WORD
        return entrySize
    cpdef public tuple getEntryRealMode(self, unsigned short num):
        cdef unsigned short offset, entrySegment, entryEip
        offset = num*4
        entryEip = self.main.mm.mmPhyReadValue(offset, 2)
        entrySegment = self.main.mm.mmPhyReadValue(offset+2, 2)
        return entrySegment, entryEip


cdef class Segments:
    cdef public object main, cpu, registers, gdt, idt
    def __init__(self, object main, object cpu, object registers):
        self.main, self.cpu, self.registers = main, cpu, registers
        self.reset()
    def reset(self):
        self.gdt = Gdt(self.main)
        self.idt = Idt(self.main, 0, 0x3ff)
    cpdef public unsigned long getBaseAddr(self, unsigned short segId): # segId == segments regId
        cdef unsigned long long segValue = self.registers.segRead(segId)
        if (self.cpu.isInProtectedMode()): # protected mode enabled
            return self.gdt.getEntry(segValue)[0]
        #else: # real mode
        return segValue<<4
    cpdef public unsigned long getRealAddr(self, unsigned short segId, long long offsetAddr):
        cdef long long addr
        addr = self.getBaseAddr(segId)
        if (not self.cpu.isInProtectedMode()):
            if (self.cpu.getA20State()): # A20 Active? if True == on, else off
                offsetAddr &= 0x1fffff
            else:
                offsetAddr &= 0xfffff
            addr += offsetAddr
        else:
            addr += offsetAddr
        return addr&0xffffffff
    cpdef public unsigned char getSegSize(self, unsigned short segId): # segId == segments regId
        if (self.cpu.isInProtectedMode()): # protected mode enabled
        #if (self.gdt.gdtLoaded and not self.gdt.needFlush):
            return self.gdt.getSegSize(self.registers.segRead(segId))
        #else: # real mode
        return OP_SIZE_WORD
    cpdef public unsigned char isSegPresent(self, unsigned short segId): # segId == segments regId
        if (self.cpu.isInProtectedMode()): # protected mode enabled
        #if (self.gdt.gdtLoaded and not self.gdt.needFlush):
            return self.gdt.isSegPresent(self.registers.segRead(segId))
        #else: # real mode
        return True
    cpdef public unsigned char getOpSegSize(self, unsigned short segId): # segId == segments regId
        cdef unsigned char segSize = self.getSegSize(segId)
        if (segSize == OP_SIZE_WORD):
            return ((self.registers.operandSizePrefix and OP_SIZE_DWORD) or OP_SIZE_WORD)
        elif (segSize == OP_SIZE_DWORD):
            return ((self.registers.operandSizePrefix and OP_SIZE_WORD) or OP_SIZE_DWORD)
        else:
            self.main.exitError("getOpSegSize: segSize is not valid. ({0:d})", segSize)
    cpdef public unsigned char getAddrSegSize(self, unsigned short segId): # segId == segments regId
        cdef unsigned char segSize = self.getSegSize(segId)
        if (segSize == OP_SIZE_WORD):
            return ((self.registers.addressSizePrefix and OP_SIZE_DWORD) or OP_SIZE_WORD)
        elif (segSize == OP_SIZE_DWORD):
            return ((self.registers.addressSizePrefix and OP_SIZE_WORD) or OP_SIZE_DWORD)
        else:
            self.main.exitError("getAddrSegSize: segSize is not valid. ({0:d})", segSize)
    cpdef public tuple getOpAddrSegSize(self, unsigned short segId): # segId == segments regId
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
    

cdef class Registers:
    cdef public object main, cpu, segments, regs
    cdef public unsigned char lockPrefix, branchPrefix, repPrefix, segmentOverridePrefix, operandSizePrefix, addressSizePrefix, cpl, iopl
    def __init__(self, object main, object cpu):
        self.main, self.cpu = main, cpu
        self.regs = bytearray(CPU_REGISTER_LENGTH)
        self.segments = Segments(self.main, self.cpu, self)
        self.reset(doInit=True)
    def reset(self, unsigned char doInit=False):
        if (not doInit):
            self.regs = bytearray(CPU_REGISTER_LENGTH)
            self.segments.reset()
        self.regWrite(CPU_REGISTER_EFLAGS, 0x2)
        self.segWrite(CPU_SEGMENT_CS, 0xffff000, shortSeg=False)
        self.regWrite(CPU_REGISTER_EIP, 0xfff0)
        self.regWrite(CPU_REGISTER_CR0, 0x60000034)
        self.resetPrefixes()
    def resetPrefixes(self):
        self.lockPrefix = False
        self.branchPrefix = False
        self.repPrefix = False
        self.segmentOverridePrefix = 0
        self.operandSizePrefix = False
        self.addressSizePrefix = False
        self.cpl, self.iopl = 0, 0 # TODO
    cpdef public unsigned short regGetSize(self, unsigned short regId): # return size in bits
        if (regId in CPU_REGISTER_QWORD):
            return OP_SIZE_QWORD
        elif (regId in CPU_REGISTER_DWORD):
            return OP_SIZE_DWORD
        elif (regId in CPU_REGISTER_WORD):
            return OP_SIZE_WORD
        elif (regId in CPU_REGISTER_BYTE):
            return OP_SIZE_BYTE
        self.main.exitError("regId is unknown! ({0:d})", regId)
    cpdef public unsigned long segRead(self, unsigned short segId): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        cdef unsigned short aregId
        cdef unsigned long segValue
        if (not segId and not (segId in CPU_REGISTER_SREG)):
            self.main.exitError("segRead: segId is not a segment! ({0:d})", segId)
            return 0
        aregId = (segId//5)*8
        segValue = int.from_bytes(bytes=self.regs[aregId+4:aregId+8], byteorder="big")
        return segValue
    cpdef public unsigned long segWrite(self, unsigned short segId, unsigned long value, unsigned char shortSeg=True): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        cdef unsigned short aregId
        if (not segId and not (segId in CPU_REGISTER_SREG)):
            self.main.exitError("segWrite: segId is not a segment! ({0:d})", segId)
            return 0
        aregId = (segId//5)*8
        if (shortSeg):
            value &= 0xffff
        self.regs[aregId+4:aregId+8] = value.to_bytes(length=4, byteorder="big")
        return value
    cpdef public long long regRead(self, unsigned short regId, unsigned char signed=False): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        cdef unsigned short aregId
        cdef long long regName
        if (regId == CPU_REGISTER_NONE):
            return 0
        if (regId < CPU_MIN_REGISTER or regId >= CPU_MAX_REGISTER):
            self.main.exitError("regRead: regId is reserved! ({0:d})", regId)
            return 0
        aregId = (regId//5)*8
        if (regId in CPU_REGISTER_QWORD):
            regName = int.from_bytes(bytes=self.regs[aregId:aregId+8], byteorder="big", signed=signed)
        elif (regId in CPU_REGISTER_DWORD):
            regName = int.from_bytes(bytes=self.regs[aregId+4:aregId+8], byteorder="big", signed=signed)
        elif (regId in CPU_REGISTER_WORD):
            regName = int.from_bytes(bytes=self.regs[aregId+6:aregId+8], byteorder="big", signed=signed)
        elif (regId in CPU_REGISTER_HBYTE):
            regName = self.regs[aregId+6]
            if (regName & 0x80 and signed):
                regName -= 0x100
        elif (regId in CPU_REGISTER_LBYTE):
            regName = self.regs[aregId+7]
            if (regName & 0x80 and signed):
                regName -= 0x100
        else:
            self.main.exitError("regRead: regId is unknown! ({0:d})", regId)
        return regName
    cpdef public unsigned long regWrite(self, unsigned short regId, unsigned long value): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        cdef unsigned short aregId
        if (regId < CPU_MIN_REGISTER or regId >= CPU_MAX_REGISTER):
            self.main.exitError("regWrite: regId is reserved! ({0:d})", regId)
            return 0
        aregId = (regId//5)*8
        if (regId in CPU_REGISTER_QWORD):
            value &= 0xffffffffffffffff
            self.regs[aregId:aregId+8] = value.to_bytes(length=8, byteorder="big")
        elif (regId in CPU_REGISTER_DWORD):
            value &= 0xffffffff
            self.regs[aregId+4:aregId+8] = value.to_bytes(length=4, byteorder="big")
        elif (regId in CPU_REGISTER_WORD):
            value &= 0xffff
            self.regs[aregId+6:aregId+8] = value.to_bytes(length=2, byteorder="big")
        elif (regId in CPU_REGISTER_HBYTE):
            value &= 0xff
            self.regs[aregId+6] = value
        elif (regId in CPU_REGISTER_LBYTE):
            value &= 0xff
            self.regs[aregId+7] = value
        else:
            self.main.exitError("regWrite: regId is unknown! ({0:d})", regId)
        return value # return value is unsigned!!
    cpdef public unsigned long regAdd(self, unsigned short regId, long long value):
        cdef unsigned long newVal = self.regRead(regId)
        newVal += value
        return self.regWrite(regId, newVal)
    cpdef public unsigned long regAdc(self, unsigned short regId, unsigned long value):
        cdef unsigned char withCarry = self.getEFLAG( FLAG_CF )
        cdef unsigned long newVal = value+withCarry
        return self.regAdd(regId, newVal)
    cpdef public unsigned long regSub(self, unsigned short regId, unsigned long value):
        cdef unsigned long newVal = self.regRead(regId)
        newVal -= value
        return self.regWrite(regId, newVal)
    cpdef public unsigned long regSbb(self, unsigned short regId, unsigned long value):
        cdef unsigned char withCarry = self.getEFLAG( FLAG_CF )
        cdef unsigned long newVal = value+withCarry
        return self.regSub(regId, newVal)
    cpdef public unsigned long regXor(self, unsigned short regId, unsigned long value):
        cdef unsigned long newVal = self.regRead(regId)^value
        return self.regWrite(regId, newVal)
    cpdef public unsigned long regAnd(self, unsigned short regId, unsigned long value):
        cdef unsigned long newVal = self.regRead(regId)&value
        return self.regWrite(regId, newVal)
    cpdef public unsigned long regOr (self, unsigned short regId, unsigned long value):
        cdef unsigned long newVal = self.regRead(regId)|value
        return self.regWrite(regId, newVal)
    cpdef public unsigned long regNeg(self, unsigned short regId):
        cdef unsigned long newVal = -self.regRead(regId)
        return self.regWrite(regId, newVal)
    cpdef public unsigned long regNot(self, unsigned short regId):
        cdef unsigned long newVal = ~self.regRead(regId)
        return self.regWrite(regId, newVal)
    cpdef public unsigned long regWriteWithOp(self, unsigned short regId, unsigned long value, unsigned char valueOp):
        if (valueOp == VALUEOP_SAVE):
            return self.regWrite(regId, value)
        elif (valueOp == VALUEOP_ADD):
            return self.regAdd(regId, value)
        elif (valueOp == VALUEOP_ADC):
            return self.regAdc(regId, value)
        elif (valueOp == VALUEOP_SUB):
            return self.regSub(regId, value)
        elif (valueOp == VALUEOP_SBB):
            return self.regSbb(regId, value)
        elif (valueOp == VALUEOP_AND):
            return self.regAnd(regId, value)
        elif (valueOp == VALUEOP_OR):
            return self.regOr(regId, value)
        elif (valueOp == VALUEOP_XOR):
            return self.regXor(regId, value)
    cpdef public unsigned long regDelFlag(self, unsigned short regId, unsigned long value): # by val, not bit
        newVal = self.regRead(regId)&(~value)
        return self.regWrite(regId, newVal)
    cpdef public unsigned long regSetBit(self, unsigned short regId, unsigned char bit, unsigned char state):
        cdef unsigned long newVal
        if (state):
            newVal = self.regRead(regId)|(1<<bit)
        else:
            newVal = self.regRead(regId)&(~(1<<bit))
        self.regWrite(regId, newVal)
        return newVal
    cpdef public unsigned char regGetBit(self, unsigned short regId, unsigned char bit): # return True if bit is set, otherwise False
        cdef unsigned long bitMask = (1<<bit)
        return (self.regRead(regId)&bitMask)!=0
    cpdef public unsigned long valSetBit(self, unsigned long value, unsigned char bit, unsigned char state):
        cdef unsigned long bitMask = (1<<bit)
        if (state):
            return ( value | bitMask )
        else:
            return ( value & (~bitMask) )
    cpdef public unsigned char valGetBit(self, unsigned long value, unsigned char bit): # return True if bit is set, otherwise False
        cdef unsigned long long bitMask = (1<<bit)
        return (value&bitMask)!=0
    def setEFLAG(self, unsigned long flags, unsigned char flagState):
        if (flagState):
            return self.regOr(CPU_REGISTER_EFLAGS, flags)
        return self.regDelFlag(CPU_REGISTER_EFLAGS, flags)
    def getEFLAG(self, unsigned long flags):
        return (self.regRead(CPU_REGISTER_EFLAGS)&flags)!=0
    def getFlag(self, unsigned short regId, unsigned long flags):
        return (self.regRead(regId)&flags)!=0
    def clearThisEFLAGS(self, unsigned long flags):
        self.regAnd( CPU_REGISTER_EFLAGS, ~flags )
    def setThisEFLAGS(self, unsigned long flags):
        self.regOr( CPU_REGISTER_EFLAGS, flags )
    cpdef public unsigned short getWordAsDword(self, unsigned short regWord, unsigned char wantRegSize):
        if (regWord in CPU_REGISTER_WORD and wantRegSize == OP_SIZE_DWORD):
            return regWord-1 # regWord-1 is for example bx as ebx...
        elif (regWord in CPU_REGISTER_DWORD and wantRegSize == OP_SIZE_WORD):
            return regWord+1 # regWord+1 is for example ebx as bx...
        return regWord
    def setSZP(self, unsigned long value, unsigned char regSize):
        self.setEFLAG(FLAG_SF, (value&self.main.misc.getBitMask(regSize, half=True, minus=0))!=0)
        self.setEFLAG(FLAG_ZF, value==0)
        self.setEFLAG(FLAG_PF, PARITY_TABLE[value&0xff])
    def setSZP_O0(self, unsigned long value, unsigned char regSize):
        self.clearThisEFLAGS(FLAG_OF)
        self.setSZP(value, regSize)
    def setSZP_C0_O0(self, unsigned long value, unsigned char regSize):
        self.clearThisEFLAGS(FLAG_CF)
        self.setSZP_O0(value, regSize)
    def setSZP_C0_O0_A0(self, unsigned long value, unsigned char regSize):
        self.setSZP_C0_O0(value, regSize)
        self.setEFLAG(FLAG_AF, 0)
    cpdef public unsigned long long getRMValueFull(self, tuple rmNames, unsigned char rmSize):
        cdef unsigned long rmMask
        cdef unsigned long long rmValueFull
        rmMask = self.main.misc.getBitMask(rmSize)
        rmValueFull = (self.regRead(rmNames[0])+self.regRead(rmNames[1])+rmNames[2])&rmMask
        return rmValueFull
    cpdef public long long modRMLoad(self, tuple rmOperands, unsigned char regSize, unsigned char signed=False, unsigned char allowOverride=True): # imm == unsigned ; disp == signed; regSize in bits
        cdef unsigned char addrSize, mod
        cdef long long returnInt
        cdef tuple rmNames
        mod, rmNames = rmOperands[0:2]
        addrSize = self.segments.getAddrSegSize(CPU_SEGMENT_CS)
        returnInt = self.getRMValueFull(rmNames[0], addrSize)
        if (mod in (0, 1, 2)):
            returnInt = self.main.mm.mmReadValue(returnInt, regSize, segId=rmNames[1], signed=signed, allowOverride=allowOverride)
        else:
            returnInt = self.regRead(rmNames[0][0], signed=signed)
        return returnInt
    cpdef public unsigned long long modRMSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value, unsigned char allowOverride=True, unsigned char valueOp=VALUEOP_SAVE): # imm == unsigned ; disp == signed
        cdef unsigned char addrSize, mod
        cdef unsigned short regName
        cdef long long rmValueFull
        cdef tuple rmNames
        mod, rmNames, regName = rmOperands
        addrSize = self.segments.getAddrSegSize(CPU_SEGMENT_CS)
        rmValueFull = self.getRMValueFull(rmNames[0], addrSize)
        if (mod in (0, 1, 2)):
            return self.main.mm.mmWriteValueWithOp(rmValueFull, value, regSize, segId=rmNames[1], allowOverride=allowOverride, valueOp=valueOp)
        else:
            return self.regWriteWithOp(rmNames[0][0], value, valueOp)
    cpdef public unsigned short modSegLoad(self, tuple rmOperands, unsigned char regSize): # imm == unsigned ; disp == signed
        cdef unsigned short regName
        cdef unsigned long returnInt
        regName = rmOperands[2]
        returnInt  = self.segRead(regName)
        return returnInt
    cpdef public unsigned short modSegSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value): # imm == unsigned ; disp == signed
        cdef unsigned char segDPL
        cdef unsigned short regName
        regName = rmOperands[2]
        if (regName == CPU_SEGMENT_CS):
            raise misc.ChemuException(CPU_EXCEPTION_UD)
        if (self.cpu.isInProtectedMode()):
            segDPL = self.segments.gdt.getSegDPL(value)
            if (regName == CPU_SEGMENT_SS):
                if (value == 0 or not self.segments.gdt.isSegReadableWritable(value) \
                        or (value&3 != self.cpl) or (segDPL != self.cpl) ): # RPL > DPL && CPL > DPL
                    raise misc.ChemuException(CPU_EXCEPTION_GP, value)
                if (not self.segments.gdt.isSegPresent(value) ):
                    raise misc.ChemuException(CPU_EXCEPTION_SS, value)
            else:
                if (value != 0):
                    if (((self.segments.gdt.isCodeSeg(value) or not self.segments.gdt.isSegReadableWritable(value)) \
                            and (value&3 > segDPL and self.cpl > segDPL ) ) ): # RPL > DPL && CPL > DPL
                        raise misc.ChemuException(CPU_EXCEPTION_GP, value)
                    if (not self.segments.gdt.isSegPresent(value) ):
                        raise misc.ChemuException(CPU_EXCEPTION_NP, value)
        return self.segWrite(regName, value)
    cpdef public long long modRLoad(self, tuple rmOperands, unsigned char regSize, unsigned char signed=False): # imm == unsigned ; disp == signed
        cdef unsigned short regName
        cdef long long returnInt
        regName = rmOperands[2]
        returnInt  = self.regRead(regName, signed=signed)
        return returnInt
    cpdef public unsigned long long modRSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value, unsigned char valueOp=VALUEOP_SAVE): # imm == unsigned ; disp == signed
        cdef unsigned short regName
        regName = rmOperands[2]
        ##value &= self.main.misc.getBitMask(regSize)
        return self.regWriteWithOp(regName, value, valueOp)
    cpdef public unsigned short getRegValueWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize):
        cdef unsigned short regName = CPU_REGISTER_NONE
        if (modRMflags & MODRM_FLAGS_SREG):
            regName = CPU_REGISTER_SREG[reg]
        elif (modRMflags & MODRM_FLAGS_CREG):
            regName = CPU_REGISTER_CREG[reg]
        elif (modRMflags & MODRM_FLAGS_DREG):
            #regName = CPU_REGISTER_DREG[reg]
            self.main.exitError("debug register NOT IMPLEMENTED yet!")
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
    cpdef public tuple sibOperands(self, unsigned char mod):
        cdef unsigned char sibByte, base, index, ss
        cdef unsigned short rmBase, rmNameSegId, indexReg
        cdef unsigned long bitMask
        cdef unsigned long long rmIndex
        sibByte = self.cpu.getCurrentOpcodeAdd()
        bitMask = 0xffffffff
        base    = (sibByte)&7
        index   = (sibByte>>3)&7
        ss      = (sibByte>>6)&3
        rmBase  = CPU_REGISTER_NONE
        rmNameSegId = CPU_SEGMENT_DS
        
        if (index == 0):
            indexReg = CPU_REGISTER_EAX
        elif (index == 1):
            indexReg = CPU_REGISTER_ECX
        elif (index == 2):
            indexReg = CPU_REGISTER_EDX
        elif (index == 3):
            indexReg = CPU_REGISTER_EBX
        elif (index == 4):
            indexReg = CPU_REGISTER_NONE
        elif (index == 5):
            indexReg = CPU_REGISTER_EBP
        elif (index == 6):
            indexReg = CPU_REGISTER_ESI
        elif (index == 7):
            indexReg = CPU_REGISTER_EDI
        
        rmIndex = (self.regRead( indexReg ) * (1 << ss))&bitMask
        
        if (mod == 0 and base == 5):
            rmIndex += self.cpu.getCurrentOpcodeAdd(OP_SIZE_DWORD)
        else:
            rmBase = self.getRegValueWithFlags(0, base, OP_SIZE_DWORD)
            if (rmBase in (CPU_REGISTER_ESP, CPU_REGISTER_EBP)):
                rmNameSegId = CPU_SEGMENT_SS
        
        return rmBase, rmNameSegId, rmIndex
    cpdef public tuple modRMOperands(self, unsigned char regSize, unsigned char modRMflags=0): # imm == unsigned ; disp == signed ; regSize in bytes
        cdef unsigned char modRMByte, rm, reg, mod
        cdef unsigned short rmNameSegId, rmName0, rmName1, regName
        cdef long long rmName2
        modRMByte = self.cpu.getCurrentOpcodeAdd()
        rm  = modRMByte&0x7
        reg = (modRMByte>>3)&0x7
        mod = (modRMByte>>6)&0x3

        rmNameSegId = CPU_SEGMENT_DS
        if (self.segmentOverridePrefix):
            rmNameSegId = self.segmentOverridePrefix
        
        rmName0, rmName1, rmName2 = 0, 0, 0
        regName = 0
        if (self.segments.getAddrSegSize(CPU_SEGMENT_CS) == OP_SIZE_WORD):
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
                regName  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
                if (mod == 0 and rm == 6):
                    rmName2 = self.cpu.getCurrentOpcodeAdd(numBytes=OP_SIZE_WORD)
                elif (mod == 2):
                    rmName2 = self.cpu.getCurrentOpcodeAdd(numBytes=OP_SIZE_WORD, signed=True)
                elif (mod == 1):
                    rmName2 = self.cpu.getCurrentOpcodeAdd(numBytes=OP_SIZE_BYTE, signed=True)
            elif (mod == 3): # reg: source ; rm: dest
                regName  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
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
        elif (self.segments.getAddrSegSize(CPU_SEGMENT_CS) == OP_SIZE_DWORD):
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
                        rmName2 = self.cpu.getCurrentOpcodeAdd(numBytes=OP_SIZE_DWORD)
                    else:
                        rmName0 = CPU_REGISTER_EBP
                        rmNameSegId = CPU_SEGMENT_SS
                elif (rm == 6):
                    rmName0 = CPU_REGISTER_ESI
                elif (rm == 7):
                    rmName0 = CPU_REGISTER_EDI
                if (mod == 1):
                    rmName2 += self.cpu.getCurrentOpcodeAdd(numBytes=OP_SIZE_BYTE, signed=True)
                elif (mod == 2):
                    rmName2 += self.cpu.getCurrentOpcodeAdd(numBytes=OP_SIZE_DWORD, signed=True)
                
                regName  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
                
            elif (mod == 3): # reg: source ; rm: dest
                regName  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
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
    cpdef public tuple modRMOperandsResetEip(self, unsigned char regSize, unsigned char modRMflags=0):
        oldEip = self.regRead( CPU_REGISTER_EIP )
        rmOperands = self.modRMOperands(regSize, modRMflags=modRMflags)
        self.regWrite( CPU_REGISTER_EIP, oldEip )
        return rmOperands
    cpdef public unsigned char getCond(self, unsigned char index):
        if (index == 0x0): # O
            return (self.getEFLAG( FLAG_OF ))
        elif (index == 0x1): # NO
            return (not self.getEFLAG( FLAG_OF ))
        elif (index == 0x2): # C
            return (self.getEFLAG( FLAG_CF ))
        elif (index == 0x3): # NC
            return (not self.getEFLAG( FLAG_CF ))
        elif (index == 0x4): # E
            return (self.getEFLAG( FLAG_ZF ))
        elif (index == 0x5): # NE
            return (not self.getEFLAG( FLAG_ZF ))
        elif (index == 0x6): # NA
            return ((self.getEFLAG( FLAG_CF )) or (self.getEFLAG( FLAG_ZF )))
        elif (index == 0x7): # A
            return ((not self.getEFLAG( FLAG_CF )) and (not self.getEFLAG( FLAG_ZF )))
        elif (index == 0x8): # S
            return (self.getEFLAG( FLAG_SF ))
        elif (index == 0x9): # NS
            return (not self.getEFLAG( FLAG_SF ))
        elif (index == 0xa): # P
            return (self.getEFLAG( FLAG_PF ))
        elif (index == 0xb): # NP
            return (not self.getEFLAG( FLAG_PF ))
        elif (index == 0xc): # L
            return ((self.getEFLAG( FLAG_SF )) != (self.getEFLAG( FLAG_OF )))
        elif (index == 0xd): # GE
            return ((self.getEFLAG( FLAG_SF )) == (self.getEFLAG( FLAG_OF )))
        elif (index == 0xe): # LE
            return ((self.getEFLAG( FLAG_ZF )) or ((self.getEFLAG( FLAG_SF )) != (self.getEFLAG( FLAG_OF ))) )
        elif (index == 0xf): # G
            return ((not self.getEFLAG( FLAG_ZF )) and ((self.getEFLAG( FLAG_SF )) == (self.getEFLAG( FLAG_OF ))) )
        else:
            self.main.exitError("getCond: index {0:#x} invalid.", index)
    def setFullFlags(self, long long reg0, long long reg1, unsigned char regSize, unsigned char method, unsigned char signed=False): # regSize in bits
        cdef unsigned char unsignedOverflow, signedOverflow, isResZero, afFlag, reg0Nibble, reg1Nibble, regSumNibble
        cdef unsigned long bitMask, bitMaskHalf
        cdef unsigned long long doubleBitMask, regSumu, regSumMasked, regSumuMasked
        cdef long long regSum
        unsignedOverflow = False
        signedOverflow = False
        isResZero = False
        afFlag = False
        bitMask = self.main.misc.getBitMask(regSize)
        bitMaskHalf = self.main.misc.getBitMask(regSize, half=True, minus=0)
        
        if (method == SET_FLAGS_ADD):
            regSum = reg0+reg1
            regSumMasked = regSum&bitMask
            isResZero = regSumMasked==0
            unsignedOverflow = (regSumMasked < reg0 or regSumMasked < reg1)
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&0xff])
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
            self.setEFLAG(FLAG_OF, ((not isResZero) and signedOverflow))
            self.setEFLAG(FLAG_SF, regSum!=0)
        elif (method == SET_FLAGS_SUB):
            regSum = reg0-reg1
            regSumMasked = regSum&bitMask
            isResZero = regSumMasked==0
            unsignedOverflow = ( regSum<0 )
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&0xff])
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
        elif (method == SET_FLAGS_MUL):
            doubleBitMask = self.main.misc.getBitMask(regSize*2)
            ##doubleBitMaskHalf = self.main.misc.getBitMask(regSize*2, half=True, minus=0)
            regSum = reg0*reg1
            reg0 = (reg0 < 0 and -reg0) or reg0
            reg1 = (reg1 < 0 and -reg1) or reg1
            regSumu = reg0*reg1
            regSumMasked = regSum&doubleBitMask
            regSumuMasked = regSumu&doubleBitMask
            isResZero = regSumMasked==0
            if ((signed and ((regSize != OP_SIZE_BYTE and regSumu <= bitMask) or (regSize == OP_SIZE_BYTE and regSumu <= 0x7f))) or \
                   (not signed and ((regSumu <= bitMask)))):
                self.setEFLAG(FLAG_CF, False)
                self.setEFLAG(FLAG_OF, False)
            else:
                self.setEFLAG(FLAG_CF, True)
                self.setEFLAG(FLAG_OF, True)
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setEFLAG(FLAG_ZF, isResZero)
            self.setEFLAG(FLAG_SF, (regSum&bitMaskHalf)!=0)
        elif (method == SET_FLAGS_DIV):
            pass
        else:
            self.main.exitError("setFullFlags: method not (add, sub, mul or div). (method: {0:d})", method)
    def checkMemAccessRights(self, unsigned short segId, unsigned char write):
        if (not self.cpu.isInProtectedMode()):
            return
        cdef unsigned short segVal = self.segRead(segId)
        if (not self.segments.gdt.isSegPresent(segVal) ):
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
            if (self.segments.gdt.isCodeSeg(segVal) or not self.segments.gdt.isSegReadableWritable(segVal) ):
                if (segId == CPU_SEGMENT_SS):
                    raise misc.ChemuException(CPU_EXCEPTION_SS, segVal)
                else:
                    raise misc.ChemuException(CPU_EXCEPTION_GP, segVal)
        else:
            if (self.segments.gdt.isCodeSeg(segVal) and not self.segments.gdt.isSegReadableWritable(segVal) ):
                raise misc.ChemuException(CPU_EXCEPTION_GP, segVal)
    


