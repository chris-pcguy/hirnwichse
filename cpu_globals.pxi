
from libc.stdint cimport *

cdef uint8_t CPU_REGISTER_RAX = 0
cdef uint8_t CPU_REGISTER_EAX = 0
cdef uint8_t CPU_REGISTER_AX = 0
cdef uint8_t CPU_REGISTER_AH = 0
cdef uint8_t CPU_REGISTER_AL = 0
cdef uint8_t CPU_REGISTER_RCX = 1
cdef uint8_t CPU_REGISTER_ECX = 1
cdef uint8_t CPU_REGISTER_CX = 1
cdef uint8_t CPU_REGISTER_CH = 1
cdef uint8_t CPU_REGISTER_CL = 1
cdef uint8_t CPU_REGISTER_RDX = 2
cdef uint8_t CPU_REGISTER_EDX = 2
cdef uint8_t CPU_REGISTER_DX = 2
cdef uint8_t CPU_REGISTER_DH = 2
cdef uint8_t CPU_REGISTER_DL = 2
cdef uint8_t CPU_REGISTER_RBX = 3
cdef uint8_t CPU_REGISTER_EBX = 3
cdef uint8_t CPU_REGISTER_BX = 3
cdef uint8_t CPU_REGISTER_BH = 3
cdef uint8_t CPU_REGISTER_BL = 3
cdef uint8_t CPU_REGISTER_RSP = 4
cdef uint8_t CPU_REGISTER_ESP = 4
cdef uint8_t CPU_REGISTER_SP = 4
cdef uint8_t CPU_REGISTER_RBP = 5
cdef uint8_t CPU_REGISTER_EBP = 5
cdef uint8_t CPU_REGISTER_BP = 5
cdef uint8_t CPU_REGISTER_RSI = 6
cdef uint8_t CPU_REGISTER_ESI = 6
cdef uint8_t CPU_REGISTER_SI = 6
cdef uint8_t CPU_REGISTER_RDI = 7
cdef uint8_t CPU_REGISTER_EDI = 7
cdef uint8_t CPU_REGISTER_DI = 7
cdef uint8_t CPU_REGISTER_RIP = 8
cdef uint8_t CPU_REGISTER_EIP = 8
cdef uint8_t CPU_REGISTER_IP = 8
cdef uint8_t CPU_REGISTER_RFLAGS = 9
cdef uint8_t CPU_REGISTER_EFLAGS = 9
cdef uint8_t CPU_REGISTER_FLAGS = 9

cdef uint8_t CPU_SEGMENT_BASE = 10
cdef uint8_t CPU_SEGMENT_CS  = 1 # 11
cdef uint8_t CPU_SEGMENT_SS  = 2 # 12
cdef uint8_t CPU_SEGMENT_DS  = 3 # 13
cdef uint8_t CPU_SEGMENT_ES  = 4 # 14
cdef uint8_t CPU_SEGMENT_FS  = 5 # 15
cdef uint8_t CPU_SEGMENT_GS  = 6 # 16
cdef uint8_t CPU_SEGMENT_TSS = 7 # 17


cdef uint8_t CPU_REGISTER_CR0 = 18
cdef uint8_t CPU_REGISTER_CR2 = 19
cdef uint8_t CPU_REGISTER_CR3 = 20
cdef uint8_t CPU_REGISTER_CR4 = 21

cdef uint8_t CPU_REGISTER_DR0 = 22
cdef uint8_t CPU_REGISTER_DR1 = 23
cdef uint8_t CPU_REGISTER_DR2 = 24
cdef uint8_t CPU_REGISTER_DR3 = 25
cdef uint8_t CPU_REGISTER_DR6 = 26
cdef uint8_t CPU_REGISTER_DR7 = 27

cdef uint8_t CPU_REGISTER_NONE = 28

DEF CPU_REGISTERS = 29

