
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"
include "cpu_globals.pxi"

from cpu import HirnwichseException


cdef class Gdt:
    def __init__(self, Segments segments):
        self.segments = segments
        self.tableBase = self.tableLimit = 0
    cdef void loadTablePosition(self, uint32_t tableBase, uint16_t tableLimit):
        if (tableLimit > GDT_HARD_LIMIT):
            self.segments.main.exitError("Gdt::loadTablePosition: tableLimit {0:#06x} > GDT_HARD_LIMIT {1:#06x}.", tableLimit, GDT_HARD_LIMIT)
            return
        self.tableBase, self.tableLimit = tableBase, tableLimit
        #self.segments.main.debug("Gdt::loadTablePosition: tableBase: {0:#010x}; tableLimit: {1:#06x}", self.tableBase, self.tableLimit)
    cdef uint8_t getEntry(self, GdtEntry *gdtEntry, uint16_t num) except BITMASK_BYTE_CONST:
        cdef uint64_t entryData
        self.segments.paging.implicitSV = True
        num &= 0xfff8
        if (not num):
            ##self.segments.main.debug("GDT::getEntry: num == 0!")
            return False
        #self.segments.main.debug("Gdt::getEntry: tableBase=={0:#010x}; tableLimit=={1:#06x}; num=={2:#06x}", self.tableBase, self.tableLimit, num)
        entryData = self.tableBase+num
        entryData = self.segments.registers.mmReadValueUnsignedQword(entryData, NULL, False)
        self.segments.parseGdtEntryData(gdtEntry, entryData)
        return True
    cdef uint8_t getSegType(self, uint16_t num) except? BITMASK_BYTE_CONST: # access byte
        self.segments.paging.implicitSV = True
        num &= 0xfff8
        return (self.segments.registers.mmReadValueUnsignedByte(self.tableBase+num+5, NULL, False) & TABLE_ENTRY_SYSTEM_TYPE_MASK)
    cdef uint8_t setSegType(self, uint16_t num, uint8_t segmentType) except BITMASK_BYTE_CONST: # access byte
        self.segments.paging.implicitSV = True
        num &= 0xfff8
        return self.segments.registers.mmWriteValue(self.tableBase+num+5, <uint8_t>((self.segments.registers.\
          mmReadValueUnsignedByte(self.tableBase+num+5, NULL, False) & (~TABLE_ENTRY_SYSTEM_TYPE_MASK)) | \
            (segmentType & TABLE_ENTRY_SYSTEM_TYPE_MASK)), OP_SIZE_BYTE, NULL, False)
    cdef uint8_t checkAccessAllowed(self, uint16_t num, uint8_t isStackSegment) except BITMASK_BYTE_CONST:
        cdef uint8_t cpl
        cdef GdtEntry gdtEntry
        if (not (num&0xfff8) or num > self.tableLimit):
            #self.segments.main.notice("Gdt::checkAccessAllowed: test1")
            if (not (num&0xfff8)):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            else:
                raise HirnwichseException(CPU_EXCEPTION_GP, num)
        #cpl = self.segments.cs.segmentIndex&3
        cpl = self.segments.registers.getCPL()
        if (not self.getEntry(&gdtEntry, num) or (isStackSegment and ( num&3 != cpl or \
          gdtEntry.segDPL != cpl))):# or 0):
            #self.segments.main.notice("Gdt::checkAccessAllowed: test2")
            raise HirnwichseException(CPU_EXCEPTION_GP, num)
        elif (not gdtEntry.segPresent):
            #self.segments.main.notice("Gdt::checkAccessAllowed: test3")
            if (isStackSegment):
                raise HirnwichseException(CPU_EXCEPTION_SS, num)
            else:
                raise HirnwichseException(CPU_EXCEPTION_NP, num)
        return True
    cdef uint8_t checkReadAllowed(self, uint16_t num) except BITMASK_BYTE_CONST: # for VERR
        cdef uint8_t rpl
        cdef GdtEntry gdtEntry
        rpl = num&3
        num &= 0xfff8
        if (num == 0 or num > self.tableLimit):
            return False
        if (not self.getEntry(&gdtEntry, num)):
            return False
        if (((self.getSegType(num) == 0) or not gdtEntry.segIsConforming) and \
          ((self.segments.registers.getCPL() > gdtEntry.segDPL) or (rpl > gdtEntry.segDPL))):
            return False
        if (gdtEntry.segIsCodeSeg and not gdtEntry.segIsRW):
            return False
        return True
    cdef uint8_t checkWriteAllowed(self, uint16_t num) except BITMASK_BYTE_CONST: # for VERW
        cdef uint8_t rpl
        cdef GdtEntry gdtEntry
        rpl = num&3
        num &= 0xfff8
        if (num == 0 or num > self.tableLimit):
            return False
        if (not self.getEntry(&gdtEntry, num)):
            return False
        if (((self.getSegType(num) == 0) or not gdtEntry.segIsConforming) and \
          ((self.segments.registers.getCPL() > gdtEntry.segDPL) or (rpl > gdtEntry.segDPL))):
            return False
        if (not gdtEntry.segIsCodeSeg and gdtEntry.segIsRW):
            return True
        return False
    cdef uint8_t checkSegmentLoadAllowed(self, uint16_t num, uint16_t segId) except BITMASK_BYTE_CONST:
        cdef uint8_t numSegDPL, cpl
        cdef GdtEntry gdtEntry
        if ((num&0xfff8) > self.tableLimit):
            #self.segments.main.notice("test1: segId=={0:#04d}, num=={1:#06x}, tableLimit=={2:#06x}", segId, num, self.tableLimit)
            raise HirnwichseException(CPU_EXCEPTION_GP, num)
        if (not (num&0xfff8)):
            if (segId == CPU_SEGMENT_CS or segId == CPU_SEGMENT_SS):
                #self.segments.main.notice("test4: segId=={0:#04d}, num=={1:#06x}, tableLimit=={2:#06x}, EIP: {3:#010x}, CS: {4:#06x}", segId, num, self.tableLimit, self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            return False
        if (not self.getEntry(&gdtEntry, num) or not gdtEntry.segPresent):
            if (segId == CPU_SEGMENT_SS):
                raise HirnwichseException(CPU_EXCEPTION_SS, num)
            raise HirnwichseException(CPU_EXCEPTION_NP, num)
        #cpl = self.segments.cs.segmentIndex&3
        cpl = self.segments.registers.getCPL()
        numSegDPL = gdtEntry.segDPL
        if (segId == CPU_SEGMENT_TSS): # TODO?
            return True
        if (segId == CPU_SEGMENT_SS): # TODO: TODO!
            ##if ((num&3 != cpl or numSegDPL != cpl) or \
            if (((gdtEntry.segIsCodeSeg) or (not gdtEntry.segIsCodeSeg and not gdtEntry.segIsRW))):
                #self.segments.main.notice("test2: segId=={0:#04x}, num {1:#06x}, numSegDPL {2:d}, cpl {3:d}", segId, num, numSegDPL, cpl)
                raise HirnwichseException(CPU_EXCEPTION_GP, num)
        else: # not stack segment
            if ( ((not gdtEntry.segIsCodeSeg or not gdtEntry.segIsConforming) and (num&3 > numSegDPL and \
              cpl > numSegDPL)) or (segId != CPU_SEGMENT_CS and not gdtEntry.segIsRW) or (segId == CPU_SEGMENT_CS and not gdtEntry.segIsCodeSeg) ):
                #self.segments.main.notice("test3: segId=={0:#04d}", segId)
                raise HirnwichseException(CPU_EXCEPTION_GP, num)
        return True


