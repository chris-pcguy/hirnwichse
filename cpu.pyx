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

CPU_EXCEPTION_DE = 0 # divide-by-zero error
CPU_EXCEPTION_DB = 1 # debug
CPU_EXCEPTION_BP = 3 # breakpoint
CPU_EXCEPTION_OF = 4 # overflow
CPU_EXCEPTION_BR = 5 # bound range exceeded
CPU_EXCEPTION_UD = 6 # invalid opcode
CPU_EXCEPTION_NM = 7 # device not available
CPU_EXCEPTION_DF = 8 # double fault
CPU_EXCEPTION_TS = 10 # invalid TSS
CPU_EXCEPTION_NP = 11 # segment not present
CPU_EXCEPTION_SS = 12 # stack-segment fault
CPU_EXCEPTION_GP = 13 # general-protection fault
CPU_EXCEPTION_PF = 14 # page fault
CPU_EXCEPTION_MF = 16 # x87 floating-point exception
CPU_EXCEPTION_AC = 17 # alignment check
CPU_EXCEPTION_MC = 18 # machine check
CPU_EXCEPTION_XM = 19 # simd floating-point exception
CPU_EXCEPTION_SX = 30 # security exception


CPU_REGISTER_QWORD=()

CPU_REGISTER_DWORD=(CPU_REGISTER_EAX,CPU_REGISTER_ECX,CPU_REGISTER_EDX,CPU_REGISTER_EBX,CPU_REGISTER_ESP,
                    CPU_REGISTER_EBP,CPU_REGISTER_ESI,CPU_REGISTER_EDI,CPU_REGISTER_EIP,CPU_REGISTER_EFLAGS,
                    CPU_REGISTER_CR0,CPU_REGISTER_CR2,CPU_REGISTER_CR3,CPU_REGISTER_CR4)

CPU_REGISTER_WORD=(CPU_REGISTER_AX,CPU_REGISTER_CX,CPU_REGISTER_DX,CPU_REGISTER_BX,CPU_REGISTER_SP,
                    CPU_REGISTER_BP,CPU_REGISTER_SI,CPU_REGISTER_DI,CPU_REGISTER_IP,CPU_REGISTER_FLAGS,
                    CPU_SEGMENT_CS,CPU_SEGMENT_DS,CPU_SEGMENT_ES,CPU_SEGMENT_FS,CPU_SEGMENT_GS,CPU_SEGMENT_SS)

CPU_REGISTER_HBYTE=(CPU_REGISTER_AH,CPU_REGISTER_CH,CPU_REGISTER_DH,CPU_REGISTER_BH)
CPU_REGISTER_LBYTE=(CPU_REGISTER_AL,CPU_REGISTER_CL,CPU_REGISTER_DL,CPU_REGISTER_BL)

CPU_REGISTER_BYTE=(CPU_REGISTER_AL,CPU_REGISTER_CL,CPU_REGISTER_DL,CPU_REGISTER_BL,CPU_REGISTER_AH,CPU_REGISTER_CH,CPU_REGISTER_DH,CPU_REGISTER_BH)


CPU_SEGMENTS=(CPU_SEGMENT_CS,CPU_SEGMENT_DS,CPU_SEGMENT_ES,CPU_SEGMENT_FS,CPU_SEGMENT_GS,CPU_SEGMENT_SS)


