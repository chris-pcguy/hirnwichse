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

CPU_REGISTER_SREG=(CPU_SEGMENT_ES,CPU_SEGMENT_CS,CPU_SEGMENT_SS,CPU_SEGMENT_DS,CPU_SEGMENT_FS,CPU_SEGMENT_GS,None,None)
CPU_REGISTER_CREG=(CPU_REGISTER_CR0, None, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4, None, None, None)
CPU_REGISTER_DREG=()


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

SET_FLAGS_ADD = 50
SET_FLAGS_SUB = 51
SET_FLAGS_MUL = 52
SET_FLAGS_DIV = 53

MODRM_FLAGS_SREG = 1
MODRM_FLAGS_CREG = 2
MODRM_FLAGS_DREG = 4


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
        return 16
    def getOpSegSize(self, int segId): # segId == segments regId
        cdef int segSize = self.getSegSize(segId)
        if (segSize == 16):
            return ((self.registers.operandSizePrefix and 32) or 16)
        elif (segSize == 32):
            return ((self.registers.operandSizePrefix and 16) or 32)
        else:
            self.main.exitError("getOpSegSize: segSize is not valid. ({0:d})", segSize)
    def getAddrSegSize(self, int segId): # segId == segments regId
        cdef int segSize = self.getSegSize(segId)
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
        self.regWrite(CPU_REGISTER_AX, 0xabcd)
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
            return struct.unpack(((signedValue and ">b") or ">B"), bytes([ self.regs[aregId+2] ]))[0]
        elif (regId in CPU_REGISTER_LBYTE):
            return struct.unpack(((signedValue and ">b") or ">B"), bytes([ self.regs[aregId+3] ]))[0]
        raise NameError("regId is unknown! ({0})".format(regId))
    def regWrite(self, int regId, long value):
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
    def regWriteEip(self, long value):
        cdef int regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == 32):
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
    def regDeleteBitsByValue(self, int regId, long value, int signedValue=False):
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
            return self.regOr(CPU_REGISTER_EFLAGS, flags)
        return self.regDeleteBitsByValue(CPU_REGISTER_EFLAGS, flags)
    def getFlag(self, int regId, long flags):
        return self.regRead(regId)&flags
    def clearFlags(self, long flags):
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
    def setFlags(self, long flags):
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
    def modRMLoad(self, rmOperands, int regSize): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        cdef int regSizeInBytes = regSize//8
        if (mod in (0, 1, 2)):
            return self.main.misc.binToNum(self.main.mm.mmRead(rmValue, regSizeInBytes), regSizeInBytes)
        else:
            return self.regRead(rmValue)
    def modRLoad(self, rmOperands, int regSize): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        cdef int regSizeInBytes = regSize//8
        return self.regRead(regValue)
    def modRMSave(self, rmOperands, int regSize, long value): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        if (mod in (0, 1, 2)):        
            self.main.mm.mmWrite(rmValue, regSize//8, value)
        else:
            self.regWrite(rmValue, value)
    def modRSave(self, rmOperands, int regSize, long value): # imm == unsigned ; disp == signed
        mod, rmValue, regValue = rmOperands
        self.regWrite(regValue, value)
    def modRMOperands(self, int regSize, int modRMflags=0): # imm == unsigned ; disp == signed
        cdef int modRMByte = self.cpu.getCurrentOpcodeAdd()
        cdef int rm  = modRMByte&0x7
        cdef int reg = (modRMByte>>3)&0x7
        cdef int mod = (modRMByte>>6)&0x3

        cdef int rmValue  = 0
        cdef int regValue = 0
        if (self.segments.getAddrSegSize(CPU_SEGMENT_CS) == 16):
            if (mod in (0, 1, 2)): # rm: source ; reg: dest
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
                if (regSize == 8):
                    regValue = CPU_REGISTER_BYTE[reg]
                else:
                    if (modRMflags & MODRM_FLAGS_SREG):
                        regValue = CPU_REGISTER_SREG[reg]
                    elif (modRMflags & MODRM_FLAGS_CREG):
                        regValue = CPU_REGISTER_CREG[reg]
                    elif (modRMflags & MODRM_FLAGS_DREG):
                        #regValue = CPU_REGISTER_DREG[reg]
                        self.main.exitError("debug register NOT IMPLEMENTED yet!")
                    else:
                        regValue = CPU_REGISTER_WORD[reg]
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
                if (regSize == 8):
                    regValue  = CPU_REGISTER_BYTE[reg] # source
                    rmValue   = CPU_REGISTER_BYTE[rm] # dest
                elif (regSize == 16):
                    regValue  = CPU_REGISTER_WORD[reg] # source
                    rmValue   = CPU_REGISTER_WORD[rm] # dest
                else:
                    self.main.exitError("modRMLoad: mod==3; regSize not in (8, 16)")
        elif (self.segments.getAddrSegSize(CPU_SEGMENT_CS) == 32):
            self.main.exitError("modRMLoad: 32bits NOT SUPPORTED YET.")
        else:
            self.main.exitError("modRMLoad: AddrSegSize(CS) not in (16, 32)")
        return mod, rmValue, regValue
    def setFullFlags(self, long reg0, long reg1, int regSize, int method):
        if (method == SET_FLAGS_ADD):
            regSum = reg0+reg1
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_ZF, regSum==0)
            
            afFlag = False
            if (reg0&0xf<=0xf and ((reg0&0xf)+(reg1&0xf))>0xf):
                afFlag = True
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_AF, afFlag)
            
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_CF, (regSum > self.main.misc.getBitMask(regSize)))
            pass
        elif (method == SET_FLAGS_SUB):
            regSum = reg0-reg1
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_ZF, regSum == 0)
            
            self.setFlag(CPU_REGISTER_EFLAGS, FLAG_CF, (regSum < 0))
            pass
        elif (method == SET_FLAGS_MUL):
            pass
        elif (method == SET_FLAGS_DIV):
            pass
        else:
            self.main.exitError("setFullFlags: method not (add, sub, mul or div). (method: {0:d})", method)

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
        cdef int eipSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef int eipSizeRegId = CPU_REGISTER_IP
        if (eipSize not in (16, 32)):
            self.main.exitError("eipSize is INVALID. ({0:d})", eipSize)
        elif (eipSize == 32):
            eipSizeRegId = CPU_REGISTER_EIP
        cdef long opcodeAddr = self.registers.segments.getRealAddr(CPU_SEGMENT_CS, self.registers.regRead(eipSizeRegId))
        ##opcodeAddr += self.registers.regRead(eipSizeId)
        return opcodeAddr
    def getCurrentOpcode(self, int numBytes=1, int signedValue=False):
        cdef long eip = self.getCurrentOpcodeAddr()
        return self.main.misc.binToNum(self.main.mm.mmRead(eip, numBytes, segId=0), numBytes, signedValue)
    def getCurrentOpcodeAdd(self, int numBytes=1, int signedValue=False):
        opcodeData = self.getCurrentOpcode(numBytes, signedValue)
        cdef int regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == 32):
            regSizeId = CPU_REGISTER_EIP
        self.registers.regAdd(regSizeId, numBytes)
        return opcodeData
    def getCurrentOpcodeAddEip(self, int signedValue=False):
        cdef int regSize   = 2
        cdef int regSizeId = CPU_REGISTER_IP
        if (self.registers.segments.getOpSegSize(CPU_SEGMENT_CS) == 32):
            regSize   = 4
            regSizeId = CPU_REGISTER_EIP
        opcodeData = self.getCurrentOpcode(regSize, signedValue)
        self.registers.regAdd(regSizeId, regSize)
        return opcodeData
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
        self.registers.resetPrefixes()
        self.savedCs  = self.registers.regRead(CPU_SEGMENT_CS)
        self.savedEip = self.registers.regRead(CPU_REGISTER_EIP)
        self.opcode = self.getCurrentOpcodeAdd()
        if (self.opcode in OPCODE_PREFIXES):
            self.opcode = self.parsePrefixes(self.opcode)
        self.main.debug("Current Opcode: {0:#04x}; It's Eip: {1:#07x}", self.opcode, self.savedEip)
        
        if (self.opcode in self.opcodes.opcodeList):
            self.opcodes.opcodeList[self.opcode]()
        else:
            self.main.debug("Opcode not found. (opcode: {0:#04x}; eip: {1:#07x})", self.opcode, self.savedEip)
            self.exception(CPU_EXCEPTION_UD)
    def run(self):
        self.doInfiniteCycles()


