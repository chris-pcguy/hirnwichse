
include "globals.pxi"
include "cpu_globals.pxi"

from hirnwichse_main cimport Hirnwichse
from misc cimport Misc
from segments cimport GdtEntry, IdtEntry, Gdt, Idt, Paging, Segment, Segments
from registers cimport ModRMClass, Registers
from cpu cimport Cpu
from mm cimport Mm
from pic cimport Pic


cdef class Opcodes:
    cdef Hirnwichse main
    cdef Cpu cpu
    cdef Registers registers
    cdef ModRMClass modRMInstance
    cdef inline int executeOpcode(self, unsigned char opcode) except BITMASK_BYTE_CONST
    cdef int cli(self) nogil except BITMASK_BYTE_CONST
    cdef int sti(self) nogil except BITMASK_BYTE_CONST
    cdef inline int hlt(self) nogil except BITMASK_BYTE_CONST
    cdef inline void cld(self) nogil
    cdef inline void std(self) nogil
    cdef inline void clc(self) nogil
    cdef inline void stc(self) nogil
    cdef inline void cmc(self) nogil
    cdef inline void clac(self) nogil
    cdef inline void stac(self) nogil
    cdef int checkIOPL(self, unsigned short ioPortAddr, unsigned char dataSize) nogil except BITMASK_BYTE_CONST
    cdef long int inPort(self, unsigned short ioPortAddr, unsigned char dataSize) except? BITMASK_BYTE_CONST
    cdef int outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize) except BITMASK_BYTE_CONST
    cdef int jumpFarDirect(self, unsigned char method, unsigned short segVal, unsigned int eipVal) except BITMASK_BYTE_CONST
    cdef inline int jumpFarAbsolutePtr(self) nogil except BITMASK_BYTE_CONST
    cdef inline int loopFunc(self, unsigned char loopType) nogil except BITMASK_BYTE_CONST
    cdef int opcodeR_RM(self, unsigned char opcode, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef int opcodeRM_R(self, unsigned char opcode, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef int opcodeAxEaxImm(self, unsigned char opcode, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int movImmToR(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int movRM_R(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef inline int movR_RM(self, unsigned char operSize, unsigned char cond) except BITMASK_BYTE_CONST
    cdef inline int movRM16_SREG(self) except BITMASK_BYTE_CONST
    cdef inline int movSREG_RM16(self) except BITMASK_BYTE_CONST
    cdef inline int movAxMoffs(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int movMoffsAx(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef int stosFuncWord(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef int stosFuncDword(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int stosFunc(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef int movsFuncWord(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef int movsFuncDword(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int movsFunc(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef int lodsFuncWord(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef int lodsFuncDword(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int lodsFunc(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef int cmpsFuncWord(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef int cmpsFuncDword(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int cmpsFunc(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef int scasFuncWord(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef int scasFuncDword(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int scasFunc(self, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef int inAxImm8(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef int inAxDx(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef int outImm8Ax(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef int outDxAx(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef int outsFuncWord(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef int outsFuncDword(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef inline int outsFunc(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef int insFuncWord(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef int insFuncDword(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef inline int insFunc(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef inline int jcxzShort(self) nogil except BITMASK_BYTE_CONST
    cdef inline int jumpShort(self, unsigned char offsetSize, unsigned char cond) nogil except BITMASK_BYTE_CONST
    cdef inline int callNearRel16_32(self) except BITMASK_BYTE_CONST
    cdef inline int callPtr16_32(self) except BITMASK_BYTE_CONST
    cdef int pushaWD(self) nogil except BITMASK_BYTE_CONST
    cdef int popaWD(self) nogil except BITMASK_BYTE_CONST
    cdef int pushfWD(self) nogil except BITMASK_BYTE_CONST
    cdef int popfWD(self) nogil except BITMASK_BYTE_CONST
    cdef inline int stackPopSegment(self, Segment segment) nogil except BITMASK_BYTE_CONST
    cdef inline int stackPopRegId(self, unsigned short regId, unsigned char regSize) nogil except BITMASK_BYTE_CONST
    cdef unsigned int stackPopValue(self, unsigned char increaseStackAddr) nogil except? BITMASK_BYTE_CONST
    cdef int stackPushValue(self, unsigned int value, unsigned char operSize, unsigned char onlyWord) nogil except BITMASK_BYTE_CONST
    cdef inline int stackPushSegment(self, Segment segment, unsigned char operSize, unsigned char onlyWord) nogil except BITMASK_BYTE_CONST
    cdef int stackPushRegId(self, unsigned short regId, unsigned char operSize) nogil except BITMASK_BYTE_CONST
    cdef int pushIMM(self, unsigned char immIsByte) except BITMASK_BYTE_CONST
    cdef int imulR_RM_ImmFunc(self, unsigned char immIsByte) except BITMASK_BYTE_CONST
    cdef int opcodeGroup1_RM_ImmFunc(self, unsigned char operSize, unsigned char immIsByte) except BITMASK_BYTE_CONST
    cdef int opcodeGroup3_RM_ImmFunc(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef int opcodeGroup0F(self) except BITMASK_BYTE_CONST
    cdef int opcodeGroupFE(self) except BITMASK_BYTE_CONST
    cdef int opcodeGroupFF(self) except BITMASK_BYTE_CONST
    cdef int incFuncReg(self, unsigned short regId, unsigned char regSize) except BITMASK_BYTE_CONST
    cdef int decFuncReg(self, unsigned short regId, unsigned char regSize) except BITMASK_BYTE_CONST
    cdef int incFuncRM(self, unsigned char rmSize) except BITMASK_BYTE_CONST
    cdef int decFuncRM(self, unsigned char rmSize) except BITMASK_BYTE_CONST
    cdef int incReg(self) except BITMASK_BYTE_CONST
    cdef int decReg(self) except BITMASK_BYTE_CONST
    cdef int pushReg(self) except BITMASK_BYTE_CONST
    cdef int pushSeg(self, unsigned char opcode) except BITMASK_BYTE_CONST
    cdef int popReg(self) except BITMASK_BYTE_CONST
    cdef int popSeg(self, unsigned char opcode) except BITMASK_BYTE_CONST
    cdef int popRM16_32(self) except BITMASK_BYTE_CONST
    cdef int lea(self) except BITMASK_BYTE_CONST
    cdef int retNear(self, unsigned short imm) except BITMASK_BYTE_CONST
    cdef int retNearImm(self) except BITMASK_BYTE_CONST
    cdef int retFar(self, unsigned short imm) except BITMASK_BYTE_CONST
    cdef int retFarImm(self) except BITMASK_BYTE_CONST
    cdef int lfpFunc(self, unsigned short segId) except BITMASK_BYTE_CONST # 'load far pointer' function
    cdef int xlatb(self) except BITMASK_BYTE_CONST
    cdef int opcodeGroup2_RM(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef int interrupt(self, signed short intNum=?, signed int errorCode=?) except BITMASK_BYTE_CONST # TODO: complete this!
    cdef int into(self) except BITMASK_BYTE_CONST
    cdef int iret(self) except BITMASK_BYTE_CONST
    cdef int aad(self) except BITMASK_BYTE_CONST
    cdef int aam(self) except BITMASK_BYTE_CONST
    cdef int aaa(self) except BITMASK_BYTE_CONST
    cdef int aas(self) except BITMASK_BYTE_CONST
    cdef int daa(self) except BITMASK_BYTE_CONST
    cdef int das(self) except BITMASK_BYTE_CONST
    cdef int cbw_cwde(self) except BITMASK_BYTE_CONST
    cdef int cwd_cdq(self) except BITMASK_BYTE_CONST
    cdef int shlFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE_CONST
    cdef int sarFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE_CONST
    cdef int shrFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE_CONST
    cdef int rclFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE_CONST
    cdef int rcrFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE_CONST
    cdef int rolFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE_CONST
    cdef int rorFunc(self, unsigned char operSize, unsigned char count) except BITMASK_BYTE_CONST
    cdef int opcodeGroup4_RM(self, unsigned char operSize, unsigned char method) except BITMASK_BYTE_CONST
    cdef int sahf(self) except BITMASK_BYTE_CONST
    cdef int lahf(self) except BITMASK_BYTE_CONST
    cdef int xchgFuncRegWord(self, unsigned short regName, unsigned short regName2) except BITMASK_BYTE_CONST
    cdef int xchgFuncRegDword(self, unsigned short regName, unsigned short regName2) except BITMASK_BYTE_CONST
    cdef int xchgReg(self) except BITMASK_BYTE_CONST
    cdef int xchgR_RM(self, unsigned char operSize) except BITMASK_BYTE_CONST
    cdef int enter(self) except BITMASK_BYTE_CONST
    cdef int leave(self) except BITMASK_BYTE_CONST
    cdef int setWithCondFunc(self, unsigned char cond) except BITMASK_BYTE_CONST # if cond==True set 1, else 0
    cdef int arpl(self) except BITMASK_BYTE_CONST
    cdef int bound(self) except BITMASK_BYTE_CONST
    cdef int btFunc(self, unsigned char newValType) except BITMASK_BYTE_CONST
    cdef int fwait(self) except BITMASK_BYTE_CONST
    cdef int fpuFcomHelper(self, object data, unsigned char popRegs) except BITMASK_BYTE_CONST
    cdef int fpuOpcodes(self, unsigned char opcode) except BITMASK_BYTE_CONST
    cdef void run(self)
    # end of opcodes



