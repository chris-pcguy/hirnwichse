
include "cpu_globals.pxi"

from hirnwichse_main cimport Hirnwichse
from misc cimport Misc
from segments cimport GdtEntry, IdtEntry, Gdt, Idt, Paging, Segment, Segments
from registers cimport ModRMClass, Registers
from mm cimport Mm


cdef class Opcodes:
    cdef Hirnwichse main
    cdef Registers registers
    cdef ModRMClass modRMInstance
    cdef int executeOpcode(self, unsigned char opcode) except -1
    cdef int cli(self) except -1
    cdef int sti(self) except -1
    cdef int hlt(self) except -1
    cdef void cld(self)
    cdef void std(self)
    cdef void clc(self)
    cdef void stc(self)
    cdef void cmc(self)
    cdef inline unsigned int quirkCR0(self, unsigned int value):
        #value |= (CR0_FLAG_EM | CR0_FLAG_ET | CR0_FLAG_NE | CR0_FLAG_NW | CR0_FLAG_CD)
        #value |= (CR0_FLAG_EM | CR0_FLAG_NE)
        value &= ~(CR0_FLAG_ET | CR0_FLAG_MP)
        value |= (CR0_FLAG_EM | CR0_FLAG_NE | CR0_FLAG_ET)
        return value
    cdef int checkIOPL(self, unsigned short ioPortAddr, unsigned char dataSize) except -1
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
    cdef int stosFuncWord(self, unsigned char operSize) except -1
    cdef int stosFuncDword(self, unsigned char operSize) except -1
    cdef int stosFunc(self, unsigned char operSize) except -1
    cdef int movsFuncWord(self, unsigned char operSize) except -1
    cdef int movsFuncDword(self, unsigned char operSize) except -1
    cdef int movsFunc(self, unsigned char operSize) except -1
    cdef int lodsFuncWord(self, unsigned char operSize) except -1
    cdef int lodsFuncDword(self, unsigned char operSize) except -1
    cdef int lodsFunc(self, unsigned char operSize) except -1
    cdef int cmpsFuncWord(self, unsigned char operSize) except -1
    cdef int cmpsFuncDword(self, unsigned char operSize) except -1
    cdef int cmpsFunc(self, unsigned char operSize) except -1
    cdef int scasFuncWord(self, unsigned char operSize) except -1
    cdef int scasFuncDword(self, unsigned char operSize) except -1
    cdef int scasFunc(self, unsigned char operSize) except -1
    cdef int inAxImm8(self, unsigned char operSize) except -1
    cdef int inAxDx(self, unsigned char operSize) except -1
    cdef int outImm8Ax(self, unsigned char operSize) except -1
    cdef int outDxAx(self, unsigned char operSize) except -1
    cdef int outsFuncWord(self, unsigned char operSize) except -1
    cdef int outsFuncDword(self, unsigned char operSize) except -1
    cdef int outsFunc(self, unsigned char operSize) except -1
    cdef int insFuncWord(self, unsigned char operSize) except -1
    cdef int insFuncDword(self, unsigned char operSize) except -1
    cdef int insFunc(self, unsigned char operSize) except -1
    cdef int jcxzShort(self) except -1
    cdef int jumpShort(self, unsigned char offsetSize, unsigned char cond) except -1
    cdef int callNearRel16_32(self) except -1
    cdef int callPtr16_32(self) except -1
    cdef int pushaWD(self) except -1
    cdef int popaWD(self) except -1
    cdef int pushfWD(self) except -1
    cdef int popfWD(self) except -1
    cdef int stackPopSegment(self, Segment segment) except -1
    cdef int stackPopRegId(self, unsigned short regId, unsigned char regSize) except -1
    cdef unsigned int stackPopValue(self, unsigned char increaseStackAddr)
    cdef int stackPushValue(self, unsigned int value, unsigned char operSize, unsigned char segmentSource) except -1
    cdef int stackPushSegment(self, Segment segment, unsigned char operSize) except -1
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
    cdef int interrupt(self, signed short intNum=?, signed int errorCode=?) except -1 # TODO: complete this!
    cdef int into(self) except -1
    cdef int iret(self) except -1
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
    cdef int xchgFuncRegWord(self, unsigned short regName, unsigned short regName2) except -1
    cdef int xchgFuncRegDword(self, unsigned short regName, unsigned short regName2) except -1
    cdef int xchgReg(self) except -1
    cdef int xchgR_RM(self, unsigned char operSize) except -1
    cdef int enter(self) except -1
    cdef int leave(self) except -1
    cdef int setWithCondFunc(self, unsigned char cond) except -1 # if cond==True set 1, else 0
    cdef int arpl(self) except -1
    cdef int bound(self) except -1
    cdef int btFunc(self, unsigned int offset, unsigned char newValType) except -1
    cdef int fpuOpcodes(self, unsigned char opcode) except -1
    cdef void run(self)
    # end of opcodes



