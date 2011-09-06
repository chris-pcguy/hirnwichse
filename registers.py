import misc

# Parity Flag Table: DO NOT EDIT!!
PARITY_TABLE = [True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, False, True, True, False,
                True, False, False, True, True, False, False, True, False, True,
                True, False, False, True, True, False, True, False, False, True,
                True, False, False, True, False, True, True, False, True, False,
                False, True, False, True, True, False, False, True, True, False,
                True, False, False, True, False, True, True, False, True, False,
                False, True, True, False, False, True, False, True, True, False,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, True, False, False, True,
                False, True, True, False, False, True, True, False, True, False,
                False, True, False, True, True, False, True, False, False, True,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, True, False, False, True,
                False, True, True, False, True, False, False, True, False, True,
                True, False, False, True, True, False, True, False, False, True,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, False, True, True, False,
                True, False, False, True, True, False, False, True, False, True,
                True, False, True, False, False, True, False, True, True, False,
                False, True, True, False, True, False, False, True, False, True,
                True, False, True, False, False, True, True, False, False, True,
                False, True, True, False, False, True, True, False, True, False,
                False, True, True, False, False, True, False, True, True, False,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True]

CPU_MIN_REGISTER = 20
CPU_REGISTER_NONE = 0
CPU_REGISTER_RAX = 20
CPU_REGISTER_EAX = 21
CPU_REGISTER_AX  = 22
CPU_REGISTER_AH  = 23
CPU_REGISTER_AL  = 24
CPU_REGISTER_RCX = 25
CPU_REGISTER_ECX = 26
CPU_REGISTER_CX  = 27
CPU_REGISTER_CH  = 28
CPU_REGISTER_CL  = 29
CPU_REGISTER_RDX = 30
CPU_REGISTER_EDX = 31
CPU_REGISTER_DX  = 32
CPU_REGISTER_DH  = 33
CPU_REGISTER_DL  = 34
CPU_REGISTER_RBX = 35
CPU_REGISTER_EBX = 36
CPU_REGISTER_BX  = 37
CPU_REGISTER_BH  = 38
CPU_REGISTER_BL  = 39
CPU_REGISTER_RSP = 40
CPU_REGISTER_ESP = 41
CPU_REGISTER_SP  = 42
CPU_REGISTER_RBP = 45
CPU_REGISTER_EBP = 46
CPU_REGISTER_BP  = 47
CPU_REGISTER_RSI = 50
CPU_REGISTER_ESI = 51
CPU_REGISTER_SI  = 52
CPU_REGISTER_RDI = 55
CPU_REGISTER_EDI = 56
CPU_REGISTER_DI  = 57
CPU_REGISTER_RIP = 60
CPU_REGISTER_EIP = 61
CPU_REGISTER_IP  = 62
CPU_REGISTER_RFLAGS = 65
CPU_REGISTER_EFLAGS = 66
CPU_REGISTER_FLAGS  = 67
CPU_REGISTER_CR0 = 70
CPU_REGISTER_CR2 = 75
CPU_REGISTER_CR3 = 80
CPU_REGISTER_CR4 = 85

CPU_SEGMENT_CS = 92
CPU_SEGMENT_DS = 97
CPU_SEGMENT_ES = 102
CPU_SEGMENT_FS = 107
CPU_SEGMENT_GS = 112
CPU_SEGMENT_SS = 117
CPU_REGISTER_LENGTH = 256*8

FLAG_CF = 0x1
FLAG_PF = 0x4
FLAG_AF = 0x10
FLAG_ZF = 0x40
FLAG_SF = 0x80
FLAG_TF = 0x100
FLAG_IF = 0x200
FLAG_DF = 0x400
FLAG_OF = 0x800
FLAG_IOPL = 0x3000
FLAG_AC = 0x40000


CR0_FLAG_PE  = 0x1
CR4_FLAG_TSD = 0x4


MODRM_FLAGS_SREG = 1
MODRM_FLAGS_CREG = 2
MODRM_FLAGS_DREG = 4




