import registers, misc

include "globals.pxi"

DEF GROUP1_OP_ADD = 0
DEF GROUP1_OP_OR  = 1
DEF GROUP1_OP_ADC = 2
DEF GROUP1_OP_SBB = 3
DEF GROUP1_OP_AND = 4
DEF GROUP1_OP_SUB = 5
DEF GROUP1_OP_XOR = 6
DEF GROUP1_OP_CMP = 7

DEF GROUP2_OP_TEST = 0
DEF GROUP2_OP_TEST_ALIAS = 1
DEF GROUP2_OP_NOT  = 2
DEF GROUP2_OP_NEG  = 3
DEF GROUP2_OP_MUL  = 4
DEF GROUP2_OP_IMUL = 5
DEF GROUP2_OP_DIV  = 6
DEF GROUP2_OP_IDIV = 7

DEF GROUP4_OP_ROL = 0
DEF GROUP4_OP_ROR = 1
DEF GROUP4_OP_RCL = 2
DEF GROUP4_OP_RCR = 3
DEF GROUP4_OP_SHL_SAL = 4
DEF GROUP4_OP_SHR = 5
DEF GROUP4_OP_SHL_SAL_ALIAS = 6
DEF GROUP4_OP_SAR = 7


DEF OPCODE_LOOP = 1
DEF OPCODE_LOOPE = 2
DEF OPCODE_LOOPNE = 3

cdef tuple OPCODE_LOOPTYPES = (OPCODE_LOOP, OPCODE_LOOPE, OPCODE_LOOPNE)


DEF PUSH_CS = 0x0e
DEF PUSH_DS = 0x1e
DEF PUSH_ES = 0x06
DEF PUSH_FS = 0xa0 # 0F A0
DEF PUSH_GS = 0xa8 # 0F A8
DEF PUSH_SS = 0x16

DEF POP_DS = 0x1f
DEF POP_ES = 0x07
DEF POP_FS = 0xa1 # 0F A1
DEF POP_GS = 0xa9 # 0F A9
DEF POP_SS = 0x17