cdef class Idt:
    def __init__(self, Segments segments):
        self.segments = segments
        self.tableBase = self.tableLimit = 0
    cdef void loadTable(self, uint32_t tableBase, uint16_t tableLimit):
        if (tableLimit > IDT_HARD_LIMIT):
            self.segments.main.exitError("Idt::loadTablePosition: tableLimit {0:#06x} > IDT_HARD_LIMIT {1:#06x}.",\
              tableLimit, IDT_HARD_LIMIT)
            return
        self.tableBase, self.tableLimit = tableBase, tableLimit
    cdef void parseIdtEntryData(self, IdtEntry *idtEntry, uint64_t entryData) nogil:
        idtEntry[0].entryEip = entryData&0xffff # interrupt eip: lower word
        idtEntry[0].entryEip |= ((entryData>>48)&0xffff)<<16 # interrupt eip: upper word
        idtEntry[0].entrySegment = (entryData>>16)&0xffff # interrupt segment
        idtEntry[0].entryType = (entryData>>40)&0xf # interrupt type
        idtEntry[0].entryNeededDPL = (entryData>>45)&0x3 # interrupt: Need this DPL
        idtEntry[0].entryPresent = (entryData>>47)&1 # is interrupt present
        idtEntry[0].entrySize = OP_SIZE_DWORD if (idtEntry[0].entryType in (TABLE_ENTRY_SYSTEM_TYPE_LDT, \
          TABLE_ENTRY_SYSTEM_TYPE_TASK_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY, \
          TABLE_ENTRY_SYSTEM_TYPE_32BIT_CALL_GATE, TABLE_ENTRY_SYSTEM_TYPE_32BIT_INTERRUPT_GATE, \
          TABLE_ENTRY_SYSTEM_TYPE_32BIT_TRAP_GATE)) else OP_SIZE_WORD
    cdef uint8_t getEntry(self, IdtEntry *idtEntry, uint8_t num) except BITMASK_BYTE_CONST:
        cdef uint64_t address
        self.segments.paging.implicitSV = True
        if (not self.tableLimit):
            #self.segments.main.notice("Idt::getEntry: tableLimit is zero.")
            return False
        address = (num<<3)
        if (address >= self.tableLimit):
            #self.segments.main.notice("Idt::getEntry: tableLimit is too small.")
            return False
        address += self.tableBase
        address = self.segments.registers.mmReadValueUnsignedQword(address, NULL, False)
        self.parseIdtEntryData(idtEntry, address)
        if (idtEntry[0].entryType in (TABLE_ENTRY_SYSTEM_TYPE_LDT, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY)):
            #self.segments.main.notice("Idt::getEntry: entryType is LDT or TSS. (is this allowed?)")
            return False
        if (not idtEntry[0].entryPresent):
            #self.segments.main.notice("Idt::getEntry: idtEntry is not present.")
            return False
        return True
    cdef void getEntryRealMode(self, uint8_t num, uint16_t *entrySegment, uint16_t *entryEip) nogil:
        cdef uint16_t offset
        offset = num<<2 # Don't use ConfigSpace here.
        entryEip[0] = self.segments.main.mm.mmPhyReadValueUnsignedWord(offset)
        entrySegment[0] = self.segments.main.mm.mmPhyReadValueUnsignedWord(offset+2)




