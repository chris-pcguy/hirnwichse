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

class Opcodes:
    def __init__(self, main, cpu):
        self.main = main
        self.cpu = cpu
        self.registers = self.cpu.registers
        self.opcodeList = {0x00: self.addRM8_R8, 0x01: self.addRM16_32_R16_32, 0x02: self.addR8_RM8, 0x03: self.addR16_32_RM16_32,
                           0x04: self.addAL_IMM8, 0x05: self.addAX_EAX_IMM16_32,
                           0x10: self.adcRM8_R8, 0x11: self.adcRM16_32_R16_32, 0x12: self.adcR8_RM8, 0x13: self.adcR16_32_RM16_32,
                           0x14: self.adcAL_IMM8, 0x15: self.adcAX_EAX_IMM16_32,
                           0x30: self.xorRM8_R8, 0x31: self.xorRM16_32_R16_32,
                           0x3c: self.cmpAlImm8, 0x3d: self.cmpAxEaxImm16_32,
                           0x40: self.incAX, 0x41: self.incCX, 0x42: self.incDX, 0x43: self.incBX,
                           0x44: self.incSP, 0x45: self.incBP, 0x46: self.incSI, 0x47: self.incDI,
                           0x48: self.decAX, 0x49: self.decCX, 0x4a: self.decDX, 0x4b: self.decBX,
                           0x4c: self.decSP, 0x4d: self.decBP, 0x4e: self.decSI, 0x4f: self.decDI,
                           0x72: self.jcShort, 0x73: self.jncShort, 0x74: self.jzShort, 0x75: self.jnzShort,
                           0x76: self.jbeShort, 0x77: self.jaShort, 0x78: self.jsShort, 0x79: self.jnsShort,
                           0x7a: self.jpShort, 0x7b: self.jnpShort, 0x7c: self.jlShort, 0x7d: self.jgeShort,
                           0x7e: self.jleShort, 0x7f: self.jgShort, 
                           0x80: self.opcodeGroup1_RM8_IMM8, 0x81: self.opcodeGroup1_RM16_32_IMM16_32,
                           0x83: self.opcodeGroup1_RM16_32_IMM8,
                           0x88: self.movRM8_R8, 0x89: self.movRM16_32_R16_32,
                           0x8a: self.movR8_RM8, 0x8b: self.movR16_32_RM16_32,
                           0x8c: self.movRM16_SREG, 0x8e: self.movSREG_RM16, 0x9c: self.pushfWD,
                           0xa2: self.movMOFFS8_AL, 0xa3: self.movMOFFS16_32_AX_EAX,
                           0xb0: self.movImm8ToR8, 0xb1: self.movImm8ToR8, 0xb2: self.movImm8ToR8,
                           0xb3: self.movImm8ToR8, 0xb4: self.movImm8ToR8, 0xb5: self.movImm8ToR8,
                           0xb6: self.movImm8ToR8, 0xb7: self.movImm8ToR8, 0xb8: self.movImm16_32ToR16_32,
                           0xb9: self.movImm16_32ToR16_32, 0xba: self.movImm16_32ToR16_32, 0xbb: self.movImm16_32ToR16_32,
                           0xbc: self.movImm16_32ToR16_32, 0xbd: self.movImm16_32ToR16_32, 0xbe: self.movImm16_32ToR16_32,
                           0xbf: self.movImm16_32ToR16_32, 0xc6: self.opcodeGroup3_RM8_IMM8, 0xc7: self.opcodeGroup3_RM16_32_IMM16_32,
                           0xe3: self.jcxzShort, 0xe4: self.inAlImm8, 0xe5: self.inAxEaxImm8, 0xe6: self.outImm8Al, 0xe7: self.outImm8AxEax, 0xe8: self.callNearRel16_32, 0xe9: self.jumpShortRelativeWordDWord,
                           0xea: self.jumpFarAbsolutePtr, 0xeb: self.jumpShortRelativeByte, 0xec: self.inAlDx, 0xed: self.inAxEaxDx, 0xee: self.outDxAl, 0xef: self.outDxAxEax,
                           0xf0: self.opcodeGroupF0, 0xf4: self.hlt,
                           0xfa: self.cli, 0xfb: self.sti, 0xfc: self.cld, 0xfd: self.std,
                           0xfe: self.opcodeGroupFE, 0xff: self.opcodeGroupFF}
    def cli(self):
        self.registers.regDelFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_DF)
    def sti(self):
        self.registers.regSetFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_DF)
    def cld(self):
        self.registers.regDelFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_DF)
    def std(self):
        self.registers.regSetFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_DF)
    def hlt(self):
        self.cpu.cpuHalted = True
    def jumpFarAbsolutePtr(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef long eip = self.cpu.getCurrentOpcodeAddEip()
        cdef long cs = self.cpu.getCurrentOpcodeAdd(2)
        self.registers.regWrite(registers.CPU_SEGMENT_CS, cs)
        self.registers.regWrite(registers.CPU_REGISTER_EIP, eip)
    def jumpShortRelativeByte(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        self.jumpShort(1)
    def jumpShortRelativeWordDWord(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef int offsetSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        self.jumpShort(offsetSize)
    def cmpAlImm8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef long reg0 = self.registers.regRead(registers.CPU_REGISTER_AL)
        cdef long imm8 = self.cpu.getCurrentOpcodeAdd()
        #cdef long cmpSum = reg0-imm8
        self.registers.setFullFlags(reg0, imm8, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    def cmpAxEaxImm16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int axReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            axReg = registers.CPU_REGISTER_EAX
        cdef long reg0 = self.registers.regRead(axReg)
        cdef long imm16_32 = self.cpu.getCurrentOpcodeAdd(operSize)
        #cdef long cmpSum = reg0-imm16_32
        self.registers.setFullFlags(reg0, imm16_32, operSize, misc.SET_FLAGS_SUB)
    def movImm8ToR8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef int r8reg = self.cpu.opcode&0x7
        self.registers.regWrite(registers.CPU_REGISTER_BYTE[r8reg], self.cpu.getCurrentOpcodeAdd())
    def movImm16_32ToR16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef long r16_32reg = self.cpu.opcode&0x7
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        if (operSize == misc.OP_SIZE_16BIT):
            self.registers.regWrite(registers.CPU_REGISTER_WORD[r16_32reg], self.cpu.getCurrentOpcodeAddEip())
        elif (operSize == misc.OP_SIZE_32BIT):
            self.registers.regWrite(registers.CPU_REGISTER_DWORD[r16_32reg], self.cpu.getCurrentOpcodeAddEip())
        else:
            self.main.exitError("operSize is NOT OK ({0:d})", operSize)
    def movRM8_R8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT))
    def movRM16_32_R16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        self.registers.modRM_RSave(rmOperands, operSize, self.registers.modRM_RLoad(rmOperands, operSize))
    def movR8_RM8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        self.registers.modR_RMSave(rmOperands, misc.OP_SIZE_8BIT, self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT))
    def movR16_32_RM16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        self.registers.modR_RMSave(rmOperands, operSize, self.registers.modR_RMLoad(rmOperands, operSize))
    def movRM16_SREG(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_16BIT, registers.MODRM_FLAGS_SREG)
        self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_16BIT, self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_16BIT))
    def movSREG_RM16(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_16BIT, registers.MODRM_FLAGS_SREG)
        self.registers.modR_RMSave(rmOperands, misc.OP_SIZE_16BIT, self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_16BIT))
    def movMOFFS8_AL(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef long mmAddr = self.cpu.getCurrentOpcodeAdd()
        self.main.mm.mmWrite(mmAddr, self.registers.regRead(registers.CPU_REGISTER_AL), 1)
    def movMOFFS16_32_AX_EAX(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        cdef long mmAddr = self.cpu.getCurrentOpcodeAdd(addrSize)
        self.main.mm.mmWrite(mmAddr, self.registers.regRead(regName), addrSize)
    def addRM8_R8(self):
        cdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cdef long op1 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        cdef long op2 = self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    def addRM16_32_R16_32(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cdef long op1 = self.registers.modR_RMLoad(rmOperands, operSize)
        cdef long op2 = self.registers.modRM_RLoad(rmOperands, operSize)
        self.registers.modRM_RSave(rmOperands, operSize, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    def addR8_RM8(self):
        cdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cdef long op1 = self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT)
        cdef long op2 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.modR_RMSave(rmOperands, misc.OP_SIZE_8BIT, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    def addR16_32_RM16_32(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cdef long op1 = self.registers.modRM_RLoad(rmOperands, operSize)
        cdef long op2 = self.registers.modR_RMLoad(rmOperands, operSize)
        self.registers.modR_RMSave(rmOperands, operSize, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    def addAL_IMM8(self):
        cdef long op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        cdef long op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        self.registers.regWrite(registers.CPU_REGISTER_AL, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    def addAX_EAX_IMM16_32(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        cdef long op1 = self.registers.regRead(dataReg)
        cdef long op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        self.registers.regWrite(dataReg, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    def adcRM8_R8(self):
        cdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cdef long op1 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        cdef long op2 = self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT)
        op1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    def adcRM16_32_R16_32(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cdef long op1 = self.registers.modR_RMLoad(rmOperands, operSize)
        cdef long op2 = self.registers.modRM_RLoad(rmOperands, operSize)
        op1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.modRM_RSave(rmOperands, operSize, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    def adcR8_RM8(self):
        cdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cdef long op1 = self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT)
        cdef long op2 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.modR_RMSave(rmOperands, misc.OP_SIZE_8BIT, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    def adcR16_32_RM16_32(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cdef long op1 = self.registers.modRM_RLoad(rmOperands, operSize)
        cdef long op2 = self.registers.modR_RMLoad(rmOperands, operSize)
        op1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.modR_RMSave(rmOperands, operSize, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    def adcAL_IMM8(self):
        cdef long op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        cdef long op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        op1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.regWrite(registers.CPU_REGISTER_AL, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    def adcAX_EAX_IMM16_32(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        cdef long op1 = self.registers.regRead(dataReg)
        cdef long op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        op1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.regWrite(dataReg, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    def xorRM8_R8(self):
        cdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)^self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT))
    def xorRM16_32_R16_32(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        self.registers.modRM_RSave(rmOperands, operSize, self.registers.modR_RMLoad(rmOperands, operSize)^self.registers.modRM_RLoad(rmOperands, operSize))
    def inAlImm8(self):
        self.registers.regWrite(registers.CPU_REGISTER_AL, self.main.platform.inPort(self.cpu.getCurrentOpcodeAdd(), misc.OP_SIZE_8BIT))
    def inAxEaxImm8(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        self.registers.regWrite(dataReg, self.main.platform.inPort(self.cpu.getCurrentOpcodeAdd(), operSize))
    def inAlDx(self):
        self.registers.regWrite(registers.CPU_REGISTER_AL, self.main.platform.inPort(self.registers.regRead(registers.CPU_REGISTER_DX), misc.OP_SIZE_8BIT))
    def inAxEaxDx(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        self.registers.regWrite(dataReg, self.main.platform.inPort(self.registers.regRead(registers.CPU_REGISTER_DX), operSize))
    def outImm8Al(self):
        self.main.platform.outPort(self.cpu.getCurrentOpcodeAdd(), self.registers.regRead(registers.CPU_REGISTER_AL), misc.OP_SIZE_8BIT)
    def outImm8AxEax(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        self.main.platform.outPort(self.cpu.getCurrentOpcodeAdd(), self.registers.regRead(dataReg), operSize)
    def outDxAl(self):
        self.main.platform.outPort(self.registers.regRead(registers.CPU_REGISTER_DX), self.registers.regRead(registers.CPU_REGISTER_AL), misc.OP_SIZE_8BIT)
    def outDxAxEax(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        self.main.platform.outPort(self.registers.regRead(registers.CPU_REGISTER_DX), self.registers.regRead(dataReg), operSize)
    def jgShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_ZF) and (self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_SF)==self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_OF)))
    def jgeShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_SF)==self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_OF))
    def jlShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_SF)!=self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_OF))
    def jleShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_ZF) or (self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_SF)!=self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_OF)))
    def jnzShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_ZF))
    def jzShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_ZF))
    def jaShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_CF) and not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_ZF))
    def jbeShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_CF) or self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_ZF))
    def jncShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_CF))
    def jcShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_CF))
    def jnpShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_PF))
    def jpShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_PF))
    def jnoShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_OF))
    def joShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_OF))
    def jnsShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_SF))
    def jsShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_SF))
    def jcxzShort(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int cxReg = registers.CPU_REGISTER_CX
        if (operSize == misc.OP_SIZE_32BIT):
            cxReg = registers.CPU_REGISTER_ECX
        self.jmpShort(operSize, self.registers.regRead(cxReg)==0)
    def jumpShort(self, int operSize, int c=True):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef int segOperSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef long tempEIP = self.cpu.getCurrentOpcodeAdd(numBytes=(operSize), signedValue=True) + \
                            self.registers.regRead(registers.CPU_REGISTER_EIP)
        if (segOperSize == misc.OP_SIZE_16BIT):
            tempEIP &= 0xffff
        if (c):
            self.registers.regWrite(registers.CPU_REGISTER_EIP, tempEIP)
    def callNearRel16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cdef int segOperSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int eipRegName = registers.CPU_REGISTER_IP
        if (segOperSize == misc.OP_SIZE_32BIT):
            eipRegName = registers.CPU_REGISTER_EIP
        cdef long tempEIP = self.cpu.getCurrentOpcodeAdd(numBytes=(segOperSize), signedValue=True) + \
                            self.registers.regRead(registers.CPU_REGISTER_EIP)
        if (segOperSize == misc.OP_SIZE_16BIT):
            tempEIP &= 0xffff
        self.stackPush(eipRegName)
        self.registers.regWrite(registers.CPU_REGISTER_EIP, tempEIP)
    def pushfWD(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regNameId = registers.CPU_REGISTER_FLAGS
        if (operSize == misc.OP_SIZE_32BIT):
            regNameId = registers.CPU_REGISTER_EFLAGS
            return self.stackPush(registers.RegImm(self.registers.regRead(regNameId)&0x00FCFFFF))
        return self.stackPush(regNameId)
    def stackPush(self, int regId):
        cdef int segOperSize   = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int stackAddrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_SS)
        cdef int stackRegName = registers.CPU_REGISTER_SP
        if (stackAddrSize == misc.OP_SIZE_16BIT):
            stackRegName = registers.CPU_REGISTER_SP
        elif (stackAddrSize == misc.OP_SIZE_32BIT):
            stackRegName = registers.CPU_REGISTER_ESP
        else:
            self.main.exitError(self, "stackAddrSize not in (misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT). (stackAddrSize: {0:d})", stackAddrSize)
        self.registers.regSub(stackRegName, segOperSize)
        self.main.mm.mmWrite(self.registers.regRead(stackRegName), self.registers.regRead(regId), segOperSize, registers.CPU_SEGMENT_SS)
    def opcodeGroup1_RM8_IMM8(self): # addOrAdcSbbAndSubXorCmp RM8 IMM8
        cdef int operOpcode = self.cpu.getCurrentOpcode()
        cdef int operOpcodeId = (operOpcode>>3)&7
        cdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        cdef long operOp2 = self.cpu.getCurrentOpcodeAdd() # operImm8
        cdef long operRes = 0
        cdef long bitMask = self.main.misc.getBitMask(misc.OP_SIZE_8BIT)
        if (operOpcodeId == GROUP1_OP_ADD):
            operRes = operOp1+operOp2
            self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_OR):
            operRes = operOp1|operOp2
            self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
        elif (operOpcodeId == GROUP1_OP_ADC):
            operOp1 = (operOp1+self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF))
            operRes = (operOp1+operOp2)
            self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_SBB):
            operOp2 -= self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
            operRes = operOp1-operOp2
            self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_AND):
            operRes = operOp1&operOp2
            self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
        elif (operOpcodeId == GROUP1_OP_SUB):
            operRes = operOp1-operOp2
            self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_XOR):
            operRes = operOp1^operOp2
            self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
        elif (operOpcodeId == GROUP1_OP_CMP):
            operRes = operOp1-operOp2
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
        else:
            self.main.exitError("opcodeGroup1_RM8_IMM8: invalid operOpcodeId.")
    def opcodeGroup1_RM16_32_IMM16_32(self): # addOrAdcSbbAndSubXorCmp RM16/32 IMM16/32
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int operOpcode = self.cpu.getCurrentOpcode()
        cdef int operOpcodeId = (operOpcode>>3)&7
        cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, operSize)
        cdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        cdef long operRes = 0
        cdef long bitMask = self.main.misc.getBitMask(operSize)
        if (operOpcodeId == GROUP1_OP_ADD):
            operRes = operOp1+operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_OR):
            operRes = operOp1|operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
        elif (operOpcodeId == GROUP1_OP_ADC):
            operOp1 = (operOp1+self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF))
            operRes = (operOp1+operOp2)
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_ADD, signedAsUnsigned=True)
        elif (operOpcodeId == GROUP1_OP_SBB):
            operOp2 -= self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
            operRes = operOp1-operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_AND):
            operRes = operOp1&operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
        elif (operOpcodeId == GROUP1_OP_SUB):
            operRes = operOp1-operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_XOR):
            operRes = operOp1^operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
        elif (operOpcodeId == GROUP1_OP_CMP):
            operRes = operOp1-operOp2
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB)
        else:
            self.main.exitError("opcodeGroup1_RM16_32_IMM16_32: invalid operOpcodeId.")
    def opcodeGroup1_RM16_32_IMM8(self): # addOrAdcSbbAndSubXorCmp RM16/32 IMM8
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int operOpcode = self.cpu.getCurrentOpcode()
        cdef int operOpcodeId = (operOpcode>>3)&7
        cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, operSize)
        cdef long operOp2 = self.cpu.getCurrentOpcodeAdd(signedValue=True) # operImm8
        cdef long operRes = 0
        cdef long bitMask = self.main.misc.getBitMask(operSize)
        if (operOpcodeId == GROUP1_OP_ADD):
            operRes = operOp1+operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_OR):
            operRes = operOp1|operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
        elif (operOpcodeId == GROUP1_OP_ADC):
            operOp1 = (operOp1+self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF))&bitMask
            operRes = (operOp1+operOp2)&bitMask
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_SBB):
            operOp2 -= self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
            operRes = operOp1-operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_AND):
            operRes = operOp1&operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
        elif (operOpcodeId == GROUP1_OP_SUB):
            operRes = operOp1-operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB)
        elif (operOpcodeId == GROUP1_OP_XOR):
            operRes = operOp1^operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
        elif (operOpcodeId == GROUP1_OP_CMP):
            operRes = operOp1-operOp2
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB)
        else:
            self.main.exitError("opcodeGroup1_RM16_32_IMM8: invalid operOpcodeId.")
    def opcodeGroup3_RM8_IMM8(self): # 0/MOV RM8 IMM8
        cdef int operOpcode = self.cpu.getCurrentOpcode()
        cdef int operOpcodeId = (operOpcode>>3)&7
        cdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        #cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, 8)
        cdef long operOp2 = self.cpu.getCurrentOpcodeAdd() # operImm8
        cdef long operRes = 0
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, operOp2)
        else:
            self.main.exitError("opcodeGroup3_RM8_IMM8: invalid operOpcodeId.")
    def opcodeGroup3_RM16_32_IMM16_32(self): # 0/MOV RM16/32 IMM16/32
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int operOpcode = self.cpu.getCurrentOpcode()
        cdef int operOpcodeId = (operOpcode>>3)&7
        cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        #cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, operSize)
        cdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        cdef long operRes = 0
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.registers.modRM_RSave(rmOperands, operSize, operOp2)
        else:
            self.main.exitError("opcodeGroup3_RM16_32_IMM16_32: invalid operOpcodeId.")
    def opcodeGroupF0(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int operOpcode = self.cpu.getCurrentOpcode()
        cdef int operOpcodeId = (operOpcode>>3)&7
        #cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        #cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, operSize)
        #cdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        cdef long operRes = 0
        #if (operOpcodeId == 0):
        if (0):
            pass
        else:
            self.main.exitError("opcodeGroupF0: invalid operOpcodeId.")
    def opcodeGroupFE(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int operOpcode = self.cpu.getCurrentOpcode()
        cdef int operOpcodeId = (operOpcode>>3)&7
        cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        #cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, operSize)
        #cdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        cdef long operRes = 0
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(rmOperands, misc.OP_SIZE_8BIT)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(rmOperands, misc.OP_SIZE_8BIT)
        else:
            self.main.exitError("opcodeGroupFE: invalid operOpcodeId.")
    def opcodeGroupFF(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int operOpcode = self.cpu.getCurrentOpcode()
        cdef int operOpcodeId = (operOpcode>>3)&7
        cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        #cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, operSize)
        #cdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        cdef long operRes = 0
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(rmOperands, operSize)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(rmOperands, operSize)
        else:
            self.main.exitError("opcodeGroupFF: invalid operOpcodeId.")
    def incFuncReg(self, int regId):
        cdef int origCF = self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        cdef int regSize = self.registers.regGetSize(regId)
        cdef long bitMask = self.main.misc.getBitMask(regSize)
        cdef long op1 = self.registers.regRead(regId)
        cdef long op2 = 1
        self.registers.regWrite(regId, (op1+op2)&bitMask)
        self.registers.setFullFlags(op1, op2, regSize, misc.SET_FLAGS_ADD)
        self.registers.setFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF, origCF)
    def decFuncReg(self, int regId):
        cdef int origCF = self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        cdef int regSize = self.registers.regGetSize(regId)
        cdef long bitMask = self.main.misc.getBitMask(regSize)
        cdef long op1 = self.registers.regRead(regId)
        cdef long op2 = 1
        self.registers.regWrite(regId, (op1-op2)&bitMask)
        self.registers.setFullFlags(op1, op2, regSize, misc.SET_FLAGS_SUB)
        self.registers.setFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF, origCF)
    def incFuncRM(self, tuple rmOperands, int rmSize): # rmSize in bits
        cdef int origCF = self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        cdef long bitMask = self.main.misc.getBitMask(rmSize)
        cdef long op1 = self.registers.modR_RMLoad(rmOperands, rmSize)
        cdef long op2 = 1
        self.registers.modRM_RSave(rmOperands, rmSize, (op1+op2)&bitMask)
        self.registers.setFullFlags(op1, op2, rmSize, misc.SET_FLAGS_ADD)
        self.registers.setFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF, origCF)
    def decFuncRM(self, tuple rmOperands, int rmSize): # rmSize in bits
        cdef int origCF = self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        cdef long bitMask = self.main.misc.getBitMask(rmSize)
        cdef long op1 = self.registers.modR_RMLoad(rmOperands, rmSize)
        cdef long op2 = 1
        self.registers.modRM_RSave(rmOperands, rmSize, (op1-op2)&bitMask)
        self.registers.setFullFlags(op1, op2, rmSize, misc.SET_FLAGS_SUB)
        self.registers.setFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF, origCF)
    def incAX(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        self.incFuncReg(regName)
    def incCX(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_CX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ECX
        self.incFuncReg(regName)
    def incDX(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_DX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDX
        self.incFuncReg(regName)
    def incBX(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_BX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBX
        self.incFuncReg(regName)
    def incSP(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_SP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESP
        self.incFuncReg(regName)
    def incBP(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_BP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBP
        self.incFuncReg(regName)
    def incSI(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_SI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESI
        self.incFuncReg(regName)
    def incDI(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_DI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDI
        self.incFuncReg(regName)
    def decAX(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        self.decFuncReg(regName)
    def decCX(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_CX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ECX
        self.decFuncReg(regName)
    def decDX(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_DX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDX
        self.decFuncReg(regName)
    def decBX(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_BX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBX
        self.decFuncReg(regName)
    def decSP(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_SP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESP
        self.decFuncReg(regName)
    def decBP(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_BP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBP
        self.decFuncReg(regName)
    def decSI(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_SI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESI
        self.decFuncReg(regName)
    def decDI(self):
        cdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cdef int regName  = registers.CPU_REGISTER_DI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDI
        self.decFuncReg(regName)
    # end of opcodes



