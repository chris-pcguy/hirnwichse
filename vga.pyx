import sys, threading, time, mm, pygameUI

include "globals.pxi"

cimport mm

TEXTMODE_ADDR = 0xb8000
VGA_MEMAREA_ADDR = 0xa0000

VGA_SEQ_INDEX_ADDR = 0x3c4
VGA_SEQ_DATA_ADDR  = 0x3c5

VGA_SEQ_MAX_INDEX  = 1

VGA_SEQ_DATA_LENGTH = 256
VGA_CRT_DATA_LENGTH = 256
VGA_GDC_DATA_LENGTH = 256
VGA_DAC_DATA_LENGTH = 256
VGA_EXTREG_DATA_LENGTH = 256
VGA_ATTRCTRLREG_DATA_LENGTH = 256


VGA_CURSOR_BASE_ADDR  = 0x450
VGA_CURRENT_MODE_ADDR = 0x449
VGA_CURRENT_PAGE_ADDR = 0x462

cdef class VRamArea(mm.MmArea):
    def __init__(self, object mmObj, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly):
        mm.MmArea.__init__(self, mmObj, mmBaseAddr, mmAreaSize, mmReadOnly)
    cpdef mmAreaWrite(self, unsigned long long mmPhyAddr, bytes data, unsigned long long dataSize): # dataSize(type int) in bytes
        cdef unsigned long long mmAreaAddr
        mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        mm.MmArea.mmAreaWrite(self, mmPhyAddr, data, dataSize)
        self.handleVRamWrite(mmAreaAddr, dataSize)
    cpdef handleVRamWrite(self, unsigned long long mmAreaAddr, unsigned long dataSize):
        cdef list rectList = []
        cdef unsigned short x, y
        cdef bytes charstr
        ##mmAreaAddr -= self.mmBaseAddr # TODO
        if (mmAreaAddr % 2): # odd
            mmAreaAddr -= 1
        while (dataSize > 0):
            y, x = divmod(mmAreaAddr//2, 80)
            charstr = bytes(self.mmAreaData[mmAreaAddr:mmAreaAddr+2])
            if (self.main.platform.vga.ui):
                rectList.append(self.main.platform.vga.ui.putChar(x, y, chr(charstr[0]), charstr[1]))
            mmAreaAddr += 2
            dataSize   -= min(dataSize, 2)
        if (self.main.platform.vga.ui):
            self.main.platform.vga.ui.updateScreen(rectList)


cdef class VGA_REGISTER_RAW:
    cdef object main, vga, csData
    cdef unsigned short csDataSize, index
    def __init__(self, unsigned short csDataSize, object vga, object main):
        self.csDataSize = csDataSize
        self.vga  = vga
        self.main = main
        self.reset()
    def reset(self):
        self.csData  = mm.ConfigSpace(self.csDataSize, self.main)
        self.index = 0
    def getIndex(self):
        return self.index
    def setIndex(self, unsigned short index):
        self.index = index
    def indexAdd(self, unsigned short n):
        self.index += n
    def indexSub(self, unsigned short n):
        self.index -= n
    def getData(self, unsigned char dataSize):
        return self.csData.csReadValue(self.index, dataSize)
    def setData(self, unsigned long long data, unsigned char dataSize):
        self.csData.csWriteValue(self.index, data, dataSize)
    

cdef class CRT(VGA_REGISTER_RAW):
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_CRT_DATA_LENGTH, vga, main)

cdef class DAC(VGA_REGISTER_RAW): # PEL
    cdef unsigned char mask
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_DAC_DATA_LENGTH, vga, main)
        self.mask = 0xff
    def setData(self, int data, unsigned char dataSize):
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        self.indexAdd(1)
    def getMask(self):
        return self.mask
    def setMask(self, int value):
        self.mask = value


cdef class GDC(VGA_REGISTER_RAW):
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_GDC_DATA_LENGTH, vga, main)

