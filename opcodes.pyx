import registers, misc

include "globals.pxi"

GROUP1_OP_ADD = 0
GROUP1_OP_OR  = 1
GROUP1_OP_ADC = 2
GROUP1_OP_SBB = 3
GROUP1_OP_AND = 4
GROUP1_OP_SUB = 5
GROUP1_OP_XOR = 6
GROUP1_OP_CMP = 7

GROUP2_OP_TEST = 0
GROUP2_OP_TEST_ALIAS = 1
GROUP2_OP_NOT  = 2
GROUP2_OP_NEG  = 3
GROUP2_OP_MUL  = 4
GROUP2_OP_IMUL = 5
GROUP2_OP_DIV  = 6
GROUP2_OP_IDIV = 7

GROUP4_OP_ROL = 0
GROUP4_OP_ROR = 1
GROUP4_OP_RCL = 2
GROUP4_OP_RCR = 3
GROUP4_OP_SHL_SAL = 4
GROUP4_OP_SHR = 5
GROUP4_OP_SHL_SAL_ALIAS = 6
GROUP4_OP_SAR = 7


OPCODE_LOOP = 1
OPCODE_LOOPE = 2
OPCODE_LOOPNE = 3

OPCODE_LOOPTYPES = (OPCODE_LOOP, OPCODE_LOOPE, OPCODE_LOOPNE)


PUSH_CS = 0x0e
PUSH_DS = 0x1e
PUSH_ES = 0x06
PUSH_FS = 0xa0 # 0F A0
PUSH_GS = 0xa8 # 0F A8
PUSH_SS = 0x16

POP_DS = 0x1f
POP_ES = 0x07
POP_FS = 0xa1 # 0F A1
POP_GS = 0xa9 # 0F A9
POP_SS = 0x17



