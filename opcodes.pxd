
from misc cimport Misc
from segments cimport Segments, Gdt, Idt, IdtEntry, GdtEntry
from registers cimport Registers, ModRMClass
from mm cimport Mm

include "cpu_globals.pxi"


cdef class Opcodes:
    cpdef object main
    cdef Registers registers
    cdef ModRMClass modRMInstance
    cdef unsigned char executeOpcode(self, unsigned char opcode)
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
        if ((<Segments>self.registers.segments).protectedModeOn):
            (<Gdt>self.registers.segments.gdt).loadTableData()
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef jumpFarAbsolutePtr(self)
    cdef loopFunc(self, unsigned char loopType)
    cdef opcodeR_RM(self, unsigned char opcode, unsigned char operSize)
    cdef opcodeRM_R(self, unsigned char opcode, unsigned char operSize)
    cdef opcodeAxEaxImm(self, unsigned char opcode, unsigned char operSize)
    cdef movImmToR(self, unsigned char operSize)
    cdef movRM_R(self, unsigned char operSize)
    cdef movR_RM(self, unsigned char operSize, unsigned char cond)
    cdef movRM16_SREG(self)
    cdef movSREG_RM16(self)
    cdef movAxMoffs(self, unsigned char operSize)
    cdef movMoffsAx(self, unsigned char operSize)
    cdef stosFunc(self, unsigned char operSize)
    cdef movsFunc(self, unsigned char operSize)
    cdef lodsFunc(self, unsigned char operSize)
    cdef cmpsFunc(self, unsigned char operSize)
    cdef scasFunc(self, unsigned char operSize)
    cdef inAxImm8(self, unsigned char operSize)
    cdef inAxDx(self, unsigned char operSize)
    cdef outImm8Ax(self, unsigned char operSize)
    cdef outDxAx(self, unsigned char operSize)
    cdef outsFunc(self, unsigned char operSize)
    cdef insFunc(self, unsigned char operSize)
    cdef jcxzShort(self)
    cdef jumpShort(self, unsigned char offsetSize, unsigned char cond)
    cdef callNearRel16_32(self)
    cdef callPtr16_32(self)
    cdef pushaWD(self)
    cdef popaWD(self)
    cdef pushfWD(self)
    cdef popfWD(self)
    cdef stackPopSegId(self, unsigned short segId)
    cdef stackPopRegId(self, unsigned short regId)
    cdef unsigned long stackGetValue(self)
    cdef unsigned long stackPopValue(self)
    cdef stackPushSegId(self, unsigned short segId, unsigned char operSize)
    cdef stackPushRegId(self, unsigned short regId, unsigned char operSize)
    cdef stackPushValue(self, unsigned long value, unsigned char operSize)
    cdef pushIMM(self, unsigned char immIsByte)
    cdef imulR_RM_ImmFunc(self, unsigned char immIsByte)
    cdef opcodeGroup1_RM_ImmFunc(self, unsigned char operSize, unsigned char immIsByte)
    cdef opcodeGroup3_RM_ImmFunc(self, unsigned char operSize)
    cdef opcodeGroup0F(self)
    cdef opcodeGroupFE(self)
    cdef opcodeGroupFF(self)
    cdef incFuncReg(self, unsigned short regId, unsigned char regSize)
    cdef decFuncReg(self, unsigned short regId, unsigned char regSize)
    cdef incFuncRM(self, unsigned char rmSize)
    cdef decFuncRM(self, unsigned char rmSize)
    cdef incReg(self)
    cdef decReg(self)
    cdef pushReg(self)
    cdef pushSeg(self, unsigned char opcode)
    cdef popReg(self)
    cdef popSeg(self, unsigned char opcode)
    cdef popRM16_32(self)
    cdef lea(self)
    cdef retNear(self, unsigned short imm)
    cdef retNearImm(self)
    cdef retFar(self, unsigned short imm)
    cdef retFarImm(self)
    cdef lfpFunc(self, unsigned short segId) # 'load far pointer' function
    cdef xlatb(self)
    cdef opcodeGroup2_RM(self, unsigned char operSize)
    cdef interrupt(self, short intNum, long errorCode) # TODO: complete this!
    cdef into(self)
    cdef int3(self)
    cdef iret(self)
    cdef aad(self)
    cdef aam(self)
    cdef aaa(self)
    cdef aas(self)
    cdef daa(self)
    cdef das(self)
    cdef cbw_cwde(self)
    cdef cwd_cdq(self)
    cdef shlFunc(self, unsigned char operSize, unsigned char count)
    cdef sarFunc(self, unsigned char operSize, unsigned char count)
    cdef shrFunc(self, unsigned char operSize, unsigned char count)
    cdef rclFunc(self, unsigned char operSize, unsigned char count)
    cdef rcrFunc(self, unsigned char operSize, unsigned char count)
    cdef rolFunc(self, unsigned char operSize, unsigned char count)
    cdef rorFunc(self, unsigned char operSize, unsigned char count)
    cdef opcodeGroup4_RM(self, unsigned char operSize, unsigned char method)
    cdef sahf(self)
    cdef lahf(self)
    cdef xchgFuncReg(self, unsigned short regName, unsigned short regName2)
    cdef xchgReg(self)
    cdef xchgR_RM(self, unsigned char operSize)
    cdef enter(self)
    cdef leave(self)
    cdef cmovFunc(self, unsigned char cond) # R16, R/M 16; R32, R/M 32
    cdef setWithCondFunc(self, unsigned char cond) # if cond==True set 1, else 0
    cdef arpl(self)
    cdef bound(self)
    cdef btFunc(self, unsigned long offset, unsigned char newValType)
    cdef run(self)
    # end of opcodes



