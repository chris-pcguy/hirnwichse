
cimport mm

cdef class Gdt:
    cpdef public object segments, registers, main
    cdef public unsigned char needFlush, setGdtLoadedTo, gdtLoaded
    cdef unsigned long long tableBase
    cdef unsigned long tableLimit
    cpdef loadTable(self, unsigned long long tableBase, unsigned long tableLimit)
    cpdef tuple getBaseLimit(self)
    cpdef tuple getEntry(self, unsigned short num)
    cpdef unsigned char getSegSize(self, unsigned short num)
    cpdef unsigned char getSegAccess(self, unsigned short num)
    cpdef unsigned char isSegPresent(self, unsigned short num)
    cpdef unsigned char isCodeSeg(self, unsigned short num)
    cpdef unsigned char isSegReadableWritable(self, unsigned short num)
    cpdef unsigned char isSegConforming(self, unsigned short num)
    cpdef unsigned char getSegDPL(self, unsigned short num)
    cpdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment)
    cpdef unsigned char checkReadAllowed(self, unsigned short num, unsigned char doException)
    cpdef unsigned char checkWriteAllowed(self, unsigned short num, unsigned char doException)
    cpdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment, unsigned char doException)

cdef class Idt:
    cpdef public object segments, main
    cdef public unsigned long long tableBase
    cdef public unsigned long tableLimit
    cpdef loadTable(self, unsigned long long tableBase, unsigned long tableLimit)
    cpdef tuple getBaseLimit(self)
    cpdef tuple getEntry(self, unsigned short num)
    cpdef unsigned char isEntryPresent(self, unsigned short num)
    cpdef unsigned char getEntryNeededDPL(self, unsigned short num)
    cpdef unsigned char getEntrySize(self, unsigned short num)
    cpdef tuple getEntryRealMode(self, unsigned short num)
    cpdef run(self, unsigned long long tableBase, unsigned long tableLimit)

cdef class Segments:
    cpdef public object main, cpu, registers, gdt, ldt, idt
    cpdef reset(self)
    cpdef unsigned long getBaseAddr(self, unsigned short segId) # segId == segments regId
    cpdef unsigned long getRealAddr(self, unsigned short segId, long long offsetAddr)
    cpdef unsigned char getSegSize(self, unsigned short segId) # segId == segments regId
    cpdef unsigned char isSegPresent(self, unsigned short segId) # segId == segments regId
    cpdef unsigned char getOpSegSize(self, unsigned short segId) # segId == segments regId
    cpdef unsigned char getAddrSegSize(self, unsigned short segId) # segId == segments regId
    cpdef tuple getOpAddrSegSize(self, unsigned short segId) # segId == segments regId
    cpdef unsigned char getSegAccess(self, unsigned short num)
    cpdef unsigned char isCodeSeg(self, unsigned short num)
    cpdef unsigned char isSegReadableWritable(self, unsigned short num)
    cpdef unsigned char isSegConforming(self, unsigned short num)
    cpdef unsigned char getSegDPL(self, unsigned short num)
    cpdef unsigned char checkAccessAllowed(self, unsigned short num, unsigned char isStackSegment)
    cpdef unsigned char checkReadAllowed(self, unsigned short num, unsigned char doException)
    cpdef unsigned char checkWriteAllowed(self, unsigned short num, unsigned char doException)
    cpdef unsigned char checkSegmentLoadAllowed(self, unsigned short num, unsigned char loadStackSegment, unsigned char doException)
    cpdef run(self)

