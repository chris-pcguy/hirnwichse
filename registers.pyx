import misc



# Parity Table: DO NOT EDIT!!
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

CPU_REGISTER_RAX = 0
CPU_REGISTER_EAX = 1
CPU_REGISTER_AX  = 2
CPU_REGISTER_AH  = 3
CPU_REGISTER_AL  = 4
CPU_REGISTER_RCX = 5
CPU_REGISTER_ECX = 6
CPU_REGISTER_CX  = 7
CPU_REGISTER_CH  = 8
CPU_REGISTER_CL  = 9
CPU_REGISTER_RDX = 10
CPU_REGISTER_EDX = 11
CPU_REGISTER_DX  = 12
CPU_REGISTER_DH  = 13
CPU_REGISTER_DL  = 14
CPU_REGISTER_RBX = 15
CPU_REGISTER_EBX = 16
CPU_REGISTER_BX  = 17
CPU_REGISTER_BH  = 18
CPU_REGISTER_BL  = 19
CPU_REGISTER_RSP = 20
CPU_REGISTER_ESP = 21
CPU_REGISTER_SP  = 22
CPU_REGISTER_RBP = 25
CPU_REGISTER_EBP = 26
CPU_REGISTER_BP  = 27
CPU_REGISTER_RSI = 30
CPU_REGISTER_ESI = 31
CPU_REGISTER_SI  = 32
CPU_REGISTER_RDI = 35
CPU_REGISTER_EDI = 36
CPU_REGISTER_DI  = 37
CPU_REGISTER_RIP = 40
CPU_REGISTER_EIP = 41
CPU_REGISTER_IP  = 42
CPU_REGISTER_RFLAGS = 45
CPU_REGISTER_EFLAGS = 46
CPU_REGISTER_FLAGS  = 47
CPU_REGISTER_CR0 = 50
CPU_REGISTER_CR2 = 55
CPU_REGISTER_CR3 = 60
CPU_REGISTER_CR4 = 65

CPU_SEGMENT_CS = 72
CPU_SEGMENT_DS = 77
CPU_SEGMENT_ES = 82
CPU_SEGMENT_FS = 87
CPU_SEGMENT_GS = 92
CPU_SEGMENT_SS = 97
CPU_REGISTER_LENGTH = 100*8

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


CR0_FLAG_PE = 0x1


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


class RegImm:
    def __init__(self, long value=0):
        self.isRegImm = True
        self.value = value
    def getValue(self):
        return self.value
    def setValue(self, value):
        self.value = value

class Gdt:
    def __init__(self):
        pass
    def loadGdt(self, long gdtBaseAddr):
        pass

