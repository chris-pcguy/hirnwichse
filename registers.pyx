import misc

# Parity Flag Table: DO NOT EDIT!!
PARITY_TABLE = [True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, False, True, True, False,
                True, False, False, True, True, False, False, True, False, True,
                True, False, False, True, True, False, True, False, False, True,
                True, False, False, True, False, True, True, False, True, False,
                False, True, False, True, True, False, False, True, True, False,
                True, False, False, True, False, True, True, False, True, False,
                False, True, True, False, False, True, False, True, True, False,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, True, False, False, True,
                False, True, True, False, False, True, True, False, True, False,
                False, True, False, True, True, False, True, False, False, True,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, True, False, False, True,
                False, True, True, False, True, False, False, True, False, True,
                True, False, False, True, True, False, True, False, False, True,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True, False, True, True, False,
                True, False, False, True, True, False, False, True, False, True,
                True, False, True, False, False, True, False, True, True, False,
                False, True, True, False, True, False, False, True, False, True,
                True, False, True, False, False, True, True, False, False, True,
                False, True, True, False, False, True, True, False, True, False,
                False, True, True, False, False, True, False, True, True, False,
                True, False, False, True, False, True, True, False, False, True,
                True, False, True, False, False, True]

# regs:
# offset 0 == QWORD
# offset 1 == DWORD
# offset 2 == WORD
# offset 3 == HBYTE
# offset 4 == LBYTE

CPU_REGISTER_OFFSET_QWORD = 0
CPU_REGISTER_OFFSET_DWORD = 1
CPU_REGISTER_OFFSET_WORD = 2
CPU_REGISTER_OFFSET_HBYTE = 3
CPU_REGISTER_OFFSET_LBYTE = 4



CPU_MIN_REGISTER = 20
CPU_REGISTER_NONE = 0
CPU_REGISTER_RAX = 20
CPU_REGISTER_EAX = 21
CPU_REGISTER_AX  = 22
CPU_REGISTER_AH  = 23
CPU_REGISTER_AL  = 24
CPU_REGISTER_RCX = 25
CPU_REGISTER_ECX = 26
CPU_REGISTER_CX  = 27
CPU_REGISTER_CH  = 28
CPU_REGISTER_CL  = 29
CPU_REGISTER_RDX = 30
CPU_REGISTER_EDX = 31
CPU_REGISTER_DX  = 32
CPU_REGISTER_DH  = 33
CPU_REGISTER_DL  = 34
CPU_REGISTER_RBX = 35
CPU_REGISTER_EBX = 36
CPU_REGISTER_BX  = 37
CPU_REGISTER_BH  = 38
CPU_REGISTER_BL  = 39
CPU_REGISTER_RSP = 40
CPU_REGISTER_ESP = 41
CPU_REGISTER_SP  = 42
CPU_REGISTER_RBP = 45
CPU_REGISTER_EBP = 46
CPU_REGISTER_BP  = 47
CPU_REGISTER_RSI = 50
CPU_REGISTER_ESI = 51
CPU_REGISTER_SI  = 52
CPU_REGISTER_RDI = 55
CPU_REGISTER_EDI = 56
CPU_REGISTER_DI  = 57
CPU_REGISTER_RIP = 60
CPU_REGISTER_EIP = 61
CPU_REGISTER_IP  = 62
CPU_REGISTER_RFLAGS = 65
CPU_REGISTER_EFLAGS = 66
CPU_REGISTER_FLAGS  = 67

CPU_SEGMENT_CS = 72
CPU_SEGMENT_SS = 77
CPU_SEGMENT_DS = 82
CPU_SEGMENT_ES = 87
CPU_SEGMENT_FS = 92
CPU_SEGMENT_GS = 97

CPU_REGISTER_CR0 = 101
CPU_REGISTER_CR2 = 106
CPU_REGISTER_CR3 = 111
CPU_REGISTER_CR4 = 116

CPU_MAX_REGISTER_WO_CR = 100 # without CRd
CPU_MAX_REGISTER = 120
CPU_REGISTER_LENGTH = 640*8
CPU_NB_REGS64 = 16
CPU_NB_REGS = CPU_NB_REGS32 = 8
NUM_CORE_REGS = (CPU_NB_REGS * 2) + 25

FLAG_CF   = 0x1
FLAG_PF   = 0x4
FLAG_AF   = 0x10
FLAG_ZF   = 0x40
FLAG_SF   = 0x80
FLAG_TF   = 0x100
FLAG_IF   = 0x200
FLAG_DF   = 0x400
FLAG_OF   = 0x800
FLAG_IOPL = 0x3000
FLAG_NT   = 0x4000
FLAG_RF   = 0x10000 # resume flag
FLAG_VM   = 0x20000 # virtual 8086 mode
FLAG_AC   = 0x40000 # alignment check if this and CR0 #AM set
FLAG_VIF  = 0x80000 # virtual interrupt flag
FLAG_VIP  = 0x100000 # virtual interrupt pending flag
FLAG_ID   = 0x200000

CR0_FLAG_PE = 0x1
CR0_FLAG_MP = 0x2
CR0_FLAG_EM = 0x4
CR0_FLAG_TS = 0x8
CR0_FLAG_ET = 0x10
CR0_FLAG_NE = 0x20
CR0_FLAG_WP = 0x10000
CR0_FLAG_AM = 0x40000
CR0_FLAG_NW = 0x20000000
CR0_FLAG_CD = 0x40000000
CR0_FLAG_PG = 0x80000000


CR4_FLAG_VME = 0x1
CR4_FLAG_PVI = 0x2
CR4_FLAG_TSD = 0x4
CR4_FLAG_DE  = 0x8
CR4_FLAG_PSE = 0x10
CR4_FLAG_PAE = 0x20
CR4_FLAG_MCE = 0x40
CR4_FLAG_PGE = 0x80
CR4_FLAG_PCE = 0x100
CR4_FLAG_OSFXSR = 0x200
CR4_FLAG_OSXMMEXCPT = 0x400


MODRM_FLAGS_SREG = 1
MODRM_FLAGS_CREG = 2
MODRM_FLAGS_DREG = 4


IDT_INTR_TYPE_INTERRUPT = 6
IDT_INTR_TYPE_TRAP = 7
IDT_INTR_TYPE_TASK = 5