OPCODE_PREFIX_CS=0x2e
OPCODE_PREFIX_SS=0x36
OPCODE_PREFIX_DS=0x3e
OPCODE_PREFIX_ES=0x26
OPCODE_PREFIX_FS=0x64
OPCODE_PREFIX_GS=0x65
OPCODE_PREFIX_SEGMENTS=(OPCODE_PREFIX_CS, OPCODE_PREFIX_SS, OPCODE_PREFIX_DS, OPCODE_PREFIX_ES, OPCODE_PREFIX_FS, OPCODE_PREFIX_GS)
OPCODE_PREFIX_OP=0x66
OPCODE_PREFIX_ADDR=0x67
OPCODE_PREFIX_BRANCH_NOT_TAKEN=0x2e
OPCODE_PREFIX_BRANCH_TAKEN=0x3e
OPCODE_PREFIX_BRANCHES=(OPCODE_PREFIX_BRANCH_NOT_TAKEN,OPCODE_PREFIX_BRANCH_TAKEN)
OPCODE_PREFIX_LOCK=0xf0
OPCODE_PREFIX_REPNE=0xf2
OPCODE_PREFIX_REPE=0xf3
OPCODE_PREFIX_REPS=(OPCODE_PREFIX_REPNE,OPCODE_PREFIX_REPE)


OPCODE_PREFIXES=(OPCODE_PREFIX_LOCK, OPCODE_PREFIX_OP, OPCODE_PREFIX_ADDR, OPCODE_PREFIX_CS,
                 OPCODE_PREFIX_SS, OPCODE_PREFIX_DS, OPCODE_PREFIX_ES, OPCODE_PREFIX_FS,
                 OPCODE_PREFIX_GS, OPCODE_PREFIX_BRANCH_NOT_TAKEN, OPCODE_PREFIX_BRANCH_TAKEN,
                 OPCODE_PREFIX_REPNE, OPCODE_PREFIX_REPE)

class Gdt:
    def __init__(self):
        pass
    def loadGdt(self, gdtBaseAddr):
        pass

class Segments:
    def __init__(self, main, cpu, registers):
        self.main, self.cpu, self.registers = main, cpu, registers
        self.gdt = Gdt()
    def getBase(self, segId): # segId == segments regId
        if (self.registers.getFlags(CPU_REGISTER_CR0, CR0_FLAG_PE)): # protected mode enabled
            self.main.exitError("GDT: protected mode not supported.")
            return
        #else: # real mode
        return self.registers.regRead(segId)<<4
    def getSegSize(self, segId): # segId == segments regId
        if (self.registers.getFlags(CPU_REGISTER_CR0, CR0_FLAG_PE)): # protected mode enabled
            self.main.exitError("GDT: protected mode not supported.")
            return
        #else: # real mode
        return 16
    def getOpSegSize(self, segId): # segId == segments regId
        segSize = self.getSegSize(segId)
        if (segSize == 16):
            return ((self.registers.operandSizePrefix and 32) or 16)
        elif (segSize == 32):
            return ((self.registers.operandSizePrefix and 16) or 32)
        else:
            self.main.exitError("getOpSegSize: segSize is not valid. ({0:d})", segSize)
    def getAddrSegSize(self, segId): # segId == segments regId
        segSize = self.getSegSize(segId)
        if (segSize == 16):
            return ((self.registers.addressSizePrefix and 32) or 16)
        elif (segSize == 32):
            return ((self.registers.addressSizePrefix and 16) or 32)
        else:
            self.main.exitError("getAddrSegSize: segSize is not valid. ({0:d})", segSize)

