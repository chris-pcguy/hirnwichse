
cdef class Opcodes:
    #cdef object main
    #cdef object cpu
    #cdef object registers
    cpdef public object main, cpu, registers
    cpdef public dict opcodeList
    ####def __init__(self, object main, object cpu)
    ####cpdef __cinit__(self, object main, object cpu)
    cpdef cli(self)
    cpdef sti(self)
    cpdef cld(self)
    cpdef std(self)
    cpdef hlt(self)
    cpdef jumpFarAbsolutePtr(self)
    cpdef jumpShortRelativeByte(self)
    cpdef jumpShortRelativeWordDWord(self)
    cpdef cmpAlImm8(self)
    cpdef cmpAxEaxImm16_32(self)
    cpdef movImm8ToR8(self)
    cpdef movImm16_32ToR16_32(self)
    cpdef movRM8_R8(self)
    cpdef movRM16_32_R16_32(self)
    cpdef movR8_RM8(self)
    cpdef movR16_32_RM16_32(self)
    cpdef movRM16_SREG(self)
    cpdef movSREG_RM16(self)
    cpdef movMOFFS8_AL(self)
    cpdef movMOFFS16_32_AX_EAX(self)
    cpdef addRM8_R8(self)
    cpdef addRM16_32_R16_32(self)
    cpdef addR8_RM8(self)
    cpdef addR16_32_RM16_32(self)
    cpdef addAL_IMM8(self)
    cpdef addAX_EAX_IMM16_32(self)
    cpdef adcRM8_R8(self)
    cpdef adcRM16_32_R16_32(self)
    cpdef adcR8_RM8(self)
    cpdef adcR16_32_RM16_32(self)
    cpdef adcAL_IMM8(self)
    cpdef adcAX_EAX_IMM16_32(self)
    cpdef subRM8_R8(self)
    cpdef subRM16_32_R16_32(self)
    cpdef subR8_RM8(self)
    cpdef subR16_32_RM16_32(self)
    cpdef subAL_IMM8(self)
    cpdef subAX_EAX_IMM16_32(self)
    cpdef sbbRM8_R8(self)
    cpdef sbbRM16_32_R16_32(self)
    cpdef sbbR8_RM8(self)
    cpdef sbbR16_32_RM16_32(self)
    cpdef sbbAL_IMM8(self)
    cpdef sbbAX_EAX_IMM16_32(self)
    cpdef xorRM8_R8(self)
    cpdef xorRM16_32_R16_32(self)
    cpdef inAlImm8(self)
    cpdef inAxEaxImm8(self)
    cpdef inAlDx(self)
    cpdef inAxEaxDx(self)
    cpdef outImm8Al(self)
    cpdef outImm8AxEax(self)
    cpdef outDxAl(self)
    cpdef outDxAxEax(self)
    cpdef jgShort(self) # byte8
    cpdef jgeShort(self) # byte8
    cpdef jlShort(self) # byte8
    cpdef jleShort(self) # byte8
    cpdef jnzShort(self) # byte8
    cpdef jzShort(self) # byte8
    cpdef jaShort(self) # byte8
    cpdef jbeShort(self) # byte8
    cpdef jncShort(self) # byte8
    cpdef jcShort(self) # byte8
    cpdef jnpShort(self) # byte8
    cpdef jpShort(self) # byte8
    cpdef jnoShort(self) # byte8
    cpdef joShort(self) # byte8
    cpdef jnsShort(self) # byte8
    cpdef jsShort(self) # byte8
    cpdef jcxzShort(self)
    cpdef jumpShort(self, int operSize, int c=?)
    cpdef callNearRel16_32(self)
    cpdef pushfWD(self)
    cpdef stackPushRegId(self, int regId)
    cpdef stackPushValue(self, long value)
    cpdef opcodeGroup1_RM8_IMM8(self) # addOrAdcSbbAndSubXorCmp RM8 IMM8
    cpdef opcodeGroup1_RM16_32_IMM16_32(self) # addOrAdcSbbAndSubXorCmp RM16/32 IMM16/32
    cpdef opcodeGroup1_RM16_32_IMM8(self) # addOrAdcSbbAndSubXorCmp RM16/32 IMM8
    cpdef opcodeGroup3_RM8_IMM8(self) # 0/MOV RM8 IMM8
    cpdef opcodeGroup3_RM16_32_IMM16_32(self) # 0/MOV RM16/32 IMM16/32
    cpdef opcodeGroupF0(self)
    cpdef opcodeGroupFE(self)
    cpdef opcodeGroupFF(self)
    cpdef incFuncReg(self, int regId)
    cpdef decFuncReg(self, int regId)
    cpdef incFuncRM(self, tuple rmOperands, int rmSize) # rmSize in bits
    cpdef decFuncRM(self, tuple rmOperands, int rmSize) # rmSize in bits
    cpdef incAX(self)
    cpdef incCX(self)
    cpdef incDX(self)
    cpdef incBX(self)
    cpdef incSP(self)
    cpdef incBP(self)
    cpdef incSI(self)
    cpdef incDI(self)
    cpdef decAX(self)
    cpdef decCX(self)
    cpdef decDX(self)
    cpdef decBX(self)
    cpdef decSP(self)
    cpdef decBP(self)
    cpdef decSI(self)
    cpdef decDI(self)
    # end of opcodes



