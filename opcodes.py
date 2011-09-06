import registers, misc

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

class Opcodes:
    def __init__(self, main, cpu):
        self.main = main
        self.cpu = cpu
        self.registers = self.cpu.registers
        self.opcodeList = {0x00: self.addRM8_R8, 0x01: self.addRM16_32_R16_32, 0x02: self.addR8_RM8, 0x03: self.addR16_32_RM16_32,
                           0x04: self.addAL_IMM8, 0x05: self.addAX_EAX_IMM16_32,
                           0x06: self.pushES, 0x07: self.popES,
                           
                           0x08: self.orRM8_R8, 0x09: self.orRM16_32_R16_32, 0x0a: self.orR8_RM8, 0x0b: self.orR16_32_RM16_32,
                           0x0c: self.orAL_IMM8, 0x0d: self.orAX_EAX_IMM16_32,
                           
                           
                           0x0e: self.pushCS, 0x0f: self.opcodeGroup0F,
                           0x10: self.adcRM8_R8, 0x11: self.adcRM16_32_R16_32, 0x12: self.adcR8_RM8, 0x13: self.adcR16_32_RM16_32,
                           0x14: self.adcAL_IMM8, 0x15: self.adcAX_EAX_IMM16_32,
                           0x16: self.pushSS, 0x17: self.popSS,
                           0x18: self.sbbRM8_R8, 0x19: self.sbbRM16_32_R16_32,
                           0x1a: self.sbbR8_RM8, 0x1b: self.sbbR16_32_RM16_32,
                           0x1c: self.sbbAL_IMM8, 0x1d: self.sbbAX_EAX_IMM16_32,
                           0x1e: self.pushDS, 0x1f: self.popDS,
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
                           0x40: self.incAX, 0x41: self.incCX, 0x42: self.incDX, 0x43: self.incBX,
                           0x44: self.incSP, 0x45: self.incBP, 0x46: self.incSI, 0x47: self.incDI,
                           0x48: self.decAX, 0x49: self.decCX, 0x4a: self.decDX, 0x4b: self.decBX,
                           0x4c: self.decSP, 0x4d: self.decBP, 0x4e: self.decSI, 0x4f: self.decDI,
                           
                           0x50: self.pushAX, 0x51: self.pushCX, 0x52: self.pushDX, 0x53: self.pushBX,
                           0x54: self.pushSP, 0x55: self.pushBP, 0x56: self.pushSI, 0x57: self.pushDI,
                           0x58: self.popAX, 0x59: self.popCX, 0x5a: self.popDX, 0x5b: self.popBX,
                           0x5c: self.popSP, 0x5d: self.popBP, 0x5e: self.popSI, 0x5f: self.popDI,
                           0x60: self.pushaWD, 0x61: self.popaWD,
                           0x68: self.pushIMM16_32, 0x69: self.imulR_RM_IMM16_32,
                           0x6a: self.pushIMM8, 0x6b: self.imulR_RM_IMM8,
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
                           0x91: self.xchgCX, 0x92: self.xchgDX, 0x93: self.xchgBX, 0x94: self.xchgSP, 
                           0x95: self.xchgBP, 0x96: self.xchgSI, 0x97: self.xchgDI,
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
                           0xb6: self.movImm8ToR8, 0xb7: self.movImm8ToR8, 0xb8: self.movImm16_32ToR16_32,
                           0xb9: self.movImm16_32ToR16_32, 0xba: self.movImm16_32ToR16_32, 0xbb: self.movImm16_32ToR16_32,
                           0xbc: self.movImm16_32ToR16_32, 0xbd: self.movImm16_32ToR16_32, 0xbe: self.movImm16_32ToR16_32,
                           0xbf: self.movImm16_32ToR16_32,
                           0xc0: self.opcodeGroup4_RM8_IMM8, 0xc1: self.opcodeGroup4_RM16_32_IMM8,
                           0xc2: self.retNearImm, 0xc3: self.retNear,
                           0xc4: self.les, 0xc5: self.lds,
                           0xc6: self.opcodeGroup3_RM8_IMM8, 0xc7: self.opcodeGroup3_RM16_32_IMM16_32,
                           0xc8: self.enter, 0xc9: self.leave,
                           0xca: self.retFarImm,  0xcb: self.retFar, 0xcd: self.interrupt, 
                           0xce: self.into, 0xcf: self.iret,
                           0xd0: self.opcodeGroup4_RM8_1, 0xd1: self.opcodeGroup4_RM16_32_1,
                           0xd2: self.opcodeGroup4_RM8_CL, 0xd3: self.opcodeGroup4_RM16_32_CL,
                           0xd4: self.aam, 0xd5: self.aad, 0xd7: self.xlatb,
                           0xe0: self.loopne, 0xe1: self.loope, 0xe2: self.loop,
                           0xe3: self.jcxzShort, 0xe4: self.inAlImm8, 0xe5: self.inAxEaxImm8, 0xe6: self.outImm8Al, 0xe7: self.outImm8AxEax, 0xe8: self.callNearRel16_32, 0xe9: self.jumpShortRelativeWordDWord,
                           0xea: self.jumpFarAbsolutePtr, 0xeb: self.jumpShortRelativeByte, 0xec: self.inAlDx, 0xed: self.inAxEaxDx, 0xee: self.outDxAl, 0xef: self.outDxAxEax,
                           0xf0: self.opcodeGroupF0, 0xf4: self.hlt, 0xf5: self.cmc,
                           0xf6: self.opcodeGroup2_RM8, 0xf7: self.opcodeGroup2_RM16_32,
                           0xf8: self.clc, 0xf9: self.stc,
                           0xfa: self.cli, 0xfb: self.sti, 0xfc: self.cld, 0xfd: self.std,
                           0xfe: self.opcodeGroupFE, 0xff: self.opcodeGroupFF}
    def cli(self):
        self.registers.setEFLAG(registers.FLAG_IF, False)
    def sti(self):
        self.registers.setEFLAG(registers.FLAG_IF, True)
    def cld(self):
        self.registers.setEFLAG(registers.FLAG_DF, False)
    def std(self):
        self.registers.setEFLAG(registers.FLAG_DF, True)
    def clc(self):
        self.registers.setEFLAG(registers.FLAG_CF, False)
    def stc(self):
        self.registers.setEFLAG(registers.FLAG_CF, True)
    def cmc(self):
        self.registers.setEFLAG(registers.FLAG_CF, not self.registers.getEFLAG(registers.FLAG_CF) )
    def hlt(self):
        self.cpu.cpuHalted = True
    def nop(self):
        pass
    def jumpFarAbsolutePtr(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        eip = self.cpu.getCurrentOpcodeAddEip()
        cs = self.cpu.getCurrentOpcodeAdd(misc.OP_SIZE_16BIT)
        self.registers.regWrite(registers.CPU_SEGMENT_CS, cs)
        self.registers.regWrite(registers.CPU_REGISTER_EIP, eip)
        self.registers.segments.gdt.flushed = True
    def jumpShortRelativeByte(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        self.jumpShort(1)
    def jumpShortRelativeWordDWord(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        offsetSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        self.jumpShort(offsetSize)
    def loop(self):
        self.loopFunc(OPCODE_LOOP)
    def loope(self):
        self.loopFunc(OPCODE_LOOPE)
    def loopne(self):
        self.loopFunc(OPCODE_LOOPNE)
    def loopFunc(self, loopType):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        countReg = registers.CPU_REGISTER_CX
        eipReg   = registers.CPU_REGISTER_IP
        cond = False
        rel8 = self.cpu.getCurrentOpcodeAdd(1, signed=True)
        if (operSize == misc.OP_SIZE_32BIT):
            eipReg = registers.CPU_REGISTER_EIP
        if (addrSize == misc.OP_SIZE_32BIT):
            countReg = registers.CPU_REGISTER_ECX
        self.registers.regSub(countReg, 1)
        count = self.registers.regRead(countReg)
        if (loopType != OPCODE_LOOP):
            if (loopType == OPCODE_LOOPE):
                if (self.registers.getEFLAG(registers.FLAG_ZF) and count != 0):
                    cond = True
            elif (loopType == OPCODE_LOOPNE):
                if ((not self.registers.getEFLAG(registers.FLAG_ZF)) and count != 0):
                    cond = True
            else:
                self.main.exitError("loopFunc: loopType not in (OPCODE_LOOPE, OPCODE_LOOPNE)")
        else:
            if (count != 0):
                cond = True
        if (cond):
            tempEIP = self.registers.regRead(eipReg)
            tempEIP += rel8
            if (operSize == misc.OP_SIZE_16BIT):
                tempEIP &= 0xffff
            elif (operSize == misc.OP_SIZE_32BIT):
                tempEIP &= 0xffffffff
            self.registers.regWrite(eipReg, tempEIP)
    def cmpRM8_R8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    def cmpRM16_32_R16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    def cmpR8_RM8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    def cmpR16_32_RM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    def cmpAlImm8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        reg0 = self.registers.regRead(registers.CPU_REGISTER_AL)
        imm8 = self.cpu.getCurrentOpcodeAdd()
        #cdef long cmpSum = reg0-imm8
        self.registers.setFullFlags(reg0, imm8, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    def cmpAxEaxImm16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        axReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            axReg = registers.CPU_REGISTER_EAX
        reg0 = self.registers.regRead(axReg)
        imm16_32 = self.cpu.getCurrentOpcodeAdd(operSize)
        #cdef long cmpSum = reg0-imm16_32
        self.registers.setFullFlags(reg0, imm16_32, operSize, misc.SET_FLAGS_SUB)
    def movImm8ToR8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        r8reg = self.cpu.opcode&0x7
        self.registers.regWrite(registers.CPU_REGISTER_BYTE[r8reg], self.cpu.getCurrentOpcodeAdd())
    def movImm16_32ToR16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        r16_32reg = self.cpu.opcode&0x7
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        if (operSize == misc.OP_SIZE_16BIT):
            self.registers.regWrite(registers.CPU_REGISTER_WORD[r16_32reg], self.cpu.getCurrentOpcodeAddEip())
        elif (operSize == misc.OP_SIZE_32BIT):
            self.registers.regWrite(registers.CPU_REGISTER_DWORD[r16_32reg], self.cpu.getCurrentOpcodeAddEip())
        else:
            self.main.exitError("operSize is NOT OK ({0:d})", operSize)
    def movRM8_R8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT))
    def movRM16_32_R16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        self.registers.modRMSave(rmOperands, operSize, self.registers.modRLoad(rmOperands, operSize))
    def testRM8_R8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.setSZP_C0_O0(op1&op2, misc.OP_SIZE_8BIT)
    def testRM16_32_R16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        self.registers.setSZP_C0_O0(op1&op2, operSize)
    def testAL_IMM8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd()
        self.registers.setSZP_C0_O0(op1&op2, misc.OP_SIZE_8BIT)
    def testAX_EAX_IMM16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        axReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            axReg = registers.CPU_REGISTER_EAX
        op1 = self.registers.regRead(axReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize)
        self.registers.setSZP_C0_O0(op1&op2, operSize)
    def movR8_RM8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        self.registers.modRSave(rmOperands, misc.OP_SIZE_8BIT, self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT))
    def movR16_32_RM16_32(self, c=True):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        if (c):
            self.registers.modRSave(rmOperands, operSize, self.registers.modRMLoad(rmOperands, operSize))
    def movRM16_SREG(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_16BIT, registers.MODRM_FLAGS_SREG)
        self.registers.modRMSave(rmOperands, misc.OP_SIZE_16BIT, self.registers.modRLoad(rmOperands, misc.OP_SIZE_16BIT))
    def movSREG_RM16(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_16BIT, registers.MODRM_FLAGS_SREG)
        self.registers.modRSave(rmOperands, misc.OP_SIZE_16BIT, self.registers.modRMLoad(rmOperands, misc.OP_SIZE_16BIT))
    def movAL_MOFFS8(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        regName = registers.CPU_REGISTER_AL
        mmAddr = self.cpu.getCurrentOpcodeAdd(addrSize)
        self.registers.regWrite(regName, self.main.mm.mmReadValue(mmAddr, misc.OP_SIZE_8BIT))
    def movAX_EAX_MOFFS16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        regName = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        mmAddr = self.cpu.getCurrentOpcodeAdd(addrSize)
        self.registers.regWrite(regName, self.main.mm.mmReadValue(mmAddr, operSize))
    
    def movMOFFS8_AL(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        regName = registers.CPU_REGISTER_AL
        mmAddr = self.cpu.getCurrentOpcodeAdd(addrSize)
        self.main.mm.mmWriteValue(mmAddr, self.registers.regRead(regName), misc.OP_SIZE_8BIT)
    def movMOFFS16_32_AX_EAX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        regName = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        mmAddr = self.cpu.getCurrentOpcodeAdd(addrSize)
        self.main.mm.mmWriteValue(mmAddr, self.registers.regRead(regName), operSize)
    def addRM8_R8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    def addRM16_32_R16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        self.registers.modRMSave(rmOperands, operSize, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    def addR8_RM8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.modRSave(rmOperands, misc.OP_SIZE_8BIT, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    def addR16_32_RM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        self.registers.modRSave(rmOperands, operSize, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    def addAL_IMM8(self):
        op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        self.registers.regWrite(registers.CPU_REGISTER_AL, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    def addAX_EAX_IMM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        op1 = self.registers.regRead(dataReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        self.registers.regWrite(dataReg, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    def adcRM8_R8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        op1 += self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    def adcRM16_32_R16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        op1 += self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.modRMSave(rmOperands, operSize, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    def adcR8_RM8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op1 += self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.modRSave(rmOperands, misc.OP_SIZE_8BIT, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    def adcR16_32_RM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        op1 += self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.modRSave(rmOperands, operSize, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    def adcAL_IMM8(self):
        op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        op1 += self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.regWrite(registers.CPU_REGISTER_AL, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    def adcAX_EAX_IMM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        op1 = self.registers.regRead(dataReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        op1 += self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.regWrite(dataReg, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    def subRM8_R8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, op1-op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    def subRM16_32_R16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        self.registers.modRMSave(rmOperands, operSize, op1-op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    def subR8_RM8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.modRSave(rmOperands, misc.OP_SIZE_8BIT, op1-op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    def subR16_32_RM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        self.registers.modRSave(rmOperands, operSize, op1-op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    def subAL_IMM8(self):
        op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        self.registers.regWrite(registers.CPU_REGISTER_AL, op1-op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    def subAX_EAX_IMM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        op1 = self.registers.regRead(dataReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        self.registers.regWrite(dataReg, op1-op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    def sbbRM8_R8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        op1 -= self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, op1-op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    def sbbRM16_32_R16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        op1 -= self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.modRMSave(rmOperands, operSize, op1-op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    def sbbR8_RM8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op1 -= self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.modRSave(rmOperands, misc.OP_SIZE_8BIT, op1-op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    def sbbR16_32_RM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        op1 -= self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.modRSave(rmOperands, operSize, op1-op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    def sbbAL_IMM8(self):
        op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        op1 -= self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.regWrite(registers.CPU_REGISTER_AL, op1-op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    def sbbAX_EAX_IMM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        op1 = self.registers.regRead(dataReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        op1 -= self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.regWrite(dataReg, op1-op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    def andRM8_R8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        data = op1&op2
        self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, data)
        self.registers.setSZP_C0_O0(data, misc.OP_SIZE_8BIT)
    def andRM16_32_R16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        data = op1&op2
        self.registers.modRMSave(rmOperands, operSize, data)
        self.registers.setSZP_C0_O0(data, operSize)
    def andR8_RM8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        data = op1&op2
        self.registers.modRSave(rmOperands, misc.OP_SIZE_8BIT, data)
        self.registers.setSZP_C0_O0(data, misc.OP_SIZE_8BIT)
    def andR16_32_RM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        data = op1&op2
        self.registers.modRSave(rmOperands, operSize, data)
        self.registers.setSZP_C0_O0(data, operSize)
    def andAL_IMM8(self):
        op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        data = op1&op2
        self.registers.regWrite(registers.CPU_REGISTER_AL, data)
        self.registers.setSZP_C0_O0(data, misc.OP_SIZE_8BIT)
    def andAX_EAX_IMM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        op1 = self.registers.regRead(dataReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        data = op1&op2
        self.registers.regWrite(dataReg, data)
        self.registers.setSZP_C0_O0(data, operSize)
    
    
    
    def orRM8_R8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        data = op1|op2
        self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, data)
        self.registers.setSZP_C0_O0(data, misc.OP_SIZE_8BIT)
    def orRM16_32_R16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        data = op1|op2
        self.registers.modRMSave(rmOperands, operSize, data)
        self.registers.setSZP_C0_O0(data, operSize)
    def orR8_RM8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        data = op1|op2
        self.registers.modRSave(rmOperands, misc.OP_SIZE_8BIT, data)
        self.registers.setSZP_C0_O0(data, misc.OP_SIZE_8BIT)
    def orR16_32_RM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        data = op1|op2
        self.registers.modRSave(rmOperands, operSize, data)
        self.registers.setSZP_C0_O0(data, operSize)
    def orAL_IMM8(self):
        op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        data = op1|op2
        self.registers.regWrite(registers.CPU_REGISTER_AL, data)
        self.registers.setSZP_C0_O0(data, misc.OP_SIZE_8BIT)
    def orAX_EAX_IMM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        op1 = self.registers.regRead(dataReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        data = op1|op2
        self.registers.regWrite(dataReg, data)
        self.registers.setSZP_C0_O0(data, operSize)
    
    
    
    def xorRM8_R8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        data = op1^op2
        self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, data)
        self.registers.setSZP_C0_O0(data, misc.OP_SIZE_8BIT)
    def xorRM16_32_R16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRMLoad(rmOperands, operSize)
        op2 = self.registers.modRLoad(rmOperands, operSize)
        data = op1^op2
        self.registers.modRMSave(rmOperands, operSize, data)
        self.registers.setSZP_C0_O0(data, operSize)
    def xorR8_RM8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        data = op1^op2
        self.registers.modRSave(rmOperands, misc.OP_SIZE_8BIT, data)
        self.registers.setSZP_C0_O0(data, misc.OP_SIZE_8BIT)
    def xorR16_32_RM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        data = op1^op2
        self.registers.modRSave(rmOperands, operSize, data)
        self.registers.setSZP_C0_O0(data, operSize)
    def xorAL_IMM8(self):
        op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        data = op1^op2
        self.registers.regWrite(registers.CPU_REGISTER_AL, data)
        self.registers.setSZP_C0_O0(data, misc.OP_SIZE_8BIT)
    def xorAX_EAX_IMM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        op1 = self.registers.regRead(dataReg)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        data = op1^op2
        self.registers.regWrite(dataReg, data)
        self.registers.setSZP_C0_O0(data, operSize)
    
    
    
    
    
    
    def stosb(self):
        operSize = misc.OP_SIZE_8BIT
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        dataReg  = registers.CPU_REGISTER_DI
        srcReg   = registers.CPU_REGISTER_AL
        countReg = registers.CPU_REGISTER_CX
        countVal = 1
        data = self.registers.regRead(srcReg, signed=False)
        if (addrSize == misc.OP_SIZE_32BIT):
            dataReg  = registers.CPU_REGISTER_EDI
            countReg = registers.CPU_REGISTER_ECX
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
        if (countVal == 0):
            return
        op1 = self.registers.regRead(dataReg)
        memData = data.to_bytes(length=operSize, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=False)*countVal
        self.main.mm.mmWrite(op1, memData, countVal, registers.CPU_SEGMENT_ES)
        if (not self.registers.getEFLAG(registers.FLAG_DF)):
            self.registers.regAdd(dataReg, countVal)
        else:
            self.registers.regSub(dataReg, countVal)
        self.registers.regWrite( countReg, 0 )
    def stos_wd(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        dataReg = registers.CPU_REGISTER_DI
        srcReg  = registers.CPU_REGISTER_AX
        data = self.registers.regRead(srcReg, signed=False)
        countReg = registers.CPU_REGISTER_CX
        countVal = 1
        if (addrSize == misc.OP_SIZE_32BIT):
            dataReg  = registers.CPU_REGISTER_EDI
            srcReg   = registers.CPU_REGISTER_EAX
            countReg = registers.CPU_REGISTER_ECX
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
        if (countVal == 0):
            return
        dataLength = operSize*countVal
        op1 = self.registers.regRead(dataReg)
        memData = data.to_bytes(length=operSize, byteorder=misc.BYTE_ORDER_LITTLE_ENDIAN, signed=False)*countVal
        self.main.mm.mmWrite(op1, memData, dataLength, registers.CPU_SEGMENT_ES)
        if (not self.registers.getEFLAG(registers.FLAG_DF)):
            self.registers.regAdd(dataReg, dataLength)
        else:
            self.registers.regSub(dataReg, dataLength)
        self.registers.regWrite( countReg, 0 )
    
    
    def movsb(self):
        operSize = misc.OP_SIZE_8BIT
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        esiReg  = registers.CPU_REGISTER_SI
        ediReg  = registers.CPU_REGISTER_DI
        countReg = registers.CPU_REGISTER_CX
        countVal = 1
        if (addrSize == misc.OP_SIZE_32BIT):
            esiReg  = registers.CPU_REGISTER_ESI
            ediReg  = registers.CPU_REGISTER_EDI
            countReg = registers.CPU_REGISTER_ECX
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
        if (countVal == 0):
            return
        dataLength = operSize*countVal
        esiVal = self.registers.regRead(esiReg)
        ediVal = self.registers.regRead(ediReg)
        data = self.main.mm.mmRead(esiVal, dataLength, segId=registers.CPU_SEGMENT_DS, allowOverride=True)
        self.main.mm.mmWrite(ediVal, data, dataLength, segId=registers.CPU_SEGMENT_ES, allowOverride=False)
        if (not self.registers.getEFLAG(registers.FLAG_DF)):
            self.registers.regAdd(esiReg, dataLength)
            self.registers.regAdd(ediReg, dataLength)
        else:
            self.registers.regSub(esiReg, dataLength)
            self.registers.regSub(ediReg, dataLength)
        self.registers.regWrite( countReg, 0 )
    def movs_wd(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        esiReg  = registers.CPU_REGISTER_SI
        ediReg  = registers.CPU_REGISTER_DI
        countReg = registers.CPU_REGISTER_CX
        countVal = 1
        if (addrSize == misc.OP_SIZE_32BIT):
            esiReg  = registers.CPU_REGISTER_ESI
            ediReg  = registers.CPU_REGISTER_EDI
            countReg = registers.CPU_REGISTER_ECX
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
        if (countVal == 0):
            return
        dataLength = operSize*countVal
        esiVal = self.registers.regRead(esiReg)
        ediVal = self.registers.regRead(ediReg)
        data = self.main.mm.mmRead(esiVal, dataLength, segId=registers.CPU_SEGMENT_DS, allowOverride=True)
        self.main.mm.mmWrite(ediVal, data, dataLength, segId=registers.CPU_SEGMENT_ES, allowOverride=False)
        if (not self.registers.getEFLAG(registers.FLAG_DF)):
            self.registers.regAdd(esiReg, dataLength)
            self.registers.regAdd(ediReg, dataLength)
        else:
            self.registers.regSub(esiReg, dataLength)
            self.registers.regSub(ediReg, dataLength)
        self.registers.regWrite( countReg, 0 )
    
    
    
    
    
    
    
    def lodsb(self):
        operSize = misc.OP_SIZE_8BIT
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        esiReg  = registers.CPU_REGISTER_SI
        countReg = registers.CPU_REGISTER_CX
        countVal = 1
        if (addrSize == misc.OP_SIZE_32BIT):
            esiReg  = registers.CPU_REGISTER_ESI
            countReg = registers.CPU_REGISTER_ECX
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
        if (countVal == 0):
            return
        dataLength = operSize*countVal
        esiVal = self.registers.regRead(esiReg)
        data = self.main.mm.mmReadValue(esiVal+dataLength-1, misc.OP_SIZE_8BIT, segId=registers.CPU_SEGMENT_DS, allowOverride=True)
        self.registers.regWrite(registers.CPU_REGISTER_AL, data)
        if (not self.registers.getEFLAG(registers.FLAG_DF)):
            self.registers.regAdd(esiReg, dataLength)
        else:
            self.registers.regSub(esiReg, dataLength)
        self.registers.regWrite( countReg, 0 )
    def lods_wd(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        eaxReg  = registers.CPU_REGISTER_AX
        esiReg  = registers.CPU_REGISTER_SI
        countReg = registers.CPU_REGISTER_CX
        countVal = 1
        if (addrSize == misc.OP_SIZE_32BIT):
            eaxReg  = registers.CPU_REGISTER_EAX
            esiReg  = registers.CPU_REGISTER_ESI
            countReg = registers.CPU_REGISTER_ECX
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
        if (countVal == 0):
            return
        dataLength = operSize*countVal
        esiVal = self.registers.regRead(esiReg)
        data = self.main.mm.mmReadValue(esiVal+dataLength-operSize, operSize, segId=registers.CPU_SEGMENT_DS, allowOverride=True)
        self.registers.regWrite(eaxReg, data)
        if (not self.registers.getEFLAG(registers.FLAG_DF)):
            self.registers.regAdd(esiReg, dataLength)
        else:
            self.registers.regSub(esiReg, dataLength)
        self.registers.regWrite( countReg, 0 )
    
    
    
    
    
    
    
    
    
    
    
    def cmpsb(self):
        operSize = misc.OP_SIZE_8BIT
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        esiReg  = registers.CPU_REGISTER_SI
        ediReg  = registers.CPU_REGISTER_DI
        countReg = registers.CPU_REGISTER_CX
        countVal = 1
        if (addrSize == misc.OP_SIZE_32BIT):
            esiReg = registers.CPU_REGISTER_ESI
            ediReg = registers.CPU_REGISTER_EDI
            countReg = registers.CPU_REGISTER_ECX
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
        if (countVal == 0):
            return
        while (countVal > 0):
            esiVal = self.registers.regRead(esiReg)
            ediVal = self.registers.regRead(ediReg)
            src1 = self.main.mm.mmReadValue(esiVal, operSize, segId=registers.CPU_SEGMENT_DS, allowOverride=True)
            src2 = self.main.mm.mmReadValue(ediVal, operSize, segId=registers.CPU_SEGMENT_ES, allowOverride=False)
            #temp = src1-src2
            self.registers.setFullFlags(src1, src2, operSize, misc.SET_FLAGS_SUB)
            if (not self.registers.getEFLAG(registers.FLAG_DF)):
                self.registers.regAdd(esiReg, operSize)
                self.registers.regAdd(ediReg, operSize)
            else:
                self.registers.regSub(esiReg, operSize)
                self.registers.regSub(ediReg, operSize)
            countVal -= 1
            if ((self.registers.repPrefix == misc.OPCODE_PREFIX_REPE and not self.registers.getEFLAG(registers.FLAG_ZF)) or \
                (self.registers.repPrefix == misc.OPCODE_PREFIX_REPNE and self.registers.getEFLAG(registers.FLAG_ZF))):
                break
        self.registers.regWrite( countReg, countVal )
    def cmps_wd(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        esiReg  = registers.CPU_REGISTER_SI
        ediReg  = registers.CPU_REGISTER_DI
        countReg = registers.CPU_REGISTER_CX
        countVal = 1
        if (addrSize == misc.OP_SIZE_32BIT):
            esiReg = registers.CPU_REGISTER_ESI
            ediReg = registers.CPU_REGISTER_EDI
            countReg = registers.CPU_REGISTER_ECX
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
        if (countVal == 0):
            return
        while (countVal > 0):
            esiVal = self.registers.regRead(esiReg)
            ediVal = self.registers.regRead(ediReg)
            src1 = self.main.mm.mmReadValue(esiVal, operSize, segId=registers.CPU_SEGMENT_DS, allowOverride=True)
            src2 = self.main.mm.mmReadValue(ediVal, operSize, segId=registers.CPU_SEGMENT_ES, allowOverride=False)
            #temp = src1-src2
            self.registers.setFullFlags(src1, src2, operSize, misc.SET_FLAGS_SUB)
            if (not self.registers.getEFLAG(registers.FLAG_DF)):
                self.registers.regAdd(esiReg, operSize)
                self.registers.regAdd(ediReg, operSize)
            else:
                self.registers.regSub(esiReg, operSize)
                self.registers.regSub(ediReg, operSize)
            countVal -= 1
            if ((self.registers.repPrefix == misc.OPCODE_PREFIX_REPE and not self.registers.getEFLAG(registers.FLAG_ZF)) or \
                (self.registers.repPrefix == misc.OPCODE_PREFIX_REPNE and self.registers.getEFLAG(registers.FLAG_ZF))):
                break
        self.registers.regWrite( countReg, countVal )
    
    
    
    
    def scasb(self):
        operSize = misc.OP_SIZE_8BIT
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        alReg  = registers.CPU_REGISTER_AL
        ediReg  = registers.CPU_REGISTER_DI
        countReg = registers.CPU_REGISTER_CX
        countVal = 1
        if (addrSize == misc.OP_SIZE_32BIT):
            ediReg = registers.CPU_REGISTER_EDI
            countReg = registers.CPU_REGISTER_ECX
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
        if (countVal == 0):
            return
        while (countVal > 0):
            ediVal = self.registers.regRead(ediReg)
            src1 = self.registers.regRead(alReg)
            src2 = self.main.mm.mmReadValue(ediVal, operSize, segId=registers.CPU_SEGMENT_ES, allowOverride=False)
            #temp = src1-src2
            self.registers.setFullFlags(src1, src2, operSize, misc.SET_FLAGS_SUB)
            if (not self.registers.getEFLAG(registers.FLAG_DF)):
                self.registers.regAdd(ediReg, operSize)
            else:
                self.registers.regSub(ediReg, operSize)
            countVal -= 1
            if ((self.registers.repPrefix == misc.OPCODE_PREFIX_REPE and not self.registers.getEFLAG(registers.FLAG_ZF)) or \
                (self.registers.repPrefix == misc.OPCODE_PREFIX_REPNE and self.registers.getEFLAG(registers.FLAG_ZF))):
                break
        self.registers.regWrite( countReg, countVal )
    def scas_wd(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        eaxReg  = registers.CPU_REGISTER_AX
        ediReg  = registers.CPU_REGISTER_DI
        countReg = registers.CPU_REGISTER_CX
        countVal = 1
        if (addrSize == misc.OP_SIZE_32BIT):
            eaxReg = registers.CPU_REGISTER_EAX
            ediReg = registers.CPU_REGISTER_EDI
            countReg = registers.CPU_REGISTER_ECX
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg)
        if (countVal == 0):
            return
        
        while (countVal > 0):
            ediVal = self.registers.regRead(ediReg)
            src1 = self.registers.regRead(eaxReg)
            src2 = self.main.mm.mmReadValue(ediVal, operSize, segId=registers.CPU_SEGMENT_ES, allowOverride=False)
            #temp = src1-src2
            self.registers.setFullFlags(src1, src2, operSize, misc.SET_FLAGS_SUB)
            if (not self.registers.getEFLAG(registers.FLAG_DF)):
                self.registers.regAdd(ediReg, operSize)
            else:
                self.registers.regSub(ediReg, operSize)
            countVal -= 1
            if ((self.registers.repPrefix == misc.OPCODE_PREFIX_REPE and not self.registers.getEFLAG(registers.FLAG_ZF)) or \
                (self.registers.repPrefix == misc.OPCODE_PREFIX_REPNE and self.registers.getEFLAG(registers.FLAG_ZF))):
                break
        self.registers.regWrite( countReg, countVal )
    
    
    
    
    
    
    
    
    
    
    
    
    
    def inAlImm8(self):
        self.registers.regWrite(registers.CPU_REGISTER_AL, self.main.platform.inPort(self.cpu.getCurrentOpcodeAdd(), misc.OP_SIZE_8BIT))
    def inAxEaxImm8(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        self.registers.regWrite(dataReg, self.main.platform.inPort(self.cpu.getCurrentOpcodeAdd(), operSize))
    def inAlDx(self):
        self.registers.regWrite(registers.CPU_REGISTER_AL, self.main.platform.inPort(self.registers.regRead(registers.CPU_REGISTER_DX), misc.OP_SIZE_8BIT))
    def inAxEaxDx(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        self.registers.regWrite(dataReg, self.main.platform.inPort(self.registers.regRead(registers.CPU_REGISTER_DX), operSize))
    def outImm8Al(self):
        self.main.platform.outPort(self.cpu.getCurrentOpcodeAdd(), self.registers.regRead(registers.CPU_REGISTER_AL), misc.OP_SIZE_8BIT)
    def outImm8AxEax(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        self.main.platform.outPort(self.cpu.getCurrentOpcodeAdd(), self.registers.regRead(dataReg), operSize)
    def outDxAl(self):
        self.main.platform.outPort(self.registers.regRead(registers.CPU_REGISTER_DX), self.registers.regRead(registers.CPU_REGISTER_AL), misc.OP_SIZE_8BIT)
    def outDxAxEax(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        self.main.platform.outPort(self.registers.regRead(registers.CPU_REGISTER_DX), self.registers.regRead(dataReg), operSize)
    def jgShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(registers.FLAG_ZF) and (self.registers.getEFLAG(registers.FLAG_SF)==self.registers.getEFLAG(registers.FLAG_OF)))
    def jgeShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, self.registers.getEFLAG(registers.FLAG_SF)==self.registers.getEFLAG(registers.FLAG_OF))
    def jlShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, self.registers.getEFLAG(registers.FLAG_SF)!=self.registers.getEFLAG(registers.FLAG_OF))
    def jleShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, self.registers.getEFLAG(registers.FLAG_ZF) or (self.registers.getEFLAG(registers.FLAG_SF)!=self.registers.getEFLAG(registers.FLAG_OF)))
    def jnzShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(registers.FLAG_ZF))
    def jzShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, self.registers.getEFLAG(registers.FLAG_ZF))
    def jaShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(registers.FLAG_CF) and not self.registers.getEFLAG(registers.FLAG_ZF))
    def jbeShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, self.registers.getEFLAG(registers.FLAG_CF) or self.registers.getEFLAG(registers.FLAG_ZF))
    def jncShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(registers.FLAG_CF))
    def jcShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, self.registers.getEFLAG(registers.FLAG_CF))
    def jnpShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(registers.FLAG_PF))
    def jpShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, self.registers.getEFLAG(registers.FLAG_PF))
    def jnoShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(registers.FLAG_OF))
    def joShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, self.registers.getEFLAG(registers.FLAG_OF))
    def jnsShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(registers.FLAG_SF))
    def jsShort(self, size=misc.OP_SIZE_8BIT): # byte8
        self.jumpShort(size, self.registers.getEFLAG(registers.FLAG_SF))
    def jcxzShort(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cxReg = registers.CPU_REGISTER_CX
        if (operSize == misc.OP_SIZE_32BIT):
            cxReg = registers.CPU_REGISTER_ECX
        self.jumpShort(misc.OP_SIZE_8BIT, self.registers.regRead(cxReg)==0)
    def jumpShort(self, operSize, c=True):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        segOperSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        tempEIP = self.cpu.getCurrentOpcodeAdd(numBytes=(operSize), signed=True) + \
                            self.registers.regRead(registers.CPU_REGISTER_EIP)
        if (segOperSize == misc.OP_SIZE_16BIT):
            tempEIP &= 0xffff
        if (c):
            self.registers.regWrite(registers.CPU_REGISTER_EIP, tempEIP)
    def callNearRel16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        segOperSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        eipRegName = registers.CPU_REGISTER_IP
        if (segOperSize == misc.OP_SIZE_32BIT):
            eipRegName = registers.CPU_REGISTER_EIP
        tempEIP = self.cpu.getCurrentOpcodeAdd(numBytes=(segOperSize), signed=True) + \
                            self.registers.regRead(registers.CPU_REGISTER_EIP)
        if (segOperSize == misc.OP_SIZE_16BIT):
            tempEIP &= 0xffff
        self.stackPushRegId(eipRegName)
        self.registers.regWrite(registers.CPU_REGISTER_EIP, tempEIP)
    def callPtr16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        segmentName = registers.CPU_SEGMENT_CS
        eipName = registers.CPU_REGISTER_IP
        if (operSize == misc.OP_SIZE_32BIT):
            eipName = registers.CPU_REGISTER_EIP
        
        eipAddr = self.cpu.getCurrentOpcodeAdd(operSize)
        segVal = self.cpu.getCurrentOpcodeAdd(misc.OP_SIZE_16BIT)
        self.stackPushRegId(segmentName, operSize)
        self.stackPushRegId(eipName, operSize)
        self.registers.regWrite(segmentName, segVal)
        self.registers.regWrite(registers.CPU_REGISTER_EIP, eipAddr)
    def pushaWD(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        eaxName = registers.CPU_REGISTER_AX
        ecxName = registers.CPU_REGISTER_CX
        edxName = registers.CPU_REGISTER_DX
        ebxName = registers.CPU_REGISTER_BX
        espName = registers.CPU_REGISTER_SP
        ebpName = registers.CPU_REGISTER_BP
        esiName = registers.CPU_REGISTER_SI
        ediName = registers.CPU_REGISTER_DI
        if (operSize == misc.OP_SIZE_32BIT):
            eaxName = registers.CPU_REGISTER_EAX
            ecxName = registers.CPU_REGISTER_ECX
            edxName = registers.CPU_REGISTER_EDX
            ebxName = registers.CPU_REGISTER_EBX
            espName = registers.CPU_REGISTER_ESP
            ebpName = registers.CPU_REGISTER_EBP
            esiName = registers.CPU_REGISTER_ESI
            ediName = registers.CPU_REGISTER_EDI
        temp = self.registers.regRead( espName )
        self.stackPushRegId(eaxName, operSize)
        self.stackPushRegId(ecxName, operSize)
        self.stackPushRegId(edxName, operSize)
        self.stackPushRegId(ebxName, operSize)
        self.stackPushValue(temp, operSize)
        self.stackPushRegId(ebpName, operSize)
        self.stackPushRegId(esiName, operSize)
        self.stackPushRegId(ediName, operSize)
    def popaWD(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        eaxName = registers.CPU_REGISTER_AX
        ecxName = registers.CPU_REGISTER_CX
        edxName = registers.CPU_REGISTER_DX
        ebxName = registers.CPU_REGISTER_BX
        espName = registers.CPU_REGISTER_SP
        ebpName = registers.CPU_REGISTER_BP
        esiName = registers.CPU_REGISTER_SI
        ediName = registers.CPU_REGISTER_DI
        if (operSize == misc.OP_SIZE_32BIT):
            eaxName = registers.CPU_REGISTER_EAX
            ecxName = registers.CPU_REGISTER_ECX
            edxName = registers.CPU_REGISTER_EDX
            ebxName = registers.CPU_REGISTER_EBX
            espName = registers.CPU_REGISTER_ESP
            ebpName = registers.CPU_REGISTER_EBP
            esiName = registers.CPU_REGISTER_ESI
            ediName = registers.CPU_REGISTER_EDI
        self.stackPopRegId(ediName, operSize)
        self.stackPopRegId(esiName, operSize)
        self.stackPopRegId(ebpName, operSize)
        self.registers.regAdd(espName, operSize)
        self.stackPopRegId(ebxName, operSize)
        self.stackPopRegId(edxName, operSize)
        self.stackPopRegId(ecxName, operSize)
        self.stackPopRegId(eaxName, operSize)
        
    def pushfWD(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regNameId = registers.CPU_REGISTER_FLAGS
        value = self.registers.regRead(regNameId)|2
        self.registers.setEFLAG(0x3000, False) # This is for
        value |= ((self.registers.iopl&3)<<12) # IOPL, Bits 12,13
        if (operSize == misc.OP_SIZE_32BIT):
            regNameId = registers.CPU_REGISTER_EFLAGS
            value &= 0x00FCFFFF
        self.stackPushValue(value, operSize)
    def popfWD(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regNameId = registers.CPU_REGISTER_FLAGS
        if (operSize == misc.OP_SIZE_32BIT):
            regNameId = registers.CPU_REGISTER_EFLAGS
        stackPopValue = self.stackPopValue(operSize)
        self.registers.regWrite( regNameId, stackPopValue )
        self.registers.iopl = (stackPopValue>>12)&3
        self.registers.setEFLAG(2, True)
        self.registers.setEFLAG(0x3000, False) # This is for
        self.registers.setEFLAG((self.registers.iopl&3)<<12, True) # IOPL, Bits 12,13
        self.registers.setEFLAG(0x8, False)
        self.registers.setEFLAG(0x20, False)
        self.registers.setEFLAG(0x8000, False)
    def stackPopRM(self, rmOperands, operSize):
        value = self.stackPopValue(operSize)
        self.registers.modRMSave(rmOperands, operSize, value)
        return value
    def stackPopRegId(self, regId, operSize=0):
        if (operSize == 0):
            operSize = self.registers.regGetSize(regId)
        value = self.stackPopValue(operSize)
        self.registers.regWrite(regId, value)
        return value
    def stackPopValue(self, operSize):
        if (operSize == 0):
            self.main.exitError("stackPopValue: operSize == 0")
            #operSize   = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        stackAddrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_SS)
        stackRegName = registers.CPU_REGISTER_SP
        if (stackAddrSize == misc.OP_SIZE_32BIT):
            stackRegName = registers.CPU_REGISTER_ESP
        stackAddr = self.registers.regRead(stackRegName)
        data = self.main.mm.mmReadValue(stackAddr, operSize, segId=registers.CPU_SEGMENT_SS, allowOverride=False)
        self.registers.regAdd(stackRegName, operSize)
        return data
    def stackPushRegId(self, regId, operSize=0):
        value = self.registers.regRead(regId)
        if (operSize == 0):
            operSize = self.registers.regGetSize(regId)
        self.stackPushValue(value, operSize)
    def stackPushValue(self, value, operSize):
        if (operSize == 0):
            self.main.exitError("stackPushValue: operSize == 0")
            operSize   = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        stackAddrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_SS)
        stackRegName = registers.CPU_REGISTER_SP
        if (stackAddrSize == misc.OP_SIZE_32BIT):
            stackRegName = registers.CPU_REGISTER_ESP
        self.registers.regSub(stackRegName, operSize)
        stackAddr = self.registers.regRead(stackRegName)
        self.main.mm.mmWriteValue(stackAddr, value, operSize, segId=registers.CPU_SEGMENT_SS, allowOverride=False)
    def pushIMM8(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operMask = self.main.misc.getBitMask(operSize)
        value = self.cpu.getCurrentOpcodeAdd(misc.OP_SIZE_8BIT, signed=True)
        value &= operMask
        self.stackPushValue(value, operSize)
    def pushIMM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        value = self.cpu.getCurrentOpcodeAdd(operSize)
        self.stackPushValue(value, operSize)
    def imulR_RM_IMM8(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        operOp1 = self.registers.modRMLoad(rmOperands, operSize, signed=True)
        operOp2 = self.cpu.getCurrentOpcodeAdd(misc.OP_SIZE_8BIT, signed=True)
        operOp2 &= self.main.misc.getBitMask(operSize)
        operSum = operOp1*operOp2
        self.registers.modRSave(rmOperands, operSize, operSum)
        self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_MUL, signed=True)
    def imulR_RM_IMM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        operOp1 = self.registers.modRMLoad(rmOperands, operSize, signed=True)
        operOp2 = self.cpu.getCurrentOpcodeAdd(operSize, signed=True)
        operSum = operOp1*operOp2
        self.registers.modRSave(rmOperands, operSize, operSum)
        self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_MUL, signed=True)
    def opcodeGroup1_RM8_IMM8(self): # addOrAdcSbbAndSubXorCmp RM8 IMM8
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        operOp1 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        operOp2 = self.cpu.getCurrentOpcodeAdd() # operImm8
        operRes = 0
        bitMask = self.main.misc.getBitMask(misc.OP_SIZE_8BIT)
        if (operOpcodeId == GROUP1_OP_ADD):
            operRes = operOp1+operOp2
            self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_OR):
            operRes = operOp1|operOp2
            self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setSZP_C0_O0(operRes, misc.OP_SIZE_8BIT)
        elif (operOpcodeId == GROUP1_OP_ADC):
            operOp1 += self.registers.getEFLAG(registers.FLAG_CF)
            operRes = (operOp1+operOp2)
            self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_SBB):
            operOp1 -= self.registers.getEFLAG(registers.FLAG_CF)
            operRes = operOp1-operOp2
            self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_AND):
            operRes = operOp1&operOp2
            self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setSZP_C0_O0(operRes, misc.OP_SIZE_8BIT)
        elif (operOpcodeId == GROUP1_OP_SUB):
            operRes = operOp1-operOp2
            self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_XOR):
            operRes = operOp1^operOp2
            self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setSZP_C0_O0(operRes, misc.OP_SIZE_8BIT)
        elif (operOpcodeId == GROUP1_OP_CMP):
            operRes = operOp1-operOp2
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
        else:
            self.main.exitError("opcodeGroup1_RM8_IMM8: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    def opcodeGroup1_RM16_32_IMM16_32(self): # addOrAdcSbbAndSubXorCmp RM16/32 IMM16/32
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        operOp1 = self.registers.modRMLoad(rmOperands, operSize)
        operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        operRes = 0
        bitMask = self.main.misc.getBitMask(operSize)
        if (operOpcodeId == GROUP1_OP_ADD):
            operRes = operOp1+operOp2
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_OR):
            operRes = operOp1|operOp2
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setSZP_C0_O0(operRes, operSize)
        elif (operOpcodeId == GROUP1_OP_ADC):
            operOp1 += self.registers.getEFLAG(registers.FLAG_CF)
            operRes = (operOp1+operOp2)
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_SBB):
            operOp1 -= self.registers.getEFLAG(registers.FLAG_CF)
            operRes = operOp1-operOp2
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_AND):
            operRes = operOp1&operOp2
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setSZP_C0_O0(operRes, operSize)
        elif (operOpcodeId == GROUP1_OP_SUB):
            operRes = operOp1-operOp2
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_XOR):
            operRes = operOp1^operOp2
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setSZP_C0_O0(operRes, operSize)
        elif (operOpcodeId == GROUP1_OP_CMP):
            operRes = operOp1-operOp2
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB)
        else:
            self.main.exitError("opcodeGroup1_RM16_32_IMM16_32: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    def opcodeGroup1_RM16_32_IMM8(self): # addOrAdcSbbAndSubXorCmp RM16/32 IMM8
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        operOp1 = self.registers.modRMLoad(rmOperands, operSize)
        operOp2 = self.cpu.getCurrentOpcodeAdd(signed=True) # operImm8
        operRes = 0
        bitMask = self.main.misc.getBitMask(operSize)
        operOp2 &= bitMask
        if (operOpcodeId == GROUP1_OP_ADD):
            operRes = operOp1+operOp2
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_OR):
            operRes = operOp1|operOp2
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setSZP_C0_O0(operRes, operSize)
        elif (operOpcodeId == GROUP1_OP_ADC):
            operOp1 += self.registers.getEFLAG(registers.FLAG_CF)
            #operOp1 &= bitMask
            operRes = (operOp1+operOp2)&bitMask
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_SBB):
            operOp1 -= self.registers.getEFLAG(registers.FLAG_CF)
            operRes = operOp1-operOp2
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_AND):
            operRes = operOp1&operOp2
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setSZP_C0_O0(operRes, operSize)
        elif (operOpcodeId == GROUP1_OP_SUB):
            operRes = operOp1-operOp2
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_XOR):
            operRes = operOp1^operOp2
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setSZP_C0_O0(operRes, operSize)
        elif (operOpcodeId == GROUP1_OP_CMP):
            operRes = operOp1-operOp2
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB)
        else:
            self.main.exitError("opcodeGroup1_RM16_32_IMM8: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    def opcodeGroup3_RM8_IMM8(self): # 0/MOV RM8 IMM8
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        #cdef long operOp1 = self.registers.modRMLoad(rmOperands, 8)
        operOp2 = self.cpu.getCurrentOpcodeAdd() # operImm8
        operRes = 0
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, operOp2)
        else:
            self.main.exitError("opcodeGroup3_RM8_IMM8: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    def opcodeGroup3_RM16_32_IMM16_32(self): # 0/MOV RM16/32 IMM16/32
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        #cdef long operOp1 = self.registers.modRMLoad(rmOperands, operSize)
        operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        operRes = 0
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.registers.modRMSave(rmOperands, operSize, operOp2)
        else:
            self.main.exitError("opcodeGroup3_RM16_32_IMM16_32: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    def opcodeGroup0F(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcodeAdd()
        if (operOpcode == 0x01): # LGDT/LIDT SGDT/SIDT
            operOpcodeMod = self.cpu.getCurrentOpcodeAdd()
            operOpcodeModId = (operOpcodeMod>>3)&7
            mmAddr = self.cpu.getCurrentOpcodeAdd(operSize)
            if (operOpcodeModId == 0): # SGDT
                self.main.exitError("opcodeGroup0F_01_0: SGDT not supported yet.")
            elif (operOpcodeModId == 1): # SIDT
                self.main.exitError("opcodeGroup0F_01_1: SIDT not supported yet.")
            elif (operOpcodeModId == 2): # LGDT
                #self.main.exitError("opcodeGroup0F_01_2: LGDT not supported yet.")
                pass
                limit = self.main.mm.mmReadValue(mmAddr, misc.OP_SIZE_16BIT)
                base = self.main.mm.mmReadValue(mmAddr+misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT)
                if (operSize == misc.OP_SIZE_16BIT):
                    base &= 0xffffff
                self.registers.segments.gdt.loadTable(base, limit)
            elif (operOpcodeModId == 3): # LIDT
                #self.main.exitError("opcodeGroup0F_01_3: LIDT not supported yet.")
                pass
                limit = self.main.mm.mmReadValue(mmAddr, misc.OP_SIZE_16BIT)
                base = self.main.mm.mmReadValue(mmAddr+misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT)
                if (operSize == misc.OP_SIZE_16BIT):
                    base &= 0xffffff
                self.registers.segments.idt.loadTable(base, limit)
            else:
                self.main.exitError("opcodeGroup0F_01: invalid operOpcodeModId. 0x{0:x}".format(operOpcodeModId))
        elif (operOpcode == 0x20): # MOV R/M, CRn
            rmOperands = self.registers.modRMOperands(operSize, registers.MODRM_FLAGS_CREG)
            self.registers.modRMSave(rmOperands, operSize, self.registers.modRLoad(rmOperands, operSize))
        elif (operOpcode == 0x22): # MOV CRn, R/M
            rmOperands = self.registers.modRMOperands(operSize, registers.MODRM_FLAGS_CREG)
            self.registers.modRSave(rmOperands, operSize, self.registers.modRMLoad(rmOperands, operSize))
        elif (operOpcode == 0x31): # RDTSC
            if (not self.registers.getFlag( registers.CPU_REGISTER_CR4, registers.CR4_FLAG_TSD ) or \
                 self.registers.cpl == 0 or not self.cpu.isInProtectedMode()):
                self.registers.regWrite( registers.CPU_REGISTER_EAX, self.cpu.cycles&0xffffffff )
                self.registers.regWrite( registers.CPU_REGISTER_EDX, (self.cpu.cycles>>32)&0xffffffff )
            else:
                self.cpu.exception( misc.CPU_EXCEPTION_GP, errorCode=0 )
        elif (operOpcode >= 0x40 and operOpcode <= 0x4f): # CMOVcc
            self.cmovFunc(self.registers.getCond( operOpcode&0xf ) )
        elif (operOpcode >= 0x80 and operOpcode <= 0x8f):
            self.jumpShort(operSize, self.registers.getCond( operOpcode&0xf ))
        elif (operOpcode >= 0x90 and operOpcode <= 0x9f): # SETcc
            self.setCondFunc(self.registers.getCond( operOpcode&0xf ) )
        elif (operOpcode == 0xa0):
            self.pushFS()
        elif (operOpcode == 0xa1):
            self.popFS()
        elif (operOpcode == 0xa2): # CPUID
            ###self.cpu.exception(misc.CPU_EXCEPTION_UD) # for <= early 486s
            eaxId = self.registers.regRead( registers.CPU_REGISTER_EAX )
            eaxIsInvalid = (eaxId >= 0x40000000 and eaxId <= 0x4fffffff)
            if ( eaxId == 0x0 or eaxIsInvalid ):
                self.registers.regWrite( registers.CPU_REGISTER_EAX, 0x1 )
                self.registers.regWrite( registers.CPU_REGISTER_EBX, 0x756e6547 )
                self.registers.regWrite( registers.CPU_REGISTER_EDX, 0x49656e69 )
                self.registers.regWrite( registers.CPU_REGISTER_ECX, 0x6c65746e )
            elif ( eaxId == 0x1 ):
                self.registers.regWrite( registers.CPU_REGISTER_EAX, 0x400 )
                self.registers.regWrite( registers.CPU_REGISTER_EBX, 0x0 )
                self.registers.regWrite( registers.CPU_REGISTER_EDX, 0x0 )
                self.registers.regWrite( registers.CPU_REGISTER_ECX, 0x0 )
            else:
                self.main.exitError("CPUID: eaxId {0:#04x} unknown.".format(eaxId))
        elif (operOpcode == 0xa8):
            self.pushGS()
        elif (operOpcode == 0xa9):
            self.popGS()
        elif (operOpcode in (0xac, 0xad)): # SHRD
            operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
            halfOperMask = self.main.misc.getBitMask(operSize, half=True, minus=0)
            bitSize = operSize * 8
            rmOperands = self.registers.modRMOperands(operSize)
            if (operOpcode == 0xac): # SHRD imm8
                count = self.cpu.getCurrentOpcodeAdd()
            elif (operOpcode == 0xad): # SHRD CL
                count = self.registers.regRead( registers.CPU_REGISTER_CL )
            else:
                self.main.exitError("group0F: SHRD: operOpcode {0:#04x} unknown.".format(operOpcode))
            count %= 32
            if (count == 0):
                pass
            else:
                if (count > bitSize): # bad parameters
                    self.main.exitError("group0F: SHRD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).".format(count, bitSize, operOpcode))
                else:
                    dest = self.registers.modRMLoad(rmOperands, operSize)
                    oldDest = dest
                    src  = self.registers.modRLoad(rmOperands, operSize)
                    newCF = self.registers.valGetBit(dest, count-1)!=0
                    for i in range(bitSize-count):
                        tmpBit = self.registers.valGetBit(dest, i+count)
                        dest = self.registers.valSetBit(dest, i, tmpBit)
                    for i in range(bitSize-count, bitSize):
                        tmpBit = self.registers.valGetBit(src, i+count-bitSize)
                        dest = self.registers.valSetBit(dest, i, tmpBit)
                    
                    
                    self.registers.modRMSave(rmOperands, operSize, dest)
                    if (count == 1):
                        newOF = (oldDest&halfOperMask)!=(dest&halfOperMask)
                        self.registers.setEFLAG( registers.FLAG_OF, newOF )
                    self.registers.setEFLAG( registers.FLAG_CF, newCF )
                    self.registers.setSZP(dest, operSize)
        elif (operOpcode == 0xaf): # IMUL R16_32, R/M16_32
            operMask = self.main.misc.getBitMask(operSize)
            rmOperands = self.registers.modRMOperands(operSize)
            operOp1 = self.registers.modRLoad(rmOperands, operSize, signed=True)
            operOp2 = self.registers.modRMLoad(rmOperands, operSize, signed=True)
            operSum = operOp1*operOp2
            self.registers.modRSave(rmOperands, operSize, operSum&operMask)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_MUL, signed=True)
        elif (operOpcode == 0xb2): # LSS
            self.lfpFunc(registers.CPU_SEGMENT_SS) # 'load far pointer' function
        elif (operOpcode == 0xb4): # LFS
            self.lfpFunc(registers.CPU_SEGMENT_FS) # 'load far pointer' function
        elif (operOpcode == 0xb5): # LGS
            self.lfpFunc(registers.CPU_SEGMENT_GS) # 'load far pointer' function
        elif (operOpcode == 0xb6): # MOVZX R16_32, R/M8
            operMask = self.main.misc.getBitMask(operSize)
            rmOperandsRM8 = self.registers.modRMOperandsResetEip(misc.OP_SIZE_8BIT)
            rmOperandsR16_32 = self.registers.modRMOperands(operSize)
            rmOperands = (rmOperandsR16_32[0], rmOperandsRM8[1], rmOperandsR16_32[2])
            op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
            self.registers.modRSave(rmOperands, operSize, op2)
        elif (operOpcode == 0xb7): # MOVZX R32, R/M16
            rmOperandsRM16 = self.registers.modRMOperandsResetEip(misc.OP_SIZE_16BIT)
            rmOperands = self.registers.modRMOperands(misc.OP_SIZE_32BIT)
            rmOperands = (rmOperands[0], rmOperandsRM16[1], rmOperands[2])
            op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_16BIT)
            self.registers.modRSave(rmOperands, misc.OP_SIZE_32BIT, op2)
        elif (operOpcode == 0xbd): # BSR R16_32, R/M16_32
            rmOperands = self.registers.modRMOperands(operSize)
            src = self.registers.modRMLoad(rmOperands, operSize)
            self.registers.setEFLAG( registers.FLAG_ZF, src==0 )
            self.registers.modRSave(rmOperands, misc.OP_SIZE_32BIT, src.bit_length()-1)
        elif (operOpcode == 0xbe): # MOVSX R16_32, R/M8
            operMask = self.main.misc.getBitMask(operSize)
            rmOperandsRM8 = self.registers.modRMOperandsResetEip(misc.OP_SIZE_8BIT)
            rmOperandsR16_32 = self.registers.modRMOperands(operSize)
            rmOperands = (rmOperandsR16_32[0], rmOperandsRM8[1], rmOperandsR16_32[2])
            op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT, signed=True)
            op2 &= operMask
            self.registers.modRSave(rmOperands, operSize, op2)
        elif (operOpcode == 0xbf): # MOVSX R32, R/M16
            rmOperandsRM16 = self.registers.modRMOperandsResetEip(misc.OP_SIZE_16BIT)
            rmOperands = self.registers.modRMOperands(misc.OP_SIZE_32BIT)
            rmOperands = (rmOperands[0], rmOperandsRM16[1], rmOperands[2])
            op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_16BIT, signed=True)
            op2 &= 0xffffffff
            self.registers.modRSave(rmOperands, misc.OP_SIZE_32BIT, op2)
        else:
            self.main.exitError("opcodeGroup0F: invalid operOpcode. {0:#04x}, savedAddr(PhyEIP): {1:#06x}".format(operOpcode, ))
    def opcodeGroupF0(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        #cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        #cdef long operOp1 = self.registers.modRMLoad(rmOperands, operSize)
        #cdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        operRes = 0
        #if (operOpcodeId == 0):
        if (0):
            pass
        else:
            self.main.exitError("opcodeGroupF0: invalid operOpcode. {0:#04x}, savedAddr(PhyEIP): {1:#06x}".format(operOpcode, ))
    def opcodeGroupFE(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        ##cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        #cdef long operOp1 = self.registers.modRMLoad(rmOperands, operSize)
        #cdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        operRes = 0
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(rmOperands, misc.OP_SIZE_8BIT)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(rmOperands, misc.OP_SIZE_8BIT)
        else:
            self.main.exitError("opcodeGroupFE: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    def opcodeGroupFF(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        ###cdef long operOp1 = self.registers.modRMLoad(rmOperands, operSize)
        ###cdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        operRes = 0
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(rmOperands, operSize)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(rmOperands, operSize)
        elif (operOpcodeId == 2): # 2/CALL NEAR
            eipName = registers.CPU_REGISTER_IP
            if (operSize == misc.OP_SIZE_32BIT):
                eipName = registers.CPU_REGISTER_EIP
            rmValue = rmOperands[1]
            eipAddr = self.registers.modRMLoad(rmOperands, operSize)
            self.stackPushRegId(eipName, operSize)
            self.registers.regWrite(registers.CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 3): # 3/CALL FAR
            segmentName = registers.CPU_SEGMENT_CS
            eipName = registers.CPU_REGISTER_IP
            if (operSize == misc.OP_SIZE_32BIT):
                eipName = registers.CPU_REGISTER_EIP
            rmValue = rmOperands[1]
            op1 = self.registers.getRMValueFull(rmValue[0], operSize)
            eipAddr = self.main.mm.mmReadValue(op1, operSize, segId=rmValue[1])
            segVal = self.main.mm.mmReadValue(op1+operSize, misc.OP_SIZE_16BIT, segId=rmValue[1])
            self.stackPushRegId(segmentName, operSize)
            self.stackPushRegId(eipName, operSize)
            self.registers.regWrite(segmentName, segVal)
            self.registers.regWrite(registers.CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 4): # 4/JMP NEAR
            eipName = registers.CPU_REGISTER_IP
            if (operSize == misc.OP_SIZE_32BIT):
                eipName = registers.CPU_REGISTER_EIP
            eipAddr = self.registers.modRMLoad(rmOperands, operSize)
            self.registers.regWrite(registers.CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 5): # 5/JMP FAR
            segmentName = registers.CPU_SEGMENT_CS
            eipName = registers.CPU_REGISTER_IP
            if (operSize == misc.OP_SIZE_32BIT):
                eipName = registers.CPU_REGISTER_EIP
            rmValue = rmOperands[1]
            op1 = self.registers.getRMValueFull(rmValue[0], operSize)
            eipAddr = self.main.mm.mmReadValue(op1, operSize, segId=rmValue[1])
            segVal = self.main.mm.mmReadValue(op1+operSize, misc.OP_SIZE_16BIT, segId=rmValue[1])
            self.registers.regWrite(segmentName, segVal)
            self.registers.regWrite(registers.CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 6): # 6/PUSH
            operOp1 = self.registers.modRMLoad(rmOperands, operSize)
            self.stackPushValue(operOp1, operSize)
        else:
            self.main.exitError("opcodeGroupFF: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    def incFuncReg(self, regId):
        origCF = self.registers.getEFLAG(registers.FLAG_CF)
        regSize = self.registers.regGetSize(regId)
        bitMask = self.main.misc.getBitMask(regSize)
        op1 = self.registers.regRead(regId)
        op2 = 1
        self.registers.regWrite(regId, (op1+op2)&bitMask)
        self.registers.setFullFlags(op1, op2, regSize, misc.SET_FLAGS_ADD)
        self.registers.setEFLAG(registers.FLAG_CF, origCF)
    def decFuncReg(self, regId):
        origCF = self.registers.getEFLAG(registers.FLAG_CF)
        regSize = self.registers.regGetSize(regId)
        bitMask = self.main.misc.getBitMask(regSize)
        op1 = self.registers.regRead(regId)
        op2 = 1
        self.registers.regWrite(regId, (op1-op2)&bitMask)
        self.registers.setFullFlags(op1, op2, regSize, misc.SET_FLAGS_SUB)
        self.registers.setEFLAG(registers.FLAG_CF, origCF)
    def incFuncRM(self, rmOperands, rmSize): # rmSize in bits
        origCF = self.registers.getEFLAG(registers.FLAG_CF)
        bitMask = self.main.misc.getBitMask(rmSize)
        op1 = self.registers.modRMLoad(rmOperands, rmSize)
        op2 = 1
        self.registers.modRMSave(rmOperands, rmSize, (op1+op2)&bitMask)
        self.registers.setFullFlags(op1, op2, rmSize, misc.SET_FLAGS_ADD)
        self.registers.setEFLAG(registers.FLAG_CF, origCF)
    def decFuncRM(self, rmOperands, rmSize): # rmSize in bits
        origCF = self.registers.getEFLAG(registers.FLAG_CF)
        bitMask = self.main.misc.getBitMask(rmSize)
        op1 = self.registers.modRMLoad(rmOperands, rmSize)
        op2 = 1
        self.registers.modRMSave(rmOperands, rmSize, (op1-op2)&bitMask)
        self.registers.setFullFlags(op1, op2, rmSize, misc.SET_FLAGS_SUB)
        self.registers.setEFLAG(registers.FLAG_CF, origCF)
    def incAX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        self.incFuncReg(regName)
    def incCX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_CX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ECX
        self.incFuncReg(regName)
    def incDX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_DX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDX
        self.incFuncReg(regName)
    def incBX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_BX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBX
        self.incFuncReg(regName)
    def incSP(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_SP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESP
        self.incFuncReg(regName)
    def incBP(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_BP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBP
        self.incFuncReg(regName)
    def incSI(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_SI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESI
        self.incFuncReg(regName)
    def incDI(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_DI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDI
        self.incFuncReg(regName)
    def decAX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        self.decFuncReg(regName)
    def decCX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_CX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ECX
        self.decFuncReg(regName)
    def decDX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_DX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDX
        self.decFuncReg(regName)
    def decBX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_BX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBX
        self.decFuncReg(regName)
    def decSP(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_SP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESP
        self.decFuncReg(regName)
    def decBP(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_BP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBP
        self.decFuncReg(regName)
    def decSI(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_SI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESI
        self.decFuncReg(regName)
    def decDI(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_DI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDI
        self.decFuncReg(regName)
    
    
    def pushAX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        return self.stackPushRegId(regName)
    def pushCX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_CX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ECX
        return self.stackPushRegId(regName)
    def pushDX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_DX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDX
        return self.stackPushRegId(regName)
    def pushBX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_BX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBX
        return self.stackPushRegId(regName)
    def pushSP(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_SP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESP
        return self.stackPushRegId(regName)
    def pushBP(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_BP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBP
        return self.stackPushRegId(regName)
    def pushCS(self):
        return self.stackPushRegId(registers.CPU_SEGMENT_CS)
    def pushDS(self):
        return self.stackPushRegId(registers.CPU_SEGMENT_DS)
    def pushES(self):
        return self.stackPushRegId(registers.CPU_SEGMENT_ES)
    def pushFS(self):
        return self.stackPushRegId(registers.CPU_SEGMENT_FS)
    def pushGS(self):
        return self.stackPushRegId(registers.CPU_SEGMENT_GS)
    def pushSS(self):
        return self.stackPushRegId(registers.CPU_SEGMENT_SS)
    def pushSI(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_SI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESI
        return self.stackPushRegId(regName)
    def pushDI(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_DI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDI
        return self.stackPushRegId(regName)
    def popAX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        return self.stackPopRegId(regName)
    def popCX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_CX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ECX
        return self.stackPopRegId(regName)
    def popDX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_DX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDX
        return self.stackPopRegId(regName)
    def popBX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_BX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBX
        return self.stackPopRegId(regName)
    def popSP(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_SP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESP
        return self.stackPopRegId(regName)
    def popBP(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_BP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBP
        return self.stackPopRegId(regName)
    def popSI(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_SI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESI
        return self.stackPopRegId(regName)
    def popDI(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_DI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDI
        return self.stackPopRegId(regName)
    def popDS(self):
        return self.stackPopRegId(registers.CPU_SEGMENT_DS)
    def popES(self):
        return self.stackPopRegId(registers.CPU_SEGMENT_ES)
    def popFS(self):
        return self.stackPopRegId(registers.CPU_SEGMENT_FS)
    def popGS(self):
        return self.stackPopRegId(registers.CPU_SEGMENT_GS)
    def popSS(self):
        return self.stackPopRegId(registers.CPU_SEGMENT_SS)
    
    def popRM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        return self.stackPopRM(rmOperands, operSize)
    
    
    def lea(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(addrSize)
        rmValue = rmOperands[1]
        mmAddr = self.registers.getRMValueFull(rmValue[0], addrSize)
        ###mmValue = self.main.mm.mmReadValue(mmAddr, misc.OP_SIZE_16BIT, segId=rmValue[1])
        self.registers.modRSave(rmOperands, operSize, mmAddr)
    def retNear(self, imm=0):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        stackAddrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_SS)
        eipName = registers.CPU_REGISTER_IP
        espName = registers.CPU_REGISTER_SP
        if (operSize == misc.OP_SIZE_32BIT):
            eipName = registers.CPU_REGISTER_EIP
        if (stackAddrSize == misc.OP_SIZE_32BIT):
            espName = registers.CPU_REGISTER_ESP
        tempEIP = self.stackPopValue(operSize)
        if (operSize == misc.OP_SIZE_16BIT):
            tempEIP &= 0xffff
        self.registers.regWrite(eipName, tempEIP)
        if (imm):
            self.registers.regAdd(espName, imm&0xffff)
    def retFar(self, imm=0):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        stackAddrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_SS)
        eipName = registers.CPU_REGISTER_IP
        espName = registers.CPU_REGISTER_SP
        if (operSize == misc.OP_SIZE_32BIT):
            eipName = registers.CPU_REGISTER_EIP
        if (stackAddrSize == misc.OP_SIZE_32BIT):
            espName = registers.CPU_REGISTER_ESP
        tempEIP = self.stackPopValue(operSize)
        tempCS = self.stackPopValue(operSize)
        self.registers.regWrite(eipName, tempEIP)
        self.registers.regWrite(registers.CPU_SEGMENT_CS, tempCS)
        if (imm):
            self.registers.regAdd(espName, imm&0xffff)
    def retNearImm(self):
        imm = self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_16BIT) # imm16
        self.retNear(imm)
    def retFarImm(self):
        imm = self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_16BIT) # imm16
        self.retFar(imm)
    def lds(self):
        self.lfpFunc(registers.CPU_SEGMENT_DS) # 'load far pointer' function
    def les(self):
        self.lfpFunc(registers.CPU_SEGMENT_ES) # 'load far pointer' function
    def lfpFunc(self, segId): # 'load far pointer' function
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        rmValue = rmOperands[1]
        mmAddr = self.registers.getRMValueFull(rmValue[0], operSize)
        offsetAddr = self.main.mm.mmReadValue(mmAddr, operSize, segId=rmValue[1])
        segmentAddr = self.main.mm.mmReadValue(mmAddr+operSize, misc.OP_SIZE_16BIT, segId=rmValue[1])
        self.registers.modRSave(rmOperands, operSize, offsetAddr)
        self.registers.regWrite(segId, segmentAddr)
    def xlatb(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        m8 = self.registers.regRead(registers.CPU_REGISTER_AL)
        baseReg = registers.CPU_REGISTER_BX
        if (addrSize == misc.OP_SIZE_32BIT):
            baseReg = registers.CPU_REGISTER_EBX
        baseValue = self.registers.regRead(baseReg)
        data = self.main.mm.mmReadValue(baseValue+m8, misc.OP_SIZE_8BIT)
        self.registers.regWrite(registers.CPU_REGISTER_AL, data)
    def opcodeGroup2_RM8(self): # testTestaNotNegMulImulDivIdiv RM8
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        operOp2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        operRes = 0
        bitMask = 0xff
        bitMaskWord = 0xffff
        halfBitMask = 0x80
        halfBitMaskWord = 0x8000
        if (operOpcodeId in (GROUP2_OP_TEST, GROUP2_OP_TEST_ALIAS)):
            imm8 = self.cpu.getCurrentOpcodeAdd()
            operRes = operOp2&imm8
            self.registers.setSZP_C0_O0(operRes, misc.OP_SIZE_8BIT)
        elif (operOpcodeId == GROUP2_OP_NOT):
            operRes = (~operOp2)&bitMask
            self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setEFLAG(registers.FLAG_ZF, operRes==0)
        elif (operOpcodeId == GROUP2_OP_NEG):
            operRes = (-operOp2)&bitMask
            self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            #self.registers.setSZP_C0_O0_SubAF(operRes, misc.OP_SIZE_8BIT)
            self.registers.setFullFlags(0, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP2_OP_MUL):
            operOp1 = self.registers.regRead(registers.CPU_REGISTER_AL)
            operSum = operOp1*operOp2
            self.registers.regWrite(registers.CPU_REGISTER_AX, operSum&bitMaskWord)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_MUL)
        elif (operOpcodeId == GROUP2_OP_IMUL):
            operOp1 = self.registers.regRead(registers.CPU_REGISTER_AL, signed=True)
            operOp2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT, signed=True)
            operSum = operOp1*operOp2
            self.registers.regWrite(registers.CPU_REGISTER_AX, operSum&bitMaskWord)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_MUL, signed=True)
        elif (operOpcodeId == GROUP2_OP_DIV):
            axReg = registers.CPU_REGISTER_AX
            operOp1 = self.registers.regRead(axReg)
            if (operOp2 == 0):
                self.cpu.exception(misc.CPU_EXCEPTION_DE)
                return
            temp, tempmod = divmod(operOp1, operOp2)
            if (temp > bitMask):
                self.cpu.exception(misc.CPU_EXCEPTION_DE)
                return
            self.registers.regWrite(registers.CPU_REGISTER_AL, temp&bitMask)
            self.registers.regWrite(registers.CPU_REGISTER_AH, tempmod&bitMask)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_DIV)
        elif (operOpcodeId == GROUP2_OP_IDIV):
            axReg = registers.CPU_REGISTER_AX
            operOp1  = self.registers.regRead(axReg, signed=True)
            origOperOp2  = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT, signed=True)
            operOp2  = (origOperOp2 < 0 and -origOperOp2) or origOperOp2
            if (operOp2 == 0):
                self.cpu.exception(misc.CPU_EXCEPTION_DE)
                return
            temp, tempmod = divmod(operOp1, operOp2)
            ###temp = self.registers.unsignedToSigned(temp&bitMask, misc.OP_SIZE_8BIT)
            if (origOperOp2 != operOp2):
                temp = -temp
            if ( ((temp >= halfBitMask) or (temp < -halfBitMask))):
                self.cpu.exception(misc.CPU_EXCEPTION_DE)
                return
            self.registers.regWrite(registers.CPU_REGISTER_AL, temp&bitMask)
            self.registers.regWrite(registers.CPU_REGISTER_AH, tempmod&bitMask)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_DIV)
        else:
            self.main.exitError("opcodeGroup2_RM8: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    def opcodeGroup2_RM16_32(self): # testTestaNotNegMulImulDivIdiv RM16_32
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        operOp2 = self.registers.modRMLoad(rmOperands, operSize)
        operRes = 0
        operSizeInBits = operSize * 8
        bitMask = self.main.misc.getBitMask(operSize)
        bitMaskHalf = self.main.misc.getBitMask(operSize, half=True, minus=0) # 0x8000..
        doubleBitMask = self.main.misc.getBitMask(operSize*2)
        doubleBitMaskHalf = self.main.misc.getBitMask(operSize*2, half=True, minus=0) # 0x8000..
        if (operOpcodeId in (GROUP2_OP_TEST, GROUP2_OP_TEST_ALIAS)):
            imm16_32 = self.cpu.getCurrentOpcodeAdd(operSize)
            operRes = operOp2&imm16_32
            self.registers.setSZP_C0_O0(operRes, operSize)
        elif (operOpcodeId == GROUP2_OP_NOT):
            operRes = (~operOp2)&bitMask
            self.registers.modRMSave(rmOperands, operSize, operRes)
            self.registers.setEFLAG(registers.FLAG_ZF, operRes==0)
        elif (operOpcodeId == GROUP2_OP_NEG):
            operRes = (-operOp2)&bitMask
            self.registers.modRMSave(rmOperands, operSize, operRes)
            #self.registers.setSZP_C0_O0_SubAF(operRes, operSize)
            self.registers.setFullFlags(0, operOp2, operSize, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP2_OP_MUL):
            eaxReg = registers.CPU_REGISTER_AX
            edxReg = registers.CPU_REGISTER_DX
            if (operSize == misc.OP_SIZE_32BIT):
                eaxReg = registers.CPU_REGISTER_EAX
                edxReg = registers.CPU_REGISTER_EDX
            operOp1 = self.registers.regRead(eaxReg)
            operSum = operOp1*operOp2
            self.registers.regWrite(edxReg, (operSum>>operSizeInBits)&bitMask)
            self.registers.regWrite(eaxReg, operSum&bitMask)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_MUL)
        elif (operOpcodeId == GROUP2_OP_IMUL):
            eaxReg = registers.CPU_REGISTER_AX
            edxReg = registers.CPU_REGISTER_DX
            if (operSize == misc.OP_SIZE_32BIT):
                eaxReg = registers.CPU_REGISTER_EAX
                edxReg = registers.CPU_REGISTER_EDX
            operOp1 = self.registers.regRead(eaxReg, signed=True)
            operOp2 = self.registers.modRMLoad(rmOperands, operSize, signed=True)
            operSum = operOp1*operOp2
            self.registers.regWrite(edxReg, (operSum>>operSizeInBits)&bitMask)
            self.registers.regWrite(eaxReg, operSum&bitMask)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_MUL, signed=True)
        elif (operOpcodeId == GROUP2_OP_DIV):
            eaxReg = registers.CPU_REGISTER_AX
            edxReg = registers.CPU_REGISTER_DX
            if (operSize == misc.OP_SIZE_32BIT):
                eaxReg = registers.CPU_REGISTER_EAX
                edxReg = registers.CPU_REGISTER_EDX
            operOp1  = self.registers.regRead(eaxReg)
            operOp1 |= self.registers.regRead(edxReg)<<operSizeInBits
            if (operOp2 == 0):
                self.cpu.exception(misc.CPU_EXCEPTION_DE)
                return
            temp, tempmod = divmod(operOp1, operOp2)
            if (temp > bitMask):
                self.cpu.exception(misc.CPU_EXCEPTION_DE)
                return
            self.registers.regWrite(eaxReg, temp&bitMask)
            self.registers.regWrite(edxReg, tempmod&bitMask)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_DIV)
        elif (operOpcodeId == GROUP2_OP_IDIV):
            eaxReg = registers.CPU_REGISTER_AX
            edxReg = registers.CPU_REGISTER_DX
            if (operSize == misc.OP_SIZE_32BIT):
                eaxReg = registers.CPU_REGISTER_EAX
                edxReg = registers.CPU_REGISTER_EDX
            operOp1  = (self.registers.regRead(eaxReg, signed=False)&bitMask)
            operOp1 |= (self.registers.regRead(edxReg, signed=False)&bitMask)<<operSizeInBits
            operOp1 = self.registers.unsignedToSigned(operOp1, operSize*2)
            operOp2 = self.registers.modRMLoad(rmOperands, operSize, signed=True)
            if (operOp2 == 0):
                self.cpu.exception(misc.CPU_EXCEPTION_DE)
                return
            temp, tempmod = divmod(operOp1, operOp2)
            if ( ((-temp >= bitMaskHalf) or (-temp < -bitMaskHalf)) ):
                self.cpu.exception(misc.CPU_EXCEPTION_DE)
                return
            self.registers.regWrite(eaxReg, temp&bitMask)
            self.registers.regWrite(edxReg, tempmod&bitMask)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_DIV)
        else:
            self.main.exitError("opcodeGroup2_RM16_32: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    def interrupt(self, intNum=None, errorCode=None):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        segId = registers.CPU_SEGMENT_DS
        if (intNum == None):
            intNum = self.cpu.getCurrentOpcodeAdd()
        self.stackPushRegId(registers.CPU_REGISTER_FLAGS, operSize)
        self.registers.clearFlags(registers.FLAG_IF | registers.FLAG_TF | registers.FLAG_AC)
        self.stackPushRegId(registers.CPU_SEGMENT_CS, operSize)
        self.stackPushRegId(registers.CPU_REGISTER_IP, operSize)
        if (errorCode != None):
            self.stackPushValue(errorCode, operSize)
        if (operSize == misc.OP_SIZE_16BIT):
            entrySegment, entryEip = self.registers.segments.idt.getEntryRealMode(intNum)
        elif (operSize == misc.OP_SIZE_32BIT):
            entrySegment, entryEip = self.registers.segments.idt.getEntry(intNum)
        self.registers.regWrite(registers.CPU_SEGMENT_CS, entrySegment)
        self.registers.regWrite(registers.CPU_REGISTER_EIP, entryEip)
        #else:
        #    self.main.exitError("interrupt: 32-bit mode not supported yet. (intNum: {0:#04x})".format(intNum))
    def into(self):
        if (self.registers.getEFLAG( registers.FLAG_OF )):
            self.interrupt(intNum=4)
    def iret(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        if (operSize == misc.OP_SIZE_32BIT):
            self.stackPopRegId(registers.CPU_REGISTER_EIP, misc.OP_SIZE_32BIT)
            self.stackPopRegId(registers.CPU_SEGMENT_CS, misc.OP_SIZE_32BIT)
            tempEFLAGS = self.stackPopValue(misc.OP_SIZE_32BIT)
            EFLAGS = self.registers.regRead(registers.CPU_REGISTER_EFLAGS)
            self.registers.regWrite(registers.CPU_REGISTER_EFLAGS, ((tempEFLAGS & 0x257fd5) | (EFLAGS & 0x1a0000)) )
        elif (operSize == misc.OP_SIZE_16BIT):
            self.stackPopRegId(registers.CPU_REGISTER_EIP, misc.OP_SIZE_16BIT)
            self.stackPopRegId(registers.CPU_SEGMENT_CS, misc.OP_SIZE_16BIT)
            self.stackPopRegId(registers.CPU_REGISTER_FLAGS, misc.OP_SIZE_16BIT)
    def aad(self):
        imm8 = self.cpu.getCurrentOpcodeAdd()
        tempAL = self.registers.regRead(registers.CPU_REGISTER_AL)
        tempAH = self.registers.regRead(registers.CPU_REGISTER_AH)
        self.registers.regWrite(registers.CPU_REGISTER_AL, ( tempAL + (tempAH * imm8) )&0xff)
        self.registers.regWrite(registers.CPU_REGISTER_AH, 0)
        ALtest = self.registers.regRead(registers.CPU_REGISTER_AL)
        self.registers.setSZP_C0_O0(ALtest, misc.OP_SIZE_8BIT)
    def aam(self):
        imm8 = self.cpu.getCurrentOpcodeAdd()
        if (imm8 == 0):
            self.cpu.exception(misc.CPU_EXCEPTION_DE)
            return
        tempAL = self.registers.regRead(registers.CPU_REGISTER_AL)
        ALdiv, ALmod = divmod(tempAL, imm8)
        self.registers.regWrite(registers.CPU_REGISTER_AH, ALdiv)
        self.registers.regWrite(registers.CPU_REGISTER_AL, ALmod)
        self.registers.setSZP_C0_O0(ALmod, misc.OP_SIZE_8BIT)
    def aaa(self):
        tempAX = self.registers.regRead(registers.CPU_REGISTER_AX)
        tempAL = tempAX&0xff
        tempAH = (tempAX>>8)&0xff
        AFflag = self.registers.getEFLAG(registers.FLAG_AF)
        if (((tempAL&0xf)>9) or AFflag):
            tempAL += 6
            self.registers.setFlags(registers.FLAG_AF | registers.FLAG_CF)
            self.registers.regWrite(registers.CPU_REGISTER_AH, tempAH+1)
            self.registers.regWrite(registers.CPU_REGISTER_AL, tempAL&0xf)
        else:
            self.registers.clearFlags(registers.FLAG_AF | registers.FLAG_CF)
            self.registers.regWrite(registers.CPU_REGISTER_AL, tempAX&0xf)
        self.registers.setSZP_O0(self.registers.regRead(registers.CPU_REGISTER_AL), misc.OP_SIZE_8BIT)
    def aas(self):
        tempAX = self.registers.regRead(registers.CPU_REGISTER_AX)
        tempAL = tempAX&0xff
        tempAH = (tempAX>>8)&0xff
        AFflag = self.registers.getEFLAG(registers.FLAG_AF)
        if (((tempAL&0xf)>9) or AFflag):
            tempAL -= 6
            self.registers.setFlags(registers.FLAG_AF | registers.FLAG_CF)
            self.registers.regWrite(registers.CPU_REGISTER_AH, tempAH-1)
            self.registers.regWrite(registers.CPU_REGISTER_AL, tempAL&0xf)
        else:
            self.registers.clearFlags(registers.FLAG_AF | registers.FLAG_CF)
            self.registers.regWrite(registers.CPU_REGISTER_AL, tempAX&0xf)
        self.registers.setSZP_O0(self.registers.regRead(registers.CPU_REGISTER_AL), misc.OP_SIZE_8BIT)
    def daa(self):
        old_AL = self.registers.regRead(registers.CPU_REGISTER_AL)
        old_AF = self.registers.getEFLAG(registers.FLAG_AF)
        old_CF = self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.setEFLAG(registers.FLAG_CF, False)
        if (((old_AL&0xf)>9) or old_AF):
            self.registers.regWrite(registers.CPU_REGISTER_AL, old_AL+6)
            self.registers.setEFLAG(registers.FLAG_CF, old_CF or (old_AL+6>0xff))
            self.registers.setEFLAG(registers.FLAG_AF, True)
        else:
            self.registers.setEFLAG(registers.FLAG_AF, False)
        if ((old_AL > 0x99) or old_CF):
            self.registers.regAdd(registers.CPU_REGISTER_AL, 0x60)
            self.registers.setEFLAG(registers.FLAG_CF, True)
        else:
            self.registers.setEFLAG(registers.FLAG_CF, False)
        self.registers.setSZP_O0(self.registers.regRead(registers.CPU_REGISTER_AL), misc.OP_SIZE_8BIT)
    def das(self):
        old_AL = self.registers.regRead(registers.CPU_REGISTER_AL)
        old_AF = self.registers.getEFLAG(registers.FLAG_AF)
        old_CF = self.registers.getEFLAG(registers.FLAG_CF)
        self.registers.setEFLAG(registers.FLAG_CF, False)
        if (((old_AL&0xf)>9) or old_AF):
            self.registers.regWrite(registers.CPU_REGISTER_AL, old_AL-6)
            self.registers.setEFLAG(registers.FLAG_CF, old_CF or (old_AL-6<0))
            self.registers.setEFLAG(registers.FLAG_AF, True)
        else:
            self.registers.setEFLAG(registers.FLAG_AF, False)
        if ((old_AL > 0x99) or old_CF):
            self.registers.regSub(registers.CPU_REGISTER_AL, 0x60)
            self.registers.setEFLAG(registers.FLAG_CF, True)
        self.registers.setSZP_O0(self.registers.regRead(registers.CPU_REGISTER_AL), misc.OP_SIZE_8BIT)
    def cbw_cwde(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        bitMask = self.main.misc.getBitMask(operSize)
        if (operSize == misc.OP_SIZE_16BIT):
            old_AL = self.registers.regRead(registers.CPU_REGISTER_AL)
            if (old_AL&0x80):
                self.registers.regWrite(registers.CPU_REGISTER_AH, 0xff)
            else:
                self.registers.regWrite(registers.CPU_REGISTER_AH, 0x00)
        elif (operSize == misc.OP_SIZE_32BIT):
            old_AX = self.registers.regRead(registers.CPU_REGISTER_AX)
            if (old_AX&0x8000):
                self.registers.regWrite(registers.CPU_REGISTER_EAX, 0xffff0000|old_AX)
            else:
                self.registers.regWrite(registers.CPU_REGISTER_EAX, old_AX)
        else:
            self.main.exitError("cbw_cwde: operSize {0:d} not in (OP_SIZE_16BIT, OP_SIZE_32BIT))".format(operSize))
    def cwd_cdq(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        bitMask = self.main.misc.getBitMask(operSize)
        if (operSize == misc.OP_SIZE_16BIT):
            old_AX = self.registers.regRead(registers.CPU_REGISTER_AX)
            if (old_AX&0x8000):
                self.registers.regWrite(registers.CPU_REGISTER_DX, 0xffff)
            else:
                self.registers.regWrite(registers.CPU_REGISTER_DX, 0x0)
        elif (operSize == misc.OP_SIZE_32BIT):
            old_EAX = self.registers.regRead(registers.CPU_REGISTER_EAX)
            if (old_EAX&0x80000000):
                self.registers.regWrite(registers.CPU_REGISTER_EDX, 0xffffffff)
            else:
                self.registers.regWrite(registers.CPU_REGISTER_EDX, 0x0)
        else:
            self.main.exitError("cwd_cdq: operSize {0:d} not in (OP_SIZE_16BIT, OP_SIZE_32BIT))".format(operSize))
    def shlFunc(self, rmOperands, operSize, count):
        bitMask = self.main.misc.getBitMask(operSize)
        halfOperMask = self.main.misc.getBitMask(operSize, half=True, minus=0)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        countWithMask = count&0x1f
        if (countWithMask == 0):
            newCF = False
        else:
            newCF = ((dest<<(countWithMask-1))&halfOperMask)!=0
        dest <<= countWithMask
        dest &= bitMask
        self.registers.modRMSave(rmOperands, operSize, dest)
        if (countWithMask == 0):
            return
        if (countWithMask == 1):
            newOF = ( ((dest&halfOperMask)!=0)^newCF )
            self.registers.setEFLAG( registers.FLAG_OF, newOF )
        else:
            self.registers.setEFLAG( registers.FLAG_OF, False )
        self.registers.setEFLAG( registers.FLAG_CF, newCF )
        self.registers.setSZP(dest, operSize)
        
    
    
    
    def sarFunc(self, rmOperands, operSize, count):
        bitMask = self.main.misc.getBitMask(operSize)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        dest = self.registers.unsignedToSigned(dest, operSize)
        countWithMask = count&0x1f
        if (countWithMask == 0):
            newCF = ((dest)&1)
        else:
            newCF = ((dest>>(countWithMask-1))&1)
        dest >>= countWithMask
        dest &= bitMask
        self.registers.modRMSave(rmOperands, operSize, dest)
        if (countWithMask == 0):
            return
        if (countWithMask == 1):
            newOF = False
            self.registers.setEFLAG( registers.FLAG_OF, newOF )
        self.registers.setEFLAG( registers.FLAG_CF, newCF )
        self.registers.setSZP(dest, operSize)
        
    
    
    
    def shrFunc(self, rmOperands, operSize, count):
        bitMask = self.main.misc.getBitMask(operSize)
        halfOperMask = self.main.misc.getBitMask(operSize, half=True, minus=0)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        tempDest = dest
        countWithMask = count&0x1f
        if (countWithMask == 0):
            newCF = ((dest)&1)
        else:
            newCF = ((dest>>(countWithMask-1))&1)
        dest >>= countWithMask
        dest &= bitMask
        self.registers.modRMSave(rmOperands, operSize, dest)
        if (countWithMask == 0):
            return
        #if (countWithMask == 1):
        if (1):
            newOF = ((tempDest)&halfOperMask)!=0
            self.registers.setEFLAG( registers.FLAG_OF, newOF )
        self.registers.setEFLAG( registers.FLAG_CF, newCF )
        self.registers.setSZP(dest, operSize)
        
    
    
    
    def rclFunc(self, rmOperands, operSize, count):
        bitMask = self.main.misc.getBitMask(operSize)
        halfOperMask = self.main.misc.getBitMask(operSize, half=True, minus=0)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        tempCount = count&0x1f
        if (operSize == misc.OP_SIZE_8BIT):
            tempCount %= 9
        elif (operSize == misc.OP_SIZE_16BIT):
            tempCount %= 17
        newCF = self.registers.getEFLAG( registers.FLAG_CF )
        for i in range(tempCount):
            tempCF = (dest&halfOperMask)!=0
            dest = (dest<<1)|newCF
            newCF = tempCF
        dest &= bitMask
        self.registers.modRMSave(rmOperands, operSize, dest)
        if (tempCount == 0):
            return
        #if (count == 1):
        if (1):
            newOF = ( ((dest&halfOperMask)!=0)^newCF )
            self.registers.setEFLAG( registers.FLAG_OF, newOF )
        #else:
        #    self.registers.setEFLAG( registers.FLAG_OF, False )
        self.registers.setEFLAG( registers.FLAG_CF, newCF )
        
    
    
    
    
    
    
    def rcrFunc(self, rmOperands, operSize, count):
        bitMask = self.main.misc.getBitMask(operSize)
        halfOperMask = self.main.misc.getBitMask(operSize, half=True, minus=0)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        tempDest = dest
        tempCount = count&0x1f
        newCF = self.registers.getEFLAG( registers.FLAG_CF )
        if (operSize == misc.OP_SIZE_8BIT):
            tempCount %= 9
        elif (operSize == misc.OP_SIZE_16BIT):
            tempCount %= 17
        
        if (tempCount == 0):
            return
        #if (count == 1):
        if (1):
            newOF = ( ((dest&halfOperMask)!=0)^newCF )
            self.registers.setEFLAG( registers.FLAG_OF, newOF )
        #elif (tempCount != 0):
        #    self.registers.setEFLAG( registers.FLAG_OF, False )
        
        for i in range(tempCount):
            tempCF = (dest&1)!=0
            dest = (dest >> 1) | (newCF * halfOperMask)
            newCF = tempCF
        dest &= bitMask
        
        self.registers.modRMSave(rmOperands, operSize, dest)
        self.registers.setEFLAG( registers.FLAG_CF, newCF )
    
    
    
    
    def rolFunc(self, rmOperands, operSize, count):
        bitMask = self.main.misc.getBitMask(operSize)
        halfOperMask = self.main.misc.getBitMask(operSize, half=True, minus=0)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        
        
        
        if ((count & 0x1f) > 0):
            tempCount = count%(operSize*8)
            
            for i in range(tempCount):
                tempCF = (dest&halfOperMask)!=0
                dest = (dest << 1) | tempCF
            
            self.registers.modRMSave(rmOperands, operSize, dest)
            
            if (tempCount == 0):
                return
            newCF = dest&1
            self.registers.setEFLAG( registers.FLAG_CF, newCF )
            #if (count == 1):
            if (1):
                newOF = ( ((dest&halfOperMask)!=0)^newCF )
                self.registers.setEFLAG( registers.FLAG_OF, newOF )
            #else:
            #    self.registers.setEFLAG( registers.FLAG_OF, False )
            
    
    
    
    
    def rorFunc(self, rmOperands, operSize, count):
        bitMask = self.main.misc.getBitMask(operSize)
        halfOperMask = self.main.misc.getBitMask(operSize, half=True, minus=0)
        dest = self.registers.modRMLoad(rmOperands, operSize)
        destM1 = dest
        
        if ((count & 0x1f) > 0):
            tempCount = count%(operSize*8)
            
            for i in range(tempCount-1):
                tempCF = destM1&1
                destM1 = (destM1 >> 1) | (tempCF * halfOperMask)
            
            tempCF = destM1&1
            dest = (destM1 >> 1) | (tempCF * halfOperMask)
            
            self.registers.modRMSave(rmOperands, operSize, dest)
            
            if (tempCount == 0):
                return
            newCF = (dest&halfOperMask)!=0
            newCF_M1 = (destM1&halfOperMask)!=0
            self.registers.setEFLAG( registers.FLAG_CF, newCF )
            #if (count == 1):
            if (1):
                newOF = ( newCF ^ newCF_M1 )
                self.registers.setEFLAG( registers.FLAG_OF, newOF )
            #else:
            #    self.registers.setEFLAG( registers.FLAG_OF, False )
            
    
    
    
    
    
    
    def opcodeGroup4_RM8_1(self): # rolRorRclRcrShlSalShrSar RM8
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        if (operOpcodeId in (GROUP4_OP_SHL_SAL, GROUP4_OP_SHL_SAL_ALIAS)):
            self.shlFunc(rmOperands, misc.OP_SIZE_8BIT, 1)
        elif (operOpcodeId == GROUP4_OP_SAR):
            self.sarFunc(rmOperands, misc.OP_SIZE_8BIT, 1)
        elif (operOpcodeId == GROUP4_OP_SHR):
            self.shrFunc(rmOperands, misc.OP_SIZE_8BIT, 1)
        elif (operOpcodeId == GROUP4_OP_RCL):
            self.rclFunc(rmOperands, misc.OP_SIZE_8BIT, 1)
        elif (operOpcodeId == GROUP4_OP_RCR):
            self.rcrFunc(rmOperands, misc.OP_SIZE_8BIT, 1)
        elif (operOpcodeId == GROUP4_OP_ROL):
            self.rolFunc(rmOperands, misc.OP_SIZE_8BIT, 1)
        elif (operOpcodeId == GROUP4_OP_ROR):
            self.rorFunc(rmOperands, misc.OP_SIZE_8BIT, 1)
        else:
            self.main.exitError("opcodeGroup4_RM8_1: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    def opcodeGroup4_RM16_32_1(self): # rolRorRclRcrShlSalShrSar RM16_32
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
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
            self.main.exitError("opcodeGroup4_RM16_32_1: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    
    
    
    
    def opcodeGroup4_RM8_CL(self): # rolRorRclRcrShlSalShrSar RM8
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        count = self.registers.regRead(registers.CPU_REGISTER_CL)
        if (operOpcodeId in (GROUP4_OP_SHL_SAL, GROUP4_OP_SHL_SAL_ALIAS)):
            self.shlFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        elif (operOpcodeId == GROUP4_OP_SAR):
            self.sarFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        elif (operOpcodeId == GROUP4_OP_SHR):
            self.shrFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        elif (operOpcodeId == GROUP4_OP_RCL):
            self.rclFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        elif (operOpcodeId == GROUP4_OP_RCR):
            self.rcrFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        elif (operOpcodeId == GROUP4_OP_ROL):
            self.rolFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        elif (operOpcodeId == GROUP4_OP_ROR):
            self.rorFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        else:
            self.main.exitError("opcodeGroup4_RM8_1: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    def opcodeGroup4_RM16_32_CL(self): # rolRorRclRcrShlSalShrSar RM16_32
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize)
        count = self.registers.regRead(registers.CPU_REGISTER_CL)
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
            self.main.exitError("opcodeGroup4_RM16_32_1: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    
    
    
    
    
    def opcodeGroup4_RM8_IMM8(self): # rolRorRclRcrShlSalShrSar RM8
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode()
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        count = self.cpu.getCurrentOpcodeAdd()
        if (operOpcodeId in (GROUP4_OP_SHL_SAL, GROUP4_OP_SHL_SAL_ALIAS)):
            self.shlFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        elif (operOpcodeId == GROUP4_OP_SAR):
            self.sarFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        elif (operOpcodeId == GROUP4_OP_SHR):
            self.shrFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        elif (operOpcodeId == GROUP4_OP_RCL):
            self.rclFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        elif (operOpcodeId == GROUP4_OP_RCR):
            self.rcrFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        elif (operOpcodeId == GROUP4_OP_ROL):
            self.rolFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        elif (operOpcodeId == GROUP4_OP_ROR):
            self.rorFunc(rmOperands, misc.OP_SIZE_8BIT, count )
        else:
            self.main.exitError("opcodeGroup4_RM8_1: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    def opcodeGroup4_RM16_32_IMM8(self): # rolRorRclRcrShlSalShrSar RM16_32
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
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
            self.main.exitError("opcodeGroup4_RM16_32_1: invalid operOpcodeId. 0x{0:x}".format(operOpcodeId))
    
    
    
    
    
    
    
    
    def sahf(self):
        ahVal = self.registers.regRead( registers.CPU_REGISTER_AH )
        self.registers.setEFLAG( registers.FLAG_CF, ahVal & registers.FLAG_CF )
        self.registers.setEFLAG( registers.FLAG_PF, ahVal & registers.FLAG_PF )
        self.registers.setEFLAG( registers.FLAG_AF, ahVal & registers.FLAG_AF )
        self.registers.setEFLAG( registers.FLAG_ZF, ahVal & registers.FLAG_ZF )
        self.registers.setEFLAG( registers.FLAG_SF, ahVal & registers.FLAG_SF )
    def lahf(self):
        newAH = 0x2
        newAH |= self.registers.getEFLAG( registers.FLAG_CF ) and registers.FLAG_CF
        newAH |= self.registers.getEFLAG( registers.FLAG_PF ) and registers.FLAG_PF
        newAH |= self.registers.getEFLAG( registers.FLAG_AF ) and registers.FLAG_AF
        newAH |= self.registers.getEFLAG( registers.FLAG_ZF ) and registers.FLAG_ZF
        newAH |= self.registers.getEFLAG( registers.FLAG_SF ) and registers.FLAG_SF
        self.registers.regWrite( registers.CPU_REGISTER_AH, newAH )
    
    
    
    def xchgFuncReg(self, regName, regName2):
        regValue, regValue2 = self.registers.regRead( regName ), self.registers.regRead( regName2 )
        
        self.registers.regWrite( regName, regValue2 )
        self.registers.regWrite( regName2, regValue )
    def xchgAX(self): # xchg ax, ax == nop, so don't use it for opcode 0x90
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        
        regName2  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName2 = registers.CPU_REGISTER_EAX
        
        self.xchgFuncReg(regName, regName2)
    def xchgCX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        
        regName2  = registers.CPU_REGISTER_CX
        if (operSize == misc.OP_SIZE_32BIT):
            regName2 = registers.CPU_REGISTER_ECX
        
        self.xchgFuncReg(regName, regName2)
    def xchgDX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        
        regName2  = registers.CPU_REGISTER_DX
        if (operSize == misc.OP_SIZE_32BIT):
            regName2 = registers.CPU_REGISTER_EDX
        
        self.xchgFuncReg(regName, regName2)
    def xchgBX(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        
        regName2  = registers.CPU_REGISTER_BX
        if (operSize == misc.OP_SIZE_32BIT):
            regName2 = registers.CPU_REGISTER_EBX
        
        self.xchgFuncReg(regName, regName2)
    def xchgSP(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        
        regName2  = registers.CPU_REGISTER_SP
        if (operSize == misc.OP_SIZE_32BIT):
            regName2 = registers.CPU_REGISTER_ESP
        
        self.xchgFuncReg(regName, regName2)
    def xchgBP(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        
        regName2  = registers.CPU_REGISTER_BP
        if (operSize == misc.OP_SIZE_32BIT):
            regName2 = registers.CPU_REGISTER_EBP
        
        self.xchgFuncReg(regName, regName2)
    def xchgSI(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        
        regName2  = registers.CPU_REGISTER_SI
        if (operSize == misc.OP_SIZE_32BIT):
            regName2 = registers.CPU_REGISTER_ESI
        
        self.xchgFuncReg(regName, regName2)
    def xchgDI(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        
        regName2  = registers.CPU_REGISTER_DI
        if (operSize == misc.OP_SIZE_32BIT):
            regName2 = registers.CPU_REGISTER_EDI
        
        self.xchgFuncReg(regName, regName2)
    
    def xchgR8_RM8(self):
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        op1 = self.registers.modRLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 = self.registers.modRMLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, op1)
        self.registers.modRSave(rmOperands, misc.OP_SIZE_8BIT, op2)
    def xchgR16_32_RM16_32(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize)
        op1 = self.registers.modRLoad(rmOperands, operSize)
        op2 = self.registers.modRMLoad(rmOperands, operSize)
        self.registers.modRMSave(rmOperands, operSize, op1)
        self.registers.modRSave(rmOperands, operSize, op2)
    def enter(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        stackSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_SS)
        #sizeOp = 
        self.main.exitError("ENTER: not implemented yet.".format())
    def leave(self):
        operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        stackSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_SS)
        spName = registers.CPU_REGISTER_SP
        bpName = registers.CPU_REGISTER_BP
        espName = registers.CPU_REGISTER_ESP
        ebpName = registers.CPU_REGISTER_EBP
        if (stackSize == misc.OP_SIZE_32BIT):
            self.registers.regWrite(espName, self.registers.regRead(ebpName) )
        elif (stackSize == misc.OP_SIZE_16BIT):
            self.registers.regWrite(spName, self.registers.regRead(bpName) )
        if (operSize == misc.OP_SIZE_32BIT):
            self.stackPopRegId( ebpName, operSize )
        elif (operSize == misc.OP_SIZE_16BIT):
            self.stackPopRegId( bpName, operSize )
    def cmovFunc(self, c): # R16, R/M 16; R32, R/M 32
        self.movR16_32_RM16_32(c)
    def setCondFunc(self, cond): # if cond==True set 1, else 0
        rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        self.registers.modRMSave(rmOperands, misc.OP_SIZE_8BIT, cond!=0)
    
    
    
    
    # end of opcodes



