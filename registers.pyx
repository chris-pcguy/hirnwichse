import misc

#import numpy
#cimport numpy

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


##cdef class RegImm:
##    cpdef isRegImm
##    cpdef value
##    def __init__(self, long value=0):
##        self.isRegImm = True
##        self.value = value
##    def getValue(self):
##        return self.value
##    def setValue(self, value):
##        self.value = value

cdef class Gdt:
    def __init__(self):
        pass
    cpdef loadGdt(self, long gdtBaseAddr):
        pass

cdef class Segments:
    #cdef object main, cpu, registers, gdt
    def __init__(self, object main, object cpu, object registers):
        self.main, self.cpu, self.registers = main, cpu, registers
        self.gdt = Gdt()
    cpdef getBase(self, int segId): # segId == segments regId
        if (self.registers.getFlag(CPU_REGISTER_CR0, CR0_FLAG_PE)): # protected mode enabled
            self.main.exitError("GDT: protected mode not supported.")
            #return
        #else: # real mode
        return self.registers.regRead(segId)<<4
    cpdef getRealAddr(self, int segId, long offsetAddr):
        return (self.getBase(segId)+offsetAddr)
    cpdef getSegSize(self, int segId): # segId == segments regId
        if (self.registers.getFlag(CPU_REGISTER_CR0, CR0_FLAG_PE)): # protected mode enabled
            self.main.exitError("GDT: protected mode not supported.")
            #return
        #else: # real mode
        return misc.OP_SIZE_16BIT
    cpdef getOpSegSize(self, int segId): # segId == segments regId
        cpdef segSize = self.getSegSize(segId)
        if (segSize == misc.OP_SIZE_16BIT):
            return ((self.registers.operandSizePrefix and misc.OP_SIZE_32BIT) or misc.OP_SIZE_16BIT)
        elif (segSize == misc.OP_SIZE_32BIT):
            return ((self.registers.operandSizePrefix and misc.OP_SIZE_16BIT) or misc.OP_SIZE_32BIT)
        else:
            self.main.exitError("getOpSegSize: segSize is not valid. ({0:d})", segSize)
    cpdef getAddrSegSize(self, int segId): # segId == segments regId
        cpdef segSize = self.getSegSize(segId)
        if (segSize == misc.OP_SIZE_16BIT):
            return ((self.registers.addressSizePrefix and misc.OP_SIZE_32BIT) or misc.OP_SIZE_16BIT)
        elif (segSize == misc.OP_SIZE_32BIT):
            return ((self.registers.addressSizePrefix and misc.OP_SIZE_16BIT) or misc.OP_SIZE_32BIT)
        else:
            self.main.exitError("getAddrSegSize: segSize is not valid. ({0:d})", segSize)