CPU_REGISTER_QWORD=(CPU_REGISTER_RAX,CPU_REGISTER_RCX,CPU_REGISTER_RDX,CPU_REGISTER_RBX,CPU_REGISTER_RSP,
                    CPU_REGISTER_RBP,CPU_REGISTER_RSI,CPU_REGISTER_RDI,CPU_REGISTER_RIP,CPU_REGISTER_RFLAGS,
                    CPU_REGISTER_CR0,CPU_REGISTER_CR2,CPU_REGISTER_CR3,CPU_REGISTER_CR4)

CPU_REGISTER_DWORD=(CPU_REGISTER_EAX,CPU_REGISTER_ECX,CPU_REGISTER_EDX,CPU_REGISTER_EBX,CPU_REGISTER_ESP,
                    CPU_REGISTER_EBP,CPU_REGISTER_ESI,CPU_REGISTER_EDI,CPU_REGISTER_EIP,CPU_REGISTER_EFLAGS)

CPU_REGISTER_WORD=(CPU_REGISTER_AX,CPU_REGISTER_CX,CPU_REGISTER_DX,CPU_REGISTER_BX,CPU_REGISTER_SP,
                   CPU_REGISTER_BP,CPU_REGISTER_SI,CPU_REGISTER_DI,CPU_REGISTER_IP,CPU_REGISTER_FLAGS,
                   CPU_SEGMENT_CS,CPU_SEGMENT_DS,CPU_SEGMENT_ES,CPU_SEGMENT_FS,CPU_SEGMENT_GS,CPU_SEGMENT_SS)

CPU_REGISTER_HBYTE=(CPU_REGISTER_AH,CPU_REGISTER_CH,CPU_REGISTER_DH,CPU_REGISTER_BH)
CPU_REGISTER_LBYTE=(CPU_REGISTER_AL,CPU_REGISTER_CL,CPU_REGISTER_DL,CPU_REGISTER_BL)

CPU_REGISTER_BYTE=(CPU_REGISTER_AL,CPU_REGISTER_CL,CPU_REGISTER_DL,CPU_REGISTER_BL,CPU_REGISTER_AH,CPU_REGISTER_CH,CPU_REGISTER_DH,CPU_REGISTER_BH)

CPU_REGISTER_SREG=(CPU_SEGMENT_ES,CPU_SEGMENT_CS,CPU_SEGMENT_SS,CPU_SEGMENT_DS,CPU_SEGMENT_FS,CPU_SEGMENT_GS,None,None)
CPU_REGISTER_CREG=(CPU_REGISTER_CR0, None, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4, None, None, None)
CPU_REGISTER_DREG=()


CPU_SEGMENTS=(CPU_SEGMENT_ES,CPU_SEGMENT_CS,CPU_SEGMENT_SS,CPU_SEGMENT_DS,CPU_SEGMENT_FS,CPU_SEGMENT_GS,None,None)


GDT_FLAG_GRANULARITY = 0x8
GDT_FLAG_SIZE = 0x4 # 0==16bit; 1==32bit
GDT_FLAG_LONGMODE = 0x2
GDT_FLAG_AVAILABLE = 0x1





class Gdt:
    def __init__(self, main, base, limit):
        self.main = main
        self.loadTable(base, limit)
        self.flushed = False # flush with farJMP
    def loadTable(self, base, limit):
        self.base, self.limit = base, limit
        self.flushed = False
    def getEntry(self, num):
        entryData = self.main.mm.mmPhyReadValue(self.base+num, 8)
        limit = entryData&0xffff
        base  = (entryData>>16)&0xffffff
        accessByte = (entryData>>40)&0xff
        flags  = (entryData>>48)&0xf
        limit |= ( entryData>>48 )<<16
        base  |= ( entryData>>56 )<<24
        return base, limit, accessByte, flags
    def getSegSize(self, num):
        entryRet = self.getEntry(num)
        flags = entryRet[3]
        if (flags & GDT_FLAG_SIZE):
            return misc.OP_SIZE_32BIT
        return misc.OP_SIZE_16BIT

class Idt:
    def __init__(self, main, base, limit):
        self.main = main
        self.loadTable(base, limit)
    def loadTable(self, base, limit):
        self.base, self.limit = base, limit
    def getEntry(self, num):
        entryData = self.main.mm.mmPhyReadValue(self.base+num, 8)
        entryEip = entryData&0xffff
        entrySegment = (entryData>>16)&0xffff
        entryEip |= ((entryData>>48)&0xffff)<<16
        return entrySegment, entryEip
    def getEntryRealMode(self, num):
        offset = num*4
        entryEip = self.main.mm.mmPhyReadValue(self.base+offset, 2)
        entrySegment = self.main.mm.mmPhyReadValue(self.base+offset+2, 2)
        return entrySegment, entryEip


