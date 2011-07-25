#import struct

#BYTE_ORDER_LITTLE_ENDIAN = 10
#DATA_ORDER_BIG_ENDIAN = 11

OP_SIZE_8BIT  = 1
OP_SIZE_16BIT = 2
OP_SIZE_32BIT = 4
OP_SIZE_64BIT = 8


SET_FLAGS_ADD = 50
SET_FLAGS_SUB = 51
SET_FLAGS_MUL = 52
SET_FLAGS_DIV = 53


CPU_EXCEPTION_DE = 0 # divide-by-zero error
CPU_EXCEPTION_DB = 1 # debug
CPU_EXCEPTION_BP = 3 # breakpoint
CPU_EXCEPTION_OF = 4 # overflow
CPU_EXCEPTION_BR = 5 # bound range exceeded
CPU_EXCEPTION_UD = 6 # invalid opcode
CPU_EXCEPTION_NM = 7 # device not available
CPU_EXCEPTION_DF = 8 # double fault
CPU_EXCEPTION_TS = 10 # invalid TSS
CPU_EXCEPTION_NP = 11 # segment not present
CPU_EXCEPTION_SS = 12 # stack-segment fault
CPU_EXCEPTION_GP = 13 # general-protection fault
CPU_EXCEPTION_PF = 14 # page fault
CPU_EXCEPTION_MF = 16 # x87 floating-point exception
CPU_EXCEPTION_AC = 17 # alignment check
CPU_EXCEPTION_MC = 18 # machine check
CPU_EXCEPTION_XM = 19 # simd floating-point exception
CPU_EXCEPTION_SX = 30 # security exception



OPCODE_PREFIX_CS=0x2e
OPCODE_PREFIX_SS=0x36
OPCODE_PREFIX_DS=0x3e
OPCODE_PREFIX_ES=0x26
OPCODE_PREFIX_FS=0x64
OPCODE_PREFIX_GS=0x65
OPCODE_PREFIX_SEGMENTS=(OPCODE_PREFIX_CS, OPCODE_PREFIX_SS, OPCODE_PREFIX_DS, OPCODE_PREFIX_ES, OPCODE_PREFIX_FS, OPCODE_PREFIX_GS)
OPCODE_PREFIX_OP=0x66
OPCODE_PREFIX_ADDR=0x67
OPCODE_PREFIX_BRANCH_NOT_TAKEN=0x2e
OPCODE_PREFIX_BRANCH_TAKEN=0x3e
OPCODE_PREFIX_BRANCHES=(OPCODE_PREFIX_BRANCH_NOT_TAKEN,OPCODE_PREFIX_BRANCH_TAKEN)
OPCODE_PREFIX_LOCK=0xf0
OPCODE_PREFIX_REPNE=0xf2
OPCODE_PREFIX_REPE=0xf3
OPCODE_PREFIX_REPS=(OPCODE_PREFIX_REPNE,OPCODE_PREFIX_REPE)


OPCODE_PREFIXES=(OPCODE_PREFIX_LOCK, OPCODE_PREFIX_OP, OPCODE_PREFIX_ADDR, OPCODE_PREFIX_CS,
                 OPCODE_PREFIX_SS, OPCODE_PREFIX_DS, OPCODE_PREFIX_ES, OPCODE_PREFIX_FS,
                 OPCODE_PREFIX_GS, OPCODE_PREFIX_BRANCH_NOT_TAKEN, OPCODE_PREFIX_BRANCH_TAKEN,
                 OPCODE_PREFIX_REPNE, OPCODE_PREFIX_REPE)


BYTE_ORDER_LITTLE_ENDIAN = 'little'
BYTE_ORDER_BIG_ENDIAN = 'big'


cdef class Misc:
    #cdef object main
    def __init__(self, main):
        self.main = main
    cpdef long getBitMask(self, int bits, int half=False, int minus=1):
        if (bits == OP_SIZE_8BIT):
            if (half):
                return ((1<<8)//2)-minus
            else:
                return (1<<8)-minus
        elif (bits == OP_SIZE_16BIT):
            if (half):
                return ((1<<16)//2)-minus
            else:
                return (1<<16)-minus
        elif (bits == OP_SIZE_32BIT):
            if (half):
                return ((1<<32)//2)-minus
            else:
                return (1<<32)-minus
        elif (bits == OP_SIZE_64BIT):
            if (half):
                return ((1<<64)//2)-minus
            else:
                return (1<<64)-minus
        else:
            self.main.exitError("Misc::getBitMask: bits not in (OP_SIZE_8BIT, OP_SIZE_16BIT, OP_SIZE_32BIT, OP_SIZE_64BIT)")



