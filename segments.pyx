
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"
include "cpu_globals.pxi"

from misc import HirnwichseException


cdef class Segment:
    def __init__(self, Segments segments, unsigned short segId):
        self.segments = segments
        self.segId = segId
        self.loadSegment(0, True)
    cdef unsigned char loadSegment(self, unsigned short segmentIndex, unsigned char doInit) except BITMASK_BYTE:
        cdef GdtEntry gdtEntry
        cdef unsigned char protectedModeOn, segType
        protectedModeOn = (self.segments.registers.protectedModeOn and not self.segments.registers.vm)
        self.segmentIndex = segmentIndex
        self.readChecked = self.writeChecked = False
        if (not protectedModeOn):
            self.base = <unsigned int>segmentIndex<<4
            self.isValid = self.segPresent = self.segIsNormal = True
            self.useGDT = self.anotherLimit = False
            self.segSize = OP_SIZE_WORD
            if (doInit or (self.segments.registers.protectedModeOn and self.segments.registers.vm)):
                self.accessByte = 0x92
                if (self.segments.registers.protectedModeOn and self.segments.registers.vm):
                    self.segmentIndex |= 0x3
                    self.segDPL = 0x3
                    self.accessByte |= 0x60
                self.limit = 0xffff
                self.segIsRW = True
                self.segIsConforming = self.segUse4K = False
                self.flags = 0
                self.segDPL = self.segments.registers.getCPL()
                if (self.segId == CPU_SEGMENT_CS):
                    self.segIsCodeSeg = True
            return True
        gdtEntry = self.segments.getEntry(segmentIndex)
        if (not segmentIndex or gdtEntry is None):
            self.isValid = self.useGDT = self.base = self.limit = self.accessByte = self.flags = self.segSize = self.isValid = \
              self.segPresent = self.segIsCodeSeg = self.segIsRW = self.segIsConforming = self.segIsNormal = self.segUse4K = \
              self.segDPL = self.anotherLimit = 0
            return False
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
        self.anotherLimit = (self.segIsNormal and not self.segIsCodeSeg and self.segIsConforming) != 0
        return True
    ### isSegReadableWritable:
    ### if codeseg, return True if readable, else False
    ### if dataseg, return True if writable, else False
    cdef unsigned char isAddressInLimit(self, unsigned int address, unsigned int size) except BITMASK_BYTE: # TODO: copied from GdtEntry::isAddressInLimit until a better solution is found... so never.
        ## address is an offset.
        if (self.anotherLimit):
            if ((address+size)<self.limit or (not self.segSize and ((address+size-1)>BITMASK_WORD))):
                self.segments.main.notice("Segment::isAddressInLimit: test1: not in limit; (addr=={0:#010x}; size=={1:#010x}; limit=={2:#010x})", address, size, self.limit)
                return False
        else:
            if ((address+size-1)>self.limit):
                self.segments.main.notice("Segment::isAddressInLimit: test2: not in limit; (addr=={0:#010x}; size=={1:#010x}; limit=={2:#010x})", address, size, self.limit)
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
        if (self.segUse4K):
            self.limit <<= 12
            self.limit |= 0xfff
        if (not self.segIsCodeSeg and self.segIsConforming):
            self.gdt.segments.main.notice("GdtEntry::parseEntryData: TODO: expand-down data segment may not supported yet!")
        if (self.flags & GDT_FLAG_LONGMODE): # TODO: int-mode isn't implemented yet...
            self.gdt.segments.main.notice("GdtEntry::parseEntryData: WTF: Did you just tried to use int-mode?!? Maybe I'll implement it in a few decades... (long-mode; AMD64)")
    cdef unsigned char isAddressInLimit(self, unsigned int address, unsigned int size) except BITMASK_BYTE:
        ## address is an offset.
        if (self.segIsNormal and not self.segIsCodeSeg and self.segIsConforming):
            if ((address+size)<self.limit or (not self.segSize and ((address+size-1)>BITMASK_WORD))):
                self.gdt.segments.main.notice("GdtEntry::isAddressInLimit: test1: not in limit; (addr=={0:#010x}; size=={1:#010x}; limit=={2:#010x})", address, size, self.limit)
                return False
        else:
            if ((address+size-1)>self.limit):
                self.gdt.segments.main.notice("GdtEntry::isAddressInLimit: test2: not in limit; (addr=={0:#010x}; size=={1:#010x}; limit=={2:#010x})", address, size, self.limit)
                return False
        return True