cdef uint32_t FLAG_CF   = 0x1
cdef uint32_t FLAG_REQUIRED = 0x2
cdef uint32_t FLAG_PF   = 0x4
cdef uint32_t FLAG_AF   = 0x10
cdef uint32_t FLAG_ZF   = 0x40
cdef uint32_t FLAG_SF   = 0x80
cdef uint32_t FLAG_TF   = 0x100
cdef uint32_t FLAG_IF   = 0x200
cdef uint32_t FLAG_DF   = 0x400
cdef uint32_t FLAG_OF   = 0x800
cdef uint32_t FLAG_IOPL = 0x3000
cdef uint32_t FLAG_NT   = 0x4000
cdef uint32_t FLAG_RF   = 0x10000 # resume flag
cdef uint32_t FLAG_VM   = 0x20000 # virtual 8086 mode
cdef uint32_t FLAG_AC   = 0x40000 # alignment check if this and CR0 #AM set
cdef uint32_t FLAG_VIF  = 0x80000 # virtual interrupt flag
cdef uint32_t FLAG_VIP  = 0x100000 # virtual interrupt pending flag
cdef uint32_t FLAG_ID   = 0x200000

cdef uint32_t FLAG_CF_ZF = FLAG_CF | FLAG_ZF
cdef uint32_t FLAG_SF_OF = FLAG_SF | FLAG_OF
cdef uint32_t FLAG_SF_OF_ZF = FLAG_SF | FLAG_OF | FLAG_ZF

cdef uint32_t RESERVED_FLAGS_BITMASK = 0xffc0802a
cdef uint32_t CR0_FLAG_PE = 0x1
cdef uint32_t CR0_FLAG_MP = 0x2
cdef uint32_t CR0_FLAG_EM = 0x4
cdef uint32_t CR0_FLAG_TS = 0x8
cdef uint32_t CR0_FLAG_ET = 0x10
cdef uint32_t CR0_FLAG_NE = 0x20
cdef uint32_t CR0_FLAG_WP = 0x10000
cdef uint32_t CR0_FLAG_AM = 0x40000
cdef uint32_t CR0_FLAG_NW = 0x20000000
cdef uint32_t CR0_FLAG_CD = 0x40000000
cdef uint32_t CR0_FLAG_PG = 0x80000000


cdef uint32_t CR4_FLAG_VME = 0x1
cdef uint32_t CR4_FLAG_PVI = 0x2
cdef uint32_t CR4_FLAG_TSD = 0x4
cdef uint32_t CR4_FLAG_DE  = 0x8
cdef uint32_t CR4_FLAG_PSE = 0x10
cdef uint32_t CR4_FLAG_PAE = 0x20
cdef uint32_t CR4_FLAG_MCE = 0x40
cdef uint32_t CR4_FLAG_PGE = 0x80
cdef uint32_t CR4_FLAG_PCE = 0x100
cdef uint32_t CR4_FLAG_OSFXSR = 0x200
cdef uint32_t CR4_FLAG_OSXMMEXCPT = 0x400

cdef uint8_t MODRM_FLAGS_NONE = 0
cdef uint8_t MODRM_FLAGS_SREG = 1
cdef uint8_t MODRM_FLAGS_CREG = 2
cdef uint8_t MODRM_FLAGS_DREG = 3


cdef uint8_t REG_TYPE_LOW_BYTE = 1
cdef uint8_t REG_TYPE_HIGH_BYTE = 2
cdef uint8_t REG_TYPE_WORD = 3
cdef uint8_t REG_TYPE_DWORD = 4
cdef uint8_t REG_TYPE_QWORD = 5

cdef uint8_t CPU_REGISTER_SREG[9]
CPU_REGISTER_SREG = (CPU_SEGMENT_ES,CPU_SEGMENT_CS,CPU_SEGMENT_SS,CPU_SEGMENT_DS,CPU_SEGMENT_FS,CPU_SEGMENT_GS, \
                                CPU_REGISTER_NONE, CPU_REGISTER_NONE, CPU_SEGMENT_TSS)
cdef uint8_t CPU_REGISTER_CREG[8]
CPU_REGISTER_CREG = (CPU_REGISTER_CR0, CPU_REGISTER_NONE, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4, \
                                CPU_REGISTER_NONE, CPU_REGISTER_NONE, CPU_REGISTER_NONE)
