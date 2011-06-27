import struct

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



CPU_REGISTER_EAX = 0
CPU_REGISTER_AX = 1
CPU_REGISTER_AH = 2
CPU_REGISTER_AL = 3
CPU_REGISTER_ECX = 4
CPU_REGISTER_CX = 5
CPU_REGISTER_CH = 6
CPU_REGISTER_CL = 7
CPU_REGISTER_EDX = 8
CPU_REGISTER_DX = 9
CPU_REGISTER_DH = 10
CPU_REGISTER_DL = 11
CPU_REGISTER_EBX = 12
CPU_REGISTER_BX = 13
CPU_REGISTER_BH = 14
CPU_REGISTER_BL = 15
CPU_REGISTER_ESP = 16
CPU_REGISTER_SP = 18
CPU_REGISTER_EBP = 20
CPU_REGISTER_BP = 22
CPU_REGISTER_ESI = 24
CPU_REGISTER_SI = 26
CPU_REGISTER_EDI = 28
CPU_REGISTER_DI = 30
CPU_REGISTER_EIP = 32
CPU_REGISTER_IP = 34
CPU_REGISTER_EFLAGS = 36
CPU_REGISTER_FLAGS = 38
CPU_REGISTER_CR0 = 40
CPU_REGISTER_CR2 = 44
CPU_REGISTER_CR3 = 48
CPU_REGISTER_CR4 = 52

CPU_SEGMENT_CS = 56
CPU_SEGMENT_DS = 58
CPU_SEGMENT_ES = 60
CPU_SEGMENT_FS = 62
CPU_SEGMENT_GS = 64
CPU_SEGMENT_SS = 66
CPU_REGISTER_LENGTH = 68

CPU_PREFIX_BRANCH_TAKEN = 100
CPU_PREFIX_BRANCH_NOT_TAKEN = 101
CPU_PREFIX_LOCK = 102
CPU_PREFIX_REPE = 103
CPU_PREFIX_REPNE = 104

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



CPU_REGISTER_DWORD=(CPU_REGISTER_EAX,CPU_REGISTER_ECX,CPU_REGISTER_EDX,CPU_REGISTER_EBX,CPU_REGISTER_ESP,
                    CPU_REGISTER_EBP,CPU_REGISTER_ESI,CPU_REGISTER_EDI,CPU_REGISTER_EIP,CPU_REGISTER_EFLAGS,
                    CPU_REGISTER_CR0,CPU_REGISTER_CR2,CPU_REGISTER_CR3,CPU_REGISTER_CR4)

CPU_REGISTER_LWORD=(CPU_REGISTER_AX,CPU_REGISTER_CX,CPU_REGISTER_DX,CPU_REGISTER_BX,CPU_REGISTER_SP,
                    CPU_REGISTER_BP,CPU_REGISTER_SI,CPU_REGISTER_DI,CPU_REGISTER_IP,CPU_REGISTER_FLAGS,
                    CPU_SEGMENT_CS,CPU_SEGMENT_DS,CPU_SEGMENT_ES,CPU_SEGMENT_FS,CPU_SEGMENT_GS,CPU_SEGMENT_SS)

CPU_REGISTER_HBYTE=(CPU_REGISTER_AH,CPU_REGISTER_CH,CPU_REGISTER_DH,CPU_REGISTER_BH)
CPU_REGISTER_LBYTE=(CPU_REGISTER_AL,CPU_REGISTER_CL,CPU_REGISTER_DL,CPU_REGISTER_BL)


class Gdt:
    def __init__(self):
        pass
    def loadGdt(self, gdtBaseAddr):
        pass


