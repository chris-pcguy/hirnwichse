
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"
include "cpu_globals.pxi"

from misc import HirnwichseException


cdef class Segment:
    def __init__(self, Segments segments, unsigned short segId):
        self.segments = segments
        self.segId = segId
        self.isValid = True
        self.segSize = OP_SIZE_WORD
        self.base = self.segmentIndex = self.useGDT = 0
    cdef void loadSegment(self, unsigned short segmentIndex, unsigned char protectedModeOn):
        cdef GdtEntry gdtEntry
        self.segmentIndex = segmentIndex
        if (not protectedModeOn):
            self.base = <unsigned int>segmentIndex<<4
            #self.limit = 0xffff
            self.isValid = True
            self.useGDT = False
            self.segSize = OP_SIZE_WORD
            self.segPresent = True
            self.segIsRW = True
            return
        gdtEntry = self.segments.getEntry(segmentIndex)
        if (gdtEntry is None):
            self.isValid = False
            self.useGDT = True
            return
        self.useGDT = True
        self.base = gdtEntry.base
        self.limit = gdtEntry.limit
        self.accessByte = gdtEntry.accessByte
        self.flags = gdtEntry.flags
        self.segSize = gdtEntry.segSize
        self.isValid = True
        self.segPresent = gdtEntry.segPresent
        self.segIsCodeSeg = gdtEntry.segIsCodeSeg
        self.segIsRW = gdtEntry.segIsRW
        self.segIsConforming = gdtEntry.segIsConforming
        self.segIsNormal = gdtEntry.segIsNormal
        self.segUse4K = gdtEntry.segUse4K
        self.segDPL = gdtEntry.segDPL
    cdef unsigned char isCodeSeg(self):
        return self.segIsCodeSeg
    ### isSegReadableWritable:
    ### if codeseg, return True if readable, else False
    ### if dataseg, return True if writable, else False
    cdef unsigned char isSegReadableWritable(self):
        return self.segIsRW
    cdef unsigned char isSysSeg(self):
        return (not self.segIsNormal)
    cdef unsigned char isSegConforming(self):
        return self.segIsConforming
    cdef unsigned char getSegDPL(self):
        return self.segDPL
    cdef unsigned char isAddressInLimit(self, unsigned int address, unsigned int size): # TODO: copied from GdtEntry::isAddressInLimit until a better solution is found... so never.
        cdef unsigned int limit
        limit = self.limit
        if (self.segUse4K):
            limit <<= 12
        # TODO: handle the direction bit here.
        ## address is an offset.
        if (not self.segIsCodeSeg and self.segIsConforming):
            self.gdt.segments.main.exitError("GdtEntry::isAddressInLimit: direction-bit ISN'T supported yet.")
        if ((address+size)>limit):
            return False
        return True


cdef class GdtEntry:
    def __init__(self, Gdt gdt, unsigned long int entryData):
        self.gdt = gdt
        self.parseEntryData(entryData)
    cdef void parseEntryData(self, unsigned long int entryData):
        self.accessByte = <unsigned char>(entryData>>40)
        self.flags  = (entryData>>52)&0xf
        self.base  = (entryData>>16)&0xffffff
        self.limit = entryData&0xffff
        self.base  |= (<unsigned char>(entryData>>56))<<24
        self.limit |= ((entryData>>48)&0xf)<<16
        # segment size: 1==32bit; 0==16bit; segSize is 4 for 32bit and 2 for 16bit
        self.segSize = OP_SIZE_DWORD if (self.flags & GDT_FLAG_SIZE) else OP_SIZE_WORD
        self.segPresent = (self.accessByte & GDT_ACCESS_PRESENT)!=0
        self.segIsCodeSeg = (self.accessByte & GDT_ACCESS_EXECUTABLE)!=0
        self.segIsRW = (self.accessByte & GDT_ACCESS_READABLE_WRITABLE)!=0
        self.segIsConforming = (self.accessByte & GDT_ACCESS_CONFORMING)!=0
        self.segIsNormal = (self.accessByte & GDT_ACCESS_NORMAL_SEGMENT)!=0
        self.segUse4K = (self.flags & GDT_FLAG_USE_4K)!=0
        self.segDPL = ((self.accessByte & GDT_ACCESS_DPL)>>5)&3
        if (self.flags & GDT_FLAG_LONGMODE): # TODO: int-mode isn't implemented yet...
            self.gdt.segments.main.exitError("Did you just tried to use int-mode?!? Maybe I'll implement it in a few decades...")
    cdef unsigned char isAddressInLimit(self, unsigned int address, unsigned int size):
        cdef unsigned int limit
        limit = self.limit
        if (self.segUse4K):
            limit <<= 12
        # TODO: handle the direction bit here.
        ## address is an offset.
        if (not self.segIsCodeSeg and self.segIsConforming):
            self.gdt.segments.main.exitError("GdtEntry::isAddressInLimit: direction-bit ISN'T supported yet.")
        if ((address+size)>limit):
            return False
        return True

