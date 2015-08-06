
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"
include "cpu_globals.pxi"

from misc import HirnwichseException


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
DEF BT_IMM = 4



cdef class Opcodes:
    def __init__(self, Hirnwichse main):
        self.main = main
    cdef int executeOpcode(self, unsigned char opcode) except BITMASK_BYTE:
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
        elif (opcode in (0x80, 0x82)):
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
            self.main.notice("Opcodes::executeOpcode: WAIT/FWAIT: TODO!")
            if (self.registers.getFlagDword(CPU_REGISTER_CR0, (CR0_FLAG_MP | CR0_FLAG_TS)) ==  (CR0_FLAG_MP | CR0_FLAG_TS)):
                raise HirnwichseException(CPU_EXCEPTION_NM)
            #raise HirnwichseException(CPU_EXCEPTION_UD) # TODO
            retVal = True
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
            self.main.notice("Opcodes::executeOpcode: INT3 (Opcode 0xcc): TODO!")
            retVal = True
            raise HirnwichseException(CPU_EXCEPTION_BP)
        elif (opcode == 0xcd):
            retVal = self.interrupt()
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
            self.main.notice("Opcodes::executeOpcode: undef_no_UD! (Opcode 0xd6)")
            pass ### undefNoUD
            retVal = True
        elif (opcode == 0xd7):
            retVal = self.xlatb()
        elif (opcode >= 0xd8 and opcode <= 0xdf):
            retVal = self.fpuOpcodes(opcode)
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
            self.main.notice("Opcodes::executeOpcode: undef_no_UD! (Opcode 0xf1)")
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
            self.main.notice("handler for opcode {0:#04x} wasn't found.", opcode)
            raise HirnwichseException(CPU_EXCEPTION_UD) # if opcode wasn't found.
        return retVal
    cdef int cli(self) except BITMASK_BYTE:
        if (self.registers.protectedModeOn):
            if (self.registers.vm):
                if (self.registers.getIOPL() < 3):
                    if (self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_VME) != 0):
                        self.registers.vif = False
                        return True
                    else:
                        raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            elif (self.registers.getIOPL() < self.registers.getCPL()):
                if ((self.registers.getCPL() == 3) and self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_PVI) != 0):
                    self.registers.vif = False
                    return True
                else:
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        self.registers.if_flag = False
        return True
    cdef int sti(self) except BITMASK_BYTE:
        if (self.registers.protectedModeOn):
            if (self.registers.vm):
                if (self.registers.getIOPL() < 3):
                    if (self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_VME) != 0 and not self.registers.vip):
                        self.registers.vif = True
                        return True
                    else:
                        raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            elif (self.registers.getIOPL() < self.registers.getCPL()):
                if ((self.registers.getCPL() == 3) and not self.registers.vip):
                    self.registers.vif = True
                    return True
                else:
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        self.registers.if_flag = True
        self.registers.ssInhibit = True
        self.main.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
        return True
    cdef int hlt(self) except BITMASK_BYTE:
        if (self.registers.getCPL() > 0):
             self.main.notice("Opcodes::hlt: CPL > 0.")
             return True
        self.main.cpu.cpuHalted = True
        if (self.registers.if_flag and self.main.debugEnabled):
            self.main.debug("Opcodes::hlt: HLT was called with IF on.")
        return True
    cdef void cld(self):
        self.registers.df = False
    cdef void std(self):
        self.registers.df = True
    cdef void clc(self):
        self.registers.cf = False
    cdef void stc(self):
        self.registers.cf = True
    cdef void cmc(self):
        self.registers.cf = not self.registers.cf
    cdef void clac(self):
        self.registers.ac = False
    cdef void stac(self):
        self.registers.ac = True
    cdef int checkIOPL(self, unsigned short ioPortAddr, unsigned char dataSize) except BITMASK_BYTE: # return True if protected
        cdef unsigned char res
        cdef unsigned short ioMapBase, bits
        if (not self.registers.protectedModeOn or (not self.registers.vm and self.registers.getCPL() <= self.registers.getIOPL())):
            return False
        ioMapBase = self.registers.mmReadValueUnsignedWord(TSS_32BIT_IOMAP_BASE_ADDR, (<Segment>self.registers.segments.tss), False)
        if (ioMapBase >= (<Segment>self.registers.segments.tss).limit):
            self.main.notice("Opcodes::checkIOPL: test1: iomap base addr=={0:#06x}; tss limit=={1:#06x}", self.registers.mmReadValueUnsignedWord(TSS_32BIT_IOMAP_BASE_ADDR, (<Segment>self.registers.segments.tss), False), (<Segment>self.registers.segments.tss).limit)
            return True
        bits = self.registers.mmReadValueUnsignedWord(ioMapBase+(ioPortAddr>>3), (<Segment>self.registers.segments.tss), False)>>(ioPortAddr&0x7)
        res = (bits&((1<<dataSize)-1)) != 0
        if (res):
            self.main.notice("Opcodes::checkIOPL: test2.0: iomap base addr=={0:#06x}; tss limit=={1:#06x}", self.registers.mmReadValueUnsignedWord(TSS_32BIT_IOMAP_BASE_ADDR, (<Segment>self.registers.segments.tss), False), (<Segment>self.registers.segments.tss).limit)
            self.main.notice("Opcodes::checkIOPL: test2.1: bits=={0:#06x}; result=={1:d}; result==1 means gpf", bits, res)
        return res
    cdef long int inPort(self, unsigned short ioPortAddr, unsigned char dataSize) except? BITMASK_BYTE:
        if (self.registers.protectedModeOn and self.checkIOPL(ioPortAddr, dataSize)):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        return self.main.platform.inPort(ioPortAddr, dataSize)
    cdef int outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize) except BITMASK_BYTE:
        if (self.registers.protectedModeOn and self.checkIOPL(ioPortAddr, dataSize)):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        self.main.platform.outPort(ioPortAddr, data, dataSize)
        return True
    cdef int jumpFarDirect(self, unsigned char method, unsigned short segVal, unsigned int eipVal) except BITMASK_BYTE:
        cdef unsigned char segType, oldSegType
        cdef unsigned short oldTSSsel
        cdef GdtEntry gdtEntry
        cdef Segment segment
        self.registers.syncCR0State()
        if (method == OPCODE_CALL):
            self.stackPushSegment((<Segment>self.registers.segments.cs), self.registers.operSize)
            self.stackPushRegId(CPU_REGISTER_EIP, self.registers.operSize)
        if (self.registers.protectedModeOn and not self.registers.vm):
            gdtEntry = <GdtEntry>self.registers.segments.getEntry(segVal)
            if (gdtEntry is None):
                raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
            if (not gdtEntry.segPresent):
                raise HirnwichseException(CPU_EXCEPTION_NP, segVal)
            segType = (gdtEntry.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK)
            if (segType == TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE):
                #if (self.main.debugEnabled):
                IF 1:
                    self.main.notice("Opcodes::jumpFarDirect: task-gates aren't fully implemented yet.")
                segment = (<Segment>self.registers.segments.tss)
                if (gdtEntry.segDPL < self.registers.getCPL() or gdtEntry.segDPL < segVal&3):
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                segVal = gdtEntry.base
                gdtEntry = <GdtEntry>self.registers.segments.getEntry(segVal)
                if (gdtEntry is None):
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                segType = (gdtEntry.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK)
                if ((segVal & GDT_USE_LDT) or (gdtEntry.segIsRW) or segType in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY) or not self.registers.segments.inLimit(segVal)): # segIsRW means busy here
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                if (not gdtEntry.segPresent):
                    raise HirnwichseException(CPU_EXCEPTION_NP, segVal)
                segType &= TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY
                oldTSSsel = segment.segmentIndex
                if (method == OPCODE_JUMP):
                    oldSegType = self.registers.segments.getSegType(oldTSSsel) & TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY
                    self.registers.segments.setSegType(oldTSSsel, oldSegType)
                if (oldSegType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.saveTSS32()
                else:
                    self.registers.saveTSS16()
                self.registers.segWriteSegment((<Segment>self.registers.segments.tss), segVal)
                if (segType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.switchTSS32()
                else:
                    self.registers.switchTSS16()
                if (method == OPCODE_CALL):
                    self.registers.nt = True
                    self.registers.mmWriteValue(TSS_PREVIOUS_TASK_LINK, oldTSSsel, OP_SIZE_WORD, (<Segment>self.registers.segments.tss), False)
                self.registers.segments.setSegType(segVal, (segType | 0x2))
                if (not (<Segment>self.registers.segments.cs).isAddressInLimit(self.registers.regReadUnsignedDword(CPU_REGISTER_EIP), OP_SIZE_BYTE)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                return True
            elif ((segType & TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY) in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS)):
                #if (self.main.debugEnabled):
                IF 1:
                    self.main.notice("Opcodes::jumpFarDirect: TSS isn't fully implemented yet.")
                #self.main.notice("Opcodes::jumpFarDirect: test1: segType1 == {0:#04x}; segType2 == {1:#04x}!", self.registers.segments.getSegType(0x20), self.registers.segments.getSegType(0x30))
                segment = (<Segment>self.registers.segments.tss)
                if ((segVal & GDT_USE_LDT) or not self.registers.segments.inLimit(segVal)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                if (segType in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                oldTSSsel = segment.segmentIndex
                if (method == OPCODE_JUMP):
                    oldSegType = self.registers.segments.getSegType(oldTSSsel) & TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY
                    self.registers.segments.setSegType(oldTSSsel, oldSegType)
                if (oldSegType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.saveTSS32()
                else:
                    self.registers.saveTSS16()
                self.registers.segWriteSegment(segment, segVal)
                if (not segment.isValid or segment.segDPL < self.registers.getCPL() or segment.segDPL < (segment.segmentIndex&3)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, segment.segmentIndex)
                if (not segment.segPresent):
                    raise HirnwichseException(CPU_EXCEPTION_NP, segment.segmentIndex)
                if (segment.limit < 0x67):
                    raise HirnwichseException(CPU_EXCEPTION_TS, segment.segmentIndex)
                if (segType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.switchTSS32()
                else:
                    self.registers.switchTSS16()
                if (method == OPCODE_CALL):
                    self.registers.nt = True
                    self.registers.mmWriteValue(TSS_PREVIOUS_TASK_LINK, oldTSSsel, OP_SIZE_WORD, (<Segment>self.registers.segments.tss), False)
                self.registers.segments.setSegType(segVal, (segType | 0x2))
                if (not (<Segment>self.registers.segments.cs).isAddressInLimit(self.registers.regReadUnsignedDword(CPU_REGISTER_EIP), OP_SIZE_BYTE)): # TODO
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                #self.main.notice("Opcodes::jumpFarDirect: sysSegType == {0:d}; method == {1:d} (TSS); TODO!", segType, method)
                #self.main.notice("Opcodes::jumpFarDirect: test2: segType1 == {0:#04x}; segType2 == {1:#04x}!", self.registers.segments.getSegType(0x20), self.registers.segments.getSegType(0x30))
                return True
            elif (not (segType & GDT_ACCESS_NORMAL_SEGMENT)):
                self.main.exitError("Opcodes::jumpFarDirect: sysSegType {0:d} isn't supported yet. (segVal {1:#06x}; eipVal {2:#010x})", segType, segVal, eipVal)
                return True
        #self.main.debug("Opcodes::jumpFarDirect: test8: Gdt::tableLimit=={0:#06x}", self.registers.segments.gdt.tableLimit)
        self.registers.segWriteSegment((<Segment>self.registers.segments.cs), segVal)
        #self.main.debug("Opcodes::jumpFarDirect: test9: Gdt::tableLimit=={0:#06x}", self.registers.segments.gdt.tableLimit)
        self.registers.regWriteDword(CPU_REGISTER_EIP, eipVal)
        return True
    cdef int jumpFarAbsolutePtr(self) except BITMASK_BYTE:
        cdef unsigned short cs
        cdef unsigned int eip
        eip = self.registers.getCurrentOpcodeAddUnsigned(self.registers.operSize)
        cs = self.registers.getCurrentOpcodeAddUnsignedWord()
        if (self.main.debugEnabled):
            self.main.debug("Opcodes::jumpFarAbsolutePtr: cs=={0:#06x}; eip=={1:#010x}", cs, eip)
        return self.jumpFarDirect(OPCODE_JUMP, cs, eip)
    cdef int loopFunc(self, unsigned char loopType) except BITMASK_BYTE:
        cdef unsigned char oldZF
        cdef signed char rel8
        oldZF = self.registers.zf
        rel8 = self.registers.getCurrentOpcodeAddSignedByte()
        if (not self.registers.regSub(CPU_REGISTER_CX, 1, self.registers.addrSize)):
            return True
        elif (loopType == OPCODE_LOOPE and not oldZF):
            return True
        elif (loopType == OPCODE_LOOPNE and oldZF):
            return True
        if (self.registers.operSize == OP_SIZE_WORD):
            self.registers.regAddWord(CPU_REGISTER_EIP, rel8)
        else:
            self.registers.regAddDword(CPU_REGISTER_EIP, rel8)
        return True
    cdef int opcodeR_RM(self, unsigned char opcode, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned int op1, op2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (opcode not in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op1 = self.modRMInstance.modRLoadUnsigned(operSize)
        op2 = self.modRMInstance.modRMLoadUnsigned(operSize)
        if (opcode in (OPCODE_ADD, OPCODE_ADC, OPCODE_SUB, OPCODE_SBB)):
            self.modRMInstance.modRSave(operSize, op2, opcode)
            self.registers.setFullFlags(op1, op2, operSize, opcode)
        elif (opcode == OPCODE_CMP):
            self.registers.setFullFlags(op1, op2, operSize, OPCODE_SUB)
        elif (opcode in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op2 = self.modRMInstance.modRSave(operSize, op2, opcode)
            self.registers.setSZP_COA(op2, operSize)
        elif (opcode == OPCODE_TEST):
            self.main.exitError("OPCODE::opcodeR_RM: OPCODE_TEST HAS NO R_RM!!")
        else:
            self.main.exitError("OPCODE::opcodeR_RM: invalid opcode: {0:d}.", opcode)
        return True
    cdef int opcodeRM_R(self, unsigned char opcode, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned int op1, op2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (opcode not in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op1 = self.modRMInstance.modRMLoadUnsigned(operSize)
        op2 = self.modRMInstance.modRLoadUnsigned(operSize)
        if (opcode in (OPCODE_ADD, OPCODE_ADC, OPCODE_SUB, OPCODE_SBB)):
            self.modRMInstance.modRMSave(operSize, op2, opcode)
            self.registers.setFullFlags(op1, op2, operSize, opcode)
        elif (opcode == OPCODE_CMP):
            self.registers.setFullFlags(op1, op2, operSize, OPCODE_SUB)
        elif (opcode in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op2 = self.modRMInstance.modRMSave(operSize, op2, opcode)
            self.registers.setSZP_COA(op2, operSize)
        elif (opcode == OPCODE_TEST):
            self.registers.setSZP_COA(op1&op2, operSize)
        else:
            self.main.notice("OPCODE::opcodeRM_R: invalid opcode: {0:d}.", opcode)
        return True
    cdef int opcodeAxEaxImm(self, unsigned char opcode, unsigned char operSize) except BITMASK_BYTE:
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
            self.registers.setSZP_COA(op2, operSize)
        elif (opcode == OPCODE_TEST):
            self.registers.setSZP_COA(op1&op2, operSize)
        else:
            self.main.notice("OPCODE::opcodeRM_R: invalid opcode: {0:d}.", opcode)
        return True
    cdef int movImmToR(self, unsigned char operSize) except BITMASK_BYTE:
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
    cdef int movRM_R(self, unsigned char operSize) except BITMASK_BYTE:
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        self.modRMInstance.modRMSave(operSize, self.modRMInstance.modRLoadUnsigned(operSize), OPCODE_SAVE)
        return True
    cdef int movR_RM(self, unsigned char operSize, unsigned char cond) except BITMASK_BYTE:
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (cond):
            self.modRMInstance.modRSave(operSize, self.modRMInstance.modRMLoadUnsigned(operSize), OPCODE_SAVE)
        return True
    cdef int movRM16_SREG(self) except BITMASK_BYTE:
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        self.modRMInstance.modRMSave(self.registers.operSize, self.registers.segRead(self.modRMInstance.regName), OPCODE_SAVE)
        return True
    cdef int movSREG_RM16(self) except BITMASK_BYTE:
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        if (self.modRMInstance.regName == CPU_SEGMENT_CS):
            raise HirnwichseException(CPU_EXCEPTION_UD)
        if (self.modRMInstance.regName == CPU_SEGMENT_SS):
            self.registers.ssInhibit = True
        self.registers.segWrite(self.modRMInstance.regName, self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD))
        return True
    cdef int movAxMoffs(self, unsigned char operSize) except BITMASK_BYTE:
        self.registers.regWrite(CPU_REGISTER_AX, \
          self.registers.mmReadValueUnsigned(self.registers.getCurrentOpcodeAddUnsigned(self.registers.addrSize), operSize, (<Segment>self.registers.segments.ds), True), operSize)
        return True
    cdef int movMoffsAx(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned int value
        if (operSize == OP_SIZE_BYTE):
            value = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        elif (operSize == OP_SIZE_WORD):
            value = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
        elif (operSize == OP_SIZE_DWORD):
            value = self.registers.regReadUnsignedDword(CPU_REGISTER_EAX)
        self.registers.mmWriteValue(self.registers.getCurrentOpcodeAddUnsigned(self.registers.addrSize), value, operSize, (<Segment>self.registers.segments.ds), True)
        return True
    cdef int stosFuncWord(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char dfFlag
        cdef unsigned short countVal, ediVal
        cdef unsigned int data, dataLength
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        dfFlag = self.registers.df
        dataLength = (<unsigned int>countVal*operSize)
        data = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
        ediVal = self.registers.regReadUnsignedWord(CPU_REGISTER_DI)
        if (dfFlag):
            ediVal = (ediVal-(dataLength-operSize))
        self.registers.mmWrite(ediVal, data.to_bytes(length=operSize, byteorder="little")*countVal, dataLength, (<Segment>self.registers.segments.es), False)
        if (not dfFlag):
            self.registers.regAddWord(CPU_REGISTER_DI, dataLength)
        else:
            self.registers.regSubWord(CPU_REGISTER_DI, dataLength)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteWord(CPU_REGISTER_CX, 0)
            self.registers.repPrefix = False
        return True
    cdef int stosFuncDword(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char dfFlag
        cdef unsigned int data, countVal, ediVal
        cdef unsigned int dataLength
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        dfFlag = self.registers.df
        dataLength = (<unsigned int>countVal*operSize)
        data = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
        ediVal = self.registers.regReadUnsignedDword(CPU_REGISTER_EDI)
        if (dfFlag):
            ediVal = (ediVal-(dataLength-operSize))
        self.registers.mmWrite(ediVal, data.to_bytes(length=operSize, byteorder="little")*countVal, dataLength, (<Segment>self.registers.segments.es), False)
        if (not dfFlag):
            self.registers.regAddDword(CPU_REGISTER_EDI, dataLength)
        else:
            self.registers.regSubDword(CPU_REGISTER_EDI, dataLength)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteDword(CPU_REGISTER_ECX, 0)
            self.registers.repPrefix = False
        return True
    cdef int stosFunc(self, unsigned char operSize) except BITMASK_BYTE:
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.stosFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.stosFuncDword(operSize)
        return False
    cdef int movsFuncWord(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char dfFlag
        cdef unsigned short countVal, esiVal, ediVal, i
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        dfFlag = self.registers.df
        esiVal = self.registers.regReadUnsignedWord(CPU_REGISTER_SI)
        ediVal = self.registers.regReadUnsignedWord(CPU_REGISTER_DI)
        for i in range(countVal):
            self.registers.mmWrite(ediVal, self.registers.mmRead(esiVal, operSize, (<Segment>self.registers.segments.ds), True), operSize, (<Segment>self.registers.segments.es), False)
            if (not dfFlag):
                esiVal = self.registers.regAddWord(CPU_REGISTER_SI, operSize)
                ediVal = self.registers.regAddWord(CPU_REGISTER_DI, operSize)
            else:
                esiVal = self.registers.regSubWord(CPU_REGISTER_SI, operSize)
                ediVal = self.registers.regSubWord(CPU_REGISTER_DI, operSize)
            if (self.registers.repPrefix):
                self.registers.regSubWord(CPU_REGISTER_CX, 1)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.repPrefix = False
        return True
    cdef int movsFuncDword(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char dfFlag
        cdef unsigned int countVal, esiVal, ediVal, i
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        dfFlag = self.registers.df
        esiVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ESI)
        ediVal = self.registers.regReadUnsignedDword(CPU_REGISTER_EDI)
        for i in range(countVal):
            self.registers.mmWrite(ediVal, self.registers.mmRead(esiVal, operSize, (<Segment>self.registers.segments.ds), True), operSize, (<Segment>self.registers.segments.es), False)
            if (not dfFlag):
                esiVal = self.registers.regAddDword(CPU_REGISTER_ESI, operSize)
                ediVal = self.registers.regAddDword(CPU_REGISTER_EDI, operSize)
            else:
                esiVal = self.registers.regSubDword(CPU_REGISTER_ESI, operSize)
                ediVal = self.registers.regSubDword(CPU_REGISTER_EDI, operSize)
            if (self.registers.repPrefix):
                self.registers.regSubDword(CPU_REGISTER_ECX, 1)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.repPrefix = False
        return True
    cdef int movsFunc(self, unsigned char operSize) except BITMASK_BYTE:
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.movsFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.movsFuncDword(operSize)
        return False
    cdef int lodsFuncWord(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char dfFlag
        cdef unsigned short countVal, esiVal
        cdef unsigned int data, dataLength
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        dfFlag = self.registers.df
        dataLength = (<unsigned int>countVal*operSize)
        if (not dfFlag):
            esiVal = (self.registers.regAddWord(CPU_REGISTER_SI, dataLength)-operSize)
        else:
            esiVal = (self.registers.regSubWord(CPU_REGISTER_SI, dataLength)+operSize)
        data = self.registers.mmReadValueUnsigned(esiVal, operSize, (<Segment>self.registers.segments.ds), True)
        self.registers.regWrite(CPU_REGISTER_AX, data, operSize)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteWord(CPU_REGISTER_CX, 0)
            self.registers.repPrefix = False
        return True
    cdef int lodsFuncDword(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char dfFlag
        cdef unsigned int data, countVal, esiVal
        cdef unsigned int dataLength
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        dfFlag = self.registers.df
        dataLength = (<unsigned int>countVal*operSize)
        if (not dfFlag):
            esiVal = (self.registers.regAddDword(CPU_REGISTER_ESI, dataLength)-operSize)
        else:
            esiVal = (self.registers.regSubDword(CPU_REGISTER_ESI, dataLength)+operSize)
        data = self.registers.mmReadValueUnsigned(esiVal, operSize, (<Segment>self.registers.segments.ds), True)
        self.registers.regWrite(CPU_REGISTER_AX, data, operSize)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.regWriteDword(CPU_REGISTER_ECX, 0)
            self.registers.repPrefix = False
        return True
    cdef int lodsFunc(self, unsigned char operSize) except BITMASK_BYTE:
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.lodsFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.lodsFuncDword(operSize)
        return False
    cdef int cmpsFuncWord(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char zfFlag, dfFlag
        cdef unsigned short esiVal, ediVal, countVal, i
        cdef unsigned int src1, src2
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        dfFlag = self.registers.df
        esiVal = self.registers.regReadUnsignedWord(CPU_REGISTER_SI)
        ediVal = self.registers.regReadUnsignedWord(CPU_REGISTER_DI)
        for i in range(countVal):
            src1 = self.registers.mmReadValueUnsigned(esiVal, operSize, (<Segment>self.registers.segments.ds), True)
            src2 = self.registers.mmReadValueUnsigned(ediVal, operSize, (<Segment>self.registers.segments.es), False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not dfFlag):
                esiVal = self.registers.regAddWord(CPU_REGISTER_SI, operSize)
                ediVal = self.registers.regAddWord(CPU_REGISTER_DI, operSize)
            else:
                esiVal = self.registers.regSubWord(CPU_REGISTER_SI, operSize)
                ediVal = self.registers.regSubWord(CPU_REGISTER_DI, operSize)
            if (self.registers.repPrefix):
                self.registers.regSubWord(CPU_REGISTER_CX, 1)
            zfFlag = self.registers.zf
            if ((self.registers.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or (self.registers.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                break
        self.main.cpu.cycles += (countVal) << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.repPrefix = False
        return True
    cdef int cmpsFuncDword(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char zfFlag, dfFlag
        cdef unsigned int esiVal, ediVal, countVal, src1, src2, i
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        dfFlag = self.registers.df
        esiVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ESI)
        ediVal = self.registers.regReadUnsignedDword(CPU_REGISTER_EDI)
        for i in range(countVal):
            src1 = self.registers.mmReadValueUnsigned(esiVal, operSize, (<Segment>self.registers.segments.ds), True)
            src2 = self.registers.mmReadValueUnsigned(ediVal, operSize, (<Segment>self.registers.segments.es), False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not dfFlag):
                esiVal = self.registers.regAddDword(CPU_REGISTER_ESI, operSize)
                ediVal = self.registers.regAddDword(CPU_REGISTER_EDI, operSize)
            else:
                esiVal = self.registers.regSubDword(CPU_REGISTER_ESI, operSize)
                ediVal = self.registers.regSubDword(CPU_REGISTER_EDI, operSize)
            if (self.registers.repPrefix):
                self.registers.regSubDword(CPU_REGISTER_ECX, 1)
            zfFlag = self.registers.zf
            if ((self.registers.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or (self.registers.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                break
        self.main.cpu.cycles += (countVal) << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.repPrefix = False
        return True
    cdef int cmpsFunc(self, unsigned char operSize) except BITMASK_BYTE:
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.cmpsFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.cmpsFuncDword(operSize)
        return False
    cdef int scasFuncWord(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char zfFlag, dfFlag
        cdef unsigned short ediVal, countVal, i
        cdef unsigned int src1, src2
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        dfFlag = self.registers.df
        ediVal = self.registers.regReadUnsignedWord(CPU_REGISTER_DI)
        src1 = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
        for i in range(countVal):
            src2 = self.registers.mmReadValueUnsigned(ediVal, operSize, (<Segment>self.registers.segments.es), False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not dfFlag):
                ediVal = self.registers.regAddWord(CPU_REGISTER_DI, operSize)
            else:
                ediVal = self.registers.regSubWord(CPU_REGISTER_DI, operSize)
            if (self.registers.repPrefix):
                self.registers.regSubWord(CPU_REGISTER_CX, 1)
            zfFlag = self.registers.zf
            if ((self.registers.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or (self.registers.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                break
        self.main.cpu.cycles += (countVal) << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.repPrefix = False
        return True
    cdef int scasFuncDword(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char zfFlag, dfFlag
        cdef unsigned int src1, src2, ediVal, countVal, i
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        dfFlag = self.registers.df
        ediVal = self.registers.regReadUnsignedDword(CPU_REGISTER_EDI)
        src1 = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
        for i in range(countVal):
            src2 = self.registers.mmReadValueUnsigned(ediVal, operSize, (<Segment>self.registers.segments.es), False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not dfFlag):
                ediVal = self.registers.regAddDword(CPU_REGISTER_EDI, operSize)
            else:
                ediVal = self.registers.regSubDword(CPU_REGISTER_EDI, operSize)
            if (self.registers.repPrefix):
                self.registers.regSubDword(CPU_REGISTER_ECX, 1)
            zfFlag = self.registers.zf
            if ((self.registers.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or (self.registers.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                break
        self.main.cpu.cycles += (countVal) << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.repPrefix = False
        return True
    cdef int scasFunc(self, unsigned char operSize) except BITMASK_BYTE:
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.scasFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.scasFuncDword(operSize)
        return False
    cdef int inAxImm8(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned int value
        value = self.inPort(self.registers.getCurrentOpcodeAddUnsignedByte(), operSize)
        if (operSize == OP_SIZE_BYTE):
            self.registers.regWriteLowByte(CPU_REGISTER_AL, value)
        elif (operSize == OP_SIZE_WORD):
            self.registers.regWriteWord(CPU_REGISTER_AX, value)
        elif (operSize == OP_SIZE_DWORD):
            self.registers.regWriteDword(CPU_REGISTER_EAX, value)
        return True
    cdef int inAxDx(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned int value
        value = self.inPort(self.registers.regReadUnsignedWord(CPU_REGISTER_DX), operSize)
        if (operSize == OP_SIZE_BYTE):
            self.registers.regWriteLowByte(CPU_REGISTER_AL, value)
        elif (operSize == OP_SIZE_WORD):
            self.registers.regWriteWord(CPU_REGISTER_AX, value)
        elif (operSize == OP_SIZE_DWORD):
            self.registers.regWriteDword(CPU_REGISTER_EAX, value)
        return True
    cdef int outImm8Ax(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned int value
        if (operSize == OP_SIZE_BYTE):
            value = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        elif (operSize == OP_SIZE_WORD):
            value = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
        elif (operSize == OP_SIZE_DWORD):
            value = self.registers.regReadUnsignedDword(CPU_REGISTER_EAX)
        self.outPort(self.registers.getCurrentOpcodeAddUnsignedByte(), value, operSize)
        return True
    cdef int outDxAx(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned int value
        if (operSize == OP_SIZE_BYTE):
            value = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        elif (operSize == OP_SIZE_WORD):
            value = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
        elif (operSize == OP_SIZE_DWORD):
            value = self.registers.regReadUnsignedDword(CPU_REGISTER_EAX)
        self.outPort(self.registers.regReadUnsignedWord(CPU_REGISTER_DX), value, operSize)
        return True
    cdef int outsFuncWord(self, unsigned char operSize) except BITMASK_BYTE:
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
        dfFlag = self.registers.df
        for i in range(countVal):
            value = self.registers.mmReadValueUnsigned(esiVal, operSize, (<Segment>self.registers.segments.ds), True)
            self.outPort(ioPort, value, operSize)
            if (not dfFlag):
                esiVal = self.registers.regAddWord(CPU_REGISTER_SI, operSize)
            else:
                esiVal = self.registers.regSubWord(CPU_REGISTER_SI, operSize)
            if (self.registers.repPrefix):
                self.registers.regSubWord(CPU_REGISTER_CX, 1)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.repPrefix = False
        return True
    cdef int outsFuncDword(self, unsigned char operSize) except BITMASK_BYTE:
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
        dfFlag = self.registers.df
        for i in range(countVal):
            value = self.registers.mmReadValueUnsigned(esiVal, operSize, (<Segment>self.registers.segments.ds), True)
            self.outPort(ioPort, value, operSize)
            if (not dfFlag):
                esiVal = self.registers.regAddDword(CPU_REGISTER_ESI, operSize)
            else:
                esiVal = self.registers.regSubDword(CPU_REGISTER_ESI, operSize)
            if (self.registers.repPrefix):
                self.registers.regSubDword(CPU_REGISTER_ECX, 1)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.repPrefix = False
        return True
    cdef int outsFunc(self, unsigned char operSize) except BITMASK_BYTE:
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.outsFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.outsFuncDword(operSize)
        return False
    cdef int insFuncWord(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char dfFlag
        cdef unsigned short ioPort, ediVal, countVal, i
        cdef unsigned int value
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedWord(CPU_REGISTER_CX)
            if (not countVal):
                return True
        dfFlag = self.registers.df
        ediVal = self.registers.regReadUnsignedWord(CPU_REGISTER_DI)
        ioPort = self.registers.regReadUnsignedWord(CPU_REGISTER_DX)
        for i in range(countVal):
            value = self.inPort(ioPort, operSize)
            self.registers.mmWriteValue(ediVal, value, operSize, (<Segment>self.registers.segments.es), False)
            if (not dfFlag):
                ediVal = self.registers.regAddWord(CPU_REGISTER_DI, operSize)
            else:
                ediVal = self.registers.regSubWord(CPU_REGISTER_DI, operSize)
            if (self.registers.repPrefix):
                self.registers.regSubWord(CPU_REGISTER_CX, 1)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.repPrefix = False
        return True
    cdef int insFuncDword(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char dfFlag
        cdef unsigned short ioPort
        cdef unsigned int value, ediVal, countVal, i
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            if (not countVal):
                return True
        dfFlag = self.registers.df
        ediVal = self.registers.regReadUnsignedDword(CPU_REGISTER_EDI)
        ioPort = self.registers.regReadUnsignedWord(CPU_REGISTER_DX)
        for i in range(countVal):
            value = self.inPort(ioPort, operSize)
            self.registers.mmWriteValue(ediVal, value, operSize, (<Segment>self.registers.segments.es), False)
            if (not dfFlag):
                ediVal = self.registers.regAddDword(CPU_REGISTER_EDI, operSize)
            else:
                ediVal = self.registers.regSubDword(CPU_REGISTER_EDI, operSize)
            if (self.registers.repPrefix):
                self.registers.regSubDword(CPU_REGISTER_ECX, 1)
        self.registers.regWriteDword(CPU_REGISTER_EDI, ediVal)
        self.main.cpu.cycles += countVal << CPU_CLOCK_TICK_SHIFT
        if (self.registers.repPrefix):
            self.registers.repPrefix = False
        return True
    cdef int insFunc(self, unsigned char operSize) except BITMASK_BYTE:
        if (self.registers.addrSize == OP_SIZE_WORD):
            return self.insFuncWord(operSize)
        elif (self.registers.addrSize == OP_SIZE_DWORD):
            return self.insFuncDword(operSize)
        return False
    cdef int jcxzShort(self) except BITMASK_BYTE:
        cdef unsigned int cxVal
        cxVal = self.registers.regReadUnsigned(CPU_REGISTER_CX, self.registers.addrSize)
        self.jumpShort(OP_SIZE_BYTE, not cxVal)
        return True
    cdef int jumpShort(self, unsigned char offsetSize, unsigned char cond) except BITMASK_BYTE:
        cdef signed int offset
        offset = offsetSize
        if (cond):
            offset = self.registers.getCurrentOpcodeAddSigned(offsetSize)
        self.registers.syncCR0State()
        if (self.registers.operSize == OP_SIZE_WORD):
            self.registers.regAddWord(CPU_REGISTER_EIP, offset)
        else:
            self.registers.regAddDword(CPU_REGISTER_EIP, offset)
        return True
    cdef int callNearRel16_32(self) except BITMASK_BYTE:
        cdef signed int offset
        cdef unsigned int newEip
        offset = self.registers.getCurrentOpcodeAddSigned(self.registers.operSize)
        self.registers.syncCR0State()
        newEip = (self.registers.regReadUnsignedDword(CPU_REGISTER_EIP)+offset)
        if (self.registers.operSize == OP_SIZE_WORD):
            newEip = <unsigned short>newEip
        if (self.registers.protectedModeOn and not (<Segment>self.registers.segments.cs).isAddressInLimit(newEip, OP_SIZE_BYTE)):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        self.stackPushRegId(CPU_REGISTER_EIP, self.registers.operSize)
        self.registers.regWriteDword(CPU_REGISTER_EIP, newEip)
        return True
    cdef int callPtr16_32(self) except BITMASK_BYTE:
        cdef unsigned short segVal
        cdef unsigned int eipAddr
        eipAddr = self.registers.getCurrentOpcodeAddUnsigned(self.registers.operSize)
        segVal = self.registers.getCurrentOpcodeAddUnsignedWord()
        self.jumpFarDirect(OPCODE_CALL, segVal, eipAddr)
        return True
    cdef int pushaWD(self) except BITMASK_BYTE:
        cdef unsigned int temp
        temp = self.registers.regReadUnsigned(CPU_REGISTER_SP, self.registers.operSize)
        if (not self.registers.protectedModeOn and temp in (7, 9, 11, 13, 15)):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        self.stackPushRegId(CPU_REGISTER_AX, self.registers.operSize)
        self.stackPushRegId(CPU_REGISTER_CX, self.registers.operSize)
        self.stackPushRegId(CPU_REGISTER_DX, self.registers.operSize)
        self.stackPushRegId(CPU_REGISTER_BX, self.registers.operSize)
        self.stackPushValue(temp, self.registers.operSize, False)
        self.stackPushRegId(CPU_REGISTER_BP, self.registers.operSize)
        self.stackPushRegId(CPU_REGISTER_SI, self.registers.operSize)
        self.stackPushRegId(CPU_REGISTER_DI, self.registers.operSize)
        return True
    cdef int popaWD(self) except BITMASK_BYTE:
        self.stackPopRegId(CPU_REGISTER_DI, self.registers.operSize)
        self.stackPopRegId(CPU_REGISTER_SI, self.registers.operSize)
        self.stackPopRegId(CPU_REGISTER_BP, self.registers.operSize)
        self.registers.regAddDword(CPU_REGISTER_ESP, self.registers.operSize)
        self.stackPopRegId(CPU_REGISTER_BX, self.registers.operSize)
        self.stackPopRegId(CPU_REGISTER_DX, self.registers.operSize)
        self.stackPopRegId(CPU_REGISTER_CX, self.registers.operSize)
        self.stackPopRegId(CPU_REGISTER_AX, self.registers.operSize)
        return True
    cdef int pushfWD(self) except BITMASK_BYTE:
        cdef unsigned char iopl
        cdef unsigned int value
        iopl = self.registers.getIOPL()
        if (self.registers.protectedModeOn and self.registers.vm and iopl < 3):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        value = self.registers.regReadUnsigned(CPU_REGISTER_FLAGS, self.registers.operSize)
        value &= (~FLAG_IOPL) # This is for
        value |= (self.registers.getIOPL()<<12) # IOPL, Bits 12,13
        if (self.registers.operSize == OP_SIZE_DWORD):
            value &= 0x00FCFFFF
        self.stackPushValue(value, self.registers.operSize, False)
        return True
    cdef int popfWD(self) except BITMASK_BYTE:
        cdef unsigned char cpl, iopl
        cdef unsigned int flagValue, oldFlagValue, keepFlags
        keepFlags = FLAG_RF | FLAG_VM
        iopl = self.registers.getIOPL()
        if (self.registers.protectedModeOn and self.registers.vm and iopl < 3):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        cpl = self.registers.getCPL()
        oldFlagValue = self.registers.regReadUnsigned(CPU_REGISTER_FLAGS, self.registers.operSize)
        flagValue = self.stackPopValue(True)
        if (cpl != 0):
            keepFlags |= FLAG_IOPL
            if (cpl > iopl):
                keepFlags |= FLAG_IF
        if (self.registers.vm):
            keepFlags |= FLAG_VIP | FLAG_VIF | FLAG_IOPL
        flagValue &= ~(keepFlags | RESERVED_FLAGS_BITMASK)
        flagValue |= oldFlagValue & keepFlags
        if (self.registers.operSize == OP_SIZE_WORD):
            flagValue = <unsigned short>flagValue
        elif (not self.registers.vm):
            flagValue &= ~(FLAG_VIP | FLAG_VIF)
        if (self.registers.vm and iopl < 3):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        self.registers.regWrite(CPU_REGISTER_FLAGS, flagValue, self.registers.operSize)
        return True
    cdef int stackPopSegment(self, Segment segment) except BITMASK_BYTE:
        self.registers.segWriteSegment(segment, <unsigned short>self.stackPopValue(True))
        return True
    cdef int stackPopRegId(self, unsigned short regId, unsigned char regSize) except BITMASK_BYTE:
        cdef unsigned int value
        value = self.stackPopValue(True)
        if (regSize == OP_SIZE_WORD):
            value = <unsigned short>value
        self.registers.regWrite(regId, value, regSize)
        return True
    cdef unsigned int stackPopValue(self, unsigned char increaseStackAddr):
        cdef unsigned char stackAddrSize
        cdef unsigned int data
        stackAddrSize = (<Segment>self.registers.segments.ss).segSize
        data = self.registers.regReadUnsigned(CPU_REGISTER_SP, stackAddrSize)
        data = self.registers.mmReadValueUnsigned(data, self.registers.operSize, (<Segment>self.registers.segments.ss), False)
        if (increaseStackAddr):
            self.registers.regAdd(CPU_REGISTER_SP, self.registers.operSize, stackAddrSize)
        return data
    cdef int stackPushValue(self, unsigned int value, unsigned char operSize, unsigned char segmentSource) except BITMASK_BYTE:
        cdef unsigned char stackAddrSize
        cdef unsigned int stackAddr
        stackAddrSize = (<Segment>self.registers.segments.ss).segSize
        stackAddr = self.registers.regReadUnsigned(CPU_REGISTER_SP, stackAddrSize)
        stackAddr = (stackAddr-operSize)
        if (stackAddrSize == OP_SIZE_WORD):
            stackAddr = <unsigned short>stackAddr
        if (self.registers.protectedModeOn and not (<Segment>self.registers.segments.ss).isAddressInLimit(stackAddr, operSize)):
            raise HirnwichseException(CPU_EXCEPTION_SS, 0)
        if (self.registers.protectedModeOn and self.registers.pagingOn): # TODO: HACK
             self.registers.segments.paging.getPhysicalAddress((<Segment>self.registers.segments.ss).base+stackAddr, operSize, True)
        self.registers.regWrite(CPU_REGISTER_SP, stackAddr, stackAddrSize)
        if (operSize == OP_SIZE_WORD or segmentSource):
            value = <unsigned short>value
        self.registers.mmWriteValue(stackAddr, value, operSize, (<Segment>self.registers.segments.ss), False)
        return True
    cdef int stackPushSegment(self, Segment segment, unsigned char operSize) except BITMASK_BYTE:
        return self.stackPushValue(self.registers.segRead(segment.segId), operSize, True)
    cdef int stackPushRegId(self, unsigned short regId, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned int value
        value = self.registers.regReadUnsigned(regId, operSize)
        return self.stackPushValue(value, operSize, False)
    cdef int pushIMM(self, unsigned char immIsByte) except BITMASK_BYTE:
        cdef unsigned int value
        if (immIsByte):
            value = self.registers.getCurrentOpcodeAddSignedByte()
        else:
            value = self.registers.getCurrentOpcodeAddUnsigned(self.registers.operSize)
        if (self.registers.operSize == OP_SIZE_WORD):
            value = <unsigned short>value
        return self.stackPushValue(value, self.registers.operSize, False)
    cdef int imulR_RM_ImmFunc(self, unsigned char immIsByte) except BITMASK_BYTE:
        cdef signed int operOp1
        cdef signed long int operOp2
        cdef unsigned int operSum, bitMask
        bitMask = BITMASKS_FF[self.registers.operSize]
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        operOp1 = self.modRMInstance.modRMLoadSigned(self.registers.operSize)
        if (immIsByte):
            operOp2 = self.registers.getCurrentOpcodeAddSignedByte()
            operOp2 &= bitMask
        else:
            operOp2 = self.registers.getCurrentOpcodeAddSigned(self.registers.operSize)
        operSum = (operOp1*operOp2)&bitMask
        self.modRMInstance.modRSave(self.registers.operSize, operSum, OPCODE_SAVE)
        self.registers.setFullFlags(operOp1, operOp2, self.registers.operSize, OPCODE_IMUL)
        return True
    cdef int opcodeGroup1_RM_ImmFunc(self, unsigned char operSize, unsigned char immIsByte) except BITMASK_BYTE:
        cdef unsigned char operOpcodeId
        cdef unsigned int operOp1, operOp2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        if (self.main.debugEnabled):
            self.main.debug("Group1_RM_ImmFunc: operOpcodeId=={0:d}", operOpcodeId)
        operOp1 = self.modRMInstance.modRMLoadUnsigned(operSize)
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
            self.modRMInstance.modRMSave(operSize, operOp2, operOpcodeId)
            self.registers.setFullFlags(operOp1, operOp2, operSize, operOpcodeId)
        elif (operOpcodeId in (GROUP1_OP_AND, GROUP1_OP_OR, GROUP1_OP_XOR)):
            if (operOpcodeId == GROUP1_OP_AND):
                operOpcodeId = OPCODE_AND
            elif (operOpcodeId == GROUP1_OP_OR):
                operOpcodeId = OPCODE_OR
            elif (operOpcodeId == GROUP1_OP_XOR):
                operOpcodeId = OPCODE_XOR
            operOp2 = self.modRMInstance.modRMSave(operSize, operOp2, operOpcodeId)
            self.registers.setSZP_COA(operOp2, operSize)
        elif (operOpcodeId == GROUP1_OP_CMP):
            self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_SUB)
        else:
            self.main.notice("opcodeGroup1_RM16_32_IMM8: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise HirnwichseException(CPU_EXCEPTION_UD)
        return True
    cdef int opcodeGroup3_RM_ImmFunc(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char operOpcodeId
        cdef unsigned int operOp2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        if (self.main.debugEnabled):
            self.main.debug("Group3_RM_ImmFunc: operOpcodeId=={0:d}", operOpcodeId)
        operOp2 = self.registers.getCurrentOpcodeAddUnsigned(operSize) # operImm
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.modRMInstance.modRMSave(operSize, operOp2, OPCODE_SAVE)
        else:
            self.main.notice("opcodeGroup3_RM16_32_IMM16_32: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise HirnwichseException(CPU_EXCEPTION_UD)
        return True
    cdef int opcodeGroup0F(self) except BITMASK_BYTE:
        cdef unsigned char operOpcode, bitSize, byteSize, operOpcodeMod, operOpcodeModId, newCF, oldOF, count, eaxIsInvalid, cpl, segType, protectedModeOn
        cdef unsigned short limit
        cdef unsigned int eaxId, bitMask, bitMaskHalf, base, mmAddr, op1, op2
        cdef unsigned long int qop1, qop2
        cdef signed short i
        cdef signed int sop1, sop2
        cdef GdtEntry gdtEntry = None
        protectedModeOn = self.registers.protectedModeOn and not self.registers.vm
        cpl = self.registers.getCPL()
        operOpcode = self.registers.getCurrentOpcodeAddUnsignedByte()
        if (self.main.debugEnabled):
            self.main.debug("Group0F: Opcode=={0:#04x}", operOpcode)
        if (operOpcode == 0x00): # LLDT/SLDT LTR/STR VERR/VERW
            if (not protectedModeOn):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            operOpcodeModId = self.modRMInstance.reg
            if (self.main.debugEnabled):
                self.main.debug("Group0F_00: operOpcodeModId=={0:d}", operOpcodeModId)
            if (operOpcodeModId in (0, 1)): # SLDT/STR
                byteSize = OP_SIZE_WORD
                if (self.modRMInstance.mod == 3):
                    byteSize = OP_SIZE_DWORD
                if (operOpcodeModId == 0): # SLDT
                    self.modRMInstance.modRMSave(byteSize, (<Segments>self.registers.segments).ldtr, OPCODE_SAVE)
                elif (operOpcodeModId == 1): # STR
                    self.modRMInstance.modRMSave(byteSize, (<Segment>self.registers.segments.tss).segmentIndex, OPCODE_SAVE)
                    self.main.notice("opcodeGroup0F_00_STR: TR isn't fully supported yet.")
            elif (operOpcodeModId in (2, 3)): # LLDT/LTR
                if (cpl != 0):
                    self.main.notice("Group0F_00_2_3: cpl=={0:d}", cpl)
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                op1 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
                if (operOpcodeModId == 2): # LLDT
                    self.main.notice("Opcode0F_01::LLDT: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                    if (not (op1>>2)):
                        if (self.main.debugEnabled):
                            self.main.debug("Opcode0F_01::LLDT: (op1>>2) == 0, mark LDTR as invalid. (LDTR: {0:#06x})", op1)
                        op1 = 0
                    else:
                        if ((op1 & SELECTOR_USE_LDT) or not self.registers.segments.inLimit(op1)):
                            raise HirnwichseException(CPU_EXCEPTION_GP, op1)
                        segType = self.registers.segments.getSegType(op1)
                        if (segType != TABLE_ENTRY_SYSTEM_TYPE_LDT):
                            raise HirnwichseException(CPU_EXCEPTION_GP, op1)
                        op1 &= 0xfff8
                        gdtEntry = <GdtEntry>self.registers.segments.gdt.getEntry(op1)
                        if (gdtEntry is None):
                            self.main.notice("Opcode0F_01::LLDT: gdtEntry is invalid, mark LDTR as invalid.")
                            op1 = 0
                        if (not gdtEntry.segPresent):
                            raise HirnwichseException(CPU_EXCEPTION_NP, op1)
                    self.main.notice("Opcode0F_01::LLDT: TODO! op1=={0:#06x}", op1)
                    (<Segments>self.registers.segments).ldtr = op1
                    if (gdtEntry):
                        (<Gdt>self.registers.segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
                    else:
                        #self.main.debugEnabled = True
                        self.main.notice("Opcode0F_01::LLDT: gdtEntry is invalid, mark LDTR as invalid; load tableposition 0, 0.")
                        (<Gdt>self.registers.segments.ldt).loadTablePosition(0, 0)
                elif (operOpcodeModId == 3): # LTR
                    if (not (op1&0xfff8)):
                        self.main.notice("opcodeGroup0F_00_LTR: exception_test_1 (op1: {0:#06x})", op1)
                        raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                    elif ((op1 & SELECTOR_USE_LDT) or not self.registers.segments.inLimit(op1)):
                        self.main.notice("opcodeGroup0F_00_LTR: exception_test_2 (op1: {0:#06x}; c1: {1:d}; c2: {2:d})", op1, (op1 & SELECTOR_USE_LDT)!=0, not self.registers.segments.inLimit(op1))
                        raise HirnwichseException(CPU_EXCEPTION_GP, op1)
                    gdtEntry = <GdtEntry>self.registers.segments.getEntry(op1)
                    if (gdtEntry is None):
                        self.main.notice("opcodeGroup0F_00_LTR: test3")
                        raise HirnwichseException(CPU_EXCEPTION_GP, op1)
                    if (not gdtEntry.segPresent):
                        raise HirnwichseException(CPU_EXCEPTION_NP, op1)
                    segType = (gdtEntry.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK)
                    if (segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS)):
                        self.main.notice("opcodeGroup0F_00_LTR: segType {0:d} not a TSS or is busy.)", segType)
                        raise HirnwichseException(CPU_EXCEPTION_GP, op1)
                    self.registers.segments.setSegType(op1, segType | 0x2)
                    if (segType == TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS):
                        if (gdtEntry.limit != TSS_MIN_16BIT_HARD_LIMIT):
                            self.main.notice("opcodeGroup0F_00_LTR: tssLimit {0:#06x} != TSS_MIN_16BIT_HARD_LIMIT {1:#06x}.", gdtEntry.limit, TSS_MIN_16BIT_HARD_LIMIT)
                            op1 = 0
                    elif (segType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                        if (gdtEntry.limit < TSS_MIN_32BIT_HARD_LIMIT):
                            self.main.notice("opcodeGroup0F_00_LTR: tssLimit {0:#06x} < TSS_MIN_32BIT_HARD_LIMIT {1:#06x}.", gdtEntry.limit, TSS_MIN_32BIT_HARD_LIMIT)
                            op1 = 0
                    else:
                        self.main.exitError("opcodeGroup0F_00_LTR: segType {0:d} might be busy.)", segType)
                        return True
                    self.registers.segWriteSegment((<Segment>self.registers.segments.tss), op1)
                    self.main.notice("opcodeGroup0F_00_LTR: TR isn't fully supported yet.")
            elif (operOpcodeModId == 4): # VERR
                op1 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
                self.registers.zf = (<Segments>self.registers.segments).checkReadAllowed(op1)
            elif (operOpcodeModId == 5): # VERW
                op1 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
                self.registers.zf = (<Segments>self.registers.segments).checkWriteAllowed(op1)
            else:
                self.main.notice("opcodeGroup0F_00: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x01): # LGDT/LIDT SGDT/SIDT SMSW/LMSW
            operOpcodeMod = self.registers.getCurrentOpcodeUnsignedByte()
            if (self.main.debugEnabled):
                self.main.debug("Group0F_01: operOpcodeMod=={0:#02x}", operOpcodeMod)
            if (operOpcodeMod == 0xc1): # VMCALL
                self.main.notice("opcodeGroup0F_01: VMCALL isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc2): # VMLAUNCH
                self.main.notice("opcodeGroup0F_01: VMLAUNCH isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc3): # VMRESUME
                self.main.notice("opcodeGroup0F_01: VMRESUME isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc4): # VMXOFF
                self.main.notice("opcodeGroup0F_01: VMXOFF isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc8): # MONITOR
                self.main.notice("opcodeGroup0F_01: MONITOR isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc9): # MWAIT
                self.main.notice("opcodeGroup0F_01: MWAIT isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xca): # CLAC
                self.main.notice("opcodeGroup0F_01: CLAC isn't fully supported yet.")
                if (cpl != 0):
                    raise HirnwichseException(CPU_EXCEPTION_UD)
                self.clac()
            elif (operOpcodeMod == 0xcb): # STAC
                self.main.notice("opcodeGroup0F_01: STAC isn't fully supported yet.")
                if (cpl != 0):
                    raise HirnwichseException(CPU_EXCEPTION_UD)
                self.stac()
            elif (operOpcodeMod == 0xd0): # XGETBV
                self.main.notice("opcodeGroup0F_01: XGETBV isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xd1): # XSETBV
                self.main.notice("opcodeGroup0F_01: XSETBV isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xd4): # VMFUNC
                self.main.notice("opcodeGroup0F_01: VMFUNC isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xd5): # XEND
                self.main.notice("opcodeGroup0F_01: XEND isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xd6): # XTEST
                self.main.notice("opcodeGroup0F_01: XTEST isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xee): # RDPKRU
                self.main.notice("opcodeGroup0F_01: RDPKRU isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xef): # WRPKRU
                self.main.notice("opcodeGroup0F_01: WRPKRU isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xf8): # SWAPGS
                self.main.notice("opcodeGroup0F_01: SWAPGS isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xf9): # RDTSCP
                self.main.notice("opcodeGroup0F_01: RDTSCP isn't supported yet.")
                raise HirnwichseException(CPU_EXCEPTION_UD)
            else:
                operOpcodeModId = (operOpcodeMod>>3)&7
                if (operOpcodeModId in (0, 1, 2, 3, 7)): # SGDT/SIDT LGDT/LIDT INVLPG
                    self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
                    if (self.modRMInstance.mod == 3):
                        raise HirnwichseException(CPU_EXCEPTION_UD)
                elif (operOpcodeModId in (4, 6)): # SMSW/LMSW
                    self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
                else:
                    self.main.notice("Group0F_01: operOpcodeModId not in (0, 1, 2, 3, 4, 6, 7)")
                if (operOpcodeModId in (2, 3, 6, 7) and cpl != 0):
                    self.main.notice("Group0F_01_2_3_6_7: cpl=={0:d}", cpl)
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                mmAddr = self.modRMInstance.getRMValueFull(self.registers.addrSize)
                if (operOpcodeModId in (0, 1)): # SGDT/SIDT
                    if (operOpcodeModId == 0): # SGDT
                        (<Gdt>self.registers.segments.gdt).getBaseLimit(&base, &limit)
                    elif (operOpcodeModId == 1): # SIDT
                        (<Idt>self.registers.segments.idt).getBaseLimit(&base, &limit)
                    if (self.registers.operSize == OP_SIZE_WORD):
                        base &= 0xffffff
                    self.registers.mmWriteValue(mmAddr, limit, OP_SIZE_WORD, (<Segment>self.registers.segments.ds), True)
                    self.registers.mmWriteValue(mmAddr+OP_SIZE_WORD, base, OP_SIZE_DWORD, (<Segment>self.registers.segments.ds), True)
                elif (operOpcodeModId in (2, 3)): # LGDT/LIDT
                    limit = self.registers.mmReadValueUnsignedWord(mmAddr, (<Segment>self.registers.segments.ds), True)
                    base = self.registers.mmReadValueUnsignedDword(mmAddr+OP_SIZE_WORD, (<Segment>self.registers.segments.ds), True)
                    if (self.registers.operSize == OP_SIZE_WORD):
                        base &= 0xffffff
                    if (operOpcodeModId == 2): # LGDT
                        (<Gdt>self.registers.segments.gdt).loadTablePosition(base, limit)
                    elif (operOpcodeModId == 3): # LIDT
                        if (protectedModeOn and base and not limit):
                            self.main.exitError("Opcodes::LIDT: limit is zero.")
                            return True
                        (<Idt>self.registers.segments.idt).loadTable(base, limit)
                elif (operOpcodeModId == 4): # SMSW
                    byteSize = OP_SIZE_WORD
                    if (self.modRMInstance.mod == 3):
                        byteSize = OP_SIZE_DWORD
                    op2 = self.registers.regReadUnsignedWord(CPU_REGISTER_CR0)
                    self.modRMInstance.modRMSave(byteSize, op2, OPCODE_SAVE)
                    self.main.notice("opcodeGroup0F_01: SMSW isn't fully supported yet.")
                elif (operOpcodeModId == 6): # LMSW
                    self.main.notice("opcodeGroup0F_01: LMSW isn't fully supported yet.")
                    op1 = self.registers.regReadUnsignedDword(CPU_REGISTER_CR0)
                    op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
                    if ((op1&1) and not (op2&1)): # it's already in protected mode, but it tries to switch to real mode...
                        self.main.exitError("opcodeGroup0F_01: LMSW: tried to switch to real mode from protected mode.")
                        return True
                    op1 = ((op1&0xfffffff0)|(op2&0xf))
                    self.registers.regWriteDword(CPU_REGISTER_CR0, op1)
                    #self.registers.syncCR0State()
                elif (operOpcodeModId == 7): # INVLPG
                    if (self.registers.protectedModeOn and self.registers.pagingOn): # TODO: HACK
                        (<Paging>self.registers.segments.paging).invalidateTables(self.registers.regReadUnsignedDword(CPU_REGISTER_CR3), False)
                        #(<Paging>self.registers.segments.paging).invalidatePage(self.modRMInstance.getRMValueFull(OP_SIZE_DWORD))
                    self.registers.reloadCpuCache()
                else:
                    self.main.notice("opcodeGroup0F_01: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                    raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x02): # LAR
            self.main.notice("Opcodes::opcodeGroup0F: LAR: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
            if (not protectedModeOn):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
            if (not self.registers.segments.inLimit(op2)):
                self.registers.zf = False
                self.main.notice("Opcodes::opcodeGroup0F: LAR: test1!")
                return True
            gdtEntry = <GdtEntry>self.registers.segments.getEntry(op2)
            if (gdtEntry is None):
                self.main.exitError("Opcodes::LAR: not gdtEntry")
                return True
            segType = self.registers.segments.getSegType(op2)
            if ((not gdtEntry.segIsConforming and ((cpl > gdtEntry.segDPL) or ((op2&3) > gdtEntry.segDPL))) or \
              (not (segType&0x10) and segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_LDT, \
              TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_16BIT_CALL_GATE, TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE, \
              TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_CALL_GATE))):
                self.registers.zf = False
                self.main.notice("Opcodes::opcodeGroup0F: LAR: test2!")
                self.main.notice("Opcodes::opcodeGroup0F: LAR: test2.1! (c1=={0:d}; c2=={1:d}; c3=={2:d}; c4=={3:d}; c5=={4:#04x})", not gdtEntry.segIsConforming, (cpl > gdtEntry.segDPL), ((op2&3) > gdtEntry.segDPL), (segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_LDT, TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_16BIT_CALL_GATE, TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_CALL_GATE)), segType)
                return True
            op1 = gdtEntry.accessByte << 8
            if (self.registers.operSize == OP_SIZE_DWORD):
                op1 |= ((gdtEntry.flags & GDT_FLAG_AVAILABLE) != 0) << 20
                op1 |= ((gdtEntry.flags & GDT_FLAG_LONGMODE) != 0) << 21
                op1 |= (gdtEntry.segSize == OP_SIZE_DWORD) << 22
                op1 |= gdtEntry.segUse4K << 23
            self.main.notice("Opcodes::opcodeGroup0F: LAR: test2.2! (op1=={0:#010x}; op2=={1:#06x})", op1, op2)
            self.modRMInstance.modRSave(self.registers.operSize, op1, OPCODE_SAVE)
            self.registers.zf = True
        elif (operOpcode == 0x03): # LSL
            self.main.notice("Opcodes::opcodeGroup0F: LSL: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
            if (not protectedModeOn):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
            if (not self.registers.segments.inLimit(op2)):
                self.registers.zf = False
                self.main.notice("Opcodes::opcodeGroup0F: LSL: test1!")
                return True
            gdtEntry = <GdtEntry>self.registers.segments.getEntry(op2)
            if (gdtEntry is None):
                self.main.exitError("Opcodes::LSL: not gdtEntry")
                return True
            segType = self.registers.segments.getSegType(op2)
            if ((not gdtEntry.segIsConforming and ((cpl > gdtEntry.segDPL) or ((op2&3) > gdtEntry.segDPL))) or \
              (not (segType&0x10) and segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_LDT, \
              TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY))):
                self.registers.zf = False
                self.main.notice("Opcodes::opcodeGroup0F: LSL: test2!")
                self.main.notice("Opcodes::opcodeGroup0F: LSL: test2.1! (c1=={0:d}; c2=={1:d}; c3=={2:d}; c4=={3:d}; c5=={4:#04x})", not gdtEntry.segIsConforming, (cpl > gdtEntry.segDPL), ((op2&3) > gdtEntry.segDPL), (segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_LDT, TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY)), segType)
                return True  
            op1 = gdtEntry.limit
            if ((gdtEntry.flags & GDT_FLAG_USE_4K)):
                op1 <<= 12
                op1 |= 0xfff
            if (self.registers.operSize == OP_SIZE_WORD):
                op1 = <unsigned short>op1
            self.modRMInstance.modRSave(self.registers.operSize, op1, OPCODE_SAVE)
            self.registers.zf = True
        elif (operOpcode == 0x05): # LOADALL (286, undocumented)
            self.main.notice("opcodeGroup0F_05: LOADALL 286 opcode isn't supported yet.")
            raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x07): # LOADALL (386, undocumented)
            self.main.notice("opcodeGroup0F_07: LOADALL 386 opcode isn't supported yet.")
            raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (operOpcode in (0x06, 0x08, 0x09)): # 0x06: CLTS, 0x08: INVD, 0x09: WBINVD
            if (cpl != 0):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            if (operOpcode == 0x06): # CLTS
                self.registers.regAndDword(CPU_REGISTER_CR0, ~CR0_FLAG_TS)
            elif (operOpcode == 0x08): # INVD
                self.main.notice("Opcodes::opcodeGroup0F: INVD/WBINVD: TODO!")
            elif (operOpcode == 0x09): # WBINVD
                self.main.notice("Opcodes::opcodeGroup0F: WBINVD: TODO!")
        elif (operOpcode == 0x0b): # UD2
            self.main.notice("Opcodes::opcodeGroup0F: UD2!")
            raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x20): # MOV R32, CRn
            if (cpl != 0):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_CREG)
            if (self.modRMInstance.regName not in (CPU_REGISTER_CR0, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4)):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            elif (self.modRMInstance.regName == CPU_REGISTER_CR2):
                self.main.notice("TODO: MOV R32, CR2")
            # We need to 'ignore' mod to read the source/dest as a register. That's the way to do it.
            if (self.modRMInstance.mod != 3):
                self.main.exitError("Opcodes::MOV_R32_CRn: mod != 3")
                return True
            self.modRMInstance.modRMSave(OP_SIZE_DWORD, self.modRMInstance.modRLoadUnsigned(OP_SIZE_DWORD), OPCODE_SAVE)
        elif (operOpcode == 0x21): # MOV R32, DRn
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_DREG)
            self.modRMInstance.modRMSave(OP_SIZE_DWORD, self.modRMInstance.modRLoadUnsigned(OP_SIZE_DWORD), OPCODE_SAVE)
        elif (operOpcode == 0x22): # MOV CRn, R32
            if (cpl != 0):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_CREG)
            if (self.modRMInstance.regName not in (CPU_REGISTER_CR0, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4)):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            # We need to 'ignore' mod to read the source/dest as a register. That's the way to do it.
            if (self.modRMInstance.mod != 3):
                self.main.exitError("Opcodes::MOV_CRn_R32: mod != 3")
                return True
            op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_DWORD)
            if (self.modRMInstance.regName == CPU_REGISTER_CR0):
                op1 = self.registers.regReadUnsignedDword(CPU_REGISTER_CR0) # op1 == old CR0
                if ((op2 & CR0_FLAG_PG) and not (op2 & CR0_FLAG_PE)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            self.modRMInstance.modRSave(OP_SIZE_DWORD, op2, OPCODE_SAVE)
            if (self.modRMInstance.regName == CPU_REGISTER_CR0):
                self.registers.pagingOn = (op2 & CR0_FLAG_PG)!=0
                self.registers.writeProtectionOn = (op2 & CR0_FLAG_WP)!=0
                self.registers.cacheDisabled = (op2 & CR0_FLAG_CD)!=0
                if (((op1 & (CR0_FLAG_PG | CR0_FLAG_CD | CR0_FLAG_NW | CR0_FLAG_WP)) != (op2 & (CR0_FLAG_PG | CR0_FLAG_CD | CR0_FLAG_NW | CR0_FLAG_WP))) and self.registers.pagingOn):
                    (<Paging>self.registers.segments.paging).invalidateTables(self.registers.regReadUnsignedDword(CPU_REGISTER_CR3), False)
                #self.registers.syncCR0State()
            elif (self.modRMInstance.regName == CPU_REGISTER_CR2):
                self.main.notice("TODO: MOV CR2, R32")
            elif (self.modRMInstance.regName == CPU_REGISTER_CR4):
                if (op2):
                    self.main.exitError("opcodeGroup0F_22: CR4 IS NOT FULLY SUPPORTED yet.")
                elif (op2 & CR4_FLAG_VME):
                    self.main.exitError("opcodeGroup0F_22: VME (virtual-8086 mode extension) IS NOT SUPPORTED yet.")
                elif (op2 & CR4_FLAG_PSE):
                    self.main.exitError("opcodeGroup0F_22: PSE (page-size extension) IS NOT SUPPORTED yet.")
                elif (op2 & CR4_FLAG_PAE):
                    self.main.exitError("opcodeGroup0F_22: PAE (physical-address extension) IS NOT SUPPORTED yet.")
        elif (operOpcode == 0x23): # MOV DRn, R32
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_DREG)
            self.modRMInstance.modRSave(OP_SIZE_DWORD, self.modRMInstance.modRMLoadUnsigned(OP_SIZE_DWORD), OPCODE_SAVE)
        elif (operOpcode in (0x30, 0x31, 0x32)): # WRMSR, RDTSC, RDMSR
            self.main.notice("Opcodes::opcodeGroup0F: WRMSR/RDTSC/RDMSR: TODO!")
            raise HirnwichseException(CPU_EXCEPTION_UD)
            if (operOpcode == 0x31 and self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_TSD) != 0 and cpl != 0 and self.registers.protectedModeOn): # RDTSC
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            elif (cpl != 0):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            eaxId = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
            eaxIsInvalid = (eaxId >= 0x40000000 and eaxId <= 0x400000ff)
            if (operOpcode != 0x31 and eaxIsInvalid):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            if (operOpcode == 0x31 or (operOpcode == 0x32 and eaxId == 0x10)):
                self.registers.regWriteDword(CPU_REGISTER_EAX, <unsigned int>(self.main.cpu.cycles))
                self.registers.regWriteDword(CPU_REGISTER_EDX, <unsigned int>(self.main.cpu.cycles>>32))
            elif (operOpcode == 0x30 and eaxId == 0x10):
                self.main.cpu.cycles = self.registers.regReadUnsignedDword(CPU_REGISTER_EAX)
                self.main.cpu.cycles |= <unsigned long int>self.registers.regReadUnsignedDword(CPU_REGISTER_EDX)<<32
            elif (eaxId == 0x8b): # no microcode loaded or rather supported.
                pass
            else:
                self.main.notice("Opcodes::group0F: MSR: Unimplemented! (operOpcode=={0:#04x}; ECX=={1:#010x})", operOpcode, eaxId)
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        elif (operOpcode == 0x38): # MOVBE
            self.main.notice("Opcodes::opcodeGroup0F: MOVBE: TODO!")
            operOpcodeMod = self.registers.getCurrentOpcodeAddUnsignedByte()
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            if (operOpcodeMod == 0xf0): # MOVBE R16_32, M16_32
                op2 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize)
                op2 = (<Misc>self.main.misc).reverseByteOrder(op2, self.registers.operSize)
                self.modRMInstance.modRSave(self.registers.operSize, op2, OPCODE_SAVE)
            elif (operOpcodeMod == 0xf1): # MOVBE M16_32, R16_32
                op2 = self.modRMInstance.modRLoadUnsigned(self.registers.operSize)
                op2 = (<Misc>self.main.misc).reverseByteOrder(op2, self.registers.operSize)
                self.modRMInstance.modRMSave(self.registers.operSize, op2, OPCODE_SAVE)
            else:
                self.main.exitError("MOVBE: operOpcodeMod {0:#04x} not in (0xf0, 0xf1)", operOpcodeMod)
        elif (operOpcode >= 0x40 and operOpcode <= 0x4f): # CMOVcc ;; R16, R/M 16; R32, R/M 32
            self.main.notice("Opcodes::cmovFunc: TODO!")
            self.movR_RM(self.registers.operSize, self.registers.getCond(operOpcode&0xf))
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
            self.main.notice("Opcodes::opcodeGroup0F: CPUID: TODO! (eax; {0:#010x})", eaxId)
            #eaxIsInvalid = (eaxId >= 0x40000000 and eaxId <= 0x4fffffff)
            IF 0:
                if (eaxId in (0x2, 0x3, 0x4, 0x5, 0x80000001, 0x80000005, 0x80000006, 0x80000007)):
                    self.registers.regWriteDword(CPU_REGISTER_EAX, 0x0)
                    self.registers.regWriteDword(CPU_REGISTER_EBX, 0x0)
                    self.registers.regWriteDword(CPU_REGISTER_EDX, 0x0)
                    self.registers.regWriteDword(CPU_REGISTER_ECX, 0x0)
                elif (eaxId == 0x80000000):
                    self.registers.regWriteDword(CPU_REGISTER_EAX, 0x80000007)
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
            if (eaxId & 0x70000000):
                self.main.exitError("Opcodes::opcodeGroup0F: CPUID test1: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x}; eax; {2:#010x})", self.main.cpu.savedEip, self.main.cpu.savedCs, eaxId)
            elif (eaxId & 0x80000000):
                self.main.notice("Opcodes::opcodeGroup0F: CPUID test2: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x}; eax; {2:#010x})", self.main.cpu.savedEip, self.main.cpu.savedCs, eaxId)
                self.registers.regWriteDword(CPU_REGISTER_EAX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_EBX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_EDX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_ECX, 0x0)
            elif (eaxId >= 0x1):
                self.main.notice("Opcodes::opcodeGroup0F: CPUID test4: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x}; eax; {2:#010x})", self.main.cpu.savedEip, self.main.cpu.savedCs, eaxId)
                self.registers.regWriteDword(CPU_REGISTER_EAX, 0x421)
                #self.registers.regWriteDword(CPU_REGISTER_EBX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_EBX, 0x10000)
                #self.registers.regWriteDword(CPU_REGISTER_EDX, 0x8112)
                #self.registers.regWriteDword(CPU_REGISTER_EDX, 0x8102) # TODO: HACK for freq calibrating functions. don't declare tsc support.
                #self.registers.regWriteDword(CPU_REGISTER_EDX, 0x8100) # TODO: HACK for freq calibrating functions. don't declare tsc support.; don't declare vme because cr4 is TODO
                #self.registers.regWriteDword(CPU_REGISTER_ECX, 0xc00020)
                self.registers.regWriteDword(CPU_REGISTER_EDX, 0x0)
                self.registers.regWriteDword(CPU_REGISTER_ECX, 0x0)
            else:
                self.main.notice("Opcodes::opcodeGroup0F: CPUID test3: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x}; eax; {2:#010x})", self.main.cpu.savedEip, self.main.cpu.savedCs, eaxId)
                #if (not (eaxId == 0x0 or eaxIsInvalid)):
                #    self.main.notice("CPUID: eaxId {0:#04x} unknown.", eaxId)
                #self.registers.regWriteDword(CPU_REGISTER_EAX, 0x5)
                self.registers.regWriteDword(CPU_REGISTER_EAX, 0x1)
                self.registers.regWriteDword(CPU_REGISTER_EBX, 0x756e6547)
                self.registers.regWriteDword(CPU_REGISTER_EDX, 0x49656e69)
                self.registers.regWriteDword(CPU_REGISTER_ECX, 0x6c65746e)
        elif (operOpcode == 0xa3): # BT RM16/32, R16/R32
            self.btFunc(BT_NONE)
        elif (operOpcode in (0xa4, 0xa5)): # SHLD
            self.main.notice("Opcodes::opcodeGroup0F: SHLD: TODO!")
            bitMaskHalf = BITMASKS_80[self.registers.operSize]
            bitSize = self.registers.operSize << 3
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            if (operOpcode == 0xa4): # SHLD imm8
                count = self.registers.getCurrentOpcodeAddUnsignedByte()
                if (count > 0x1f):
                    self.main.notice("SHLD: count > 0x1f...")
            elif (operOpcode == 0xa5): # SHLD CL
                count = self.registers.regReadUnsignedLowByte(CPU_REGISTER_CL)
                count &= 0x1f
            else:
                self.main.exitError("group0F::SHLD: operOpcode {0:#04x} unknown.", operOpcode)
                return True
            if (not count):
                return True
            if (count >= bitSize):
                self.main.notice("SHLD: count >= bitSize...")
            if (count > bitSize): # bad parameters
                self.main.exitError("group0F: SHLD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).", count, bitSize, operOpcode)
                return True
            op1 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize) # dest
            oldOF = (op1&bitMaskHalf)!=0
            op2  = self.modRMInstance.modRLoadUnsigned(self.registers.operSize) # src
            newCF = self.registers.valGetBit(op1, bitSize-count)
            for i in range(bitSize-1, count-1, -1):
                tmpBit = self.registers.valGetBit(op1, i-count)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            for i in range(count-1, -1, -1):
                tmpBit = self.registers.valGetBit(op2, i-count+bitSize)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            self.modRMInstance.modRMSave(self.registers.operSize, op1, OPCODE_SAVE)
            self.registers.of = oldOF!=((op1&bitMaskHalf)!=0) if (count == 1) else False
            self.registers.cf = newCF
            self.registers.setSZP_A(op1, self.registers.operSize)
        elif (operOpcode == 0xa8): # PUSH GS
            self.pushSeg(PUSH_GS)
        elif (operOpcode == 0xa9): # POP GS
            self.popSeg(POP_GS)
        elif (operOpcode == 0xab): # BTS RM16/32, R16/32
            self.btFunc(BT_SET)
        elif (operOpcode in (0xac, 0xad)): # SHRD
            bitMaskHalf = BITMASKS_80[self.registers.operSize]
            bitSize = self.registers.operSize << 3
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            if (operOpcode == 0xac): # SHRD imm8
                self.main.notice("Opcodes::opcodeGroup0F: SHRD_imm8: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                count = self.registers.getCurrentOpcodeAddUnsignedByte()
            elif (operOpcode == 0xad): # SHRD CL
                self.main.notice("Opcodes::opcodeGroup0F: SHRD_CL: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                count = self.registers.regReadUnsignedLowByte(CPU_REGISTER_CL)
            else:
                self.main.exitError("group0F::SHRD: operOpcode {0:#04x} unknown.", operOpcode)
                return True
            if (count != 1 and self.registers.of):
                self.main.notice("Opcodes::opcodeGroup0F: SHRD: OF is SET! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                self.main.cpu.cpuDump()
            count &= 0x1f
            if (not count):
                return True
            if (count >= bitSize):
                self.main.notice("SHRD: count >= bitSize...")
            if (count > bitSize): # bad parameters
                self.main.exitError("group0F: SHRD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).", count, bitSize, operOpcode)
                return True
            op1 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize) # dest
            oldOF = (op1&bitMaskHalf)!=0
            op2  = self.modRMInstance.modRLoadUnsigned(self.registers.operSize) # src
            newCF = self.registers.valGetBit(op1, count-1)
            for i in range(bitSize-count):
                tmpBit = self.registers.valGetBit(op1, i+count)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            for i in range(bitSize-count, bitSize):
                tmpBit = self.registers.valGetBit(op2, i+count-bitSize)
                op1 = self.registers.valSetBit(op1, i, tmpBit)
            self.modRMInstance.modRMSave(self.registers.operSize, op1, OPCODE_SAVE)
            self.registers.of = oldOF!=((op1&bitMaskHalf)!=0) if (count == 1) else False
            self.registers.cf = newCF
            self.registers.setSZP_A(op1, self.registers.operSize)
            if (count != 1 and self.registers.of):
                self.main.notice("Opcodes::opcodeGroup0F: SHRD: OF were SET! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                self.main.cpu.cpuDump()
        elif (operOpcode == 0xaf): # IMUL R16_32, R/M16_32
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            sop1 = self.modRMInstance.modRLoadSigned(self.registers.operSize)
            sop2 = self.modRMInstance.modRMLoadSigned(self.registers.operSize)
            if (self.registers.operSize == OP_SIZE_WORD):
                sop1 = <signed short>sop1
                sop2 = <signed short>sop2
            op1 = <unsigned int>(sop1*sop2)
            if (self.registers.operSize == OP_SIZE_WORD):
                op1 = <unsigned short>op1
            self.modRMInstance.modRSave(self.registers.operSize, op1, OPCODE_SAVE)
            self.registers.setFullFlags(sop1, sop2, self.registers.operSize, OPCODE_IMUL)
        elif (operOpcode in (0xb0, 0xb1)): # 0xb0: CMPXCHG RM8, R8 ;; 0xb1: CMPXCHG RM16_32, R16_32
            self.main.notice("Opcodes::opcodeGroup0F: CMPXCHG: TODO!")
            byteSize = self.registers.operSize
            if (operOpcode == 0xb0): # 0xb0: CMPXCHG RM8, R8
                byteSize = OP_SIZE_BYTE
            self.modRMInstance.modRMOperands(byteSize, MODRM_FLAGS_NONE)
            op1 = self.modRMInstance.modRMLoadUnsigned(byteSize)
            op2 = self.registers.regReadUnsigned(CPU_REGISTER_AX, byteSize)
            self.registers.setFullFlags(op2, op1, byteSize, OPCODE_SUB)
            if (op2 == op1):
                self.registers.zf = True
                op2 = self.modRMInstance.modRLoadUnsigned(byteSize)
                self.modRMInstance.modRMSave(byteSize, op2, OPCODE_SAVE)
            else:
                self.registers.zf = False
                self.registers.regWrite(CPU_REGISTER_AX, op1, byteSize)
        elif (operOpcode == 0xb2): # LSS
            self.lfpFunc(CPU_SEGMENT_SS)
        elif (operOpcode == 0xb3): # BTR RM16/32, R16/32
            self.btFunc(BT_RESET)
        elif (operOpcode == 0xb4): # LFS
            self.lfpFunc(CPU_SEGMENT_FS)
        elif (operOpcode == 0xb5): # LGS
            self.lfpFunc(CPU_SEGMENT_GS)
        elif (operOpcode == 0xb8): # POPCNT R16/32 RM16/32
            self.main.notice("Opcodes::opcodeGroup0F: POPCNT: TODO!")
            if (self.registers.repPrefix):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize)
            op2 = bin(op2).count('1')
            self.modRMInstance.modRSave(self.registers.operSize, op2, OPCODE_SAVE)
            self.registers.cf = self.registers.pf = self.registers.af = self.registers.sf = self.registers.of = False
            self.registers.zf = not op2
        elif (operOpcode == 0xba): # BT/BTS/BTR/BTC RM16/32 IMM8
            self.main.notice("Opcodes::opcodeGroup0F: BT*: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            operOpcodeModId = self.modRMInstance.reg
            if (self.main.debugEnabled):
                self.main.debug("Group0F_BA: operOpcodeModId=={0:d}", operOpcodeModId)
            if (operOpcodeModId == 4): # BT
                self.btFunc(BT_IMM | BT_NONE)
            elif (operOpcodeModId == 5): # BTS
                self.btFunc(BT_IMM | BT_SET)
            elif (operOpcodeModId == 6): # BTR
                self.btFunc(BT_IMM | BT_RESET)
            elif (operOpcodeModId == 7): # BTC
                self.btFunc(BT_IMM | BT_COMPLEMENT)
            else:
                self.main.notice("opcodeGroup0F_BA: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0xbb): # BTC RM16/32, R16/32
            self.btFunc(BT_COMPLEMENT)
        elif (operOpcode == 0xbc): # BSF R16_32, R/M16_32
            self.main.notice("Opcodes::opcodeGroup0F: BSF: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
            self.main.cpu.cpuDump()
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize)
            if (op2 >= 1):
                op1 = bin(op2)[::-1].find('1')
                self.modRMInstance.modRSave(self.registers.operSize, op1, OPCODE_SAVE)
                self.registers.setSZP_COA(op1, self.registers.operSize)
            self.registers.zf = not op2
            self.main.cpu.cpuDump()
        elif (operOpcode == 0xbd): # BSR R16_32, R/M16_32
            self.main.notice("Opcodes::opcodeGroup0F: BSR: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
            self.main.cpu.cpuDump()
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize)
            if (op2 >= 1):
                op1 = op2.bit_length()-1
                self.modRMInstance.modRSave(self.registers.operSize, op1, OPCODE_SAVE)
                self.registers.setSZP_COA(op1, self.registers.operSize)
            self.registers.zf = not op2
            self.main.cpu.cpuDump()
        elif (operOpcode in (0xb6, 0xbe)): # 0xb6==MOVZX R16_32, R/M8 ;; 0xbe==MOVSX R16_32, R/M8
            self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
            self.modRMInstance.regName = self.registers.getRegNameWithFlags(MODRM_FLAGS_NONE, self.modRMInstance.reg, self.registers.operSize)
            if (operOpcode == 0xb6): # MOVZX R16_32, R/M8
                op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_BYTE)
            else: # MOVSX R16_32, R/M8
                op2 = <unsigned int>(<signed char>self.modRMInstance.modRMLoadSigned(OP_SIZE_BYTE))
                if (self.registers.operSize == OP_SIZE_WORD):
                    op2 = <unsigned short>op2
            self.modRMInstance.modRSave(self.registers.operSize, op2, OPCODE_SAVE)
        elif (operOpcode in (0xb7, 0xbf)): # 0xb7==MOVZX R32, R/M16 ;; 0xbf==MOVSX R32, R/M16
            self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            self.modRMInstance.regName = self.registers.getRegNameWithFlags(MODRM_FLAGS_NONE, self.modRMInstance.reg, OP_SIZE_DWORD)
            if (operOpcode == 0xb7): # MOVZX R32, R/M16
                op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
            else: # MOVSX R32, R/M16
                op2 = <unsigned int>(self.modRMInstance.modRMLoadSigned(OP_SIZE_WORD))
            self.modRMInstance.modRSave(OP_SIZE_DWORD, op2, OPCODE_SAVE)
        elif (operOpcode in (0xc0, 0xc1)): # 0xc0: XADD RM8, R8 ;; 0xc1: XADD RM16_32, R16_32
            self.main.notice("Opcodes::opcodeGroup0F: XADD: TODO!")
            if (operOpcode == 0xc0): # 0xc0: XADD RM8, R8
                byteSize = OP_SIZE_BYTE
            else:
                byteSize = self.registers.operSize
            self.modRMInstance.modRMOperands(byteSize, MODRM_FLAGS_NONE)
            op1 = self.modRMInstance.modRMLoadUnsigned(byteSize)
            op2 = self.modRMInstance.modRLoadUnsigned(byteSize)
            self.modRMInstance.modRMSave(byteSize, op2, OPCODE_ADD)
            self.modRMInstance.modRSave(byteSize, op1, OPCODE_SAVE)
            self.registers.setFullFlags(op1, op2, byteSize, OPCODE_ADD)
        elif (operOpcode == 0xc7): # CMPXCHG8B M64
            self.main.notice("Opcodes::opcodeGroup0F: CMPXCHG8B: TODO!")
            operOpcodeMod = self.registers.getCurrentOpcodeAddUnsignedByte()
            operOpcodeModId = (operOpcodeMod>>3)&7
            if (self.main.debugEnabled):
                self.main.debug("Group0F_C7: operOpcodeModId=={0:d}", operOpcodeModId)
            if (operOpcodeModId == 1):
                op1 = self.registers.getCurrentOpcodeAddUnsigned(self.registers.addrSize)
                qop1 = (<Mm>self.main.mm).mmPhyReadValueUnsignedQword(op1)
                qop2 = self.registers.regReadUnsignedDword(CPU_REGISTER_EDX)
                qop2 <<= 32
                qop2 |= self.registers.regReadUnsignedDword(CPU_REGISTER_EAX)
                if (qop2 == qop1):
                    self.registers.zf = True
                    qop2 = self.registers.regReadUnsignedDword(CPU_REGISTER_ECX)
                    qop2 <<= 32
                    qop2 |= self.registers.regReadUnsignedDword(CPU_REGISTER_EBX)
                    (<Mm>self.main.mm).mmPhyWriteValue(op1, qop2, OP_SIZE_QWORD)
                else:
                    self.registers.zf = False
                    self.registers.regWriteDword(CPU_REGISTER_EDX, qop1>>32)
                    self.registers.regWriteDword(CPU_REGISTER_EAX, qop1)
            else:
                self.main.notice("opcodeGroup0F_C7: operOpcodeModId {0:d} isn't supported yet.", operOpcodeModId)
                raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (operOpcode >= 0xc8 and operOpcode <= 0xcf): # BSWAP R32
            self.main.notice("Opcodes::opcodeGroup0F: BSWAP: TODO!")
            regName  = operOpcode&7
            op1 = self.registers.regReadUnsignedDword(regName)
            op1 = (<Misc>self.main.misc).reverseByteOrder(op1, OP_SIZE_DWORD)
            self.registers.regWriteDword(regName, op1)
        else:
            self.main.notice("opcodeGroup0F: invalid operOpcode. {0:#04x}", operOpcode)
            return False
        return True
    cdef int opcodeGroupFE(self) except BITMASK_BYTE:
        cdef unsigned char operOpcodeId
        self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        if (self.main.debugEnabled):
            self.main.debug("GroupFE: operOpcodeId=={0:d}", operOpcodeId)
        if (operOpcodeId == 0): # 0/INC
            return self.incFuncRM(OP_SIZE_BYTE)
        elif (operOpcodeId == 1): # 1/DEC
            return self.decFuncRM(OP_SIZE_BYTE)
        else:
            self.main.notice("opcodeGroupFE: invalid operOpcodeId. {0:d}", operOpcodeId)
        return False
    cdef int opcodeGroupFF(self) except BITMASK_BYTE:
        cdef unsigned char operOpcodeId
        cdef unsigned short segVal
        cdef unsigned int op1
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        if (self.main.debugEnabled):
            self.main.debug("GroupFF: operOpcodeId=={0:d}", operOpcodeId)
        if (operOpcodeId == 0): # 0/INC
            return self.incFuncRM(self.registers.operSize)
        elif (operOpcodeId == 1): # 1/DEC
            return self.decFuncRM(self.registers.operSize)
        elif (operOpcodeId == 2): # 2/CALL NEAR
            op1 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize)
            self.stackPushRegId(CPU_REGISTER_EIP, self.registers.operSize)
            self.registers.regWriteDword(CPU_REGISTER_EIP, op1)
        elif (operOpcodeId == 3): # 3/CALL FAR
            op1 = self.modRMInstance.getRMValueFull(self.registers.addrSize)
            segVal = self.registers.mmReadValueUnsignedWord(op1+self.registers.operSize, self.modRMInstance.rmNameSeg, True)
            op1 = self.registers.mmReadValueUnsigned(op1, self.registers.operSize, self.modRMInstance.rmNameSeg, True)
            return self.jumpFarDirect(OPCODE_CALL, segVal, op1)
        elif (operOpcodeId == 4): # 4/JMP NEAR
            op1 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize)
            self.registers.regWriteDword(CPU_REGISTER_EIP, op1)
        elif (operOpcodeId == 5): # 5/JMP FAR
            op1 = self.modRMInstance.getRMValueFull(self.registers.addrSize)
            segVal = self.registers.mmReadValueUnsignedWord(op1+self.registers.operSize, self.modRMInstance.rmNameSeg, True)
            op1 = self.registers.mmReadValueUnsigned(op1, self.registers.operSize, self.modRMInstance.rmNameSeg, True)
            return self.jumpFarDirect(OPCODE_JUMP, segVal, op1)
        elif (operOpcodeId == 6): # 6/PUSH
            op1 = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize)
            return self.stackPushValue(op1, self.registers.operSize, False)
        else:
            self.main.notice("opcodeGroupFF: invalid operOpcodeId. {0:d}", operOpcodeId)
            return False
        return True
    cdef int incFuncReg(self, unsigned short regId, unsigned char regSize) except BITMASK_BYTE:
        cdef unsigned char origCF
        cdef unsigned int origValue
        origCF = self.registers.cf
        origValue = self.registers.regReadUnsigned(regId, regSize)
        self.registers.regWrite(regId, <unsigned int>(origValue+1), regSize)
        self.registers.setFullFlags(origValue, 1, regSize, OPCODE_ADD)
        self.registers.cf = origCF
        return True
    cdef int decFuncReg(self, unsigned short regId, unsigned char regSize) except BITMASK_BYTE:
        cdef unsigned char origCF
        cdef unsigned int origValue
        origCF = self.registers.cf
        origValue = self.registers.regReadUnsigned(regId, regSize)
        self.registers.regWrite(regId, <unsigned int>(origValue-1), regSize)
        self.registers.setFullFlags(origValue, 1, regSize, OPCODE_SUB)
        self.registers.cf = origCF
        return True
    cdef int incFuncRM(self, unsigned char rmSize) except BITMASK_BYTE:
        cdef unsigned char origCF
        cdef unsigned int origValue
        origCF = self.registers.cf
        origValue = self.modRMInstance.modRMLoadUnsigned(rmSize)
        self.modRMInstance.modRMSave(rmSize, <unsigned int>(origValue+1), OPCODE_SAVE)
        self.registers.setFullFlags(origValue, 1, rmSize, OPCODE_ADD)
        self.registers.cf = origCF
        return True
    cdef int decFuncRM(self, unsigned char rmSize) except BITMASK_BYTE:
        cdef unsigned char origCF
        cdef unsigned int origValue
        origCF = self.registers.cf
        origValue = self.modRMInstance.modRMLoadUnsigned(rmSize)
        self.modRMInstance.modRMSave(rmSize, <unsigned int>(origValue-1), OPCODE_SAVE)
        self.registers.setFullFlags(origValue, 1, rmSize, OPCODE_SUB)
        self.registers.cf = origCF
        return True
    cdef int incReg(self) except BITMASK_BYTE:
        cdef unsigned short regName
        regName  = self.main.cpu.opcode&7
        return self.incFuncReg(regName, self.registers.operSize)
    cdef int decReg(self) except BITMASK_BYTE:
        cdef unsigned short regName
        regName  = self.main.cpu.opcode&7
        return self.decFuncReg(regName, self.registers.operSize)
    cdef int pushReg(self) except BITMASK_BYTE:
        cdef unsigned short regName
        regName  = self.main.cpu.opcode&7
        return self.stackPushRegId(regName, self.registers.operSize)
    cdef int popReg(self) except BITMASK_BYTE:
        cdef unsigned short regName
        regName  = self.main.cpu.opcode&7
        return self.stackPopRegId(regName, self.registers.operSize)
    cdef int pushSeg(self, unsigned char opcode) except BITMASK_BYTE:
        cdef Segment segment
        if (opcode == PUSH_CS):
            segment = (<Segment>self.registers.segments.cs)
        elif (opcode == PUSH_DS):
            segment = (<Segment>self.registers.segments.ds)
        elif (opcode == PUSH_ES):
            segment = (<Segment>self.registers.segments.es)
        elif (opcode == PUSH_FS):
            segment = (<Segment>self.registers.segments.fs)
        elif (opcode == PUSH_GS):
            segment = (<Segment>self.registers.segments.gs)
        elif (opcode == PUSH_SS):
            segment = (<Segment>self.registers.segments.ss)
        else:
            self.main.exitError("pushSeg: unknown push-opcode: {0:#04x}", opcode)
            return False
        return self.stackPushSegment(segment, self.registers.operSize)
    cdef int popSeg(self, unsigned char opcode) except BITMASK_BYTE:
        cdef Segment segment
        if (opcode == POP_DS):
            segment = (<Segment>self.registers.segments.ds)
        elif (opcode == POP_ES):
            segment = (<Segment>self.registers.segments.es)
        elif (opcode == POP_FS):
            segment = (<Segment>self.registers.segments.fs)
        elif (opcode == POP_GS):
            segment = (<Segment>self.registers.segments.gs)
        elif (opcode == POP_SS):
            self.registers.ssInhibit = True
            segment = (<Segment>self.registers.segments.ss)
        else:
            self.main.exitError("popSeg: unknown pop-opcode: {0:#04x}", opcode)
            return False
        return self.stackPopSegment(segment)
    cdef int popRM16_32(self) except BITMASK_BYTE:
        cdef unsigned char operOpcodeId
        cdef unsigned int value
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        if (operOpcodeId == 0): # POP
            value = self.stackPopValue(True)
            self.modRMInstance.modRMSave(self.registers.operSize, value, OPCODE_SAVE)
        else:
            self.main.notice("popRM16_32: unknown operOpcodeId: {0:d}", operOpcodeId)
            raise HirnwichseException(CPU_EXCEPTION_UD)
        return True
    cdef int lea(self) except BITMASK_BYTE:
        cdef unsigned int mmAddr
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        if (self.modRMInstance.mod == 3):
            raise HirnwichseException(CPU_EXCEPTION_UD)
        mmAddr = self.modRMInstance.getRMValueFull(self.registers.operSize)
        self.modRMInstance.modRSave(self.registers.operSize, mmAddr, OPCODE_SAVE)
        return True
    cdef int retNear(self, unsigned short imm) except BITMASK_BYTE:
        cdef unsigned char stackAddrSize
        cdef unsigned int tempEIP
        self.registers.syncCR0State()
        tempEIP = self.stackPopValue(True)
        if (imm):
            stackAddrSize = (<Segment>self.registers.segments.ss).segSize
            self.registers.regAdd(CPU_REGISTER_SP, imm, stackAddrSize)
        self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
        return True
    cdef int retNearImm(self) except BITMASK_BYTE:
        cdef unsigned short imm
        imm = self.registers.getCurrentOpcodeAddUnsignedWord() # imm16
        return self.retNear(imm)
    cdef int retFar(self, unsigned short imm) except BITMASK_BYTE:
        cdef GdtEntry gdtEntrySS
        cdef Segment tempSegment
        cdef unsigned char stackAddrSize, cpl
        cdef unsigned short tempCS, tempSS
        cdef unsigned int tempEIP, tempESP, oldESP
        self.registers.syncCR0State()
        stackAddrSize = (<Segment>self.registers.segments.ss).segSize
        tempEIP = self.stackPopValue(True)
        tempCS = <unsigned short>self.stackPopValue(True)
        if (imm):
            self.registers.regAdd(CPU_REGISTER_SP, imm, stackAddrSize)
        if (self.registers.protectedModeOn and not self.registers.vm):
            cpl = self.registers.getCPL()
            if ((tempCS&3) > cpl): # outer privilege level; rpl > cpl
                if (stackAddrSize == OP_SIZE_DWORD):
                    oldESP = self.registers.regReadUnsignedDword(CPU_REGISTER_ESP)
                else:
                    oldESP = self.registers.regReadUnsignedWord(CPU_REGISTER_SP)
                self.main.notice("Opcodes::ret: test1: opl: rpl > cpl")
                if ((oldESP - (8 if (self.registers.operSize == OP_SIZE_DWORD) else 4)) >= oldESP):
                    raise HirnwichseException(CPU_EXCEPTION_SS, 0)
                tempESP = self.stackPopValue(True)
                tempSS = self.stackPopValue(True)
                if (not (tempSS&0xfff8)):
                    self.main.notice("Opcodes::ret: test1: opl: rpl > cpl: test1.4")
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                if (not self.registers.segments.inLimit(tempSS)):
                    self.main.notice("Opcodes::ret: test1: opl: rpl > cpl: test1.1")
                    raise HirnwichseException(CPU_EXCEPTION_GP, tempSS)
                gdtEntrySS = <GdtEntry>self.registers.segments.getEntry(tempSS)
                if (gdtEntrySS is None):
                    self.main.exitError("Opcodes::ret: not gdtEntrySS")
                    return True
                if ((tempSS&3 != tempCS&3) or (not gdtEntrySS.segIsRW) or (gdtEntrySS.segDPL != tempCS&3)):
                    self.main.notice("Opcodes::ret: test1: opl: rpl > cpl: test1.2")
                    self.main.notice("Opcodes::ret: test1: opl: rpl > cpl: test1.3; {0:d}; {1:d}; {2:d}", (tempSS&3 != tempCS&3), (not gdtEntrySS.segIsRW), (gdtEntrySS.segDPL != tempCS&3))
                    raise HirnwichseException(CPU_EXCEPTION_GP, tempSS)
                if (not gdtEntrySS.segPresent):
                    self.main.notice("Opcodes::ret: test1: opl: rpl > cpl: test1.5")
                    raise HirnwichseException(CPU_EXCEPTION_SS, tempSS)
                for tempSegment in ((<Segment>self.registers.segments.ds), (<Segment>self.registers.segments.es), (<Segment>self.registers.segments.fs), (<Segment>self.registers.segments.gs)):
                    if (tempSegment.isValid and (not tempSegment.segIsCodeSeg or not tempSegment.segIsConforming) and (cpl > tempSegment.segDPL)):
                        self.main.notice("Opcodes::ret: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                        self.main.notice("Opcodes::ret: TODO! (segmentIndex: {0:#06x}; segDPL: {1:d}; tempCS=={2:#06x}; segId=={3:d}", tempSegment.segmentIndex, tempSegment.segDPL, tempCS, tempSegment.segId)
                        self.main.notice("Opcodes::ret: (isValid and (not codeSeg or not conforming) and (cpl > dpl)), set segments to zero")
                        self.registers.segWriteSegment(tempSegment, 0)
                tempCS &= 0xfffc
                tempCS |= cpl
                self.registers.segWriteSegment((<Segment>self.registers.segments.ss), tempSS)
                stackAddrSize = (<Segment>self.registers.segments.ss).segSize
                if (stackAddrSize == OP_SIZE_DWORD):
                    self.registers.regWriteDword(CPU_REGISTER_ESP, tempESP)
                else:
                    self.registers.regWriteWord(CPU_REGISTER_SP, <unsigned short>tempESP)
        self.registers.segWriteSegment((<Segment>self.registers.segments.cs), tempCS)
        self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
        return True
    cdef int retFarImm(self) except BITMASK_BYTE:
        cdef unsigned short imm
        imm = self.registers.getCurrentOpcodeAddUnsignedWord() # imm16
        return self.retFar(imm)
    cdef int lfpFunc(self, unsigned short segId) except BITMASK_BYTE: # 'load far pointer' function
        cdef unsigned short segmentAddr
        cdef unsigned int mmAddr, offsetAddr
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        if (self.modRMInstance.mod == 3):
            raise HirnwichseException(CPU_EXCEPTION_UD)
        mmAddr = self.modRMInstance.getRMValueFull(self.registers.addrSize)
        offsetAddr = self.registers.mmReadValueUnsigned(mmAddr, self.registers.operSize, self.modRMInstance.rmNameSeg, True)
        segmentAddr = self.registers.mmReadValueUnsignedWord(mmAddr+self.registers.operSize, self.modRMInstance.rmNameSeg, True)
        if (self.main.debugEnabled):
            self.main.debug("lfpFunc: test_1 (segId: {0:d}; segmentAddr: {1:#06x}; mmAddr: {2:#010x}; rmNameSeg.segId: {3:d}; operSize: {4:d}; addrSize: {5:d})", segId, segmentAddr, mmAddr, self.modRMInstance.rmNameSeg.segId, self.registers.operSize, self.registers.addrSize)
        self.registers.segWrite(segId, segmentAddr)
        self.modRMInstance.modRSave(self.registers.operSize, offsetAddr, OPCODE_SAVE)
        return True
    cdef int xlatb(self) except BITMASK_BYTE:
        cdef unsigned char data
        cdef unsigned int mmAddr
        self.main.notice("Opcodes::xlatb: TODO!")
        mmAddr = self.registers.regReadUnsigned(CPU_REGISTER_BX, self.registers.addrSize)+self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        data = self.registers.mmReadValueUnsignedByte(mmAddr, (<Segment>self.registers.segments.ds), True)
        self.registers.regWriteLowByte(CPU_REGISTER_AL, data)
        return True
    cdef int opcodeGroup2_RM(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned char operOpcodeId, operSizeInBits
        cdef unsigned int operOp2, bitMaskHalf, bitMask
        cdef unsigned long int utemp, operOp1, operSum, doubleBitMask, doubleBitMaskHalf
        cdef signed int sop2
        cdef signed long int sop1, temp, tempmod
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        if (self.main.debugEnabled):
            self.main.debug("Group2_RM: operOpcodeId=={0:d}", operOpcodeId)
        operOp2 = self.modRMInstance.modRMLoadUnsigned(operSize)
        operSizeInBits = operSize << 3
        bitMask = BITMASKS_FF[operSize]
        if (operOpcodeId in (GROUP2_OP_TEST, GROUP2_OP_TEST_ALIAS)):
            operOp1 = self.registers.getCurrentOpcodeAddUnsigned(operSize)
            operOp2 = operOp2&operOp1
            self.registers.setSZP_COA(operOp2, operSize)
        elif (operOpcodeId == GROUP2_OP_NEG):
            self.modRMInstance.modRMSave(operSize, operOp2, OPCODE_NEG)
            self.registers.setFullFlags(0, operOp2, operSize, OPCODE_SUB)
            self.registers.cf = operOp2!=0
        elif (operOpcodeId == GROUP2_OP_NOT):
            self.modRMInstance.modRMSave(operSize, operOp2, OPCODE_NOT)
        elif (operOpcodeId == GROUP2_OP_MUL):
            if (operSize == OP_SIZE_BYTE):
                operOp1 = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
                self.registers.regWriteWord(CPU_REGISTER_AX, operOp1*operOp2)
                self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_MUL)
                return True
            operOp1 = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
            operSum = (operOp1*operOp2)
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
                self.registers.cf = self.registers.of = (<signed char>operSum)!=(<signed short>operSum)
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
                self.registers.cf = self.registers.of = (<signed short>operSum)!=(<signed int>operSum)
            elif (operSize == OP_SIZE_DWORD):
                self.registers.cf = self.registers.of = utemp!=0
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_DIV):
            op1Word = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
            if (not operOp2):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(op1Word, operOp2)
            if (temp != temp&bitMask):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            self.registers.regWriteLowByte(CPU_REGISTER_AL, temp)
            self.registers.regWriteHighByte(CPU_REGISTER_AH, tempmod)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_IDIV):
            sop1  = self.registers.regReadSignedWord(CPU_REGISTER_AX)
            sop2  = self.modRMInstance.modRMLoadSigned(operSize)
            if (sop1 == -0x8000 or not sop2):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            operOp2 = abs(sop2)
            temp, tempmod = divmod(sop1, operOp2)
            if (sop2 != operOp2):
                temp = -temp
            if (<signed short>temp != <signed char>temp):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            self.registers.regWriteLowByte(CPU_REGISTER_AL, temp)
            self.registers.regWriteHighByte(CPU_REGISTER_AH, tempmod)
        elif (operOpcodeId == GROUP2_OP_DIV):
            operOp1  = self.registers.regReadUnsigned(CPU_REGISTER_DX, operSize)<<operSizeInBits
            operOp1 |= self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
            if (not operOp2):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            utemp, tempmod = divmod(operOp1, operOp2)
            if (utemp != utemp&bitMask):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            self.registers.regWrite(CPU_REGISTER_AX, utemp, operSize)
            self.registers.regWrite(CPU_REGISTER_DX, tempmod, operSize)
        elif (operOpcodeId == GROUP2_OP_IDIV):
            bitMaskHalf = BITMASKS_80[operSize]
            doubleBitMaskHalf = BITMASKS_80[operSize<<1]
            sop1 = (self.registers.regReadUnsigned(CPU_REGISTER_DX, operSize)<<operSizeInBits)|self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
            sop2 = self.modRMInstance.modRMLoadSigned(operSize)
            if (operSize == OP_SIZE_WORD):
                sop1 = <signed int>sop1
            else:
                sop1 = <signed long int>sop1
            if (sop1 == -doubleBitMaskHalf or not sop2):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(sop1, sop2)
            if (operSize == OP_SIZE_WORD):
                if (<signed int>temp != <signed short>temp):
                    raise HirnwichseException(CPU_EXCEPTION_DE)
            else:
                if (<signed long int>temp != <signed int>temp):
                    raise HirnwichseException(CPU_EXCEPTION_DE)
            self.registers.regWrite(CPU_REGISTER_AX, temp, operSize)
            self.registers.regWrite(CPU_REGISTER_DX, tempmod, operSize)
        else:
            self.main.notice("opcodeGroup2_RM: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise HirnwichseException(CPU_EXCEPTION_UD)
        return True
    cdef int interrupt(self, signed short intNum=-1, signed int errorCode=-1) except BITMASK_BYTE: # TODO: complete this!
        cdef unsigned char entryType, entrySize, entryNeededDPL, entryPresent, cpl, isSoftInt, oldVM = 0
        cdef unsigned short entrySegment, newSS, oldSS, oldTSSsel
        cdef unsigned int entryEip, eflagsClearThis, TSSstackOffset, newESP, oldESP, oldEFLAGS
        cdef IdtEntry idtEntry
        cdef GdtEntry gdtEntryCS, gdtEntrySS
        self.registers.syncCR0State()
        isSoftInt = False
        entryType, entrySize, entryPresent, eflagsClearThis = TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE, OP_SIZE_WORD, True, (FLAG_TF | FLAG_RF)
        if (self.registers.protectedModeOn):
            eflagsClearThis |= (FLAG_NT | FLAG_VM)
            oldVM = self.registers.vm
        else:
            eflagsClearThis |= FLAG_AC
        if (intNum == -1):
            isSoftInt = True
            intNum = self.registers.getCurrentOpcodeAddUnsignedByte()
        oldEFLAGS = self.registers.readFlags()
        #if (self.main.debugEnabled):
        IF 1:
            self.main.notice("Opcodes::interrupt: Go Interrupt {0:#04x}; isSoftInt=={1:d}", intNum, isSoftInt)
            self.main.notice("Opcodes::interrupt: TODO! (opcode: {0:#04x}, savedCs: {1:#06x}, savedEip: {2:#010x})", self.main.cpu.opcode, self.main.cpu.savedCs, self.main.cpu.savedEip)
        if (self.registers.protectedModeOn):
            if (oldVM and (self.registers.iopl < 3) and isSoftInt):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            idtEntry = (<IdtEntry>(<Idt>(<Segments>self.registers.segments).idt).getEntry(intNum))
            if (idtEntry is None):
                raise HirnwichseException(CPU_EXCEPTION_GP, intNum)
            entrySegment = idtEntry.entrySegment
            entryEip = idtEntry.entryEip
            entryType = idtEntry.entryType
            entryNeededDPL = idtEntry.entryNeededDPL
            entryPresent = idtEntry.entryPresent
            entrySize = idtEntry.entrySize
            if (entryType == TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE):
                #if (self.main.debugEnabled):
                IF 1:
                    self.main.notice("Opcodes::interrupt: task-gates aren't fully implemented yet. entrySegment=={0:#06x}", entrySegment)
                gdtEntryCS = <GdtEntry>self.registers.segments.getEntry(entrySegment)
                if (gdtEntryCS is None):
                    raise HirnwichseException(CPU_EXCEPTION_GP, (<Misc>self.main.misc).calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
                entryType = (gdtEntryCS.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK)
                if ((entrySegment & GDT_USE_LDT) or (entryType in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY)) or not self.registers.segments.inLimit(entrySegment)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, (<Misc>self.main.misc).calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
                if (not gdtEntryCS.segPresent):
                    raise HirnwichseException(CPU_EXCEPTION_NP, (<Misc>self.main.misc).calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
                oldTSSsel = (<Segment>self.registers.segments.tss).segmentIndex
                if (entryType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.saveTSS32()
                else:
                    self.registers.saveTSS16()
                self.registers.segWriteSegment((<Segment>self.registers.segments.tss), entrySegment)
                if (entryType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.switchTSS32()
                else:
                    self.registers.switchTSS16()
                self.registers.nt = True
                self.registers.mmWriteValue(TSS_PREVIOUS_TASK_LINK, oldTSSsel, OP_SIZE_WORD, (<Segment>self.registers.segments.tss), False)
                if (not (<Segment>self.registers.segments.cs).isAddressInLimit(self.registers.regReadUnsignedDword(CPU_REGISTER_EIP), OP_SIZE_BYTE)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, not isSoftInt)
                return True
            elif (entryType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE, TABLE_ENTRY_SYSTEM_TYPE_16BIT_TRAP_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TRAP_GATE)):
                self.main.exitError("Opcodes::interrupt: unknown entryType {0:d}.", entryType)
                return True
            if (not (entrySegment&0xfff8)):
                raise HirnwichseException(CPU_EXCEPTION_GP, not isSoftInt)
            if (not self.registers.segments.inLimit(entrySegment)):
                raise HirnwichseException(CPU_EXCEPTION_GP, (<Misc>self.main.misc).calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
            gdtEntryCS = <GdtEntry>self.registers.segments.getEntry(entrySegment)
            if (gdtEntryCS is None):
                self.main.exitError("Opcodes::interrupt: not gdtEntryCS")
                return True
            cpl = self.registers.getCPL()
            if ((not gdtEntryCS.segIsCodeSeg) or (gdtEntryCS.segDPL > cpl)):
                raise HirnwichseException(CPU_EXCEPTION_GP, (<Misc>self.main.misc).calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
            if (not gdtEntryCS.segPresent):
                raise HirnwichseException(CPU_EXCEPTION_NP, (<Misc>self.main.misc).calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
            if ((not gdtEntryCS.segIsConforming) and (gdtEntryCS.segDPL < cpl)):
                # TODO: What to do if VM flag is true?
                # inter-privilege-level-interrupt
                #self.main.debug("Opcodes::interrupt: inter/inner")
                if (oldVM):
                    self.main.notice("Opcodes::interrupt: Go Interrupt {0:#04x}; isSoftInt=={1:d}", intNum, isSoftInt)
                    self.main.notice("Opcodes::interrupt: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                    self.main.notice("Opcodes::interrupt: VM86-Mode isn't supported yet. (interrupt from VM86-Mode; inter-privilege-level-interrupt)")
                    self.main.cpu.cpuDump()
                    if (gdtEntryCS.segDPL):
                        raise HirnwichseException(CPU_EXCEPTION_GP, (<Misc>self.main.misc).calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
                if (((<Segment>self.registers.segments.tss).accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY) == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    if (oldVM):
                        if ((<Segment>self.registers.segments.tss).limit < 9):
                            raise HirnwichseException(CPU_EXCEPTION_TS, (<Misc>self.main.misc).calculateInterruptErrorcode((<Segment>self.registers.segments.tss).segmentIndex, 0, not isSoftInt))
                        newSS = self.registers.mmReadValueUnsignedWord(TSS_32BIT_SS0, (<Segment>self.registers.segments.tss), False)
                        newESP = self.registers.mmReadValueUnsignedDword(TSS_32BIT_ESP0, (<Segment>self.registers.segments.tss), False)
                    else:
                        TSSstackOffset = (gdtEntryCS.segDPL << 3) + 4
                        if ((TSSstackOffset + 5) > (<Segment>self.registers.segments.tss).limit):
                            raise HirnwichseException(CPU_EXCEPTION_TS, (<Misc>self.main.misc).calculateInterruptErrorcode((<Segment>self.registers.segments.tss).segmentIndex, 0, not isSoftInt))
                        newSS = self.registers.mmReadValueUnsignedWord((TSSstackOffset + OP_SIZE_DWORD), (<Segment>self.registers.segments.tss), False)
                        newESP = self.registers.mmReadValueUnsignedDword(TSSstackOffset, (<Segment>self.registers.segments.tss), False)
                elif (((<Segment>self.registers.segments.tss).accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY) == TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS):
                    if (oldVM):
                        if ((<Segment>self.registers.segments.tss).limit < 5):
                            raise HirnwichseException(CPU_EXCEPTION_TS, (<Misc>self.main.misc).calculateInterruptErrorcode((<Segment>self.registers.segments.tss).segmentIndex, 0, not isSoftInt))
                        newSS = self.registers.mmReadValueUnsignedWord(TSS_16BIT_SS0, (<Segment>self.registers.segments.tss), False)
                        newESP = self.registers.mmReadValueUnsignedWord(TSS_16BIT_SP0, (<Segment>self.registers.segments.tss), False)
                    else:
                        TSSstackOffset = (gdtEntryCS.segDPL << 2) + 2
                        if ((TSSstackOffset + 3) > (<Segment>self.registers.segments.tss).limit):
                            raise HirnwichseException(CPU_EXCEPTION_TS, (<Misc>self.main.misc).calculateInterruptErrorcode((<Segment>self.registers.segments.tss).segmentIndex, 0, not isSoftInt))
                        newSS = self.registers.mmReadValueUnsignedWord((TSSstackOffset + OP_SIZE_WORD), (<Segment>self.registers.segments.tss), False)
                        newESP = self.registers.mmReadValueUnsignedWord(TSSstackOffset, (<Segment>self.registers.segments.tss), False)
                else:
                    self.main.exitError("Opcodes::interrupt: not (tss32 or tss16)")
                    return True
                if (not (newSS&0xfff8)):
                    raise HirnwichseException(CPU_EXCEPTION_TS, not isSoftInt)
                if (not self.registers.segments.inLimit(newSS) or (not oldVM and ((newSS&3) != gdtEntryCS.segDPL)) or (oldVM and ((newSS&3) != 0))):
                    raise HirnwichseException(CPU_EXCEPTION_TS, (<Misc>self.main.misc).calculateInterruptErrorcode(newSS, 0, not isSoftInt))
                gdtEntrySS = <GdtEntry>self.registers.segments.getEntry(newSS)
                if (gdtEntrySS is None):
                    self.main.exitError("Opcodes::interrupt: not gdtEntrySS")
                    return True
                if ((not oldVM and gdtEntrySS.segDPL != gdtEntryCS.segDPL) or (oldVM and gdtEntrySS.segDPL != 0) or (not gdtEntrySS.segIsCodeSeg and not gdtEntrySS.segIsRW)):
                    raise HirnwichseException(CPU_EXCEPTION_TS, (<Misc>self.main.misc).calculateInterruptErrorcode(newSS, 0, not isSoftInt))
                if (not gdtEntrySS.segPresent):
                    raise HirnwichseException(CPU_EXCEPTION_SS, (<Misc>self.main.misc).calculateInterruptErrorcode(newSS, 0, not isSoftInt))
                cpl = gdtEntryCS.segDPL
                self.registers.cpl = cpl # TODO: HACK!
                if (not gdtEntryCS.isAddressInLimit(entryEip, OP_SIZE_BYTE)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, not isSoftInt)
                if (entryType in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE)):
                    eflagsClearThis |= FLAG_IF
                    if (oldVM):
                        eflagsClearThis |= FLAG_VM | FLAG_NT
                self.registers.clearEFLAG(eflagsClearThis)
                oldSS = self.registers.segRead(CPU_SEGMENT_SS)
                oldESP = self.registers.regReadUnsignedDword(CPU_REGISTER_ESP)
                self.registers.segWriteSegment((<Segment>self.registers.segments.ss), newSS)
                if ((<Segment>self.registers.segments.ss).segSize == OP_SIZE_WORD):
                    newESP = <unsigned short>newESP
                if (idtEntry.entrySize == OP_SIZE_DWORD):
                    if ((not oldVM and (newESP - (24 if (errorCode != -1) else 20)) >= newESP) or (oldVM and (newESP - (40 if (errorCode != -1) else 36)) >= newESP)):
                        raise HirnwichseException(CPU_EXCEPTION_SS, (<Misc>self.main.misc).calculateInterruptErrorcode(newSS, 0, not isSoftInt))
                else:
                    if ((not oldVM and (newESP - (12 if (errorCode != -1) else 10)) >= newESP) or (oldVM and (newESP - (20 if (errorCode != -1) else 18)) >= newESP)):
                        raise HirnwichseException(CPU_EXCEPTION_SS, (<Misc>self.main.misc).calculateInterruptErrorcode(newSS, 0, not isSoftInt))
                if ((<Segment>self.registers.segments.ss).segSize == OP_SIZE_DWORD):
                    self.registers.regWriteDword(CPU_REGISTER_ESP, newESP)
                else:
                    self.registers.regWriteWord(CPU_REGISTER_SP, <unsigned short>newESP)
                if (oldVM):
                    self.stackPushSegment((<Segment>self.registers.segments.gs), entrySize)
                    self.stackPushSegment((<Segment>self.registers.segments.fs), entrySize)
                    self.stackPushSegment((<Segment>self.registers.segments.ds), entrySize)
                    self.stackPushSegment((<Segment>self.registers.segments.es), entrySize)
                self.stackPushValue(oldSS, entrySize, True)
                self.stackPushValue(oldESP, entrySize, False)
            else:
                # intra-privilege-level-interrupt
                #self.main.debug("Opcodes::interrupt: intra")
                if (oldVM):
                    self.main.notice("Opcodes::interrupt: VM86-Mode isn't supported yet. (exception from intra-privilege-level-interrupt)")
                    raise HirnwichseException(CPU_EXCEPTION_GP, (<Misc>self.main.misc).calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
                if (gdtEntryCS.segIsConforming or (gdtEntryCS.segDPL == cpl)):
                    oldESP = self.registers.regReadUnsignedDword(CPU_REGISTER_ESP)
                    if (idtEntry.entrySize == OP_SIZE_DWORD):
                        if ((oldESP - (16 if (errorCode != -1) else 12)) >= oldESP):
                            raise HirnwichseException(CPU_EXCEPTION_SS, not isSoftInt)
                    else:
                        if ((oldESP - (8 if (errorCode != -1) else 6)) >= oldESP):
                            raise HirnwichseException(CPU_EXCEPTION_SS, not isSoftInt)
                    if (not gdtEntryCS.isAddressInLimit(entryEip, OP_SIZE_BYTE)):
                        raise HirnwichseException(CPU_EXCEPTION_GP, not isSoftInt)
                else:
                    raise HirnwichseException(CPU_EXCEPTION_GP, (<Misc>self.main.misc).calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
            if (not oldVM):
                entrySegment &= 0xfffc
                entrySegment |= cpl
        else:
            (<Idt>(<Segments>self.registers.segments).idt).getEntryRealMode(intNum, &entrySegment, <unsigned short*>&entryEip)
            entryEip = <unsigned short>entryEip
        #if (self.main.debugEnabled):
        IF 1:
            self.main.notice("Opcodes::interrupt: Go Interrupt {0:#04x}. CS: {1:#06x}, (E)IP: {2:#06x}, AX: {3:#06x}", intNum, entrySegment, entryEip, self.registers.regReadUnsignedWord(CPU_REGISTER_AX))
        if (entryType in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE)):
            eflagsClearThis |= FLAG_IF
            if (oldVM):
                eflagsClearThis |= FLAG_VM | FLAG_NT
        self.registers.clearEFLAG(eflagsClearThis)
        self.stackPushValue(oldEFLAGS, entrySize, False)
        self.stackPushSegment((<Segment>self.registers.segments.cs), entrySize)
        self.stackPushRegId(CPU_REGISTER_EIP, entrySize)
        if (self.registers.protectedModeOn and not isSoftInt and errorCode != -1):
            self.stackPushValue(errorCode, entrySize, False)
        if (oldVM):
            self.main.notice("Opcodes::interrupt: Go Interrupt {0:#04x}; isSoftInt=={1:d}", intNum, isSoftInt)
            self.main.notice("Opcodes::interrupt: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
            self.main.notice("Opcodes::interrupt: oldVM, set segments to zero")
            self.main.cpu.cpuDump()
            self.registers.segWriteSegment((<Segment>self.registers.segments.gs), 0)
            self.registers.segWriteSegment((<Segment>self.registers.segments.fs), 0)
            self.registers.segWriteSegment((<Segment>self.registers.segments.ds), 0)
            self.registers.segWriteSegment((<Segment>self.registers.segments.es), 0)
        self.registers.segWriteSegment((<Segment>self.registers.segments.cs), entrySegment)
        self.registers.regWriteDword(CPU_REGISTER_EIP, entryEip)
        return True
    cdef int into(self) except BITMASK_BYTE:
        self.main.notice("Opcodes::into: TODO!")
        if (self.registers.of):
            raise HirnwichseException(CPU_EXCEPTION_OF)
        return True
    cdef int iret(self) except BITMASK_BYTE:
        cdef GdtEntry gdtEntryCS, gdtEntrySS, gdtEntryTSS
        cdef Segment tempSegment
        cdef unsigned char cpl, newCpl, segType, oldSegType
        cdef unsigned short tempCS, tempSS, linkSel, TSSsel
        cdef unsigned int tempEFLAGS, currentEFLAGS, tempEIP, tempESP, oldESP, eflagsMask = 0
        #if (self.main.debugEnabled):
        IF 1:
            self.main.notice("Opcodes::iret: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        self.registers.syncCR0State()
        tempEIP = self.stackPopValue(False) # this is here because esp should stay on
                                            # it's original value in case of an exception.
        if (not self.registers.protectedModeOn and self.registers.operSize == OP_SIZE_DWORD and (tempEIP>>16)):
            self.main.notice("Opcodes::iret: test1: opl: test1.9")
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        oldESP = self.registers.regReadUnsignedDword(CPU_REGISTER_ESP)
        if ((oldESP - (12 if (self.registers.operSize == OP_SIZE_DWORD) else 6)) >= oldESP):
            raise HirnwichseException(CPU_EXCEPTION_SS, 0)
        tempEIP = self.stackPopValue(True)
        tempCS = self.stackPopValue(True)
        tempEFLAGS = self.stackPopValue(True)
        currentEFLAGS = self.registers.readFlags()
        if (self.registers.protectedModeOn):
            cpl = newCpl = self.registers.getCPL()
            if (currentEFLAGS & FLAG_VM):
                self.main.notice("Opcodes::iret: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                self.main.notice("Opcodes::iret: VM86-Mode isn't fully supported yet. (return from VM86-Mode)")
                self.main.cpu.cpuDump()
                if (self.registers.getIOPL() < 3):
                    self.main.notice("Opcodes::iret: test1: opl: vm: test1.10")
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                #if (not (<Segment>self.registers.segments.cs).isAddressInLimit(tempEIP, OP_SIZE_BYTE)):
                #    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                eflagsMask = FLAG_VM | FLAG_IOPL | FLAG_VIP | FLAG_VIF
                tempEFLAGS &= ~eflagsMask
                tempEFLAGS |= currentEFLAGS & eflagsMask
                self.registers.regWrite(CPU_REGISTER_FLAGS, tempEFLAGS, self.registers.operSize)
                self.registers.segWriteSegment((<Segment>self.registers.segments.cs), tempCS)
                self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
                #self.registers.ssInhibit = True
                self.main.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
                return True
            elif (currentEFLAGS & FLAG_NT):
                #if (self.main.debugEnabled):
                #    self.main.debug("Opcodes::iret: Nested-Task-Flag isn't fully supported yet.")
                self.main.notice("Opcodes::iret: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                self.main.notice("Opcodes::iret: Nested-Task-Flag isn't fully supported yet.")
                self.main.cpu.cpuDump()
                TSSsel = (<Segment>self.registers.segments.tss).segmentIndex
                linkSel = self.registers.mmReadValueUnsignedWord(TSS_PREVIOUS_TASK_LINK, (<Segment>self.registers.segments.tss), False)
                if ((linkSel & GDT_USE_LDT) or not self.registers.segments.inLimit(linkSel)):
                    raise HirnwichseException(CPU_EXCEPTION_TS, TSSsel)
                gdtEntryTSS = <GdtEntry>self.registers.segments.getEntry(linkSel)
                if (gdtEntryTSS is None):
                    self.main.notice("Opcodes::iret: test1: opl: nt: test1.11")
                    raise HirnwichseException(CPU_EXCEPTION_GP, TSSsel)
                segType = (gdtEntryTSS.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK)
                if (segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY)):
                    self.main.notice("Opcodes::iret: nested-task-flag: exception_2 (segType: {0:#04x}; linkSel: {1:#06x})", segType, linkSel)
                    raise HirnwichseException(CPU_EXCEPTION_TS, TSSsel)
                if (not gdtEntryTSS.segPresent):
                    raise HirnwichseException(CPU_EXCEPTION_NP, TSSsel)
                oldSegType = ((<Segment>self.registers.segments.tss).accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY)
                self.registers.segments.setSegType(TSSsel, oldSegType)
                self.registers.clearEFLAG(FLAG_NT)
                if (segType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.saveTSS32()
                else:
                    self.registers.saveTSS16()
                self.registers.segWriteSegment((<Segment>self.registers.segments.tss), linkSel)
                if (segType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.switchTSS32()
                else:
                    self.registers.switchTSS16()
                if (not (<Segment>self.registers.segments.cs).isAddressInLimit(self.registers.regReadUnsignedDword(CPU_REGISTER_EIP), OP_SIZE_BYTE)):
                    self.main.notice("Opcodes::iret: test1: opl: nt: test1.12")
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                #self.registers.ssInhibit = True
                self.main.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
                return True
            elif (tempEFLAGS & FLAG_VM):
                if (not cpl):
                    self.main.notice("Opcodes::iret: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                    self.main.notice("Opcodes::iret: VM86-Mode isn't fully supported yet. (return to VM86-Mode)")
                    self.main.cpu.cpuDump()
                    if ((oldESP - 24) >= oldESP):
                        raise HirnwichseException(CPU_EXCEPTION_SS, 0)
                    #if (not (<Segment>self.registers.segments.cs).isAddressInLimit(tempEIP, OP_SIZE_BYTE)):
                    #    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                    tempESP = self.stackPopValue(True)
                    tempSS = self.stackPopValue(True)
                    self.registers.regWriteDwordEflags(tempEFLAGS)
                    self.registers.segWriteSegment((<Segment>self.registers.segments.cs), tempCS)
                    self.registers.regWriteDword(CPU_REGISTER_EIP, <unsigned short>tempEIP)
                    self.stackPopSegment((<Segment>self.registers.segments.es))
                    self.stackPopSegment((<Segment>self.registers.segments.ds))
                    self.stackPopSegment((<Segment>self.registers.segments.fs))
                    self.stackPopSegment((<Segment>self.registers.segments.gs))
                    self.registers.segWriteSegment((<Segment>self.registers.segments.ss), tempSS)
                    self.registers.regWriteDword(CPU_REGISTER_ESP, tempESP)
                    #self.registers.ssInhibit = True
                    self.main.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
                    return True
                else:
                    self.main.exitError("Opcodes::iret: TODO; tempeflags & vm and cpl != 0! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                    return True
            elif ((tempCS&3) > cpl): # outer privilege level; rpl > cpl
                self.main.notice("Opcodes::iret: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                self.main.notice("Opcodes::iret: test1: opl: rpl > cpl")
                self.main.cpu.cpuDump()
                if ((oldESP - (8 if (self.registers.operSize == OP_SIZE_DWORD) else 4)) >= oldESP):
                    raise HirnwichseException(CPU_EXCEPTION_SS, 0)
                tempESP = self.stackPopValue(True)
                tempSS = self.stackPopValue(True)
                if (not (tempSS&0xfff8)):
                    self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.4")
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                if (not self.registers.segments.inLimit(tempSS)):
                    self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.1")
                    raise HirnwichseException(CPU_EXCEPTION_GP, tempSS)
                gdtEntrySS = <GdtEntry>self.registers.segments.getEntry(tempSS)
                if (gdtEntrySS is None):
                    self.main.exitError("Opcodes::iret: not gdtEntrySS")
                    return True
                if ((tempSS&3 != tempCS&3) or (not gdtEntrySS.segIsRW) or (gdtEntrySS.segDPL != tempCS&3)):
                    self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.2")
                    self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.3; {0:d}; {1:d}; {2:d}", (tempSS&3 != tempCS&3), (not gdtEntrySS.segIsRW), (gdtEntrySS.segDPL != tempCS&3))
                    raise HirnwichseException(CPU_EXCEPTION_GP, tempSS)
                if (not gdtEntrySS.segPresent):
                    self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.5")
                    raise HirnwichseException(CPU_EXCEPTION_SS, tempSS)
                if (self.registers.operSize == OP_SIZE_DWORD and not cpl):
                    eflagsMask |= FLAG_VM
                newCpl = tempCS & 0x3
                for tempSegment in ((<Segment>self.registers.segments.ds), (<Segment>self.registers.segments.es), (<Segment>self.registers.segments.fs), (<Segment>self.registers.segments.gs)):
                    if (tempSegment.isValid and (not tempSegment.segIsCodeSeg or not tempSegment.segIsConforming) and (newCpl > tempSegment.segDPL)):
                        self.main.notice("Opcodes::iret: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
                        self.main.notice("Opcodes::iret: TODO! (segmentIndex: {0:#06x}; segDPL: {1:d}; tempCS=={2:#06x}; segId=={3:d}", tempSegment.segmentIndex, tempSegment.segDPL, tempCS, tempSegment.segId)
                        self.main.notice("Opcodes::iret: (isValid and (not codeSeg or not conforming) and (newCpl > dpl)), set segments to zero")
                        self.registers.segWriteSegment(tempSegment, 0)
                self.registers.segWriteSegment((<Segment>self.registers.segments.ss), tempSS)
                if ((<Segment>self.registers.segments.ss).segSize == OP_SIZE_DWORD):
                    self.registers.regWriteDword(CPU_REGISTER_ESP, tempESP)
                else:
                    self.registers.regWriteWord(CPU_REGISTER_SP, <unsigned short>tempESP)
            if (not (tempCS&0xfff8)):
                self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.6")
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            if (not self.registers.segments.inLimit(tempCS)):
                self.main.notice("Opcodes::iret: test2: not inLimit: tempCS")
                raise HirnwichseException(CPU_EXCEPTION_GP, tempCS)
            gdtEntryCS = <GdtEntry>self.registers.segments.getEntry(tempCS)
            if (gdtEntryCS is None):
                self.main.exitError("Opcodes::iret: not gdtEntryCS")
                return True
            if (not gdtEntryCS.segIsCodeSeg or ((tempCS&3) < cpl) or (gdtEntryCS.segIsConforming and (gdtEntryCS.segDPL > (tempCS&3)))):
                self.main.notice("Opcodes::iret: test3")
                raise HirnwichseException(CPU_EXCEPTION_GP, tempCS)
            if (not gdtEntryCS.segPresent):
                self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.7")
                raise HirnwichseException(CPU_EXCEPTION_NP, tempCS)
            eflagsMask |= FLAG_CF | FLAG_PF | FLAG_AF | FLAG_ZF | FLAG_SF | FLAG_TF | FLAG_DF | FLAG_OF | FLAG_NT
            if (self.registers.operSize in (OP_SIZE_DWORD, OP_SIZE_QWORD)):
                eflagsMask |= FLAG_RF | FLAG_AC | FLAG_ID
            if (cpl <= self.registers.getIOPL()):
                eflagsMask |= FLAG_IF
            if (not cpl): # cpl == 0
                eflagsMask |= FLAG_IOPL
                if (self.registers.operSize in (OP_SIZE_DWORD, OP_SIZE_QWORD)):
                    eflagsMask |= FLAG_VIF | FLAG_VIP
            tempEFLAGS &= eflagsMask
            currentEFLAGS &= ~eflagsMask
            currentEFLAGS |= tempEFLAGS
            self.registers.regWriteDwordEflags(currentEFLAGS)
            tempCS &= 0xfffc
            tempCS |= newCpl
            self.registers.segWriteSegment((<Segment>self.registers.segments.cs), tempCS)
            self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
            self.main.cpu.saveCurrentInstPointer()
            if (not gdtEntryCS.isAddressInLimit(tempEIP, OP_SIZE_BYTE)):
                self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.8")
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        else:
            if (self.registers.operSize == OP_SIZE_DWORD):
                tempEFLAGS = (tempEFLAGS & 0x257fd5)
                tempEFLAGS |= self.registers.readFlags()&0xff1a0000
                self.registers.regWriteDwordEflags(tempEFLAGS)
            else:
                self.registers.regWriteWordFlags(<unsigned short>tempEFLAGS)
            self.registers.segWriteSegment((<Segment>self.registers.segments.cs), tempCS)
            self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
        #self.registers.ssInhibit = True
        self.main.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
        return True
    cdef int aad(self) except BITMASK_BYTE:
        cdef unsigned char imm8, tempAL, tempAH
        imm8 = self.registers.getCurrentOpcodeAddUnsignedByte()
        tempAL = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        tempAH = self.registers.regReadUnsignedHighByte(CPU_REGISTER_AH)
        tempAL = self.registers.regWriteWord(CPU_REGISTER_AX, <unsigned char>(tempAL + (tempAH * imm8)))
        self.registers.setSZP_COA(tempAL, OP_SIZE_BYTE)
        return True
    cdef int aam(self) except BITMASK_BYTE:
        cdef unsigned char imm8, tempAL, ALdiv, ALmod
        imm8 = self.registers.getCurrentOpcodeAddUnsignedByte()
        if (not imm8):
            raise HirnwichseException(CPU_EXCEPTION_DE)
        tempAL = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        ALdiv, ALmod = divmod(tempAL, imm8)
        self.registers.regWriteHighByte(CPU_REGISTER_AH, ALdiv)
        self.registers.regWriteLowByte(CPU_REGISTER_AL, ALmod)
        self.registers.setSZP_COA(ALmod, OP_SIZE_BYTE)
        return True
    cdef int aaa(self) except BITMASK_BYTE:
        cdef unsigned char AFflag, tempAL, tempAH
        cdef unsigned short tempAX
        tempAX = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
        tempAL = tempAX&0xf
        tempAH = (tempAX>>8)
        AFflag = self.registers.af
        if ((tempAL>9) or AFflag):
            tempAL = (tempAL+6)&0xf
            self.registers.setSZP_O(tempAL, OP_SIZE_BYTE)
            self.registers.af = self.registers.cf = True
            self.registers.regAddHighByte(CPU_REGISTER_AH, 1)
        else:
            tempAL &= 0xf
            self.registers.setSZP_COA(tempAL, OP_SIZE_BYTE)
        self.registers.regWriteLowByte(CPU_REGISTER_AL, tempAL)
        return True
    cdef int aas(self) except BITMASK_BYTE:
        cdef unsigned char AFflag, tempAL, tempAH
        cdef unsigned short tempAX
        tempAX = self.registers.regReadUnsignedWord(CPU_REGISTER_AX)
        tempAL = tempAX&0xf
        tempAH = (tempAX>>8)
        AFflag = self.registers.af
        if ((tempAL>9) or AFflag):
            tempAL = (tempAL-6)&0xf
            self.registers.setSZP_O(tempAL, OP_SIZE_BYTE)
            self.registers.af = self.registers.cf = True
            self.registers.regSubHighByte(CPU_REGISTER_AH, 1)
        else:
            tempAL &= 0xf
            self.registers.setSZP_COA(tempAL, OP_SIZE_BYTE)
        self.registers.regWriteLowByte(CPU_REGISTER_AL, tempAL)
        return True
    cdef int daa(self) except BITMASK_BYTE:
        cdef unsigned char old_AL, old_AF, old_CF
        old_AL = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        old_AF = self.registers.af
        old_CF = self.registers.cf
        self.clc()
        if (((old_AL&0xf)>9) or old_AF):
            self.registers.regAddLowByte(CPU_REGISTER_AL, 0x6)
            self.registers.cf = old_CF or (old_AL+6>BITMASK_BYTE)
            self.registers.af = True
        else:
            self.registers.af = False
        if ((old_AL > 0x99) or old_CF):
            self.registers.regAddLowByte(CPU_REGISTER_AL, 0x60)
            self.stc()
        else:
            self.clc()
        self.registers.setSZP_O(self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL), OP_SIZE_BYTE)
        return True
    cdef int das(self) except BITMASK_BYTE:
        cdef unsigned char old_AL, old_AF, old_CF
        old_AL = self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL)
        old_AF = self.registers.af
        old_CF = self.registers.cf
        self.clc()
        if (((old_AL&0xf)>9) or old_AF):
            self.registers.regSubLowByte(CPU_REGISTER_AL, 6)
            self.registers.cf = old_CF or (old_AL-6<0)
            self.registers.af = True
        else:
            self.registers.af = False
        if ((old_AL > 0x99) or old_CF):
            self.registers.regSubLowByte(CPU_REGISTER_AL, 0x60)
            self.stc()
        self.registers.setSZP_O(self.registers.regReadUnsignedLowByte(CPU_REGISTER_AL), OP_SIZE_BYTE)
        return True
    cdef int cbw_cwde(self) except BITMASK_BYTE:
        cdef unsigned int op2
        if (self.registers.operSize == OP_SIZE_WORD): # CBW
            op2 = <unsigned short>self.registers.regReadSignedLowByte(CPU_REGISTER_AL)
            self.registers.regWriteWord(CPU_REGISTER_AX, op2)
        elif (self.registers.operSize == OP_SIZE_DWORD): # CWDE
            op2 = self.registers.regReadSignedWord(CPU_REGISTER_AX)
            self.registers.regWriteDword(CPU_REGISTER_EAX, op2)
        return True
    cdef int cwd_cdq(self) except BITMASK_BYTE:
        cdef unsigned int bitMask, bitMaskHalf, op2
        bitMask = BITMASKS_FF[self.registers.operSize]
        bitMaskHalf = BITMASKS_80[self.registers.operSize]
        op2 = self.registers.regReadUnsigned(CPU_REGISTER_AX, self.registers.operSize)
        if (op2&bitMaskHalf):
            self.registers.regWrite(CPU_REGISTER_DX, bitMask, self.registers.operSize)
        else:
            self.registers.regWrite(CPU_REGISTER_DX, 0, self.registers.operSize)
        return True
    cdef int shlFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE:
        cdef unsigned char newCF
        cdef unsigned int bitMaskHalf, dest
        bitMaskHalf = BITMASKS_80[operSize]
        dest = self.modRMInstance.modRMLoadUnsigned(operSize)
        count = count&0x1f
        if (not count):
            return True
        newCF = ((dest<<(count-1))&bitMaskHalf)!=0
        dest = (dest<<count)
        if (operSize == OP_SIZE_WORD):
            dest = <unsigned short>dest
        self.modRMInstance.modRMSave(operSize, dest, OPCODE_SAVE)
        self.registers.of = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.cf = newCF
        self.registers.af = False
        self.registers.setSZP(dest, operSize)
        return True
    cdef int sarFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE:
        cdef unsigned char newCF
        cdef unsigned int bitMask
        cdef signed int dest
        bitMask = BITMASKS_FF[operSize]
        dest = self.modRMInstance.modRMLoadSigned(operSize)
        count = count&0x1f
        if (not count):
            return True
        newCF = ((dest>>(count-1))&1)
        dest >>= count
        self.modRMInstance.modRMSave(operSize, dest&bitMask, OPCODE_SAVE)
        self.registers.setSZP_COA(dest&bitMask, operSize)
        self.registers.cf = newCF
        return True
    cdef int shrFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE:
        cdef unsigned char newCF_OF
        cdef unsigned int bitMaskHalf, dest, tempDest
        bitMaskHalf = BITMASKS_80[operSize]
        dest = self.modRMInstance.modRMLoadUnsigned(operSize)
        tempDest = dest
        count = count&0x1f
        if (not count):
            return True
        newCF_OF = ((dest>>(count-1))&1)
        dest >>= count
        self.modRMInstance.modRMSave(operSize, dest, OPCODE_SAVE)
        self.registers.cf = newCF_OF
        newCF_OF = (((dest<<1)^dest)&bitMaskHalf)!=0
        self.registers.of = newCF_OF
        self.registers.af = False
        self.registers.setSZP(dest, operSize)
        return True
    cdef int rclFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE:
        cdef unsigned char tempCF_OF, newCF, i
        cdef unsigned int bitMaskHalf, dest
        self.main.notice("Opcodes::rclFunc: RCL: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        bitMaskHalf = BITMASKS_80[operSize]
        dest = self.modRMInstance.modRMLoadUnsigned(operSize)
        count = count&0x1f
        if (operSize == OP_SIZE_BYTE):
            count %= 9
        elif (operSize == OP_SIZE_WORD):
            count %= 17
        if (not count):
            return True
        newCF = self.registers.cf
        for i in range(count):
            tempCF_OF = (dest&bitMaskHalf)!=0
            dest = ((dest<<1)|newCF)
            if (operSize == OP_SIZE_WORD):
                dest = <unsigned short>dest
            newCF = tempCF_OF
        self.modRMInstance.modRMSave(operSize, dest, OPCODE_SAVE)
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.cf = newCF
        self.registers.of = tempCF_OF
        return True
    cdef int rcrFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE:
        cdef unsigned char tempCF_OF, newCF, i
        cdef unsigned int bitMaskHalf, dest
        self.main.notice("Opcodes::rcrFunc: RCR: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        bitMaskHalf = BITMASKS_80[operSize]
        dest = self.modRMInstance.modRMLoadUnsigned(operSize)
        count = count&0x1f
        newCF = self.registers.cf
        if (operSize == OP_SIZE_BYTE):
            count %= 9
        elif (operSize == OP_SIZE_WORD):
            count %= 17
        if (not count):
            return True
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.of = tempCF_OF
        for i in range(count):
            tempCF_OF = (dest&1)
            dest = (dest >> 1) | (newCF * bitMaskHalf)
            newCF = tempCF_OF
        self.modRMInstance.modRMSave(operSize, dest, OPCODE_SAVE)
        self.registers.cf = newCF
        return True
    cdef int rolFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE:
        cdef unsigned char tempCF_OF, newCF, i
        cdef unsigned int bitMaskHalf, dest
        self.main.notice("Opcodes::rolFunc: ROL: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        bitMaskHalf = BITMASKS_80[operSize]
        dest = self.modRMInstance.modRMLoadUnsigned(operSize)
        count &= 0x1f
        count = count&((operSize<<3)-1)
        if (not count):
            return True
        for i in range(count):
            tempCF_OF = (dest&bitMaskHalf)!=0
            dest = ((dest << 1) | tempCF_OF)
            if (operSize == OP_SIZE_WORD):
                dest = <unsigned short>dest
        self.modRMInstance.modRMSave(operSize, dest, OPCODE_SAVE)
        newCF = dest&1
        self.registers.cf = newCF
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.of = tempCF_OF
        return True
    cdef int rorFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE:
        cdef unsigned char tempCF_OF, newCF_M1, i
        cdef unsigned int bitMaskHalf, dest
        self.main.notice("Opcodes::rorFunc: ROR: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        bitMaskHalf = BITMASKS_80[operSize]
        dest = self.modRMInstance.modRMLoadUnsigned(operSize)
        count &= 0x1f
        count = count&((operSize<<3)-1)
        if (not count):
            return True
        for i in range(count):
            tempCF_OF = dest&1
            dest = (dest >> 1) | (tempCF_OF * bitMaskHalf)
        self.modRMInstance.modRMSave(operSize, dest, OPCODE_SAVE)
        tempCF_OF = (dest&bitMaskHalf)!=0
        newCF_M1 = (dest&(bitMaskHalf>>1))!=0
        self.registers.cf = tempCF_OF
        tempCF_OF = (tempCF_OF ^ newCF_M1)
        self.registers.of = tempCF_OF
        return True
    cdef int opcodeGroup4_RM(self, unsigned char operSize, unsigned char method) except BITMASK_BYTE:
        cdef unsigned char operOpcodeId, count
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        if (self.main.debugEnabled):
            self.main.debug("opcodeGroup4_RM: operOpcodeId=={0:d}", operOpcodeId)
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
            raise HirnwichseException(CPU_EXCEPTION_UD)
        return True
    cdef int sahf(self) except BITMASK_BYTE:
        cdef unsigned short flagsVal
        flagsVal = self.registers.readFlags()&0xff00
        flagsVal |= self.registers.regReadUnsignedHighByte(CPU_REGISTER_AH) & (FLAG_SF | FLAG_ZF | FLAG_AF | FLAG_PF | FLAG_CF)
        self.registers.regWriteWordFlags(flagsVal)
        return True
    cdef int lahf(self) except BITMASK_BYTE:
        cdef unsigned char flagsVal
        flagsVal = self.registers.readFlags() & (FLAG_SF | FLAG_ZF | FLAG_AF | FLAG_PF | FLAG_REQUIRED | FLAG_CF)
        self.registers.regWriteHighByte(CPU_REGISTER_AH, flagsVal)
        return True
    cdef int xchgFuncRegWord(self, unsigned short regName, unsigned short regName2) except BITMASK_BYTE:
        cdef unsigned short regValue, regValue2
        regValue, regValue2 = self.registers.regReadUnsignedWord(regName), self.registers.regReadUnsignedWord(regName2)
        self.registers.regWriteWord(regName, regValue2)
        self.registers.regWriteWord(regName2, regValue)
        return True
    cdef int xchgFuncRegDword(self, unsigned short regName, unsigned short regName2) except BITMASK_BYTE:
        cdef unsigned int regValue, regValue2
        regValue, regValue2 = self.registers.regReadUnsignedDword(regName), self.registers.regReadUnsignedDword(regName2)
        self.registers.regWriteDword(regName, regValue2)
        self.registers.regWriteDword(regName2, regValue)
        return True
    ##### DON'T USE XCHG AX, AX FOR OPCODE 0x90, use NOP instead!!
    cdef int xchgReg(self) except BITMASK_BYTE:
        if (self.registers.operSize == OP_SIZE_WORD):
            self.xchgFuncRegWord(CPU_REGISTER_AX, self.main.cpu.opcode&7)
        elif (self.registers.operSize == OP_SIZE_DWORD):
            self.xchgFuncRegDword(CPU_REGISTER_AX, self.main.cpu.opcode&7)
        return True
    cdef int xchgR_RM(self, unsigned char operSize) except BITMASK_BYTE:
        cdef unsigned int op1, op2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.modRMInstance.modRLoadUnsigned(operSize)
        op2 = self.modRMInstance.modRMLoadUnsigned(operSize)
        self.modRMInstance.modRSave(operSize, op2, OPCODE_SAVE)
        self.modRMInstance.modRMSave(operSize, op1, OPCODE_SAVE)
        return True
    cdef int enter(self) except BITMASK_BYTE:
        cdef unsigned char stackAddrSize, nestingLevel, i
        cdef unsigned short sizeOp
        cdef unsigned int frameTemp, temp
        #self.main.debugEnabled = True
        stackAddrSize = (<Segment>self.registers.segments.ss).segSize
        self.main.notice("Opcodes::enter: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        self.main.cpu.cpuDump()
        sizeOp = self.registers.getCurrentOpcodeAddUnsignedWord()
        nestingLevel = self.registers.getCurrentOpcodeAddUnsignedByte()
        nestingLevel &= 0x1f
        #if (nestingLevel):
        self.main.notice("Opcodes::enter: test1: sizeOp=={0:#06x}; nestingLevel=={1:d}!", sizeOp, nestingLevel)
        self.stackPushRegId(CPU_REGISTER_BP, stackAddrSize)
        if (stackAddrSize == OP_SIZE_WORD):
            frameTemp = self.registers.regReadUnsignedWord(CPU_REGISTER_SP)
            if (nestingLevel > 0):
                if (nestingLevel > 1):
                    for i in range(nestingLevel-2):
                        self.registers.regSubWord(CPU_REGISTER_BP, self.registers.operSize)
                        temp = self.registers.mmReadValueUnsigned(self.registers.regReadUnsignedWord(CPU_REGISTER_BP), self.registers.operSize, (<Segment>self.registers.segments.ss), False)
                        self.stackPushValue(temp, self.registers.operSize, False)
                self.stackPushValue(frameTemp, self.registers.operSize, False)
            self.registers.regWriteWord(CPU_REGISTER_BP, frameTemp)
            self.registers.regSubWord(CPU_REGISTER_SP, sizeOp)
        elif (stackAddrSize == OP_SIZE_DWORD):
            frameTemp = self.registers.regReadUnsignedDword(CPU_REGISTER_ESP)
            if (nestingLevel > 0):
                if (nestingLevel > 1):
                    for i in range(nestingLevel-2):
                        self.registers.regSubDword(CPU_REGISTER_EBP, self.registers.operSize)
                        temp = self.registers.mmReadValueUnsigned(self.registers.regReadUnsignedDword(CPU_REGISTER_EBP), self.registers.operSize, (<Segment>self.registers.segments.ss), False)
                        self.stackPushValue(temp, self.registers.operSize, False)
                self.stackPushValue(frameTemp, self.registers.operSize, False)
            self.registers.regWriteDword(CPU_REGISTER_EBP, frameTemp)
            self.registers.regSubDword(CPU_REGISTER_ESP, sizeOp)
        return True
    cdef int leave(self) except BITMASK_BYTE:
        cdef unsigned char stackAddrSize
        #self.main.debugEnabled = True
        #self.main.notice("Opcodes::leave: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
        #self.main.cpu.cpuDump()
        stackAddrSize = (<Segment>self.registers.segments.ss).segSize
        if (stackAddrSize == OP_SIZE_WORD):
            self.registers.regWriteWord(CPU_REGISTER_SP, self.registers.regReadUnsignedWord(CPU_REGISTER_BP))
        elif (stackAddrSize == OP_SIZE_DWORD):
            self.registers.regWriteDword(CPU_REGISTER_ESP, self.registers.regReadUnsignedDword(CPU_REGISTER_EBP))
        self.stackPopRegId(CPU_REGISTER_EBP, self.registers.operSize)
        #self.main.notice("Opcodes::leave: end of function")
        return True
    cdef int setWithCondFunc(self, unsigned char cond) except BITMASK_BYTE: # if cond==True set 1, else 0
        self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
        self.modRMInstance.modRMSave(OP_SIZE_BYTE, cond, OPCODE_SAVE)
        return True
    cdef int arpl(self) except BITMASK_BYTE:
        cdef unsigned short op1, op2
        self.main.notice("Opcodes::arpl: TODO!")
        if (not (self.registers.protectedModeOn and not self.registers.vm)):
            self.main.notice("Opcodes::arpl: called while not being in the protected mode. raising UD!")
            self.main.cpu.cpuDump()
            raise HirnwichseException(CPU_EXCEPTION_UD)
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
        op1 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
        op2 = self.modRMInstance.modRLoadUnsigned(OP_SIZE_WORD)
        if ((op1&3) < (op2&3)):
            self.registers.zf = True
            self.modRMInstance.modRMSave(OP_SIZE_WORD, (op1&0xfffc)|(op2&3), OPCODE_SAVE)
        else:
            self.registers.zf = False
        return True
    cdef int bound(self) except BITMASK_BYTE:
        cdef unsigned int returnInt
        cdef signed int index, lowerBound, upperBound
        self.main.notice("Opcodes::bound: TODO!")
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        if (self.modRMInstance.mod == 3):
            raise HirnwichseException(CPU_EXCEPTION_UD)
        index = self.modRMInstance.modRLoadSigned(self.registers.operSize)
        returnInt = self.modRMInstance.getRMValueFull(self.registers.addrSize)
        lowerBound = self.registers.mmReadValueSigned(returnInt, self.registers.operSize, self.modRMInstance.rmNameSeg, True)
        upperBound = self.registers.mmReadValueSigned(returnInt+self.registers.operSize, self.registers.operSize, self.modRMInstance.rmNameSeg, True)
        if (index < lowerBound or index > upperBound):
            self.main.notice("bound_test1: index: {0:#06x}, lowerBound: {1:#06x}, upperBound: {2:#06x}", index, lowerBound, upperBound)
            raise HirnwichseException(CPU_EXCEPTION_BR)
        return True
    cdef int btFunc(self, unsigned char newValType) except BITMASK_BYTE:
        cdef unsigned char state
        cdef unsigned int value, address, offset
        if ((newValType & BT_IMM) != 0):
            newValType &= ~BT_IMM
            offset = self.registers.getCurrentOpcodeAddUnsignedByte()
        else:
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            offset = self.modRMInstance.modRLoadUnsigned(self.registers.operSize)
        if (self.modRMInstance.mod == 3): # register operand
            offset &= (self.registers.operSize << 3) - 1 # operSizeInBits - 1
            value = self.modRMInstance.modRMLoadUnsigned(self.registers.operSize)
            state = self.registers.valGetBit(value, offset)
        else: # memory operand
            #self.main.notice("ATTENTION: this could be a WRONG IMPLEMENTATION of btFunc!!! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.main.cpu.savedEip, self.main.cpu.savedCs)
            #self.main.cpu.cpuDump() # dump before
            #self.main.notice("test1.1: rmName0=={0:d}, rmName1=={1:d}, rmName2=={2:#010x}, segId=={3:d}, segmentIndex=={4:d}, ss=={5:d}, regSize=={6:d}", self.modRMInstance.rmName0, self.modRMInstance.rmName1, self.modRMInstance.rmName2, self.modRMInstance.rmNameSeg.segId, self.modRMInstance.rmNameSeg.segmentIndex, self.modRMInstance.ss, self.modRMInstance.regSize)
            ##### TODO!!!!!!!!!
            address = self.modRMInstance.getRMValueFull(self.registers.addrSize)
            #self.main.notice("test1.2: address=={0:#010x}, offset=={1:#010x}, opcode=={2:#04x}", address, offset, self.main.cpu.opcode)
            if (self.registers.operSize == OP_SIZE_WORD):
                address += <signed short>(offset >> 3)
            elif (self.registers.operSize == OP_SIZE_DWORD):
                address += <signed int>(offset >> 3)
            offset &= 7
            #self.main.notice("test1.3: address=={0:#010x}, offset=={1:#010x}", address, offset)
            value = self.registers.mmReadValueUnsigned(address, OP_SIZE_BYTE, self.modRMInstance.rmNameSeg, True)
            state = self.registers.valGetBit(value, offset)
            #self.main.notice("btFunc: test1.1: address=={0:#010x}; offset=={1:d}; value=={2:#04x}; state=={3:d}; segId=={4:d}", address, offset, value, state, self.modRMInstance.rmNameSeg.segId)
        self.registers.cf = state
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
                self.modRMInstance.modRMSave(self.registers.operSize, value, OPCODE_SAVE)
            else: # memory operands
                self.registers.mmWriteValue(address, value, OP_SIZE_BYTE, self.modRMInstance.rmNameSeg, True)
                #self.main.notice("btFunc: test1.2: address=={0:#010x}; offset=={1:d}; value=={2:#04x}; state=={3:d}; segId=={4:d}", address, offset, value, state, self.modRMInstance.rmNameSeg.segId)
                #self.main.cpu.cpuDump() # dump after
        #elif (self.modRMInstance.mod != 3): # memory operands
        #    self.main.cpu.cpuDump() # dump after
        return True
    cdef int fpuOpcodes(self, unsigned char opcode) except BITMASK_BYTE:
        cdef unsigned char opcode2
        opcode2 = self.registers.getCurrentOpcodeUnsignedByte()
        self.main.notice("Opcodes::fpuOpcodes: FPU Opcodes: TODO! (opcode=={0:#04x}; opcode2=={1:#04x}; savedEip: {2:#010x}, savedCs: {3:#06x})", opcode, opcode2, self.main.cpu.savedEip, self.main.cpu.savedCs)
        #if (not self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_OSFXSR)): # TODO
        #    raise HirnwichseException(CPU_EXCEPTION_UD)
        if (self.registers.getFlagDword(CPU_REGISTER_CR0, (CR0_FLAG_EM | CR0_FLAG_TS)) != 0):
            raise HirnwichseException(CPU_EXCEPTION_NM)
        if (opcode in (0xd9, 0xdb, 0xdd, 0xde, 0xdf)):
            if ((opcode == 0xdf and opcode2 == 0xe0) or \
              (opcode == 0xdb and opcode2 == 0xe3) or \
              (opcode == 0xde and opcode2 in (0x05, 0x60, 0x63)) or \
              (opcode == 0xd9 and ((opcode2>>3)&7) == 7) or \
              (opcode == 0xdd and ((opcode2>>3)&7) in (6, 7))): # FNSTSW/FINIT/FNSTSW
                if ((opcode == 0xdd and ((opcode2>>3)&7) in (6, 7)) or \
                  (opcode == 0xd9 and ((opcode2>>3)&7) == 7) or \
                  (opcode == 0xde and opcode2 in (0x05, 0x60, 0x63))):
                    self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE) # FNSAVE
                else:
                    self.registers.getCurrentOpcodeAddUnsignedByte()
                return True
        self.main.notice("Opcodes::fpuOpcodes: opcode=={0:#04x}, opcode2=={1:#04x}", opcode, opcode2)
        raise HirnwichseException(CPU_EXCEPTION_UD)
        #return True
    cdef void run(self):
        self.modRMInstance = ModRMClass(self.registers)
    # end of opcodes