class Registers:
    def __init__(self, main, cpu):
        self.main, self.cpu = main, cpu
        self.regs = bytearray(CPU_REGISTER_LENGTH)
        self.segments = Segments(self.main, self.cpu, self)
        self.reset()
    def reset(self):
        self.regWrite(CPU_SEGMENT_CS, 0xffff)
        self.regWrite(CPU_REGISTER_IP, 0x0)
        
        self.resetPrefixes()
    def resetPrefixes(self):
        self.lockPrefix = False
        self.branchPrefix = False
        self.repPrefix = False
        self.segmentOverridePrefix = False
        self.operandSizePrefix = False
        self.addressSizePrefix = False
    def regRead(self, int regId, int signedValue=False):
        cdef int aregId = regId//4
        if (regId in CPU_REGISTER_QWORD):
            return struct.unpack(((signedValue and ">q") or ">Q"), self.regs[aregId:aregId+8])[0]
        elif (regId in CPU_REGISTER_DWORD):
            return struct.unpack(((signedValue and ">i") or ">I"), self.regs[aregId:aregId+4])[0]
        elif (regId in CPU_REGISTER_WORD):
            return struct.unpack(((signedValue and ">h") or ">H"), self.regs[aregId+2:aregId+4])[0]
        elif (regId in CPU_REGISTER_HBYTE):
            return struct.unpack(((signedValue and ">b") or ">B"), self.regs[aregId+2])[0]
        elif (regId in CPU_REGISTER_LBYTE):
            return struct.unpack(((signedValue and ">b") or ">B"), self.regs[aregId+3])[0]
        raise NameError("regId is unknown! ({0})".format(regId))
    def regWrite(self, int regId, int value):
        cdef int aregId = regId//4
        if (regId in CPU_REGISTER_QWORD):
            self.regs[aregId:aregId+8] = struct.pack(">Q", value&0xffffffffffffffff)
        elif (regId in CPU_REGISTER_DWORD):
            self.regs[aregId:aregId+4] = struct.pack(">I", value&0xffffffff)
        elif (regId in CPU_REGISTER_WORD):
            self.regs[aregId+2:aregId+4] = struct.pack(">H", value&0xffff)
        elif (regId in CPU_REGISTER_HBYTE):
            self.regs[aregId+2] = value&0xff
        elif (regId in CPU_REGISTER_LBYTE):
            self.regs[aregId+3] = value&0xff
        else:
            raise NameError("regId is unknown! ({0})".format(regId))
    def regReadEip(self, int signedValue=False):
        cdef int regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == 32):
            regSizeId = CPU_REGISTER_EIP
        self.registers.regRead(regSizeId, signedValue)
    def regWriteEip(self, int value):
        cdef int regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == 32):
            regSizeId = CPU_REGISTER_EIP
        self.registers.regWrite(regSizeId, value)
    def regAdd(self, int regId, int value, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)+value)
    def regSub(self, int regId, int value, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)-value)
    def regXor(self, int regId, int value, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)^value)
    def regAnd(self, int regId, int value, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)&value)
    def regOr (self, int regId, int value, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)|value)
    def regNeg(self, int regId, int signedValue=False):
        self.regWrite(regId, -self.regRead(regId, signedValue))
    def regNot(self, int regId, int signedValue=False):
        self.regWrite(regId, ~self.regRead(regId, signedValue))
    def regDeleteBitsByValue(self, int regId, int value, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)&(~value))
    def regDeleteBit(self, int regId, int bit, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)&(~(1<<bit)))
    def regSetBit(self, int regId, int bit, int signedValue=False):
        self.regWrite(regId, self.regRead(regId, signedValue)|(1<<bit))
    def regInc(self, int regId, int signedValue=False):
        self.regAdd(regId, 1, signedValue)
    def regDec(self, int regId, int signedValue=False):
        self.regSub(regId, 1, signedValue)
    def getFlags(self, int regId, int flags):
        return self.regRead(regId)&flags
    def clearFlags(self, int flags):
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
    def setFlags(self, int flags):
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
    def modRMLoad(self, int regSize): # imm == unsigned ; disp == signed
        cdef int mod, rmValue = self.modRMOperands(regSize)
        
    def modRMSave(self, int regSize): # imm == unsigned ; disp == signed
        cdef int mod, rmValue = self.modRMOperands(regSize)
        
    def modRMOperands(self, int regSize): # imm == unsigned ; disp == signed
        cdef int modRMByte = self.cpu.getCurrentOpcodeAdd()
        cdef int rm  = modRMByte&0x7
        cdef int reg = (modRMByte>>3)&0x7
        cdef int mod = (modRMByte>>6)&0x3
        
        cdef int rmValue  = 0
        if (self.segments.getAddrSegSize(CPU_SEGMENT_CS) == 16):
            if (mod in (0, 1, 2)):
                if (rm in (0, 1, 7)):
                    rmValue += CPU_REGISTER_BX
                elif (rm in (2, 3)):
                    rmValue += CPU_REGISTER_BP
                elif (rm == 4):
                    rmValue += CPU_REGISTER_SI
                elif (rm == 5):
                    rmValue += CPU_REGISTER_DI
                elif (rm in (0, 2)):
                    rmValue += CPU_REGISTER_SI
                elif (rm in (1, 3)):
                    rmValue += CPU_REGISTER_DI
            if (mod == 0):
                if (rm == 6):
                    rmValue += self.cpu.getCurrentOpcodeAdd(numBytes=2, signedValue=True)
                
            elif (mod in (1, 2)):
                if (rm == 6):
                    rmValue += CPU_REGISTER_BP
                if (mod == 1):
                    rmValue += self.cpu.getCurrentOpcodeAdd(numBytes=1, signedValue=True)
                elif (mod == 2):
                    rmValue += self.cpu.getCurrentOpcodeAdd(numBytes=2, signedValue=True)
            elif (mod == 3):
                if (regSize == 8):
                    rmValue  = CPU_REGISTER_BYTE[reg]
                elif (regSize == 16):
                    rmValue  = CPU_REGISTER_WORD[reg]
                else:
                    self.main.exitError("modRMLoad: mod==3; regSize not in (8, 16)")
        elif (self.segments.getAddrSegSize(CPU_SEGMENT_CS) == 32):
            self.main.exitError("modRMLoad: 32bits NOT SUPPORTED YET.")
        else:
            self.main.exitError("modRMLoad: AddrSegSize(CS) not in (16, 32)")
        return mod, rmValue