cdef class IdtEntry:
    def __init__(self, unsigned long int entryData):
        self.parseEntryData(entryData)
    cdef void parseEntryData(self, unsigned long int entryData):
        self.entryEip = entryData&0xffff # interrupt eip: lower word
        self.entryEip |= ((entryData>>48)&0xffff)<<16 # interrupt eip: upper word
        self.entrySegment = (entryData>>16)&0xffff # interrupt segment
        self.entryType = (entryData>>40)&0xf # interrupt type
        self.entryNeededDPL = (entryData>>45)&0x3 # interrupt: Need this DPL
        self.entryPresent = (entryData>>47)&1 # is interrupt present
        self.entrySize = OP_SIZE_DWORD if (self.entryType in (TABLE_ENTRY_SYSTEM_TYPE_LDT, TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE, \
          TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY, \
          TABLE_ENTRY_SYSTEM_TYPE_32BIT_CALL_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE, \
          TABLE_ENTRY_SYSTEM_TYPE_32BIT_TRAP_GATE)) else OP_SIZE_WORD


cdef class Gdt:
    def __init__(self, Segments segments):
        self.segments = segments
        self.tableBase = self.tableLimit = 0
    cdef void loadTablePosition(self, unsigned int tableBase, unsigned short tableLimit):
        if (tableLimit > GDT_HARD_LIMIT):
            self.segments.main.exitError("Gdt::loadTablePosition: tableLimit {0:#06x} > GDT_HARD_LIMIT {1:#06x}.", \
              tableLimit, GDT_HARD_LIMIT)
            return
        self.tableBase, self.tableLimit = tableBase, tableLimit
        #self.segments.main.debug("Gdt::loadTablePosition: tableBase: {0:#010x}; tableLimit: {1:#06x}", self.tableBase, self.tableLimit)
    cdef GdtEntry getEntry(self, unsigned short num):
        cdef unsigned long int entryData
        num &= 0xfff8
        if (not num):
            ##self.segments.main.debug("GDT::getEntry: num == 0!")
            return None
        #self.segments.main.debug("Gdt::getEntry: tableBase=={0:#010x}; tableLimit=={1:#06x}; num=={2:#06x}", self.tableBase, self.tableLimit, num)
        entryData = self.tableBase+num
        entryData = self.segments.registers.mmReadValueUnsignedQword(entryData, None, False)
        return GdtEntry(self, entryData)
    cdef unsigned char getSegType(self, unsigned short num):
        num &= 0xfff8
        return (self.segments.registers.mmReadValueUnsignedByte(self.tableBase+num+5, None, False) & TABLE_ENTRY_SYSTEM_TYPE_MASK)
    cdef void setSegType(self, unsigned short num, unsigned char segmentType):
        num &= 0xfff8
        self.segments.registers.mmWriteValue(self.tableBase+num+5, <unsigned char>((self.segments.registers.\
          mmReadValueUnsignedByte(self.tableBase+num+5, None, False) & (~TABLE_ENTRY_SYSTEM_TYPE_MASK)) | \
            (segmentType & TABLE_ENTRY_SYSTEM_TYPE_MASK)), OP_SIZE_BYTE, None, False)
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment):
        cdef unsigned char cpl
        cdef GdtEntry gdtEntry
        if (not (num&0xfff8) or num > self.tableLimit):
            self.segments.main.notice("Gdt::checkAccessAllowed: test1")
            if (not (num&0xfff8)):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            else:
                raise HirnwichseException(CPU_EXCEPTION_GP, num)
        #cpl = self.segments.cs.segmentIndex&3
        cpl = self.segments.registers.cpl
        gdtEntry = self.getEntry(num)
        if (not gdtEntry or (isStackSegment and ( num&3 != cpl or \
          gdtEntry.segDPL != cpl))):# or 0):
            self.segments.main.notice("Gdt::checkAccessAllowed: test2")
            raise HirnwichseException(CPU_EXCEPTION_GP, num)
        elif (not gdtEntry.segPresent):
            self.segments.main.notice("Gdt::checkAccessAllowed: test3")
            if (isStackSegment):
                raise HirnwichseException(CPU_EXCEPTION_SS, num)
            else:
                raise HirnwichseException(CPU_EXCEPTION_NP, num)
        return True
    cdef unsigned char checkReadAllowed(self, unsigned short num): # for VERR
        cdef unsigned char rpl
        cdef GdtEntry gdtEntry
        rpl = num&3
        num &= 0xfff8
        if (num == 0 or num > self.tableLimit):
            return False
        gdtEntry = self.getEntry(num)
        if (not gdtEntry):
            return False
        if (((self.getSegType(num) == 0) or not gdtEntry.segIsConforming) and \
          ((self.segments.registers.cpl > gdtEntry.segDPL) or (rpl > gdtEntry.segDPL))):
            return False
        if (gdtEntry.segIsCodeSeg and not gdtEntry.segIsRW):
            return False
        return True
    cdef unsigned char checkWriteAllowed(self, unsigned short num): # for VERW
        cdef unsigned char rpl
        cdef GdtEntry gdtEntry
        rpl = num&3
        num &= 0xfff8
        if (num == 0 or num > self.tableLimit):
            return False
        gdtEntry = self.getEntry(num)
        if (not gdtEntry):
            return False
        if (((self.getSegType(num) == 0) or not gdtEntry.segIsConforming) and \
          ((self.segments.registers.cpl > gdtEntry.segDPL) or (rpl > gdtEntry.segDPL))):
            return False
        if (not gdtEntry.segIsCodeSeg and gdtEntry.segIsRW):
            return True
        return False
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned short segId):
        cdef unsigned char numSegDPL, cpl
        cdef GdtEntry gdtEntry
        if ((num&0xfff8) > self.tableLimit):
            self.segments.main.notice("test1: segId=={0:#04d}, num=={1:#06x}, tableLimit=={2:#06x}", segId, num, self.tableLimit)
            raise HirnwichseException(CPU_EXCEPTION_GP, num)
        if (not (num&0xfff8)):
            if (segId == CPU_SEGMENT_CS or segId == CPU_SEGMENT_SS):
                self.segments.main.notice("test4: segId=={0:#04d}, num=={1:#06x}, tableLimit=={2:#06x}, EIP: {3:#010x}, CS: {4:#06x}", segId, num, self.tableLimit, self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            return False
        gdtEntry = self.getEntry(num)
        if (not gdtEntry or not gdtEntry.segPresent):
            if (segId == CPU_SEGMENT_SS):
                raise HirnwichseException(CPU_EXCEPTION_SS, num)
            raise HirnwichseException(CPU_EXCEPTION_NP, num)
        #cpl = self.segments.cs.segmentIndex&3
        cpl = self.segments.registers.cpl
        numSegDPL = gdtEntry.segDPL
        if (segId == CPU_SEGMENT_TSS): # TODO?
            return True
        if (segId == CPU_SEGMENT_SS): # TODO: TODO!
            ##if ((num&3 != cpl or numSegDPL != cpl) or \
            if (((gdtEntry.segIsCodeSeg) or (not gdtEntry.segIsCodeSeg and not gdtEntry.segIsRW))):
                self.segments.main.notice("test2: segId=={0:#04x}, num {1:#06x}, numSegDPL {2:d}, cpl {3:d}", segId, num, numSegDPL, cpl)
                raise HirnwichseException(CPU_EXCEPTION_GP, num)
        else: # not stack segment
            if ( ((not gdtEntry.segIsCodeSeg or not gdtEntry.segIsConforming) and (num&3 > numSegDPL and \
              cpl > numSegDPL)) or (gdtEntry.segIsCodeSeg and not gdtEntry.segIsRW) ):
                self.segments.main.notice("test3: segId=={0:#04d}", segId)
                raise HirnwichseException(CPU_EXCEPTION_GP, num)
        return True


cdef class Idt:
    def __init__(self, Segments segments):
        self.segments = segments
        self.tableBase = self.tableLimit = 0
    cdef void loadTable(self, unsigned int tableBase, unsigned short tableLimit):
        if (tableLimit > IDT_HARD_LIMIT):
            self.segments.main.exitError("Idt::loadTablePosition: tableLimit {0:#06x} > IDT_HARD_LIMIT {1:#06x}.",\
              tableLimit, IDT_HARD_LIMIT)
            return
        self.tableBase, self.tableLimit = tableBase, tableLimit
    cdef IdtEntry getEntry(self, unsigned char num):
        cdef unsigned long int address
        cdef IdtEntry idtEntry
        if (not self.tableLimit):
            self.segments.main.notice("Idt::getEntry: tableLimit is zero.")
        address = self.tableBase+(num<<3)
        address = self.segments.registers.mmReadValueUnsignedQword(address, None, False)
        idtEntry = IdtEntry(address)
        if (idtEntry.entryType in (TABLE_ENTRY_SYSTEM_TYPE_LDT, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY)):
            self.segments.main.notice("Idt::getEntry: entryType is LDT or TSS. (is this allowed?)")
        return idtEntry
    cdef unsigned char isEntryPresent(self, unsigned char num):
        return self.getEntry(num).entryPresent
    cdef unsigned char getEntryNeededDPL(self, unsigned char num):
        return self.getEntry(num).entryNeededDPL
    cdef unsigned char getEntrySize(self, unsigned char num):
        # interrupt size: 1==32bit==return 4; 0==16bit==return 2
        return self.getEntry(num).entrySize
    cdef void getEntryRealMode(self, unsigned char num, unsigned short *entrySegment, unsigned short *entryEip):
        cdef unsigned short offset
        offset = num<<2 # Don't use ConfigSpace here.
        entryEip[0] = self.segments.main.mm.mmPhyReadValueUnsignedWord(offset)
        entrySegment[0] = self.segments.main.mm.mmPhyReadValueUnsignedWord(offset+2)




cdef class Paging: # TODO
    def __init__(self, Segments segments):
        self.instrFetch = False
        self.segments = segments
        self.pageDirectoryBaseAddress = self.pageDirectoryOffset = self.pageTableOffset = self.pageDirectoryEntry = self.pageTableEntry = 0
    cdef void invalidateTables(self, unsigned int pageDirectoryBaseAddress):
        self.pageDirectoryBaseAddress = (pageDirectoryBaseAddress&0xfffff000)
    cdef unsigned char doPF(self, unsigned int virtualAddress, unsigned char written) except -1:
        cdef unsigned int errorFlags
        errorFlags = ((self.pageDirectoryEntry & PAGE_PRESENT) and (self.pageTableEntry & PAGE_PRESENT)) != 0
        errorFlags |= written << 1
        errorFlags |= (self.segments.registers.cpl == 3) << 2
        # TODO: reserved bits are set ; only with 4MB pages ; << 3
        errorFlags |= self.instrFetch << 4
        self.segments.main.debugEnabled = True
        self.segments.main.notice("Paging::doPF: savedEip=={0:#010x}; savedCs=={1:#06x}", self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
        self.segments.main.notice("Paging::doPF: virtualAddress=={0:#010x}; errorFlags=={1:#04x}", virtualAddress, errorFlags)
        self.segments.registers.regWriteDword(CPU_REGISTER_CR2, virtualAddress)
        self.segments.main.notice("Paging::doPF: test2")
        raise HirnwichseException(CPU_EXCEPTION_PF, errorFlags)
        #return 0
    cdef unsigned char readAddresses(self, unsigned int virtualAddress, unsigned char written) except -1:
        #self.segments.main.notice("Paging::readAddresses: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
        self.pageDirectoryOffset = (virtualAddress>>22) << 2
        self.pageTableOffset = ((virtualAddress>>12)&0x3ff) << 2
        self.pageOffset = virtualAddress&0xfff
        self.pageDirectoryEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|self.pageDirectoryOffset) # page directory
        if (not (self.pageDirectoryEntry & PAGE_PRESENT)):
            self.segments.main.notice("Paging::readAddresses: PDE-Entry is not present. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageDirectoryEntry, self.pageDirectoryBaseAddress|self.pageDirectoryOffset, virtualAddress)
            self.doPF(virtualAddress, written)
            return False
        elif (self.pageDirectoryEntry & PAGE_SIZE): # it's a 4MB page
            # size is 4MB if CR4/PSE is set
            # size is 2MB if CR4/PAE is set
            # I don't know which size is used if both, CR4/PSE && CR4/PAE, are set
            self.segments.main.exitError("Paging::readAddresses: 4MB pages are UNSUPPORTED yet.")
            return False
        self.pageTableEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword((self.pageDirectoryEntry&0xfffff000)|self.pageTableOffset) # page table
        if (not (self.pageTableEntry & PAGE_PRESENT)):
            self.segments.main.notice("Paging::readAddresses: PTE-Entry is not present. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageTableEntry, (self.pageDirectoryEntry&0xfffff000)|self.pageTableOffset, virtualAddress)
            self.doPF(virtualAddress, written)
            return False
        return True
    cdef unsigned char writeAccessAllowed(self, unsigned int virtualAddress, unsigned char refresh) except -1:
        if (refresh):
            self.readAddresses(virtualAddress, True)
        if (self.pageDirectoryEntry&PAGE_WRITABLE and self.pageTableEntry&PAGE_WRITABLE):
            return True
        return False
    cdef unsigned char everyRingAccessAllowed(self, unsigned int virtualAddress, unsigned char refresh) except -1:
        if (refresh):
            self.readAddresses(virtualAddress, False)
        if (self.pageDirectoryEntry&PAGE_EVERY_RING and self.pageTableEntry&PAGE_EVERY_RING):
            return True
        return False
    cdef unsigned char setFlags(self, unsigned int virtualAddress, unsigned int dataSize, unsigned char written) except -1:
        cdef unsigned int pageDirectoryOffset, pageTableOffset, pageDirectoryEntry, pageTableEntry
        # TODO: for now only handling 4KB pages. (very inefficient)
        if (not dataSize):
            return True
        while (dataSize > 0):
            pageDirectoryOffset = (virtualAddress>>22) << 2
            pageTableOffset = ((virtualAddress>>12)&0x3ff) << 2
            pageDirectoryEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|pageDirectoryOffset) # page directory
            pageTableEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntry&0xfffff000)|pageTableOffset) # page table
            if ((pageDirectoryEntry & PAGE_PRESENT) and (pageTableEntry & PAGE_PRESENT)):
                #self.segments.main.debug("Paging::setFlags: test3: pdo addr {0:#010x}; pto addr {1:#010x}", (self.pageDirectoryBaseAddress|pageDirectoryOffset), ((pageDirectoryEntry&0xfffff000)|pageTableOffset))
                #self.segments.main.debug("Paging::setFlags: test4: pdo {0:#010x}; pto {1:#010x}", pageDirectoryEntry, pageTableEntry)
                #self.segments.main.debug("Paging::setFlags: test5: pdo {0:#010x}; pto {1:#010x}", self.segments.main.mm.mmPhyReadValueUnsignedDword((self.pageDirectoryBaseAddress|pageDirectoryOffset)), self.segments.main.mm.mmPhyReadValueUnsignedDword(((pageDirectoryEntry&0xfffff000)|pageTableOffset)))
                pageDirectoryEntry |= (PAGE_WAS_USED | (((pageDirectoryEntry & PAGE_SIZE) and written) and PAGE_WRITTEN_ON_PAGE))
                pageTableEntry |= (PAGE_WAS_USED | (written and PAGE_WRITTEN_ON_PAGE))
                self.segments.main.mm.mmPhyWriteValue(self.pageDirectoryBaseAddress|pageDirectoryOffset, pageDirectoryEntry, OP_SIZE_DWORD) # page directory
                self.segments.main.mm.mmPhyWriteValue(((pageDirectoryEntry&0xfffff000)|pageTableOffset), pageTableEntry, OP_SIZE_DWORD) # page table
                #self.segments.main.debug("Paging::setFlags: test6: pdo {0:#010x}; pto {1:#010x}", self.segments.main.mm.mmPhyReadValueUnsignedDword((self.pageDirectoryBaseAddress|pageDirectoryOffset)), self.segments.main.mm.mmPhyReadValueUnsignedDword(((pageDirectoryEntry&0xfffff000)|pageTableOffset)))
            if (dataSize <= PAGE_DIRECTORY_LENGTH):
                break
            virtualAddress += PAGE_DIRECTORY_LENGTH
            dataSize -= PAGE_DIRECTORY_LENGTH
        return True
    cdef unsigned int getPhysicalAddress(self, unsigned int virtualAddress, unsigned int dataSize, unsigned char written) except? 0:
        cdef unsigned char cpl, writable, everyRing
        self.readAddresses(virtualAddress, written)
        self.instrFetch = False
        cpl = self.segments.registers.getCPL()
        writable = self.writeAccessAllowed(virtualAddress, False)
        everyRing = self.everyRingAccessAllowed(virtualAddress, False)
        if (self.segments.registers.writeProtectionOn and written and not writable):
            self.segments.main.debug("Paging::getPhysicalAddress: address is not accessable: test1. (virtualAddress: {0:#010x})", virtualAddress)
            self.doPF(virtualAddress, written)
            return 0
        elif (cpl == 3 and (not everyRing or (written and not writable))):
            self.segments.main.debug("Paging::getPhysicalAddress: address is not accessable: test2. (virtualAddress: {0:#010x})", virtualAddress)
            self.doPF(virtualAddress, written)
            return 0
        self.setFlags(virtualAddress, dataSize, written)
        return (self.pageTableEntry&0xfffff000)|self.pageOffset