class Segments:
    #cdef object main, cpu, registers, gdt
    def __init__(self, main, cpu, registers):
        self.main, self.cpu, self.registers = main, cpu, registers
        self.gdt = Gdt(self.main, 0, 0xfffff)
        self.idt = Idt(self.main, 0, 0x3ff)
    def getBaseAddr(self, segId): # segId == segments regId
        if (segId != 0 and segId not in CPU_SEGMENTS):
            self.main.exitError("getBaseAddr: segId not in CPU_SEGMENTS")
        if (self.cpu.isInProtectedMode()): # protected mode enabled
            return self.gdt.getEntry(self.registers.regRead(segId))[0]
        #else: # real mode
        return self.registers.regRead(segId)<<4
    def getRealAddr(self, segId, offsetAddr):
        addr = (self.getBaseAddr(segId)+offsetAddr)
        if (not self.cpu.isInProtectedMode):
            if (self.cpu.getA20State()): # A20 Active? if True == on, else off
                addr &= 0xffffff
            else:
                addr &= 0xfffff
        return addr
    def getSegSize(self, segId): # segId == segments regId
        if (self.cpu.isInProtectedMode()): # protected mode enabled
            return self.gdt.getSegSize(self.registers.regRead(segId))
        #else: # real mode
        return misc.OP_SIZE_16BIT
    def getOpSegSize(self, segId): # segId == segments regId
        segSize = self.getSegSize(segId)
        if (segSize == misc.OP_SIZE_16BIT):
            return ((self.registers.operandSizePrefix and misc.OP_SIZE_32BIT) or misc.OP_SIZE_16BIT)
        elif (segSize == misc.OP_SIZE_32BIT):
            return ((self.registers.operandSizePrefix and misc.OP_SIZE_16BIT) or misc.OP_SIZE_32BIT)
        else:
            self.main.exitError("getOpSegSize: segSize is not valid. ({0:d})", segSize)
    def getAddrSegSize(self, segId): # segId == segments regId
        segSize = self.getSegSize(segId)
        if (segSize == misc.OP_SIZE_16BIT):
            return ((self.registers.addressSizePrefix and misc.OP_SIZE_32BIT) or misc.OP_SIZE_16BIT)
        elif (segSize == misc.OP_SIZE_32BIT):
            return ((self.registers.addressSizePrefix and misc.OP_SIZE_16BIT) or misc.OP_SIZE_32BIT)
        else:
            self.main.exitError("getAddrSegSize: segSize is not valid. ({0:d})", segSize)

