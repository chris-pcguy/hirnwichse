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

cdef class Opcodes:
    #cdef object main
    #cdef object cpu
    #cdef object registers
    #cdef object main, cpu, registers
    def __init__(self, object main, object cpu):
        self.main = main
        self.cpu = cpu
        ##print(dir(self.cpu), dir(cpu))
        self.registers = self.cpu.registers
        self.opcodeList = {0x00: self.addRM8_R8, 0x01: self.addRM16_32_R16_32, 0x02: self.addR8_RM8, 0x03: self.addR16_32_RM16_32,
                           0x04: self.addAL_IMM8, 0x05: self.addAX_EAX_IMM16_32,
                           0x10: self.adcRM8_R8, 0x11: self.adcRM16_32_R16_32, 0x12: self.adcR8_RM8, 0x13: self.adcR16_32_RM16_32,
                           0x14: self.adcAL_IMM8, 0x15: self.adcAX_EAX_IMM16_32,
                           0x18: self.sbbRM8_R8, 0x19: self.sbbRM16_32_R16_32,
                           0x1a: self.sbbR8_RM8, 0x1b: self.sbbR16_32_RM16_32,
                           0x1c: self.sbbAL_IMM8, 0x1d: self.sbbAX_EAX_IMM16_32,
                           0x28: self.subRM8_R8, 0x29: self.subRM16_32_R16_32,
                           0x2a: self.subR8_RM8, 0x2b: self.subR16_32_RM16_32,
                           0x2c: self.subAL_IMM8, 0x2d: self.subAX_EAX_IMM16_32,
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
    cpdef cli(self):
        self.registers.setEFLAG(registers.FLAG_DF, False)
    cpdef sti(self):
        self.registers.setEFLAG(registers.FLAG_DF, True)
    cpdef cld(self):
        self.registers.setEFLAG(registers.FLAG_DF, False)
    cpdef std(self):
        self.registers.setEFLAG(registers.FLAG_DF, True)
    cpdef hlt(self):
        self.cpu.cpuHalted = True
    cpdef jumpFarAbsolutePtr(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef long eip = self.cpu.getCurrentOpcodeAddEip()
        cpdef long cs = self.cpu.getCurrentOpcodeAdd(2)
        self.registers.regWrite(registers.CPU_SEGMENT_CS, cs)
        self.registers.regWrite(registers.CPU_REGISTER_EIP, eip)
    cpdef jumpShortRelativeByte(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        self.jumpShort(1)
    cpdef jumpShortRelativeWordDWord(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef int offsetSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        self.jumpShort(offsetSize)
    cpdef cmpAlImm8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef long reg0 = self.registers.regRead(registers.CPU_REGISTER_AL)
        cpdef long imm8 = self.cpu.getCurrentOpcodeAdd()
        #cdef long cmpSum = reg0-imm8
        self.registers.setFullFlags(reg0, imm8, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    cpdef cmpAxEaxImm16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int axReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            axReg = registers.CPU_REGISTER_EAX
        cpdef long reg0 = self.registers.regRead(axReg)
        cpdef long imm16_32 = self.cpu.getCurrentOpcodeAdd(operSize)
        #cdef long cmpSum = reg0-imm16_32
        self.registers.setFullFlags(reg0, imm16_32, operSize, misc.SET_FLAGS_SUB)
    cpdef movImm8ToR8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef int r8reg = self.cpu.opcode&0x7
        self.registers.regWrite(registers.CPU_REGISTER_BYTE[r8reg], self.cpu.getCurrentOpcodeAdd())
    cpdef movImm16_32ToR16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef long r16_32reg = self.cpu.opcode&0x7
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        if (operSize == misc.OP_SIZE_16BIT):
            self.registers.regWrite(registers.CPU_REGISTER_WORD[r16_32reg], self.cpu.getCurrentOpcodeAddEip())
        elif (operSize == misc.OP_SIZE_32BIT):
            self.registers.regWrite(registers.CPU_REGISTER_DWORD[r16_32reg], self.cpu.getCurrentOpcodeAddEip())
        else:
            self.main.exitError("operSize is NOT OK ({0:d})", operSize)
    cpdef movRM8_R8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT))
    cpdef movRM16_32_R16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        self.registers.modRM_RSave(rmOperands, operSize, self.registers.modRM_RLoad(rmOperands, operSize))
    cpdef movR8_RM8(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        self.registers.modR_RMSave(rmOperands, misc.OP_SIZE_8BIT, self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT))
    cpdef movR16_32_RM16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        self.registers.modR_RMSave(rmOperands, operSize, self.registers.modR_RMLoad(rmOperands, operSize))
    cpdef movRM16_SREG(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_16BIT, registers.MODRM_FLAGS_SREG)
        self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_16BIT, self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_16BIT))
    cpdef movSREG_RM16(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_16BIT, registers.MODRM_FLAGS_SREG)
        self.registers.modR_RMSave(rmOperands, misc.OP_SIZE_16BIT, self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_16BIT))
    cpdef movMOFFS8_AL(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef long mmAddr = self.cpu.getCurrentOpcodeAdd()
        self.main.mm.mmWriteValue(mmAddr, self.registers.regRead(registers.CPU_REGISTER_AL), 1)
    cpdef movMOFFS16_32_AX_EAX(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int addrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        cpdef long mmAddr = self.cpu.getCurrentOpcodeAdd(addrSize)
        self.main.mm.mmWriteValue(mmAddr, self.registers.regRead(regName), addrSize)
    cpdef addRM8_R8(self):
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cpdef long op1 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        cpdef long op2 = self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    cpdef addRM16_32_R16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cpdef long op1 = self.registers.modR_RMLoad(rmOperands, operSize)
        cpdef long op2 = self.registers.modRM_RLoad(rmOperands, operSize)
        self.registers.modRM_RSave(rmOperands, operSize, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    cpdef addR8_RM8(self):
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cpdef long op1 = self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT)
        cpdef long op2 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.modR_RMSave(rmOperands, misc.OP_SIZE_8BIT, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    cpdef addR16_32_RM16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cpdef long op1 = self.registers.modRM_RLoad(rmOperands, operSize)
        cpdef long op2 = self.registers.modR_RMLoad(rmOperands, operSize)
        self.registers.modR_RMSave(rmOperands, operSize, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    cpdef addAL_IMM8(self):
        cpdef long op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        cpdef long op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        self.registers.regWrite(registers.CPU_REGISTER_AL, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    cpdef addAX_EAX_IMM16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        cpdef long op1 = self.registers.regRead(dataReg)
        cpdef long op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        self.registers.regWrite(dataReg, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    cpdef adcRM8_R8(self):
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cpdef long op1 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        cpdef long op2 = self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT)
        op1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    cpdef adcRM16_32_R16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cpdef long op1 = self.registers.modR_RMLoad(rmOperands, operSize)
        cpdef long op2 = self.registers.modRM_RLoad(rmOperands, operSize)
        op1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.modRM_RSave(rmOperands, operSize, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    cpdef adcR8_RM8(self):
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cpdef long op1 = self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT)
        cpdef long op2 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.modR_RMSave(rmOperands, misc.OP_SIZE_8BIT, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    cpdef adcR16_32_RM16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cpdef long op1 = self.registers.modRM_RLoad(rmOperands, operSize)
        cpdef long op2 = self.registers.modR_RMLoad(rmOperands, operSize)
        op1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.modR_RMSave(rmOperands, operSize, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    cpdef adcAL_IMM8(self):
        cpdef long op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        cpdef long op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        op1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.regWrite(registers.CPU_REGISTER_AL, op1+op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
    cpdef adcAX_EAX_IMM16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        cpdef long op1 = self.registers.regRead(dataReg)
        cpdef long op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        op1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.regWrite(dataReg, op1+op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_ADD)
    cpdef subRM8_R8(self):
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cpdef long op1 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        cpdef long op2 = self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, op1-op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    cpdef subRM16_32_R16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cpdef long op1 = self.registers.modR_RMLoad(rmOperands, operSize)
        cpdef long op2 = self.registers.modRM_RLoad(rmOperands, operSize)
        self.registers.modRM_RSave(rmOperands, operSize, op1-op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    cpdef subR8_RM8(self):
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cpdef long op1 = self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT)
        cpdef long op2 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        self.registers.modR_RMSave(rmOperands, misc.OP_SIZE_8BIT, op1-op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    cpdef subR16_32_RM16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cpdef long op1 = self.registers.modRM_RLoad(rmOperands, operSize)
        cpdef long op2 = self.registers.modR_RMLoad(rmOperands, operSize)
        self.registers.modR_RMSave(rmOperands, operSize, op1-op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    cpdef subAL_IMM8(self):
        cpdef long op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        cpdef long op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        self.registers.regWrite(registers.CPU_REGISTER_AL, op1-op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    cpdef subAX_EAX_IMM16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        cpdef long op1 = self.registers.regRead(dataReg)
        cpdef long op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        self.registers.regWrite(dataReg, op1-op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    cpdef sbbRM8_R8(self):
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cpdef long op1 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        cpdef long op2 = self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, op1-op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    cpdef sbbRM16_32_R16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cpdef long op1 = self.registers.modR_RMLoad(rmOperands, operSize)
        cpdef long op2 = self.registers.modRM_RLoad(rmOperands, operSize)
        op2 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.modRM_RSave(rmOperands, operSize, op1-op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    cpdef sbbR8_RM8(self):
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cpdef long op1 = self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT)
        cpdef long op2 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        op2 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.modR_RMSave(rmOperands, misc.OP_SIZE_8BIT, op1-op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    cpdef sbbR16_32_RM16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cpdef long op1 = self.registers.modRM_RLoad(rmOperands, operSize)
        cpdef long op2 = self.registers.modR_RMLoad(rmOperands, operSize)
        op2 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.modR_RMSave(rmOperands, operSize, op1-op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    cpdef sbbAL_IMM8(self):
        cpdef long op1 = self.registers.regRead(registers.CPU_REGISTER_AL)
        cpdef long op2 = self.cpu.getCurrentOpcodeAdd() # IMM8
        op2 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.regWrite(registers.CPU_REGISTER_AL, op1-op2)
        self.registers.setFullFlags(op1, op2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_SUB)
    cpdef sbbAX_EAX_IMM16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        cpdef long op1 = self.registers.regRead(dataReg)
        cpdef long op2 = self.cpu.getCurrentOpcodeAdd(operSize) # IMM16_32
        op2 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        self.registers.regWrite(dataReg, op1-op2)
        self.registers.setFullFlags(op1, op2, operSize, misc.SET_FLAGS_SUB)
    cpdef xorRM8_R8(self):
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)^self.registers.modRM_RLoad(rmOperands, misc.OP_SIZE_8BIT))
    cpdef xorRM16_32_R16_32(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        self.registers.modRM_RSave(rmOperands, operSize, self.registers.modR_RMLoad(rmOperands, operSize)^self.registers.modRM_RLoad(rmOperands, operSize))
    cpdef inAlImm8(self):
        self.registers.regWrite(registers.CPU_REGISTER_AL, self.main.platform.inPort(self.cpu.getCurrentOpcodeAdd(), misc.OP_SIZE_8BIT))
    cpdef inAxEaxImm8(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        self.registers.regWrite(dataReg, self.main.platform.inPort(self.cpu.getCurrentOpcodeAdd(), operSize))
    cpdef inAlDx(self):
        self.registers.regWrite(registers.CPU_REGISTER_AL, self.main.platform.inPort(self.registers.regRead(registers.CPU_REGISTER_DX), misc.OP_SIZE_8BIT))
    cpdef inAxEaxDx(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        self.registers.regWrite(dataReg, self.main.platform.inPort(self.registers.regRead(registers.CPU_REGISTER_DX), operSize))
    cpdef outImm8Al(self):
        self.main.platform.outPort(self.cpu.getCurrentOpcodeAdd(), self.registers.regRead(registers.CPU_REGISTER_AL), misc.OP_SIZE_8BIT)
    cpdef outImm8AxEax(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        self.main.platform.outPort(self.cpu.getCurrentOpcodeAdd(), self.registers.regRead(dataReg), operSize)
    cpdef outDxAl(self):
        self.main.platform.outPort(self.registers.regRead(registers.CPU_REGISTER_DX), self.registers.regRead(registers.CPU_REGISTER_AL), misc.OP_SIZE_8BIT)
    cpdef outDxAxEax(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int dataReg = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            dataReg = registers.CPU_REGISTER_EAX
        self.main.platform.outPort(self.registers.regRead(registers.CPU_REGISTER_DX), self.registers.regRead(dataReg), operSize)
    cpdef jgShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_ZF) and (self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_SF)==self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_OF)))
    cpdef jgeShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_SF)==self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_OF))
    cpdef jlShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_SF)!=self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_OF))
    cpdef jleShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_ZF) or (self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_SF)!=self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_OF)))
    cpdef jnzShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_ZF))
    cpdef jzShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_ZF))
    cpdef jaShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_CF) and not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_ZF))
    cpdef jbeShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_CF) or self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_ZF))
    cpdef jncShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_CF))
    cpdef jcShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_CF))
    cpdef jnpShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_PF))
    cpdef jpShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_PF))
    cpdef jnoShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_OF))
    cpdef joShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_OF))
    cpdef jnsShort(self): # byte8
        self.jumpShort(1, not self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_SF))
    cpdef jsShort(self): # byte8
        self.jumpShort(1, self.registers.getFlag(registers.CPU_REGISTER_EFLAGS, registers.FLAG_SF))
    cpdef jcxzShort(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int cxReg = registers.CPU_REGISTER_CX
        if (operSize == misc.OP_SIZE_32BIT):
            cxReg = registers.CPU_REGISTER_ECX
        self.jmpShort(operSize, self.registers.regRead(cxReg)==0)
    cpdef jumpShort(self, int operSize, int c=True):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef int segOperSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef long tempEIP = self.cpu.getCurrentOpcodeAdd(numBytes=(operSize), signed=True) + \
                            self.registers.regRead(registers.CPU_REGISTER_EIP)
        if (segOperSize == misc.OP_SIZE_16BIT):
            tempEIP &= 0xffff
        if (c):
            self.registers.regWrite(registers.CPU_REGISTER_EIP, tempEIP)
    cpdef callNearRel16_32(self):
        if (self.registers.lockPrefix): self.cpu.exception(misc.CPU_EXCEPTION_UD); return
        cpdef int segOperSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int eipRegName = registers.CPU_REGISTER_IP
        if (segOperSize == misc.OP_SIZE_32BIT):
            eipRegName = registers.CPU_REGISTER_EIP
        cpdef long tempEIP = self.cpu.getCurrentOpcodeAdd(numBytes=(segOperSize), signed=True) + \
                            self.registers.regRead(registers.CPU_REGISTER_EIP)
        if (segOperSize == misc.OP_SIZE_16BIT):
            tempEIP &= 0xffff
        self.stackPush(eipRegName)
        self.registers.regWrite(registers.CPU_REGISTER_EIP, tempEIP)
    cpdef pushfWD(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regNameId = registers.CPU_REGISTER_FLAGS
        if (operSize == misc.OP_SIZE_32BIT):
            regNameId = registers.CPU_REGISTER_EFLAGS
            self.stackPushValue(self.registers.regRead(regNameId)&0x00FCFFFF)
            return
        self.stackPushRegId(regNameId)
    cpdef stackPushRegId(self, int regId):
        cpdef long value = self.registers.regRead(regId)
        self.stackPushValue(value)
    cpdef stackPushValue(self, long value):
        cpdef int segOperSize   = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int stackAddrSize = self.registers.segments.getAddrSegSize(registers.CPU_SEGMENT_SS)
        cpdef int stackRegName = registers.CPU_REGISTER_SP
        if (stackAddrSize == misc.OP_SIZE_16BIT):
            stackRegName = registers.CPU_REGISTER_SP
        elif (stackAddrSize == misc.OP_SIZE_32BIT):
            stackRegName = registers.CPU_REGISTER_ESP
        else:
            self.main.exitError(self, "stackAddrSize not in (misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT). (stackAddrSize: {0:d})", stackAddrSize)
        self.registers.regSub(stackRegName, segOperSize)
        self.main.mm.mmWriteValue(self.registers.regRead(stackRegName), value, segOperSize, registers.CPU_SEGMENT_SS)
    cpdef opcodeGroup1_RM8_IMM8(self): # addOrAdcSbbAndSubXorCmp RM8 IMM8
        cpdef int operOpcode = self.cpu.getCurrentOpcode()
        cpdef int operOpcodeId = (operOpcode>>3)&7
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        cpdef long operOp1 = self.registers.modR_RMLoad(rmOperands, misc.OP_SIZE_8BIT)
        cpdef long operOp2 = self.cpu.getCurrentOpcodeAdd() # operImm8
        cpdef long operRes = 0
        cpdef long bitMask = self.main.misc.getBitMask(misc.OP_SIZE_8BIT)
        if (operOpcodeId == GROUP1_OP_ADD):
            operRes = operOp1+operOp2
            self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_OR):
            operRes = operOp1|operOp2
            self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
        elif (operOpcodeId == GROUP1_OP_ADC):
            operOp1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
            operRes = (operOp1+operOp2)
            self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, operRes)
            self.registers.setFullFlags(operOp1, operOp2, misc.OP_SIZE_8BIT, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_SBB):
            operOp2 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
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
    cpdef opcodeGroup1_RM16_32_IMM16_32(self): # addOrAdcSbbAndSubXorCmp RM16/32 IMM16/32
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int operOpcode = self.cpu.getCurrentOpcode()
        cpdef int operOpcodeId = (operOpcode>>3)&7
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cpdef long operOp1 = self.registers.modR_RMLoad(rmOperands, operSize)
        cpdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        cpdef long operRes = 0
        cpdef long bitMask = self.main.misc.getBitMask(operSize)
        if (operOpcodeId == GROUP1_OP_ADD):
            operRes = operOp1+operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_OR):
            operRes = operOp1|operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
        elif (operOpcodeId == GROUP1_OP_ADC):
            operOp1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
            operRes = (operOp1+operOp2)
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_ADD)
        elif (operOpcodeId == GROUP1_OP_SBB):
            operOp2 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
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
    cpdef opcodeGroup1_RM16_32_IMM8(self): # addOrAdcSbbAndSubXorCmp RM16/32 IMM8
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int operOpcode = self.cpu.getCurrentOpcode()
        cpdef int operOpcodeId = (operOpcode>>3)&7
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cpdef long operOp1 = self.registers.modR_RMLoad(rmOperands, operSize)
        cpdef long operOp2 = self.cpu.getCurrentOpcodeAdd(signed=True) # operImm8
        cpdef long operRes = 0
        cpdef long bitMask = self.main.misc.getBitMask(operSize)
        operOp2 &= bitMask
        if (operOpcodeId == GROUP1_OP_ADD):
            operRes = operOp1+operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_ADD, signedAsUnsigned=True)
        elif (operOpcodeId == GROUP1_OP_OR):
            operRes = operOp1|operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
        elif (operOpcodeId == GROUP1_OP_ADC):
            operOp1 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
            #operOp1 &= bitMask
            operRes = (operOp1+operOp2)&bitMask
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_ADD, signedAsUnsigned=True)
        elif (operOpcodeId == GROUP1_OP_SBB):
            operOp2 += self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
            operRes = operOp1-operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB, signedAsUnsigned=True)
        elif (operOpcodeId == GROUP1_OP_AND):
            operRes = operOp1&operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
        elif (operOpcodeId == GROUP1_OP_SUB):
            operRes = operOp1-operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB, signedAsUnsigned=True)
        elif (operOpcodeId == GROUP1_OP_XOR):
            operRes = operOp1^operOp2
            self.registers.modRM_RSave(rmOperands, operSize, operRes)
        elif (operOpcodeId == GROUP1_OP_CMP):
            operRes = operOp1-operOp2
            self.registers.setFullFlags(operOp1, operOp2, operSize, misc.SET_FLAGS_SUB, signedAsUnsigned=True)
        else:
            self.main.exitError("opcodeGroup1_RM16_32_IMM8: invalid operOpcodeId.")
    cpdef opcodeGroup3_RM8_IMM8(self): # 0/MOV RM8 IMM8
        cpdef int operOpcode = self.cpu.getCurrentOpcode()
        cpdef int operOpcodeId = (operOpcode>>3)&7
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        #cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, 8)
        cpdef long operOp2 = self.cpu.getCurrentOpcodeAdd() # operImm8
        cpdef long operRes = 0
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.registers.modRM_RSave(rmOperands, misc.OP_SIZE_8BIT, operOp2)
        else:
            self.main.exitError("opcodeGroup3_RM8_IMM8: invalid operOpcodeId.")
    cpdef opcodeGroup3_RM16_32_IMM16_32(self): # 0/MOV RM16/32 IMM16/32
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int operOpcode = self.cpu.getCurrentOpcode()
        cpdef int operOpcodeId = (operOpcode>>3)&7
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        #cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, operSize)
        cpdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        cpdef long operRes = 0
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.registers.modRM_RSave(rmOperands, operSize, operOp2)
        else:
            self.main.exitError("opcodeGroup3_RM16_32_IMM16_32: invalid operOpcodeId.")
    cpdef opcodeGroupF0(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int operOpcode = self.cpu.getCurrentOpcode()
        cpdef int operOpcodeId = (operOpcode>>3)&7
        #cdef tuple rmOperands = self.registers.modRMOperands(operSize)
        #cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, operSize)
        #cdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        cpdef long operRes = 0
        #if (operOpcodeId == 0):
        if (0):
            pass
        else:
            self.main.exitError("opcodeGroupF0: invalid operOpcodeId.")
    cpdef opcodeGroupFE(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int operOpcode = self.cpu.getCurrentOpcode()
        cpdef int operOpcodeId = (operOpcode>>3)&7
        ##cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        cpdef tuple rmOperands = self.registers.modRMOperands(misc.OP_SIZE_8BIT)
        #cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, operSize)
        #cdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        cpdef long operRes = 0
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(rmOperands, misc.OP_SIZE_8BIT)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(rmOperands, misc.OP_SIZE_8BIT)
        else:
            self.main.exitError("opcodeGroupFE: invalid operOpcodeId.")
    cpdef opcodeGroupFF(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int operOpcode = self.cpu.getCurrentOpcode()
        cpdef int operOpcodeId = (operOpcode>>3)&7
        cpdef tuple rmOperands = self.registers.modRMOperands(operSize)
        #cdef long operOp1 = self.registers.modR_RMLoad(rmOperands, operSize)
        #cdef long operOp2 = self.cpu.getCurrentOpcodeAdd(operSize) # operImm16_32
        cpdef long operRes = 0
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(rmOperands, operSize)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(rmOperands, operSize)
        else:
            self.main.exitError("opcodeGroupFF: invalid operOpcodeId.")
    cpdef incFuncReg(self, int regId):
        cpdef int origCF = self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        cpdef int regSize = self.registers.regGetSize(regId)
        cpdef long bitMask = self.main.misc.getBitMask(regSize)
        cpdef long op1 = self.registers.regRead(regId)
        cpdef long op2 = 1
        self.registers.regWrite(regId, (op1+op2)&bitMask)
        self.registers.setFullFlags(op1, op2, regSize, misc.SET_FLAGS_ADD)
        self.registers.setEFLAG(registers.FLAG_CF, origCF)
    cpdef decFuncReg(self, int regId):
        cpdef int origCF = self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        cpdef int regSize = self.registers.regGetSize(regId)
        cpdef long bitMask = self.main.misc.getBitMask(regSize)
        cpdef long op1 = self.registers.regRead(regId)
        cpdef long op2 = 1
        self.registers.regWrite(regId, (op1-op2)&bitMask)
        self.registers.setFullFlags(op1, op2, regSize, misc.SET_FLAGS_SUB)
        self.registers.setEFLAG(registers.FLAG_CF, origCF)
    cpdef incFuncRM(self, tuple rmOperands, int rmSize): # rmSize in bits
        cpdef int origCF = self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        cpdef long bitMask = self.main.misc.getBitMask(rmSize)
        cpdef long op1 = self.registers.modR_RMLoad(rmOperands, rmSize)
        cpdef long op2 = 1
        self.registers.modRM_RSave(rmOperands, rmSize, (op1+op2)&bitMask)
        self.registers.setFullFlags(op1, op2, rmSize, misc.SET_FLAGS_ADD)
        self.registers.setEFLAG(registers.FLAG_CF, origCF)
    cpdef decFuncRM(self, tuple rmOperands, int rmSize): # rmSize in bits
        cpdef int origCF = self.registers.getFlag(registers.CPU_REGISTER_FLAGS, registers.FLAG_CF)
        cpdef long bitMask = self.main.misc.getBitMask(rmSize)
        cpdef long op1 = self.registers.modR_RMLoad(rmOperands, rmSize)
        cpdef long op2 = 1
        self.registers.modRM_RSave(rmOperands, rmSize, (op1-op2)&bitMask)
        self.registers.setFullFlags(op1, op2, rmSize, misc.SET_FLAGS_SUB)
        self.registers.setEFLAG(registers.FLAG_CF, origCF)
    cpdef incAX(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        self.incFuncReg(regName)
    cpdef incCX(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_CX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ECX
        self.incFuncReg(regName)
    cpdef incDX(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_DX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDX
        self.incFuncReg(regName)
    cpdef incBX(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_BX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBX
        self.incFuncReg(regName)
    cpdef incSP(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_SP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESP
        self.incFuncReg(regName)
    cpdef incBP(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_BP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBP
        self.incFuncReg(regName)
    cpdef incSI(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_SI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESI
        self.incFuncReg(regName)
    cpdef incDI(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_DI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDI
        self.incFuncReg(regName)
    cpdef decAX(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_AX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EAX
        self.decFuncReg(regName)
    cpdef decCX(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_CX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ECX
        self.decFuncReg(regName)
    cpdef decDX(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_DX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDX
        self.decFuncReg(regName)
    cpdef decBX(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_BX
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBX
        self.decFuncReg(regName)
    cpdef decSP(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_SP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESP
        self.decFuncReg(regName)
    cpdef decBP(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_BP
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EBP
        self.decFuncReg(regName)
    cpdef decSI(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_SI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_ESI
        self.decFuncReg(regName)
    cpdef decDI(self):
        cpdef int operSize = self.registers.segments.getOpSegSize(registers.CPU_SEGMENT_CS)
        cpdef int regName  = registers.CPU_REGISTER_DI
        if (operSize == misc.OP_SIZE_32BIT):
            regName = registers.CPU_REGISTER_EDI
        self.decFuncReg(regName)
    # end of opcodes



