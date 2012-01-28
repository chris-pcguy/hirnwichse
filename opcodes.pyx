
from misc import ChemuException
from sys import exc_info


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
    def __init__(self, object main):
        self.main = main
    cdef unsigned char executeOpcode(self, unsigned char opcode):
        cdef unsigned char operSize, addrSize
        try:
            (<Registers>self.main.cpu.registers).getOpAddrCodeSegSize(&operSize, &addrSize)
            if (opcode == 0x00):
                self.opcodeRM_R(OPCODE_ADD, OP_SIZE_BYTE)
            elif (opcode == 0x01):
                self.opcodeRM_R(OPCODE_ADD, operSize)
            elif (opcode == 0x02):
                self.opcodeR_RM(OPCODE_ADD, OP_SIZE_BYTE)
            elif (opcode == 0x03):
                self.opcodeR_RM(OPCODE_ADD, operSize)
            elif (opcode == 0x04):
                self.opcodeAxEaxImm(OPCODE_ADD, OP_SIZE_BYTE)
            elif (opcode == 0x05):
                self.opcodeAxEaxImm(OPCODE_ADD, operSize)
            elif (opcode == 0x06):
                self.pushSeg(-1)
            elif (opcode == 0x07):
                self.popSeg(-1)
            elif (opcode == 0x08):
                self.opcodeRM_R(OPCODE_OR, OP_SIZE_BYTE)
            elif (opcode == 0x09):
                self.opcodeRM_R(OPCODE_OR, operSize)
            elif (opcode == 0x0a):
                self.opcodeR_RM(OPCODE_OR, OP_SIZE_BYTE)
            elif (opcode == 0x0b):
                self.opcodeR_RM(OPCODE_OR, operSize)
            elif (opcode == 0x0c):
                self.opcodeAxEaxImm(OPCODE_OR, OP_SIZE_BYTE)
            elif (opcode == 0x0d):
                self.opcodeAxEaxImm(OPCODE_OR, operSize)
            elif (opcode == 0x0e):
                self.pushSeg(-1)
            elif (opcode == 0x0f):
                self.opcodeGroup0F()
            elif (opcode == 0x10):
                self.opcodeRM_R(OPCODE_ADC, OP_SIZE_BYTE)
            elif (opcode == 0x11):
                self.opcodeRM_R(OPCODE_ADC, operSize)
            elif (opcode == 0x12):
                self.opcodeR_RM(OPCODE_ADC, OP_SIZE_BYTE)
            elif (opcode == 0x13):
                self.opcodeR_RM(OPCODE_ADC, operSize)
            elif (opcode == 0x14):
                self.opcodeAxEaxImm(OPCODE_ADC, OP_SIZE_BYTE)
            elif (opcode == 0x15):
                self.opcodeAxEaxImm(OPCODE_ADC, operSize)
            elif (opcode == 0x16):
                self.pushSeg(-1)
            elif (opcode == 0x17):
                self.popSeg(-1)
            elif (opcode == 0x18):
                self.opcodeRM_R(OPCODE_SBB, OP_SIZE_BYTE)
            elif (opcode == 0x19):
                self.opcodeRM_R(OPCODE_SBB, operSize)
            elif (opcode == 0x1a):
                self.opcodeR_RM(OPCODE_SBB, OP_SIZE_BYTE)
            elif (opcode == 0x1b):
                self.opcodeR_RM(OPCODE_SBB, operSize)
            elif (opcode == 0x1c):
                self.opcodeAxEaxImm(OPCODE_SBB, OP_SIZE_BYTE)
            elif (opcode == 0x1d):
                self.opcodeAxEaxImm(OPCODE_SBB, operSize)
            elif (opcode == 0x1e):
                self.pushSeg(-1)
            elif (opcode == 0x1f):
                self.popSeg(-1)
            elif (opcode == 0x20):
                self.opcodeRM_R(OPCODE_AND, OP_SIZE_BYTE)
            elif (opcode == 0x21):
                self.opcodeRM_R(OPCODE_AND, operSize)
            elif (opcode == 0x22):
                self.opcodeR_RM(OPCODE_AND, OP_SIZE_BYTE)
            elif (opcode == 0x23):
                self.opcodeR_RM(OPCODE_AND, operSize)
            elif (opcode == 0x24):
                self.opcodeAxEaxImm(OPCODE_AND, OP_SIZE_BYTE)
            elif (opcode == 0x25):
                self.opcodeAxEaxImm(OPCODE_AND, operSize)
            elif (opcode == 0x27):
                self.daa()
            elif (opcode == 0x28):
                self.opcodeRM_R(OPCODE_SUB, OP_SIZE_BYTE)
            elif (opcode == 0x29):
                self.opcodeRM_R(OPCODE_SUB, operSize)
            elif (opcode == 0x2a):
                self.opcodeR_RM(OPCODE_SUB, OP_SIZE_BYTE)
            elif (opcode == 0x2b):
                self.opcodeR_RM(OPCODE_SUB, operSize)
            elif (opcode == 0x2c):
                self.opcodeAxEaxImm(OPCODE_SUB, OP_SIZE_BYTE)
            elif (opcode == 0x2d):
                self.opcodeAxEaxImm(OPCODE_SUB, operSize)
            elif (opcode == 0x2f):
                self.das()
            elif (opcode == 0x30):
                self.opcodeRM_R(OPCODE_XOR, OP_SIZE_BYTE)
            elif (opcode == 0x31):
                self.opcodeRM_R(OPCODE_XOR, operSize)
            elif (opcode == 0x32):
                self.opcodeR_RM(OPCODE_XOR, OP_SIZE_BYTE)
            elif (opcode == 0x33):
                self.opcodeR_RM(OPCODE_XOR, operSize)
            elif (opcode == 0x34):
                self.opcodeAxEaxImm(OPCODE_XOR, OP_SIZE_BYTE)
            elif (opcode == 0x35):
                self.opcodeAxEaxImm(OPCODE_XOR, operSize)
            elif (opcode == 0x37):
                self.aaa()
            elif (opcode == 0x38):
                self.opcodeRM_R(OPCODE_CMP, OP_SIZE_BYTE)
            elif (opcode == 0x39):
                self.opcodeRM_R(OPCODE_CMP, operSize)
            elif (opcode == 0x3a):
                self.opcodeR_RM(OPCODE_CMP, OP_SIZE_BYTE)
            elif (opcode == 0x3b):
                self.opcodeR_RM(OPCODE_CMP, operSize)
            elif (opcode == 0x3c):
                self.opcodeAxEaxImm(OPCODE_CMP, OP_SIZE_BYTE)
            elif (opcode == 0x3d):
                self.opcodeAxEaxImm(OPCODE_CMP, operSize)
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
            elif (opcode >= 0x70 and opcode <= 0x7f):
                self.jumpShort(OP_SIZE_BYTE, (<Registers>self.main.cpu.registers).getCond(opcode&0xf))
            elif (opcode == 0x80):
                self.opcodeGroup1_RM_ImmFunc(OP_SIZE_BYTE, True)
            elif (opcode == 0x81):
                self.opcodeGroup1_RM_ImmFunc(operSize, False)
            elif (opcode == 0x83):
                self.opcodeGroup1_RM_ImmFunc(operSize, True)
            elif (opcode == 0x84):
                self.opcodeRM_R(OPCODE_TEST, OP_SIZE_BYTE)
            elif (opcode == 0x85):
                self.opcodeRM_R(OPCODE_TEST, operSize)
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
            elif (opcode == 0x9b): # WAIT/FWAIT
                if ((<Registers>self.main.cpu.registers).getFlag(CPU_REGISTER_CR0, (CR0_FLAG_MP | CR0_FLAG_TS)) == \
                                                                                   (CR0_FLAG_MP | CR0_FLAG_TS)):
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
                self.opcodeAxEaxImm(OPCODE_TEST, OP_SIZE_BYTE)
            elif (opcode == 0xa9):
                self.opcodeAxEaxImm(OPCODE_TEST, operSize)
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
                self.interrupt(-1, -1)
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
            elif (opcode >= 0xd8 and opcode <= 0xdf):
                if ((<Registers>self.main.cpu.registers).getFlag(CPU_REGISTER_CR4, CR4_FLAG_OSFXSR) == 0):
                    raise ChemuException(CPU_EXCEPTION_UD)
                if ((<Registers>self.main.cpu.registers).getFlag(CPU_REGISTER_CR0, (CR0_FLAG_EM | CR0_FLAG_TS)) != 0):
                    raise ChemuException(CPU_EXCEPTION_NM)
                raise ChemuException(CPU_EXCEPTION_UD)
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
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_IF, False)
    cdef sti(self):
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_IF, True)
        self.main.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
    cdef cld(self):
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_DF, False)
    cdef std(self):
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_DF, True)
    cdef clc(self):
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, False)
    cdef stc(self):
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, True)
    cdef cmc(self):
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, (<Registers>self.main.cpu.registers).getEFLAG(FLAG_CF)==0)
    cdef hlt(self):
        self.main.cpu.cpuHalted = True
    cdef nop(self):
        # TODO: maybe implement PAUSE-Opcode (F3 90 / REPE NOP)
        pass
    cdef syncProtectedModeState(self):
        (<Segments>(<Registers>self.main.cpu.registers).segments).protectedModeOn = (<Registers>self.main.cpu.registers).getFlag(CPU_REGISTER_CR0, CR0_FLAG_PE)
        if ((<Segments>(<Registers>self.main.cpu.registers).segments).isInProtectedMode()):
            (<Gdt>(<Registers>self.main.cpu.registers).segments.gdt).loadTableData()
    cdef jumpFarAbsolutePtr(self):
        cdef unsigned char operSize
        cdef unsigned short cs
        cdef unsigned long eip
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        eip = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(operSize, False)
        cs = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_WORD, False)
        self.syncProtectedModeState()
        (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EIP, eip)
        (<Registers>self.main.cpu.registers).segWrite(CPU_SEGMENT_CS, cs)
    cdef jumpShortRelativeByte(self):
        self.jumpShort(OP_SIZE_BYTE, True)
    cdef jumpShortRelativeWordDWord(self):
        cdef unsigned char offsetSize
        offsetSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        self.jumpShort(offsetSize, True)
    cdef loop(self):
        self.loopFunc(OPCODE_LOOP)
    cdef loope(self):
        self.loopFunc(OPCODE_LOOPE)
    cdef loopne(self):
        self.loopFunc(OPCODE_LOOPNE)
    cdef loopFunc(self, unsigned char loopType):
        cdef unsigned char operSize, addrSize, cond, oldZF
        cdef unsigned short countReg
        cdef unsigned long bitMask
        cdef long long countOrNewEip
        cdef char rel8
        (<Registers>self.main.cpu.registers).getOpAddrCodeSegSize(&operSize, &addrSize)
        countReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_CX, addrSize)
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        oldZF = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_ZF)!=0
        rel8 = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, True)
        countOrNewEip = (<Registers>self.main.cpu.registers).regSub(countReg, 1)
        cond = False
        if (loopType == OPCODE_LOOPE and oldZF):
            cond = True
        elif (loopType == OPCODE_LOOPNE and not oldZF):
            cond = True
        elif (loopType == OPCODE_LOOP):
            cond = True
        if (cond and countOrNewEip != 0):
            countOrNewEip = ((<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_EIP, False)+rel8)&bitMask
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EIP, countOrNewEip)
    cdef opcodeR_RM(self, unsigned char opcode, unsigned char operSize):
        cdef unsigned long op1, op2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (opcode not in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op1 = self.modRMInstance.modRLoad(operSize, False)
        op2 = self.modRMInstance.modRMLoad(operSize, False, True)
        if (opcode in (OPCODE_ADD, OPCODE_ADC, OPCODE_SUB, OPCODE_SBB)):
            self.modRMInstance.modRSave(operSize, op2, opcode)
            (<Registers>self.main.cpu.registers).setFullFlags(op1, op2, operSize, opcode, False)
        elif (opcode == OPCODE_CMP):
            (<Registers>self.main.cpu.registers).setFullFlags(op1, op2, operSize, OPCODE_SUB, False)
        elif (opcode in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op2 = self.modRMInstance.modRSave(operSize, op2, opcode)
            (<Registers>self.main.cpu.registers).setSZP_C0_O0_A0(op2, operSize)
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
            (<Registers>self.main.cpu.registers).setFullFlags(op1, op2, operSize, opcode, False)
        elif (opcode == OPCODE_CMP):
            (<Registers>self.main.cpu.registers).setFullFlags(op1, op2, operSize, OPCODE_SUB, False)
        elif (opcode in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op2 = self.modRMInstance.modRMSave(operSize, op2, True, opcode)
            (<Registers>self.main.cpu.registers).setSZP_C0_O0_A0(op2, operSize)
        elif (opcode == OPCODE_TEST):
            (<Registers>self.main.cpu.registers).setSZP_C0_O0_A0(op1&op2, operSize)
        else:
            self.main.printMsg("OPCODE::opcodeRM_R: invalid opcode: {0:d}.", opcode)
    cdef opcodeAxEaxImm(self, unsigned char opcode, unsigned char operSize):
        cdef unsigned short dataReg
        cdef unsigned long op1, op2
        dataReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
        if (opcode not in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op1 = (<Registers>self.main.cpu.registers).regRead(dataReg, False)
        op2 = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(operSize, False)
        if (opcode in (OPCODE_ADD, OPCODE_ADC, OPCODE_SUB, OPCODE_SBB)):
            (<Registers>self.main.cpu.registers).regWriteWithOp(dataReg, op2, opcode)
            (<Registers>self.main.cpu.registers).setFullFlags(op1, op2, operSize, opcode, False)
        elif (opcode == OPCODE_CMP):
            (<Registers>self.main.cpu.registers).setFullFlags(op1, op2, operSize, OPCODE_SUB, False)
        elif (opcode in (OPCODE_AND, OPCODE_OR, OPCODE_XOR)):
            op2 = (<Registers>self.main.cpu.registers).regWriteWithOp(dataReg, op2, opcode)
            (<Registers>self.main.cpu.registers).setSZP_C0_O0_A0(op2, operSize)
        elif (opcode == OPCODE_TEST):
            (<Registers>self.main.cpu.registers).setSZP_C0_O0_A0(op1&op2, operSize)
        else:
            self.main.printMsg("OPCODE::opcodeRM_R: invalid opcode: {0:d}.", opcode)
    cdef movImmToR(self, unsigned char operSize):
        cdef unsigned char rReg
        cdef unsigned long src
        rReg = self.main.cpu.opcode&0x7
        src = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(operSize, False)
        if (operSize == OP_SIZE_BYTE):
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_BYTE[rReg], src)
        elif (operSize == OP_SIZE_WORD):
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_WORD[rReg], src)
        elif (operSize == OP_SIZE_DWORD):
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_DWORD[rReg], src)
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
        self.modRMInstance.modRMSave(OP_SIZE_WORD, self.modRMInstance.modSegLoad(), True, OPCODE_SAVE)
    cdef movSREG_RM16(self):
        self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_SREG)
        if (self.modRMInstance.regName == CPU_SEGMENT_CS):
            raise ChemuException(CPU_EXCEPTION_UD)
        self.modRMInstance.modSegSave(OP_SIZE_WORD, self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True))
    cdef movAxMoffs(self, unsigned char operSize, unsigned char addrSize):
        (<Registers>self.main.cpu.registers).regWrite((<unsigned short>(<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)), (<Registers>self.main.cpu.registers).mmReadValueUnsigned((<unsigned long>(<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(addrSize, False)), operSize, CPU_SEGMENT_DS, True))
    cdef movMoffsAx(self, unsigned char operSize, unsigned char addrSize):
        (<Registers>self.main.cpu.registers).mmWriteValue((<unsigned long>(<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(addrSize, False)), (<Registers>self.main.cpu.registers).regRead((<unsigned short>(<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)), False), operSize, CPU_SEGMENT_DS, True)
    cdef stosFunc(self, unsigned char operSize):
        cdef unsigned char addrSize
        cdef unsigned short dataReg, srcReg, countReg
        cdef unsigned long data, countVal
        cdef unsigned long long dataLength
        cdef long long destAddr
        cdef bytes memData
        addrSize = (<Registers>self.main.cpu.registers).getAddrCodeSegSize()
        dataReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DI, addrSize)
        srcReg  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
        data = (<Registers>self.main.cpu.registers).regRead(srcReg, False)
        countReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if ((<Registers>self.main.cpu.registers).repPrefix):
            countVal = (<Registers>self.main.cpu.registers).regRead(countReg, False)
            if (countVal == 0):
                return
        addrSize = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_DF)!=0
        dataLength = operSize*countVal
        destAddr = (<Registers>self.main.cpu.registers).regRead(dataReg, False)
        # addrSize is DF-FLAG
        if (addrSize):
            destAddr -= dataLength-operSize
        memData = data.to_bytes(length=operSize, byteorder="little")*countVal
        (<Registers>self.main.cpu.registers).mmWrite(destAddr, memData, dataLength, CPU_SEGMENT_ES, False)
        if (not addrSize):
            (<Registers>self.main.cpu.registers).regAdd(dataReg, dataLength)
        else:
            (<Registers>self.main.cpu.registers).regSub(dataReg, dataLength)
        self.main.cpu.cycles += countVal
        if ((<Registers>self.main.cpu.registers).repPrefix):
            (<Registers>self.main.cpu.registers).regWrite(countReg, 0)
    cdef movsFunc(self, unsigned char operSize):
        cdef unsigned char addrSize
        cdef unsigned short esiReg, ediReg, countReg
        cdef unsigned long countVal
        cdef unsigned long long dataLength
        cdef long long esiVal, ediVal
        cdef bytes data
        addrSize = (<Registers>self.main.cpu.registers).getAddrCodeSegSize()
        esiReg  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SI, addrSize)
        ediReg  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DI, addrSize)
        countReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if ((<Registers>self.main.cpu.registers).repPrefix):
            countVal = (<Registers>self.main.cpu.registers).regRead(countReg, False)
            if (countVal == 0):
                return
        addrSize = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_DF)!=0
        dataLength = operSize*countVal
        esiVal = (<Registers>self.main.cpu.registers).regRead(esiReg, False)
        ediVal = (<Registers>self.main.cpu.registers).regRead(ediReg, False)
        # addrSize is DF-FLAG
        if (addrSize):
            esiVal -= dataLength-operSize
            ediVal -= dataLength-operSize
        data = (<Registers>self.main.cpu.registers).mmRead(esiVal, dataLength, CPU_SEGMENT_DS, True)
        (<Registers>self.main.cpu.registers).mmWrite(ediVal, data, dataLength, CPU_SEGMENT_ES, False)
        # addrSize is DF-FLAG
        if (not addrSize):
            (<Registers>self.main.cpu.registers).regAdd(esiReg, dataLength)
            (<Registers>self.main.cpu.registers).regAdd(ediReg, dataLength)
        else:
            (<Registers>self.main.cpu.registers).regSub(esiReg, dataLength)
            (<Registers>self.main.cpu.registers).regSub(ediReg, dataLength)
        self.main.cpu.cycles += countVal
        if ((<Registers>self.main.cpu.registers).repPrefix):
            (<Registers>self.main.cpu.registers).regWrite(countReg, 0)
    cdef lodsFunc(self, unsigned char operSize):
        cdef unsigned char addrSize
        cdef unsigned short eaxReg, esiReg, countReg
        cdef unsigned long data, countVal
        cdef unsigned long long dataLength
        cdef long long esiVal
        addrSize = (<Registers>self.main.cpu.registers).getAddrCodeSegSize()
        eaxReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
        esiReg  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SI, addrSize)
        countReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if ((<Registers>self.main.cpu.registers).repPrefix):
            countVal = (<Registers>self.main.cpu.registers).regRead(countReg, False)
            if (countVal == 0):
                return
        addrSize = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_DF)!=0
        dataLength = operSize*countVal
        # addrSize is DF-FLAG
        if (not addrSize):
            esiVal = (<Registers>self.main.cpu.registers).regAdd(esiReg, dataLength)-operSize
        else:
            esiVal = (<Registers>self.main.cpu.registers).regSub(esiReg, dataLength)+operSize
        data = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(esiVal, operSize, CPU_SEGMENT_DS, True)
        (<Registers>self.main.cpu.registers).regWrite(eaxReg, data)
        self.main.cpu.cycles += countVal
        if ((<Registers>self.main.cpu.registers).repPrefix):
            (<Registers>self.main.cpu.registers).regWrite(countReg, 0)
    cdef cmpsFunc(self, unsigned char operSize):
        cdef unsigned char addrSize, zf
        cdef unsigned short esiReg, ediReg, countReg
        cdef unsigned long esiVal, ediVal, countVal, newCount, src1, src2, i
        addrSize = (<Registers>self.main.cpu.registers).getAddrCodeSegSize()
        esiReg  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SI, addrSize)
        ediReg  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DI, addrSize)
        countReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal, newCount = 1, 0
        if ((<Registers>self.main.cpu.registers).repPrefix):
            countVal = (<Registers>self.main.cpu.registers).regRead(countReg, False)
            if (countVal == 0):
                return
        addrSize = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_DF)!=0
        esiVal = (<Registers>self.main.cpu.registers).regRead(esiReg, False)
        ediVal = (<Registers>self.main.cpu.registers).regRead(ediReg, False)
        for i in range(countVal):
            src1 = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(esiVal, operSize, CPU_SEGMENT_DS, True)
            src2 = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(ediVal, operSize, CPU_SEGMENT_ES, False)
            (<Registers>self.main.cpu.registers).setFullFlags(src1, src2, operSize, OPCODE_SUB, False)
            # addrSize is DF-FLAG
            if (not addrSize):
                esiVal = (<Registers>self.main.cpu.registers).regAdd(esiReg, operSize)
                ediVal = (<Registers>self.main.cpu.registers).regAdd(ediReg, operSize)
            else:
                esiVal = (<Registers>self.main.cpu.registers).regSub(esiReg, operSize)
                ediVal = (<Registers>self.main.cpu.registers).regSub(ediReg, operSize)
            zf = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_ZF)!=0
            if (((<Registers>self.main.cpu.registers).repPrefix == OPCODE_PREFIX_REPE and not zf) or \
                ((<Registers>self.main.cpu.registers).repPrefix == OPCODE_PREFIX_REPNE and zf)):
                newCount = countVal-i-1
                break
        self.main.cpu.cycles += countVal-newCount
        if ((<Registers>self.main.cpu.registers).repPrefix):
            (<Registers>self.main.cpu.registers).regWrite(countReg, newCount)
    cdef scasFunc(self, unsigned char operSize):
        cdef unsigned char addrSize, zf
        cdef unsigned short eaxReg, ediReg, countReg
        cdef unsigned long src1, src2, ediVal, countVal, newCount, i
        addrSize = (<Registers>self.main.cpu.registers).getAddrCodeSegSize()
        eaxReg  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
        ediReg  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DI, addrSize)
        countReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal, newCount = 1, 0
        if ((<Registers>self.main.cpu.registers).repPrefix):
            countVal = (<Registers>self.main.cpu.registers).regRead(countReg, False)
            if (countVal == 0):
                return
        addrSize = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_DF)!=0
        for i in range(countVal):
            ediVal = (<Registers>self.main.cpu.registers).regRead(ediReg, False)
            src1 = (<Registers>self.main.cpu.registers).regRead(eaxReg, False)
            src2 = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(ediVal, operSize, CPU_SEGMENT_ES, False)
            (<Registers>self.main.cpu.registers).setFullFlags(src1, src2, operSize, OPCODE_SUB, False)
            # addrSize is DF-FLAG
            if (not addrSize):
                (<Registers>self.main.cpu.registers).regAdd(ediReg, operSize)
            else:
                (<Registers>self.main.cpu.registers).regSub(ediReg, operSize)
            zf = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_ZF)!=0
            if (((<Registers>self.main.cpu.registers).repPrefix == OPCODE_PREFIX_REPE and not zf) or \
                ((<Registers>self.main.cpu.registers).repPrefix == OPCODE_PREFIX_REPNE and zf)):
                newCount = countVal-i-1
                break
        self.main.cpu.cycles += countVal-newCount
        if ((<Registers>self.main.cpu.registers).repPrefix):
            (<Registers>self.main.cpu.registers).regWrite(countReg, newCount)
    cdef inAxImm8(self, unsigned char operSize):
        cdef unsigned short dataReg
        dataReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
        (<Registers>self.main.cpu.registers).regWrite(dataReg, self.main.platform.inPort((<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False), operSize))
    cdef inAxDx(self, unsigned char operSize):
        cdef unsigned short dataReg
        dataReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
        (<Registers>self.main.cpu.registers).regWrite(dataReg, self.main.platform.inPort((<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_DX, False), operSize))
    cdef outImm8Ax(self, unsigned char operSize):
        cdef unsigned short dataReg
        dataReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
        self.main.platform.outPort((<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False), (<Registers>self.main.cpu.registers).regRead(dataReg, False), operSize)
    cdef outDxAx(self, unsigned char operSize):
        cdef unsigned short dataReg
        dataReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
        self.main.platform.outPort((<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_DX, False), (<Registers>self.main.cpu.registers).regRead(dataReg, False), operSize)
    cdef outsFunc(self, unsigned char operSize):
        cdef unsigned char addrSize
        cdef unsigned short dxReg, esiReg, countReg, ioPort
        cdef unsigned long value, esiVal, countVal, i
        addrSize = (<Registers>self.main.cpu.registers).getAddrCodeSegSize()
        dxReg  = CPU_REGISTER_DX
        esiReg  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SI, addrSize)
        countReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if ((<Registers>self.main.cpu.registers).repPrefix):
            countVal = (<Registers>self.main.cpu.registers).regRead(countReg, False)
            if (countVal == 0):
                return
        addrSize = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_DF)!=0
        for i in range(countVal):
            esiVal = (<Registers>self.main.cpu.registers).regRead(esiReg, False)
            ioPort = (<Registers>self.main.cpu.registers).regRead(dxReg, False)
            value = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(esiVal, operSize, CPU_SEGMENT_DS, True)
            self.main.platform.outPort(ioPort, value, operSize)
            if (not addrSize):
                (<Registers>self.main.cpu.registers).regAdd(esiReg, operSize)
            else:
                (<Registers>self.main.cpu.registers).regSub(esiReg, operSize)
        self.main.cpu.cycles += countVal
        if ((<Registers>self.main.cpu.registers).repPrefix):
            (<Registers>self.main.cpu.registers).regWrite(countReg, 0)
    cdef insFunc(self, unsigned char operSize):
        cdef unsigned char addrSize
        cdef unsigned short dxReg, ediReg, countReg, ioPort
        cdef unsigned long value, ediVal, countVal, i
        addrSize = (<Registers>self.main.cpu.registers).getAddrCodeSegSize()
        dxReg  = CPU_REGISTER_DX
        ediReg  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DI, addrSize)
        countReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_CX, addrSize)
        countVal = 1
        if ((<Registers>self.main.cpu.registers).repPrefix):
            countVal = (<Registers>self.main.cpu.registers).regRead(countReg, False)
            if (countVal == 0):
                return
        addrSize = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_DF)!=0
        for i in range(countVal):
            ediVal = (<Registers>self.main.cpu.registers).regRead(ediReg, False)
            ioPort = (<Registers>self.main.cpu.registers).regRead(dxReg, False)
            value = self.main.platform.inPort(ioPort, operSize)
            (<Registers>self.main.cpu.registers).mmWriteValue(ediVal, value, operSize, CPU_SEGMENT_ES, False)
            if (not addrSize):
                (<Registers>self.main.cpu.registers).regAdd(ediReg, operSize)
            else:
                (<Registers>self.main.cpu.registers).regSub(ediReg, operSize)
        self.main.cpu.cycles += countVal
        if ((<Registers>self.main.cpu.registers).repPrefix):
            (<Registers>self.main.cpu.registers).regWrite(countReg, 0)
    cdef jcxzShort(self):
        cdef unsigned char operSize
        cdef unsigned short cxReg
        cdef unsigned long cxVal
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        cxReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_CX, operSize)
        cxVal = (<Registers>self.main.cpu.registers).regRead(cxReg, False)
        self.jumpShort(OP_SIZE_BYTE, cxVal==0)
    cdef jumpShort(self, unsigned char offsetSize, unsigned char c):
        cdef unsigned char operSize
        cdef long offset
        cdef long long newEip
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        offset = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(offsetSize, True)
        if (c):
            newEip = ((<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_EIP, False)+offset)&BITMASK_DWORD
            if (operSize == OP_SIZE_WORD):
                newEip &= BITMASK_WORD
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EIP, newEip)
    cdef callNearRel16_32(self):
        cdef unsigned char operSize
        cdef long offset
        cdef long long newEip
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        offset = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(operSize, True)
        self.stackPushRegId(CPU_REGISTER_EIP, operSize)
        newEip = ((<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_EIP, False)+offset)&BITMASK_DWORD
        if (operSize == OP_SIZE_WORD):
            newEip &= BITMASK_WORD
        (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EIP, newEip)
    cdef callPtr16_32(self):
        cdef unsigned char operSize
        cdef unsigned short segVal
        cdef unsigned long eipAddr
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        eipAddr = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(operSize, False)
        segVal = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_WORD, False)
        self.stackPushSegId(CPU_SEGMENT_CS, operSize)
        self.stackPushRegId(CPU_REGISTER_EIP, operSize)
        self.syncProtectedModeState()
        (<Registers>self.main.cpu.registers).segWrite(CPU_SEGMENT_CS, segVal)
        (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EIP, eipAddr)
    cdef pushaWD(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        cdef unsigned long temp
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SP, operSize)
        temp = (<Registers>self.main.cpu.registers).regRead(regName, False)
        if (not (<Segments>(<Registers>self.main.cpu.registers).segments).isInProtectedMode() and temp in (7, 9, 11, 13, 15)):
            raise ChemuException(CPU_EXCEPTION_GP)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
        self.stackPushRegId(regName, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_CX, operSize)
        self.stackPushRegId(regName, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DX, operSize)
        self.stackPushRegId(regName, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_BX, operSize)
        self.stackPushRegId(regName, operSize)
        self.stackPushValue(temp, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_BP, operSize)
        self.stackPushRegId(regName, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SI, operSize)
        self.stackPushRegId(regName, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DI, operSize)
        self.stackPushRegId(regName, operSize)
    cdef popaWD(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DI, operSize)
        self.stackPopRegId(regName, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SI, operSize)
        self.stackPopRegId(regName, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_BP, operSize)
        self.stackPopRegId(regName, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SP, operSize)
        (<Registers>self.main.cpu.registers).regAdd(regName, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_BX, operSize)
        self.stackPopRegId(regName, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DX, operSize)
        self.stackPopRegId(regName, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_CX, operSize)
        self.stackPopRegId(regName, operSize)
        regName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
        self.stackPopRegId(regName, operSize)
    cdef pushfWD(self):
        cdef unsigned char operSize
        cdef unsigned short regNameId
        cdef unsigned long value
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        regNameId = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_FLAGS, operSize)
        value = (<Registers>self.main.cpu.registers).regRead(regNameId, False)|0x2
        value &= (~FLAG_IOPL) # This is for
        value |= (((<Registers>self.main.cpu.registers).iopl&3)<<12) # IOPL, Bits 12,13
        if (operSize == OP_SIZE_DWORD):
            value &= 0x00FCFFFF
        self.stackPushValue(value, operSize)
    cdef popfWD(self):
        cdef unsigned char operSize
        cdef unsigned short regNameId
        cdef unsigned long flagValue
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        regNameId = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_FLAGS, operSize)
        flagValue = self.stackPopValue(operSize)|0x2
        flagValue &= (~0x8028)
        if ((<Registers>self.main.cpu.registers).cpl != 0):
            flagValue &= (~FLAG_IOPL)
            flagValue |= ((<Registers>self.main.cpu.registers).iopl&3)<<12
        else:
            (<Registers>self.main.cpu.registers).iopl = (flagValue>>12)&3
        (<Registers>self.main.cpu.registers).regWrite(regNameId, flagValue)
        (<Registers>self.main.cpu.registers).setEFLAG(((((<Registers>self.main.cpu.registers).iopl&3)<<12)|(FLAG_REQUIRED)), True) # This is for IOPL, Bits 12,13
        if ((<Registers>self.main.cpu.registers).getEFLAG(FLAG_VM)!=0):
            self.main.exitError("TODO: virtual 8086 mode not supported yet.")
    cdef stackPopRM(self, unsigned char operSize):
        cdef unsigned long value
        value = self.stackPopValue(operSize)
        self.modRMInstance.modRMSave(operSize, value, True, OPCODE_SAVE)
    cdef stackPopSegId(self, unsigned short segId, unsigned char operSize):
        (<Registers>self.main.cpu.registers).segWrite(segId, <unsigned short>(self.stackPopValue(operSize)&BITMASK_WORD))
    cdef stackPopRegId(self, unsigned short regId, unsigned char operSize):
        cdef unsigned long value
        value = self.stackPopValue(operSize)
        operSize = (<Registers>self.main.cpu.registers).getRegSize(regId)
        value &= (<Misc>self.main.misc).getBitMaskFF(operSize)
        (<Registers>self.main.cpu.registers).regWrite(regId, value)
    cdef unsigned long stackPopValue(self, unsigned char operSize):
        cdef unsigned char stackAddrSize
        cdef unsigned short stackRegName
        cdef unsigned long data
        stackAddrSize = (<Registers>self.main.cpu.registers).getAddrSegSize(CPU_SEGMENT_SS)
        stackRegName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        data = self.stackGetValue(operSize)
        (<Registers>self.main.cpu.registers).regAdd(stackRegName, operSize)
        return data
    cdef unsigned long stackGetValue(self, unsigned char operSize):
        cdef unsigned char stackAddrSize
        cdef unsigned short stackRegName
        cdef unsigned long stackAddr, data
        stackAddrSize = (<Registers>self.main.cpu.registers).getAddrSegSize(CPU_SEGMENT_SS)
        stackRegName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        stackAddr = (<Registers>self.main.cpu.registers).regRead(stackRegName, False)
        data = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(stackAddr, operSize, CPU_SEGMENT_SS, False)
        return data
    cdef stackPushSegId(self, unsigned short segId, unsigned char operSize):
        self.stackPushValue(<unsigned short>((<Registers>self.main.cpu.registers).segRead(segId)&BITMASK_WORD), operSize)
    cdef stackPushRegId(self, unsigned short regId, unsigned char operSize):
        cdef unsigned long value
        value = (<Registers>self.main.cpu.registers).regRead(regId, False)
        self.stackPushValue(value, operSize)
    cdef stackPushValue(self, unsigned long value, unsigned char operSize):
        cdef unsigned char stackAddrSize
        cdef unsigned short stackRegName
        cdef unsigned long stackAddr
        stackAddrSize = (<Registers>self.main.cpu.registers).getAddrSegSize(CPU_SEGMENT_SS)
        stackRegName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        stackAddr = (<Registers>self.main.cpu.registers).regRead(stackRegName, False)
        if (not (<Segments>(<Registers>self.main.cpu.registers).segments).isInProtectedMode() and stackAddr == 1):
            raise ChemuException(CPU_EXCEPTION_SS)
        stackAddr = (<Registers>self.main.cpu.registers).regSub(stackRegName, operSize)
        value &= (<Misc>self.main.misc).getBitMaskFF(operSize)
        (<Registers>self.main.cpu.registers).mmWriteValue(stackAddr, value, operSize, CPU_SEGMENT_SS, False)
    cdef pushIMM(self, unsigned char immIsByte):
        cdef unsigned char operSize
        cdef unsigned long value
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        if (immIsByte):
            value = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, True)&(<Misc>self.main.misc).getBitMaskFF(operSize)
        else:
            value = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(operSize, False)
        self.stackPushValue(value, operSize)
    cdef imulR_RM_ImmFunc(self, unsigned char immIsByte):
        cdef unsigned char operSize
        cdef long operOp1
        cdef long long operOp2
        cdef unsigned long operSum, bitMask
        cdef unsigned long long temp, doubleBitMask
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        doubleBitMask = (<Misc>self.main.misc).getBitMaskFF(operSize<<1)
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp1 = self.modRMInstance.modRMLoad(operSize, True, True)
        if (immIsByte):
            operOp2 = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, True)
            operOp2 &= bitMask
        else:
            operOp2 = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(operSize, True)
        operSum = (operOp1*operOp2)&bitMask
        temp = (operOp1*operOp2)&doubleBitMask
        self.modRMInstance.modRSave(operSize, operSum, OPCODE_SAVE)
        (<Registers>self.main.cpu.registers).setFullFlags(operOp1, operOp2, operSize, OPCODE_MUL, True)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF | FLAG_OF, temp!=operSum)
    cdef opcodeGroup1_RM_ImmFunc(self, unsigned char operSize, unsigned char immIsByte):
        cdef unsigned char operOpcode, operOpcodeId
        cdef unsigned long bitMask, operOp1, operOp2
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        operOpcode = (<Registers>self.main.cpu.registers).getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp1 = self.modRMInstance.modRMLoad(operSize, False, True)
        if (operSize != OP_SIZE_BYTE and immIsByte):
            operOp2 = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, True)&bitMask # operImm8 sign-extended to destsize
        else:
            operOp2 = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(operSize, False) # operImm8/16/32
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
            (<Registers>self.main.cpu.registers).setFullFlags(operOp1, operOp2, operSize, operOpcodeId, False)
        elif (operOpcodeId in (GROUP1_OP_AND, GROUP1_OP_OR, GROUP1_OP_XOR)):
            if (operOpcodeId == GROUP1_OP_AND):
                operOpcodeId = OPCODE_AND
            elif (operOpcodeId == GROUP1_OP_OR):
                operOpcodeId = OPCODE_OR
            elif (operOpcodeId == GROUP1_OP_XOR):
                operOpcodeId = OPCODE_XOR
            operOp2 = self.modRMInstance.modRMSave(operSize, operOp2, True, operOpcodeId)
            (<Registers>self.main.cpu.registers).setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP1_OP_CMP):
            (<Registers>self.main.cpu.registers).setFullFlags(operOp1, operOp2, operSize, OPCODE_SUB, False)
        else:
            self.main.printMsg("opcodeGroup1_RM16_32_IMM8: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroup3_RM_ImmFunc(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId
        cdef unsigned long operOp2
        operOpcode = (<Registers>self.main.cpu.registers).getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp2 = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(operSize, False) # operImm
        if (operOpcodeId == 0): # GROUP3_OP_MOV
            self.modRMInstance.modRMSave(operSize, operOp2, True, OPCODE_SAVE)
        else:
            self.main.printMsg("opcodeGroup3_RM16_32_IMM16_32: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroup0F(self):
        cdef unsigned char operSize, addrSize, operOpcode, bitSize, operOpcodeMod, operOpcodeModId, \
            newCF, newOF, oldOF, count, eaxIsInvalid
        cdef unsigned short eaxReg, limit
        cdef unsigned long eaxId, bitMask, bitMaskHalf, base, mmAddr, op1, op2
        cdef unsigned long long qop1, qop2
        cdef short i
        cdef GdtEntry gdtEntry
        (<Registers>self.main.cpu.registers).getOpAddrCodeSegSize(&operSize, &addrSize)
        operOpcode = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        ##self.main.debug("Group0F: Opcode=={0:#04x}", operOpcode)
        if (operOpcode == 0x00): # LLDT/SLDT LTR/STR VERR/VERW
            if ((<Registers>self.main.cpu.registers).cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            if (not (<Segments>(<Registers>self.main.cpu.registers).segments).isInProtectedMode()):
                raise ChemuException(CPU_EXCEPTION_UD)
            operOpcodeMod = (<Registers>self.main.cpu.registers).getCurrentOpcode(OP_SIZE_BYTE, False)
            operOpcodeModId = (operOpcodeMod>>3)&7
            self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            mmAddr = self.modRMInstance.getRMValueFull(addrSize)
            if (operOpcodeModId in (0, 1)): # SLDT/STR
                if (operOpcodeModId == 0): # SLDT
                    self.modRMInstance.modRMSave(OP_SIZE_WORD, (<Segments>\
                        (<Registers>self.main.cpu.registers).segments).ldtr, True, OPCODE_SAVE)
                elif (operOpcodeModId == 1): # STR
                    op1 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
                    if (not (<Segments>(<Registers>self.main.cpu.registers).segments).isInProtectedMode()):
                          raise ChemuException(CPU_EXCEPTION_UD)
                    self.main.exitError("opcodeGroup0F_00: STR not supported yet.")
            elif (operOpcodeModId in (2, 3)): # LLDT/LTR
                if (not (<Segments>(<Registers>self.main.cpu.registers).segments).isInProtectedMode()):
                      raise ChemuException(CPU_EXCEPTION_UD)
                elif ((<Registers>self.main.cpu.registers).cpl != 0):
                    raise ChemuException(CPU_EXCEPTION_GP, 0)
                op1 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
                if (operOpcodeModId == 2): # LLDT
                    if ((op1>>2) == 0):
                        ##self.main.debug("Opcode0F_01::LLDT: (op1>>2) == 0, mark LDTR as invalid.")
                        op1 = 0
                    else:
                        if ((op1 & SELECTOR_USE_LDT) or (((<Gdt>(<Registers>self.main.cpu.registers).segments.gdt).getSegAccess(op1)&\
                          GDT_ACCESS_SYSTEM_SEGMENT_TYPE) != GDT_ENTRY_SYSTEM_TYPE_LDT)):
                            raise ChemuException(CPU_EXCEPTION_GP, op1)
                        elif (not (<Gdt>(<Registers>self.main.cpu.registers).segments.gdt).isSegPresent(op1)):
                            raise ChemuException(CPU_EXCEPTION_NP, op1)
                    (<Segments>(<Registers>self.main.cpu.registers).segments).ldtr = op1&0xfff8
                    gdtEntry = (<GdtEntry>(<Gdt>(<Registers>self.main.cpu.registers).segments.gdt).getEntry(op1))
                    (<Gdt>(<Registers>self.main.cpu.registers).segments.ldt).loadTablePosition(gdtEntry.base, gdtEntry.limit)
                    (<Gdt>(<Registers>self.main.cpu.registers).segments.ldt).loadTableData()
                elif (operOpcodeModId == 3): # LTR
                    if ((op1&0xfff8) == 0):
                        raise ChemuException(CPU_EXCEPTION_GP, 0)
                    elif (((<Segments>(<Registers>self.main.cpu.registers).segments).ldtr == (op1&0xfff8)) or (((<Gdt>(<Registers>self.main.cpu.registers).segments.gdt).getSegAccess(op1)&\
                      GDT_ACCESS_SYSTEM_SEGMENT_TYPE) != GDT_ENTRY_SYSTEM_TYPE_TSS)):
                        raise ChemuException(CPU_EXCEPTION_GP, op1)
                    elif (not (<Gdt>(<Registers>self.main.cpu.registers).segments.gdt).isSegPresent(op1)):
                        raise ChemuException(CPU_EXCEPTION_NP, op1)
                    self.main.exitError("opcodeGroup0F_00: LTR not supported yet.")
            elif (operOpcodeModId == 4): # VERR
                op1 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
                (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, (<Segments>(<Registers>self.main.cpu.registers).segments).checkReadAllowed(op1))
            elif (operOpcodeModId == 5): # VERW
                op1 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
                (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, (<Segments>(<Registers>self.main.cpu.registers).segments).checkWriteAllowed(op1))
            else:
                self.main.printMsg("opcodeGroup0F_00: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x01): # LGDT/LIDT SGDT/SIDT SMSW/LMSW
            if ((<Registers>self.main.cpu.registers).cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            operOpcodeMod = (<Registers>self.main.cpu.registers).getCurrentOpcode(OP_SIZE_BYTE, False)
            operOpcodeModId = (operOpcodeMod>>3)&7
            if (operOpcodeModId in (0, 1, 2, 3)): # SGDT/SIDT LGDT/LIDT
                self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            elif (operOpcodeModId in (4, 6)): # SMSW/LMSW
                self.modRMInstance.modRMOperands(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            else:
                self.main.printMsg("Group0F_01: operOpcodeModId not in (0, 1, 2, 3, 4, 6)")
            mmAddr = self.modRMInstance.getRMValueFull(addrSize)
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
                    (<Gdt>(<Registers>self.main.cpu.registers).segments.gdt).getBaseLimit(&base, &limit)
                elif (operOpcodeModId == 1): # SIDT
                    (<Idt>(<Registers>self.main.cpu.registers).segments.idt).getBaseLimit(&base, &limit)
                limit &= BITMASK_WORD
                if (operSize == OP_SIZE_WORD):
                    base &= 0xffffff
                (<Registers>self.main.cpu.registers).mmWriteValue(mmAddr, limit, OP_SIZE_WORD, CPU_SEGMENT_DS, True)
                (<Registers>self.main.cpu.registers).mmWriteValue(mmAddr+OP_SIZE_WORD, base, OP_SIZE_DWORD, CPU_SEGMENT_DS, True)
            elif (operOpcodeModId in (2, 3)): # LGDT/LIDT
                limit = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(mmAddr, OP_SIZE_WORD, CPU_SEGMENT_DS, True)
                base = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(mmAddr+OP_SIZE_WORD, OP_SIZE_DWORD, CPU_SEGMENT_DS, True)
                if (operSize == OP_SIZE_WORD):
                    base &= 0xffffff
                if (operOpcodeModId == 2): # LGDT
                    (<Gdt>(<Registers>self.main.cpu.registers).segments.gdt).loadTablePosition(base, limit)
                elif (operOpcodeModId == 3): # LIDT
                    (<Idt>(<Registers>self.main.cpu.registers).segments.idt).loadTable(base, limit)
            elif (operOpcodeModId == 4): # SMSW
                op2 = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_CR0, False)&BITMASK_WORD
                self.modRMInstance.modRMSave(OP_SIZE_WORD, op2, True, OPCODE_SAVE)
            elif (operOpcodeModId == 6): # LMSW
                if ((<Registers>self.main.cpu.registers).cpl != 0):
                    raise ChemuException(CPU_EXCEPTION_GP, 0)
                op1 = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_CR0, False)
                op2 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
                if ((op1&1 != 0) and (op2&1 == 0)): # if is already in protected mode, but try to switch to real mode...
                    self.main.exitError("opcodeGroup0F_01: LMSW: try to switch to real mode from protected mode.")
                    return
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_CR0, ((op1&0xfffffff0)|(op2&0xf)))
                self.syncProtectedModeState()
            elif (operOpcodeModId == 7): # INVLPG
                self.main.printMsg("opcodeGroup0F_01: INVLPG isn't supported yet.")
                raise ChemuException(CPU_EXCEPTION_UD)
            else:
                self.main.printMsg("opcodeGroup0F_01: invalid operOpcodeModId: {0:d}", operOpcodeModId)
                raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x05): # LOADALL (286, undocumented)
            self.main.printMsg("opcodeGroup0F_05: LOADALL 286 opcode isn't supported yet.")
            raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x07): # LOADALL (386, undocumented)
            self.main.printMsg("opcodeGroup0F_07: LOADALL 386 opcode isn't supported yet.")
            raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode in (0x06, 0x08, 0x09)): # 0x06: CLTS, 0x08: INVD, 0x09: WBINVD
            if ((<Registers>self.main.cpu.registers).cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            if (operOpcode == 0x06): # CLTS
                (<Registers>self.main.cpu.registers).regAnd(CPU_REGISTER_CR0, (~CR0_FLAG_TS)&BITMASK_DWORD)
        elif (operOpcode == 0x0b): # UD2
            raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode == 0x20): # MOV R32, CRn
            if ((<Registers>self.main.cpu.registers).cpl != 0):
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
            if ((<Registers>self.main.cpu.registers).cpl != 0):
                raise ChemuException(CPU_EXCEPTION_GP, 0)
            self.modRMInstance.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_CREG)
            if (self.modRMInstance.regName not in (CPU_REGISTER_CR0, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4)):
                raise ChemuException(CPU_EXCEPTION_UD)
            # We need to 'ignore' mod to read the source/dest as a register. That's the way to do it.
            self.modRMInstance.mod = 3
            op2 = self.modRMInstance.modRMLoad(OP_SIZE_DWORD, False, True)
            if (self.modRMInstance.regName == CPU_REGISTER_CR0):
                op1 = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_CR0, False) # op1 == old CR0
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
            if (not (<Registers>self.main.cpu.registers).getFlag(CPU_REGISTER_CR4, CR4_FLAG_TSD) or \
                 (<Registers>self.main.cpu.registers).cpl == 0 or not (<Segments>(<Registers>self.main.cpu.registers).segments).isInProtectedMode()):
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EAX, self.main.cpu.cycles&BITMASK_DWORD)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EDX, (self.main.cpu.cycles>>32)&BITMASK_DWORD)
            else:
                raise ChemuException(CPU_EXCEPTION_GP, 0)
        elif (operOpcode == 0x38): # MOVBE
            operOpcodeMod = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            if (operOpcodeMod == 0xf0): # MOVBE R16_32, M16_32
                op2 = self.modRMInstance.modRMLoad(operSize, False, True)
                op2 = (<Misc>self.main.misc).reverseByteOrder(op2, operSize)
                self.modRMInstance.modRSave(operSize, op2, OPCODE_SAVE)
            elif (operOpcodeMod == 0xf1): # MOVBE M16_32, R16_32
                op2 = self.modRMInstance.modRLoad(operSize, False)
                op2 = (<Misc>self.main.misc).reverseByteOrder(op2, operSize)
                self.modRMInstance.modRMSave(operSize, op2, True, OPCODE_SAVE)
            else:
                self.main.exitError("MOVBE: operOpcodeMod {0:#04x} not in (0xf0, 0xf1)", operOpcodeMod)
        elif (operOpcode >= 0x40 and operOpcode <= 0x4f): # CMOVcc
            self.cmovFunc(operSize, (<Registers>self.main.cpu.registers).getCond(operOpcode&0xf))
        elif (operOpcode >= 0x80 and operOpcode <= 0x8f):
            self.jumpShort(operSize, (<Registers>self.main.cpu.registers).getCond(operOpcode&0xf))
        elif (operOpcode >= 0x90 and operOpcode <= 0x9f): # SETcc
            self.setWithCondFunc((<Registers>self.main.cpu.registers).getCond(operOpcode&0xf))
        elif (operOpcode == 0xa0): # PUSH FS
            self.pushSeg(operOpcode)
        elif (operOpcode == 0xa1): # POP FS
            self.popSeg(operOpcode)
        elif (operOpcode == 0xa2): # CPUID
            eaxId = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_EAX, False)
            eaxIsInvalid = (eaxId >= 0x40000000 and eaxId <= 0x4fffffff)
            if (eaxId == 0x1):
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EAX, 0x400)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EBX, 0x0)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EDX, 0x8110)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_ECX, 0xc00000)
            elif (eaxId in (0x2, 0x3, 0x4)):
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EAX, 0x0)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EBX, 0x0)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EDX, 0x0)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_ECX, 0x0)
            #elif (eaxId in (0x3, 0x4, 0x5, 0x6, 0x7)): #, 0x80000005, 0x80000006, 0x80000007)):
            #    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EAX, 0x0)
            #    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EBX, 0x0)
            #    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EDX, 0x0)
            #    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_ECX, 0x0)
            #elif (eaxId == 0x80000000):
            #    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EAX, 0x80000001)
            #    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EBX, 0x0)
            #    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EDX, 0x0)
            #    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_ECX, 0x0)
            #elif (eaxId == 0x80000001):
            #    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EAX, 0x0)
            #    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EBX, 0x0)
            #    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EDX, 0x0)
            #    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_ECX, 0x0)
            #elif (eaxId == 0x0 or eaxIsInvalid):
            else:
                if (not (eaxId == 0x0 or eaxIsInvalid)):
                    self.main.printMsg("CPUID: eaxId {0:#04x} unknown.", eaxId)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EAX, 0x1) # 0x7)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EBX, 0x756e6547)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EDX, 0x49656e69)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_ECX, 0x6c65746e)
            #else:
            #    self.main.exitError("CPUID: eaxId {0:#04x} unknown.", eaxId)
        elif (operOpcode == 0xa3): # BT RM16/32, R16
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRLoad(operSize, False)
            self.btFunc(op2, BT_NONE)
        elif (operOpcode in (0xa4, 0xa5)): # SHLD
            bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
            bitSize = operSize << 3
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            if (operOpcode == 0xa4): # SHLD imm8
                count = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            elif (operOpcode == 0xa5): # SHLD CL
                count = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_CL, False)
            else:
                self.main.exitError("group0F::SHLD: operOpcode {0:#04x} unknown.", operOpcode)
                return
            count %= 32
            if (count == 0):
                return
            if (count > bitSize): # bad parameters
                self.main.exitError("group0F: SHLD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).", count, bitSize, operOpcode)
                return
            op1 = self.modRMInstance.modRMLoad(operSize, False, True) # dest
            oldOF = (op1&bitMaskHalf)!=0
            op2  = self.modRMInstance.modRLoad(operSize, False) # src
            newCF = (<Registers>self.main.cpu.registers).valGetBit(op1, bitSize-count)
            for i in range(bitSize-1, count-1, -1):
                tmpBit = (<Registers>self.main.cpu.registers).valGetBit(op1, i-count)
                op1 = (<Registers>self.main.cpu.registers).valSetBit(op1, i, tmpBit)
            for i in range(count-1, -1, -1):
                tmpBit = (<Registers>self.main.cpu.registers).valGetBit(op2, i-count+bitSize)
                op1 = (<Registers>self.main.cpu.registers).valSetBit(op1, i, tmpBit)
            self.modRMInstance.modRMSave(operSize, op1, True, OPCODE_SAVE)
            if (count == 1):
                newOF = oldOF!=((op1&bitMaskHalf)!=0)
                (<Registers>self.main.cpu.registers).setEFLAG(FLAG_OF, newOF)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, newCF)
            (<Registers>self.main.cpu.registers).setSZP(op1, operSize)
        elif (operOpcode == 0xa8): # PUSH GS
            self.pushSeg(operOpcode)
        elif (operOpcode == 0xa9): # POP GS
            self.popSeg(operOpcode)
        elif (operOpcode == 0xab): # BTS RM16/32, R16
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRLoad(operSize, False)
            self.btFunc(op2, BT_SET)
        elif (operOpcode in (0xac, 0xad)): # SHRD
            bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
            bitSize = operSize << 3
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            if (operOpcode == 0xac): # SHRD imm8
                count = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            elif (operOpcode == 0xad): # SHRD CL
                count = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_CL, False)
            else:
                self.main.exitError("group0F::SHRD: operOpcode {0:#04x} unknown.", operOpcode)
                return
            count %= 32
            if (count == 0):
                return
            if (count > bitSize): # bad parameters
                self.main.exitError("group0F: SHRD: count > bitSize (count == {0:d}, bitSize == {1:d}, operOpcode == {2:#04x}).", count, bitSize, operOpcode)
                return
            op1 = self.modRMInstance.modRMLoad(operSize, False, True) # dest
            oldOF = (op1&bitMaskHalf)!=0
            op2  = self.modRMInstance.modRLoad(operSize, False) # src
            newCF = (<Registers>self.main.cpu.registers).valGetBit(op1, count-1)
            for i in range(bitSize-count):
                tmpBit = (<Registers>self.main.cpu.registers).valGetBit(op1, i+count)
                op1 = (<Registers>self.main.cpu.registers).valSetBit(op1, i, tmpBit)
            for i in range(bitSize-count, bitSize):
                tmpBit = (<Registers>self.main.cpu.registers).valGetBit(op2, i+count-bitSize)
                op1 = (<Registers>self.main.cpu.registers).valSetBit(op1, i, tmpBit)
            self.modRMInstance.modRMSave(operSize, op1, True, OPCODE_SAVE)
            if (count == 1):
                newOF = oldOF!=((op1&bitMaskHalf)!=0)
                (<Registers>self.main.cpu.registers).setEFLAG(FLAG_OF, newOF)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, newCF)
            (<Registers>self.main.cpu.registers).setSZP(op1, operSize)
        elif (operOpcode == 0xaf): # IMUL R16_32, R/M16_32
            bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op1 = self.modRMInstance.modRLoad(operSize, True)&bitMask
            op2 = self.modRMInstance.modRMLoad(operSize, True, True)&bitMask
            (<Registers>self.main.cpu.registers).setFullFlags(op1, op2, operSize, OPCODE_MUL, True)
            op1 = (op1*op2)&bitMask
            self.modRMInstance.modRSave(operSize, op1, OPCODE_SAVE)
        elif (operOpcode in (0xb0, 0xb1)): # 0xb0: CMPXCHG RM8, R8 ;; 0xb1: CMPXCHG RM16_32, R16_32
            if (operOpcode == 0xb0): # 0xb0: CMPXCHG RM8, R8
                operSize = OP_SIZE_BYTE
            eaxReg  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op1 = self.modRMInstance.modRMLoad(operSize, False, True)
            op2 = self.reg.regRead(eaxReg, False)
            (<Registers>self.main.cpu.registers).setFullFlags(op2, op1, operSize, OPCODE_SUB, False)
            if (op2 == op1):
                (<Registers>self.main.cpu.registers).setEFLAG(FLAG_ZF, True)
                op2 = self.modRMInstance.modRLoad(operSize, False)
                self.modRMInstance.modRMSave(operSize, op2, True, OPCODE_SAVE)
            else:
                (<Registers>self.main.cpu.registers).setEFLAG(FLAG_ZF, False)
                (<Registers>self.main.cpu.registers).regWrite(eaxReg, op1)
        elif (operOpcode == 0xb2): # LSS
            self.lfpFunc(CPU_SEGMENT_SS) # 'load far pointer' function
        elif (operOpcode == 0xb3): # BTR RM16/32, R16
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRLoad(operSize, False)
            self.btFunc(op2, BT_RESET)
        elif (operOpcode == 0xb4): # LFS
            self.lfpFunc(CPU_SEGMENT_FS) # 'load far pointer' function
        elif (operOpcode == 0xb5): # LGS
            self.lfpFunc(CPU_SEGMENT_GS) # 'load far pointer' function
        elif (operOpcode == 0xb6): # MOVZX R16_32, R/M8
            bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
            self.modRMInstance.modRMOperandsResetEip(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
            self.modRMInstanceOther.modRMOperands(operSize, MODRM_FLAGS_NONE)
            self.modRMInstance.copyRMVars(self.modRMInstanceOther)
            op2 = self.modRMInstance.modRMLoad(OP_SIZE_BYTE, False, True)
            self.modRMInstance.modRSave(operSize, op2, OPCODE_SAVE)
        elif (operOpcode == 0xb7): # MOVZX R32, R/M16
            self.modRMInstance.modRMOperandsResetEip(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            self.modRMInstanceOther.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_NONE)
            self.modRMInstance.copyRMVars(self.modRMInstanceOther)
            op2 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, False, True)
            self.modRMInstance.modRSave(OP_SIZE_DWORD, op2, OPCODE_SAVE)
        elif (operOpcode == 0xb8): # POPCNT R16/32 RM16/32
            if ((<Registers>self.main.cpu.registers).repPrefix):
                raise ChemuException(CPU_EXCEPTION_UD)
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoad(operSize, False, True)
            op2 = bin(op2).count('1')
            self.modRMInstance.modRSave(operSize, op2, OPCODE_SAVE)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF | FLAG_PF | FLAG_AF | FLAG_ZF | FLAG_SF | FLAG_OF, False)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_ZF, op2==0)
        elif (operOpcode == 0xba): # BT/BTS/BTR/BTC RM16/32 IMM8
            operOpcodeMod = (<Registers>self.main.cpu.registers).getCurrentOpcode(OP_SIZE_BYTE, False)
            operOpcodeModId = (operOpcodeMod>>3)&7
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
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
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRLoad(operSize, False)
            self.btFunc(op2, BT_COMPLEMENT)
        elif (operOpcode == 0xbc): # BSF R16_32, R/M16_32
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoad(operSize, False, True)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_ZF, op2==0)
            op1 = 0
            if (op2 > 1):
                op1 = bin(op2)[::-1].find('1')
            self.modRMInstance.modRSave(operSize, op1, OPCODE_SAVE)
        elif (operOpcode == 0xbd): # BSR R16_32, R/M16_32
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op2 = self.modRMInstance.modRMLoad(operSize, False, True)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_ZF, op2==0)
            self.modRMInstance.modRSave(operSize, op2.bit_length()-1, OPCODE_SAVE)
        elif (operOpcode == 0xbe): # MOVSX R16_32, R/M8
            bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
            self.modRMInstance.modRMOperandsResetEip(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
            self.modRMInstanceOther.modRMOperands(operSize, MODRM_FLAGS_NONE)
            self.modRMInstance.copyRMVars(self.modRMInstanceOther)
            op2 = self.modRMInstance.modRMLoad(OP_SIZE_BYTE, True, True)&bitMask
            self.modRMInstance.modRSave(operSize, op2, OPCODE_SAVE)
        elif (operOpcode == 0xbf): # MOVSX R32, R/M16
            self.modRMInstance.modRMOperandsResetEip(OP_SIZE_WORD, MODRM_FLAGS_NONE)
            self.modRMInstanceOther.modRMOperands(OP_SIZE_DWORD, MODRM_FLAGS_NONE)
            self.modRMInstance.copyRMVars(self.modRMInstanceOther)
            op2 = self.modRMInstance.modRMLoad(OP_SIZE_WORD, True, True)&BITMASK_DWORD
            self.modRMInstance.modRSave(OP_SIZE_DWORD, op2, OPCODE_SAVE)
        elif (operOpcode in (0xc0, 0xc1)): # 0xc0: XADD RM8, R8 ;; 0xc1: XADD RM16_32, R16_32
            if (operOpcode == 0xc0): # 0xc0: XADD RM8, R8
                operSize = OP_SIZE_BYTE
            self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
            op1 = self.modRMInstance.modRMLoad(operSize, False, True)
            op2 = self.modRMInstance.modRLoad(operSize, False)
            self.modRMInstance.modRMSave(operSize, op2, True, OPCODE_ADD)
            self.modRMInstance.modRSave(operSize, op1, OPCODE_SAVE)
            (<Registers>self.main.cpu.registers).setFullFlags(op2, op1, operSize, OPCODE_ADD, False)
        elif (operOpcode == 0xc7): # CMPXCHG8B M64
            operOpcodeMod = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
            operOpcodeModId = (operOpcodeMod>>3)&7
            if (operOpcodeModId == 1):
                op1 = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(addrSize, False)
                qop1 = (<Mm>self.main.mm).mmPhyReadValueUnsigned(op1, OP_SIZE_QWORD)
                qop2 = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_EDX, False)
                qop2 <<= 32
                qop2 |= (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_EAX, False)
                if (qop2 == qop1):
                    (<Registers>self.main.cpu.registers).setEFLAG(FLAG_ZF, True)
                    qop2 = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_ECX, False)
                    qop2 <<= 32
                    qop2 |= (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_EBX, False)
                    (<Mm>self.main.mm).mmPhyWriteValue(op1, qop2, OP_SIZE_QWORD)
                else:
                    (<Registers>self.main.cpu.registers).setEFLAG(FLAG_ZF, False)
                    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EDX, qop1>>32)
                    (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EAX, qop1&BITMASK_DWORD)
            else:
                self.main.printMsg("opcodeGroup0F_C7: operOpcodeModId {0:d} isn't supported yet.", operOpcodeModId)
                raise ChemuException(CPU_EXCEPTION_UD)
        elif (operOpcode >= 0xc8 and operOpcode <= 0xcf): # BSWAP R32
            regName  = CPU_REGISTER_DWORD[operOpcode&7]
            op1 = (<Registers>self.main.cpu.registers).regRead(regName, False)
            op1 = (<Misc>self.main.misc).reverseByteOrder(op1, OP_SIZE_DWORD)
            (<Registers>self.main.cpu.registers).regWrite(regName, op1)
        else:
            self.main.printMsg("opcodeGroup0F: invalid operOpcode. {0:#04x}", operOpcode)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroupFE(self):
        cdef unsigned char operSize, operOpcode, operOpcodeId
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        operOpcode = (<Registers>self.main.cpu.registers).getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(OP_SIZE_BYTE)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(OP_SIZE_BYTE)
        else:
            self.main.printMsg("opcodeGroupFE: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef opcodeGroupFF(self):
        cdef unsigned char operSize, operOpcode, operOpcodeId
        cdef unsigned short segVal
        cdef unsigned long op1, eipAddr
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        operOpcode = (<Registers>self.main.cpu.registers).getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (operOpcodeId == 0): # 0/INC
            self.incFuncRM(operSize)
        elif (operOpcodeId == 1): # 1/DEC
            self.decFuncRM(operSize)
        elif (operOpcodeId == 2): # 2/CALL NEAR
            eipAddr = self.modRMInstance.modRMLoad(operSize, False, True)
            self.stackPushRegId(CPU_REGISTER_EIP, operSize)
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 3): # 3/CALL FAR
            op1 = self.modRMInstance.getRMValueFull(operSize)
            eipAddr = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(op1, operSize, self.modRMInstance.rmNameSegId, True)
            segVal = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(op1+operSize, OP_SIZE_WORD, self.modRMInstance.rmNameSegId, True)
            self.stackPushSegId(CPU_SEGMENT_CS, operSize)
            self.stackPushRegId(CPU_REGISTER_EIP, operSize)
            self.syncProtectedModeState()
            (<Registers>self.main.cpu.registers).segWrite(CPU_SEGMENT_CS, segVal)
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 4): # 4/JMP NEAR
            eipAddr = self.modRMInstance.modRMLoad(operSize, False, True)
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 5): # 5/JMP FAR
            op1 = self.modRMInstance.getRMValueFull(operSize)
            eipAddr = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(op1, operSize, self.modRMInstance.rmNameSegId, True)
            segVal = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(op1+operSize, OP_SIZE_WORD, self.modRMInstance.rmNameSegId, True)
            self.syncProtectedModeState()
            (<Registers>self.main.cpu.registers).segWrite(CPU_SEGMENT_CS, segVal)
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EIP, eipAddr)
        elif (operOpcodeId == 6): # 6/PUSH
            op1 = self.modRMInstance.modRMLoad(operSize, False, True)
            self.stackPushValue(op1, operSize)
        else:
            self.main.printMsg("opcodeGroupFF: invalid operOpcodeId. {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef incFuncReg(self, unsigned char regId, unsigned char regSize):
        cdef unsigned char origCF
        cdef unsigned long retValue
        origCF = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_CF)
        retValue = (<Registers>self.main.cpu.registers).regAdd(regId, 1)
        (<Registers>self.main.cpu.registers).setFullFlags(retValue-1, 1, regSize, OPCODE_ADD, False)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, origCF)
    cdef decFuncReg(self, unsigned char regId, unsigned char regSize):
        cdef unsigned char origCF
        cdef unsigned long retValue
        origCF = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_CF)
        retValue = (<Registers>self.main.cpu.registers).regSub(regId, 1)
        (<Registers>self.main.cpu.registers).setFullFlags(retValue+1, 1, regSize, OPCODE_SUB, False)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, origCF)
    cdef incFuncRM(self, unsigned char rmSize):
        cdef unsigned char origCF
        cdef unsigned long retValue
        origCF = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_CF)
        retValue = self.modRMInstance.modRMSave(rmSize, 1, True, OPCODE_ADD)
        (<Registers>self.main.cpu.registers).setFullFlags(retValue-1, 1, rmSize, OPCODE_ADD, False)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, origCF)
    cdef decFuncRM(self, unsigned char rmSize):
        cdef unsigned char origCF
        cdef unsigned long retValue
        origCF = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_CF)
        retValue = self.modRMInstance.modRMSave(rmSize, 1, True, OPCODE_SUB)
        (<Registers>self.main.cpu.registers).setFullFlags(retValue+1, 1, rmSize, OPCODE_SUB, False)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, origCF)
    cdef incReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        regName  = CPU_REGISTER_WORD[self.main.cpu.opcode&7]
        regName  = (<Registers>self.main.cpu.registers).getWordAsDword(regName, operSize)
        self.incFuncReg(regName, operSize)
    cdef decReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        regName  = CPU_REGISTER_WORD[self.main.cpu.opcode&7]
        regName  = (<Registers>self.main.cpu.registers).getWordAsDword(regName, operSize)
        self.decFuncReg(regName, operSize)
    cdef pushReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        regName  = CPU_REGISTER_WORD[self.main.cpu.opcode&7]
        regName  = (<Registers>self.main.cpu.registers).getWordAsDword(regName, operSize)
        self.stackPushRegId(regName, operSize)
    cdef pushSeg(self, short opcode):
        cdef unsigned char operSize
        cdef unsigned short segName
        if (opcode == -1):
            opcode = self.main.cpu.opcode
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
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
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        regName  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_WORD[self.main.cpu.opcode&7], operSize)
        self.stackPopRegId(regName, operSize)
    cdef popSeg(self, short opcode):
        cdef unsigned char operSize
        cdef unsigned short segName
        if (opcode == -1):
            opcode = self.main.cpu.opcode
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
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
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        operOpcode = (<Registers>self.main.cpu.registers).getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        if (operOpcodeId == 0): # POP
            self.stackPopRM(operSize)
        else:
            self.main.printMsg("popRM16_32: unknown operOpcodeId: {0:d}", operOpcodeId)
            raise ChemuException(CPU_EXCEPTION_UD)
    cdef lea(self):
        cdef unsigned char operSize, addrSize
        cdef unsigned long mmAddr
        (<Registers>self.main.cpu.registers).getOpAddrCodeSegSize(&operSize, &addrSize)
        self.modRMInstance.modRMOperands(addrSize, MODRM_FLAGS_NONE)
        mmAddr = self.modRMInstance.getRMValueFull(addrSize)&(<Misc>self.main.misc).getBitMaskFF(operSize)
        self.modRMInstance.modRSave(operSize, mmAddr, OPCODE_SAVE)
    cdef retNear(self, unsigned char imm):
        cdef unsigned char operSize, stackAddrSize
        cdef unsigned short espName
        cdef unsigned long tempEIP
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        stackAddrSize = (<Registers>self.main.cpu.registers).getAddrSegSize(CPU_SEGMENT_SS)
        espName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        tempEIP = self.stackPopValue(operSize)
        (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EIP, tempEIP)
        if (imm):
            (<Registers>self.main.cpu.registers).regAdd(espName, imm)
    cdef retNearImm(self):
        cdef unsigned short imm
        imm = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_WORD, False) # imm16
        self.retNear(imm)
    cdef retFar(self, unsigned char imm):
        cdef unsigned char operSize, stackAddrSize
        cdef unsigned short espName
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        stackAddrSize = (<Registers>self.main.cpu.registers).getAddrSegSize(CPU_SEGMENT_SS)
        espName = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SP, stackAddrSize)
        self.syncProtectedModeState()
        self.stackPopRegId(CPU_REGISTER_EIP, operSize)
        self.stackPopSegId(CPU_SEGMENT_CS, operSize)
        if (imm):
            (<Registers>self.main.cpu.registers).regAdd(espName, imm)
    cdef retFarImm(self):
        cdef unsigned short imm
        imm = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_WORD, False) # imm16
        self.retFar(imm)
    cdef lfpFunc(self, unsigned char segId): # 'load far pointer' function
        cdef unsigned char operSize
        cdef unsigned short segmentAddr
        cdef unsigned long mmAddr, offsetAddr
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        mmAddr = self.modRMInstance.getRMValueFull(operSize)
        offsetAddr = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(mmAddr, operSize, self.modRMInstance.rmNameSegId, True)
        segmentAddr = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(mmAddr+operSize, OP_SIZE_WORD, self.modRMInstance.rmNameSegId, True)
        self.modRMInstance.modRSave(operSize, offsetAddr, OPCODE_SAVE)
        (<Registers>self.main.cpu.registers).segWrite(segId, segmentAddr)
    cdef xlatb(self):
        cdef unsigned char addrSize, m8, data
        cdef unsigned short baseReg
        cdef unsigned long baseValue
        addrSize = (<Registers>self.main.cpu.registers).getAddrCodeSegSize()
        m8 = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AL, False)
        baseReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_BX, addrSize)
        baseValue = (<Registers>self.main.cpu.registers).regRead(baseReg, False)
        data = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(baseValue+m8, OP_SIZE_BYTE, CPU_SEGMENT_DS, True)
        (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AL, data)
    cdef opcodeGroup2_RM(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId, operSizeInBits
        cdef unsigned long operOp2, bitMaskHalf, bitMask
        cdef long long sop1, temp, tempmod
        cdef long sop2
        cdef unsigned long long utemp, operOp1, doubleBitMask, doubleBitMaskHalf
        operOpcode = (<Registers>self.main.cpu.registers).getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        operOp2 = self.modRMInstance.modRMLoad(operSize, False, True)
        operSizeInBits = operSize << 3
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        if (operOpcodeId in (GROUP2_OP_TEST, GROUP2_OP_TEST_ALIAS)):
            operOp1 = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(operSize, False)
            operOp2 = operOp2&operOp1
            (<Registers>self.main.cpu.registers).setSZP_C0_O0_A0(operOp2, operSize)
        elif (operOpcodeId == GROUP2_OP_NEG):
            self.modRMInstance.modRMSave(operSize, operOp2, True, OPCODE_NEG)
            (<Registers>self.main.cpu.registers).setFullFlags(0, operOp2, operSize, OPCODE_SUB, False)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, operOp2!=0)
        elif (operOpcodeId == GROUP2_OP_NOT):
            self.modRMInstance.modRMSave(operSize, operOp2, True, OPCODE_NOT)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_MUL):
            operOp1 = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AL, False)
            operSum = operOp1*operOp2
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AX, operSum&BITMASK_WORD)
            (<Registers>self.main.cpu.registers).setFullFlags(operOp1, operOp2, operSize, OPCODE_MUL, False)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_IMUL):
            sop1 = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AL, True)
            sop2 = self.modRMInstance.modRMLoad(operSize, True, True)
            operSum = sop1*sop2
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AX, operSum&BITMASK_WORD)
            (<Registers>self.main.cpu.registers).setFullFlags(sop1, sop2, operSize, OPCODE_MUL, True)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_DIV):
            op1Word = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AX, False)
            if (operOp2 == 0):
                raise ChemuException(CPU_EXCEPTION_DE)
            temp, tempmod = divmod(op1Word, operOp2)
            if (temp > <unsigned char>bitMask):
                raise ChemuException(CPU_EXCEPTION_DE)
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AL, temp&BITMASK_BYTE)
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AH, tempmod&BITMASK_BYTE)
            (<Registers>self.main.cpu.registers).setFullFlags(op1Word, operOp2, operSize, OPCODE_DIV, False)
        elif (operSize == OP_SIZE_BYTE and operOpcodeId == GROUP2_OP_IDIV):
            sop1  = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AX, True)
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
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AL, temp&BITMASK_BYTE)
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AH, tempmod&BITMASK_BYTE)
            (<Registers>self.main.cpu.registers).setFullFlags(sop1, operOp2, operSize, OPCODE_DIV, False)
        elif (operOpcodeId == GROUP2_OP_MUL):
            eaxReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DX, operSize)
            operOp1 = (<Registers>self.main.cpu.registers).regRead(eaxReg, False)
            operSum = operOp1*operOp2
            (<Registers>self.main.cpu.registers).regWrite(edxReg, (operSum>>operSizeInBits)&bitMask)
            (<Registers>self.main.cpu.registers).regWrite(eaxReg, operSum&bitMask)
            (<Registers>self.main.cpu.registers).setFullFlags(operOp1, operOp2, operSize, OPCODE_MUL, False)
        elif (operOpcodeId == GROUP2_OP_IMUL):
            eaxReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DX, operSize)
            sop1 = (<Registers>self.main.cpu.registers).regRead(eaxReg, True)
            sop2 = self.modRMInstance.modRMLoad(operSize, True, True)
            operSum = sop1*sop2
            (<Registers>self.main.cpu.registers).regWrite(edxReg, (operSum>>operSizeInBits)&bitMask)
            (<Registers>self.main.cpu.registers).regWrite(eaxReg, operSum&bitMask)
            (<Registers>self.main.cpu.registers).setFullFlags(sop1, sop2, operSize, OPCODE_MUL, True)
        elif (operOpcodeId == GROUP2_OP_DIV):
            eaxReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DX, operSize)
            operOp1  = (<Registers>self.main.cpu.registers).regRead(edxReg, False)<<operSizeInBits
            operOp1 |= (<Registers>self.main.cpu.registers).regRead(eaxReg, False)
            if (operOp2 == 0):
                raise ChemuException(CPU_EXCEPTION_DE)
            utemp, tempmod = divmod(operOp1, operOp2)
            if (utemp > <unsigned long>bitMask):
                raise ChemuException(CPU_EXCEPTION_DE)
            (<Registers>self.main.cpu.registers).regWrite(eaxReg, utemp&bitMask)
            (<Registers>self.main.cpu.registers).regWrite(edxReg, tempmod&bitMask)
            (<Registers>self.main.cpu.registers).setFullFlags(operOp1, operOp2, operSize, OPCODE_DIV, False)
        elif (operOpcodeId == GROUP2_OP_IDIV):
            doubleBitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize<<1)
            eaxReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
            edxReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DX, operSize)
            operOp1 = (<Registers>self.main.cpu.registers).regRead(edxReg, False)<<operSizeInBits
            operOp1 |= (<Registers>self.main.cpu.registers).regRead(eaxReg, False)
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
            (<Registers>self.main.cpu.registers).regWrite(eaxReg, temp&bitMask)
            (<Registers>self.main.cpu.registers).regWrite(edxReg, tempmod&bitMask)
            (<Registers>self.main.cpu.registers).setFullFlags(sop1, operOp2, operSize, OPCODE_DIV, False)
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
        inProtectedMode = (<Segments>(<Registers>self.main.cpu.registers).segments).isInProtectedMode()
        if (inProtectedMode):
            eflagsClearThis |= (FLAG_NT | FLAG_VM)
        else:
            eflagsClearThis |= FLAG_AC
        segId = CPU_SEGMENT_DS
        if (intNum == -1):
            intNum = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        if (inProtectedMode):
            idtEntry = (<IdtEntry>(<Idt>(<Segments>(<Registers>self.main.cpu.registers).segments).idt).getEntry(intNum))
            entrySegment = idtEntry.entrySegment
            entryEip = idtEntry.entryEip
            entryType = idtEntry.entryType
            entrySize = idtEntry.entrySize
            entryNeededDPL = idtEntry.entryNeededDPL
            entryPresent = idtEntry.entryPresent
        else:
            (<Idt>(<Segments>(<Registers>self.main.cpu.registers).segments).idt).getEntryRealMode(intNum, &entrySegment, <unsigned short*>&entryEip)
            if ((entrySegment == 0xf000 and intNum != 0x10) or (entrySegment == 0xc000 and intNum == 0x10)):
                if (self.main.platform.pythonBios.interrupt(intNum)):
                    return
        ##self.main.debug("Interrupt: Go Interrupt {0:#04x}. CS: {1:#06x}, (E)IP: {2:#06x}", intNum, entrySegment, entryEip)
        if (inProtectedMode):
            if (((<Registers>self.main.cpu.registers).cpl and (<Registers>self.main.cpu.registers).cpl > entrySegment&3) or (<Segments>(<Registers>self.main.cpu.registers).segments).getSegDPL(entrySegment)):
                self.main.exitError("Interrupt: (cpl!=0 and cpl>rpl) or dpl!=0")
                return
            entrySegment = ((entrySegment&0xfffc)|((<Registers>self.main.cpu.registers).cpl&3))
            if ((<Registers>self.main.cpu.registers).cpl): # FIXME
                self.stackPushSegId(CPU_SEGMENT_SS, entrySize)
                self.stackPushRegId(CPU_REGISTER_ESP, entrySize)
        if (entryType == IDT_INTR_TYPE_INTERRUPT):
            eflagsClearThis |= FLAG_IF
        self.stackPushRegId(CPU_REGISTER_EFLAGS, entrySize)
        (<Registers>self.main.cpu.registers).setEFLAG(eflagsClearThis, False)
        self.stackPushSegId(CPU_SEGMENT_CS, entrySize)
        self.stackPushRegId(CPU_REGISTER_EIP, entrySize)
        (<Registers>self.main.cpu.registers).segWrite(CPU_SEGMENT_CS, entrySegment)
        (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EIP, entryEip)
        if (inProtectedMode and errorCode != -1):
            self.stackPushValue(errorCode, entrySize)
    cdef into(self):
        if ((<Registers>self.main.cpu.registers).getEFLAG(FLAG_OF)):
            self.interrupt(CPU_EXCEPTION_OF, -1)
    cdef int3(self):
        self.interrupt(CPU_EXCEPTION_BP, -1)
    cdef iret(self):
        cdef unsigned char operSize, inProtectedMode
        cdef unsigned short SSsel
        cdef unsigned long tempEFLAGS, EFLAGS, newEIP, eflagsMask, temp
        inProtectedMode = (<Segments>(<Registers>self.main.cpu.registers).segments).isInProtectedMode()
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        if ((not inProtectedMode) and operSize == OP_SIZE_DWORD):
            newEIP = self.stackGetValue(operSize)
            if ((newEIP>>16)!=0):
                raise ChemuException(CPU_EXCEPTION_GP)
        self.stackPopRegId(CPU_REGISTER_EIP, operSize)
        self.stackPopSegId(CPU_SEGMENT_CS, operSize)
        tempEFLAGS = self.stackPopValue(operSize)
        EFLAGS = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_EFLAGS, False)
        if (inProtectedMode):
            if (0): # TODO
                pass
            else: # RPL==CPL
                eflagsMask = FLAG_CF | FLAG_PF | FLAG_AF | FLAG_ZF | \
                             FLAG_SF | FLAG_TF | FLAG_DF | FLAG_OF | \
                             FLAG_NT
                if (operSize in (OP_SIZE_DWORD, OP_SIZE_QWORD)):
                    eflagsMask |= FLAG_RF | FLAG_AC | FLAG_ID
                if ((<Registers>self.main.cpu.registers).cpl < (<Registers>self.main.cpu.registers).iopl):
                    eflagsMask |= FLAG_IF
                if (not (<Registers>self.main.cpu.registers).cpl):
                    eflagsMask |= FLAG_IOPL
                    if (operSize in (OP_SIZE_DWORD, OP_SIZE_QWORD)):
                        eflagsMask |= FLAG_VIF | FLAG_VIP
                temp = tempEFLAGS&eflagsMask
                tempEFLAGS &= ~eflagsMask
                tempEFLAGS |= temp
        else:
            if (operSize == OP_SIZE_DWORD):
                tempEFLAGS = ((tempEFLAGS & 0x257fd5) | (EFLAGS & 0x1a0000))
        if (operSize == OP_SIZE_WORD):
            tempEFLAGS &= BITMASK_WORD
            if (not inProtectedMode):
                tempEFLAGS |= (EFLAGS&0xffff0000)
        (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EFLAGS, tempEFLAGS)
    cdef aad(self):
        cdef unsigned char imm8, tempAL, tempAH
        imm8 = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        tempAL = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AL, False)
        tempAH = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AH, False)
        tempAL = (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AX, (tempAL + (tempAH * imm8))&BITMASK_BYTE)
        (<Registers>self.main.cpu.registers).setSZP_C0_O0_A0(tempAL, OP_SIZE_BYTE)
    cdef aam(self):
        cdef unsigned char imm8, tempAL, ALdiv, ALmod
        imm8 = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        if (imm8 == 0):
            raise ChemuException(CPU_EXCEPTION_DE)
        tempAL = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AL, False)
        ALdiv, ALmod = divmod(tempAL, imm8)
        (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AH, ALdiv)
        (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AL, ALmod)
        (<Registers>self.main.cpu.registers).setSZP_C0_O0_A0(ALmod, OP_SIZE_BYTE)
    cdef aaa(self):
        cdef unsigned char AFflag, tempAL, tempAH
        cdef unsigned short tempAX
        tempAX = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AX, False)
        tempAL = tempAX&BITMASK_BYTE
        tempAH = (tempAX>>8)&BITMASK_BYTE
        AFflag = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_AF)!=0
        if (((tempAL&0xf)>9) or AFflag):
            tempAL += 6
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_AF | FLAG_CF, True)
            (<Registers>self.main.cpu.registers).regAdd(CPU_REGISTER_AH, 1)
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AL, tempAL&0xf)
        else:
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_AF | FLAG_CF, False)
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AL, tempAL&0xf)
        (<Registers>self.main.cpu.registers).setSZP_O0((<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AL, False), OP_SIZE_BYTE)
    cdef aas(self):
        cdef unsigned char AFflag, tempAL, tempAH
        cdef unsigned short tempAX
        tempAX = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AX, False)
        tempAL = tempAX&BITMASK_BYTE
        tempAH = (tempAX>>8)&BITMASK_BYTE
        AFflag = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_AF)!=0
        if (((tempAL&0xf)>9) or AFflag):
            tempAL -= 6
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_AF | FLAG_CF, True)
            (<Registers>self.main.cpu.registers).regSub(CPU_REGISTER_AH, 1)
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AL, tempAL&0xf)
        else:
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_AF | FLAG_CF, False)
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AL, tempAL&0xf)
        (<Registers>self.main.cpu.registers).setSZP_O0((<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AL, False), OP_SIZE_BYTE)
    cdef daa(self):
        cdef unsigned char old_AL, old_AF, old_CF
        old_AL = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AL, False)
        old_AF = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_AF)!=0
        old_CF = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_CF)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, False)
        if (((old_AL&0xf)>9) or old_AF):
            (<Registers>self.main.cpu.registers).regAdd(CPU_REGISTER_AL, 0x6)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, old_CF or (old_AL+6>BITMASK_BYTE))
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_AF, True)
        else:
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_AF, False)
        if ((old_AL > 0x99) or old_CF):
            (<Registers>self.main.cpu.registers).regAdd(CPU_REGISTER_AL, 0x60)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, True)
        else:
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, False)
        (<Registers>self.main.cpu.registers).setSZP_O0((<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AL, False), OP_SIZE_BYTE)
    cdef das(self):
        cdef unsigned char old_AL, old_AF, old_CF
        old_AL = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AL, False)
        old_AF = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_AF)!=0
        old_CF = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_CF)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, False)
        if (((old_AL&0xf)>9) or old_AF):
            (<Registers>self.main.cpu.registers).regSub(CPU_REGISTER_AL, 6)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, old_CF or (old_AL-6<0))
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_AF, True)
        else:
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_AF, False)
        if ((old_AL > 0x99) or old_CF):
            (<Registers>self.main.cpu.registers).regSub(CPU_REGISTER_AL, 0x60)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, True)
        (<Registers>self.main.cpu.registers).setSZP_O0((<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AL, False), OP_SIZE_BYTE)
    cdef cbw_cwde(self):
        cdef unsigned char operSize
        cdef unsigned long op2, bitMask
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        if (operSize == OP_SIZE_WORD): # CBW
            op2 = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AL, True)&bitMask
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AX, op2)
        elif (operSize == OP_SIZE_DWORD): # CWDE
            op2 = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AX, True)&bitMask
            (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_EAX, op2)
        else:
            self.main.exitError("cbw_cwde: operSize {0:d} not in (OP_SIZE_WORD, OP_SIZE_DWORD))", operSize)
    cdef cwd_cdq(self):
        cdef unsigned char operSize
        cdef unsigned short eaxReg, edxReg
        cdef unsigned long bitMask, bitMaskHalf, op2
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        eaxReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
        edxReg = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_DX, operSize)
        op2 = (<Registers>self.main.cpu.registers).regRead(eaxReg, False)
        if (op2&bitMaskHalf):
            (<Registers>self.main.cpu.registers).regWrite(edxReg, bitMask)
        else:
            (<Registers>self.main.cpu.registers).regWrite(edxReg, 0)
    cdef shlFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char newCF, newOF
        cdef unsigned long bitMask, bitMaskHalf, dest
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoad(operSize, False, True)
        count = count&0x1f
        if (count == 0):
            newCF = False
        else:
            newCF = ((dest<<(count-1))&bitMaskHalf)!=0
        dest <<= count
        dest &= bitMask
        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        if (count == 0):
            return
        elif (count == 1):
            newOF = (((dest&bitMaskHalf)!=0)^newCF)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_OF, newOF)
        else:
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_OF, False)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, newCF)
        (<Registers>self.main.cpu.registers).setSZP(dest, operSize)
    cdef sarFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char newCF
        cdef unsigned long bitMask
        cdef long long dest
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        dest = self.modRMInstance.modRMLoad(operSize, True, True)
        count = count&0x1f
        if (count == 0):
            newCF = ((dest)&1)
        else:
            newCF = ((dest>>(count-1))&1)
        dest >>= count
        dest &= bitMask
        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        if (count == 0):
            return
        elif (count == 1):
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_OF, False)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, newCF)
        (<Registers>self.main.cpu.registers).setSZP(dest, operSize)
    cdef shrFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char newCF_OF
        cdef unsigned long bitMask, bitMaskHalf, dest, tempDest
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
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
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, newCF_OF)
        newCF_OF = ((tempDest)&bitMaskHalf)!=0
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_OF, newCF_OF)
        (<Registers>self.main.cpu.registers).setSZP(dest, operSize)
    cdef rclFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char tempCF_OF, newCF, i
        cdef unsigned long bitMask, bitMaskHalf, dest
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoad(operSize, False, True)
        count = count&0x1f
        if (operSize == OP_SIZE_BYTE):
            count %= 9
        elif (operSize == OP_SIZE_WORD):
            count %= 17
        newCF = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_CF)
        for i in range(count):
            tempCF_OF = (dest&bitMaskHalf)!=0
            dest = ((dest<<1)|newCF)&bitMask
            newCF = tempCF_OF
        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        if (count == 0):
            return
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_OF, tempCF_OF)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, newCF)
    cdef rcrFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char tempCF_OF, newCF, i
        cdef unsigned long bitMask, bitMaskHalf, dest
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoad(operSize, False, True)
        count = count&0x1f
        newCF = (<Registers>self.main.cpu.registers).getEFLAG(FLAG_CF)
        if (operSize == OP_SIZE_BYTE):
            count %= 9
        elif (operSize == OP_SIZE_WORD):
            count %= 17

        if (count == 0):
            return
        tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_OF, tempCF_OF)

        for i in range(count):
            tempCF_OF = (dest&1)
            dest = (dest >> 1) | (newCF * bitMaskHalf)
            newCF = tempCF_OF
        dest &= bitMask

        self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, newCF)
    cdef rolFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char tempCF_OF, newCF, i
        cdef unsigned long bitMask, bitMaskHalf, dest
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
        bitMaskHalf = (<Misc>self.main.misc).getBitMask80(operSize)
        dest = self.modRMInstance.modRMLoad(operSize, False, True)

        if ((count & 0x1f) > 0):
            count = count%(operSize<<3)

            for i in range(count):
                tempCF_OF = (dest&bitMaskHalf)!=0
                dest = (dest << 1) | tempCF_OF
                dest &= bitMask

            self.modRMInstance.modRMSave(operSize, dest, True, OPCODE_SAVE)

            if (count == 0):
                return
            newCF = dest&1
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, newCF)
            tempCF_OF = (((dest&bitMaskHalf)!=0)^newCF)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_OF, tempCF_OF)
    cdef rorFunc(self, unsigned char operSize, unsigned char count):
        cdef unsigned char tempCF_OF, newCF_M1, i
        cdef unsigned long bigMask, bitMaskHalf, dest, destM1
        bitMask = (<Misc>self.main.misc).getBitMaskFF(operSize)
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
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, tempCF_OF)
            tempCF_OF = (tempCF_OF ^ newCF_M1)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_OF, tempCF_OF)
    cdef opcodeGroup4_RM_1(self, unsigned char operSize):
        cdef unsigned char operOpcode, operOpcodeId
        operOpcode = (<Registers>self.main.cpu.registers).getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
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
        operOpcode = (<Registers>self.main.cpu.registers).getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        count = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_CL, False)
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
        operOpcode = (<Registers>self.main.cpu.registers).getCurrentOpcode(OP_SIZE_BYTE, False)
        operOpcodeId = (operOpcode>>3)&7
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        count = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
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
        cdef unsigned char ahVal, orThis
        ahVal = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AH, False)
        (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF | FLAG_PF | \
            FLAG_AF | FLAG_ZF | FLAG_SF, False)
        orThis = ((ahVal & (FLAG_CF | FLAG_PF | FLAG_AF | FLAG_ZF | FLAG_SF)) | FLAG_REQUIRED)
        (<Registers>self.main.cpu.registers).regOr(CPU_REGISTER_FLAGS, orThis)
    cdef lahf(self):
        cdef unsigned char newAH, flagsByte
        flagsByte = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_FLAGS, False)&BITMASK_BYTE
        newAH = ((flagsByte & (FLAG_CF | FLAG_PF | FLAG_AF | FLAG_ZF | FLAG_SF)) | FLAG_REQUIRED)
        (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AH, newAH)
    cdef xchgFuncReg(self, unsigned short regName, unsigned short regName2):
        cdef unsigned long regValue, regValue2
        regValue, regValue2 = (<Registers>self.main.cpu.registers).regRead(regName, False), (<Registers>self.main.cpu.registers).regRead(regName2, False)
        (<Registers>self.main.cpu.registers).regWrite(regName, regValue2)
        (<Registers>self.main.cpu.registers).regWrite(regName2, regValue)
    ##### DON'T USE XCHG AX, AX FOR OPCODE 0x90, use NOP instead!!
    cdef xchgReg(self):
        cdef unsigned char operSize
        cdef unsigned short regName, regName2
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        regName  = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_AX, operSize)
        regName2 = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_WORD[self.main.cpu.opcode&7], operSize)
        self.xchgFuncReg(regName, regName2)
    cdef xchgR_RM(self, unsigned char operSize):
        cdef unsigned long op1, op2
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.modRMInstance.modRLoad(operSize, False)
        op2 = self.modRMInstance.modRMLoad(operSize, False, True)
        self.modRMInstance.modRSave(operSize, op2, OPCODE_SAVE)
        self.modRMInstance.modRMSave(operSize, op1, True, OPCODE_SAVE)
    cdef enter(self):
        cdef unsigned char operSize, stackSize, nestingLevel, i
        cdef unsigned short sizeOp, espNameStack, ebpNameStack
        cdef unsigned long frameTemp, temp
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        stackSize = (<Registers>self.main.cpu.registers).getAddrSegSize(CPU_SEGMENT_SS)
        espNameStack = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SP, stackSize)
        ebpNameStack = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_BP, stackSize)
        sizeOp = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_WORD, False)
        nestingLevel = (<Registers>self.main.cpu.registers).getCurrentOpcodeAdd(OP_SIZE_BYTE, False)
        nestingLevel %= 32
        self.stackPushRegId(ebpNameStack, stackSize)
        frameTemp = (<Registers>self.main.cpu.registers).regRead(espNameStack, False)
        if (nestingLevel > 1):
            for i in range(nestingLevel-1):
                (<Registers>self.main.cpu.registers).regSub(ebpNameStack, operSize)
                temp = (<Registers>self.main.cpu.registers).mmReadValueUnsigned((<Registers>self.main.cpu.registers).regRead(ebpNameStack, False), operSize, CPU_SEGMENT_SS, False)
                self.stackPushValue(temp, operSize)
        if (nestingLevel >= 1):
            self.stackPushValue(frameTemp, operSize)
        (<Registers>self.main.cpu.registers).regWrite(ebpNameStack, frameTemp)
        (<Registers>self.main.cpu.registers).regSub(espNameStack, sizeOp)
    cdef leave(self):
        cdef unsigned char operSize, stackSize
        cdef unsigned short ebpNameOper, espNameStack, ebpNameStack
        operSize = (<Registers>self.main.cpu.registers).getOpCodeSegSize()
        stackSize = (<Registers>self.main.cpu.registers).getAddrSegSize(CPU_SEGMENT_SS)
        ebpNameOper = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_BP, operSize)
        espNameStack = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_SP, stackSize)
        ebpNameStack = (<Registers>self.main.cpu.registers).getWordAsDword(CPU_REGISTER_BP, stackSize)
        (<Registers>self.main.cpu.registers).regWrite(espNameStack, (<Registers>self.main.cpu.registers).regRead(ebpNameStack, False))
        self.stackPopRegId(ebpNameOper, operSize)
    cdef cmovFunc(self, unsigned char operSize, unsigned char cond): # R16, R/M 16; R32, R/M 32
        self.movR_RM(operSize, cond)
    cdef setWithCondFunc(self, unsigned char cond): # if cond==True set 1, else 0
        self.modRMInstance.modRMOperands(OP_SIZE_BYTE, MODRM_FLAGS_NONE)
        self.modRMInstance.modRMSave(OP_SIZE_BYTE, cond!=0, True, OPCODE_SAVE)
    cdef arpl(self):
        cdef unsigned char operSize
        cdef unsigned short op1, op2
        if (not (<Segments>(<Registers>self.main.cpu.registers).segments).isInProtectedMode()):
            raise ChemuException(CPU_EXCEPTION_UD)
        operSize = OP_SIZE_WORD
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        op1 = self.modRMInstance.modRMLoad(operSize, False, True)
        op2 = self.modRMInstance.modRLoad(operSize, False)
        if (op1 < op2):
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_ZF, True)
            self.modRMInstance.modRMSave(operSize, (op1&0xfffc)|(op2&3), True, OPCODE_SAVE)
        else:
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_ZF, False)
    cdef bound(self):
        cdef unsigned char operSize, addrSize
        cdef unsigned long returnInt
        cdef long index, lowerBound, upperBound
        (<Registers>self.main.cpu.registers).getOpAddrCodeSegSize(&operSize, &addrSize)
        self.modRMInstance.modRMOperands(operSize, MODRM_FLAGS_NONE)
        index = self.modRMInstance.modRLoad(operSize, True)
        returnInt = self.modRMInstance.getRMValueFull(addrSize)
        lowerBound = (<Registers>self.main.cpu.registers).mmReadValueSigned(returnInt, operSize, self.modRMInstance.rmNameSegId, True)
        upperBound = (<Registers>self.main.cpu.registers).mmReadValueSigned(returnInt+operSize, operSize, self.modRMInstance.rmNameSegId, True)
        if (index < lowerBound or index > upperBound+operSize):
            raise ChemuException(CPU_EXCEPTION_BR)
    cdef btFunc(self, unsigned long offset, unsigned char newValType):
        cdef unsigned char operSize, addrSize, operSizeInBits, state
        cdef unsigned long value, address
        (<Registers>self.main.cpu.registers).getOpAddrCodeSegSize(&operSize, &addrSize)
        operSizeInBits = operSize << 3
        address = 0
        if (self.modRMInstance.mod == 3): # register operand
            offset %= operSizeInBits
            value = self.modRMInstance.modRLoad(operSize, False)
            state = (<Registers>self.main.cpu.registers).valGetBit(value, offset)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, state)
        else: # memory operand
            address = self.modRMInstance.getRMValueFull(addrSize)
            address += (operSize * (offset // operSizeInBits))
            value = (<Registers>self.main.cpu.registers).mmReadValueUnsigned(address, operSize, self.modRMInstance.rmNameSegId, True)
            state = (<Registers>self.main.cpu.registers).valGetBit(value, offset)
            (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, state)
        if (newValType != BT_NONE):
            if (newValType == BT_COMPLEMENT):
                state = not state
            elif (newValType == BT_RESET):
                state = False
            elif (newValType == BT_SET):
                state = True
            else:
                self.main.exitError("btFunc: unknown newValType: {0:d}", newValType)
            value = (<Registers>self.main.cpu.registers).valSetBit(value, offset, state)
            if (self.modRMInstance.mod == 3): # register operand
                self.modRMInstance.modRSave(operSize, value, OPCODE_SAVE)
            else: # memory operands
                (<Registers>self.main.cpu.registers).mmWriteValue(address, value, operSize, self.modRMInstance.rmNameSegId, True)
    cdef run(self):
        self.modRMInstance = ModRMClass(self.main, (<Registers>self.main.cpu.registers))
        self.modRMInstanceOther = ModRMClass(self.main, (<Registers>self.main.cpu.registers))
    # end of opcodes



