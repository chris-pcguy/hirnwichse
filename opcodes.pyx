
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"
include "cpu_globals.pxi"

from cpu import HirnwichseException
import gmpy2, struct


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
    def __init__(self, Hirnwichse main, Cpu cpu):
        self.main = main
        self.cpu = cpu
    cdef uint64_t reverseByteOrder(self, uint64_t value, uint8_t valueSize):
        cdef bytes data
        data = value.to_bytes(length=valueSize, byteorder="big")
        value = int.from_bytes(bytes=data, byteorder="little")
        return value
    cdef inline int executeOpcode(self, uint8_t opcode) except BITMASK_BYTE_CONST:
        if (opcode == 0x00):
            return self.opcodeRM_R(OPCODE_ADD, OP_SIZE_BYTE)
        elif (opcode == 0x01):
            return self.opcodeRM_R(OPCODE_ADD, self.cpu.operSize)
        elif (opcode == 0x02):
            return self.opcodeR_RM(OPCODE_ADD, OP_SIZE_BYTE)
        elif (opcode == 0x03):
            return self.opcodeR_RM(OPCODE_ADD, self.cpu.operSize)
        elif (opcode == 0x04):
            return self.opcodeAxEaxImm(OPCODE_ADD, OP_SIZE_BYTE)
        elif (opcode == 0x05):
            return self.opcodeAxEaxImm(OPCODE_ADD, self.cpu.operSize)
        elif (opcode == 0x06):
            return self.pushSeg(PUSH_ES)
        elif (opcode == 0x07):
            return self.popSeg(POP_ES)
        elif (opcode == 0x08):
            return self.opcodeRM_R(OPCODE_OR, OP_SIZE_BYTE)
        elif (opcode == 0x09):
            return self.opcodeRM_R(OPCODE_OR, self.cpu.operSize)
        elif (opcode == 0x0a):
            return self.opcodeR_RM(OPCODE_OR, OP_SIZE_BYTE)
        elif (opcode == 0x0b):
            return self.opcodeR_RM(OPCODE_OR, self.cpu.operSize)
        elif (opcode == 0x0c):
            return self.opcodeAxEaxImm(OPCODE_OR, OP_SIZE_BYTE)
        elif (opcode == 0x0d):
            return self.opcodeAxEaxImm(OPCODE_OR, self.cpu.operSize)
        elif (opcode == 0x0e):
            return self.pushSeg(PUSH_CS)
        elif (opcode == 0x0f):
            return self.opcodeGroup0F()
        elif (opcode == 0x10):
            return self.opcodeRM_R(OPCODE_ADC, OP_SIZE_BYTE)
        elif (opcode == 0x11):
            return self.opcodeRM_R(OPCODE_ADC, self.cpu.operSize)
        elif (opcode == 0x12):
            return self.opcodeR_RM(OPCODE_ADC, OP_SIZE_BYTE)
        elif (opcode == 0x13):
            return self.opcodeR_RM(OPCODE_ADC, self.cpu.operSize)
        elif (opcode == 0x14):
            return self.opcodeAxEaxImm(OPCODE_ADC, OP_SIZE_BYTE)
        elif (opcode == 0x15):
            return self.opcodeAxEaxImm(OPCODE_ADC, self.cpu.operSize)
        elif (opcode == 0x16):
            return self.pushSeg(PUSH_SS)
        elif (opcode == 0x17):
            return self.popSeg(POP_SS)
        elif (opcode == 0x18):
            return self.opcodeRM_R(OPCODE_SBB, OP_SIZE_BYTE)
        elif (opcode == 0x19):
            return self.opcodeRM_R(OPCODE_SBB, self.cpu.operSize)
        elif (opcode == 0x1a):
            return self.opcodeR_RM(OPCODE_SBB, OP_SIZE_BYTE)
        elif (opcode == 0x1b):
            return self.opcodeR_RM(OPCODE_SBB, self.cpu.operSize)
        elif (opcode == 0x1c):
            return self.opcodeAxEaxImm(OPCODE_SBB, OP_SIZE_BYTE)
        elif (opcode == 0x1d):
            return self.opcodeAxEaxImm(OPCODE_SBB, self.cpu.operSize)
        elif (opcode == 0x1e):
            return self.pushSeg(PUSH_DS)
        elif (opcode == 0x1f):
            return self.popSeg(POP_DS)
        elif (opcode == 0x20):
            return self.opcodeRM_R(OPCODE_AND, OP_SIZE_BYTE)
        elif (opcode == 0x21):
            return self.opcodeRM_R(OPCODE_AND, self.cpu.operSize)
        elif (opcode == 0x22):
            return self.opcodeR_RM(OPCODE_AND, OP_SIZE_BYTE)
        elif (opcode == 0x23):
            return self.opcodeR_RM(OPCODE_AND, self.cpu.operSize)
        elif (opcode == 0x24):
            return self.opcodeAxEaxImm(OPCODE_AND, OP_SIZE_BYTE)
        elif (opcode == 0x25):
            return self.opcodeAxEaxImm(OPCODE_AND, self.cpu.operSize)
        elif (opcode == 0x27):
            return self.daa()
        elif (opcode == 0x28):
            return self.opcodeRM_R(OPCODE_SUB, OP_SIZE_BYTE)
        elif (opcode == 0x29):
            return self.opcodeRM_R(OPCODE_SUB, self.cpu.operSize)
        elif (opcode == 0x2a):
            return self.opcodeR_RM(OPCODE_SUB, OP_SIZE_BYTE)
        elif (opcode == 0x2b):
            return self.opcodeR_RM(OPCODE_SUB, self.cpu.operSize)
        elif (opcode == 0x2c):
            return self.opcodeAxEaxImm(OPCODE_SUB, OP_SIZE_BYTE)
        elif (opcode == 0x2d):
            return self.opcodeAxEaxImm(OPCODE_SUB, self.cpu.operSize)
        elif (opcode == 0x2f):
            return self.das()
        elif (opcode == 0x30):
            return self.opcodeRM_R(OPCODE_XOR, OP_SIZE_BYTE)
        elif (opcode == 0x31):
            return self.opcodeRM_R(OPCODE_XOR, self.cpu.operSize)
        elif (opcode == 0x32):
            return self.opcodeR_RM(OPCODE_XOR, OP_SIZE_BYTE)
        elif (opcode == 0x33):
            return self.opcodeR_RM(OPCODE_XOR, self.cpu.operSize)
        elif (opcode == 0x34):
            return self.opcodeAxEaxImm(OPCODE_XOR, OP_SIZE_BYTE)
        elif (opcode == 0x35):
            return self.opcodeAxEaxImm(OPCODE_XOR, self.cpu.operSize)
        elif (opcode == 0x37):
            return self.aaa()
        elif (opcode == 0x38):
            return self.opcodeRM_R(OPCODE_CMP, OP_SIZE_BYTE)
        elif (opcode == 0x39):
            return self.opcodeRM_R(OPCODE_CMP, self.cpu.operSize)
        elif (opcode == 0x3a):
            return self.opcodeR_RM(OPCODE_CMP, OP_SIZE_BYTE)
        elif (opcode == 0x3b):
            return self.opcodeR_RM(OPCODE_CMP, self.cpu.operSize)
        elif (opcode == 0x3c):
            return self.opcodeAxEaxImm(OPCODE_CMP, OP_SIZE_BYTE)
        elif (opcode == 0x3d):
            return self.opcodeAxEaxImm(OPCODE_CMP, self.cpu.operSize)
        elif (opcode == 0x3f):
            return self.aas()
        elif ((opcode & 0xf8) == 0x40): # 0x40 .. 0x47
            return self.incReg()
        elif ((opcode & 0xf8) == 0x48): # 0x48 .. 0x4f
            return self.decReg()
        elif ((opcode & 0xf8) == 0x50): # 0x50 .. 0x57
            return self.pushReg()
        elif ((opcode & 0xf8) == 0x58): # 0x58 .. 0x5f
            return self.popReg()
        elif (opcode == 0x60):
            return self.pushaWD()
        elif (opcode == 0x61):
            return self.popaWD()
        elif (opcode == 0x62):
            return self.bound()
        elif (opcode == 0x63):
            return self.arpl()
        elif (opcode == 0x68):
            return self.pushIMM(False)
        elif (opcode == 0x69):
            return self.imulR_RM_ImmFunc(False)
        elif (opcode == 0x6a):
            return self.pushIMM(True)
        elif (opcode == 0x6b):
            return self.imulR_RM_ImmFunc(True)
        elif (opcode == 0x6c):
            return self.insFunc(OP_SIZE_BYTE)
        elif (opcode == 0x6d):
            return self.insFunc(self.cpu.operSize)
        elif (opcode == 0x6e):
            return self.outsFunc(OP_SIZE_BYTE)
        elif (opcode == 0x6f):
            return self.outsFunc(self.cpu.operSize)
        elif ((opcode & 0xf0) == 0x70):
            return self.jumpShort(OP_SIZE_BYTE, self.registers.getCond(opcode&0xf))
        elif (opcode in (0x80, 0x82)):
            return self.opcodeGroup1_RM_ImmFunc(OP_SIZE_BYTE, True)
        elif (opcode == 0x81):
            return self.opcodeGroup1_RM_ImmFunc(self.cpu.operSize, False)
        elif (opcode == 0x83):
            return self.opcodeGroup1_RM_ImmFunc(self.cpu.operSize, True)
        elif (opcode == 0x84):
            return self.opcodeRM_R(OPCODE_TEST, OP_SIZE_BYTE)
        elif (opcode == 0x85):
            return self.opcodeRM_R(OPCODE_TEST, self.cpu.operSize)
        elif (opcode == 0x86):
            return self.xchgR_RM(OP_SIZE_BYTE)
        elif (opcode == 0x87):
            return self.xchgR_RM(self.cpu.operSize)
        elif (opcode == 0x88):
            return self.movRM_R(OP_SIZE_BYTE)
        elif (opcode == 0x89):
            return self.movRM_R(self.cpu.operSize)
        elif (opcode == 0x8a):
            return self.movR_RM(OP_SIZE_BYTE, True)
        elif (opcode == 0x8b):
            return self.movR_RM(self.cpu.operSize, True)
        elif (opcode == 0x8c):
            return self.movRM16_SREG()
        elif (opcode == 0x8d):
            return self.lea()
        elif (opcode == 0x8e):
            return self.movSREG_RM16()
        elif (opcode == 0x8f):
            return self.popRM16_32()
        elif (opcode == 0x90):
            if (self.cpu.repPrefix == OPCODE_PREFIX_REPE): # PAUSE-Opcode (F3 90 / REPE NOP)
                with nogil:
                    usleep(0)
            return True
        elif ((opcode & 0xf8) == 0x90): # this won't match 0x90 because of the upper if
            return self.xchgReg()
        elif (opcode == 0x98):
            return self.cbw_cwde()
        elif (opcode == 0x99):
            return self.cwd_cdq()
        elif (opcode == 0x9a):
            return self.callPtr16_32()
        elif (opcode == 0x9b): # WAIT/FWAIT
            return self.fwait()
        elif (opcode == 0x9c):
            return self.pushfWD()
        elif (opcode == 0x9d):
            return self.popfWD()
        elif (opcode == 0x9e):
            return self.sahf()
        elif (opcode == 0x9f):
            return self.lahf()
        elif (opcode == 0xa0):
            return self.movAxMoffs(OP_SIZE_BYTE)
        elif (opcode == 0xa1):
            return self.movAxMoffs(self.cpu.operSize)
        elif (opcode == 0xa2):
            return self.movMoffsAx(OP_SIZE_BYTE)
        elif (opcode == 0xa3):
            return self.movMoffsAx(self.cpu.operSize)
        elif (opcode == 0xa4):
            return self.movsFunc(OP_SIZE_BYTE)
        elif (opcode == 0xa5):
            return self.movsFunc(self.cpu.operSize)
        elif (opcode == 0xa6):
            return self.cmpsFunc(OP_SIZE_BYTE)
        elif (opcode == 0xa7):
            return self.cmpsFunc(self.cpu.operSize)
        elif (opcode == 0xa8):
            return self.opcodeAxEaxImm(OPCODE_TEST, OP_SIZE_BYTE)
        elif (opcode == 0xa9):
            return self.opcodeAxEaxImm(OPCODE_TEST, self.cpu.operSize)
        elif (opcode == 0xaa):
            return self.stosFunc(OP_SIZE_BYTE)
        elif (opcode == 0xab):
            return self.stosFunc(self.cpu.operSize)
        elif (opcode == 0xac):
            return self.lodsFunc(OP_SIZE_BYTE)
        elif (opcode == 0xad):
            return self.lodsFunc(self.cpu.operSize)
        elif (opcode == 0xae):
            return self.scasFunc(OP_SIZE_BYTE)
        elif (opcode == 0xaf):
            return self.scasFunc(self.cpu.operSize)
        elif ((opcode & 0xf8) == 0xb0): # 0xb0 .. 0xb7
            return self.movImmToR(OP_SIZE_BYTE)
        elif ((opcode & 0xf8) == 0xb8): # 0xb8 .. 0xbf
            return self.movImmToR(self.cpu.operSize)
        elif (opcode == 0xc0):
            return self.opcodeGroup4_RM(OP_SIZE_BYTE, GROUP4_IMM8)
        elif (opcode == 0xc1):
            return self.opcodeGroup4_RM(self.cpu.operSize, GROUP4_IMM8)
        elif (opcode == 0xc2):
            return self.retNearImm()
        elif (opcode == 0xc3):
            return self.retNear(0)
        elif (opcode == 0xc4):
            return self.lfpFunc(&self.registers.segments.es) # LES
        elif (opcode == 0xc5):
            return self.lfpFunc(&self.registers.segments.ds) # LDS
        elif (opcode == 0xc6):
            return self.opcodeGroup3_RM_ImmFunc(OP_SIZE_BYTE)
        elif (opcode == 0xc7):
            return self.opcodeGroup3_RM_ImmFunc(self.cpu.operSize)
        elif (opcode == 0xc8):
            return self.enter()
        elif (opcode == 0xc9):
            return self.leave()
        elif (opcode == 0xca):
            return self.retFarImm()
        elif (opcode == 0xcb):
            return self.retFar(0)
        elif (opcode == 0xcc):
            self.main.notice("Opcodes::executeOpcode: INT3 (Opcode 0xcc): TODO!")
            raise HirnwichseException(CPU_EXCEPTION_BP)
        elif (opcode == 0xcd):
            return self.interrupt()
        elif (opcode == 0xce):
            return self.into()
        elif (opcode == 0xcf):
            return self.iret()
        elif (opcode == 0xd0):
            return self.opcodeGroup4_RM(OP_SIZE_BYTE, GROUP4_1)
        elif (opcode == 0xd1):
            return self.opcodeGroup4_RM(self.cpu.operSize, GROUP4_1)
        elif (opcode == 0xd2):
            return self.opcodeGroup4_RM(OP_SIZE_BYTE, GROUP4_CL)
        elif (opcode == 0xd3):
            return self.opcodeGroup4_RM(self.cpu.operSize, GROUP4_CL)
        elif (opcode == 0xd4):
            return self.aam()
        elif (opcode == 0xd5):
            return self.aad()
        elif (opcode == 0xd6):
            self.main.notice("Opcodes::executeOpcode: undef_no_UD! (Opcode 0xd6)")
            pass ### undefNoUD
            return True
        elif (opcode == 0xd7):
            return self.xlatb()
        elif ((opcode & 0xf8) == 0xd8):
            return self.fpuOpcodes(opcode-FPU_BASE_OPCODE)
        elif (opcode == 0xe0):
            return self.loopFunc(OPCODE_LOOPNE)
        elif (opcode == 0xe1):
            return self.loopFunc(OPCODE_LOOPE)
        elif (opcode == 0xe2):
            return self.loopFunc(OPCODE_LOOP)
        elif (opcode == 0xe3):
            return self.jcxzShort()
        elif (opcode == 0xe4):
            return self.inAxImm8(OP_SIZE_BYTE)
        elif (opcode == 0xe5):
            return self.inAxImm8(self.cpu.operSize)
        elif (opcode == 0xe6):
            return self.outImm8Ax(OP_SIZE_BYTE)
        elif (opcode == 0xe7):
            return self.outImm8Ax(self.cpu.operSize)
        elif (opcode == 0xe8):
            return self.callNearRel16_32()
        elif (opcode == 0xe9):
            return self.jumpShort(self.cpu.operSize, True)
        elif (opcode == 0xea):
            return self.jumpFarAbsolutePtr()
        elif (opcode == 0xeb):
            return self.jumpShort(OP_SIZE_BYTE, True)
        elif (opcode == 0xec):
            return self.inAxDx(OP_SIZE_BYTE)
        elif (opcode == 0xed):
            return self.inAxDx(self.cpu.operSize)
        elif (opcode == 0xee):
            return self.outDxAx(OP_SIZE_BYTE)
        elif (opcode == 0xef):
            return self.outDxAx(self.cpu.operSize)
        elif (opcode == 0xf1):
            self.main.notice("Opcodes::executeOpcode: undef_no_UD! (Opcode 0xf1)")
            pass ### undefNoUD
            return True
        elif (opcode == 0xf4):
            return self.hlt()
        elif (opcode == 0xf5):
            self.cmc()
            return True
        elif (opcode == 0xf6):
            return self.opcodeGroup2_RM(OP_SIZE_BYTE)
        elif (opcode == 0xf7):
            return self.opcodeGroup2_RM(self.cpu.operSize)
        elif (opcode == 0xf8):
            self.clc()
            return True
        elif (opcode == 0xf9):
            self.stc()
            return True
        elif (opcode == 0xfa):
            self.cli()
            return True
        elif (opcode == 0xfb):
            self.sti()
            return True
        elif (opcode == 0xfc):
            self.cld()
            return True
        elif (opcode == 0xfd):
            self.std()
            return True
        elif (opcode == 0xfe):
            return self.opcodeGroupFE()
        elif (opcode == 0xff):
            return self.opcodeGroupFF()
        else:
            self.main.notice("handler for opcode 0x%02x wasn't found.", opcode)
            #raise HirnwichseException(CPU_EXCEPTION_UD) # if opcode wasn't found.
            return False
        #return False
    cdef int cli(self) except BITMASK_BYTE_CONST:
        if (self.registers.protectedModeOn):
            if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
                if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.iopl < 3):
                    if (self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_VME) != 0):
                        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vif = False
                        return True
                    else:
                        raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            elif (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.iopl < self.registers.getCPL()):
                if ((self.registers.getCPL() == 3) and self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_PVI) != 0):
                    self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vif = False
                    return True
                else:
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.if_flag = False
        return True
    cdef int sti(self) except BITMASK_BYTE_CONST:
        if (self.registers.protectedModeOn):
            if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
                if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.iopl < 3):
                    if (self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_VME) != 0 and not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vip):
                        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vif = True
                        return True
                    else:
                        raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            elif (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.iopl < self.registers.getCPL()):
                if ((self.registers.getCPL() == 3) and self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_PVI) != 0):
                    self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vif = True
                    return True
                else:
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.if_flag = True
        self.registers.ssInhibit = True
        self.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
        return True
    cdef inline int hlt(self) except BITMASK_BYTE_CONST:
        if (self.registers.getCPL() > 0):
            #self.main.notice("Opcodes::hlt: CPL > 0.")
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            #return True
        self.cpu.cpuHalted = True
        #if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.if_flag and self.main.debugEnabled):
        #    self.main.debug("Opcodes::hlt: HLT was called with IF on.")
        return True
    cdef inline void cld(self) nogil:
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df = False
    cdef inline void std(self) nogil:
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df = True
    cdef inline void clc(self) nogil:
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = False
    cdef inline void stc(self) nogil:
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = True
    cdef inline void cmc(self) nogil:
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
    cdef inline void clac(self) nogil:
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.ac = False
    cdef inline void stac(self) nogil:
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.ac = True
    cdef int checkIOPL(self, uint16_t ioPortAddr, uint8_t dataSize) except BITMASK_BYTE_CONST: # return True if protected
        cdef uint8_t res
        cdef uint16_t ioMapBase, bits
        if (not self.registers.protectedModeOn or (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm and self.registers.getCPL() <= self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.iopl)):
            return False
        ioMapBase = self.registers.mmReadValueUnsignedWord(TSS_32BIT_IOMAP_BASE_ADDR, &self.registers.segments.tss, False)
        if (ioMapBase >= (<Segment>self.registers.segments.tss).gdtEntry.limit):
            #self.main.notice("Opcodes::checkIOPL: test1: iomap base addr==0x%04x; tss limit==0x%04x", self.registers.mmReadValueUnsignedWord(TSS_32BIT_IOMAP_BASE_ADDR, &self.registers.segments.tss, False), (<Segment>self.registers.segments.tss).gdtEntry.limit)
            return True
        bits = self.registers.mmReadValueUnsignedWord(ioMapBase+(ioPortAddr>>3), &self.registers.segments.tss, False)>>(ioPortAddr&0x7)
        res = (bits&((1<<dataSize)-1)) != 0
        #if (res):
        #    self.main.notice("Opcodes::checkIOPL: test2.0: iomap base addr==0x%04x; tss limit==0x%04x", self.registers.mmReadValueUnsignedWord(TSS_32BIT_IOMAP_BASE_ADDR, &self.registers.segments.tss, False), (<Segment>self.registers.segments.tss).gdtEntry.limit)
        #    self.main.notice("Opcodes::checkIOPL: test2.1: bits==0x%04x; result==%u; result==1 means gpf", bits, res)
        return res
    cdef long int inPort(self, uint16_t ioPortAddr, uint8_t dataSize) except? BITMASK_BYTE_CONST:
        if (self.registers.protectedModeOn and self.checkIOPL(ioPortAddr, dataSize)):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        return self.main.platform.inPort(ioPortAddr, dataSize)
    cdef int outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) except BITMASK_BYTE_CONST:
        if (self.registers.protectedModeOn and self.checkIOPL(ioPortAddr, dataSize)):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        self.main.platform.outPort(ioPortAddr, data, dataSize)
        return True
    cdef int jumpFarDirect(self, uint8_t method, uint16_t segVal, uint32_t eipVal) except BITMASK_BYTE_CONST:
        cdef uint8_t segType, oldSegType
        cdef uint16_t oldTSSsel
        cdef GdtEntry gdtEntry
        cdef Segment *segment
        self.registers.syncCR0State()
        if (method == OPCODE_CALL):
            self.stackPushSegment(&self.registers.segments.cs, self.cpu.operSize, False)
            self.stackPushRegId(CPU_REGISTER_EIP, self.cpu.operSize)
        if (self.registers.protectedModeOn and not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
            if (not self.registers.segments.getEntry(&gdtEntry, segVal)):
                raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
            if (not gdtEntry.segPresent):
                raise HirnwichseException(CPU_EXCEPTION_NP, segVal)
            segType = (gdtEntry.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK)
            if (segType in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_CALL_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_CALL_GATE)):
                self.main.exitError("Opcodes::jumpFarDirect: call-gate sysSegType %u isn't supported yet. (segVal 0x%04x; eipVal 0x%08x)", segType, segVal, eipVal)
                return True
            elif (segType == TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE):
                if (self.main.debugEnabled):
                #IF 1:
                    self.main.notice("Opcodes::jumpFarDirect: task-gates aren't fully implemented yet.")
                segment = &self.registers.segments.tss
                if (gdtEntry.segDPL < self.registers.getCPL() or gdtEntry.segDPL < segVal&3):
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                segVal = gdtEntry.base
                if (not self.registers.segments.getEntry(&gdtEntry, segVal)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                segType = (gdtEntry.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK)
                if ((segVal & GDT_USE_LDT) or (gdtEntry.segIsRW) or segType in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY) or not self.registers.segments.inLimit(segVal)): # segIsRW means busy here
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                if (not gdtEntry.segPresent):
                    raise HirnwichseException(CPU_EXCEPTION_NP, segVal)
                segType &= TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY
                oldTSSsel = segment[0].segmentIndex
                oldSegType = self.registers.segments.getSegType(oldTSSsel) & TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY
                if (method == OPCODE_JUMP):
                    self.registers.segments.setSegType(oldTSSsel, oldSegType)
                if (oldSegType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.saveTSS32()
                else:
                    self.registers.saveTSS16()
                self.registers.segWriteSegment(&self.registers.segments.tss, segVal)
                if (segType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.switchTSS32()
                else:
                    self.registers.switchTSS16()
                if (method == OPCODE_CALL):
                    self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.nt = True
                    self.registers.mmWriteValue(TSS_PREVIOUS_TASK_LINK, oldTSSsel, OP_SIZE_WORD, &self.registers.segments.tss, False)
                self.registers.segments.setSegType(segVal, (segType | 0x2))
                if (not self.registers.isAddressInLimit(&self.registers.segments.cs.gdtEntry, self.registers.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_BYTE)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                return True
            elif ((segType & TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY) in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS)):
                if (self.main.debugEnabled):
                #IF 1:
                    self.main.notice("Opcodes::jumpFarDirect: TSS isn't fully implemented yet.")
                #self.main.notice("Opcodes::jumpFarDirect: test1: segType1 == 0x%02x; segType2 == 0x%02x!", self.registers.segments.getSegType(0x20), self.registers.segments.getSegType(0x30))
                segment = &self.registers.segments.tss
                if ((segVal & GDT_USE_LDT) or not self.registers.segments.inLimit(segVal)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                if (segType in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, segVal)
                oldTSSsel = segment[0].segmentIndex
                oldSegType = self.registers.segments.getSegType(oldTSSsel) & TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY
                if (method == OPCODE_JUMP):
                    self.registers.segments.setSegType(oldTSSsel, oldSegType)
                if (oldSegType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.saveTSS32()
                else:
                    self.registers.saveTSS16()
                self.registers.segWriteSegment(segment, segVal)
                if (not segment[0].isValid or segment[0].gdtEntry.segDPL < self.registers.getCPL() or segment[0].gdtEntry.segDPL < (segment[0].segmentIndex&3)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, segment[0].segmentIndex)
                if (not segment[0].gdtEntry.segPresent):
                    raise HirnwichseException(CPU_EXCEPTION_NP, segment[0].segmentIndex)
                if (segment[0].gdtEntry.limit < 0x67):
                    raise HirnwichseException(CPU_EXCEPTION_TS, segment[0].segmentIndex)
                if (segType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.switchTSS32()
                else:
                    self.registers.switchTSS16()
                if (method == OPCODE_CALL):
                    self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.nt = True
                    self.registers.mmWriteValue(TSS_PREVIOUS_TASK_LINK, oldTSSsel, OP_SIZE_WORD, &self.registers.segments.tss, False)
                self.registers.segments.setSegType(segVal, (segType | 0x2))
                if (not self.registers.isAddressInLimit(&self.registers.segments.cs.gdtEntry, self.registers.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_BYTE)): # TODO
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                #self.main.notice("Opcodes::jumpFarDirect: sysSegType == %u; method == %u (TSS); TODO!", segType, method)
                #self.main.notice("Opcodes::jumpFarDirect: test2: segType1 == 0x%02x; segType2 == 0x%02x!", self.registers.segments.getSegType(0x20), self.registers.segments.getSegType(0x30))
                return True
            elif (not (segType & GDT_ACCESS_NORMAL_SEGMENT)):
                self.main.exitError("Opcodes::jumpFarDirect: sysSegType %u isn't supported yet. (segVal 0x%04x; eipVal 0x%08x)", segType, segVal, eipVal)
                return True
        #self.main.debug("Opcodes::jumpFarDirect: test8: Gdt::tableLimit==0x%04x", self.registers.segments.gdt.tableLimit)
        self.registers.segWriteSegment(&self.registers.segments.cs, segVal)
        #self.main.debug("Opcodes::jumpFarDirect: test9: Gdt::tableLimit==0x%04x", self.registers.segments.gdt.tableLimit)
        self.registers.regWriteDword(CPU_REGISTER_EIP, eipVal)
        return True
    cdef inline int jumpFarAbsolutePtr(self) except BITMASK_BYTE_CONST:
        cdef uint16_t cs
        cdef uint32_t eip
        eip = self.registers.getCurrentOpcodeAddUnsigned(self.cpu.operSize)
        cs = self.registers.getCurrentOpcodeAddUnsignedWord()
        if (self.main.debugEnabled):
            self.main.notice("Opcodes::jumpFarAbsolutePtr: cs==0x%04x; eip==0x%08x", cs, eip)
        return self.jumpFarDirect(OPCODE_JUMP, cs, eip)
    cdef inline int loopFunc(self, uint8_t loopType) except BITMASK_BYTE_CONST:
        cdef uint8_t oldZF
        cdef int8_t rel8
        oldZF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf
        rel8 = <int8_t>self.registers.getCurrentOpcodeAddUnsignedByte()
        if (self.cpu.addrSize == OP_SIZE_WORD):
            self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx-1
            if (not self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx):
                return True
        else:
            self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx-1
            if (not self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx):
                return True
        if ((loopType == OPCODE_LOOPE and not oldZF) or (loopType == OPCODE_LOOPNE and oldZF)):
            return True
        if (self.cpu.operSize == OP_SIZE_WORD):
            self.registers.regWriteWord(CPU_REGISTER_IP, self.registers.regs[CPU_REGISTER_IP]._union.word._union.rx+rel8)
        else:
            self.registers.regWriteDword(CPU_REGISTER_EIP, self.registers.regs[CPU_REGISTER_EIP]._union.dword.erx+rel8)
        return True
    cdef int opcodeR_RM(self, uint8_t opcode, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t op1 = 0, op2
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
            op1 = self.modRMInstance.modRSave(operSize, op2, opcode)
            self.registers.setSZP_COA(op1, operSize)
        elif (opcode == OPCODE_TEST):
            self.main.exitError("OPCODE::opcodeR_RM: OPCODE_TEST HAS NO R_RM!!")
        else:
            self.main.exitError("OPCODE::opcodeR_RM: invalid opcode: %u.", opcode)
        return True
    cdef int opcodeRM_R(self, uint8_t opcode, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t op1 = 0, op2
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
            self.main.notice("OPCODE::opcodeRM_R: invalid opcode: %u.", opcode)
        return True
    cdef int opcodeAxEaxImm(self, uint8_t opcode, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t op1 = 0, op2
        if (opcode not in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            if (operSize == OP_SIZE_BYTE):
                op1 = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl
            elif (operSize == OP_SIZE_WORD):
                op1 = self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx
            elif (operSize == OP_SIZE_DWORD):
                op1 = self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx
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
            self.main.notice("OPCODE::opcodeRM_R: invalid opcode: %u.", opcode)
        return True
    cdef inline int movImmToR(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint8_t rReg
        cdef uint32_t src
        rReg = self.cpu.opcode&0x7
        src = self.registers.getCurrentOpcodeAddUnsigned(operSize)
        if (operSize == OP_SIZE_BYTE):
            if (rReg & 0x4):
                self.registers.regs[rReg&3]._union.word._union.byte.rh = src
            else:
                self.registers.regs[rReg]._union.word._union.byte.rl = src
        elif (operSize == OP_SIZE_WORD):
            self.registers.regs[rReg]._union.word._union.rx = src
        elif (operSize == OP_SIZE_DWORD):
            self.registers.regs[rReg]._union.dword.erx = src
        else:
            self.main.notice("OPCODE::movImmToR: unknown operSize: %u.", operSize)
        return True
    cdef inline int movRM_R(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        self.modRMInstance.modRMSave(operSize, self.modRMInstance.modRLoadUnsigned(operSize), OPCODE_SAVE)
        return True
    cdef inline int movR_RM(self, uint8_t operSize, uint8_t cond) except BITMASK_BYTE_CONST:
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (cond):
            self.modRMInstance.modRSave(operSize, self.modRMInstance.modRMLoadUnsigned(operSize), OPCODE_SAVE)
        return True
    cdef inline int movRM16_SREG(self) except BITMASK_BYTE_CONST:
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        if (self.modRMInstance.mod == 3):
            self.modRMInstance.modRMSave(self.cpu.operSize, self.registers.regs[CPU_SEGMENT_BASE+self.modRMInstance.regName]._union.word._union.rx, OPCODE_SAVE)
        else:
            self.modRMInstance.modRMSave(OP_SIZE_WORD, self.registers.regs[CPU_SEGMENT_BASE+self.modRMInstance.regName]._union.word._union.rx, OPCODE_SAVE)
        return True
    cdef inline int movSREG_RM16(self) except BITMASK_BYTE_CONST:
        cdef Segment *segment
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        if (self.modRMInstance.regName == CPU_SEGMENT_CS):
            raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (self.modRMInstance.regName == CPU_SEGMENT_SS):
            segment = &self.registers.segments.ss
            self.registers.ssInhibit = True
        elif (self.modRMInstance.regName == CPU_SEGMENT_DS):
            segment = &self.registers.segments.ds
        elif (self.modRMInstance.regName == CPU_SEGMENT_ES):
            segment = &self.registers.segments.es
        elif (self.modRMInstance.regName == CPU_SEGMENT_FS):
            segment = &self.registers.segments.fs
        elif (self.modRMInstance.regName == CPU_SEGMENT_GS):
            segment = &self.registers.segments.gs
        elif (self.modRMInstance.regName == CPU_SEGMENT_TSS):
            segment = &self.registers.segments.tss
        else:
            self.main.exitError("Opcodes::movSREG_RM16: segId %u doesn't exist.", self.modRMInstance.regName)
            return True
        self.registers.segWriteSegment(segment, self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD))
        return True
    cdef inline int movAxMoffs(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        self.registers.regWrite(CPU_REGISTER_AX, \
          self.registers.mmReadValueUnsigned(self.registers.getCurrentOpcodeAddUnsigned(self.cpu.addrSize), operSize, &self.registers.segments.ds, True), operSize)
        return True
    cdef inline int movMoffsAx(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t value = 0
        if (operSize == OP_SIZE_BYTE):
            value = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl
        elif (operSize == OP_SIZE_WORD):
            value = self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx
        elif (operSize == OP_SIZE_DWORD):
            value = self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx
        self.registers.mmWriteValue(self.registers.getCurrentOpcodeAddUnsigned(self.cpu.addrSize), value, operSize, &self.registers.segments.ds, True)
        return True
    cdef int stosFuncWord(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint16_t countVal, i
        cdef uint32_t data
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx
            if (not countVal):
                return True
        else:
            countVal = 1
        data = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
        for i in range(countVal):
            self.registers.mmWriteValue(self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx, data, operSize, &self.registers.segments.es, False)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx+operSize
            else:
                self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx-1
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef int stosFuncDword(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t data, countVal, i
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx
            if (not countVal):
                return True
        else:
            countVal = 1
        data = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
        for i in range(countVal):
            self.registers.mmWriteValue(self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx, data, operSize, &self.registers.segments.es, False)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx = self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx+operSize
            else:
                self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx = self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx-1
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef inline int stosFunc(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        if (self.cpu.addrSize == OP_SIZE_WORD):
            return self.stosFuncWord(operSize)
        elif (self.cpu.addrSize == OP_SIZE_DWORD):
            return self.stosFuncDword(operSize)
        return True
    cdef int movsFuncWord(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint16_t countVal, i
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx
            if (not countVal):
                return True
        else:
            countVal = 1
        for i in range(countVal):
            self.registers.mmWriteValue(self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx, self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx, operSize, &self.registers.segments.ds, True), operSize, &self.registers.segments.es, False)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx+operSize
                self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx+operSize
            else:
                self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx-operSize
                self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx-1
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef int movsFuncDword(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t countVal, i
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx
            if (not countVal):
                return True
        else:
            countVal = 1
        for i in range(countVal):
            self.registers.mmWriteValue(self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx, self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx, operSize, &self.registers.segments.ds, True), operSize, &self.registers.segments.es, False)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx+operSize
                self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx = self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx+operSize
            else:
                self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx-operSize
                self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx = self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx-1
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef inline int movsFunc(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        if (self.cpu.addrSize == OP_SIZE_WORD):
            return self.movsFuncWord(operSize)
        elif (self.cpu.addrSize == OP_SIZE_DWORD):
            return self.movsFuncDword(operSize)
        return True
    cdef int lodsFuncWord(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint16_t countVal, i
        cdef uint32_t data
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx
            if (not countVal):
                return True
        else:
            countVal = 1
        for i in range(countVal):
            data = self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx, operSize, &self.registers.segments.ds, True)
            self.registers.regWrite(CPU_REGISTER_AX, data, operSize)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx+operSize
            else:
                self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx-1
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef int lodsFuncDword(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t data, countVal, i
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx
            if (not countVal):
                return True
        else:
            countVal = 1
        for i in range(countVal):
            data = self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx, operSize, &self.registers.segments.ds, True)
            self.registers.regWrite(CPU_REGISTER_AX, data, operSize)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx+operSize
            else:
                self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx-1
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef inline int lodsFunc(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        if (self.cpu.addrSize == OP_SIZE_WORD):
            return self.lodsFuncWord(operSize)
        elif (self.cpu.addrSize == OP_SIZE_DWORD):
            return self.lodsFuncDword(operSize)
        return True
    cdef int cmpsFuncWord(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint8_t zfFlag
        cdef uint16_t countVal, i
        cdef uint32_t src1, src2
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx
            if (not countVal):
                return True
        else:
            countVal = 1
        for i in range(countVal):
            src1 = self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx, operSize, &self.registers.segments.ds, True)
            src2 = self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx, operSize, &self.registers.segments.es, False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx+operSize
                self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx+operSize
            else:
                self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx-operSize
                self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx-1
            zfFlag = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf
            if ((self.cpu.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or (self.cpu.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                break
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef int cmpsFuncDword(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint8_t zfFlag
        cdef uint32_t countVal, src1, src2, i
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx
            if (not countVal):
                return True
        else:
            countVal = 1
        for i in range(countVal):
            src1 = self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx, operSize, &self.registers.segments.ds, True)
            src2 = self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx, operSize, &self.registers.segments.es, False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx+operSize
                self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx = self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx+operSize
            else:
                self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx-operSize
                self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx = self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx-1
            zfFlag = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf
            if ((self.cpu.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or (self.cpu.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                break
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef inline int cmpsFunc(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        if (self.cpu.addrSize == OP_SIZE_WORD):
            return self.cmpsFuncWord(operSize)
        elif (self.cpu.addrSize == OP_SIZE_DWORD):
            return self.cmpsFuncDword(operSize)
        return True
    cdef int scasFuncWord(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint8_t zfFlag
        cdef uint16_t countVal, i
        cdef uint32_t src1, src2
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx
            if (not countVal):
                return True
        else:
            countVal = 1
        src1 = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
        for i in range(countVal):
            src2 = self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx, operSize, &self.registers.segments.es, False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx+operSize
            else:
                self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx-1
            zfFlag = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf
            if ((self.cpu.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or (self.cpu.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                break
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef int scasFuncDword(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint8_t zfFlag
        cdef uint32_t src1, src2, countVal, i
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx
            if (not countVal):
                return True
        else:
            countVal = 1
        src1 = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
        for i in range(countVal):
            src2 = self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx, operSize, &self.registers.segments.es, False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx = self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx+operSize
            else:
                self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx = self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx-1
            zfFlag = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf
            if ((self.cpu.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or (self.cpu.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                break
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef inline int scasFunc(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        if (self.cpu.addrSize == OP_SIZE_WORD):
            return self.scasFuncWord(operSize)
        elif (self.cpu.addrSize == OP_SIZE_DWORD):
            return self.scasFuncDword(operSize)
        return True
    cdef int inAxImm8(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t value
        value = self.inPort(self.registers.getCurrentOpcodeAddUnsignedByte(), operSize)
        if (operSize == OP_SIZE_BYTE):
            self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl = value
        elif (operSize == OP_SIZE_WORD):
            self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx = value
        elif (operSize == OP_SIZE_DWORD):
            self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = value
        return True
    cdef int inAxDx(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t value
        value = self.inPort(self.registers.regs[CPU_REGISTER_DX]._union.word._union.rx, operSize)
        if (operSize == OP_SIZE_BYTE):
            self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl = value
        elif (operSize == OP_SIZE_WORD):
            self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx = value
        elif (operSize == OP_SIZE_DWORD):
            self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = value
        return True
    cdef int outImm8Ax(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t value = 0
        if (operSize == OP_SIZE_BYTE):
            value = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl
        elif (operSize == OP_SIZE_WORD):
            value = self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx
        elif (operSize == OP_SIZE_DWORD):
            value = self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx
        self.outPort(self.registers.getCurrentOpcodeAddUnsignedByte(), value, operSize)
        return True
    cdef int outDxAx(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t value = 0
        if (operSize == OP_SIZE_BYTE):
            value = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl
        elif (operSize == OP_SIZE_WORD):
            value = self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx
        elif (operSize == OP_SIZE_DWORD):
            value = self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx
        self.outPort(self.registers.regs[CPU_REGISTER_DX]._union.word._union.rx, value, operSize)
        return True
    cdef int outsFuncWord(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint16_t countVal, i
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx
            if (not countVal):
                return True
        else:
            countVal = 1
        for i in range(countVal):
            self.outPort(self.registers.regs[CPU_REGISTER_DX]._union.word._union.rx, self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx, operSize, &self.registers.segments.ds, True), operSize)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx+operSize
            else:
                self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_SI]._union.word._union.rx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx-1
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef int outsFuncDword(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t countVal, i
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx
            if (not countVal):
                return True
        else:
            countVal = 1
        for i in range(countVal):
            self.outPort(self.registers.regs[CPU_REGISTER_DX]._union.word._union.rx, self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx, operSize, &self.registers.segments.ds, True), operSize)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx+operSize
            else:
                self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESI]._union.dword.erx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx-1
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef inline int outsFunc(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        if (self.cpu.addrSize == OP_SIZE_WORD):
            return self.outsFuncWord(operSize)
        elif (self.cpu.addrSize == OP_SIZE_DWORD):
            return self.outsFuncDword(operSize)
        return True
    cdef int insFuncWord(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint16_t countVal, i
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx
            if (not countVal):
                return True
        else:
            countVal = 1
        for i in range(countVal):
            self.registers.mmWriteValue(self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx, self.inPort(self.registers.regs[CPU_REGISTER_DX]._union.word._union.rx, operSize), operSize, &self.registers.segments.es, False)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx+operSize
            else:
                self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx = self.registers.regs[CPU_REGISTER_DI]._union.word._union.rx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx = self.registers.regs[CPU_REGISTER_CX]._union.word._union.rx-1
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef int insFuncDword(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t countVal, i
        if (self.cpu.repPrefix):
            countVal = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx
            if (not countVal):
                return True
        else:
            countVal = 1
        for i in range(countVal):
            self.registers.mmWriteValue(self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx, self.inPort(self.registers.regs[CPU_REGISTER_DX]._union.word._union.rx, operSize), operSize, &self.registers.segments.es, False)
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.df):
                self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx = self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx+operSize
            else:
                self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx = self.registers.regs[CPU_REGISTER_EDI]._union.dword.erx-operSize
            if (self.cpu.repPrefix):
                self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx-1
        #self.cpu.cycles = self.cpu.cycles+(countVal << CPU_CLOCK_TICK_SHIFT) # cython doesn't like the former variant without GIL
        return True
    cdef inline int insFunc(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        if (self.cpu.addrSize == OP_SIZE_WORD):
            return self.insFuncWord(operSize)
        elif (self.cpu.addrSize == OP_SIZE_DWORD):
            return self.insFuncDword(operSize)
        return True
    cdef inline int jcxzShort(self) except BITMASK_BYTE_CONST:
        cdef uint32_t cxVal
        cxVal = self.registers.regReadUnsigned(CPU_REGISTER_CX, self.cpu.addrSize)
        self.jumpShort(OP_SIZE_BYTE, not cxVal)
        return True
    cdef inline int jumpShort(self, int32_t offset, uint8_t cond) except BITMASK_BYTE_CONST:
        if (cond):
            offset = self.registers.getCurrentOpcodeAddSigned(offset)
        self.registers.syncCR0State()
        if (self.cpu.operSize == OP_SIZE_WORD):
            self.registers.regWriteWord(CPU_REGISTER_EIP, self.registers.regs[CPU_REGISTER_EIP]._union.word._union.rx+offset)
        else:
            self.registers.regWriteDword(CPU_REGISTER_EIP, self.registers.regs[CPU_REGISTER_EIP]._union.dword.erx+offset)
        return True
    cdef inline int callNearRel16_32(self) except BITMASK_BYTE_CONST:
        cdef int32_t offset
        cdef uint32_t newEip
        offset = self.registers.getCurrentOpcodeAddSigned(self.cpu.operSize)
        self.registers.syncCR0State()
        newEip = (self.registers.regs[CPU_REGISTER_EIP]._union.dword.erx+offset)
        if (self.cpu.operSize == OP_SIZE_WORD):
            newEip = <uint16_t>newEip
        if (self.registers.protectedModeOn and not self.registers.isAddressInLimit(&self.registers.segments.cs.gdtEntry, newEip, OP_SIZE_BYTE)):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        self.stackPushRegId(CPU_REGISTER_EIP, self.cpu.operSize)
        self.registers.regWriteDword(CPU_REGISTER_EIP, newEip)
        return True
    cdef inline int callPtr16_32(self) except BITMASK_BYTE_CONST:
        cdef uint16_t segVal
        cdef uint32_t eipAddr
        eipAddr = self.registers.getCurrentOpcodeAddUnsigned(self.cpu.operSize)
        segVal = self.registers.getCurrentOpcodeAddUnsignedWord()
        self.jumpFarDirect(OPCODE_CALL, segVal, eipAddr)
        return True
    cdef int pushaWD(self) except BITMASK_BYTE_CONST:
        cdef uint32_t temp
        temp = self.registers.regReadUnsigned(CPU_REGISTER_SP, self.cpu.operSize)
        if (not self.registers.protectedModeOn and temp in (7, 9, 11, 13, 15)):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        self.stackPushRegId(CPU_REGISTER_AX, self.cpu.operSize)
        self.stackPushRegId(CPU_REGISTER_CX, self.cpu.operSize)
        self.stackPushRegId(CPU_REGISTER_DX, self.cpu.operSize)
        self.stackPushRegId(CPU_REGISTER_BX, self.cpu.operSize)
        self.stackPushValue(temp, self.cpu.operSize, False)
        self.stackPushRegId(CPU_REGISTER_BP, self.cpu.operSize)
        self.stackPushRegId(CPU_REGISTER_SI, self.cpu.operSize)
        self.stackPushRegId(CPU_REGISTER_DI, self.cpu.operSize)
        return True
    cdef int popaWD(self) except BITMASK_BYTE_CONST:
        self.stackPopRegId(CPU_REGISTER_DI, self.cpu.operSize)
        self.stackPopRegId(CPU_REGISTER_SI, self.cpu.operSize)
        self.stackPopRegId(CPU_REGISTER_BP, self.cpu.operSize)
        self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx+self.cpu.operSize
        self.stackPopRegId(CPU_REGISTER_BX, self.cpu.operSize)
        self.stackPopRegId(CPU_REGISTER_DX, self.cpu.operSize)
        self.stackPopRegId(CPU_REGISTER_CX, self.cpu.operSize)
        self.stackPopRegId(CPU_REGISTER_AX, self.cpu.operSize)
        return True
    cdef int pushfWD(self) except BITMASK_BYTE_CONST:
        cdef uint8_t iopl
        cdef uint32_t value
        iopl = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.iopl
        if (self.registers.protectedModeOn and self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm and iopl < 3):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        value = self.registers.regReadUnsigned(CPU_REGISTER_FLAGS, self.cpu.operSize)
        value &= (~FLAG_IOPL) # This is for
        value |= (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.iopl<<12) # IOPL, Bits 12,13
        if (self.cpu.operSize == OP_SIZE_DWORD):
            value &= <uint32_t>0x00FCFFFF
        self.stackPushValue(value, self.cpu.operSize, False)
        return True
    cdef int popfWD(self) except BITMASK_BYTE_CONST:
        cdef uint8_t cpl, iopl
        cdef uint32_t flagValue, oldFlagValue, keepFlags
        keepFlags = FLAG_VM | FLAG_VIP | FLAG_VIF
        iopl = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.iopl
        if (self.registers.protectedModeOn and self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm and (iopl < 3 or self.cpu.operSize == OP_SIZE_DWORD)):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        cpl = self.registers.getCPL()
        oldFlagValue = self.registers.regReadUnsigned(CPU_REGISTER_FLAGS, self.cpu.operSize)
        #oldFlagValue = self.registers.regs[CPU_REGISTER_EFLAGS]._union.dword.erx
        flagValue = self.stackPopValue(True)
        if (self.registers.protectedModeOn and self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm and iopl < 3 and self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_VME) != 0 and self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vip and (flagValue & FLAG_IF) != 0):
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        if (not (not cpl and (not self.registers.protectedModeOn or not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm))):
            keepFlags |= FLAG_IOPL
        if (self.registers.protectedModeOn):
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
                if (cpl > 0 and cpl > iopl):
                    keepFlags |= FLAG_IF
            elif (iopl != 3):
                keepFlags |= FLAG_IF
                if (self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_VME) != 0):
                    flagValue &= ~(FLAG_VIF)
                    if ((flagValue & FLAG_IF) != 0):
                        flagValue |= FLAG_VIF
                else:
                    keepFlags |= FLAG_VIF
        flagValue &= ~(keepFlags | RESERVED_FLAGS_BITMASK | FLAG_RF)
        flagValue |= oldFlagValue & keepFlags
        if (self.cpu.operSize == OP_SIZE_WORD):
            self.registers.regWriteWord(CPU_REGISTER_FLAGS, flagValue)
        else:
            self.registers.regWriteDword(CPU_REGISTER_EFLAGS, flagValue)
        #self.registers.regWriteDword(CPU_REGISTER_EFLAGS, flagValue)
        return True
    cdef inline int stackPopSegment(self, Segment *segment) except BITMASK_BYTE_CONST:
        self.registers.segWriteSegment(segment, <uint16_t>self.stackPopValue(True))
        return True
    cdef inline int stackPopRegId(self, uint16_t regId, uint8_t regSize) except BITMASK_BYTE_CONST:
        cdef uint32_t value
        value = self.stackPopValue(True)
        if (regSize == OP_SIZE_WORD):
            value = <uint16_t>value
        self.registers.regWrite(regId, value, regSize)
        return True
    cdef uint32_t stackPopValue(self, uint8_t increaseStackAddr) except? BITMASK_BYTE_CONST:
        cdef uint8_t stackAddrSize
        cdef uint32_t data
        stackAddrSize = (<Segment>self.registers.segments.ss).gdtEntry.segSize
        data = self.registers.regReadUnsigned(CPU_REGISTER_SP, stackAddrSize)
        data = self.registers.mmReadValueUnsigned(data, self.cpu.operSize, &self.registers.segments.ss, False)
        if (increaseStackAddr):
            if (stackAddrSize == OP_SIZE_WORD):
                self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx = self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx+self.cpu.operSize
            else:
                self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx+self.cpu.operSize
        return data
    cdef int stackPushValue(self, uint32_t value, uint8_t operSize, uint8_t onlyWord) except BITMASK_BYTE_CONST:
        cdef uint8_t stackAddrSize
        cdef uint32_t stackAddr
        stackAddrSize = (<Segment>self.registers.segments.ss).gdtEntry.segSize
        stackAddr = self.registers.regReadUnsigned(CPU_REGISTER_SP, stackAddrSize)
        stackAddr = (stackAddr-operSize)
        if (stackAddrSize == OP_SIZE_WORD):
            stackAddr = <uint16_t>stackAddr
        if (self.registers.protectedModeOn and not self.registers.isAddressInLimit(&self.registers.segments.ss.gdtEntry, stackAddr, operSize)):
            raise HirnwichseException(CPU_EXCEPTION_SS, 0)
        if (self.registers.protectedModeOn and self.registers.pagingOn): # TODO: HACK
             self.registers.segments.paging.getPhysicalAddress((<Segment>self.registers.segments.ss).gdtEntry.base+stackAddr, operSize, True)
        self.registers.regWrite(CPU_REGISTER_SP, stackAddr, stackAddrSize)
        if (operSize == OP_SIZE_WORD or onlyWord):
            value = <uint16_t>value
            operSize = OP_SIZE_WORD
        self.registers.mmWriteValue(stackAddr, value, operSize, &self.registers.segments.ss, False)
        return True
    cdef inline int stackPushSegment(self, Segment *segment, uint8_t operSize, uint8_t onlyWord) except BITMASK_BYTE_CONST:
        return self.stackPushValue(self.registers.regs[CPU_SEGMENT_BASE+segment[0].segId]._union.word._union.rx, operSize, onlyWord)
    cdef int stackPushRegId(self, uint16_t regId, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t value
        value = self.registers.regReadUnsigned(regId, operSize)
        return self.stackPushValue(value, operSize, False)
    cdef int pushIMM(self, uint8_t immIsByte) except BITMASK_BYTE_CONST:
        cdef uint32_t value
        if (immIsByte):
            value = <int8_t>self.registers.getCurrentOpcodeAddUnsignedByte()
        else:
            value = self.registers.getCurrentOpcodeAddUnsigned(self.cpu.operSize)
        if (self.cpu.operSize == OP_SIZE_WORD):
            value = <uint16_t>value
        return self.stackPushValue(value, self.cpu.operSize, False)
    cdef int imulR_RM_ImmFunc(self, uint8_t immIsByte) except BITMASK_BYTE_CONST:
        cdef int32_t operOp1
        cdef int64_t operOp2
        cdef uint32_t operSum, bitMask
        bitMask = BITMASKS_FF[self.cpu.operSize]
        self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
        operOp1 = self.modRMInstance.modRMLoadSigned(self.cpu.operSize)
        if (immIsByte):
            operOp2 = <int8_t>self.registers.getCurrentOpcodeAddUnsignedByte()
            operOp2 &= bitMask
        else:
            operOp2 = self.registers.getCurrentOpcodeAddSigned(self.cpu.operSize)
        operSum = (operOp1*operOp2)&bitMask
        self.modRMInstance.modRSave(self.cpu.operSize, operSum, OPCODE_SAVE)
        self.registers.setFullFlags(operOp1, operOp2, self.cpu.operSize, OPCODE_IMUL)
        return True
    cdef int opcodeGroup1_RM_ImmFunc(self, uint8_t operSize, uint8_t immIsByte) except BITMASK_BYTE_CONST:
        cdef uint8_t operOpcodeId
        cdef uint32_t operOp1, operOp2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Group1_RM_ImmFunc: operOpcodeId==%u", operOpcodeId)
        operOp1 = self.modRMInstance.modRMLoadUnsigned(operSize)
        if (operSize != OP_SIZE_BYTE and immIsByte):
            operOp2 = <uint32_t>(<int8_t>self.registers.getCurrentOpcodeAddUnsignedByte()) # operImm8 sign-extended to destsize
            if (operSize == OP_SIZE_WORD):
                operOp2 = <uint16_t>operOp2
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
            self.main.notice("opcodeGroup1_RM16_32_IMM8: invalid operOpcodeId. %u", operOpcodeId)
            raise HirnwichseException(CPU_EXCEPTION_UD)
        return True
    cdef int opcodeGroup3_RM_ImmFunc(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint8_t operOpcodeId
        cdef uint32_t operOp2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Group3_RM_ImmFunc: operOpcodeId==%u", operOpcodeId)
        operOp2 = self.registers.getCurrentOpcodeAddUnsigned(operSize) # operImm
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.modRMInstance.modRMSave(operSize, operOp2, OPCODE_SAVE)
        else:
            self.main.notice("opcodeGroup3_RM16_32_IMM16_32: invalid operOpcodeId. %u", operOpcodeId)
            raise HirnwichseException(CPU_EXCEPTION_UD)
        return True
    cdef int opcodeGroup0F(self) except BITMASK_BYTE_CONST:
        cdef uint8_t operOpcode, bitSize, byteSize, operOpcodeMod, operOpcodeModId, newCF, count, eaxIsInvalid, cpl, segType, protectedModeOn
        cdef uint16_t limit = 0
        cdef uint32_t eaxId, base = 0, mmAddr, op1 = 0, op2 #, bitMask, bitMaskHalf
        cdef uint64_t qop1, qop2
        cdef int16_t i
        cdef int32_t sop1, sop2
        cdef GdtEntry gdtEntry
        protectedModeOn = self.registers.protectedModeOn and not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm
        cpl = self.registers.getCPL()
        operOpcode = self.registers.getCurrentOpcodeAddUnsignedByte()
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Group0F: Opcode==0x%02x", operOpcode)
        if (operOpcode == 0x00): # LLDT/SLDT LTR/STR VERR/VERW
            if (not protectedModeOn):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            operOpcodeModId = self.modRMInstance.reg
            IF COMP_DEBUG:
                if (self.main.debugEnabled):
                    self.main.notice("Group0F_00: operOpcodeModId==%u", operOpcodeModId)
            if (operOpcodeModId in (0, 1)): # SLDT/STR
                byteSize = OP_SIZE_WORD
                if (self.modRMInstance.mod == 3):
                    byteSize = OP_SIZE_DWORD
                if (operOpcodeModId == 0): # SLDT
                    self.modRMInstance.modRMSave(byteSize, self.registers.ldtr, OPCODE_SAVE)
                elif (operOpcodeModId == 1): # STR
                    self.modRMInstance.modRMSave(byteSize, (<Segment>self.registers.segments.tss).segmentIndex, OPCODE_SAVE)
                    IF COMP_DEBUG:
                        self.main.notice("opcodeGroup0F_00_STR: TR isn't fully supported yet.")
            elif (operOpcodeModId in (2, 3)): # LLDT/LTR
                if (cpl != 0):
                    IF COMP_DEBUG:
                        self.main.notice("Group0F_00_2_3: cpl==%u", cpl)
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                op1 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
                if (operOpcodeModId == 2): # LLDT
                    IF COMP_DEBUG:
                        self.main.notice("Opcode0F_01::LLDT: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    if (not (op1>>2)):
                        IF COMP_DEBUG:
                            if (self.main.debugEnabled):
                                self.main.notice("Opcode0F_01::LLDT: (op1>>2) == 0, mark LDTR as invalid. (LDTR: 0x%04x)", op1)
                        op1 = 0
                    else:
                        if ((op1 & SELECTOR_USE_LDT) or not self.registers.segments.inLimit(op1)):
                            raise HirnwichseException(CPU_EXCEPTION_GP, op1)
                        segType = self.registers.segments.getSegType(op1)
                        if (segType != TABLE_ENTRY_SYSTEM_TYPE_LDT):
                            raise HirnwichseException(CPU_EXCEPTION_GP, op1)
                        op1 &= 0xfff8
                        if (not self.registers.segments.getEntry(&gdtEntry, op1)):
                            IF COMP_DEBUG:
                                self.main.notice("Opcode0F_01::LLDT: gdtEntry is invalid, mark LDTR as invalid.")
                            op1 = 0
                        elif (not gdtEntry.segPresent):
                            raise HirnwichseException(CPU_EXCEPTION_NP, op1)
                    IF COMP_DEBUG:
                        self.main.notice("Opcode0F_01::LLDT: TODO! op1==0x%04x", op1)
                    self.registers.ldtr = op1
                    if (op1 != 0):
                        (<Gdt>self.registers.segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
                    else:
                        #self.main.debugEnabled = True
                        IF COMP_DEBUG:
                            self.main.notice("Opcode0F_01::LLDT: gdtEntry is invalid, mark LDTR as invalid; load tableposition 0, 0.")
                        (<Gdt>self.registers.segments.ldt).loadTablePosition(0, 0)
                elif (operOpcodeModId == 3): # LTR
                    if (not (op1&0xfff8)):
                        IF COMP_DEBUG:
                            self.main.notice("opcodeGroup0F_00_LTR: exception_test_1 (op1: 0x%04x)", op1)
                        raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                    elif ((op1 & SELECTOR_USE_LDT) or not self.registers.segments.inLimit(op1)):
                        IF COMP_DEBUG:
                            self.main.notice("opcodeGroup0F_00_LTR: exception_test_2 (op1: 0x%04x; c1: %u; c2: %u)", op1, (op1 & SELECTOR_USE_LDT)!=0, not self.registers.segments.inLimit(op1))
                        raise HirnwichseException(CPU_EXCEPTION_GP, op1)
                    if (not self.registers.segments.getEntry(&gdtEntry, op1)):
                        IF COMP_DEBUG:
                            self.main.notice("opcodeGroup0F_00_LTR: test3")
                        raise HirnwichseException(CPU_EXCEPTION_GP, op1)
                    if (not gdtEntry.segPresent):
                        raise HirnwichseException(CPU_EXCEPTION_NP, op1)
                    segType = (gdtEntry.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK)
                    if (segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS)):
                        IF COMP_DEBUG:
                            self.main.notice("opcodeGroup0F_00_LTR: segType %u not a TSS or is busy.)", segType)
                        raise HirnwichseException(CPU_EXCEPTION_GP, op1)
                    self.registers.segments.setSegType(op1, segType | 0x2)
                    if (segType == TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS):
                        if (gdtEntry.limit != TSS_MIN_16BIT_HARD_LIMIT):
                            IF COMP_DEBUG:
                                self.main.notice("opcodeGroup0F_00_LTR: tssLimit 0x%04x != TSS_MIN_16BIT_HARD_LIMIT 0x%04x.", gdtEntry.limit, TSS_MIN_16BIT_HARD_LIMIT)
                            op1 = 0
                    elif (segType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                        if (gdtEntry.limit < TSS_MIN_32BIT_HARD_LIMIT):
                            IF COMP_DEBUG:
                                self.main.notice("opcodeGroup0F_00_LTR: tssLimit 0x%04x < TSS_MIN_32BIT_HARD_LIMIT 0x%04x.", gdtEntry.limit, TSS_MIN_32BIT_HARD_LIMIT)
                            op1 = 0
                    else:
                        self.main.exitError("opcodeGroup0F_00_LTR: segType %u might be busy.)", segType)
                        return True
                    self.registers.segWriteSegment(&self.registers.segments.tss, op1)
                    IF COMP_DEBUG:
                        self.main.notice("opcodeGroup0F_00_LTR: TR isn't fully supported yet.")
            elif (operOpcodeModId == 4): # VERR
                op1 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = (<Segments>self.registers.segments).checkReadAllowed(op1)
            elif (operOpcodeModId == 5): # VERW
                op1 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = (<Segments>self.registers.segments).checkWriteAllowed(op1)
            else:
                IF COMP_DEBUG:
                    self.main.notice("opcodeGroup0F_00: invalid operOpcodeModId: %u", operOpcodeModId)
                raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x01): # LGDT/LIDT SGDT/SIDT SMSW/LMSW
            operOpcodeMod = self.registers.getCurrentOpcodeUnsignedByte()
            IF COMP_DEBUG:
                if (self.main.debugEnabled):
                    self.main.notice("Group0F_01: operOpcodeMod==0x%02x", operOpcodeMod)
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
                    self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
                    if (self.modRMInstance.mod == 3):
                        raise HirnwichseException(CPU_EXCEPTION_UD)
                elif (operOpcodeModId in (4, 6)): # SMSW/LMSW
                    self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
                else:
                    self.main.notice("Group0F_01: operOpcodeModId not in (0, 1, 2, 3, 4, 6, 7)")
                if (operOpcodeModId in (2, 3, 6, 7) and cpl != 0):
                    self.main.notice("Group0F_01_2_3_6_7: cpl==%u", cpl)
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                mmAddr = self.modRMInstance.getRMValueFull(self.cpu.addrSize)
                if (operOpcodeModId in (0, 1)): # SGDT/SIDT
                    if (operOpcodeModId == 0): # SGDT
                        (<Gdt>self.registers.segments.gdt).getBaseLimit(&base, &limit)
                    elif (operOpcodeModId == 1): # SIDT
                        (<Idt>self.registers.segments.idt).getBaseLimit(&base, &limit)
                    if (self.cpu.operSize == OP_SIZE_WORD):
                        base &= 0xffffff
                    self.registers.mmWriteValue(mmAddr, limit, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                    self.registers.mmWriteValue(mmAddr+OP_SIZE_WORD, base, OP_SIZE_DWORD, self.modRMInstance.rmNameSeg, True)
                elif (operOpcodeModId in (2, 3)): # LGDT/LIDT
                    limit = self.registers.mmReadValueUnsignedWord(mmAddr, self.modRMInstance.rmNameSeg, True)
                    base = self.registers.mmReadValueUnsignedDword(mmAddr+OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                    if (self.cpu.operSize == OP_SIZE_WORD):
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
                    op2 = self.registers.regs[CPU_REGISTER_CR0]._union.word._union.rx
                    self.modRMInstance.modRMSave(byteSize, op2, OPCODE_SAVE)
                    IF COMP_DEBUG:
                        self.main.notice("opcodeGroup0F_01: SMSW isn't fully supported yet.")
                elif (operOpcodeModId == 6): # LMSW
                    IF COMP_DEBUG:
                        self.main.notice("opcodeGroup0F_01: LMSW isn't fully supported yet.")
                    op1 = self.registers.regs[CPU_REGISTER_CR0]._union.dword.erx
                    op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
                    if ((op1&1) and not (op2&1)): # it's already in protected mode, but it tries to switch to real mode...
                        self.main.exitError("opcodeGroup0F_01: LMSW: tried to switch to real mode from protected mode.")
                        return True
                    op1 = ((op1&<uint64_t>0xfffffff0)|(op2&0xf))
                    self.registers.regWriteDword(CPU_REGISTER_CR0, op1)
                    #self.registers.syncCR0State()
                elif (operOpcodeModId == 7): # INVLPG
                    if (self.registers.protectedModeOn and self.registers.pagingOn): # TODO: HACK
                        #(<Paging>self.registers.segments.paging).invalidateTables(self.registers.regs[CPU_REGISTER_CR3]._union.dword.erx, False)
                        mmAddr = self.modRMInstance.getRMValueFull(self.cpu.operSize)
                        if (self.main.cpu.segmentOverridePrefix is not NULL):
                            mmAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
                        else:
                            mmAddr = self.modRMInstance.rmNameSeg[0].gdtEntry.base+mmAddr
                        (<Paging>self.registers.segments.paging).invalidatePage(mmAddr)
                    IF CPU_CACHE_SIZE:
                        self.registers.reloadCpuCache()
                else:
                    self.main.notice("opcodeGroup0F_01: invalid operOpcodeModId: %u", operOpcodeModId)
                    raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x02): # LAR
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: LAR: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
            if (not protectedModeOn):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
            if (not self.registers.segments.inLimit(op2)):
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = False
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::opcodeGroup0F: LAR: test1!")
                return True
            if (not self.registers.segments.getEntry(&gdtEntry, op2)):
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = False
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::LAR: not gdtEntry (op2==0x%04x)", op2)
                return True
            segType = self.registers.segments.getSegType(op2)
            if ((not gdtEntry.segIsConforming and ((cpl > gdtEntry.segDPL) or ((op2&3) > gdtEntry.segDPL))) or \
              (not (segType&0x10) and segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_LDT, \
              TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_16BIT_CALL_GATE, TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE, \
              TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_CALL_GATE))):
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = False
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::opcodeGroup0F: LAR: test2!")
                    self.main.notice("Opcodes::opcodeGroup0F: LAR: test2.1! (c1==%u; c2==%u; c3==%u; c4==%u; c5==0x%02x)", not gdtEntry.segIsConforming, (cpl > gdtEntry.segDPL), ((op2&3) > gdtEntry.segDPL), (segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_LDT, TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_16BIT_CALL_GATE, TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_CALL_GATE)), segType)
                return True
            op1 = gdtEntry.accessByte << 8
            if (self.cpu.operSize == OP_SIZE_DWORD):
                op1 |= ((gdtEntry.flags & GDT_FLAG_AVAILABLE) != 0) << 20
                op1 |= ((gdtEntry.flags & GDT_FLAG_LONGMODE) != 0) << 21
                op1 |= (gdtEntry.segSize == OP_SIZE_DWORD) << 22
                op1 |= gdtEntry.segUse4K << 23
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: LAR: test2.2! (op1==0x%08x; op2==0x%04x)", op1, op2)
            self.modRMInstance.modRSave(self.cpu.operSize, op1, OPCODE_SAVE)
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = True
            #if (self.cpu.savedCs == 0x28 and self.cpu.savedEip == 0xc0002636 and op2 == 0x87):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
        elif (operOpcode == 0x03): # LSL
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: LSL: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
            if (not protectedModeOn):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
            if (not self.registers.segments.inLimit(op2)):
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = False
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::opcodeGroup0F: LSL: test1!")
                return True
            if (not self.registers.segments.getEntry(&gdtEntry, op2)):
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = False
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::LSL: not gdtEntry (op2==0x%04x)", op2)
                return True
            segType = self.registers.segments.getSegType(op2)
            if ((not gdtEntry.segIsConforming and ((cpl > gdtEntry.segDPL) or ((op2&3) > gdtEntry.segDPL))) or \
              (not (segType&0x10) and segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_LDT, \
              TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY))):
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = False
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::opcodeGroup0F: LSL: test2! (c1==%u; c2==%u; c3==%u; c4==%u; c5==0x%02x)", not gdtEntry.segIsConforming, (cpl > gdtEntry.segDPL), ((op2&3) > gdtEntry.segDPL), (segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_LDT, TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY)), segType)
                return True  
            op1 = gdtEntry.limit
            if ((gdtEntry.flags & GDT_FLAG_USE_4K)):
                op1 <<= 12
                op1 |= 0xfff
            if (self.cpu.operSize == OP_SIZE_WORD):
                op1 = <uint16_t>op1
            self.modRMInstance.modRSave(self.cpu.operSize, op1, OPCODE_SAVE)
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = True
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
                self.registers.regs[CPU_REGISTER_CR0]._union.dword.erx = self.registers.regs[CPU_REGISTER_CR0]._union.dword.erx&(~CR0_FLAG_TS)
            elif (operOpcode == 0x08): # INVD
                self.main.notice("Opcodes::opcodeGroup0F: INVD: TODO!")
                if (self.registers.protectedModeOn and self.registers.pagingOn): # TODO: HACK
                    (<Paging>self.registers.segments.paging).invalidateTables(self.registers.regs[CPU_REGISTER_CR3]._union.dword.erx, False)
                IF CPU_CACHE_SIZE:
                    self.registers.reloadCpuCache()
            elif (operOpcode == 0x09): # WBINVD
                self.main.notice("Opcodes::opcodeGroup0F: WBINVD: TODO!")
                if (self.registers.protectedModeOn and self.registers.pagingOn): # TODO: HACK
                    (<Paging>self.registers.segments.paging).invalidateTables(self.registers.regs[CPU_REGISTER_CR3]._union.dword.erx, False)
                IF CPU_CACHE_SIZE:
                    self.registers.reloadCpuCache()
        elif (operOpcode == 0x0b): # UD2
            self.main.notice("Opcodes::opcodeGroup0F: UD2!")
            raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (operOpcode in (0x18, 0x1f)): # Multibyte NOP
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
        #elif (operOpcode in (0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e)): # Singlebyte NOP
        #    pass
        elif (operOpcode == 0x20): # MOV R32, CRn
            if (cpl != 0):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_CREG)
            if (self.modRMInstance.regName not in (CPU_REGISTER_CR0, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4)):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            IF COMP_DEBUG:
                if (self.modRMInstance.regName == CPU_REGISTER_CR2):
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
                op1 = self.registers.regs[CPU_REGISTER_CR0]._union.dword.erx # op1 == old CR0
                if ((op2 & CR0_FLAG_PG) and not (op2 & CR0_FLAG_PE)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            self.modRMInstance.modRSave(OP_SIZE_DWORD, op2, OPCODE_SAVE)
            if (self.modRMInstance.regName == CPU_REGISTER_CR0):
                self.registers.pagingOn = (op2 & CR0_FLAG_PG)!=0
                self.registers.writeProtectionOn = (op2 & CR0_FLAG_WP)!=0
                self.registers.cacheDisabled = (op2 & CR0_FLAG_CD)!=0
                if ((op1 & (CR0_FLAG_PG | CR0_FLAG_CD | CR0_FLAG_NW | CR0_FLAG_WP)) != (op2 & (CR0_FLAG_PG | CR0_FLAG_CD | CR0_FLAG_NW | CR0_FLAG_WP))):
                    if (self.registers.protectedModeOn and self.registers.pagingOn): # TODO: HACK
                        (<Paging>self.registers.segments.paging).invalidateTables(self.registers.regs[CPU_REGISTER_CR3]._union.dword.erx, False)
                    IF (CPU_CACHE_SIZE):
                        self.registers.reloadCpuCache()
                #self.registers.syncCR0State()
            elif (self.modRMInstance.regName == CPU_REGISTER_CR4):
                if (op2 & CR4_FLAG_VME):
                    self.main.notice("opcodeGroup0F_22: VME (virtual-8086 mode extension) IS NOT FULLY SUPPORTED yet.")
                if (op2 & CR4_FLAG_PSE):
                    self.main.exitError("opcodeGroup0F_22: PSE (page-size extension) IS NOT SUPPORTED yet.")
                if (op2 & CR4_FLAG_PAE):
                    self.main.exitError("opcodeGroup0F_22: PAE (physical-address extension) IS NOT SUPPORTED yet.")
                if (op2):
                    self.main.notice("opcodeGroup0F_22: CR4 IS NOT FULLY SUPPORTED yet. (op2==0x%08x)", op2)
            IF COMP_DEBUG:
                if (self.modRMInstance.regName == CPU_REGISTER_CR2):
                    self.main.notice("TODO: MOV CR2, R32")
            if (self.modRMInstance.regName in (CPU_REGISTER_CR3, CPU_REGISTER_CR4)):
                #if (self.registers.protectedModeOn and self.registers.pagingOn): # TODO: HACK
                IF 1:
                    #op2 = self.registers.regs[CPU_REGISTER_CR3]._union.dword.erx
                    #(<Paging>self.registers.segments.paging).invalidateTables(op2, True)
                    #(<Paging>self.registers.segments.paging).invalidateTables(op2, False)
                    (<Paging>self.registers.segments.paging).invalidateTables(self.registers.regs[CPU_REGISTER_CR3]._union.dword.erx, False)
                    IF (CPU_CACHE_SIZE):
                        self.registers.reloadCpuCache()
        elif (operOpcode == 0x23): # MOV DRn, R32
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_DREG)
            self.modRMInstance.modRSave(OP_SIZE_DWORD, self.modRMInstance.modRMLoadUnsigned(OP_SIZE_DWORD), OPCODE_SAVE)
        elif (operOpcode in (0x30, 0x31, 0x32)): # WRMSR, RDTSC, RDMSR
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: WRMSR/RDTSC/RDMSR: TODO!")
            #raise HirnwichseException(CPU_EXCEPTION_UD)
            if (operOpcode == 0x31 and self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_TSD) != 0 and cpl != 0 and self.registers.protectedModeOn): # RDTSC
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            elif (cpl != 0):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            eaxId = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx
            eaxIsInvalid = (eaxId >= 0x40000000 and eaxId <= 0x400000ff)
            if (operOpcode != 0x31 and eaxIsInvalid):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            if (operOpcode == 0x31 or (operOpcode == 0x32 and eaxId == 0x10)):
                self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = <uint32_t>(self.cpu.cycles)
                self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = <uint32_t>(self.cpu.cycles>>32)
            elif (operOpcode == 0x30 and eaxId == 0x10):
                self.cpu.cycles = self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx
                self.cpu.cycles = self.cpu.cycles|(<uint64_t>self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx<<32)
            elif (operOpcode == 0x32 and eaxId in (0x2a, 0x8b)): # power on configuration bits, no microcode loaded or rather supported.
                self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0
                self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0
            elif (operOpcode == 0x30 and eaxId in (0x2a, 0x8b)): # power on configuration bits, no microcode loaded or rather supported.
                pass
            elif (operOpcode == 0x32 and eaxId == 0x1b): # apic base
                self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = self.registers.apicBase
                self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0
            elif (operOpcode == 0x30 and eaxId == 0x1b): # apic base
                self.registers.apicBase = self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx
                self.registers.apicBaseReal = self.registers.apicBase&<uint32_t>0xfffff000
                self.registers.apicBaseRealPlusSize = self.registers.apicBaseReal+SIZE_4KB
                if (self.registers.apicBaseReal != <uint32_t>0xfee00000):
                    self.main.exitError("Opcodes::group0F: apicBaseReal != 0xfee00000 (operOpcode==0x%02x; ECX==0x%08x; apicBase==0x%08x)", operOpcode, eaxId, self.registers.apicBase)
                if (self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx): # higher 32-bits are set.
                    self.main.exitError("Opcodes::group0F: MSR: WRMSR apic_base higher 32-bits (EDX) set! (operOpcode==0x%02x; ECX==0x%08x)", operOpcode, eaxId)
            elif (operOpcode == 0x30 and self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx): # higher 32-bits are set.
                self.main.exitError("Opcodes::group0F: MSR: WRMSR higher 32-bits (EDX) set! (operOpcode==0x%02x; ECX==0x%08x)", operOpcode, eaxId)
            else:
                self.main.notice("Opcodes::group0F: MSR: Unimplemented! (operOpcode==0x%02x; ECX==0x%08x)", operOpcode, eaxId)
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        elif (operOpcode == 0x38): # MOVBE
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: MOVBE: TODO!")
            operOpcodeMod = self.registers.getCurrentOpcodeAddUnsignedByte()
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            if (operOpcodeMod == 0xf0): # MOVBE R16_32, M16_32
                op2 = self.modRMInstance.modRMLoadUnsigned(self.cpu.operSize)
                op2 = self.reverseByteOrder(op2, self.cpu.operSize)
                self.modRMInstance.modRSave(self.cpu.operSize, op2, OPCODE_SAVE)
            elif (operOpcodeMod == 0xf1): # MOVBE M16_32, R16_32
                op2 = self.modRMInstance.modRLoadUnsigned(self.cpu.operSize)
                op2 = self.reverseByteOrder(op2, self.cpu.operSize)
                self.modRMInstance.modRMSave(self.cpu.operSize, op2, OPCODE_SAVE)
            else:
                self.main.exitError("MOVBE: operOpcodeMod 0x%02x not in (0xf0, 0xf1)", operOpcodeMod)
        elif ((operOpcode & 0xf0) == 0x40): # CMOVcc ;; R16, R/M 16; R32, R/M 32
            IF COMP_DEBUG:
            #IF 1:
                self.main.notice("Opcodes::cmovFunc: TODO!")
            self.movR_RM(self.cpu.operSize, self.registers.getCond(operOpcode&0xf))
        elif ((operOpcode & 0xf0) == 0x80):
            self.jumpShort(self.cpu.operSize, self.registers.getCond(operOpcode&0xf))
        elif ((operOpcode & 0xf0) == 0x90): # SETcc
            self.setWithCondFunc(self.registers.getCond(operOpcode&0xf))
        elif (operOpcode == 0xa0): # PUSH FS
            self.pushSeg(PUSH_FS)
        elif (operOpcode == 0xa1): # POP FS
            self.popSeg(POP_FS)
        elif (operOpcode == 0xa2): # CPUID
            eaxId = self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: CPUID: TODO! (eax; 0x%08x)", eaxId)
            #eaxIsInvalid = (eaxId >= <uint32_t>0x40000000 and eaxId <= <uint32_t>0x4fffffff)
            IF 0:
                if (eaxId in (0x2, 0x3, 0x4, 0x5, <uint32_t>0x80000001, <uint32_t>0x80000005, <uint32_t>0x80000006, <uint32_t>0x80000007)):
                    self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0
                    self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx = 0
                    self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = 0
                    self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0
                elif (eaxId == <uint32_t>0x80000000):
                    self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0x80000007
                    self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx = 0
                    self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = 0
                    self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0
                elif (eaxId == <uint32_t>0x80000002):
                    self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0x20202020
                    self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx = 0x20202020
                    self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = 0x20202020
                    self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0x6e492020
                elif (eaxId == <uint32_t>0x80000003):
                    self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0x286c6574
                    self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx = 0x50202952
                    self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = 0x69746e65
                    self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0x52286d75
                elif (eaxId == <uint32_t>0x80000004):
                    self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0x20342029
                    self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx = 0x20555043
                    self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = 0x20202020
                    self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0x00202020
            if (eaxId & <uint32_t>0x30000000):
                self.main.exitError("Opcodes::opcodeGroup0F: CPUID test1: TODO! (savedEip: 0x%08x, savedCs: 0x%04x; eax; 0x%08x)", self.cpu.savedEip, self.cpu.savedCs, eaxId)
            elif (eaxId & <uint32_t>0x80000000):
                self.main.notice("Opcodes::opcodeGroup0F: CPUID test2: TODO! (savedEip: 0x%08x, savedCs: 0x%04x; eax; 0x%08x)", self.cpu.savedEip, self.cpu.savedCs, eaxId)
                #self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0
                self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0x3 # TODO: HACK
                self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx = 0
                self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = 0
                self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0
            elif (eaxId == 0x1):
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::opcodeGroup0F: CPUID test4: TODO! (savedEip: 0x%08x, savedCs: 0x%04x; eax; 0x%08x)", self.cpu.savedEip, self.cpu.savedCs, eaxId)
                #self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0x521
                #self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0x611
                #self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0x631
                self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0x635
                self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx = 0x10000
                self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = 0xc00000
                #self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0x8113
                #self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0xa117
                #self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0xa11f
                self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0x1800a117
                #self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0x1800a337
            elif (eaxId == 0x2):
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::opcodeGroup0F: CPUID test5: TODO! (savedEip: 0x%08x, savedCs: 0x%04x; eax; 0x%08x)", self.cpu.savedEip, self.cpu.savedCs, eaxId)
                self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0x410601
                self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx = 0
                self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = 0
                self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0
            elif (eaxId == 0x3):
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::opcodeGroup0F: CPUID test6: TODO! (savedEip: 0x%08x, savedCs: 0x%04x; eax; 0x%08x)", self.cpu.savedEip, self.cpu.savedCs, eaxId)
                self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0
                self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx = 0
                self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = 0
                self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0
            else:
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::opcodeGroup0F: CPUID test3: TODO! (savedEip: 0x%08x, savedCs: 0x%04x; eax; 0x%08x)", self.cpu.savedEip, self.cpu.savedCs, eaxId)
                #if (not (eaxId == 0x0 or eaxIsInvalid)):
                #    self.main.notice("CPUID: eaxId 0x%02x unknown.", eaxId)
                #self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0x5
                self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = 0x3
                self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx = 0x756e6547
                self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx = 0x6c65746e
                self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = 0x49656e69
        elif (operOpcode == 0xa3): # BT RM16/32, R16/R32
            return self.btFunc(BT_NONE)
        elif (operOpcode in (0xa4, 0xa5)): # SHLD
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: SHLD: TODO!")
            #bitMaskHalf = BITMASKS_80[self.cpu.operSize]
            bitSize = self.cpu.operSize << 3
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            if (operOpcode == 0xa4): # SHLD imm8
                count = self.registers.getCurrentOpcodeAddUnsignedByte()
            elif (operOpcode == 0xa5): # SHLD CL
                count = self.registers.regs[CPU_REGISTER_CL]._union.word._union.byte.rl
            else:
                self.main.exitError("group0F::SHLD: operOpcode 0x%02x unknown.", operOpcode)
                return True
            count &= 0x1f
            if (not count):
                return True
            op1 = self.modRMInstance.modRMLoadUnsigned(self.cpu.operSize) # dest
            op2  = self.modRMInstance.modRLoadUnsigned(self.cpu.operSize) # src
            newCF = (op1 >> (bitSize - count)) & 1
            if (self.cpu.operSize == OP_SIZE_WORD): # "inspired"/stolen from bochs. Thanks. :-)
                base = ((op1 << bitSize) | op2) << count
                if (count > bitSize):
                    base |= (op1 << (count - bitSize))
                op1 = base >> bitSize
            else:
                op1 = (op1 << count) | (op2 >> (bitSize - count))
            self.modRMInstance.modRMSave(self.cpu.operSize, op1, OPCODE_SAVE)
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = newCF
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = newCF^((op1>>(bitSize - 1))&1)
            self.registers.setSZP_A(op1, self.cpu.operSize)
        elif (operOpcode == 0xa8): # PUSH GS
            self.pushSeg(PUSH_GS)
        elif (operOpcode == 0xa9): # POP GS
            self.popSeg(POP_GS)
        elif (operOpcode == 0xab): # BTS RM16/32, R16/32
            return self.btFunc(BT_SET)
        elif (operOpcode in (0xac, 0xad)): # SHRD
            #bitMaskHalf = BITMASKS_80[self.cpu.operSize]
            bitSize = self.cpu.operSize << 3
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            if (operOpcode == 0xac): # SHRD imm8
                count = self.registers.getCurrentOpcodeAddUnsignedByte()
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::opcodeGroup0F: SHRD_imm8: TODO! (savedEip: 0x%08x, savedCs: 0x%04x, count: 0x%02x, bitSize: %u)", self.cpu.savedEip, self.cpu.savedCs, count, bitSize)
            elif (operOpcode == 0xad): # SHRD CL
                count = self.registers.regs[CPU_REGISTER_CL]._union.word._union.byte.rl
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::opcodeGroup0F: SHRD_CL: TODO! (savedEip: 0x%08x, savedCs: 0x%04x, count: 0x%02x), bitSize: %u", self.cpu.savedEip, self.cpu.savedCs, count, bitSize)
            else:
                self.main.exitError("group0F::SHRD: operOpcode 0x%02x unknown.", operOpcode)
                return True
            count &= 0x1f
            if (not count):
                return True
            op1 = self.modRMInstance.modRMLoadUnsigned(self.cpu.operSize) # dest
            op2  = self.modRMInstance.modRLoadUnsigned(self.cpu.operSize) # src
            newCF = (op1 >> (count - 1)) & 1
            if (self.cpu.operSize == OP_SIZE_WORD): # "inspired"/stolen from bochs. Thanks. :-)
                base = ((op2 << bitSize) | op1) >> count
                if (count > bitSize):
                    base |= (op1 << (bitSize - count))
                op1 = base
            else:
                op1 = (op2 << (bitSize - count)) | (op1 >> count)
            self.modRMInstance.modRMSave(self.cpu.operSize, op1, OPCODE_SAVE)
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = (((op1 << 1) ^ op1) >> (bitSize-1))&1
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = newCF
            self.registers.setSZP_A(op1, self.cpu.operSize)
        elif (operOpcode == 0xae): # 0xae
            #self.main.exitError("Opcodes::opcodeGroup0F: 0xae: TODO!")
            self.main.notice("Opcodes::opcodeGroup0F: 0xae: TODO!")
            raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0xaf): # IMUL R16_32, R/M16_32
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            sop1 = self.modRMInstance.modRLoadSigned(self.cpu.operSize)
            sop2 = self.modRMInstance.modRMLoadSigned(self.cpu.operSize)
            if (self.cpu.operSize == OP_SIZE_WORD):
                sop1 = <int16_t>sop1
                sop2 = <int16_t>sop2
            op1 = <uint32_t>(sop1*sop2)
            if (self.cpu.operSize == OP_SIZE_WORD):
                op1 = <uint16_t>op1
            self.modRMInstance.modRSave(self.cpu.operSize, op1, OPCODE_SAVE)
            self.registers.setFullFlags(sop1, sop2, self.cpu.operSize, OPCODE_IMUL)
        elif (operOpcode in (0xb0, 0xb1)): # 0xb0: CMPXCHG RM8, R8 ;; 0xb1: CMPXCHG RM16_32, R16_32
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: CMPXCHG: TODO!")
            byteSize = self.cpu.operSize
            if (operOpcode == 0xb0): # 0xb0: CMPXCHG RM8, R8
                byteSize = OP_SIZE_BYTE
            self.modRMInstance.modRMOperands(byteSize, MODRM_FLAGS_NONE)
            op1 = self.modRMInstance.modRMLoadUnsigned(byteSize)
            op2 = self.registers.regReadUnsigned(CPU_REGISTER_AX, byteSize)
            self.registers.setFullFlags(op2, op1, byteSize, OPCODE_SUB)
            if (op2 == op1):
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = True
                op2 = self.modRMInstance.modRLoadUnsigned(byteSize)
                self.modRMInstance.modRMSave(byteSize, op2, OPCODE_SAVE)
            else:
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = False
                self.registers.regWrite(CPU_REGISTER_AX, op1, byteSize)
        elif (operOpcode == 0xb2): # LSS
            self.lfpFunc(&self.registers.segments.ss)
        elif (operOpcode == 0xb3): # BTR RM16/32, R16/32
            return self.btFunc(BT_RESET)
        elif (operOpcode == 0xb4): # LFS
            self.lfpFunc(&self.registers.segments.fs)
        elif (operOpcode == 0xb5): # LGS
            self.lfpFunc(&self.registers.segments.gs)
        elif (operOpcode == 0xb8): # POPCNT R16/32 RM16/32
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: POPCNT: TODO!")
            if (self.cpu.repPrefix):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(self.cpu.operSize)
            op2 = bin(op2).count('1')
            self.modRMInstance.modRSave(self.cpu.operSize, op2, OPCODE_SAVE)
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.sf = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = False
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = not op2
        elif (operOpcode == 0xba): # BT/BTS/BTR/BTC RM16/32 IMM8
            IF COMP_DEBUG:
                if (self.main.debugEnabled):
                    self.main.notice("Opcodes::opcodeGroup0F: BT*: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            operOpcodeModId = self.modRMInstance.reg
            IF COMP_DEBUG:
                if (self.main.debugEnabled):
                    self.main.notice("Group0F_BA: operOpcodeModId==%u", operOpcodeModId)
            if (operOpcodeModId == 4): # BT
                return self.btFunc(BT_IMM | BT_NONE)
            elif (operOpcodeModId == 5): # BTS
                return self.btFunc(BT_IMM | BT_SET)
            elif (operOpcodeModId == 6): # BTR
                return self.btFunc(BT_IMM | BT_RESET)
            elif (operOpcodeModId == 7): # BTC
                return self.btFunc(BT_IMM | BT_COMPLEMENT)
            else:
                self.main.notice("opcodeGroup0F_BA: invalid operOpcodeModId: %u", operOpcodeModId)
                raise HirnwichseException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0xbb): # BTC RM16/32, R16/32
            return self.btFunc(BT_COMPLEMENT)
        elif (operOpcode == 0xbc): # BSF R16_32, R/M16_32
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: BSF: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                self.cpu.cpuDump()
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(self.cpu.operSize)
            if (op2 >= 1):
                op1 = bin(op2)[::-1].find('1')
                self.modRMInstance.modRSave(self.cpu.operSize, op1, OPCODE_SAVE)
                self.registers.setSZP_COA(op1, self.cpu.operSize)
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = not op2
            IF COMP_DEBUG:
                self.cpu.cpuDump()
        elif (self.cpu.repPrefix == OPCODE_PREFIX_REPE and operOpcode == 0xbd): # LZCNT R16_32, R/M16_32
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: LZCNT: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                self.cpu.cpuDump()
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(self.cpu.operSize)
            op1 = self.cpu.operSize-op2.bit_length()
            self.modRMInstance.modRSave(self.cpu.operSize, op1, OPCODE_SAVE)
            self.registers.setSZP_COA(op1, self.cpu.operSize)
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = not op2
            IF COMP_DEBUG:
                self.cpu.cpuDump()
        elif (operOpcode == 0xbd): # BSR R16_32, R/M16_32
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: BSR: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                self.cpu.cpuDump()
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoadUnsigned(self.cpu.operSize)
            if (op2 >= 1):
                op1 = op2.bit_length()-1
                self.modRMInstance.modRSave(self.cpu.operSize, op1, OPCODE_SAVE)
                self.registers.setSZP_COA(op1, self.cpu.operSize)
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = not op2
            IF COMP_DEBUG:
                self.cpu.cpuDump()
        elif (operOpcode in (0xb6, 0xbe)): # 0xb6==MOVZX R16_32, R/M8 ;; 0xbe==MOVSX R16_32, R/M8
            self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
            if (not self.modRMInstance.getRegNameWithFlags(MODRM_FLAGS_NONE, self.modRMInstance.reg, self.cpu.operSize)):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            if (operOpcode == 0xb6): # MOVZX R16_32, R/M8
                op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_BYTE)
            else: # MOVSX R16_32, R/M8
                op2 = <uint32_t>(<int8_t>self.modRMInstance.modRMLoadSigned(OP_SIZE_BYTE))
                if (self.cpu.operSize == OP_SIZE_WORD):
                    op2 = <uint16_t>op2
            self.modRMInstance.modRSave(self.cpu.operSize, op2, OPCODE_SAVE)
        elif (operOpcode in (0xb7, 0xbf)): # 0xb7==MOVZX R32, R/M16 ;; 0xbf==MOVSX R32, R/M16
            self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            if (not self.modRMInstance.getRegNameWithFlags(MODRM_FLAGS_NONE, self.modRMInstance.reg, OP_SIZE_DWORD)):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            if (operOpcode == 0xb7): # MOVZX R32, R/M16
                op2 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
            else: # MOVSX R32, R/M16
                op2 = <uint32_t>(self.modRMInstance.modRMLoadSigned(OP_SIZE_WORD))
            self.modRMInstance.modRSave(OP_SIZE_DWORD, op2, OPCODE_SAVE)
        elif (operOpcode in (0xc0, 0xc1)): # 0xc0: XADD RM8, R8 ;; 0xc1: XADD RM16_32, R16_32
            #if (self.cpu.savedCs == 0x8 and self.cpu.savedEip == 0x80905f66):
            #    self.main.debugEnabledTest = self.main.debugEnabled = True
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: XADD: TODO! (operOpcode: 0x%02x, savedEip: 0x%08x, savedCs: 0x%04x)", operOpcode, self.cpu.savedEip, self.cpu.savedCs)
            byteSize = OP_SIZE_BYTE if (operOpcode == 0xc0) else self.cpu.operSize
            self.modRMInstance.modRMOperands(byteSize, MODRM_FLAGS_NONE)
            op1 = self.modRMInstance.modRMLoadUnsigned(byteSize)
            op2 = self.modRMInstance.modRLoadUnsigned(byteSize)
            self.modRMInstance.modRMSave(byteSize, op1+op2, OPCODE_SAVE)
            self.modRMInstance.modRSave(byteSize, op1, OPCODE_SAVE)
            self.registers.setFullFlags(op1, op2, byteSize, OPCODE_ADD)
        elif (operOpcode == 0xc7): # CMPXCHG8B M64 / ...
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: CMPXCHG8B: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            if (self.modRMInstance.mod == 3):
                raise HirnwichseException(CPU_EXCEPTION_UD)
            mmAddr = self.modRMInstance.getRMValueFull(self.cpu.operSize)
            IF COMP_DEBUG:
                if (self.main.debugEnabled):
                    self.main.notice("Group0F_C7: self.modRMInstance.reg==%u", self.modRMInstance.reg)
            if (self.modRMInstance.reg == 1):
                qop1 = self.registers.mmReadValueUnsignedQword(mmAddr, self.modRMInstance.rmNameSeg, True)
                qop2 = self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx
                qop2 <<= 32
                qop2 |= self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx
                if (qop2 == qop1):
                    self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = True
                    qop2 = self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx
                    qop2 <<= 32
                    qop2 |= self.registers.regs[CPU_REGISTER_EBX]._union.dword.erx
                    self.registers.mmWriteValue(mmAddr, qop2, OP_SIZE_QWORD, self.modRMInstance.rmNameSeg, True)
                else:
                    self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = False
                    self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = qop1>>32
                    self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = qop1
                    self.registers.mmWriteValue(mmAddr, qop1, OP_SIZE_QWORD, self.modRMInstance.rmNameSeg, True) # it's supposed to write always.
            else:
                self.main.notice("opcodeGroup0F_C7: self.modRMInstance.reg %u isn't supported yet.", self.modRMInstance.reg)
                raise HirnwichseException(CPU_EXCEPTION_UD)
        elif ((operOpcode & 0xf8) == 0xc8): # BSWAP R32
            IF COMP_DEBUG:
                self.main.notice("Opcodes::opcodeGroup0F: BSWAP: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
            regName  = operOpcode&7
            op1 = self.registers.regs[regName]._union.dword.erx
            #self.main.notice("Opcodes::opcodeGroup0F: BSWAP: test1==0x%08x", op1)
            op1 = self.reverseByteOrder(op1, OP_SIZE_DWORD)
            #self.main.notice("Opcodes::opcodeGroup0F: BSWAP: test2==0x%08x", op1)
            self.registers.regs[regName]._union.dword.erx = op1
        elif (operOpcode == 0xff): # 0xFF UD3
            self.main.notice("Opcodes::opcodeGroup0F: 0xff UD3!")
            raise HirnwichseException(CPU_EXCEPTION_UD)
        else:
            self.main.exitError("opcodeGroup0F: invalid operOpcode. 0x%02x", operOpcode)
            return False
        return True
    cdef int opcodeGroupFE(self) except BITMASK_BYTE_CONST:
        cdef uint8_t operOpcodeId
        self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        if (self.main.debugEnabled):
            self.main.notice("GroupFE: operOpcodeId==%u", operOpcodeId)
        if (operOpcodeId == 0): # 0/INC
            return self.incFuncRM(OP_SIZE_BYTE)
        elif (operOpcodeId == 1): # 1/DEC
            return self.decFuncRM(OP_SIZE_BYTE)
        else:
            self.main.exitError("opcodeGroupFE: invalid operOpcodeId. %u", operOpcodeId)
        return True
    cdef int opcodeGroupFF(self) except BITMASK_BYTE_CONST:
        cdef uint8_t operOpcodeId
        cdef uint16_t segVal
        cdef uint32_t op1
        self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        if (self.main.debugEnabled):
            self.main.notice("GroupFF: operOpcodeId==%u", operOpcodeId)
        if (operOpcodeId == 0): # 0/INC
            return self.incFuncRM(self.cpu.operSize)
        elif (operOpcodeId == 1): # 1/DEC
            return self.decFuncRM(self.cpu.operSize)
        elif (operOpcodeId == 2): # 2/CALL NEAR
            op1 = self.modRMInstance.modRMLoadUnsigned(self.cpu.operSize)
            self.stackPushRegId(CPU_REGISTER_EIP, self.cpu.operSize)
            self.registers.regWriteDword(CPU_REGISTER_EIP, op1)
        elif (operOpcodeId == 3): # 3/CALL FAR
            op1 = self.modRMInstance.getRMValueFull(self.cpu.addrSize)
            segVal = self.registers.mmReadValueUnsignedWord(op1+self.cpu.operSize, self.modRMInstance.rmNameSeg, True)
            op1 = self.registers.mmReadValueUnsigned(op1, self.cpu.operSize, self.modRMInstance.rmNameSeg, True)
            return self.jumpFarDirect(OPCODE_CALL, segVal, op1)
        elif (operOpcodeId == 4): # 4/JMP NEAR
            op1 = self.modRMInstance.modRMLoadUnsigned(self.cpu.operSize)
            self.registers.regWriteDword(CPU_REGISTER_EIP, op1)
        elif (operOpcodeId == 5): # 5/JMP FAR
            op1 = self.modRMInstance.getRMValueFull(self.cpu.addrSize)
            segVal = self.registers.mmReadValueUnsignedWord(op1+self.cpu.operSize, self.modRMInstance.rmNameSeg, True)
            op1 = self.registers.mmReadValueUnsigned(op1, self.cpu.operSize, self.modRMInstance.rmNameSeg, True)
            return self.jumpFarDirect(OPCODE_JUMP, segVal, op1)
        elif (operOpcodeId == 6): # 6/PUSH
            op1 = self.modRMInstance.modRMLoadUnsigned(self.cpu.operSize)
            return self.stackPushValue(op1, self.cpu.operSize, False)
        else:
            self.main.exitError("opcodeGroupFF: invalid operOpcodeId. %u", operOpcodeId)
        return True
    cdef int incFuncReg(self, uint16_t regId, uint8_t regSize) nogil except BITMASK_BYTE_CONST:
        cdef uint8_t origCF
        cdef uint32_t origValue
        origCF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        origValue = self.registers.regReadUnsigned(regId, regSize)
        self.registers.regWrite(regId, <uint32_t>(origValue+1), regSize)
        self.registers.setFullFlags(origValue, 1, regSize, OPCODE_ADD)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = origCF
        return True
    cdef int decFuncReg(self, uint16_t regId, uint8_t regSize) nogil except BITMASK_BYTE_CONST:
        cdef uint8_t origCF
        cdef uint32_t origValue
        origCF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        origValue = self.registers.regReadUnsigned(regId, regSize)
        self.registers.regWrite(regId, <uint32_t>(origValue-1), regSize)
        self.registers.setFullFlags(origValue, 1, regSize, OPCODE_SUB)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = origCF
        return True
    cdef int incFuncRM(self, uint8_t rmSize) except BITMASK_BYTE_CONST:
        cdef uint8_t origCF
        cdef uint32_t origValue
        origCF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        origValue = self.modRMInstance.modRMLoadUnsigned(rmSize)
        self.modRMInstance.modRMSave(rmSize, <uint32_t>(origValue+1), OPCODE_SAVE)
        self.registers.setFullFlags(origValue, 1, rmSize, OPCODE_ADD)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = origCF
        return True
    cdef int decFuncRM(self, uint8_t rmSize) except BITMASK_BYTE_CONST:
        cdef uint8_t origCF
        cdef uint32_t origValue
        origCF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        origValue = self.modRMInstance.modRMLoadUnsigned(rmSize)
        self.modRMInstance.modRMSave(rmSize, <uint32_t>(origValue-1), OPCODE_SAVE)
        self.registers.setFullFlags(origValue, 1, rmSize, OPCODE_SUB)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = origCF
        return True
    cdef int incReg(self) nogil except BITMASK_BYTE_CONST:
        return self.incFuncReg(self.cpu.opcode&7, self.cpu.operSize)
    cdef int decReg(self) nogil except BITMASK_BYTE_CONST:
        return self.decFuncReg(self.cpu.opcode&7, self.cpu.operSize)
    cdef int pushReg(self) except BITMASK_BYTE_CONST:
        return self.stackPushRegId(self.cpu.opcode&7, self.cpu.operSize)
    cdef int popReg(self) except BITMASK_BYTE_CONST:
        return self.stackPopRegId(self.cpu.opcode&7, self.cpu.operSize)
    cdef int pushSeg(self, uint8_t opcode) except BITMASK_BYTE_CONST:
        cdef Segment *segment
        if (opcode == PUSH_CS):
            segment = &self.registers.segments.cs
        elif (opcode == PUSH_DS):
            segment = &self.registers.segments.ds
        elif (opcode == PUSH_ES):
            segment = &self.registers.segments.es
        elif (opcode == PUSH_FS):
            segment = &self.registers.segments.fs
        elif (opcode == PUSH_GS):
            segment = &self.registers.segments.gs
        elif (opcode == PUSH_SS):
            segment = &self.registers.segments.ss
        else:
            self.main.exitError("pushSeg: unknown push-opcode: 0x%02x", opcode)
            return True
        return self.stackPushSegment(segment, self.cpu.operSize, True)
    cdef int popSeg(self, uint8_t opcode) except BITMASK_BYTE_CONST:
        cdef Segment *segment
        if (opcode == POP_DS):
            segment = &self.registers.segments.ds
        elif (opcode == POP_ES):
            segment = &self.registers.segments.es
        elif (opcode == POP_FS):
            segment = &self.registers.segments.fs
        elif (opcode == POP_GS):
            segment = &self.registers.segments.gs
        elif (opcode == POP_SS):
            self.registers.ssInhibit = True
            segment = &self.registers.segments.ss
        else:
            self.main.exitError("popSeg: unknown pop-opcode: 0x%02x", opcode)
            return True
        return self.stackPopSegment(segment)
    cdef int popRM16_32(self) except BITMASK_BYTE_CONST:
        cdef uint8_t operOpcodeId
        cdef uint32_t value
        self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        if (operOpcodeId == 0): # POP
            value = self.stackPopValue(True)
            self.modRMInstance.modRMSave(self.cpu.operSize, value, OPCODE_SAVE)
        else:
            self.main.notice("popRM16_32: unknown operOpcodeId: %u", operOpcodeId)
            raise HirnwichseException(CPU_EXCEPTION_UD)
        return True
    cdef int lea(self) except BITMASK_BYTE_CONST:
        cdef uint32_t mmAddr
        self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
        if (self.modRMInstance.mod == 3):
            raise HirnwichseException(CPU_EXCEPTION_UD)
        mmAddr = self.modRMInstance.getRMValueFull(self.cpu.operSize)
        #if (self.main.cpu.segmentOverridePrefix is not NULL):
        #    mmAddr = self.main.cpu.segmentOverridePrefix[0].gdtEntry.base+mmAddr
        #else:
        #    mmAddr = self.modRMInstance.rmNameSeg[0].gdtEntry.base+mmAddr
        self.modRMInstance.modRSave(self.cpu.operSize, mmAddr, OPCODE_SAVE)
        return True
    cdef int retNear(self, int16_t imm) except BITMASK_BYTE_CONST:
        self.registers.syncCR0State()
        self.registers.regWriteDword(CPU_REGISTER_EIP, self.stackPopValue(True))
        if (imm):
            if ((<Segment>self.registers.segments.ss).gdtEntry.segSize == OP_SIZE_WORD):
                self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx = self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx+imm
            else:
                self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx+imm
        return True
    cdef int retNearImm(self) except BITMASK_BYTE_CONST:
        cdef int16_t imm
        imm = <int16_t>self.registers.getCurrentOpcodeAddUnsignedWord() # imm16
        return self.retNear(imm)
    cdef int retFar(self, uint16_t imm) except BITMASK_BYTE_CONST:
        cdef GdtEntry gdtEntrySS
        cdef uint8_t stackAddrSize, cpl
        cdef uint16_t tempCS, tempSS
        cdef uint32_t tempEIP, tempESP, oldESP
        self.registers.syncCR0State()
        stackAddrSize = (<Segment>self.registers.segments.ss).gdtEntry.segSize
        tempEIP = self.stackPopValue(True)
        tempCS = <uint16_t>self.stackPopValue(True)
        if (imm):
            if (stackAddrSize == OP_SIZE_WORD):
                self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx = self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx+imm
            else:
                self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx+imm
        if (self.registers.protectedModeOn and not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
            cpl = self.registers.getCPL()
            if ((tempCS&3) > cpl): # outer privilege level; rpl > cpl
                if (stackAddrSize == OP_SIZE_DWORD):
                    oldESP = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx
                else:
                    oldESP = self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx
                self.main.notice("Opcodes::ret: test1: opl: rpl > cpl")
                if ((oldESP - (8 if (self.cpu.operSize == OP_SIZE_DWORD) else 4)) >= oldESP):
                    raise HirnwichseException(CPU_EXCEPTION_SS, 0)
                tempESP = self.stackPopValue(True)
                tempSS = self.stackPopValue(True)
                if (not (tempSS&0xfff8)):
                    self.main.notice("Opcodes::ret: test1: opl: rpl > cpl: test1.4")
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                if (not self.registers.segments.inLimit(tempSS)):
                    self.main.notice("Opcodes::ret: test1: opl: rpl > cpl: test1.1")
                    raise HirnwichseException(CPU_EXCEPTION_GP, tempSS)
                if (not self.registers.segments.getEntry(&gdtEntrySS, tempSS)):
                    self.main.exitError("Opcodes::ret: not gdtEntrySS")
                    return True
                if ((tempSS&3 != tempCS&3) or (not gdtEntrySS.segIsRW) or (gdtEntrySS.segDPL != tempCS&3)):
                    self.main.notice("Opcodes::ret: test1: opl: rpl > cpl: test1.2")
                    self.main.notice("Opcodes::ret: test1: opl: rpl > cpl: test1.3; %u; %u; %u", (tempSS&3 != tempCS&3), (not gdtEntrySS.segIsRW), (gdtEntrySS.segDPL != tempCS&3))
                    raise HirnwichseException(CPU_EXCEPTION_GP, tempSS)
                if (not gdtEntrySS.segPresent):
                    self.main.notice("Opcodes::ret: test1: opl: rpl > cpl: test1.5")
                    raise HirnwichseException(CPU_EXCEPTION_SS, tempSS)
                if ((<Segment>self.registers.segments.ds).isValid and (not (<Segment>self.registers.segments.ds).gdtEntry.segIsCodeSeg or not (<Segment>self.registers.segments.ds).gdtEntry.segIsConforming) and (cpl > (<Segment>self.registers.segments.ds).gdtEntry.segDPL)):
                    self.main.notice("Opcodes::ret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    self.main.notice("Opcodes::ret: TODO! (segmentIndex: 0x%04x; segDPL: %u; tempCS==0x%04x; segId==%u", (<Segment>self.registers.segments.ds).segmentIndex, (<Segment>self.registers.segments.ds).gdtEntry.segDPL, tempCS, (<Segment>self.registers.segments.ds).segId)
                    self.main.notice("Opcodes::ret: (isValid and (not codeSeg or not conforming) and (cpl > dpl)), set segments to zero")
                    self.registers.segWriteSegment(&self.registers.segments.ds, 0)
                if ((<Segment>self.registers.segments.es).isValid and (not (<Segment>self.registers.segments.es).gdtEntry.segIsCodeSeg or not (<Segment>self.registers.segments.es).gdtEntry.segIsConforming) and (cpl > (<Segment>self.registers.segments.es).gdtEntry.segDPL)):
                    self.main.notice("Opcodes::ret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    self.main.notice("Opcodes::ret: TODO! (segmentIndex: 0x%04x; segDPL: %u; tempCS==0x%04x; segId==%u", (<Segment>self.registers.segments.es).segmentIndex, (<Segment>self.registers.segments.es).gdtEntry.segDPL, tempCS, (<Segment>self.registers.segments.es).segId)
                    self.main.notice("Opcodes::ret: (isValid and (not codeSeg or not conforming) and (cpl > dpl)), set segments to zero")
                    self.registers.segWriteSegment(&self.registers.segments.es, 0)
                if ((<Segment>self.registers.segments.fs).isValid and (not (<Segment>self.registers.segments.fs).gdtEntry.segIsCodeSeg or not (<Segment>self.registers.segments.fs).gdtEntry.segIsConforming) and (cpl > (<Segment>self.registers.segments.fs).gdtEntry.segDPL)):
                    self.main.notice("Opcodes::ret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    self.main.notice("Opcodes::ret: TODO! (segmentIndex: 0x%04x; segDPL: %u; tempCS==0x%04x; segId==%u", (<Segment>self.registers.segments.fs).segmentIndex, (<Segment>self.registers.segments.fs).gdtEntry.segDPL, tempCS, (<Segment>self.registers.segments.fs).segId)
                    self.main.notice("Opcodes::ret: (isValid and (not codeSeg or not conforming) and (cpl > dpl)), set segments to zero")
                    self.registers.segWriteSegment(&self.registers.segments.fs, 0)
                if ((<Segment>self.registers.segments.gs).isValid and (not (<Segment>self.registers.segments.gs).gdtEntry.segIsCodeSeg or not (<Segment>self.registers.segments.gs).gdtEntry.segIsConforming) and (cpl > (<Segment>self.registers.segments.gs).gdtEntry.segDPL)):
                    self.main.notice("Opcodes::ret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    self.main.notice("Opcodes::ret: TODO! (segmentIndex: 0x%04x; segDPL: %u; tempCS==0x%04x; segId==%u", (<Segment>self.registers.segments.gs).segmentIndex, (<Segment>self.registers.segments.gs).gdtEntry.segDPL, tempCS, (<Segment>self.registers.segments.gs).segId)
                    self.main.notice("Opcodes::ret: (isValid and (not codeSeg or not conforming) and (cpl > dpl)), set segments to zero")
                    self.registers.segWriteSegment(&self.registers.segments.gs, 0)
                tempCS &= 0xfffc
                tempCS |= cpl
                self.registers.segWriteSegment(&self.registers.segments.ss, tempSS)
                stackAddrSize = (<Segment>self.registers.segments.ss).gdtEntry.segSize
                if (stackAddrSize == OP_SIZE_DWORD):
                    self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx = tempESP
                else:
                    self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx = <uint16_t>tempESP
        self.registers.segWriteSegment(&self.registers.segments.cs, tempCS)
        self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
        return True
    cdef int retFarImm(self) except BITMASK_BYTE_CONST:
        cdef uint16_t imm
        imm = self.registers.getCurrentOpcodeAddUnsignedWord() # imm16
        return self.retFar(imm)
    cdef int lfpFunc(self, Segment *segment) except BITMASK_BYTE_CONST: # 'load far pointer' function
        cdef uint16_t segmentAddr
        cdef uint32_t mmAddr, offsetAddr
        self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
        if (self.modRMInstance.mod == 3):
            raise HirnwichseException(CPU_EXCEPTION_UD)
        mmAddr = self.modRMInstance.getRMValueFull(self.cpu.addrSize)
        offsetAddr = self.registers.mmReadValueUnsigned(mmAddr, self.cpu.operSize, self.modRMInstance.rmNameSeg, True)
        segmentAddr = self.registers.mmReadValueUnsignedWord(mmAddr+self.cpu.operSize, self.modRMInstance.rmNameSeg, True)
        if (self.main.debugEnabled):
            self.main.notice("lfpFunc: test_1 (segId: %u; segmentAddr: 0x%04x; mmAddr: 0x%08x; rmNameSeg.segId: %u; operSize: %u; addrSize: %u)", segment[0].segId, segmentAddr, mmAddr, self.modRMInstance.rmNameSeg[0].segId, self.cpu.operSize, self.cpu.addrSize)
        self.registers.segWriteSegment(segment, segmentAddr)
        self.modRMInstance.modRSave(self.cpu.operSize, offsetAddr, OPCODE_SAVE)
        return True
    cdef int xlatb(self) except BITMASK_BYTE_CONST:
        cdef uint8_t data
        cdef uint32_t mmAddr
        IF COMP_DEBUG:
            self.main.notice("Opcodes::xlatb: TODO!")
        mmAddr = self.registers.regReadUnsigned(CPU_REGISTER_BX, self.cpu.addrSize)+self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl
        if (self.cpu.addrSize == OP_SIZE_WORD):
            mmAddr = <uint16_t>mmAddr
        data = self.registers.mmReadValueUnsignedByte(mmAddr, &self.registers.segments.ds, True)
        self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl = data
        return True
    cdef int opcodeGroup2_RM(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint8_t operOpcodeId, operSizeInBits
        cdef uint16_t op1Word
        cdef uint32_t operOp2, bitMask #, bitMaskHalf
        cdef uint64_t utemp, operOp1, operSum = 0, doubleBitMaskHalf
        cdef int32_t sop2
        cdef int64_t sop1, temp, tempmod
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        if (self.main.debugEnabled):
            self.main.notice("Group2_RM: operOpcodeId==%u", operOpcodeId)
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
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = operOp2!=0
        elif (operOpcodeId == GROUP2_OP_NOT):
            self.modRMInstance.modRMSave(operSize, operOp2, OPCODE_NOT)
        elif (operOpcodeId == GROUP2_OP_MUL):
            if (operSize == OP_SIZE_BYTE):
                operOp1 = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl
                self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx = operOp1*operOp2
                self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_MUL)
                return True
            operOp1 = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
            operSum = (operOp1*operOp2)
            if (operSize == OP_SIZE_WORD):
                operSum = <uint32_t>operSum
            self.registers.regWrite(CPU_REGISTER_DX, <uint32_t>(operSum>>operSizeInBits), operSize)
            if (operSize == OP_SIZE_WORD):
                operSum = <uint16_t>operSum
            elif (operSize == OP_SIZE_DWORD):
                operSum = <uint32_t>operSum
            self.registers.regWrite(CPU_REGISTER_AX, operSum, operSize)
            self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_MUL)
        elif (operOpcodeId == GROUP2_OP_IMUL):
            operOp1 = self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
            if (operSize == OP_SIZE_BYTE):
                operSum = <uint16_t>(<int16_t><int8_t>operOp1*<int8_t>operOp2)
                self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx = <uint16_t>operSum
            elif (operSize == OP_SIZE_WORD):
                operSum = <uint32_t>(<int32_t><int16_t>operOp1*<int16_t>operOp2)
                self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx = <uint16_t>operSum
                self.registers.regs[CPU_REGISTER_DX]._union.word._union.rx = <uint16_t>(operSum>>operSizeInBits)
            elif (operSize == OP_SIZE_DWORD):
                operSum = <uint64_t>(<int64_t><int32_t>operOp1*<int32_t>operOp2)
                self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = <uint32_t>operSum
                self.registers.regs[CPU_REGISTER_EDX]._union.dword.erx = <uint32_t>(operSum>>operSizeInBits)
            self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_IMUL)
            if (operSize == OP_SIZE_BYTE):
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = (<int8_t>operSum)!=(<int16_t>operSum)
            elif (operSize == OP_SIZE_WORD):
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = (<int16_t>operSum)!=(<int32_t>operSum)
            elif (operSize == OP_SIZE_DWORD):
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = (<int32_t>operSum)!=(<int64_t>operSum)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_DIV):
            op1Word = self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx
            if (not operOp2):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            temp = op1Word//operOp2
            tempmod = op1Word%operOp2
            if (temp != temp&bitMask):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl = temp
            self.registers.regs[CPU_REGISTER_AH]._union.word._union.byte.rh = tempmod
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_IDIV):
            sop1  = <int16_t>self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx
            sop2  = self.modRMInstance.modRMLoadSigned(operSize)
            if (sop1 == -0x8000 or not sop2):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            operOp2 = -sop2 if (sop2 < 0) else sop2
            temp = sop1//operOp2
            tempmod = sop1%operOp2
            if (sop2 != operOp2):
                temp = -temp
            if (<int16_t>temp != <int8_t>temp):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl = temp
            self.registers.regs[CPU_REGISTER_AH]._union.word._union.byte.rh = tempmod
        elif (operOpcodeId == GROUP2_OP_DIV):
            operOp1  = self.registers.regReadUnsigned(CPU_REGISTER_DX, operSize)<<operSizeInBits
            operOp1 |= self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
            if (not operOp2):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            utemp = operOp1//operOp2
            tempmod = operOp1%operOp2
            if (utemp != utemp&bitMask):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            self.registers.regWrite(CPU_REGISTER_AX, utemp, operSize)
            self.registers.regWrite(CPU_REGISTER_DX, tempmod, operSize)
        elif (operOpcodeId == GROUP2_OP_IDIV):
            #bitMaskHalf = BITMASKS_80[operSize]
            doubleBitMaskHalf = BITMASKS_80[operSize<<1]
            sop1 = (self.registers.regReadUnsigned(CPU_REGISTER_DX, operSize)<<operSizeInBits)|self.registers.regReadUnsigned(CPU_REGISTER_AX, operSize)
            sop2 = self.modRMInstance.modRMLoadSigned(operSize)
            if (operSize == OP_SIZE_WORD):
                sop1 = <int32_t>sop1
            else:
                sop1 = <int64_t>sop1
            if (sop1 == -doubleBitMaskHalf or not sop2):
                raise HirnwichseException(CPU_EXCEPTION_DE)
            temp = sop1//sop2
            tempmod = sop1%sop2
            if (operSize == OP_SIZE_WORD):
                if (<int32_t>temp != <int16_t>temp):
                    raise HirnwichseException(CPU_EXCEPTION_DE)
            else:
                if (<int64_t>temp != <int32_t>temp):
                    raise HirnwichseException(CPU_EXCEPTION_DE)
            self.registers.regWrite(CPU_REGISTER_AX, temp, operSize)
            self.registers.regWrite(CPU_REGISTER_DX, tempmod, operSize)
        else:
            self.main.notice("opcodeGroup2_RM: invalid operOpcodeId. %u", operOpcodeId)
            raise HirnwichseException(CPU_EXCEPTION_UD)
        return True
    cdef int interrupt(self, int16_t intNum=-1, int32_t errorCode=-1) except BITMASK_BYTE_CONST: # TODO: complete this!
        cdef uint8_t entryType, entrySize, entryNeededDPL, cpl, isSoftInt, oldVM = 0 #, entryPresent
        cdef uint16_t entrySegment = 0, newSS, oldSS, oldTSSsel
        cdef uint32_t entryEip = 0, eflagsClearThis, TSSstackOffset, newESP, oldESP, oldEFLAGS
        cdef IdtEntry idtEntry
        cdef GdtEntry gdtEntryCS
        cdef GdtEntry gdtEntrySS
        if (self.cpu.savedCs == 0x1000 and self.cpu.savedEip == 0x0):
            self.main.exitError("Opcodes::interrupt: faulty address/opcode called, exiting...")
            return True
        self.registers.syncCR0State()
        isSoftInt = False
        #entryType, entrySize, entryPresent, eflagsClearThis = TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE, OP_SIZE_WORD, True, (FLAG_TF | FLAG_RF)
        entryType, entrySize, eflagsClearThis = TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE, OP_SIZE_WORD, (FLAG_TF | FLAG_RF)
        if (self.registers.protectedModeOn):
            eflagsClearThis |= (FLAG_NT | FLAG_VM)
            oldVM = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm
        else:
            eflagsClearThis |= FLAG_AC
        if (intNum == -1):
            isSoftInt = True
            intNum = self.registers.getCurrentOpcodeAddUnsignedByte()
        oldEFLAGS = self.registers.readFlags()
        if (self.main.debugEnabled):
        #IF 1:
            self.main.notice("Opcodes::interrupt: Go Interrupt 0x%02x; isSoftInt==%u", intNum, isSoftInt)
            self.main.notice("Opcodes::interrupt: TODO! (opcode: 0x%02x, savedCs: 0x%04x, savedEip: 0x%08x)", self.cpu.opcode, self.cpu.savedCs, self.cpu.savedEip)
        if (self.registers.protectedModeOn):
            if (oldVM and (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.iopl < 3) and isSoftInt):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            if (not (<Idt>(<Segments>self.registers.segments).idt).getEntry(&idtEntry, intNum)):
                raise HirnwichseException(CPU_EXCEPTION_GP, self.calculateInterruptErrorcode(intNum, 1, not isSoftInt))
            cpl = self.registers.getCPL()
            entrySegment = idtEntry.entrySegment
            entryEip = idtEntry.entryEip
            entryType = idtEntry.entryType
            entryNeededDPL = idtEntry.entryNeededDPL
            #entryPresent = idtEntry.entryPresent
            entrySize = idtEntry.entrySize
            if (isSoftInt and entryNeededDPL < cpl):
                raise HirnwichseException(CPU_EXCEPTION_GP, self.calculateInterruptErrorcode(intNum, 1, not isSoftInt))
            if (entryType == TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE):
                if (self.main.debugEnabled):
                #IF 1:
                    self.main.notice("Opcodes::interrupt: task-gates aren't fully implemented yet. entrySegment==0x%04x", entrySegment)
                if (not self.registers.segments.getEntry(&gdtEntryCS, entrySegment)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, self.calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
                entryType = (gdtEntryCS.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK)
                if ((entrySegment & GDT_USE_LDT) or (entryType in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY)) or not self.registers.segments.inLimit(entrySegment)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, self.calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
                if (not gdtEntryCS.segPresent):
                    raise HirnwichseException(CPU_EXCEPTION_NP, self.calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
                oldTSSsel = (<Segment>self.registers.segments.tss).segmentIndex
                if (entryType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.saveTSS32()
                else:
                    self.registers.saveTSS16()
                self.registers.segWriteSegment(&self.registers.segments.tss, entrySegment)
                if (entryType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.switchTSS32()
                else:
                    self.registers.switchTSS16()
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.nt = True
                self.registers.mmWriteValue(TSS_PREVIOUS_TASK_LINK, oldTSSsel, OP_SIZE_WORD, &self.registers.segments.tss, False)
                if (not self.registers.isAddressInLimit(&self.registers.segments.cs.gdtEntry, self.registers.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_BYTE)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, not isSoftInt)
                return True
            elif (entryType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE, TABLE_ENTRY_SYSTEM_TYPE_16BIT_TRAP_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TRAP_GATE)):
                self.main.exitError("Opcodes::interrupt: unknown entryType %u.", entryType)
                return True
            if (not (entrySegment&0xfff8)):
                raise HirnwichseException(CPU_EXCEPTION_GP, not isSoftInt)
            if (not self.registers.segments.inLimit(entrySegment)):
                raise HirnwichseException(CPU_EXCEPTION_GP, self.calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
            if (not self.registers.segments.getEntry(&gdtEntryCS, entrySegment)):
                self.main.exitError("Opcodes::interrupt: not gdtEntryCS")
                return True
            if ((not gdtEntryCS.segIsCodeSeg) or (gdtEntryCS.segDPL > cpl)):
                raise HirnwichseException(CPU_EXCEPTION_GP, self.calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
            if (not gdtEntryCS.segPresent):
                raise HirnwichseException(CPU_EXCEPTION_NP, self.calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
            if ((not gdtEntryCS.segIsConforming) and (gdtEntryCS.segDPL < cpl)):
                # TODO: What to do if VM flag is true?
                # inter-privilege-level-interrupt
                if (self.main.debugEnabled):
                    self.main.notice("Opcodes::interrupt: inter/inner")
                if (oldVM):
                    if (self.main.debugEnabled):
                        self.main.notice("Opcodes::interrupt: Go Interrupt 0x%02x; isSoftInt==%u", intNum, isSoftInt)
                        self.main.notice("Opcodes::interrupt: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                        self.main.notice("Opcodes::interrupt: VM86-Mode isn't supported yet. (interrupt from VM86-Mode; inter-privilege-level-interrupt)")
                        self.cpu.cpuDump()
                    if (gdtEntryCS.segDPL):
                        raise HirnwichseException(CPU_EXCEPTION_GP, self.calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
                if (((<Segment>self.registers.segments.tss).gdtEntry.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY) == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    if (oldVM):
                        if ((<Segment>self.registers.segments.tss).gdtEntry.limit < 9):
                            raise HirnwichseException(CPU_EXCEPTION_TS, self.calculateInterruptErrorcode((<Segment>self.registers.segments.tss).segmentIndex, 0, not isSoftInt))
                        newSS = self.registers.mmReadValueUnsignedWord(TSS_32BIT_SS0, &self.registers.segments.tss, False)
                        newESP = self.registers.mmReadValueUnsignedDword(TSS_32BIT_ESP0, &self.registers.segments.tss, False)
                    else:
                        TSSstackOffset = (gdtEntryCS.segDPL << 3) + 4
                        if ((TSSstackOffset + 5) > (<Segment>self.registers.segments.tss).gdtEntry.limit):
                            raise HirnwichseException(CPU_EXCEPTION_TS, self.calculateInterruptErrorcode((<Segment>self.registers.segments.tss).segmentIndex, 0, not isSoftInt))
                        newSS = self.registers.mmReadValueUnsignedWord((TSSstackOffset + OP_SIZE_DWORD), &self.registers.segments.tss, False)
                        newESP = self.registers.mmReadValueUnsignedDword(TSSstackOffset, &self.registers.segments.tss, False)
                elif (((<Segment>self.registers.segments.tss).gdtEntry.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY) == TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS):
                    if (oldVM):
                        if ((<Segment>self.registers.segments.tss).gdtEntry.limit < 5):
                            raise HirnwichseException(CPU_EXCEPTION_TS, self.calculateInterruptErrorcode((<Segment>self.registers.segments.tss).segmentIndex, 0, not isSoftInt))
                        newSS = self.registers.mmReadValueUnsignedWord(TSS_16BIT_SS0, &self.registers.segments.tss, False)
                        newESP = self.registers.mmReadValueUnsignedWord(TSS_16BIT_SP0, &self.registers.segments.tss, False)
                    else:
                        TSSstackOffset = (gdtEntryCS.segDPL << 2) + 2
                        if ((TSSstackOffset + 3) > (<Segment>self.registers.segments.tss).gdtEntry.limit):
                            raise HirnwichseException(CPU_EXCEPTION_TS, self.calculateInterruptErrorcode((<Segment>self.registers.segments.tss).segmentIndex, 0, not isSoftInt))
                        newSS = self.registers.mmReadValueUnsignedWord((TSSstackOffset + OP_SIZE_WORD), &self.registers.segments.tss, False)
                        newESP = self.registers.mmReadValueUnsignedWord(TSSstackOffset, &self.registers.segments.tss, False)
                else:
                    self.main.exitError("Opcodes::interrupt: not (tss32 or tss16)")
                    return True
                if (not (newSS&0xfff8)):
                    raise HirnwichseException(CPU_EXCEPTION_TS, not isSoftInt)
                if (not self.registers.segments.inLimit(newSS) or (not oldVM and ((newSS&3) != gdtEntryCS.segDPL)) or (oldVM and ((newSS&3) != 0))):
                    raise HirnwichseException(CPU_EXCEPTION_TS, self.calculateInterruptErrorcode(newSS, 0, not isSoftInt))
                if (not self.registers.segments.getEntry(&gdtEntrySS, newSS)):
                    self.main.exitError("Opcodes::interrupt: not gdtEntrySS")
                    return True
                if ((not oldVM and gdtEntrySS.segDPL != gdtEntryCS.segDPL) or (oldVM and gdtEntrySS.segDPL != 0) or (not gdtEntrySS.segIsCodeSeg and not gdtEntrySS.segIsRW)):
                    raise HirnwichseException(CPU_EXCEPTION_TS, self.calculateInterruptErrorcode(newSS, 0, not isSoftInt))
                if (not gdtEntrySS.segPresent):
                    raise HirnwichseException(CPU_EXCEPTION_SS, self.calculateInterruptErrorcode(newSS, 0, not isSoftInt))
                cpl = gdtEntryCS.segDPL
                self.registers.cpl = cpl # TODO: HACK!
                if (not self.registers.isAddressInLimit(&gdtEntryCS, entryEip, OP_SIZE_BYTE)):
                    raise HirnwichseException(CPU_EXCEPTION_GP, not isSoftInt)
                if (entryType in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE)):
                    eflagsClearThis |= FLAG_IF
                    if (oldVM):
                        eflagsClearThis |= FLAG_VM | FLAG_NT
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.dword.erx &= ~eflagsClearThis
                oldSS = self.registers.regs[CPU_SEGMENT_BASE+CPU_SEGMENT_SS]._union.word._union.rx
                oldESP = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx
                self.registers.segWriteSegment(&self.registers.segments.ss, newSS)
                if ((<Segment>self.registers.segments.ss).gdtEntry.segSize == OP_SIZE_WORD):
                    newESP = <uint16_t>newESP
                if (idtEntry.entrySize == OP_SIZE_DWORD):
                    if ((not oldVM and (newESP - (24 if (errorCode != -1) else 20)) >= newESP) or (oldVM and (newESP - (40 if (errorCode != -1) else 36)) >= newESP)):
                        raise HirnwichseException(CPU_EXCEPTION_SS, self.calculateInterruptErrorcode(newSS, 0, not isSoftInt))
                else:
                    if ((not oldVM and (newESP - (12 if (errorCode != -1) else 10)) >= newESP) or (oldVM and (newESP - (20 if (errorCode != -1) else 18)) >= newESP)):
                        raise HirnwichseException(CPU_EXCEPTION_SS, self.calculateInterruptErrorcode(newSS, 0, not isSoftInt))
                if ((<Segment>self.registers.segments.ss).gdtEntry.segSize == OP_SIZE_DWORD):
                    self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx = newESP
                else:
                    self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx = <uint16_t>newESP
                if (oldVM):
                    self.stackPushSegment(&self.registers.segments.gs, entrySize, False)
                    self.stackPushSegment(&self.registers.segments.fs, entrySize, False)
                    self.stackPushSegment(&self.registers.segments.ds, entrySize, False)
                    self.stackPushSegment(&self.registers.segments.es, entrySize, False)
                self.stackPushValue(oldSS, entrySize, False)
                self.stackPushValue(oldESP, entrySize, False)
            else:
                # intra-privilege-level-interrupt
                if (self.main.debugEnabled):
                    self.main.notice("Opcodes::interrupt: intra")
                if (oldVM):
                    if (self.main.debugEnabled):
                        self.main.notice("Opcodes::interrupt: VM86-Mode isn't supported yet. (exception from intra-privilege-level-interrupt)")
                    raise HirnwichseException(CPU_EXCEPTION_GP, self.calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
                if (gdtEntryCS.segIsConforming or (gdtEntryCS.segDPL == cpl)):
                    oldESP = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx
                    if (idtEntry.entrySize == OP_SIZE_DWORD):
                        if ((oldESP - (16 if (errorCode != -1) else 12)) >= oldESP):
                            raise HirnwichseException(CPU_EXCEPTION_SS, not isSoftInt)
                    else:
                        if ((oldESP - (8 if (errorCode != -1) else 6)) >= oldESP):
                            raise HirnwichseException(CPU_EXCEPTION_SS, not isSoftInt)
                    if (not self.registers.isAddressInLimit(&gdtEntryCS, entryEip, OP_SIZE_BYTE)):
                        raise HirnwichseException(CPU_EXCEPTION_GP, not isSoftInt)
                else:
                    raise HirnwichseException(CPU_EXCEPTION_GP, self.calculateInterruptErrorcode(entrySegment, 0, not isSoftInt))
            if (not oldVM):
                entrySegment &= 0xfffc
                entrySegment |= cpl
        else:
            (<Idt>(<Segments>self.registers.segments).idt).getEntryRealMode(intNum, &entrySegment, <uint16_t*>&entryEip)
            entryEip = <uint16_t>entryEip
        if (self.main.debugEnabled):
        #IF 1:
            self.main.notice("Opcodes::interrupt: Go Interrupt 0x%02x. CS: 0x%04x, (E)IP: 0x%04x, AX: 0x%04x", intNum, entrySegment, entryEip, self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx)
        if (entryType in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE)):
            eflagsClearThis |= FLAG_IF
            if (oldVM):
                eflagsClearThis |= FLAG_VM | FLAG_NT
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.dword.erx &= ~eflagsClearThis
        self.stackPushValue(oldEFLAGS, entrySize, False)
        self.stackPushSegment(&self.registers.segments.cs, entrySize, False)
        self.stackPushRegId(CPU_REGISTER_EIP, entrySize)
        if (self.registers.protectedModeOn and not isSoftInt and errorCode != -1):
            self.stackPushValue(errorCode, entrySize, False)
        if (oldVM):
            if (self.main.debugEnabled):
                self.main.notice("Opcodes::interrupt: Go Interrupt 0x%02x; isSoftInt==%u", intNum, isSoftInt)
                self.main.notice("Opcodes::interrupt: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                self.main.notice("Opcodes::interrupt: oldVM, set segments to zero")
                self.cpu.cpuDump()
            self.registers.segWriteSegment(&self.registers.segments.gs, 0)
            self.registers.segWriteSegment(&self.registers.segments.fs, 0)
            self.registers.segWriteSegment(&self.registers.segments.ds, 0)
            self.registers.segWriteSegment(&self.registers.segments.es, 0)
        self.registers.segWriteSegment(&self.registers.segments.cs, entrySegment)
        self.registers.regWriteDword(CPU_REGISTER_EIP, entryEip)
        return True
    cdef int into(self) except BITMASK_BYTE_CONST:
        #self.main.notice("Opcodes::into: TODO!")
        if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of):
            raise HirnwichseException(CPU_EXCEPTION_OF)
        return True
    cdef int iret(self) except BITMASK_BYTE_CONST:
        cdef GdtEntry gdtEntryCS
        cdef GdtEntry gdtEntrySS
        cdef GdtEntry gdtEntryTSS
        cdef uint8_t cpl, newCpl, segType, oldSegType
        cdef uint16_t tempCS, tempSS, tempES, tempDS, tempFS, tempGS, linkSel, TSSsel
        cdef uint32_t tempEFLAGS, currentEFLAGS, tempEIP, tempESP, oldESP, eflagsMask = 0
        if (self.main.debugEnabled):
        #IF 1:
            self.main.notice("Opcodes::iret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
        self.registers.syncCR0State()
        tempEIP = self.stackPopValue(False) # this is here because esp should stay on
                                            # it's original value in case of an exception.
        if (not self.registers.protectedModeOn and self.cpu.operSize == OP_SIZE_DWORD and (tempEIP>>16)):
            self.main.notice("Opcodes::iret: test1: opl: test1.9 (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
            raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        oldESP = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx
        if ((oldESP - (12 if (self.cpu.operSize == OP_SIZE_DWORD) else 6)) >= oldESP):
            raise HirnwichseException(CPU_EXCEPTION_SS, 0)
        tempEIP = self.stackPopValue(True)
        tempCS = self.stackPopValue(True)
        tempEFLAGS = self.stackPopValue(True)
        currentEFLAGS = self.registers.readFlags()
        if (self.registers.protectedModeOn):
            cpl = newCpl = self.registers.getCPL()
            if (currentEFLAGS & FLAG_VM):
                IF COMP_DEBUG:
                    if (self.main.debugEnabled):
                        self.main.notice("Opcodes::iret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                        self.main.notice("Opcodes::iret: VM86-Mode isn't fully supported yet. (return from VM86-Mode)")
                        self.cpu.cpuDump()
                if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.iopl < 3):
                    IF COMP_DEBUG:
                        self.main.notice("Opcodes::iret: test1: opl: vm: test1.10 (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                #if (not self.registers.isAddressInLimit(&self.registers.segments.cs.gdtEntry, tempEIP, OP_SIZE_BYTE)):
                #    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                eflagsMask = FLAG_VM | FLAG_IOPL | FLAG_VIP | FLAG_VIF
                tempEFLAGS &= ~eflagsMask
                tempEFLAGS |= currentEFLAGS & eflagsMask
                if (self.cpu.operSize == OP_SIZE_WORD):
                    self.registers.regWriteWord(CPU_REGISTER_FLAGS, tempEFLAGS)
                else:
                    self.registers.regWriteDword(CPU_REGISTER_EFLAGS, tempEFLAGS)
                #self.registers.regWriteDword(CPU_REGISTER_EFLAGS, tempEFLAGS)
                self.registers.segWriteSegment(&self.registers.segments.cs, tempCS)
                self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
                #self.registers.ssInhibit = True
                self.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
                return True
            elif (currentEFLAGS & FLAG_NT):
                if (self.main.debugEnabled):
                    self.main.notice("Opcodes::iret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    self.main.notice("Opcodes::iret: Nested-Task-Flag isn't fully supported yet.")
                    self.cpu.cpuDump()
                TSSsel = (<Segment>self.registers.segments.tss).segmentIndex
                linkSel = self.registers.mmReadValueUnsignedWord(TSS_PREVIOUS_TASK_LINK, &self.registers.segments.tss, False)
                if ((linkSel & GDT_USE_LDT) or not self.registers.segments.inLimit(linkSel)):
                    raise HirnwichseException(CPU_EXCEPTION_TS, TSSsel)
                if (not self.registers.segments.getEntry(&gdtEntryTSS, linkSel)):
                    self.main.notice("Opcodes::iret: test1: opl: nt: test1.11 (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    raise HirnwichseException(CPU_EXCEPTION_GP, TSSsel)
                segType = (gdtEntryTSS.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK)
                if (segType not in (TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY)):
                    self.main.notice("Opcodes::iret: nested-task-flag: exception_2 (segType: 0x%02x; linkSel: 0x%04x)", segType, linkSel)
                    raise HirnwichseException(CPU_EXCEPTION_TS, TSSsel)
                if (not gdtEntryTSS.segPresent):
                    raise HirnwichseException(CPU_EXCEPTION_NP, TSSsel)
                oldSegType = ((<Segment>self.registers.segments.tss).gdtEntry.accessByte & TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY)
                self.registers.segments.setSegType(TSSsel, oldSegType)
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.dword.erx = self.registers.regs[CPU_REGISTER_EFLAGS]._union.dword.erx&(~FLAG_NT)
                if (segType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.saveTSS32()
                else:
                    self.registers.saveTSS16()
                self.registers.segWriteSegment(&self.registers.segments.tss, linkSel)
                if (segType == TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS):
                    self.registers.switchTSS32()
                else:
                    self.registers.switchTSS16()
                if (not self.registers.isAddressInLimit(&self.registers.segments.cs.gdtEntry, self.registers.regs[CPU_REGISTER_EIP]._union.dword.erx, OP_SIZE_BYTE)):
                    self.main.notice("Opcodes::iret: test1: opl: nt: test1.12 (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                #self.registers.ssInhibit = True
                self.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
                return True
            elif (tempEFLAGS & FLAG_VM):
                if (not cpl):
                    if (self.main.debugEnabled):
                        self.main.notice("Opcodes::iret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                        self.main.notice("Opcodes::iret: VM86-Mode isn't fully supported yet. (return to VM86-Mode)")
                        self.cpu.cpuDump()
                    if ((oldESP - 24) >= oldESP):
                        raise HirnwichseException(CPU_EXCEPTION_SS, 0)
                    #if (not self.registers.isAddressInLimit(&self.registers.segments.cs.gdtEntry, tempEIP, OP_SIZE_BYTE)):
                    #    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                    tempESP = self.stackPopValue(True)
                    tempSS = self.stackPopValue(True)
                    tempES = self.stackPopValue(True)
                    tempDS = self.stackPopValue(True)
                    tempFS = self.stackPopValue(True)
                    tempGS = self.stackPopValue(True)
                    self.registers.regWriteDword(CPU_REGISTER_EFLAGS, tempEFLAGS)
                    self.registers.segWriteSegment(&self.registers.segments.cs, tempCS)
                    self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
                    self.registers.segWriteSegment(&self.registers.segments.ss, tempSS)
                    self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx = tempESP
                    self.registers.segWriteSegment(&self.registers.segments.es, tempES)
                    self.registers.segWriteSegment(&self.registers.segments.ds, tempDS)
                    self.registers.segWriteSegment(&self.registers.segments.fs, tempFS)
                    self.registers.segWriteSegment(&self.registers.segments.gs, tempGS)
                    #self.registers.ssInhibit = True
                    self.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
                    return True
                else:
                    self.main.exitError("Opcodes::iret: TODO; tempEFLAGS & vm and cpl != 0! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    return True
            elif ((tempCS&3) > cpl): # outer privilege level; rpl > cpl
                if (self.main.debugEnabled):
                    self.main.notice("Opcodes::iret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    self.main.notice("Opcodes::iret: test1: opl: rpl > cpl")
                    self.cpu.cpuDump()
                if ((oldESP - (8 if (self.cpu.operSize == OP_SIZE_DWORD) else 4)) >= oldESP):
                    raise HirnwichseException(CPU_EXCEPTION_SS, 0)
                tempESP = self.stackPopValue(True)
                tempSS = self.stackPopValue(True)
                if (not (tempSS&0xfff8)):
                    self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.4 (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    raise HirnwichseException(CPU_EXCEPTION_GP, 0)
                if (not self.registers.segments.inLimit(tempSS)):
                    self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.1 (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    raise HirnwichseException(CPU_EXCEPTION_GP, tempSS)
                if (not self.registers.segments.getEntry(&gdtEntrySS, tempSS)):
                    self.main.exitError("Opcodes::iret: not gdtEntrySS")
                    return True
                if ((tempSS&3 != tempCS&3) or (not gdtEntrySS.segIsRW) or (gdtEntrySS.segDPL != tempCS&3)):
                    self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.2 (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.3; %u; %u; %u", (tempSS&3 != tempCS&3), (not gdtEntrySS.segIsRW), (gdtEntrySS.segDPL != tempCS&3))
                    raise HirnwichseException(CPU_EXCEPTION_GP, tempSS)
                if (not gdtEntrySS.segPresent):
                    self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.5 (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                    raise HirnwichseException(CPU_EXCEPTION_SS, tempSS)
                if (self.cpu.operSize == OP_SIZE_DWORD and not cpl):
                    eflagsMask |= FLAG_VM
                newCpl = tempCS & 0x3
                if ((<Segment>self.registers.segments.ds).isValid and (not (<Segment>self.registers.segments.ds).gdtEntry.segIsCodeSeg or not (<Segment>self.registers.segments.ds).gdtEntry.segIsConforming) and (newCpl > (<Segment>self.registers.segments.ds).gdtEntry.segDPL)):
                    if (self.main.debugEnabled):
                        self.main.notice("Opcodes::iret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                        self.main.notice("Opcodes::iret: TODO! (segmentIndex: 0x%04x; segDPL: %u; tempCS==0x%04x; segId==%u", (<Segment>self.registers.segments.ds).segmentIndex, (<Segment>self.registers.segments.ds).gdtEntry.segDPL, tempCS, (<Segment>self.registers.segments.ds).segId)
                        self.main.notice("Opcodes::iret: (isValid and (not codeSeg or not conforming) and (newCpl > dpl)), set segments to zero")
                    self.registers.segWriteSegment(&self.registers.segments.ds, 0)
                if ((<Segment>self.registers.segments.es).isValid and (not (<Segment>self.registers.segments.es).gdtEntry.segIsCodeSeg or not (<Segment>self.registers.segments.es).gdtEntry.segIsConforming) and (newCpl > (<Segment>self.registers.segments.es).gdtEntry.segDPL)):
                    if (self.main.debugEnabled):
                        self.main.notice("Opcodes::iret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                        self.main.notice("Opcodes::iret: TODO! (segmentIndex: 0x%04x; segDPL: %u; tempCS==0x%04x; segId==%u", (<Segment>self.registers.segments.es).segmentIndex, (<Segment>self.registers.segments.es).gdtEntry.segDPL, tempCS, (<Segment>self.registers.segments.es).segId)
                        self.main.notice("Opcodes::iret: (isValid and (not codeSeg or not conforming) and (newCpl > dpl)), set segments to zero")
                    self.registers.segWriteSegment(&self.registers.segments.es, 0)
                if ((<Segment>self.registers.segments.fs).isValid and (not (<Segment>self.registers.segments.fs).gdtEntry.segIsCodeSeg or not (<Segment>self.registers.segments.fs).gdtEntry.segIsConforming) and (newCpl > (<Segment>self.registers.segments.fs).gdtEntry.segDPL)):
                    if (self.main.debugEnabled):
                        self.main.notice("Opcodes::iret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                        self.main.notice("Opcodes::iret: TODO! (segmentIndex: 0x%04x; segDPL: %u; tempCS==0x%04x; segId==%u", (<Segment>self.registers.segments.fs).segmentIndex, (<Segment>self.registers.segments.fs).gdtEntry.segDPL, tempCS, (<Segment>self.registers.segments.fs).segId)
                        self.main.notice("Opcodes::iret: (isValid and (not codeSeg or not conforming) and (newCpl > dpl)), set segments to zero")
                    self.registers.segWriteSegment(&self.registers.segments.fs, 0)
                if ((<Segment>self.registers.segments.gs).isValid and (not (<Segment>self.registers.segments.gs).gdtEntry.segIsCodeSeg or not (<Segment>self.registers.segments.gs).gdtEntry.segIsConforming) and (newCpl > (<Segment>self.registers.segments.gs).gdtEntry.segDPL)):
                    if (self.main.debugEnabled):
                        self.main.notice("Opcodes::iret: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                        self.main.notice("Opcodes::iret: TODO! (segmentIndex: 0x%04x; segDPL: %u; tempCS==0x%04x; segId==%u", (<Segment>self.registers.segments.gs).segmentIndex, (<Segment>self.registers.segments.gs).gdtEntry.segDPL, tempCS, (<Segment>self.registers.segments.gs).segId)
                        self.main.notice("Opcodes::iret: (isValid and (not codeSeg or not conforming) and (newCpl > dpl)), set segments to zero")
                    self.registers.segWriteSegment(&self.registers.segments.gs, 0)
                self.registers.segWriteSegment(&self.registers.segments.ss, tempSS)
                if ((<Segment>self.registers.segments.ss).gdtEntry.segSize == OP_SIZE_DWORD):
                    self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx = tempESP
                else:
                    self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx = <uint16_t>tempESP
            if (not (tempCS&0xfff8)):
                self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.6 (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            if (not self.registers.segments.inLimit(tempCS)):
                self.main.notice("Opcodes::iret: test2: not inLimit: tempCS: 0x%04x; currentEFLAGS: 0x%04x; tempEFLAGS: 0x%04x (savedEip: 0x%08x, savedCs: 0x%04x)", tempCS, currentEFLAGS, tempEFLAGS, self.cpu.savedEip, self.cpu.savedCs)
                raise HirnwichseException(CPU_EXCEPTION_GP, tempCS)
            if (not self.registers.segments.getEntry(&gdtEntryCS, tempCS)):
                self.main.exitError("Opcodes::iret: not gdtEntryCS (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                return True
            if (not gdtEntryCS.segIsCodeSeg or ((tempCS&3) < cpl) or (gdtEntryCS.segIsConforming and (gdtEntryCS.segDPL > (tempCS&3))) or (not gdtEntryCS.segIsConforming and (gdtEntryCS.segDPL != (tempCS&3)))):
                IF COMP_DEBUG:
                    self.main.notice("Opcodes::iret: test3 (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                #self.main.notice("Opcodes::iret: test3.1 (segIsCodeSeg: %u, segIsConforming: %u, segDPL: %u, RetCS-RPL: %u; CPL: %u)", gdtEntryCS.segIsCodeSeg, gdtEntryCS.segIsConforming, gdtEntryCS.segDPL, tempCS&3, cpl)
                #self.cpu.cpuDump()
                raise HirnwichseException(CPU_EXCEPTION_GP, tempCS & 0xfffc)
            if (not gdtEntryCS.segPresent):
                self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.7 (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                raise HirnwichseException(CPU_EXCEPTION_NP, tempCS & 0xfffc)
            eflagsMask |= FLAG_CF | FLAG_PF | FLAG_AF | FLAG_ZF | FLAG_SF | FLAG_TF | FLAG_DF | FLAG_OF | FLAG_NT
            if (self.cpu.operSize in (OP_SIZE_DWORD, OP_SIZE_QWORD)):
                eflagsMask |= FLAG_RF | FLAG_AC | FLAG_ID
            if (cpl <= self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.iopl):
                eflagsMask |= FLAG_IF
            if (not cpl): # cpl == 0
                eflagsMask |= FLAG_IOPL
                if (self.cpu.operSize in (OP_SIZE_DWORD, OP_SIZE_QWORD)):
                    eflagsMask |= FLAG_VIF | FLAG_VIP
            tempEFLAGS &= eflagsMask
            currentEFLAGS &= ~eflagsMask
            currentEFLAGS |= tempEFLAGS
            self.registers.regWriteDword(CPU_REGISTER_EFLAGS, currentEFLAGS)
            tempCS &= 0xfffc
            tempCS |= newCpl
            self.registers.segWriteSegment(&self.registers.segments.cs, tempCS)
            self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
            #self.cpu.saveCurrentInstPointer() # TODO
            if (not self.registers.isAddressInLimit(&gdtEntryCS, tempEIP, OP_SIZE_BYTE)):
                self.main.notice("Opcodes::iret: test1: opl: rpl > cpl: test1.8 (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
        else:
            if (self.cpu.operSize == OP_SIZE_DWORD):
                tempEFLAGS = (tempEFLAGS & 0x257fd5)
                tempEFLAGS |= self.registers.readFlags()&<uint32_t>0xff1a0000
                self.registers.regWriteDword(CPU_REGISTER_EFLAGS, tempEFLAGS)
            else:
                self.registers.regWriteWord(CPU_REGISTER_FLAGS, <uint16_t>tempEFLAGS)
            self.registers.segWriteSegment(&self.registers.segments.cs, tempCS)
            self.registers.regWriteDword(CPU_REGISTER_EIP, tempEIP)
        #self.registers.ssInhibit = True
        self.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
        return True
    cdef int aad(self) except BITMASK_BYTE_CONST:
        cdef uint8_t imm8, tempAL, tempAH
        imm8 = self.registers.getCurrentOpcodeAddUnsignedByte()
        tempAH = self.registers.regs[CPU_REGISTER_AH]._union.word._union.byte.rh*imm8
        tempAL = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl+tempAH
        self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx = tempAL
        self.registers.setSZP_COA(tempAL, OP_SIZE_BYTE)
        return True
    cdef int aam(self) except BITMASK_BYTE_CONST:
        cdef uint8_t imm8, tempAL, ALdiv, ALmod
        imm8 = self.registers.getCurrentOpcodeAddUnsignedByte()
        if (not imm8):
            raise HirnwichseException(CPU_EXCEPTION_DE)
        tempAL = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl
        ALdiv = tempAL//imm8
        ALmod = tempAL%imm8
        self.registers.regs[CPU_REGISTER_AH]._union.word._union.byte.rh = ALdiv
        self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl = ALmod
        self.registers.setSZP_COA(ALmod, OP_SIZE_BYTE)
        return True
    cdef int aaa(self) nogil except BITMASK_BYTE_CONST:
        cdef uint8_t AFflag, tempAL #, tempAH
        cdef uint16_t tempAX
        tempAX = self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx
        tempAL = tempAX&0xf
        #tempAH = (tempAX>>8)
        AFflag = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af
        if ((tempAL>9) or AFflag):
            tempAL = (tempAL+6)&0xf
            self.registers.setSZP_O(tempAL, OP_SIZE_BYTE)
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = True
            self.registers.regs[CPU_REGISTER_AH]._union.word._union.byte.rh = self.registers.regs[CPU_REGISTER_AH]._union.word._union.byte.rh+1
        else:
            tempAL &= 0xf
            self.registers.setSZP_COA(tempAL, OP_SIZE_BYTE)
        self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl = tempAL
        return True
    cdef int aas(self) nogil except BITMASK_BYTE_CONST:
        cdef uint8_t AFflag, tempAL #, tempAH
        cdef uint16_t tempAX
        tempAX = self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx
        tempAL = tempAX&0xf
        #tempAH = (tempAX>>8)
        AFflag = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af
        if ((tempAL>9) or AFflag):
            tempAL = (tempAL-6)&0xf
            self.registers.setSZP_O(tempAL, OP_SIZE_BYTE)
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = True
            self.registers.regs[CPU_REGISTER_AH]._union.word._union.byte.rh = self.registers.regs[CPU_REGISTER_AH]._union.word._union.byte.rh-1
        else:
            tempAL &= 0xf
            self.registers.setSZP_COA(tempAL, OP_SIZE_BYTE)
        self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl = tempAL
        return True
    cdef int daa(self) nogil except BITMASK_BYTE_CONST:
        cdef uint8_t old_AL, old_AF, old_CF
        old_AL = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl
        old_AF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af
        old_CF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        self.clc()
        if (((old_AL&0xf)>9) or old_AF):
            self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl+0x6
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = old_CF or (old_AL+6>BITMASK_BYTE)
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = True
        else:
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = False
        if ((old_AL > 0x99) or old_CF):
            self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl+0x60
            self.stc()
        else:
            self.clc()
        self.registers.setSZP_O(self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl, OP_SIZE_BYTE)
        return True
    cdef int das(self) nogil except BITMASK_BYTE_CONST:
        cdef uint8_t old_AL, old_AF, old_CF
        old_AL = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl
        old_AF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af
        old_CF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        self.clc()
        if (((old_AL&0xf)>9) or old_AF):
            self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl-0x6
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = old_CF or (old_AL-6<0)
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = True
        else:
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = False
        if ((old_AL > 0x99) or old_CF):
            self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl = self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl-0x60
            self.stc()
        self.registers.setSZP_O(self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl, OP_SIZE_BYTE)
        return True
    cdef int cbw_cwde(self) nogil except BITMASK_BYTE_CONST:
        cdef uint32_t op2
        if (self.cpu.operSize == OP_SIZE_WORD): # CBW
            op2 = <uint16_t><int8_t>self.registers.regs[CPU_REGISTER_AL]._union.word._union.byte.rl
            self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx = op2
        elif (self.cpu.operSize == OP_SIZE_DWORD): # CWDE
            op2 = <int16_t>self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx
            self.registers.regs[CPU_REGISTER_EAX]._union.dword.erx = op2
        return True
    cdef int cwd_cdq(self) nogil except BITMASK_BYTE_CONST:
        cdef uint32_t bitMask, bitMaskHalf, op2
        bitMask = BITMASKS_FF[self.cpu.operSize]
        bitMaskHalf = BITMASKS_80[self.cpu.operSize]
        op2 = self.registers.regReadUnsigned(CPU_REGISTER_AX, self.cpu.operSize)
        if (op2&bitMaskHalf):
            self.registers.regWrite(CPU_REGISTER_DX, bitMask, self.cpu.operSize)
        else:
            self.registers.regWrite(CPU_REGISTER_DX, 0, self.cpu.operSize)
        return True
    cdef int shlFunc(self, uint8_t operSize, uint8_t count) except BITMASK_BYTE_CONST:
        cdef uint8_t newCF
        cdef uint32_t bitMaskHalf, dest
        bitMaskHalf = BITMASKS_80[operSize]
        dest = self.modRMInstance.modRMLoadUnsigned(operSize)
        count = count&0x1f
        if (not count):
            return True
        newCF = ((dest<<(count-1))&bitMaskHalf)!=0
        dest = (dest<<count)
        if (operSize == OP_SIZE_WORD):
            dest = <uint16_t>dest
        self.modRMInstance.modRMSave(operSize, dest, OPCODE_SAVE)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = newCF
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = False
        self.registers.setSZP(dest, operSize)
        return True
    cdef int sarFunc(self, uint8_t operSize, uint8_t count) except BITMASK_BYTE_CONST:
        cdef uint8_t newCF
        cdef uint32_t bitMask
        cdef int32_t dest
        bitMask = BITMASKS_FF[operSize]
        dest = self.modRMInstance.modRMLoadSigned(operSize)
        count = count&0x1f
        if (not count):
            return True
        newCF = ((dest>>(count-1))&1)
        dest >>= count
        self.modRMInstance.modRMSave(operSize, dest&bitMask, OPCODE_SAVE)
        self.registers.setSZP_COA(dest&bitMask, operSize)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = newCF
        return True
    cdef int shrFunc(self, uint8_t operSize, uint8_t count) except BITMASK_BYTE_CONST:
        cdef uint8_t newCF_OF
        cdef uint32_t bitMaskHalf, dest #, tempDest
        bitMaskHalf = BITMASKS_80[operSize]
        dest = self.modRMInstance.modRMLoadUnsigned(operSize)
        #tempDest = dest
        count = count&0x1f
        if (not count):
            return True
        newCF_OF = ((dest>>(count-1))&1)
        dest >>= count
        self.modRMInstance.modRMSave(operSize, dest, OPCODE_SAVE)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = newCF_OF
        newCF_OF = (((dest<<1)^dest)&bitMaskHalf)!=0
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = newCF_OF
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.af = False
        self.registers.setSZP(dest, operSize)
        return True
    cdef int rclFunc(self, uint8_t operSize, uint8_t count) except BITMASK_BYTE_CONST:
        cdef uint8_t tempCF_OF, newCF, i
        cdef uint32_t bitMaskHalf, dest
        IF COMP_DEBUG:
            self.main.notice("Opcodes::rclFunc: RCL: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
        bitMaskHalf = BITMASKS_80[operSize]
        dest = self.modRMInstance.modRMLoadUnsigned(operSize)
        count = count&0x1f
        if (operSize == OP_SIZE_BYTE):
            count %= 9
        elif (operSize == OP_SIZE_WORD):
            count %= 17
        if (not count):
            return True
        newCF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        for i in range(count):
            tempCF_OF = (dest&bitMaskHalf)!=0
            dest = ((dest<<1)|newCF)
            if (operSize == OP_SIZE_WORD):
                dest = <uint16_t>dest
            newCF = tempCF_OF
        self.modRMInstance.modRMSave(operSize, dest, OPCODE_SAVE)
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = newCF
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = tempCF_OF
        return True
    cdef int rcrFunc(self, uint8_t operSize, uint8_t count) except BITMASK_BYTE_CONST:
        cdef uint8_t tempCF_OF, newCF, i
        cdef uint32_t bitMaskHalf, dest
        IF COMP_DEBUG:
            self.main.notice("Opcodes::rcrFunc: RCR: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
        bitMaskHalf = BITMASKS_80[operSize]
        dest = self.modRMInstance.modRMLoadUnsigned(operSize)
        count = count&0x1f
        newCF = self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf
        if (operSize == OP_SIZE_BYTE):
            count %= 9
        elif (operSize == OP_SIZE_WORD):
            count %= 17
        if (not count):
            return True
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = tempCF_OF
        for i in range(count):
            tempCF_OF = (dest&1)
            dest = (dest >> 1) | (newCF * bitMaskHalf)
            newCF = tempCF_OF
        self.modRMInstance.modRMSave(operSize, dest, OPCODE_SAVE)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = newCF
        return True
    cdef int rolFunc(self, uint8_t operSize, uint8_t count) except BITMASK_BYTE_CONST:
        cdef uint8_t tempCF_OF, newCF, i
        cdef uint32_t bitMaskHalf, dest
        IF COMP_DEBUG:
            self.main.notice("Opcodes::rolFunc: ROL: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
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
                dest = <uint16_t>dest
        self.modRMInstance.modRMSave(operSize, dest, OPCODE_SAVE)
        newCF = dest&1
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = newCF
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = tempCF_OF
        return True
    cdef int rorFunc(self, uint8_t operSize, uint8_t count) except BITMASK_BYTE_CONST:
        cdef uint8_t tempCF_OF, newCF_M1, i
        cdef uint32_t bitMaskHalf, dest
        IF COMP_DEBUG:
            self.main.notice("Opcodes::rorFunc: ROR: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
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
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = tempCF_OF
        tempCF_OF = (tempCF_OF ^ newCF_M1)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.of = tempCF_OF
        return True
    cdef int opcodeGroup4_RM(self, uint8_t operSize, uint8_t method) except BITMASK_BYTE_CONST:
        cdef uint8_t operOpcodeId, count
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOpcodeId = self.modRMInstance.reg
        if (self.main.debugEnabled):
            self.main.notice("opcodeGroup4_RM: operOpcodeId==%u", operOpcodeId)
        if (method == GROUP4_1):
            count = 1
        elif (method == GROUP4_CL):
            count = self.registers.regs[CPU_REGISTER_CL]._union.word._union.byte.rl
        elif (method == GROUP4_IMM8):
            count = self.registers.getCurrentOpcodeAddUnsignedByte()
        else:
            self.main.exitError("opcodeGroup4_RM: method %u is unknown.", method)
            return True
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
            self.main.notice("opcodeGroup4_RM: invalid operOpcodeId. %u", operOpcodeId)
            raise HirnwichseException(CPU_EXCEPTION_UD)
        return True
    cdef int sahf(self) except BITMASK_BYTE_CONST:
        cdef uint16_t flagsVal
        flagsVal = self.registers.readFlags()&0xff00
        flagsVal |= self.registers.regs[CPU_REGISTER_AH]._union.word._union.byte.rh & (FLAG_SF | FLAG_ZF | FLAG_AF | FLAG_PF | FLAG_CF)
        self.registers.regWriteWord(CPU_REGISTER_FLAGS, flagsVal)
        return True
    cdef int lahf(self) nogil:
        cdef uint8_t flagsVal
        flagsVal = self.registers.readFlags() & (FLAG_SF | FLAG_ZF | FLAG_AF | FLAG_PF | FLAG_REQUIRED | FLAG_CF)
        self.registers.regs[CPU_REGISTER_AH]._union.word._union.byte.rh = flagsVal
        return True
    cdef int xchgFuncRegWord(self, uint16_t regName, uint16_t regName2) nogil:
        cdef uint16_t regValue, regValue2
        regValue, regValue2 = self.registers.regs[regName]._union.word._union.rx, self.registers.regs[regName2]._union.word._union.rx
        self.registers.regs[regName]._union.word._union.rx = regValue2
        self.registers.regs[regName2]._union.word._union.rx = regValue
        return True
    cdef int xchgFuncRegDword(self, uint16_t regName, uint16_t regName2) nogil:
        cdef uint32_t regValue, regValue2
        regValue, regValue2 = self.registers.regs[regName]._union.dword.erx, self.registers.regs[regName2]._union.dword.erx
        self.registers.regs[regName]._union.dword.erx = regValue2
        self.registers.regs[regName2]._union.dword.erx = regValue
        return True
    ##### DON'T USE XCHG AX, AX FOR OPCODE 0x90, use NOP instead!!
    cdef int xchgReg(self) nogil:
        if (self.cpu.operSize == OP_SIZE_WORD):
            self.xchgFuncRegWord(CPU_REGISTER_AX, self.cpu.opcode&7)
        elif (self.cpu.operSize == OP_SIZE_DWORD):
            self.xchgFuncRegDword(CPU_REGISTER_AX, self.cpu.opcode&7)
        return True
    cdef int xchgR_RM(self, uint8_t operSize) except BITMASK_BYTE_CONST:
        cdef uint32_t op1, op2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.modRMInstance.modRLoadUnsigned(operSize)
        op2 = self.modRMInstance.modRMLoadUnsigned(operSize)
        self.modRMInstance.modRMSave(operSize, op1, OPCODE_SAVE)
        self.modRMInstance.modRSave(operSize, op2, OPCODE_SAVE)
        return True
    cdef int enter(self) except BITMASK_BYTE_CONST:
        cdef uint8_t stackAddrSize, nestingLevel, i
        cdef int16_t sizeOp
        cdef uint32_t frameTemp, temp
        #self.main.debugEnabled = True
        stackAddrSize = (<Segment>self.registers.segments.ss).gdtEntry.segSize
        sizeOp = <int16_t>self.registers.getCurrentOpcodeAddUnsignedWord()
        nestingLevel = self.registers.getCurrentOpcodeAddUnsignedByte()
        nestingLevel &= 0x1f
        if (nestingLevel and self.main.debugEnabled):
            self.main.notice("Opcodes::enter: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
            self.cpu.cpuDump()
            self.main.notice("Opcodes::enter: test1: sizeOp==0x%04x; nestingLevel==%u!", sizeOp, nestingLevel)
        self.stackPushRegId(CPU_REGISTER_BP, stackAddrSize)
        if (stackAddrSize == OP_SIZE_WORD):
            frameTemp = self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx
            if (nestingLevel > 0):
                if (nestingLevel > 1):
                    for i in range(nestingLevel-2):
                        self.registers.regs[CPU_REGISTER_BP]._union.word._union.rx = self.registers.regs[CPU_REGISTER_BP]._union.word._union.rx-self.cpu.operSize
                        temp = self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_BP]._union.word._union.rx, self.cpu.operSize, &self.registers.segments.ss, False)
                        self.stackPushValue(temp, self.cpu.operSize, False)
                self.stackPushValue(frameTemp, self.cpu.operSize, False)
            self.registers.regs[CPU_REGISTER_BP]._union.word._union.rx = frameTemp
            self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx = self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx-sizeOp
        elif (stackAddrSize == OP_SIZE_DWORD):
            frameTemp = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx
            if (nestingLevel > 0):
                if (nestingLevel > 1):
                    for i in range(nestingLevel-2):
                        self.registers.regs[CPU_REGISTER_EBP]._union.dword.erx = self.registers.regs[CPU_REGISTER_EBP]._union.dword.erx-self.cpu.operSize
                        temp = self.registers.mmReadValueUnsigned(self.registers.regs[CPU_REGISTER_EBP]._union.dword.erx, self.cpu.operSize, &self.registers.segments.ss, False)
                        self.stackPushValue(temp, self.cpu.operSize, False)
                self.stackPushValue(frameTemp, self.cpu.operSize, False)
            self.registers.regs[CPU_REGISTER_EBP]._union.dword.erx = frameTemp
            self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx = self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx-sizeOp
        return True
    cdef int leave(self) except BITMASK_BYTE_CONST:
        cdef uint8_t stackAddrSize
        #self.main.debugEnabled = True
        #self.main.notice("Opcodes::leave: TODO! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
        #self.cpu.cpuDump()
        stackAddrSize = (<Segment>self.registers.segments.ss).gdtEntry.segSize
        if (stackAddrSize == OP_SIZE_WORD):
            self.registers.regs[CPU_REGISTER_SP]._union.word._union.rx = self.registers.regs[CPU_REGISTER_BP]._union.word._union.rx
        elif (stackAddrSize == OP_SIZE_DWORD):
            self.registers.regs[CPU_REGISTER_ESP]._union.dword.erx = self.registers.regs[CPU_REGISTER_EBP]._union.dword.erx
        self.stackPopRegId(CPU_REGISTER_EBP, self.cpu.operSize)
        #self.main.notice("Opcodes::leave: end of function")
        return True
    cdef int setWithCondFunc(self, uint8_t cond) except BITMASK_BYTE_CONST: # if cond==True set 1, else 0
        self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
        self.modRMInstance.modRMSave(OP_SIZE_BYTE, cond, OPCODE_SAVE)
        return True
    cdef int arpl(self) except BITMASK_BYTE_CONST:
        cdef uint16_t op1, op2
        #self.main.notice("Opcodes::arpl: TODO!")
        if (not (self.registers.protectedModeOn and not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm)):
            #self.main.notice("Opcodes::arpl: called while not being in the protected mode. raising UD!")
            #self.cpu.cpuDump()
            raise HirnwichseException(CPU_EXCEPTION_UD)
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
        op1 = self.modRMInstance.modRMLoadUnsigned(OP_SIZE_WORD)
        op2 = self.modRMInstance.modRLoadUnsigned(OP_SIZE_WORD)
        if ((op1&3) < (op2&3)):
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = True
            self.modRMInstance.modRMSave(OP_SIZE_WORD, (op1&0xfffc)|(op2&3), OPCODE_SAVE)
        else:
            self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = False
        return True
    cdef int bound(self) except BITMASK_BYTE_CONST:
        cdef uint32_t returnInt
        cdef int32_t index, lowerBound, upperBound
        self.main.notice("Opcodes::bound: TODO!")
        self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
        if (self.modRMInstance.mod == 3):
            raise HirnwichseException(CPU_EXCEPTION_UD)
        index = self.modRMInstance.modRLoadSigned(self.cpu.operSize)
        returnInt = self.modRMInstance.getRMValueFull(self.cpu.addrSize)
        if (self.cpu.operSize == OP_SIZE_WORD):
            lowerBound = <int16_t>self.registers.mmReadValueUnsignedWord(returnInt, self.modRMInstance.rmNameSeg, True)
            upperBound = <int16_t>self.registers.mmReadValueUnsignedWord(returnInt+self.cpu.operSize, self.modRMInstance.rmNameSeg, True)+self.cpu.operSize
        else:
            lowerBound = <int32_t>self.registers.mmReadValueUnsignedDword(returnInt, self.modRMInstance.rmNameSeg, True)
            upperBound = <int32_t>self.registers.mmReadValueUnsignedDword(returnInt+self.cpu.operSize, self.modRMInstance.rmNameSeg, True)+self.cpu.operSize
        if (index < lowerBound or index > upperBound):
            self.main.notice("bound_test1: index: 0x%04x, lowerBound: 0x%04x, upperBound: 0x%04x", index, lowerBound, upperBound)
            raise HirnwichseException(CPU_EXCEPTION_BR)
        return True
    cdef int btFunc(self, uint8_t newValType) except BITMASK_BYTE_CONST:
        cdef uint8_t state
        cdef uint32_t value, address = 0, offset
        if ((newValType & BT_IMM) != 0):
            newValType &= ~BT_IMM
            offset = self.registers.getCurrentOpcodeAddUnsignedByte()
        else:
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            offset = self.modRMInstance.modRLoadUnsigned(self.cpu.operSize)
        if (self.modRMInstance.mod == 3): # register operand
            offset &= (self.cpu.operSize << 3) - 1 # operSizeInBits - 1
            value = self.modRMInstance.modRMLoadUnsigned(self.cpu.operSize)
            state = (value >> offset)&1
        else: # memory operand
            #self.main.notice("ATTENTION: this could be a WRONG IMPLEMENTATION of btFunc!!! (savedEip: 0x%08x, savedCs: 0x%04x)", self.cpu.savedEip, self.cpu.savedCs)
            #self.cpu.cpuDump() # dump before
            #self.main.notice("test1.1: rmName0==%u, rmName1==%u, rmName2==0x%08x, segId==%u, segmentIndex==%u, ss==%u, regSize==%u", self.modRMInstance.rmName0, self.modRMInstance.rmName1, self.modRMInstance.rmName2, (<Segment>self.modRMInstance.rmNameSeg[0]).segId, (<Segment>self.modRMInstance.rmNameSeg[0]).segmentIndex, self.modRMInstance.ss, self.modRMInstance.regSize)
            ##### TODO!!!!!!!!!
            address = self.modRMInstance.getRMValueFull(self.cpu.addrSize)
            #self.main.notice("test1.2: address==0x%08x, offset==0x%08x, opcode==0x%02x", address, offset, self.cpu.opcode)
            if (self.cpu.operSize == OP_SIZE_WORD):
                address += <int16_t>(offset >> 3)
            elif (self.cpu.operSize == OP_SIZE_DWORD):
                address += <int32_t>(offset >> 3)
            offset &= 7
            #self.main.notice("test1.3: address==0x%08x, offset==0x%08x", address, offset)
            value = self.registers.mmReadValueUnsigned(address, OP_SIZE_BYTE, self.modRMInstance.rmNameSeg, True)
            state = (value >> offset)&1
            #self.main.notice("btFunc: test1.1: address==0x%08x; offset==%u; value==0x%02x; state==%u; segId==%u", address, offset, value, state, (<Segment>self.modRMInstance.rmNameSeg[0]).segId)
        self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = state
        if (newValType != BT_NONE):
            if (newValType == BT_COMPLEMENT):
                state = not state
            elif (newValType == BT_RESET):
                state = False
            elif (newValType == BT_SET):
                state = True
            else:
                self.main.exitError("btFunc: unknown newValType: %u", newValType)
            if (state):
                value |= <uint32_t>(1 << offset)
            else:
                value &= <uint32_t>(~(1 << offset))
            if (self.modRMInstance.mod == 3): # register operand
                self.modRMInstance.modRMSave(self.cpu.operSize, value, OPCODE_SAVE)
            else: # memory operands
                self.registers.mmWriteValue(address, value, OP_SIZE_BYTE, self.modRMInstance.rmNameSeg, True)
                #self.main.notice("btFunc: test1.2: address==0x%08x; offset==%u; value==0x%02x; state==%u; segId==%u", address, offset, value, state, (<Segment>self.modRMInstance.rmNameSeg[0]).segId)
                #self.cpu.cpuDump() # dump after
        #elif (self.modRMInstance.mod != 3): # memory operands
        #    self.cpu.cpuDump() # dump after
        return True
    cdef int fwait(self) except BITMASK_BYTE_CONST:
        cdef uint8_t val
        self.main.notice("Opcodes::fwait: FPU: WAIT/FWAIT: TODO!")
        if (self.registers.getFlagDword(CPU_REGISTER_CR0, (CR0_FLAG_MP | CR0_FLAG_TS)) ==  (CR0_FLAG_MP | CR0_FLAG_TS)):
            raise HirnwichseException(CPU_EXCEPTION_NM)
        #raise HirnwichseException(CPU_EXCEPTION_UD) # TODO
        val = (self.registers.fpu.status & 0x3f)
        val &= ~(self.registers.fpu.ctrl & 0x3f)
        if (val):
            self.registers.fpu.status |= (1 << FPU_EXCEPTION_ES)
        val = (self.registers.fpu.status >> FPU_EXCEPTION_ES) & 1
        if (val):
            val = (self.registers.fpu.status & 0x3f)
            val &= ~(self.registers.fpu.ctrl & 0x3f)
            if (val):
                if (self.registers.getFlagDword(CPU_REGISTER_CR0, CR0_FLAG_NE) != 0):
                    raise HirnwichseException(CPU_EXCEPTION_MF)
                else:
                    (<Pic>self.main.platform.pic).raiseIrq(FPU_IRQ)
        return True
    cdef int fpuFcomHelper(self, object data, uint8_t popRegs, uint8_t regFlags) except BITMASK_BYTE_CONST:
        cdef uint8_t i
        cdef object st0
        st0 = self.registers.fpu.getVal(0)
        self.registers.fpu.setC(1, False)
        if (st0 > data):
            if (not regFlags):
                self.registers.fpu.setC(3, False)
                self.registers.fpu.setC(2, False)
                self.registers.fpu.setC(0, False)
            else:
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = False
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf = False
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = False
        elif (st0 < data):
            if (not regFlags):
                self.registers.fpu.setC(3, False)
                self.registers.fpu.setC(2, False)
                self.registers.fpu.setC(0, True)
            else:
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = False
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf = False
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = True
        elif (not gmpy2.is_regular(st0) or not gmpy2.is_regular(data)): # TODO: QNaN
            self.registers.fpu.setExc(FPU_EXCEPTION_IM, True)
            if (self.registers.fpu.ctrl & 1):
                if (not regFlags):
                    self.registers.fpu.setC(3, True)
                    self.registers.fpu.setC(2, True)
                    self.registers.fpu.setC(0, True)
                else:
                    self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = True
                    self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf = True
                    self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = True
        else:
            if (not regFlags):
                self.registers.fpu.setC(3, True)
                self.registers.fpu.setC(2, False)
                self.registers.fpu.setC(0, False)
            else:
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf = True
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf = False
                self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf = False
        for i in range(popRegs):
            self.registers.fpu.pop()
        return True
    cdef int fpuOpcodes(self, uint8_t opcode) except BITMASK_BYTE_CONST:
        cdef uint8_t opcode2, reg, i, j, divZero = False
        cdef uint32_t dataAddr, baseAddr
        cdef int64_t signedInt = 0
        cdef uint64_t tempVal
        cdef double data = 0.0
        cdef object data2, data3 = None
        opcode2 = self.registers.getCurrentOpcodeUnsignedByte()
        reg = (opcode2 >> 3) & 7
        self.main.notice("Opcodes::fpuOpcodes: FPU Opcodes: TODO! (opcode==0x%02x; opcode2==0x%02x; savedEip: 0x%08x, savedCs: 0x%04x)", FPU_BASE_OPCODE+opcode, opcode2, self.cpu.savedEip, self.cpu.savedCs)
        #if (not self.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_OSFXSR)): # TODO
        #    raise HirnwichseException(CPU_EXCEPTION_UD)
        if (self.registers.getFlagDword(CPU_REGISTER_CR0, (CR0_FLAG_EM | CR0_FLAG_TS)) != 0):
            raise HirnwichseException(CPU_EXCEPTION_NM)
        if (not (opcode == 7 and opcode2 in (0xe0,0xe2)) and not (opcode == 1 and reg in (5,7) and opcode2 not in \
          (0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff)) and not (opcode == 5 and reg == 7)):
            self.registers.fpu.setPointers((opcode << 8) | opcode2)
        if (opcode == 1 and opcode2 == 0x00): # FNOP
            pass
        elif (opcode == 1 and ((opcode2 & 0xf8) == 0xc8)): # FXCH
            i = opcode2&0x7
            data3 = self.registers.fpu.getVal(0)
            self.registers.fpu.setVal(0, self.registers.fpu.getVal(i), False)
            self.registers.fpu.setVal(i, data3, False)
            self.registers.fpu.setC(1, False)
        elif (opcode == 1 and opcode2 == 0xe0): # FCHS
            self.registers.fpu.setVal(0, -(self.registers.fpu.getVal(0)), False)
            self.registers.fpu.setC(1, False)
        elif (opcode == 1 and opcode2 == 0xe1): # FABS
            self.registers.fpu.setVal(0, abs(self.registers.fpu.getVal(0)), False)
            self.registers.fpu.setC(1, False)
        elif (opcode == 1 and opcode2 == 0xe4): # FTST
            self.fpuFcomHelper(gmpy2.mpfr(0.0), 0, True)
        elif (opcode == 1 and opcode2 == 0xe5): # FXAM
            self.main.exitError("Opcodes::fpuOpcodes: TODO: FXAM: opcode==0x%02x, opcode2==0x%02x", FPU_BASE_OPCODE+opcode, opcode2)
            return True
        elif (opcode == 1 and opcode2 == 0xe8): # FLD1
            self.registers.fpu.push(1, False)
        elif (opcode == 1 and opcode2 == 0xe9): # FLDL2T
            self.registers.fpu.push(gmpy2.log2(10), False)
        elif (opcode == 1 and opcode2 == 0xea): # FLDL2E
            self.registers.fpu.push(1/gmpy2.log(2), False)
        elif (opcode == 1 and opcode2 == 0xeb): # FLDPI
            self.registers.fpu.push(gmpy2.const_pi(), False)
        elif (opcode == 1 and opcode2 == 0xec): # FLDLG2
            self.registers.fpu.push(gmpy2.log10(2), False)
        elif (opcode == 1 and opcode2 == 0xed): # FLDLN2
            self.registers.fpu.push(gmpy2.log(2), False)
        elif (opcode == 1 and opcode2 == 0xee): # FLDZ
            self.registers.fpu.push(0, False)
        elif (opcode == 1 and opcode2 == 0xf0): # F2XM1
            self.registers.fpu.setVal(0, (2**self.registers.fpu.getVal(0))-1, True)
        elif (opcode == 1 and opcode2 == 0xf1): # FYL2X
            self.registers.fpu.setVal(1, self.registers.fpu.getVal(1)*gmpy2.log2(self.registers.fpu.getVal(0)), True)
            self.registers.fpu.pop()
        elif (opcode == 1 and opcode2 == 0xf2): # FPTAN
            self.registers.fpu.setVal(0, gmpy2.tan(self.registers.fpu.getVal(0)), True)
            self.registers.fpu.push(1, False)
            self.registers.fpu.setC(2, False)
        elif (opcode == 1 and opcode2 == 0xf3): # FPATAN
            self.registers.fpu.setVal(1, gmpy2.atan(self.registers.fpu.getVal(1)/self.registers.fpu.getVal(0)), True)
            self.registers.fpu.pop()
        elif (opcode == 1 and opcode2 == 0xf4): # FXTRACT
            self.main.exitError("Opcodes::fpuOpcodes: TODO: FXTRACT: opcode==0x%02x, opcode2==0x%02x", FPU_BASE_OPCODE+opcode, opcode2)
            return True
        elif (opcode == 1 and opcode2 == 0xf6): # FDECSTP
            self.registers.fpu.addTop(-1)
            self.registers.fpu.setC(1, False)
        elif (opcode == 1 and opcode2 == 0xf7): # FINCSTP
            self.registers.fpu.addTop(1)
            self.registers.fpu.setC(1, False)
        elif (opcode == 1 and opcode2 in (0xf5, 0xf8)): # FPREM1/FPREM ; TODO
            if (opcode == 0xf5):
                data3, data2 = gmpy2.remquo(self.registers.fpu.getVal(0), self.registers.fpu.getVal(1))
                data2 = gmpy2.mpfr(data2)
            else:
                data2, data3 = gmpy2.t_divmod(self.registers.fpu.getVal(0), self.registers.fpu.getVal(1))
            self.registers.fpu.setVal(0, data3, False)
            self.registers.fpu.setC(2, False)
            self.registers.fpu.setC(0, gmpy2.bit_test(data2, 2))
            self.registers.fpu.setC(3, gmpy2.bit_test(data2, 1))
            self.registers.fpu.setC(1, gmpy2.bit_test(data2, 0))
        elif (opcode == 1 and opcode2 == 0xf9): # FYL2XP1
            self.registers.fpu.setVal(1, self.registers.fpu.getVal(1)*gmpy2.log2(self.registers.fpu.getVal(0)+1), True)
            self.registers.fpu.pop()
        elif (opcode == 1 and opcode2 == 0xfa): # FSQRT
            self.registers.fpu.setVal(0, gmpy2.sqrt(self.registers.fpu.getVal(0)), True)
        elif (opcode == 1 and opcode2 == 0xfb): # FSINCOS ; TODO
            self.registers.fpu.setC(2, False)
            data2 = gmpy2.cos(self.registers.fpu.getVal(0))
            self.registers.fpu.setVal(0, gmpy2.sin(self.registers.fpu.getVal(0)), True)
            self.registers.fpu.push(data2, True)
        elif (opcode == 1 and opcode2 == 0xfc): # FRNDINT
            self.registers.fpu.setVal(0, gmpy2.rint(self.registers.fpu.getVal(0)), True)
        elif (opcode == 1 and opcode2 == 0xfd): # FSCALE
            self.registers.fpu.setVal(0, gmpy2.rint(self.registers.fpu.getVal(0))*(2**gmpy2.rint(self.registers.fpu.getVal(1))), True)
        elif (opcode == 1 and opcode2 == 0xfe): # FSIN
            self.registers.fpu.setVal(0, gmpy2.sin(self.registers.fpu.getVal(0)), True)
            self.registers.fpu.setC(2, False)
        elif (opcode == 1 and opcode2 == 0xff): # FCOS
            self.registers.fpu.setVal(0, gmpy2.cos(self.registers.fpu.getVal(0)), True)
            self.registers.fpu.setC(2, False)
        elif (opcode == 1 and ((opcode2 & 0xf8) == 0xc0)): # FLD ST(i)
            i = opcode2&0x7
            self.registers.fpu.push(self.registers.fpu.getVal(i), False)
        elif (opcode == 2 and ((opcode2 & 0xf8) == 0xc0)): # FCMOVB
            if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf):
                self.registers.fpu.setVal(0, abs(self.registers.fpu.getVal(opcode2&0x7)), False)
        elif (opcode == 2 and ((opcode2 & 0xf8) == 0xc8)): # FCMOVE
            if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf):
                self.registers.fpu.setVal(0, abs(self.registers.fpu.getVal(opcode2&0x7)), False)
        elif (opcode == 2 and ((opcode2 & 0xf8) == 0xd0)): # FCMOVBE
            if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf or self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf):
                self.registers.fpu.setVal(0, abs(self.registers.fpu.getVal(opcode2&0x7)), False)
        elif (opcode == 2 and ((opcode2 & 0xf8) == 0xd8)): # FCMOVU
            if (self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf):
                self.registers.fpu.setVal(0, abs(self.registers.fpu.getVal(opcode2&0x7)), False)
        elif (opcode == 3 and ((opcode2 & 0xf8) == 0xc0)): # FCMOVNB
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf):
                self.registers.fpu.setVal(0, abs(self.registers.fpu.getVal(opcode2&0x7)), False)
        elif (opcode == 3 and ((opcode2 & 0xf8) == 0xc8)): # FCMOVNE
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf):
                self.registers.fpu.setVal(0, abs(self.registers.fpu.getVal(opcode2&0x7)), False)
        elif (opcode == 3 and ((opcode2 & 0xf8) == 0xd0)): # FCMOVNBE
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.cf and not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.zf):
                self.registers.fpu.setVal(0, abs(self.registers.fpu.getVal(opcode2&0x7)), False)
        elif (opcode == 3 and ((opcode2 & 0xf8) == 0xd8)): # FCMOVNU
            if (not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.pf):
                self.registers.fpu.setVal(0, abs(self.registers.fpu.getVal(opcode2&0x7)), False)
        elif (opcode == 3 and opcode2 == 0xe4): # FNSETPM
            pass
        elif (opcode in (3,7) and (opcode2 >= 0xe8 and opcode2 <= 0xf7)): # FCOMI/FCOMIP/FUCOMI/FUCOMIP
            i = opcode2&0x7
            data2 = self.registers.fpu.getVal(i)
            if (opcode == 7):
                i = 1
            else:
                i = 0
            self.fpuFcomHelper(data2, i, True)
        elif (opcode == 3 and opcode2 == 0xe2): # FNCLEX
            self.registers.fpu.status &= 0x7f00
        elif (opcode == 3 and opcode2 == 0xe3): # FNINIT
            self.registers.fpu.reset(True)
        elif (opcode == 5 and ((opcode2 & 0xf8) == 0xc0)): # FFREE
            self.setTag(self.getIndex(opcode2&0x7), 3)
        elif (opcode == 5 and ((opcode2 & 0xf0) == 0xd0)): # FST(P)
            i = opcode2&0x7
            self.registers.fpu.setVal(i, self.registers.fpu.getVal(0), True)
            if (opcode2 & 8):
                self.registers.fpu.pop()
        elif ((opcode == 5 and ((opcode2 & 0xf0) == 0xe0)) or (opcode == 2 and opcode2 == 0xe9)): # FUCOM(P)
            i = opcode2&0x7
            data2 = self.registers.fpu.getVal(i)
            if (opcode == 2):
                i = 2
            elif (opcode2 & 8):
                i = 1
            else:
                i = 0
            self.fpuFcomHelper(data2, i, False)
        elif ((opcode == 0 and ((opcode2 & 0xf0) == 0xd0)) or (opcode == 6 and opcode2 == 0xd9)): # FCOM/FCOMP/FCOMPP
            i = opcode2&0x7
            data2 = self.registers.fpu.getVal(i)
            if (opcode == 6):
                i = 2
            elif (opcode2 & 8):
                i = 1
            else:
                i = 0
            self.fpuFcomHelper(data2, i, False)
        elif (opcode in (0, 4, 6) and (((opcode2 & 0xf0) == 0xc0) or ((opcode2 & 0xe0) == 0xe0))): # FADD/FADDP/FMUL/FMULP/...
            i = opcode2&0x7
            if ((opcode2 & 0xf8) == 0xc0):
                if (opcode in (0,6)):
                    #self.main.notice("FADDPb tempIndex==%u", self.registers.fpu.getIndex(0))
                    #self.main.notice("FADDPb data2==%s", repr(self.registers.fpu.getVal(i)))
                    #self.main.notice("FADDPb data3==%s", repr(self.registers.fpu.getVal(0)))
                    data3 = self.registers.fpu.getVal(i)+self.registers.fpu.getVal(0)
                    #self.main.notice("FADDPa data3==%s", repr(data3))
                else:
                    data3 = self.registers.fpu.getVal(0)+self.registers.fpu.getVal(i)
            elif ((opcode2 & 0xf8) == 0xc8):
                if (opcode in (4,6)):
                    data3 = self.registers.fpu.getVal(i)*self.registers.fpu.getVal(0)
                else:
                    data3 = self.registers.fpu.getVal(0)*self.registers.fpu.getVal(i)
            elif ((opcode2 & 0xf8) == 0xe0):
                data3 = self.registers.fpu.getVal(0)-self.registers.fpu.getVal(i)
            elif ((opcode2 & 0xf8) == 0xe8):
                data3 = self.registers.fpu.getVal(i)-self.registers.fpu.getVal(0)
            elif ((opcode2 & 0xf0) == 0xf0):
                if (not (opcode2 & 0x8)): # 0xf0 .. 0xf7
                    data2 = self.registers.fpu.getVal(0)
                    data3 = self.registers.fpu.getVal(i)
                else:
                    data2 = self.registers.fpu.getVal(i)
                    data3 = self.registers.fpu.getVal(0)
                if (not data3):
                    divZero = True
                data3 = data2/data3
            if (divZero and (self.registers.fpu.ctrl & 4) == 0):
                self.registers.fpu.status |= (1 << FPU_EXCEPTION_ES)
            elif (opcode == 0):
                self.registers.fpu.setVal(0, data3, True)
            elif (opcode in (4,6)):
                self.registers.fpu.setVal(i, data3, True)
            if (opcode == 6):
                self.registers.fpu.pop()
            if (divZero):
                self.registers.fpu.status |= 4
        elif (opcode == 7 and opcode2 == 0xe0): # FNSTSW ax
            self.registers.regs[CPU_REGISTER_AX]._union.word._union.rx = self.registers.fpu.status
        else:
            self.modRMInstance.modRMOperands(self.cpu.operSize, MODRM_FLAGS_NONE)
            dataAddr = self.modRMInstance.getRMValueFull(self.cpu.addrSize)
            if (opcode == 1 and reg == 5): # FLDCW
                self.registers.fpu.setCtrl(self.registers.mmReadValueUnsignedWord(dataAddr, self.modRMInstance.rmNameSeg, True))
            elif (opcode == 1 and reg == 7): # FNSTCW
                self.registers.mmWriteValue(dataAddr, self.registers.fpu.ctrl, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
            elif (opcode == 5 and reg == 7): # FNSTSW rm
                self.registers.mmWriteValue(dataAddr, self.registers.fpu.status, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
            elif (opcode in (0,2,4,6) or (opcode == 7 and reg in (2,3,5,7)) or (opcode == 1 and reg in (0,2,3,4,6)) or (opcode == 3 and reg in (0,2,3,7)) or (opcode == 5 and reg in (0,2,3,4,6))):
                self.registers.fpu.setDataPointers((<Segment>self.modRMInstance.rmNameSeg[0]).segmentIndex, dataAddr)
                if (opcode in (0,2,4,6)):
                    if (opcode == 0): # fp32
                        tempVal = self.registers.mmReadValueUnsignedDword(dataAddr, self.modRMInstance.rmNameSeg, True)
                        data = (<float*>&tempVal)[0]
                    elif (opcode == 2): # int32
                        signedInt = <int32_t>self.registers.mmReadValueUnsignedDword(dataAddr, self.modRMInstance.rmNameSeg, True)
                    elif (opcode == 4): # fp64
                        tempVal = self.registers.mmReadValueUnsignedQword(dataAddr, self.modRMInstance.rmNameSeg, True)
                        data = (<double*>&tempVal)[0]
                    elif (opcode == 6): # int16
                        signedInt = <int16_t>self.registers.mmReadValueUnsignedWord(dataAddr, self.modRMInstance.rmNameSeg, True)
                    if (opcode in (0, 4)):
                        data3 = gmpy2.mpfr(data)
                    else:
                        data3 = gmpy2.mpfr(signedInt)
                    data2 = self.registers.fpu.getVal(0)
                    if (reg == 0): # FADD
                        data3 = data2+data3
                    elif (reg == 1): # FMUL
                        #self.main.notice("FMULb data2==%s", repr(data2))
                        #self.main.notice("FMULb data3==%s", repr(data3))
                        data3 = data2*data3
                        #self.main.notice("FMULa data3==%s", repr(data3))
                    elif (reg in (2, 3)): # FCOM/FCOMP
                        self.fpuFcomHelper(data3, 1 if (reg == 3) else 0, False)
                    elif (reg in (4,5)): # FSUB/FSUBR
                        if (reg == 4):
                            data3 = data2-data3
                        else:
                            #self.main.notice("FSUBRb tempVal==%s", repr(tempVal))
                            #self.main.notice("FSUBRb data2==%s", repr(data2))
                            #self.main.notice("FSUBRb data3==%s", repr(data3))
                            data3 = data3-data2
                            #self.main.notice("FSUBRa data3==%s", repr(data3))
                    elif (reg in (6,7)): # FDIV/FDIVR/FIDIVR
                        if (reg == 6):
                            if (not data3):
                                divZero = True
                            data3 = data2/data3
                        else:
                            if (not data2):
                                divZero = True
                            data3 = data3/data2
                    if (divZero and (self.registers.fpu.ctrl & 4) == 0):
                        self.registers.fpu.status |= (1 << FPU_EXCEPTION_ES)
                    elif (reg not in (2, 3)):
                        self.registers.fpu.setVal(0, data3, True)
                    if (divZero):
                        self.registers.fpu.status |= 4
                elif (opcode == 7):
                    if (reg in (2, 3)): # FIST(P) m16int
                        data2 = gmpy2.rint(self.registers.fpu.getVal(0))
                        self.registers.mmWriteValue(dataAddr, struct.unpack(">H", struct.pack(">h", int(data2)))[0], OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                        if (reg == 3):
                            self.registers.fpu.pop()
                    elif (reg in (5,)): # FILD
                        signedInt = <int64_t>self.registers.mmReadValueUnsignedQword(dataAddr, self.modRMInstance.rmNameSeg, True)
                        data2 = gmpy2.mpfr(signedInt)
                        #self.main.notice("Opcodes::fpuOpcodes: TODO: test13: op1==%s", repr(data2))
                        self.registers.fpu.push(data2, False)
                    elif (reg == 7): # FISTP m64int
                        data2 = gmpy2.rint(self.registers.fpu.getVal(0))
                        self.registers.mmWriteValue(dataAddr, struct.unpack(">Q", struct.pack(">q", int(data2)))[0], OP_SIZE_QWORD, self.modRMInstance.rmNameSeg, True)
                        self.registers.fpu.pop()
                    else:
                        self.main.exitError("Opcodes::fpuOpcodes: TODO: test14: opcode==0x%02x, opcode2==0x%02x", FPU_BASE_OPCODE+opcode, opcode2)
                elif (opcode == 3):
                    if (reg in (0,2,3,7)):
                        if (reg == 0): # FILD
                            signedInt = <int32_t>self.registers.mmReadValueUnsignedDword(dataAddr, self.modRMInstance.rmNameSeg, True)
                            data2 = gmpy2.mpfr(signedInt)
                            #self.main.notice("Opcodes::fpuOpcodes: TODO: test12: op1==%s", repr(data2))
                            self.registers.fpu.push(data2, False)
                        elif  (reg == 7): # FSTP
                            self.main.notice("Opcodes::fpuOpcodes: TODO: test16: opcode==0x%02x, opcode2==0x%02x", FPU_BASE_OPCODE+opcode, opcode2)
                            baseAddr = self.registers.mmGetRealAddr(dataAddr, 8, self.modRMInstance.rmNameSeg, True, True, False)
                            self.main.mm.mmPhyWrite(baseAddr, self.registers.fpu.st[self.registers.fpu.getIndex(0)], OP_SIZE_QWORD)
                            self.registers.fpu.pop()
                        else: # FIST/FISTP
                            data2 = gmpy2.rint(self.registers.fpu.getVal(0))
                            self.registers.mmWriteValue(dataAddr, struct.unpack(">I", struct.pack(">i", int(data2)))[0], OP_SIZE_DWORD, self.modRMInstance.rmNameSeg, True)
                            if (reg == 3):
                                self.registers.fpu.pop()
                    else:
                        self.main.exitError("Opcodes::fpuOpcodes: TODO: test8: opcode==0x%02x, opcode2==0x%02x", FPU_BASE_OPCODE+opcode, opcode2)
                else:
                    if (opcode == 1 and reg not in (4,6)):
                        if  (reg == 0): # FLD
                            tempVal = self.registers.mmReadValueUnsignedDword(dataAddr, self.modRMInstance.rmNameSeg, True)
                            data = (<float*>&tempVal)[0]
                            data2 = gmpy2.mpfr(data)
                            self.registers.fpu.push(data2, False)
                        elif  (reg in (2,3)): # FST/FSTP
                            data2 = self.registers.fpu.getVal(0)
                            self.registers.mmWriteValue(dataAddr, struct.unpack(">I", struct.pack(">f", data2))[0], OP_SIZE_DWORD, self.modRMInstance.rmNameSeg, True)
                            if  (reg == 3): # FSTP
                                self.registers.fpu.pop()
                        else:
                            self.main.exitError("Opcodes::fpuOpcodes: TODO: test9: opcode==0x%02x, opcode2==0x%02x", FPU_BASE_OPCODE+opcode, opcode2)
                    elif (opcode == 5 or (opcode == 1 and reg in (4,6))):
                        tempVal = self.registers.mmReadValueUnsignedQword(dataAddr, self.modRMInstance.rmNameSeg, True)
                        if  (reg == 0): # FLD
                            data = (<double*>&tempVal)[0]
                            data2 = gmpy2.mpfr(data)
                            self.registers.fpu.push(data2, False)
                        elif  (reg in (2,3)): # FST/FSTP
                            data2 = self.registers.fpu.getVal(0)
                            if ((opcode2 & 0xf0) == 0xd0):
                                opcode2 &= 7
                                self.registers.fpu.setVal(opcode2, data2, True)
                            else:
                                self.registers.mmWriteValue(dataAddr, struct.unpack(">Q", struct.pack(">d", data2))[0], OP_SIZE_QWORD, self.modRMInstance.rmNameSeg, True)
                            if (reg == 3): # FSTP
                                self.registers.fpu.pop()
                        elif  (reg == 4): # FRSTOR/FLDENV
                            self.registers.fpu.ctrl = self.registers.mmReadValueUnsignedWord(dataAddr, self.modRMInstance.rmNameSeg, True)
                            if (self.cpu.operSize == OP_SIZE_WORD):
                                self.registers.fpu.status = self.registers.mmReadValueUnsignedWord(dataAddr+2, self.modRMInstance.rmNameSeg, True)
                                self.registers.fpu.tag = self.registers.mmReadValueUnsignedWord(dataAddr+4, self.modRMInstance.rmNameSeg, True)
                                self.registers.fpu.instPointer = self.registers.mmReadValueUnsignedWord(dataAddr+6, self.modRMInstance.rmNameSeg, True)
                            else:
                                self.registers.fpu.status = self.registers.mmReadValueUnsignedWord(dataAddr+4, self.modRMInstance.rmNameSeg, True)
                                self.registers.fpu.tag = self.registers.mmReadValueUnsignedWord(dataAddr+8, self.modRMInstance.rmNameSeg, True)
                            if (self.registers.protectedModeOn and not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
                                if (self.cpu.operSize == OP_SIZE_WORD):
                                    self.registers.fpu.instSeg = self.registers.mmReadValueUnsignedWord(dataAddr+8, self.modRMInstance.rmNameSeg, True)
                                    self.registers.fpu.dataPointer = self.registers.mmReadValueUnsignedWord(dataAddr+10, self.modRMInstance.rmNameSeg, True)
                                    self.registers.fpu.dataSeg = self.registers.mmReadValueUnsignedWord(dataAddr+12, self.modRMInstance.rmNameSeg, True)
                                else:
                                    self.registers.fpu.instPointer = self.registers.mmReadValueUnsignedDword(dataAddr+12, self.modRMInstance.rmNameSeg, True)
                                    tempVal = self.registers.mmReadValueUnsignedDword(dataAddr+16, self.modRMInstance.rmNameSeg, True)
                                    self.registers.fpu.instSeg = <uint16_t>tempVal
                                    self.registers.fpu.opcode = (tempVal>>16)&0x3f
                                    self.registers.fpu.dataPointer = self.registers.mmReadValueUnsignedDword(dataAddr+20, self.modRMInstance.rmNameSeg, True)
                                    self.registers.fpu.dataSeg = self.registers.mmReadValueUnsignedWord(dataAddr+24, self.modRMInstance.rmNameSeg, True)
                            else:
                                if (self.cpu.operSize == OP_SIZE_WORD):
                                    tempVal = self.registers.mmReadValueUnsignedWord(dataAddr+8, self.modRMInstance.rmNameSeg, True)
                                    self.registers.fpu.opcode = tempVal&0x3f
                                    self.registers.fpu.instPointer |= (tempVal>>12)<<16
                                    self.registers.fpu.dataPointer = self.registers.mmReadValueUnsignedWord(dataAddr+10, self.modRMInstance.rmNameSeg, True)
                                    tempVal = self.registers.mmReadValueUnsignedWord(dataAddr+12, self.modRMInstance.rmNameSeg, True)
                                    self.registers.fpu.dataPointer |= (tempVal>>12)<<16
                                else:
                                    self.registers.fpu.instPointer = self.registers.mmReadValueUnsignedWord(dataAddr+12, self.modRMInstance.rmNameSeg, True)
                                    tempVal = self.registers.mmReadValueUnsignedDword(dataAddr+16, self.modRMInstance.rmNameSeg, True)
                                    self.registers.fpu.opcode = tempVal&0x3f
                                    self.registers.fpu.instPointer |= (tempVal>>12)<<16
                                    self.registers.fpu.dataPointer = self.registers.mmReadValueUnsignedWord(dataAddr+20, self.modRMInstance.rmNameSeg, True)
                                    tempVal = self.registers.mmReadValueUnsignedDword(dataAddr+24, self.modRMInstance.rmNameSeg, True)
                                    self.registers.fpu.dataPointer |= (tempVal>>12)<<16
                            if (self.cpu.operSize == OP_SIZE_DWORD and opcode != 1):
                                baseAddr = self.registers.mmGetRealAddr(dataAddr+28, 1, self.modRMInstance.rmNameSeg, True, False, False)
                                if (((baseAddr&0xfff)+80) > 0xfff):
                                    self.main.exitError("Opcodes::fpuOpcodes: baseAddr_1 is over page boundary!")
                                    return True
                                for i in range(8):
                                    data2 = []
                                    for j in range(10):
                                        data2.append(self.main.mm.mmPhyReadValueUnsignedByte(baseAddr+(i*10)+j))
                                    self.registers.fpu.st[i] = bytes(data2)
                            self.fwait()
                        elif  (reg == 6): # FNSAVE
                            self.registers.mmWriteValue(dataAddr, self.registers.fpu.ctrl, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                            if (self.cpu.operSize == OP_SIZE_WORD):
                                self.registers.mmWriteValue(dataAddr+2, self.registers.fpu.status, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                                self.registers.mmWriteValue(dataAddr+4, self.registers.fpu.tag, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                                self.registers.mmWriteValue(dataAddr+6, <uint16_t>self.registers.fpu.instPointer, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                            else:
                                self.registers.mmWriteValue(dataAddr+4, self.registers.fpu.status, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                                self.registers.mmWriteValue(dataAddr+8, self.registers.fpu.tag, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                            if (self.registers.protectedModeOn and not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
                                if (self.cpu.operSize == OP_SIZE_WORD):
                                    self.registers.mmWriteValue(dataAddr+8, self.registers.fpu.instSeg, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                                    self.registers.mmWriteValue(dataAddr+10, <uint16_t>self.registers.fpu.dataPointer, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                                    self.registers.mmWriteValue(dataAddr+12, self.registers.fpu.dataSeg, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                                else:
                                    self.registers.mmWriteValue(dataAddr+12, self.registers.fpu.instPointer, OP_SIZE_DWORD, self.modRMInstance.rmNameSeg, True)
                                    self.registers.mmWriteValue(dataAddr+16, (self.registers.fpu.opcode<<16)|self.registers.fpu.instSeg, OP_SIZE_DWORD, self.modRMInstance.rmNameSeg, True)
                                    self.registers.mmWriteValue(dataAddr+20, self.registers.fpu.dataPointer, OP_SIZE_DWORD, self.modRMInstance.rmNameSeg, True)
                                    self.registers.mmWriteValue(dataAddr+24, self.registers.fpu.dataSeg, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                            else:
                                if (self.cpu.operSize == OP_SIZE_WORD):
                                    self.registers.mmWriteValue(dataAddr+8, (((self.registers.fpu.instPointer>>16)&0xf)<<12)|self.registers.fpu.opcode, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                                    self.registers.mmWriteValue(dataAddr+10, <uint16_t>self.registers.fpu.dataPointer, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                                    self.registers.mmWriteValue(dataAddr+12, (((self.registers.fpu.dataPointer>>16)&0xf)<<12), OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                                else:
                                    self.registers.mmWriteValue(dataAddr+12, <uint16_t>self.registers.fpu.instPointer, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                                    self.registers.mmWriteValue(dataAddr+16, ((self.registers.fpu.instPointer>>16)<<12)|self.registers.fpu.opcode, OP_SIZE_DWORD, self.modRMInstance.rmNameSeg, True)
                                    self.registers.mmWriteValue(dataAddr+20, <uint16_t>self.registers.fpu.dataPointer, OP_SIZE_WORD, self.modRMInstance.rmNameSeg, True)
                                    self.registers.mmWriteValue(dataAddr+24, ((self.registers.fpu.dataPointer>>16)<<12), OP_SIZE_DWORD, self.modRMInstance.rmNameSeg, True)
                            if (self.cpu.operSize == OP_SIZE_DWORD and opcode != 1):
                                baseAddr = self.registers.mmGetRealAddr(dataAddr+28, 1, self.modRMInstance.rmNameSeg, True, True, False)
                                if (((baseAddr&0xfff)+80) > 0xfff):
                                    self.main.exitError("Opcodes::fpuOpcodes: baseAddr_2 is over page boundary!")
                                    return True
                                self.main.mm.mmPhyWrite(baseAddr, b"".join(self.registers.fpu.st), 80)
                            self.registers.fpu.reset(True)
                        else:
                            self.main.exitError("Opcodes::fpuOpcodes: TODO: test7: opcode==0x%02x, opcode2==0x%02x", FPU_BASE_OPCODE+opcode, opcode2)
                    else:
                        self.main.exitError("Opcodes::fpuOpcodes: TODO: test2: opcode==0x%02x, opcode2==0x%02x", FPU_BASE_OPCODE+opcode, opcode2)
            else:
                self.main.exitError("Opcodes::fpuOpcodes: TODO: test1: opcode==0x%02x, opcode2==0x%02x", FPU_BASE_OPCODE+opcode, opcode2)
            return True
        self.registers.getCurrentOpcodeAddUnsignedByte()
        #raise HirnwichseException(CPU_EXCEPTION_UD)
        return True
    cdef void run(self):
        self.modRMInstance = ModRMClass(self.registers)
    # end of opcodes