cdef uint8_t CPU_REGISTER_DREG[8]
CPU_REGISTER_DREG = (CPU_REGISTER_DR0, CPU_REGISTER_DR1, CPU_REGISTER_DR2, CPU_REGISTER_DR3, CPU_REGISTER_DR6, \
                                CPU_REGISTER_DR7, CPU_REGISTER_DR6, CPU_REGISTER_DR7)

cdef uint8_t CPU_MODRM_16BIT_RM0[8]
CPU_MODRM_16BIT_RM0 = (CPU_REGISTER_RBX, CPU_REGISTER_RBX, CPU_REGISTER_RBP, CPU_REGISTER_RBP, CPU_REGISTER_RSI, \
                                  CPU_REGISTER_RDI, CPU_REGISTER_RBP, CPU_REGISTER_RBX)

cdef uint8_t CPU_MODRM_16BIT_RM1[8]
CPU_MODRM_16BIT_RM1 = (CPU_REGISTER_RSI, CPU_REGISTER_RDI, CPU_REGISTER_RSI, CPU_REGISTER_RDI, CPU_REGISTER_NONE, \
                                  CPU_REGISTER_NONE, CPU_REGISTER_NONE, CPU_REGISTER_NONE)


cdef uint8_t GDT_USE_LDT = 0x4
cdef uint8_t GDT_FLAG_USE_4K = 0x8
cdef uint8_t GDT_FLAG_SIZE = 0x4 # 0==16bit; 1==32bit
cdef uint8_t GDT_FLAG_LONGMODE = 0x2
cdef uint8_t GDT_FLAG_AVAILABLE = 0x1

cdef uint8_t GDT_ACCESS_ACCESSED = 0x1
cdef uint8_t GDT_ACCESS_READABLE_WRITABLE = 0x2 # segment readable/writable
cdef uint8_t GDT_ACCESS_CONFORMING = 0x4
cdef uint8_t GDT_ACCESS_EXECUTABLE = 0x8 # 1==code segment; 0==data segment
cdef uint8_t GDT_ACCESS_NORMAL_SEGMENT = 0x10 # 1==code/data segment; 0==system segment
cdef uint8_t GDT_ACCESS_DPL = 0x60
cdef uint8_t GDT_ACCESS_PRESENT = 0x80

cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS = 0x1
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_LDT = 0x2
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_16BIT_TSS_BUSY = 0x3
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_16BIT_CALL_GATE = 0x4
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE = 0x5
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_16BIT_INTERRUPT_GATE = 0x6
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_16BIT_TRAP_GATE = 0x7
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS = 0x9
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY = 0xb
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_32BIT_CALL_GATE = 0xc
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE = 0xe
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_32BIT_TRAP_GATE = 0xf
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_MASK = 0x1f
cdef uint8_t TABLE_ENTRY_SYSTEM_TYPE_MASK_WITHOUT_BUSY = 0x1d


cdef uint8_t SELECTOR_USE_LDT = 0x4

cdef uint16_t GDT_HARD_LIMIT = 0xffff
cdef uint16_t IDT_HARD_LIMIT = 0xffff
cdef uint16_t TSS_MIN_16BIT_HARD_LIMIT = 0x2b
cdef uint16_t TSS_MIN_32BIT_HARD_LIMIT = 0x67



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


DEF CPU_EXCEPTIONS_FAULT_GROUP = (CPU_EXCEPTION_DE, CPU_EXCEPTION_BR, CPU_EXCEPTION_UD, CPU_EXCEPTION_NM, CPU_EXCEPTION_TS, \
                        CPU_EXCEPTION_NP, CPU_EXCEPTION_SS, CPU_EXCEPTION_GP, CPU_EXCEPTION_PF, CPU_EXCEPTION_MF, \
                        CPU_EXCEPTION_AC, CPU_EXCEPTION_XF)

