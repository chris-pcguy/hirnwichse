
from misc cimport Misc
from segments cimport Segments, Gdt, Idt, IdtEntry, GdtEntry
from registers cimport Registers, ModRMClass
from mm cimport Mm

include "cpu_globals.pxi"


cdef class Opcodes:
    cpdef object main
    cdef Registers registers
    cdef ModRMClass modRMInstance
    cdef int executeOpcode(self, unsigned char opcode) except -1
    cdef inline void cli(self):
        self.registers.setEFLAG(FLAG_IF, False)
    cdef inline void sti(self):
        self.registers.setEFLAG(FLAG_IF, True)
        self.main.cpu.asyncEvent = True # set asyncEvent to True when set IF/TF to True
    cdef inline void cld(self):
        self.registers.setEFLAG(FLAG_DF, False)
    cdef inline void std(self):
        self.registers.setEFLAG(FLAG_DF, True)
    cdef inline void clc(self):
        self.registers.setEFLAG(FLAG_CF, False)
    cdef inline void stc(self):
        self.registers.setEFLAG(FLAG_CF, True)
    cdef inline void cmc(self):
        self.registers.setEFLAG(FLAG_CF, not self.registers.getEFLAG(FLAG_CF))
    cdef inline void hlt(self):
        self.main.cpu.cpuHalted = True
    cdef inline void syncProtectedModeState(self):
        (<Segments>self.registers.segments).protectedModeOn = self.registers.getFlag(CPU_REGISTER_CR0, CR0_FLAG_PE)
    cdef long int inPort(self, unsigned short ioPortAddr, unsigned char dataSize) except -1
    cdef int outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize) except -1
    cdef int jumpFarDirect(self, unsigned char method, unsigned short segVal, unsigned int eipVal) except -1
    cdef int jumpFarAbsolutePtr(self) except -1
    cdef int loopFunc(self, unsigned char loopType) except -1
    cdef int opcodeR_RM(self, unsigned char opcode, unsigned char operSize) except -1
    cdef int opcodeRM_R(self, unsigned char opcode, unsigned char operSize) except -1
    cdef int opcodeAxEaxImm(self, unsigned char opcode, unsigned char operSize) except -1
    cdef int movImmToR(self, unsigned char operSize) except -1
    cdef int movRM_R(self, unsigned char operSize) except -1
    cdef int movR_RM(self, unsigned char operSize, unsigned char cond) except -1
    cdef int movRM16_SREG(self) except -1
    cdef int movSREG_RM16(self) except -1
    cdef int movAxMoffs(self, unsigned char operSize) except -1
    cdef int movMoffsAx(self, unsigned char operSize) except -1
    cdef int stosFunc(self, unsigned char operSize) except -1
    cdef int movsFunc(self, unsigned char operSize) except -1
    cdef int lodsFunc(self, unsigned char operSize) except -1
    cdef int cmpsFunc(self, unsigned char operSize) except -1
    cdef int scasFunc(self, unsigned char operSize) except -1
    cdef int inAxImm8(self, unsigned char operSize) except -1
    cdef int inAxDx(self, unsigned char operSize) except -1
    cdef int outImm8Ax(self, unsigned char operSize) except -1
    cdef int outDxAx(self, unsigned char operSize) except -1
    cdef int outsFunc(self, unsigned char operSize) except -1
    cdef int insFunc(self, unsigned char operSize) except -1
    cdef int jcxzShort(self) except -1
    cdef int jumpShort(self, unsigned char offsetSize, unsigned char cond) except -1
    cdef int callNearRel16_32(self) except -1
    cdef int callPtr16_32(self) except -1
    cdef int pushaWD(self) except -1
    cdef int popaWD(self) except -1
    cdef int pushfWD(self) except -1
    cdef int popfWD(self) except -1
    cdef int stackPopSegId(self, unsigned short segId) except -1
    cdef int stackPopRegId(self, unsigned short regId) except -1
    cdef unsigned int stackPopValue(self, unsigned char increaseStackAddr)
    cdef int stackPushValue(self, unsigned int value, unsigned char operSize) except -1
    cdef int stackPushSegId(self, unsigned short segId, unsigned char operSize) except -1
    cdef int stackPushRegId(self, unsigned short regId, unsigned char operSize) except -1
    cdef int pushIMM(self, unsigned char immIsByte) except -1
    cdef int imulR_RM_ImmFunc(self, unsigned char immIsByte) except -1
    cdef int opcodeGroup1_RM_ImmFunc(self, unsigned char operSize, unsigned char immIsByte) except -1
    cdef int opcodeGroup3_RM_ImmFunc(self, unsigned char operSize) except -1
    cdef int opcodeGroup0F(self) except -1
    cdef int opcodeGroupFE(self) except -1
    cdef int opcodeGroupFF(self) except -1
    cdef int incFuncReg(self, unsigned short regId, unsigned char regSize) except -1
    cdef int decFuncReg(self, unsigned short regId, unsigned char regSize) except -1
    cdef int incFuncRM(self, unsigned char rmSize) except -1
    cdef int decFuncRM(self, unsigned char rmSize) except -1
    cdef int incReg(self) except -1
    cdef int decReg(self) except -1
    cdef int pushReg(self) except -1
    cdef int pushSeg(self, unsigned char opcode) except -1
    cdef int popReg(self) except -1
    cdef int popSeg(self, unsigned char opcode) except -1
    cdef int popRM16_32(self) except -1
    cdef int lea(self) except -1
    cdef int retNear(self, unsigned short imm) except -1
    cdef int retNearImm(self) except -1
    cdef int retFar(self, unsigned short imm) except -1
    cdef int retFarImm(self) except -1
    cdef int lfpFunc(self, unsigned short segId) except -1 # 'load far pointer' function
    cdef int xlatb(self) except -1
    cdef int opcodeGroup2_RM(self, unsigned char operSize) except -1
    cpdef interrupt(self, signed short intNum, signed int errorCode) # TODO: complete this!
    cpdef into(self)
    cpdef int3(self)
    cpdef iret(self)
    cdef int aad(self) except -1
    cdef int aam(self) except -1
    cdef int aaa(self) except -1
    cdef int aas(self) except -1
    cdef int daa(self) except -1
    cdef int das(self) except -1
    cdef int cbw_cwde(self) except -1
    cdef int cwd_cdq(self) except -1
    cdef int shlFunc(self, unsigned char operSize, unsigned char count) except -1
    cdef int sarFunc(self, unsigned char operSize, unsigned char count) except -1
    cdef int shrFunc(self, unsigned char operSize, unsigned char count) except -1
    cdef int rclFunc(self, unsigned char operSize, unsigned char count) except -1
    cdef int rcrFunc(self, unsigned char operSize, unsigned char count) except -1
    cdef int rolFunc(self, unsigned char operSize, unsigned char count) except -1
    cdef int rorFunc(self, unsigned char operSize, unsigned char count) except -1
    cdef int opcodeGroup4_RM(self, unsigned char operSize, unsigned char method) except -1
    cdef int sahf(self) except -1
    cdef int lahf(self) except -1
    cdef int xchgFuncReg(self, unsigned short regName, unsigned short regName2) except -1
    cdef int xchgReg(self) except -1
    cdef int xchgR_RM(self, unsigned char operSize) except -1
    cdef int enter(self) except -1
    cdef int leave(self) except -1
    cdef int cmovFunc(self, unsigned char cond) except -1 # R16, R/M 16; R32, R/M 32
    cdef int setWithCondFunc(self, unsigned char cond) except -1 # if cond==True set 1, else 0
    cdef int arpl(self) except -1
    cdef int bound(self) except -1
    cdef int btFunc(self, unsigned int offset, unsigned char newValType) except -1
    cdef void run(self)
    # end of opcodes