cdef class Opcodes:
    cdef public object main, cpu, registers
    cdef public dict opcodeList
    def __init__(self, object main, object cpu):
        self.main = main
        self.cpu = cpu
        self.registers = self.cpu.registers
        self.opcodeList = {0x00: self.addRM8_R8, 0x01: self.addRM16_32_R16_32, 0x02: self.addR8_RM8, 0x03: self.addR16_32_RM16_32,
                           0x04: self.addAL_IMM8, 0x05: self.addAX_EAX_IMM16_32,
                           0x06: self.pushSeg, 0x07: self.popSeg,
                           
                           0x08: self.orRM8_R8, 0x09: self.orRM16_32_R16_32, 0x0a: self.orR8_RM8, 0x0b: self.orR16_32_RM16_32,
                           0x0c: self.orAL_IMM8, 0x0d: self.orAX_EAX_IMM16_32,
                           
                           
                           0x0e: self.pushSeg, 0x0f: self.opcodeGroup0F,
                           0x10: self.adcRM8_R8, 0x11: self.adcRM16_32_R16_32, 0x12: self.adcR8_RM8, 0x13: self.adcR16_32_RM16_32,
                           0x14: self.adcAL_IMM8, 0x15: self.adcAX_EAX_IMM16_32,
                           0x16: self.pushSeg, 0x17: self.popSeg,
                           0x18: self.sbbRM8_R8, 0x19: self.sbbRM16_32_R16_32,
                           0x1a: self.sbbR8_RM8, 0x1b: self.sbbR16_32_RM16_32,
                           0x1c: self.sbbAL_IMM8, 0x1d: self.sbbAX_EAX_IMM16_32,
                           0x1e: self.pushSeg, 0x1f: self.popSeg,
                           0x20: self.andRM8_R8, 0x21: self.andRM16_32_R16_32, 0x22: self.andR8_RM8, 0x23: self.andR16_32_RM16_32,
                           0x24: self.andAL_IMM8, 0x25: self.andAX_EAX_IMM16_32,
                           0x27: self.daa,
                           0x28: self.subRM8_R8, 0x29: self.subRM16_32_R16_32,
                           0x2a: self.subR8_RM8, 0x2b: self.subR16_32_RM16_32,
                           0x2c: self.subAL_IMM8, 0x2d: self.subAX_EAX_IMM16_32,
                           0x2f: self.das,
                           0x30: self.xorRM8_R8, 0x31: self.xorRM16_32_R16_32, 0x32: self.xorR8_RM8, 0x33: self.xorR16_32_RM16_32,
                           0x34: self.xorAL_IMM8, 0x35: self.xorAX_EAX_IMM16_32,
                           0x37: self.aaa,
                           0x38: self.cmpRM8_R8, 0x39: self.cmpRM16_32_R16_32,
                           0x3a: self.cmpR8_RM8, 0x3b: self.cmpR16_32_RM16_32,
                           
                           
                           0x3c: self.cmpAlImm8, 0x3d: self.cmpAxEaxImm16_32,
                           0x3f: self.aas,
                           0x40: self.incReg, 0x41: self.incReg, 0x42: self.incReg, 0x43: self.incReg,
                           0x44: self.incReg, 0x45: self.incReg, 0x46: self.incReg, 0x47: self.incReg,
                           0x48: self.decReg, 0x49: self.decReg, 0x4a: self.decReg, 0x4b: self.decReg,
                           0x4c: self.decReg, 0x4d: self.decReg, 0x4e: self.decReg, 0x4f: self.decReg,
                           
                           0x50: self.pushReg, 0x51: self.pushReg, 0x52: self.pushReg, 0x53: self.pushReg,
                           0x54: self.pushReg, 0x55: self.pushReg, 0x56: self.pushReg, 0x57: self.pushReg,
                           0x58: self.popReg, 0x59: self.popReg, 0x5a: self.popReg, 0x5b: self.popReg,
                           0x5c: self.popReg, 0x5d: self.popReg, 0x5e: self.popReg, 0x5f: self.popReg,
                           0x60: self.pushaWD, 0x61: self.popaWD, 0x62: self.bound, 0x63: self.arpl,
                           0x68: self.pushIMM16_32, 0x69: self.imulR_RM_IMM16_32,
                           0x6a: self.pushIMM8, 0x6b: self.imulR_RM_IMM8,
                           0x6c: self.insb, 0x6d: self.ins_wd,
                           0x6e: self.outsb, 0x6f: self.outs_wd,
                           0x70: self.joShort, 0x71: self.jnoShort,
                           0x72: self.jcShort, 0x73: self.jncShort, 0x74: self.jzShort, 0x75: self.jnzShort,
                           0x76: self.jbeShort, 0x77: self.jaShort, 0x78: self.jsShort, 0x79: self.jnsShort,
                           0x7a: self.jpShort, 0x7b: self.jnpShort, 0x7c: self.jlShort, 0x7d: self.jgeShort,
                           0x7e: self.jleShort, 0x7f: self.jgShort, 
                           0x80: self.opcodeGroup1_RM8_IMM8, 0x81: self.opcodeGroup1_RM16_32_IMM16_32,
                           0x83: self.opcodeGroup1_RM16_32_IMM8,
                           0x84: self.testRM8_R8, 0x85: self.testRM16_32_R16_32,
                           0x86: self.xchgR8_RM8, 0x87: self.xchgR16_32_RM16_32,
                           0x88: self.movRM8_R8, 0x89: self.movRM16_32_R16_32,
                           0x8a: self.movR8_RM8, 0x8b: self.movR16_32_RM16_32,
                           0x8c: self.movRM16_SREG, 0x8d: self.lea,
                           0x8e: self.movSREG_RM16, 0x8f: self.popRM16_32, 0x90: self.nop, # nop==xchg ax, ax
                           0x91: self.xchgReg, 0x92: self.xchgReg, 0x93: self.xchgReg, 0x94: self.xchgReg, 
                           0x95: self.xchgReg, 0x96: self.xchgReg, 0x97: self.xchgReg,
                           0x98: self.cbw_cwde, 0x99: self.cwd_cdq, 0x9a: self.callPtr16_32,
                           0x9c: self.pushfWD, 0x9d: self.popfWD,
                           0x9e: self.sahf, 0x9f: self.lahf,
                           0xa0: self.movAL_MOFFS8, 0xa1: self.movAX_EAX_MOFFS16_32,
                           0xa2: self.movMOFFS8_AL, 0xa3: self.movMOFFS16_32_AX_EAX,
                           0xa4: self.movsb, 0xa5: self.movs_wd,
                           0xa6: self.cmpsb, 0xa7: self.cmps_wd,
                           0xa8: self.testAL_IMM8, 0xa9: self.testAX_EAX_IMM16_32,
                           0xaa: self.stosb, 0xab: self.stos_wd,
                           0xac: self.lodsb, 0xad: self.lods_wd,
                           0xae: self.scasb, 0xaf: self.scas_wd,
                           0xb0: self.movImm8ToR8, 0xb1: self.movImm8ToR8, 0xb2: self.movImm8ToR8,
                           0xb3: self.movImm8ToR8, 0xb4: self.movImm8ToR8, 0xb5: self.movImm8ToR8,
                           0xb6: self.movImm8ToR8, 0xb7: self.movImm8ToR8,
                           0xb8: self.movImm16_32ToR16_32, 0xb9: self.movImm16_32ToR16_32, 0xba: self.movImm16_32ToR16_32,
                           0xbb: self.movImm16_32ToR16_32, 0xbc: self.movImm16_32ToR16_32, 0xbd: self.movImm16_32ToR16_32,
                           0xbe: self.movImm16_32ToR16_32, 0xbf: self.movImm16_32ToR16_32,
                           0xc0: self.opcodeGroup4_RM8_IMM8, 0xc1: self.opcodeGroup4_RM16_32_IMM8,
                           0xc2: self.retNearImm, 0xc3: self.retNear,
                           0xc4: self.les, 0xc5: self.lds,
                           0xc6: self.opcodeGroup3_RM8_IMM8, 0xc7: self.opcodeGroup3_RM16_32_IMM16_32,
                           0xc8: self.enter, 0xc9: self.leave,
                           0xca: self.retFarImm,  0xcb: self.retFar, 0xcc: self.int3, 0xcd: self.interrupt, 
                           0xce: self.into, 0xcf: self.iret,
                           0xd0: self.opcodeGroup4_RM8_1, 0xd1: self.opcodeGroup4_RM16_32_1,
                           0xd2: self.opcodeGroup4_RM8_CL, 0xd3: self.opcodeGroup4_RM16_32_CL,
                           0xd4: self.aam, 0xd5: self.aad, 0xd6: self.undefNoUD, 0xd7: self.xlatb,
                           0xe0: self.loopne, 0xe1: self.loope, 0xe2: self.loop,
                           0xe3: self.jcxzShort, 0xe4: self.inAlImm8, 0xe5: self.inAxEaxImm8, 0xe6: self.outImm8Al, 0xe7: self.outImm8AxEax, 0xe8: self.callNearRel16_32, 0xe9: self.jumpShortRelativeWordDWord,
                           0xea: self.jumpFarAbsolutePtr, 0xeb: self.jumpShortRelativeByte, 0xec: self.inAlDx, 0xed: self.inAxEaxDx, 0xee: self.outDxAl, 0xef: self.outDxAxEax,
                           0xf1: self.undefNoUD, 0xf4: self.hlt, 0xf5: self.cmc,
                           0xf6: self.opcodeGroup2_RM8, 0xf7: self.opcodeGroup2_RM16_32,
                           0xf8: self.clc, 0xf9: self.stc,
                           0xfa: self.cli, 0xfb: self.sti, 0xfc: self.cld, 0xfd: self.std,
                           0xfe: self.opcodeGroupFE, 0xff: self.opcodeGroupFF}
    def undefNoUD(self):
        pass
    def cli(self):
        self.registers.setEFLAG(FLAG_IF, False)
    def sti(self):
        self.registers.setEFLAG(FLAG_IF, True)
    def cld(self):
        self.registers.setEFLAG(FLAG_DF, False)
    def std(self):
        self.registers.setEFLAG(FLAG_DF, True)
    def clc(self):
        self.registers.setEFLAG(FLAG_CF, False)
    def stc(self):
        self.registers.setEFLAG(FLAG_CF, True)
    def cmc(self):
        self.registers.setEFLAG(FLAG_CF, not self.registers.getEFLAG(FLAG_CF) )
    def hlt(self):
        self.cpu.cpuHalted = True
    def nop(self):
        pass
    def switchToProtectedModeIfNeeded(self):
        if (self.registers.segments.gdt.needFlush):
            self.registers.segments.gdt.gdtLoaded = self.registers.segments.gdt.setGdtLoadedTo
            self.registers.segments.gdt.needFlush = False
            self.cpu.protectedModeOn = self.registers.getFlag(CPU_REGISTER_CR0, CR0_FLAG_PE)
    def jumpFarAbsolutePtr(self):
        cdef unsigned char operSize
        cdef unsigned short cs
        cdef unsigned long eip
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        eip = self.cpu.getCurrentOpcodeAdd(operSize)
        cs = self.cpu.getCurrentOpcodeAdd(OP_SIZE_WORD)
        self.registers.regWrite(CPU_REGISTER_EIP, eip)
        self.registers.segWrite(CPU_SEGMENT_CS, cs)
        self.switchToProtectedModeIfNeeded()
    def jumpShortRelativeByte(self):
        self.jumpShort(OP_SIZE_BYTE)
    def jumpShortRelativeWordDWord(self):
        cdef unsigned char offsetSize
        offsetSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.jumpShort(offsetSize)
    def loop(self):
        self.loopFunc(OPCODE_LOOP)
    def loope(self):
        self.loopFunc(OPCODE_LOOPE)
    def loopne(self):
        self.loopFunc(OPCODE_LOOPNE)
    def loopFunc(self, unsigned char loopType):
        cdef unsigned char operSize, addrSize, cond, oldZF
        cdef unsigned short countReg, eipRegName
        cdef unsigned long bitMask
        cdef long long countOrNewEip
        cdef char rel8
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        eipRegName   = CPU_REGISTER_EIP
        bitMask = self.main.misc.getBitMask(operSize)
        oldZF = self.registers.getEFLAG(FLAG_ZF)
        rel8 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, signed=True)
        countOrNewEip = self.registers.regSub(countReg, 1)
        cond = False
        if (loopType == OPCODE_LOOPE and oldZF):
            cond = True
        elif (loopType == OPCODE_LOOPNE and not oldZF):
            cond = True
        elif (loopType == OPCODE_LOOP):
            cond = True
        if (cond and countOrNewEip != 0):
            countOrNewEip = (self.registers.regRead(eipRegName)+rel8)&bitMask
            self.registers.regWrite(eipRegName, countOrNewEip)
    def cmpRM8_R8(self):
        cdef unsigned char op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        op2 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        self.registers.setFullFlags(op1, op2, OP_SIZE_BYTE, SET_FLAGS_SUB)
    def cmpRM16_32_R16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_SUB)
    def cmpR8_RM8(self):
        cdef unsigned char op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op1 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        self.registers.setFullFlags(op1, op2, OP_SIZE_BYTE, SET_FLAGS_SUB)
    def cmpR16_32_RM16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_SUB)
    def cmpAlImm8(self):
        cdef unsigned char reg0, imm8
        reg0 = self.registers.regRead(CPU_REGISTER_AL)
        imm8 = self.cpu.getCurrentOpcodeAdd()
        self.registers.setFullFlags(reg0, imm8, OP_SIZE_BYTE, SET_FLAGS_SUB)
    def cmpAxEaxImm16_32(self):
        cdef unsigned char operSize
        cdef unsigned short eaxReg
        cdef unsigned long reg0, imm16_32
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        reg0 = self.registers.regRead(eaxReg)
        imm16_32 = self.cpu.getCurrentOpcodeAdd(operSize)
        self.registers.setFullFlags(reg0, imm16_32, operSize, SET_FLAGS_SUB)
    def movImm8ToR8(self):
        cdef unsigned char r8reg
        r8reg = self.cpu.opcode&0x7
        self.registers.regWrite(CPU_REGISTER_BYTE[r8reg], self.cpu.getCurrentOpcodeAdd())
    def movImm16_32ToR16_32(self):
        cdef unsigned char operSize, r16_32reg
        cdef unsigned long src
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        r16_32reg = self.cpu.opcode&0x7
        src = self.cpu.getCurrentOpcodeAdd(operSize)
        if (operSize == OP_SIZE_WORD):
            self.registers.regWrite(CPU_REGISTER_WORD[r16_32reg], src)
        elif (operSize == OP_SIZE_DWORD):
            self.registers.regWrite(CPU_REGISTER_DWORD[r16_32reg], src)
    def movRM8_R8(self):
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        self.registers.modRMSave(rmOperands, OP_SIZE_BYTE, self.registers.modRLoad(rmOperands, OP_SIZE_BYTE))
    def movRM16_32_R16_32(self):
        cdef unsigned char operSize
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        self.registers.modRMSave(rmOperands, operSize, self.registers.modRLoad(rmOperands, operSize))
    def testRM8_R8(self):
        cdef unsigned char op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op1 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        self.registers.setSZP_C0_O0_A0(op1&op2, OP_SIZE_BYTE)
    def testRM16_32_R16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        self.registers.setSZP_C0_O0_A0(op1&op2, operSize)
    def testAL_IMM8(self):
        cdef unsigned char op1, op2
        op1 = self.registers.regRead(CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd()
        self.registers.setSZP_C0_O0_A0(op1&op2, OP_SIZE_BYTE)
    def testAX_EAX_IMM16_32(self):
        cdef unsigned char operSize
        cdef unsigned short eaxReg
        cdef unsigned long op1, op2
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op1 = self.registers.regRead(eaxReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize)
        self.registers.setSZP_C0_O0_A0(op1&op2, operSize)
    def movR8_RM8(self):
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        self.registers.modRSave(rmOperands, OP_SIZE_BYTE, self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE))
    def movR16_32_RM16_32(self, unsigned char cond=True):
        cdef unsigned char operSize
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        if (cond):
            self.registers.modRSave(rmOperands, operSize, self.registers.modRMLoad(rmOperands, operSize))
    def movRM16_SREG(self):
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        self.registers.modRMSave(rmOperands, OP_SIZE_WORD, self.registers.modSegLoad(rmOperands, OP_SIZE_WORD))
    def movSREG_RM16(self):
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        if (rmOperands[2] == CPU_SEGMENT_CS):
            raise misc.ChemuException(CPU_EXCEPTION_UD)
        self.registers.modSegSave(rmOperands, OP_SIZE_WORD, self.registers.modRMLoad(rmOperands, OP_SIZE_WORD))
    def movAL_MOFFS8(self):
        cdef unsigned char operSize, addrSize
        cdef unsigned short regName
        cdef unsigned long mmAddr
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        regName = CPU_REGISTER_AL
        mmAddr = self.cpu.getCurrentOpcodeAdd(addrSize)
        self.registers.regWrite(regName, self.main.mm.mmReadValue(mmAddr, OP_SIZE_BYTE))
    def movAX_EAX_MOFFS16_32(self):
        cdef unsigned char operSize, addrSize
        cdef unsigned short regName
        cdef unsigned long mmAddr
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        regName = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        mmAddr = self.cpu.getCurrentOpcodeAdd(addrSize)
        self.registers.regWrite(regName, self.main.mm.mmReadValue(mmAddr, operSize))
    def movMOFFS8_AL(self):
        cdef unsigned char operSize, addrSize
        cdef unsigned short regName
        cdef unsigned long mmAddr
        addrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_CS)
        regName = CPU_REGISTER_AL
        mmAddr = self.cpu.getCurrentOpcodeAdd(addrSize)
        self.main.mm.mmWriteValue(mmAddr, self.registers.regRead(regName), OP_SIZE_BYTE)
    def movMOFFS16_32_AX_EAX(self):
        cdef unsigned char operSize, addrSize
        cdef unsigned short regName
        cdef unsigned long mmAddr
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        regName = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        mmAddr = self.cpu.getCurrentOpcodeAdd(addrSize)
        self.main.mm.mmWriteValue(mmAddr, self.registers.regRead(regName), operSize)
    def addRM8_R8(self):
        cdef unsigned char op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        op2 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        self.registers.modRMSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_ADD)
        self.registers.setFullFlags(op1, op2, OP_SIZE_BYTE, SET_FLAGS_ADD)
    def addRM16_32_R16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        self.registers.modRMSave(rmOperands, operSize, op2, valueOp=VALUEOP_ADD)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_ADD)
    def addR8_RM8(self):
        cdef unsigned char op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op1 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        self.registers.modRSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_ADD)
        self.registers.setFullFlags(op1, op2, OP_SIZE_BYTE, SET_FLAGS_ADD)
    def addR16_32_RM16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        self.registers.modRSave(rmOperands, operSize, op2, valueOp=VALUEOP_ADD)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_ADD)
    def addAL_IMM8(self):
        cdef unsigned char op1, op2
        op1 = self.registers.regRead(CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        self.registers.regAdd(CPU_REGISTER_AL, op2)
        self.registers.setFullFlags(op1, op2, OP_SIZE_BYTE, SET_FLAGS_ADD)
    def addAX_EAX_IMM16_32(self):
        cdef unsigned char operSize
        cdef unsigned short dataReg
        cdef unsigned long op1, op2
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op1 = self.registers.regRead(dataReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        self.registers.regAdd(dataReg, op2)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_ADD)
    def adcRM8_R8(self):
        cdef unsigned char op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        op2 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        self.registers.modRMSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_ADC)
        self.registers.setFullFlags(op1+self.registers.getEFLAG(FLAG_CF), op2, OP_SIZE_BYTE, SET_FLAGS_ADD)
    def adcRM16_32_R16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        self.registers.modRMSave(rmOperands, operSize, op2, valueOp=VALUEOP_ADC)
        self.registers.setFullFlags(op1+self.registers.getEFLAG(FLAG_CF), op2, operSize, SET_FLAGS_ADD)
    def adcR8_RM8(self):
        cdef unsigned char op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op1 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        self.registers.modRSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_ADC)
        self.registers.setFullFlags(op1+self.registers.getEFLAG(FLAG_CF), op2, OP_SIZE_BYTE, SET_FLAGS_ADD)
    def adcR16_32_RM16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        self.registers.modRSave(rmOperands, operSize, op2, valueOp=VALUEOP_ADC)
        self.registers.setFullFlags(op1+self.registers.getEFLAG(FLAG_CF), op2, operSize, SET_FLAGS_ADD)
    def adcAL_IMM8(self):
        cdef unsigned char op1, op2
        op1 = self.registers.regRead(CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        self.registers.regAdc(CPU_REGISTER_AL, op2)
        self.registers.setFullFlags(op1+self.registers.getEFLAG(FLAG_CF), op2, OP_SIZE_BYTE, SET_FLAGS_ADD)
    def adcAX_EAX_IMM16_32(self):
        cdef unsigned char operSize
        cdef unsigned short dataReg
        cdef unsigned long op1, op2
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op1 = self.registers.regRead(dataReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        self.registers.regAdc(dataReg, op2)
        self.registers.setFullFlags(op1+self.registers.getEFLAG(FLAG_CF), op2, operSize, SET_FLAGS_ADD)
    def subRM8_R8(self):
        cdef unsigned char op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        op2 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        self.registers.modRMSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_SUB)
        self.registers.setFullFlags(op1, op2, OP_SIZE_BYTE, SET_FLAGS_SUB)
    def subRM16_32_R16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        self.registers.modRMSave(rmOperands, operSize, op2, valueOp=VALUEOP_SUB)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_SUB)
    def subR8_RM8(self):
        cdef unsigned char op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op1 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        self.registers.modRSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_SUB)
        self.registers.setFullFlags(op1, op2, OP_SIZE_BYTE, SET_FLAGS_SUB)
    def subR16_32_RM16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        self.registers.modRSave(rmOperands, operSize, op2, valueOp=VALUEOP_SUB)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_SUB)
    def subAL_IMM8(self):
        cdef unsigned char op1, op2
        op1 = self.registers.regRead(CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        self.registers.regSub(CPU_REGISTER_AL, op2)
        self.registers.setFullFlags(op1, op2, OP_SIZE_BYTE, SET_FLAGS_SUB)
    def subAX_EAX_IMM16_32(self):
        cdef unsigned char operSize
        cdef unsigned short dataReg
        cdef unsigned long op1, op2
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op1 = self.registers.regRead(dataReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        self.registers.regSub(dataReg, op2)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_SUB)
    def sbbRM8_R8(self):
        cdef unsigned char op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        op2 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        self.registers.modRMSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_SBB)
        self.registers.setFullFlags(op1-self.registers.getEFLAG(FLAG_CF), op2, OP_SIZE_BYTE, SET_FLAGS_SUB)
    def sbbRM16_32_R16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        self.registers.modRMSave(rmOperands, operSize, op2, valueOp=VALUEOP_SBB)
        self.registers.setFullFlags(op1-self.registers.getEFLAG(FLAG_CF), op2, operSize, SET_FLAGS_SUB)
    def sbbR8_RM8(self):
        cdef unsigned char op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op1 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        self.registers.modRSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_SBB)
        self.registers.setFullFlags(op1-self.registers.getEFLAG(FLAG_CF), op2, OP_SIZE_BYTE, SET_FLAGS_SUB)
    def sbbR16_32_RM16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        self.registers.modRSave(rmOperands, operSize, op2, valueOp=VALUEOP_SBB)
        self.registers.setFullFlags(op1-self.registers.getEFLAG(FLAG_CF), op2, operSize, SET_FLAGS_SUB)
    def sbbAL_IMM8(self):
        cdef unsigned char op1, op2
        op1 = self.registers.regRead(CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        self.registers.regSbb(CPU_REGISTER_AL, op2)
        self.registers.setFullFlags(op1-self.registers.getEFLAG(FLAG_CF), op2, OP_SIZE_BYTE, SET_FLAGS_SUB)
    def sbbAX_EAX_IMM16_32(self):
        cdef unsigned char operSize
        cdef unsigned short dataReg
        cdef unsigned long op1, op2
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op1 = self.registers.regRead(dataReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        self.registers.regSbb(dataReg, op2)
        self.registers.setFullFlags(op1-self.registers.getEFLAG(FLAG_CF), op2, operSize, SET_FLAGS_SUB)
    def andRM8_R8(self):
        cdef unsigned char op2, data
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op2 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        data = self.registers.modRMSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_AND)
        self.registers.setSZP_C0_O0_A0(data, OP_SIZE_BYTE)
    def andRM16_32_R16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op2, data
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        data = self.registers.modRMSave(rmOperands, operSize, op2, valueOp=VALUEOP_AND)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    def andR8_RM8(self):
        cdef unsigned char op2, data
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        data = self.registers.modRSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_AND)
        self.registers.setSZP_C0_O0_A0(data, OP_SIZE_BYTE)
    def andR16_32_RM16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op2, data
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        data = self.registers.modRSave(rmOperands, operSize, op2, valueOp=VALUEOP_AND)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    def andAL_IMM8(self):
        cdef unsigned char op2, data
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        data = self.registers.regAnd(CPU_REGISTER_AL, op2)
        self.registers.setSZP_C0_O0_A0(data, OP_SIZE_BYTE)
    def andAX_EAX_IMM16_32(self):
        cdef unsigned char operSize
        cdef unsigned short dataReg
        cdef unsigned long op2, data
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        data = self.registers.regAnd(dataReg, op2)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    
    
    
    def orRM8_R8(self):
        cdef unsigned char op2, data
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op2 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        data = self.registers.modRMSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_OR)
        self.registers.setSZP_C0_O0_A0(data, OP_SIZE_BYTE)
    def orRM16_32_R16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op2, data
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        data = self.registers.modRMSave(rmOperands, operSize, op2, valueOp=VALUEOP_OR)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    def orR8_RM8(self):
        cdef unsigned char op2, data
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        data = self.registers.modRSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_OR)
        self.registers.setSZP_C0_O0_A0(data, OP_SIZE_BYTE)
    def orR16_32_RM16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op2, data
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        data = self.registers.modRSave(rmOperands, operSize, op2, valueOp=VALUEOP_OR)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    def orAL_IMM8(self):
        cdef unsigned char op2, data
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        data = self.registers.regOr(CPU_REGISTER_AL, op2)
        self.registers.setSZP_C0_O0_A0(data, OP_SIZE_BYTE)
    def orAX_EAX_IMM16_32(self):
        cdef unsigned char operSize
        cdef unsigned short dataReg
        cdef unsigned long op2, data
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        data = self.registers.regOr(dataReg, op2)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    
    
    
    def xorRM8_R8(self):
        cdef unsigned char op2, data
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op2 = self.registers.modRLoad(rmOperands, OP_SIZE_BYTE)
        data = self.registers.modRMSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_XOR)
        self.registers.setSZP_C0_O0_A0(data, OP_SIZE_BYTE)
    def xorRM16_32_R16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op2, data
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        data = self.registers.modRMSave(rmOperands, operSize, op2, valueOp=VALUEOP_XOR)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    def xorR8_RM8(self):
        cdef unsigned char op2, data
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
        data = self.registers.modRSave(rmOperands, OP_SIZE_BYTE, op2, valueOp=VALUEOP_XOR)
        self.registers.setSZP_C0_O0_A0(data, OP_SIZE_BYTE)
    def xorR16_32_RM16_32(self):
        cdef unsigned char operSize
        cdef unsigned long op2, data
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        data = self.registers.modRSave(rmOperands, operSize, op2, valueOp=VALUEOP_XOR)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    def xorAL_IMM8(self):
        cdef unsigned char op2, data
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        data = self.registers.regXor(CPU_REGISTER_AL, op2)
        self.registers.setSZP_C0_O0_A0(data, OP_SIZE_BYTE)
    def xorAX_EAX_IMM16_32(self):
        cdef unsigned char operSize
        cdef unsigned short dataReg
        cdef unsigned long op2, data
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        data = self.registers.regXor(dataReg, op2)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    
    
    def stosb(self):
        self.stosFunc(OP_SIZE_BYTE)
    def stos_wd(self):
        cdef unsigned char operSize
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.stosFunc(operSize)
    def stosFunc(self, unsigned char operSize):
        cdef unsigned char addrSize, df
        cdef unsigned short dataReg, srcReg, countReg
        cdef unsigned long data, countVal
        cdef unsigned long long dataLength
        cdef long long destAddr
        cdef bytes memData
        addrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_CS)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_DI, addrSize)
        if (operSize == OP_SIZE_BYTE):
            srcReg = CPU_REGISTER_AL
        else:
            srcReg  = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        data = self.registers.regRead(srcReg)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        dataLength = operSize*countVal
        destAddr = self.registers.regRead(dataReg)
        if (df):
            destAddr -= dataLength-operSize
        memData = data.to_bytes(length=operSize, byteorder="little")*countVal
        self.main.mm.mmWrite(destAddr, memData, dataLength, segId=CPU_SEGMENT_ES, allowOverride=False)
        if (not df):
            self.registers.regAdd(dataReg, dataLength)
        else:
            self.registers.regSub(dataReg, dataLength)
        self.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite( countReg, 0 )
    
    
    def movsb(self):
        self.movsFunc(OP_SIZE_BYTE)
    def movs_wd(self):
        cdef unsigned char operSize
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.movsFunc(operSize)
    def movsFunc(self, unsigned char operSize):
        cdef unsigned char addrSize, df
        cdef unsigned short esiReg, ediReg, countReg
        cdef unsigned long countVal
        cdef unsigned long long dataLength
        cdef long long esiVal, ediVal
        cdef bytes data
        addrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_CS)
        esiReg  = self.registers.getWordAsDword(CPU_REGISTER_SI, addrSize)
        ediReg  = self.registers.getWordAsDword(CPU_REGISTER_DI, addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        dataLength = operSize*countVal
        esiVal = self.registers.regRead(esiReg)
        ediVal = self.registers.regRead(ediReg)
        if (df):
            esiVal -= dataLength-operSize
            ediVal -= dataLength-operSize
        data = self.main.mm.mmRead(esiVal, dataLength, segId=CPU_SEGMENT_DS, allowOverride=True)
        self.main.mm.mmWrite(ediVal, data, dataLength, segId=CPU_SEGMENT_ES, allowOverride=False)
        if (not df):
            self.registers.regAdd(esiReg, dataLength)
            self.registers.regAdd(ediReg, dataLength)
        else:
            self.registers.regSub(esiReg, dataLength)
            self.registers.regSub(ediReg, dataLength)
        self.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite( countReg, 0 )
    
    
    def lodsb(self):
        self.lodsFunc(OP_SIZE_BYTE)
    def lods_wd(self):
        cdef unsigned char operSize
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.lodsFunc(operSize)
    def lodsFunc(self, unsigned char operSize):
        cdef unsigned char addrSize, df
        cdef unsigned short eaxReg, esiReg, countReg
        cdef unsigned long data, countVal
        cdef unsigned long long dataLength
        cdef long long esiVal
        addrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_CS)
        if (operSize == OP_SIZE_BYTE):
            eaxReg = CPU_REGISTER_AL
        else:
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        esiReg  = self.registers.getWordAsDword(CPU_REGISTER_SI, addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        dataLength = operSize*countVal
        if (not df):
            esiVal = self.registers.regAdd(esiReg, dataLength)-operSize
        else:
            esiVal = self.registers.regSub(esiReg, dataLength)+operSize
        data = self.main.mm.mmReadValue(esiVal, operSize, segId=CPU_SEGMENT_DS, allowOverride=True)
        self.registers.regWrite(eaxReg, data)
        self.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite( countReg, 0 )
    
    
    def cmpsb(self):
        self.cmpsFunc(OP_SIZE_BYTE)
    def cmps_wd(self):
        cdef unsigned char operSize
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.cmpsFunc(operSize)
    def cmpsFunc(self, unsigned char operSize):
        cdef unsigned char addrSize, df, zf
        cdef unsigned short esiReg, ediReg, countReg
        cdef unsigned long esiVal, ediVal, countVal, newCount, src1, src2
        addrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_CS)
        esiReg  = self.registers.getWordAsDword(CPU_REGISTER_SI, addrSize)
        ediReg  = self.registers.getWordAsDword(CPU_REGISTER_DI, addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal, newCount = 1, 0
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        esiVal = self.registers.regRead(esiReg)
        ediVal = self.registers.regRead(ediReg)
        for i in range(countVal):
            src1 = self.main.mm.mmReadValue(esiVal, operSize, segId=CPU_SEGMENT_DS, allowOverride=True)
            src2 = self.main.mm.mmReadValue(ediVal, operSize, segId=CPU_SEGMENT_ES, allowOverride=False)
            self.registers.setFullFlags(src1, src2, operSize, SET_FLAGS_SUB)
            if (not df):
                esiVal = self.registers.regAdd(esiReg, operSize)
                ediVal = self.registers.regAdd(ediReg, operSize)
            else:
                esiVal = self.registers.regSub(esiReg, operSize)
                ediVal = self.registers.regSub(ediReg, operSize)
            zf = self.registers.getEFLAG(FLAG_ZF)
            if ((self.registers.repPrefix == OPCODE_PREFIX_REPE and not zf) or \
                (self.registers.repPrefix == OPCODE_PREFIX_REPNE and zf)):
                newCount = countVal-i-1
                break
        self.cpu.cycles += countVal-newCount
        if (self.registers.repPrefix):
            self.registers.regWrite( countReg, newCount )
    
    
    def scasb(self):
        self.scasFunc(OP_SIZE_BYTE)
    def scas_wd(self):
        cdef unsigned char operSize
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.scasFunc(operSize)
    def scasFunc(self, unsigned char operSize):
        cdef unsigned char addrSize, df, zf
        cdef unsigned short eaxReg, ediReg, countReg
        cdef unsigned long src1, src2, ediVal, countVal, newCount
        addrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_CS)
        if (operSize == OP_SIZE_BYTE):
            eaxReg = CPU_REGISTER_AL
        else:
            eaxReg  = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        ediReg  = self.registers.getWordAsDword(CPU_REGISTER_DI, addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal, newCount = 1, 0
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        for i in range(countVal):
            ediVal = self.registers.regRead(ediReg)
            src1 = self.registers.regRead(eaxReg)
            src2 = self.main.mm.mmReadValue(ediVal, operSize, segId=CPU_SEGMENT_ES, allowOverride=False)
            self.registers.setFullFlags(src1, src2, operSize, SET_FLAGS_SUB)
            if (not df):
                self.registers.regAdd(ediReg, operSize)
            else:
                self.registers.regSub(ediReg, operSize)
            zf = self.registers.getEFLAG(FLAG_ZF)
            if ((self.registers.repPrefix == OPCODE_PREFIX_REPE and not zf) or \
                (self.registers.repPrefix == OPCODE_PREFIX_REPNE and zf)):
                newCount = countVal-i-1
                break
        self.cpu.cycles += countVal-newCount
        if (self.registers.repPrefix):
            self.registers.regWrite( countReg, newCount )
    
    
    def inAlImm8(self):
        self.registers.regWrite(CPU_REGISTER_AL, self.main.platform.inPort(self.cpu.getCurrentOpcodeAdd(), OP_SIZE_BYTE))
    def inAxEaxImm8(self):
        cdef unsigned char operSize
        cdef unsigned short dataReg
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        self.registers.regWrite(dataReg, self.main.platform.inPort(self.cpu.getCurrentOpcodeAdd(), operSize))
    def inAlDx(self):
        self.registers.regWrite(CPU_REGISTER_AL, self.main.platform.inPort(self.registers.regRead(CPU_REGISTER_DX), OP_SIZE_BYTE))
    def inAxEaxDx(self):
        cdef unsigned char operSize
        cdef unsigned short dataReg
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        self.registers.regWrite(dataReg, self.main.platform.inPort(self.registers.regRead(CPU_REGISTER_DX), operSize))
    def outImm8Al(self):
        self.main.platform.outPort(self.cpu.getCurrentOpcodeAdd(), self.registers.regRead(CPU_REGISTER_AL), OP_SIZE_BYTE)
    def outImm8AxEax(self):
        cdef unsigned char operSize
        cdef unsigned short dataReg
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        self.main.platform.outPort(self.cpu.getCurrentOpcodeAdd(), self.registers.regRead(dataReg), operSize)
    def outDxAl(self):
        self.main.platform.outPort(self.registers.regRead(CPU_REGISTER_DX), self.registers.regRead(CPU_REGISTER_AL), OP_SIZE_BYTE)
    def outDxAxEax(self):
        cdef unsigned char operSize
        cdef unsigned short dataReg
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        self.main.platform.outPort(self.registers.regRead(CPU_REGISTER_DX), self.registers.regRead(dataReg), operSize)
    def outs_func(self, unsigned char operSize):
        cdef unsigned char addrSize, df
        cdef unsigned short dxReg, esiReg, countReg, ioPort
        cdef unsigned long value, esiVal, countVal
        addrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_CS)
        dxReg  = CPU_REGISTER_DX
        esiReg  = self.registers.getWordAsDword(CPU_REGISTER_SI, addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        for i in range(countVal):
            esiVal = self.registers.regRead(esiReg)
            ioPort = self.registers.regRead(dxReg)
            value = self.main.mm.mmReadValue(esiVal, operSize, segId=CPU_SEGMENT_DS, allowOverride=True)
            self.main.platform.outPort(ioPort, value, operSize)
            if (not df):
                self.registers.regAdd(esiReg, operSize)
            else:
                self.registers.regSub(esiReg, operSize)
        self.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite( countReg, 0 )
    def outsb(self):
        self.outs_func(OP_SIZE_BYTE)
    def outs_wd(self):
        cdef unsigned char operSize
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.outs_func(operSize)
    def ins_func(self, unsigned char operSize):
        cdef unsigned char addrSize, df
        cdef unsigned short dxReg, ediReg, countReg, ioPort
        cdef unsigned long value, ediVal, countVal
        addrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_CS)
        dxReg  = CPU_REGISTER_DX
        ediReg  = self.registers.getWordAsDword(CPU_REGISTER_DI, addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        for i in range(countVal):
            ediVal = self.registers.regRead(ediReg)
            ioPort = self.registers.regRead(dxReg)
            value = self.main.platform.inPort(ioPort, operSize)
            self.main.mm.mmWriteValue(ediVal, value, operSize, segId=CPU_SEGMENT_ES, allowOverride=False)
            if (not df):
                self.registers.regAdd(ediReg, operSize)
            else:
                self.registers.regSub(ediReg, operSize)
        self.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite( countReg, 0 )
    def insb(self):
        self.ins_func(OP_SIZE_BYTE)
    def ins_wd(self):
        cdef unsigned char operSize
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.ins_func(operSize)
    def jgShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_ZF) and (self.registers.getEFLAG(FLAG_SF)==self.registers.getEFLAG(FLAG_OF)))
    def jgeShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        cdef unsigned long flags, flagsVal
        flags = FLAG_SF | FLAG_OF
        flagsVal = self.registers.getEFLAG(flags)
        self.jumpShort(size, not flagsVal or flagsVal == flags)
    def jlShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_SF)!=self.registers.getEFLAG(FLAG_OF))
    def jleShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_ZF) or (self.registers.getEFLAG(FLAG_SF)!=self.registers.getEFLAG(FLAG_OF)))
    def jnzShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_ZF))
    def jzShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_ZF))
    def jaShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_CF) and not self.registers.getEFLAG(FLAG_ZF))
    def jbeShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        cdef unsigned long flags
        flags = FLAG_CF | FLAG_ZF
        self.jumpShort(size, self.registers.getEFLAG(flags))
    def jncShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_CF))
    def jcShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_CF))
    def jnpShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_PF))
    def jpShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_PF))
    def jnoShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_OF))
    def joShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_OF))
    def jnsShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_SF))
    def jsShort(self, unsigned char size=OP_SIZE_BYTE): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_SF))
    def jcxzShort(self):
        cdef unsigned char operSize
        cdef unsigned short cxReg
        cdef unsigned long cxVal
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cxReg = self.registers.getWordAsDword(CPU_REGISTER_CX, operSize)
        cxVal = self.registers.regRead(cxReg)
        self.jumpShort(OP_SIZE_BYTE, cxVal==0)
    def jumpShort(self, unsigned char offsetSize, unsigned char c=True):
        cdef unsigned char operSize
        cdef unsigned short eipRegName
        cdef long offset
        cdef long long newEip
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        eipRegName = CPU_REGISTER_EIP
        offset = self.cpu.getCurrentOpcodeAdd(numBytes=offsetSize, signed=True)
        if (c):
            newEip = self.registers.regRead(eipRegName)+offset
            if (operSize == OP_SIZE_WORD):
                newEip &= 0xffff
            self.registers.regWrite(eipRegName, newEip)
    def callNearRel16_32(self):
        cdef unsigned char operSize
        cdef unsigned short eipRegName
        cdef long offset
        cdef long long newEip
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        eipRegName = CPU_REGISTER_EIP
        offset = self.cpu.getCurrentOpcodeAdd(numBytes=operSize, signed=True)
        self.stackPushRegId(eipRegName, operSize)
        newEip = self.registers.regRead(eipRegName)+offset
        if (operSize == OP_SIZE_WORD):
            newEip &= 0xffff
        self.registers.regWrite(eipRegName, newEip)
    def callPtr16_32(self):
        cdef unsigned char operSize
        cdef unsigned short segId, eipRegName, segVal
        cdef unsigned long eipAddr
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        segId = CPU_SEGMENT_CS
        eipRegName = CPU_REGISTER_EIP
        eipAddr = self.cpu.getCurrentOpcodeAdd(operSize)
        segVal = self.cpu.getCurrentOpcodeAdd(OP_SIZE_WORD)
        self.stackPushSegId(segId, operSize)
        self.stackPushRegId(eipRegName, operSize)
        self.registers.segWrite(segId, segVal)
        self.registers.regWrite(eipRegName, eipAddr)
        self.switchToProtectedModeIfNeeded()
    def pushaWD(self):
        cdef unsigned char operSize
        cdef unsigned short eaxName, ecxName, edxName, ebxName, espName, ebpName, esiName, ediName
        cdef unsigned long temp
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        espName = self.registers.getWordAsDword(CPU_REGISTER_SP, operSize)
        temp = self.registers.regRead( espName )
        if (not self.cpu.isInProtectedMode() and temp in (7, 9, 11, 13, 15)):
            raise misc.ChemuException(CPU_EXCEPTION_GP)
        eaxName = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        ecxName = self.registers.getWordAsDword(CPU_REGISTER_CX, operSize)
        edxName = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
        ebxName = self.registers.getWordAsDword(CPU_REGISTER_BX, operSize)
        ebpName = self.registers.getWordAsDword(CPU_REGISTER_BP, operSize)
        esiName = self.registers.getWordAsDword(CPU_REGISTER_SI, operSize)
        ediName = self.registers.getWordAsDword(CPU_REGISTER_DI, operSize)
        self.stackPushRegId(eaxName, operSize)
        self.stackPushRegId(ecxName, operSize)
        self.stackPushRegId(edxName, operSize)
        self.stackPushRegId(ebxName, operSize)
        self.stackPushValue(temp, operSize)
        self.stackPushRegId(ebpName, operSize)
        self.stackPushRegId(esiName, operSize)
        self.stackPushRegId(ediName, operSize)
    def popaWD(self):
        cdef unsigned char operSize
        cdef unsigned short eaxName, ecxName, edxName, ebxName, espName, ebpName, esiName, ediName
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        eaxName = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        ecxName = self.registers.getWordAsDword(CPU_REGISTER_CX, operSize)
        edxName = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
        ebxName = self.registers.getWordAsDword(CPU_REGISTER_BX, operSize)
        espName = self.registers.getWordAsDword(CPU_REGISTER_SP, operSize)
        ebpName = self.registers.getWordAsDword(CPU_REGISTER_BP, operSize)
        esiName = self.registers.getWordAsDword(CPU_REGISTER_SI, operSize)
        ediName = self.registers.getWordAsDword(CPU_REGISTER_DI, operSize)
        self.stackPopRegId(ediName, operSize)
        self.stackPopRegId(esiName, operSize)
        self.stackPopRegId(ebpName, operSize)
        self.registers.regAdd(espName, operSize)
        self.stackPopRegId(ebxName, operSize)
        self.stackPopRegId(edxName, operSize)
        self.stackPopRegId(ecxName, operSize)
        self.stackPopRegId(eaxName, operSize)
    def pushfWD(self):
        cdef unsigned char operSize, 
        cdef unsigned short regNameId
        cdef unsigned long value
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regNameId = self.registers.getWordAsDword(CPU_REGISTER_FLAGS, operSize)
        value = self.registers.regRead(regNameId)|2
        self.registers.setEFLAG(0x3000, False) # This is for
        value |= ((self.registers.iopl&3)<<12) # IOPL, Bits 12,13
        if (operSize == OP_SIZE_DWORD):
            value &= 0x00FCFFFF
        self.stackPushValue(value, operSize)
    def popfWD(self):
        cdef unsigned char operSize
        cdef unsigned short regNameId
        cdef unsigned long stackPopValue
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regNameId = self.registers.getWordAsDword(CPU_REGISTER_FLAGS, operSize)
        stackPopValue = self.stackPopValue(operSize)
        self.registers.regWrite( regNameId, stackPopValue )
        self.registers.iopl = (stackPopValue>>12)&3
        self.registers.setEFLAG(2, True)
        self.registers.setEFLAG(0x3000, False) # This is for
        self.registers.setEFLAG((self.registers.iopl&3)<<12, True) # IOPL, Bits 12,13
        self.registers.setEFLAG(0x8, False)
        self.registers.setEFLAG(0x20, False)
        self.registers.setEFLAG(0x8000, False)
        if (self.registers.getEFLAG(FLAG_VM)):
            self.main.exitError("TODO: virtual 8086 mode not supported yet.")
    def stackPopRM(self, tuple rmOperands, unsigned char operSize):
        cdef unsigned long value
        value = self.stackPopValue(operSize)
        self.registers.modRMSave(rmOperands, operSize, value)
    def stackPopSegId(self, unsigned short segId, unsigned char operSize):
        cdef unsigned short value
        value = self.stackPopValue(operSize)&0xffff
        self.registers.segWrite(segId, value)
    def stackPopRegId(self, unsigned short regId, unsigned char operSize):
        cdef unsigned long value
        value = self.stackPopValue(operSize)
        self.registers.regWrite(regId, value)
    cpdef unsigned long stackPopValue(self, unsigned char operSize):
        cdef unsigned char stackAddrSize
        cdef unsigned short stackRegName
        cdef unsigned long stackAddr, data
        stackAddrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_SS)
        stackRegName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        stackAddr = self.registers.regRead(stackRegName)
        data = self.main.mm.mmReadValue(stackAddr, operSize, segId=CPU_SEGMENT_SS, allowOverride=False)
        self.registers.regAdd(stackRegName, operSize)
        return data
    def stackPushSegId(self, unsigned short segId, unsigned char operSize):
        cdef unsigned long value
        value = self.registers.segRead(segId)
        self.stackPushValue(value, operSize)
    def stackPushRegId(self, unsigned short regId, unsigned char operSize):
        cdef unsigned long value
        value = self.registers.regRead(regId)
        self.stackPushValue(value, operSize)
    def stackPushValue(self, unsigned long value, unsigned char operSize):
        cdef unsigned char stackAddrSize
        cdef unsigned short stackRegName
        cdef unsigned long stackAddr
        stackAddrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_SS)
        stackRegName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        stackAddr = self.registers.regRead(stackRegName)
        if (not self.cpu.isInProtectedMode() and stackAddr == 1):
            raise misc.ChemuException(CPU_EXCEPTION_SS)
        stackAddr = self.registers.regSub(stackRegName, operSize)
        self.main.mm.mmWriteValue(stackAddr, value, operSize, segId=CPU_SEGMENT_SS, allowOverride=False)
    def pushIMM8(self):
        cdef unsigned char operSize
        cdef unsigned long bitMask
        cdef unsigned long value
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        bitMask = self.main.misc.getBitMask(operSize)
        value = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, signed=True)&bitMask
        self.stackPushValue(value, operSize)
    def pushIMM16_32(self):
        cdef unsigned char operSize
        cdef unsigned long value
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        value = self.cpu.getCurrentOpcodeAdd(operSize)
        self.stackPushValue(value, operSize)
    def imulR_RM_IMM8(self):
        self.imulR_RM_ImmFunc(True)
    def imulR_RM_IMM16_32(self):
        self.imulR_RM_ImmFunc(False)
    def imulR_RM_ImmFunc(self, unsigned char isImmByte):
        cdef unsigned char operSize
        cdef tuple rmOperands
        cdef long operOp1
        cdef long long operOp2
        cdef unsigned long operSum, bitMask
        cdef unsigned long long temp, doubleBitMask
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        bitMask = self.main.misc.getBitMask(operSize)
        doubleBitMask = self.main.misc.getBitMask(operSize*2)
        rmOperands = self.registers.modRMOperands(operSize)
        operOp1 = self.registers.modRMLoad(rmOperands, operSize, signed=True)
        if (isImmByte):
            operOp2 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, signed=True)
            operOp2 &= bitMask
        else:
            operOp2 = self.cpu.getCurrentOpcodeAdd(operSize, signed=True)
        operSum = (operOp1*operOp2)&bitMask
        temp = (operOp1*operOp2)&doubleBitMask
        self.registers.modRSave(rmOperands, operSize, operSum)
        self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_MUL, signed=True)
        self.registers.setEFLAG( FLAG_CF, temp!=operSum )
        self.registers.setEFLAG( FLAG_OF, temp!=operSum )
    def opcodeGroup1_RM8_IMM8(self): # addOrAdcSbbAndSubXorCmp RM8 IMM8
        cdef unsigned char operSize, operOpcode, operOpcodeId, operOp1, operOp2
        cdef tuple rmOperands
        operSize = OP_SIZE_BYTE
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        operOp1 = self.registers.modRMLoad(rmOperands, operSize)
        operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm8
        if (operOpcodeId == GROUP1_OP_ADD):
            self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_ADD)
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_OR):
            operOp2 = self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_OR)
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP1_OP_ADC):
            self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_ADC)
            self.registers.setFullFlags(operOp1+self.registers.getEFLAG(FLAG_CF), operOp2, operSize, SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_SBB):
            self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_SBB)
            self.registers.setFullFlags(operOp1-self.registers.getEFLAG(FLAG_CF), operOp2, operSize, SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_AND):
            operOp2 = self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_AND)
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP1_OP_SUB):
            self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_SUB)
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_XOR):
            operOp2 = self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_XOR)
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP1_OP_CMP):
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_SUB)
        else:
            self.main.printMsg("opcodeGroup1_RM8_IMM8: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    def opcodeGroup1_RM16_32_IMM8(self): # addOrAdcSbbAndSubXorCmp RM16/32 IMM8
        self.opcodeGroup1_RM16_32_ImmFunc(True)
    def opcodeGroup1_RM16_32_IMM16_32(self): # addOrAdcSbbAndSubXorCmp RM16/32 IMM16/32
        self.opcodeGroup1_RM16_32_ImmFunc(False)
    def opcodeGroup1_RM16_32_ImmFunc(self, unsigned char isImmByte):
        cdef unsigned char operSize, operOpcode, operOpcodeId
        cdef unsigned long bitMask, operOp1, operOp2
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        bitMask = self.main.misc.getBitMask(operSize)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        operOp1 = self.registers.modRMLoad(rmOperands, operSize)
        if (isImmByte):
            operOp2 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, signed=True)&bitMask # operImm8 sign-extended to destsize
        else:
            operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16/32
        if (operOpcodeId == GROUP1_OP_ADD):
            self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_ADD)
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_OR):
            operOp2 = self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_OR)
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP1_OP_ADC):
            self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_ADC)
            self.registers.setFullFlags(operOp1+self.registers.getEFLAG(FLAG_CF), operOp2, operSize, SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_SBB):
            self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_SBB)
            self.registers.setFullFlags(operOp1-self.registers.getEFLAG(FLAG_CF), operOp2, operSize, SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_AND):
            operOp2 = self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_AND)
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP1_OP_SUB):
            self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_SUB)
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_XOR):
            operOp2 = self.registers.modRMSave(rmOperands, operSize, operOp2, valueOp=VALUEOP_XOR)
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP1_OP_CMP):
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_SUB)
        else:
            self.main.printMsg("opcodeGroup1_RM16_32_IMM8: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    def opcodeGroup3_RM8_IMM8(self): # 0/MOV RM8 IMM8
        self.opcodeGroup3_RM_ImmFunc(OP_SIZE_BYTE)
    def opcodeGroup3_RM16_32_IMM16_32(self): # 0/MOV RM16/32 IMM16/32
        cdef unsigned char operSize
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.opcodeGroup3_RM_ImmFunc(operSize)
    def opcodeGroup3_RM_ImmFunc(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId
        cdef tuple rmOperands
        cdef unsigned long operOp2
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.registers.modRMSave(rmOperands, operSize, operOp2)
        else:
            self.main.printMsg("opcodeGroup3_RM16_32_IMM16_32: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    def opcodeGroup0F(self):
        cdef unsigned char operSize, addrSize, operOpcode, bitSize, operOpcodeMod, operOpcodeModId, oldPE, newPE, \
            newCF, newOF, oldOF, count, eaxIsInvalid, 
        cdef unsigned long eaxId, bitMask, bitMaskHalf, base, limit, mmAddr, op1, op2
        cdef tuple rmOperands, rmOperandsOther
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcodeAdd()
        if (operOpcode == 0x00): # LLDT/SLDT LTR/STR VERR/VERW
            if (self.registers.cpl != 0):
                raise misc.ChemuException(CPU_EXCEPTION_GP, 0)
            if (not self.cpu.isInProtectedMode()):
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            operOpcodeMod = self.cpu.getCurrentOpcode()
            operOpcodeModId = (operOpcodeMod>>3)&7
            rmOperands = self.registers.modRMOperands(OP_SIZE_WORD)
            mmAddr = self.registers.getRMValueFull(rmOperands[1][0], addrSize)
            if (operOpcodeModId in (0, 1)): # SLDT/STR
                if (operOpcodeModId == 1): # STR
                    op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD)
                    if (self.registers.lockPrefix or not self.cpu.isInProtectedMode()): 
                        raise misc.ChemuException(CPU_EXCEPTION_UD)
                    self.main.exitError("opcodeGroup0F_00: STR not supported yet.")
                elif (operOpcodeModId == 0): # SLDT
                    base, limit = self.registers.segments.ldt.getBaseLimit()
                    limit &= 0xffff
                    if (operSize == OP_SIZE_WORD):
                        base &= 0xffffff
                    self.main.mm.mmWriteValue(mmAddr, limit, OP_SIZE_WORD)
                    self.main.mm.mmWriteValue(mmAddr+OP_SIZE_WORD, base, OP_SIZE_DWORD)
            elif (operOpcodeModId in (2, 3)): # LLDT/LTR
                if (operOpcodeModId == 2): # LLDT
                    limit = self.main.mm.mmReadValue(mmAddr, OP_SIZE_WORD)
                    base = self.main.mm.mmReadValue(mmAddr+OP_SIZE_WORD, OP_SIZE_DWORD)
                    if (operSize == OP_SIZE_WORD):
                        base &= 0xffffff
                    self.registers.segments.ldt.loadTable(base, limit)
                elif (operOpcodeModId == 3): # LTR
                    op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD)
                    if (self.registers.lockPrefix or not self.cpu.isInProtectedMode()): 
                        raise misc.ChemuException(CPU_EXCEPTION_UD)
                    elif (self.registers.cpl != 0 or op1&0xfff8 == 0):
                        raise misc.ChemuException( CPU_EXCEPTION_GP, 0)
                    elif (not self.registers.segments.isSegPresent(op1)):
                        raise misc.ChemuException( CPU_EXCEPTION_NP, op1)
                    self.main.exitError("opcodeGroup0F_00: LTR not supported yet.")
            elif (operOpcodeModId == 4): # VERR
                op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD)
                self.registers.setEFLAG( FLAG_CF, self.registers.segments.checkReadAllowed(op1, False) )
            elif (operOpcodeModId == 5): # VERW
                op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD)
                self.registers.setEFLAG( FLAG_CF, self.registers.segments.checkWriteAllowed(op1, False) )
            else:
                self.main.printMsg("opcodeGroup0F_00: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise misc.ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x01): # LGDT/LIDT SGDT/SIDT SMSW/LMSW
            if (self.registers.cpl != 0):
                raise misc.ChemuException(CPU_EXCEPTION_GP, 0)
            operOpcodeMod = self.cpu.getCurrentOpcode()
            operOpcodeModId = (operOpcodeMod>>3)&7
            if (operOpcodeModId in (0, 1, 2, 3)): # LGDT/LIDT SGDT/SIDT
                rmOperands = self.registers.modRMOperands(operSize)
            else: # SMSW/LMSW
                rmOperands = self.registers.modRMOperands(OP_SIZE_WORD)
            mmAddr = self.registers.getRMValueFull(rmOperands[1][0], addrSize)
            if (operOpcodeMod == 0xc1): # VMCALL
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc2): # VMLAUNCH
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc3): # VMRESUME
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc4): # VMXOFF
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc8): # MONITOR
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc9): # MWAIT
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xd0): # XGETBV
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xd1): # XSETBV
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xf9): # RDTSCP
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeModId in (0, 1)): # SGDT/SIDT
                if (operOpcodeModId == 0): # SGDT
                    base, limit = self.registers.segments.gdt.getBaseLimit()
                elif (operOpcodeModId == 1): # SIDT
                    base, limit = self.registers.segments.idt.getBaseLimit()
                limit &= 0xffff
                if (operSize == OP_SIZE_WORD):
                    base &= 0xffffff
                self.main.mm.mmWriteValue(mmAddr, limit, OP_SIZE_WORD)
                self.main.mm.mmWriteValue(mmAddr+OP_SIZE_WORD, base, OP_SIZE_DWORD)
            elif (operOpcodeModId in (2, 3)): # LGDT/LIDT
                limit = self.main.mm.mmReadValue(mmAddr, OP_SIZE_WORD)
                base = self.main.mm.mmReadValue(mmAddr+OP_SIZE_WORD, OP_SIZE_DWORD)
                if (operSize == OP_SIZE_WORD):
                    base &= 0xffffff
                if (operOpcodeModId == 2): # LGDT
                    self.registers.segments.gdt.loadTable(base, limit)
                elif (operOpcodeModId == 3): # LIDT
                    self.registers.segments.idt.loadTable(base, limit)
            elif (operOpcodeModId == 4): # SMSW
                op2 = self.registers.regRead(CPU_REGISTER_CR0)&0xffff
                self.registers.modRMSave(rmOperands, OP_SIZE_WORD, op2)
            elif (operOpcodeModId == 6): # LMSW
                if (self.registers.cpl != 0):
                    raise misc.ChemuException( CPU_EXCEPTION_GP, 0 )
                op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD)
                op2 = 0xfffffff0
                if (self.cpu.isInProtectedMode()):
                    op2 |= 1
                self.registers.regAnd(CPU_REGISTER_CR0, op2)
                self.registers.regOr(CPU_REGISTER_CR0, op1&0xf)
                if (not self.cpu.isInProtectedMode() and op1&CR0_FLAG_PE):
                    self.registers.segments.gdt.setGdtLoadedTo = True
                    self.registers.segments.gdt.needFlush = True
            else:
                self.main.printMsg("opcodeGroup0F_01: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise misc.ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x08): # INVD
            if (self.registers.lockPrefix): 
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            if (self.registers.cpl != 0):
                raise misc.ChemuException( CPU_EXCEPTION_GP, 0 )
        elif (operOpcode == 0x09): # WBINVD
            pass
        elif (operOpcode == 0x0b): # UD2
            raise misc.ChemuException( CPU_EXCEPTION_UD )
        elif (operOpcode == 0x20): # MOV R32, CRn
            rmOperands = self.registers.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_CREG)
            self.registers.modRMSave(rmOperands, OP_SIZE_DWORD, self.registers.modRLoad(rmOperands, OP_SIZE_DWORD))
        elif (operOpcode == 0x21): # MOV R32, DRn
            rmOperands = self.registers.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_DREG)
            self.registers.modRMSave(rmOperands, OP_SIZE_DWORD, self.registers.modRLoad(rmOperands, OP_SIZE_DWORD))
        elif (operOpcode == 0x22): # MOV CRn, R32
            rmOperands = self.registers.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_CREG)
            oldPE = self.registers.getFlag( CPU_REGISTER_CR0, CR0_FLAG_PE )
            self.registers.modRSave(rmOperands, OP_SIZE_DWORD, self.registers.modRMLoad(rmOperands, OP_SIZE_DWORD))
            newPE = self.registers.getFlag( CPU_REGISTER_CR0, CR0_FLAG_PE )
            if (oldPE != newPE and rmOperands[2] == CPU_REGISTER_CR0):
                self.registers.segments.gdt.setGdtLoadedTo = newPE
                self.registers.segments.gdt.needFlush = True
            if (self.registers.getFlag( CPU_REGISTER_CR0, CR0_FLAG_PG )):
                self.main.exitError("opcodeGroup0F_22: Paging NOT SUPPORTED yet.")
            elif (self.registers.getFlag( CPU_REGISTER_CR4, CR4_FLAG_VME )):
                self.main.exitError("opcodeGroup0F_22: VME (virtual-8086 mode extension) NOT SUPPORTED yet.")
        elif (operOpcode == 0x23): # MOV DRn, R32
            rmOperands = self.registers.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_DREG)
            self.registers.modRSave(rmOperands, OP_SIZE_DWORD, self.registers.modRMLoad(rmOperands, OP_SIZE_DWORD))
        elif (operOpcode == 0x31): # RDTSC
            if (not self.registers.getFlag( CPU_REGISTER_CR4, CR4_FLAG_TSD ) or \
                 self.registers.cpl == 0 or not self.cpu.isInProtectedMode()):
                self.registers.regWrite( CPU_REGISTER_EAX, self.cpu.cycles&0xffffffff )
                self.registers.regWrite( CPU_REGISTER_EDX, (self.cpu.cycles>>32)&0xffffffff )
            else:
                raise misc.ChemuException( CPU_EXCEPTION_GP, 0 )
        elif (operOpcode == 0x38): # MOVBE
            operOpcodeMod = self.cpu.getCurrentOpcodeAdd()
            rmOperands = self.registers.modRMOperands(operSize)
            if (operOpcodeMod == 0xf0): # MOVBE R16_32, M16_32
                op2 = self.registers.modRMLoad(rmOperands, operSize)
                op2 = self.main.misc.reverseByteOrder(op2, operSize)
                self.registers.modRSave(rmOperands, operSize, op2)
            elif (operOpcodeMod == 0xf1): # MOVBE M16_32, R16_32
                op2 = self.registers.modRLoad(rmOperands, operSize)
                op2 = self.main.misc.reverseByteOrder(op2, operSize)
                self.registers.modRMSave(rmOperands, operSize, op2)
            else:
                self.main.exitError("MOVBE: operOpcodeMod {0:#04x} not in (0xf0, 0xf1)", operOpcodeMod)
        elif (operOpcode >= 0x40 and operOpcode <= 0x4f): # CMOVcc
            self.cmovFunc(self.registers.getCond( operOpcode&0xf ) )
        elif (operOpcode >= 0x80 and operOpcode <= 0x8f):
            if (self.registers.lockPrefix): 
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            self.jumpShort(operSize, self.registers.getCond( operOpcode&0xf ))
        elif (operOpcode >= 0x90 and operOpcode <= 0x9f): # SETcc
            self.setWithCondFunc(self.registers.getCond( operOpcode&0xf ) )
        elif (operOpcode == 0xa0): # PUSH FS
            self.pushSeg(operOpcode)
        elif (operOpcode == 0xa1): # POP FS
            self.popSeg(operOpcode)
        elif (operOpcode == 0xa2): # CPUID
            eaxId = self.registers.regRead( CPU_REGISTER_EAX )
            eaxIsInvalid = (eaxId >= 0x40000000 and eaxId <= 0x4fffffff)
            if ( eaxId == 0x1 ):
                self.registers.regWrite( CPU_REGISTER_EAX, 0x400 )
                self.registers.regWrite( CPU_REGISTER_EBX, 0x0 )
                self.registers.regWrite( CPU_REGISTER_EDX, 0x8010 )
                self.registers.regWrite( CPU_REGISTER_ECX, 0xc00000 )
            #elif ( eaxId == 0x0 or eaxIsInvalid ):
            else:
                if ( not (eaxId == 0x0 or eaxIsInvalid) ):
                    self.main.printMsg("CPUID: eaxId {0:#04x} unknown.", eaxId)
                self.registers.regWrite( CPU_REGISTER_EAX, 0x1 )
                self.registers.regWrite( CPU_REGISTER_EBX, 0x756e6547 )
                self.registers.regWrite( CPU_REGISTER_EDX, 0x49656e69 )
                self.registers.regWrite( CPU_REGISTER_ECX, 0x6c65746e )
            #else:
            #    self.main.exitError("CPUID: eaxId {0:#04x} unknown.", eaxId)
        elif (operOpcode == 0xa3): # BT RM16/32, R16
            rmOperands = self.registers.modRMOperands(operSize)
            op2 = self.registers.modRLoad(rmOperands, operSize)
            self.btFunc(rmOperands, op2)
        elif (operOpcode in (0xa4, 0xa5)): # SHLD
            bitMaskHalf = self.main.misc.getBitMask(operSize, half=True, minus=0)
            bitSize = operSize << 3
            rmOperands = self.registers.modRMOperands(operSize)
            if (operOpcode == 0xa4): # SHLD imm8
                count = self.cpu.getCurrentOpcodeAdd()
            elif (operOpcode == 0xa5): # SHLD CL
                count = self.registers.regRead( CPU_REGISTER_CL )
            else:
                self.main.exitError("group0F::SHLD: operOpcode {0:#04x} unknown.", operOpcode)
                return
            count %= 32
            if (count == 0):
                return
            if (count > bitSize): # bad parameters
                self.main.exitError("group0F: SHLD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).", count, bitSize, operOpcode)
                return
            op1 = self.registers.modRMLoad(rmOperands, operSize) # dest
            oldOF = op1&bitMaskHalf
            op2  = self.registers.modRLoad(rmOperands, operSize) # src
            newCF = self.registers.valGetBit(op1, bitSize-count)!=0
            for i in range(bitSize-1, count-1, -1):
                tmpBit = self.registers.valGetBit(op1, i-count)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            for i in range(count-1, -1, -1):
                tmpBit = self.registers.valGetBit(op2, i-count+bitSize)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            self.registers.modRMSave(rmOperands, operSize, op1)
            if (count == 1):
                newOF = oldOF!=(op1&bitMaskHalf)
                self.registers.setEFLAG( FLAG_OF, newOF )
            self.registers.setEFLAG( FLAG_CF, newCF )
            self.registers.setSZP(op1, operSize)
        elif (operOpcode == 0xa8): # PUSH GS
            self.pushSeg(operOpcode)
        elif (operOpcode == 0xa9): # POP GS
            self.popSeg(operOpcode)
        elif (operOpcode == 0xab): # BTS RM16/32, R16
            rmOperands = self.registers.modRMOperands(operSize)
            op2 = self.registers.modRLoad(rmOperands, operSize)
            self.btsFunc(rmOperands, op2)
        elif (operOpcode in (0xac, 0xad)): # SHRD
            bitMaskHalf = self.main.misc.getBitMask(operSize, half=True, minus=0)
            bitSize = operSize << 3
            rmOperands = self.registers.modRMOperands(operSize)
            if (operOpcode == 0xac): # SHRD imm8
                count = self.cpu.getCurrentOpcodeAdd()
            elif (operOpcode == 0xad): # SHRD CL
                count = self.registers.regRead( CPU_REGISTER_CL )
            else:
                self.main.exitError("group0F::SHRD: operOpcode {0:#04x} unknown.", operOpcode)
                return
            count %= 32
            if (count == 0):
                return
            if (count > bitSize): # bad parameters
                self.main.exitError("group0F: SHRD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).", count, bitSize, operOpcode)
                return
            op1 = self.registers.modRMLoad(rmOperands, operSize) # dest
            oldOF = op1&bitMaskHalf
            op2  = self.registers.modRLoad(rmOperands, operSize) # src
            newCF = self.registers.valGetBit(op1, count-1)!=0
            for i in range(bitSize-count):
                tmpBit = self.registers.valGetBit(op1, i+count)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            for i in range(bitSize-count, bitSize):
                tmpBit = self.registers.valGetBit(op2, i+count-bitSize)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            self.registers.modRMSave(rmOperands, operSize, op1)
            if (count == 1):
                newOF = oldOF!=(op1&bitMaskHalf)
                self.registers.setEFLAG( FLAG_OF, newOF )
            self.registers.setEFLAG( FLAG_CF, newCF )
            self.registers.setSZP(op1, operSize)
        elif (operOpcode == 0xaf): # IMUL R16_32, R/M16_32
            bitMask = self.main.misc.getBitMask(operSize)
            rmOperands = self.registers.modRMOperands(operSize)
            op1 = self.registers.modRLoad(rmOperands, operSize, signed=True)&bitMask
            op2 = self.registers.modRMLoad(rmOperands, operSize, signed=True)&bitMask
            self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_MUL, signed=True)
            op1 = (op1*op2)&bitMask
            self.registers.modRSave(rmOperands, operSize, op1)
        elif (operOpcode == 0xb2): # LSS
            self.lfpFunc(CPU_SEGMENT_SS) # 'load far pointer' function
        elif (operOpcode == 0xb3): # BTR RM16/32, R16
            rmOperands = self.registers.modRMOperands(operSize)
            op2 = self.registers.modRLoad(rmOperands, operSize)
            self.btrFunc(rmOperands, op2)
        elif (operOpcode == 0xb4): # LFS
            self.lfpFunc(CPU_SEGMENT_FS) # 'load far pointer' function
        elif (operOpcode == 0xb5): # LGS
            self.lfpFunc(CPU_SEGMENT_GS) # 'load far pointer' function
        elif (operOpcode == 0xb6): # MOVZX R16_32, R/M8
            bitMask = self.main.misc.getBitMask(operSize)
            rmOperandsOther = self.registers.modRMOperandsResetEip(OP_SIZE_BYTE)
            rmOperands = self.registers.modRMOperands(operSize)
            rmOperands = (rmOperands[0], rmOperandsOther[1], rmOperands[2])
            op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE)
            self.registers.modRSave(rmOperands, operSize, op2)
        elif (operOpcode == 0xb7): # MOVZX R32, R/M16
            rmOperandsOther = self.registers.modRMOperandsResetEip(OP_SIZE_WORD)
            rmOperands = self.registers.modRMOperands(OP_SIZE_DWORD)
            rmOperands = (rmOperands[0], rmOperandsOther[1], rmOperands[2])
            op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD)
            self.registers.modRSave(rmOperands, OP_SIZE_DWORD, op2)
        elif (operOpcode == 0xb8): # POPCNT R16/32 RM16/32
            if (self.registers.lockPrefix or self.registers.repPrefix): 
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            rmOperands = self.registers.modRMOperands(operSize)
            op2 = self.registers.modRMLoad(rmOperands, operSize)
            op1 = bin(op2).count('1')
            self.registers.modRSave(rmOperands, operSize, op1)
            self.registers.clearThisEFLAGS( FLAG_CF | FLAG_PF | FLAG_AF | FLAG_ZF | FLAG_SF | FLAG_OF )
            self.registers.setEFLAG( FLAG_ZF, op2==0 )
        elif (operOpcode == 0xba): # BT/BTS/BTR/BTC RM16/32 IMM8
            operOpcodeMod = self.cpu.getCurrentOpcode()
            operOpcodeModId = (operOpcodeMod>>3)&7
            rmOperands = self.registers.modRMOperands(operSize)
            op2 = self.cpu.getCurrentOpcodeAdd()
            if (operOpcodeModId == 4): # BT
                self.btFunc(rmOperands, op2)
            elif (operOpcodeModId == 5): # BTS
                self.btsFunc(rmOperands, op2)
            elif (operOpcodeModId == 6): # BTR
                self.btrFunc(rmOperands, op2)
            elif (operOpcodeModId == 7): # BTC
                self.btcFunc(rmOperands, op2)
            else:
                self.main.printMsg("opcodeGroup0F_BA: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise misc.ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0xbb): # BTC RM16/32, R16
            rmOperands = self.registers.modRMOperands(operSize)
            op2 = self.registers.modRLoad(rmOperands, operSize)
            self.btcFunc(rmOperands, op2)
        elif (operOpcode == 0xbc): # BSF R16_32, R/M16_32
            rmOperands = self.registers.modRMOperands(operSize)
            op2 = self.registers.modRMLoad(rmOperands, operSize)
            self.registers.setEFLAG( FLAG_ZF, op2==0 )
            op1 = 0
            if (op2 != 0):
                while (not self.registers.valGetBit(op2, op1)):
                    op1 += 1
            self.registers.modRSave(rmOperands, operSize, op1)
        elif (operOpcode == 0xbd): # BSR R16_32, R/M16_32
            rmOperands = self.registers.modRMOperands(operSize)
            op2 = self.registers.modRMLoad(rmOperands, operSize)
            self.registers.setEFLAG( FLAG_ZF, op2==0 )
            self.registers.modRSave(rmOperands, operSize, op2.bit_length()-1)
        elif (operOpcode == 0xbe): # MOVSX R16_32, R/M8
            bitMask = self.main.misc.getBitMask(operSize)
            rmOperandsOther = self.registers.modRMOperandsResetEip(OP_SIZE_BYTE)
            rmOperands = self.registers.modRMOperands(operSize)
            rmOperands = (rmOperands[0], rmOperandsOther[1], rmOperands[2])
            op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE, signed=True)&bitMask
            self.registers.modRSave(rmOperands, operSize, op2)
        elif (operOpcode == 0xbf): # MOVSX R32, R/M16
            rmOperandsOther = self.registers.modRMOperandsResetEip(OP_SIZE_WORD)
            rmOperands = self.registers.modRMOperands(OP_SIZE_DWORD)
            rmOperands = (rmOperands[0], rmOperandsOther[1], rmOperands[2])
            op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD, signed=True)&0xffffffff
            self.registers.modRSave(rmOperands, OP_SIZE_DWORD, op2)
        else:
            self.main.printMsg("opcodeGroup0F: invalid operOpcode. {0:#04x}", operOpcode)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    def opcodeGroupFE(self):
        cdef unsigned char operSize, operOpcode, operOpcodeId
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(rmOperands, OP_SIZE_BYTE)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(rmOperands, OP_SIZE_BYTE)
        else:
            self.main.printMsg("opcodeGroupFE: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    def opcodeGroupFF(self):
        cdef unsigned char operSize, operOpcode, operOpcodeId
        cdef unsigned short eipName, segVal
        cdef unsigned long op1, eipAddr
        cdef tuple rmOperands, rmValue
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(rmOperands, operSize)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(rmOperands, operSize)
        elif (operOpcodeId == 2): # 2/CALL NEAR
            eipName = CPU_REGISTER_EIP
            eipAddr = self.registers.modRMLoad(rmOperands, operSize)
            self.stackPushRegId(eipName, operSize)
            self.registers.regWrite(CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 3): # 3/CALL FAR
            segId = CPU_SEGMENT_CS
            eipName = CPU_REGISTER_EIP
            rmValue = rmOperands[1]
            op1 = self.registers.getRMValueFull(rmValue[0], operSize)
            eipAddr = self.main.mm.mmReadValue(op1, operSize, segId=rmValue[1])
            segVal = self.main.mm.mmReadValue(op1+operSize, OP_SIZE_WORD, segId=rmValue[1])
            self.stackPushSegId(segId, operSize)
            self.stackPushRegId(eipName, operSize)
            self.registers.segWrite(segId, segVal)
            self.registers.regWrite(CPU_REGISTER_EIP, eipAddr)
            self.switchToProtectedModeIfNeeded()
        elif (operOpcodeId == 4): # 4/JMP NEAR
            rmValue = rmOperands[1]
            eipAddr = self.registers.modRMLoad(rmOperands, operSize)
            self.registers.regWrite(CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 5): # 5/JMP FAR
            segId = CPU_SEGMENT_CS
            eipName = CPU_REGISTER_EIP
            rmValue = rmOperands[1]
            op1 = self.registers.getRMValueFull(rmValue[0], operSize)
            eipAddr = self.main.mm.mmReadValue(op1, operSize, segId=rmValue[1])
            segVal = self.main.mm.mmReadValue(op1+operSize, OP_SIZE_WORD, segId=rmValue[1])
            self.registers.segWrite(segId, segVal)
            self.registers.regWrite(CPU_REGISTER_EIP, eipAddr)
            self.switchToProtectedModeIfNeeded()
        elif (operOpcodeId == 6): # 6/PUSH
            op1 = self.registers.modRMLoad(rmOperands, operSize)
            self.stackPushValue(op1, operSize)
        else:
            self.main.printMsg("opcodeGroupFF: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    def incFuncReg(self, unsigned char regId):
        cdef unsigned char origCF, regSize
        cdef unsigned long retValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        regSize = self.registers.regGetSize(regId)
        retValue = self.registers.regAdd(regId, 1)
        self.registers.setFullFlags(retValue-1, 1, regSize, SET_FLAGS_ADD)
        self.registers.setEFLAG(FLAG_CF, origCF)
    def decFuncReg(self, unsigned char regId):
        cdef unsigned char origCF, regSize
        cdef unsigned long retValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        regSize = self.registers.regGetSize(regId)
        retValue = self.registers.regSub(regId, 1)
        self.registers.setFullFlags(retValue+1, 1, regSize, SET_FLAGS_SUB)
        self.registers.setEFLAG(FLAG_CF, origCF)
    def incFuncRM(self, tuple rmOperands, unsigned char rmSize): # rmSize in bits
        cdef unsigned char origCF
        cdef unsigned long retValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        retValue = self.registers.modRMSave(rmOperands, rmSize, 1, valueOp=VALUEOP_ADD)
        self.registers.setFullFlags(retValue-1, 1, rmSize, SET_FLAGS_ADD)
        self.registers.setEFLAG(FLAG_CF, origCF)
    def decFuncRM(self, tuple rmOperands, unsigned char rmSize): # rmSize in bits
        cdef unsigned char origCF
        cdef unsigned long retValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        retValue = self.registers.modRMSave(rmOperands, rmSize, 1, valueOp=VALUEOP_SUB)
        self.registers.setFullFlags(retValue+1, 1, rmSize, SET_FLAGS_SUB)
        self.registers.setEFLAG(FLAG_CF, origCF)
    def incReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regName  = CPU_REGISTER_WORD[self.cpu.opcode&7]
        regName  = self.registers.getWordAsDword(regName, operSize)
        self.incFuncReg(regName)
    def decReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regName  = CPU_REGISTER_WORD[self.cpu.opcode&7]
        regName  = self.registers.getWordAsDword(regName, operSize)
        self.decFuncReg(regName)
    
    
    def pushReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regName  = CPU_REGISTER_WORD[self.cpu.opcode&7]
        regName  = self.registers.getWordAsDword(regName, operSize)
        self.stackPushRegId(regName, operSize)
    def pushSeg(self, short opcode=-1):
        cdef unsigned char operSize
        cdef unsigned short segName
        if (opcode == -1):
            opcode = self.cpu.opcode
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        if (opcode == PUSH_CS):
            segName = CPU_SEGMENT_CS
        elif (opcode == PUSH_DS):
            segName = CPU_SEGMENT_DS
        elif (opcode == PUSH_ES):
            segName = CPU_SEGMENT_ES
        elif (opcode == PUSH_FS):
            segName = CPU_SEGMENT_FS
        elif (opcode == PUSH_GS):
            segName = CPU_SEGMENT_GS
        elif (opcode == PUSH_SS):
            segName = CPU_SEGMENT_SS
        else:
            self.main.exitError("pushSeg: unknown push-opcode: {0:#04x}", opcode)
            return
        self.stackPushSegId(segName, operSize)
    def popReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regName  = CPU_REGISTER_WORD[self.cpu.opcode&7]
        regName  = self.registers.getWordAsDword(regName, operSize)
        self.stackPopRegId(regName, operSize)
    def popSeg(self, short opcode=-1):
        cdef unsigned char operSize
        cdef unsigned short segName
        if (opcode == -1):
            opcode = self.cpu.opcode
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        if (opcode == POP_DS):
            segName = CPU_SEGMENT_DS
        elif (opcode == POP_ES):
            segName = CPU_SEGMENT_ES
        elif (opcode == POP_FS):
            segName = CPU_SEGMENT_FS
        elif (opcode == POP_GS):
            segName = CPU_SEGMENT_GS
        elif (opcode == POP_SS):
            segName = CPU_SEGMENT_SS
        else:
            self.main.exitError("popSeg: unknown pop-opcode: {0:#04x}", opcode)
            return
        self.stackPopSegId(segName, operSize)
    def popRM16_32(self):
        cdef unsigned char operSize, operOpcode, operOpcodeId
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        if (operOpcodeId == 0): # POP
            self.stackPopRM(rmOperands, operSize)
        else:
            self.main.printMsg("popRM16_32: unknown operOpcodeId: {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    def lea(self):
        cdef unsigned char operSize, addrSize
        cdef unsigned long mmAddr
        cdef tuple rmOperands
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(addrSize)
        mmAddr = self.registers.getRMValueFull(rmOperands[1][0], addrSize)
        self.registers.modRSave(rmOperands, operSize, mmAddr)
    def retNear(self, unsigned char imm=0):
        cdef unsigned char operSize, stackAddrSize
        cdef unsigned short eipName, espName
        cdef unsigned long tempEIP
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        stackAddrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_SS)
        eipName = CPU_REGISTER_EIP
        espName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        tempEIP = self.stackPopValue(operSize)
        self.registers.regWrite(eipName, tempEIP)
        if (imm):
            self.registers.regAdd(espName, imm)
    def retFar(self, unsigned char imm=0):
        cdef unsigned char operSize, stackAddrSize
        cdef unsigned short eipName, espName, tempCS
        cdef unsigned long tempEIP
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        stackAddrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_SS)
        eipName = CPU_REGISTER_EIP
        espName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        tempEIP = self.stackPopValue(operSize)
        tempCS = self.stackPopValue(operSize)&0xffff
        self.registers.regWrite(eipName, tempEIP)
        self.registers.segWrite(CPU_SEGMENT_CS, tempCS)
        if (imm):
            self.registers.regAdd(espName, imm)
        self.switchToProtectedModeIfNeeded()
    def retNearImm(self):
        cdef unsigned short imm
        imm = self.cpu.getCurrentOpcodeAdd(numBytes=OP_SIZE_WORD) # imm16
        self.retNear(imm)
    def retFarImm(self):
        cdef unsigned short imm
        imm = self.cpu.getCurrentOpcodeAdd(numBytes=OP_SIZE_WORD) # imm16
        self.retFar(imm)
    def lds(self):
        self.lfpFunc(CPU_SEGMENT_DS) # 'load far pointer' function
    def les(self):
        self.lfpFunc(CPU_SEGMENT_ES) # 'load far pointer' function
    def lfpFunc(self, int segId): # 'load far pointer' function
        cdef unsigned char operSize
        cdef unsigned short segmentAddr
        cdef unsigned long mmAddr, offsetAddr
        cdef tuple rmOperands, rmValue
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        rmValue = rmOperands[1]
        mmAddr = self.registers.getRMValueFull(rmValue[0], operSize)
        offsetAddr = self.main.mm.mmReadValue(mmAddr, operSize, segId=rmValue[1])
        segmentAddr = self.main.mm.mmReadValue(mmAddr+operSize, OP_SIZE_WORD, segId=rmValue[1])
        self.registers.modRSave(rmOperands, operSize, offsetAddr)
        self.registers.segWrite(segId, segmentAddr)
    def xlatb(self):
        cdef unsigned char operSize, addrSize, m8, data
        cdef unsigned short baseReg
        cdef unsigned long baseValue
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        m8 = self.registers.regRead(CPU_REGISTER_AL)
        baseReg = self.registers.getWordAsDword(CPU_REGISTER_BX, addrSize)
        baseValue = self.registers.regRead(baseReg)
        data = self.main.mm.mmReadValue(baseValue+m8, OP_SIZE_BYTE)
        self.registers.regWrite(CPU_REGISTER_AL, data)
    def opcodeGroup2_RM8(self): # testTestaNotNegMulImulDivIdiv RM8
        self.opcodeGroup2_RM_Func(OP_SIZE_BYTE)
    def opcodeGroup2_RM16_32(self): # testTestaNotNegMulImulDivIdiv RM16_32
        cdef unsigned char operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.opcodeGroup2_RM_Func(operSize)
    def opcodeGroup2_RM_Func(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId, operSizeInBits
        cdef unsigned long operOp2, bitMaskHalf, bitMask
        cdef long long sop1, temp, tempmod
        cdef long sop2
        cdef unsigned long long operOp1, doubleBitMask, doubleBitMaskHalf
        cdef tuple rmOperands
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        operOp2 = self.registers.modRMLoad(rmOperands, operSize)
        operSizeInBits = operSize << 3
        bitMask = self.main.misc.getBitMask(operSize)
        bitMaskHalf = self.main.misc.getBitMask(operSize, half=True, minus=0) # 0x8000..
        if (operOpcodeId in (GROUP2_OP_TEST, GROUP2_OP_TEST_ALIAS)):
            operOp1 = self.cpu.getCurrentOpcodeAdd(operSize)
            operOp2 = operOp2&operOp1
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP2_OP_NOT):
            operOp2 = (~operOp2)
            self.registers.modRMSave(rmOperands, operSize, operOp2)
        elif (operOpcodeId == GROUP2_OP_NEG):
            operOp1 = (-operOp2)
            self.registers.modRMSave(rmOperands, operSize, operOp1)
            self.registers.setFullFlags(0, operOp2, operSize, SET_FLAGS_SUB)
            self.registers.setEFLAG(FLAG_CF, operOp2!=0)
        
        
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_MUL):
            operOp1 = self.registers.regRead(CPU_REGISTER_AL)
            operSum = operOp1*operOp2
            self.registers.regWrite(CPU_REGISTER_AX, operSum&0xffff)
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_MUL)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_IMUL):
            sop1 = self.registers.regRead(CPU_REGISTER_AL, signed=True)
            sop2 = self.registers.modRMLoad(rmOperands, operSize, signed=True)
            operSum = sop1*sop2
            self.registers.regWrite(CPU_REGISTER_AX, operSum&0xffff)
            self.registers.setFullFlags(sop1, sop2, operSize, SET_FLAGS_MUL, signed=True)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_DIV):
            op1Word = self.registers.regRead(CPU_REGISTER_AX)
            if (operOp2 == 0):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(op1Word, operOp2)
            if (temp > <unsigned char>bitMask):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            self.registers.regWrite(CPU_REGISTER_AL, temp)
            self.registers.regWrite(CPU_REGISTER_AH, tempmod)
            self.registers.setFullFlags(op1Word, operOp2, operSize, SET_FLAGS_DIV)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_IDIV):
            sop1  = self.registers.regRead(CPU_REGISTER_AX, signed=True)
            sop2  = self.registers.modRMLoad(rmOperands, operSize, signed=True)
            operOp2 = abs(sop2)
            if (operOp2 == 0):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            elif (sop1 >= 0):
                temp, tempmod = divmod(sop1, operOp2)
                if (sop2 != operOp2):
                    temp = -temp
            else:    
                temp, tempmod = divmod(sop1, sop2)
            if ( ((temp >= <unsigned char>bitMaskHalf) or (temp < -(<signed short>bitMaskHalf)))):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            self.registers.regWrite(CPU_REGISTER_AL, temp&0xff)
            self.registers.regWrite(CPU_REGISTER_AH, tempmod&0xff)
            self.registers.setFullFlags(sop1, operOp2, operSize, SET_FLAGS_DIV)
        
        
        
        elif (operOpcodeId == GROUP2_OP_MUL):
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
            operOp1 = self.registers.regRead(eaxReg)
            operSum = operOp1*operOp2
            self.registers.regWrite(edxReg, (operSum>>operSizeInBits)&bitMask)
            self.registers.regWrite(eaxReg, operSum&bitMask)
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_MUL)
        elif (operOpcodeId == GROUP2_OP_IMUL):
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
            sop1 = self.registers.regRead(eaxReg, signed=True)
            sop2 = self.registers.modRMLoad(rmOperands, operSize, signed=True)
            operSum = sop1*sop2
            self.registers.regWrite(edxReg, (operSum>>operSizeInBits)&bitMask)
            self.registers.regWrite(eaxReg, operSum&bitMask)
            self.registers.setFullFlags(sop1, sop2, operSize, SET_FLAGS_MUL, signed=True)
        elif (operOpcodeId == GROUP2_OP_DIV):
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
            operOp1  = self.registers.regRead(eaxReg)
            operOp1 |= self.registers.regRead(edxReg)<<operSizeInBits
            if (operOp2 == 0):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(operOp1, operOp2)
            if (temp > <unsigned long>bitMask):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            self.registers.regWrite(eaxReg, temp&bitMask)
            self.registers.regWrite(edxReg, tempmod&bitMask)
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_DIV)
        elif (operOpcodeId == GROUP2_OP_IDIV):
            doubleBitMaskHalf = self.main.misc.getBitMask(operSize*2, half=True, minus=0) # 0x8000..
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
            operOp1 = self.registers.regRead(edxReg)<<operSizeInBits
            operOp1 |= self.registers.regRead(eaxReg)
            if (operOp1 & doubleBitMaskHalf):
                sop1 = operOp1-doubleBitMaskHalf
                sop1 -= doubleBitMaskHalf
            else:
                sop1 = operOp1
            sop2 = self.registers.modRMLoad(rmOperands, operSize, signed=True)
            operOp2 = abs(sop2)
            if (operOp2 == 0):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(sop1, sop2)
            if ( ((temp >= <unsigned long>bitMaskHalf) or (temp < -(<signed long long>bitMaskHalf))) ):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            self.registers.regWrite(eaxReg, temp&bitMask)
            self.registers.regWrite(edxReg, tempmod&bitMask)
            self.registers.setFullFlags(sop1, operOp2, operSize, SET_FLAGS_DIV)
        else:
            self.main.printMsg("opcodeGroup2_RM_Func: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    def interrupt(self, short intNum=-1, long errorCode=-1, unsigned char hwInt=False):
        cdef unsigned char operSize, inProtectedMode, pythonBiosDone, entryType, entrySize, \
                              entryNeededDPL, entryPresent
        cdef unsigned short segId, entrySegment
        cdef unsigned long entryEip, eflagsClearThis
        entryType, entrySize, entryPresent = IDT_INTR_TYPE_INTERRUPT, OP_SIZE_WORD, True
        inProtectedMode = self.cpu.isInProtectedMode()
        if (inProtectedMode):
            eflagsClearThis = FLAG_TF | FLAG_NT | FLAG_VM | FLAG_RF
        else:
            eflagsClearThis = FLAG_TF | FLAG_AC | FLAG_IF
        segId = CPU_SEGMENT_DS
        if (intNum == -1):
            intNum = self.cpu.getCurrentOpcodeAdd()
        if (inProtectedMode):
            entrySegment, entryEip, entryType, entrySize, entryNeededDPL, entryPresent = self.registers.segments.idt.getEntry(intNum)
        else:
            entrySegment, entryEip = self.registers.segments.idt.getEntryRealMode(intNum)
        self.main.debug("Interrupt: Go Interrupt {0:#04x}. CS: {1:#06x}, (E)IP: {2:#06x}", intNum, entrySegment, entryEip)
        pythonBiosDone = self.main.platform.pythonBios.interrupt(intNum)
        if (pythonBiosDone):
            return
        if (inProtectedMode):
            if (entryType == IDT_INTR_TYPE_INTERRUPT or hwInt):
                eflagsClearThis |= FLAG_IF
            entrySegment = (entrySegment&0xfffc)|(self.registers.cpl&3)
        if (self.registers.cpl != 0):
            self.stackPushSegId(CPU_SEGMENT_SS, entrySize)
            self.stackPushRegId(CPU_REGISTER_ESP, entrySize)
        self.stackPushRegId(CPU_REGISTER_EFLAGS, entrySize)
        self.registers.clearThisEFLAGS(eflagsClearThis)
        self.stackPushSegId(CPU_SEGMENT_CS, entrySize)
        self.stackPushRegId(CPU_REGISTER_EIP, entrySize)
        self.registers.segWrite(CPU_SEGMENT_CS, entrySegment)
        self.registers.regWrite(CPU_REGISTER_EIP, entryEip)
        if (errorCode != -1):
            self.stackPushValue(errorCode, entrySize)
    def into(self):
        if (self.registers.getEFLAG( FLAG_OF )):
            self.interrupt(intNum=CPU_EXCEPTION_OF)
    def int3(self):
        self.interrupt(intNum=CPU_EXCEPTION_BP)
    def iret(self):
        cdef unsigned char operSize, inProtectedMode
        cdef unsigned long tempEFLAGS, EFLAGS, newEIP, eflagsMask, temp
        cdef unsigned short newCS, newEFLAGSreg, SSsel
        inProtectedMode = self.cpu.isInProtectedMode()
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        newEIP = self.stackPopValue(operSize)
        newCS  = self.stackPopValue(operSize)&0xffff
        tempEFLAGS = self.stackPopValue(operSize)
        newEFLAGSreg = CPU_REGISTER_EFLAGS
        EFLAGS = self.registers.regRead(CPU_REGISTER_EFLAGS)
        if (operSize == OP_SIZE_DWORD):
            if (not inProtectedMode):
                tempEFLAGS = ((tempEFLAGS & 0x257fd5) | (EFLAGS & 0x1a0000))
        elif (operSize == OP_SIZE_WORD):
            if (not inProtectedMode):
                newEFLAGSreg = CPU_REGISTER_FLAGS
                tempEFLAGS &= 0xffff
        if (inProtectedMode):
            if (0): # TODO
                pass
            else: # RPL==CPL
                eflagsMask = FLAG_CF | FLAG_PF | FLAG_AF | FLAG_ZF | \
                             FLAG_SF | FLAG_TF | FLAG_DF | FLAG_OF | \
                             FLAG_NT
                if (operSize in (OP_SIZE_DWORD, OP_SIZE_QWORD)):
                    eflagsMask |= FLAG_RF | FLAG_AC | FLAG_ID
                if (self.registers.cpl < self.registers.iopl):
                    eflagsMask |= FLAG_IF
                if (self.registers.cpl == 0):
                    eflagsMask |= FLAG_IOPL
                    if (operSize in (OP_SIZE_DWORD, OP_SIZE_QWORD)):
                        eflagsMask |= FLAG_VIF | FLAG_VIP
                temp = tempEFLAGS
                tempEFLAGS &= ~eflagsMask
                tempEFLAGS |= temp&eflagsMask
        self.registers.regWrite(CPU_REGISTER_EIP, newEIP )
        self.registers.segWrite(CPU_SEGMENT_CS, newCS )
        self.registers.regWrite(newEFLAGSreg, tempEFLAGS )
    def aad(self):
        cdef unsigned char imm8, tempAL, tempAH
        imm8 = self.cpu.getCurrentOpcodeAdd()
        tempAL = self.registers.regRead(CPU_REGISTER_AL)
        tempAH = self.registers.regRead(CPU_REGISTER_AH)
        tempAL = self.registers.regWrite(CPU_REGISTER_AX, ( tempAL + (tempAH * imm8) )&0xff)
        self.registers.setSZP_C0_O0_A0(tempAL, OP_SIZE_BYTE)
    def aam(self):
        cdef unsigned char imm8, tempAL, ALdiv, ALmod
        imm8 = self.cpu.getCurrentOpcodeAdd()
        if (imm8 == 0):
            raise misc.ChemuException(CPU_EXCEPTION_DE)
        tempAL = self.registers.regRead(CPU_REGISTER_AL)
        ALdiv, ALmod = divmod(tempAL, imm8)
        self.registers.regWrite(CPU_REGISTER_AH, ALdiv)
        self.registers.regWrite(CPU_REGISTER_AL, ALmod)
        self.registers.setSZP_C0_O0_A0(ALmod, OP_SIZE_BYTE)
    def aaa(self):
        cdef unsigned char AFflag, tempAL, tempAH
        cdef unsigned short tempAX
        tempAX = self.registers.regRead(CPU_REGISTER_AX)
        tempAL = tempAX&0xff
        tempAH = (tempAX>>8)&0xff
        AFflag = self.registers.getEFLAG(FLAG_AF)
        if (((tempAL&0xf)>9) or AFflag):
            tempAL += 6
            self.registers.setThisEFLAGS(FLAG_AF | FLAG_CF)
            self.registers.regAdd(CPU_REGISTER_AH, 1)
            self.registers.regWrite(CPU_REGISTER_AL, tempAL&0xf)
        else:
            self.registers.clearThisEFLAGS(FLAG_AF | FLAG_CF)
            self.registers.regWrite(CPU_REGISTER_AL, tempAL&0xf)
        self.registers.setSZP_O0(self.registers.regRead(CPU_REGISTER_AL), OP_SIZE_BYTE)
    def aas(self):
        cdef unsigned char AFflag, tempAL, tempAH
        cdef unsigned short tempAX
        tempAX = self.registers.regRead(CPU_REGISTER_AX)
        tempAL = tempAX&0xff
        tempAH = (tempAX>>8)&0xff
        AFflag = self.registers.getEFLAG(FLAG_AF)
        if (((tempAL&0xf)>9) or AFflag):
            tempAL -= 6
            self.registers.setThisEFLAGS(FLAG_AF | FLAG_CF)
            self.registers.regSub(CPU_REGISTER_AH, 1)
            self.registers.regWrite(CPU_REGISTER_AL, tempAL&0xf)
        else:
            self.registers.clearThisEFLAGS(FLAG_AF | FLAG_CF)
            self.registers.regWrite(CPU_REGISTER_AL, tempAL&0xf)
        self.registers.setSZP_O0(self.registers.regRead(CPU_REGISTER_AL), OP_SIZE_BYTE)
    def daa(self):
        cdef unsigned char old_AL, old_AF, old_CF
        old_AL = self.registers.regRead(CPU_REGISTER_AL)
        old_AF = self.registers.getEFLAG(FLAG_AF)
        old_CF = self.registers.getEFLAG(FLAG_CF)
        self.registers.setEFLAG(FLAG_CF, False)
        if (((old_AL&0xf)>9) or old_AF):
            self.registers.regWrite(CPU_REGISTER_AL, old_AL+6)
            self.registers.setEFLAG(FLAG_CF, old_CF or (old_AL+6>0xff))
            self.registers.setEFLAG(FLAG_AF, True)
        else:
            self.registers.setEFLAG(FLAG_AF, False)
        if ((old_AL > 0x99) or old_CF):
            self.registers.regAdd(CPU_REGISTER_AL, 0x60)
            self.registers.setEFLAG(FLAG_CF, True)
        else:
            self.registers.setEFLAG(FLAG_CF, False)
        self.registers.setSZP_O0(self.registers.regRead(CPU_REGISTER_AL), OP_SIZE_BYTE)
    def das(self):
        cdef unsigned char old_AL, old_AF, old_CF
        old_AL = self.registers.regRead(CPU_REGISTER_AL)
        old_AF = self.registers.getEFLAG(FLAG_AF)
        old_CF = self.registers.getEFLAG(FLAG_CF)
        self.registers.setEFLAG(FLAG_CF, False)
        if (((old_AL&0xf)>9) or old_AF):
            self.registers.regWrite(CPU_REGISTER_AL, old_AL-6)
            self.registers.setEFLAG(FLAG_CF, old_CF or (old_AL-6<0))
            self.registers.setEFLAG(FLAG_AF, True)
        else:
            self.registers.setEFLAG(FLAG_AF, False)
        if ((old_AL > 0x99) or old_CF):
            self.registers.regSub(CPU_REGISTER_AL, 0x60)
            self.registers.setEFLAG(FLAG_CF, True)
        self.registers.setSZP_O0(self.registers.regRead(CPU_REGISTER_AL), OP_SIZE_BYTE)
    def cbw_cwde(self):
        cdef unsigned char operSize
        cdef unsigned short op2
        cdef unsigned long bitMask
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        bitMask = self.main.misc.getBitMask(operSize)
        if (operSize == OP_SIZE_WORD):
            op2 = self.registers.regRead(CPU_REGISTER_AL)
            if (op2&0x80):
                self.registers.regWrite(CPU_REGISTER_AH, 0xff)
            else:
                self.registers.regWrite(CPU_REGISTER_AH, 0x00)
        elif (operSize == OP_SIZE_DWORD):
            op2 = self.registers.regRead(CPU_REGISTER_AX)
            if (op2&0x8000):
                self.registers.regWrite(CPU_REGISTER_EAX, 0xffff0000|op2)
            else:
                self.registers.regWrite(CPU_REGISTER_EAX, op2)
        else:
            self.main.exitError("cbw_cwde: operSize {0:d} not in (OP_SIZE_WORD, OP_SIZE_DWORD))", operSize)
    def cwd_cdq(self):
        cdef unsigned char operSize
        cdef unsigned short eaxReg, edxReg
        cdef unsigned long bitMask, bitMaskHalf, op2
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        bitMask = self.main.misc.getBitMask(operSize)
        bitMaskHalf = self.main.misc.getBitMask(operSize, half=True, minus=0)
        eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
        op2 = self.registers.regRead(eaxReg)
        if (op2&bitMaskHalf):
            self.registers.regWrite(edxReg, bitMask)
        else:
            self.registers.regWrite(edxReg, 0)
    def shlFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char newCF, newOF
        cdef unsigned long bitMask, bitMaskHalf, dest
        bitMask = self.main.misc.getBitMask(operSize)
        bitMaskHalf = self.main.misc.getBitMask(operSize, half=True, minus=0)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        count = count&0x1f
        if (count == 0):
            newCF = False
        else:
            newCF = ((dest<<(count-1))&bitMaskHalf)!=0
        dest <<= count
        dest &= bitMask
        self.registers.modRMSave(rmOperands, operSize, dest)
        if (count == 0):
            return
        elif (count == 1):
            newOF = ( ((dest&bitMaskHalf)!=0)^newCF )
            self.registers.setEFLAG( FLAG_OF, newOF )
        else:
            self.registers.setEFLAG( FLAG_OF, False )
        self.registers.setEFLAG( FLAG_CF, newCF )
        self.registers.setSZP(dest, operSize)
        
    
    
    
    def sarFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char newCF
        cdef unsigned long bitMask
        cdef long long dest
        bitMask = self.main.misc.getBitMask(operSize)
        dest = self.registers.modRMLoad(rmOperands, operSize, signed=True)
        count = count&0x1f
        if (count == 0):
            newCF = ((dest)&1)
        else:
            newCF = ((dest>>(count-1))&1)
        dest >>= count
        dest &= bitMask
        self.registers.modRMSave(rmOperands, operSize, dest)
        if (count == 0):
            return
        elif (count == 1):
            self.registers.setEFLAG( FLAG_OF, False )
        self.registers.setEFLAG( FLAG_CF, newCF )
        self.registers.setSZP(dest, operSize)
        
    
    
    
    def shrFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char newCF_OF
        cdef unsigned long bitMask, bitMaskHalf, dest, tempDest
        bitMask = self.main.misc.getBitMask(operSize)
        bitMaskHalf = self.main.misc.getBitMask(operSize, half=True, minus=0)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        tempDest = dest
        count = count&0x1f
        if (count == 0):
            newCF_OF = ((dest)&1)
        else:
            newCF_OF = ((dest>>(count-1))&1)
        dest >>= count
        self.registers.modRMSave(rmOperands, operSize, dest)
        if (count == 0):
            return
        self.registers.setEFLAG( FLAG_CF, newCF_OF )
        newCF_OF = ((tempDest)&bitMaskHalf)!=0
        self.registers.setEFLAG( FLAG_OF, newCF_OF )
        self.registers.setSZP(dest, operSize)
        
    
    
    
    def rclFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char tempCF_OF, newCF
        cdef unsigned long bitMask, bitMaskHalf, dest
        bitMask = self.main.misc.getBitMask(operSize)
        bitMaskHalf = self.main.misc.getBitMask(operSize, half=True, minus=0)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        count = count&0x1f
        if (operSize == OP_SIZE_BYTE):
            count %= 9
        elif (operSize == OP_SIZE_WORD):
            count %= 17
        newCF = self.registers.getEFLAG( FLAG_CF )
        for i in range(count):
            tempCF_OF = (dest&bitMaskHalf)!=0
            dest = (dest<<1)|newCF
            newCF = tempCF_OF
        self.registers.modRMSave(rmOperands, operSize, dest)
        if (count == 0):
            return
        tempCF_OF = ( ((dest&bitMaskHalf)!=0)^newCF )
        self.registers.setEFLAG( FLAG_OF, tempCF_OF )
        self.registers.setEFLAG( FLAG_CF, newCF )
        
    
    
    
    
    
    
    def rcrFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char tempCF_OF, newCF
        cdef unsigned long bitMask, bitMaskHalf, dest
        bitMask = self.main.misc.getBitMask(operSize)
        bitMaskHalf = self.main.misc.getBitMask(operSize, half=True, minus=0)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        count = count&0x1f
        newCF = self.registers.getEFLAG( FLAG_CF )
        if (operSize == OP_SIZE_BYTE):
            count %= 9
        elif (operSize == OP_SIZE_WORD):
            count %= 17
        
        if (count == 0):
            return
        tempCF_OF = ( ((dest&bitMaskHalf)!=0)^newCF )
        self.registers.setEFLAG( FLAG_OF, tempCF_OF )
        
        for i in range(count):
            tempCF_OF = (dest&1)!=0
            dest = (dest >> 1) | (newCF * bitMaskHalf)
            newCF = tempCF_OF
        dest &= bitMask
        
        self.registers.modRMSave(rmOperands, operSize, dest)
        self.registers.setEFLAG( FLAG_CF, newCF )
    
    
    
    
    def rolFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char tempCF_OF, newCF
        cdef unsigned long bitMask, bitMaskHalf, dest
        bitMask = self.main.misc.getBitMask(operSize)
        bitMaskHalf = self.main.misc.getBitMask(operSize, half=True, minus=0)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        
        if ((count & 0x1f) > 0):
            count = count%(operSize<<3)
            
            for i in range(count):
                tempCF_OF = (dest&bitMaskHalf)!=0
                dest = (dest << 1) | tempCF_OF
            
            self.registers.modRMSave(rmOperands, operSize, dest)
            
            if (count == 0):
                return
            newCF = dest&1
            self.registers.setEFLAG( FLAG_CF, newCF )
            tempCF_OF = ( ((dest&bitMaskHalf)!=0)^newCF )
            self.registers.setEFLAG( FLAG_OF, tempCF_OF )
            
    
    
    
    
    def rorFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char tempCF_OF, newCF_M1
        cdef unsigned long bigMask, bitMaskHalf, dest, destM1
        bitMask = self.main.misc.getBitMask(operSize)
        bitMaskHalf = self.main.misc.getBitMask(operSize, half=True, minus=0)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        destM1 = dest
        
        if ((count & 0x1f) > 0):
            count = count%(operSize<<3)
            
            for i in range(count):
                destM1 = dest
                tempCF_OF = destM1&1
                dest = (destM1 >> 1) | (tempCF_OF * bitMaskHalf)
            
            self.registers.modRMSave(rmOperands, operSize, dest)
            
            if (count == 0):
                return
            tempCF_OF = (dest&bitMaskHalf)!=0
            newCF_M1 = (destM1&bitMaskHalf)!=0
            self.registers.setEFLAG( FLAG_CF, tempCF_OF )
            tempCF_OF = ( tempCF_OF ^ newCF_M1 )
            self.registers.setEFLAG( FLAG_OF, tempCF_OF )
            
    
    
    
    
    
    
    def opcodeGroup4_RM8_1(self): # rolRorRclRcrShlSalShrSar RM8
        self.opcodeGroup4_RM_1_Func(OP_SIZE_BYTE)
    def opcodeGroup4_RM16_32_1(self): # rolRorRclRcrShlSalShrSar RM16_32
        cdef unsigned char operSize
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.opcodeGroup4_RM_1_Func(operSize)
    def opcodeGroup4_RM_1_Func(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId
        cdef tuple rmOperands
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        if (operOpcodeId in (GROUP4_OP_SHL_SAL, GROUP4_OP_SHL_SAL_ALIAS)):
            self.shlFunc(rmOperands, operSize, 1)
        elif (operOpcodeId == GROUP4_OP_SAR):
            self.sarFunc(rmOperands, operSize, 1)
        elif (operOpcodeId == GROUP4_OP_SHR):
            self.shrFunc(rmOperands, operSize, 1)
        elif (operOpcodeId == GROUP4_OP_RCL):
            self.rclFunc(rmOperands, operSize, 1)
        elif (operOpcodeId == GROUP4_OP_RCR):
            self.rcrFunc(rmOperands, operSize, 1)
        elif (operOpcodeId == GROUP4_OP_ROL):
            self.rolFunc(rmOperands, operSize, 1)
        elif (operOpcodeId == GROUP4_OP_ROR):
            self.rorFunc(rmOperands, operSize, 1)
        else:
            self.main.printMsg("opcodeGroup4_RM16_32_1: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    def opcodeGroup4_RM8_CL(self): # rolRorRclRcrShlSalShrSar RM8
        self.opcodeGroup4_RM_CL_Func(OP_SIZE_BYTE)
    def opcodeGroup4_RM16_32_CL(self): # rolRorRclRcrShlSalShrSar RM16_32
        cdef unsigned char operSize
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.opcodeGroup4_RM_CL_Func(operSize)
    def opcodeGroup4_RM_CL_Func(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId, count
        cdef tuple rmOperands
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        count = self.registers.regRead(CPU_REGISTER_CL)
        if (operOpcodeId in (GROUP4_OP_SHL_SAL, GROUP4_OP_SHL_SAL_ALIAS)):
            self.shlFunc(rmOperands, operSize, count )
        elif (operOpcodeId == GROUP4_OP_SAR):
            self.sarFunc(rmOperands, operSize, count )
        elif (operOpcodeId == GROUP4_OP_SHR):
            self.shrFunc(rmOperands, operSize, count )
        elif (operOpcodeId == GROUP4_OP_RCL):
            self.rclFunc(rmOperands, operSize, count )
        elif (operOpcodeId == GROUP4_OP_RCR):
            self.rcrFunc(rmOperands, operSize, count )
        elif (operOpcodeId == GROUP4_OP_ROL):
            self.rolFunc(rmOperands, operSize, count )
        elif (operOpcodeId == GROUP4_OP_ROR):
            self.rorFunc(rmOperands, operSize, count )
        else:
            self.main.printMsg("opcodeGroup4_RM16_32_1: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    def opcodeGroup4_RM8_IMM8(self): # rolRorRclRcrShlSalShrSar RM8
        self.opcodeGroup4_RM_IMM8_Func(OP_SIZE_BYTE)
    def opcodeGroup4_RM16_32_IMM8(self): # rolRorRclRcrShlSalShrSar RM16_32
        cdef unsigned char operSize
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.opcodeGroup4_RM_IMM8_Func(operSize)
    def opcodeGroup4_RM_IMM8_Func(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId, count
        cdef tuple rmOperands
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        count = self.cpu.getCurrentOpcodeAdd()
        if (operOpcodeId in (GROUP4_OP_SHL_SAL, GROUP4_OP_SHL_SAL_ALIAS)):
            self.shlFunc(rmOperands, operSize, count )
        elif (operOpcodeId == GROUP4_OP_SAR):
            self.sarFunc(rmOperands, operSize, count )
        elif (operOpcodeId == GROUP4_OP_SHR):
            self.shrFunc(rmOperands, operSize, count )
        elif (operOpcodeId == GROUP4_OP_RCL):
            self.rclFunc(rmOperands, operSize, count )
        elif (operOpcodeId == GROUP4_OP_RCR):
            self.rcrFunc(rmOperands, operSize, count )
        elif (operOpcodeId == GROUP4_OP_ROL):
            self.rolFunc(rmOperands, operSize, count )
        elif (operOpcodeId == GROUP4_OP_ROR):
            self.rorFunc(rmOperands, operSize, count )
        else:
            self.main.printMsg("opcodeGroup4_RM16_32_1: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    def sahf(self):
        cdef unsigned char ahVal, orThis
        ahVal = self.registers.regRead( CPU_REGISTER_AH )
        self.registers.clearThisEFLAGS( FLAG_CF | FLAG_PF | \
            FLAG_AF | FLAG_ZF | FLAG_SF )
        orThis = 0x2
        orThis |= ahVal & FLAG_CF
        orThis |= ahVal & FLAG_PF
        orThis |= ahVal & FLAG_AF
        orThis |= ahVal & FLAG_ZF
        orThis |= ahVal & FLAG_SF
        self.registers.regOr( CPU_REGISTER_FLAGS, orThis )
    def lahf(self):
        cdef unsigned char newAH, flagsByte
        newAH = 0x2
        flagsByte = self.registers.regRead( CPU_REGISTER_FLAGS )&0xff
        newAH |= flagsByte & FLAG_CF
        newAH |= flagsByte & FLAG_PF
        newAH |= flagsByte & FLAG_AF
        newAH |= flagsByte & FLAG_ZF
        newAH |= flagsByte & FLAG_SF
        self.registers.regWrite( CPU_REGISTER_AH, newAH )
    def xchgFuncReg(self, unsigned short regName, unsigned short regName2):
        cdef unsigned long regValue, regValue2
        regValue, regValue2 = self.registers.regRead( regName ), self.registers.regRead( regName2 )
        self.registers.regWrite( regName, regValue2 )
        self.registers.regWrite( regName2, regValue )
    ##### both, XCHG AX, AX == NOP is opcode 0x90, so don't use this (xchg) for it (opcode 0x90)
    def xchgReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName, regName2
        operSize  = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regName   = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        regName2  = self.registers.getWordAsDword(CPU_REGISTER_WORD[self.cpu.opcode&7], operSize)
        self.xchgFuncReg(regName, regName2)
    def xchgR8_RM8(self):
        self.xchgR_RM_Func(OP_SIZE_BYTE)
    def xchgR16_32_RM16_32(self):
        cdef unsigned char operSize
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.xchgR_RM_Func(operSize)
    def xchgR_RM_Func(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        self.registers.modRMSave(rmOperands, operSize, op1)
        self.registers.modRSave(rmOperands, operSize, op2)
    def enter(self):
        cdef unsigned char operSize, stackSize, nestingLevel
        cdef unsigned short sizeOp, espNameStack, ebpNameStack
        cdef unsigned long frameTemp, temp
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        stackSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_SS)
        espNameStack = self.registers.getWordAsDword(CPU_REGISTER_SP, stackSize)
        ebpNameStack = self.registers.getWordAsDword(CPU_REGISTER_BP, stackSize)
        sizeOp = self.cpu.getCurrentOpcodeAdd(OP_SIZE_WORD)
        nestingLevel = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE)
        nestingLevel %= 32
        self.stackPushRegId(ebpNameStack, stackSize)
        frameTemp = self.registers.regRead(espNameStack)
        if (nestingLevel > 1):
            for i in range(nestingLevel-1):
                self.registers.regSub(ebpNameStack, operSize)
                temp = self.main.mm.mmReadValue(self.registers.regRead(ebpNameStack), operSize, segId=CPU_SEGMENT_SS, allowOverride=False)
                self.stackPushValue(temp, operSize)
        if (nestingLevel >= 1):
            self.stackPushValue(frameTemp, operSize)
        self.registers.regWrite(ebpNameStack, frameTemp)
        self.registers.regSub(espNameStack, sizeOp)
    def leave(self):
        cdef unsigned char operSize, stackSize
        cdef unsigned short ebpNameOper, espNameStack, ebpNameStack
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        stackSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_SS)
        ebpNameOper = self.registers.getWordAsDword(CPU_REGISTER_BP, operSize)
        espNameStack = self.registers.getWordAsDword(CPU_REGISTER_SP, stackSize)
        ebpNameStack = self.registers.getWordAsDword(CPU_REGISTER_BP, stackSize)
        self.registers.regWrite(espNameStack, self.registers.regRead(ebpNameStack) )
        self.stackPopRegId( ebpNameOper, operSize )
    def cmovFunc(self, unsigned char cond): # R16, R/M 16; R32, R/M 32
        self.movR16_32_RM16_32(cond)
    def setWithCondFunc(self, unsigned char cond): # if cond==True set 1, else 0
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE)
        self.registers.modRMSave(rmOperands, OP_SIZE_BYTE, cond!=0)
    def arpl(self):
        cdef unsigned char operSize
        cdef unsigned short op1, op2
        cdef tuple rmOperands
        if (not self.cpu.isInProtectedMode()):
            raise misc.ChemuException(CPU_EXCEPTION_UD)
        operSize = OP_SIZE_WORD
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        if (op1 < op2):
            self.registers.setEFLAG( FLAG_ZF, True )
            self.registers.modRMSave(rmOperands, operSize, (op1&0xfffc)|(op2&3) )
        else:
            self.registers.setEFLAG( FLAG_ZF, False )
    def bound(self):
        cdef unsigned char operSize, addrSize
        cdef unsigned long returnInt
        cdef long index, lowerBound, upperBound
        cdef tuple rmOperands, rmValue
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        rmValue = rmOperands[1]
        index = self.registers.modRLoad(rmOperands, operSize, signed=True)
        returnInt = self.getRMValueFull(rmValue[0], addrSize)
        lowerBound = self.main.mm.mmReadValue(returnInt, operSize, segId=rmValue[1], signed=True)
        upperBound = self.main.mm.mmReadValue(returnInt+operSize, operSize, segId=rmValue[1], signed=True)
        if (index < lowerBound or index > upperBound+operSize):
            raise misc.ChemuException(CPU_EXCEPTION_BR)
    def btFunc(self, tuple rmOperands, unsigned long offset, unsigned char newValType=BT_NONE):
        cdef unsigned char operSize, addrSize, operSizeInBits, state
        cdef unsigned long value, address
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        operSizeInBits = operSize << 3
        address = 0
        if (rmOperands[0] == 3): # register operand
            offset %= operSizeInBits
            value = self.registers.modRLoad(rmOperands, operSize)
            state = self.registers.valGetBit(value, offset)
            self.registers.setEFLAG( FLAG_CF, state )
        else: # memory operand
            address = self.registers.getRMValueFull(rmOperands[1][0], addrSize)
            address += (operSize * (offset // operSizeInBits))
            value = self.main.mm.mmReadValue(address, operSize, segId=rmOperands[1][1])
            state = self.registers.valGetBit(value, offset)
            self.registers.setEFLAG( FLAG_CF, state )
        if (newValType != BT_NONE):
            if (newValType == BT_NOT):
                state = not state
            elif (newValType == BT_SET):
                state = True
            elif (newValType == BT_CLEAR):
                state = False
            else:
                self.main.exitError("btFunc: unknown newValType: {0:d}", newValType)
            value = self.registers.valSetBit(value, offset, state)
            if (rmOperands[0] == 3): # register operand
                self.registers.modRSave(rmOperands, operSize, value)
            else: # memory operands
                self.main.mm.mmWriteValue(address, value, operSize, segId=rmOperands[1][1])
    def btcFunc(self, tuple rmOperands, unsigned long offset):
        self.btFunc(rmOperands, offset, BT_NOT)
    def btrFunc(self, tuple rmOperands, unsigned long offset):
        self.btFunc(rmOperands, offset, BT_CLEAR)
    def btsFunc(self, tuple rmOperands, unsigned long offset):
        self.btFunc(rmOperands, offset, BT_SET)
    # end of opcodes



