
from misc import ChemuException
from sys import exc_info


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
    cdef unsigned char executeOpcode(self, unsigned char opcode):
        try:
            if (opcode == 0x00):
                self.opcodeRM_R(OPCODE_ADD, OP_SIZE_BYTE)
            elif (opcode == 0x01):
                self.opcodeRM_R(OPCODE_ADD, self.registers.operSize)
            elif (opcode == 0x02):
                self.opcodeR_RM(OPCODE_ADD, OP_SIZE_BYTE)
            elif (opcode == 0x03):
                self.opcodeR_RM(OPCODE_ADD, self.registers.operSize)
            elif (opcode == 0x04):
                self.opcodeAxEaxImm(OPCODE_ADD, OP_SIZE_BYTE)
            elif (opcode == 0x05):
                self.opcodeAxEaxImm(OPCODE_ADD, self.registers.operSize)
            elif (opcode == 0x06):
                self.pushSeg(PUSH_ES)
            elif (opcode == 0x07):
                self.popSeg(POP_ES)
            elif (opcode == 0x08):
                self.opcodeRM_R(OPCODE_OR, OP_SIZE_BYTE)
            elif (opcode == 0x09):
                self.opcodeRM_R(OPCODE_OR, self.registers.operSize)
            elif (opcode == 0x0a):
                self.opcodeR_RM(OPCODE_OR, OP_SIZE_BYTE)
            elif (opcode == 0x0b):
                self.opcodeR_RM(OPCODE_OR, self.registers.operSize)
            elif (opcode == 0x0c):
                self.opcodeAxEaxImm(OPCODE_OR, OP_SIZE_BYTE)
            elif (opcode == 0x0d):
                self.opcodeAxEaxImm(OPCODE_OR, self.registers.operSize)
            elif (opcode == 0x0e):
                self.pushSeg(PUSH_CS)
            elif (opcode == 0x0f):
                self.opcodeGroup0F()
            elif (opcode == 0x10):
                self.opcodeRM_R(OPCODE_ADC, OP_SIZE_BYTE)
            elif (opcode == 0x11):
                self.opcodeRM_R(OPCODE_ADC, self.registers.operSize)
            elif (opcode == 0x12):
                self.opcodeR_RM(OPCODE_ADC, OP_SIZE_BYTE)
            elif (opcode == 0x13):
                self.opcodeR_RM(OPCODE_ADC, self.registers.operSize)
            elif (opcode == 0x14):
                self.opcodeAxEaxImm(OPCODE_ADC, OP_SIZE_BYTE)
            elif (opcode == 0x15):
                self.opcodeAxEaxImm(OPCODE_ADC, self.registers.operSize)
            elif (opcode == 0x16):
                self.pushSeg(PUSH_SS)
            elif (opcode == 0x17):
                self.popSeg(POP_SS)
            elif (opcode == 0x18):
                self.opcodeRM_R(OPCODE_SBB, OP_SIZE_BYTE)
            elif (opcode == 0x19):
                self.opcodeRM_R(OPCODE_SBB, self.registers.operSize)
            elif (opcode == 0x1a):
                self.opcodeR_RM(OPCODE_SBB, OP_SIZE_BYTE)
            elif (opcode == 0x1b):
                self.opcodeR_RM(OPCODE_SBB, self.registers.operSize)
            elif (opcode == 0x1c):
                self.opcodeAxEaxImm(OPCODE_SBB, OP_SIZE_BYTE)
            elif (opcode == 0x1d):
                self.opcodeAxEaxImm(OPCODE_SBB, self.registers.operSize)
            elif (opcode == 0x1e):
                self.pushSeg(PUSH_DS)
            elif (opcode == 0x1f):
                self.popSeg(POP_DS)
            elif (opcode == 0x20):
                self.opcodeRM_R(OPCODE_AND, OP_SIZE_BYTE)
            elif (opcode == 0x21):
                self.opcodeRM_R(OPCODE_AND, self.registers.operSize)
            elif (opcode == 0x22):
                self.opcodeR_RM(OPCODE_AND, OP_SIZE_BYTE)
            elif (opcode == 0x23):
                self.opcodeR_RM(OPCODE_AND, self.registers.operSize)
            elif (opcode == 0x24):
                self.opcodeAxEaxImm(OPCODE_AND, OP_SIZE_BYTE)
            elif (opcode == 0x25):
                self.opcodeAxEaxImm(OPCODE_AND, self.registers.operSize)
            elif (opcode == 0x27):
                self.daa()
            elif (opcode == 0x28):
                self.opcodeRM_R(OPCODE_SUB, OP_SIZE_BYTE)
            elif (opcode == 0x29):
                self.opcodeRM_R(OPCODE_SUB, self.registers.operSize)
            elif (opcode == 0x2a):
                self.opcodeR_RM(OPCODE_SUB, OP_SIZE_BYTE)
            elif (opcode == 0x2b):
                self.opcodeR_RM(OPCODE_SUB, self.registers.operSize)
            elif (opcode == 0x2c):
                self.opcodeAxEaxImm(OPCODE_SUB, OP_SIZE_BYTE)
            elif (opcode == 0x2d):
                self.opcodeAxEaxImm(OPCODE_SUB, self.registers.operSize)
            elif (opcode == 0x2f):
                self.das()
            elif (opcode == 0x30):
                self.opcodeRM_R(OPCODE_XOR, OP_SIZE_BYTE)
            elif (opcode == 0x31):
                self.opcodeRM_R(OPCODE_XOR, self.registers.operSize)
            elif (opcode == 0x32):
                self.opcodeR_RM(OPCODE_XOR, OP_SIZE_BYTE)
            elif (opcode == 0x33):
                self.opcodeR_RM(OPCODE_XOR, self.registers.operSize)
            elif (opcode == 0x34):
                self.opcodeAxEaxImm(OPCODE_XOR, OP_SIZE_BYTE)
            elif (opcode == 0x35):
                self.opcodeAxEaxImm(OPCODE_XOR, self.registers.operSize)
            elif (opcode == 0x37):
                self.aaa()
            elif (opcode == 0x38):
                self.opcodeRM_R(OPCODE_CMP, OP_SIZE_BYTE)
            elif (opcode == 0x39):
                self.opcodeRM_R(OPCODE_CMP, self.registers.operSize)
            elif (opcode == 0x3a):
                self.opcodeR_RM(OPCODE_CMP, OP_SIZE_BYTE)
            elif (opcode == 0x3b):
                self.opcodeR_RM(OPCODE_CMP, self.registers.operSize)
            elif (opcode == 0x3c):
                self.opcodeAxEaxImm(OPCODE_CMP, OP_SIZE_BYTE)
            elif (opcode == 0x3d):
                self.opcodeAxEaxImm(OPCODE_CMP, self.registers.operSize)
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
                self.insFunc(self.registers.operSize)
            elif (opcode == 0x6e):
                self.outsFunc(OP_SIZE_BYTE)
            elif (opcode == 0x6f):
                self.outsFunc(self.registers.operSize)
            elif (opcode >= 0x70 and opcode <= 0x7f):
                self.jumpShort(OP_SIZE_BYTE, self.registers.getCond(opcode&0xf))
            elif (opcode == 0x80):
                self.opcodeGroup1_RM_ImmFunc(OP_SIZE_BYTE, True)
            elif (opcode == 0x81):
                self.opcodeGroup1_RM_ImmFunc(self.registers.operSize, False)
            elif (opcode == 0x83):
                self.opcodeGroup1_RM_ImmFunc(self.registers.operSize, True)
            elif (opcode == 0x84):
                self.opcodeRM_R(OPCODE_TEST, OP_SIZE_BYTE)
            elif (opcode == 0x85):
                self.opcodeRM_R(OPCODE_TEST, self.registers.operSize)
            elif (opcode == 0x86):
                self.xchgR_RM(OP_SIZE_BYTE)
            elif (opcode == 0x87):
                self.xchgR_RM(self.registers.operSize)
            elif (opcode == 0x88):
                self.movRM_R(OP_SIZE_BYTE)
            elif (opcode == 0x89):
                self.movRM_R(self.registers.operSize)
            elif (opcode == 0x8a):
                self.movR_RM(OP_SIZE_BYTE, True)
            elif (opcode == 0x8b):
                self.movR_RM(self.registers.operSize, True)
            elif (opcode == 0x8c):
                self.movRM16_SREG()
            elif (opcode == 0x8d):
                self.lea()
            elif (opcode == 0x8e):
                self.movSREG_RM16()
            elif (opcode == 0x8f):
                self.popRM16_32()
            elif (opcode == 0x90):
                pass # TODO: maybe implement PAUSE-Opcode (F3 90 / REPE NOP)
            elif (opcode >= 0x91 and opcode <= 0x97):
                self.xchgReg()
            elif (opcode == 0x98):
                self.cbw_cwde()
            elif (opcode == 0x99):
                self.cwd_cdq()
            elif (opcode == 0x9a):
                self.callPtr16_32()
            elif (opcode == 0x9b): # WAIT/FWAIT
                if (self.registers.getFlag(CPU_REGISTER_CR0, (CR0_FLAG_MP | \
                  CR0_FLAG_TS)) ==  (CR0_FLAG_MP | CR0_FLAG_TS)):
                    raise ChemuException(CPU_EXCEPTION_NM)
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (opcode == 0x9c):
                self.pushfWD()
            elif (opcode == 0x9d):
                self.popfWD()
            elif (opcode == 0x9e):
                self.sahf()
            elif (opcode == 0x9f):
                self.lahf()
            elif (opcode >= 0xa0 and opcode <= 0xa3):
                if (opcode == 0xa0):
                    self.movAxMoffs(OP_SIZE_BYTE)
                elif (opcode == 0xa1):
                    self.movAxMoffs(self.registers.operSize)
                elif (opcode == 0xa2):
                    self.movMoffsAx(OP_SIZE_BYTE)
                elif (opcode == 0xa3):
                    self.movMoffsAx(self.registers.operSize)
            elif (opcode == 0xa4):
                self.movsFunc(OP_SIZE_BYTE)
            elif (opcode == 0xa5):
                self.movsFunc(self.registers.operSize)
            elif (opcode == 0xa6):
                self.cmpsFunc(OP_SIZE_BYTE)
            elif (opcode == 0xa7):
                self.cmpsFunc(self.registers.operSize)
            elif (opcode == 0xa8):
                self.opcodeAxEaxImm(OPCODE_TEST, OP_SIZE_BYTE)
            elif (opcode == 0xa9):
                self.opcodeAxEaxImm(OPCODE_TEST, self.registers.operSize)
            elif (opcode == 0xaa):
                self.stosFunc(OP_SIZE_BYTE)
            elif (opcode == 0xab):
                self.stosFunc(self.registers.operSize)
            elif (opcode == 0xac):
                self.lodsFunc(OP_SIZE_BYTE)
            elif (opcode == 0xad):
                self.lodsFunc(self.registers.operSize)
            elif (opcode == 0xae):
                self.scasFunc(OP_SIZE_BYTE)
            elif (opcode == 0xaf):
                self.scasFunc(self.registers.operSize)
            elif (opcode >= 0xb0 and opcode <= 0xb7):
                self.movImmToR(OP_SIZE_BYTE)
            elif (opcode >= 0xb8 and opcode <= 0xbf):
                self.movImmToR(self.registers.operSize)
            elif (opcode == 0xc0):
                self.opcodeGroup4_RM_IMM8(OP_SIZE_BYTE)
            elif (opcode == 0xc1):
                self.opcodeGroup4_RM_IMM8(self.registers.operSize)
            elif (opcode == 0xc2):
                self.retNearImm()
            elif (opcode == 0xc3):
                self.retNear(0)
            elif (opcode == 0xc4):
                self.lfpFunc(CPU_SEGMENT_ES) # LES
            elif (opcode == 0xc5):
                self.lfpFunc(CPU_SEGMENT_DS) # LDS
            elif (opcode == 0xc6):
                self.opcodeGroup3_RM_ImmFunc(OP_SIZE_BYTE)
            elif (opcode == 0xc7):
                self.opcodeGroup3_RM_ImmFunc(self.registers.operSize)
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
                self.interrupt(-1, -1)
            elif (opcode == 0xce):
                self.into()
            elif (opcode == 0xcf):
                self.iret()
            elif (opcode == 0xd0):
                self.opcodeGroup4_RM_1(OP_SIZE_BYTE)
            elif (opcode == 0xd1):
                self.opcodeGroup4_RM_1(self.registers.operSize)
            elif (opcode == 0xd2):
                self.opcodeGroup4_RM_CL(OP_SIZE_BYTE)
            elif (opcode == 0xd3):
                self.opcodeGroup4_RM_CL(self.registers.operSize)
            elif (opcode == 0xd4):
                self.aam()
            elif (opcode == 0xd5):
                self.aad()
            elif (opcode == 0xd6):
                self.undefNoUD()
            elif (opcode == 0xd7):
                self.xlatb()
            elif (opcode >= 0xd8 and opcode <= 0xdf):
                if (self.registers.getFlag(CPU_REGISTER_CR4, CR4_FLAG_OSFXSR) == 0):
                    raise ChemuException(CPU_EXCEPTION_UD)
                if (self.registers.getFlag(CPU_REGISTER_CR0, (CR0_FLAG_EM | CR0_FLAG_TS)) != 0):
                    raise ChemuException(CPU_EXCEPTION_NM)
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (opcode == 0xe0):
                self.loopFunc(OPCODE_LOOPNE)
            elif (opcode == 0xe1):
                self.loopFunc(OPCODE_LOOPE)
            elif (opcode == 0xe2):
                self.loopFunc(OPCODE_LOOP)
            elif (opcode == 0xe3):
                self.jcxzShort()
            elif (opcode == 0xe4):
                self.inAxImm8(OP_SIZE_BYTE)
            elif (opcode == 0xe5):
                self.inAxImm8(self.registers.operSize)
            elif (opcode == 0xe6):
                self.outImm8Ax(OP_SIZE_BYTE)
            elif (opcode == 0xe7):
                self.outImm8Ax(self.registers.operSize)
            elif (opcode == 0xe8):
                self.callNearRel16_32()
            elif (opcode == 0xe9):
                self.jumpShort(self.registers.operSize, True)
            elif (opcode == 0xea):
                self.jumpFarAbsolutePtr()
            elif (opcode == 0xeb):
                self.jumpShort(OP_SIZE_BYTE, True)
            elif (opcode == 0xec):
                self.inAxDx(OP_SIZE_BYTE)
            elif (opcode == 0xed):
                self.inAxDx(self.registers.operSize)
            elif (opcode == 0xee):
                self.outDxAx(OP_SIZE_BYTE)
            elif (opcode == 0xef):
                self.outDxAx(self.registers.operSize)
            elif (opcode == 0xf1):
                self.undefNoUD()
            elif (opcode == 0xf4):
                self.hlt()
            elif (opcode == 0xf5):
                self.cmc()
            elif (opcode == 0xf6):
                self.opcodeGroup2_RM(OP_SIZE_BYTE)
            elif (opcode == 0xf7):
                self.opcodeGroup2_RM(self.registers.operSize)
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
                self.main.printMsg("handler for opcode {0:#06x} wasn't found.", opcode)
                return False # if opcode wasn't found.
            return True  # if opcode was found.
        except ChemuException as exception: # exception
            try:
                self.main.cpu.handleException(exception) # execute exception handler
                return True
            except ChemuException as exception: # DF double fault
                try:
                    raise ChemuException(CPU_EXCEPTION_DF, 0) # exec DF double fault
                except ChemuException as exception:
                    try:
                        self.main.cpu.handleException(exception) # handle DF double fault
                        return True
                    except ChemuException as exception: # DF double fault failed! triple fault... reset!
                        if (self.main.exitOnTripleFault):
                            self.main.exitError("CPU::doCycle: TRIPLE FAULT! exit.", exitNow=True)
                        else:
                            self.main.printMsg("CPU::doCycle: TRIPLE FAULT! reset.")
                            self.main.cpu.reset()
                            return True
        except (SystemExit, KeyboardInterrupt):
            print(exc_info())
            self.main.quitEmu = True
            self.main.exitError('Opcodes::executeOpcode: (SystemExit, KeyboardInterrupt) exception while handling opcode, exiting... (opcode: {0:#04x})', opcode, exitNow=True)
        except:
            print(exc_info())
            self.main.exitError('Opcodes::executeOpcode: (else case) exception while handling opcode, exiting... (opcode: {0:#04x})', opcode, exitNow=True)
        return False
    cdef undefNoUD(self):
        pass
    cdef cli(self):
        self.registers.setEFLAG(FLAG_IF, False)
    cdef sti(self):
        self.registers.setEFLAG(FLAG_IF, True)
        self.main.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
    cdef cld(self):
        self.registers.setEFLAG(FLAG_DF, False)
    cdef std(self):
        self.registers.setEFLAG(FLAG_DF, True)
    cdef clc(self):
        self.registers.setEFLAG(FLAG_CF, False)
    cdef stc(self):
        self.registers.setEFLAG(FLAG_CF, True)
    cdef cmc(self):
        self.registers.setEFLAG(FLAG_CF, self.registers.getEFLAG(FLAG_CF)==0)
    cdef hlt(self):
        self.main.cpu.cpuHalted = True
    cdef syncProtectedModeState(self):
        (<Segments>self.registers.segments).protectedModeOn = self.registers.getFlag(CPU_REGISTER_CR0, CR0_FLAG_PE)
        if ((<Segments>self.registers.segments).protectedModeOn):
            (<Gdt>self.registers.segments.gdt).loadTableData()
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if ((<Segments>self.registers.segments).isInProtectedMode()):
            if (self.cpl > self.iopl):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
        return self.main.platform.inPort(ioPortAddr, dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
        if ((<Segments>self.registers.segments).isInProtectedMode()):
            if (self.cpl > self.iopl):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
        self.main.platform.outPort(ioPortAddr, data, dataSize)
    cdef jumpFarAbsolutePtr(self):
        cdef unsigned short cs
        cdef unsigned long eip
        eip = self.registers.getCurrentOpcodeAdd(self.registers.operSize, False)
        cs = self.registers.getCurrentOpcodeAdd(OP_SIZE_WORD, False)
        self.syncProtectedModeState()
        self.registers.regWrite(CPU_REGISTER_EIP, eip)
        self.registers.segWrite(CPU_SEGMENT_CS, cs)
    cdef loopFunc(self, unsigned char loopType):
        cdef unsigned char cond, oldZF
        cdef unsigned short countReg
        cdef long long countOrNewEip
        cdef char rel8
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, self.registers.addrSize)
        oldZF = self.registers.getEFLAG(FLAG_ZF)!=0
        rel8 = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, True)
        countOrNewEip = self.registers.regSub(countReg, 1)
        cond = countOrNewEip != 0
        if (not cond):
            return
        if (loopType == OPCODE_LOOPE and not oldZF):
            cond = False
        elif (loopType == OPCODE_LOOPNE and oldZF):
            cond = False
        if (cond):
            countOrNewEip = <unsigned long>(self.registers.regRead(self.registers.eipSizeRegId, False)+rel8)
            if (self.registers.operSize == OP_SIZE_WORD):
                countOrNewEip = <unsigned short>countOrNewEip
            self.registers.regWrite(CPU_REGISTER_EIP, countOrNewEip)
    cdef opcodeR_RM(self, unsigned char opcode, unsigned char operSize):
        cdef unsigned long op1, op2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (opcode not in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op1 = self.modRMInstance.modRLoad(operSize, False)
        op2 = self.modRMInstance.modRMLoad(operSize, False, True)
        if (opcode in (OPCODE_ADD, OPCODE_ADC, OPCODE_SUB, OPCODE_SBB)):
            self.modRMInstance.modRSave(operSize, op2, opcode)
            self.registers.setFullFlags(op1, op2, operSize, opcode)
        elif (opcode == OPCODE_CMP):
            self.registers.setFullFlags(op1, op2, operSize, OPCODE_SUB)
        elif (opcode in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op2 = self.modRMInstance.modRSave(operSize, op2, opcode)
            self.registers.setSZP_C0_O0_A0(op2, operSize)
        elif (opcode == OPCODE_TEST):
            self.main.printMsg("OPCODE::opcodeR_RM: OPCODE_TEST HAS NO R_RM!!")
        else:
            self.main.printMsg("OPCODE::opcodeR_RM: invalid opcode: {0:d}.", opcode)
    cdef opcodeRM_R(self, unsigned char opcode, unsigned char operSize):
        cdef unsigned long op1, op2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (opcode not in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op1 = self.modRMInstance.modRMLoad(operSize, False, True)
        op2 = self.modRMInstance.modRLoad(operSize, False)
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
            self.main.printMsg("OPCODE::opcodeRM_R: invalid opcode: {0:d}.", opcode)
    cdef opcodeAxEaxImm(self, unsigned char opcode, unsigned char operSize):
        cdef unsigned short dataReg
        cdef unsigned long op1, op2
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        if (opcode not in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op1 = self.registers.regRead(dataReg, False)
        op2 = self.registers.getCurrentOpcodeAdd(operSize, False)
        if (opcode in (OPCODE_ADD, OPCODE_ADC, OPCODE_SUB, OPCODE_SBB)):
            self.registers.regWriteWithOp(dataReg, op2, opcode)
            self.registers.setFullFlags(op1, op2, operSize, opcode)
        elif (opcode == OPCODE_CMP):
            self.registers.setFullFlags(op1, op2, operSize, OPCODE_SUB)
        elif (opcode in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op2 = self.registers.regWriteWithOp(dataReg, op2, opcode)
            self.registers.setSZP_C0_O0_A0(op2, operSize)
        elif (opcode == OPCODE_TEST):
            self.registers.setSZP_C0_O0_A0(op1&op2, operSize)
        else:
            self.main.printMsg("OPCODE::opcodeRM_R: invalid opcode: {0:d}.", opcode)
    cdef movImmToR(self, unsigned char operSize):
        cdef unsigned char rReg
        cdef unsigned long src
        rReg = self.main.cpu.opcode&0x7
        src = self.registers.getCurrentOpcodeAdd(operSize, False)
        if (operSize == OP_SIZE_BYTE):
            self.registers.regWrite(CPU_REGISTER_BYTE[rReg], src)
        elif (operSize == OP_SIZE_WORD):
            self.registers.regWrite(CPU_REGISTER_WORD[rReg], src)
        elif (operSize == OP_SIZE_DWORD):
            self.registers.regWrite(CPU_REGISTER_DWORD[rReg], src)
        else:
            self.main.printMsg("OPCODE::movImmToR: unknown operSize: {0:d}.", operSize)
    cdef movRM_R(self, unsigned char operSize):
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        self.modRMInstance.modRMSave(operSize, self.modRMInstance.modRLoad(operSize, False), True, OPCODE_SAVE)
    cdef movR_RM(self, unsigned char operSize, unsigned char cond):
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (cond):
            self.modRMInstance.modRSave(operSize, self.modRMInstance.modRMLoad(operSize, False, True), OPCODE_SAVE)
    cdef movRM16_SREG(self):
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        self.modRMInstance.modRMSave(OP_SIZE_WORD, self.registers.segRead(self.modRMInstance.regName), True, OPCODE_SAVE)
    cdef movSREG_RM16(self):
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        if (self.modRMInstance.regName == CPU_SEGMENT_CS):
            raise ChemuException(CPU_EXCEPTION_UD)
        self.registers.segWrite(self.modRMInstance.regName, self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True))
    cdef movAxMoffs(self, unsigned char operSize):
        self.registers.regWrite(self.registers.getWordAsDword(CPU_REGISTER_AX, operSize), \
          self.registers.mmReadValueUnsigned(self.registers.getCurrentOpcodeAdd(self.registers.addrSize, \
          False), operSize, CPU_SEGMENT_DS, True))
    cdef movMoffsAx(self, unsigned char operSize):
        self.registers.mmWriteValue(self.registers.getCurrentOpcodeAdd(self.registers.addrSize, False), \
          self.registers.regRead(self.registers.getWordAsDword(CPU_REGISTER_AX, operSize), False), operSize, CPU_SEGMENT_DS, True)
    cdef stosFunc(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned short dataReg, srcReg, countReg
        cdef unsigned long data, countVal
        cdef unsigned long long dataLength
        cdef long long destAddr
        cdef bytes memData
        srcReg  = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_DI, self.registers.addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, self.registers.addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        dataLength = <unsigned long long>(operSize*countVal)
        if (dataLength != <unsigned long>dataLength):
            self.main.printMsg("Opcodes::stosFunc: dataLength overflow.")
        dataLength = <unsigned long>dataLength
        data = self.registers.regRead(srcReg, False)
        destAddr = self.registers.regRead(dataReg, False)
        if (dfFlag):
            destAddr = <unsigned long>(destAddr-(dataLength-operSize))
        if (self.registers.addrSize == OP_SIZE_WORD):
            destAddr = <unsigned short>destAddr
        memData = data.to_bytes(length=operSize, byteorder="little")*countVal
        self.registers.mmWrite(destAddr, memData, dataLength, CPU_SEGMENT_ES, False)
        if (not dfFlag):
            self.registers.regAdd(dataReg, dataLength)
        else:
            self.registers.regSub(dataReg, dataLength)
        self.main.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite(countReg, 0)
    cdef movsFunc(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned short esiReg, ediReg, countReg
        cdef unsigned long countVal
        cdef unsigned long long dataLength
        cdef long long esiVal, ediVal
        cdef bytes data
        esiReg  = self.registers.getWordAsDword(CPU_REGISTER_SI, self.registers.addrSize)
        ediReg  = self.registers.getWordAsDword(CPU_REGISTER_DI, self.registers.addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, self.registers.addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        dataLength = <unsigned long long>(operSize*countVal)
        if (dataLength != <unsigned long>dataLength):
            self.main.printMsg("Opcodes::movsFunc: dataLength overflow.")
        dataLength = <unsigned long>dataLength
        esiVal = self.registers.regRead(esiReg, False)
        ediVal = self.registers.regRead(ediReg, False)
        if (dfFlag):
            esiVal = <unsigned long>(esiVal-(dataLength-operSize))
            ediVal = <unsigned long>(ediVal-(dataLength-operSize))
        if (self.registers.addrSize == OP_SIZE_WORD):
            esiVal = <unsigned short>esiVal
            ediVal = <unsigned short>ediVal
        data = self.registers.mmRead(esiVal, dataLength, CPU_SEGMENT_DS, True)
        self.registers.mmWrite(ediVal, data, dataLength, CPU_SEGMENT_ES, False)
        if (not dfFlag):
            self.registers.regAdd(esiReg, dataLength)
            self.registers.regAdd(ediReg, dataLength)
        else:
            self.registers.regSub(esiReg, dataLength)
            self.registers.regSub(ediReg, dataLength)
        self.main.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite(countReg, 0)
    cdef lodsFunc(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned short eaxReg, esiReg, countReg
        cdef unsigned long data, countVal
        cdef unsigned long long dataLength
        cdef long long esiVal
        eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        esiReg  = self.registers.getWordAsDword(CPU_REGISTER_SI, self.registers.addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, self.registers.addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        dataLength = <unsigned long long>(operSize*countVal)
        if (dataLength != <unsigned long>dataLength):
            self.main.printMsg("Opcodes::lodsFunc: dataLength overflow.")
        dataLength = <unsigned long>dataLength
        if (not dfFlag):
            esiVal = <unsigned long>(self.registers.regAdd(esiReg, dataLength)-operSize)
        else:
            esiVal = <unsigned long>(self.registers.regSub(esiReg, dataLength)+operSize)
        if (self.registers.addrSize == OP_SIZE_WORD):
            esiVal = <unsigned short>esiVal
        data = self.registers.mmReadValueUnsigned(esiVal, operSize, CPU_SEGMENT_DS, True)
        self.registers.regWrite(eaxReg, data)
        self.main.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite(countReg, 0)
    cdef cmpsFunc(self, unsigned char operSize):
        cdef unsigned char zfFlag, dfFlag
        cdef unsigned short esiReg, ediReg, countReg
        cdef unsigned long esiVal, ediVal, countVal, newCount, src1, src2, i
        esiReg  = self.registers.getWordAsDword(CPU_REGISTER_SI, self.registers.addrSize)
        ediReg  = self.registers.getWordAsDword(CPU_REGISTER_DI, self.registers.addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, self.registers.addrSize)
        countVal, newCount = 1, 0
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        esiVal = self.registers.regRead(esiReg, False)
        ediVal = self.registers.regRead(ediReg, False)
        for i in range(countVal):
            src1 = self.registers.mmReadValueUnsigned(esiVal, operSize, CPU_SEGMENT_DS, True)
            src2 = self.registers.mmReadValueUnsigned(ediVal, operSize, CPU_SEGMENT_ES, False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not dfFlag):
                esiVal = <unsigned long>(esiVal+operSize)
                ediVal = <unsigned long>(ediVal+operSize)
            else:
                esiVal = <unsigned long>(esiVal-operSize)
                ediVal = <unsigned long>(ediVal-operSize)
            if (self.registers.addrSize == OP_SIZE_WORD):
                esiVal = <unsigned short>esiVal
                ediVal = <unsigned short>ediVal
            zfFlag = self.registers.getEFLAG(FLAG_ZF)!=0
            if ((self.registers.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or \
              (self.registers.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                newCount = <unsigned long>(countVal-i-1)
                break
        self.registers.regWrite(esiReg, esiVal)
        self.registers.regWrite(ediReg, ediVal)
        self.main.cpu.cycles += countVal-newCount
        if (self.registers.repPrefix):
            self.registers.regWrite(countReg, newCount)
    cdef scasFunc(self, unsigned char operSize):
        cdef unsigned char zfFlag, dfFlag
        cdef unsigned short eaxReg, ediReg, countReg
        cdef unsigned long src1, src2, ediVal, countVal, newCount, i
        eaxReg  = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        ediReg  = self.registers.getWordAsDword(CPU_REGISTER_DI, self.registers.addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, self.registers.addrSize)
        countVal, newCount = 1, 0
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        for i in range(countVal):
            ediVal = self.registers.regRead(ediReg, False)
            src1 = self.registers.regRead(eaxReg, False)
            src2 = self.registers.mmReadValueUnsigned(ediVal, operSize, CPU_SEGMENT_ES, False)
            self.registers.setFullFlags(src1, src2, operSize, OPCODE_SUB)
            if (not dfFlag):
                ediVal = <unsigned long>(ediVal+operSize)
            else:
                ediVal = <unsigned long>(ediVal-operSize)
            if (self.registers.addrSize == OP_SIZE_WORD):
                ediVal = <unsigned short>ediVal
            zfFlag = self.registers.getEFLAG(FLAG_ZF)!=0
            if ((self.registers.repPrefix == OPCODE_PREFIX_REPE and not zfFlag) or \
              (self.registers.repPrefix == OPCODE_PREFIX_REPNE and zfFlag)):
                newCount = countVal-i-1
                break
        self.registers.regWrite(ediReg, ediVal)
        self.main.cpu.cycles += countVal-newCount
        if (self.registers.repPrefix):
            self.registers.regWrite(countReg, newCount)
    cdef inAxImm8(self, unsigned char operSize):
        cdef unsigned short dataReg
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        self.registers.regWrite(dataReg, self.inPort(self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False), operSize))
    cdef inAxDx(self, unsigned char operSize):
        cdef unsigned short dataReg
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        self.registers.regWrite(dataReg, self.inPort(self.registers.regRead(CPU_REGISTER_DX, False), operSize))
    cdef outImm8Ax(self, unsigned char operSize):
        cdef unsigned short dataReg
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        self.outPort(self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False), self.registers.regRead(dataReg, False), operSize)
    cdef outDxAx(self, unsigned char operSize):
        cdef unsigned short dataReg
        dataReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
        self.outPort(self.registers.regRead(CPU_REGISTER_DX, False), self.registers.regRead(dataReg, False), operSize)
    cdef outsFunc(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned short esiReg, countReg, ioPort
        cdef unsigned long value, esiVal, countVal, i
        esiReg  = self.registers.getWordAsDword(CPU_REGISTER_SI, self.registers.addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, self.registers.addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        esiVal = self.registers.regRead(esiReg, False)
        ioPort = self.registers.regRead(CPU_REGISTER_DX, False)
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        for i in range(countVal):
            value = self.registers.mmReadValueUnsigned(esiVal, operSize, CPU_SEGMENT_DS, True)
            self.outPort(ioPort, value, operSize)
            if (not dfFlag):
                esiVal = <unsigned long>(esiVal+operSize)
            else:
                esiVal = <unsigned long>(esiVal-operSize)
            if (self.registers.addrSize == OP_SIZE_WORD):
                esiVal = <unsigned short>esiVal
        self.registers.regWrite(esiReg, esiVal)
        self.main.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite(countReg, 0)
    cdef insFunc(self, unsigned char operSize):
        cdef unsigned char dfFlag
        cdef unsigned short ediReg, countReg, ioPort
        cdef unsigned long value, ediVal, countVal, i
        ediReg  = self.registers.getWordAsDword(CPU_REGISTER_DI, self.registers.addrSize)
        countReg = self.registers.getWordAsDword(CPU_REGISTER_CX, self.registers.addrSize)
        countVal = 1
        if (self.registers.repPrefix):
            countVal = self.registers.regRead(countReg, False)
            if (countVal == 0):
                return
        dfFlag = self.registers.getEFLAG(FLAG_DF)!=0
        ediVal = self.registers.regRead(ediReg, False)
        ioPort = self.registers.regRead(CPU_REGISTER_DX, False)
        for i in range(countVal):
            value = self.inPort(ioPort, operSize)
            self.registers.mmWriteValue(ediVal, value, operSize, CPU_SEGMENT_ES, False)
            if (not dfFlag):
                ediVal = <unsigned long>(ediVal+operSize)
            else:
                ediVal = <unsigned long>(ediVal-operSize)
            if (self.registers.addrSize == OP_SIZE_WORD):
                ediVal = <unsigned short>ediVal
        self.registers.regWrite(ediReg, ediVal)
        self.main.cpu.cycles += countVal
        if (self.registers.repPrefix):
            self.registers.regWrite(countReg, 0)
    cdef jcxzShort(self):
        cdef unsigned short cxReg
        cdef unsigned long cxVal
        cxReg = self.registers.getWordAsDword(CPU_REGISTER_CX, self.registers.addrSize)
        cxVal = self.registers.regRead(cxReg, False)
        self.jumpShort(OP_SIZE_BYTE, cxVal==0)
    cdef jumpShort(self, unsigned char offsetSize, unsigned char cond):
        cdef long offset
        cdef unsigned long newEip
        offset = self.registers.getCurrentOpcodeAdd(offsetSize, True)
        if (not cond):
            return
        newEip = <unsigned long>(self.registers.regRead(self.registers.eipSizeRegId, False)+offset)
        if (self.registers.operSize == OP_SIZE_WORD):
            newEip = <unsigned short>newEip
        self.registers.regWrite(CPU_REGISTER_EIP, newEip)
    cdef callNearRel16_32(self):
        cdef long offset
        cdef unsigned long newEip
        offset = self.registers.getCurrentOpcodeAdd(self.registers.operSize, True)
        newEip = <unsigned long>(self.registers.regRead(self.registers.eipSizeRegId, False)+offset)
        if (self.registers.operSize == OP_SIZE_WORD):
            newEip = <unsigned short>newEip
        self.stackPushRegId(self.registers.eipSizeRegId, self.registers.operSize)
        self.registers.regWrite(CPU_REGISTER_EIP, newEip)
    cdef callPtr16_32(self):
        cdef unsigned char wasInPM
        cdef unsigned short segVal
        cdef unsigned long eipAddr
        eipAddr = self.registers.getCurrentOpcodeAdd(self.registers.operSize, False)
        segVal = self.registers.getCurrentOpcodeAdd(OP_SIZE_WORD, False)
        wasInPM = (<Segments>self.registers.segments).isInProtectedMode()
        self.syncProtectedModeState()
        if (wasInPM == (<Segments>self.registers.segments).isInProtectedMode()):
            segVal &= 0xfffc
            segVal |= self.registers.cpl&3
        self.stackPushSegId(CPU_SEGMENT_CS, self.registers.operSize)
        self.stackPushRegId(self.registers.eipSizeRegId, self.registers.operSize)
        self.registers.segWrite(CPU_SEGMENT_CS, segVal)
        self.registers.regWrite(CPU_REGISTER_EIP, eipAddr)
    cdef pushaWD(self):
        cdef unsigned short regName
        cdef unsigned long temp
        regName = self.registers.getWordAsDword(CPU_REGISTER_SP, self.registers.operSize)
        temp = self.registers.regRead(regName, False)
        if (not (<Segments>self.registers.segments).isInProtectedMode() and temp in (7, 9, 11, 13, 15)):
            raise ChemuException(CPU_EXCEPTION_GP, 0)
        regName = self.registers.getWordAsDword(CPU_REGISTER_AX, self.registers.operSize)
        self.stackPushRegId(regName, self.registers.operSize)
        regName = self.registers.getWordAsDword(CPU_REGISTER_CX, self.registers.operSize)
        self.stackPushRegId(regName, self.registers.operSize)
        regName = self.registers.getWordAsDword(CPU_REGISTER_DX, self.registers.operSize)
        self.stackPushRegId(regName, self.registers.operSize)
        regName = self.registers.getWordAsDword(CPU_REGISTER_BX, self.registers.operSize)
        self.stackPushRegId(regName, self.registers.operSize)
        self.stackPushValue(temp, self.registers.operSize)
        regName = self.registers.getWordAsDword(CPU_REGISTER_BP, self.registers.operSize)
        self.stackPushRegId(regName, self.registers.operSize)
        regName = self.registers.getWordAsDword(CPU_REGISTER_SI, self.registers.operSize)
        self.stackPushRegId(regName, self.registers.operSize)
        regName = self.registers.getWordAsDword(CPU_REGISTER_DI, self.registers.operSize)
        self.stackPushRegId(regName, self.registers.operSize)
    cdef popaWD(self):
        cdef unsigned short regName
        regName = self.registers.getWordAsDword(CPU_REGISTER_DI, self.registers.operSize)
        self.stackPopRegId(regName)
        regName = self.registers.getWordAsDword(CPU_REGISTER_SI, self.registers.operSize)
        self.stackPopRegId(regName)
        regName = self.registers.getWordAsDword(CPU_REGISTER_BP, self.registers.operSize)
        self.stackPopRegId(regName)
        self.registers.regAdd(CPU_REGISTER_ESP, self.registers.operSize)
        regName = self.registers.getWordAsDword(CPU_REGISTER_BX, self.registers.operSize)
        self.stackPopRegId(regName)
        regName = self.registers.getWordAsDword(CPU_REGISTER_DX, self.registers.operSize)
        self.stackPopRegId(regName)
        regName = self.registers.getWordAsDword(CPU_REGISTER_CX, self.registers.operSize)
        self.stackPopRegId(regName)
        regName = self.registers.getWordAsDword(CPU_REGISTER_AX, self.registers.operSize)
        self.stackPopRegId(regName)
    cdef pushfWD(self):
        cdef unsigned short regNameId
        cdef unsigned long value
        regNameId = self.registers.getWordAsDword(CPU_REGISTER_FLAGS, self.registers.operSize)
        value = self.registers.regRead(regNameId, False)|0x2
        value &= (~FLAG_IOPL) # This is for
        value |= ((self.registers.iopl&3)<<12) # IOPL, Bits 12,13
        if (self.registers.operSize == OP_SIZE_DWORD):
            value &= 0x00FCFFFF
        self.stackPushValue(value, self.registers.operSize)
    cdef popfWD(self):
        cdef unsigned short regNameId
        cdef unsigned long flagValue, oldFlagValue
        regNameId = self.registers.getWordAsDword(CPU_REGISTER_FLAGS, self.registers.operSize)
        oldFlagValue = self.registers.regRead(regNameId, False)
        flagValue = self.stackPopValue()
        flagValue &= ~RESERVED_FLAGS_BITMASK
        flagValue |= FLAG_REQUIRED
        if (self.registers.cpl == 0):
            self.registers.iopl = (flagValue>>12)&3
        else:
            flagValue &= ~(FLAG_IOPL)
            flagValue |= (oldFlagValue & FLAG_IOPL)
            if(self.registers.operSize == OP_SIZE_WORD and self.registers.cpl > self.registers.iopl):
                flagValue &= ~(FLAG_IF)
                flagValue |= (oldFlagValue & FLAG_IF)
        if(self.registers.operSize == OP_SIZE_WORD):
            flagValue = <unsigned short>flagValue
        else:
            flagValue &= ~(FLAG_VIP | FLAG_VIF | FLAG_RF)
        self.registers.regWrite(regNameId, flagValue)
        if (self.registers.getEFLAG(FLAG_VM)!=0):
            self.main.exitError("Opcodes::popfWD: VM86-Mode isn't supported yet.")
    cdef stackPopRM16_32(self):
        cdef unsigned long value
        value = self.stackPopValue()
        self.modRMInstance.modRMSave(self.registers.operSize, value, True, OPCODE_SAVE)
    cdef stackPopSegId(self, unsigned short segId):
        self.registers.segWrite(segId, <unsigned short>(self.stackPopValue()))
    cdef stackPopRegId(self, unsigned short regId):
        cdef unsigned long value
        value = self.stackPopValue()
        if (self.registers.getRegSize(regId) == OP_SIZE_WORD):
            value = <unsigned short>value
        self.registers.regWrite(regId, value)
    cdef unsigned long stackPopValue(self):
        cdef unsigned char stackAddrSize
        cdef unsigned short stackRegName
        cdef unsigned long data
        stackAddrSize = self.registers.getAddrSegSize(CPU_SEGMENT_SS)
        stackRegName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        data = self.stackGetValue()
        self.registers.regAdd(stackRegName, self.registers.operSize)
        return data
    cdef unsigned long stackGetValue(self):
        cdef unsigned char stackAddrSize
        cdef unsigned short stackRegName
        cdef unsigned long stackAddr
        stackAddrSize = self.registers.getAddrSegSize(CPU_SEGMENT_SS)
        stackRegName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        stackAddr = self.registers.regRead(stackRegName, False)
        return self.registers.mmReadValueUnsigned(stackAddr, self.registers.operSize, CPU_SEGMENT_SS, False)
    cdef stackPushSegId(self, unsigned short segId, unsigned char operSize):
        self.stackPushValue(self.registers.segRead(segId), operSize)
    cdef stackPushRegId(self, unsigned short regId, unsigned char operSize):
        cdef unsigned long value
        value = self.registers.regRead(regId, False)
        self.stackPushValue(value, operSize)
    cdef stackPushValue(self, unsigned long value, unsigned char operSize):
        cdef unsigned char stackAddrSize
        cdef unsigned short stackRegName
        cdef unsigned long stackAddr
        stackAddrSize = self.registers.getAddrSegSize(CPU_SEGMENT_SS)
        stackRegName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        stackAddr = self.registers.regRead(stackRegName, False)
        if ((<Segments>self.registers.segments).isInProtectedMode() and stackAddr < operSize):
            raise ChemuException(CPU_EXCEPTION_SS, 0)
        stackAddr = <unsigned long>(stackAddr-operSize)
        if (stackAddrSize == OP_SIZE_WORD):
            stackAddr = <unsigned short>stackAddr
        self.registers.regWrite(stackRegName, stackAddr)
        if (operSize == OP_SIZE_WORD):
            value = <unsigned short>value
        self.registers.mmWriteValue(stackAddr, value, operSize, CPU_SEGMENT_SS, False)
    cdef pushIMM(self, unsigned char immIsByte):
        cdef unsigned long value
        if (immIsByte):
            value = <unsigned long>(self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, True))
        else:
            value = self.registers.getCurrentOpcodeAdd(self.registers.operSize, False)
        if (self.registers.operSize == OP_SIZE_WORD):
            value = <unsigned short>value
        self.stackPushValue(value, self.registers.operSize)
    cdef imulR_RM_ImmFunc(self, unsigned char immIsByte):
        cdef long operOp1
        cdef long long operOp2
        cdef unsigned long operSum, bitMask
        cdef unsigned long long temp
        bitMask = (<Misc>self.main.misc).getBitMaskFF(self.registers.operSize)
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        operOp1 = self.modRMInstance.modRMLoad(self.registers.operSize, True, True)
        if (immIsByte):
            operOp2 = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, True)
            operOp2 &= bitMask
        else:
            operOp2 = self.registers.getCurrentOpcodeAdd(self.registers.operSize, True)
        operSum = (operOp1*operOp2)&bitMask
        temp = <unsigned long long>(operOp1*operOp2)
        if (self.registers.operSize == OP_SIZE_WORD):
            temp = <unsigned long>temp
        self.modRMInstance.modRSave(self.registers.operSize, operSum, OPCODE_SAVE)
        self.registers.setFullFlags(operOp1, operOp2, self.registers.operSize, OPCODE_IMUL)
        self.registers.setEFLAG(FLAG_CF | FLAG_OF, temp!=operSum)
    cdef opcodeGroup1_RM_ImmFunc(self, unsigned char operSize, unsigned char immIsByte):
        cdef unsigned char operOpcode, operOpcodeId
        cdef unsigned long operOp1, operOp2
        operOpcode = self.registers.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        ##self.main.debug("Group1_RM_ImmFunc: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp1 = self.modRMInstance.modRMLoad(operSize, False, True)
        if (operSize != OP_SIZE_BYTE and immIsByte):
            operOp2 = <unsigned long>(self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, True)) # operImm8 sign-extended to destsize
            if (operSize == OP_SIZE_WORD):
                operOp2 = <unsigned short>operOp2
        else:
            operOp2 = self.registers.getCurrentOpcodeAdd(operSize, False) # operImm8/16/32
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
            self.main.printMsg("opcodeGroup1_RM16_32_IMM8: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroup3_RM_ImmFunc(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId
        cdef unsigned long operOp2
        operOpcode = self.registers.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        ##self.main.debug("Group3_RM_ImmFunc: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp2 = self.registers.getCurrentOpcodeAdd(operSize, False) # operImm
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.modRMInstance.modRMSave(operSize, operOp2, True, OPCODE_SAVE)
        else:
            self.main.printMsg("opcodeGroup3_RM16_32_IMM16_32: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroup0F(self):
        cdef unsigned char operOpcode, bitSize, operOpcodeMod, operOpcodeModId, \
            newCF, newOF, oldOF, count, eaxIsInvalid
        cdef unsigned short eaxReg, limit
        cdef unsigned long eaxId, bitMask, bitMaskHalf, base, mmAddr, op1, op2
        cdef unsigned long long qop1, qop2
        cdef short i
        cdef GdtEntry gdtEntry
        operOpcode = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        ##self.main.debug("Group0F: Opcode=={0:#04x}", operOpcode)
        if (operOpcode == 0x00): # LLDT/SLDT LTR/STR VERR/VERW
            if (not (<Segments>self.registers.segments).isInProtectedMode()):
                raise ChemuException(CPU_EXCEPTION_UD)
            if (self.registers.cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            operOpcodeMod = self.registers.getCurrentOpcode(OP_SIZE_BYTE, False)
            operOpcodeModId = (operOpcodeMod>>3)&7
            ##self.main.debug("Group0F_00: operOpcodeModId=={0:d}", operOpcodeModId)
            self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            mmAddr = self.modRMInstance.getRMValueFull(self.registers.addrSize)
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
                    self.main.printMsg("opcodeGroup0F_00_STR: TR isn't fully supported yet.")
            elif (operOpcodeModId in (2, 3)): # LLDT/LTR
                op1 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
                if (operOpcodeModId == 2): # LLDT
                    if ((op1>>2) == 0):
                        ##self.main.debug("Opcode0F_01::LLDT: (op1>>2) == 0, mark LDTR as invalid.")
                        op1 = 0
                    else:
                        if ((op1 & SELECTOR_USE_LDT) or \
                          ((op1&0xfff8) > (<Gdt>self.registers.segments.gdt).tableLimit) or \
                          (((<Gdt>self.registers.segments.gdt).getSegAccess(op1) & \
                          GDT_ACCESS_SYSTEM_SEGMENT_TYPE) != GDT_ENTRY_SYSTEM_TYPE_LDT)):
                            raise ChemuException(CPU_EXCEPTION_GP, op1)
                        elif (not (<Gdt>self.registers.segments.gdt).isSegPresent(op1)):
                            raise ChemuException(CPU_EXCEPTION_NP, op1)
                    op1 &= 0xfff8
                    gdtEntry = (<GdtEntry>(<Gdt>self.registers.segments.gdt).getEntry(op1))
                    if (not gdtEntry):
                        op1 = 0
                    (<Segments>self.registers.segments).ldtr = op1
                    if (gdtEntry):
                        (<Gdt>self.registers.segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
                        (<Gdt>self.registers.segments.ldt).loadTableData()
                elif (operOpcodeModId == 3): # LTR
                    if ((op1&0xfff8) == 0):
                        raise ChemuException(CPU_EXCEPTION_GP, 0)
                    elif ((op1 & SELECTOR_USE_LDT) or \
                      ((op1&0xfff8) > (<Gdt>self.registers.segments.gdt).tableLimit) or \
                      (((<Gdt>self.registers.segments.gdt).getSegAccess(op1) & \
                      GDT_ACCESS_SYSTEM_SEGMENT_TYPE) != GDT_ENTRY_SYSTEM_TYPE_TSS)):
                        raise ChemuException(CPU_EXCEPTION_GP, op1)
                    elif (not (<Gdt>self.registers.segments.gdt).isSegPresent(op1)):
                        raise ChemuException(CPU_EXCEPTION_NP, op1)
                    gdtEntry = (<GdtEntry>(<Gdt>self.registers.segments.gdt).getEntry(op1))
                    if (not gdtEntry):
                        raise ChemuException(CPU_EXCEPTION_GP, op1)
                    op1 &= 0xfff8
                    (<Segments>self.registers.segments).tr = op1
                    (<Gdt>self.registers.segments.tss).loadTablePosition(gdtEntry.base, gdtEntry.limit)
                    (<Gdt>self.registers.segments.tss).loadTableData()
                    self.main.printMsg("opcodeGroup0F_00_LTR: TR isn't fully supported yet.")
            elif (operOpcodeModId == 4): # VERR
                op1 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
                self.registers.setEFLAG(FLAG_ZF, (<Segments>self.registers.segments).checkReadAllowed(op1))
            elif (operOpcodeModId == 5): # VERW
                op1 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
                self.registers.setEFLAG(FLAG_ZF, (<Segments>self.registers.segments).checkWriteAllowed(op1))
            else:
                self.main.printMsg("opcodeGroup0F_00: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x01): # LGDT/LIDT SGDT/SIDT SMSW/LMSW
            if (self.registers.cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            operOpcodeMod = self.registers.getCurrentOpcode(OP_SIZE_BYTE, False)
            operOpcodeModId = (operOpcodeMod>>3)&7
            ##self.main.debug("Group0F_01: operOpcodeModId=={0:d}", operOpcodeModId)
            if (operOpcodeModId in (0, 1, 2, 3)): # SGDT/SIDT LGDT/LIDT
                self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            elif (operOpcodeModId in (4, 6)): # SMSW/LMSW
                self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            else:
                self.main.printMsg("Group0F_01: operOpcodeModId not in (0, 1, 2, 3, 4, 6)")
            mmAddr = self.modRMInstance.getRMValueFull(self.registers.addrSize)
            if (operOpcodeMod == 0xc1): # VMCALL
                self.main.printMsg("opcodeGroup0F_01: VMCALL isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc2): # VMLAUNCH
                self.main.printMsg("opcodeGroup0F_01: VMLAUNCH isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc3): # VMRESUME
                self.main.printMsg("opcodeGroup0F_01: VMRESUME isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc4): # VMXOFF
                self.main.printMsg("opcodeGroup0F_01: VMXOFF isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc8): # MONITOR
                self.main.printMsg("opcodeGroup0F_01: MONITOR isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xc9): # MWAIT
                self.main.printMsg("opcodeGroup0F_01: MWAIT isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xd0): # XGETBV
                self.main.printMsg("opcodeGroup0F_01: XGETBV isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xd1): # XSETBV
                self.main.printMsg("opcodeGroup0F_01: XSETBV isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeMod == 0xf9): # RDTSCP
                self.main.printMsg("opcodeGroup0F_01: RDTSCP isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            elif (operOpcodeModId in (0, 1)): # SGDT/SIDT
                if (operOpcodeModId == 0): # SGDT
                    (<Gdt>self.registers.segments.gdt).getBaseLimit(&base, &limit)
                elif (operOpcodeModId == 1): # SIDT
                    (<Idt>self.registers.segments.idt).getBaseLimit(&base, &limit)
                if (self.registers.operSize == OP_SIZE_WORD):
                    base &= 0xffffff
                self.registers.mmWriteValue(mmAddr, limit, OP_SIZE_WORD, CPU_SEGMENT_DS, True)
                self.registers.mmWriteValue(mmAddr+OP_SIZE_WORD, base, OP_SIZE_DWORD, CPU_SEGMENT_DS, True)
            elif (operOpcodeModId in (2, 3)): # LGDT/LIDT
                limit = self.registers.mmReadValueUnsigned(mmAddr, OP_SIZE_WORD, CPU_SEGMENT_DS, True)
                base = self.registers.mmReadValueUnsigned(mmAddr+OP_SIZE_WORD, OP_SIZE_DWORD, CPU_SEGMENT_DS, True)
                if (self.registers.operSize == OP_SIZE_WORD):
                    base &= 0xffffff
                if (operOpcodeModId == 2): # LGDT
                    (<Gdt>self.registers.segments.gdt).loadTablePosition(base, limit)
                elif (operOpcodeModId == 3): # LIDT
                    (<Idt>self.registers.segments.idt).loadTable(base, limit)
            elif (operOpcodeModId == 4): # SMSW
                op2 = <unsigned short>(self.registers.regRead(CPU_REGISTER_CR0, False))
                self.modRMInstance.modRMSave(OP_SIZE_WORD, op2, True, OPCODE_SAVE)
            elif (operOpcodeModId == 6): # LMSW
                if (self.registers.cpl != 0):
                    raise ChemuException(CPU_EXCEPTION_GP, 0)
                op1 = self.registers.regRead(CPU_REGISTER_CR0, False)
                op2 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
                if ((op1&1 != 0) and (op2&1 == 0)): # if is already in protected mode, but try to switch to real mode...
                    self.main.exitError("opcodeGroup0F_01: LMSW: try to switch to real mode from protected mode.")
                    return
                self.registers.regWrite(CPU_REGISTER_CR0, ((op1&0xfffffff0)|(op2&0xf)))
                self.syncProtectedModeState()
            elif (operOpcodeModId == 7): # INVLPG
                self.main.printMsg("opcodeGroup0F_01: INVLPG isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            else:
                self.main.printMsg("opcodeGroup0F_01: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x03): # LSL
            if (not (<Segments>self.registers.segments).isInProtectedMode()):
                raise ChemuException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
            if (op2 > ((<Gdt>self.registers.segments.gdt).tableLimit)):
                self.registers.setEFLAG(FLAG_ZF, False)
                return
            gdtEntry = (<GdtEntry>(<Gdt>self.registers.segments.gdt).getEntry(op2))
            if ((not gdtEntry.segIsConforming and ((self.registers.cpl > gdtEntry.segDPL) or ((op2&3) > gdtEntry.segDPL))) or \
              ((gdtEntry.accessByte & GDT_ACCESS_SYSTEM_SEGMENT_TYPE) not in (0x1, 0x2, 0x3, 0x9, 0xb))):
                self.registers.setEFLAG(FLAG_ZF, False)
                return
            op1 = gdtEntry.limit
            if ((gdtEntry.flags & GDT_FLAG_USE_4K) != 0):
                op1 <<= 12
                op1 |= 0xfff
            if (self.registers.operSize == OP_SIZE_WORD):
                op1 = <unsigned short>op1
            self.modRMInstance.modRSave(self.registers.operSize, op1, OPCODE_SAVE)
            self.registers.setEFLAG(FLAG_ZF, True)
        elif (operOpcode == 0x05): # LOADALL (286, undocumented)
            self.main.printMsg("opcodeGroup0F_05: LOADALL 286 opcode isn't supported yet.")
            raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x07): # LOADALL (386, undocumented)
            self.main.printMsg("opcodeGroup0F_07: LOADALL 386 opcode isn't supported yet.")
            raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode in (0x06, 0x08, 0x09)): # 0x06: CLTS, 0x08: INVD, 0x09: WBINVD
            if (self.registers.cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            if (operOpcode == 0x06): # CLTS
                self.registers.regAnd(CPU_REGISTER_CR0, <unsigned long>(~CR0_FLAG_TS))
        elif (operOpcode == 0x0b): # UD2
            raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x20): # MOV R32, CRn
            if (self.registers.cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_CREG)
            if (self.modRMInstance.regName not in (CPU_REGISTER_CR0, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4)):
                raise ChemuException(CPU_EXCEPTION_UD)
            # We need to 'ignore' mod to read the source/dest as a register. That's the way to do it.
            self.modRMInstance.mod = 3
            self.modRMInstance.modRMSave(OP_SIZE_DWORD, self.modRMInstance.modRLoad(OP_SIZE_DWORD, False), True, OPCODE_SAVE)
        elif (operOpcode == 0x21): # MOV R32, DRn
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_DREG)
            self.modRMInstance.modRMSave(OP_SIZE_DWORD, self.modRMInstance.modRLoad(OP_SIZE_DWORD, False), True, OPCODE_SAVE)
        elif (operOpcode == 0x22): # MOV CRn, R32
            if (self.registers.cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_CREG)
            if (self.modRMInstance.regName not in (CPU_REGISTER_CR0, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4)):
                raise ChemuException(CPU_EXCEPTION_UD)
            # We need to 'ignore' mod to read the source/dest as a register. That's the way to do it.
            self.modRMInstance.mod = 3
            op2 = self.modRMInstance.modRMLoad(OP_SIZE_DWORD, False, True)
            if (self.modRMInstance.regName == CPU_REGISTER_CR0):
                op1 = self.registers.regRead(CPU_REGISTER_CR0, False) # op1 == old CR0
                if (op2 & CR0_FLAG_PG):
                    self.main.exitError("opcodeGroup0F_22: Paging IS NOT SUPPORTED yet.")
                if (((op2 & CR0_FLAG_PG) and not (op1 & CR0_FLAG_PE)) or \
                  (not (op2 & CR0_FLAG_CD) and (op1 & CR0_FLAG_NW))):
                    raise ChemuException(CPU_EXCEPTION_GP, 0)
            elif (self.modRMInstance.regName == CPU_REGISTER_CR4):
                if (op2 & CR4_FLAG_VME):
                    self.main.exitError("opcodeGroup0F_22: VME (virtual-8086 mode extension) IS NOT SUPPORTED yet.")
            self.modRMInstance.modRSave(OP_SIZE_DWORD, op2, OPCODE_SAVE)
        elif (operOpcode == 0x23): # MOV DRn, R32
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_DREG)
            self.modRMInstance.modRSave(OP_SIZE_DWORD, self.modRMInstance.modRMLoad(OP_SIZE_DWORD, False, True), OPCODE_SAVE)
        elif (operOpcode == 0x31): # RDTSC
            if (not self.registers.getFlag(CPU_REGISTER_CR4, CR4_FLAG_TSD) or \
              self.registers.cpl == 0 or not (<Segments>self.registers.segments).isInProtectedMode()):
                self.registers.regWrite(CPU_REGISTER_EAX, <unsigned long>self.main.cpu.cycles)
                self.registers.regWrite(CPU_REGISTER_EDX, <unsigned long>(self.main.cpu.cycles>>32))
            else:
                raise ChemuException(CPU_EXCEPTION_GP, 0)
        elif (operOpcode == 0x38): # MOVBE
            operOpcodeMod = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            if (operOpcodeMod == 0xf0): # MOVBE R16_32, M16_32
                op2 = self.modRMInstance.modRMLoad(self.registers.operSize, False, True)
                op2 = (<Misc>self.main.misc).reverseByteOrder(op2, self.registers.operSize)
                self.modRMInstance.modRSave(self.registers.operSize, op2, OPCODE_SAVE)
            elif (operOpcodeMod == 0xf1): # MOVBE M16_32, R16_32
                op2 = self.modRMInstance.modRLoad(self.registers.operSize, False)
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
            eaxId = self.registers.regRead(CPU_REGISTER_EAX, False)
            eaxIsInvalid = (eaxId >= 0x40000000 and eaxId <= 0x4fffffff)
            if (eaxId == 0x1):
                self.registers.regWrite(CPU_REGISTER_EAX, 0x400)
                self.registers.regWrite(CPU_REGISTER_EBX, 0x0)
                self.registers.regWrite(CPU_REGISTER_EDX, 0x8110)
                self.registers.regWrite(CPU_REGISTER_ECX, 0xc00000)
            elif (eaxId in (0x2, 0x3, 0x4)):
                self.registers.regWrite(CPU_REGISTER_EAX, 0x0)
                self.registers.regWrite(CPU_REGISTER_EBX, 0x0)
                self.registers.regWrite(CPU_REGISTER_EDX, 0x0)
                self.registers.regWrite(CPU_REGISTER_ECX, 0x0)
            #elif (eaxId in (0x3, 0x4, 0x5, 0x6, 0x7)): #, 0x80000005, 0x80000006, 0x80000007)):
            #    self.registers.regWrite(CPU_REGISTER_EAX, 0x0)
            #    self.registers.regWrite(CPU_REGISTER_EBX, 0x0)
            #    self.registers.regWrite(CPU_REGISTER_EDX, 0x0)
            #    self.registers.regWrite(CPU_REGISTER_ECX, 0x0)
            #elif (eaxId == 0x80000000):
            #    self.registers.regWrite(CPU_REGISTER_EAX, 0x80000001)
            #    self.registers.regWrite(CPU_REGISTER_EBX, 0x0)
            #    self.registers.regWrite(CPU_REGISTER_EDX, 0x0)
            #    self.registers.regWrite(CPU_REGISTER_ECX, 0x0)
            #elif (eaxId == 0x80000001):
            #    self.registers.regWrite(CPU_REGISTER_EAX, 0x0)
            #    self.registers.regWrite(CPU_REGISTER_EBX, 0x0)
            #    self.registers.regWrite(CPU_REGISTER_EDX, 0x0)
            #    self.registers.regWrite(CPU_REGISTER_ECX, 0x0)
            #elif (eaxId == 0x0 or eaxIsInvalid):
            else:
                if (not (eaxId == 0x0 or eaxIsInvalid)):
                    self.main.printMsg("CPUID: eaxId {0:#04x} unknown.", eaxId)
                self.registers.regWrite(CPU_REGISTER_EAX, 0x4) # 0x1) # 0x7)
                self.registers.regWrite(CPU_REGISTER_EBX, 0x756e6547)
                self.registers.regWrite(CPU_REGISTER_EDX, 0x49656e69)
                self.registers.regWrite(CPU_REGISTER_ECX, 0x6c65746e)
            #else:
            #    self.main.exitError("CPUID: eaxId {0:#04x} unknown.", eaxId)
        elif (operOpcode == 0xa3): # BT RM16/32, R16
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRLoad(self.registers.operSize, False)
            self.btFunc(op2, BT_NONE)
        elif (operOpcode in (0xa4, 0xa5)): # SHLD
            bitMaskHalf = (<Misc>self.main.misc).getBitMask80(self.registers.operSize)
            bitSize = self.registers.operSize << 3
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            if (operOpcode == 0xa4): # SHLD imm8
                count = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            elif (operOpcode == 0xa5): # SHLD CL
                count = self.registers.regRead(CPU_REGISTER_CL, False)
            else:
                self.main.exitError("group0F::SHLD: operOpcode {0:#04x} unknown.", operOpcode)
                return
            count %= 32
            if (count == 0):
                return
            if (count > bitSize): # bad parameters
                self.main.exitError("group0F: SHLD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).", count, bitSize, operOpcode)
                return
            op1 = self.modRMInstance.modRMLoad(self.registers.operSize, False, True) # dest
            oldOF = (op1&bitMaskHalf)!=0
            op2  = self.modRMInstance.modRLoad(self.registers.operSize, False) # src
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
            op2 = self.modRMInstance.modRLoad(self.registers.operSize, False)
            self.btFunc(op2, BT_SET)
        elif (operOpcode in (0xac, 0xad)): # SHRD
            bitMaskHalf = (<Misc>self.main.misc).getBitMask80(self.registers.operSize)
            bitSize = self.registers.operSize << 3
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            if (operOpcode == 0xac): # SHRD imm8
                count = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            elif (operOpcode == 0xad): # SHRD CL
                count = self.registers.regRead(CPU_REGISTER_CL, False)
            else:
                self.main.exitError("group0F::SHRD: operOpcode {0:#04x} unknown.", operOpcode)
                return
            count %= 32
            if (count == 0):
                return
            if (count > bitSize): # bad parameters
                self.main.exitError("group0F: SHRD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).", count, bitSize, operOpcode)
                return
            op1 = self.modRMInstance.modRMLoad(self.registers.operSize, False, True) # dest
            oldOF = (op1&bitMaskHalf)!=0
            op2  = self.modRMInstance.modRLoad(self.registers.operSize, False) # src
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
            op1 = self.modRMInstance.modRLoad(self.registers.operSize, True)
            op2 = self.modRMInstance.modRMLoad(self.registers.operSize, True, True)
            if (self.registers.operSize == OP_SIZE_WORD):
                op1 = <unsigned short>op1
                op2 = <unsigned short>op2
            elif (self.registers.operSize == OP_SIZE_DWORD):
                op1 = <unsigned long>op1
                op2 = <unsigned long>op2
            self.registers.setFullFlags(op1, op2, self.registers.operSize, OPCODE_IMUL)
            qop1 = (op1*op2)
            if (self.registers.operSize == OP_SIZE_WORD):
                qop1 = <unsigned short>qop1
            elif (self.registers.operSize == OP_SIZE_DWORD):
                qop1 = <unsigned long>qop1
            self.modRMInstance.modRSave(self.registers.operSize, qop1, OPCODE_SAVE)
        elif (operOpcode in (0xb0, 0xb1)): # 0xb0: CMPXCHG RM8, R8 ;; 0xb1: CMPXCHG RM16_32, R16_32
            bitSize = self.registers.operSize # bitSize is in bytes (double usage of vars)
            if (operOpcode == 0xb0): # 0xb0: CMPXCHG RM8, R8
                bitSize = OP_SIZE_BYTE
            eaxReg  = self.registers.getWordAsDword(CPU_REGISTER_AX, bitSize)
            self.modRMInstance.modRMOperands(bitSize, MODRM_FLAGS_NONE)
            op1 = self.modRMInstance.modRMLoad(bitSize, False, True)
            op2 = self.reg.regRead(eaxReg, False)
            self.registers.setFullFlags(op2, op1, bitSize, OPCODE_SUB)
            if (op2 == op1):
                self.registers.setEFLAG(FLAG_ZF, True)
                op2 = self.modRMInstance.modRLoad(bitSize, False)
                self.modRMInstance.modRMSave(bitSize, op2, True, OPCODE_SAVE)
            else:
                self.registers.setEFLAG(FLAG_ZF, False)
                self.registers.regWrite(eaxReg, op1)
        elif (operOpcode == 0xb2): # LSS
            self.lfpFunc(CPU_SEGMENT_SS)
        elif (operOpcode == 0xb3): # BTR RM16/32, R16
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRLoad(self.registers.operSize, False)
            self.btFunc(op2, BT_RESET)
        elif (operOpcode == 0xb4): # LFS
            self.lfpFunc(CPU_SEGMENT_FS)
        elif (operOpcode == 0xb5): # LGS
            self.lfpFunc(CPU_SEGMENT_GS)
        elif (operOpcode == 0xb8): # POPCNT R16/32 RM16/32
            if (self.registers.repPrefix):
                raise ChemuException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoad(self.registers.operSize, False, True)
            op2 = bin(op2).count('1')
            self.modRMInstance.modRSave(self.registers.operSize, op2, OPCODE_SAVE)
            self.registers.setEFLAG(FLAG_CF | FLAG_PF | FLAG_AF | FLAG_ZF | FLAG_SF | FLAG_OF, False)
            self.registers.setEFLAG(FLAG_ZF, op2==0)
        elif (operOpcode == 0xba): # BT/BTS/BTR/BTC RM16/32 IMM8
            operOpcodeMod = self.registers.getCurrentOpcode(OP_SIZE_BYTE, False)
            operOpcodeModId = (operOpcodeMod>>3)&7
            ##self.main.debug("Group0F_BA: operOpcodeModId=={0:d}", operOpcodeModId)
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            if (operOpcodeModId == 4): # BT
                self.btFunc(op2, BT_NONE)
            elif (operOpcodeModId == 5): # BTS
                self.btFunc(op2, BT_SET)
            elif (operOpcodeModId == 6): # BTR
                self.btFunc(op2, BT_RESET)
            elif (operOpcodeModId == 7): # BTC
                self.btFunc(op2, BT_COMPLEMENT)
            else:
                self.main.printMsg("opcodeGroup0F_BA: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0xbb): # BTC RM16/32, R16
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRLoad(self.registers.operSize, False)
            self.btFunc(op2, BT_COMPLEMENT)
        elif (operOpcode == 0xbc): # BSF R16_32, R/M16_32
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoad(self.registers.operSize, False, True)
            self.registers.setEFLAG(FLAG_ZF, op2==0)
            op1 = 0
            if (op2 > 1):
                op1 = bin(op2)[::-1].find('1')
            self.modRMInstance.modRSave(self.registers.operSize, op1, OPCODE_SAVE)
        elif (operOpcode == 0xbd): # BSR R16_32, R/M16_32
            self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoad(self.registers.operSize, False, True)
            self.registers.setEFLAG(FLAG_ZF, op2==0)
            self.modRMInstance.modRSave(self.registers.operSize, op2.bit_length()-1, OPCODE_SAVE)
        elif (operOpcode in (0xb6, 0xbe)): # 0xb6==MOVZX R16_32, R/M8 ;; 0xbe==MOVSX R16_32, R/M8
            self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
            self.modRMInstance.regName = self.registers.getRegNameWithFlags(MODRM_FLAGS_NONE, \
              self.modRMInstance.reg, self.registers.operSize)
            if (operOpcode == 0xb6): # MOVZX R16_32, R/M8
                op2 = self.modRMInstance.modRMLoad(OP_SIZE_BYTE, False, True)
            else: # MOVSX R16_32, R/M8
                op2 = <unsigned long>(self.modRMInstance.modRMLoad(OP_SIZE_BYTE, True, True))
                if (self.registers.operSize == OP_SIZE_WORD):
                    op2 = <unsigned short>op2
            self.modRMInstance.modRSave(self.registers.operSize, op2, OPCODE_SAVE)
        elif (operOpcode in (0xb7, 0xbf)): # 0xb7==MOVZX R32, R/M16 ;; 0xbf==MOVSX R32, R/M16
            self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            self.modRMInstance.regName = self.registers.getRegNameWithFlags(MODRM_FLAGS_NONE, \
              self.modRMInstance.reg, OP_SIZE_DWORD)
            if (operOpcode == 0xb7): # MOVZX R32, R/M16
                op2 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
            else: # MOVSX R32, R/M16
                op2 = <unsigned long>(self.modRMInstance.modRMLoad(OP_SIZE_WORD, True, True))
            self.modRMInstance.modRSave(OP_SIZE_DWORD, op2, OPCODE_SAVE)
        elif (operOpcode in (0xc0, 0xc1)): # 0xc0: XADD RM8, R8 ;; 0xc1: XADD RM16_32, R16_32
            bitSize = self.registers.operSize # bitSize is in bytes (double usage of vars)
            if (operOpcode == 0xc0): # 0xc0: XADD RM8, R8
                bitSize = OP_SIZE_BYTE
            self.modRMInstance.modRMOperands(bitSize, MODRM_FLAGS_NONE)
            op1 = self.modRMInstance.modRMLoad(bitSize, False, True)
            op2 = self.modRMInstance.modRLoad(bitSize, False)
            self.modRMInstance.modRMSave(bitSize, op2, True, OPCODE_ADD)
            self.modRMInstance.modRSave(bitSize, op1, OPCODE_SAVE)
            self.registers.setFullFlags(op1, op2, bitSize, OPCODE_ADD)
        elif (operOpcode == 0xc7): # CMPXCHG8B M64
            operOpcodeMod = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            operOpcodeModId = (operOpcodeMod>>3)&7
            ##self.main.debug("Group0F_C7: operOpcodeModId=={0:d}", operOpcodeModId)
            if (operOpcodeModId == 1):
                op1 = self.registers.getCurrentOpcodeAdd(self.registers.addrSize, False)
                qop1 = (<Mm>self.main.mm).mmPhyReadValueUnsigned(op1, OP_SIZE_QWORD)
                qop2 = self.registers.regRead(CPU_REGISTER_EDX, False)
                qop2 <<= 32
                qop2 |= self.registers.regRead(CPU_REGISTER_EAX, False)
                if (qop2 == qop1):
                    self.registers.setEFLAG(FLAG_ZF, True)
                    qop2 = self.registers.regRead(CPU_REGISTER_ECX, False)
                    qop2 <<= 32
                    qop2 |= self.registers.regRead(CPU_REGISTER_EBX, False)
                    (<Mm>self.main.mm).mmPhyWriteValue(op1, qop2, OP_SIZE_QWORD)
                else:
                    self.registers.setEFLAG(FLAG_ZF, False)
                    self.registers.regWrite(CPU_REGISTER_EDX, qop1>>32)
                    self.registers.regWrite(CPU_REGISTER_EAX, <unsigned long>qop1)
            else:
                self.main.printMsg("opcodeGroup0F_C7: operOpcodeModId {0:d} isn't supported yet.", operOpcodeModId)
                raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode >= 0xc8 and operOpcode <= 0xcf): # BSWAP R32
            regName  = CPU_REGISTER_DWORD[operOpcode&7]
            op1 = self.registers.regRead(regName, False)
            op1 = (<Misc>self.main.misc).reverseByteOrder(op1, OP_SIZE_DWORD)
            self.registers.regWrite(regName, op1)
        else:
            self.main.printMsg("opcodeGroup0F: invalid operOpcode. {0:#04x}", operOpcode)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroupFE(self):
        cdef unsigned char operOpcode, operOpcodeId
        operOpcode = self.registers.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        ##self.main.debug("GroupFE: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(OP_SIZE_BYTE)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(OP_SIZE_BYTE)
        else:
            self.main.printMsg("opcodeGroupFE: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroupFF(self):
        cdef unsigned char operOpcode, operOpcodeId
        cdef unsigned short segVal
        cdef unsigned long op1, eipAddr
        operOpcode = self.registers.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        ##self.main.debug("GroupFF: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(self.registers.operSize)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(self.registers.operSize)
        elif (operOpcodeId == 2): # 2/CALL NEAR
            eipAddr = self.modRMInstance.modRMLoad(self.registers.operSize, False, True)
            self.stackPushRegId(self.registers.eipSizeRegId, self.registers.operSize)
            self.registers.regWrite(CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 3): # 3/CALL FAR
            op1 = self.modRMInstance.getRMValueFull(self.registers.addrSize)
            eipAddr = self.registers.mmReadValueUnsigned(op1, self.registers.operSize, self.modRMInstance.rmNameSegId, True)
            segVal = self.registers.mmReadValueUnsigned(op1+self.registers.operSize, OP_SIZE_WORD, self.modRMInstance.rmNameSegId, True)
            self.stackPushSegId(CPU_SEGMENT_CS, self.registers.operSize)
            self.stackPushRegId(self.registers.eipSizeRegId, self.registers.operSize)
            self.syncProtectedModeState()
            self.registers.segWrite(CPU_SEGMENT_CS, segVal)
            self.registers.regWrite(CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 4): # 4/JMP NEAR
            eipAddr = self.modRMInstance.modRMLoad(self.registers.operSize, False, True)
            self.registers.regWrite(CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 5): # 5/JMP FAR
            op1 = self.modRMInstance.getRMValueFull(self.registers.addrSize)
            eipAddr = self.registers.mmReadValueUnsigned(op1, self.registers.operSize, self.modRMInstance.rmNameSegId, True)
            segVal = self.registers.mmReadValueUnsigned(op1+self.registers.operSize, OP_SIZE_WORD, self.modRMInstance.rmNameSegId, True)
            self.syncProtectedModeState()
            self.registers.segWrite(CPU_SEGMENT_CS, segVal)
            self.registers.regWrite(CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 6): # 6/PUSH
            op1 = self.modRMInstance.modRMLoad(self.registers.operSize, False, True)
            self.stackPushValue(op1, self.registers.operSize)
        else:
            self.main.printMsg("opcodeGroupFF: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef incFuncReg(self, unsigned short regId, unsigned char regSize):
        cdef unsigned char origCF
        cdef unsigned long origValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        origValue = self.registers.regRead(regId, False)
        self.registers.regWrite(regId, <unsigned long>(origValue+1))
        self.registers.setFullFlags(origValue, 1, regSize, OPCODE_ADD)
        self.registers.setEFLAG(FLAG_CF, origCF)
    cdef decFuncReg(self, unsigned short regId, unsigned char regSize):
        cdef unsigned char origCF
        cdef unsigned long origValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        origValue = self.registers.regRead(regId, False)
        self.registers.regWrite(regId, <unsigned long>(origValue-1))
        self.registers.setFullFlags(origValue, 1, regSize, OPCODE_SUB)
        self.registers.setEFLAG(FLAG_CF, origCF)
    cdef incFuncRM(self, unsigned char rmSize):
        cdef unsigned char origCF
        cdef unsigned long origValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        origValue = self.modRMInstance.modRMLoad(rmSize, False, True)
        self.modRMInstance.modRMSave(rmSize, <unsigned long>(origValue+1), True, OPCODE_SAVE)
        self.registers.setFullFlags(origValue, 1, rmSize, OPCODE_ADD)
        self.registers.setEFLAG(FLAG_CF, origCF)
    cdef decFuncRM(self, unsigned char rmSize):
        cdef unsigned char origCF
        cdef unsigned long origValue
        origCF = self.registers.getEFLAG(FLAG_CF)
        origValue = self.modRMInstance.modRMLoad(rmSize, False, True)
        self.modRMInstance.modRMSave(rmSize, <unsigned long>(origValue-1), True, OPCODE_SAVE)
        self.registers.setFullFlags(origValue, 1, rmSize, OPCODE_SUB)
        self.registers.setEFLAG(FLAG_CF, origCF)
    cdef incReg(self):
        cdef unsigned short regName
        regName  = CPU_REGISTER_WORD[self.main.cpu.opcode&7]
        regName  = self.registers.getWordAsDword(regName, self.registers.operSize)
        self.incFuncReg(regName, self.registers.operSize)
    cdef decReg(self):
        cdef unsigned short regName
        regName  = CPU_REGISTER_WORD[self.main.cpu.opcode&7]
        regName  = self.registers.getWordAsDword(regName, self.registers.operSize)
        self.decFuncReg(regName, self.registers.operSize)
    cdef pushReg(self):
        cdef unsigned short regName
        regName  = CPU_REGISTER_WORD[self.main.cpu.opcode&7]
        regName  = self.registers.getWordAsDword(regName, self.registers.operSize)
        self.stackPushRegId(regName, self.registers.operSize)
    cdef pushSeg(self, unsigned char opcode):
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
            return
        self.stackPushSegId(segName, self.registers.operSize)
    cdef popReg(self):
        cdef unsigned short regName
        regName  = self.registers.getWordAsDword(CPU_REGISTER_WORD[self.main.cpu.opcode&7], self.registers.operSize)
        self.stackPopRegId(regName)
    cdef popSeg(self, unsigned char opcode):
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
            return
        self.stackPopSegId(segName)
    cdef popRM16_32(self):
        cdef unsigned char operOpcode, operOpcodeId
        operOpcode = self.registers.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        if (operOpcodeId == 0): # POP
            self.stackPopRM16_32()
        else:
            self.main.printMsg("popRM16_32: unknown operOpcodeId: {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef lea(self):
        cdef unsigned long mmAddr
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        if (self.modRMInstance.mod == 3):
            raise ChemuException(CPU_EXCEPTION_UD)
        mmAddr = self.modRMInstance.getRMValueFull(self.registers.addrSize)
        if (self.registers.operSize == OP_SIZE_WORD):
            mmAddr = <unsigned short>mmAddr
        self.modRMInstance.modRSave(self.registers.operSize, mmAddr, OPCODE_SAVE)
    cdef retNear(self, unsigned short imm):
        cdef unsigned char stackAddrSize
        cdef unsigned short espName
        cdef unsigned long tempEIP
        stackAddrSize = self.registers.getAddrSegSize(CPU_SEGMENT_SS)
        espName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        tempEIP = self.stackPopValue()
        self.registers.regWrite(CPU_REGISTER_EIP, tempEIP)
        if (imm):
            self.registers.regAdd(espName, imm)
    cdef retNearImm(self):
        cdef unsigned short imm
        imm = self.registers.getCurrentOpcodeAdd(OP_SIZE_WORD, False) # imm16
        self.retNear(imm)
    cdef retFar(self, unsigned short imm):
        cdef unsigned char stackAddrSize
        cdef unsigned short espName
        stackAddrSize = self.registers.getAddrSegSize(CPU_SEGMENT_SS)
        espName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        self.syncProtectedModeState()
        self.stackPopRegId(CPU_REGISTER_EIP)
        self.stackPopSegId(CPU_SEGMENT_CS)
        if (imm):
            self.registers.regAdd(espName, imm)
    cdef retFarImm(self):
        cdef unsigned short imm
        imm = self.registers.getCurrentOpcodeAdd(OP_SIZE_WORD, False) # imm16
        self.retFar(imm)
    cdef lfpFunc(self, unsigned short segId): # 'load far pointer' function
        cdef unsigned short segmentAddr
        cdef unsigned long mmAddr, offsetAddr
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        mmAddr = self.modRMInstance.getRMValueFull(self.registers.addrSize)
        offsetAddr = self.registers.mmReadValueUnsigned(mmAddr, self.registers.operSize, self.modRMInstance.rmNameSegId, True)
        segmentAddr = self.registers.mmReadValueUnsigned(mmAddr+self.registers.operSize, OP_SIZE_WORD, self.modRMInstance.rmNameSegId, True)
        self.modRMInstance.modRSave(self.registers.operSize, offsetAddr, OPCODE_SAVE)
        self.registers.segWrite(segId, segmentAddr)
    cdef xlatb(self):
        cdef unsigned char data
        cdef unsigned short baseReg
        cdef unsigned long baseValue
        baseReg = self.registers.getWordAsDword(CPU_REGISTER_BX, self.registers.addrSize)
        baseValue = self.registers.regRead(baseReg, False)
        data = self.registers.regRead(CPU_REGISTER_AL, False)
        data = self.registers.mmReadValueUnsigned(<unsigned long>(baseValue+data), OP_SIZE_BYTE, CPU_SEGMENT_DS, True)
        self.registers.regWrite(CPU_REGISTER_AL, data)
    cdef opcodeGroup2_RM(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId, operSizeInBits
        cdef unsigned long operOp2, bitMaskHalf, bitMask
        cdef unsigned long long utemp, operOp1, operSum, doubleBitMask, doubleBitMaskHalf
        cdef long sop2
        cdef long long sop1, temp, tempmod
        operOpcode = self.registers.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        ##self.main.debug("Group2_RM: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp2 = self.modRMInstance.modRMLoad(operSize, False, True)
        operSizeInBits = operSize << 3
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        if (operOpcodeId in (GROUP2_OP_TEST, GROUP2_OP_TEST_ALIAS)):
            operOp1 = self.registers.getCurrentOpcodeAdd(operSize, False)
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
                operOp1 = self.registers.regRead(CPU_REGISTER_AX, False)
                self.registers.regWrite(CPU_REGISTER_AX, <unsigned short>((<unsigned char>operOp1)*operOp2))
                self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_MUL)
                return
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
            operOp1 = self.registers.regRead(eaxReg, False)
            operSum = operOp1*operOp2
            if (operSize == OP_SIZE_WORD):
                operSum = <unsigned long>operSum
            self.registers.regWrite(edxReg, (operSum>>operSizeInBits))
            if (operSize == OP_SIZE_WORD):
                operSum = <unsigned short>operSum
            elif (operSize == OP_SIZE_DWORD):
                operSum = <unsigned long>operSum
            self.registers.regWrite(eaxReg, operSum)
            self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_MUL)
        elif (operOpcodeId == GROUP2_OP_IMUL):
            if (operSize == OP_SIZE_BYTE):
                sop1 = self.registers.regRead(CPU_REGISTER_AX, True)
                sop2 = self.modRMInstance.modRMLoad(operSize, True, True)
                self.registers.regWrite(CPU_REGISTER_AX, <unsigned short>((<char>sop1)*sop2))
                self.registers.setFullFlags(sop1, sop2, operSize, OPCODE_IMUL)
                return
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
            sop1 = self.registers.regRead(eaxReg, True)
            sop2 = self.modRMInstance.modRMLoad(operSize, True, True)
            operSum = sop1*sop2
            if (operSize == OP_SIZE_WORD):
                operSum = <unsigned long>operSum
            self.registers.regWrite(edxReg, (operSum>>operSizeInBits))
            if (operSize == OP_SIZE_WORD):
                operSum = <unsigned short>operSum
            elif (operSize == OP_SIZE_DWORD):
                operSum = <unsigned long>operSum
            self.registers.regWrite(eaxReg, operSum)
            self.registers.setFullFlags(sop1, sop2, operSize, OPCODE_IMUL)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_DIV):
            op1Word = self.registers.regRead(CPU_REGISTER_AX, False)
            if (operOp2 == 0):
                raise ChemuException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(op1Word, operOp2)
            if (temp > <unsigned char>bitMask):
                raise ChemuException(CPU_EXCEPTION_DE)
            self.registers.regWrite(CPU_REGISTER_AL, <unsigned char>temp)
            self.registers.regWrite(CPU_REGISTER_AH, <unsigned char>tempmod)
            self.registers.setFullFlags(op1Word, operOp2, operSize, OPCODE_DIV)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_IDIV):
            bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
            sop1  = self.registers.regRead(CPU_REGISTER_AX, True)
            sop2  = self.modRMInstance.modRMLoad(operSize, True, True)
            operOp2 = abs(sop2)
            if (operOp2 == 0):
                raise ChemuException(CPU_EXCEPTION_DE)
            elif (sop1 >= 0):
                temp, tempmod = divmod(sop1, operOp2)
                if (sop2 != operOp2):
                    temp = -temp
            else:
                temp, tempmod = divmod(sop1, sop2)
            if (((temp >= <unsigned char>bitMaskHalf) or (temp < -(<signed short>bitMaskHalf)))):
                raise ChemuException(CPU_EXCEPTION_DE)
            self.registers.regWrite(CPU_REGISTER_AL, <unsigned char>temp)
            self.registers.regWrite(CPU_REGISTER_AH, <unsigned char>tempmod)
            self.registers.setFullFlags(sop1, operOp2, operSize, OPCODE_DIV)
        elif (operOpcodeId == GROUP2_OP_DIV):
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
            operOp1  = self.registers.regRead(edxReg, False)<<operSizeInBits
            operOp1 |= self.registers.regRead(eaxReg, False)
            if (operOp2 == 0):
                raise ChemuException(CPU_EXCEPTION_DE)
            utemp, tempmod = divmod(operOp1, operOp2)
            if (utemp > <unsigned long>bitMask):
                raise ChemuException(CPU_EXCEPTION_DE)
            if (operSize == OP_SIZE_WORD):
                utemp = <unsigned short>utemp
                tempmod = <unsigned short>tempmod
            else:
                utemp = <unsigned long>utemp
                tempmod = <unsigned long>tempmod
            self.registers.regWrite(eaxReg, utemp)
            self.registers.regWrite(edxReg, tempmod)
            self.registers.setFullFlags(operOp1, operOp2, operSize, OPCODE_DIV)
        elif (operOpcodeId == GROUP2_OP_IDIV):
            bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
            doubleBitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize<<1)
            eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, operSize)
            operOp1 = self.registers.regRead(edxReg, False)<<operSizeInBits
            operOp1 |= self.registers.regRead(eaxReg, False)
            if (operOp1 & doubleBitMaskHalf):
                sop1 = operOp1-doubleBitMaskHalf
                sop1 -= doubleBitMaskHalf
            else:
                sop1 = operOp1
            sop2 = self.modRMInstance.modRMLoad(operSize, True, True)
            operOp2 = abs(sop2)
            if (operOp2 == 0):
                raise ChemuException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(sop1, sop2)
            if (((temp >= <unsigned long>bitMaskHalf) or (temp < -(<signed long long>bitMaskHalf)))):
                raise ChemuException(CPU_EXCEPTION_DE)
            if (operSize == OP_SIZE_WORD):
                temp = <unsigned short>temp
                tempmod = <unsigned short>tempmod
            else:
                temp = <unsigned long>temp
                tempmod = <unsigned long>tempmod
            self.registers.regWrite(eaxReg, temp)
            self.registers.regWrite(edxReg, tempmod)
            self.registers.setFullFlags(sop1, operOp2, operSize, OPCODE_DIV)
        else:
            self.main.printMsg("opcodeGroup2_RM: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef interrupt(self, short intNum, long errorCode): # TODO: complete this!
        cdef unsigned char inProtectedMode, entryType, entrySize, \
                              entryNeededDPL, entryPresent
        cdef unsigned short segId, entrySegment
        cdef unsigned long entryEip, eflagsClearThis
        cdef IdtEntry idtEntry
        entryType, entrySize, entryPresent, eflagsClearThis = IDT_INTR_TYPE_INTERRUPT, OP_SIZE_WORD, True, (FLAG_TF | FLAG_RF)
        inProtectedMode = (<Segments>self.registers.segments).isInProtectedMode()
        if (inProtectedMode):
            eflagsClearThis |= (FLAG_NT | FLAG_VM)
        else:
            eflagsClearThis |= FLAG_AC
        segId = CPU_SEGMENT_DS
        if (intNum == -1):
            intNum = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        if (inProtectedMode):
            idtEntry = (<IdtEntry>(<Idt>(<Segments>self.registers.segments).idt).getEntry(<unsigned char>intNum))
            entrySegment = idtEntry.entrySegment
            entryEip = idtEntry.entryEip
            entryType = idtEntry.entryType
            entrySize = idtEntry.entrySize
            entryNeededDPL = idtEntry.entryNeededDPL
            entryPresent = idtEntry.entryPresent
        else:
            (<Idt>(<Segments>self.registers.segments).idt).getEntryRealMode(intNum, &entrySegment, <unsigned short*>&entryEip)
            if ((entrySegment == 0xf000 and intNum != 0x10) or (entrySegment == 0xc000 and intNum == 0x10)):
                if (self.main.platform.pythonBios.interrupt(intNum)):
                    return
        ##self.main.debug("Interrupt: Go Interrupt {0:#04x}. CS: {1:#06x}, (E)IP: {2:#06x}", intNum, entrySegment, entryEip)
        if (inProtectedMode):
            if ((self.registers.cpl and self.registers.cpl > entrySegment&3) or (<Segments>self.registers.segments).getSegDPL(entrySegment)):
                self.main.exitError("Interrupt: (cpl!=0 and cpl>rpl) or dpl!=0")
                return
            entrySegment = ((entrySegment&0xfffc)|(self.registers.cpl&3))
            if (self.registers.cpl&3 != entrySegment&3): # FIXME
                self.main.printMsg("Opcodes::interrupt: cpl&3 != entrySegment&3. What to do here???")
                self.stackPushSegId(CPU_SEGMENT_SS, entrySize)
                self.stackPushRegId(CPU_REGISTER_ESP, entrySize)
        if (entryType == IDT_INTR_TYPE_INTERRUPT):
            eflagsClearThis |= FLAG_IF
        self.stackPushRegId(CPU_REGISTER_EFLAGS, entrySize)
        self.registers.setEFLAG(eflagsClearThis, False)
        self.stackPushSegId(CPU_SEGMENT_CS, entrySize)
        self.stackPushRegId(self.registers.eipSizeRegId, entrySize)
        self.registers.segWrite(CPU_SEGMENT_CS, entrySegment)
        self.registers.regWrite(CPU_REGISTER_EIP, entryEip)
        if (inProtectedMode and errorCode != -1):
            self.stackPushValue(errorCode, entrySize)
    cdef into(self):
        if (self.registers.getEFLAG(FLAG_OF)):
            self.interrupt(CPU_EXCEPTION_OF, -1)
    cdef int3(self):
        self.interrupt(CPU_EXCEPTION_BP, -1)
    cdef iret(self):
        cdef unsigned char inProtectedMode
        cdef unsigned short SSsel, intrSeg
        cdef unsigned long tempEFLAGS, EFLAGS, newEIP, eflagsMask, temp
        inProtectedMode = (<Segments>self.registers.segments).isInProtectedMode()
        if (not inProtectedMode and self.registers.operSize == OP_SIZE_DWORD):
            newEIP = self.stackGetValue()
            if ((newEIP>>16)!=0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
        intrSeg = self.registers.segRead(CPU_SEGMENT_CS)
        self.stackPopRegId(CPU_REGISTER_EIP)
        self.stackPopSegId(CPU_SEGMENT_CS)
        tempEFLAGS = self.stackPopValue()
        EFLAGS = self.registers.regRead(CPU_REGISTER_EFLAGS, False)
        if (((EFLAGS | tempEFLAGS) & (FLAG_NT | FLAG_VM)) != 0):
            self.main.exitError("Opcodes::iret: VM86-Mode isn't supported yet.")
        if (inProtectedMode):
            if (self.registers.cpl&3 != intrSeg&3): # TODO
                self.main.printMsg("Opcodes::iret: cpl!=intrSeg&3. What to do here???")
            else: # RPL==CPL
                eflagsMask = FLAG_CF | FLAG_PF | FLAG_AF | FLAG_ZF | FLAG_SF | \
                             FLAG_TF | FLAG_DF | FLAG_OF | FLAG_NT
                if (self.registers.operSize in (OP_SIZE_DWORD, OP_SIZE_QWORD)):
                    eflagsMask |= FLAG_RF | FLAG_AC | FLAG_ID
                if (self.registers.cpl < self.registers.iopl):
                    eflagsMask |= FLAG_IF
                if (not self.registers.cpl):
                    eflagsMask |= FLAG_IOPL
                    if (self.registers.operSize in (OP_SIZE_DWORD, OP_SIZE_QWORD)):
                        eflagsMask |= FLAG_VIF | FLAG_VIP
                temp = tempEFLAGS&eflagsMask
                tempEFLAGS &= ~eflagsMask
                tempEFLAGS |= temp
        else:
            if (self.registers.operSize == OP_SIZE_DWORD):
                tempEFLAGS = ((tempEFLAGS & 0x257fd5) | (EFLAGS & 0x1a0000))
            else:
                tempEFLAGS = <unsigned short>tempEFLAGS
                tempEFLAGS |= (EFLAGS&0xffff0000)
        self.registers.regWrite(CPU_REGISTER_EFLAGS, tempEFLAGS)
    cdef aad(self):
        cdef unsigned char imm8, tempAL, tempAH
        imm8 = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        tempAL = self.registers.regRead(CPU_REGISTER_AL, False)
        tempAH = self.registers.regRead(CPU_REGISTER_AH, False)
        tempAL = <unsigned char>(self.registers.regWrite(CPU_REGISTER_AX, <unsigned char>(tempAL + (tempAH * imm8))))
        self.registers.setSZP_C0_O0_A0(tempAL, OP_SIZE_BYTE)
    cdef aam(self):
        cdef unsigned char imm8, tempAL, ALdiv, ALmod
        imm8 = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        if (imm8 == 0):
            raise ChemuException(CPU_EXCEPTION_DE)
        tempAL = self.registers.regRead(CPU_REGISTER_AL, False)
        ALdiv, ALmod = divmod(tempAL, imm8)
        self.registers.regWrite(CPU_REGISTER_AH, ALdiv)
        self.registers.regWrite(CPU_REGISTER_AL, ALmod)
        self.registers.setSZP_C0_O0_A0(ALmod, OP_SIZE_BYTE)
    cdef aaa(self):
        cdef unsigned char AFflag, tempAL, tempAH
        cdef unsigned short tempAX
        tempAX = self.registers.regRead(CPU_REGISTER_AX, False)
        tempAL = <unsigned char>tempAX
        tempAH = (tempAX>>8)
        AFflag = self.registers.getEFLAG(FLAG_AF)!=0
        if (((tempAL&0xf)>9) or AFflag):
            tempAL += 6
            self.registers.setEFLAG(FLAG_AF | FLAG_CF, True)
            self.registers.regAdd(CPU_REGISTER_AH, 1)
            self.registers.regWrite(CPU_REGISTER_AL, tempAL&0xf)
        else:
            self.registers.setEFLAG(FLAG_AF | FLAG_CF, False)
            self.registers.regWrite(CPU_REGISTER_AL, tempAL&0xf)
        self.registers.setSZP_O0(self.registers.regRead(CPU_REGISTER_AL, False), OP_SIZE_BYTE)
    cdef aas(self):
        cdef unsigned char AFflag, tempAL, tempAH
        cdef unsigned short tempAX
        tempAX = self.registers.regRead(CPU_REGISTER_AX, False)
        tempAL = <unsigned char>tempAX
        tempAH = (tempAX>>8)
        AFflag = self.registers.getEFLAG(FLAG_AF)!=0
        if (((tempAL&0xf)>9) or AFflag):
            tempAL -= 6
            self.registers.setEFLAG(FLAG_AF | FLAG_CF, True)
            self.registers.regSub(CPU_REGISTER_AH, 1)
            self.registers.regWrite(CPU_REGISTER_AL, tempAL&0xf)
        else:
            self.registers.setEFLAG(FLAG_AF | FLAG_CF, False)
            self.registers.regWrite(CPU_REGISTER_AL, tempAL&0xf)
        self.registers.setSZP_O0(self.registers.regRead(CPU_REGISTER_AL, False), OP_SIZE_BYTE)
    cdef daa(self):
        cdef unsigned char old_AL, old_AF, old_CF
        old_AL = self.registers.regRead(CPU_REGISTER_AL, False)
        old_AF = self.registers.getEFLAG(FLAG_AF)!=0
        old_CF = self.registers.getEFLAG(FLAG_CF)
        self.registers.setEFLAG(FLAG_CF, False)
        if (((old_AL&0xf)>9) or old_AF):
            self.registers.regAdd(CPU_REGISTER_AL, 0x6)
            self.registers.setEFLAG(FLAG_CF, old_CF or (old_AL+6>BITMASK_BYTE))
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
        old_AF = self.registers.getEFLAG(FLAG_AF)!=0
        old_CF = self.registers.getEFLAG(FLAG_CF)
        self.registers.setEFLAG(FLAG_CF, False)
        if (((old_AL&0xf)>9) or old_AF):
            self.registers.regSub(CPU_REGISTER_AL, 6)
            self.registers.setEFLAG(FLAG_CF, old_CF or (old_AL-6<0))
            self.registers.setEFLAG(FLAG_AF, True)
        else:
            self.registers.setEFLAG(FLAG_AF, False)
        if ((old_AL > 0x99) or old_CF):
            self.registers.regSub(CPU_REGISTER_AL, 0x60)
            self.registers.setEFLAG(FLAG_CF, True)
        self.registers.setSZP_O0(self.registers.regRead(CPU_REGISTER_AL, False), OP_SIZE_BYTE)
    cdef cbw_cwde(self):
        cdef unsigned long op2
        if (self.registers.operSize == OP_SIZE_WORD): # CBW
            op2 = <unsigned short>(self.registers.regRead(CPU_REGISTER_AL, True))
            self.registers.regWrite(CPU_REGISTER_AX, op2)
        elif (self.registers.operSize == OP_SIZE_DWORD): # CWDE
            op2 = <unsigned long>(self.registers.regRead(CPU_REGISTER_AX, True))
            self.registers.regWrite(CPU_REGISTER_EAX, op2)
        else:
            self.main.exitError("cbw_cwde: operSize {0:d} not in (OP_SIZE_WORD, OP_SIZE_DWORD))", self.registers.operSize)
    cdef cwd_cdq(self):
        cdef unsigned short eaxReg, edxReg
        cdef unsigned long bitMask, bitMaskHalf, op2
        bitMask = (<Misc>self.main.misc).getBitMaskFF(self.registers.operSize)
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(self.registers.operSize)
        eaxReg = self.registers.getWordAsDword(CPU_REGISTER_AX, self.registers.operSize)
        edxReg = self.registers.getWordAsDword(CPU_REGISTER_DX, self.registers.operSize)
        op2 = self.registers.regRead(eaxReg, False)
        if (op2&bitMaskHalf):
            self.registers.regWrite(edxReg, bitMask)
        else:
            self.registers.regWrite(edxReg, 0)
    cdef shlFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char newCF, newOF
        cdef unsigned long bitMaskHalf, dest
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoad(operSize, False, True)
        count = count&0x1f
        if (count == 0):
            newCF = False
        else:
            newCF = ((dest<<(count-1))&bitMaskHalf)!=0
        dest = <unsigned long>(dest<<count)
        if (operSize == OP_SIZE_WORD):
            dest = <unsigned short>dest
        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        if (count == 0):
            return
        elif (count == 1):
            newOF = (((dest&bitMaskHalf)!=0)^newCF)
            self.registers.setEFLAG(FLAG_OF, newOF)
        else:
            self.registers.setEFLAG(FLAG_OF, False)
        self.registers.setEFLAG(FLAG_CF, newCF)
        self.registers.setSZP(dest, operSize)
    cdef sarFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char newCF
        cdef unsigned long bitMask
        cdef long dest
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        dest = self.modRMInstance.modRMLoad(operSize, True, True)
        count = count&0x1f
        if (count == 0):
            newCF = ((dest)&1)
        else:
            newCF = ((dest>>(count-1))&1)
        dest >>= count
        self.modRMInstance.modRMSave(operSize, dest&bitMask, True, OPCODE_SAVE)
        if (count == 0):
            return
        elif (count == 1):
            self.registers.setEFLAG(FLAG_OF, False)
        self.registers.setEFLAG(FLAG_CF, newCF)
        self.registers.setSZP(dest, operSize)
    cdef shrFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char newCF_OF
        cdef unsigned long bitMaskHalf, dest, tempDest
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoad(operSize, False, True)
        tempDest = dest
        count = count&0x1f
        if (count == 0):
            newCF_OF = ((dest)&1)
        else:
            newCF_OF = ((dest>>(count-1))&1)
        dest >>= count
        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        if (count == 0):
            return
        self.registers.setEFLAG(FLAG_CF, newCF_OF)
        newCF_OF = ((tempDest)&bitMaskHalf)!=0
        self.registers.setEFLAG(FLAG_OF, newCF_OF)
        self.registers.setSZP(dest, operSize)
    cdef rclFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char tempCF_OF, newCF, i
        cdef unsigned long bitMaskHalf, dest
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoad(operSize, False, True)
        count = count&0x1f
        if (operSize == OP_SIZE_BYTE):
            count %= 9
        elif (operSize == OP_SIZE_WORD):
            count %= 17
        newCF = self.registers.getEFLAG(FLAG_CF)
        for i in range(count):
            tempCF_OF = (dest&bitMaskHalf)!=0
            dest = <unsigned long>((dest<<1)|newCF)
            if (operSize == OP_SIZE_WORD):
                dest = <unsigned short>dest
            newCF = tempCF_OF
        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        if (count == 0):
            return
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.setEFLAG(FLAG_OF, tempCF_OF)
        self.registers.setEFLAG(FLAG_CF, newCF)
    cdef rcrFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char tempCF_OF, newCF, i
        cdef unsigned long bitMaskHalf, dest
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoad(operSize, False, True)
        count = count&0x1f
        newCF = self.registers.getEFLAG(FLAG_CF)
        if (operSize == OP_SIZE_BYTE):
            count %= 9
        elif (operSize == OP_SIZE_WORD):
            count %= 17

        if (count == 0):
            return
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        self.registers.setEFLAG(FLAG_OF, tempCF_OF)

        for i in range(count):
            tempCF_OF = (dest&1)
            dest = (dest >> 1) | (newCF * bitMaskHalf)
            newCF = tempCF_OF

        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        self.registers.setEFLAG(FLAG_CF, newCF)
    cdef rolFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char tempCF_OF, newCF, i
        cdef unsigned long bitMaskHalf, dest
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoad(operSize, False, True)

        if ((count & 0x1f) > 0):
            count = count%(operSize<<3)
            for i in range(count):
                tempCF_OF = (dest&bitMaskHalf)!=0
                dest = <unsigned long>((dest << 1) | tempCF_OF)
                if (operSize == OP_SIZE_WORD):
                    dest = <unsigned short>dest
            self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
            if (count == 0):
                return
            newCF = dest&1
            self.registers.setEFLAG(FLAG_CF, newCF)
            tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
            self.registers.setEFLAG(FLAG_OF, tempCF_OF)
    cdef rorFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char tempCF_OF, newCF_M1, i
        cdef unsigned long bitMaskHalf, dest, destM1
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoad(operSize, False, True)
        destM1 = dest

        if ((count & 0x1f) > 0):
            count = count%(operSize<<3)

            for i in range(count):
                destM1 = dest
                tempCF_OF = destM1&1
                dest = (destM1 >> 1) | (tempCF_OF * bitMaskHalf)

            self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)

            if (count == 0):
                return
            tempCF_OF = (dest&bitMaskHalf)!=0
            newCF_M1 = (destM1&bitMaskHalf)!=0
            self.registers.setEFLAG(FLAG_CF, tempCF_OF)
            tempCF_OF = (tempCF_OF ^ newCF_M1)
            self.registers.setEFLAG(FLAG_OF, tempCF_OF)
    cdef opcodeGroup4_RM_1(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId
        operOpcode = self.registers.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        ##self.main.debug("Group4_RM_1: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (operOpcodeId in (GROUP4_OP_SHL_SAL, GROUP4_OP_SHL_SAL_ALIAS)):
            self.shlFunc(operSize, 1)
        elif (operOpcodeId == GROUP4_OP_SAR):
            self.sarFunc(operSize, 1)
        elif (operOpcodeId == GROUP4_OP_SHR):
            self.shrFunc(operSize, 1)
        elif (operOpcodeId == GROUP4_OP_RCL):
            self.rclFunc(operSize, 1)
        elif (operOpcodeId == GROUP4_OP_RCR):
            self.rcrFunc(operSize, 1)
        elif (operOpcodeId == GROUP4_OP_ROL):
            self.rolFunc(operSize, 1)
        elif (operOpcodeId == GROUP4_OP_ROR):
            self.rorFunc(operSize, 1)
        else:
            self.main.printMsg("opcodeGroup4_RM_1: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroup4_RM_CL(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId, count
        operOpcode = self.registers.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        ##self.main.debug("Group4_RM_CL: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        count = self.registers.regRead(CPU_REGISTER_CL, False)
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
            self.main.printMsg("opcodeGroup4_RM_CL: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroup4_RM_IMM8(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId, count
        operOpcode = self.registers.getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        ##self.main.debug("Group4_RM_IMM8: operOpcodeId=={0:d}", operOpcodeId)
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        count = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
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
            self.main.printMsg("opcodeGroup4_RM_IMM8: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef sahf(self):
        cdef unsigned short flagsVal
        flagsVal = self.registers.regRead(CPU_REGISTER_FLAGS, False)&0xff00
        flagsVal |= self.registers.regRead(CPU_REGISTER_AH, False)
        flagsVal &= (0xff00 | FLAG_SF | FLAG_ZF | FLAG_AF | FLAG_PF | FLAG_CF)
        flagsVal |= FLAG_REQUIRED
        self.registers.regWrite(CPU_REGISTER_FLAGS, flagsVal)
    cdef lahf(self):
        cdef unsigned char flagsVal
        flagsVal = <unsigned char>(self.registers.regRead(CPU_REGISTER_FLAGS, False))
        flagsVal &= (FLAG_SF | FLAG_ZF | FLAG_AF | FLAG_PF | FLAG_CF)
        flagsVal |= FLAG_REQUIRED
        self.registers.regWrite(CPU_REGISTER_AH, flagsVal)
    cdef xchgFuncReg(self, unsigned short regName, unsigned short regName2):
        cdef unsigned long regValue, regValue2
        regValue, regValue2 = self.registers.regRead(regName, False), self.registers.regRead(regName2, False)
        self.registers.regWrite(regName, regValue2)
        self.registers.regWrite(regName2, regValue)
    ##### DON'T USE XCHG AX, AX FOR OPCODE 0x90, use NOP instead!!
    cdef xchgReg(self):
        cdef unsigned short regName, regName2
        regName  = self.registers.getWordAsDword(CPU_REGISTER_AX, self.registers.operSize)
        regName2 = self.registers.getWordAsDword(CPU_REGISTER_WORD[self.main.cpu.opcode&7], self.registers.operSize)
        self.xchgFuncReg(regName, regName2)
    cdef xchgR_RM(self, unsigned char operSize):
        cdef unsigned long op1, op2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.modRMInstance.modRLoad(operSize, False)
        op2 = self.modRMInstance.modRMLoad(operSize, False, True)
        self.modRMInstance.modRSave(operSize, op2, OPCODE_SAVE)
        self.modRMInstance.modRMSave(operSize, op1, True, OPCODE_SAVE)
    cdef enter(self):
        cdef unsigned char stackSize, nestingLevel, i
        cdef unsigned short sizeOp, espNameStack, ebpNameStack
        cdef unsigned long frameTemp, temp
        sizeOp = self.registers.getCurrentOpcodeAdd(OP_SIZE_WORD, False)
        nestingLevel = self.registers.getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        nestingLevel %= 32
        stackSize = self.registers.getAddrSegSize(CPU_SEGMENT_SS)
        espNameStack = self.registers.getWordAsDword(CPU_REGISTER_SP, stackSize)
        ebpNameStack = self.registers.getWordAsDword(CPU_REGISTER_BP, stackSize)
        self.stackPushRegId(ebpNameStack, stackSize)
        frameTemp = self.registers.regRead(espNameStack, False)
        if (nestingLevel > 1):
            for i in range(nestingLevel-1):
                self.registers.regSub(ebpNameStack, self.registers.operSize)
                temp = self.registers.mmReadValueUnsigned(self.registers.regRead(ebpNameStack, False), \
                  self.registers.operSize, CPU_SEGMENT_SS, False)
                self.stackPushValue(temp, self.registers.operSize)
        if (nestingLevel >= 1):
            self.stackPushValue(frameTemp, self.registers.operSize)
        self.registers.regWrite(ebpNameStack, frameTemp)
        self.registers.regSub(espNameStack, sizeOp)
    cdef leave(self):
        cdef unsigned char stackAddrSize
        cdef unsigned short espName, ebpName
        stackAddrSize = self.registers.getAddrSegSize(CPU_SEGMENT_SS)
        espName = self.registers.getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        ebpName = self.registers.getWordAsDword(CPU_REGISTER_BP, stackAddrSize)
        self.registers.regWrite(espName, self.registers.regRead(ebpName, False))
        ebpName = self.registers.getWordAsDword(CPU_REGISTER_BP, self.registers.operSize)
        self.stackPopRegId(ebpName)
    cdef cmovFunc(self, unsigned char cond): # R16, R/M 16; R32, R/M 32
        self.movR_RM(self.registers.operSize, cond)
    cdef setWithCondFunc(self, unsigned char cond): # if cond==True set 1, else 0
        self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
        self.modRMInstance.modRMSave(OP_SIZE_BYTE, cond!=0, True, OPCODE_SAVE)
    cdef arpl(self):
        cdef unsigned short op1, op2
        if (not (<Segments>self.registers.segments).isInProtectedMode()):
            raise ChemuException(CPU_EXCEPTION_UD)
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
        op1 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
        op2 = self.modRMInstance.modRLoad(OP_SIZE_WORD, False)
        if (op1 < op2):
            self.registers.setEFLAG(FLAG_ZF, True)
            self.modRMInstance.modRMSave(OP_SIZE_WORD, (op1&0xfffc)|(op2&3), True, OPCODE_SAVE)
        else:
            self.registers.setEFLAG(FLAG_ZF, False)
    cdef bound(self):
        cdef unsigned long returnInt
        cdef long index, lowerBound, upperBound
        self.modRMInstance.modRMOperands(self.registers.operSize, MODRM_FLAGS_NONE)
        index = self.modRMInstance.modRLoad(self.registers.operSize, True)
        returnInt = self.modRMInstance.getRMValueFull(self.registers.addrSize)
        lowerBound = self.registers.mmReadValueSigned(returnInt, self.registers.operSize, self.modRMInstance.rmNameSegId, True)
        upperBound = self.registers.mmReadValueSigned(returnInt+self.registers.operSize, self.registers.operSize, self.modRMInstance.rmNameSegId, True)
        if (index < lowerBound or index > upperBound+self.registers.operSize):
            raise ChemuException(CPU_EXCEPTION_BR)
    cdef btFunc(self, unsigned long offset, unsigned char newValType):
        cdef unsigned char operSizeInBits, state
        cdef unsigned long value, address
        operSizeInBits = self.registers.operSize << 3
        address = 0
        if (self.modRMInstance.mod == 3): # register operand
            offset %= operSizeInBits
            value = self.modRMInstance.modRLoad(self.registers.operSize, False)
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
    cdef run(self):
        self.modRMInstance = ModRMClass(self.main, (<Registers>self.main.cpu.registers))
    # end of opcodes