class Opcodes:
    def __init__(self, main, cpu):
        self.main = main
        self.cpu = cpu
        self.registers = self.cpu.registers
        self.opcodeList = {0x30: self.xorRM8_R8, 0x31: self.xorRM16_32_R16_32,
                           0x3c: self.cmpAlImm8, 0x3d: self.cmpAxEaxImm16_32,
                           0x72: self.jcShort, 0x73: self.jncShort, 0x74: self.jzShort, 0x75: self.jnzShort,
                           0x76: self.jbeShort, 0x77: self.jaShort, 0x78: self.jsShort, 0x79: self.jnsShort,
                           0x7a: self.jpShort, 0x7b: self.jnpShort, 0x7c: self.jlShort, 0x7d: self.jgeShort,
                           0x7e: self.jleShort, 0x7f: self.jgShort,
                           0x88: self.movRM8_R8, 0x89: self.movRM16_32_R16_32,
                           0x8a: self.movR8_RM8, 0x8b: self.movR16_32_RM16_32,
                           0x8c: self.movRM16_SREG, 0x8e: self.movSREG_RM16,
                           0xb0: self.movImm8ToR8, 0xb1: self.movImm8ToR8, 0xb2: self.movImm8ToR8,
                           0xb3: self.movImm8ToR8, 0xb4: self.movImm8ToR8, 0xb5: self.movImm8ToR8,
                           0xb6: self.movImm8ToR8, 0xb7: self.movImm8ToR8, 0xb8: self.movImm16_32ToR16_32,
                           0xb9: self.movImm16_32ToR16_32, 0xba: self.movImm16_32ToR16_32, 0xbb: self.movImm16_32ToR16_32,
                           0xbc: self.movImm16_32ToR16_32, 0xbd: self.movImm16_32ToR16_32, 0xbe: self.movImm16_32ToR16_32,
                           0xbf: self.movImm16_32ToR16_32, 0xe3: self.jcxzShort, 0xe4: self.inAlImm8, 0xe5: self.inAxEaxImm8, 0xe6: self.outImm8Al, 0xe7: self.outImm8AxEax, 0xe8: self.callNearRel16_32, 0xe9: self.jumpShortRelativeWordDWord,
                           0xea: self.jumpFarAbsolutePtr, 0xeb: self.jumpShortRelativeByte, 0xec: self.inAlDx, 0xed: self.inAxEaxDx, 0xee: self.outDxAl, 0xef: self.outDxAxEax}
    def jumpFarAbsolutePtr(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef long eip = self.cpu.getCurrentOpcodeAddEip()
        cdef long cs = self.cpu.getCurrentOpcodeAdd(2)
        self.registers.regWrite(CPU_SEGMENT_CS, cs)
        self.registers.regWrite(CPU_REGISTER_EIP, eip)
    def jumpShortRelativeByte(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.jumpShort(1)
    def jumpShortRelativeWordDWord(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int offsetSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.jumpShort(offsetSize//8)
    def cmpAlImm8(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef long reg0 = self.registers.regRead(CPU_REGISTER_AL)
        cdef long imm8 = self.cpu.getCurrentOpcodeAdd()
        #cdef long cmpSum = reg0-imm8
        self.registers.setFullFlags(reg0, imm8, 8, SET_FLAGS_SUB)
    def cmpAxEaxImm16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef int axReg = CPU_REGISTER_AX
        if (operSize == 32):
            axReg = CPU_REGISTER_EAX
        cdef long reg0 = self.registers.regRead(axReg)
        cdef long imm16_32 = self.cpu.getCurrentOpcodeAdd(operSize)
        #cdef long cmpSum = reg0-imm16_32
        self.registers.setFullFlags(reg0, imm16_32, operSize, SET_FLAGS_SUB)
    def movImm8ToR8(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int r8reg = self.cpu.opcode&0x7
        self.registers.regWrite(CPU_REGISTER_BYTE[r8reg], self.cpu.getCurrentOpcodeAdd())
    def movImm16_32ToR16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef long r16_32reg = self.cpu.opcode&0x7
        cdef int operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        if (operSize == 16):
            self.registers.regWrite(CPU_REGISTER_WORD[r16_32reg], self.cpu.getCurrentOpcodeAddEip())
        elif (operSize == 32):
            self.registers.regWrite(CPU_REGISTER_DWORD[r16_32reg], self.cpu.getCurrentOpcodeAddEip())
        else:
            self.main.exitError("operSize is NOT OK ({0:d})", operSize)
    def movRM8_R8(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        rmOperands = self.registers.modRMOperands(8)
        self.registers.modRMSave(rmOperands, 8, self.registers.modRLoad(rmOperands, 8))
    def movRM16_32_R16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        self.registers.modRMSave(rmOperands, operSize, self.registers.modRLoad(rmOperands, operSize))
    def movR8_RM8(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        rmOperands = self.registers.modRMOperands(8)
        self.registers.modRSave(rmOperands, 8, self.registers.modRMLoad(rmOperands, 8))
    def movR16_32_RM16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        self.registers.modRSave(rmOperands, operSize, self.registers.modRMLoad(rmOperands, operSize))
    def movRM16_SREG(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        rmOperands = self.registers.modRMOperands(16, MODRM_FLAGS_SREG)
        self.registers.modRMSave(rmOperands, 16, self.registers.modRLoad(rmOperands, 16))
    def movSREG_RM16(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        rmOperands = self.registers.modRMOperands(16, MODRM_FLAGS_SREG)
        self.registers.modRSave(rmOperands, 16, self.registers.modRMLoad(rmOperands, 16))
    def xorRM8_R8(self):
        rmOperands = self.registers.modRMOperands(8)
        self.registers.modRMSave(rmOperands, 8, self.registers.modRMLoad(rmOperands, 8)^self.registers.modRLoad(rmOperands, 8))
    def xorRM16_32_R16_32(self):
        cdef int operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        self.registers.modRMSave(rmOperands, operSize, self.registers.modRMLoad(rmOperands, operSize)^self.registers.modRLoad(rmOperands, operSize))
    def inAlImm8(self):
        self.registers.regWrite(CPU_REGISTER_AL, self.main.platform.inPort(self.cpu.getCurrentOpcodeAdd(), 8))
    def inAxEaxImm8(self):
        cdef int operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef int dataReg = CPU_REGISTER_AX
        if (operSize == 32):
            dataReg = CPU_REGISTER_EAX
        self.registers.regWrite(dataReg, self.main.platform.inPort(self.cpu.getCurrentOpcodeAdd(), operSize))
    def inAlDx(self):
        self.registers.regWrite(CPU_REGISTER_AL, self.main.platform.inPort(self.registers.regRead(CPU_REGISTER_DX), 8))
    def inAxEaxDx(self):
        cdef int operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef int dataReg = CPU_REGISTER_AX
        if (operSize == 32):
            dataReg = CPU_REGISTER_EAX
        self.registers.regWrite(dataReg, self.main.platform.inPort(self.registers.regRead(CPU_REGISTER_DX), operSize))
    def outImm8Al(self):
        self.main.platform.outPort(self.cpu.getCurrentOpcodeAdd(), self.registers.regRead(CPU_REGISTER_AL), 8)
    def outImm8AxEax(self):
        cdef int operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef int dataReg = CPU_REGISTER_AX
        if (operSize == 32):
            dataReg = CPU_REGISTER_EAX
        self.main.platform.outPort(self.cpu.getCurrentOpcodeAdd(), self.registers.regRead(dataReg), operSize)
    def outDxAl(self):
        self.main.platform.outPort(self.registers.regRead(CPU_REGISTER_DX), self.registers.regRead(CPU_REGISTER_AL), 8)
    def outDxAxEax(self):
        cdef int operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef int dataReg = CPU_REGISTER_AX
        if (operSize == 32):
            dataReg = CPU_REGISTER_EAX
        self.main.platform.outPort(self.registers.regRead(CPU_REGISTER_DX), self.registers.regRead(dataReg), operSize)
    def jgShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_ZF) and (self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_SF)==self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_OF)))
    def jgeShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_SF)==self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_OF))
    def jlShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_SF)!=self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_OF))
    def jleShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_ZF) or (self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_SF)!=self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_OF)))
    def jnzShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_ZF))
    def jzShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_ZF))
    def jaShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_CF) and not self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_ZF))
    def jbeShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_CF) or self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_ZF))
    def jncShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_CF))
    def jcShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_CF))
    def jnpShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_PF))
    def jpShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_PF))
    def jnoShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_OF))
    def joShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_OF))
    def jnsShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_SF))
    def jsShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(CPU_REGISTER_EFLAGS, FLAG_SF))
    def jcxzShort(self):
        cdef int operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef int cxReg = CPU_REGISTER_CX
        if (operSize == 32):
            cxReg = CPU_REGISTER_ECX
        self.jmpShort(operSize//8, self.registers.regRead(cxReg)==0)
    def jumpShort(self, int operSizeInBytes, int c=True): # operSize in bytes
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int segOperSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef long tempEIP = self.registers.regRead(CPU_REGISTER_EIP) + \
                            self.cpu.getCurrentOpcodeAdd(numBytes=(operSizeInBytes), signedValue=True)
        if (segOperSize == 16):
            tempEIP &= 0xffff
        if (c):
            self.registers.regWrite(CPU_REGISTER_EIP, tempEIP)
    def callNearRel16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(CPU_EXCEPTION_UD); return
        cdef int segOperSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef int eipRegName = CPU_REGISTER_IP
        cdef int opSizeInBytes = segOperSize//8
        if (segOperSize == 32):
            eipRegName = CPU_REGISTER_EIP
        cdef long tempEIP = self.registers.regRead(CPU_REGISTER_EIP) + \
                            self.cpu.getCurrentOpcodeAdd(numBytes=(opSizeInBytes), signedValue=True)
        if (segOperSize == 16):
            tempEIP &= 0xffff
        self.stackPush(eipRegName, segOperSize)
        self.registers.regWrite(CPU_REGISTER_EIP, tempEIP)
    def stackPush(self, regName, regSize):
        cdef int segOperSize   = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cdef int stackAddrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_SS)
        cdef int stackRegName = CPU_REGISTER_SP
        cdef int opSizeInBytes = segOperSize//8
        if (stackAddrSize == 16):
            stackRegName = CPU_REGISTER_SP
        elif (stackAddrSize == 32):
            stackRegName = CPU_REGISTER_ESP
        else:
            self.main.exitError(self, "stackAddrSize not in (16, 32). (stackAddrSize: {0:d})", stackAddrSize)
        self.registers.regSub(stackRegName, opSizeInBytes)
        
        

