
include "globals.pxi"
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
    cdef int executeOpcode(self, unsigned char opcode) except BITMASK_BYTE
    cdef int cli(self) except BITMASK_BYTE
    cdef int sti(self) except BITMASK_BYTE
    cdef int hlt(self) except BITMASK_BYTE
    cdef void cld(self)
    cdef void std(self)
    cdef void clc(self)
    cdef void stc(self)
    cdef void cmc(self)
    cdef inline unsigned int quirkCR0(self, unsigned int value):
        #value |= (CR0_FLAG_EM | CR0_FLAG_ET | CR0_FLAG_NE | CR0_FLAG_NW | CR0_FLAG_CD)
        #value |= (CR0_FLAG_EM | CR0_FLAG_NE)
        #value &= ~(CR0_FLAG_ET | CR0_FLAG_MP | CR0_FLAG_TS)
        #value |= (CR0_FLAG_EM | CR0_FLAG_NE)
        return value
    cdef int checkIOPL(self, unsigned short ioPortAddr, unsigned char dataSize) except BITMASK_BYTE
    cdef long int inPort(self, unsigned short ioPortAddr, unsigned char dataSize) except? BITMASK_BYTE
    cdef int outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize) except BITMASK_BYTE
    cdef int jumpFarDirect(self, unsigned char method, unsigned short segVal, unsigned int eipVal) except BITMASK_BYTE
    cdef int jumpFarAbsolutePtr(self) except BITMASK_BYTE
    cdef int loopFunc(self, unsigned char loopType) except BITMASK_BYTE
    cdef int opcodeR_RM(self, unsigned char opcode, unsigned char operSize) except BITMASK_BYTE
    cdef int opcodeRM_R(self, unsigned char opcode, unsigned char operSize) except BITMASK_BYTE
    cdef int opcodeAxEaxImm(self, unsigned char opcode, unsigned char operSize) except BITMASK_BYTE
    cdef int movImmToR(self, unsigned char operSize) except BITMASK_BYTE
    cdef int movRM_R(self, unsigned char operSize) except BITMASK_BYTE
    cdef int movR_RM(self, unsigned char operSize, unsigned char cond) except BITMASK_BYTE
    cdef int movRM16_SREG(self) except BITMASK_BYTE
    cdef int movSREG_RM16(self) except BITMASK_BYTE
    cdef int movAxMoffs(self, unsigned char operSize) except BITMASK_BYTE
    cdef int movMoffsAx(self, unsigned char operSize) except BITMASK_BYTE
    cdef int stosFuncWord(self, unsigned char operSize) except BITMASK_BYTE
    cdef int stosFuncDword(self, unsigned char operSize) except BITMASK_BYTE
    cdef int stosFunc(self, unsigned char operSize) except BITMASK_BYTE
    cdef int movsFuncWord(self, unsigned char operSize) except BITMASK_BYTE
    cdef int movsFuncDword(self, unsigned char operSize) except BITMASK_BYTE
    cdef int movsFunc(self, unsigned char operSize) except BITMASK_BYTE
    cdef int lodsFuncWord(self, unsigned char operSize) except BITMASK_BYTE
    cdef int lodsFuncDword(self, unsigned char operSize) except BITMASK_BYTE
    cdef int lodsFunc(self, unsigned char operSize) except BITMASK_BYTE
    cdef int cmpsFuncWord(self, unsigned char operSize) except BITMASK_BYTE
    cdef int cmpsFuncDword(self, unsigned char operSize) except BITMASK_BYTE
    cdef int cmpsFunc(self, unsigned char operSize) except BITMASK_BYTE
    cdef int scasFuncWord(self, unsigned char operSize) except BITMASK_BYTE
    cdef int scasFuncDword(self, unsigned char operSize) except BITMASK_BYTE
    cdef int scasFunc(self, unsigned char operSize) except BITMASK_BYTE
    cdef int inAxImm8(self, unsigned char operSize) except BITMASK_BYTE
    cdef int inAxDx(self, unsigned char operSize) except BITMASK_BYTE
    cdef int outImm8Ax(self, unsigned char operSize) except BITMASK_BYTE
    cdef int outDxAx(self, unsigned char operSize) except BITMASK_BYTE
    cdef int outsFuncWord(self, unsigned char operSize) except BITMASK_BYTE
    cdef int outsFuncDword(self, unsigned char operSize) except BITMASK_BYTE
    cdef int outsFunc(self, unsigned char operSize) except BITMASK_BYTE
    cdef int insFuncWord(self, unsigned char operSize) except BITMASK_BYTE
    cdef int insFuncDword(self, unsigned char operSize) except BITMASK_BYTE
    cdef int insFunc(self, unsigned char operSize) except BITMASK_BYTE
    cdef int jcxzShort(self) except BITMASK_BYTE
    cdef int jumpShort(self, unsigned char offsetSize, unsigned char cond) except BITMASK_BYTE
    cdef int callNearRel16_32(self) except BITMASK_BYTE
    cdef int callPtr16_32(self) except BITMASK_BYTE
    cdef int pushaWD(self) except BITMASK_BYTE
    cdef int popaWD(self) except BITMASK_BYTE
    cdef int pushfWD(self) except BITMASK_BYTE
    cdef int popfWD(self) except BITMASK_BYTE
    cdef int stackPopSegment(self, Segment segment) except BITMASK_BYTE
    cdef int stackPopRegId(self, unsigned short regId, unsigned char regSize) except BITMASK_BYTE
    cdef unsigned int stackPopValue(self, unsigned char increaseStackAddr)
    cdef int stackPushValue(self, unsigned int value, unsigned char operSize, unsigned char segmentSource) except BITMASK_BYTE
    cdef int stackPushSegment(self, Segment segment, unsigned char operSize) except BITMASK_BYTE
    cdef int stackPushRegId(self, unsigned short regId, unsigned char operSize) except BITMASK_BYTE
    cdef int pushIMM(self, unsigned char immIsByte) except BITMASK_BYTE
    cdef int imulR_RM_ImmFunc(self, unsigned char immIsByte) except BITMASK_BYTE
    cdef int opcodeGroup1_RM_ImmFunc(self, unsigned char operSize, unsigned char immIsByte) except BITMASK_BYTE
    cdef int opcodeGroup3_RM_ImmFunc(self, unsigned char operSize) except BITMASK_BYTE
    cdef int opcodeGroup0F(self) except BITMASK_BYTE
    cdef int opcodeGroupFE(self) except BITMASK_BYTE
    cdef int opcodeGroupFF(self) except BITMASK_BYTE
    cdef int incFuncReg(self, unsigned short regId, unsigned char regSize) except BITMASK_BYTE
    cdef int decFuncReg(self, unsigned short regId, unsigned char regSize) except BITMASK_BYTE
    cdef int incFuncRM(self, unsigned char rmSize) except BITMASK_BYTE
    cdef int decFuncRM(self, unsigned char rmSize) except BITMASK_BYTE
    cdef int incReg(self) except BITMASK_BYTE
    cdef int decReg(self) except BITMASK_BYTE
    cdef int pushReg(self) except BITMASK_BYTE
    cdef int pushSeg(self, unsigned char opcode) except BITMASK_BYTE
    cdef int popReg(self) except BITMASK_BYTE
    cdef int popSeg(self, unsigned char opcode) except BITMASK_BYTE
    cdef int popRM16_32(self) except BITMASK_BYTE
    cdef int lea(self) except BITMASK_BYTE
    cdef int retNear(self, unsigned short imm) except BITMASK_BYTE
    cdef int retNearImm(self) except BITMASK_BYTE
    cdef int retFar(self, unsigned short imm) except BITMASK_BYTE
    cdef int retFarImm(self) except BITMASK_BYTE
    cdef int lfpFunc(self, unsigned short segId) except BITMASK_BYTE # 'load far pointer' function
    cdef int xlatb(self) except BITMASK_BYTE
    cdef int opcodeGroup2_RM(self, unsigned char operSize) except BITMASK_BYTE
    cdef int interrupt(self, signed short intNum=?, signed int errorCode=?) except BITMASK_BYTE # TODO: complete this!
    cdef int into(self) except BITMASK_BYTE
    cdef int iret(self) except BITMASK_BYTE
    cdef int aad(self) except BITMASK_BYTE
    cdef int aam(self) except BITMASK_BYTE
    cdef int aaa(self) except BITMASK_BYTE
    cdef int aas(self) except BITMASK_BYTE
    cdef int daa(self) except BITMASK_BYTE
    cdef int das(self) except BITMASK_BYTE
    cdef int cbw_cwde(self) except BITMASK_BYTE
    cdef int cwd_cdq(self) except BITMASK_BYTE
    cdef int shlFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE
    cdef int sarFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE
    cdef int shrFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE
    cdef int rclFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE
    cdef int rcrFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE
    cdef int rolFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE
    cdef int rorFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE
    cdef int opcodeGroup4_RM(self, unsigned char operSize, unsigned char method) except BITMASK_BYTE
    cdef int sahf(self) except BITMASK_BYTE
    cdef int lahf(self) except BITMASK_BYTE
    cdef int xchgFuncRegWord(self, unsigned short regName, unsigned short regName2) except BITMASK_BYTE
    cdef int xchgFuncRegDword(self, unsigned short regName, unsigned short regName2) except BITMASK_BYTE
    cdef int xchgReg(self) except BITMASK_BYTE
    cdef int xchgR_RM(self, unsigned char operSize) except BITMASK_BYTE
    cdef int enter(self) except BITMASK_BYTE
    cdef int leave(self) except BITMASK_BYTE
    cdef int setWithCondFunc(self, unsigned char cond) except BITMASK_BYTE # if cond==True set 1, else 0
    cdef int arpl(self) except BITMASK_BYTE
    cdef int bound(self) except BITMASK_BYTE
    cdef int btFunc(self, unsigned int offset, unsigned char newValType) except BITMASK_BYTE
    cdef int fpuOpcodes(self, unsigned char opcode) except BITMASK_BYTE
    cdef void run(self)
    # end of opcodes



