
OP_SIZE_BYTE  = 1
OP_SIZE_WORD = 2
OP_SIZE_DWORD = 4
OP_SIZE_QWORD = 8


SET_FLAGS_ADD = 1
SET_FLAGS_SUB = 2
SET_FLAGS_MUL = 3
SET_FLAGS_DIV = 4


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
CPU_EXCEPTION_XF = 19 # simd floating-point exception
CPU_EXCEPTION_SX = 30 # security exception


CPU_EXCEPTIONS_FAULT_GROUP = (CPU_EXCEPTION_DE, CPU_EXCEPTION_BR, CPU_EXCEPTION_UD, CPU_EXCEPTION_NM, CPU_EXCEPTION_TS, \
                        CPU_EXCEPTION_NP, CPU_EXCEPTION_SS, CPU_EXCEPTION_GP, CPU_EXCEPTION_PF, CPU_EXCEPTION_MF, \
                        CPU_EXCEPTION_AC, CPU_EXCEPTION_XF)
CPU_EXCEPTIONS_WITH_ERRORCODE = (CPU_EXCEPTION_DF, CPU_EXCEPTION_TS, CPU_EXCEPTION_NP, CPU_EXCEPTION_SS, \
                                 CPU_EXCEPTION_GP, CPU_EXCEPTION_PF, CPU_EXCEPTION_AC)


OPCODE_PREFIX_CS=0x2e
OPCODE_PREFIX_SS=0x36
OPCODE_PREFIX_DS=0x3e
OPCODE_PREFIX_ES=0x26
OPCODE_PREFIX_FS=0x64
OPCODE_PREFIX_GS=0x65
OPCODE_PREFIX_SEGMENTS=(OPCODE_PREFIX_CS, OPCODE_PREFIX_SS, OPCODE_PREFIX_DS, OPCODE_PREFIX_ES, OPCODE_PREFIX_FS, OPCODE_PREFIX_GS)
OPCODE_PREFIX_OP=0x66
OPCODE_PREFIX_ADDR=0x67
#OPCODE_PREFIX_BRANCH_NOT_TAKEN=0x2e
#OPCODE_PREFIX_BRANCH_TAKEN=0x3e
#OPCODE_PREFIX_BRANCHES=(OPCODE_PREFIX_BRANCH_NOT_TAKEN,OPCODE_PREFIX_BRANCH_TAKEN)
OPCODE_PREFIX_LOCK=0xf0
OPCODE_PREFIX_REPNE=0xf2
OPCODE_PREFIX_REPE=0xf3
OPCODE_PREFIX_REPS=(OPCODE_PREFIX_REPNE,OPCODE_PREFIX_REPE)


OPCODE_PREFIXES=(OPCODE_PREFIX_LOCK, OPCODE_PREFIX_OP, OPCODE_PREFIX_ADDR, OPCODE_PREFIX_CS,
                 OPCODE_PREFIX_SS, OPCODE_PREFIX_DS, OPCODE_PREFIX_ES, OPCODE_PREFIX_FS,
                 OPCODE_PREFIX_GS, OPCODE_PREFIX_REPNE, OPCODE_PREFIX_REPE) 
                 #OPCODE_PREFIX_BRANCH_NOT_TAKEN, OPCODE_PREFIX_BRANCH_TAKEN

OPCODES_LOCK_PREFIX_INVALID = (0x07, 0x17, 0x1f, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d,
                               0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63, 0x69, 0x6b, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75,
                               0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 0x84, 0x85, 0x90, 0x9a, 0x9c,
                               0xa8, 0xa9, 0xc8, 0xc9, 0xcd, 0xe3, 0xe8, 0xe9, 0xea, 0xeb, 0xf9, 0xfb, 0xfd)


BYTE_ORDER_LITTLE_ENDIAN = 'little'
BYTE_ORDER_BIG_ENDIAN = 'big'


VALUEOP_SAVE = 0
VALUEOP_ADD  = 1
VALUEOP_ADC  = 2
VALUEOP_SUB  = 3
VALUEOP_SBB  = 4
VALUEOP_AND  = 5
VALUEOP_OR   = 6
VALUEOP_XOR  = 7
VALUEOPS = (VALUEOP_SAVE, VALUEOP_ADD, VALUEOP_ADC, VALUEOP_SUB, VALUEOP_SBB, VALUEOP_AND, VALUEOP_OR, VALUEOP_XOR)

GETADDR_OPCODE = 1
GETADDR_NEXT_OPCODE = 2
GETADDR_VALUES = (GETADDR_OPCODE, GETADDR_NEXT_OPCODE)

BT_NONE = 0
BT_NOT = 1
BT_SET = 2
BT_CLEAR = 3


class ChemuException(Exception):
    pass


cdef class Misc:
    cdef object main
    def __init__(self, object main):
        self.main = main
    def getBitMask(self, long size, int half=False, int minus=1):
        cdef unsigned long long returnValue
        if (size == OP_SIZE_BYTE):
            if (half):
                returnValue = 0x80-minus
            else:
                returnValue = 0x100-minus
        elif (size == OP_SIZE_WORD):
            if (half):
                returnValue = 0x8000-minus
            else:
                returnValue = 0x10000-minus
        elif (size == OP_SIZE_DWORD):
            if (half):
                returnValue = 0x80000000-minus
            else:
                returnValue = 0x100000000-minus
        elif (size == OP_SIZE_QWORD):
            if (half):
                returnValue = 0x8000000000000000-minus
            else:
                returnValue = 0x10000000000000000-minus
        else:
            self.main.exitError("Misc::getBitMask: size not in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD, OP_SIZE_QWORD)")
        return returnValue