class Registers:
    def __init__(self, main, cpu):
        self.main, self.cpu = main, cpu
        self.regs = bytearray(CPU_REGISTER_LENGTH)
        self.segments = Segments(self.main, self.cpu, self)
        self.reset()
    def reset(self):
        self.regs = bytearray(CPU_REGISTER_LENGTH)
        self.regWrite(CPU_REGISTER_FLAGS, 0x2)
        self.regWrite(CPU_SEGMENT_CS, 0xf000)
        self.regWrite(CPU_REGISTER_IP, 0xfff0)
        self.resetPrefixes()
    def resetPrefixes(self):
        self.lockPrefix = False
        self.branchPrefix = False
        self.repPrefix = False
        self.segmentOverridePrefix = 0
        self.operandSizePrefix = False
        self.addressSizePrefix = False
        self.cpl, self.iopl = 0, 0
    def regGetSize(self, regId): # return size in bits
        if (regId in CPU_REGISTER_QWORD):
            return misc.OP_SIZE_64BIT
        elif (regId in CPU_REGISTER_DWORD):
            return misc.OP_SIZE_32BIT
        elif (regId in CPU_REGISTER_WORD):
            return misc.OP_SIZE_16BIT
        elif (regId in CPU_REGISTER_BYTE):
            return misc.OP_SIZE_8BIT
        raise NameError("regId is unknown! ({0})".format(regId))
    def unsignedToSigned(self, uint, intSize): # 0xff == -1; 0xfe == -2 ...; 0x02==0x02, 0x50==0x50...
        if (intSize not in (misc.OP_SIZE_8BIT, misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT, misc.OP_SIZE_64BIT)):
            raise NameError("intSize is invalid! ({0})".format(intSize))
        bitMask = self.main.misc.getBitMask(intSize)
        halfBitMask = self.main.misc.getBitMask(intSize, half=True, minus=0)
        minusInt = self.main.misc.getBitMask(intSize, minus=0)
        if (uint&halfBitMask):
            return (uint&bitMask)-minusInt
        else:
            return uint&bitMask
    def regRead(self, regId, signed=False): #, regIdIsVal=False): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        if (regId == CPU_REGISTER_NONE):
            return 0
        if (regId < CPU_MIN_REGISTER):
            raise NameError("regId is reserved! ({0})".format(regId))
        
        regValue = 0
        aregId = (regId-(regId%5))*8
        if (regId in CPU_REGISTER_QWORD):
            regValue = int.from_bytes(bytes=self.regs[aregId:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_DWORD):
            regValue = int.from_bytes(bytes=self.regs[aregId+4:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_WORD):
            regValue = int.from_bytes(bytes=self.regs[aregId+6:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_HBYTE):
            regValue = int.from_bytes(bytes=bytes([self.regs[aregId+6]]), byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_LBYTE):
            regValue = int.from_bytes(bytes=bytes([self.regs[aregId+7]]), byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        else:
            raise NameError("regId is unknown! ({0})".format(regId))
        return regValue
    def regWrite(self, regId, value, signed=False): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        if (regId < CPU_MIN_REGISTER):
            raise NameError("regId is reserved! ({0})".format(regId))
        
        aregId = (regId-(regId%5))*8
        if (regId in CPU_REGISTER_QWORD):
            value &= 0xffffffffffffffff
            self.regs[aregId:aregId+8] = value.to_bytes(length=8, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_DWORD):
            value &= 0xffffffff
            self.regs[aregId+4:aregId+8] = value.to_bytes(length=4, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_WORD):
            value &= 0xffff
            self.regs[aregId+6:aregId+8] = value.to_bytes(length=2, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_HBYTE):
            value &= 0xff
            self.regs[aregId+6] = ord(value.to_bytes(length=1, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed))
        elif (regId in CPU_REGISTER_LBYTE):
            value &= 0xff
            self.regs[aregId+7] = ord(value.to_bytes(length=1, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed))
        else:
            raise NameError("regId is unknown! ({0})".format(regId))
    def regReadEip(self, signed=False):
        regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == misc.OP_SIZE_32BIT):
            regSizeId = CPU_REGISTER_EIP
        self.registers.regRead(regSizeId, signed=signed)
    def regWriteEip(self, value):
        regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == misc.OP_SIZE_32BIT):
            regSizeId = CPU_REGISTER_EIP
        self.registers.regWrite(regSizeId, value)
    def regAdd(self, regId, value, signed=False):
        self.regWrite(regId, self.regRead(regId, signed=signed)+value, signed=signed)
    def regSub(self, regId, value, signed=False):
        self.regWrite(regId, self.regRead(regId, signed=signed)-value, signed=signed)
    def regXor(self, regId, value, signed=False):
        self.regWrite(regId, self.regRead(regId, signed=signed)^value, signed=signed)
    def regAnd(self, regId, value, signed=False):
        self.regWrite(regId, self.regRead(regId, signed=signed)&value, signed=signed)
    def regOr (self, regId, value, signed=False):
        self.regWrite(regId, self.regRead(regId, signed=signed)|value, signed=signed)
    def regSetFlag(self, regId, value, signed=False):
        self.regOr(regId, value, signed=signed)
    def regNeg(self, regId, signed=False):
        self.regWrite(regId, -self.regRead(regId, signed=signed), signed=signed)
    def regNot(self, regId, signed=False):
        self.regWrite(regId, ~self.regRead(regId, signed=signed), signed=signed)
    def regDelFlag(self, regId, value, signed=False): # by val, not bit
        self.regWrite(regId, self.regRead(regId, signed=signed)&(~value), signed=signed)
    def regSetBit(self, regId, bit, state):
        if (state):
            self.regWrite(regId, self.regRead(regId)|(1<<bit))
        else:
            self.regWrite(regId, self.regRead(regId)&(~(1<<bit)))
    def regGetBit(self, regId, bit): # return True if bit is set, otherwise False
        bitMask = (1<<bit)
        return (self.regRead(regId)&bitMask)!=0
    def valSetBit(self, value, bit, state):
        if (state):
            return ( value | (1<<bit) )
        else:
            return ( value & (~(1<<bit)) )
    def valGetBit(self, value, bit): # return True if bit is set, otherwise False
        bitMask = (1<<bit)
        return (value&bitMask)!=0
    def regInc(self, regId, signed=False):
        self.regAdd(regId, 1, signed=signed)
    def regDec(self, regId, signed=False):
        self.regSub(regId, 1, signed=signed)
    def setEFLAG(self, flags, flagState):
        if (flagState):
            self.regSetFlag(CPU_REGISTER_EFLAGS, flags)
            return
        self.regDelFlag(CPU_REGISTER_EFLAGS, flags)
    def getEFLAG(self, flags):
        return (self.regRead(CPU_REGISTER_EFLAGS)&flags)!=0
    def getFlag(self, regId, flags):
        return (self.regRead(regId)&flags)!=0
    def clearFlags(self, flags):
        if (flags & FLAG_CF):
            self.setEFLAG(FLAG_CF, False)
        if (flags & FLAG_PF):
            self.setEFLAG(FLAG_PF, False)
        if (flags & FLAG_AF):
            self.setEFLAG(FLAG_AF, False)
        if (flags & FLAG_ZF):
            self.setEFLAG(FLAG_ZF, False)
        if (flags & FLAG_SF):
            self.setEFLAG(FLAG_SF, False)
        if (flags & FLAG_TF):
            self.setEFLAG(FLAG_TF, False)
        if (flags & FLAG_IF):
            self.setEFLAG(FLAG_IF, False)
        if (flags & FLAG_DF):
            self.setEFLAG(FLAG_DF, False)
        if (flags & FLAG_OF):
            self.setEFLAG(FLAG_OF, False)
        if (flags & FLAG_AC):
            self.setEFLAG(FLAG_AC, False)
    def setFlags(self, flags):
        if (flags & FLAG_CF):
            self.setEFLAG(FLAG_CF, True)
        if (flags & FLAG_PF):
            self.setEFLAG(FLAG_PF, True)
        if (flags & FLAG_AF):
            self.setEFLAG(FLAG_AF, True)
        if (flags & FLAG_ZF):
            self.setEFLAG(FLAG_ZF, True)
        if (flags & FLAG_SF):
            self.setEFLAG(FLAG_SF, True)
        if (flags & FLAG_TF):
            self.setEFLAG(FLAG_TF, True)
        if (flags & FLAG_IF):
            self.setEFLAG(FLAG_IF, True)
        if (flags & FLAG_DF):
            self.setEFLAG(FLAG_DF, True)
        if (flags & FLAG_OF):
            self.setEFLAG(FLAG_OF, True)
        if (flags & FLAG_AC):
            self.setEFLAG(FLAG_AC, True)
    def setSZP(self, value, regSize):
        self.setEFLAG(FLAG_SF, (value&self.main.misc.getBitMask(regSize, half=True, minus=0))!=0)
        self.setEFLAG(FLAG_ZF, value==0)
        self.setEFLAG(FLAG_PF, PARITY_TABLE[value&0xff])
    def setSZP_O0(self, value, regSize):
        self.clearFlags(FLAG_OF)
        self.setSZP(value, regSize)
    def setSZP_C0_O0(self, value, regSize):
        self.clearFlags(FLAG_CF)
        self.setSZP_O0(value, regSize)
    def setSZP_C0_O0_SubAF(self, value, regSize):
        self.setSZP_C0_O0(value, regSize)
        self.setEFLAG(FLAG_AF, 0)
    def setSZP_C0_O0_AndAF(self, value, regSize):
        self.setSZP_C0_O0(value, regSize)
        self.setEFLAG(FLAG_AF, 0)
    def getDefaultSegment(self, segId=0):
        if (segId == 0):
            segId = CPU_SEGMENT_DS
            if (self.main.cpu.registers.segmentOverridePrefix):
                segId = self.main.cpu.registers.segmentOverridePrefix
        return segId
    def getRMValueFull(self, rmValue, rmSize):
        rmMask = self.main.misc.getBitMask(rmSize)
        rmValueFull =  self.regRead(rmValue[0])
        rmValueFull += self.regRead(rmValue[1])
        rmValueFull += rmValue[2]
        rmValueFull &= rmMask
        return rmValueFull
    def modRMLoad(self, rmOperands, regSize, signed=False, allowOverride=True): # imm == unsigned ; disp == signed; regSize in bits
        mod, rmValue, regValue = rmOperands
        addrSize = self.segments.getAddrSegSize(CPU_SEGMENT_CS)
        returnInt = 0
        rmValueFull = self.getRMValueFull(rmValue[0], addrSize)
        if (mod in (0, 1, 2)):
            returnInt = self.main.mm.mmReadValue(rmValueFull, regSize, segId=rmValue[1], signed=signed, allowOverride=allowOverride)
        else:
            returnInt = self.regRead(rmValue[0][0], signed=signed)
        return returnInt
    def modRLoad(self, rmOperands, regSize, signed=False): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        returnInt  = self.regRead(regValue, signed=signed)
        return returnInt
    def modRSave(self, rmOperands, regSize, value): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        value &= self.main.misc.getBitMask(regSize)
        self.regWrite(regValue, value)
    def modRMSave(self, rmOperands, regSize, value, signed=False, allowOverride=True): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        addrSize = self.segments.getAddrSegSize(CPU_SEGMENT_CS)
        value &= self.main.misc.getBitMask(regSize)
        rmValueFull = self.getRMValueFull(rmValue[0], addrSize)
        if (mod in (0, 1, 2)):
            self.main.mm.mmWriteValue(rmValueFull, value, regSize, segId=rmValue[1], signed=signed, allowOverride=allowOverride)
        else:
            self.regWrite(rmValue[0][0], value)
    def getRegValueWithFlags(self, modRMflags, reg, operSize):
        ###operSize = self.segments.getOpSegSize(CPU_SEGMENT_CS)
        regValue = 0
        if (modRMflags & MODRM_FLAGS_SREG):
            regValue = CPU_REGISTER_SREG[reg]
        elif (modRMflags & MODRM_FLAGS_CREG):
            regValue = CPU_REGISTER_CREG[reg]
        elif (modRMflags & MODRM_FLAGS_DREG):
            #regValue = CPU_REGISTER_DREG[reg]
            self.main.exitError("debug register NOT IMPLEMENTED yet!")
        else:
            if (operSize == misc.OP_SIZE_8BIT):
                regValue = CPU_REGISTER_BYTE[reg]
            elif (operSize == misc.OP_SIZE_16BIT):
                regValue = CPU_REGISTER_WORD[reg]
            elif (operSize == misc.OP_SIZE_32BIT):
                regValue = CPU_REGISTER_DWORD[reg]
            else:
                self.main.exitError("getRegValueWithFlags: operSize not in (misc.OP_SIZE_8BIT, misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT)")
        return regValue
    def sibOperands(self, mod):
        sibByte = self.cpu.getCurrentOpcodeAdd()
        bitMask = 0xffffffff
        base    = (sibByte)&7
        index   = (sibByte>>3)&7
        ss      = (sibByte>>6)&3
        rmBase  = CPU_REGISTER_NONE
        rmIndex = 0
        rmValueSegId = CPU_SEGMENT_DS
        
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
            rmIndex += self.cpu.getCurrentOpcodeAdd(misc.OP_SIZE_32BIT, signed=False)
        else:
            rmBase = self.getRegValueWithFlags(0, base, misc.OP_SIZE_32BIT)
        if (rmBase in (CPU_REGISTER_ESP, CPU_REGISTER_EBP)):
            rmValueSegId = CPU_SEGMENT_SS
        
        
        return rmBase, rmValueSegId, rmIndex
    def modRMOperands(self, regSize, modRMflags=0): # imm == unsigned ; disp == signed ; regSize in bits
        modRMByte = self.cpu.getCurrentOpcodeAdd()
        rm  = modRMByte&0x7
        reg = (modRMByte>>3)&0x7
        mod = (modRMByte>>6)&0x3

        rmValueSegId = self.getDefaultSegment()
        rmValue0, rmValue1, rmValue2 = 0, 0, 0
        regValue = 0
        if (self.segments.getAddrSegSize(CPU_SEGMENT_CS) == misc.OP_SIZE_16BIT):
            if (mod in (0, 1, 2)): # rm: source ; reg: dest
                if (rm in (0, 1, 7)):
                    rmValue0 = CPU_REGISTER_BX
                elif (rm in (2, 3) or (rm == 6 and mod in (1,2))):
                    rmValue0 = CPU_REGISTER_BP
                    rmValueSegId = CPU_SEGMENT_SS
                elif (rm == 4):
                    rmValue0 = CPU_REGISTER_SI
                elif (rm == 5):
                    rmValue0 = CPU_REGISTER_DI
                if (rm in (0, 2)):
                    rmValue1 = CPU_REGISTER_SI
                elif (rm in (1, 3)):
                    rmValue1 = CPU_REGISTER_DI
                regValue  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
                if (mod == 0 and rm == 6):
                    rmValue2 = self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_16BIT, signed=False)
                elif (mod == 2):
                    rmValue2 = self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_16BIT, signed=True)
                elif (mod == 1):
                    rmValue2 = self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_8BIT, signed=True)
            elif (mod == 3): # reg: source ; rm: dest
                regValue  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
                if (regSize == misc.OP_SIZE_8BIT):
                    rmValue0  = CPU_REGISTER_BYTE[rm] # dest
                elif (regSize == misc.OP_SIZE_16BIT):
                    rmValue0  = CPU_REGISTER_WORD[rm] # dest
                elif (regSize == misc.OP_SIZE_32BIT):
                    rmValue0  = CPU_REGISTER_DWORD[rm] # dest
                else:
                    self.main.exitError("modRMOperands: mod==3; regSize {0:d} not in (misc.OP_SIZE_8BIT, misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT)", regSize)
            else:
                self.main.exitError("modRMOperands: mod not in (0,1,2)")
        elif (self.segments.getAddrSegSize(CPU_SEGMENT_CS) == misc.OP_SIZE_32BIT):
            if (mod in (0, 1, 2)): # rm: source ; reg: dest
                if (rm == 0):
                    rmValue0 = CPU_REGISTER_EAX
                elif (rm == 1):
                    rmValue0 = CPU_REGISTER_ECX
                elif (rm == 2):
                    rmValue0 = CPU_REGISTER_EDX
                elif (rm == 3):
                    rmValue0 = CPU_REGISTER_EBX
                elif (rm == 4): # SIB
                    rmValue0, rmValueSegId, rmValue2 = self.sibOperands(mod)
                elif (rm == 5):
                    if (mod == 0):
                        rmValue2 = self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_32BIT, signed=False)
                    else:
                        rmValue0 = CPU_REGISTER_EBP
                        rmValueSegId = CPU_SEGMENT_SS
                elif (rm == 6):
                    rmValue0 = CPU_REGISTER_ESI
                elif (rm == 7):
                    rmValue0 = CPU_REGISTER_EDI
                if (mod == 1):
                    rmValue2 += self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_8BIT, signed=True)
                elif (mod == 2):
                    rmValue2 += self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_32BIT, signed=True)
                
                
                
                regValue  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
                
            elif (mod == 3): # reg: source ; rm: dest
                regValue  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
                if (regSize == misc.OP_SIZE_8BIT):
                    rmValue0  = CPU_REGISTER_BYTE[rm] # dest
                elif (regSize == misc.OP_SIZE_16BIT):
                    rmValue0  = CPU_REGISTER_WORD[rm] # dest
                elif (regSize == misc.OP_SIZE_32BIT):
                    rmValue0  = CPU_REGISTER_DWORD[rm] # dest
                else:
                    self.main.exitError("modRMOperands: mod==3; regSize {0:d} not in (misc.OP_SIZE_8BIT, misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT)", regSize)
            else:
                self.main.exitError("modRMOperands: mod not in (0,1,2)")
        else:
            self.main.exitError("modRMOperands: AddrSegSize(CS) not in (misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT)")
        return (mod, ((rmValue0, rmValue1, rmValue2), rmValueSegId), regValue)
    def modRMOperandsResetEip(self, regSize, modRMflags=0):
        oldEip = self.regRead( CPU_REGISTER_EIP )
        rmOperands = self.modRMOperands(regSize, modRMflags=modRMflags)
        self.regWrite( CPU_REGISTER_EIP, oldEip )
        return rmOperands
    def getCond(self, index):
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
    def setFullFlags(self, reg0, reg1, regSize, method, signed=False): # regSize in bits
        regSum = 0
        regSumMasked = 0
        unsignedOverflow = False
        signedOverflow = False
        isResZero = False
        afFlag = False
        bitMask = self.main.misc.getBitMask(regSize)
        doubleBitMask = self.main.misc.getBitMask(regSize*2)
        bitMaskHalf = self.main.misc.getBitMask(regSize, half=True, minus=0)
        doubleBitMaskHalf = self.main.misc.getBitMask(regSize*2, half=True, minus=0)
        
        if (method == misc.SET_FLAGS_ADD):
            regSum = reg0+reg1
            regSumMasked = regSum&bitMask
            isResZero = regSumMasked==0
            unsignedOverflow = (regSum > bitMask)
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setEFLAG(FLAG_ZF, isResZero)
            if ( (((reg0&0xf)+(reg1&0xf))>regSum&0xf or reg0>bitMask or reg1>bitMask)):# or regSum>bitMask) ):
                afFlag = True
            self.setEFLAG(FLAG_AF, afFlag)
            self.setEFLAG(FLAG_CF, unsignedOverflow)
            signedOverflow = ( (((not (reg0&bitMask)&bitMaskHalf) and (not (reg1&bitMask)&bitMaskHalf)) and (regSumMasked&bitMaskHalf)) or \
                               ((((reg0&bitMask)&bitMaskHalf) and ((reg1&bitMask)&bitMaskHalf)) and not (regSumMasked&bitMaskHalf)) )
            self.setEFLAG(FLAG_OF, ((not isResZero) and signedOverflow))
            self.setEFLAG(FLAG_SF, (regSum&bitMaskHalf)!=0)
        elif (method == misc.SET_FLAGS_SUB):
            regSum = reg0-reg1
            regSumMasked = regSum&bitMask
            isResZero = regSumMasked==0
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setEFLAG(FLAG_ZF, isResZero)
            if ( (((reg0&0xf)-(reg1&0xf)) < regSum&0xf) and reg1!=0):# or regSum<0)):# or regSum>bitMask) ):
                afFlag = True
            self.setEFLAG(FLAG_AF, afFlag)
            self.setEFLAG(FLAG_CF, ( regSum<0 ) )
            signedOverflow = ( ((((reg0&bitMask)&bitMaskHalf) and (not (reg1&bitMask)&bitMaskHalf)) and not (regSumMasked&bitMaskHalf)) or \
                               ((not ((reg0&bitMask)&bitMaskHalf) and ((reg1&bitMask)&bitMaskHalf)) and (regSumMasked&bitMaskHalf)) )
            self.setEFLAG(FLAG_OF, (not isResZero and signedOverflow))
            
            
            self.setEFLAG(FLAG_SF, (regSum&bitMaskHalf)!=0)
            pass
        elif (method == misc.SET_FLAGS_MUL):
            regSum = reg0*reg1
            reg0u = (reg0 < 0 and -reg0) or reg0
            reg1u = (reg1 < 0 and -reg1) or reg1
            regSumu = reg0u*reg1u
            regSumMasked = regSum&doubleBitMask
            regSumuMasked = regSumu&doubleBitMask
            isResZero = regSumMasked==0
            regSumCheckOne = regSum
            if ((signed and ((regSize != misc.OP_SIZE_8BIT and regSumu <= bitMask) or (regSize == misc.OP_SIZE_8BIT and regSumu <= 0x7f))) or \
                   (not signed and ((regSumu <= bitMask)))):
                self.setEFLAG(FLAG_CF, False)
                self.setEFLAG(FLAG_OF, False)
            else:
                self.setEFLAG(FLAG_CF, True)
                self.setEFLAG(FLAG_OF, True)
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setEFLAG(FLAG_ZF, isResZero)
            self.setEFLAG(FLAG_SF, (regSum&bitMaskHalf)!=0)
        elif (method == misc.SET_FLAGS_DIV):
            pass
        else:
            self.main.exitError("setFullFlags: method not (add, sub, mul or div). (method: {0:d})", method)



