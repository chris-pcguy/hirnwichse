
from libc.stdint cimport *

from hirnwichse_main cimport Hirnwichse
from mm cimport ConfigSpace
from pci cimport PciDevice
from pysdlUI cimport PysdlUI


cdef class VGA_REGISTER_RAW:
    cdef ConfigSpace configSpace
    cdef Vga vga
    cdef uint16_t index
    cdef void reset(self) nogil
    cdef uint16_t getIndex(self) nogil
    cdef void setIndex(self, uint16_t index) nogil
    cdef void indexAdd(self, uint16_t n) nogil
    cdef void indexSub(self, uint16_t n) nogil
    cdef uint32_t getData(self, uint8_t dataSize) nogil
    cdef void setData(self, uint32_t data, uint8_t dataSize) nogil

cdef class CRT(VGA_REGISTER_RAW):
    cdef uint8_t protectRegisters

cdef class DAC(VGA_REGISTER_RAW): # PEL
    cdef uint8_t mask, state, readCycle, writeCycle, readIndex, writeIndex
    cdef uint8_t getWriteIndex(self) nogil
    cdef void setReadIndex(self, uint8_t index) nogil
    cdef void setWriteIndex(self, uint8_t index) nogil
    cdef uint8_t getMask(self) nogil
    cdef uint8_t getState(self) nogil
    cdef void setMask(self, uint8_t value) nogil


cdef class GDC(VGA_REGISTER_RAW):
    cdef void setData(self, uint32_t data, uint8_t dataSize) nogil

cdef class Sequencer(VGA_REGISTER_RAW):
    cdef void setData(self, uint32_t data, uint8_t dataSize) nogil

cdef class AttrCtrlReg(VGA_REGISTER_RAW):
    cdef uint8_t flipFlop, paletteEnabled
    cdef void setFlipFlop(self, uint8_t flipFlop) nogil
    cdef void setIndexData(self, uint32_t data, uint8_t dataSize) nogil

cdef class Vga:
    cdef Hirnwichse main
    cdef PysdlUI ui
    cdef Sequencer seq
    cdef CRT crt
    cdef GDC gdc
    cdef DAC dac
    cdef AttrCtrlReg attrctrlreg
    cdef PciDevice pciDevice
    cdef ConfigSpace plane0, plane1, plane2, plane3
    cdef uint8_t latchReg[4]
    cdef uint8_t processVideoMem, needLoadFont, readMap, writeMap, charSelA, charSelB, chain4, chainOddEven, oddEvenReadDisabled, oddEvenWriteDisabled, extMem, readMode, writeMode, bitMask, resetReg, enableResetReg, logicOp, rotateCount, charHeight, graphicalMode, miscReg, palette54, enable8Bit, shift256, colorPlaneEnable, colorSelect, colorCompare, colorDontCare, refreshScreen, retrace, addressSizeShift, alphaDis
    cdef uint16_t vde,
    cdef uint32_t videoMemBase, startAddress, offset, videoMemSize
    cdef double newTimer, oldTimer
    cdef void setStartAddress(self) nogil
    cdef uint32_t getColor(self, uint16_t color) nogil # RGBA
    cdef void readFontData(self) nogil
    cdef uint32_t translateBytes(self, uint32_t data) nogil
    cdef void refreshScreenFunction(self) nogil
    cdef char *vgaAreaReadHandler(self, uint32_t offset, uint32_t dataSize)
    cdef char *vgaAreaRead(self, uint32_t offset, uint32_t dataSize) nogil
    cdef void vgaAreaWriteHandler(self, uint32_t offset, uint32_t dataSize)
    cdef void vgaAreaWrite(self, uint32_t offset, uint32_t dataSize) nogil
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil
    cdef void run(self)