class Cpu:
    def __init__(self, main):
        self.main = main
        self.registers = Registers(self.main, self)
        self.opcodes = Opcodes(self.main, self)
        self.reset()
    def reset(self):
        self.savedCs  = 0
        self.savedEip = 0
    def getCurrentOpcodeAddr(self):
        cdef int opcodeAddr = self.registers.segments.getBase(CPU_SEGMENT_CS)
        cdef int eipSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef int eipSizeId = CPU_REGISTER_IP
        if (eipSize not in (16, 32)):
            self.main.exitError("eipSize is INVALID. ({0:d})", eipSize)
        elif (eipSize == 32):
            eipSizeId = CPU_REGISTER_EIP
        
        opcodeAddr += self.registers.regRead(eipSizeId)
        return opcodeAddr
    def getCurrentOpcode(self, int numBytes=1):
        cdef int eip = self.getCurrentOpcodeAddr()
        return self.main.mm.mmRead(eip, numBytes)
    def getCurrentOpcodeAdd(self, int numBytes=1, int signedValue=False):
        opcodeData = self.getCurrentOpcode(numBytes)
        cdef int regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == 32):
            regSizeId = CPU_REGISTER_EIP
        self.registers.regAdd(regSizeId, numBytes)
        return self.main.misc.binToNum(opcodeData, numBytes, signedValue)
    def getCurrentOpcodeAddEip(self, int signedValue=False):
        cdef int regSize   = 2
        cdef int regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == 32):
            regSize   = 4
            regSizeId = CPU_REGISTER_EIP
        opcodeData = self.getCurrentOpcode(regSize)
        self.registers.regAdd(regSizeId, regSize)
        return self.main.misc.binToNum(opcodeData, regSize, signedValue)
    def exception(self, int exceptionId):
        self.main.exitError("CPU Exception catched. (exceptionId: {0:d})", exceptionId)
    def parsePrefixes(self, int opcode):
        while (opcode in OPCODE_PREFIXES):
            if (opcode == OPCODE_PREFIX_LOCK):
                self.registers.lockPrefix = True
            elif (opcode in OPCODE_PREFIX_BRANCHES):
                self.registers.branchPrefix = opcode
            elif (opcode in OPCODE_PREFIX_REPS):
                self.registers.repPrefix = opcode
            elif (opcode in OPCODE_PREFIX_SEGMENTS):
                self.registers.segmentOverridePrefix = opcode
            elif (opcode == OPCODE_PREFIX_OP):
                self.registers.operandSizePrefix = True
            elif (opcode == OPCODE_PREFIX_ADDR):
                self.registers.addressSizePrefix = True
            
            opcode = self.getCurrentOpcodeAdd()
        
        return opcode
    def doInfiniteCycles(self):
        while True:
            self.doCycle()
    def doCycle(self):
        self.savedCs  = self.registers.regRead(CPU_SEGMENT_CS)
        self.savedEip = self.registers.regRead(CPU_REGISTER_EIP)
        self.registers.resetPrefixes()
        self.opcode = self.getCurrentOpcodeAdd()
        if (self.opcode in OPCODE_PREFIXES):
            self.opcode = self.parsePrefixes(self.opcode)
        self.main.debug("Current Opcode: {0:02x}", self.opcode)
        
        if (self.opcode in self.opcodes.opcodeList):
            self.opcodes.opcodeList[self.opcode]()
        else:
            self.main.debug("Opcode not found. (opcode: {0:02x})", self.opcode)
            self.exception(CPU_EXCEPTION_UD)
    def run(self):
        self.doInfiniteCycles()