cdef class Segments:
    def __init__(self, Registers registers, Hirnwichse main):
        self.registers = registers
        self.main = main
    cdef void reset(self):
        self.ldtr = 0
    cdef Segment getSegment(self, unsigned short segmentId, unsigned char checkForValidness):
        cdef Segment segment
        segment = self.segs[segmentId]
        if (checkForValidness and not segment.isValid):
            self.main.notice("Segments::getSegment: segment with ID {0:d} isn't valid.", segmentId)
            raise HirnwichseException(CPU_EXCEPTION_GP, segment.segmentIndex)
        return segment
    cdef GdtEntry getEntry(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return <GdtEntry>self.ldt.getEntry(num)
        return <GdtEntry>self.gdt.getEntry(num)
    cdef unsigned char isCodeSeg(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.isCodeSeg(num)
        return self.gdt.isCodeSeg(num)
    cdef unsigned char isSegReadableWritable(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.isSegReadableWritable(num)
        return self.gdt.isSegReadableWritable(num)
    cdef unsigned char isSegConforming(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.isSegConforming(num)
        return self.gdt.isSegConforming(num)
    cdef unsigned char isSegPresent(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.isSegPresent(num)
        return self.gdt.isSegPresent(num)
    cdef unsigned char getSegDPL(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.getSegDPL(num)
        return self.gdt.getSegDPL(num)
    cdef unsigned char getSegType(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.getSegType(num)
        return self.gdt.getSegType(num)
    cdef void setSegType(self, unsigned short num, unsigned char segmentType):
        if (num & SELECTOR_USE_LDT):
            self.ldt.setSegType(num, segmentType)
            return
        self.gdt.setSegType(num, segmentType)
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkAccessAllowed(num, isStackSegment)
        return self.gdt.checkAccessAllowed(num, isStackSegment)
    cdef unsigned char checkReadAllowed(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkReadAllowed(num)
        return self.gdt.checkReadAllowed(num)
    cdef unsigned char checkWriteAllowed(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkWriteAllowed(num)
        return self.gdt.checkWriteAllowed(num)
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned short segId):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkSegmentLoadAllowed(num, segId)
        return self.gdt.checkSegmentLoadAllowed(num, segId)
    cdef unsigned char inLimit(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return ((num&0xfff8) <= self.ldt.tableLimit)
        return ((num&0xfff8) <= self.gdt.tableLimit)
    cdef void run(self):
        self.gdt = Gdt(self)
        self.ldt = Gdt(self)
        self.idt = Idt(self)
        self.paging = Paging(self)
        self.cs = Segment(self, CPU_SEGMENT_CS)
        self.ss = Segment(self, CPU_SEGMENT_SS)
        self.ds = Segment(self, CPU_SEGMENT_DS)
        self.es = Segment(self, CPU_SEGMENT_ES)
        self.fs = Segment(self, CPU_SEGMENT_FS)
        self.gs = Segment(self, CPU_SEGMENT_GS)
        self.tss = Segment(self, CPU_SEGMENT_TSS)
        self.segs = (None, self.cs, self.ss, self.ds, self.es, self.fs, self.gs, self.tss)



