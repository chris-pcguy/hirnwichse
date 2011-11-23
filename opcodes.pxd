

cdef class Opcodes:
    cpdef public object main, cpu, registers
    cpdef unsigned char executeOpcode(self, unsigned char opcode)
    cdef undefNoUD(self)
    cdef cli(self)
    cdef sti(self)
    cdef cld(self)
    cdef std(self)
    cdef clc(self)
    cdef stc(self)
    cdef cmc(self)
    cdef hlt(self)
    cdef nop(self)
    cdef switchToProtectedModeIfNeeded(self)
    cdef jumpFarAbsolutePtr(self)
    cdef jumpShortRelativeByte(self)
    cdef jumpShortRelativeWordDWord(self)
    cdef loop(self)
    cdef loope(self)
    cdef loopne(self)
    cdef loopFunc(self, unsigned char loopType)
    cdef opcodeR_RM(self, unsigned char opcode, unsigned char operSize)
    cdef opcodeRM_R(self, unsigned char opcode, unsigned char operSize)
    cdef opcodeAxEaxImm(self, unsigned char opcode, unsigned char operSize)
    cdef movImmToR(self, unsigned char operSize)
    cdef movRM_R(self, unsigned char operSize)
    cdef movR_RM(self, unsigned char operSize, unsigned char cond)
    cdef movRM16_SREG(self)
    cdef movSREG_RM16(self)
    cdef movAxMoffs(self, unsigned char operSize, unsigned char addrSize)
    cdef movMoffsAx(self, unsigned char operSize, unsigned char addrSize)
    cdef stosFunc(self, unsigned char operSize)
    cdef movsFunc(self, unsigned char operSize)
    cdef lodsFunc(self, unsigned char operSize)
    cdef cmpsFunc(self, unsigned char operSize)
    cdef scasFunc(self, unsigned char operSize)
    cdef inAxImm8(self, unsigned char operSize)
    cdef inAxDx(self, unsigned char operSize)
    cdef outImm8Ax(self, unsigned char operSize)
    cdef outDxAx(self, unsigned char operSize)
    cdef outsFunc(self, unsigned char operSize)
    cdef insFunc(self, unsigned char operSize)
    cdef jcxzShort(self)
    cdef jumpShort(self, unsigned char offsetSize, unsigned char c)
    cdef callNearRel16_32(self)
    cdef callPtr16_32(self)
    cdef pushaWD(self)
    cdef popaWD(self)
    cdef pushfWD(self)
    cdef popfWD(self)
    cdef stackPopRM(self, tuple rmOperands, unsigned char operSize)
    cdef stackPopSegId(self, unsigned short segId, unsigned char operSize)
    cdef stackPopRegId(self, unsigned short regId, unsigned char operSize)
    cdef unsigned long stackPopValue(self, unsigned char operSize)
    cdef stackPushSegId(self, unsigned short segId, unsigned char operSize)
    cdef stackPushRegId(self, unsigned short regId, unsigned char operSize)
    cdef stackPushValue(self, unsigned long value, unsigned char operSize)
    cdef pushIMM(self, unsigned char immIsByte)
    cdef imulR_RM_ImmFunc(self, unsigned char immIsByte)
    cdef opcodeGroup1_RM_ImmFunc(self, unsigned char operSize, unsigned char immIsByte)
    cdef opcodeGroup3_RM_ImmFunc(self, unsigned char operSize)
    cdef opcodeGroup0F(self)
    cdef opcodeGroupFE(self)
    cdef opcodeGroupFF(self)
    cdef incFuncReg(self, unsigned char regId)
    cdef decFuncReg(self, unsigned char regId)
    cdef incFuncRM(self, tuple rmOperands, unsigned char rmSize) # rmSize in bits
    cdef decFuncRM(self, tuple rmOperands, unsigned char rmSize) # rmSize in bits
    cdef incReg(self)
    cdef decReg(self)
    cdef pushReg(self)
    cdef pushSeg(self, short opcode)
    cdef popReg(self)
    cdef popSeg(self, short opcode)
    cdef popRM16_32(self)
    cdef lea(self)
    cdef retNear(self, unsigned char imm)
    cdef retNearImm(self)
    cdef retFar(self, unsigned char imm)
    cdef retFarImm(self)
    cdef lfpFunc(self, unsigned char segId) # 'load far pointer' function
    cdef xlatb(self)
    cdef opcodeGroup2_RM(self, unsigned char operSize)
    cpdef interrupt(self, short intNum, long errorCode, unsigned char hwInt) # TODO: complete this!
    cdef into(self)
    cdef int3(self)
    cdef iret(self)
    cdef aad(self)
    cdef aam(self)
    cdef aaa(self)
    cdef aas(self)
    cdef daa(self)
    cdef das(self)
    cdef cbw_cwde(self)
    cdef cwd_cdq(self)
    cdef shlFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count)
    cdef sarFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count)
    cdef shrFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count)
    cdef rclFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count)
    cdef rcrFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count)
    cdef rolFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count)
    cdef rorFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count)
    cdef opcodeGroup4_RM_1(self, unsigned char operSize)
    cdef opcodeGroup4_RM_CL(self, unsigned char operSize)
    cdef opcodeGroup4_RM_IMM8(self, unsigned char operSize)
    cdef sahf(self)
    cdef lahf(self)
    cdef xchgFuncReg(self, unsigned short regName, unsigned short regName2)
    cdef xchgReg(self)
    cdef xchgR_RM(self, unsigned char operSize)
    cdef enter(self)
    cdef leave(self)
    cdef cmovFunc(self, unsigned char operSize, unsigned char cond) # R16, R/M 16; R32, R/M 32
    cdef setWithCondFunc(self, unsigned char cond) # if cond==True set 1, else 0
    cdef arpl(self)
    cdef bound(self)
    cdef btFunc(self, tuple rmOperands, unsigned long offset, unsigned char newValType)
    cdef btcFunc(self, tuple rmOperands, unsigned long offset)
    cdef btrFunc(self, tuple rmOperands, unsigned long offset)
    cdef btsFunc(self, tuple rmOperands, unsigned long offset)
    # end of opcodes



