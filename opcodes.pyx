
from misc import ChemuException

include "globals.pxi"
include "cpu_globals.pxi"


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

DEF GROUP4_1 = 1
DEF GROUP4_CL = 2
DEF GROUP4_IMM8 = 3


DEF OPCODE_LOOP = 1
DEF OPCODE_LOOPE = 2
DEF OPCODE_LOOPNE = 3


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


DEF BT_NONE = 0
DEF BT_COMPLEMENT = 1
DEF BT_RESET = 2
DEF BT_SET = 3



cdef class Opcodes:
    def __init__(self, object main):
        self.main = main
    cdef int executeOpcode(self, unsigned char opcode):
        cdef int retVal = False
        if (opcode == 0x00):
            retVal = self.opcodeRM_R(OPCODE_ADD, OP_SIZE_BYTE)
        elif (opcode == 0x01):
            retVal = self.opcodeRM_R(OPCODE_ADD, self.registers.operSize)
        elif (opcode == 0x02):
            retVal = self.opcodeR_RM(OPCODE_ADD, OP_SIZE_BYTE)
        elif (opcode == 0x03):
            retVal = self.opcodeR_RM(OPCODE_ADD, self.registers.operSize)
        elif (opcode == 0x04):
            retVal = self.opcodeAxEaxImm(OPCODE_ADD, OP_SIZE_BYTE)
        elif (opcode == 0x05):
            retVal = self.opcodeAxEaxImm(OPCODE_ADD, self.registers.operSize)
        elif (opcode == 0x06):
            retVal = self.pushSeg(PUSH_ES)
        elif (opcode == 0x07):
            retVal = self.popSeg(POP_ES)
        elif (opcode == 0x08):
            retVal = self.opcodeRM_R(OPCODE_OR, OP_SIZE_BYTE)
        elif (opcode == 0x09):
            retVal = self.opcodeRM_R(OPCODE_OR, self.registers.operSize)
        elif (opcode == 0x0a):
            retVal = self.opcodeR_RM(OPCODE_OR, OP_SIZE_BYTE)
        elif (opcode == 0x0b):
            retVal = self.opcodeR_RM(OPCODE_OR, self.registers.operSize)
        elif (opcode == 0x0c):
            retVal = self.opcodeAxEaxImm(OPCODE_OR, OP_SIZE_BYTE)
        elif (opcode == 0x0d):
            retVal = self.opcodeAxEaxImm(OPCODE_OR, self.registers.operSize)
        elif (opcode == 0x0e):
            retVal = self.pushSeg(PUSH_CS)
        elif (opcode == 0x0f):
            retVal = self.opcodeGroup0F()
        elif (opcode == 0x10):
            retVal = self.opcodeRM_R(OPCODE_ADC, OP_SIZE_BYTE)
        elif (opcode == 0x11):
            retVal = self.opcodeRM_R(OPCODE_ADC, self.registers.operSize)
        elif (opcode == 0x12):
            retVal = self.opcodeR_RM(OPCODE_ADC, OP_SIZE_BYTE)
        elif (opcode == 0x13):
            retVal = self.opcodeR_RM(OPCODE_ADC, self.registers.operSize)
        elif (opcode == 0x14):
            retVal = self.opcodeAxEaxImm(OPCODE_ADC, OP_SIZE_BYTE)
        elif (opcode == 0x15):
            retVal = self.opcodeAxEaxImm(OPCODE_ADC, self.registers.operSize)
        elif (opcode == 0x16):
            retVal = self.pushSeg(PUSH_SS)
        elif (opcode == 0x17):
            retVal = self.popSeg(POP_SS)
        elif (opcode == 0x18):
            retVal = self.opcodeRM_R(OPCODE_SBB, OP_SIZE_BYTE)
        elif (opcode == 0x19):
            retVal = self.opcodeRM_R(OPCODE_SBB, self.registers.operSize)
        elif (opcode == 0x1a):
            retVal = self.opcodeR_RM(OPCODE_SBB, OP_SIZE_BYTE)
        elif (opcode == 0x1b):
            retVal = self.opcodeR_RM(OPCODE_SBB, self.registers.operSize)
        elif (opcode == 0x1c):
            retVal = self.opcodeAxEaxImm(OPCODE_SBB, OP_SIZE_BYTE)
        elif (opcode == 0x1d):
            retVal = self.opcodeAxEaxImm(OPCODE_SBB, self.registers.operSize)
        elif (opcode == 0x1e):
            retVal = self.pushSeg(PUSH_DS)
        elif (opcode == 0x1f):
            retVal = self.popSeg(POP_DS)
        elif (opcode == 0x20):
            retVal = self.opcodeRM_R(OPCODE_AND, OP_SIZE_BYTE)
        elif (opcode == 0x21):
            retVal = self.opcodeRM_R(OPCODE_AND, self.registers.operSize)
        elif (opcode == 0x22):
            retVal = self.opcodeR_RM(OPCODE_AND, OP_SIZE_BYTE)
        elif (opcode == 0x23):
            retVal = self.opcodeR_RM(OPCODE_AND, self.registers.operSize)
        elif (opcode == 0x24):
            retVal = self.opcodeAxEaxImm(OPCODE_AND, OP_SIZE_BYTE)
        elif (opcode == 0x25):
            retVal = self.opcodeAxEaxImm(OPCODE_AND, self.registers.operSize)
        elif (opcode == 0x27):
            retVal = self.daa()
        elif (opcode == 0x28):
            retVal = self.opcodeRM_R(OPCODE_SUB, OP_SIZE_BYTE)
        elif (opcode == 0x29):
            retVal = self.opcodeRM_R(OPCODE_SUB, self.registers.operSize)
        elif (opcode == 0x2a):
            retVal = self.opcodeR_RM(OPCODE_SUB, OP_SIZE_BYTE)
        elif (opcode == 0x2b):
            retVal = self.opcodeR_RM(OPCODE_SUB, self.registers.operSize)
        elif (opcode == 0x2c):
            retVal = self.opcodeAxEaxImm(OPCODE_SUB, OP_SIZE_BYTE)
        elif (opcode == 0x2d):
            retVal = self.opcodeAxEaxImm(OPCODE_SUB, self.registers.operSize)
        elif (opcode == 0x2f):
            retVal = self.das()
        elif (opcode == 0x30):
            retVal = self.opcodeRM_R(OPCODE_XOR, OP_SIZE_BYTE)
        elif (opcode == 0x31):
            retVal = self.opcodeRM_R(OPCODE_XOR, self.registers.operSize)
        elif (opcode == 0x32):
            retVal = self.opcodeR_RM(OPCODE_XOR, OP_SIZE_BYTE)
        elif (opcode == 0x33):
            retVal = self.opcodeR_RM(OPCODE_XOR, self.registers.operSize)
        elif (opcode == 0x34):
            retVal = self.opcodeAxEaxImm(OPCODE_XOR, OP_SIZE_BYTE)
        elif (opcode == 0x35):
            retVal = self.opcodeAxEaxImm(OPCODE_XOR, self.registers.operSize)
        elif (opcode == 0x37):
            retVal = self.aaa()
        elif (opcode == 0x38):
            retVal = self.opcodeRM_R(OPCODE_CMP, OP_SIZE_BYTE)
        elif (opcode == 0x39):
            retVal = self.opcodeRM_R(OPCODE_CMP, self.registers.operSize)
        elif (opcode == 0x3a):
            retVal = self.opcodeR_RM(OPCODE_CMP, OP_SIZE_BYTE)
        elif (opcode == 0x3b):
            retVal = self.opcodeR_RM(OPCODE_CMP, self.registers.operSize)
        elif (opcode == 0x3c):
            retVal = self.opcodeAxEaxImm(OPCODE_CMP, OP_SIZE_BYTE)
        elif (opcode == 0x3d):
            retVal = self.opcodeAxEaxImm(OPCODE_CMP, self.registers.operSize)
        elif (opcode == 0x3f):
            retVal = self.aas()
        elif (opcode >= 0x40 and opcode <= 0x47):
            retVal = self.incReg()
        elif (opcode >= 0x48 and opcode <= 0x4f):
            retVal = self.decReg()
        elif (opcode >= 0x50 and opcode <= 0x57):
            retVal = self.pushReg()
        elif (opcode >= 0x58 and opcode <= 0x5f):
            retVal = self.popReg()
        elif (opcode == 0x60):
            retVal = self.pushaWD()
        elif (opcode == 0x61):
            retVal = self.popaWD()
        elif (opcode == 0x62):
            retVal = self.bound()
        elif (opcode == 0x63):
            retVal = self.arpl()
        elif (opcode == 0x68):
            retVal = self.pushIMM(False)
        elif (opcode == 0x69):
            retVal = self.imulR_RM_ImmFunc(False)
        elif (opcode == 0x6a):
            retVal = self.pushIMM(True)
        elif (opcode == 0x6b):
            retVal = self.imulR_RM_ImmFunc(True)
        elif (opcode == 0x6c):
            retVal = self.insFunc(OP_SIZE_BYTE)
        elif (opcode == 0x6d):
            retVal = self.insFunc(self.registers.operSize)
        elif (opcode == 0x6e):
            retVal = self.outsFunc(OP_SIZE_BYTE)
        elif (opcode == 0x6f):
            retVal = self.outsFunc(self.registers.operSize)
        elif (opcode >= 0x70 and opcode <= 0x7f):
            retVal = self.jumpShort(OP_SIZE_BYTE, self.registers.getCond(opcode&0xf))
        elif (opcode == 0x80):
            retVal = self.opcodeGroup1_RM_ImmFunc(OP_SIZE_BYTE, True)
        elif (opcode == 0x81):
            retVal = self.opcodeGroup1_RM_ImmFunc(self.registers.operSize, False)
        elif (opcode == 0x83):
            retVal = self.opcodeGroup1_RM_ImmFunc(self.registers.operSize, True)
        elif (opcode == 0x84):
            retVal = self.opcodeRM_R(OPCODE_TEST, OP_SIZE_BYTE)
        elif (opcode == 0x85):
            retVal = self.opcodeRM_R(OPCODE_TEST, self.registers.operSize)
        elif (opcode == 0x86):
            retVal = self.xchgR_RM(OP_SIZE_BYTE)
        elif (opcode == 0x87):
            retVal = self.xchgR_RM(self.registers.operSize)
        elif (opcode == 0x88):
            retVal = self.movRM_R(OP_SIZE_BYTE)
        elif (opcode == 0x89):
            retVal = self.movRM_R(self.registers.operSize)
        elif (opcode == 0x8a):
            retVal = self.movR_RM(OP_SIZE_BYTE, True)
        elif (opcode == 0x8b):
            retVal = self.movR_RM(self.registers.operSize, True)
        elif (opcode == 0x8c):
            retVal = self.movRM16_SREG()
        elif (opcode == 0x8d):
            retVal = self.lea()
        elif (opcode == 0x8e):
            retVal = self.movSREG_RM16()
        elif (opcode == 0x8f):
            retVal = self.popRM16_32()
        elif (opcode == 0x90):
            pass # TODO: maybe implement PAUSE-Opcode (F3 90 / REPE NOP)
            retVal = True
        elif (opcode >= 0x91 and opcode <= 0x97):
            retVal = self.xchgReg()
        elif (opcode == 0x98):
            retVal = self.cbw_cwde()
        elif (opcode == 0x99):
            retVal = self.cwd_cdq()
        elif (opcode == 0x9a):
            retVal = self.callPtr16_32()
        elif (opcode == 0x9b): # WAIT/FWAIT
            if (self.registers.getFlagDword(CPU_REGISTER_CR0, (CR0_FLAG_MP | \
              CR0_FLAG_TS)) ==  (CR0_FLAG_MP | CR0_FLAG_TS)):
                raise ChemuException(CPU_EXCEPTION_NM)
            raise ChemuException(CPU_EXCEPTION_UD)
        elif (opcode == 0x9c):
            retVal = self.pushfWD()
        elif (opcode == 0x9d):
            retVal = self.popfWD()
        elif (opcode == 0x9e):
            retVal = self.sahf()
        elif (opcode == 0x9f):
            retVal = self.lahf()
        elif (opcode >= 0xa0 and opcode <= 0xa3):
            if (opcode == 0xa0):
                retVal = self.movAxMoffs(OP_SIZE_BYTE)
            elif (opcode == 0xa1):
                retVal = self.movAxMoffs(self.registers.operSize)
            elif (opcode == 0xa2):
                retVal = self.movMoffsAx(OP_SIZE_BYTE)
            elif (opcode == 0xa3):
                retVal = self.movMoffsAx(self.registers.operSize)
        elif (opcode == 0xa4):
            retVal = self.movsFunc(OP_SIZE_BYTE)
        elif (opcode == 0xa5):
            retVal = self.movsFunc(self.registers.operSize)
        elif (opcode == 0xa6):
            retVal = self.cmpsFunc(OP_SIZE_BYTE)
        elif (opcode == 0xa7):
            retVal = self.cmpsFunc(self.registers.operSize)
        elif (opcode == 0xa8):
            retVal = self.opcodeAxEaxImm(OPCODE_TEST, OP_SIZE_BYTE)
        elif (opcode == 0xa9):
            retVal = self.opcodeAxEaxImm(OPCODE_TEST, self.registers.operSize)
        elif (opcode == 0xaa):
            retVal = self.stosFunc(OP_SIZE_BYTE)
        elif (opcode == 0xab):
            retVal = self.stosFunc(self.registers.operSize)
        elif (opcode == 0xac):
            retVal = self.lodsFunc(OP_SIZE_BYTE)
        elif (opcode == 0xad):
            retVal = self.lodsFunc(self.registers.operSize)
        elif (opcode == 0xae):
            retVal = self.scasFunc(OP_SIZE_BYTE)
        elif (opcode == 0xaf):
            retVal = self.scasFunc(self.registers.operSize)
        elif (opcode >= 0xb0 and opcode <= 0xb7):
            retVal = self.movImmToR(OP_SIZE_BYTE)
        elif (opcode >= 0xb8 and opcode <= 0xbf):
            retVal = self.movImmToR(self.registers.operSize)
        elif (opcode == 0xc0):
            retVal = self.opcodeGroup4_RM(OP_SIZE_BYTE, GROUP4_IMM8)
        elif (opcode == 0xc1):
            retVal = self.opcodeGroup4_RM(self.registers.operSize, GROUP4_IMM8)
        elif (opcode == 0xc2):
            retVal = self.retNearImm()
        elif (opcode == 0xc3):
            retVal = self.retNear(0)
        elif (opcode == 0xc4):
            retVal = self.lfpFunc(CPU_SEGMENT_ES) # LES
        elif (opcode == 0xc5):
            retVal = self.lfpFunc(CPU_SEGMENT_DS) # LDS
        elif (opcode == 0xc6):
            retVal = self.opcodeGroup3_RM_ImmFunc(OP_SIZE_BYTE)
        elif (opcode == 0xc7):
            retVal = self.opcodeGroup3_RM_ImmFunc(self.registers.operSize)
        elif (opcode == 0xc8):
            retVal = self.enter()
        elif (opcode == 0xc9):
            retVal = self.leave()
        elif (opcode == 0xca):
            retVal = self.retFarImm()
        elif (opcode == 0xcb):
            retVal = self.retFar(0)
        elif (opcode == 0xcc):
            retVal = self.int3()
        elif (opcode == 0xcd):
            retVal = self.interrupt(-1, -1)
        elif (opcode == 0xce):
            retVal = self.into()
        elif (opcode == 0xcf):
            retVal = self.iret()
        elif (opcode == 0xd0):
            retVal = self.opcodeGroup4_RM(OP_SIZE_BYTE, GROUP4_1)
        elif (opcode == 0xd1):
            retVal = self.opcodeGroup4_RM(self.registers.operSize, GROUP4_1)
        elif (opcode == 0xd2):
            retVal = self.opcodeGroup4_RM(OP_SIZE_BYTE, GROUP4_CL)
        elif (opcode == 0xd3):
            retVal = self.opcodeGroup4_RM(self.registers.operSize, GROUP4_CL)
        elif (opcode == 0xd4):
            retVal = self.aam()
        elif (opcode == 0xd5):
            retVal = self.aad()
        elif (opcode == 0xd6):
            pass ### undefNoUD
            retVal = True
        elif (opcode == 0xd7):
            retVal = self.xlatb()
        elif (opcode >= 0xd8 and opcode <= 0xdf):
            if (self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_OSFXSR) == 0):
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (self.registers.getFlagDword(CPU_REGISTER_CR0, (CR0_FLAG_EM | CR0_FLAG_TS)) != 0):
                raise ChemuException(CPU_EXCEPTION_NM)
            raise ChemuException(CPU_EXCEPTION_UD)
        elif (opcode == 0xe0):
            retVal = self.loopFunc(OPCODE_LOOPNE)
        elif (opcode == 0xe1):
            retVal = self.loopFunc(OPCODE_LOOPE)
        elif (opcode == 0xe2):
            retVal = self.loopFunc(OPCODE_LOOP)
        elif (opcode == 0xe3):
            retVal = self.jcxzShort()
        elif (opcode == 0xe4):
            retVal = self.inAxImm8(OP_SIZE_BYTE)
        elif (opcode == 0xe5):
            retVal = self.inAxImm8(self.registers.operSize)
        elif (opcode == 0xe6):
            retVal = self.outImm8Ax(OP_SIZE_BYTE)
        elif (opcode == 0xe7):
            retVal = self.outImm8Ax(self.registers.operSize)
        elif (opcode == 0xe8):
            retVal = self.callNearRel16_32()
        elif (opcode == 0xe9):
            retVal = self.jumpShort(self.registers.operSize, True)
        elif (opcode == 0xea):
            retVal = self.jumpFarAbsolutePtr()
        elif (opcode == 0xeb):
            retVal = self.jumpShort(OP_SIZE_BYTE, True)
        elif (opcode == 0xec):
            retVal = self.inAxDx(OP_SIZE_BYTE)
        elif (opcode == 0xed):
            retVal = self.inAxDx(self.registers.operSize)
        elif (opcode == 0xee):
            retVal = self.outDxAx(OP_SIZE_BYTE)
        elif (opcode == 0xef):
            retVal = self.outDxAx(self.registers.operSize)
        elif (opcode == 0xf1):
            pass ### undefNoUD
            retVal = True
        elif (opcode == 0xf4):
            self.hlt()
            retVal = True
        elif (opcode == 0xf5):
            self.cmc()
            retVal = True
        elif (opcode == 0xf6):
            retVal = self.opcodeGroup2_RM(OP_SIZE_BYTE)
        elif (opcode == 0xf7):
            retVal = self.opcodeGroup2_RM(self.registers.operSize)
        elif (opcode == 0xf8):
            self.clc()
            retVal = True
        elif (opcode == 0xf9):
            self.stc()
            retVal = True
        elif (opcode == 0xfa):
            self.cli()
            retVal = True
        elif (opcode == 0xfb):
            self.sti()
            retVal = True
        elif (opcode == 0xfc):
            self.cld()
            retVal = True
        elif (opcode == 0xfd):
            self.std()
            retVal = True
        elif (opcode == 0xfe):
            retVal = self.opcodeGroupFE()
        elif (opcode == 0xff):
            retVal = self.opcodeGroupFF()
        else:
            self.main.notice("handler for opcode {0:#06x} wasn't found.", opcode)
            raise ChemuException(CPU_EXCEPTION_UD) # if opcode wasn't found.
        return retVal
    cdef long int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if ((<Segments>self.registers.segments).isInProtectedMode()):
            if (self.registers.getCPL() > self.registers.getIOPL()):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
        return self.main.platform.inPort(ioPortAddr, dataSize)
    cdef int outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if ((<Segments>self.registers.segments).isInProtectedMode()):
            if (self.registers.getCPL() > self.registers.getIOPL()):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
        self.main.platform.outPort(ioPortAddr, data, dataSize)
    cdef int jumpFarDirect(self, unsigned char method, unsigned short segVal, unsigned int eipVal):
        cdef unsigned char segType
        cdef GdtEntry gdtEntry
        self.syncCR0State()
        if ((<Segments>self.registers.segments).isInProtectedMode()):
            gdtEntry = (<GdtEntry>(<Gdt>self.registers.segments.gdt).getEntry(segVal))
            if (not gdtEntry or not gdtEntry.segPresent):
                raise ChemuException(CPU_EXCEPTION_NP, segVal)
            segType = (gdtEntry.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK)
            if (not (segType & GDT_ACCESS_NORMAL_SEGMENT) and (segType != TABLE_ENTRY_SYSTEM_TYPE_LDT)):
                self.main.exitError("Opcodes::jumpFarDirect: sysSegType {0:d} isn't supported yet.", segType)
                return True
        if (method == OPCODE_CALL):
            self.stackPushSegId(CPU_SEGMENT_CS, self.registers.operSize)
            self.stackPushRegId(CPU_REGISTER_EIP, self.registers.operSize)
        self.registers.segWrite(CPU_SEGMENT_CS, segVal)
        self.registers.regWriteDword(CPU_REGISTER_EIP, eipVal)
        return True
    cdef int jumpFarAbsolutePtr(self):
        cdef unsigned short cs
        cdef unsigned int eip
        eip = self.registers.getCurrentOpcodeAddUnsigned(self.registers.operSize)
        cs = self.registers.getCurrentOpcodeAddUnsignedWord()
        return self.jumpFarDirect(OPCODE_JUMP, cs, eip)
    cdef int loopFunc(self, unsigned char loopType):
        cdef unsigned char oldZF
        cdef unsigned int countOrNewEip
        cdef signed char rel8
        oldZF = self.registers.getEFLAG(FLAG_ZF)!=0
        rel8 = self.registers.getCurrentOpcodeAddSignedByte()
        if (not self.registers.regSub(CPU_REGISTER_CX, 1, self.registers.addrSize)):
            return True
        elif (loopType == OPCODE_LOOPE and not oldZF):
            return True
        elif (loopType == OPCODE_LOOPNE and oldZF):
            return True
        countOrNewEip = <unsigned int>(self.registers.regReadUnsignedDword(CPU_REGISTER_EIP)+rel8)
        if (self.registers.operSize == OP_SIZE_WORD):
            countOrNewEip = <unsigned short>countOrNewEip
        self.registers.regWriteDword(CPU_REGISTER_EIP, countOrNewEip)
        return True
    cdef int opcodeR_RM(self, unsigned char opcode, unsigned char operSize):
        cdef unsigned int op1, op2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (opcode not in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op1 = self.modRMInstance.modRLoadUnsigned(operSize)
        op2 = self.modRMInstance.modRMLoadUnsigned(operSize, True)
        if (opcode in (OPCODE_ADD, OPCODE_ADC, OPCODE_SUB, OPCODE_SBB)):
            self.modRMInstance.modRSave(operSize, op2, opcode)
            self.registers.setFullFlags(op1, op2, operSize, opcode)
        elif (opcode == OPCODE_CMP):
            self.registers.setFullFlags(op1, op2, operSize, OPCODE_SUB)
        elif (opcode in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op2 = self.modRMInstance.modRSave(operSize, op2, opcode)
            self.registers.setSZP_C0_O0_A0(op2, operSize)
        elif (opcode == OPCODE_TEST):
            self.main.exitError("OPCODE::opcodeR_RM: OPCODE_TEST HAS NO R_RM!!")
        else:
            self.main.exitError("OPCODE::opcodeR_RM: invalid opcode: {0:d}.", opcode)
        return True
    cdef int opcodeRM_R(self, unsigned char opcode, unsigned char operSize):
        cdef unsigned int op1, op2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (opcode not in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op1 = self.modRMInstance.modRMLoadUnsigned(operSize, True)
        op2 = self.modRMInstance.modRLoadUnsigned(operSize)
        if (opcode in (OPCODE_ADD, OPCODE_ADC, OPCODE_SUB, OPCODE_SBB)):
            self.modRMInstance.modRMSave(operSize, op2, True, opcode)
            self.registers.setFullFlags(op1, op2, operSize, opcode)
        elif (opcode == OPCODE_CMP):
            self.registers.setFullFlags(op1, op2, operSize, OPCODE_SUB)
        elif (opcode in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op2 = self.modRMInstance.modRMSave(operSize, op2, True, opcode)
            self.registers.setSZP_C0_O0_A0(op2, operSize)
        elif (opcode == OPCODE_TEST):
            self.registers.setSZP_C0_O0_A0(op1&op2, operSize)
        else:
            self.main.notice("OPCODE::opcodeRM_R: invalid opcode: {0:d}.", opcode)
        return True
    cdef int opcodeAxEaxImm(self, unsigned char opcode, unsigned char operSize):
        cdef unsigned int op1, op2
        if (opcode not in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            if (operSize == OP_SIZE_BYTE):
                op1 = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
            elif (operSize == OP_SIZE_WORD):
                op1 = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
            elif (operSize == OP_SIZE_DWORD):
                op1 = self.registers.regReadUnsignedDword(CPU_REGISTER_EAX)
        op2 = self.registers.getCurrentOpcodeAddUnsigned(operSize)
        if (opcode in (OPCODE_ADD, OPCODE_ADC, OPCODE_SUB, OPCODE_SBB)):
            if (operSize == OP_SIZE_BYTE):
                self.registers.regWriteWithOpLowByte(CPU_REGISTER_AL, op2, opcode)
            elif (operSize == OP_SIZE_WORD):
                self.registers.regWriteWithOpWord(CPU_REGISTER_AX, op2, opcode)
            elif (operSize == OP_SIZE_DWORD):
                self.registers.regWriteWithOpDword(CPU_REGISTER_EAX, op2, opcode)
            self.registers.setFullFlags(op1, op2, operSize, opcode)
        elif (opcode == OPCODE_CMP):
            self.registers.setFullFlags(op1, op2, operSize, OPCODE_SUB)
        elif (opcode in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            if (operSize == OP_SIZE_BYTE):
                op2 = self.registers.regWriteWithOpLowByte(CPU_REGISTER_AL, op2, opcode)
            elif (operSize == OP_SIZE_WORD):
                op2 = self.registers.regWriteWithOpWord(CPU_REGISTER_AX, op2, opcode)
            elif (operSize == OP_SIZE_DWORD):
                op2 = self.registers.regWriteWithOpDword(CPU_REGISTER_EAX, op2, opcode)
            self.registers.setSZP_C0_O0_A0(op2, operSize)
        elif (opcode == OPCODE_TEST):
            self.registers.setSZP_C0_O0_A0(op1&op2, operSize)
        else:
            self.main.notice("OPCODE::opcodeRM_R: invalid opcode: {0:d}.", opcode)
        return True
    cdef int movImmToR(self, unsigned char operSize):
        cdef unsigned char rReg
        cdef unsigned int src
        rReg = self.main.cpu.opcode&0x7
        src = self.registers.getCurrentOpcodeAddUnsigned(operSize)
        if (operSize == OP_SIZE_BYTE and rReg <= 0x3):
            self.registers.regWriteLowByte(rReg, src)
        elif (operSize == OP_SIZE_BYTE and rReg >= 0x4):
            self.registers.regWriteHighByte(rReg&3, src)
        elif (operSize == OP_SIZE_WORD):
            self.registers.regWriteWord(rReg, src)
        elif (operSize == OP_SIZE_DWORD):
            self.registers.regWriteDword(rReg, src)
        else:
            self.main.notice("OPCODE::movImmToR: unknown operSize: {0:d}.", operSize)
        return True
    cdef int movRM_R(self, unsigned char operSize):
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        self.modRMInstance.modRMSave(operSize, self.modRMInstance.modRLoadUnsigned(operSize), True, OPCODE_SAVE)
        return True
    cdef int movR_RM(self, unsigned char operSize, unsigned char cond):
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (cond):
            self.modRMInstance.modRSave(operSize, self.modRMInstance.modRMLoadUnsigned(operSize, True), OPCODE_SAVE)
        return True
    cdef int movRM16_SREG(self):
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        self.modRMInstance.modRMSave(OP_SIZE_WORD, self.registers.segRead(self.modRMInstance.regName), True, OPCODE_SAVE)
        return True
    cdef int movSREG_RM16(self):
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        if (self.modRMInstance.regName == CPU_SEGMENT_CS):
            raise ChemuException(CPU_EXCEPTION_UD)
        self.registers.segWrite(self.modRMInstance.regName, self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD, True))
        return True
    cdef int movAxMoffs(self, unsigned char operSize):
        self.registers.regWrite(CPU_REGISTER_AX, \
          self.registers.mmReadValueUnsigned(self.registers.getCurrentOpcodeAddUnsigned(self.registers.addrSize), \
            operSize, CPU_SEGMENT_DS, True), operSize)
        return True
    cdef int movMoffsAx(self, unsigned char operSize):
        cdef unsigned int value
        if (operSize == OP_SIZE_BYTE):
            value = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        elif (operSize == OP_SIZE_WORD):
            value = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
        elif (operSize == OP_SIZE_DWORD):
            value = self.registers.regReadUnsignedDword(CPU_REGISTER_EAX)
        self.registers.mmWriteValue(self.registers.getCurrentOpcodeAddUnsigned(self.registers.addrSize), \
          value, operSize, CPU_SEGMENT_DS, True)
        return True
    cdef int stosFuncWord(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned short countVal, ediVal
        cdef unsigned int data, dataLength
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        dataLength = <unsigned int>(<unsigned int>countVal*operSize)
        data = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
        ediVal = self.registers.regReadUnsignedWord(CPU_REGISTER_DI)
        if (dfFlag):
            ediVal = <unsigned short>(ediVal-(dataLength-operSize))
        self.registers.mmWrite(ediVal, data.to_bytes(length=operSize, \
          byteorder="little")*countVal, dataLength, CPU_SEGMENT_ES, False)
        if (not dfFlag):
            self.registers.regAddWord(CPU_REGISTER_DI, dataLength)
        else:
            self.registers.regSubWord(CPU_REGISTER_DI, dataLength)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteWord(CPU_REGISTER_CX, 0)
        return True
    cdef int stosFuncDword(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned int data, countVal, ediVal
        cdef unsigned long int dataLength
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        dataLength = (<unsigned long int>countVal*operSize)
        if (dataLength != <unsigned int>dataLength):
            self.main.notice("Opcodes::stosFunc: dataLength overflow.")
        dataLength = <unsigned int>dataLength
        data = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
        ediVal = self.registers.regReadUnsignedDword(CPU_REGISTER_EDI)
        if (dfFlag):
            ediVal = <unsigned int>(ediVal-(dataLength-operSize))
        self.registers.mmWrite(ediVal, data.to_bytes(length=operSize, \
          byteorder="little")*countVal, dataLength, CPU_SEGMENT_ES, False)
        if (not dfFlag):
            self.registers.regAddDword(CPU_REGISTER_EDI, dataLength)
        else:
            self.registers.regSubDword(CPU_REGISTER_EDI, dataLength)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteDword(CPU_REGISTER_ECX, 0)
        return True
    cdef int stosFunc(self, unsigned char operSize):
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.stosFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.stosFuncDword(operSize)
        return False
    cdef int movsFuncWord(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned short countVal, esiVal, ediVal, i
        cdef unsigned int dataLength
        cdef unsigned int esiFull, ediFull
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        dataLength = <unsigned int>(<unsigned int>countVal*operSize)
        esiVal = self.registers.regReadUnsignedWord(CPU_REGISTER_SI)
        ediVal = self.registers.regReadUnsignedWord(CPU_REGISTER_DI)
        esiFull = self.registers.mmGetRealAddr(esiVal, CPU_SEGMENT_DS, True)
        ediFull = self.registers.mmGetRealAddr(ediVal, CPU_SEGMENT_ES, False)
        if ((ediFull >= esiFull) and (ediFull < esiFull+dataLength)): # are these addresses overlapping? true if they do
            for i in range(countVal):
                self.registers.mmWrite(ediVal, self.registers.mmRead(esiVal, operSize, CPU_SEGMENT_DS, True), operSize, CPU_SEGMENT_ES, False)
                if (not dfFlag):
                    esiVal = <unsigned short>(esiVal+operSize)
                    ediVal = <unsigned short>(ediVal+operSize)
                else:
                    esiVal = <unsigned short>(esiVal-operSize)
                    ediVal = <unsigned short>(ediVal-operSize)
            self.registers.regWriteWord(CPU_REGISTER_SI, esiVal)
            self.registers.regWriteWord(CPU_REGISTER_DI, ediVal)
        else:
            if (dfFlag):
                esiFull = <unsigned int>(esiFull-(dataLength-operSize))
                ediFull = <unsigned int>(ediFull-(dataLength-operSize))
            (<Mm>self.main.mm).mmPhyCopy(ediFull, esiFull, dataLength)
            if (not dfFlag):
                self.registers.regAddWord(CPU_REGISTER_SI, dataLength)
                self.registers.regAddWord(CPU_REGISTER_DI, dataLength)
            else:
                self.registers.regSubWord(CPU_REGISTER_SI, dataLength)
                self.registers.regSubWord(CPU_REGISTER_DI, dataLength)

        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteWord(CPU_REGISTER_CX, 0)
        return True
    cdef int movsFuncDword(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned int countVal, esiVal, ediVal, i, esiFull, ediFull
        cdef unsigned long int dataLength
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        dataLength = (<unsigned long int>countVal*operSize)
        if (dataLength != <unsigned int>dataLength):
            self.main.notice("Opcodes::movsFunc: dataLength overflow.")
        dataLength = <unsigned int>dataLength
        esiVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ESI)
        ediVal = self.registers.regReadUnsignedDword(CPU_REGISTER_EDI)
        esiFull = self.registers.mmGetRealAddr(esiVal, CPU_SEGMENT_DS, True)
        ediFull = self.registers.mmGetRealAddr(ediVal, CPU_SEGMENT_ES, False)
        if ((ediFull >= esiFull) and (ediFull < esiFull+dataLength)): # are these addresses overlapping? true if they do
            for i in range(countVal):
                self.registers.mmWrite(ediVal, self.registers.mmRead(esiVal, operSize, CPU_SEGMENT_DS, True), operSize, CPU_SEGMENT_ES, False)
                if (not dfFlag):
                    esiVal = <unsigned int>(esiVal+operSize)
                    ediVal = <unsigned int>(ediVal+operSize)
                else:
                    esiVal = <unsigned int>(esiVal-operSize)
                    ediVal = <unsigned int>(ediVal-operSize)
            self.registers.regWriteDword(CPU_REGISTER_ESI, esiVal)
            self.registers.regWriteDword(CPU_REGISTER_EDI, ediVal)
        else:
            if (dfFlag):
                esiFull = <unsigned int>(esiFull-(dataLength-operSize))
                ediFull = <unsigned int>(ediFull-(dataLength-operSize))
            (<Mm>self.main.mm).mmPhyCopy(ediFull, esiFull, dataLength)
            if (not dfFlag):
                self.registers.regAddDword(CPU_REGISTER_ESI, dataLength)
                self.registers.regAddDword(CPU_REGISTER_EDI, dataLength)
            else:
                self.registers.regSubDword(CPU_REGISTER_ESI, dataLength)
                self.registers.regSubDword(CPU_REGISTER_EDI, dataLength)

        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteDword(CPU_REGISTER_ECX, 0)
        return True
    cdef int movsFunc(self, unsigned char operSize):
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.movsFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.movsFuncDword(operSize)
        return False
    cdef int lodsFuncWord(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned short countVal, esiVal
        cdef unsigned int data, dataLength
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        dataLength = <unsigned int>(<unsigned int>countVal*operSize)
        if (not dfFlag):
            esiVal = <unsigned short>(self.registers.regAddWord(CPU_REGISTER_SI, dataLength)-operSize)
        else:
            esiVal = <unsigned short>(self.registers.regSubWord(CPU_REGISTER_SI, dataLength)+operSize)
        data = self.registers.mmReadValueUnsigned(esiVal, operSize, CPU_SEGMENT_DS, True)
        self.registers.regWrite(CPU_REGISTER_AX, data, operSize)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteWord(CPU_REGISTER_CX, 0)
        return True
    cdef int lodsFuncDword(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned int data, countVal, esiVal
        cdef unsigned long int dataLength
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        dataLength = (<unsigned long int>countVal*operSize)
        if (dataLength != <unsigned int>dataLength):
            self.main.notice("Opcodes::lodsFunc: dataLength overflow.")
        dataLength = <unsigned int>dataLength
        if (not dfFlag):
            esiVal = <unsigned int>(self.registers.regAddDword(CPU_REGISTER_ESI, dataLength)-operSize)
        else:
            esiVal = <unsigned int>(self.registers.regSubDword(CPU_REGISTER_ESI, dataLength)+operSize)
        data = self.registers.mmReadValueUnsigned(esiVal, operSize, CPU_SEGMENT_DS, True)
        self.registers.regWrite(CPU_REGISTER_AX, data, operSize)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteDword(CPU_REGISTER_ECX, 0)
        return True
    cdef int lodsFunc(self, unsigned char operSize):
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.lodsFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.lodsFuncDword(operSize)
        return False
    cdef int cmpsFuncWord(self, unsigned char operSize):
        cdef unsigned char zfFlag, dfFlag
        cdef unsigned short countVal, newCount, esiVal, ediVal, i
        cdef unsigned int src1, src2
        countVal, newCount = 1, 0
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        esiVal = self.registers.regReadUnsignedWord(CPU_REGISTER_SI)
        ediVal = self.registers.regReadUnsignedWord(CPU_REGISTER_DI)
        for i in range(countVal):
            src1 = self.registers.mmReadValueUnsigned(esiVal, operSize, CPU_SEGMENT_DS, True)
            src2 = self.registers.mmReadValueUnsigned(ediVal, operSize, CPU_SEGMENT_ES, False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not dfFlag):
                esiVal = <unsigned short>(esiVal+operSize)
                ediVal = <unsigned short>(ediVal+operSize)
            else:
                esiVal = <unsigned short>(esiVal-operSize)
                ediVal = <unsigned short>(ediVal-operSize)
            zfFlag = self.registers.getEFLAG(FLAG_ZF)!=0
            if ((self.registers.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or \
              (self.registers.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                newCount = countVal-i-1
                break
        self.registers.regWriteWord(CPU_REGISTER_SI, esiVal)
        self.registers.regWriteWord(CPU_REGISTER_DI, ediVal)
        self.main.cpu.cycles += (countVal-newCount) << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteWord(CPU_REGISTER_CX, newCount)
        return True
    cdef int cmpsFuncDword(self, unsigned char operSize):
        cdef unsigned char zfFlag, dfFlag
        cdef unsigned int esiVal, ediVal, countVal, newCount, src1, src2, i
        countVal, newCount = 1, 0
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        esiVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ESI)
        ediVal = self.registers.regReadUnsignedDword(CPU_REGISTER_EDI)
        for i in range(countVal):
            src1 = self.registers.mmReadValueUnsigned(esiVal, operSize, CPU_SEGMENT_DS, True)
            src2 = self.registers.mmReadValueUnsigned(ediVal, operSize, CPU_SEGMENT_ES, False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not dfFlag):
                esiVal = <unsigned int>(esiVal+operSize)
                ediVal = <unsigned int>(ediVal+operSize)
            else:
                esiVal = <unsigned int>(esiVal-operSize)
                ediVal = <unsigned int>(ediVal-operSize)
            zfFlag = self.registers.getEFLAG(FLAG_ZF)!=0
            if ((self.registers.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or \
              (self.registers.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                newCount = countVal-i-1
                break
        self.registers.regWriteDword(CPU_REGISTER_ESI, esiVal)
        self.registers.regWriteDword(CPU_REGISTER_EDI, ediVal)
        self.main.cpu.cycles += (countVal-newCount) << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteDword(CPU_REGISTER_ECX, newCount)
        return True
    cdef int cmpsFunc(self, unsigned char operSize):
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.cmpsFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.cmpsFuncDword(operSize)
        return False
    cdef int scasFuncWord(self, unsigned char operSize):
        cdef unsigned char zfFlag, dfFlag
        cdef unsigned short ediVal, countVal, newCount, i
        cdef unsigned int src1, src2
        countVal, newCount = 1, 0
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        ediVal = self.registers.regReadUnsignedWord(CPU_REGISTER_DI)
        src1 = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
        for i in range(countVal):
            src2 = self.registers.mmReadValueUnsigned(ediVal, operSize, CPU_SEGMENT_ES, False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not dfFlag):
                ediVal = <unsigned short>(ediVal+operSize)
            else:
                ediVal = <unsigned short>(ediVal-operSize)
            zfFlag = self.registers.getEFLAG(FLAG_ZF)!=0
            if ((self.registers.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or \
              (self.registers.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                newCount = countVal-i-1
                break
        self.registers.regWriteWord(CPU_REGISTER_DI, ediVal)
        self.main.cpu.cycles += (countVal-newCount) << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteWord(CPU_REGISTER_CX, newCount)
        return True
    cdef int scasFuncDword(self, unsigned char operSize):
        cdef unsigned char zfFlag, dfFlag
        cdef unsigned int src1, src2, ediVal, countVal, newCount, i
        countVal, newCount = 1, 0
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        ediVal = self.registers.regReadUnsignedDword(CPU_REGISTER_EDI)
        src1 = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
        for i in range(countVal):
            src2 = self.registers.mmReadValueUnsigned(ediVal, operSize, CPU_SEGMENT_ES, False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not dfFlag):
                ediVal = <unsigned int>(ediVal+operSize)
            else:
                ediVal = <unsigned int>(ediVal-operSize)
            zfFlag = self.registers.getEFLAG(FLAG_ZF)!=0
            if ((self.registers.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or \
              (self.registers.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                newCount = countVal-i-1
                break
        self.registers.regWriteDword(CPU_REGISTER_EDI, ediVal)
        self.main.cpu.cycles += (countVal-newCount) << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteDword(CPU_REGISTER_ECX, newCount)
        return True
    cdef int scasFunc(self, unsigned char operSize):
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.scasFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.scasFuncDword(operSize)
        return False
    cdef int inAxImm8(self, unsigned char operSize):
        cdef unsigned int value
        value = self.inPort(self.registers.getCurrentOpcodeAddUnsignedByte(), operSize)
        if (operSize == OP_SIZE_BYTE):
            self.registers.regWriteLowByte(CPU_REGISTER_AL, value)
        elif (operSize == OP_SIZE_WORD):
            self.registers.regWriteWord(CPU_REGISTER_AX, value)
        elif (operSize == OP_SIZE_DWORD):
            self.registers.regWriteDword(CPU_REGISTER_EAX, value)
        return True
    cdef int inAxDx(self, unsigned char operSize):
        cdef unsigned int value
        value = self.inPort(self.registers.regReadUnsignedWord(CPU_REGISTER_DX), operSize)
        if (operSize == OP_SIZE_BYTE):
            self.registers.regWriteLowByte(CPU_REGISTER_AL, value)
        elif (operSize == OP_SIZE_WORD):
            self.registers.regWriteWord(CPU_REGISTER_AX, value)
        elif (operSize == OP_SIZE_DWORD):
            self.registers.regWriteDword(CPU_REGISTER_EAX, value)
        return True
    cdef int outImm8Ax(self, unsigned char operSize):
        cdef unsigned int value
        if (operSize == OP_SIZE_BYTE):
            value = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        elif (operSize == OP_SIZE_WORD):
            value = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
        elif (operSize == OP_SIZE_DWORD):
            value = self.registers.regReadUnsignedDword(CPU_REGISTER_EAX)
        self.outPort(self.registers.getCurrentOpcodeAddUnsignedByte(), value, operSize)
        return True
    cdef int outDxAx(self, unsigned char operSize):
        cdef unsigned int value
        if (operSize == OP_SIZE_BYTE):
            value = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        elif (operSize == OP_SIZE_WORD):
            value = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
        elif (operSize == OP_SIZE_DWORD):
            value = self.registers.regReadUnsignedDword(CPU_REGISTER_EAX)
        self.outPort(self.registers.regReadUnsignedWord(CPU_REGISTER_DX), value, operSize)
        return True
    cdef int outsFuncWord(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned short ioPort, esiVal, countVal, i
        cdef unsigned int value
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        esiVal = self.registers.regReadUnsignedWord(CPU_REGISTER_SI)
        ioPort = self.registers.regReadUnsignedWord(CPU_REGISTER_DX)
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        for i in range(countVal):
            value = self.registers.mmReadValueUnsigned(esiVal, operSize, CPU_SEGMENT_DS, True)
            self.outPort(ioPort, value, operSize)
            if (not dfFlag):
                esiVal = <unsigned short>(esiVal+operSize)
            else:
                esiVal = <unsigned short>(esiVal-operSize)
        self.registers.regWriteWord(CPU_REGISTER_SI, esiVal)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteWord(CPU_REGISTER_CX, 0)
        return True
    cdef int outsFuncDword(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned short ioPort
        cdef unsigned int value, esiVal, countVal, i
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        esiVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ESI)
        ioPort = self.registers.regReadUnsignedWord(CPU_REGISTER_DX)
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        for i in range(countVal):
            value = self.registers.mmReadValueUnsigned(esiVal, operSize, CPU_SEGMENT_DS, True)
            self.outPort(ioPort, value, operSize)
            if (not dfFlag):
                esiVal = <unsigned int>(esiVal+operSize)
            else:
                esiVal = <unsigned int>(esiVal-operSize)
        self.registers.regWriteDword(CPU_REGISTER_ESI, esiVal)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteDword(CPU_REGISTER_ECX, 0)
        return True
    cdef int outsFunc(self, unsigned char operSize):
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.outsFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.outsFuncDword(operSize)
        return False
    cdef int insFuncWord(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned short ioPort, ediVal, countVal, i
        cdef unsigned int value
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        ediVal = self.registers.regReadUnsignedWord(CPU_REGISTER_DI)
        ioPort = self.registers.regReadUnsignedWord(CPU_REGISTER_DX)
        for i in range(countVal):
            value = self.inPort(ioPort, operSize)
            self.registers.mmWriteValue(ediVal, value, operSize, CPU_SEGMENT_ES, False)
            if (not dfFlag):
                ediVal = <unsigned short>(ediVal+operSize)
            else:
                ediVal = <unsigned short>(ediVal-operSize)
        self.registers.regWriteWord(CPU_REGISTER_DI, ediVal)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteWord(CPU_REGISTER_CX, 0)
        return True
    cdef int insFuncDword(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned short ioPort
        cdef unsigned int value, ediVal, countVal, i
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        ediVal = self.registers.regReadUnsignedDword(CPU_REGISTER_EDI)
        ioPort = self.registers.regReadUnsignedWord(CPU_REGISTER_DX)
        for i in range(countVal):
            value = self.inPort(ioPort, operSize)
            self.registers.mmWriteValue(ediVal, value, operSize, CPU_SEGMENT_ES, False)
            if (not dfFlag):
                ediVal = <unsigned int>(ediVal+operSize)
            else:
                ediVal = <unsigned int>(ediVal-operSize)
        self.registers.regWriteDword(CPU_REGISTER_EDI, ediVal)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteDword(CPU_REGISTER_ECX, 0)
        return True
    cdef int insFunc(self, unsigned char operSize):
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.insFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.insFuncDword(operSize)
        return False
    cdef int jcxzShort(self):
        cdef unsigned int cxVal
        cxVal = self.registers.regReadUnsigned(CPU_REGISTER_CX, self.registers.addrSize)
        self.jumpShort(OP_SIZE_BYTE, not cxVal)
        return True
    cdef int jumpShort(self, unsigned char offsetSize, unsigned char cond):
        cdef signed int offset
        cdef unsigned int newEip
        offset = self.registers.getCurrentOpcodeAddSigned(offsetSize)
        if (not cond):
            return True
        newEip = <unsigned int>(self.registers.regReadUnsignedDword(CPU_REGISTER_EIP)+offset)
        if (self.registers.operSize == OP_SIZE_WORD):
            newEip = <unsigned short>newEip
        self.registers.regWriteDword(CPU_REGISTER_EIP, newEip)
        return True
    cdef int callNearRel16_32(self):
        cdef signed int offset
        cdef unsigned int newEip
        offset = self.registers.getCurrentOpcodeAddSigned(self.registers.operSize)
        newEip = <unsigned int>(self.registers.regReadUnsignedDword(CPU_REGISTER_EIP)+offset)
        if (self.registers.operSize == OP_SIZE_WORD):
            newEip = <unsigned short>newEip
        self.stackPushRegId(CPU_REGISTER_EIP, self.registers.operSize)
        self.registers.regWriteDword(CPU_REGISTER_EIP, newEip)
        return True
    cdef int callPtr16_32(self):
        cdef unsigned short segVal
        cdef unsigned int eipAddr
        eipAddr = self.registers.getCurrentOpcodeAddUnsigned(self.registers.operSize)
        segVal = self.registers.getCurrentOpcodeAddUnsignedWord()
        self.jumpFarDirect(OPCODE_CALL, segVal, eipAddr)
        return True
    cdef int pushaWD(self):
        cdef unsigned int temp
        temp = self.registers.regReadUnsigned(CPU_REGISTER_SP, self.registers.operSize)
        if (not (<Segments>self.registers.segments).isInProtectedMode() and temp in (7, 9, 11, 13, 15)):
            raise ChemuException(CPU_EXCEPTION_GP, 0)
        self.stackPushRegId(CPU_REGISTER_AX, self.registers.operSize)
        self.stackPushRegId(CPU_REGISTER_CX, self.registers.operSize)
        self.stackPushRegId(CPU_REGISTER_DX, self.registers.operSize)
        self.stackPushRegId(CPU_REGISTER_BX, self.registers.operSize)
        self.stackPushValue(temp, self.registers.operSize)
        self.stackPushRegId(CPU_REGISTER_BP, self.registers.operSize)
        self.stackPushRegId(CPU_REGISTER_SI, self.registers.operSize)
        self.stackPushRegId(CPU_REGISTER_DI, self.registers.operSize)
        return True
    cdef int popaWD(self):
        self.stackPopRegId(CPU_REGISTER_DI, self.registers.operSize)
        self.stackPopRegId(CPU_REGISTER_SI, self.registers.operSize)
        self.stackPopRegId(CPU_REGISTER_BP, self.registers.operSize)
        self.registers.regAddDword(CPU_REGISTER_ESP, self.registers.operSize)
        self.stackPopRegId(CPU_REGISTER_BX, self.registers.operSize)
        self.stackPopRegId(CPU_REGISTER_DX, self.registers.operSize)
        self.stackPopRegId(CPU_REGISTER_CX, self.registers.operSize)
        self.stackPopRegId(CPU_REGISTER_AX, self.registers.operSize)
        return True
    cdef int pushfWD(self):
        cdef unsigned int value
        value = self.registers.regReadUnsigned(CPU_REGISTER_FLAGS, self.registers.operSize)|0x2
        value &= (~FLAG_IOPL) # This is for
        value |= (self.registers.getIOPL()<<12) # IOPL, Bits 12,13
        if (self.registers.operSize == OP_SIZE_DWORD):
            value &= 0x00FCFFFF
        self.stackPushValue(value, self.registers.operSize)
        return True
    cdef int popfWD(self):
        cdef unsigned char cpl
        cdef unsigned int flagValue, oldFlagValue
        cpl = self.registers.getCPL()
        oldFlagValue = self.registers.regReadUnsigned(CPU_REGISTER_FLAGS, self.registers.operSize)
        flagValue = self.stackPopValue(True)
        flagValue &= ~RESERVED_FLAGS_BITMASK
        flagValue |= FLAG_REQUIRED
        if (cpl != 0):
            flagValue &= ~(FLAG_IOPL)
            flagValue |= (oldFlagValue&FLAG_IOPL)
            if (self.registers.operSize == OP_SIZE_WORD and cpl > ((oldFlagValue>>12)&3)):
                flagValue &= ~(FLAG_IF)
                flagValue |= (oldFlagValue & FLAG_IF)
        if (self.registers.operSize == OP_SIZE_WORD):
            flagValue = <unsigned short>flagValue
        else:
            flagValue &= ~(FLAG_VIP | FLAG_VIF | FLAG_RF)
        self.registers.regWrite(CPU_REGISTER_FLAGS, flagValue, self.registers.operSize)
        if (self.registers.getEFLAG(FLAG_VM)!=0):
            self.main.exitError("Opcodes::popfWD: VM86-Mode isn't supported yet.")
        return True
    cdef int stackPopSegId(self, unsigned short segId):
        self.registers.segWrite(segId, <unsigned short>(self.stackPopValue(True)))
        return True
    cdef int stackPopRegId(self, unsigned short regId, unsigned char regSize):
        cdef unsigned int value
        value = self.stackPopValue(True)
        if (regSize == OP_SIZE_WORD):
            value = <unsigned short>value
        self.registers.regWrite(regId, value, regSize)
        return True
    cdef unsigned int stackPopValue(self, unsigned char increaseStackAddr):
        cdef unsigned char stackAddrSize
        cdef unsigned int data
        stackAddrSize = self.registers.getAddrSegSize(CPU_SEGMENT_SS)
        data = self.registers.regReadUnsigned(CPU_REGISTER_SP, stackAddrSize)
        data = self.registers.mmReadValueUnsigned(data, self.registers.operSize, CPU_SEGMENT_SS, False)
        if (increaseStackAddr):
            self.registers.regAdd(CPU_REGISTER_SP, self.registers.operSize, stackAddrSize)
        return data
    cdef int stackPushValue(self, unsigned int value, unsigned char operSize):
        cdef unsigned char stackAddrSize
        cdef unsigned int stackAddr
        stackAddrSize = self.registers.getAddrSegSize(CPU_SEGMENT_SS)
        stackAddr = self.registers.regReadUnsigned(CPU_REGISTER_SP, stackAddrSize)
        if ((<Segments>self.registers.segments).isInProtectedMode() and stackAddr < operSize):
            raise ChemuException(CPU_EXCEPTION_SS, 0)
        stackAddr = <unsigned int>(stackAddr-operSize)
        if (stackAddrSize == OP_SIZE_WORD):
            stackAddr = <unsigned short>stackAddr
        self.registers.regWrite(CPU_REGISTER_SP, stackAddr, stackAddrSize)
        if (operSize == OP_SIZE_WORD):
            value = <unsigned short>value
        self.registers.mmWriteValue(stackAddr, value, operSize, CPU_SEGMENT_SS, False)
        return True
    cdef int stackPushSegId(self, unsigned short segId, unsigned char operSize):
        return self.stackPushValue(self.registers.segRead(segId), operSize)
    cdef int stackPushRegId(self, unsigned short regId, unsigned char operSize):
        cdef unsigned int value
        value = self.registers.regReadUnsigned(regId, operSize)
        return self.stackPushValue(value, operSize)
    cdef int pushIMM(self, unsigned char immIsByte):
        cdef unsigned int value
        if (immIsByte):
            value = <unsigned int>(self.registers.getCurrentOpcodeAddSignedByte())
        else:
            value = self.registers.getCurrentOpcodeAddUnsigned(self.registers.operSize)
        if (self.registers.operSize == OP_SIZE_WORD):
            value = <unsigned short>value
        return self.stackPushValue(value, self.registers.operSize)
    cdef int imulR_RM_ImmFunc(self, unsigned char immIsByte):
        cdef signed int operOp1
        cdef signed long int operOp2
        cdef unsigned int operSum, bitMask
        cdef unsigned long int temp
        bitMask = (<Misc>self.main.misc).getBitMaskFF(self.registers.operSize)
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        operOp1 = self.modRMInstance.modRMLoadSigned(self.registers.operSize, True)
        if (immIsByte):
            operOp2 = self.registers.getCurrentOpcodeAddSignedByte()
            operOp2 &= bitMask
        else:
            operOp2 = self.registers.getCurrentOpcodeAddSigned(self.registers.operSize)
        operSum = (operOp1*operOp2)&bitMask
        temp = <unsigned long int>(operOp1*operOp2)
        if (self.registers.operSize == OP_SIZE_WORD):
            temp = <unsigned int>temp
        self.modRMInstance.modRSave(self.registers.operSize, operSum, OPCODE_SAVE)
        self.registers.setFullFlags(operOp1, operOp2, self.registers.operSize, OPCODE_IMUL)
        self.registers.setEFLAG(FLAG_CF | FLAG_OF, temp!=operSum)
        return True
    cdef int opcodeGroup1_RM_ImmFunc(self, unsigned char operSize, unsigned char immIsByte):
        cdef unsigned char operOpcode, operOpcodeId
        cdef unsigned int operOp1, operOp2
        operOpcode = self.registers.getCurrentOpcodeUnsignedByte()
        operOpcodeId = (operOpcode>>3)&7
        self.main.debug("Group1_RM_ImmFunc: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp1 = self.modRMInstance.modRMLoadUnsigned(operSize, True)
        if (operSize != OP_SIZE_BYTE and immIsByte):
            operOp2 = <unsigned int>self.registers.getCurrentOpcodeAddSignedByte() # operImm8 sign-extended to destsize
            if (operSize == OP_SIZE_WORD):
                operOp2 = <unsigned short>operOp2
        else:
            operOp2 = self.registers.getCurrentOpcodeAddUnsigned(operSize) # operImm8/16/32
        if (operOpcodeId in (GROUP1_OP_ADD, GROUP1_OP_ADC, GROUP1_OP_SUB, GROUP1_OP_SBB)):
            if (operOpcodeId == GROUP1_OP_ADD):
                operOpcodeId = OPCODE_ADD
            elif (operOpcodeId == GROUP1_OP_ADC):
                operOpcodeId = OPCODE_ADC
            elif (operOpcodeId == GROUP1_OP_SUB):
                operOpcodeId = OPCODE_SUB
            elif (operOpcodeId == GROUP1_OP_SBB):
                operOpcodeId = OPCODE_SBB
            self.modRMInstance.modRMSave(operSize, operOp2, True, operOpcodeId)
            self.registers.setFullFlags(operOp1, operOp2, operSize, operOpcodeId)
        elif (operOpcodeId in (GROUP1_OP_AND, GROUP1_OP_OR, GROUP1_OP_XOR)):
            if (operOpcodeId == GROUP1_OP_AND):
                operOpcodeId = OPCODE_AND
            elif (operOpcodeId == GROUP1_OP_OR):
                operOpcodeId = OPCODE_OR
            elif (operOpcodeId == GROUP1_OP_XOR):
                operOpcodeId = OPCODE_XOR
            operOp2 = self.modRMInstance.modRMSave(operSize, operOp2, True, operOpcodeId)
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP1_OP_CMP):
            self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_SUB)
        else:
            self.main.notice("opcodeGroup1_RM16_32_IMM8: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
        return True
    cdef int opcodeGroup3_RM_ImmFunc(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId
        cdef unsigned int operOp2
        operOpcode = self.registers.getCurrentOpcodeUnsignedByte()
        operOpcodeId = (operOpcode>>3)&7
        self.main.debug("Group3_RM_ImmFunc: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp2 = self.registers.getCurrentOpcodeAddUnsigned(operSize) # operImm
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.modRMInstance.modRMSave(operSize, operOp2, True, OPCODE_SAVE)
        else:
            self.main.notice("opcodeGroup3_RM16_32_IMM16_32: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
        return True
    cdef int opcodeGroup0F(self):
        cdef unsigned char operOpcode, bitSize, operOpcodeMod, operOpcodeModId, \
            newCF, newOF, oldOF, count, eaxIsInvalid, cpl, segType
        cdef unsigned short limit
        cdef unsigned int eaxId, bitMask, bitMaskHalf, base, mmAddr, op1, op2
        cdef unsigned long int qop1, qop2
        cdef signed short i
        cdef signed int sop1, sop2
        cdef GdtEntry gdtEntry
        cpl = self.registers.getCPL()
        operOpcode = self.registers.getCurrentOpcodeAddUnsignedByte()
        self.main.debug("Group0F: Opcode=={0:#04x}", operOpcode)
        if (operOpcode == 0x00): # LLDT/SLDT LTR/STR VERR/VERW
            if (not (<Segments>self.registers.segments).isInProtectedMode()):
                raise ChemuException(CPU_EXCEPTION_UD)
            if (cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            operOpcodeMod = self.registers.getCurrentOpcodeUnsignedByte()
            operOpcodeModId = (operOpcodeMod>>3)&7
            self.main.debug("Group0F_00: operOpcodeModId=={0:d}", operOpcodeModId)
            self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            if (operOpcodeModId in (0, 1)): # SLDT/STR
                bitSize = OP_SIZE_WORD # bitSize is in bytes because of the double-usage of vars
                if (self.modRMInstance.mod == 3):
                    bitSize = OP_SIZE_DWORD
                if (operOpcodeModId == 0): # SLDT
                    self.modRMInstance.modRMSave(bitSize, (<Segments>\
                      self.registers.segments).ldtr, True, OPCODE_SAVE)
                elif (operOpcodeModId == 1): # STR
                    self.modRMInstance.modRMSave(bitSize, (<Segments>\
                      self.registers.segments).tr, True, OPCODE_SAVE)
                    self.main.notice("opcodeGroup0F_00_STR: TR isn't fully supported yet.")
            elif (operOpcodeModId in (2, 3)): # LLDT/LTR
                op1 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD, True)
                if (operOpcodeModId == 2): # LLDT
                    if (not (op1>>2)):
                        self.main.debug("Opcode0F_01::LLDT: (op1>>2) == 0, mark LDTR as invalid.")
                        op1 = 0
                    else:
                        if ((op1 & SELECTOR_USE_LDT) or \
                          ((op1&0xfff8) > (<Gdt>self.registers.segments.gdt).tableLimit)):
                            raise ChemuException(CPU_EXCEPTION_GP, op1)
                        segType = (<Gdt>self.registers.segments.gdt).getSegType(op1)
                        if (segType != TABLE_ENTRY_SYSTEM_TYPE_LDT):
                            raise ChemuException(CPU_EXCEPTION_GP, op1)
                        if (not (<Gdt>self.registers.segments.gdt).isSegPresent(op1)):
                            raise ChemuException(CPU_EXCEPTION_NP, op1)
                        op1 &= 0xfff8
                    gdtEntry = (<GdtEntry>(<Gdt>self.registers.segments.gdt).getEntry(op1))
                    if (not gdtEntry):
                        op1 = 0
                    (<Segments>self.registers.segments).ldtr = op1
                    if (gdtEntry):
                        (<Gdt>self.registers.segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
                elif (operOpcodeModId == 3): # LTR
                    if (not (op1&0xfff8)):
                        raise ChemuException(CPU_EXCEPTION_GP, 0)
                    elif ((op1 & SELECTOR_USE_LDT) or \
                      ((op1&0xfff8) > (<Gdt>self.registers.segments.gdt).tableLimit)):
                        raise ChemuException(CPU_EXCEPTION_GP, op1)
                    if (not (<Gdt>self.registers.segments.gdt).isSegPresent(op1)):
                        raise ChemuException(CPU_EXCEPTION_NP, op1)
                    gdtEntry = (<GdtEntry>(<Gdt>self.registers.segments.gdt).getEntry(op1))
                    segType = (gdtEntry.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK) if (gdtEntry) else 0
                    if (not gdtEntry or segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS)):
                        self.main.notice("opcodeGroup0F_00_LTR: segType {0:d} not a TSS. (is gdtEntry None? {1:d})", \
                          segType, (gdtEntry is None))
                        raise ChemuException(CPU_EXCEPTION_GP, op1)
                    if (segType == TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS):
                        (<Gdt>self.registers.segments.gdt).setSegType(op1, TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY)
                        if (gdtEntry.limit != TSS_MIN_16BIT_HARD_LIMIT):
                            self.main.notice(\
                              "opcodeGroup0F_00_LTR: tssLimit {0:#06x} != TSS_MIN_16BIT_HARD_LIMIT {1:#06x}.", gdtEntry.limit, \
                              TSS_MIN_16BIT_HARD_LIMIT)
                            op1 = 0
                    elif (segType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                        (<Gdt>self.registers.segments.gdt).setSegType(op1, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY)
                        if (gdtEntry.limit < TSS_MIN_32BIT_HARD_LIMIT):
                            self.main.notice(\
                              "opcodeGroup0F_00_LTR: tssLimit {0:#06x} < TSS_MIN_32BIT_HARD_LIMIT {1:#06x}.", gdtEntry.limit, \
                              TSS_MIN_32BIT_HARD_LIMIT)
                            op1 = 0
                    op1 &= 0xfff8
                    (<Segments>self.registers.segments).tr = op1
                    (<Gdt>self.registers.segments.tss).loadTablePosition(gdtEntry.base, gdtEntry.limit)
                    self.main.notice("opcodeGroup0F_00_LTR: TR isn't fully supported yet.")
            elif (operOpcodeModId == 4): # VERR
                op1 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD, True)
                self.registers.setEFLAG(FLAG_ZF, (<Segments>self.registers.segments).checkReadAllowed(op1))
            elif (operOpcodeModId == 5): # VERW
                op1 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD, True)
                self.registers.setEFLAG(FLAG_ZF, (<Segments>self.registers.segments).checkWriteAllowed(op1))
            else:
                self.main.notice("opcodeGroup0F_00: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x01): # LGDT/LIDT SGDT/SIDT SMSW/LMSW
            if (cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            operOpcodeMod = self.registers.getCurrentOpcodeUnsignedByte()
            operOpcodeModId = (operOpcodeMod>>3)&7
            self.main.debug("Group0F_01: operOpcodeModId=={0:d}", operOpcodeModId)
            if (operOpcodeModId in (0, 1, 2, 3)): # SGDT/SIDT LGDT/LIDT
                self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
                if (self.modRMInstance.mod == 3):
                    raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeModId in (4, 6)): # SMSW/LMSW
                self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            else:
                self.main.notice("Group0F_01: operOpcodeModId not in (0, 1, 2, 3, 4, 6)")
            mmAddr = self.modRMInstance.getRMValueFull(self.registers.addrSize)
            if (operOpcodeMod == 0xc1): # VMCALL
                self.main.notice("opcodeGroup0F_01: VMCALL isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc2): # VMLAUNCH
                self.main.notice("opcodeGroup0F_01: VMLAUNCH isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc3): # VMRESUME
                self.main.notice("opcodeGroup0F_01: VMRESUME isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc4): # VMXOFF
                self.main.notice("opcodeGroup0F_01: VMXOFF isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc8): # MONITOR
                self.main.notice("opcodeGroup0F_01: MONITOR isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc9): # MWAIT
                self.main.notice("opcodeGroup0F_01: MWAIT isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xd0): # XGETBV
                self.main.notice("opcodeGroup0F_01: XGETBV isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xd1): # XSETBV
                self.main.notice("opcodeGroup0F_01: XSETBV isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xf9): # RDTSCP
                self.main.notice("opcodeGroup0F_01: RDTSCP isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeModId in (0, 1)): # SGDT/SIDT
                if (operOpcodeModId == 0): # SGDT
                    (<Gdt>self.registers.segments.gdt).getBaseLimit(&base, &limit)
                elif (operOpcodeModId == 1): # SIDT
                    (<Idt>self.registers.segments.idt).getBaseLimit(&base, &limit)
                if (self.registers.operSize == OP_SIZE_WORD):
                    base &= 0xffffff
                self.registers.mmWriteValueWord(mmAddr, limit, CPU_SEGMENT_DS, True)
                self.registers.mmWriteValueDword(mmAddr+OP_SIZE_WORD, base, CPU_SEGMENT_DS, True)
            elif (operOpcodeModId in (2, 3)): # LGDT/LIDT
                limit = self.registers.mmReadValueUnsignedWord(mmAddr, CPU_SEGMENT_DS, True)
                base = self.registers.mmReadValueUnsignedDword(mmAddr+OP_SIZE_WORD, CPU_SEGMENT_DS, True)
                if (self.registers.operSize == OP_SIZE_WORD):
                    base &= 0xffffff
                if (operOpcodeModId == 2): # LGDT
                    (<Gdt>self.registers.segments.gdt).loadTablePosition(base, limit)
                elif (operOpcodeModId == 3): # LIDT
                    (<Idt>self.registers.segments.idt).loadTable(base, limit)
            elif (operOpcodeModId == 4): # SMSW
                op2 = <unsigned short>(self.registers.regReadUnsignedDword(CPU_REGISTER_CR0))
                self.modRMInstance.modRMSave(OP_SIZE_WORD, op2, True, OPCODE_SAVE)
            elif (operOpcodeModId == 6): # LMSW
                if (cpl != 0):
                    raise ChemuException(CPU_EXCEPTION_GP, 0)
                op1 = self.registers.regReadUnsignedDword(CPU_REGISTER_CR0)
                op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD, True)
                if ((op1&1) and not (op2&1)): # it's already in protected mode, but it tries to switch to real mode...
                    self.main.exitError("opcodeGroup0F_01: LMSW: try to switch to real mode from protected mode.")
                    return True
                self.registers.regWriteDword(CPU_REGISTER_CR0, ((op1&0xfffffff0)|(op2&0xf)))
                self.syncCR0State()
            elif (operOpcodeModId == 7): # INVLPG
                (<Paging>self.registers.segments.paging).invalidateTables(self.registers.regReadUnsignedDword(CPU_REGISTER_CR3))
            else:
                self.main.notice("opcodeGroup0F_01: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x03): # LSL
            if (not (<Segments>self.registers.segments).isInProtectedMode()):
                raise ChemuException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD, True)
            if (op2 > ((<Gdt>self.registers.segments.gdt).tableLimit)):
                self.registers.setEFLAG(FLAG_ZF, False)
                return True
            gdtEntry = (<GdtEntry>(<Gdt>self.registers.segments.gdt).getEntry(op2))
            if ((not gdtEntry.segIsConforming and ((cpl > gdtEntry.segDPL) or ((op2&3) > gdtEntry.segDPL))) or \
              ((<Gdt>self.registers.segments.gdt).getSegType(op2) not in (0x1, 0x2, 0x3, 0x9, 0xb))):
                self.registers.setEFLAG(FLAG_ZF, False)
                return True  
            op1 = gdtEntry.limit
            if ((gdtEntry.flags & GDT_FLAG_USE_4K) != 0):
                op1 <<= 12
                op1 |= 0xfff
            if (self.registers.operSize == OP_SIZE_WORD):
                op1 = <unsigned short>op1
            self.modRMInstance.modRSave(self.registers.operSize, op1, OPCODE_SAVE)
            self.registers.setEFLAG(FLAG_ZF, True)
        elif (operOpcode == 0x05): # LOADALL (286, undocumented)
            self.main.notice("opcodeGroup0F_05: LOADALL 286 opcode isn't supported yet.")
            raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x07): # LOADALL (386, undocumented)
            self.main.notice("opcodeGroup0F_07: LOADALL 386 opcode isn't supported yet.")
            raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode in (0x06, 0x08, 0x09)): # 0x06: CLTS, 0x08: INVD, 0x09: WBINVD
            if (cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            if (operOpcode == 0x06): # CLTS
                self.registers.regAndDword(CPU_REGISTER_CR0, <unsigned int>(~CR0_FLAG_TS))
        elif (operOpcode == 0x0b): # UD2
            raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x20): # MOV R32, CRn
            if (cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_CREG)
            if (self.modRMInstance.regName not in (CPU_REGISTER_CR0, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4)):
                raise ChemuException(CPU_EXCEPTION_UD)
            # We need to 'ignore' mod to read the source/dest as a register. That's the way to do it.
            self.modRMInstance.mod = 3
            self.modRMInstance.modRMSave(OP_SIZE_DWORD, self.modRMInstance.modRLoadUnsigned(OP_SIZE_DWORD), True, OPCODE_SAVE)
        elif (operOpcode == 0x21): # MOV R32, DRn
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_DREG)
            self.modRMInstance.modRMSave(OP_SIZE_DWORD, self.modRMInstance.modRLoadUnsigned(OP_SIZE_DWORD), True, OPCODE_SAVE)
        elif (operOpcode == 0x22): # MOV CRn, R32
            if (cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_CREG)
            if (self.modRMInstance.regName not in (CPU_REGISTER_CR0, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4)):
                raise ChemuException(CPU_EXCEPTION_UD)
            # We need to 'ignore' mod to read the source/dest as a register. That's the way to do it.
            self.modRMInstance.mod = 3
            op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_DWORD, True)
            if (self.modRMInstance.regName == CPU_REGISTER_CR0):
                op1 = self.registers.regReadUnsignedDword(CPU_REGISTER_CR0) # op1 == old CR0
                if (op1 & CR0_FLAG_ET):
                    op2 |= CR0_FLAG_ET
                if ((op2 & CR0_FLAG_PG) and not (op2 & CR0_FLAG_PE)):
                    raise ChemuException(CPU_EXCEPTION_GP, 0)
            elif (self.modRMInstance.regName == CPU_REGISTER_CR4):
                if (op2 & CR4_FLAG_VME):
                    self.main.exitError("opcodeGroup0F_22: VME (virtual-8086 mode extension) IS NOT SUPPORTED yet.")
            self.modRMInstance.modRSave(OP_SIZE_DWORD, op2, OPCODE_SAVE)
            if (self.modRMInstance.regName == CPU_REGISTER_CR3):
                (<Paging>self.registers.segments.paging).invalidateTables(op2)
        elif (operOpcode == 0x23): # MOV DRn, R32
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_DREG)
            self.modRMInstance.modRSave(OP_SIZE_DWORD, self.modRMInstance.modRMLoadUnsigned(OP_SIZE_DWORD, True), OPCODE_SAVE)
        elif (operOpcode == 0x31): # RDTSC
            if (not self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_TSD) or \
              not cpl or not (<Segments>self.registers.segments).isInProtectedMode()):
                self.registers.regWriteDword(CPU_REGISTER_EAX, <unsigned int>(self.main.cpu.cycles&BITMASK_DWORD))
                self.registers.regWriteDword(CPU_REGISTER_EDX, <unsigned int>((self.main.cpu.cycles>>32)&BITMASK_DWORD))
            else:
                raise ChemuException(CPU_EXCEPTION_GP, 0)
        elif (operOpcode == 0x38): # MOVBE
            operOpcodeMod = self.registers.getCurrentOpcodeAddUnsignedByte()
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            if (operOpcodeMod == 0xf0): # MOVBE R16_32, M16_32
                op2 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize, True)
                op2 = (<Misc>self.main.misc).reverseByteOrder(op2, self.registers.operSize)
                self.modRMInstance.modRSave(self.registers.operSize, op2, OPCODE_SAVE)
            elif (operOpcodeMod == 0xf1): # MOVBE M16_32, R16_32
                op2 = self.modRMInstance.modRLoadUnsigned(self.registers.operSize)
                op2 = (<Misc>self.main.misc).reverseByteOrder(op2, self.registers.operSize)
                self.modRMInstance.modRMSave(self.registers.operSize, op2, True, OPCODE_SAVE)
            else:
                self.main.exitError("MOVBE: operOpcodeMod {0:#04x} not in (0xf0, 0xf1)", operOpcodeMod)
        elif (operOpcode >= 0x40 and operOpcode <= 0x4f): # CMOVcc
            self.cmovFunc(self.registers.getCond(operOpcode&0xf))
        elif (operOpcode >= 0x80 and operOpcode <= 0x8f):
            self.jumpShort(self.registers.operSize, self.registers.getCond(operOpcode&0xf))
        elif (operOpcode >= 0x90 and operOpcode <= 0x9f): # SETcc
            self.setWithCondFunc(self.registers.getCond(operOpcode&0xf))
        elif (operOpcode == 0xa0): # PUSH FS
            self.pushSeg(PUSH_FS)
        elif (operOpcode == 0xa1): # POP FS
            self.popSeg(POP_FS)
        elif (operOpcode == 0xa2): # CPUID
            eaxId = self.registers.regReadUnsignedDword(CPU_REGISTER_EAX)
            eaxIsInvalid = (eaxId >= 0x40000000 and eaxId <= 0x4fffffff)
            if (eaxId == 0x1):
                self.registers.regWriteDword(CPU_REGISTER_EAX, 0x400)
                self.registers.regWriteDword(CPU_REGISTER_EBX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_EDX, 0x8110)
                self.registers.regWriteDword(CPU_REGISTER_ECX, 0xc00000)
            elif (eaxId >= 0x2 and eaxId <= 0x5):
                self.registers.regWriteDword(CPU_REGISTER_EAX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_EBX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_EDX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_ECX, 0x0)
            elif (eaxId == 0x80000000):
                self.registers.regWriteDword(CPU_REGISTER_EAX, 0x80000004)
                self.registers.regWriteDword(CPU_REGISTER_EBX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_EDX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_ECX, 0x0)
            elif (eaxId == 0x80000001):
                self.registers.regWriteDword(CPU_REGISTER_EAX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_EBX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_EDX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_ECX, 0x0)
            elif (eaxId == 0x80000002):
                self.registers.regWriteDword(CPU_REGISTER_EAX, 0x20202020)
                self.registers.regWriteDword(CPU_REGISTER_EBX, 0x20202020)
                self.registers.regWriteDword(CPU_REGISTER_ECX, 0x20202020)
                self.registers.regWriteDword(CPU_REGISTER_EDX, 0x6e492020)
            elif (eaxId == 0x80000003):
                self.registers.regWriteDword(CPU_REGISTER_EAX, 0x286c6574)
                self.registers.regWriteDword(CPU_REGISTER_EBX, 0x50202952)
                self.registers.regWriteDword(CPU_REGISTER_ECX, 0x69746e65)
                self.registers.regWriteDword(CPU_REGISTER_EDX, 0x52286d75)
            elif (eaxId == 0x80000004):
                self.registers.regWriteDword(CPU_REGISTER_EAX, 0x20342029)
                self.registers.regWriteDword(CPU_REGISTER_EBX, 0x20555043)
                self.registers.regWriteDword(CPU_REGISTER_ECX, 0x20202020)
                self.registers.regWriteDword(CPU_REGISTER_EDX, 0x00202020)
            else:
                if (not (eaxId == 0x0 or eaxIsInvalid)):
                    self.main.notice("CPUID: eaxId {0:#04x} unknown.", eaxId)
                self.registers.regWriteDword(CPU_REGISTER_EAX, 0x5)
                self.registers.regWriteDword(CPU_REGISTER_EBX, 0x756e6547)
                self.registers.regWriteDword(CPU_REGISTER_EDX, 0x49656e69)
                self.registers.regWriteDword(CPU_REGISTER_ECX, 0x6c65746e)
        elif (operOpcode == 0xa3): # BT RM16/32, R16
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRLoadUnsigned(self.registers.operSize)
            self.btFunc(op2, BT_NONE)
        elif (operOpcode in (0xa4, 0xa5)): # SHLD
            bitMaskHalf = (<Misc>self.main.misc).getBitMask80(self.registers.operSize)
            bitSize = self.registers.operSize << 3
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            if (operOpcode == 0xa4): # SHLD imm8
                count = self.registers.getCurrentOpcodeAddUnsignedByte()
            elif (operOpcode == 0xa5): # SHLD CL
                count = self.registers.regReadUnsignedLowByte(CPU_REGISTER_CL)
                count &= 0x1f
            else:
                self.main.exitError("group0F::SHLD: operOpcode {0:#04x} unknown.", operOpcode)
                return True
            if (not count):
                return True
            if (count > bitSize): # bad parameters
                self.main.exitError("group0F: SHLD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).", count, bitSize, operOpcode)
                return True
            op1 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize, True) # dest
            oldOF = (op1&bitMaskHalf)!=0
            op2  = self.modRMInstance.modRLoadUnsigned(self.registers.operSize) # src
            newCF = self.registers.valGetBit(op1, bitSize-count)
            for i in range(bitSize-1, count-1, -1):
                tmpBit = self.registers.valGetBit(op1, i-count)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            for i in range(count-1, -1, -1):
                tmpBit = self.registers.valGetBit(op2, i-count+bitSize)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            self.modRMInstance.modRMSave(self.registers.operSize, op1, True, OPCODE_SAVE)
            if (count == 1):
                newOF = oldOF!=((op1&bitMaskHalf)!=0)
                self.registers.setEFLAG(FLAG_OF, newOF)
            self.registers.setEFLAG(FLAG_CF, newCF)
            self.registers.setSZP(op1, self.registers.operSize)
        elif (operOpcode == 0xa8): # PUSH GS
            self.pushSeg(PUSH_GS)
        elif (operOpcode == 0xa9): # POP GS
            self.popSeg(POP_GS)
        elif (operOpcode == 0xab): # BTS RM16/32, R16
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRLoadUnsigned(self.registers.operSize)
            self.btFunc(op2, BT_SET)
        elif (operOpcode in (0xac, 0xad)): # SHRD
            bitMaskHalf = (<Misc>self.main.misc).getBitMask80(self.registers.operSize)
            bitSize = self.registers.operSize << 3
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            if (operOpcode == 0xac): # SHRD imm8
                count = self.registers.getCurrentOpcodeAddUnsignedByte()
            elif (operOpcode == 0xad): # SHRD CL
                count = self.registers.regReadUnsignedLowByte(CPU_REGISTER_CL)
                count &= 0x1f
            else:
                self.main.exitError("group0F::SHRD: operOpcode {0:#04x} unknown.", operOpcode)
                return True
            if (not count):
                return True
            if (count > bitSize): # bad parameters
                self.main.exitError("group0F: SHRD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).", count, bitSize, operOpcode)
                return True
            op1 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize, True) # dest
            oldOF = (op1&bitMaskHalf)!=0
            op2  = self.modRMInstance.modRLoadUnsigned(self.registers.operSize) # src
            newCF = self.registers.valGetBit(op1, count-1)
            for i in range(bitSize-count):
                tmpBit = self.registers.valGetBit(op1, i+count)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            for i in range(bitSize-count, bitSize):
                tmpBit = self.registers.valGetBit(op2, i+count-bitSize)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            self.modRMInstance.modRMSave(self.registers.operSize, op1, True, OPCODE_SAVE)
            if (count == 1):
                newOF = oldOF!=((op1&bitMaskHalf)!=0)
                self.registers.setEFLAG(FLAG_OF, newOF)
            self.registers.setEFLAG(FLAG_CF, newCF)
            self.registers.setSZP(op1, self.registers.operSize)
        elif (operOpcode == 0xaf): # IMUL R16_32, R/M16_32
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            sop1 = self.modRMInstance.modRLoadSigned(self.registers.operSize)
            sop2 = self.modRMInstance.modRMLoadSigned(self.registers.operSize, True)
            if (self.registers.operSize == OP_SIZE_WORD):
                sop1 = <signed short>sop1
                sop2 = <signed short>sop2
            op1 = <unsigned int>(sop1*sop2)
            if (self.registers.operSize == OP_SIZE_WORD):
                op1 = <unsigned short>op1
            self.modRMInstance.modRSave(self.registers.operSize, op1, OPCODE_SAVE)
            self.registers.setFullFlags(sop1, sop2, self.registers.operSize, OPCODE_IMUL)
        elif (operOpcode in (0xb0, 0xb1)): # 0xb0: CMPXCHG RM8, R8 ;; 0xb1: CMPXCHG RM16_32, R16_32
            bitSize = self.registers.operSize # bitSize is in bytes (double usage of vars)
            if (operOpcode == 0xb0): # 0xb0: CMPXCHG RM8, R8
                bitSize = OP_SIZE_BYTE
            self.modRMInstance.modRMOperands(bitSize, MODRM_FLAGS_NONE)
            op1 = self.modRMInstance.modRMLoadUnsigned(bitSize, True)
            op2 = self.registers.regReadUnsigned(CPU_REGISTER_AX, bitSize)
            self.registers.setFullFlags(op2, op1, bitSize, OPCODE_SUB)
            if (op2 == op1):
                self.registers.setEFLAG(FLAG_ZF, True)
                op2 = self.modRMInstance.modRLoadUnsigned(bitSize)
                self.modRMInstance.modRMSave(bitSize, op2, True, OPCODE_SAVE)
            else:
                self.registers.setEFLAG(FLAG_ZF, False)
                self.registers.regWrite(CPU_REGISTER_AX, op1, bitSize)
        elif (operOpcode == 0xb2): # LSS
            self.lfpFunc(CPU_SEGMENT_SS)
        elif (operOpcode == 0xb3): # BTR RM16/32, R16
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRLoadUnsigned(self.registers.operSize)
            self.btFunc(op2, BT_RESET)
        elif (operOpcode == 0xb4): # LFS
            self.lfpFunc(CPU_SEGMENT_FS)
        elif (operOpcode == 0xb5): # LGS
            self.lfpFunc(CPU_SEGMENT_GS)
        elif (operOpcode == 0xb8): # POPCNT R16/32 RM16/32
            if (self.registers.repPrefix):
                raise ChemuException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize, True)
            op2 = bin(op2).count('1')
            self.modRMInstance.modRSave(self.registers.operSize, op2, OPCODE_SAVE)
            self.registers.setEFLAG(FLAG_CF | FLAG_PF | FLAG_AF | FLAG_SF | FLAG_OF, False)
            self.registers.setEFLAG(FLAG_ZF, not op2)
        elif (operOpcode == 0xba): # BT/BTS/BTR/BTC RM16/32 IMM8
            operOpcodeMod = self.registers.getCurrentOpcodeUnsignedByte()
            operOpcodeModId = (operOpcodeMod>>3)&7
            self.main.debug("Group0F_BA: operOpcodeModId=={0:d}", operOpcodeModId)
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.registers.getCurrentOpcodeAddUnsignedByte()
            if (operOpcodeModId == 4): # BT
                self.btFunc(op2, BT_NONE)
            elif (operOpcodeModId == 5): # BTS
                self.btFunc(op2, BT_SET)
            elif (operOpcodeModId == 6): # BTR
                self.btFunc(op2, BT_RESET)
            elif (operOpcodeModId == 7): # BTC
                self.btFunc(op2, BT_COMPLEMENT)
            else:
                self.main.notice("opcodeGroup0F_BA: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0xbb): # BTC RM16/32, R16
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRLoadUnsigned(self.registers.operSize)
            self.btFunc(op2, BT_COMPLEMENT)
        elif (operOpcode == 0xbc): # BSF R16_32, R/M16_32
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize, True)
            self.registers.setEFLAG(FLAG_ZF, not op2)
            op1 = 0
            if (op2 > 1):
                op1 = bin(op2)[::-1].find('1')
            self.modRMInstance.modRSave(self.registers.operSize, op1, OPCODE_SAVE)
        elif (operOpcode == 0xbd): # BSR R16_32, R/M16_32
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize, True)
            self.registers.setEFLAG(FLAG_ZF, not op2)
            self.modRMInstance.modRSave(self.registers.operSize, op2.bit_length()-1, OPCODE_SAVE)
        elif (operOpcode in (0xb6, 0xbe)): # 0xb6==MOVZX R16_32, R/M8 ;; 0xbe==MOVSX R16_32, R/M8
            self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
            self.modRMInstance.regName = self.registers.getRegNameWithFlags(MODRM_FLAGS_NONE, \
              self.modRMInstance.reg, self.registers.operSize)
            if (operOpcode == 0xb6): # MOVZX R16_32, R/M8
                op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_BYTE, True)
            else: # MOVSX R16_32, R/M8
                op2 = <unsigned int>(<signed char>self.modRMInstance.modRMLoadSigned(OP_SIZE_BYTE, True))
                if (self.registers.operSize == OP_SIZE_WORD):
                    op2 = <unsigned short>op2
            self.modRMInstance.modRSave(self.registers.operSize, op2, OPCODE_SAVE)
        elif (operOpcode in (0xb7, 0xbf)): # 0xb7==MOVZX R32, R/M16 ;; 0xbf==MOVSX R32, R/M16
            self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            self.modRMInstance.regName = self.registers.getRegNameWithFlags(MODRM_FLAGS_NONE, \
              self.modRMInstance.reg, OP_SIZE_DWORD)
            if (operOpcode == 0xb7): # MOVZX R32, R/M16
                op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD, True)
            else: # MOVSX R32, R/M16
                op2 = <unsigned int>(self.modRMInstance.modRMLoadSigned(OP_SIZE_WORD, True))
            self.modRMInstance.modRSave(OP_SIZE_DWORD, op2, OPCODE_SAVE)
        elif (operOpcode in (0xc0, 0xc1)): # 0xc0: XADD RM8, R8 ;; 0xc1: XADD RM16_32, R16_32
            bitSize = self.registers.operSize # bitSize is in bytes (double usage of vars)
            if (operOpcode == 0xc0): # 0xc0: XADD RM8, R8
                bitSize = OP_SIZE_BYTE
            self.modRMInstance.modRMOperands(bitSize, MODRM_FLAGS_NONE)
            op1 = self.modRMInstance.modRMLoadUnsigned(bitSize, True)
            op2 = self.modRMInstance.modRLoadUnsigned(bitSize)
            self.modRMInstance.modRMSave(bitSize, op2, True, OPCODE_ADD)
            self.modRMInstance.modRSave(bitSize, op1, OPCODE_SAVE)
            self.registers.setFullFlags(op1, op2, bitSize, OPCODE_ADD)
        elif (operOpcode == 0xc7): # CMPXCHG8B M64
            operOpcodeMod = self.registers.getCurrentOpcodeAddUnsignedByte()
            operOpcodeModId = (operOpcodeMod>>3)&7
            self.main.debug("Group0F_C7: operOpcodeModId=={0:d}", operOpcodeModId)
            if (operOpcodeModId == 1):
                op1 = self.registers.getCurrentOpcodeAddUnsigned(self.registers.addrSize)
                qop1 = (<Mm>self.main.mm).mmPhyReadValueUnsignedQword(op1)
                qop2 = self.registers.regReadUnsignedDword(CPU_REGISTER_EDX)
                qop2 <<= 32
                qop2 |= self.registers.regReadUnsignedDword(CPU_REGISTER_EAX)
                if (qop2 == qop1):
                    self.registers.setEFLAG(FLAG_ZF, True)
                    qop2 = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
                    qop2 <<= 32
                    qop2 |= self.registers.regReadUnsignedDword(CPU_REGISTER_EBX)
                    (<Mm>self.main.mm).mmPhyWriteValueQword(op1, qop2)
                else:
                    self.registers.setEFLAG(FLAG_ZF, False)
                    self.registers.regWriteDword(CPU_REGISTER_EDX, qop1>>32)
                    self.registers.regWriteDword(CPU_REGISTER_EAX, <unsigned int>qop1)
            else:
                self.main.notice("opcodeGroup0F_C7: operOpcodeModId {0:d} isn't supported yet.", operOpcodeModId)
                raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode >= 0xc8 and operOpcode <= 0xcf): # BSWAP R32
            regName  = operOpcode&7
            op1 = self.registers.regReadUnsignedDword(regName)
            op1 = (<Misc>self.main.misc).reverseByteOrder(op1, OP_SIZE_DWORD)
            self.registers.regWriteDword(regName, op1)
        else:
            self.main.notice("opcodeGroup0F: invalid operOpcode. {0:#04x}", operOpcode)
            return False
        return True
    cdef int opcodeGroupFE(self):
        cdef unsigned char operOpcode, operOpcodeId
        operOpcode = self.registers.getCurrentOpcodeUnsignedByte()
        operOpcodeId = (operOpcode>>3)&7
        self.main.debug("GroupFE: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
        if (operOpcodeId == 0): # 0/INC
            return self.incFuncRM(OP_SIZE_BYTE)
        elif (operOpcodeId == 1): # 1/DEC
            return self.decFuncRM(OP_SIZE_BYTE)
        else:
            self.main.notice("opcodeGroupFE: invalid operOpcodeId. {0:d}", operOpcodeId)
            return False
        #return True
    cdef int opcodeGroupFF(self):
        cdef unsigned char operOpcode, operOpcodeId
        cdef unsigned short segVal
        cdef unsigned int op1
        operOpcode = self.registers.getCurrentOpcodeUnsignedByte()
        operOpcodeId = (operOpcode>>3)&7
        self.main.debug("GroupFF: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        if (operOpcodeId == 0): # 0/INC
            return self.incFuncRM(self.registers.operSize)
        elif (operOpcodeId == 1): # 1/DEC
            return self.decFuncRM(self.registers.operSize)
        elif (operOpcodeId == 2): # 2/CALL NEAR
            op1 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize, True)
            self.stackPushRegId(CPU_REGISTER_EIP, self.registers.operSize)
            self.registers.regWriteDword(CPU_REGISTER_EIP, op1)
        elif (operOpcodeId == 3): # 3/CALL FAR
            op1 = self.modRMInstance.getRMValueFull(self.registers.addrSize)
            segVal = self.registers.mmReadValueUnsignedWord(op1+self.registers.operSize, self.modRMInstance.rmNameSegId, True)
            op1 = self.registers.mmReadValueUnsigned(op1, self.registers.operSize, self.modRMInstance.rmNameSegId, True)
            self.jumpFarDirect(OPCODE_CALL, segVal, op1)
        elif (operOpcodeId == 4): # 4/JMP NEAR
            op1 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize, True)
            self.registers.regWriteDword(CPU_REGISTER_EIP, op1)
        elif (operOpcodeId == 5): # 5/JMP FAR
            op1 = self.modRMInstance.getRMValueFull(self.registers.addrSize)
            segVal = self.registers.mmReadValueUnsignedWord(op1+self.registers.operSize, self.modRMInstance.rmNameSegId, True)
            op1 = self.registers.mmReadValueUnsigned(op1, self.registers.operSize, self.modRMInstance.rmNameSegId, True)
            return self.jumpFarDirect(OPCODE_JUMP, segVal, op1)
        elif (operOpcodeId == 6): # 6/PUSH
            op1 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize, True)
            return self.stackPushValue(op1, self.registers.operSize)
        else:
            self.main.notice("opcodeGroupFF: invalid operOpcodeId. {0:d}", operOpcodeId)
            return False
        return True
    cdef int incFuncReg(self, unsigned short regId, unsigned char regSize):
        cdef unsigned char origCF
        cdef unsigned int origValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        origValue = self.registers.regReadUnsigned(regId, regSize)
        self.registers.regWrite(regId, <unsigned int>(origValue+1), regSize)
        self.registers.setFullFlags(origValue, 1, regSize, OPCODE_ADD)
        self.registers.setEFLAG(FLAG_CF, origCF)
        return True
    cdef int decFuncReg(self, unsigned short regId, unsigned char regSize):
        cdef unsigned char origCF
        cdef unsigned int origValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        origValue = self.registers.regReadUnsigned(regId, regSize)
        self.registers.regWrite(regId, <unsigned int>(origValue-1), regSize)
        self.registers.setFullFlags(origValue, 1, regSize, OPCODE_SUB)
        self.registers.setEFLAG(FLAG_CF, origCF)
        return True
    cdef int incFuncRM(self, unsigned char rmSize):
        cdef unsigned char origCF
        cdef unsigned int origValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        origValue = self.modRMInstance.modRMLoadUnsigned(rmSize, True)
        self.modRMInstance.modRMSave(rmSize, <unsigned int>(origValue+1), True, OPCODE_SAVE)
        self.registers.setFullFlags(origValue, 1, rmSize, OPCODE_ADD)
        self.registers.setEFLAG(FLAG_CF, origCF)
        return True
    cdef int decFuncRM(self, unsigned char rmSize):
        cdef unsigned char origCF
        cdef unsigned int origValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        origValue = self.modRMInstance.modRMLoadUnsigned(rmSize, True)
        self.modRMInstance.modRMSave(rmSize, <unsigned int>(origValue-1), True, OPCODE_SAVE)
        self.registers.setFullFlags(origValue, 1, rmSize, OPCODE_SUB)
        self.registers.setEFLAG(FLAG_CF, origCF)
        return True
    cdef int incReg(self):
        cdef unsigned short regName
        regName  = self.main.cpu.opcode&7
        return self.incFuncReg(regName, self.registers.operSize)
    cdef int decReg(self):
        cdef unsigned short regName
        regName  = self.main.cpu.opcode&7
        return self.decFuncReg(regName, self.registers.operSize)
    cdef int pushReg(self):
        cdef unsigned short regName
        regName  = self.main.cpu.opcode&7
        return self.stackPushRegId(regName, self.registers.operSize)
    cdef int popReg(self):
        cdef unsigned short regName
        regName  = self.main.cpu.opcode&7
        return self.stackPopRegId(regName, self.registers.operSize)
    cdef int pushSeg(self, unsigned char opcode):
        cdef unsigned short segName
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
            return False
        return self.stackPushSegId(segName, self.registers.operSize)
    cdef int popSeg(self, unsigned char opcode):
        cdef unsigned short segName
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
            return False
        return self.stackPopSegId(segName)
    cdef int popRM16_32(self):
        cdef unsigned char operOpcode, operOpcodeId
        cdef unsigned int value
        operOpcode = self.registers.getCurrentOpcodeUnsignedByte()
        operOpcodeId = (operOpcode>>3)&7
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        if (operOpcodeId == 0): # POP
            value = self.stackPopValue(True)
            self.modRMInstance.modRMSave(self.registers.operSize, value, True, OPCODE_SAVE)
        else:
            self.main.notice("popRM16_32: unknown operOpcodeId: {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
        return True
    cdef int lea(self):
        cdef unsigned int mmAddr
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        if (self.modRMInstance.mod == 3):
            raise ChemuException(CPU_EXCEPTION_UD)
        mmAddr = self.modRMInstance.getRMValueFull(self.registers.operSize)
        self.modRMInstance.modRSave(self.registers.operSize, mmAddr, OPCODE_SAVE)
        return True
    cdef int retNear(self, unsigned short imm):
        cdef unsigned char stackAddrSize
        cdef unsigned int tempEIP
        tempEIP = self.stackPopValue(True)
        self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
        if (imm):
            stackAddrSize = self.registers.getAddrSegSize(CPU_SEGMENT_SS)
            self.registers.regAdd(CPU_REGISTER_SP, imm, stackAddrSize)
        return True
    cdef int retNearImm(self):
        cdef unsigned short imm
        imm = self.registers.getCurrentOpcodeAddUnsignedWord() # imm16
        return self.retNear(imm)
    cdef int retFar(self, unsigned short imm):
        cdef unsigned char stackAddrSize
        self.syncCR0State()
        self.stackPopRegId(CPU_REGISTER_EIP, OP_SIZE_DWORD)
        self.stackPopSegId(CPU_SEGMENT_CS)
        if (imm):
            stackAddrSize = self.registers.getAddrSegSize(CPU_SEGMENT_SS)
            self.registers.regAdd(CPU_REGISTER_SP, imm, stackAddrSize)
        return True
    cdef int retFarImm(self):
        cdef unsigned short imm
        imm = self.registers.getCurrentOpcodeAddUnsignedWord() # imm16
        return self.retFar(imm)
    cdef int lfpFunc(self, unsigned short segId): # 'load far pointer' function
        cdef unsigned short segmentAddr
        cdef unsigned int mmAddr, offsetAddr
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        if (self.modRMInstance.mod == 3):
            raise ChemuException(CPU_EXCEPTION_UD)
        mmAddr = self.modRMInstance.getRMValueFull(self.registers.addrSize)
        offsetAddr = self.registers.mmReadValueUnsigned(mmAddr, self.registers.operSize, self.modRMInstance.rmNameSegId, True)
        segmentAddr = self.registers.mmReadValueUnsignedWord(mmAddr+self.registers.operSize, self.modRMInstance.rmNameSegId, True)
        self.modRMInstance.modRSave(self.registers.operSize, offsetAddr, OPCODE_SAVE)
        self.registers.segWrite(segId, segmentAddr)
        return True
    cdef int xlatb(self):
        cdef unsigned char data
        cdef unsigned int baseValue
        baseValue = self.registers.regReadUnsigned(CPU_REGISTER_BX, self.registers.addrSize)
        data = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        data = self.registers.mmReadValueUnsignedByte(<unsigned int>(baseValue+data), CPU_SEGMENT_DS, True)
        self.registers.regWriteLowByte(CPU_REGISTER_AL, data)
        return True
    cdef int opcodeGroup2_RM(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId, operSizeInBits
        cdef unsigned int operOp2, bitMaskHalf, bitMask
        cdef unsigned long int utemp, operOp1, operSum, doubleBitMask, doubleBitMaskHalf
        cdef signed int sop2
        cdef signed long int sop1, temp, tempmod
        operOpcode = self.registers.getCurrentOpcodeUnsignedByte()
        operOpcodeId = (operOpcode>>3)&7
        self.main.debug("Group2_RM: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp2 = self.modRMInstance.modRMLoadUnsigned(operSize, True)
        operSizeInBits = operSize << 3
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        if (operOpcodeId in (GROUP2_OP_TEST, GROUP2_OP_TEST_ALIAS)):
            operOp1 = self.registers.getCurrentOpcodeAddUnsigned(operSize)
            operOp2 = operOp2&operOp1
            self.registers.setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP2_OP_NEG):
            self.modRMInstance.modRMSave(operSize, operOp2, True, OPCODE_NEG)
            self.registers.setFullFlags(0, operOp2, operSize, OPCODE_SUB)
            self.registers.setEFLAG(FLAG_CF, operOp2!=0)
        elif (operOpcodeId == GROUP2_OP_NOT):
            self.modRMInstance.modRMSave(operSize, operOp2, True, OPCODE_NOT)
        elif (operOpcodeId == GROUP2_OP_MUL):
            if (operSize == OP_SIZE_BYTE):
                operOp1 = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
                self.registers.regWriteWord(CPU_REGISTER_AX, <unsigned short>((<unsigned char>operOp1)*operOp2))
                self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_MUL)
                return True
            operOp1 = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
            operSum = <unsigned long int>(operOp1*operOp2)
            if (operSize == OP_SIZE_WORD):
                operSum = <unsigned int>operSum
            self.registers.regWrite(CPU_REGISTER_DX, <unsigned int>(operSum>>operSizeInBits), operSize)
            if (operSize == OP_SIZE_WORD):
                operSum = <unsigned short>operSum
            elif (operSize == OP_SIZE_DWORD):
                operSum = <unsigned int>operSum
            self.registers.regWrite(CPU_REGISTER_AX, operSum, operSize)
            self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_MUL)
        elif (operOpcodeId == GROUP2_OP_IMUL):
            operOp1 = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
            if (operSize == OP_SIZE_BYTE):
                operSum = <unsigned short>((<signed char>operOp1)*(<signed char>operOp2))
                self.registers.regWriteWord(CPU_REGISTER_AX, operSum)
                self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_IMUL)
                self.registers.setEFLAG(FLAG_CF | FLAG_OF, (<signed char>operSum)!=(<signed short>operSum))
                return True
            if (operSize == OP_SIZE_WORD):
                operSum = <unsigned int>(<signed short>operOp1*<signed short>operOp2)
                self.registers.regWrite(CPU_REGISTER_AX, <unsigned short>operSum, operSize)
                self.registers.regWrite(CPU_REGISTER_DX, <unsigned short>(operSum>>operSizeInBits), operSize)
            elif (operSize == OP_SIZE_DWORD):
                operSum = <unsigned int>(<signed int>operOp1*<signed int>operOp2)
                utemp = (operOp1*operOp2)>>operSizeInBits
                self.registers.regWrite(CPU_REGISTER_AX, operSum, operSize)
                self.registers.regWrite(CPU_REGISTER_DX, utemp, operSize)
            self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_IMUL)
            if (operSize == OP_SIZE_WORD):
                self.registers.setEFLAG(FLAG_CF | FLAG_OF, (<signed short>operSum)!=(<signed int>operSum))
            elif (operSize == OP_SIZE_DWORD):
                self.registers.setEFLAG(FLAG_CF | FLAG_OF, utemp!=0)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_DIV):
            op1Word = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
            if (not operOp2):
                raise ChemuException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(op1Word, operOp2)
            if (temp != temp&bitMask):
                raise ChemuException(CPU_EXCEPTION_DE)
            self.registers.regWriteLowByte(CPU_REGISTER_AL, <unsigned char>temp)
            self.registers.regWriteHighByte(CPU_REGISTER_AH, <unsigned char>tempmod)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_IDIV):
            sop1  = self.registers.regReadSignedWord(CPU_REGISTER_AX)
            sop2  = self.modRMInstance.modRMLoadSigned(operSize, True)
            if (sop1 == 0x8000):
                raise ChemuException(CPU_EXCEPTION_DE)
            operOp2 = abs(sop2)
            if (not operOp2):
                raise ChemuException(CPU_EXCEPTION_DE)
            elif (sop1 >= 0):
                temp, tempmod = divmod(sop1, operOp2)
                if (sop2 != operOp2):
                    temp = -temp
            else:
                temp, tempmod = divmod(sop1, sop2)
            if (<signed short>temp != <signed char>temp):
                raise ChemuException(CPU_EXCEPTION_DE)
            self.registers.regWriteLowByte(CPU_REGISTER_AL, <unsigned char>temp)
            self.registers.regWriteHighByte(CPU_REGISTER_AH, <unsigned char>tempmod)
        elif (operOpcodeId == GROUP2_OP_DIV):
            operOp1  = self.registers.regReadUnsigned(CPU_REGISTER_DX, operSize)<<operSizeInBits
            operOp1 |= self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
            if (not operOp2):
                raise ChemuException(CPU_EXCEPTION_DE)
            utemp, tempmod = divmod(operOp1, operOp2)
            if (utemp != utemp&bitMask):
                raise ChemuException(CPU_EXCEPTION_DE)
            if (operSize == OP_SIZE_WORD):
                utemp = <unsigned short>utemp
                tempmod = <unsigned short>tempmod
            else:
                utemp = <unsigned int>utemp
                tempmod = <unsigned int>tempmod
            self.registers.regWrite(CPU_REGISTER_AX, utemp, operSize)
            self.registers.regWrite(CPU_REGISTER_DX, tempmod, operSize)
        elif (operOpcodeId == GROUP2_OP_IDIV):
            bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
            doubleBitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize<<1)
            operOp1 = self.registers.regReadUnsigned(CPU_REGISTER_DX, operSize)<<operSizeInBits
            operOp1 |= self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
            if (operOp1 == doubleBitMaskHalf):
                raise ChemuException(CPU_EXCEPTION_DE)
            if (operOp1 & doubleBitMaskHalf):
                sop1 = operOp1-doubleBitMaskHalf
                sop1 -= doubleBitMaskHalf
            else:
                sop1 = operOp1
            sop2 = self.modRMInstance.modRMLoadSigned(operSize, True)
            operOp2 = abs(sop2)
            if (not operOp2):
                raise ChemuException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(sop1, sop2)
            if (((temp >= <unsigned int>bitMaskHalf) or (temp < -(<signed long int>bitMaskHalf)))):
                raise ChemuException(CPU_EXCEPTION_DE)
            if (operSize == OP_SIZE_WORD):
                temp = <unsigned short>temp
                tempmod = <unsigned short>tempmod
            else:
                temp = <unsigned int>temp
                tempmod = <unsigned int>tempmod
            self.registers.regWrite(CPU_REGISTER_AX, temp, operSize)
            self.registers.regWrite(CPU_REGISTER_DX, tempmod, operSize)
        else:
            self.main.notice("opcodeGroup2_RM: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
        return True
    cpdef interrupt(self, signed short intNum, signed int errorCode): # TODO: complete this!
        cdef unsigned char inProtectedMode, entryType, entrySize, \
                              entryNeededDPL, entryPresent, cpl, isSoftInt
        cdef unsigned short entrySegment
        cdef unsigned int entryEip, eflagsClearThis
        cdef IdtEntry idtEntry
        isSoftInt = False
        entryType, entrySize, entryPresent, eflagsClearThis = TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE, \
          OP_SIZE_WORD, True, (FLAG_TF | FLAG_RF)
        inProtectedMode = (<Segments>self.registers.segments).isInProtectedMode()
        if (inProtectedMode):
            eflagsClearThis |= (FLAG_NT | FLAG_VM)
        else:
            eflagsClearThis |= FLAG_AC
        if (intNum == -1):
            isSoftInt = True
            intNum = self.registers.getCurrentOpcodeAddUnsignedByte()
        if (inProtectedMode):
            idtEntry = (<IdtEntry>(<Idt>(<Segments>self.registers.segments).idt).getEntry(intNum))
            entrySegment = idtEntry.entrySegment
            entryEip = idtEntry.entryEip
            entryType = idtEntry.entryType
            entryNeededDPL = idtEntry.entryNeededDPL
            entryPresent = idtEntry.entryPresent
            entrySize = idtEntry.entrySize
            if (entryType == TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE):
                self.main.exitError("Opcodes::interrupt: task-gates aren't implemented yet.")
                return True
            elif (entryType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE, \
              TABLE_ENTRY_SYSTEM_TYPE_16BIT_TRAP_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE,\
              TABLE_ENTRY_SYSTEM_TYPE_32BIT_TRAP_GATE)):
                self.main.exitError("Opcodes::interrupt: unknown entryType {0:d}.", entryType)
                return True
        else:
            (<Idt>(<Segments>self.registers.segments).idt).getEntryRealMode(intNum, &entrySegment, <unsigned short*>&entryEip)
            if (isSoftInt and ((entrySegment == 0xf000 and intNum != 0x10) or (entrySegment == 0xc000 and intNum == 0x10)) and \
              self.main.platform.pythonBios.interrupt(intNum)):
                return True
        self.main.debug("Opcodes::interrupt: Go Interrupt {0:#04x}. CS: {1:#06x}, (E)IP: {2:#06x}, AX: {3:#06x}", intNum, entrySegment, entryEip, self.registers.regReadUnsignedWord(CPU_REGISTER_AX))
        if (inProtectedMode):
            cpl = self.registers.getCPL()
            if ((cpl and cpl > entrySegment&3) or (<Segments>self.registers.segments).getSegDPL(entrySegment)):
                self.main.exitError("Opcodes::interrupt: (cpl!=0 and cpl>rpl) or dpl!=0")
                return True
            elif (cpl&3 != entrySegment&3): # FIXME
                self.main.exitError("Opcodes::interrupt: cpl&3 != entrySegment&3. What to do here???")
                return True
                #self.stackPushSegId(CPU_SEGMENT_SS, entrySize)
                #self.stackPushRegId(CPU_REGISTER_ESP, entrySize)
            entrySegment &= 0xfffc
            entrySegment |= cpl
        if (entryType in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE)):
            eflagsClearThis |= FLAG_IF
        self.stackPushRegId(CPU_REGISTER_EFLAGS, entrySize)
        self.registers.setEFLAG(eflagsClearThis, False)
        self.stackPushSegId(CPU_SEGMENT_CS, entrySize)
        self.stackPushRegId(CPU_REGISTER_EIP, entrySize)
        self.registers.segWrite(CPU_SEGMENT_CS, entrySegment)
        self.registers.regWriteDword(CPU_REGISTER_EIP, entryEip)
        if (inProtectedMode and errorCode != -1):
            self.stackPushValue(errorCode, entrySize)
        return True
    cpdef into(self):
        if (self.registers.getEFLAG(FLAG_OF)):
            raise ChemuException(CPU_EXCEPTION_OF)
        return True
    cpdef int3(self):
        raise ChemuException(CPU_EXCEPTION_BP)
    cpdef iret(self):
        cdef GdtEntry gdtEntry
        cdef unsigned char inProtectedMode, cpl
        cdef unsigned int tempEFLAGS, tempEIP, tempCS, eflagsMask
        inProtectedMode = (<Segments>self.registers.segments).isInProtectedMode()
        tempEIP = self.stackPopValue(False) # this is here because esp should stay on
                                            # it's original value in case of an exception.
        if (not inProtectedMode and self.registers.operSize == OP_SIZE_DWORD and (tempEIP>>16)):
            raise ChemuException(CPU_EXCEPTION_GP, 0)
        tempEIP = self.stackPopValue(True)
        tempCS = self.stackPopValue(True)
        tempEFLAGS = self.stackPopValue(True)
        if (inProtectedMode):
            if (tempEFLAGS & (FLAG_NT | FLAG_VM)):
                self.main.exitError("Opcodes::iret: VM86-Mode isn't supported yet.")
                return True
            if (not (tempCS&0xfff8)):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            if ((tempCS&0xfff8) > (<Gdt>self.registers.segments.gdt).tableLimit):
                raise ChemuException(CPU_EXCEPTION_GP, tempCS)
            cpl = self.registers.getCPL()
            gdtEntry = (<GdtEntry>(<Gdt>self.registers.segments.gdt).getEntry(tempCS))
            if (not gdtEntry.segIsCodeSeg or ((tempCS&3) < cpl) or (gdtEntry.segIsConforming and \
              (gdtEntry.segDPL > (tempCS&3)))):
                raise ChemuException(CPU_EXCEPTION_GP, tempCS)
            if (not gdtEntry.segPresent):
                raise ChemuException(CPU_EXCEPTION_NP, tempCS)
            if ((tempCS&3) > cpl): # outer privilege level
                self.main.exitError("Opcodes::iret: rpl > cpl. What to do here???")
                return True
            else: # same privilege level; rpl==cpl
                if (not gdtEntry.isAddressInLimit(tempEIP, OP_SIZE_BYTE)):
                    raise ChemuException(CPU_EXCEPTION_GP, 0)
                self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
                self.registers.segWrite(CPU_SEGMENT_CS, tempCS)
                eflagsMask = FLAG_CF | FLAG_PF | FLAG_AF | FLAG_ZF | FLAG_SF | \
                             FLAG_TF | FLAG_DF | FLAG_OF | FLAG_NT
                if (self.registers.operSize in (OP_SIZE_DWORD, OP_SIZE_QWORD)):
                    eflagsMask |= FLAG_RF | FLAG_AC | FLAG_ID
                if (cpl < self.registers.getIOPL()):
                    eflagsMask |= FLAG_IF
                if (not cpl):
                    eflagsMask |= FLAG_IOPL
                    if (self.registers.operSize in (OP_SIZE_DWORD, OP_SIZE_QWORD)):
                        eflagsMask |= FLAG_VIF | FLAG_VIP
                tempEFLAGS &= eflagsMask
                tempEFLAGS |= FLAG_REQUIRED
                self.registers.regWriteDword(CPU_REGISTER_EFLAGS, tempEFLAGS)
        else:
            if (self.registers.operSize == OP_SIZE_DWORD):
                tempEFLAGS = (tempEFLAGS & 0x257fd5)
                tempEFLAGS |= self.registers.regReadUnsignedDword(CPU_REGISTER_EFLAGS)&0x1a0000
                tempEFLAGS |= FLAG_REQUIRED
                self.registers.regWriteDword(CPU_REGISTER_EFLAGS, tempEFLAGS)
            else:
                tempEFLAGS |= FLAG_REQUIRED
                self.registers.regWriteWord(CPU_REGISTER_FLAGS, (<unsigned short>tempEFLAGS))
            self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
            self.registers.segWrite(CPU_SEGMENT_CS, tempCS)
        return True
    cdef int aad(self):
        cdef unsigned char imm8, tempAL, tempAH
        imm8 = self.registers.getCurrentOpcodeAddUnsignedByte()
        tempAL = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        tempAH = self.registers.regReadUnsignedHighByte(CPU_REGISTER_AH)
        tempAL = <unsigned char>(self.registers.regWriteWord(CPU_REGISTER_AX, <unsigned char>(tempAL + (tempAH * imm8))))
        self.registers.setSZP_C0_O0_A0(tempAL, OP_SIZE_BYTE)
        return True
    cdef int aam(self):
        cdef unsigned char imm8, tempAL, ALdiv, ALmod
        imm8 = self.registers.getCurrentOpcodeAddUnsignedByte()
        if (not imm8):
            raise ChemuException(CPU_EXCEPTION_DE)
        tempAL = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        ALdiv, ALmod = divmod(tempAL, imm8)
        self.registers.regWriteHighByte(CPU_REGISTER_AH, ALdiv)
        self.registers.regWriteLowByte(CPU_REGISTER_AL, ALmod)
        self.registers.setSZP_C0_O0_A0(ALmod, OP_SIZE_BYTE)
        return True
    cdef int aaa(self):
        cdef unsigned char AFflag, tempAL, tempAH
        cdef unsigned short tempAX
        tempAX = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
        tempAL = <unsigned char>tempAX
        tempAH = (tempAX>>8)
        AFflag = self.registers.getEFLAG(FLAG_AF)!=0
        if (((tempAL&0xf)>9) or AFflag):
            tempAL += 6
            self.registers.setEFLAG(FLAG_AF | FLAG_CF, True)
            self.registers.regAddHighByte(CPU_REGISTER_AH, 1)
            self.registers.regWriteLowByte(CPU_REGISTER_AL, tempAL&0xf)
        else:
            self.registers.setEFLAG(FLAG_AF | FLAG_CF, False)
            self.registers.regWriteLowByte(CPU_REGISTER_AL, tempAL&0xf)
        self.registers.setSZP_O0(self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL), OP_SIZE_BYTE)
        return True
    cdef int aas(self):
        cdef unsigned char AFflag, tempAL, tempAH
        cdef unsigned short tempAX
        tempAX = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
        tempAL = <unsigned char>tempAX
        tempAH = (tempAX>>8)
        AFflag = self.registers.getEFLAG(FLAG_AF)!=0
        if (((tempAL&0xf)>9) or AFflag):
            tempAL -= 6
            self.registers.setEFLAG(FLAG_AF | FLAG_CF, True)
            self.registers.regSubHighByte(CPU_REGISTER_AH, 1)
            self.registers.regWriteLowByte(CPU_REGISTER_AL, tempAL&0xf)
        else:
            self.registers.setEFLAG(FLAG_AF | FLAG_CF, False)
            self.registers.regWriteLowByte(CPU_REGISTER_AL, tempAL&0xf)
        self.registers.setSZP_O0(self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL), OP_SIZE_BYTE)
        return True
    cdef int daa(self):
        cdef unsigned char old_AL, old_AF, old_CF
        old_AL = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        old_AF = self.registers.getEFLAG(FLAG_AF)!=0
        old_CF = self.registers.getEFLAG(FLAG_CF)
        self.clc()
        if (((old_AL&0xf)>9) or old_AF):
            self.registers.regAddLowByte(CPU_REGISTER_AL, 0x6)
            self.registers.setEFLAG(FLAG_CF, old_CF or (old_AL+6>BITMASK_BYTE))
            self.registers.setEFLAG(FLAG_AF, True)
        else:
            self.registers.setEFLAG(FLAG_AF, False)
        if ((old_AL > 0x99) or old_CF):
            self.registers.regAddLowByte(CPU_REGISTER_AL, 0x60)
            self.stc()
        else:
            self.clc()
        self.registers.setSZP_O0(self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL), OP_SIZE_BYTE)
        return True
    cdef int das(self):
        cdef unsigned char old_AL, old_AF, old_CF
        old_AL = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        old_AF = self.registers.getEFLAG(FLAG_AF)!=0
        old_CF = self.registers.getEFLAG(FLAG_CF)
        self.clc()
        if (((old_AL&0xf)>9) or old_AF):
            self.registers.regSubLowByte(CPU_REGISTER_AL, 6)
            self.registers.setEFLAG(FLAG_CF, old_CF or (old_AL-6<0))
            self.registers.setEFLAG(FLAG_AF, True)
        else:
            self.registers.setEFLAG(FLAG_AF, False)
        if ((old_AL > 0x99) or old_CF):
            self.registers.regSubLowByte(CPU_REGISTER_AL, 0x60)
            self.stc()
        self.registers.setSZP_O0(self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL), OP_SIZE_BYTE)
        return True
    cdef int cbw_cwde(self):
        cdef unsigned int op2
        if (self.registers.operSize == OP_SIZE_WORD): # CBW
            op2 = <unsigned short>(self.registers.regReadSignedLowByte(CPU_REGISTER_AL))
            self.registers.regWriteWord(CPU_REGISTER_AX, op2)
        elif (self.registers.operSize == OP_SIZE_DWORD): # CWDE
            op2 = <unsigned int>(self.registers.regReadSignedWord(CPU_REGISTER_AX))
            self.registers.regWriteDword(CPU_REGISTER_EAX, op2)
        return True
    cdef int cwd_cdq(self):
        cdef unsigned int bitMask, bitMaskHalf, op2
        bitMask = (<Misc>self.main.misc).getBitMaskFF(self.registers.operSize)
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(self.registers.operSize)
        op2 = self.registers.regReadUnsigned(CPU_REGISTER_AX, self.registers.operSize)
        if (op2&bitMaskHalf):
            self.registers.regWrite(CPU_REGISTER_DX, bitMask, self.registers.operSize)
        else:
            self.registers.regWrite(CPU_REGISTER_DX, 0, self.registers.operSize)
        return True
    cdef int shlFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char newCF, newOF
        cdef unsigned int bitMaskHalf, dest
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoadUnsigned(operSize, True)
        count = count&0x1f
        if (not count):
            return True
        newCF = ((dest<<(count-1))&bitMaskHalf)!=0
        dest = <unsigned int>(dest<<count)
        if (operSize == OP_SIZE_WORD):
            dest = <unsigned short>dest
        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        newOF = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.setEFLAG(FLAG_OF, newOF)
        self.registers.setEFLAG(FLAG_CF, newCF)
        self.registers.setEFLAG(FLAG_AF, False)
        self.registers.setSZP(dest, operSize)
        return True
    cdef int sarFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char newCF
        cdef unsigned int bitMask
        cdef signed int dest
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        dest = self.modRMInstance.modRMLoadSigned(operSize, True)
        count = count&0x1f
        if (not count):
            return True
        newCF = ((dest>>(count-1))&1)
        dest >>= count
        self.modRMInstance.modRMSave(operSize, dest&bitMask, True, OPCODE_SAVE)
        self.registers.setSZP_C0_O0_A0(dest&bitMask, operSize)
        self.registers.setEFLAG(FLAG_CF, newCF)
        return True
    cdef int shrFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char newCF_OF
        cdef unsigned int bitMaskHalf, dest, tempDest
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoadUnsigned(operSize, True)
        tempDest = dest
        count = count&0x1f
        if (not count):
            return True
        newCF_OF = ((dest>>(count-1))&1)
        dest >>= count
        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        self.registers.setEFLAG(FLAG_CF, newCF_OF)
        newCF_OF = ((tempDest)&bitMaskHalf)!=0
        self.registers.setEFLAG(FLAG_OF, newCF_OF)
        self.registers.setEFLAG(FLAG_AF, False)
        self.registers.setSZP(dest, operSize)
        return True
    cdef int rclFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char tempCF_OF, newCF, i
        cdef unsigned int bitMaskHalf, dest
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoadUnsigned(operSize, True)
        count = count&0x1f
        if (operSize == OP_SIZE_BYTE):
            count %= 9
        elif (operSize == OP_SIZE_WORD):
            count %= 17
        if (not count):
            return True
        newCF = self.registers.getEFLAG(FLAG_CF)
        for i in range(count):
            tempCF_OF = (dest&bitMaskHalf)!=0
            dest = <unsigned int>((dest<<1)|newCF)
            if (operSize == OP_SIZE_WORD):
                dest = <unsigned short>dest
            newCF = tempCF_OF
        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.setEFLAG(FLAG_CF, newCF)
        self.registers.setEFLAG(FLAG_OF, tempCF_OF)
        return True
    cdef int rcrFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char tempCF_OF, newCF, i
        cdef unsigned int bitMaskHalf, dest
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoadUnsigned(operSize, True)
        count = count&0x1f
        newCF = self.registers.getEFLAG(FLAG_CF)
        if (operSize == OP_SIZE_BYTE):
            count %= 9
        elif (operSize == OP_SIZE_WORD):
            count %= 17
        if (not count):
            return True
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.setEFLAG(FLAG_OF, tempCF_OF)
        for i in range(count):
            tempCF_OF = (dest&1)
            dest = (dest >> 1) | (newCF * bitMaskHalf)
            newCF = tempCF_OF
        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        self.registers.setEFLAG(FLAG_CF, newCF)
        return True
    cdef int rolFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char tempCF_OF, newCF, i
        cdef unsigned int bitMaskHalf, dest
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoadUnsigned(operSize, True)
        count &= 0x1f
        count = count&((operSize<<3)-1)
        if (not count):
            return True
        for i in range(count):
            tempCF_OF = (dest&bitMaskHalf)!=0
            dest = <unsigned int>((dest << 1) | tempCF_OF)
            if (operSize == OP_SIZE_WORD):
                dest = <unsigned short>dest
        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        newCF = dest&1
        self.registers.setEFLAG(FLAG_CF, newCF)
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.setEFLAG(FLAG_OF, tempCF_OF)
        return True
    cdef int rorFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char tempCF_OF, newCF_M1, i
        cdef unsigned int bitMaskHalf, dest, destM1
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoadUnsigned(operSize, True)
        destM1 = dest
        count &= 0x1f
        count = count&((operSize<<3)-1)
        if (not count):
            return True
        for i in range(count):
            destM1 = dest
            tempCF_OF = destM1&1
            dest = (destM1 >> 1) | (tempCF_OF * bitMaskHalf)
        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        tempCF_OF = (dest&bitMaskHalf)!=0
        newCF_M1 = (destM1&bitMaskHalf)!=0
        self.registers.setEFLAG(FLAG_CF, tempCF_OF)
        tempCF_OF = (tempCF_OF ^ newCF_M1)
        self.registers.setEFLAG(FLAG_OF, tempCF_OF)
        return True
    cdef int opcodeGroup4_RM(self, unsigned char operSize, unsigned char method):
        cdef unsigned char operOpcode, operOpcodeId, count
        operOpcode = self.registers.getCurrentOpcodeUnsignedByte()
        operOpcodeId = (operOpcode>>3)&7
        self.main.debug("opcodeGroup4_RM: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (method == GROUP4_1):
            count = 1
        elif (method == GROUP4_CL):
            count = self.registers.regReadUnsignedLowByte(CPU_REGISTER_CL)
        elif (method == GROUP4_IMM8):
            count = self.registers.getCurrentOpcodeAddUnsignedByte()
        else:
            self.main.exitError("opcodeGroup4_RM: method {0:d} is unknown.", method)
        if (operOpcodeId in (GROUP4_OP_SHL_SAL, GROUP4_OP_SHL_SAL_ALIAS)):
            self.shlFunc(operSize, count)
        elif (operOpcodeId == GROUP4_OP_SAR):
            self.sarFunc(operSize, count)
        elif (operOpcodeId == GROUP4_OP_SHR):
            self.shrFunc(operSize, count)
        elif (operOpcodeId == GROUP4_OP_RCL):
            self.rclFunc(operSize, count)
        elif (operOpcodeId == GROUP4_OP_RCR):
            self.rcrFunc(operSize, count)
        elif (operOpcodeId == GROUP4_OP_ROL):
            self.rolFunc(operSize, count)
        elif (operOpcodeId == GROUP4_OP_ROR):
            self.rorFunc(operSize, count)
        else:
            self.main.notice("opcodeGroup4_RM: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
        return True
    cdef int sahf(self):
        cdef unsigned short flagsVal
        flagsVal = self.registers.regReadUnsignedWord(CPU_REGISTER_FLAGS)&0xff00
        flagsVal |= self.registers.regReadUnsignedHighByte(CPU_REGISTER_AH)
        flagsVal &= (0xff00 | FLAG_SF | FLAG_ZF | FLAG_AF | FLAG_PF | FLAG_CF)
        flagsVal |= FLAG_REQUIRED
        self.registers.regWriteWord(CPU_REGISTER_FLAGS, flagsVal)
        return True
    cdef int lahf(self):
        cdef unsigned char flagsVal
        flagsVal = <unsigned char>(self.registers.regReadUnsignedWord(CPU_REGISTER_FLAGS))
        flagsVal &= (FLAG_SF | FLAG_ZF | FLAG_AF | FLAG_PF | FLAG_CF)
        flagsVal |= FLAG_REQUIRED
        self.registers.regWriteHighByte(CPU_REGISTER_AH, flagsVal)
        return True
    cdef int xchgFuncRegWord(self, unsigned short regName, unsigned short regName2):
        cdef unsigned int regValue, regValue2
        regValue, regValue2 = self.registers.regReadUnsignedWord(regName), self.registers.regReadUnsignedWord(regName2)
        self.registers.regWriteWord(regName, regValue2)
        self.registers.regWriteWord(regName2, regValue)
        return True
    cdef int xchgFuncRegDword(self, unsigned short regName, unsigned short regName2):
        cdef unsigned int regValue, regValue2
        regValue, regValue2 = self.registers.regReadUnsignedDword(regName), self.registers.regReadUnsignedDword(regName2)
        self.registers.regWriteDword(regName, regValue2)
        self.registers.regWriteDword(regName2, regValue)
        return True
    ##### DON'T USE XCHG AX, AX FOR OPCODE 0x90, use NOP instead!!
    cdef int xchgReg(self):
        if (self.registers.operSize == OP_SIZE_WORD):
            self.xchgFuncRegWord(CPU_REGISTER_AX, self.main.cpu.opcode&7)
        elif (self.registers.operSize == OP_SIZE_DWORD):
            self.xchgFuncRegDword(CPU_REGISTER_AX, self.main.cpu.opcode&7)
        return True
    cdef int xchgR_RM(self, unsigned char operSize):
        cdef unsigned int op1, op2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.modRMInstance.modRLoadUnsigned(operSize)
        op2 = self.modRMInstance.modRMLoadUnsigned(operSize, True)
        self.modRMInstance.modRSave(operSize, op2, OPCODE_SAVE)
        self.modRMInstance.modRMSave(operSize, op1, True, OPCODE_SAVE)
        return True
    cdef int enter(self):
        cdef unsigned char stackSize, nestingLevel, i
        cdef unsigned short sizeOp
        cdef unsigned int frameTemp, temp
        sizeOp = self.registers.getCurrentOpcodeAddUnsignedWord()
        nestingLevel = self.registers.getCurrentOpcodeAddUnsignedByte()
        nestingLevel &= 0x1f
        stackSize = self.registers.getOpSegSize(CPU_SEGMENT_SS)
        self.stackPushRegId(CPU_REGISTER_BP, stackSize)
        if (stackSize == OP_SIZE_WORD):
            frameTemp = self.registers.regReadUnsignedWord(CPU_REGISTER_SP)
            if (nestingLevel > 1):
                for i in range(nestingLevel-1):
                    self.registers.regSubWord(CPU_REGISTER_BP, stackSize)
                    temp = self.registers.mmReadValueUnsigned(self.registers.regReadUnsignedWord(CPU_REGISTER_BP), \
                      stackSize, CPU_SEGMENT_SS, False)
                    self.stackPushValue(temp, stackSize)
            if (nestingLevel >= 1):
                self.stackPushValue(frameTemp, stackSize)
            self.registers.regWriteWord(CPU_REGISTER_BP, frameTemp)
            self.registers.regSubWord(CPU_REGISTER_SP, sizeOp)
        elif (stackSize == OP_SIZE_DWORD):
            frameTemp = self.registers.regReadUnsignedDword(CPU_REGISTER_ESP)
            for i in range(nestingLevel-1):
                self.registers.regSubDword(CPU_REGISTER_EBP, stackSize)
                temp = self.registers.mmReadValueUnsigned(self.registers.regReadUnsignedDword(CPU_REGISTER_EBP), \
                  stackSize, CPU_SEGMENT_SS, False)
                self.stackPushValue(temp, stackSize)
            if (nestingLevel >= 1):
                self.stackPushValue(frameTemp, stackSize)
            self.registers.regWriteDword(CPU_REGISTER_EBP, frameTemp)
            self.registers.regSubDword(CPU_REGISTER_ESP, sizeOp)
        return True
    cdef int leave(self):
        cdef unsigned char stackAddrSize
        stackAddrSize = self.registers.getAddrSegSize(CPU_SEGMENT_SS)
        if (stackAddrSize == OP_SIZE_WORD):
            self.registers.regWriteWord(CPU_REGISTER_SP, self.registers.regReadUnsignedWord(CPU_REGISTER_BP))
        elif (stackAddrSize == OP_SIZE_DWORD):
            self.registers.regWriteDword(CPU_REGISTER_ESP, self.registers.regReadUnsignedDword(CPU_REGISTER_EBP))
        self.stackPopRegId(CPU_REGISTER_EBP, self.registers.operSize)
        return True
    cdef int cmovFunc(self, unsigned char cond): # R16, R/M 16; R32, R/M 32
        self.movR_RM(self.registers.operSize, cond)
        return True
    cdef int setWithCondFunc(self, unsigned char cond): # if cond==True set 1, else 0
        self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
        self.modRMInstance.modRMSave(OP_SIZE_BYTE, cond!=0, True, OPCODE_SAVE)
        return True
    cdef int arpl(self):
        cdef unsigned short op1, op2
        if (not (<Segments>self.registers.segments).isInProtectedMode()):
            raise ChemuException(CPU_EXCEPTION_UD)
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
        op1 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD, True)
        op2 = self.modRMInstance.modRLoadUnsigned(OP_SIZE_WORD)
        if (op1 < op2):
            self.registers.setEFLAG(FLAG_ZF, True)
            self.modRMInstance.modRMSave(OP_SIZE_WORD, (op1&0xfffc)|(op2&3), True, OPCODE_SAVE)
        else:
            self.registers.setEFLAG(FLAG_ZF, False)
        return True
    cdef int bound(self):
        cdef unsigned int returnInt
        cdef signed int index, lowerBound, upperBound
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        if (self.modRMInstance.mod == 3):
            raise ChemuException(CPU_EXCEPTION_UD)
        index = self.modRMInstance.modRLoadSigned(self.registers.operSize)
        returnInt = self.modRMInstance.getRMValueFull(self.registers.addrSize)
        lowerBound = self.registers.mmReadValueSigned(returnInt, self.registers.operSize, self.modRMInstance.rmNameSegId, True)
        upperBound = self.registers.mmReadValueSigned(returnInt+self.registers.operSize, self.registers.operSize, self.modRMInstance.rmNameSegId, True)
        if (index < lowerBound or index > upperBound+self.registers.operSize):
            raise ChemuException(CPU_EXCEPTION_BR)
        return True
    cdef int btFunc(self, unsigned int offset, unsigned char newValType):
        cdef unsigned char operSizeInBits, state
        cdef unsigned int value, address
        operSizeInBits = self.registers.operSize << 3
        address = 0
        if (self.modRMInstance.mod == 3): # register operand
            offset &= operSizeInBits-1
            value = self.modRMInstance.modRLoadUnsigned(self.registers.operSize)
            state = self.registers.valGetBit(value, offset)
            self.registers.setEFLAG(FLAG_CF, state)
        else: # memory operand
            address = self.modRMInstance.getRMValueFull(self.registers.addrSize)
            address += (self.registers.operSize * (offset // operSizeInBits))
            value = self.registers.mmReadValueUnsigned(address, self.registers.operSize, self.modRMInstance.rmNameSegId, True)
            state = self.registers.valGetBit(value, offset)
            self.registers.setEFLAG(FLAG_CF, state)
        if (newValType != BT_NONE):
            if (newValType == BT_COMPLEMENT):
                state = not state
            elif (newValType == BT_RESET):
                state = False
            elif (newValType == BT_SET):
                state = True
            else:
                self.main.exitError("btFunc: unknown newValType: {0:d}", newValType)
            value = self.registers.valSetBit(value, offset, state)
            if (self.modRMInstance.mod == 3): # register operand
                self.modRMInstance.modRSave(self.registers.operSize, value, OPCODE_SAVE)
            else: # memory operands
                self.registers.mmWriteValue(address, value, self.registers.operSize, self.modRMInstance.rmNameSegId, True)
        return True
    cdef void run(self):
        self.modRMInstance = ModRMClass(self.main, (<Registers>self.main.cpu.registers))
    # end of opcodes