class Opcodes:
    def __init__(self, main, cpu):
        self.main = main
        self.cpu = cpu
        self.registers = self.cpu.registers
        self.opcodeList = {0xb0: self.movImm8ToR8, 0xb1: self.movImm8ToR8, 0xb2: self.movImm8ToR8,
                           0xb3: self.movImm8ToR8, 0xb4: self.movImm8ToR8, 0xb5: self.movImm8ToR8,
                           0xb6: self.movImm8ToR8, 0xb7: self.movImm8ToR8, 0xb8: self.movImm16_32ToR16_32,
                           0xb9: self.movImm16_32ToR16_32, 0xba: self.movImm16_32ToR16_32, 0xbb: self.movImm16_32ToR16_32,
                           0xbc: self.movImm16_32ToR16_32, 0xbd: self.movImm16_32ToR16_32, 0xbe: self.movImm16_32ToR16_32,
                           0xbf: self.movImm16_32ToR16_32, 0xe8: self.jumpShortRelativeByte, 0xe9: self.jumpShortRelativeWordDWord,
                           0xea: self.jumpFarAbsolutePtr}
    def jumpFarAbsolutePtr(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int eip = self.cpu.getCurrentOpcodeAddEip()
        cdef int cs = self.cpu.getCurrentOpcodeAdd(2)
        self.registers.regWrite(CPU_SEGMENT_CS, cs)
        self.registers.regWrite(CPU_REGISTER_EIP, eip)
    def jumpShortRelativeByte(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int offset = self.cpu.getCurrentOpcodeAdd()
        self.jumpShortRelative(offset)
    def jumpShortRelativeWordDWord(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int offset = self.cpu.getCurrentOpcodeAddEip()
        self.jumpShortRelative(offset)
    def jumpShortRelative(self, int offset):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int newEip = self.registers.regRead(CPU_REGISTER_EIP)
        newEip += offset
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == 16):
            newEip &= 0xffff
        self.registers.regWrite(CPU_REGISTER_EIP, newEip)
    def movImm8ToR8(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int r8reg = self.cpu.opcode&0x7
        self.registers.regWrite(CPU_REGISTER_BYTE[r8reg], self.cpu.getCurrentOpcodeAdd())
    def movImm16_32ToR16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int r16_32reg = self.cpu.opcode&0x7
        cdef int operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        if (operSize == 16):
            self.registers.regWrite(CPU_REGISTER_WORD[r16_32reg], self.cpu.getCurrentOpcodeAddEip())
        elif (operSize == 32):
            self.registers.regWrite(CPU_REGISTER_DWORD[r16_32reg], self.cpu.getCurrentOpcodeAddEip())
        else:
            self.main.exitError("operSize is NOT OK ({0:d})", operSize)
        
        