### TODO: CPU_EXCEPTION_DB is FAULT/TRAP
DEF CPU_EXCEPTIONS_TRAP_GROUP = (CPU_EXCEPTION_DB, CPU_EXCEPTION_BP, CPU_EXCEPTION_OF)

DEF CPU_EXCEPTIONS_WITH_ERRORCODE = (CPU_EXCEPTION_DF, CPU_EXCEPTION_TS, CPU_EXCEPTION_NP, CPU_EXCEPTION_SS, \
                                 CPU_EXCEPTION_GP, CPU_EXCEPTION_PF, CPU_EXCEPTION_AC)


cdef uint8_t OPCODE_PREFIX_ES=0x26
cdef uint8_t OPCODE_PREFIX_CS=0x2e
cdef uint8_t OPCODE_PREFIX_SS=0x36
cdef uint8_t OPCODE_PREFIX_DS=0x3e
cdef uint8_t OPCODE_PREFIX_FS=0x64
cdef uint8_t OPCODE_PREFIX_GS=0x65
cdef uint8_t OPCODE_PREFIX_OP=0x66
cdef uint8_t OPCODE_PREFIX_ADDR=0x67
cdef uint8_t OPCODE_PREFIX_LOCK=0xf0
cdef uint8_t OPCODE_PREFIX_REPNE=0xf2
cdef uint8_t OPCODE_PREFIX_REPE=0xf3

DEF OPCODE_PREFIX_REPS = (0xf2, 0xf3)
DEF OPCODE_PREFIXES = (0x26, 0x2e, 0x36, 0x3e, 0x64, 0x65, 0x66, 0x67, 0xf0, 0xf2, 0xf3)

cdef uint8_t OPCODE_SAVE = 0
cdef uint8_t OPCODE_ADD  = 1
cdef uint8_t OPCODE_ADC  = 2
cdef uint8_t OPCODE_SUB  = 3
cdef uint8_t OPCODE_SBB  = 4
cdef uint8_t OPCODE_CMP  = 5
cdef uint8_t OPCODE_AND  = 6
cdef uint8_t OPCODE_OR   = 7
cdef uint8_t OPCODE_XOR  = 8
cdef uint8_t OPCODE_TEST = 9
cdef uint8_t OPCODE_NEG  = 10
cdef uint8_t OPCODE_NOT  = 11
cdef uint8_t OPCODE_MUL  = 12
cdef uint8_t OPCODE_IMUL = 13
cdef uint8_t OPCODE_DIV  = 14
cdef uint8_t OPCODE_IDIV = 15
cdef uint8_t OPCODE_JUMP = 16
cdef uint8_t OPCODE_CALL = 17

#cdef uint8_t CPU_CLOCK_TICK_SHIFT = 8
#cdef uint8_t CPU_CLOCK_TICK_SHIFT = 4
#cdef uint8_t CPU_CLOCK_TICK_SHIFT = 3
#cdef uint8_t CPU_CLOCK_TICK_SHIFT = 2
cdef uint8_t CPU_CLOCK_TICK_SHIFT = 0
cdef uint32_t CPU_CLOCK_TICK = 1<<CPU_CLOCK_TICK_SHIFT

cdef uint32_t PAGE_PRESENT = 0x1
cdef uint32_t PAGE_WRITABLE = 0x2
cdef uint32_t PAGE_EVERY_RING = 0x4 # allow access from every ring
cdef uint32_t PAGE_WRITE_THROUGH_CACHING = 0x8
cdef uint32_t PAGE_NO_CACHING = 0x10
cdef uint32_t PAGE_WAS_USED = 0x20
cdef uint32_t PAGE_WRITTEN_ON_PAGE = 0x40 # if page_directory: set it on write access at 4MB pages;; if page_table: set it on write access
cdef uint32_t PAGE_SIZE = 0x80
cdef uint32_t PAGE_GLOBAL = 0x100
cdef uint32_t PAGE_DIRECTORY_LENGTH = 0x1000
cdef uint32_t PAGE_DIRECTORY_ENTRIES = 0x400
cdef uint32_t TLB_SIZE = 0x400000


