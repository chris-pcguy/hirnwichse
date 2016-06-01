
include "globals.pxi"
include "cpu_globals.pxi"

from libc.stdint cimport *

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
    cdef inline int executeOpcode(self, uint8_t opcode) except BITMASK_BYTE_CONST
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
    cdef int checkIOPL(self, uint16_t ioPortAddr, uint8_t dataSize) nogil except BITMASK_BYTE_CONST
    cdef long int inPort(self, uint16_t ioPortAddr, uint8_t dataSize) except? BITMASK_BYTE_CONST
    cdef int outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) except BITMASK_BYTE_CONST
    cdef int jumpFarDirect(self, uint8_t method, uint16_t segVal, uint32_t eipVal) nogil except BITMASK_BYTE_CONST
    cdef inline int jumpFarAbsolutePtr(self) nogil except BITMASK_BYTE_CONST
    cdef inline int loopFunc(self, uint8_t loopType) nogil except BITMASK_BYTE_CONST
    cdef int opcodeR_RM(self, uint8_t opcode, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int opcodeRM_R(self, uint8_t opcode, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int opcodeAxEaxImm(self, uint8_t opcode, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int movImmToR(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int movRM_R(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int movR_RM(self, uint8_t operSize, uint8_t cond) nogil except BITMASK_BYTE_CONST
    cdef inline int movRM16_SREG(self) nogil except BITMASK_BYTE_CONST
    cdef inline int movSREG_RM16(self) nogil except BITMASK_BYTE_CONST
    cdef inline int movAxMoffs(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int movMoffsAx(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int stosFuncWord(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int stosFuncDword(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int stosFunc(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int movsFuncWord(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int movsFuncDword(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int movsFunc(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int lodsFuncWord(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int lodsFuncDword(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int lodsFunc(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int cmpsFuncWord(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int cmpsFuncDword(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int cmpsFunc(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int scasFuncWord(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int scasFuncDword(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef inline int scasFunc(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int inAxImm8(self, uint8_t operSize) except BITMASK_BYTE_CONST
    cdef int inAxDx(self, uint8_t operSize) except BITMASK_BYTE_CONST
    cdef int outImm8Ax(self, uint8_t operSize) except BITMASK_BYTE_CONST
    cdef int outDxAx(self, uint8_t operSize) except BITMASK_BYTE_CONST
    cdef int outsFuncWord(self, uint8_t operSize) except BITMASK_BYTE_CONST
    cdef int outsFuncDword(self, uint8_t operSize) except BITMASK_BYTE_CONST
    cdef inline int outsFunc(self, uint8_t operSize) except BITMASK_BYTE_CONST
    cdef int insFuncWord(self, uint8_t operSize) except BITMASK_BYTE_CONST
    cdef int insFuncDword(self, uint8_t operSize) except BITMASK_BYTE_CONST
    cdef inline int insFunc(self, uint8_t operSize) except BITMASK_BYTE_CONST
    cdef inline int jcxzShort(self) nogil except BITMASK_BYTE_CONST
    cdef inline int jumpShort(self, uint8_t offsetSize, uint8_t cond) nogil except BITMASK_BYTE_CONST
    cdef inline int callNearRel16_32(self) nogil except BITMASK_BYTE_CONST
    cdef inline int callPtr16_32(self) nogil except BITMASK_BYTE_CONST
    cdef int pushaWD(self) nogil except BITMASK_BYTE_CONST
    cdef int popaWD(self) nogil except BITMASK_BYTE_CONST
    cdef int pushfWD(self) nogil except BITMASK_BYTE_CONST
    cdef int popfWD(self) nogil except BITMASK_BYTE_CONST
    cdef inline int stackPopSegment(self, Segment *segment) nogil except BITMASK_BYTE_CONST
    cdef inline int stackPopRegId(self, uint16_t regId, uint8_t regSize) nogil except BITMASK_BYTE_CONST
    cdef uint32_t stackPopValue(self, uint8_t increaseStackAddr) nogil except? BITMASK_BYTE_CONST
    cdef int stackPushValue(self, uint32_t value, uint8_t operSize, uint8_t onlyWord) nogil except BITMASK_BYTE_CONST
    cdef inline int stackPushSegment(self, Segment *segment, uint8_t operSize, uint8_t onlyWord) nogil except BITMASK_BYTE_CONST
    cdef int stackPushRegId(self, uint16_t regId, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int pushIMM(self, uint8_t immIsByte) nogil except BITMASK_BYTE_CONST
    cdef int imulR_RM_ImmFunc(self, uint8_t immIsByte) nogil except BITMASK_BYTE_CONST
    cdef int opcodeGroup1_RM_ImmFunc(self, uint8_t operSize, uint8_t immIsByte) nogil except BITMASK_BYTE_CONST
    cdef int opcodeGroup3_RM_ImmFunc(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int opcodeGroup0F(self) nogil except BITMASK_BYTE_CONST
    cdef int opcodeGroupFE(self) nogil except BITMASK_BYTE_CONST
    cdef int opcodeGroupFF(self) nogil except BITMASK_BYTE_CONST
    cdef int incFuncReg(self, uint16_t regId, uint8_t regSize) nogil except BITMASK_BYTE_CONST
    cdef int decFuncReg(self, uint16_t regId, uint8_t regSize) nogil except BITMASK_BYTE_CONST
    cdef int incFuncRM(self, uint8_t rmSize) nogil except BITMASK_BYTE_CONST
    cdef int decFuncRM(self, uint8_t rmSize) nogil except BITMASK_BYTE_CONST
    cdef int incReg(self) nogil except BITMASK_BYTE_CONST
    cdef int decReg(self) nogil except BITMASK_BYTE_CONST
    cdef int pushReg(self) nogil except BITMASK_BYTE_CONST
    cdef int popReg(self) nogil except BITMASK_BYTE_CONST
    cdef int pushSeg(self, uint8_t opcode) nogil except BITMASK_BYTE_CONST
    cdef int popSeg(self, uint8_t opcode) nogil except BITMASK_BYTE_CONST
    cdef int popRM16_32(self) nogil except BITMASK_BYTE_CONST
    cdef int lea(self) nogil except BITMASK_BYTE_CONST
    cdef int retNear(self, int16_t imm) nogil except BITMASK_BYTE_CONST
    cdef int retNearImm(self) nogil except BITMASK_BYTE_CONST
    cdef int retFar(self, uint16_t imm) nogil except BITMASK_BYTE_CONST
    cdef int retFarImm(self) nogil except BITMASK_BYTE_CONST
    cdef int lfpFunc(self, uint16_t segId) nogil except BITMASK_BYTE_CONST # 'load far pointer' function
    cdef int xlatb(self) nogil except BITMASK_BYTE_CONST
    cdef int opcodeGroup2_RM(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int interrupt(self, int16_t intNum=?, int32_t errorCode=?) except BITMASK_BYTE_CONST # TODO: complete this!
    cdef int into(self) nogil except BITMASK_BYTE_CONST
    cdef int iret(self) nogil except BITMASK_BYTE_CONST
    cdef int aad(self) nogil except BITMASK_BYTE_CONST
    cdef int aam(self) nogil except BITMASK_BYTE_CONST
    cdef int aaa(self) nogil except BITMASK_BYTE_CONST
    cdef int aas(self) nogil except BITMASK_BYTE_CONST
    cdef int daa(self) nogil except BITMASK_BYTE_CONST
    cdef int das(self) nogil except BITMASK_BYTE_CONST
    cdef int cbw_cwde(self) nogil except BITMASK_BYTE_CONST
    cdef int cwd_cdq(self) nogil except BITMASK_BYTE_CONST
    cdef int shlFunc(self, uint8_t operSize, uint8_t count) nogil except BITMASK_BYTE_CONST
    cdef int sarFunc(self, uint8_t operSize, uint8_t count) nogil except BITMASK_BYTE_CONST
    cdef int shrFunc(self, uint8_t operSize, uint8_t count) nogil except BITMASK_BYTE_CONST
    cdef int rclFunc(self, uint8_t operSize, uint8_t count) nogil except BITMASK_BYTE_CONST
    cdef int rcrFunc(self, uint8_t operSize, uint8_t count) nogil except BITMASK_BYTE_CONST
    cdef int rolFunc(self, uint8_t operSize, uint8_t count) nogil except BITMASK_BYTE_CONST
    cdef int rorFunc(self, uint8_t operSize, uint8_t count) nogil except BITMASK_BYTE_CONST
    cdef int opcodeGroup4_RM(self, uint8_t operSize, uint8_t method) nogil except BITMASK_BYTE_CONST
    cdef int sahf(self) nogil except BITMASK_BYTE_CONST
    cdef int lahf(self) nogil except BITMASK_BYTE_CONST
    cdef int xchgFuncRegWord(self, uint16_t regName, uint16_t regName2) nogil except BITMASK_BYTE_CONST
    cdef int xchgFuncRegDword(self, uint16_t regName, uint16_t regName2) nogil except BITMASK_BYTE_CONST
    cdef int xchgReg(self) nogil except BITMASK_BYTE_CONST
    cdef int xchgR_RM(self, uint8_t operSize) nogil except BITMASK_BYTE_CONST
    cdef int enter(self) nogil except BITMASK_BYTE_CONST
    cdef int leave(self) nogil except BITMASK_BYTE_CONST
    cdef int setWithCondFunc(self, uint8_t cond) nogil except BITMASK_BYTE_CONST # if cond==True set 1, else 0
    cdef int arpl(self) nogil except BITMASK_BYTE_CONST
    cdef int bound(self) nogil except BITMASK_BYTE_CONST
    cdef int btFunc(self, uint8_t newValType) nogil except BITMASK_BYTE_CONST
    cdef int fwait(self) except BITMASK_BYTE_CONST
    cdef int fpuFcomHelper(self, object data, uint8_t popRegs, uint8_t regFlags) except BITMASK_BYTE_CONST
    cdef int fpuOpcodes(self, uint8_t opcode) except BITMASK_BYTE_CONST
    cdef void run(self)
    # end of opcodes