cdef class Opcodes:
    cpdef public object main, cpu, registers
    def __init__(self, object main, object cpu):
        self.main = main
        self.cpu = cpu
        self.registers = self.cpu.registers
    cpdef unsigned char executeOpcode(self, unsigned char opcode):
        cdef unsigned char operSize, addrSize
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        if (opcode == 0x00):
            self.addRM_R(OP_SIZE_BYTE)
        elif (opcode == 0x01):
            self.addRM_R(operSize)
        elif (opcode == 0x02):
            self.addR_RM(OP_SIZE_BYTE)
        elif (opcode == 0x03):
            self.addR_RM(operSize)
        elif (opcode == 0x04):
            self.addAxImm(OP_SIZE_BYTE)
        elif (opcode == 0x05):
            self.addAxImm(operSize)
        elif (opcode == 0x06):
            self.pushSeg(-1)
        elif (opcode == 0x07):
            self.popSeg(-1)
        elif (opcode == 0x08):
            self.orRM_R(OP_SIZE_BYTE)
        elif (opcode == 0x09):
            self.orRM_R(operSize)
        elif (opcode == 0x0a):
            self.orR_RM(OP_SIZE_BYTE)
        elif (opcode == 0x0b):
            self.orR_RM(operSize)
        elif (opcode == 0x0c):
            self.orAxImm(OP_SIZE_BYTE)
        elif (opcode == 0x0d):
            self.orAxImm(operSize)
        elif (opcode == 0x0e):
            self.pushSeg(-1)
        elif (opcode == 0x0f):
            self.opcodeGroup0F()
        elif (opcode == 0x10):
            self.adcRM_R(OP_SIZE_BYTE)
        elif (opcode == 0x11):
            self.adcRM_R(operSize)
        elif (opcode == 0x12):
            self.adcR_RM(OP_SIZE_BYTE)
        elif (opcode == 0x13):
            self.adcR_RM(operSize)
        elif (opcode == 0x14):
            self.adcAxImm(OP_SIZE_BYTE)
        elif (opcode == 0x15):
            self.adcAxImm(operSize)
        elif (opcode == 0x16):
            self.pushSeg(-1)
        elif (opcode == 0x17):
            self.popSeg(-1)
        elif (opcode == 0x18):
            self.sbbRM_R(OP_SIZE_BYTE)
        elif (opcode == 0x19):
            self.sbbRM_R(operSize)
        elif (opcode == 0x1a):
            self.sbbR_RM(OP_SIZE_BYTE)
        elif (opcode == 0x1b):
            self.sbbR_RM(operSize)
        elif (opcode == 0x1c):
            self.sbbAxImm(OP_SIZE_BYTE)
        elif (opcode == 0x1d):
            self.sbbAxImm(operSize)
        elif (opcode == 0x1e):
            self.pushSeg(-1)
        elif (opcode == 0x1f):
            self.popSeg(-1)
        elif (opcode == 0x20):
            self.andRM_R(OP_SIZE_BYTE)
        elif (opcode == 0x21):
            self.andRM_R(operSize)
        elif (opcode == 0x22):
            self.andR_RM(OP_SIZE_BYTE)
        elif (opcode == 0x23):
            self.andR_RM(operSize)
        elif (opcode == 0x24):
            self.andAxImm(OP_SIZE_BYTE)
        elif (opcode == 0x25):
            self.andAxImm(operSize)
        elif (opcode == 0x27):
            self.daa()
        elif (opcode == 0x28):
            self.subRM_R(OP_SIZE_BYTE)
        elif (opcode == 0x29):
            self.subRM_R(operSize)
        elif (opcode == 0x2a):
            self.subR_RM(OP_SIZE_BYTE)
        elif (opcode == 0x2b):
            self.subR_RM(operSize)
        elif (opcode == 0x2c):
            self.subAxImm(OP_SIZE_BYTE)
        elif (opcode == 0x2d):
            self.subAxImm(operSize)
        elif (opcode == 0x2f):
            self.das()
        elif (opcode == 0x30):
            self.xorRM_R(OP_SIZE_BYTE)
        elif (opcode == 0x31):
            self.xorRM_R(operSize)
        elif (opcode == 0x32):
            self.xorR_RM(OP_SIZE_BYTE)
        elif (opcode == 0x33):
            self.xorR_RM(operSize)
        elif (opcode == 0x34):
            self.xorAxImm(OP_SIZE_BYTE)
        elif (opcode == 0x35):
            self.xorAxImm(operSize)
        elif (opcode == 0x37):
            self.aaa()
        elif (opcode == 0x38):
            self.cmpRM_R(OP_SIZE_BYTE)
        elif (opcode == 0x39):
            self.cmpRM_R(operSize)
        elif (opcode == 0x3a):
            self.cmpR_RM(OP_SIZE_BYTE)
        elif (opcode == 0x3b):
            self.cmpR_RM(operSize)
        elif (opcode == 0x3c):
            self.cmpAxImm(OP_SIZE_BYTE)
        elif (opcode == 0x3d):
            self.cmpAxImm(operSize)
        elif (opcode == 0x3f):
            self.aas()
        elif (opcode >= 0x40 and opcode <= 0x47):
            self.incReg()
        elif (opcode >= 0x48 and opcode <= 0x4f):
            self.decReg()
        elif (opcode >= 0x50 and opcode <= 0x57):
            self.pushReg()
        elif (opcode >= 0x58 and opcode <= 0x5f):
            self.popReg()
        elif (opcode == 0x60):
            self.pushaWD()
        elif (opcode == 0x61):
            self.popaWD()
        elif (opcode == 0x62):
            self.bound()
        elif (opcode == 0x63):
            self.arpl()
        elif (opcode == 0x68):
            self.pushIMM(False)
        elif (opcode == 0x69):
            self.imulR_RM_ImmFunc(False)
        elif (opcode == 0x6a):
            self.pushIMM(True)
        elif (opcode == 0x6b):
            self.imulR_RM_ImmFunc(True)
        elif (opcode == 0x6c):
            self.insFunc(OP_SIZE_BYTE)
        elif (opcode == 0x6d):
            self.insFunc(operSize)
        elif (opcode == 0x6e):
            self.outsFunc(OP_SIZE_BYTE)
        elif (opcode == 0x6f):
            self.outsFunc(operSize)
        elif (opcode == 0x70):
            self.joShort(OP_SIZE_BYTE)
        elif (opcode == 0x71):
            self.jnoShort(OP_SIZE_BYTE)
        elif (opcode == 0x72):
            self.jcShort(OP_SIZE_BYTE)
        elif (opcode == 0x73):
            self.jncShort(OP_SIZE_BYTE)
        elif (opcode == 0x74):
            self.jzShort(OP_SIZE_BYTE)
        elif (opcode == 0x75):
            self.jnzShort(OP_SIZE_BYTE)
        elif (opcode == 0x76):
            self.jbeShort(OP_SIZE_BYTE)
        elif (opcode == 0x77):
            self.jaShort(OP_SIZE_BYTE)
        elif (opcode == 0x78):
            self.jsShort(OP_SIZE_BYTE)
        elif (opcode == 0x79):
            self.jnsShort(OP_SIZE_BYTE)
        elif (opcode == 0x7a):
            self.jpShort(OP_SIZE_BYTE)
        elif (opcode == 0x7b):
            self.jnpShort(OP_SIZE_BYTE)
        elif (opcode == 0x7c):
            self.jlShort(OP_SIZE_BYTE)
        elif (opcode == 0x7d):
            self.jgeShort(OP_SIZE_BYTE)
        elif (opcode == 0x7e):
            self.jleShort(OP_SIZE_BYTE)
        elif (opcode == 0x7f):
            self.jgShort(OP_SIZE_BYTE)
        elif (opcode == 0x80):
            self.opcodeGroup1_RM_ImmFunc(OP_SIZE_BYTE, True)
        elif (opcode == 0x81):
            self.opcodeGroup1_RM_ImmFunc(operSize, False)
        elif (opcode == 0x83):
            self.opcodeGroup1_RM_ImmFunc(operSize, True)
        elif (opcode == 0x84):
            self.testRM_R(OP_SIZE_BYTE)
        elif (opcode == 0x85):
            self.testRM_R(operSize)
        elif (opcode == 0x86):
            self.xchgR_RM(OP_SIZE_BYTE)
        elif (opcode == 0x87):
            self.xchgR_RM(operSize)
        elif (opcode == 0x88):
            self.movRM_R(OP_SIZE_BYTE)
        elif (opcode == 0x89):
            self.movRM_R(operSize)
        elif (opcode == 0x8a):
            self.movR_RM(OP_SIZE_BYTE, True)
        elif (opcode == 0x8b):
            self.movR_RM(operSize, True)
        elif (opcode == 0x8c):
            self.movRM16_SREG()
        elif (opcode == 0x8d):
            self.lea()
        elif (opcode == 0x8e):
            self.movSREG_RM16()
        elif (opcode == 0x8f):
            self.popRM16_32()
        elif (opcode == 0x90):
            self.nop()
        elif (opcode >= 0x91 and opcode <= 0x97):
            self.xchgReg()
        elif (opcode == 0x98):
            self.cbw_cwde()
        elif (opcode == 0x99):
            self.cwd_cdq()
        elif (opcode == 0x9a):
            self.callPtr16_32()
        elif (opcode == 0x9c):
            self.pushfWD()
        elif (opcode == 0x9d):
            self.popfWD()
        elif (opcode == 0x9e):
            self.sahf()
        elif (opcode == 0x9f):
            self.lahf()
        elif (opcode == 0xa0):
            self.movAxMoffs(OP_SIZE_BYTE, addrSize)
        elif (opcode == 0xa1):
            self.movAxMoffs(operSize, addrSize)
        elif (opcode == 0xa2):
            self.movMoffsAx(OP_SIZE_BYTE, addrSize)
        elif (opcode == 0xa3):
            self.movMoffsAx(operSize, addrSize)
        elif (opcode == 0xa4):
            self.movsFunc(OP_SIZE_BYTE)
        elif (opcode == 0xa5):
            self.movsFunc(operSize)
        elif (opcode == 0xa6):
            self.cmpsFunc(OP_SIZE_BYTE)
        elif (opcode == 0xa7):
            self.cmpsFunc(operSize)
        elif (opcode == 0xa8):
            self.testAxImm(OP_SIZE_BYTE)
        elif (opcode == 0xa9):
            self.testAxImm(operSize)
        elif (opcode == 0xaa):
            self.stosFunc(OP_SIZE_BYTE)
        elif (opcode == 0xab):
            self.stosFunc(operSize)
        elif (opcode == 0xac):
            self.lodsFunc(OP_SIZE_BYTE)
        elif (opcode == 0xad):
            self.lodsFunc(operSize)
        elif (opcode == 0xae):
            self.scasFunc(OP_SIZE_BYTE)
        elif (opcode == 0xaf):
            self.scasFunc(operSize)
        elif (opcode >= 0xb0 and opcode <= 0xb7):
            self.movImmToR(OP_SIZE_BYTE)
        elif (opcode >= 0xb8 and opcode <= 0xbf):
            self.movImmToR(operSize)
        elif (opcode == 0xc0):
            self.opcodeGroup4_RM_IMM8(OP_SIZE_BYTE)
        elif (opcode == 0xc1):
            self.opcodeGroup4_RM_IMM8(operSize)
        elif (opcode == 0xc2):
            self.retNearImm()
        elif (opcode == 0xc3):
            self.retNear(0)
        elif (opcode == 0xc4):
            self.lfpFunc(CPU_SEGMENT_ES)
        elif (opcode == 0xc5):
            self.lfpFunc(CPU_SEGMENT_DS)
        elif (opcode == 0xc6):
            self.opcodeGroup3_RM_ImmFunc(OP_SIZE_BYTE)
        elif (opcode == 0xc7):
            self.opcodeGroup3_RM_ImmFunc(operSize)
        elif (opcode == 0xc8):
            self.enter()
        elif (opcode == 0xc9):
            self.leave()
        elif (opcode == 0xca):
            self.retFarImm()
        elif (opcode == 0xcb):
            self.retFar(0)
        elif (opcode == 0xcc):
            self.int3()
        elif (opcode == 0xcd):
            self.interrupt(-1, -1, False)
        elif (opcode == 0xce):
            self.into()
        elif (opcode == 0xcf):
            self.iret()
        elif (opcode == 0xd0):
            self.opcodeGroup4_RM_1(OP_SIZE_BYTE)
        elif (opcode == 0xd1):
            self.opcodeGroup4_RM_1(operSize)
        elif (opcode == 0xd2):
            self.opcodeGroup4_RM_CL(OP_SIZE_BYTE)
        elif (opcode == 0xd3):
            self.opcodeGroup4_RM_CL(operSize)
        elif (opcode == 0xd4):
            self.aam()
        elif (opcode == 0xd5):
            self.aad()
        elif (opcode == 0xd6):
            self.undefNoUD()
        elif (opcode == 0xd7):
            self.xlatb()
        elif (opcode == 0xe0):
            self.loopne()
        elif (opcode == 0xe1):
            self.loope()
        elif (opcode == 0xe2):
            self.loop()
        elif (opcode == 0xe3):
            self.jcxzShort()
        elif (opcode == 0xe4):
            self.inAxImm8(OP_SIZE_BYTE)
        elif (opcode == 0xe5):
            self.inAxImm8(operSize)
        elif (opcode == 0xe6):
            self.outImm8Ax(OP_SIZE_BYTE)
        elif (opcode == 0xe7):
            self.outImm8Ax(operSize)
        elif (opcode == 0xe8):
            self.callNearRel16_32()
        elif (opcode == 0xe9):
            self.jumpShortRelativeWordDWord()
        elif (opcode == 0xea):
            self.jumpFarAbsolutePtr()
        elif (opcode == 0xeb):
            self.jumpShortRelativeByte()
        elif (opcode == 0xec):
            self.inAxDx(OP_SIZE_BYTE)
        elif (opcode == 0xed):
            self.inAxDx(operSize)
        elif (opcode == 0xee):
            self.outDxAx(OP_SIZE_BYTE)
        elif (opcode == 0xef):
            self.outDxAx(operSize)
        elif (opcode == 0xf1):
            self.undefNoUD()
        elif (opcode == 0xf4):
            self.hlt()
        elif (opcode == 0xf5):
            self.cmc()
        elif (opcode == 0xf6):
            self.opcodeGroup2_RM(OP_SIZE_BYTE)
        elif (opcode == 0xf7):
            self.opcodeGroup2_RM(operSize)
        elif (opcode == 0xf8):
            self.clc()
        elif (opcode == 0xf9):
            self.stc()
        elif (opcode == 0xfa):
            self.cli()
        elif (opcode == 0xfb):
            self.sti()
        elif (opcode == 0xfc):
            self.cld()
        elif (opcode == 0xfd):
            self.std()
        elif (opcode == 0xfe):
            self.opcodeGroupFE()
        elif (opcode == 0xff):
            self.opcodeGroupFF()
        else:
            return False # if opcode wasn't found.
        return True  # if opcode was found.
    cdef undefNoUD(self):
        pass
    cdef cli(self):
        self.registers.setEFLAG(FLAG_IF, False)
    cdef sti(self):
        self.registers.setEFLAG(FLAG_IF, True)
    cdef cld(self):
        self.registers.setEFLAG(FLAG_DF, False)
    cdef std(self):
        self.registers.setEFLAG(FLAG_DF, True)
    cdef clc(self):
        self.registers.setEFLAG(FLAG_CF, False)
    cdef stc(self):
        self.registers.setEFLAG(FLAG_CF, True)
    cdef cmc(self):
        self.registers.setEFLAG(FLAG_CF, not self.registers.getEFLAG(FLAG_CF) )
    cdef hlt(self):
        self.cpu.cpuHalted = True
    cdef nop(self):
        # TODO: maybe implement PAUSE-Opcode (F3 90 / REPE NOP)
        pass
    cdef switchToProtectedModeIfNeeded(self):
        if (self.registers.segments.gdt.needFlush):
            self.registers.segments.gdt.gdtLoaded = self.registers.segments.gdt.setGdtLoadedTo
            self.registers.segments.gdt.needFlush = False
            self.cpu.protectedModeOn = self.registers.getFlag(CPU_REGISTER_CR0, CR0_FLAG_PE)
    cdef jumpFarAbsolutePtr(self):
        cdef unsigned char operSize
        cdef unsigned short cs
        cdef unsigned long eip
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        eip = self.cpu.getCurrentOpcodeAdd(operSize, False)
        cs = self.cpu.getCurrentOpcodeAdd(OP_SIZE_WORD, False)
        self.registers.regWrite(CPU_REGISTER_EIP, eip)
        self.registers.segWrite(CPU_SEGMENT_CS, cs)
        self.switchToProtectedModeIfNeeded()
    cdef jumpShortRelativeByte(self):
        self.jumpShort(OP_SIZE_BYTE, True)
    cdef jumpShortRelativeWordDWord(self):
        cdef unsigned char offsetSize
        offsetSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        self.jumpShort(offsetSize, True)
    cdef loop(self):
        self.loopFunc(OPCODE_LOOP)
    cdef loope(self):
        self.loopFunc(OPCODE_LOOPE)
    cdef loopne(self):
        self.loopFunc(OPCODE_LOOPNE)
    cdef loopFunc(self, unsigned char loopType):
        cdef unsigned char operSize, addrSize, cond, oldZF
        cdef unsigned short countReg, eipRegName
        cdef unsigned long bitMask
        cdef long long countOrNewEip
        cdef char rel8
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        eipRegName = CPU_REGISTER_EIP
        bitMask = self.main.misc.getBitMaskFF(operSize)
        oldZF = self.registers.getEFLAG(FLAG_ZF)
        rel8 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, True)
        countOrNewEip = self.registers.regSub(countReg, 1)
        cond = False
        if (loopType == OPCODE_LOOPE and oldZF):
            cond = True
        elif (loopType == OPCODE_LOOPNE and not oldZF):
            cond = True
        elif (loopType == OPCODE_LOOP):
            cond = True
        if (cond and countOrNewEip != 0):
            countOrNewEip = (self.registers.regRead(eipRegName, False)+rel8)&bitMask
            self.registers.regWrite(eipRegName, countOrNewEip)
    cdef cmpRM_R(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        op2 = self.registers.modRLoad(rmOperands, operSize, False)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_SUB, False)
    cdef cmpR_RM(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRLoad(rmOperands, operSize, False)
        op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_SUB, False)
    cdef cmpAxImm(self, unsigned char operSize):
        cdef unsigned short eaxReg
        cdef unsigned long reg0, imm16_32
        eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        reg0 = self.registers.regRead(eaxReg, False)
        imm16_32 = self.cpu.getCurrentOpcodeAdd(operSize, False)
        self.registers.setFullFlags(reg0, imm16_32, operSize, SET_FLAGS_SUB, False)
    cdef movImmToR(self, unsigned char operSize):
        cdef unsigned char rReg
        cdef unsigned long src
        rReg = self.cpu.opcode&0x7
        src = self.cpu.getCurrentOpcodeAdd(operSize, False)
        if (operSize == OP_SIZE_BYTE):
            self.registers.regWrite(CPU_REGISTER_BYTE[rReg], src)
        elif (operSize == OP_SIZE_WORD):
            self.registers.regWrite(CPU_REGISTER_WORD[rReg], src)
        elif (operSize == OP_SIZE_DWORD):
            self.registers.regWrite(CPU_REGISTER_DWORD[rReg], src)
    cdef movRM_R(self, unsigned char operSize):
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        self.registers.modRMSave(rmOperands, operSize, self.registers.modRLoad(rmOperands, operSize, False), True, VALUEOP_SAVE)
    cdef testRM_R(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRLoad(rmOperands, operSize, False)
        op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        self.registers.setSZP_C0_O0_A0(op1&op2, operSize)
    cdef testAxImm(self, unsigned char operSize):
        cdef unsigned short eaxReg
        cdef unsigned long op1, op2
        eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op1 = self.registers.regRead(eaxReg, False)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize, False)
        self.registers.setSZP_C0_O0_A0(op1&op2, operSize)
    cdef movR_RM(self, unsigned char operSize, unsigned char cond):
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (cond):
            self.registers.modRSave(rmOperands, operSize, self.registers.modRMLoad(rmOperands, operSize, False, True), VALUEOP_SAVE)
    cdef movRM16_SREG(self):
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        self.registers.modRMSave(rmOperands, OP_SIZE_WORD, self.registers.modSegLoad(rmOperands, OP_SIZE_WORD), True, VALUEOP_SAVE)
    cdef movSREG_RM16(self):
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        if (rmOperands[2] == CPU_SEGMENT_CS):
            raise misc.ChemuException(CPU_EXCEPTION_UD)
        self.registers.modSegSave(rmOperands, OP_SIZE_WORD, self.registers.modRMLoad(rmOperands, OP_SIZE_WORD, False, True))
    cdef movAxMoffs(self, unsigned char operSize, unsigned char addrSize):
        cdef unsigned short regName
        cdef unsigned long mmAddr
        regName = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        mmAddr = self.cpu.getCurrentOpcodeAdd(addrSize, False)
        self.registers.regWrite(regName, self.main.mm.mmReadValue(mmAddr, operSize, CPU_SEGMENT_DS, False, True))
    cdef movMoffsAx(self, unsigned char operSize, unsigned char addrSize):
        cdef unsigned short regName
        cdef unsigned long mmAddr
        regName = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        mmAddr = self.cpu.getCurrentOpcodeAdd(addrSize, False)
        self.main.mm.mmWriteValue(mmAddr, self.registers.regRead(regName, False), operSize, CPU_SEGMENT_DS, True)
    cdef addRM_R(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        op2 = self.registers.modRLoad(rmOperands, operSize, False)
        self.registers.modRMSave(rmOperands, operSize, op2, True, VALUEOP_ADD)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_ADD, False)
    cdef addR_RM(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRLoad(rmOperands, operSize, False)
        op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        self.registers.modRSave(rmOperands, operSize, op2, VALUEOP_ADD)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_ADD, False)
    cdef addAxImm(self, unsigned char operSize):
        cdef unsigned short dataReg
        cdef unsigned long op1, op2
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op1 = self.registers.regRead(dataReg, False)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize, False)
        self.registers.regAdd(dataReg, op2)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_ADD, False)
    cdef adcRM_R(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        op2 = self.registers.modRLoad(rmOperands, operSize, False)
        self.registers.modRMSave(rmOperands, operSize, op2, True, VALUEOP_ADC)
        self.registers.setFullFlags(op1+self.registers.getEFLAG(FLAG_CF), op2, operSize, SET_FLAGS_ADD, False)
    cdef adcR_RM(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRLoad(rmOperands, operSize, False)
        op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        self.registers.modRSave(rmOperands, operSize, op2, VALUEOP_ADC)
        self.registers.setFullFlags(op1+self.registers.getEFLAG(FLAG_CF), op2, operSize, SET_FLAGS_ADD, False)
    cdef adcAxImm(self, unsigned char operSize):
        cdef unsigned short dataReg
        cdef unsigned long op1, op2
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op1 = self.registers.regRead(dataReg, False)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize, False)
        self.registers.regAdc(dataReg, op2)
        self.registers.setFullFlags(op1+self.registers.getEFLAG(FLAG_CF), op2, operSize, SET_FLAGS_ADD, False)
    cdef subRM_R(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        op2 = self.registers.modRLoad(rmOperands, operSize, False)
        self.registers.modRMSave(rmOperands, operSize, op2, True, VALUEOP_SUB)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_SUB, False)
    cdef subR_RM(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRLoad(rmOperands, operSize, False)
        op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        self.registers.modRSave(rmOperands, operSize, op2, VALUEOP_SUB)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_SUB, False)
    cdef subAxImm(self, unsigned char operSize):
        cdef unsigned short dataReg
        cdef unsigned long op1, op2
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op1 = self.registers.regRead(dataReg, False)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize, False)
        self.registers.regSub(dataReg, op2)
        self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_SUB, False)
    cdef sbbRM_R(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        op2 = self.registers.modRLoad(rmOperands, operSize, False)
        self.registers.modRMSave(rmOperands, operSize, op2, True, VALUEOP_SBB)
        self.registers.setFullFlags(op1-self.registers.getEFLAG(FLAG_CF), op2, operSize, SET_FLAGS_SUB, False)
    cdef sbbR_RM(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRLoad(rmOperands, operSize, False)
        op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        self.registers.modRSave(rmOperands, operSize, op2, VALUEOP_SBB)
        self.registers.setFullFlags(op1-self.registers.getEFLAG(FLAG_CF), op2, operSize, SET_FLAGS_SUB, False)
    cdef sbbAxImm(self, unsigned char operSize):
        cdef unsigned short dataReg
        cdef unsigned long op1, op2
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op1 = self.registers.regRead(dataReg, False)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize, False)
        self.registers.regSbb(dataReg, op2)
        self.registers.setFullFlags(op1-self.registers.getEFLAG(FLAG_CF), op2, operSize, SET_FLAGS_SUB, False)
    cdef andRM_R(self, unsigned char operSize):
        cdef unsigned long op2, data
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op2 = self.registers.modRLoad(rmOperands, operSize, False)
        data = self.registers.modRMSave(rmOperands, operSize, op2, True, VALUEOP_AND)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    cdef andR_RM(self, unsigned char operSize):
        cdef unsigned long op2, data
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        data = self.registers.modRSave(rmOperands, operSize, op2, VALUEOP_AND)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    cdef andAxImm(self, unsigned char operSize):
        cdef unsigned short dataReg
        cdef unsigned long op2, data
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize, False)
        data = self.registers.regAnd(dataReg, op2)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    
    
    
    cdef orRM_R(self, unsigned char operSize):
        cdef unsigned long op2, data
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op2 = self.registers.modRLoad(rmOperands, operSize, False)
        data = self.registers.modRMSave(rmOperands, operSize, op2, True, VALUEOP_OR)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    cdef orR_RM(self, unsigned char operSize):
        cdef unsigned long op2, data
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        data = self.registers.modRSave(rmOperands, operSize, op2, VALUEOP_OR)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    cdef orAxImm(self, unsigned char operSize):
        cdef unsigned short dataReg
        cdef unsigned long op2, data
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize, False)
        data = self.registers.regOr(dataReg, op2)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    
    
    
    cdef xorRM_R(self, unsigned char operSize):
        cdef unsigned long op2, data
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op2 = self.registers.modRLoad(rmOperands, operSize, False)
        data = self.registers.modRMSave(rmOperands, operSize, op2, True, VALUEOP_XOR)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    cdef xorR_RM(self, unsigned char operSize):
        cdef unsigned long op2, data
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        data = self.registers.modRSave(rmOperands, operSize, op2, VALUEOP_XOR)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    cdef xorAxImm(self, unsigned char operSize):
        cdef unsigned short dataReg
        cdef unsigned long op2, data
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        op2 = self.cpu.getCurrentOpcodeAdd(operSize, False) # IMM16_32
        data = self.registers.regXor(dataReg, op2)
        self.registers.setSZP_C0_O0_A0(data, operSize)
    
    
    cdef stosFunc(self, unsigned char operSize):
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
        data = self.registers.regRead(srcReg, False)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        dataLength = operSize*countVal
        destAddr = self.registers.regRead(dataReg, False)
        if (df):
            destAddr -= dataLength-operSize
        memData = data.to_bytes(length=operSize, byteorder="little")*countVal
        self.main.mm.mmWrite(destAddr, memData, dataLength, CPU_SEGMENT_ES, False)
        if (not df):
            self.registers.regAdd(dataReg, dataLength)
        else:
            self.registers.regSub(dataReg, dataLength)
        self.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite( countReg, 0 )
    cdef movsFunc(self, unsigned char operSize):
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
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        dataLength = operSize*countVal
        esiVal = self.registers.regRead(esiReg, False)
        ediVal = self.registers.regRead(ediReg, False)
        if (df):
            esiVal -= dataLength-operSize
            ediVal -= dataLength-operSize
        data = self.main.mm.mmRead(esiVal, dataLength, CPU_SEGMENT_DS, True)
        self.main.mm.mmWrite(ediVal, data, dataLength, CPU_SEGMENT_ES, False)
        if (not df):
            self.registers.regAdd(esiReg, dataLength)
            self.registers.regAdd(ediReg, dataLength)
        else:
            self.registers.regSub(esiReg, dataLength)
            self.registers.regSub(ediReg, dataLength)
        self.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite( countReg, 0 )
    cdef lodsFunc(self, unsigned char operSize):
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
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        dataLength = operSize*countVal
        if (not df):
            esiVal = self.registers.regAdd(esiReg, dataLength)-operSize
        else:
            esiVal = self.registers.regSub(esiReg, dataLength)+operSize
        data = self.main.mm.mmReadValue(esiVal, operSize, CPU_SEGMENT_DS, False, True)
        self.registers.regWrite(eaxReg, data)
        self.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite( countReg, 0 )
    cdef cmpsFunc(self, unsigned char operSize):
        cdef unsigned char addrSize, df, zf
        cdef unsigned short esiReg, ediReg, countReg
        cdef unsigned long esiVal, ediVal, countVal, newCount, src1, src2
        addrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_CS)
        esiReg  = self.registers.getWordAsDword(CPU_REGISTER_SI, addrSize)
        ediReg  = self.registers.getWordAsDword(CPU_REGISTER_DI, addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal, newCount = 1, 0
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        esiVal = self.registers.regRead(esiReg, False)
        ediVal = self.registers.regRead(ediReg, False)
        for i in range(countVal):
            src1 = self.main.mm.mmReadValue(esiVal, operSize, CPU_SEGMENT_DS, False, True)
            src2 = self.main.mm.mmReadValue(ediVal, operSize, CPU_SEGMENT_ES, False, False)
            self.registers.setFullFlags(src1, src2, operSize, SET_FLAGS_SUB, False)
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
    cdef scasFunc(self, unsigned char operSize):
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
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        for i in range(countVal):
            ediVal = self.registers.regRead(ediReg, False)
            src1 = self.registers.regRead(eaxReg, False)
            src2 = self.main.mm.mmReadValue(ediVal, operSize, CPU_SEGMENT_ES, False, False)
            self.registers.setFullFlags(src1, src2, operSize, SET_FLAGS_SUB, False)
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
    cdef inAxImm8(self, unsigned char operSize):
        cdef unsigned short dataReg
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        self.registers.regWrite(dataReg, self.main.platform.inPort(self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False), operSize))
    cdef inAxDx(self, unsigned char operSize):
        cdef unsigned short dataReg
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        self.registers.regWrite(dataReg, self.main.platform.inPort(self.registers.regRead(CPU_REGISTER_DX, False), operSize))
    cdef outImm8Ax(self, unsigned char operSize):
        cdef unsigned short dataReg
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        self.main.platform.outPort(self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False), self.registers.regRead(dataReg, False), operSize)
    cdef outDxAx(self, unsigned char operSize):
        cdef unsigned short dataReg
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        self.main.platform.outPort(self.registers.regRead(CPU_REGISTER_DX, False), self.registers.regRead(dataReg, False), operSize)
    cdef outsFunc(self, unsigned char operSize):
        cdef unsigned char addrSize, df
        cdef unsigned short dxReg, esiReg, countReg, ioPort
        cdef unsigned long value, esiVal, countVal
        addrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_CS)
        dxReg  = CPU_REGISTER_DX
        esiReg  = self.registers.getWordAsDword(CPU_REGISTER_SI, addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        for i in range(countVal):
            esiVal = self.registers.regRead(esiReg, False)
            ioPort = self.registers.regRead(dxReg, False)
            value = self.main.mm.mmReadValue(esiVal, operSize, CPU_SEGMENT_DS, False, True)
            self.main.platform.outPort(ioPort, value, operSize)
            if (not df):
                self.registers.regAdd(esiReg, operSize)
            else:
                self.registers.regSub(esiReg, operSize)
        self.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite( countReg, 0 )
    cdef insFunc(self, unsigned char operSize):
        cdef unsigned char addrSize, df
        cdef unsigned short dxReg, ediReg, countReg, ioPort
        cdef unsigned long value, ediVal, countVal
        addrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_CS)
        dxReg  = CPU_REGISTER_DX
        ediReg  = self.registers.getWordAsDword(CPU_REGISTER_DI, addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        df = self.registers.getEFLAG(FLAG_DF)
        for i in range(countVal):
            ediVal = self.registers.regRead(ediReg, False)
            ioPort = self.registers.regRead(dxReg, False)
            value = self.main.platform.inPort(ioPort, operSize)
            self.main.mm.mmWriteValue(ediVal, value, operSize, CPU_SEGMENT_ES, False)
            if (not df):
                self.registers.regAdd(ediReg, operSize)
            else:
                self.registers.regSub(ediReg, operSize)
        self.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite( countReg, 0 )
    cdef jgShort(self, unsigned char size): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_ZF) and (self.registers.getEFLAG(FLAG_SF)==self.registers.getEFLAG(FLAG_OF)))
    cdef jgeShort(self, unsigned char size): # byte8
        cdef unsigned long flags, flagsVal
        flags = FLAG_SF | FLAG_OF
        flagsVal = self.registers.getEFLAG(flags)
        self.jumpShort(size, not flagsVal or flagsVal == flags)
    cdef jlShort(self, unsigned char size): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_SF)!=self.registers.getEFLAG(FLAG_OF))
    cdef jleShort(self, unsigned char size): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_ZF) or (self.registers.getEFLAG(FLAG_SF)!=self.registers.getEFLAG(FLAG_OF)))
    cdef jnzShort(self, unsigned char size): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_ZF))
    cdef jzShort(self, unsigned char size): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_ZF))
    cdef jaShort(self, unsigned char size): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_CF) and not self.registers.getEFLAG(FLAG_ZF))
    cdef jbeShort(self, unsigned char size): # byte8
        cdef unsigned long flags
        flags = FLAG_CF | FLAG_ZF
        self.jumpShort(size, self.registers.getEFLAG(flags))
    cdef jncShort(self, unsigned char size): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_CF))
    cdef jcShort(self, unsigned char size): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_CF))
    cdef jnpShort(self, unsigned char size): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_PF))
    cdef jpShort(self, unsigned char size): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_PF))
    cdef jnoShort(self, unsigned char size): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_OF))
    cdef joShort(self, unsigned char size): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_OF))
    cdef jnsShort(self, unsigned char size): # byte8
        self.jumpShort(size, not self.registers.getEFLAG(FLAG_SF))
    cdef jsShort(self, unsigned char size): # byte8
        self.jumpShort(size, self.registers.getEFLAG(FLAG_SF))
    cdef jcxzShort(self):
        cdef unsigned char operSize
        cdef unsigned short cxReg
        cdef unsigned long cxVal
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        cxReg = self.registers.getWordAsDword(CPU_REGISTER_CX, operSize)
        cxVal = self.registers.regRead(cxReg, False)
        self.jumpShort(OP_SIZE_BYTE, cxVal==0)
    cdef jumpShort(self, unsigned char offsetSize, unsigned char c):
        cdef unsigned char operSize
        cdef unsigned short eipRegName
        cdef long offset
        cdef long long newEip
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        eipRegName = CPU_REGISTER_EIP
        offset = self.cpu.getCurrentOpcodeAdd(offsetSize, True)
        if (c):
            newEip = self.registers.regRead(eipRegName, False)+offset
            if (operSize == OP_SIZE_WORD):
                newEip &= 0xffff
            self.registers.regWrite(eipRegName, newEip)
    cdef callNearRel16_32(self):
        cdef unsigned char operSize
        cdef unsigned short eipRegName
        cdef long offset
        cdef long long newEip
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        eipRegName = CPU_REGISTER_EIP
        offset = self.cpu.getCurrentOpcodeAdd(operSize, True)
        self.stackPushRegId(eipRegName, operSize)
        newEip = self.registers.regRead(eipRegName, False)+offset
        if (operSize == OP_SIZE_WORD):
            newEip &= 0xffff
        self.registers.regWrite(eipRegName, newEip)
    cdef callPtr16_32(self):
        cdef unsigned char operSize
        cdef unsigned short segId, eipRegName, segVal
        cdef unsigned long eipAddr
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        segId = CPU_SEGMENT_CS
        eipRegName = CPU_REGISTER_EIP
        eipAddr = self.cpu.getCurrentOpcodeAdd(operSize, False)
        segVal = self.cpu.getCurrentOpcodeAdd(OP_SIZE_WORD, False)
        self.stackPushSegId(segId, operSize)
        self.stackPushRegId(eipRegName, operSize)
        self.registers.segWrite(segId, segVal)
        self.registers.regWrite(eipRegName, eipAddr)
        self.switchToProtectedModeIfNeeded()
    cdef pushaWD(self):
        cdef unsigned char operSize
        cdef unsigned short eaxName, ecxName, edxName, ebxName, espName, ebpName, esiName, ediName
        cdef unsigned long temp
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        espName = self.registers.getWordAsDword(CPU_REGISTER_SP, operSize)
        temp = self.registers.regRead( espName, False )
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
    cdef popaWD(self):
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
    cdef pushfWD(self):
        cdef unsigned char operSize, 
        cdef unsigned short regNameId
        cdef unsigned long value
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regNameId = self.registers.getWordAsDword(CPU_REGISTER_FLAGS, operSize)
        value = self.registers.regRead(regNameId, False)|2
        self.registers.setEFLAG(0x3000, False) # This is for
        value |= ((self.registers.iopl&3)<<12) # IOPL, Bits 12,13
        if (operSize == OP_SIZE_DWORD):
            value &= 0x00FCFFFF
        self.stackPushValue(value, operSize)
    cdef popfWD(self):
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
    cdef stackPopRM(self, tuple rmOperands, unsigned char operSize):
        cdef unsigned long value
        value = self.stackPopValue(operSize)
        self.registers.modRMSave(rmOperands, operSize, value, True, VALUEOP_SAVE)
    cdef stackPopSegId(self, unsigned short segId, unsigned char operSize):
        cdef unsigned short value
        value = self.stackPopValue(operSize)&0xffff
        self.registers.segWrite(segId, value)
    cdef stackPopRegId(self, unsigned short regId, unsigned char operSize):
        cdef unsigned long value
        value = self.stackPopValue(operSize)
        self.registers.regWrite(regId, value)
    cdef unsigned long stackPopValue(self, unsigned char operSize):
        cdef unsigned char stackAddrSize
        cdef unsigned short stackRegName
        cdef unsigned long stackAddr, data
        stackAddrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_SS)
        stackRegName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        stackAddr = self.registers.regRead(stackRegName, False)
        data = self.main.mm.mmReadValue(stackAddr, operSize, CPU_SEGMENT_SS, False, False)
        self.registers.regAdd(stackRegName, operSize)
        return data
    cdef stackPushSegId(self, unsigned short segId, unsigned char operSize):
        cdef unsigned long value
        value = self.registers.segRead(segId)
        self.stackPushValue(value, operSize)
    cdef stackPushRegId(self, unsigned short regId, unsigned char operSize):
        cdef unsigned long value
        value = self.registers.regRead(regId, False)
        self.stackPushValue(value, operSize)
    cdef stackPushValue(self, unsigned long value, unsigned char operSize):
        cdef unsigned char stackAddrSize
        cdef unsigned short stackRegName
        cdef unsigned long stackAddr
        stackAddrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_SS)
        stackRegName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        stackAddr = self.registers.regRead(stackRegName, False)
        if (not self.cpu.isInProtectedMode() and stackAddr == 1):
            raise misc.ChemuException(CPU_EXCEPTION_SS)
        stackAddr = self.registers.regSub(stackRegName, operSize)
        self.main.mm.mmWriteValue(stackAddr, value, operSize, CPU_SEGMENT_SS, False)
    cdef pushIMM(self, unsigned char immIsByte):
        cdef unsigned char operSize
        cdef unsigned long value
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        if (immIsByte):
            value = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, True)&self.main.misc.getBitMaskFF(operSize)
        else:
            value = self.cpu.getCurrentOpcodeAdd(operSize, False)
        self.stackPushValue(value, operSize)
    cdef imulR_RM_ImmFunc(self, unsigned char immIsByte):
        cdef unsigned char operSize
        cdef tuple rmOperands
        cdef long operOp1
        cdef long long operOp2
        cdef unsigned long operSum, bitMask
        cdef unsigned long long temp, doubleBitMask
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        bitMask = self.main.misc.getBitMaskFF(operSize)
        doubleBitMask = self.main.misc.getBitMaskFF(operSize*2)
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp1 = self.registers.modRMLoad(rmOperands, operSize, True, True)
        if (immIsByte):
            operOp2 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, True)
            operOp2 &= bitMask
        else:
            operOp2 = self.cpu.getCurrentOpcodeAdd(operSize, True)
        operSum = (operOp1*operOp2)&bitMask
        temp = (operOp1*operOp2)&doubleBitMask
        self.registers.modRSave(rmOperands, operSize, operSum, VALUEOP_SAVE)
        self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_MUL, True)
        self.registers.setEFLAG( FLAG_CF | FLAG_OF, temp!=operSum )
    cdef opcodeGroup1_RM_ImmFunc(self, unsigned char operSize, unsigned char immIsByte):
        cdef unsigned char operOpcode, operOpcodeId
        cdef unsigned long bitMask, operOp1, operOp2
        cdef tuple rmOperands
        bitMask = self.main.misc.getBitMaskFF(operSize)
        operOpcode = self.cpu.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp1 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        if (operSize != OP_SIZE_BYTE and immIsByte):
            operOp2 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, True)&bitMask # operImm8 sign-extended to destsize
        else:
            operOp2 = self.cpu.getCurrentOpcodeAdd(operSize, False) # operImm8/16/32
        if (operOpcodeId == GROUP1_OP_ADD):
            self.registers.modRMSave(rmOperands, operSize, operOp2, True, VALUEOP_ADD)
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_ADD, False)
        elif (operOpcodeId == GROUP1_OP_OR):
            operOp2 = self.registers.modRMSave(rmOperands, operSize, operOp2, True, VALUEOP_OR)
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP1_OP_ADC):
            self.registers.modRMSave(rmOperands, operSize, operOp2, True, VALUEOP_ADC)
            self.registers.setFullFlags(operOp1+self.registers.getEFLAG(FLAG_CF), operOp2, operSize, SET_FLAGS_ADD, False)
        elif (operOpcodeId == GROUP1_OP_SBB):
            self.registers.modRMSave(rmOperands, operSize, operOp2, True, VALUEOP_SBB)
            self.registers.setFullFlags(operOp1-self.registers.getEFLAG(FLAG_CF), operOp2, operSize, SET_FLAGS_SUB, False)
        elif (operOpcodeId == GROUP1_OP_AND):
            operOp2 = self.registers.modRMSave(rmOperands, operSize, operOp2, True, VALUEOP_AND)
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP1_OP_SUB):
            self.registers.modRMSave(rmOperands, operSize, operOp2, True, VALUEOP_SUB)
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_SUB, False)
        elif (operOpcodeId == GROUP1_OP_XOR):
            operOp2 = self.registers.modRMSave(rmOperands, operSize, operOp2, True, VALUEOP_XOR)
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP1_OP_CMP):
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_SUB, False)
        else:
            self.main.printMsg("opcodeGroup1_RM16_32_IMM8: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroup3_RM_ImmFunc(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId
        cdef tuple rmOperands
        cdef unsigned long operOp2
        operOpcode = self.cpu.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp2 = self.cpu.getCurrentOpcodeAdd(operSize, False) # operImm
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.registers.modRMSave(rmOperands, operSize, operOp2, True, VALUEOP_SAVE)
        else:
            self.main.printMsg("opcodeGroup3_RM16_32_IMM16_32: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroup0F(self):
        cdef unsigned char operSize, addrSize, operOpcode, bitSize, operOpcodeMod, operOpcodeModId, oldPE, newPE, \
            newCF, newOF, oldOF, count, eaxIsInvalid, 
        cdef unsigned long eaxId, bitMask, bitMaskHalf, base, limit, mmAddr, op1, op2
        cdef tuple rmOperands, rmOperandsOther
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        if (operOpcode == 0x00): # LLDT/SLDT LTR/STR VERR/VERW
            if (self.registers.cpl != 0):
                raise misc.ChemuException(CPU_EXCEPTION_GP, 0)
            if (not self.cpu.isInProtectedMode()):
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            operOpcodeMod = self.cpu.getCurrentOpcode(OP_SIZE_BYTE, False)
            operOpcodeModId = (operOpcodeMod>>3)&7
            rmOperands = self.registers.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            mmAddr = self.registers.getRMValueFull(rmOperands[1][0], addrSize)
            if (operOpcodeModId in (0, 1)): # SLDT/STR
                if (operOpcodeModId == 1): # STR
                    op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD, False, True)
                    if (self.registers.lockPrefix or not self.cpu.isInProtectedMode()): 
                        raise misc.ChemuException(CPU_EXCEPTION_UD)
                    self.main.exitError("opcodeGroup0F_00: STR not supported yet.")
                elif (operOpcodeModId == 0): # SLDT
                    base, limit = self.registers.segments.ldt.getBaseLimit()
                    limit &= 0xffff
                    if (operSize == OP_SIZE_WORD):
                        base &= 0xffffff
                    self.main.mm.mmWriteValue(mmAddr, limit, OP_SIZE_WORD, CPU_SEGMENT_DS, True)
                    self.main.mm.mmWriteValue(mmAddr+OP_SIZE_WORD, base, OP_SIZE_DWORD, CPU_SEGMENT_DS, True)
            elif (operOpcodeModId in (2, 3)): # LLDT/LTR
                if (operOpcodeModId == 2): # LLDT
                    limit = self.main.mm.mmReadValue(mmAddr, OP_SIZE_WORD, CPU_SEGMENT_DS, False, True)
                    base = self.main.mm.mmReadValue(mmAddr+OP_SIZE_WORD, OP_SIZE_DWORD, CPU_SEGMENT_DS, False, True)
                    if (operSize == OP_SIZE_WORD):
                        base &= 0xffffff
                    self.registers.segments.ldt.loadTable(base, limit)
                elif (operOpcodeModId == 3): # LTR
                    op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD, False, True)
                    if (self.registers.lockPrefix or not self.cpu.isInProtectedMode()): 
                        raise misc.ChemuException(CPU_EXCEPTION_UD)
                    elif (self.registers.cpl != 0 or op1&0xfff8 == 0):
                        raise misc.ChemuException( CPU_EXCEPTION_GP, 0)
                    elif (not self.registers.segments.isSegPresent(op1)):
                        raise misc.ChemuException( CPU_EXCEPTION_NP, op1)
                    self.main.exitError("opcodeGroup0F_00: LTR not supported yet.")
            elif (operOpcodeModId == 4): # VERR
                op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD, False, True)
                self.registers.setEFLAG( FLAG_CF, self.registers.segments.checkReadAllowed(op1, False) )
            elif (operOpcodeModId == 5): # VERW
                op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD, False, True)
                self.registers.setEFLAG( FLAG_CF, self.registers.segments.checkWriteAllowed(op1, False) )
            else:
                self.main.printMsg("opcodeGroup0F_00: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise misc.ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x01): # LGDT/LIDT SGDT/SIDT SMSW/LMSW
            if (self.registers.cpl != 0):
                raise misc.ChemuException(CPU_EXCEPTION_GP, 0)
            operOpcodeMod = self.cpu.getCurrentOpcode(OP_SIZE_BYTE, False)
            operOpcodeModId = (operOpcodeMod>>3)&7
            if (operOpcodeModId in (0, 1, 2, 3)): # LGDT/LIDT SGDT/SIDT
                rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            else: # SMSW/LMSW
                rmOperands = self.registers.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
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
                self.main.mm.mmWriteValue(mmAddr, limit, OP_SIZE_WORD, CPU_SEGMENT_DS, True)
                self.main.mm.mmWriteValue(mmAddr+OP_SIZE_WORD, base, OP_SIZE_DWORD, CPU_SEGMENT_DS, True)
            elif (operOpcodeModId in (2, 3)): # LGDT/LIDT
                limit = self.main.mm.mmReadValue(mmAddr, OP_SIZE_WORD, CPU_SEGMENT_DS, False, True)
                base = self.main.mm.mmReadValue(mmAddr+OP_SIZE_WORD, OP_SIZE_DWORD, CPU_SEGMENT_DS, False, True)
                if (operSize == OP_SIZE_WORD):
                    base &= 0xffffff
                if (operOpcodeModId == 2): # LGDT
                    self.registers.segments.gdt.loadTable(base, limit)
                elif (operOpcodeModId == 3): # LIDT
                    self.registers.segments.idt.loadTable(base, limit)
            elif (operOpcodeModId == 4): # SMSW
                op2 = self.registers.regRead(CPU_REGISTER_CR0, False)&0xffff
                self.registers.modRMSave(rmOperands, OP_SIZE_WORD, op2, True, VALUEOP_SAVE)
            elif (operOpcodeModId == 6): # LMSW
                if (self.registers.cpl != 0):
                    raise misc.ChemuException( CPU_EXCEPTION_GP, 0 )
                op1 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD, False, True)
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
            self.registers.modRMSave(rmOperands, OP_SIZE_DWORD, self.registers.modRLoad(rmOperands, OP_SIZE_DWORD, False), True, VALUEOP_SAVE)
        elif (operOpcode == 0x21): # MOV R32, DRn
            rmOperands = self.registers.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_DREG)
            self.registers.modRMSave(rmOperands, OP_SIZE_DWORD, self.registers.modRLoad(rmOperands, OP_SIZE_DWORD, False), True, VALUEOP_SAVE)
        elif (operOpcode == 0x22): # MOV CRn, R32
            rmOperands = self.registers.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_CREG)
            oldPE = self.registers.getFlag( CPU_REGISTER_CR0, CR0_FLAG_PE )
            self.registers.modRSave(rmOperands, OP_SIZE_DWORD, self.registers.modRMLoad(rmOperands, OP_SIZE_DWORD, False, True), VALUEOP_SAVE)
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
            self.registers.modRSave(rmOperands, OP_SIZE_DWORD, self.registers.modRMLoad(rmOperands, OP_SIZE_DWORD, False, True), VALUEOP_SAVE)
        elif (operOpcode == 0x31): # RDTSC
            if (not self.registers.getFlag( CPU_REGISTER_CR4, CR4_FLAG_TSD ) or \
                 self.registers.cpl == 0 or not self.cpu.isInProtectedMode()):
                self.registers.regWrite( CPU_REGISTER_EAX, self.cpu.cycles&0xffffffff )
                self.registers.regWrite( CPU_REGISTER_EDX, (self.cpu.cycles>>32)&0xffffffff )
            else:
                raise misc.ChemuException( CPU_EXCEPTION_GP, 0 )
        elif (operOpcode == 0x38): # MOVBE
            operOpcodeMod = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            if (operOpcodeMod == 0xf0): # MOVBE R16_32, M16_32
                op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
                op2 = self.main.misc.reverseByteOrder(op2, operSize)
                self.registers.modRSave(rmOperands, operSize, op2, VALUEOP_SAVE)
            elif (operOpcodeMod == 0xf1): # MOVBE M16_32, R16_32
                op2 = self.registers.modRLoad(rmOperands, operSize, False)
                op2 = self.main.misc.reverseByteOrder(op2, operSize)
                self.registers.modRMSave(rmOperands, operSize, op2, True, VALUEOP_SAVE)
            else:
                self.main.exitError("MOVBE: operOpcodeMod {0:#04x} not in (0xf0, 0xf1)", operOpcodeMod)
        elif (operOpcode >= 0x40 and operOpcode <= 0x4f): # CMOVcc
            self.cmovFunc(operSize, self.registers.getCond( operOpcode&0xf ) )
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
            eaxId = self.registers.regRead( CPU_REGISTER_EAX, False )
            eaxIsInvalid = (eaxId >= 0x40000000 and eaxId <= 0x4fffffff)
            if ( eaxId == 0x1 ):
                self.registers.regWrite( CPU_REGISTER_EAX, 0x400 )
                self.registers.regWrite( CPU_REGISTER_EBX, 0x0 )
                self.registers.regWrite( CPU_REGISTER_EDX, 0x8010 )
                self.registers.regWrite( CPU_REGISTER_ECX, 0xc00000 )
            elif ( eaxId == 0x2 ):
                self.registers.regWrite( CPU_REGISTER_EAX, 0x1 )
                self.registers.regWrite( CPU_REGISTER_EBX, 0x0 )
                self.registers.regWrite( CPU_REGISTER_EDX, 0x0 )
                self.registers.regWrite( CPU_REGISTER_ECX, 0x0 )
            elif ( eaxId in (0x3, 0x4, 0x5, 0x6, 0x7)): #, 0x80000005, 0x80000006, 0x80000007) ):
                self.registers.regWrite( CPU_REGISTER_EAX, 0x0 )
                self.registers.regWrite( CPU_REGISTER_EBX, 0x0 )
                self.registers.regWrite( CPU_REGISTER_EDX, 0x0 )
                self.registers.regWrite( CPU_REGISTER_ECX, 0x0 )
            #elif ( eaxId == 0x80000000 ):
            #    self.registers.regWrite( CPU_REGISTER_EAX, 0x80000001 )
            #    self.registers.regWrite( CPU_REGISTER_EBX, 0x0 )
            #    self.registers.regWrite( CPU_REGISTER_EDX, 0x0 )
            #    self.registers.regWrite( CPU_REGISTER_ECX, 0x0 )
            #elif ( eaxId == 0x80000001 ):
            #    self.registers.regWrite( CPU_REGISTER_EAX, 0x0 )
            #    self.registers.regWrite( CPU_REGISTER_EBX, 0x0 )
            #    self.registers.regWrite( CPU_REGISTER_EDX, 0x0 )
            #    self.registers.regWrite( CPU_REGISTER_ECX, 0x0 )
            #elif ( eaxId == 0x0 or eaxIsInvalid ):
            else:
                if ( not (eaxId == 0x0 or eaxIsInvalid) ):
                    self.main.printMsg("CPUID: eaxId {0:#04x} unknown.", eaxId)
                self.registers.regWrite( CPU_REGISTER_EAX, 0x7 )
                self.registers.regWrite( CPU_REGISTER_EBX, 0x756e6547 )
                self.registers.regWrite( CPU_REGISTER_EDX, 0x49656e69 )
                self.registers.regWrite( CPU_REGISTER_ECX, 0x6c65746e )
            #else:
            #    self.main.exitError("CPUID: eaxId {0:#04x} unknown.", eaxId)
        elif (operOpcode == 0xa3): # BT RM16/32, R16
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.registers.modRLoad(rmOperands, operSize, False)
            self.btFunc(rmOperands, op2, BT_NONE)
        elif (operOpcode in (0xa4, 0xa5)): # SHLD
            bitMaskHalf = self.main.misc.getBitMask80(operSize)
            bitSize = operSize << 3
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            if (operOpcode == 0xa4): # SHLD imm8
                count = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            elif (operOpcode == 0xa5): # SHLD CL
                count = self.registers.regRead( CPU_REGISTER_CL, False )
            else:
                self.main.exitError("group0F::SHLD: operOpcode {0:#04x} unknown.", operOpcode)
                return
            count %= 32
            if (count == 0):
                return
            if (count > bitSize): # bad parameters
                self.main.exitError("group0F: SHLD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).", count, bitSize, operOpcode)
                return
            op1 = self.registers.modRMLoad(rmOperands, operSize, False, True) # dest
            oldOF = op1&bitMaskHalf
            op2  = self.registers.modRLoad(rmOperands, operSize, False) # src
            newCF = self.registers.valGetBit(op1, bitSize-count)!=0
            for i in range(bitSize-1, count-1, -1):
                tmpBit = self.registers.valGetBit(op1, i-count)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            for i in range(count-1, -1, -1):
                tmpBit = self.registers.valGetBit(op2, i-count+bitSize)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            self.registers.modRMSave(rmOperands, operSize, op1, True, VALUEOP_SAVE)
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
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.registers.modRLoad(rmOperands, operSize, False)
            self.btsFunc(rmOperands, op2)
        elif (operOpcode in (0xac, 0xad)): # SHRD
            bitMaskHalf = self.main.misc.getBitMask80(operSize)
            bitSize = operSize << 3
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            if (operOpcode == 0xac): # SHRD imm8
                count = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            elif (operOpcode == 0xad): # SHRD CL
                count = self.registers.regRead( CPU_REGISTER_CL, False )
            else:
                self.main.exitError("group0F::SHRD: operOpcode {0:#04x} unknown.", operOpcode)
                return
            count %= 32
            if (count == 0):
                return
            if (count > bitSize): # bad parameters
                self.main.exitError("group0F: SHRD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).", count, bitSize, operOpcode)
                return
            op1 = self.registers.modRMLoad(rmOperands, operSize, False, True) # dest
            oldOF = op1&bitMaskHalf
            op2  = self.registers.modRLoad(rmOperands, operSize, False) # src
            newCF = self.registers.valGetBit(op1, count-1)!=0
            for i in range(bitSize-count):
                tmpBit = self.registers.valGetBit(op1, i+count)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            for i in range(bitSize-count, bitSize):
                tmpBit = self.registers.valGetBit(op2, i+count-bitSize)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            self.registers.modRMSave(rmOperands, operSize, op1, True, VALUEOP_SAVE)
            if (count == 1):
                newOF = oldOF!=(op1&bitMaskHalf)
                self.registers.setEFLAG( FLAG_OF, newOF )
            self.registers.setEFLAG( FLAG_CF, newCF )
            self.registers.setSZP(op1, operSize)
        elif (operOpcode == 0xaf): # IMUL R16_32, R/M16_32
            bitMask = self.main.misc.getBitMaskFF(operSize)
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op1 = self.registers.modRLoad(rmOperands, operSize, True)&bitMask
            op2 = self.registers.modRMLoad(rmOperands, operSize, True, True)&bitMask
            self.registers.setFullFlags(op1, op2, operSize, SET_FLAGS_MUL, True)
            op1 = (op1*op2)&bitMask
            self.registers.modRSave(rmOperands, operSize, op1, VALUEOP_SAVE)
        elif (operOpcode == 0xb2): # LSS
            self.lfpFunc(CPU_SEGMENT_SS) # 'load far pointer' function
        elif (operOpcode == 0xb3): # BTR RM16/32, R16
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.registers.modRLoad(rmOperands, operSize, False)
            self.btrFunc(rmOperands, op2)
        elif (operOpcode == 0xb4): # LFS
            self.lfpFunc(CPU_SEGMENT_FS) # 'load far pointer' function
        elif (operOpcode == 0xb5): # LGS
            self.lfpFunc(CPU_SEGMENT_GS) # 'load far pointer' function
        elif (operOpcode == 0xb6): # MOVZX R16_32, R/M8
            bitMask = self.main.misc.getBitMaskFF(operSize)
            rmOperandsOther = self.registers.modRMOperandsResetEip(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            rmOperands = (rmOperands[0], rmOperandsOther[1], rmOperands[2])
            op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE, False, True)
            self.registers.modRSave(rmOperands, operSize, op2, VALUEOP_SAVE)
        elif (operOpcode == 0xb7): # MOVZX R32, R/M16
            rmOperandsOther = self.registers.modRMOperandsResetEip(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            rmOperands = self.registers.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_NONE)
            rmOperands = (rmOperands[0], rmOperandsOther[1], rmOperands[2])
            op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD, False, True)
            self.registers.modRSave(rmOperands, OP_SIZE_DWORD, op2, VALUEOP_SAVE)
        elif (operOpcode == 0xb8): # POPCNT R16/32 RM16/32
            if (self.registers.lockPrefix or self.registers.repPrefix): 
                raise misc.ChemuException(CPU_EXCEPTION_UD)
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
            op1 = bin(op2).count('1')
            self.registers.modRSave(rmOperands, operSize, op1, VALUEOP_SAVE)
            self.registers.clearThisEFLAGS( FLAG_CF | FLAG_PF | FLAG_AF | FLAG_ZF | FLAG_SF | FLAG_OF )
            self.registers.setEFLAG( FLAG_ZF, op2==0 )
        elif (operOpcode == 0xba): # BT/BTS/BTR/BTC RM16/32 IMM8
            operOpcodeMod = self.cpu.getCurrentOpcode(OP_SIZE_BYTE, False)
            operOpcodeModId = (operOpcodeMod>>3)&7
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            if (operOpcodeModId == 4): # BT
                self.btFunc(rmOperands, op2, BT_NONE)
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
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.registers.modRLoad(rmOperands, operSize, False)
            self.btcFunc(rmOperands, op2)
        elif (operOpcode == 0xbc): # BSF R16_32, R/M16_32
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
            self.registers.setEFLAG( FLAG_ZF, op2==0 )
            op1 = 0
            if (op2 != 0):
                while (not self.registers.valGetBit(op2, op1)):
                    op1 += 1
            self.registers.modRSave(rmOperands, operSize, op1, VALUEOP_SAVE)
        elif (operOpcode == 0xbd): # BSR R16_32, R/M16_32
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
            self.registers.setEFLAG( FLAG_ZF, op2==0 )
            self.registers.modRSave(rmOperands, operSize, op2.bit_length()-1, VALUEOP_SAVE)
        elif (operOpcode == 0xbe): # MOVSX R16_32, R/M8
            bitMask = self.main.misc.getBitMaskFF(operSize)
            rmOperandsOther = self.registers.modRMOperandsResetEip(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
            rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
            rmOperands = (rmOperands[0], rmOperandsOther[1], rmOperands[2])
            op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_BYTE, True, True)&bitMask
            self.registers.modRSave(rmOperands, operSize, op2, VALUEOP_SAVE)
        elif (operOpcode == 0xbf): # MOVSX R32, R/M16
            rmOperandsOther = self.registers.modRMOperandsResetEip(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            rmOperands = self.registers.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_NONE)
            rmOperands = (rmOperands[0], rmOperandsOther[1], rmOperands[2])
            op2 = self.registers.modRMLoad(rmOperands, OP_SIZE_WORD, True, True)&0xffffffff
            self.registers.modRSave(rmOperands, OP_SIZE_DWORD, op2, VALUEOP_SAVE)
        elif (operOpcode >= 0xc8 and operOpcode <= 0xcf): # BSWAP R32
            regName  = CPU_REGISTER_DWORD[operOpcode&7]
            op1 = self.registers.regRead(regName, False)
            op1 = self.main.misc.reverseByteOrder(op1, OP_SIZE_DWORD)
            self.registers.regWrite(regName, op1)
        else:
            self.main.printMsg("opcodeGroup0F: invalid operOpcode. {0:#04x}", operOpcode)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroupFE(self):
        cdef unsigned char operSize, operOpcode, operOpcodeId
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(rmOperands, OP_SIZE_BYTE)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(rmOperands, OP_SIZE_BYTE)
        else:
            self.main.printMsg("opcodeGroupFE: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroupFF(self):
        cdef unsigned char operSize, operOpcode, operOpcodeId
        cdef unsigned short eipName, segVal
        cdef unsigned long op1, eipAddr
        cdef tuple rmOperands, rmValue
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(rmOperands, operSize)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(rmOperands, operSize)
        elif (operOpcodeId == 2): # 2/CALL NEAR
            eipName = CPU_REGISTER_EIP
            eipAddr = self.registers.modRMLoad(rmOperands, operSize, False, True)
            self.stackPushRegId(eipName, operSize)
            self.registers.regWrite(eipName, eipAddr)
        elif (operOpcodeId == 3): # 3/CALL FAR
            segId = CPU_SEGMENT_CS
            eipName = CPU_REGISTER_EIP
            rmValue = rmOperands[1]
            op1 = self.registers.getRMValueFull(rmValue[0], operSize)
            eipAddr = self.main.mm.mmReadValue(op1, operSize, rmValue[1], False, True)
            segVal = self.main.mm.mmReadValue(op1+operSize, OP_SIZE_WORD, rmValue[1], False, True)
            self.stackPushSegId(segId, operSize)
            self.stackPushRegId(eipName, operSize)
            self.registers.segWrite(segId, segVal)
            self.registers.regWrite(eipName, eipAddr)
            self.switchToProtectedModeIfNeeded()
        elif (operOpcodeId == 4): # 4/JMP NEAR
            rmValue = rmOperands[1]
            eipAddr = self.registers.modRMLoad(rmOperands, operSize, False, True)
            self.registers.regWrite(CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 5): # 5/JMP FAR
            segId = CPU_SEGMENT_CS
            eipName = CPU_REGISTER_EIP
            rmValue = rmOperands[1]
            op1 = self.registers.getRMValueFull(rmValue[0], operSize)
            eipAddr = self.main.mm.mmReadValue(op1, operSize, rmValue[1], False, True)
            segVal = self.main.mm.mmReadValue(op1+operSize, OP_SIZE_WORD, rmValue[1], False, True)
            self.registers.segWrite(segId, segVal)
            self.registers.regWrite(CPU_REGISTER_EIP, eipAddr)
            self.switchToProtectedModeIfNeeded()
        elif (operOpcodeId == 6): # 6/PUSH
            op1 = self.registers.modRMLoad(rmOperands, operSize, False, True)
            self.stackPushValue(op1, operSize)
        else:
            self.main.printMsg("opcodeGroupFF: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    cdef incFuncReg(self, unsigned char regId):
        cdef unsigned char origCF, regSize
        cdef unsigned long retValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        regSize = self.registers.regGetSize(regId)
        retValue = self.registers.regAdd(regId, 1)
        self.registers.setFullFlags(retValue-1, 1, regSize, SET_FLAGS_ADD, False)
        self.registers.setEFLAG(FLAG_CF, origCF)
    cdef decFuncReg(self, unsigned char regId):
        cdef unsigned char origCF, regSize
        cdef unsigned long retValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        regSize = self.registers.regGetSize(regId)
        retValue = self.registers.regSub(regId, 1)
        self.registers.setFullFlags(retValue+1, 1, regSize, SET_FLAGS_SUB, False)
        self.registers.setEFLAG(FLAG_CF, origCF)
    cdef incFuncRM(self, tuple rmOperands, unsigned char rmSize): # rmSize in bits
        cdef unsigned char origCF
        cdef unsigned long retValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        retValue = self.registers.modRMSave(rmOperands, rmSize, 1, True, VALUEOP_ADD)
        self.registers.setFullFlags(retValue-1, 1, rmSize, SET_FLAGS_ADD, False)
        self.registers.setEFLAG(FLAG_CF, origCF)
    cdef decFuncRM(self, tuple rmOperands, unsigned char rmSize): # rmSize in bits
        cdef unsigned char origCF
        cdef unsigned long retValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        retValue = self.registers.modRMSave(rmOperands, rmSize, 1, True, VALUEOP_SUB)
        self.registers.setFullFlags(retValue+1, 1, rmSize, SET_FLAGS_SUB, False)
        self.registers.setEFLAG(FLAG_CF, origCF)
    cdef incReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regName  = CPU_REGISTER_WORD[self.cpu.opcode&7]
        regName  = self.registers.getWordAsDword(regName, operSize)
        self.incFuncReg(regName)
    cdef decReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regName  = CPU_REGISTER_WORD[self.cpu.opcode&7]
        regName  = self.registers.getWordAsDword(regName, operSize)
        self.decFuncReg(regName)
    
    
    cdef pushReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regName  = CPU_REGISTER_WORD[self.cpu.opcode&7]
        regName  = self.registers.getWordAsDword(regName, operSize)
        self.stackPushRegId(regName, operSize)
    cdef pushSeg(self, short opcode):
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
    cdef popReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regName  = self.registers.getWordAsDword(CPU_REGISTER_WORD[self.cpu.opcode&7], operSize)
        self.stackPopRegId(regName, operSize)
    cdef popSeg(self, short opcode):
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
    cdef popRM16_32(self):
        cdef unsigned char operSize, operOpcode, operOpcodeId
        cdef tuple rmOperands
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        operOpcode = self.cpu.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (operOpcodeId == 0): # POP
            self.stackPopRM(rmOperands, operSize)
        else:
            self.main.printMsg("popRM16_32: unknown operOpcodeId: {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    cdef lea(self):
        cdef unsigned char operSize, addrSize
        cdef unsigned long mmAddr
        cdef tuple rmOperands
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(addrSize, MODRM_FLAGS_NONE)
        mmAddr = self.registers.getRMValueFull(rmOperands[1][0], addrSize)
        self.registers.modRSave(rmOperands, operSize, mmAddr, VALUEOP_SAVE)
    cdef retNear(self, unsigned char imm):
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
    cdef retNearImm(self):
        cdef unsigned short imm
        imm = self.cpu.getCurrentOpcodeAdd(OP_SIZE_WORD, False) # imm16
        self.retNear(imm)
    cdef retFar(self, unsigned char imm):
        cdef unsigned char operSize, stackAddrSize
        cdef unsigned short eipName, espName, tempCS
        cdef unsigned long tempEIP
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        stackAddrSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_SS)
        eipName = CPU_REGISTER_EIP
        espName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        tempEIP = self.stackPopValue(operSize)
        tempCS = self.stackPopValue(operSize)
        self.registers.regWrite(eipName, tempEIP)
        self.registers.segWrite(CPU_SEGMENT_CS, tempCS)
        if (imm):
            self.registers.regAdd(espName, imm)
        self.switchToProtectedModeIfNeeded()
    cdef retFarImm(self):
        cdef unsigned short imm
        imm = self.cpu.getCurrentOpcodeAdd(OP_SIZE_WORD, False) # imm16
        self.retFar(imm)
    cdef lfpFunc(self, unsigned char segId): # 'load far pointer' function
        cdef unsigned char operSize
        cdef unsigned short segmentAddr
        cdef unsigned long mmAddr, offsetAddr
        cdef tuple rmOperands, rmValue
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        rmValue = rmOperands[1]
        mmAddr = self.registers.getRMValueFull(rmValue[0], operSize)
        offsetAddr = self.main.mm.mmReadValue(mmAddr, operSize, rmValue[1], False, True)
        segmentAddr = self.main.mm.mmReadValue(mmAddr+operSize, OP_SIZE_WORD, rmValue[1], False, True)
        self.registers.modRSave(rmOperands, operSize, offsetAddr, VALUEOP_SAVE)
        self.registers.segWrite(segId, segmentAddr)
    cdef xlatb(self):
        cdef unsigned char operSize, addrSize, m8, data
        cdef unsigned short baseReg
        cdef unsigned long baseValue
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        m8 = self.registers.regRead(CPU_REGISTER_AL, False)
        baseReg = self.registers.getWordAsDword(CPU_REGISTER_BX, addrSize)
        baseValue = self.registers.regRead(baseReg, False)
        data = self.main.mm.mmReadValue(baseValue+m8, OP_SIZE_BYTE, CPU_SEGMENT_DS, False, True)
        self.registers.regWrite(CPU_REGISTER_AL, data)
    cdef opcodeGroup2_RM(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId, operSizeInBits
        cdef unsigned long operOp2, bitMaskHalf, bitMask
        cdef long long sop1, temp, tempmod
        cdef long sop2
        cdef unsigned long long operOp1, doubleBitMask, doubleBitMaskHalf
        cdef tuple rmOperands
        operOpcode = self.cpu.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        operSizeInBits = operSize << 3
        bitMask = self.main.misc.getBitMaskFF(operSize)
        bitMaskHalf = self.main.misc.getBitMask80(operSize)
        if (operOpcodeId in (GROUP2_OP_TEST, GROUP2_OP_TEST_ALIAS)):
            operOp1 = self.cpu.getCurrentOpcodeAdd(operSize, False)
            operOp2 = operOp2&operOp1
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP2_OP_NOT):
            operOp2 = (~operOp2)
            self.registers.modRMSave(rmOperands, operSize, operOp2, True, VALUEOP_SAVE)
        elif (operOpcodeId == GROUP2_OP_NEG):
            operOp1 = (-operOp2)
            self.registers.modRMSave(rmOperands, operSize, operOp1, True, VALUEOP_SAVE)
            self.registers.setFullFlags(0, operOp2, operSize, SET_FLAGS_SUB, False)
            self.registers.setEFLAG(FLAG_CF, operOp2!=0)
        
        
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_MUL):
            operOp1 = self.registers.regRead(CPU_REGISTER_AL, False)
            operSum = operOp1*operOp2
            self.registers.regWrite(CPU_REGISTER_AX, operSum&0xffff)
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_MUL, False)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_IMUL):
            sop1 = self.registers.regRead(CPU_REGISTER_AL, True)
            sop2 = self.registers.modRMLoad(rmOperands, operSize, True, True)
            operSum = sop1*sop2
            self.registers.regWrite(CPU_REGISTER_AX, operSum&0xffff)
            self.registers.setFullFlags(sop1, sop2, operSize, SET_FLAGS_MUL, True)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_DIV):
            op1Word = self.registers.regRead(CPU_REGISTER_AX, False)
            if (operOp2 == 0):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(op1Word, operOp2)
            if (temp > <unsigned char>bitMask):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            self.registers.regWrite(CPU_REGISTER_AL, temp)
            self.registers.regWrite(CPU_REGISTER_AH, tempmod)
            self.registers.setFullFlags(op1Word, operOp2, operSize, SET_FLAGS_DIV, False)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_IDIV):
            sop1  = self.registers.regRead(CPU_REGISTER_AX, True)
            sop2  = self.registers.modRMLoad(rmOperands, operSize, True, True)
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
            self.registers.setFullFlags(sop1, operOp2, operSize, SET_FLAGS_DIV, False)
        
        
        
        elif (operOpcodeId == GROUP2_OP_MUL):
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
            operOp1 = self.registers.regRead(eaxReg, False)
            operSum = operOp1*operOp2
            self.registers.regWrite(edxReg, (operSum>>operSizeInBits)&bitMask)
            self.registers.regWrite(eaxReg, operSum&bitMask)
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_MUL, False)
        elif (operOpcodeId == GROUP2_OP_IMUL):
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
            sop1 = self.registers.regRead(eaxReg, True)
            sop2 = self.registers.modRMLoad(rmOperands, operSize, True, True)
            operSum = sop1*sop2
            self.registers.regWrite(edxReg, (operSum>>operSizeInBits)&bitMask)
            self.registers.regWrite(eaxReg, operSum&bitMask)
            self.registers.setFullFlags(sop1, sop2, operSize, SET_FLAGS_MUL, True)
        elif (operOpcodeId == GROUP2_OP_DIV):
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
            operOp1  = self.registers.regRead(eaxReg, False)
            operOp1 |= self.registers.regRead(edxReg, False)<<operSizeInBits
            if (operOp2 == 0):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(operOp1, operOp2)
            if (temp > <unsigned long>bitMask):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            self.registers.regWrite(eaxReg, temp&bitMask)
            self.registers.regWrite(edxReg, tempmod&bitMask)
            self.registers.setFullFlags(operOp1, operOp2, operSize, SET_FLAGS_DIV, False)
        elif (operOpcodeId == GROUP2_OP_IDIV):
            doubleBitMaskHalf = self.main.misc.getBitMask80(operSize*2)
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
            operOp1 = self.registers.regRead(edxReg, False)<<operSizeInBits
            operOp1 |= self.registers.regRead(eaxReg, False)
            if (operOp1 & doubleBitMaskHalf):
                sop1 = operOp1-doubleBitMaskHalf
                sop1 -= doubleBitMaskHalf
            else:
                sop1 = operOp1
            sop2 = self.registers.modRMLoad(rmOperands, operSize, True, True)
            operOp2 = abs(sop2)
            if (operOp2 == 0):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(sop1, sop2)
            if ( ((temp >= <unsigned long>bitMaskHalf) or (temp < -(<signed long long>bitMaskHalf))) ):
                raise misc.ChemuException(CPU_EXCEPTION_DE)
            self.registers.regWrite(eaxReg, temp&bitMask)
            self.registers.regWrite(edxReg, tempmod&bitMask)
            self.registers.setFullFlags(sop1, operOp2, operSize, SET_FLAGS_DIV, False)
        else:
            self.main.printMsg("opcodeGroup2_RM: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    cpdef interrupt(self, short intNum, long errorCode, unsigned char hwInt): # TODO: complete this!
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
            intNum = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
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
            if ((self.registers.cpl != 0 and self.registers.cpl > entrySegment&3) or self.registers.segments.getSegDPL(entrySegment) != 0):
                self.main.exitError("Interrupt: (cpl!=0 and cpl>rpl) or dpl!=0")
                return
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
    cdef into(self):
        if (self.registers.getEFLAG( FLAG_OF )):
            self.interrupt(CPU_EXCEPTION_OF, -1, False)
    cdef int3(self):
        self.interrupt(CPU_EXCEPTION_BP, -1, False)
    cdef iret(self):
        cdef unsigned char operSize, inProtectedMode
        cdef unsigned short newCS, newEFLAGSreg, SSsel
        cdef unsigned long tempEFLAGS, EFLAGS, newEIP, eflagsMask, temp
        inProtectedMode = self.cpu.isInProtectedMode()
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        newEIP = self.stackPopValue(operSize)
        newCS  = self.stackPopValue(operSize)
        tempEFLAGS = self.stackPopValue(operSize)
        newEFLAGSreg = CPU_REGISTER_EFLAGS
        EFLAGS = self.registers.regRead(CPU_REGISTER_EFLAGS, False)
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
    cdef aad(self):
        cdef unsigned char imm8, tempAL, tempAH
        imm8 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        tempAL = self.registers.regRead(CPU_REGISTER_AL, False)
        tempAH = self.registers.regRead(CPU_REGISTER_AH, False)
        tempAL = self.registers.regWrite(CPU_REGISTER_AX, ( tempAL + (tempAH * imm8) )&0xff)
        self.registers.setSZP_C0_O0_A0(tempAL, OP_SIZE_BYTE)
    cdef aam(self):
        cdef unsigned char imm8, tempAL, ALdiv, ALmod
        imm8 = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        if (imm8 == 0):
            raise misc.ChemuException(CPU_EXCEPTION_DE)
        tempAL = self.registers.regRead(CPU_REGISTER_AL, False)
        ALdiv, ALmod = divmod(tempAL, imm8)
        self.registers.regWrite(CPU_REGISTER_AH, ALdiv)
        self.registers.regWrite(CPU_REGISTER_AL, ALmod)
        self.registers.setSZP_C0_O0_A0(ALmod, OP_SIZE_BYTE)
    cdef aaa(self):
        cdef unsigned char AFflag, tempAL, tempAH
        cdef unsigned short tempAX
        tempAX = self.registers.regRead(CPU_REGISTER_AX, False)
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
        self.registers.setSZP_O0(self.registers.regRead(CPU_REGISTER_AL, False), OP_SIZE_BYTE)
    cdef aas(self):
        cdef unsigned char AFflag, tempAL, tempAH
        cdef unsigned short tempAX
        tempAX = self.registers.regRead(CPU_REGISTER_AX, False)
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
        self.registers.setSZP_O0(self.registers.regRead(CPU_REGISTER_AL, False), OP_SIZE_BYTE)
    cdef daa(self):
        cdef unsigned char old_AL, old_AF, old_CF
        old_AL = self.registers.regRead(CPU_REGISTER_AL, False)
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
        self.registers.setSZP_O0(self.registers.regRead(CPU_REGISTER_AL, False), OP_SIZE_BYTE)
    cdef das(self):
        cdef unsigned char old_AL, old_AF, old_CF
        old_AL = self.registers.regRead(CPU_REGISTER_AL, False)
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
        self.registers.setSZP_O0(self.registers.regRead(CPU_REGISTER_AL, False), OP_SIZE_BYTE)
    cdef cbw_cwde(self):
        cdef unsigned char operSize
        cdef unsigned short op2
        cdef unsigned long bitMask
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        bitMask = self.main.misc.getBitMaskFF(operSize)
        if (operSize == OP_SIZE_WORD):
            op2 = self.registers.regRead(CPU_REGISTER_AL, False)
            if (op2&0x80):
                self.registers.regWrite(CPU_REGISTER_AH, 0xff)
            else:
                self.registers.regWrite(CPU_REGISTER_AH, 0x00)
        elif (operSize == OP_SIZE_DWORD):
            op2 = self.registers.regRead(CPU_REGISTER_AX, False)
            if (op2&0x8000):
                self.registers.regWrite(CPU_REGISTER_EAX, 0xffff0000|op2)
            else:
                self.registers.regWrite(CPU_REGISTER_EAX, op2)
        else:
            self.main.exitError("cbw_cwde: operSize {0:d} not in (OP_SIZE_WORD, OP_SIZE_DWORD))", operSize)
    cdef cwd_cdq(self):
        cdef unsigned char operSize
        cdef unsigned short eaxReg, edxReg
        cdef unsigned long bitMask, bitMaskHalf, op2
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        bitMask = self.main.misc.getBitMaskFF(operSize)
        bitMaskHalf = self.main.misc.getBitMask80(operSize)
        eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
        op2 = self.registers.regRead(eaxReg, False)
        if (op2&bitMaskHalf):
            self.registers.regWrite(edxReg, bitMask)
        else:
            self.registers.regWrite(edxReg, 0)
    cdef shlFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char newCF, newOF
        cdef unsigned long bitMask, bitMaskHalf, dest
        bitMask = self.main.misc.getBitMaskFF(operSize)
        bitMaskHalf = self.main.misc.getBitMask80(operSize)
        dest = self.registers.modRMLoad(rmOperands, operSize, False, True)
        count = count&0x1f
        if (count == 0):
            newCF = False
        else:
            newCF = ((dest<<(count-1))&bitMaskHalf)!=0
        dest <<= count
        dest &= bitMask
        self.registers.modRMSave(rmOperands, operSize, dest, True, VALUEOP_SAVE)
        if (count == 0):
            return
        elif (count == 1):
            newOF = ( ((dest&bitMaskHalf)!=0)^newCF )
            self.registers.setEFLAG( FLAG_OF, newOF )
        else:
            self.registers.setEFLAG( FLAG_OF, False )
        self.registers.setEFLAG( FLAG_CF, newCF )
        self.registers.setSZP(dest, operSize)
        
    
    
    
    cdef sarFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char newCF
        cdef unsigned long bitMask
        cdef long long dest
        bitMask = self.main.misc.getBitMaskFF(operSize)
        dest = self.registers.modRMLoad(rmOperands, operSize, True, True)
        count = count&0x1f
        if (count == 0):
            newCF = ((dest)&1)
        else:
            newCF = ((dest>>(count-1))&1)
        dest >>= count
        dest &= bitMask
        self.registers.modRMSave(rmOperands, operSize, dest, True, VALUEOP_SAVE)
        if (count == 0):
            return
        elif (count == 1):
            self.registers.setEFLAG( FLAG_OF, False )
        self.registers.setEFLAG( FLAG_CF, newCF )
        self.registers.setSZP(dest, operSize)
        
    
    
    
    cdef shrFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char newCF_OF
        cdef unsigned long bitMask, bitMaskHalf, dest, tempDest
        bitMask = self.main.misc.getBitMaskFF(operSize)
        bitMaskHalf = self.main.misc.getBitMask80(operSize)
        dest = self.registers.modRMLoad(rmOperands, operSize, False, True)
        tempDest = dest
        count = count&0x1f
        if (count == 0):
            newCF_OF = ((dest)&1)
        else:
            newCF_OF = ((dest>>(count-1))&1)
        dest >>= count
        self.registers.modRMSave(rmOperands, operSize, dest, True, VALUEOP_SAVE)
        if (count == 0):
            return
        self.registers.setEFLAG( FLAG_CF, newCF_OF )
        newCF_OF = ((tempDest)&bitMaskHalf)!=0
        self.registers.setEFLAG( FLAG_OF, newCF_OF )
        self.registers.setSZP(dest, operSize)
        
    
    
    
    cdef rclFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char tempCF_OF, newCF
        cdef unsigned long bitMask, bitMaskHalf, dest
        bitMask = self.main.misc.getBitMaskFF(operSize)
        bitMaskHalf = self.main.misc.getBitMask80(operSize)
        dest = self.registers.modRMLoad(rmOperands, operSize, False, True)
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
        self.registers.modRMSave(rmOperands, operSize, dest, True, VALUEOP_SAVE)
        if (count == 0):
            return
        tempCF_OF = ( ((dest&bitMaskHalf)!=0)^newCF )
        self.registers.setEFLAG( FLAG_OF, tempCF_OF )
        self.registers.setEFLAG( FLAG_CF, newCF )
        
    
    
    
    
    
    
    cdef rcrFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char tempCF_OF, newCF
        cdef unsigned long bitMask, bitMaskHalf, dest
        bitMask = self.main.misc.getBitMaskFF(operSize)
        bitMaskHalf = self.main.misc.getBitMask80(operSize)
        dest = self.registers.modRMLoad(rmOperands, operSize, False, True)
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
        
        self.registers.modRMSave(rmOperands, operSize, dest, True, VALUEOP_SAVE)
        self.registers.setEFLAG( FLAG_CF, newCF )
    
    
    
    
    cdef rolFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char tempCF_OF, newCF
        cdef unsigned long bitMask, bitMaskHalf, dest
        bitMask = self.main.misc.getBitMaskFF(operSize)
        bitMaskHalf = self.main.misc.getBitMask80(operSize)
        dest = self.registers.modRMLoad(rmOperands, operSize, False, True)
        
        if ((count & 0x1f) > 0):
            count = count%(operSize<<3)
            
            for i in range(count):
                tempCF_OF = (dest&bitMaskHalf)!=0
                dest = (dest << 1) | tempCF_OF
            
            self.registers.modRMSave(rmOperands, operSize, dest, True, VALUEOP_SAVE)
            
            if (count == 0):
                return
            newCF = dest&1
            self.registers.setEFLAG( FLAG_CF, newCF )
            tempCF_OF = ( ((dest&bitMaskHalf)!=0)^newCF )
            self.registers.setEFLAG( FLAG_OF, tempCF_OF )
            
    
    
    
    
    cdef rorFunc(self, tuple rmOperands, unsigned char operSize, unsigned long count):
        cdef unsigned char tempCF_OF, newCF_M1
        cdef unsigned long bigMask, bitMaskHalf, dest, destM1
        bitMask = self.main.misc.getBitMaskFF(operSize)
        bitMaskHalf = self.main.misc.getBitMask80(operSize)
        dest = self.registers.modRMLoad(rmOperands, operSize, False, True)
        destM1 = dest
        
        if ((count & 0x1f) > 0):
            count = count%(operSize<<3)
            
            for i in range(count):
                destM1 = dest
                tempCF_OF = destM1&1
                dest = (destM1 >> 1) | (tempCF_OF * bitMaskHalf)
            
            self.registers.modRMSave(rmOperands, operSize, dest, True, VALUEOP_SAVE)
            
            if (count == 0):
                return
            tempCF_OF = (dest&bitMaskHalf)!=0
            newCF_M1 = (destM1&bitMaskHalf)!=0
            self.registers.setEFLAG( FLAG_CF, tempCF_OF )
            tempCF_OF = ( tempCF_OF ^ newCF_M1 )
            self.registers.setEFLAG( FLAG_OF, tempCF_OF )
            
    
    
    
    
    
    
    cdef opcodeGroup4_RM_1(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId
        cdef tuple rmOperands
        operOpcode = self.cpu.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
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
            self.main.printMsg("opcodeGroup4_RM_1: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroup4_RM_CL(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId, count
        cdef tuple rmOperands
        operOpcode = self.cpu.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        count = self.registers.regRead(CPU_REGISTER_CL, False)
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
            self.main.printMsg("opcodeGroup4_RM_CL: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroup4_RM_IMM8(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId, count
        cdef tuple rmOperands
        operOpcode = self.cpu.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        count = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
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
            self.main.printMsg("opcodeGroup4_RM_IMM8: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise misc.ChemuException(CPU_EXCEPTION_UD)
    cdef sahf(self):
        cdef unsigned char ahVal, orThis
        ahVal = self.registers.regRead( CPU_REGISTER_AH, False )
        self.registers.clearThisEFLAGS( FLAG_CF | FLAG_PF | \
            FLAG_AF | FLAG_ZF | FLAG_SF )
        orThis = 0x2
        orThis |= ahVal & FLAG_CF
        orThis |= ahVal & FLAG_PF
        orThis |= ahVal & FLAG_AF
        orThis |= ahVal & FLAG_ZF
        orThis |= ahVal & FLAG_SF
        self.registers.regOr( CPU_REGISTER_FLAGS, orThis )
    cdef lahf(self):
        cdef unsigned char newAH, flagsByte
        newAH = 0x2
        flagsByte = self.registers.regRead( CPU_REGISTER_FLAGS, False )&0xff
        newAH |= flagsByte & FLAG_CF
        newAH |= flagsByte & FLAG_PF
        newAH |= flagsByte & FLAG_AF
        newAH |= flagsByte & FLAG_ZF
        newAH |= flagsByte & FLAG_SF
        self.registers.regWrite( CPU_REGISTER_AH, newAH )
    cdef xchgFuncReg(self, unsigned short regName, unsigned short regName2):
        cdef unsigned long regValue, regValue2
        regValue, regValue2 = self.registers.regRead( regName, False ), self.registers.regRead( regName2, False )
        self.registers.regWrite( regName, regValue2 )
        self.registers.regWrite( regName2, regValue )
    ##### both, XCHG AX, AX == NOP is opcode 0x90, so don't use this (xchg) for it (opcode 0x90)
    cdef xchgReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName, regName2
        operSize  = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        regName   = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        regName2  = self.registers.getWordAsDword(CPU_REGISTER_WORD[self.cpu.opcode&7], operSize)
        self.xchgFuncReg(regName, regName2)
    cdef xchgR_RM(self, unsigned char operSize):
        cdef unsigned long op1, op2
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRLoad(rmOperands, operSize, False)
        op2 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        self.registers.modRMSave(rmOperands, operSize, op1, True, VALUEOP_SAVE)
        self.registers.modRSave(rmOperands, operSize, op2, VALUEOP_SAVE)
    cdef enter(self):
        cdef unsigned char operSize, stackSize, nestingLevel
        cdef unsigned short sizeOp, espNameStack, ebpNameStack
        cdef unsigned long frameTemp, temp
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        stackSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_SS)
        espNameStack = self.registers.getWordAsDword(CPU_REGISTER_SP, stackSize)
        ebpNameStack = self.registers.getWordAsDword(CPU_REGISTER_BP, stackSize)
        sizeOp = self.cpu.getCurrentOpcodeAdd(OP_SIZE_WORD, False)
        nestingLevel = self.cpu.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        nestingLevel %= 32
        self.stackPushRegId(ebpNameStack, stackSize)
        frameTemp = self.registers.regRead(espNameStack, False)
        if (nestingLevel > 1):
            for i in range(nestingLevel-1):
                self.registers.regSub(ebpNameStack, operSize)
                temp = self.main.mm.mmReadValue(self.registers.regRead(ebpNameStack, False), operSize, CPU_SEGMENT_SS, False, False)
                self.stackPushValue(temp, operSize)
        if (nestingLevel >= 1):
            self.stackPushValue(frameTemp, operSize)
        self.registers.regWrite(ebpNameStack, frameTemp)
        self.registers.regSub(espNameStack, sizeOp)
    cdef leave(self):
        cdef unsigned char operSize, stackSize
        cdef unsigned short ebpNameOper, espNameStack, ebpNameStack
        operSize = self.registers.segments.getOpSegSize(CPU_SEGMENT_CS)
        stackSize = self.registers.segments.getAddrSegSize(CPU_SEGMENT_SS)
        ebpNameOper = self.registers.getWordAsDword(CPU_REGISTER_BP, operSize)
        espNameStack = self.registers.getWordAsDword(CPU_REGISTER_SP, stackSize)
        ebpNameStack = self.registers.getWordAsDword(CPU_REGISTER_BP, stackSize)
        self.registers.regWrite(espNameStack, self.registers.regRead(ebpNameStack, False) )
        self.stackPopRegId( ebpNameOper, operSize )
    cdef cmovFunc(self, unsigned char operSize, unsigned char cond): # R16, R/M 16; R32, R/M 32
        self.movR_RM(operSize, cond)
    cdef setWithCondFunc(self, unsigned char cond): # if cond==True set 1, else 0
        cdef tuple rmOperands
        rmOperands = self.registers.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
        self.registers.modRMSave(rmOperands, OP_SIZE_BYTE, cond!=0, True, VALUEOP_SAVE)
    cdef arpl(self):
        cdef unsigned char operSize
        cdef unsigned short op1, op2
        cdef tuple rmOperands
        if (not self.cpu.isInProtectedMode()):
            raise misc.ChemuException(CPU_EXCEPTION_UD)
        operSize = OP_SIZE_WORD
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.registers.modRMLoad(rmOperands, operSize, False, True)
        op2 = self.registers.modRLoad(rmOperands, operSize, False)
        if (op1 < op2):
            self.registers.setEFLAG( FLAG_ZF, True )
            self.registers.modRMSave(rmOperands, operSize, (op1&0xfffc)|(op2&3), True, VALUEOP_SAVE )
        else:
            self.registers.setEFLAG( FLAG_ZF, False )
    cdef bound(self):
        cdef unsigned char operSize, addrSize
        cdef unsigned long returnInt
        cdef long index, lowerBound, upperBound
        cdef tuple rmOperands, rmValue
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        rmOperands = self.registers.modRMOperands(operSize, MODRM_FLAGS_NONE)
        rmValue = rmOperands[1]
        index = self.registers.modRLoad(rmOperands, operSize, True)
        returnInt = self.getRMValueFull(rmValue[0], addrSize)
        lowerBound = self.main.mm.mmReadValue(returnInt, operSize, rmValue[1], True, True)
        upperBound = self.main.mm.mmReadValue(returnInt+operSize, operSize, rmValue[1], True, True)
        if (index < lowerBound or index > upperBound+operSize):
            raise misc.ChemuException(CPU_EXCEPTION_BR)
    cdef btFunc(self, tuple rmOperands, unsigned long offset, unsigned char newValType):
        cdef unsigned char operSize, addrSize, operSizeInBits, state
        cdef unsigned long value, address
        operSize, addrSize = self.registers.segments.getOpAddrSegSize(CPU_SEGMENT_CS)
        operSizeInBits = operSize << 3
        address = 0
        if (rmOperands[0] == 3): # register operand
            offset %= operSizeInBits
            value = self.registers.modRLoad(rmOperands, operSize, False)
            state = self.registers.valGetBit(value, offset)
            self.registers.setEFLAG( FLAG_CF, state )
        else: # memory operand
            address = self.registers.getRMValueFull(rmOperands[1][0], addrSize)
            address += (operSize * (offset // operSizeInBits))
            value = self.main.mm.mmReadValue(address, operSize, rmOperands[1][1], False, True)
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
                self.registers.modRSave(rmOperands, operSize, value, VALUEOP_SAVE)
            else: # memory operands
                self.main.mm.mmWriteValue(address, value, operSize, rmOperands[1][1], True)
    cdef btcFunc(self, tuple rmOperands, unsigned long offset):
        self.btFunc(rmOperands, offset, BT_NOT)
    cdef btrFunc(self, tuple rmOperands, unsigned long offset):
        self.btFunc(rmOperands, offset, BT_CLEAR)
    cdef btsFunc(self, tuple rmOperands, unsigned long offset):
        self.btFunc(rmOperands, offset, BT_SET)
    # end of opcodes



