

# regs:
# offset 0 == QWORD
# offset 1 == DWORD
# offset 2 == WORD
# offset 3 == HBYTE
# offset 4 == LBYTE

DEF CPU_REGISTER_OFFSET_QWORD = 0
DEF CPU_REGISTER_OFFSET_DWORD = 1
DEF CPU_REGISTER_OFFSET_WORD = 2
DEF CPU_REGISTER_OFFSET_HBYTE = 3
DEF CPU_REGISTER_OFFSET_LBYTE = 4



DEF CPU_MIN_REGISTER = 5
DEF CPU_REGISTER_NONE = 0
DEF CPU_REGISTER_RAX = 5
DEF CPU_REGISTER_EAX = 6
DEF CPU_REGISTER_AX  = 7
DEF CPU_REGISTER_AH  = 8
DEF CPU_REGISTER_AL  = 9
DEF CPU_REGISTER_RCX = 10
DEF CPU_REGISTER_ECX = 11
DEF CPU_REGISTER_CX  = 12
DEF CPU_REGISTER_CH  = 13
DEF CPU_REGISTER_CL  = 14
DEF CPU_REGISTER_RDX = 15
DEF CPU_REGISTER_EDX = 16
DEF CPU_REGISTER_DX  = 17
DEF CPU_REGISTER_DH  = 18
DEF CPU_REGISTER_DL  = 19
DEF CPU_REGISTER_RBX = 20
DEF CPU_REGISTER_EBX = 21
DEF CPU_REGISTER_BX  = 22
DEF CPU_REGISTER_BH  = 23
DEF CPU_REGISTER_BL  = 24
DEF CPU_REGISTER_RSP = 25
DEF CPU_REGISTER_ESP = 26
DEF CPU_REGISTER_SP  = 27
DEF CPU_REGISTER_RBP = 30
DEF CPU_REGISTER_EBP = 31
DEF CPU_REGISTER_BP  = 32
DEF CPU_REGISTER_RSI = 35
DEF CPU_REGISTER_ESI = 36
DEF CPU_REGISTER_SI  = 37
DEF CPU_REGISTER_RDI = 40
DEF CPU_REGISTER_EDI = 41
DEF CPU_REGISTER_DI  = 42
DEF CPU_REGISTER_RIP = 45
DEF CPU_REGISTER_EIP = 46
DEF CPU_REGISTER_IP  = 47
DEF CPU_REGISTER_RFLAGS = 50
DEF CPU_REGISTER_EFLAGS = 51
DEF CPU_REGISTER_FLAGS  = 52

DEF CPU_SEGMENT_CS = 57
DEF CPU_SEGMENT_SS = 62
DEF CPU_SEGMENT_DS = 67
DEF CPU_SEGMENT_ES = 72
DEF CPU_SEGMENT_FS = 77
DEF CPU_SEGMENT_GS = 82

DEF CPU_REGISTER_CR0 = 86
DEF CPU_REGISTER_CR2 = 91
DEF CPU_REGISTER_CR3 = 96
DEF CPU_REGISTER_CR4 = 101

DEF CPU_REGISTER_DR0 = 106
DEF CPU_REGISTER_DR1 = 111
DEF CPU_REGISTER_DR2 = 116
DEF CPU_REGISTER_DR3 = 121
DEF CPU_REGISTER_DR6 = 126
DEF CPU_REGISTER_DR7 = 131

cdef tuple CPU_REG_DATA_OFFSETS = (None, None, None, None, None, \
                                   0x08, 0x0c, 0x0e, 0x0e, 0x0f, \
                                   0x10, 0x14, 0x16, 0x16, 0x17, \
                                   0x18, 0x1c, 0x1e, 0x1e, 0x1f, \
                                   0x20, 0x24, 0x26, 0x26, 0x27, \
                                   0x28, 0x2c, 0x2e, None, None, \
                                   0x30, 0x34, 0x36, None, None, \
                                   0x38, 0x3c, 0x3e, None, None, \
                                   0x40, 0x44, 0x46, None, None, \
                                   0x48, 0x4c, 0x4e, None, None, \
                                   0x50, 0x54, 0x56, None, None, \
                                   None, None, 0x5e, None, None, \
                                   None, None, 0x66, None, None, \
                                   None, None, 0x6e, None, None, \
                                   None, None, 0x76, None, None, \
                                   None, None, 0x7e, None, None, \
                                   None, None, 0x86, None, None, \
                                   None, 0x8c, None, None, None, \
                                   None, 0x94, None, None, None, \
                                   None, 0x9c, None, None, None, \
                                   None, 0xa4, None, None, None, \
                                   None, 0xac, None, None, None, \
                                   None, 0xb4, None, None, None, \
                                   None, 0xbc, None, None, None, \
                                   None, 0xc4, None, None, None, \
                                   None, 0xcc, None, None, None, \
                                   None, 0xd4, None, None, None)