cdef class Sequencer(VGA_REGISTER_RAW):
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_SEQ_DATA_LENGTH, vga, main)

cdef class ExtReg(VGA_REGISTER_RAW):
    cdef unsigned char miscOutReg
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_EXTREG_DATA_LENGTH, vga, main)
        self.miscOutReg = 0
    def getMiscOutReg(self):
        return self.miscOutReg
    def setMiscOutReg(self, int value):
        self.miscOutReg = value

cdef class AttrCtrlReg(VGA_REGISTER_RAW):
    cdef unsigned char flipFlop
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_ATTRCTRLREG_DATA_LENGTH, vga, main)
        self.flipFlop = False
    def setIndexData(self, unsigned long long data, unsigned char dataSize):
        if (not self.flipFlop):
            self.setIndex(data)
        else:
            self.setData(data, dataSize)
        self.flipFlop = not self.flipFlop
    


cdef class Vga:
    cdef object main, seq, crt, gdc, dac, extreg, attrctrlreg
    cdef public object ui
    def __init__(self, object main):
        self.main = main
        self.seq = Sequencer(self, self.main)
        self.crt = CRT(self, self.main)
        self.gdc = GDC(self, self.main)
        self.dac = DAC(self, self.main)
        self.extreg = ExtReg(self, self.main)
        self.attrctrlreg = AttrCtrlReg(self, self.main)
        self.ui = None
        if (not self.main.noUI):
            self.ui = pygameUI.pygameUI(self, self.main)
    def writeCharacterTeletype(self, unsigned char c, short attr, unsigned char page, unsigned char updateCursor=True):
        cdef unsigned char x, y
        cdef unsigned long address
        if (page == 0xff):
            page = self.main.mm.mmPhyReadValue(VGA_CURRENT_PAGE_ADDR, 1)
        x, y = self.getCursorPosition(page)
        address = self.getAddrOfPos(page, x, y)
        if (c == 0x7): # beep
            pass
        elif (c == 0x8): # BS == backspace
            if (x > 0):
                x -= 1
        elif (c == 0x9): # TAB == horizontal tabulator
            for i in range( 8-(x%8) ):
                self.writeCharacter(address, 0x20, attr) # space
        elif (c == 0xa): # LF == Newline/Linefeed
            y += 1
        elif (c == 0xd): # CR == carriage return
            x = 0
        else:
            self.writeCharacter(address, c, attr)
            x += 1
        if (updateCursor):
            self.setCursorPosition(page, x, y)
    def writeCharacter(self, unsigned long address, unsigned char c, short attr):
        cdef bytes charData
        if (attr == -1):
            charData = bytes( [c] )
            self.main.mm.mmPhyWrite(address, charData, 1)
        else:
            charData = bytes( [c, attr] )
            self.main.mm.mmPhyWrite(address, charData, 2)
    def getAddrOfPos(self, unsigned char page, unsigned char x, unsigned char y):
        cdef unsigned long offset
        offset = ((y*80)+x)*2
        return TEXTMODE_ADDR+(page*0x1000)+offset
    def getCursorPosition(self, unsigned char page):
        cdef bytes cursorData
        if (page > 7):
            self.main.printMsg("VGA::getCursorPosition: page > 7 (page: {0:d})", page)
            return
        cursorData = self.main.mm.mmPhyRead(VGA_CURSOR_BASE_ADDR+(page*2), 2)
        return cursorData[0], cursorData[1] # x, y ## because of little endian
    def setCursorPosition(self, unsigned char page, unsigned char x, unsigned char y):
        cdef bytes cursorData
        cursorData = bytes( [x, y] )
        self.main.mm.mmPhyWrite(VGA_CURSOR_BASE_ADDR+(page*2), cursorData, 2)
    def inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x3c5):
                self.seq.getData(dataSize)
            elif (ioPortAddr == 0x3c6):
                return self.dac.getMask()
            elif (ioPortAddr == 0x3c8):
                return self.dac.getIndex()
            elif (ioPortAddr == 0x3cc):
                return self.extreg.getMiscOutReg()
            elif (ioPortAddr == 0x3c1):
                return self.attrctrlreg.getData(dataSize)
            elif (ioPortAddr == 0x3da):
                return 0
            else:
                self.main.printMsg("inPort: port {0:#04x} not supported. (dataSize byte)", ioPortAddr)
        else:
            if (ioPortAddr == 0x3cc):
                return self.extreg.getMiscOutReg()
            else:
                self.main.exitError("inPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        return 0
    def outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x400): # Bochs' Panic Port
                sys.stdout.write(chr(data))
                sys.stdout.flush()
            elif (ioPortAddr == 0x401): # Bochs' Panic Port2
                sys.stdout.write(chr(data))
                sys.stdout.flush()
            elif (ioPortAddr in (0x402,0x500,0x504)): # Bochs' Info Port
                sys.stdout.write(chr(data))
                sys.stdout.flush()
            elif (ioPortAddr == 0x403): # Bochs' Debug Port
                sys.stdout.write(chr(data))
                sys.stdout.flush()
            elif (ioPortAddr == 0x3c0):
                self.attrctrlreg.setIndexData(data, dataSize)
            elif (ioPortAddr == 0x3c2):
                self.extreg.setMiscOutReg(data)
            elif (ioPortAddr == 0x3c4):
                self.seq.setIndex(data)
            elif (ioPortAddr == 0x3c5):
                self.seq.setData(data, dataSize)
            elif (ioPortAddr == 0x3c6):
                self.dac.setMask(data)
            elif (ioPortAddr == 0x3c8):
                self.dac.setIndex(data)
            elif (ioPortAddr == 0x3c9):
                self.dac.setData(data, dataSize)
            elif (ioPortAddr == 0x3ce):
                self.gdc.setIndex(data)
            elif (ioPortAddr == 0x3cf):
                self.gdc.setData(data, dataSize)
            elif (ioPortAddr == 0x3d4):
                self.crt.setIndex(data)
            elif (ioPortAddr == 0x3d5):
                self.crt.setData(data, dataSize)
            else:
                self.main.printMsg("outPort: port {0:#04x} not supported. (dataSize byte, data {1:#04x})", ioPortAddr, data)
        elif (dataSize == OP_SIZE_WORD):
            if (ioPortAddr == 0x3c4):
                self.seq.setIndex(data)
            elif (ioPortAddr == 0x3c5):
                self.seq.setData(data, dataSize)
            elif (ioPortAddr == 0x3ce):
                self.gdc.setIndex(data)
            elif (ioPortAddr == 0x3cf):
                self.gdc.setData(data, dataSize)
            elif (ioPortAddr == 0x3d4):
                self.crt.setIndex(data)
            elif (ioPortAddr == 0x3d5):
                self.crt.setData(data, dataSize)
            else:
                self.main.printMsg("outPort: port {0:#04x} not supported. (dataSize word, data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        return
    def VRamAddMemArea(self):
        self.main.mm.mmAddArea(TEXTMODE_ADDR, 4000, mmAreaObject=VRamArea)
        ##self.main.mm.mmAddArea(VGA_MEMAREA_ADDR, 0x4000, mmAreaObject=VRamArea)
    def run(self):
        self.VRamAddMemArea()
        if (self.ui):
            self.ui.run()
        self.main.platform.addReadHandlers((0x3c1,0x3c5,0x3cc,0x3c8,0x3da), self.inPort)
        self.main.platform.addWriteHandlers((0x3c0, 0x3c2, 0x3c4, 0x3c5, 0x3c6, 0x3c7, 0x3c8, 0x3c9, 0x3ce, 0x3cf, 0x3d4, 0x3d5, 0x400, 0x401, 0x402, 0x403, 0x500, 0x504), self.outPort)
        