class Registers:
    def __init__(self):
        self.regs = bytearray(CPU_REGISTER_LENGTH)
        self.reset()
    def reset(self):
        self.regWrite(CPU_SEGMENT_CS, 0xffff)
        self.regWrite(CPU_REGISTER_IP, 0x0)
        
        self.lockPrefix = False
        self.repPrefix = False
        self.segmentOverridePrefix = False
        self.operandSizePrefix = False
        self.addressSizePrefix = False
    def regRead(self, int regId, signedValue=False):
        cdef int aregId = regId//4
        if (regId in CPU_REGISTER_DWORD):
            return struct.unpack(((signedValue and ">i") or ">I"), self.regs[aregId:aregId+4])[0]
        elif (regId in CPU_REGISTER_LWORD):
            return struct.unpack(((signedValue and ">h") or ">H"), self.regs[aregId+2:aregId+4])[0]
        elif (regId in CPU_REGISTER_HBYTE):
            return struct.unpack(((signedValue and ">b") or ">B"), self.regs[aregId+2])[0]
        elif (regId in CPU_REGISTER_LBYTE):
            return struct.unpack(((signedValue and ">b") or ">B"), self.regs[aregId+3])[0]
        raise NameError("regId is unknown! ({0})".format(regId))
    def regWrite(self, int regId, value):
        cdef int aregId = regId//4
        if (regId in CPU_REGISTER_DWORD):
            self.regs[aregId:aregId+4] = struct.pack(">I", value&0xffffffff)
        elif (regId in CPU_REGISTER_LWORD):
            self.regs[aregId+2:aregId+4] = struct.pack(">H", value&0xffff)
        elif (regId in CPU_REGISTER_HBYTE):
            self.regs[aregId+2] = value&0xff
        elif (regId in CPU_REGISTER_LBYTE):
            self.regs[aregId+3] = value&0xff
        else:
            raise NameError("regId is unknown! ({0})".format(regId))
    def regAdd(self, regId, value, signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)+value)
    def regSub(self, regId, value, signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)-value)
    def regXor(self, regId, value, signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)^value)
    def regAnd(self, regId, value, signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)&value)
    def regOr (self, regId, value, signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)|value)
    def regNeg(self, regId, signedValue=False):
        self.regWrite(regId, -self.regRead(regId, signedValue))
    def regNot(self, regId, signedValue=False):
        self.regWrite(regId, ~self.regRead(regId, signedValue))
    def regDeleteBitsByValue(self, regId, value, signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)&(~value))
    def regDeleteBit(self, regId, bit, signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)&(~(1<<bit)))
    def regSetBit(self, regId, bit, signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)|(1<<bit))
    def regInc(self, regId, signedValue=False):
        self.regAdd(regId, 1, signedValue)
    def regDec(self, regId, signedValue=False):
        self.regSub(regId, 1, signedValue)
    def getFlags(self, regId, flags):
        return self.regRead(regId)&flags
    def clearFlags(self, flags):
        if (flags & FLAG_CF):
            self.regDeleteBitsByValue(CPU_REGISTER_EFLAGS, FLAG_CF)
        if (flags & FLAG_PF):
            self.regDeleteBitsByValue(CPU_REGISTER_EFLAGS, FLAG_PF)
        if (flags & FLAG_AF):
            self.regDeleteBitsByValue(CPU_REGISTER_EFLAGS, FLAG_AF)
        if (flags & FLAG_ZF):
            self.regDeleteBitsByValue(CPU_REGISTER_EFLAGS, FLAG_ZF)
        if (flags & FLAG_SF):
            self.regDeleteBitsByValue(CPU_REGISTER_EFLAGS, FLAG_SF)
        if (flags & FLAG_TF):
            self.regDeleteBitsByValue(CPU_REGISTER_EFLAGS, FLAG_TF)
        if (flags & FLAG_IF):
            self.regDeleteBitsByValue(CPU_REGISTER_EFLAGS, FLAG_IF)
        if (flags & FLAG_DF):
            self.regDeleteBitsByValue(CPU_REGISTER_EFLAGS, FLAG_DF)
        if (flags & FLAG_OF):
            self.regDeleteBitsByValue(CPU_REGISTER_EFLAGS, FLAG_OF)
    def setFlags(self, flags):
        if (flags & FLAG_CF):
            self.regOr(CPU_REGISTER_EFLAGS, FLAG_CF)
        if (flags & FLAG_PF):
            self.regOr(CPU_REGISTER_EFLAGS, FLAG_PF)
        if (flags & FLAG_AF):
            self.regOr(CPU_REGISTER_EFLAGS, FLAG_AF)
        if (flags & FLAG_ZF):
            self.regOr(CPU_REGISTER_EFLAGS, FLAG_ZF)
        if (flags & FLAG_SF):
            self.regOr(CPU_REGISTER_EFLAGS, FLAG_SF)
        if (flags & FLAG_TF):
            self.regOr(CPU_REGISTER_EFLAGS, FLAG_TF)
        if (flags & FLAG_IF):
            self.regOr(CPU_REGISTER_EFLAGS, FLAG_IF)
        if (flags & FLAG_DF):
            self.regOr(CPU_REGISTER_EFLAGS, FLAG_DF)
        if (flags & FLAG_OF):
            self.regOr(CPU_REGISTER_EFLAGS, FLAG_OF)


class Cpu:
    def __init__(self, main):
        self.main = main
        self.registers = Registers()
    def doInfiniteCycles(self):
        while True:
            self.doCycle()
    def doCycle(self):
        pass
    def run(self):
        pass
    