cdef class Paging: # TODO
    def __init__(self, Segments segments):
        self.instrFetch = self.implicitSV = False
        self.segments = segments
        self.tlbDirectories = ConfigSpace(PAGE_DIRECTORY_LENGTH, self.segments.main)
        self.tlbTables = ConfigSpace(TLB_SIZE, self.segments.main)
        self.pageDirectoryBaseAddress = self.pageDirectoryOffset = self.pageTableOffset = self.pageDirectoryEntry = self.pageTableEntry = 0
    cdef void invalidateTables(self, uint32_t pageDirectoryBaseAddress, uint8_t noGlobal):
        cdef uint32_t pageDirectoryEntry, pageTableEntry, i, j
        if (pageDirectoryBaseAddress&0xfff):
            if (pageDirectoryBaseAddress&0xfff == 0x18):
                self.segments.main.notice("Paging::invalidateTables: PCD and PWT aren't supported yet.")
            else:
                self.segments.main.exitError("Paging::invalidateTables: pageDirectoryBaseAddress&0xfff")
                return
        self.pageDirectoryBaseAddress = (pageDirectoryBaseAddress&<uint32_t>0xfffff000)
        # TODO: handle global flag for non 4KB PDEs
        self.tlbDirectories.csWrite(0, self.segments.main.mm.mmPhyRead(self.pageDirectoryBaseAddress, PAGE_DIRECTORY_LENGTH), PAGE_DIRECTORY_LENGTH)
        for i in range(PAGE_DIRECTORY_ENTRIES):
            pageDirectoryEntry = self.tlbDirectories.csReadValueUnsigned(i<<2, OP_SIZE_DWORD) # page directory
            if (pageDirectoryEntry & PAGE_PRESENT):
                for j in range(PAGE_DIRECTORY_ENTRIES):
                    j <<= 2
                    pageTableEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntry&<uint32_t>0xfffff000)|j) # page table
                    #if (not noGlobal or not (pageTableEntry & PAGE_GLOBAL)):
                    if (not noGlobal or (self.segments.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_PGE) != 0 and not (pageTableEntry & PAGE_GLOBAL))):
                        self.tlbTables.csWriteValue((i<<12)|j, pageTableEntry, OP_SIZE_DWORD)
            else:
                self.tlbTables.csResetAddr((i<<12), 0, PAGE_DIRECTORY_LENGTH)
    cdef void invalidateTable(self, uint32_t virtualAddress):
        cdef uint32_t pageDirectoryOffset, pageTableOffset, pageDirectoryEntry, pageTableEntry, i
        pageDirectoryOffset = (virtualAddress>>22) << 2
        pageTableOffset = ((virtualAddress>>12)&0x3ff) << 2
        pageDirectoryEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|pageDirectoryOffset) # page directory
        self.tlbDirectories.csWriteValue(pageDirectoryOffset, pageDirectoryEntry, OP_SIZE_DWORD)
        pageTableEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntry&<uint32_t>0xfffff000)|pageTableOffset) # page table
        self.tlbTables.csWriteValue(((pageDirectoryOffset>>2)<<12)|pageTableOffset, pageTableEntry, OP_SIZE_DWORD)
    cdef void invalidatePage(self, uint32_t virtualAddress):
        cdef uint8_t updateDir
        cdef uint32_t pageDirectoryEntry, pageTableEntry, pageDirectoryOffset, pageTableOffset, pageDirectoryEntryV, i, j,
        pageDirectoryOffset = (virtualAddress>>22) << 2
        pageTableOffset = ((virtualAddress>>12)&0x3ff) << 2
        pageDirectoryEntryV = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|pageDirectoryOffset)&<uint32_t>0xfffff000 # page directory
        virtualAddress = self.segments.main.mm.mmPhyReadValueUnsignedDword(pageDirectoryEntryV|pageTableOffset)&<uint32_t>0xfffff000
        for i in range(0, PAGE_DIRECTORY_LENGTH, 4):
            updateDir = False
            pageDirectoryEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|i)
            if (not (pageDirectoryEntry & PAGE_PRESENT)):
                self.tlbDirectories.csWriteValue(i, 0, OP_SIZE_DWORD)
                self.tlbTables.csResetAddr(((i>>2)<<12), 0, PAGE_DIRECTORY_LENGTH)
                continue
            elif ((pageDirectoryEntry&<uint32_t>0xfffff000) == pageDirectoryEntryV):
                self.tlbDirectories.csWriteValue(i, pageDirectoryEntry, OP_SIZE_DWORD)
                updateDir = True
            for j in range(0, PAGE_DIRECTORY_LENGTH, 4):
                pageTableEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntry&<uint32_t>0xfffff000)|j) # page table
                if (not (pageTableEntry & PAGE_PRESENT)):
                    self.tlbTables.csWriteValue(((i>>2)<<12)|j, 0, OP_SIZE_DWORD)
                    continue
                elif (virtualAddress == (pageTableEntry&<uint32_t>0xfffff000) or updateDir):
                    self.tlbDirectories.csWriteValue(i, pageDirectoryEntry, OP_SIZE_DWORD)
                    self.tlbTables.csWriteValue(((i>>2)<<12)|j, pageTableEntry, OP_SIZE_DWORD)
    cdef uint8_t doPF(self, uint32_t virtualAddress, uint8_t written) except BITMASK_BYTE_CONST:
        cdef uint32_t errorFlags
        IF COMP_DEBUG:
            cdef uint32_t pageDirectoryEntryMem, pageTableEntryMem
        if (not self.segments.registers.ignoreExceptions):
            self.invalidatePage(virtualAddress)
            if (self.pageDirectoryEntry & PAGE_SIZE):
                errorFlags = (self.pageDirectoryEntry & PAGE_PRESENT) != 0
            else:
                errorFlags = ((self.pageDirectoryEntry & PAGE_PRESENT) and (self.pageTableEntry & PAGE_PRESENT)) != 0
            errorFlags |= written << 1
            errorFlags |= (self.segments.registers.getCPL() == 3) << 2
            # TODO: reserved bits are set ; only with 4MB pages ; << 3
            #errorFlags |= self.instrFetch << 4 # TODO: CR4
            #if (self.segments.main.cpu.savedCs == 0x167 and self.segments.main.cpu.savedEip == <uint32_t>0xbff77db0):
            #    self.segments.main.debugEnabled = True
            #    self.segments.main.debugEnabledTest = True
            IF COMP_DEBUG:
            #IF 1:
                pageDirectoryEntryMem = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|self.pageDirectoryOffset) # page directory
                pageTableEntryMem = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntryMem&<uint32_t>0xfffff000)|self.pageTableOffset) # page table
                self.segments.main.notice("Paging::doPF: savedEip=={0:#010x}; savedCs=={1:#06x}", self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
                self.segments.main.notice("Paging::doPF: virtualAddress=={0:#010x}; errorFlags=={1:#04x}", virtualAddress, errorFlags)
                self.segments.main.notice("Paging::doPF: PDEL=={0:#010x}, PTEL=={1:#010x}", self.pageDirectoryEntry, self.pageTableEntry)
                self.segments.main.notice("Paging::doPF: PDEM=={0:#010x}, PTEM=={1:#010x}", pageDirectoryEntryMem, pageTableEntryMem)
                self.segments.main.notice("Paging::doPF: PDO=={0:#06x}, PTO=={1:#06x}, PO=={2:#06x}", self.pageDirectoryOffset, self.pageTableOffset, self.pageOffset)
            self.segments.registers.regs[CPU_REGISTER_CR2]._union.dword.erx = virtualAddress
            self.instrFetch = self.implicitSV = False
            raise HirnwichseException(CPU_EXCEPTION_PF, errorFlags)
        else:
            self.segments.registers.ignoreExceptions = False
        return BITMASK_BYTE
    cdef uint8_t setFlags(self, uint32_t virtualAddress, uint32_t dataSize, uint8_t written) except BITMASK_BYTE_CONST:
        cdef uint32_t pageDirectoryOffset, pageTableOffset, pageDirectoryEntry, pageTableEntry, pageDirectoryEntryMem, pageTableEntryMem, pageTablesEntryNew, origVirtualAddress
        # TODO: for now only handling 4KB pages. (very inefficient)
        if (not dataSize):
            return True
        origVirtualAddress = virtualAddress
        while (dataSize >= 0):
            pageDirectoryOffset = (virtualAddress>>22) << 2
            pageTableOffset = ((virtualAddress>>12)&0x3ff) << 2
            pageDirectoryEntry = self.tlbDirectories.csReadValueUnsigned(pageDirectoryOffset, OP_SIZE_DWORD) # page directory
            pageTableEntry = self.tlbTables.csReadValueUnsigned(((pageDirectoryOffset>>2)<<12)|pageTableOffset, OP_SIZE_DWORD) # page table
            if ((pageDirectoryEntry & PAGE_PRESENT) and ((pageDirectoryEntry & PAGE_SIZE) or (pageTableEntry & PAGE_PRESENT))):
                #self.segments.main.debug("Paging::setFlags: test3: pdo addr {0:#010x}; pto addr {1:#010x}", (self.pageDirectoryBaseAddress|pageDirectoryOffset), ((pageDirectoryEntry&<uint32_t>0xfffff000)|pageTableOffset))
                #self.segments.main.debug("Paging::setFlags: test4: pdo {0:#010x}; pto {1:#010x}", pageDirectoryEntry, pageTableEntry)
                #self.segments.main.debug("Paging::setFlags: test5: pdo {0:#010x}; pto {1:#010x}", self.segments.main.mm.mmPhyReadValueUnsignedDword((self.pageDirectoryBaseAddress|pageDirectoryOffset)), self.segments.main.mm.mmPhyReadValueUnsignedDword(((pageDirectoryEntry&<uint32_t>0xfffff000)|pageTableOffset)))
                pageDirectoryEntryMem = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|pageDirectoryOffset) # page directory
                if (not (pageDirectoryEntry & PAGE_WAS_USED) or (written and not (pageDirectoryEntry & PAGE_WRITTEN_ON_PAGE))):
                    pageTablesEntryNew = pageDirectoryEntry|(PAGE_WAS_USED | (written and PAGE_WRITTEN_ON_PAGE))
                    self.tlbDirectories.csWriteValue(pageDirectoryOffset, pageTablesEntryNew, OP_SIZE_DWORD)
                    if (pageDirectoryEntry&<uint32_t>0xfffff19f == pageDirectoryEntryMem&<uint32_t>0xfffff19f):
                        pageTablesEntryNew = pageDirectoryEntryMem|(PAGE_WAS_USED | (written and PAGE_WRITTEN_ON_PAGE))
                        self.segments.main.mm.mmPhyWriteValue(self.pageDirectoryBaseAddress|pageDirectoryOffset, pageTablesEntryNew, OP_SIZE_DWORD) # page directory
                if (not (pageDirectoryEntry & PAGE_SIZE) and (not (pageTableEntry & PAGE_WAS_USED) or (written and not (pageTableEntry & PAGE_WRITTEN_ON_PAGE)))):
                    pageTablesEntryNew = pageTableEntry|(PAGE_WAS_USED | (written and PAGE_WRITTEN_ON_PAGE))
                    self.tlbTables.csWriteValue(((pageDirectoryOffset>>2)<<12)|pageTableOffset, pageTablesEntryNew, OP_SIZE_DWORD)
                    pageTableEntryMem = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntryMem&<uint32_t>0xfffff000)|pageTableOffset) # page table
                    if (pageDirectoryEntry&<uint32_t>0xfffff19f == pageDirectoryEntryMem&<uint32_t>0xfffff19f and pageTableEntry&<uint32_t>0xfffff19f == pageTableEntryMem&<uint32_t>0xfffff19f):
                        pageTablesEntryNew = pageTableEntryMem|(PAGE_WAS_USED | (written and PAGE_WRITTEN_ON_PAGE))
                        self.segments.main.mm.mmPhyWriteValue(((pageDirectoryEntryMem&<uint32_t>0xfffff000)|pageTableOffset), pageTablesEntryNew, OP_SIZE_DWORD) # page table
                #self.segments.main.debug("Paging::setFlags: test6: pdo {0:#010x}; pto {1:#010x}", self.segments.main.mm.mmPhyReadValueUnsignedDword((self.pageDirectoryBaseAddress|pageDirectoryOffset)), self.segments.main.mm.mmPhyReadValueUnsignedDword(((pageDirectoryEntry&<uint32_t>0xfffff000)|pageTableOffset)))
            if (not dataSize):
                break
            elif (dataSize < PAGE_DIRECTORY_LENGTH):
                virtualAddress += dataSize
                dataSize = 0
            else:
                virtualAddress += PAGE_DIRECTORY_LENGTH
                dataSize -= PAGE_DIRECTORY_LENGTH
        return True
    cdef uint32_t getPhysicalAddress(self, uint32_t virtualAddress, uint32_t dataSize, uint8_t written) except? BITMASK_BYTE_CONST:
        #IF 0:
        cdef uint8_t cpl
        IF COMP_DEBUG:
            cdef uint32_t pageDirectoryEntryMem, pageTableEntryMem
        #self.segments.main.notice("Paging::getPhysicalAddress: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
        #self.invalidateTables(self.pageDirectoryBaseAddress, False)
        #self.invalidatePage(virtualAddress)
        #if (self.segments.registers.cacheDisabled): # TODO?
        #    self.invalidateTable(virtualAddress)
        self.pageDirectoryOffset = (virtualAddress>>22) << 2
        self.pageTableOffset = ((virtualAddress>>12)&0x3ff) << 2
        self.pageOffset = virtualAddress&0xfff
        self.pageDirectoryEntry = self.tlbDirectories.csReadValueUnsigned(self.pageDirectoryOffset, OP_SIZE_DWORD) # page directory
        if (not self.pageDirectoryEntry):
            IF COMP_DEBUG:
                if (self.segments.main.debugEnabled):
                    self.segments.main.notice("Paging::getPhysicalAddress: PDE-Entry is zero, reloading. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageDirectoryEntry, self.pageDirectoryBaseAddress|self.pageDirectoryOffset, virtualAddress)
                    self.segments.main.notice("Paging::getPhysicalAddress: PDE-Entry is zero, reloading, PTE. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.tlbTables.csReadValueUnsigned((self.pageDirectoryOffset<<10)|self.pageTableOffset, OP_SIZE_DWORD), (self.pageDirectoryEntry&<uint32_t>0xfffff000)|self.pageTableOffset, virtualAddress)
            #self.invalidateTable(virtualAddress)
            self.invalidatePage(virtualAddress)
            self.pageDirectoryEntry = self.tlbDirectories.csReadValueUnsigned(self.pageDirectoryOffset, OP_SIZE_DWORD) # page directory
            IF COMP_DEBUG:
                if (self.segments.main.debugEnabled):
                    self.segments.main.notice("Paging::getPhysicalAddress: PDE-Entry was zero, reloaded. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageDirectoryEntry, self.pageDirectoryBaseAddress|self.pageDirectoryOffset, virtualAddress)
                    self.segments.main.notice("Paging::getPhysicalAddress: PDE-Entry was zero, reloaded, PTE. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.tlbTables.csReadValueUnsigned((self.pageDirectoryOffset<<10)|self.pageTableOffset, OP_SIZE_DWORD), (self.pageDirectoryEntry&<uint32_t>0xfffff000)|self.pageTableOffset, virtualAddress)
        if (not (self.pageDirectoryEntry & PAGE_PRESENT)):
            IF COMP_DEBUG:
                if (self.segments.main.debugEnabled):
                    self.segments.main.notice("Paging::getPhysicalAddress: PDE-Entry is not present 1. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageDirectoryEntry, self.pageDirectoryBaseAddress|self.pageDirectoryOffset, virtualAddress)
                    self.segments.main.notice("Paging::getPhysicalAddress: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
            #self.invalidateTable(virtualAddress)
            self.invalidatePage(virtualAddress)
            self.pageDirectoryEntry = self.tlbDirectories.csReadValueUnsigned(self.pageDirectoryOffset, OP_SIZE_DWORD) # page directory
            if (not (self.pageDirectoryEntry & PAGE_PRESENT)):
                IF COMP_DEBUG:
                #IF 1:
                    self.segments.main.notice("Paging::getPhysicalAddress: PDE-Entry is not present 2. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageDirectoryEntry, self.pageDirectoryBaseAddress|self.pageDirectoryOffset, virtualAddress)
                return self.doPF(virtualAddress, written)
        if (self.pageDirectoryEntry & PAGE_SIZE): # it's a 4MB page
            # size is 4MB if CR4/PSE is set
            # size is 2MB if CR4/PAE is set
            # if CR4/PAE bit is set size is 2MB and CR4/PSE bit appears as always set.
            if (self.segments.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_PAE) != 0):
                self.segments.main.exitError("Paging::getPhysicalAddress: CR4/PAE is set.")
                return False
            elif (not self.segments.registers.getFlagDword(CPU_REGISTER_CR4, CR4_FLAG_PSE)):
                self.segments.main.exitError("Paging::getPhysicalAddress: CR4/PSE isn't set.")
                return False
            self.segments.main.notice("Paging::getPhysicalAddress: EIP: {0:#010x}, CS: {1:#06x}", self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
            self.segments.main.notice("Paging::getPhysicalAddress: PDE & PAGE_SIZE. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageDirectoryEntry, self.pageDirectoryBaseAddress|self.pageDirectoryOffset, virtualAddress)
            self.segments.main.notice("Paging::getPhysicalAddress: 4MB pages are NOT FULLY SUPPORTED yet.")
            self.segments.main.exitError("Paging::getPhysicalAddress: TODO... exiting.")
        else:
            self.pageTableEntry = self.tlbTables.csReadValueUnsigned((self.pageDirectoryOffset<<10)|self.pageTableOffset, OP_SIZE_DWORD) # page table
            if (not self.pageTableEntry):
                IF COMP_DEBUG:
                    if (self.segments.main.debugEnabled):
                        self.segments.main.notice("Paging::getPhysicalAddress: PTE-Entry is zero, reloading. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageTableEntry, (self.pageDirectoryEntry&<uint32_t>0xfffff000)|self.pageTableOffset, virtualAddress)
                #self.invalidateTable(virtualAddress)
                self.invalidatePage(virtualAddress)
                self.pageTableEntry = self.tlbTables.csReadValueUnsigned((self.pageDirectoryOffset<<10)|self.pageTableOffset, OP_SIZE_DWORD) # page table
                IF COMP_DEBUG:
                    if (self.segments.main.debugEnabled):
                        self.segments.main.notice("Paging::getPhysicalAddress: PTE-Entry was zero, reloaded. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageTableEntry, (self.pageDirectoryEntry&<uint32_t>0xfffff000)|self.pageTableOffset, virtualAddress)
            if (not (self.pageTableEntry & PAGE_PRESENT)):
                IF COMP_DEBUG:
                    if (self.segments.main.debugEnabled):
                        self.segments.main.notice("Paging::getPhysicalAddress: PTE-Entry is not present 1. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageTableEntry, (self.pageDirectoryEntry&<uint32_t>0xfffff000)|self.pageTableOffset, virtualAddress)
                #self.invalidateTable(virtualAddress)
                self.invalidatePage(virtualAddress)
                self.pageTableEntry = self.tlbTables.csReadValueUnsigned((self.pageDirectoryOffset<<10)|self.pageTableOffset, OP_SIZE_DWORD) # page table
                if (not (self.pageTableEntry & PAGE_PRESENT)):
                    IF COMP_DEBUG:
                    #IF 1:
                        self.segments.main.notice("Paging::getPhysicalAddress: PTE-Entry is not present 2. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageTableEntry, (self.pageDirectoryEntry&<uint32_t>0xfffff000)|self.pageTableOffset, virtualAddress)
                    return self.doPF(virtualAddress, written)
        cpl = self.segments.registers.getCPL()
        if (self.pageDirectoryEntry & PAGE_SIZE):
            if (not self.implicitSV and ((cpl == 3 and (not (self.pageDirectoryEntry&PAGE_EVERY_RING))) or \
            (written and ((cpl == 3 or self.segments.registers.writeProtectionOn) and not (self.pageDirectoryEntry&PAGE_WRITABLE))))):
                IF COMP_DEBUG:
                #IF 1:
                    self.segments.main.notice("Paging::getPhysicalAddress: doPF_1")
                return self.doPF(virtualAddress, written)
        else:
            if (not self.implicitSV and ((cpl == 3 and (not (self.pageDirectoryEntry&PAGE_EVERY_RING and self.pageTableEntry&PAGE_EVERY_RING))) or \
            (written and ((cpl == 3 or self.segments.registers.writeProtectionOn) and not (self.pageDirectoryEntry&PAGE_WRITABLE and self.pageTableEntry&PAGE_WRITABLE))))):
                IF COMP_DEBUG:
                #IF 1:
                    self.segments.main.notice("Paging::getPhysicalAddress: doPF_2")
                return self.doPF(virtualAddress, written)
        self.setFlags(virtualAddress, dataSize, written)
        self.instrFetch = self.implicitSV = False
        #if (self.segments.main.debugEnabled):
        #IF 1:
        #IF 0:
        IF COMP_DEBUG:
            #self.pageDirectoryEntry = self.tlbDirectories.csReadValueUnsigned(self.pageDirectoryOffset, OP_SIZE_DWORD) # page directory
            #self.pageTableEntry = self.tlbTables.csReadValueUnsigned((self.pageDirectoryOffset<<10)|self.pageTableOffset, OP_SIZE_DWORD) # page table
            pageDirectoryEntryMem = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|self.pageDirectoryOffset) # page directory
            pageTableEntryMem = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntryMem&<uint32_t>0xfffff000)|self.pageTableOffset) # page table
            if (self.segments.main.debugEnabled):
            #if (self.segments.main.debugEnabled or self.pageDirectoryEntry != pageDirectoryEntryMem or self.pageTableEntry != pageTableEntryMem):
                self.segments.main.notice("Paging::getPhysicalAddress: savedEip=={0:#010x}; savedCs=={1:#06x}", self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
                self.segments.main.notice("Paging::getPhysicalAddress: virtualAddress=={0:#010x}; physicalAddress=={1:#010x}", virtualAddress, (self.pageTableEntry&<uint32_t>0xfffff000)|self.pageOffset)
                self.segments.main.notice("Paging::getPhysicalAddress: PDEL=={0:#010x}, PTEL=={1:#010x}", self.pageDirectoryEntry, self.pageTableEntry)
                self.segments.main.notice("Paging::getPhysicalAddress: PDEM=={0:#010x}, PTEM=={1:#010x}", pageDirectoryEntryMem, pageTableEntryMem)
                self.segments.main.notice("Paging::getPhysicalAddress: PDO=={0:#06x}, PTO=={1:#06x}, PO=={2:#06x}", self.pageDirectoryOffset, self.pageTableOffset, self.pageOffset)
            if (self.pageDirectoryEntry != pageDirectoryEntryMem):
                if (self.pageDirectoryEntry&<uint32_t>0xfffff19f != pageDirectoryEntryMem&<uint32_t>0xfffff19f):
                    self.segments.main.notice("Paging::getPhysicalAddress: PDE too diff; virtualAddress=={0:#010x}", virtualAddress)
                elif (self.segments.main.debugEnabled):
                    self.segments.main.notice("Paging::getPhysicalAddress: PDE diff; virtualAddress=={0:#010x}", virtualAddress)
            if (self.pageTableEntry != pageTableEntryMem):
                if (self.pageTableEntry&<uint32_t>0xfffff19f != pageTableEntryMem&<uint32_t>0xfffff19f):
                    self.segments.main.notice("Paging::getPhysicalAddress: PTE too diff; virtualAddress=={0:#010x}", virtualAddress)
                elif (self.segments.main.debugEnabled):
                    self.segments.main.notice("Paging::getPhysicalAddress: PTE diff; virtualAddress=={0:#010x}", virtualAddress)
        if (self.pageDirectoryEntry & PAGE_SIZE):
            return (self.pageDirectoryEntry & <uint32_t>0xffc00000) | (self.pageTableOffset >> 2) | self.pageOffset
        else:
            return (self.pageTableEntry & <uint32_t>0xfffff000) | self.pageOffset

cdef class Segments:
    def __init__(self, Registers registers, Hirnwichse main):
        self.registers = registers
        self.main = main
    cdef inline uint8_t isAddressInLimit(self, GdtEntry *gdtEntry, uint32_t address, uint32_t size) except BITMASK_BYTE_CONST:
        ## address is an offset.
        address += size-1
        if (not gdtEntry[0].anotherLimit):
            if (address>gdtEntry[0].limit):
                IF COMP_DEBUG:
                    self.main.notice("Segments::isAddressInLimit: test2: not in limit; (addr=={0:#010x}; size=={1:#010x}; limit=={2:#010x})", address+1, size, gdtEntry[0].limit)
                return False
        else:
            if ((address+1)<gdtEntry[0].limit or (not gdtEntry[0].segSize and (address>BITMASK_WORD))):
                IF COMP_DEBUG:
                    self.main.notice("Segments::isAddressInLimit: test1: not in limit; (addr=={0:#010x}; size=={1:#010x}; limit=={2:#010x})", address+1, size, gdtEntry[0].limit)
                return False
        return True
    cdef void parseGdtEntryData(self, GdtEntry *gdtEntry, uint64_t entryData) nogil:
        gdtEntry[0].accessByte = <uint8_t>(entryData>>40)
        gdtEntry[0].flags  = (entryData>>52)&0xf
        gdtEntry[0].base  = (entryData>>16)&0xffffff
        gdtEntry[0].limit = entryData&0xffff
        gdtEntry[0].base  |= (<uint8_t>(entryData>>56))<<24
        gdtEntry[0].limit |= ((entryData>>48)&0xf)<<16
        # segment size: 1==32bit; 0==16bit; segSize is 4 for 32bit and 2 for 16bit
        gdtEntry[0].segSize = OP_SIZE_DWORD if (gdtEntry[0].flags & GDT_FLAG_SIZE) else OP_SIZE_WORD
        gdtEntry[0].segPresent = (gdtEntry[0].accessByte & GDT_ACCESS_PRESENT)!=0
        gdtEntry[0].segIsCodeSeg = (gdtEntry[0].accessByte & GDT_ACCESS_EXECUTABLE)!=0
        gdtEntry[0].segIsRW = (gdtEntry[0].accessByte & GDT_ACCESS_READABLE_WRITABLE)!=0
        gdtEntry[0].segIsConforming = (gdtEntry[0].accessByte & GDT_ACCESS_CONFORMING)!=0
        gdtEntry[0].segIsNormal = (gdtEntry[0].accessByte & GDT_ACCESS_NORMAL_SEGMENT)!=0
        gdtEntry[0].segUse4K = (gdtEntry[0].flags & GDT_FLAG_USE_4K)!=0
        gdtEntry[0].segDPL = ((gdtEntry[0].accessByte & GDT_ACCESS_DPL)>>5)&3
        gdtEntry[0].anotherLimit = gdtEntry[0].segIsNormal and not gdtEntry[0].segIsCodeSeg and gdtEntry[0].segIsConforming
        if (gdtEntry[0].segUse4K):
            gdtEntry[0].limit <<= 12
            gdtEntry[0].limit |= 0xfff
        #if (not gdtEntry[0].segIsCodeSeg and gdtEntry[0].segIsConforming and self.main.debugEnabled):
        #    self.main.notice("GdtEntry::parseEntryData: TODO: expand-down data segment may not supported yet!")
        #if (gdtEntry[0].flags & GDT_FLAG_LONGMODE): # TODO: int-mode isn't implemented yet...
        #    self.main.notice("GdtEntry::parseEntryData: WTF: Did you just tried to use int-mode?!? Maybe I'll implement it in a few decades... (long-mode; AMD64)")
    cdef uint8_t loadSegment(self, Segment *segment, uint16_t segmentIndex, uint8_t doInit) except BITMASK_BYTE_CONST:
        cdef GdtEntry gdtEntry
        cdef uint8_t protectedModeOn
        if (segment[0].segId == CPU_SEGMENT_CS):
            protectedModeOn = self.registers.protectedModeOn
        else:
            protectedModeOn = self.registers.getFlagDword(CPU_REGISTER_CR0, CR0_FLAG_PE) != 0
        protectedModeOn = (protectedModeOn and not self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm)
        segment[0].segmentIndex = segmentIndex
        segment[0].readChecked = segment[0].writeChecked = False
        if (not protectedModeOn):
            segment[0].gdtEntry.base = <uint32_t>segmentIndex<<4
            segment[0].isValid = segment[0].gdtEntry.segPresent = segment[0].gdtEntry.segIsNormal = True
            segment[0].useGDT = segment[0].gdtEntry.anotherLimit = segment[0].segIsGDTandNormal = False
            segment[0].gdtEntry.segSize = OP_SIZE_WORD
            if (doInit or (self.registers.protectedModeOn and self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm)):
                segment[0].gdtEntry.accessByte = 0x92
                if (self.registers.protectedModeOn and self.registers.regs[CPU_REGISTER_EFLAGS]._union.eflags_struct.vm):
                    segment[0].segmentIndex |= 0x3
                    segment[0].gdtEntry.segDPL = 0x3
                    segment[0].gdtEntry.accessByte |= 0x60
                segment[0].gdtEntry.limit = 0xffff
                segment[0].gdtEntry.segIsRW = True
                segment[0].gdtEntry.segIsConforming = segment[0].gdtEntry.segUse4K = False
                segment[0].gdtEntry.flags = 0
                segment[0].gdtEntry.segDPL = self.registers.getCPL()
                if (segment[0].segId == CPU_SEGMENT_CS):
                    segment[0].gdtEntry.segIsCodeSeg = True
            return True
        if (not segmentIndex or not self.getEntry(&gdtEntry, segmentIndex)):
            segment[0].useGDT = segment[0].gdtEntry.base = segment[0].gdtEntry.limit = segment[0].gdtEntry.accessByte = segment[0].gdtEntry.flags = segment[0].gdtEntry.segSize = segment[0].isValid = \
            segment[0].gdtEntry.segPresent = segment[0].gdtEntry.segIsCodeSeg = segment[0].gdtEntry.segIsRW = segment[0].gdtEntry.segIsConforming = segment[0].gdtEntry.segIsNormal = \
            segment[0].gdtEntry.segUse4K = segment[0].gdtEntry.segDPL = segment[0].gdtEntry.anotherLimit = segment[0].segIsGDTandNormal = 0
            return False
        segment[0].useGDT = True
        segment[0].isValid = True
        segment[0].gdtEntry.base = gdtEntry.base
        segment[0].gdtEntry.limit = gdtEntry.limit
        segment[0].gdtEntry.accessByte = gdtEntry.accessByte
        segment[0].gdtEntry.flags = gdtEntry.flags
        segment[0].gdtEntry.segSize = gdtEntry.segSize
        segment[0].gdtEntry.segPresent = gdtEntry.segPresent
        segment[0].gdtEntry.segIsCodeSeg = gdtEntry.segIsCodeSeg
        segment[0].gdtEntry.segIsRW = gdtEntry.segIsRW
        segment[0].gdtEntry.segIsConforming = gdtEntry.segIsConforming
        segment[0].gdtEntry.segIsNormal = gdtEntry.segIsNormal
        segment[0].gdtEntry.segUse4K = gdtEntry.segUse4K
        segment[0].gdtEntry.segDPL = gdtEntry.segDPL
        segment[0].gdtEntry.anotherLimit = gdtEntry.anotherLimit
        segment[0].segIsGDTandNormal = segment[0].gdtEntry.segIsNormal
        return True
    cdef inline uint8_t getEntry(self, GdtEntry *gdtEntry, uint16_t num) except BITMASK_BYTE_CONST:
        if (num & SELECTOR_USE_LDT):
            return self.ldt.getEntry(gdtEntry, num)
        return self.gdt.getEntry(gdtEntry, num)
    cdef inline uint8_t getSegType(self, uint16_t num) except? BITMASK_BYTE_CONST:
        if (num & SELECTOR_USE_LDT):
            return self.ldt.getSegType(num)
        return self.gdt.getSegType(num)
    cdef inline uint8_t setSegType(self, uint16_t num, uint8_t segmentType) except BITMASK_BYTE_CONST:
        if (num & SELECTOR_USE_LDT):
            return self.ldt.setSegType(num, segmentType)
        return self.gdt.setSegType(num, segmentType)
    cdef inline uint8_t checkAccessAllowed(self, uint16_t num, uint8_t isStackSegment) except BITMASK_BYTE_CONST:
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkAccessAllowed(num, isStackSegment)
        return self.gdt.checkAccessAllowed(num, isStackSegment)
    cdef inline uint8_t checkReadAllowed(self, uint16_t num) except BITMASK_BYTE_CONST:
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkReadAllowed(num)
        return self.gdt.checkReadAllowed(num)
    cdef inline uint8_t checkWriteAllowed(self, uint16_t num) except BITMASK_BYTE_CONST:
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkWriteAllowed(num)
        return self.gdt.checkWriteAllowed(num)
    cdef inline uint8_t checkSegmentLoadAllowed(self, uint16_t num, uint16_t segId) except BITMASK_BYTE_CONST:
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkSegmentLoadAllowed(num, segId)
        return self.gdt.checkSegmentLoadAllowed(num, segId)
    cdef inline uint8_t inLimit(self, uint16_t num) nogil:
        if (num & SELECTOR_USE_LDT):
            return ((num&0xfff8) <= self.ldt.tableLimit)
        return ((num&0xfff8) <= self.gdt.tableLimit)
    cdef void run(self):
        self.gdt = Gdt(self)
        self.ldt = Gdt(self)
        self.idt = Idt(self)
        self.paging = Paging(self)
        self.cs.segId = CPU_SEGMENT_CS
        self.loadSegment(&self.cs, 0, True)
        self.ss.segId = CPU_SEGMENT_SS
        self.loadSegment(&self.ss, 0, True)
        self.ds.segId = CPU_SEGMENT_DS
        self.loadSegment(&self.ds, 0, True)
        self.es.segId = CPU_SEGMENT_ES
        self.loadSegment(&self.es, 0, True)
        self.fs.segId = CPU_SEGMENT_FS
        self.loadSegment(&self.fs, 0, True)
        self.gs.segId = CPU_SEGMENT_GS
        self.loadSegment(&self.gs, 0, True)
        self.tss.segId = CPU_SEGMENT_TSS
        self.loadSegment(&self.tss, 0, True)