IDT_INTR_TYPES = (IDT_INTR_TYPE_INTERRUPT, IDT_INTR_TYPE_TRAP, IDT_INTR_TYPE_TASK)


CPU_REGISTER_QWORD=(CPU_REGISTER_RAX,CPU_REGISTER_RCX,CPU_REGISTER_RDX,CPU_REGISTER_RBX,CPU_REGISTER_RSP,
                    CPU_REGISTER_RBP,CPU_REGISTER_RSI,CPU_REGISTER_RDI,CPU_REGISTER_RIP,CPU_REGISTER_RFLAGS)

CPU_REGISTER_DWORD=(CPU_REGISTER_EAX,CPU_REGISTER_ECX,CPU_REGISTER_EDX,CPU_REGISTER_EBX,CPU_REGISTER_ESP,
                    CPU_REGISTER_EBP,CPU_REGISTER_ESI,CPU_REGISTER_EDI,CPU_REGISTER_EIP,CPU_REGISTER_EFLAGS,
                    CPU_REGISTER_CR0,CPU_REGISTER_CR2,CPU_REGISTER_CR3,CPU_REGISTER_CR4)

CPU_REGISTER_WORD=(CPU_REGISTER_AX,CPU_REGISTER_CX,CPU_REGISTER_DX,CPU_REGISTER_BX,CPU_REGISTER_SP,
                   CPU_REGISTER_BP,CPU_REGISTER_SI,CPU_REGISTER_DI,CPU_REGISTER_IP,CPU_REGISTER_FLAGS)

CPU_REGISTER_HBYTE=(CPU_REGISTER_AH,CPU_REGISTER_CH,CPU_REGISTER_DH,CPU_REGISTER_BH)
CPU_REGISTER_LBYTE=(CPU_REGISTER_AL,CPU_REGISTER_CL,CPU_REGISTER_DL,CPU_REGISTER_BL)

CPU_REGISTER_BYTE=(CPU_REGISTER_AL,CPU_REGISTER_CL,CPU_REGISTER_DL,CPU_REGISTER_BL,CPU_REGISTER_AH,CPU_REGISTER_CH,CPU_REGISTER_DH,CPU_REGISTER_BH)

CPU_REGISTER_SREG=(CPU_SEGMENT_ES,CPU_SEGMENT_CS,CPU_SEGMENT_SS,CPU_SEGMENT_DS,CPU_SEGMENT_FS,CPU_SEGMENT_GS,None,None)
CPU_REGISTER_CREG=(CPU_REGISTER_CR0, None, CPU_REGISTER_CR2, CPU_REGISTER_CR3, CPU_REGISTER_CR4, None, None, None)
CPU_REGISTER_DREG=()

CPU_REGISTER_INST_POINTER=(CPU_REGISTER_RIP, CPU_REGISTER_EIP, CPU_REGISTER_IP)

###CPU_SEGMENTS=(CPU_SEGMENT_ES,CPU_SEGMENT_CS,CPU_SEGMENT_SS,CPU_SEGMENT_DS,CPU_SEGMENT_FS,CPU_SEGMENT_GS,None,None)

GDT_USE_LDT = 0x4
GDT_FLAG_GRANULARITY = 0x8
GDT_FLAG_SIZE = 0x4 # 0==16bit; 1==32bit
GDT_FLAG_LONGMODE = 0x2
GDT_FLAG_AVAILABLE = 0x1
GDT_ACCESS_EXECUTABLE = 0x8 # 1==code segment; 0==data segment
GDT_ACCESS_PRESENT = 0x80
GDT_ACCESS_READABLE_WRITABLE = 0x2 # segment readable/writable
GDT_ACCESS_DPL = 0x60


cdef class Gdt:
    cdef public object main
    cdef public unsigned char needFlush, setGdtLoadedTo, gdtLoaded
    cdef unsigned long long tableBase
    cdef unsigned long tableLimit
    def __init__(self, object main):
        self.main = main
        self.setGdtLoadedTo = False # used only if needFlush == True
        self.gdtLoaded = False
        self.needFlush = False # flush with farJMP (opcode 0xEA)
    def loadTable(self, unsigned long long tableBase, unsigned long tableLimit):
        self.tableBase, self.tableLimit = tableBase, tableLimit
        self.needFlush = False
        #self.gdtLoaded = True
    def getEntry(self, unsigned short num):
        cdef unsigned long long entryData, base
        cdef unsigned long limit
        cdef unsigned char flags, accessByte
        if ((num & GDT_USE_LDT)!=0):
            self.main.exitError("GDT::getEntry: LDT not supported yet, exiting...")
            return
        entryData = self.main.mm.mmPhyReadValue(self.tableBase+(num&0xfff8), 8)
        limit = entryData&0xffff
        base  = (entryData>>16)&0xffffff
        accessByte = (entryData>>40)&0xff
        flags  = (entryData>>52)&0xf
        limit |= (( entryData>>48)&0xf)<<16
        base  |= ( (entryData>>56)&0xff)<<24
        return base, limit, accessByte, flags
    def getSegSize(self, unsigned short num):
        cdef tuple entryRet
        cdef unsigned long long base
        cdef unsigned long limit
        cdef unsigned char accessByte, flags
        entryRet = self.getEntry(num)
        base, limit, accessByte, flags = entryRet
        if (flags & GDT_FLAG_SIZE):
            return misc.OP_SIZE_DWORD
        return misc.OP_SIZE_WORD
    def getSegAccess(self, unsigned short num):
        cdef tuple entryRet
        cdef unsigned char accessByte
        entryRet = self.getEntry(num)
        accessByte = entryRet[2]
        return accessByte
    def isSegPresent(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_PRESENT)!=0
    def isCodeSeg(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_EXECUTABLE)!=0
    def isSegReadableWritable(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_READABLE_WRITABLE)!=0
    def getSegDPL(self, unsigned short num):
        cdef unsigned char accessByte
        accessByte = self.getSegAccess(num)
        return (accessByte & GDT_ACCESS_DPL)&3
    
    
    