cdef class Registers:
    #cdef object main
    #cdef object cpu
    #cdef object segments
    #cdef object main, cpu, segments
    ##cdef numpy.ndarray[numpy.uint8_t, ndim=1, mode="c"] regs
    #cdef numpy.ndarray regs
    #cpdef lockPrefix, branchPrefix, repPrefix, segmentOverridePrefix, operandSizePrefix, addressSizePrefix
    #pdef bytearray regs
    def __init__(self, object main, object cpu):
        self.main, self.cpu = main, cpu
        self.regs = bytearray(CPU_REGISTER_LENGTH)
        ##self.regs = numpy.zeros(CPU_REGISTER_LENGTH, dtype=numpy.bytes_, order='C')
        ##self.regs = numpy.zeros()##(numpy.uint8_t, ndim=1, mode="c")
        self.segments = Segments(self.main, self.cpu, self)
        ###self.regSetFlag = self.regOr
        self.reset()
    cpdef reset(self):
        self.regWrite(CPU_REGISTER_FLAGS, 0x2)
        self.regWrite(CPU_SEGMENT_CS, 0xf000)
        self.regWrite(CPU_REGISTER_IP, 0xfff0)
        self.resetPrefixes()
    cpdef resetPrefixes(self):
        self.lockPrefix = False
        self.branchPrefix = False
        self.repPrefix = False
        self.segmentOverridePrefix = False
        self.operandSizePrefix = False
        self.addressSizePrefix = False
    cpdef regGetSize(self, regId): # return size in bits
        if (regId in CPU_REGISTER_QWORD):
            return misc.OP_SIZE_64BIT
        elif (regId in CPU_REGISTER_DWORD):
            return misc.OP_SIZE_32BIT
        elif (regId in CPU_REGISTER_WORD):
            return misc.OP_SIZE_16BIT
        elif (regId in CPU_REGISTER_BYTE):
            return misc.OP_SIZE_8BIT
        raise NameError("regId is unknown! ({0})".format(regId))
    cpdef regRead(self, long regId, int signed=False, int regIdIsVal=False): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' here, IT WON'T WORK!!!!
        cpdef long regValue = 0
        cpdef long aregId
        ##if (isinstance(regId, RegImm)):
        ##    regValue = regId.getValue()
        ##    return regValue
        if (regIdIsVal):
            return regId
        aregId = (regId-(regId%5))*8
        if (regId in CPU_REGISTER_QWORD):
            regValue = regValue.from_bytes(bytes=self.regs[aregId:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_DWORD):
            regValue = regValue.from_bytes(bytes=self.regs[aregId+4:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_WORD):
            regValue = regValue.from_bytes(bytes=self.regs[aregId+6:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_HBYTE):
            regValue = regValue.from_bytes(bytes=bytes([self.regs[aregId+6]]), byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
            ##regValue = self.regs[aregId+6]
            ##if (signed and regValue & 0x80):
            ##    regValue -= 0x100
        elif (regId in CPU_REGISTER_LBYTE):
            regValue = regValue.from_bytes(bytes=bytes([self.regs[aregId+7]]), byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
            ##regValue = self.regs[aregId+7]
            ##if (signed and regValue & 0x80):
            ##    regValue -= 0x100
        else:
            raise NameError("regId is unknown! ({0})".format(regId))
        return regValue
    cpdef regWrite(self, long regId, long value, int signed=False): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' here, IT WON'T WORK!!!!
        cpdef long aregId
        ##if (isinstance(regId, RegImm)):
        ##    regId.setValue(value)
        ##    return
        aregId = (regId-(regId%5))*8
        if (regId in CPU_REGISTER_QWORD):
            self.regs[aregId:aregId+8] = value.to_bytes(length=8, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
            ##if (signed and value & 0x8000000000000000):
            ##    value -= 0x10000000000000000
            ##self.regs[aregId:aregId+8] = value
        elif (regId in CPU_REGISTER_DWORD):
            self.regs[aregId+4:aregId+8] = value.to_bytes(length=4, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
            ##if (signed and value & 0x80000000):
            ##    value -= 0x100000000
            ##self.regs[aregId+4:aregId+8] = value
        elif (regId in CPU_REGISTER_WORD):
            self.regs[aregId+6:aregId+8] = value.to_bytes(length=2, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
            ##if (signed and value & 0x8000):
            ##    value -= 0x10000
            ##self.regs[aregId+6:aregId+8] = value
        elif (regId in CPU_REGISTER_HBYTE):
            self.regs[aregId+6] = ord(value.to_bytes(length=1, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed))
            ##if (signed and value & 0x80):
            ##    value -= 0x100
            ##self.regs[aregId+6] = value
        elif (regId in CPU_REGISTER_LBYTE):
            self.regs[aregId+7] = ord(value.to_bytes(length=1, byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed))
            ##if (signed and value & 0x80):
            ##    value -= 0x100
            ##self.regs[aregId+7] = value
        else:
            raise NameError("regId is unknown! ({0})".format(regId))
    cpdef regReadEip(self, int signed=False):
        cpdef regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == misc.OP_SIZE_32BIT):
            regSizeId = CPU_REGISTER_EIP
        self.registers.regRead(regSizeId, signed)
    cpdef regWriteEip(self, long value):
        cpdef regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == misc.OP_SIZE_32BIT):
            regSizeId = CPU_REGISTER_EIP
        self.registers.regWrite(regSizeId, value)
    cpdef regAdd(self, int regId, long value, int signed=False):
        self.regWrite(regId, self.regRead(regId, signed)+value)
    cpdef regSub(self, int regId, long value, int signed=False):
        self.regWrite(regId, self.regRead(regId, signed)-value)
    cpdef regXor(self, int regId, long value, int signed=False):
        self.regWrite(regId, self.regRead(regId, signed)^value)
    cpdef regAnd(self, int regId, long value, int signed=False):
        self.regWrite(regId, self.regRead(regId, signed)&value)
    cpdef regOr (self, int regId, long value, int signed=False):
        self.regWrite(regId, self.regRead(regId, signed)|value)
    cpdef regSetFlag(self, int regId, long value, int signed=False):
        self.regOr(regId, value, signed)
    cpdef regNeg(self, int regId, int signed=False):
        self.regWrite(regId, -self.regRead(regId, signed))
    cpdef regNot(self, int regId, int signed=False):
        self.regWrite(regId, ~self.regRead(regId, signed))
    cpdef regDelFlag(self, int regId, long value, int signed=False): # by val, not bit
        self.regWrite(regId, self.regRead(regId, signed)&(~value))
    cpdef regDeleteBit(self, int regId, int bit, int signed=False):
        self.regWrite(regId, self.regRead(regId, signed)&(~(1<<bit)))
    cpdef regSetBit(self, int regId, int bit, int signed=False):
        self.regWrite(regId, self.regRead(regId, signed)|(1<<bit))
    cpdef regInc(self, int regId, int signed=False):
        self.regAdd(regId, 1, signed)
    cpdef regDec(self, int regId, int signed=False):
        self.regSub(regId, 1, signed)
    cpdef setEFLAG(self, long flags, int flagState):
        if (flagState):
            self.regSetFlag(CPU_REGISTER_EFLAGS, flags)
            return
        self.regDelFlag(CPU_REGISTER_EFLAGS, flags)
    cpdef getFlag(self, int regId, long flags):
        return (self.regRead(regId)&flags)!=0
    cpdef clearFlags(self, long flags):
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
    cpdef setFlags(self, long flags):
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
    cpdef modR_RMLoad(self, tuple rmOperands, int regSize, int signed=False): # imm == unsigned ; disp == signed; regSize in bits
        mod, rmValue, regValue = rmOperands
        cpdef returnInt = 0
        if (mod in (0, 1, 2)):
            returnInt = returnInt.from_bytes(bytes=self.main.mm.mmRead(rmValue[0], regSize, segId=rmValue[1]), byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=signed)
        else:
            returnInt = self.regRead(rmValue[0])
        returnInt &= self.main.misc.getBitMask(regSize)
        return returnInt
    cpdef modRM_RLoad(self, tuple rmOperands, int regSize): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        cpdef returnInt = self.regRead(regValue)&self.main.misc.getBitMask(regSize)
        return returnInt
    cpdef modR_RMSave(self, tuple rmOperands, int regSize, long value): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        value &= self.main.misc.getBitMask(regSize)
        self.regWrite(regValue, value)
    cpdef modRM_RSave(self, tuple rmOperands, int regSize, long value, int signed=False): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        value &= self.main.misc.getBitMask(regSize)
        if (mod in (0, 1, 2)):
            ###print("regSize: {0:d}, bytesvalue: {1:s}".format(regSize, repr(value.to_bytes(length=regSize, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=signed))))
            self.main.mm.mmWriteValue(rmValue[0], value, regSize, segId=rmValue[1], signed=signed)
        else:
            self.regWrite(rmValue[0], value)
    cpdef getRegValueWithFlags(self, long modRMflags, int reg):
        cpdef regValue = 0
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
    cpdef modRMOperands(self, int regSize, long modRMflags=0): # imm == unsigned ; disp == signed ; regSize in bits
        cpdef modRMByte = self.cpu.getCurrentOpcodeAdd()
        cpdef rm  = modRMByte&0x7
        cpdef reg = (modRMByte>>3)&0x7
        cpdef mod = (modRMByte>>6)&0x3

        cpdef rmValueSegId = CPU_SEGMENT_DS
        cpdef rmValue  = 0
        cpdef regValue = 0
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
                    rmValue += self.cpu.getCurrentOpcodeAdd(numBytes=2, signed=True)
            elif (mod in (1, 2)):
                if (rm == 6):
                    rmValue += CPU_REGISTER_BP
                if (mod == 1):
                    rmValue += self.cpu.getCurrentOpcodeAdd(numBytes=1, signed=True)
                elif (mod == 2):
                    rmValue += self.cpu.getCurrentOpcodeAdd(numBytes=2, signed=True)
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
        return (mod, (rmValue, rmValueSegId), regValue)
    cpdef setFullFlags(self, long reg0, long reg1, int regSize, int method, int immOp=False): # regSize in bits
        cpdef regSum = 0
        cpdef regSumMasked = 0
        cpdef unsignedOverflow = False
        cpdef signedOverflow = False
        cpdef isResZero = False
        cpdef afFlag = False
        cpdef bitMask = self.main.misc.getBitMask(regSize)
        #cpdef bitMaskForAF = self.main.misc.getBitMask(regSize, half=False, minus=0x10)
        cpdef halfBitMask = self.main.misc.getBitMask(regSize, half=True)
        
        if (method == misc.SET_FLAGS_ADD):
            regSum = reg0+reg1
            regSumMasked = regSum&bitMask
            isResZero = regSumMasked==0
            ###unsignedOverflow = (regSum < 0 or reg0 < 0 or reg1 < 0) or (reg0&bitMask <= bitMask and reg1&bitMask <= bitMask and regSum > bitMask)
            unsignedOverflow = (regSum > bitMask)
            signedOverflow = (not (reg0>bitMask or regSumMasked==0)) and (( (reg0&bitMask <= halfBitMask) and (regSumMasked > halfBitMask) ) or ( (reg0&bitMask > halfBitMask) and (regSumMasked <= halfBitMask) ))
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setEFLAG(FLAG_ZF, isResZero)
            if ( (((reg0&0xf)+(reg1&0xf))>regSum&0xf or reg0>bitMask or reg1>bitMask)):# or regSum>bitMask) ):
                afFlag = True
            self.setEFLAG(FLAG_AF, afFlag)
            self.setEFLAG(FLAG_CF, unsignedOverflow)
            if (immOp):
                ##unsignedOverflow = ((reg0>halfBitMask or reg1>halfBitMask) and regSumMasked<=halfBitMask)
                signedOverflow = ((reg0&bitMask)&halfBitMask and (reg0&bitMask)&halfBitMask and (not (reg0&bitMask)&halfBitMask))
                self.setEFLAG(FLAG_OF, ((not isResZero) and signedOverflow))
            else:
                unsignedOverflow = (regSum>bitMask)
                self.setEFLAG(FLAG_OF, ((not isResZero) and unsignedOverflow))
            self.setEFLAG(FLAG_SF, (regSum&self.main.misc.getBitMask(regSize, half=True, minus=0))!=0)
            pass
        elif (method == misc.SET_FLAGS_SUB):
            regSum = reg0-reg1
            regSumMasked = regSum&bitMask
            isResZero = regSumMasked==0
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setEFLAG(FLAG_ZF, isResZero)
            if ( (((reg0&0xf)-(reg1&0xf))<regSum&0xf or regSum<0)):# or regSum>bitMask) ):
                afFlag = True
            self.setEFLAG(FLAG_AF, afFlag)
            ##self.setEFLAG(FLAG_CF, (((reg0&bitMask>halfBitMask or reg1&bitMask>halfBitMask) and regSumMasked <= halfBitMask)) )
            self.setEFLAG(FLAG_CF, ( regSum<0 ) )
            #if (signedAsUnsigned):
            #    #unsignedOverflow = ((reg0>halfBitMask or reg1>halfBitMask) and regSumMasked<=halfBitMask)
            #    unsignedOverflow = (regSum<0)
            #    self.setEFLAG(FLAG_OF, (not isResZero and unsignedOverflow))
            #else:
            #    ###signedOverflow = (not (reg0>bitMask or regSumMasked==0)) and (( (reg0&bitMask <= halfBitMask) and (regSumMasked > halfBitMask) ) or ( (reg0&bitMask > halfBitMask) and (regSumMasked <= halfBitMask) ))
            #    ##signedOverflow = ((reg0>halfBitMask or reg1>halfBitMask) and regSumMasked<=halfBitMask)
            #    #signedOverflow = (regSum<0)
            #    signedOverflow = ((reg0>halfBitMask or reg1>halfBitMask) and regSumMasked<=halfBitMask)
            #    self.setEFLAG(FLAG_OF, (not isResZero and signedOverflow))
            
            signedOverflow = ((reg0>halfBitMask or reg1>halfBitMask) and regSumMasked<=halfBitMask) or ((reg0<=halfBitMask or reg1<=halfBitMask) and regSumMasked>halfBitMask) # or (regSum < 0)
            self.setEFLAG(FLAG_OF, (not isResZero and signedOverflow))
            
            
            self.setEFLAG(FLAG_SF, (regSum&self.main.misc.getBitMask(regSize, half=True, minus=0))!=0)
            pass
        elif (method == misc.SET_FLAGS_MUL):
            pass
        elif (method == misc.SET_FLAGS_DIV):
            pass
        else:
            self.main.exitError("setFullFlags: method not (add, sub, mul or div). (method: {0:d})", method)