DEF CPU_MAX_REGISTER_WO_CR = 100 # without CRd
DEF CPU_MAX_REGISTER = 135
DEF CPU_REGISTER_LENGTH = 200*8
DEF CPU_NB_REGS64 = 16
DEF CPU_NB_REGS = 8
DEF CPU_NB_REGS32 = CPU_NB_REGS
DEF NUM_CORE_REGS = (CPU_NB_REGS * 2) + 25

DEF FLAG_CF   = 0x1
DEF FLAG_REQUIRED = 0x2
DEF FLAG_PF   = 0x4
DEF FLAG_AF   = 0x10
DEF FLAG_ZF   = 0x40
DEF FLAG_SF   = 0x80
DEF FLAG_TF   = 0x100
DEF FLAG_IF   = 0x200
DEF FLAG_DF   = 0x400
DEF FLAG_OF   = 0x800
DEF FLAG_IOPL = 0x3000
DEF FLAG_NT   = 0x4000
DEF FLAG_RF   = 0x10000 # resume flag
DEF FLAG_VM   = 0x20000 # virtual 8086 mode
DEF FLAG_AC   = 0x40000 # alignment check if this and CR0 #AM set
DEF FLAG_VIF  = 0x80000 # virtual interrupt flag
DEF FLAG_VIP  = 0x100000 # virtual interrupt pending flag
DEF FLAG_ID   = 0x200000

DEF FLAG_CF_ZF = FLAG_CF | FLAG_ZF
DEF FLAG_SF_OF = FLAG_SF | FLAG_OF
DEF FLAG_SF_OF_ZF = FLAG_SF | FLAG_OF | FLAG_ZF

cdef unsigned int RESERVED_FLAGS_BITMASK = 0xffc0802a
DEF CR0_FLAG_PE = 0x1
DEF CR0_FLAG_MP = 0x2
DEF CR0_FLAG_EM = 0x4
DEF CR0_FLAG_TS = 0x8
DEF CR0_FLAG_ET = 0x10
DEF CR0_FLAG_NE = 0x20
DEF CR0_FLAG_WP = 0x10000
DEF CR0_FLAG_AM = 0x40000
cdef unsigned int CR0_FLAG_NW = 0x20000000
cdef unsigned int CR0_FLAG_CD = 0x40000000
cdef unsigned int CR0_FLAG_PG = 0x80000000


DEF CR4_FLAG_VME = 0x1
DEF CR4_FLAG_PVI = 0x2
DEF CR4_FLAG_TSD = 0x4
DEF CR4_FLAG_DE  = 0x8
DEF CR4_FLAG_PSE = 0x10
DEF CR4_FLAG_PAE = 0x20
DEF CR4_FLAG_MCE = 0x40
DEF CR4_FLAG_PGE = 0x80
DEF CR4_FLAG_PCE = 0x100
DEF CR4_FLAG_OSFXSR = 0x200
DEF CR4_FLAG_OSXMMEXCPT = 0x400

DEF MODRM_FLAGS_NONE = 0
DEF MODRM_FLAGS_SREG = 1
DEF MODRM_FLAGS_CREG = 2
DEF MODRM_FLAGS_DREG = 4


cdef tuple CPU_REGISTER_QWORD = (CPU_REGISTER_RAX,CPU_REGISTER_RCX,CPU_REGISTER_RDX,CPU_REGISTER_RBX,CPU_REGISTER_RSP,
                    CPU_REGISTER_RBP,CPU_REGISTER_RSI,CPU_REGISTER_RDI,CPU_REGISTER_RIP,CPU_REGISTER_RFLAGS)

cdef tuple CPU_REGISTER_DWORD = (CPU_REGISTER_EAX,CPU_REGISTER_ECX,CPU_REGISTER_EDX,CPU_REGISTER_EBX,CPU_REGISTER_ESP,
                    CPU_REGISTER_EBP,CPU_REGISTER_ESI,CPU_REGISTER_EDI,CPU_REGISTER_EIP,CPU_REGISTER_EFLAGS,
                    CPU_REGISTER_CR0,CPU_REGISTER_CR2,CPU_REGISTER_CR3,CPU_REGISTER_CR4,
                    CPU_REGISTER_DR0,CPU_REGISTER_DR1,CPU_REGISTER_DR2,CPU_REGISTER_DR3,
                    CPU_REGISTER_DR6,CPU_REGISTER_DR7)

