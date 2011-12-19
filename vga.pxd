
from mm cimport Mm, MmArea, ConfigSpace
from pygameUI cimport PygameUI


cdef class VRamArea(MmArea):
    cdef mmAreaWrite(self, unsigned long long mmPhyAddr, bytes data, unsigned long long dataSize)
    cdef handleVRamWrite(self, unsigned long long mmAreaAddr, unsigned long dataSize)


cdef class VGA_REGISTER_RAW(ConfigSpace):
    cpdef object main
    cdef Vga vga
    cdef unsigned short index
    cdef reset(self)
    cdef getIndex(self)
    cdef setIndex(self, unsigned short index)
    cdef indexAdd(self, unsigned short n)
    cdef indexSub(self, unsigned short n)
    cdef getData(self, unsigned char dataSize)
    cdef setData(self, unsigned long data, unsigned char dataSize)

cdef class CRT(VGA_REGISTER_RAW):
    pass

cdef class DAC(VGA_REGISTER_RAW): # PEL
    cdef unsigned char mask
    cdef setData(self, unsigned long data, unsigned char dataSize)
    cdef getMask(self)
    cdef setMask(self, unsigned char value)


cdef class GDC(VGA_REGISTER_RAW):
    pass

cdef class Sequencer(VGA_REGISTER_RAW):
    pass

cdef class ExtReg(VGA_REGISTER_RAW):
    cdef unsigned char miscOutReg
    cdef getMiscOutReg(self)
    cdef setMiscOutReg(self, unsigned char value)

cdef class AttrCtrlReg(VGA_REGISTER_RAW):
    cdef unsigned char flipFlop
    cdef setIndexData(self, unsigned long data, unsigned char dataSize)


cdef class Vga:
    cpdef object main
    cdef public PygameUI ui
    cdef Sequencer seq
    cdef CRT crt
    cdef GDC gdc
    cdef DAC dac
    cdef public ExtReg extreg
    cdef AttrCtrlReg attrctrlreg
    cdef unsigned char processVideoMem
    cdef setProcessVideoMem(self, unsigned char processVideoMem)
    cdef unsigned char getProcessVideoMem(self)
    cdef unsigned char getCorrectPage(self, unsigned char page)
    cdef writeCharacterTeletype(self, unsigned char c, short attr, unsigned char page, unsigned char updateCursor)
    cdef writeCharacter(self, unsigned long address, unsigned char c, short attr)
    cdef getAddrOfPos(self, unsigned char page, unsigned char x, unsigned char y)
    cdef unsigned short getCursorPosition(self, unsigned char page)
    cdef setCursorPosition(self, unsigned char page, unsigned short pos)
    cdef scrollDown(self, unsigned char page)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef VRamAddMemArea(self)
    cdef run(self)



