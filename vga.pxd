
from mm cimport Mm, MmArea, MmAreaWriteType, ConfigSpace
from pygameUI cimport PygameUI


cdef class VGA_REGISTER_RAW(ConfigSpace):
    cdef Vga vga
    cdef unsigned short index
    cdef void reset(self)
    cdef unsigned short getIndex(self)
    cdef void setIndex(self, unsigned short index)
    cdef void indexAdd(self, unsigned short n)
    cdef void indexSub(self, unsigned short n)
    cdef unsigned int getData(self, unsigned char dataSize)
    cdef void setData(self, unsigned int data, unsigned char dataSize)

cdef class CRT(VGA_REGISTER_RAW):
    cdef unsigned char protectRegisters
    cdef void setData(self, unsigned int data, unsigned char dataSize)

cdef class DAC(VGA_REGISTER_RAW): # PEL
    cdef unsigned char mask, state, readCycle, writeCycle, readIndex, writeIndex
    cdef unsigned short getReadIndex(self)
    cdef unsigned short getWriteIndex(self)
    cdef void setReadIndex(self, unsigned short index)
    cdef void setWriteIndex(self, unsigned short index)
    cdef unsigned int getData(self, unsigned char dataSize)
    cdef void setData(self, unsigned int data, unsigned char dataSize)
    cdef unsigned char getMask(self)
    cdef unsigned char getState(self)
    cdef void setMask(self, unsigned char value)


cdef class GDC(VGA_REGISTER_RAW):
    cdef void setData(self, unsigned int data, unsigned char dataSize)

cdef class Sequencer(VGA_REGISTER_RAW):
    pass

cdef class ExtReg(VGA_REGISTER_RAW):
    cdef unsigned char miscOutReg
    cdef unsigned char getColorEmulation(self)
    cdef unsigned char getMiscOutReg(self)
    cdef void setMiscOutReg(self, unsigned char value)

cdef class AttrCtrlReg(VGA_REGISTER_RAW):
    cdef unsigned char flipFlop, videoEnabled
    cdef void setIndex(self, unsigned short index)
    cdef void setFlipFlop(self, unsigned char flipFlop)
    cdef void setIndexData(self, unsigned int data, unsigned char dataSize)
    cdef unsigned int getData(self, unsigned char dataSize)
    cdef void setData(self, unsigned int data, unsigned char dataSize)

cdef class Vga:
    cpdef object main
    cpdef public PygameUI ui
    cdef unsigned char needLoadFont
    cdef unsigned long videoMemBase, videoMemSize
    cdef Sequencer seq
    cdef CRT crt
    cdef GDC gdc
    cdef DAC dac
    cdef ExtReg extreg
    cdef AttrCtrlReg attrctrlreg
    cdef unsigned char processVideoMem
    cpdef tuple getColor(self, unsigned char color) # ARGB
    cdef void readFontData(self)
    cdef void setProcessVideoMem(self, unsigned char processVideoMem)
    cdef unsigned char getProcessVideoMem(self)
    cdef unsigned char getCorrectPage(self, unsigned char page)
    cdef void writeCharacterTeletype(self, unsigned char c, signed short attr, unsigned char page, unsigned char updateCursor)
    cdef void writeCharacter(self, unsigned int address, unsigned char c, signed short attr)
    cdef unsigned int getAddrOfPos(self, unsigned char page, unsigned char x, unsigned char y)
    cdef unsigned short getCursorPosition(self, unsigned char page)
    cdef void setCursorPosition(self, unsigned char page, unsigned short pos)
    cdef void scrollUp(self, unsigned char page, signed short attr, unsigned short lines)
    cpdef vgaAreaWrite(self, MmArea mmArea, unsigned int offset, unsigned int dataSize)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cpdef run(self)



