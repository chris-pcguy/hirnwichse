
from mm cimport Mm, MmArea, MmAreaWriteType, ConfigSpace
from pci cimport Pci, PciDevice
from pysdlUI cimport PysdlUI


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
    cdef unsigned char getWriteIndex(self)
    cdef void setReadIndex(self, unsigned char index)
    cdef void setWriteIndex(self, unsigned char index)
    cdef unsigned int getData(self, unsigned char dataSize)
    cdef void setData(self, unsigned int data, unsigned char dataSize)
    cdef unsigned char getMask(self)
    cdef unsigned char getState(self)
    cdef void setMask(self, unsigned char value)


cdef class GDC(VGA_REGISTER_RAW):
    cdef void setData(self, unsigned int data, unsigned char dataSize)

cdef class Sequencer(VGA_REGISTER_RAW):
    cdef void setData(self, unsigned int data, unsigned char dataSize)

cdef class AttrCtrlReg(VGA_REGISTER_RAW):
    cdef unsigned char flipFlop, paletteEnabled
    cdef void setIndex(self, unsigned short index)
    cdef void setFlipFlop(self, unsigned char flipFlop)
    cdef void setIndexData(self, unsigned int data, unsigned char dataSize)
    cdef void setData(self, unsigned int data, unsigned char dataSize)

cdef class Vga:
    cpdef object main
    cpdef PysdlUI ui
    cdef Sequencer seq
    cdef CRT crt
    cdef GDC gdc
    cdef DAC dac
    cdef AttrCtrlReg attrctrlreg
    cdef PciDevice pciDevice
    cdef ConfigSpace plane0, plane1, plane2, plane3
    cdef unsigned char latchReg[4]
    cdef unsigned char processVideoMem, needLoadFont, readMap, writeMap, charSelA, charSelB, chain4, oddEvenReadDisabled, oddEvenWriteDisabled, extMem, readMode, writeMode, bitMask, resetReg, enableResetReg, logicOp, rotateCount, charHeight, graphicalMode, miscReg, palette54, enable8Bit, shift256, colorPlaneEnable, colorSelect, colorCompare, colorDontCare
    cdef unsigned short vde,
    cdef unsigned int videoMemBase, startAddress, offset, videoMemSize
    cdef double newTimer, oldTimer
    cpdef unsigned int getColor(self, unsigned char color) # RGBA
    cdef void readFontData(self)
    cdef void setProcessVideoMem(self, unsigned char processVideoMem)
    cdef unsigned char getProcessVideoMem(self)
    cdef unsigned char translateByte(self, unsigned char data, unsigned char plane)
    cdef bytes vgaAreaRead(self, MmArea mmArea, unsigned int offset, unsigned int dataSize)
    cdef void vgaAreaWrite(self, MmArea mmArea, unsigned int offset, unsigned int dataSize)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cpdef run(self)