cdef class Idt:
    cdef public object main
    cdef public unsigned long long tableBase
    cdef public unsigned long tableLimit
    def __init__(self, object main, unsigned long long tableBase, unsigned long tableLimit):
        self.main = main
        self.loadTable(tableBase, tableLimit)
    def loadTable(self, unsigned long long tableBase, unsigned long tableLimit):
        self.tableBase, self.tableLimit = tableBase, tableLimit
    def getEntry(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned long entryEip
        cdef unsigned short entrySegment
        cdef unsigned char entryType, entrySize, entryNeededDPL, entryPresent
        entryData = self.main.mm.mmPhyReadValue(self.tableBase+(num*8), 8)
        entryEip = entryData&0xffff # interrupt eip: lower word
        entrySegment = (entryData>>16)&0xffff # interrupt segment
        entryEip |= ((entryData>>48)&0xffff)<<16 # interrupt eip: upper word
        entryType = (entryData>>40)&0x7 # interrupt type
        entryNeededDPL = (entryData>>45)&0x3 # interrupt: Need this DPL
        entryPresent = (entryData>>47)&1 # is interrupt present
        entrySize = (entryData>>43)&1 # interrupt size: 1==32bit; 0==16bit; return 4 for 32bit, 2 for 16bit
        if (entrySize!=0): entrySize = misc.OP_SIZE_DWORD
        else: entrySize = misc.OP_SIZE_WORD
        return entrySegment, entryEip, entryType, entrySize, entryNeededDPL, entryPresent
    def isEntryPresent(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned char entryPresent
        entryData = self.main.mm.mmPhyReadValue(self.tableBase+(num*8), 8)
        entryPresent = (entryData>>47)&1 # is interrupt present
        return entryPresent
    def getEntryNeededDPL(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned char entryPresent
        entryData = self.main.mm.mmPhyReadValue(self.tableBase+(num*8), 8)
        entryNeededDPL = (entryData>>45)&0x3 # interrupt: Need this DPL
        return entryNeededDPL
    def getEntrySize(self, unsigned short num):
        cdef unsigned long long entryData
        cdef unsigned char entrySize
        entryData = self.main.mm.mmPhyReadValue(self.tableBase+(num*8), 8)
        entrySize = (entryData>>43)&1 # interrupt size: 1==32bit; 0==16bit; return 4 for 32bit, 2 for 16bit
        if (entrySize!=0): entrySize = misc.OP_SIZE_DWORD
        else: entrySize = misc.OP_SIZE_WORD
        return entrySize
    def getEntryRealMode(self, unsigned short num):
        cdef unsigned short offset, entrySegment, entryEip
        offset = num*4
        entryEip = self.main.mm.mmPhyReadValue(offset, 2)
        entrySegment = self.main.mm.mmPhyReadValue(offset+2, 2)
        return entrySegment, entryEip


cdef class Segments:
    cdef public object main, cpu, registers, gdt, idt
    def __init__(self, object main, object cpu, object registers):
        self.main, self.cpu, self.registers = main, cpu, registers
        self.reset()
    def reset(self):
        self.gdt = Gdt(self.main)
        self.idt = Idt(self.main, 0, 0x3ff)
    def getBaseAddr(self, unsigned short segId): # segId == segments regId
        cdef unsigned long long segValue = self.registers.segRead(segId)
        if (self.cpu.isInProtectedMode()): # protected mode enabled
            return self.gdt.getEntry(segValue)[0]
        #else: # real mode
        return segValue<<4
    def getRealAddr(self, unsigned short segId, long long offsetAddr):
        cdef long long addr
        addr = self.getBaseAddr(segId)
        if (not self.cpu.isInProtectedMode()):
            if (self.cpu.getA20State()): # A20 Active? if True == on, else off
                offsetAddr &= 0x1fffff
            else:
                offsetAddr &= 0xfffff
            addr += offsetAddr
        else:
            addr += offsetAddr
        return addr&0xffffffff
    def getSegSize(self, unsigned short segId): # segId == segments regId
        if (self.cpu.isInProtectedMode()): # protected mode enabled
        #if (self.gdt.gdtLoaded and not self.gdt.needFlush):
            return self.gdt.getSegSize(self.registers.segRead(segId))
        #else: # real mode
        return misc.OP_SIZE_WORD
    def isSegPresent(self, unsigned short segId): # segId == segments regId
        if (self.cpu.isInProtectedMode()): # protected mode enabled
        #if (self.gdt.gdtLoaded and not self.gdt.needFlush):
            return self.gdt.isSegPresent(self.registers.segRead(segId))
        #else: # real mode
        return True
    def getOpSegSize(self, unsigned short segId): # segId == segments regId
        cdef unsigned char segSize = self.getSegSize(segId)
        if (segSize == misc.OP_SIZE_WORD):
            return ((self.registers.operandSizePrefix and misc.OP_SIZE_DWORD) or misc.OP_SIZE_WORD)
        elif (segSize == misc.OP_SIZE_DWORD):
            return ((self.registers.operandSizePrefix and misc.OP_SIZE_WORD) or misc.OP_SIZE_DWORD)
        else:
            self.main.exitError("getOpSegSize: segSize is not valid. ({0:d})", segSize)
    def getAddrSegSize(self, unsigned short segId): # segId == segments regId
        cdef unsigned char segSize = self.getSegSize(segId)
        if (segSize == misc.OP_SIZE_WORD):
            return ((self.registers.addressSizePrefix and misc.OP_SIZE_DWORD) or misc.OP_SIZE_WORD)
        elif (segSize == misc.OP_SIZE_DWORD):
            return ((self.registers.addressSizePrefix and misc.OP_SIZE_WORD) or misc.OP_SIZE_DWORD)
        else:
            self.main.exitError("getAddrSegSize: segSize is not valid. ({0:d})", segSize)
    def getOpAddrSegSize(self, unsigned short segId): # segId == segments regId
        cdef unsigned char opSize, addrSize, segSize
        segSize = self.getSegSize(segId)
        if (segSize == misc.OP_SIZE_WORD):
            opSize   = ((self.registers.operandSizePrefix and misc.OP_SIZE_DWORD) or misc.OP_SIZE_WORD)
            addrSize = ((self.registers.addressSizePrefix and misc.OP_SIZE_DWORD) or misc.OP_SIZE_WORD)
        elif (segSize == misc.OP_SIZE_DWORD):
            opSize   = ((self.registers.operandSizePrefix and misc.OP_SIZE_WORD) or misc.OP_SIZE_DWORD)
            addrSize = ((self.registers.addressSizePrefix and misc.OP_SIZE_WORD) or misc.OP_SIZE_DWORD)
        else:
            self.main.exitError("getOpAddrSegSize: segSize is not valid. ({0:d})", segSize)
        return opSize, addrSize
    

cdef class Registers:
    cdef public object main, cpu, segments, regs
    cdef public unsigned char lockPrefix, branchPrefix, repPrefix, segmentOverridePrefix, operandSizePrefix, addressSizePrefix, cpl, iopl
    def __init__(self, object main, object cpu):
        self.main, self.cpu = main, cpu
        self.regs = bytearray(CPU_REGISTER_LENGTH)
        self.segments = Segments(self.main, self.cpu, self)
        self.reset(doInit=True)
    def reset(self, unsigned char doInit=False):
        if (not doInit):
            self.regs = bytearray(CPU_REGISTER_LENGTH)
            self.segments.reset()
        self.regWrite(CPU_REGISTER_EFLAGS, 0x2)
        self.segWrite(CPU_SEGMENT_CS, 0xffff000, shortSeg=False)
        self.regWrite(CPU_REGISTER_EIP, 0xfff0)
        self.regWrite(CPU_REGISTER_CR0, 0x60000034)
        self.resetPrefixes()
    def resetPrefixes(self):
        self.lockPrefix = False
        self.branchPrefix = False
        self.repPrefix = False
        self.segmentOverridePrefix = 0
        self.operandSizePrefix = False
        self.addressSizePrefix = False
        self.cpl, self.iopl = 0, 0 # TODO
    def regGetSize(self, unsigned short regId): # return size in bits
        if (regId in CPU_REGISTER_QWORD):
            return misc.OP_SIZE_QWORD
        elif (regId in CPU_REGISTER_DWORD):
            return misc.OP_SIZE_DWORD
        elif (regId in CPU_REGISTER_WORD):
            return misc.OP_SIZE_WORD
        elif (regId in CPU_REGISTER_BYTE):
            return misc.OP_SIZE_BYTE
        self.main.exitError("regId is unknown! ({0:d})", regId)
    def segRead(self, unsigned short segId): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        cdef unsigned short aregId
        cdef unsigned long segValue
        if (not segId and not (segId in CPU_REGISTER_SREG)):
            self.main.exitError("segRead: segId is not a segment! ({0:d})", segId)
            return
        aregId = (segId//5)*8
        segValue = int.from_bytes(bytes=self.regs[aregId+4:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN)
        return segValue
    def segWrite(self, unsigned short segId, unsigned long value, unsigned char shortSeg=True): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        cdef unsigned short aregId
        if (not segId and not (segId in CPU_REGISTER_SREG)):
            self.main.exitError("segWrite: segId is not a segment! ({0:d})", segId)
            return
        aregId = (segId//5)*8
        if (shortSeg):
            value &= 0xffff
        self.regs[aregId+4:aregId+8] = value.to_bytes(length=4, byteorder=misc.BYTE_ORDER_BIG_ENDIAN)
        return value
    def regRead(self, unsigned short regId, unsigned char signed=False): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        cdef unsigned short aregId
        cdef long long regValue
        if (regId == CPU_REGISTER_NONE):
            return 0
        if (regId < CPU_MIN_REGISTER or regId >= CPU_MAX_REGISTER):
            self.main.exitError("regRead: regId is reserved! ({0:d})", regId)
            return
        aregId = (regId//5)*8
        if (regId in CPU_REGISTER_QWORD):
            regValue = int.from_bytes(bytes=self.regs[aregId:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_DWORD):
            regValue = int.from_bytes(bytes=self.regs[aregId+4:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_WORD):
            regValue = int.from_bytes(bytes=self.regs[aregId+6:aregId+8], byteorder=misc.BYTE_ORDER_BIG_ENDIAN, signed=signed)
        elif (regId in CPU_REGISTER_HBYTE):
            regValue = self.regs[aregId+6]
            if (regValue & 0x80 and signed):
                regValue -= 0x100
        elif (regId in CPU_REGISTER_LBYTE):
            regValue = self.regs[aregId+7]
            if (regValue & 0x80 and signed):
                regValue -= 0x100
        else:
            self.main.exitError("regRead: regId is unknown! ({0:d})", regId)
        return regValue
    def regWrite(self, unsigned short regId, unsigned long value): # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
        cdef unsigned short aregId
        if (regId < CPU_MIN_REGISTER or regId >= CPU_MAX_REGISTER):
            self.main.exitError("regWrite: regId is reserved! ({0:d})", regId)
            return
        aregId = (regId//5)*8
        if (regId in CPU_REGISTER_QWORD):
            value &= 0xffffffffffffffff
            self.regs[aregId:aregId+8] = value.to_bytes(length=8, byteorder=misc.BYTE_ORDER_BIG_ENDIAN)
        elif (regId in CPU_REGISTER_DWORD):
            value &= 0xffffffff
            self.regs[aregId+4:aregId+8] = value.to_bytes(length=4, byteorder=misc.BYTE_ORDER_BIG_ENDIAN)
        elif (regId in CPU_REGISTER_WORD):
            value &= 0xffff
            self.regs[aregId+6:aregId+8] = value.to_bytes(length=2, byteorder=misc.BYTE_ORDER_BIG_ENDIAN)
        elif (regId in CPU_REGISTER_HBYTE):
            value &= 0xff
            self.regs[aregId+6] = value
        elif (regId in CPU_REGISTER_LBYTE):
            value &= 0xff
            self.regs[aregId+7] = value
        else:
            self.main.exitError("regWrite: regId is unknown! ({0:d})", regId)
        return value # return value is unsigned!!
    def regAdd(self, unsigned short regId, long long value):
        cdef unsigned long newVal = self.regRead(regId)
        newVal += value
        return self.regWrite(regId, newVal)
    def regAdc(self, unsigned short regId, unsigned long value):
        cdef unsigned char withCarry = self.getEFLAG( FLAG_CF )
        cdef unsigned long newVal = value+withCarry
        return self.regAdd(regId, newVal)
    def regSub(self, unsigned short regId, unsigned long value):
        cdef unsigned long newVal = self.regRead(regId)
        newVal -= value
        return self.regWrite(regId, newVal)
    def regSbb(self, unsigned short regId, unsigned long value):
        cdef unsigned char withCarry = self.getEFLAG( FLAG_CF )
        cdef unsigned long newVal = value+withCarry
        return self.regSub(regId, newVal)
    def regXor(self, unsigned short regId, unsigned long value):
        cdef unsigned long newVal = self.regRead(regId)^value
        return self.regWrite(regId, newVal)
    def regAnd(self, unsigned short regId, unsigned long value):
        cdef unsigned long newVal = self.regRead(regId)&value
        return self.regWrite(regId, newVal)
    def regOr (self, unsigned short regId, unsigned long value):
        cdef unsigned long newVal = self.regRead(regId)|value
        return self.regWrite(regId, newVal)
    def regNeg(self, unsigned short regId):
        cdef unsigned long newVal = -self.regRead(regId)
        return self.regWrite(regId, newVal)
    def regNot(self, unsigned short regId):
        cdef unsigned long newVal = ~self.regRead(regId)
        return self.regWrite(regId, newVal)
    def regWriteWithOp(self, unsigned short regId, unsigned long value, unsigned char valueOp):
        if (valueOp == misc.VALUEOP_SAVE):
            return self.regWrite(regId, value)
        elif (valueOp == misc.VALUEOP_ADD):
            return self.regAdd(regId, value)
        elif (valueOp == misc.VALUEOP_ADC):
            return self.regAdc(regId, value)
        elif (valueOp == misc.VALUEOP_SUB):
            return self.regSub(regId, value)
        elif (valueOp == misc.VALUEOP_SBB):
            return self.regSbb(regId, value)
        elif (valueOp == misc.VALUEOP_AND):
            return self.regAnd(regId, value)
        elif (valueOp == misc.VALUEOP_OR):
            return self.regOr(regId, value)
        elif (valueOp == misc.VALUEOP_XOR):
            return self.regXor(regId, value)
    def regDelFlag(self, unsigned short regId, unsigned long value): # by val, not bit
        newVal = self.regRead(regId)&(~value)
        return self.regWrite(regId, newVal)
    def regSetBit(self, unsigned short regId, unsigned char bit, unsigned char state):
        cdef unsigned long newVal
        if (state):
            newVal = self.regRead(regId)|(1<<bit)
        else:
            newVal = self.regRead(regId)&(~(1<<bit))
        self.regWrite(regId, newVal)
        return newVal
    def regGetBit(self, unsigned short regId, unsigned char bit): # return True if bit is set, otherwise False
        cdef unsigned long bitMask = (1<<bit)
        return (self.regRead(regId)&bitMask)!=0
    def valSetBit(self, unsigned long value, unsigned char bit, unsigned char state):
        cdef unsigned long bitMask = (1<<bit)
        if (state):
            return ( value | bitMask )
        else:
            return ( value & (~bitMask) )
    def valGetBit(self, unsigned long value, unsigned char bit): # return True if bit is set, otherwise False
        cdef unsigned long long bitMask = (1<<bit)
        return (value&bitMask)!=0
    def setEFLAG(self, unsigned long flags, unsigned char flagState):
        if (flagState):
            return self.regOr(CPU_REGISTER_EFLAGS, flags)
        return self.regDelFlag(CPU_REGISTER_EFLAGS, flags)
    def getEFLAG(self, unsigned long flags):
        return (self.regRead(CPU_REGISTER_EFLAGS)&flags)!=0
    def getFlag(self, unsigned short regId, unsigned long flags):
        return (self.regRead(regId)&flags)!=0
    def clearThisEFLAGS(self, unsigned long flags):
        self.regAnd( CPU_REGISTER_EFLAGS, ~flags )
    def setThisEFLAGS(self, unsigned long flags):
        self.regOr( CPU_REGISTER_EFLAGS, flags )
    def getWordAsDword(self, unsigned short regWord, unsigned char wantRegSize):
        if (regWord in CPU_REGISTER_WORD and wantRegSize == misc.OP_SIZE_DWORD):
            return regWord-1 # regWord-1 is for example bx as ebx...
        elif (regWord in CPU_REGISTER_DWORD and wantRegSize == misc.OP_SIZE_WORD):
            return regWord+1 # regWord+1 is for example ebx as bx...
        return regWord
    def setSZP(self, unsigned long value, unsigned char regSize):
        self.setEFLAG(FLAG_SF, (value&self.main.misc.getBitMask(regSize, half=True, minus=0))!=0)
        self.setEFLAG(FLAG_ZF, value==0)
        self.setEFLAG(FLAG_PF, PARITY_TABLE[value&0xff])
    def setSZP_O0(self, unsigned long value, unsigned char regSize):
        self.clearThisEFLAGS(FLAG_OF)
        self.setSZP(value, regSize)
    def setSZP_C0_O0(self, unsigned long value, unsigned char regSize):
        self.clearThisEFLAGS(FLAG_CF)
        self.setSZP_O0(value, regSize)
    def setSZP_C0_O0_A0(self, unsigned long value, unsigned char regSize):
        self.setSZP_C0_O0(value, regSize)
        self.setEFLAG(FLAG_AF, 0)
    def getRMValueFull(self, tuple rmValue, unsigned char rmSize):
        cdef unsigned long rmMask
        cdef long long rmValueFull
        rmMask = self.main.misc.getBitMask(rmSize)
        rmValueFull =  self.regRead(rmValue[0])
        rmValueFull += self.regRead(rmValue[1])
        rmValueFull += rmValue[2]
        return rmValueFull&rmMask
    def modRMLoad(self, tuple rmOperands, unsigned char regSize, unsigned char signed=False, unsigned char allowOverride=True): # imm == unsigned ; disp == signed; regSize in bits
        cdef unsigned char addrSize, mod
        cdef long long returnInt
        cdef tuple rmValue
        mod, rmValue = rmOperands[0:2]
        addrSize = self.segments.getAddrSegSize(CPU_SEGMENT_CS)
        returnInt = self.getRMValueFull(rmValue[0], addrSize)
        if (mod in (0, 1, 2)):
            returnInt = self.main.mm.mmReadValue(returnInt, regSize, segId=rmValue[1], signed=signed, allowOverride=allowOverride)
        else:
            returnInt = self.regRead(rmValue[0][0], signed=signed)
        return returnInt
    def modRMSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value, unsigned char allowOverride=True, unsigned char valueOp=misc.VALUEOP_SAVE): # imm == unsigned ; disp == signed
        cdef unsigned char addrSize, mod
        cdef unsigned short regValue
        cdef long long rmValueFull
        cdef tuple rmValue
        mod, rmValue, regValue = rmOperands
        addrSize = self.segments.getAddrSegSize(CPU_SEGMENT_CS)
        rmValueFull = self.getRMValueFull(rmValue[0], addrSize)
        if (mod in (0, 1, 2)):
            return self.main.mm.mmWriteValueWithOp(rmValueFull, value, regSize, segId=rmValue[1], allowOverride=allowOverride, valueOp=valueOp)
        else:
            return self.regWriteWithOp(rmValue[0][0], value, valueOp)
    def modSegLoad(self, tuple rmOperands, unsigned char regSize): # imm == unsigned ; disp == signed
        cdef unsigned short regValue
        cdef unsigned long returnInt
        regValue = rmOperands[2]
        returnInt  = self.segRead(regValue)
        return returnInt
    def modSegSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value): # imm == unsigned ; disp == signed
        cdef unsigned char segDPL
        cdef unsigned short regValue
        regValue = rmOperands[2]
        if (regValue == CPU_SEGMENT_CS):
            raise misc.ChemuException(misc.CPU_EXCEPTION_UD)
        if (self.cpu.isInProtectedMode()):
            segDPL = self.segments.gdt.getSegDPL(value)
            if (regValue == CPU_SEGMENT_SS):
                if (value == 0 or not self.segments.gdt.isSegReadableWritable(value) \
                        or (value&3 != self.cpl) or (segDPL != self.cpl) ): # RPL > DPL && CPL > DPL
                    raise misc.ChemuException(misc.CPU_EXCEPTION_GP, value)
                if (not self.segments.gdt.isSegPresent(value) ):
                    raise misc.ChemuException(misc.CPU_EXCEPTION_SS, value)
            else:
                if (value != 0):
                    if (((self.segments.gdt.isCodeSeg(value) or not self.segments.gdt.isSegReadableWritable(value)) \
                            and (value&3 > segDPL and self.cpl > segDPL ) ) ): # RPL > DPL && CPL > DPL
                        raise misc.ChemuException(misc.CPU_EXCEPTION_GP, value)
                    if (not self.segments.gdt.isSegPresent(value) ):
                        raise misc.ChemuException(misc.CPU_EXCEPTION_NP, value)
        return self.segWrite(regValue, value)
    def modRLoad(self, tuple rmOperands, unsigned char regSize, unsigned char signed=False): # imm == unsigned ; disp == signed
        cdef unsigned short regValue
        cdef long long returnInt
        regValue = rmOperands[2]
        returnInt  = self.regRead(regValue, signed=signed)
        return returnInt
    def modRSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value, unsigned char valueOp=misc.VALUEOP_SAVE): # imm == unsigned ; disp == signed
        cdef unsigned short regValue
        regValue = rmOperands[2]
        ##value &= self.main.misc.getBitMask(regSize)
        return self.regWriteWithOp(regValue, value, valueOp)
    def getRegValueWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize):
        cdef unsigned short regValue
        regValue = CPU_REGISTER_NONE
        if (modRMflags & MODRM_FLAGS_SREG):
            regValue = CPU_REGISTER_SREG[reg]
        elif (modRMflags & MODRM_FLAGS_CREG):
            regValue = CPU_REGISTER_CREG[reg]
        elif (modRMflags & MODRM_FLAGS_DREG):
            #regValue = CPU_REGISTER_DREG[reg]
            self.main.exitError("debug register NOT IMPLEMENTED yet!")
        else:
            if (operSize == misc.OP_SIZE_BYTE):
                regValue = CPU_REGISTER_BYTE[reg]
            elif (operSize == misc.OP_SIZE_WORD):
                regValue = CPU_REGISTER_WORD[reg]
            elif (operSize == misc.OP_SIZE_DWORD):
                regValue = CPU_REGISTER_DWORD[reg]
            else:
                self.main.exitError("getRegValueWithFlags: operSize not in (misc.OP_SIZE_BYTE, misc.OP_SIZE_WORD, misc.OP_SIZE_DWORD)")
        if (not regValue):
            raise misc.ChemuException(misc.CPU_EXCEPTION_UD)
        return regValue
    def sibOperands(self, unsigned char mod):
        cdef unsigned char sibByte, base, index, ss
        cdef unsigned short rmBase, rmValueSegId, indexReg
        cdef unsigned long bitMask
        cdef unsigned long long rmIndex
        sibByte = self.cpu.getCurrentOpcodeAdd()
        bitMask = 0xffffffff
        base    = (sibByte)&7
        index   = (sibByte>>3)&7
        ss      = (sibByte>>6)&3
        rmBase  = CPU_REGISTER_NONE
        rmValueSegId = CPU_SEGMENT_DS
        
        if (index == 0):
            indexReg = CPU_REGISTER_EAX
        elif (index == 1):
            indexReg = CPU_REGISTER_ECX
        elif (index == 2):
            indexReg = CPU_REGISTER_EDX
        elif (index == 3):
            indexReg = CPU_REGISTER_EBX
        elif (index == 4):
            indexReg = CPU_REGISTER_NONE
        elif (index == 5):
            indexReg = CPU_REGISTER_EBP
        elif (index == 6):
            indexReg = CPU_REGISTER_ESI
        elif (index == 7):
            indexReg = CPU_REGISTER_EDI
        
        rmIndex = (self.regRead( indexReg ) * (1 << ss))&bitMask
        
        if (mod == 0 and base == 5):
            rmIndex += self.cpu.getCurrentOpcodeAdd(misc.OP_SIZE_DWORD)
        else:
            rmBase = self.getRegValueWithFlags(0, base, misc.OP_SIZE_DWORD)
            if (rmBase in (CPU_REGISTER_ESP, CPU_REGISTER_EBP)):
                rmValueSegId = CPU_SEGMENT_SS
        
        return rmBase, rmValueSegId, rmIndex
    def modRMOperands(self, unsigned char regSize, unsigned char modRMflags=0): # imm == unsigned ; disp == signed ; regSize in bytes
        cdef unsigned char modRMByte, rm, reg, mod
        cdef unsigned short rmValueSegId, rmValue0, rmValue1, regValue
        cdef long long rmValue2
        modRMByte = self.cpu.getCurrentOpcodeAdd()
        rm  = modRMByte&0x7
        reg = (modRMByte>>3)&0x7
        mod = (modRMByte>>6)&0x3

        rmValueSegId = CPU_SEGMENT_DS
        if (self.segmentOverridePrefix):
            rmValueSegId = self.segmentOverridePrefix
        
        rmValue0, rmValue1, rmValue2 = 0, 0, 0
        regValue = 0
        if (self.segments.getAddrSegSize(CPU_SEGMENT_CS) == misc.OP_SIZE_WORD):
            if (mod in (0, 1, 2)): # rm: source ; reg: dest
                if (rm in (0, 1, 7)):
                    rmValue0 = CPU_REGISTER_BX
                elif (rm in (2, 3) or (rm == 6 and mod in (1,2))):
                    rmValue0 = CPU_REGISTER_BP
                    rmValueSegId = CPU_SEGMENT_SS
                elif (rm == 4):
                    rmValue0 = CPU_REGISTER_SI
                elif (rm == 5):
                    rmValue0 = CPU_REGISTER_DI
                if (rm in (0, 2)):
                    rmValue1 = CPU_REGISTER_SI
                elif (rm in (1, 3)):
                    rmValue1 = CPU_REGISTER_DI
                regValue  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
                if (mod == 0 and rm == 6):
                    rmValue2 = self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_WORD)
                elif (mod == 2):
                    rmValue2 = self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_WORD, signed=True)
                elif (mod == 1):
                    rmValue2 = self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_BYTE, signed=True)
            elif (mod == 3): # reg: source ; rm: dest
                regValue  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
                if (regSize == misc.OP_SIZE_BYTE):
                    rmValue0  = CPU_REGISTER_BYTE[rm] # dest
                elif (regSize == misc.OP_SIZE_WORD):
                    rmValue0  = CPU_REGISTER_WORD[rm] # dest
                elif (regSize == misc.OP_SIZE_DWORD):
                    rmValue0  = CPU_REGISTER_DWORD[rm] # dest
                else:
                    self.main.exitError("modRMOperands: mod==3; regSize {0:d} not in (misc.OP_SIZE_BYTE, misc.OP_SIZE_WORD, misc.OP_SIZE_DWORD)", regSize)
            else:
                self.main.exitError("modRMOperands: mod not in (0,1,2)")
        elif (self.segments.getAddrSegSize(CPU_SEGMENT_CS) == misc.OP_SIZE_DWORD):
            if (mod in (0, 1, 2)): # rm: source ; reg: dest
                if (rm == 0):
                    rmValue0 = CPU_REGISTER_EAX
                elif (rm == 1):
                    rmValue0 = CPU_REGISTER_ECX
                elif (rm == 2):
                    rmValue0 = CPU_REGISTER_EDX
                elif (rm == 3):
                    rmValue0 = CPU_REGISTER_EBX
                elif (rm == 4): # SIB
                    rmValue0, rmValueSegId, rmValue2 = self.sibOperands(mod)
                elif (rm == 5):
                    if (mod == 0):
                        rmValue2 = self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_DWORD)
                    else:
                        rmValue0 = CPU_REGISTER_EBP
                        rmValueSegId = CPU_SEGMENT_SS
                elif (rm == 6):
                    rmValue0 = CPU_REGISTER_ESI
                elif (rm == 7):
                    rmValue0 = CPU_REGISTER_EDI
                if (mod == 1):
                    rmValue2 += self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_BYTE, signed=True)
                elif (mod == 2):
                    rmValue2 += self.cpu.getCurrentOpcodeAdd(numBytes=misc.OP_SIZE_DWORD, signed=True)
                
                regValue  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
                
            elif (mod == 3): # reg: source ; rm: dest
                regValue  = self.getRegValueWithFlags(modRMflags, reg, regSize) # source
                if (regSize == misc.OP_SIZE_BYTE):
                    rmValue0  = CPU_REGISTER_BYTE[rm] # dest
                elif (regSize == misc.OP_SIZE_WORD):
                    rmValue0  = CPU_REGISTER_WORD[rm] # dest
                elif (regSize == misc.OP_SIZE_DWORD):
                    rmValue0  = CPU_REGISTER_DWORD[rm] # dest
                else:
                    self.main.exitError("modRMOperands: mod==3; regSize {0:d} not in (misc.OP_SIZE_BYTE, misc.OP_SIZE_WORD, misc.OP_SIZE_DWORD)", regSize)
            else:
                self.main.exitError("modRMOperands: mod not in (0,1,2)")
        else:
            self.main.exitError("modRMOperands: AddrSegSize(CS) not in (misc.OP_SIZE_WORD, misc.OP_SIZE_DWORD)")
        return mod, ((rmValue0, rmValue1, rmValue2), rmValueSegId), regValue
    def modRMOperandsResetEip(self, unsigned char regSize, unsigned char modRMflags=0):
        oldEip = self.regRead( CPU_REGISTER_EIP )
        rmOperands = self.modRMOperands(regSize, modRMflags=modRMflags)
        self.regWrite( CPU_REGISTER_EIP, oldEip )
        return rmOperands
    def getCond(self, unsigned char index):
        if (index == 0x0): # O
            return (self.getEFLAG( FLAG_OF ))
        elif (index == 0x1): # NO
            return (not self.getEFLAG( FLAG_OF ))
        elif (index == 0x2): # C
            return (self.getEFLAG( FLAG_CF ))
        elif (index == 0x3): # NC
            return (not self.getEFLAG( FLAG_CF ))
        elif (index == 0x4): # E
            return (self.getEFLAG( FLAG_ZF ))
        elif (index == 0x5): # NE
            return (not self.getEFLAG( FLAG_ZF ))
        elif (index == 0x6): # NA
            return ((self.getEFLAG( FLAG_CF )) or (self.getEFLAG( FLAG_ZF )))
        elif (index == 0x7): # A
            return ((not self.getEFLAG( FLAG_CF )) and (not self.getEFLAG( FLAG_ZF )))
        elif (index == 0x8): # S
            return (self.getEFLAG( FLAG_SF ))
        elif (index == 0x9): # NS
            return (not self.getEFLAG( FLAG_SF ))
        elif (index == 0xa): # P
            return (self.getEFLAG( FLAG_PF ))
        elif (index == 0xb): # NP
            return (not self.getEFLAG( FLAG_PF ))
        elif (index == 0xc): # L
            return ((self.getEFLAG( FLAG_SF )) != (self.getEFLAG( FLAG_OF )))
        elif (index == 0xd): # GE
            return ((self.getEFLAG( FLAG_SF )) == (self.getEFLAG( FLAG_OF )))
        elif (index == 0xe): # LE
            return ((self.getEFLAG( FLAG_ZF )) or ((self.getEFLAG( FLAG_SF )) != (self.getEFLAG( FLAG_OF ))) )
        elif (index == 0xf): # G
            return ((not self.getEFLAG( FLAG_ZF )) and ((self.getEFLAG( FLAG_SF )) == (self.getEFLAG( FLAG_OF ))) )
        else:
            self.main.exitError("getCond: index {0:#x} invalid.", index)
    def setFullFlags(self, long long reg0, long long reg1, unsigned char regSize, unsigned char method, unsigned char signed=False): # regSize in bits
        cdef unsigned char unsignedOverflow, signedOverflow, isResZero, afFlag, reg0Nibble, reg1Nibble, regSumNibble
        cdef unsigned long bitMask, bitMaskHalf
        cdef unsigned long long doubleBitMask, regSumu, regSumMasked, regSumuMasked
        cdef long long regSum
        unsignedOverflow = False
        signedOverflow = False
        isResZero = False
        afFlag = False
        bitMask = self.main.misc.getBitMask(regSize)
        bitMaskHalf = self.main.misc.getBitMask(regSize, half=True, minus=0)
        
        if (method == misc.SET_FLAGS_ADD):
            regSum = reg0+reg1
            regSumMasked = regSum&bitMask
            isResZero = regSumMasked==0
            unsignedOverflow = (regSumMasked < reg0 or regSumMasked < reg1)
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setEFLAG(FLAG_ZF, isResZero)
            reg0Nibble = reg0&0xf
            reg1Nibble = reg1&0xf
            regSumNibble = regSum&0xf
            if ( (((reg0Nibble)+(reg1Nibble))>regSumNibble) or reg0>bitMask or reg1>bitMask):
                afFlag = True
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSum &= bitMaskHalf
            signedOverflow = ( ((not reg0 and not reg1) and regSum) or ((reg0 and reg1) and not regSum) )!=False
            self.setEFLAG(FLAG_AF, afFlag)
            self.setEFLAG(FLAG_CF, unsignedOverflow)
            self.setEFLAG(FLAG_OF, ((not isResZero) and signedOverflow))
            self.setEFLAG(FLAG_SF, regSum!=0)
        elif (method == misc.SET_FLAGS_SUB):
            regSum = reg0-reg1
            regSumMasked = regSum&bitMask
            isResZero = regSumMasked==0
            unsignedOverflow = ( regSum<0 )
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setEFLAG(FLAG_ZF, isResZero)
            reg0Nibble = reg0&0xf
            reg1Nibble = reg1&0xf
            regSumNibble = regSum&0xf
            if ( ((reg0Nibble-reg1Nibble) < regSumNibble) and reg1!=0):
                afFlag = True
            reg0 &= bitMaskHalf
            reg1 &= bitMaskHalf
            regSum &= bitMaskHalf
            signedOverflow = ( ((reg0 and not reg1) and not regSum) or ((not reg0 and reg1) and regSum) )!=False
            self.setEFLAG(FLAG_AF, afFlag)
            self.setEFLAG(FLAG_CF, unsignedOverflow )
            self.setEFLAG(FLAG_OF, (not isResZero and signedOverflow))
            self.setEFLAG(FLAG_SF, regSum!=0)
        elif (method == misc.SET_FLAGS_MUL):
            doubleBitMask = self.main.misc.getBitMask(regSize*2)
            ##doubleBitMaskHalf = self.main.misc.getBitMask(regSize*2, half=True, minus=0)
            regSum = reg0*reg1
            reg0 = (reg0 < 0 and -reg0) or reg0
            reg1 = (reg1 < 0 and -reg1) or reg1
            regSumu = reg0*reg1
            regSumMasked = regSum&doubleBitMask
            regSumuMasked = regSumu&doubleBitMask
            isResZero = regSumMasked==0
            if ((signed and ((regSize != misc.OP_SIZE_BYTE and regSumu <= bitMask) or (regSize == misc.OP_SIZE_BYTE and regSumu <= 0x7f))) or \
                   (not signed and ((regSumu <= bitMask)))):
                self.setEFLAG(FLAG_CF, False)
                self.setEFLAG(FLAG_OF, False)
            else:
                self.setEFLAG(FLAG_CF, True)
                self.setEFLAG(FLAG_OF, True)
            self.setEFLAG(FLAG_PF, PARITY_TABLE[regSum&0xff])
            self.setEFLAG(FLAG_ZF, isResZero)
            self.setEFLAG(FLAG_SF, (regSum&bitMaskHalf)!=0)
        elif (method == misc.SET_FLAGS_DIV):
            pass
        else:
            self.main.exitError("setFullFlags: method not (add, sub, mul or div). (method: {0:d})", method)
    def checkMemAccessRights(self, unsigned short segId, unsigned char write):
        if (not self.cpu.isInProtectedMode()):
            return
        cdef unsigned short segVal = self.segRead(segId)
        if (not self.segments.gdt.isSegPresent(segVal) ):
            if (segId == CPU_SEGMENT_SS):
                raise misc.ChemuException(misc.CPU_EXCEPTION_SS, segVal)
            else:
                raise misc.ChemuException(misc.CPU_EXCEPTION_NP, segVal)
        if ( segVal == 0 ):
            if (segId == CPU_SEGMENT_SS):
                raise misc.ChemuException(misc.CPU_EXCEPTION_SS, segVal)
            else:
                raise misc.ChemuException(misc.CPU_EXCEPTION_GP, segVal)
        if (write):
            if (self.segments.gdt.isCodeSeg(segVal) or not self.segments.gdt.isSegReadableWritable(segVal) ):
                if (segId == CPU_SEGMENT_SS):
                    raise misc.ChemuException(misc.CPU_EXCEPTION_SS, segVal)
                else:
                    raise misc.ChemuException(misc.CPU_EXCEPTION_GP, segVal)
        else:
            if (self.segments.gdt.isCodeSeg(segVal) and not self.segments.gdt.isSegReadableWritable(segVal) ):
                raise misc.ChemuException(misc.CPU_EXCEPTION_GP, segVal)
    