cdef class IdtEntry:
    def __init__(self, unsigned long int entryData):
        self.parseEntryData(entryData)
    cdef void parseEntryData(self, unsigned long int entryData) nogil:
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
        self.segments.paging.implicitSV = True
        num &= 0xfff8
        if (not num):
            ##self.segments.main.debug("GDT::getEntry: num == 0!")
            return None
        #self.segments.main.debug("Gdt::getEntry: tableBase=={0:#010x}; tableLimit=={1:#06x}; num=={2:#06x}", self.tableBase, self.tableLimit, num)
        entryData = self.tableBase+num
        entryData = self.segments.registers.mmReadValueUnsignedQword(entryData, None, False)
        return GdtEntry(self, entryData)
    cdef unsigned char getSegType(self, unsigned short num): # access byte
        self.segments.paging.implicitSV = True
        num &= 0xfff8
        return (self.segments.registers.mmReadValueUnsignedByte(self.tableBase+num+5, None, False) & TABLE_ENTRY_SYSTEM_TYPE_MASK)
    cdef void setSegType(self, unsigned short num, unsigned char segmentType): # access byte
        self.segments.paging.implicitSV = True
        num &= 0xfff8
        self.segments.registers.mmWriteValue(self.tableBase+num+5, <unsigned char>((self.segments.registers.\
          mmReadValueUnsignedByte(self.tableBase+num+5, None, False) & (~TABLE_ENTRY_SYSTEM_TYPE_MASK)) | \
            (segmentType & TABLE_ENTRY_SYSTEM_TYPE_MASK)), OP_SIZE_BYTE, None, False)
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment) except BITMASK_BYTE:
        cdef unsigned char cpl
        cdef GdtEntry gdtEntry
        if (not (num&0xfff8) or num > self.tableLimit):
            self.segments.main.notice("Gdt::checkAccessAllowed: test1")
            if (not (num&0xfff8)):
                raise HirnwichseException(CPU_EXCEPTION_GP, 0)
            else:
                raise HirnwichseException(CPU_EXCEPTION_GP, num)
        #cpl = self.segments.cs.segmentIndex&3
        cpl = self.segments.registers.getCPL()
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
          ((self.segments.registers.getCPL() > gdtEntry.segDPL) or (rpl > gdtEntry.segDPL))):
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
          ((self.segments.registers.getCPL() > gdtEntry.segDPL) or (rpl > gdtEntry.segDPL))):
            return False
        if (not gdtEntry.segIsCodeSeg and gdtEntry.segIsRW):
            return True
        return False
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned short segId) except BITMASK_BYTE:
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
        cpl = self.segments.registers.getCPL()
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
        self.segments.paging.implicitSV = True
        if (not self.tableLimit):
            self.segments.main.notice("Idt::getEntry: tableLimit is zero.")
            return None
        address = (num<<3)
        if (address >= self.tableLimit):
            self.segments.main.notice("Idt::getEntry: tableLimit is too small.")
            return None
        address += self.tableBase
        address = self.segments.registers.mmReadValueUnsignedQword(address, None, False)
        idtEntry = IdtEntry(address)
        if (idtEntry.entryType in (TABLE_ENTRY_SYSTEM_TYPE_LDT, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS, TABLE_ENTRY_SYSTEM_TYPE_32BIT_TSS_BUSY)):
            self.segments.main.notice("Idt::getEntry: entryType is LDT or TSS. (is this allowed?)")
            return None
        if (not idtEntry.entryPresent):
            self.segments.main.notice("Idt::getEntry: idtEntry is not present.")
            return None
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
        self.instrFetch = self.implicitSV = False
        self.segments = segments
        self.tlbDirectories = ConfigSpace(PAGE_DIRECTORY_LENGTH, self.segments.main)
        self.tlbTables = ConfigSpace(TLB_SIZE, self.segments.main)
        self.pageDirectoryBaseAddress = self.pageDirectoryOffset = self.pageTableOffset = self.pageDirectoryEntry = self.pageTableEntry = 0
    cdef void invalidateTables(self, unsigned int pageDirectoryBaseAddress, unsigned char noGlobal):
        cdef unsigned int pageDirectoryEntry, pageTableEntry, i, j
        if (pageDirectoryBaseAddress&0xfff):
            if (pageDirectoryBaseAddress&0xfff == 0x18):
                self.segments.main.notice("Paging::invalidateTables: PCD and PWT aren't supported yet.")
            else:
                self.segments.main.exitError("Paging::invalidateTables: pageDirectoryBaseAddress&0xfff")
                return
        self.pageDirectoryBaseAddress = (pageDirectoryBaseAddress&0xfffff000)
        self.tlbDirectories.csWrite(0, self.segments.main.mm.mmPhyRead(self.pageDirectoryBaseAddress, PAGE_DIRECTORY_LENGTH), PAGE_DIRECTORY_LENGTH)
        for i in range(PAGE_DIRECTORY_ENTRIES):
            pageDirectoryEntry = self.tlbDirectories.csReadValueUnsigned(i<<2, OP_SIZE_DWORD) # page directory
            if (pageDirectoryEntry & PAGE_PRESENT):
                for j in range(PAGE_DIRECTORY_ENTRIES):
                    j <<= 2
                    pageTableEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntry&0xfffff000)|j) # page table
                    if (not noGlobal or not (pageTableEntry & PAGE_GLOBAL)):
                        self.tlbTables.csWriteValue((i<<12)|j, pageTableEntry, OP_SIZE_DWORD)
            else:
                self.tlbTables.csWrite((i<<12), bytes(PAGE_DIRECTORY_LENGTH), PAGE_DIRECTORY_LENGTH)
    cdef void invalidateTable(self, unsigned int virtualAddress):
        cdef unsigned int pageDirectoryOffset, pageTableOffset, pageDirectoryEntry, pageTableEntry, i
        pageDirectoryOffset = (virtualAddress>>22) << 2
        pageTableOffset = ((virtualAddress>>12)&0x3ff) << 2
        pageDirectoryEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|pageDirectoryOffset) # page directory
        self.tlbDirectories.csWriteValue(pageDirectoryOffset, pageDirectoryEntry, OP_SIZE_DWORD)
        pageTableEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntry&0xfffff000)|pageTableOffset) # page table
        self.tlbTables.csWriteValue(((pageDirectoryOffset>>2)<<12)|pageTableOffset, pageTableEntry, OP_SIZE_DWORD)
    cdef void invalidatePage(self, unsigned int virtualAddress):
        cdef unsigned char updateDir
        cdef unsigned int pageDirectoryEntry, pageTableEntry, pageDirectoryOffset, pageTableOffset, pageDirectoryEntryV, i, j,
        pageDirectoryOffset = (virtualAddress>>22) << 2
        pageTableOffset = ((virtualAddress>>12)&0x3ff) << 2
        pageDirectoryEntryV = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|pageDirectoryOffset)&0xfffff000 # page directory
        virtualAddress = self.segments.main.mm.mmPhyReadValueUnsignedDword(pageDirectoryEntryV|pageTableOffset)&0xfffff000
        for i in range(0, PAGE_DIRECTORY_LENGTH, 4):
            updateDir = False
            pageDirectoryEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|i)
            if (not (pageDirectoryEntry & PAGE_PRESENT)):
                self.tlbDirectories.csWriteValue(i, 0, OP_SIZE_DWORD)
                self.tlbTables.csWrite(((i>>2)<<12), bytes(PAGE_DIRECTORY_LENGTH), PAGE_DIRECTORY_LENGTH)
                continue
            elif ((pageDirectoryEntry&0xfffff000) == pageDirectoryEntryV):
                self.tlbDirectories.csWriteValue(i, pageDirectoryEntry, OP_SIZE_DWORD)
                updateDir = True
            for j in range(0, PAGE_DIRECTORY_LENGTH, 4):
                pageTableEntry = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntry&0xfffff000)|j) # page table
                if (not (pageTableEntry & PAGE_PRESENT)):
                    self.tlbTables.csWriteValue(((i>>2)<<12)|j, 0, OP_SIZE_DWORD)
                    continue
                elif (virtualAddress == (pageTableEntry&0xfffff000) or updateDir):
                    self.tlbDirectories.csWriteValue(i, pageDirectoryEntry, OP_SIZE_DWORD)
                    self.tlbTables.csWriteValue(((i>>2)<<12)|j, pageTableEntry, OP_SIZE_DWORD)
    cdef unsigned char doPF(self, unsigned int virtualAddress, unsigned char written) except BITMASK_BYTE:
        cdef unsigned int errorFlags, pageDirectoryEntryMem, pageTableEntryMem
        self.invalidatePage(virtualAddress)
        pageDirectoryEntryMem = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|self.pageDirectoryOffset) # page directory
        pageTableEntryMem = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntryMem&0xfffff000)|self.pageTableOffset) # page table
        errorFlags = ((self.pageDirectoryEntry & PAGE_PRESENT) and (self.pageTableEntry & PAGE_PRESENT)) != 0
        errorFlags |= written << 1
        errorFlags |= (self.segments.registers.getCPL() == 3) << 2
        # TODO: reserved bits are set ; only with 4MB pages ; << 3
        #errorFlags |= self.instrFetch << 4 # TODO: CR4
        #self.segments.main.debugEnabled = True
        self.segments.main.notice("Paging::doPF: savedEip=={0:#010x}; savedCs=={1:#06x}", self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
        self.segments.main.notice("Paging::doPF: virtualAddress=={0:#010x}; errorFlags=={1:#04x}", virtualAddress, errorFlags)
        self.segments.main.notice("Paging::doPF: PDEL=={0:#010x}, PTEL=={1:#010x}", self.pageDirectoryEntry, self.pageTableEntry)
        self.segments.main.notice("Paging::doPF: PDEM=={0:#010x}, PTEM=={1:#010x}", pageDirectoryEntryMem, pageTableEntryMem)
        self.segments.main.notice("Paging::doPF: PDO=={0:#06x}, PTO=={1:#06x}, PO=={2:#06x}", self.pageDirectoryOffset, self.pageTableOffset, self.pageOffset)
        #if (virtualAddress == 0xefbfdee0 and self.segments.registers.main.cpu.opcode == 0xc3):
        #if (virtualAddress == 0xffbfe000):
        IF 0:
            fp=open("info_4.bin","wb")
            fp.write(self.tlbDirectories.csRead(0, PAGE_DIRECTORY_LENGTH))
            fp.flush()
            fp.close()
            fp=open("info_5.bin","wb")
            fp.write(self.tlbTables.csRead(0, TLB_SIZE))
            fp.flush()
            fp.close()
            exit()
        self.segments.registers.regWriteDword(CPU_REGISTER_CR2, virtualAddress)
        self.segments.main.notice("Paging::doPF: test2")
        #if (virtualAddress == 0xc1000000 and self.segments.main.cpu.savedCs == 0x8 and self.segments.main.cpu.savedEip == 0x80134706):
        #    self.segments.main.debugEnabled = True
        #if (self.segments.main.cpu.savedCs == 0xff03 and self.segments.main.cpu.savedEip == 0x52b9):
        #    self.segments.main.debugEnabled = True
        #elif (self.segments.main.cpu.savedCs == 0xff03 and self.segments.main.cpu.savedEip == 0x52fa):
        #    self.segments.main.debugEnabled = True
        #if (self.segments.main.cpu.savedCs == 0xfd4f and self.segments.main.cpu.savedEip == 0x2627 and self.registers.regs[CPU_REGISTER_ECX]._union.dword.erx == 0x631):
        #    self.segments.main.debugEnabled = True
        self.instrFetch = self.implicitSV = False
        raise HirnwichseException(CPU_EXCEPTION_PF, errorFlags)
        #return 0
    cdef unsigned char readAddresses(self, unsigned int virtualAddress, unsigned char written) except BITMASK_BYTE:
        #self.segments.main.notice("Paging::readAddresses: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
        #self.invalidateTables(self.pageDirectoryBaseAddress, False)
        #self.invalidatePage(virtualAddress)
        #if (self.segments.registers.cacheDisabled):
        #    self.invalidateTable(virtualAddress)
        self.pageDirectoryOffset = (virtualAddress>>22) << 2
        self.pageTableOffset = ((virtualAddress>>12)&0x3ff) << 2
        self.pageOffset = virtualAddress&0xfff
        self.pageDirectoryEntry = self.tlbDirectories.csReadValueUnsigned(self.pageDirectoryOffset, OP_SIZE_DWORD) # page directory
        if (not self.pageDirectoryEntry):
            self.segments.main.notice("Paging::readAddresses: PDE-Entry is zero, reloading. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageDirectoryEntry, self.pageDirectoryBaseAddress|self.pageDirectoryOffset, virtualAddress)
            self.segments.main.notice("Paging::readAddresses: PDE-Entry is zero, reloading, PTE. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.tlbTables.csReadValueUnsigned(((self.pageDirectoryOffset>>2)<<12)|self.pageTableOffset, OP_SIZE_DWORD), (self.pageDirectoryEntry&0xfffff000)|self.pageTableOffset, virtualAddress)
            #self.invalidateTable(virtualAddress)
            self.invalidatePage(virtualAddress)
            self.pageDirectoryEntry = self.tlbDirectories.csReadValueUnsigned(self.pageDirectoryOffset, OP_SIZE_DWORD) # page directory
            self.segments.main.notice("Paging::readAddresses: PDE-Entry was zero, reloaded. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageDirectoryEntry, self.pageDirectoryBaseAddress|self.pageDirectoryOffset, virtualAddress)
            self.segments.main.notice("Paging::readAddresses: PDE-Entry was zero, reloaded, PTE. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.tlbTables.csReadValueUnsigned(((self.pageDirectoryOffset>>2)<<12)|self.pageTableOffset, OP_SIZE_DWORD), (self.pageDirectoryEntry&0xfffff000)|self.pageTableOffset, virtualAddress)
        if (not (self.pageDirectoryEntry & PAGE_PRESENT)):
            self.segments.main.notice("Paging::readAddresses: PDE-Entry is not present 1. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageDirectoryEntry, self.pageDirectoryBaseAddress|self.pageDirectoryOffset, virtualAddress)
            self.segments.main.notice("Paging::readAddresses: TODO! (savedEip: {0:#010x}, savedCs: {1:#06x})", self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
            #self.invalidateTable(virtualAddress)
            self.invalidatePage(virtualAddress)
            self.pageDirectoryEntry = self.tlbDirectories.csReadValueUnsigned(self.pageDirectoryOffset, OP_SIZE_DWORD) # page directory
            if (not (self.pageDirectoryEntry & PAGE_PRESENT)):
                self.segments.main.notice("Paging::readAddresses: PDE-Entry is not present 2. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageDirectoryEntry, self.pageDirectoryBaseAddress|self.pageDirectoryOffset, virtualAddress)
                self.doPF(virtualAddress, written)
                return BITMASK_BYTE
        elif (self.pageDirectoryEntry & PAGE_SIZE): # it's a 4MB page
            # size is 4MB if CR4/PSE is set
            # size is 2MB if CR4/PAE is set
            # I don't know which size is used if both, CR4/PSE && CR4/PAE, are set
            self.segments.main.notice("Paging::readAddresses: EIP: {0:#010x}, CS: {1:#06x}", self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
            self.segments.main.notice("Paging::readAddresses: PDE & PAGE_SIZE. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageDirectoryEntry, self.pageDirectoryBaseAddress|self.pageDirectoryOffset, virtualAddress)
            self.segments.main.exitError("Paging::readAddresses: 4MB pages are UNSUPPORTED yet.")
            return False
        self.pageTableEntry = self.tlbTables.csReadValueUnsigned(((self.pageDirectoryOffset>>2)<<12)|self.pageTableOffset, OP_SIZE_DWORD) # page table
        if (not self.pageTableEntry):
            self.segments.main.notice("Paging::readAddresses: PTE-Entry is zero, reloading. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageTableEntry, (self.pageDirectoryEntry&0xfffff000)|self.pageTableOffset, virtualAddress)
            #self.invalidateTable(virtualAddress)
            self.invalidatePage(virtualAddress)
            self.pageTableEntry = self.tlbTables.csReadValueUnsigned(((self.pageDirectoryOffset>>2)<<12)|self.pageTableOffset, OP_SIZE_DWORD) # page table
            self.segments.main.notice("Paging::readAddresses: PTE-Entry was zero, reloaded. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageTableEntry, (self.pageDirectoryEntry&0xfffff000)|self.pageTableOffset, virtualAddress)
        if (not (self.pageTableEntry & PAGE_PRESENT)):
            self.segments.main.notice("Paging::readAddresses: PTE-Entry is not present 1. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageTableEntry, (self.pageDirectoryEntry&0xfffff000)|self.pageTableOffset, virtualAddress)
            #self.invalidateTable(virtualAddress)
            self.invalidatePage(virtualAddress)
            self.pageTableEntry = self.tlbTables.csReadValueUnsigned(((self.pageDirectoryOffset>>2)<<12)|self.pageTableOffset, OP_SIZE_DWORD) # page table
            if (not (self.pageTableEntry & PAGE_PRESENT)):
                self.segments.main.notice("Paging::readAddresses: PTE-Entry is not present 2. (entry: {0:#010x}; addr: {1:#010x}; vaddr: {2:#010x})", self.pageTableEntry, (self.pageDirectoryEntry&0xfffff000)|self.pageTableOffset, virtualAddress)
                self.doPF(virtualAddress, written)
                return BITMASK_BYTE
        return True
    cdef unsigned char accessAllowed(self, unsigned int virtualAddress, unsigned char written, unsigned char refresh) except BITMASK_BYTE:
        cdef unsigned char cpl
        cpl = self.segments.registers.getCPL()
        if (refresh):
            self.readAddresses(virtualAddress, written)
        if (not self.implicitSV and ((cpl == 3 and (not (self.pageDirectoryEntry&PAGE_EVERY_RING and self.pageTableEntry&PAGE_EVERY_RING))) or \
          (written and ((cpl == 3 or self.segments.registers.writeProtectionOn) and not (self.pageDirectoryEntry&PAGE_WRITABLE and self.pageTableEntry&PAGE_WRITABLE))))):
            self.segments.main.notice("Paging::accessAllowed: doPF")
            self.doPF(virtualAddress, written)
            return BITMASK_BYTE
        return True
    cdef unsigned char setFlags(self, unsigned int virtualAddress, unsigned int dataSize, unsigned char written) except BITMASK_BYTE:
        cdef unsigned int pageDirectoryOffset, pageTableOffset, pageDirectoryEntry, pageTableEntry, pageDirectoryEntryMem, pageTableEntryMem, pageTablesEntryNew, origVirtualAddress
        # TODO: for now only handling 4KB pages. (very inefficient)
        if (not dataSize):
            return True
        origVirtualAddress = virtualAddress
        while (dataSize >= 0):
            pageDirectoryOffset = (virtualAddress>>22) << 2
            pageTableOffset = ((virtualAddress>>12)&0x3ff) << 2
            pageDirectoryEntry = self.tlbDirectories.csReadValueUnsigned(pageDirectoryOffset, OP_SIZE_DWORD) # page directory
            pageTableEntry = self.tlbTables.csReadValueUnsigned(((pageDirectoryOffset>>2)<<12)|pageTableOffset, OP_SIZE_DWORD) # page table
            if ((pageDirectoryEntry & PAGE_PRESENT) and (pageTableEntry & PAGE_PRESENT)):
                #self.segments.main.debug("Paging::setFlags: test3: pdo addr {0:#010x}; pto addr {1:#010x}", (self.pageDirectoryBaseAddress|pageDirectoryOffset), ((pageDirectoryEntry&0xfffff000)|pageTableOffset))
                #self.segments.main.debug("Paging::setFlags: test4: pdo {0:#010x}; pto {1:#010x}", pageDirectoryEntry, pageTableEntry)
                #self.segments.main.debug("Paging::setFlags: test5: pdo {0:#010x}; pto {1:#010x}", self.segments.main.mm.mmPhyReadValueUnsignedDword((self.pageDirectoryBaseAddress|pageDirectoryOffset)), self.segments.main.mm.mmPhyReadValueUnsignedDword(((pageDirectoryEntry&0xfffff000)|pageTableOffset)))
                pageDirectoryEntryMem = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|pageDirectoryOffset) # page directory
                if (not (pageDirectoryEntry & PAGE_WAS_USED) or (written and not (pageDirectoryEntry & PAGE_WRITTEN_ON_PAGE))):
                    pageTablesEntryNew = pageDirectoryEntry|(PAGE_WAS_USED | (written and PAGE_WRITTEN_ON_PAGE))
                    self.tlbDirectories.csWriteValue(pageDirectoryOffset, pageTablesEntryNew, OP_SIZE_DWORD)
                    if (pageDirectoryEntry&0xfffff19f == pageDirectoryEntryMem&0xfffff19f):
                        pageTablesEntryNew = pageDirectoryEntryMem|(PAGE_WAS_USED | (written and PAGE_WRITTEN_ON_PAGE))
                        self.segments.main.mm.mmPhyWriteValue(self.pageDirectoryBaseAddress|pageDirectoryOffset, pageTablesEntryNew, OP_SIZE_DWORD) # page directory
                if (not (pageTableEntry & PAGE_WAS_USED) or (written and not (pageTableEntry & PAGE_WRITTEN_ON_PAGE))):
                    pageTablesEntryNew = pageTableEntry|(PAGE_WAS_USED | (written and PAGE_WRITTEN_ON_PAGE))
                    self.tlbTables.csWriteValue(((pageDirectoryOffset>>2)<<12)|pageTableOffset, pageTablesEntryNew, OP_SIZE_DWORD)
                    pageTableEntryMem = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntryMem&0xfffff000)|pageTableOffset) # page table
                    if (pageDirectoryEntry&0xfffff19f == pageDirectoryEntryMem&0xfffff19f and pageTableEntry&0xfffff19f == pageTableEntryMem&0xfffff19f):
                        pageTablesEntryNew = pageTableEntryMem|(PAGE_WAS_USED | (written and PAGE_WRITTEN_ON_PAGE))
                        self.segments.main.mm.mmPhyWriteValue(((pageDirectoryEntryMem&0xfffff000)|pageTableOffset), pageTablesEntryNew, OP_SIZE_DWORD) # page table
                #self.segments.main.debug("Paging::setFlags: test6: pdo {0:#010x}; pto {1:#010x}", self.segments.main.mm.mmPhyReadValueUnsignedDword((self.pageDirectoryBaseAddress|pageDirectoryOffset)), self.segments.main.mm.mmPhyReadValueUnsignedDword(((pageDirectoryEntry&0xfffff000)|pageTableOffset)))
            if (not dataSize):
                break
            elif (dataSize < PAGE_DIRECTORY_LENGTH):
                virtualAddress += dataSize
                dataSize = 0
            else:
                virtualAddress += PAGE_DIRECTORY_LENGTH
                dataSize -= PAGE_DIRECTORY_LENGTH
        return True
    cdef unsigned int getPhysicalAddress(self, unsigned int virtualAddress, unsigned int dataSize, unsigned char written) except? BITMASK_BYTE:
        cdef unsigned int pageDirectoryEntryMem, pageTableEntryMem
        self.readAddresses(virtualAddress, written)
        self.accessAllowed(virtualAddress, written, False)
        self.setFlags(virtualAddress, dataSize, written)
        self.instrFetch = self.implicitSV = False
        if (self.segments.main.debugEnabled):
        #IF 1:
            #self.pageDirectoryEntry = self.tlbDirectories.csReadValueUnsigned(self.pageDirectoryOffset, OP_SIZE_DWORD) # page directory
            #self.pageTableEntry = self.tlbTables.csReadValueUnsigned(((self.pageDirectoryOffset>>2)<<12)|self.pageTableOffset, OP_SIZE_DWORD) # page table
            pageDirectoryEntryMem = self.segments.main.mm.mmPhyReadValueUnsignedDword(self.pageDirectoryBaseAddress|self.pageDirectoryOffset) # page directory
            pageTableEntryMem = self.segments.main.mm.mmPhyReadValueUnsignedDword((pageDirectoryEntryMem&0xfffff000)|self.pageTableOffset) # page table
            if (self.segments.main.debugEnabled):
            #if (self.segments.main.debugEnabled or self.pageDirectoryEntry != pageDirectoryEntryMem or self.pageTableEntry != pageTableEntryMem):
                self.segments.main.notice("Paging::readAddresses: savedEip=={0:#010x}; savedCs=={1:#06x}", self.segments.main.cpu.savedEip, self.segments.main.cpu.savedCs)
                self.segments.main.notice("Paging::readAddresses: virtualAddress=={0:#010x}; physicalAddress=={1:#010x}", virtualAddress, (self.pageTableEntry&0xfffff000)|self.pageOffset)
                self.segments.main.notice("Paging::readAddresses: PDEL=={0:#010x}, PTEL=={1:#010x}", self.pageDirectoryEntry, self.pageTableEntry)
                self.segments.main.notice("Paging::readAddresses: PDEM=={0:#010x}, PTEM=={1:#010x}", pageDirectoryEntryMem, pageTableEntryMem)
                self.segments.main.notice("Paging::readAddresses: PDO=={0:#06x}, PTO=={1:#06x}, PO=={2:#06x}", self.pageDirectoryOffset, self.pageTableOffset, self.pageOffset)
            if (self.pageDirectoryEntry != pageDirectoryEntryMem):
                if (self.pageDirectoryEntry&0xfffff19f != pageDirectoryEntryMem&0xfffff19f):
                    self.segments.main.notice("Paging::readAddresses: PDE too diff; virtualAddress=={0:#010x}", virtualAddress)
                else:
                    self.segments.main.notice("Paging::readAddresses: PDE diff; virtualAddress=={0:#010x}", virtualAddress)
            if (self.pageTableEntry != pageTableEntryMem):
                if (self.pageTableEntry&0xfffff19f != pageTableEntryMem&0xfffff19f):
                    self.segments.main.notice("Paging::readAddresses: PTE too diff; virtualAddress=={0:#010x}", virtualAddress)
                else:
                    self.segments.main.notice("Paging::readAddresses: PTE diff; virtualAddress=={0:#010x}", virtualAddress)
        return (self.pageTableEntry&0xfffff000)|self.pageOffset

cdef class Segments:
    def __init__(self, Registers registers, Hirnwichse main):
        self.registers = registers
        self.main = main
    cdef void reset(self) nogil:
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
    cdef unsigned char getSegType(self, unsigned short num):
        if (num & SELECTOR_USE_LDT):
            return self.ldt.getSegType(num)
        return self.gdt.getSegType(num)
    cdef void setSegType(self, unsigned short num, unsigned char segmentType):
        if (num & SELECTOR_USE_LDT):
            self.ldt.setSegType(num, segmentType)
            return
        self.gdt.setSegType(num, segmentType)
    cdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment) except BITMASK_BYTE:
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
    cdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned short segId) except BITMASK_BYTE:
        if (num & SELECTOR_USE_LDT):
            return self.ldt.checkSegmentLoadAllowed(num, segId)
        return self.gdt.checkSegmentLoadAllowed(num, segId)
    cdef unsigned char inLimit(self, unsigned short num) nogil:
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