cdef tuple CPU_REGISTER_WORD = (CPU_REGISTER_AX,CPU_REGISTER_CX,CPU_REGISTER_DX,CPU_REGISTER_BX,CPU_REGISTER_SP,
                   CPU_REGISTER_BP,CPU_REGISTER_SI,CPU_REGISTER_DI,CPU_REGISTER_IP,CPU_REGISTER_FLAGS)

cdef tuple CPU_REGISTER_HBYTE = (CPU_REGISTER_AH,CPU_REGISTER_CH,CPU_REGISTER_DH,CPU_REGISTER_BH)
cdef tuple CPU_REGISTER_LBYTE = (CPU_REGISTER_AL,CPU_REGISTER_CL,CPU_REGISTER_DL,CPU_REGISTER_BL)

cdef tuple CPU_REGISTER_BYTE = (CPU_REGISTER_AL,CPU_REGISTER_CL,CPU_REGISTER_DL,CPU_REGISTER_BL,CPU_REGISTER_AH,CPU_REGISTER_CH,CPU_REGISTER_DH,CPU_REGISTER_BH)

cdef tuple CPU_REGISTER_SREG = (CPU_SEGMENT_ES,CPU_SEGMENT_CS,CPU_SEGMENT_SS,CPU_SEGMENT_DS,CPU_SEGMENT_FS,CPU_SEGMENT_GS,None,None)
cdef tuple CPU_REGISTER_CREG = (CPU_REGISTER_CR0, None, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4, None, None, None)
cdef tuple CPU_REGISTER_DREG = (CPU_REGISTER_DR0, CPU_REGISTER_DR1, CPU_REGISTER_DR2, CPU_REGISTER_DR3, None, None, CPU_REGISTER_DR6, CPU_REGISTER_DR7)

cdef tuple CPU_MODRM_16BIT_RM0 = (CPU_REGISTER_BX, CPU_REGISTER_BX, CPU_REGISTER_BP, CPU_REGISTER_BP, CPU_REGISTER_SI, \
                                  CPU_REGISTER_DI, CPU_REGISTER_BP, CPU_REGISTER_BX)

cdef tuple CPU_MODRM_16BIT_RM1 = (CPU_REGISTER_SI, CPU_REGISTER_DI, CPU_REGISTER_SI, CPU_REGISTER_DI, CPU_REGISTER_NONE, \
                                  CPU_REGISTER_NONE, CPU_REGISTER_NONE, CPU_REGISTER_NONE)


DEF GDT_USE_LDT = 0x4
DEF GDT_FLAG_USE_4K = 0x8
DEF GDT_FLAG_SIZE = 0x4 # 0==16bit; 1==32bit
DEF GDT_FLAG_LONGMODE = 0x2
DEF GDT_FLAG_AVAILABLE = 0x1

DEF GDT_ACCESS_ACCESSED = 0x1
DEF GDT_ACCESS_READABLE_WRITABLE = 0x2 # segment readable/writable
DEF GDT_ACCESS_CONFORMING = 0x4
DEF GDT_ACCESS_EXECUTABLE = 0x8 # 1==code segment; 0==data segment
DEF GDT_ACCESS_NORMAL_SEGMENT = 0x10
DEF GDT_ACCESS_DPL = 0x60
DEF GDT_ACCESS_PRESENT = 0x80

DEF TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS = 0x1
DEF TABLE_ENTRY_SYSTEM_TYPE_LDT = 0x2
DEF TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY = 0x3
DEF TABLE_ENTRY_SYSTEM_TYPE_16BIT_CALL_GATE = 0x4
DEF TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE = 0x5
DEF TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE = 0x6
DEF TABLE_ENTRY_SYSTEM_TYPE_16BIT_TRAP_GATE = 0x7
DEF TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS = 0x9
DEF TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY = 0xb
DEF TABLE_ENTRY_SYSTEM_TYPE_32BIT_CALL_GATE = 0xc
DEF TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE = 0xe
DEF TABLE_ENTRY_SYSTEM_TYPE_32BIT_TRAP_GATE = 0xf
DEF TABLE_ENTRY_SYSTEM_TYPE_MASK = 0x1f

DEF SELECTOR_USE_LDT = 0x4

DEF GDT_HARD_LIMIT = 0xffff
DEF IDT_HARD_LIMIT = 0x7ff
DEF TSS_MIN_16BIT_HARD_LIMIT = 0x2b
DEF TSS_MIN_32BIT_HARD_LIMIT = 0x67