cdef uint16_t TSS_PREVIOUS_TASK_LINK = 0x00
cdef uint16_t TSS_16BIT_SP0 = 0x02
cdef uint16_t TSS_16BIT_SS0  = 0x04
cdef uint16_t TSS_16BIT_SP1 = 0x06
cdef uint16_t TSS_16BIT_SS1  = 0x08
cdef uint16_t TSS_16BIT_SP2 = 0x0a
cdef uint16_t TSS_16BIT_SS2  = 0x0c
cdef uint16_t TSS_16BIT_IP  = 0x0e
cdef uint16_t TSS_16BIT_FLAGS = 0x10
cdef uint16_t TSS_16BIT_AX  = 0x12
cdef uint16_t TSS_16BIT_CX  = 0x14
cdef uint16_t TSS_16BIT_DX  = 0x16
cdef uint16_t TSS_16BIT_BX  = 0x18
cdef uint16_t TSS_16BIT_SP  = 0x1a
cdef uint16_t TSS_16BIT_BP  = 0x1c
cdef uint16_t TSS_16BIT_SI  = 0x1e
cdef uint16_t TSS_16BIT_DI  = 0x20
cdef uint16_t TSS_16BIT_ES   = 0x22
cdef uint16_t TSS_16BIT_CS   = 0x24
cdef uint16_t TSS_16BIT_SS   = 0x26
cdef uint16_t TSS_16BIT_DS   = 0x28
cdef uint16_t TSS_16BIT_LDT_SEG_SEL = 0x2a


cdef uint16_t TSS_32BIT_ESP0 = 0x04
cdef uint16_t TSS_32BIT_SS0  = 0x08
cdef uint16_t TSS_32BIT_ESP1 = 0x0C
cdef uint16_t TSS_32BIT_SS1  = 0x10
cdef uint16_t TSS_32BIT_ESP2 = 0x14
cdef uint16_t TSS_32BIT_SS2  = 0x18
cdef uint16_t TSS_32BIT_CR3  = 0x1c
cdef uint16_t TSS_32BIT_EIP  = 0x20
cdef uint16_t TSS_32BIT_EFLAGS = 0x24
cdef uint16_t TSS_32BIT_EAX  = 0x28
cdef uint16_t TSS_32BIT_ECX  = 0x2c
cdef uint16_t TSS_32BIT_EDX  = 0x30
cdef uint16_t TSS_32BIT_EBX  = 0x34
cdef uint16_t TSS_32BIT_ESP  = 0x38
cdef uint16_t TSS_32BIT_EBP  = 0x3c
cdef uint16_t TSS_32BIT_ESI  = 0x40
cdef uint16_t TSS_32BIT_EDI  = 0x44
cdef uint16_t TSS_32BIT_ES   = 0x48
cdef uint16_t TSS_32BIT_CS   = 0x4c
cdef uint16_t TSS_32BIT_SS   = 0x50
cdef uint16_t TSS_32BIT_DS   = 0x54
cdef uint16_t TSS_32BIT_FS   = 0x58
cdef uint16_t TSS_32BIT_GS   = 0x5c
cdef uint16_t TSS_32BIT_LDT_SEG_SEL = 0x60
cdef uint16_t TSS_32BIT_T_FLAG = 0x64
cdef uint16_t TSS_32BIT_IOMAP_BASE_ADDR = 0x66


#DEF CPU_CACHE_SIZE = 16*1024 # in bytes
#DEF CPU_CACHE_SIZE = 4096*2 # in bytes
#DEF CPU_CACHE_SIZE = 16 # in bytes
DEF CPU_CACHE_SIZE = 0 # in bytes




cdef uint8_t FPU_BASE_OPCODE = 0xd8
cdef uint8_t FPU_EXCEPTION_IM = 1
cdef uint8_t FPU_EXCEPTION_PE = 5
cdef uint8_t FPU_EXCEPTION_ES = 7
cdef uint8_t FPU_PRECISION[5]
FPU_PRECISION = (24, 0, 53, 64, 80)
cdef uint8_t FPU_IRQ = 13