cdef class Registers:
    cpdef public object main, cpu, segments
    cpdef public mm.ConfigSpace regs
    cdef public unsigned char lockPrefix, repPrefix, segmentOverridePrefix, operandSizePrefix, addressSizePrefix, cpl, iopl
    cpdef reset(self)
    cpdef resetPrefixes(self)
    cpdef unsigned short getRegSize(self, unsigned short regId) # return size in bits
    cpdef unsigned short segRead(self, unsigned short segId) # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
    cpdef unsigned short segWrite(self, unsigned short segId, unsigned short segValue) # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
    cpdef long long regRead(self, unsigned short regId, unsigned char signed) # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
    cpdef unsigned long regWrite(self, unsigned short regId, unsigned long value) # WARNING!!!: NEVER TRY to use 'LITTLE_ENDIAN' as byteorder here, IT WON'T WORK!!!!
    cpdef unsigned long regAdd(self, unsigned short regId, long long value)
    cpdef unsigned long regAdc(self, unsigned short regId, unsigned long value)
    cpdef unsigned long regSub(self, unsigned short regId, unsigned long value)
    cpdef unsigned long regSbb(self, unsigned short regId, unsigned long value)
    cpdef unsigned long regXor(self, unsigned short regId, unsigned long value)
    cpdef unsigned long regAnd(self, unsigned short regId, unsigned long value)
    cpdef unsigned long regOr (self, unsigned short regId, unsigned long value)
    cpdef unsigned long regNeg(self, unsigned short regId)
    cpdef unsigned long regNot(self, unsigned short regId)
    cpdef unsigned long regWriteWithOp(self, unsigned short regId, unsigned long value, unsigned char valueOp)
    cpdef unsigned long valSetBit(self, unsigned long value, unsigned char bit, unsigned char state)
    cpdef unsigned char valGetBit(self, unsigned long value, unsigned char bit) # return True if bit is set, otherwise False
    cpdef unsigned long getEFLAG(self, unsigned long flags)
    cpdef unsigned long setEFLAG(self, unsigned long flags, unsigned char flagState)
    cpdef unsigned long getFlag(self, unsigned short regId, unsigned long flags)
    cpdef unsigned short getWordAsDword(self, unsigned short regWord, unsigned char wantRegSize)
    cpdef setSZP(self, unsigned long value, unsigned char regSize)
    cpdef setSZP_O0(self, unsigned long value, unsigned char regSize)
    cpdef setSZP_C0_O0_A0(self, unsigned long value, unsigned char regSize)
    cpdef unsigned long long getRMValueFull(self, tuple rmNames, unsigned char rmSize)
    cpdef long long modRMLoad(self, tuple rmOperands, unsigned char regSize, unsigned char signed, unsigned char allowOverride) # imm == unsigned ; disp == signed; regSize in bits
    cpdef unsigned long long modRMSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value, unsigned char allowOverride, unsigned char valueOp) # imm == unsigned ; disp == signed; stdAllowOverride==True, stdValueOp==OPCODE_SAVE
    cpdef unsigned short modSegLoad(self, tuple rmOperands, unsigned char regSize) # imm == unsigned ; disp == signed
    cpdef unsigned short modSegSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value) # imm == unsigned ; disp == signed
    cpdef long long modRLoad(self, tuple rmOperands, unsigned char regSize, unsigned char signed) # imm == unsigned ; disp == signed
    cpdef unsigned long long modRSave(self, tuple rmOperands, unsigned char regSize, unsigned long long value, unsigned char valueOp) # imm == unsigned ; disp == signed
    cpdef unsigned short getRegValueWithFlags(self, unsigned char modRMflags, unsigned char reg, unsigned char operSize)
    cdef tuple sibOperands(self, unsigned char mod)
    cpdef tuple modRMOperands(self, unsigned char regSize, unsigned char modRMflags) # imm == unsigned ; disp == signed ; regSize in bytes
    cpdef tuple modRMOperandsResetEip(self, unsigned char regSize, unsigned char modRMflags)
    cpdef unsigned char getCond(self, unsigned char index)
    cpdef setFullFlags(self, long long reg0, long long reg1, unsigned char regSize, unsigned char method, unsigned char signed) # regSize in bits
    cpdef checkMemAccessRights(self, unsigned short segId, unsigned char write)
    cpdef run(self)