DEF CPU_EXCEPTION_DE = 0 # divide-by-zero error
DEF CPU_EXCEPTION_DB = 1 # debug
DEF CPU_EXCEPTION_BP = 3 # breakpoint
DEF CPU_EXCEPTION_OF = 4 # overflow
DEF CPU_EXCEPTION_BR = 5 # bound range exceeded
DEF CPU_EXCEPTION_UD = 6 # invalid opcode
DEF CPU_EXCEPTION_NM = 7 # device not available
DEF CPU_EXCEPTION_DF = 8 # double fault
DEF CPU_EXCEPTION_TS = 10 # invalid TSS
DEF CPU_EXCEPTION_NP = 11 # segment not present
DEF CPU_EXCEPTION_SS = 12 # stack-segment fault
DEF CPU_EXCEPTION_GP = 13 # general-protection fault
DEF CPU_EXCEPTION_PF = 14 # page fault
DEF CPU_EXCEPTION_MF = 16 # x87 floating-point exception
DEF CPU_EXCEPTION_AC = 17 # alignment check
DEF CPU_EXCEPTION_MC = 18 # machine check
DEF CPU_EXCEPTION_XF = 19 # simd floating-point exception
DEF CPU_EXCEPTION_SX = 30 # security exception


cdef tuple CPU_EXCEPTIONS_FAULT_GROUP = (CPU_EXCEPTION_DE, CPU_EXCEPTION_BR, CPU_EXCEPTION_UD, CPU_EXCEPTION_NM, CPU_EXCEPTION_TS, \
                        CPU_EXCEPTION_NP, CPU_EXCEPTION_SS, CPU_EXCEPTION_GP, CPU_EXCEPTION_PF, CPU_EXCEPTION_MF, \
                        CPU_EXCEPTION_AC, CPU_EXCEPTION_XF)

### TODO: CPU_EXCEPTION_DB is FAULT/TRAP
cdef tuple CPU_EXCEPTIONS_TRAP_GROUP = (CPU_EXCEPTION_DB, CPU_EXCEPTION_BP, CPU_EXCEPTION_OF)

cdef tuple CPU_EXCEPTIONS_WITH_ERRORCODE = (CPU_EXCEPTION_DF, CPU_EXCEPTION_TS, CPU_EXCEPTION_NP, CPU_EXCEPTION_SS, \
                                 CPU_EXCEPTION_GP, CPU_EXCEPTION_PF, CPU_EXCEPTION_AC)


DEF OPCODE_PREFIX_CS=0x2e
DEF OPCODE_PREFIX_SS=0x36
DEF OPCODE_PREFIX_DS=0x3e
DEF OPCODE_PREFIX_ES=0x26
DEF OPCODE_PREFIX_FS=0x64
DEF OPCODE_PREFIX_GS=0x65
cdef tuple OPCODE_PREFIX_SEGMENTS = (OPCODE_PREFIX_CS, OPCODE_PREFIX_SS, OPCODE_PREFIX_DS, OPCODE_PREFIX_ES, OPCODE_PREFIX_FS, OPCODE_PREFIX_GS)
DEF OPCODE_PREFIX_OP=0x66
DEF OPCODE_PREFIX_ADDR=0x67
DEF OPCODE_PREFIX_LOCK=0xf0
DEF OPCODE_PREFIX_REPNE=0xf2
DEF OPCODE_PREFIX_REPE=0xf3
cdef tuple OPCODE_PREFIX_REPS = (OPCODE_PREFIX_REPNE,OPCODE_PREFIX_REPE)


cdef tuple OPCODE_PREFIXES = (OPCODE_PREFIX_OP, OPCODE_PREFIX_ADDR, OPCODE_PREFIX_CS,
                 OPCODE_PREFIX_SS, OPCODE_PREFIX_DS, OPCODE_PREFIX_ES, OPCODE_PREFIX_FS,
                 OPCODE_PREFIX_GS, OPCODE_PREFIX_REPNE, OPCODE_PREFIX_REPE, OPCODE_PREFIX_LOCK)


DEF OPCODE_SAVE = 0
DEF OPCODE_ADD  = 1
DEF OPCODE_ADC  = 2
DEF OPCODE_SUB  = 3
DEF OPCODE_SBB  = 4
DEF OPCODE_CMP  = 5
DEF OPCODE_AND  = 6
DEF OPCODE_OR   = 7
DEF OPCODE_XOR  = 8
DEF OPCODE_TEST = 9
DEF OPCODE_NEG  = 10
DEF OPCODE_NOT  = 11
DEF OPCODE_MUL  = 12
DEF OPCODE_IMUL = 13
DEF OPCODE_DIV  = 14
DEF OPCODE_IDIV = 15
DEF OPCODE_JUMP = 16
DEF OPCODE_CALL = 17

DEF CPU_CLOCK_TICK_SHIFT = 0
DEF CPU_CLOCK_TICK = 1<<CPU_CLOCK_TICK_SHIFT