class Segments:
    def __init__(self, main, cpu, registers):
        self.main, self.cpu, self.registers = main, cpu, registers
        self.gdt = Gdt()
    def getBase(self, int segId): # segId == segments regId
        if (self.registers.getFlag(CPU_REGISTER_CR0, CR0_FLAG_PE)): # protected mode enabled
            self.main.exitError("GDT: protected mode not supported.")
            return
        #else: # real mode
        return self.registers.regRead(segId)<<4
    def getRealAddr(self, int segId, long offsetAddr):
        return (self.getBase(segId)+offsetAddr)
    def getSegSize(self, int segId): # segId == segments regId
        if (self.registers.getFlag(CPU_REGISTER_CR0, CR0_FLAG_PE)): # protected mode enabled
            self.main.exitError("GDT: protected mode not supported.")
            return
        #else: # real mode
        return misc.OP_SIZE_16BIT
    def getOpSegSize(self, int segId): # segId == segments regId
        cdef int segSize = self.getSegSize(segId)
        if (segSize == misc.OP_SIZE_16BIT):
            return ((self.registers.operandSizePrefix and misc.OP_SIZE_32BIT) or misc.OP_SIZE_16BIT)
        elif (segSize == misc.OP_SIZE_32BIT):
            return ((self.registers.operandSizePrefix and misc.OP_SIZE_16BIT) or misc.OP_SIZE_32BIT)
        else:
            self.main.exitError("getOpSegSize: segSize is not valid. ({0:d})", segSize)
    def getAddrSegSize(self, int segId): # segId == segments regId
        cdef int segSize = self.getSegSize(segId)
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
        self.regSetFlag = self.regOr
        self.reset()
    def reset(self):
        self.regWrite(CPU_REGISTER_FLAGS, 0x2)
        self.regWrite(CPU_SEGMENT_CS, 0xf000)
        self.regWrite(CPU_REGISTER_IP, 0xfff0)
        self.resetPrefixes()
    def resetPrefixes(self):
        self.lockPrefix = False
        self.branchPrefix = False
        self.repPrefix = False
        self.segmentOverridePrefix = False
        self.operandSizePrefix = False
        self.addressSizePrefix = False
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
    def regRead(self, regId, int signedValue=False): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' here, IT WON'T WORK!!!!
        cdef long regValue = 0
        if (isinstance(regId, RegImm)):
            regValue = regId.getValue()
            return regValue
        aregId = (regId-(regId%5))*8
        if (regId in CPU_REGISTER_QWORD):
            regValue = regValue.from_bytes(bytes=self.regs[aregId:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signedValue)
        elif (regId in CPU_REGISTER_DWORD):
            regValue = regValue.from_bytes(bytes=self.regs[aregId+4:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signedValue)
        elif (regId in CPU_REGISTER_WORD):
            regValue = regValue.from_bytes(bytes=self.regs[aregId+6:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signedValue)
        elif (regId in CPU_REGISTER_HBYTE):
            regValue = regValue.from_bytes(bytes=bytes([self.regs[aregId+6]]), byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signedValue)
        elif (regId in CPU_REGISTER_LBYTE):
            regValue = regValue.from_bytes(bytes=bytes([self.regs[aregId+7]]), byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signedValue)
        else:
            raise NameError("regId is unknown! ({0})".format(regId))
        return regValue
    def regWrite(self, regId, long value, int signedValue=False): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' here, IT WON'T WORK!!!!
        if (isinstance(regId, RegImm)):
            return regId.setValue(value)
        aregId = (regId-(regId%5))*8
        if (regId in CPU_REGISTER_QWORD):
            self.regs[aregId:aregId+8] = value.to_bytes(length=8, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signedValue)
        elif (regId in CPU_REGISTER_DWORD):
            self.regs[aregId+4:aregId+8] = value.to_bytes(length=4, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signedValue)
        elif (regId in CPU_REGISTER_WORD):
            self.regs[aregId+6:aregId+8] = value.to_bytes(length=2, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signedValue)
        elif (regId in CPU_REGISTER_HBYTE):
            self.regs[aregId+6] = ord(value.to_bytes(length=1, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signedValue))
        elif (regId in CPU_REGISTER_LBYTE):
            self.regs[aregId+7] = ord(value.to_bytes(length=1, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signedValue))
        else:
            raise NameError("regId is unknown! ({0})".format(regId))
    def regReadEip(self, int signedValue=False):
        cdef int regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == misc.OP_SIZE_32BIT):
            regSizeId = CPU_REGISTER_EIP
        self.registers.regRead(regSizeId, signedValue)
    def regWriteEip(self, long value):
        cdef int regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == misc.OP_SIZE_32BIT):
            regSizeId = CPU_REGISTER_EIP
        self.registers.regWrite(regSizeId, value)
    def regAdd(self, int regId, long value, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)+value)
    def regSub(self, int regId, long value, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)-value)
    def regXor(self, int regId, long value, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)^value)
    def regAnd(self, int regId, long value, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)&value)
    def regOr (self, int regId, long value, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)|value)
    def regNeg(self, int regId, int signedValue=False):
        self.regWrite(regId, -self.regRead(regId, signedValue))
    def regNot(self, int regId, int signedValue=False):
        self.regWrite(regId, ~self.regRead(regId, signedValue))
    def regDelFlag(self, int regId, long value, int signedValue=False): # by val, not bit
        self.regWrite(regId, self.regRead(regId, signedValue)&(~value))
    def regDeleteBit(self, int regId, int bit, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)&(~(1<<bit)))
    def regSetBit(self, int regId, int bit, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)|(1<<bit))
    def regInc(self, int regId, int signedValue=False):
        self.regAdd(regId, 1, signedValue)
    def regDec(self, int regId, int signedValue=False):
        self.regSub(regId, 1, signedValue)
    def setFlag(self, int regId, long flags, long flagState):
        if (flagState):
            return self.regSetFlag(CPU_REGISTER_EFLAGS, flags)
        return self.regDelFlag(CPU_REGISTER_EFLAGS, flags)
    def getFlag(self, int regId, long flags):
        return (self.regRead(regId)&flags)!=0
    def clearFlags(self, long flags):
        if (flags & FLAG_CF):
            self.regDelFlag(CPU_REGISTER_EFLAGS, FLAG_CF)
        if (flags & FLAG_PF):
            self.regDelFlag(CPU_REGISTER_EFLAGS, FLAG_PF)
        if (flags & FLAG_AF):
            self.regDelFlag(CPU_REGISTER_EFLAGS, FLAG_AF)
        if (flags & FLAG_ZF):
            self.regDelFlag(CPU_REGISTER_EFLAGS, FLAG_ZF)
        if (flags & FLAG_SF):
            self.regDelFlag(CPU_REGISTER_EFLAGS, FLAG_SF)
        if (flags & FLAG_TF):
            self.regDelFlag(CPU_REGISTER_EFLAGS, FLAG_TF)
        if (flags & FLAG_IF):
            self.regDelFlag(CPU_REGISTER_EFLAGS, FLAG_IF)
        if (flags & FLAG_DF):
            self.regDelFlag(CPU_REGISTER_EFLAGS, FLAG_DF)
        if (flags & FLAG_OF):
            self.regDelFlag(CPU_REGISTER_EFLAGS, FLAG_OF)
    def setFlags(self, long flags):
        if (flags & FLAG_CF):
            self.regSetFlag(CPU_REGISTER_EFLAGS, FLAG_CF)
        if (flags & FLAG_PF):
            self.regSetFlag(CPU_REGISTER_EFLAGS, FLAG_PF)
        if (flags & FLAG_AF):
            self.regSetFlag(CPU_REGISTER_EFLAGS, FLAG_AF)
        if (flags & FLAG_ZF):
            self.regSetFlag(CPU_REGISTER_EFLAGS, FLAG_ZF)
        if (flags & FLAG_SF):
            self.regSetFlag(CPU_REGISTER_EFLAGS, FLAG_SF)
        if (flags & FLAG_TF):
            self.regSetFlag(CPU_REGISTER_EFLAGS, FLAG_TF)
        if (flags & FLAG_IF):
            self.regSetFlag(CPU_REGISTER_EFLAGS, FLAG_IF)
        if (flags & FLAG_DF):
            self.regSetFlag(CPU_REGISTER_EFLAGS, FLAG_DF)
        if (flags & FLAG_OF):
            self.regSetFlag(CPU_REGISTER_EFLAGS, FLAG_OF)
    def modR_RMLoad(self, rmOperands, int regSize, int signedValue=False): # imm == unsigned ; disp == signed; regSize in bits
        mod, rmValue, regValue = rmOperands
        cdef long returnInt = 0
        if (mod in (0, 1, 2)):
            returnInt = returnInt.from_bytes(bytes=self.main.mm.mmRead(rmValue[0], regSize, segId=rmValue[1]), byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=signedValue)
        else:
            returnInt = self.regRead(rmValue[0])
        returnInt &= self.main.misc.getBitMask(regSize)
        return returnInt
    def modRM_RLoad(self, rmOperands, int regSize): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        cdef long returnInt = self.regRead(regValue)&self.main.misc.getBitMask(regSize)
        return returnInt
    def modR_RMSave(self, rmOperands, int regSize, long value): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        value &= self.main.misc.getBitMask(regSize)
        self.regWrite(regValue, value)
    def modRM_RSave(self, rmOperands, int regSize, long value, int signedValue=False): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        value &= self.main.misc.getBitMask(regSize)
        if (mod in (0, 1, 2)):
            self.main.mm.mmWrite(rmValue[0], value, regSize, segId=rmValue[1])
        else:
            self.regWrite(rmValue[0], value)
    def getRegValueWithFlags(self, long modRMflags, int reg):
        if (modRMflags & MODRM_FLAGS_SREG):
            regValue = CPU_REGISTER_SREG[reg]
        elif (modRMflags & MODRM_FLAGS_CREG):
            regValue = CPU_REGISTER_CREG[reg]
        elif (modRMflags & MODRM_FLAGS_DREG):
            #regValue = CPU_REGISTER_DREG[reg]
            self.main.exitError("debug register NOT IMPLEMENTED yet!")
        else:
            regValue = CPU_REGISTER_WORD[reg]
        return regValue
    def modRMOperands(self, int regSize, long modRMflags=0): # imm == unsigned ; disp == signed ; regSize in bits
        cdef int modRMByte = self.cpu.getCurrentOpcodeAdd()
        cdef int rm  = modRMByte&0x7
        cdef int reg = (modRMByte>>3)&0x7
        cdef int mod = (modRMByte>>6)&0x3

        cdef int rmValueSegId = CPU_SEGMENT_DS
        cdef long rmValue  = 0
        cdef long regValue = 0
        if (self.segments.getAddrSegSize(CPU_SEGMENT_CS) == misc.OP_SIZE_16BIT):
            if (mod in (0, 1, 2)): # rm: source ; reg: dest
                if (rm in (0, 1, 7)):
                    rmValue += CPU_REGISTER_BX
                elif (rm in (2, 3)):
                    rmValue += CPU_REGISTER_BP
                    rmValueSegId = CPU_SEGMENT_SS
                elif (rm == 4):
                    rmValue += CPU_REGISTER_SI
                elif (rm == 5):
                    rmValue += CPU_REGISTER_DI
                elif (rm in (0, 2)):
                    rmValue += CPU_REGISTER_SI
                elif (rm in (1, 3)):
                    rmValue += CPU_REGISTER_DI
                if (regSize == misc.OP_SIZE_8BIT):
                    regValue = CPU_REGISTER_BYTE[reg]
                else:
                    regValue = self.getRegValueWithFlags(modRMflags, reg)
                if (mod == 0 and rm == 6):
                    rmValue += self.cpu.getCurrentOpcodeAdd(numBytes=2, signedValue=True)
            elif (mod in (1, 2)):
                if (rm == 6):
                    rmValue += CPU_REGISTER_BP
                if (mod == 1):
                    rmValue += self.cpu.getCurrentOpcodeAdd(numBytes=1, signedValue=True)
                elif (mod == 2):
                    rmValue += self.cpu.getCurrentOpcodeAdd(numBytes=2, signedValue=True)
            elif (mod == 3): # reg: source ; rm: dest
                if (regSize == misc.OP_SIZE_8BIT):
                    regValue  = CPU_REGISTER_BYTE[reg] # source
                    rmValue   = CPU_REGISTER_BYTE[rm] # dest
                elif (regSize == misc.OP_SIZE_16BIT):
                    regValue  = self.getRegValueWithFlags(modRMflags, reg) # source
                    rmValue   = CPU_REGISTER_WORD[rm] # dest
                else:
                    self.main.exitError("modRMLoad: mod==3; regSize not in (misc.OP_SIZE_8BIT, misc.OP_SIZE_16BIT)")
        elif (self.segments.getAddrSegSize(CPU_SEGMENT_CS) == misc.OP_SIZE_32BIT):
            self.main.exitError("modRMLoad: 32bits NOT SUPPORTED YET.")
        else:
            self.main.exitError("modRMLoad: AddrSegSize(CS) not in (misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT)")
        return mod, (rmValue, rmValueSegId), regValue
    def setFullFlags(self, long reg0, long reg1, int regSize, int method, int signedAsUnsigned=False): # regSize in bits
        cdef long regSum = 0
        cdef long regSumMasked = 0
        cdef int unsignedOverflow = 0
        cdef int signedOverflow = 0
        cdef long bitMask = self.main.misc.getBitMask(regSize)
        #cdef long bitMaskForAF = self.main.misc.getBitMask(regSize, half=False, minus=0x10)
        cdef long halfBitMask = self.main.misc.getBitMask(regSize, half=True)
        
        if (method == misc.SET_FLAGS_ADD):
            regSum = reg0+reg1
            regSumMasked = regSum&bitMask
            unsignedOverflow = (regSum < 0 or reg0 < 0 or reg1 < 0) or (reg0&bitMask <= bitMask and regSum > bitMask)# or (reg0&bitMask > bitMask and regSum <= bitMask)
            #signedOverflow = ( (((reg0&bitMask < halfBitMask) == (reg1&bitMask > halfBitMask)) == (regSumMasked < halfBitMask)) or (((reg0&bitMask > halfBitMask) == (reg1&bitMask < halfBitMask)) == (regSumMasked > halfBitMask)) )
            signedOverflow = (not (reg0>bitMask or regSumMasked==0)) and (( (reg0&bitMask <= halfBitMask) and (regSumMasked > halfBitMask) ) or ( (reg0&bitMask > halfBitMask) and (regSumMasked <= halfBitMask) )) or \
                             0 #(regSum>bitMask+halfBitMask) #( (reg1&bitMask <= halfBitMask) and (regSumMasked > halfBitMask) ) or ( (reg1&bitMask > halfBitMask) and (regSumMasked <= halfBitMask) )
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_ZF, (regSumMasked)==0)
            afFlag = False
            #if (reg0&0xf<=0xf and ((reg0&0xf)+(reg1&0xf))>0xf):
            #if ((reg0&bitMaskForAF != regSum&bitMaskForAF) or (reg1&bitMaskForAF != regSum&bitMaskForAF)):
            if ( (((reg0&0xf)+(reg1&0xf))>regSum&0xf or reg0>bitMask or reg1>bitMask)):# or regSum>bitMask) ):
                afFlag = True
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_AF, afFlag)
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_CF, unsignedOverflow)
            if (signedAsUnsigned):
                unsignedOverflow = (regSumMasked<=halfBitMask)
                self.setFlag(CPU_REGISTER_EFLAGS, FLAG_OF, unsignedOverflow)
            else:
                self.setFlag(CPU_REGISTER_EFLAGS, FLAG_OF, signedOverflow)
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_SF, (regSum&self.main.misc.getBitMask(regSize, half=True, minus=0))!=0)
            pass
        elif (method == misc.SET_FLAGS_SUB):
            regSum = reg0-reg1
            regSumMasked = regSum&bitMask
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_ZF, (regSumMasked)==0)
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_CF, (regSum < 0))
            pass
        elif (method == misc.SET_FLAGS_MUL):
            pass
        elif (method == misc.SET_FLAGS_DIV):
            pass
        else:
            self.main.exitError("setFullFlags: method not (add, sub, mul or div). (method: {0:d})", method)



