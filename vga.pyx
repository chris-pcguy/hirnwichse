
import sys, threading, time

from pygameUI import PygameUI

include "globals.pxi"



cdef class VRamArea(MmArea):
    def __init__(self, Mm mmObj, unsigned long long mmBaseAddr, unsigned long long mmAreaSize, unsigned char mmReadOnly):
        MmArea.__init__(self, mmObj, mmBaseAddr, mmAreaSize, mmReadOnly)
    cdef mmAreaWrite(self, unsigned long long mmPhyAddr, bytes data, unsigned long long dataSize): # dataSize(type int) in bytes
        cdef unsigned long long mmAreaAddr
        mmAreaAddr = mmPhyAddr-self.mmBaseAddr
        MmArea.mmAreaWrite(self, mmPhyAddr, data, dataSize)
        if (self.main.platform.vga.processVideoMem and (<ExtReg>self.main.platform.vga.extreg).getMiscOutReg()&VGA_EXTREG_PROCESS_RAM):
            self.handleVRamWrite(mmAreaAddr, dataSize)
    cdef handleVRamWrite(self, unsigned long long mmAreaAddr, unsigned long dataSize):
        cdef list rectList
        cdef unsigned short x, y
        cdef bytes charstr
        rectList = list()
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
    def __init__(self, unsigned short registerSize, object vga, object main):
        self.registerSize = registerSize
        self.vga  = vga
        self.main = main
        self.index = 0
    cdef reset(self):
        self.configSpace.csResetData()
        self.index = 0
    cdef getIndex(self):
        return self.index
    cdef setIndex(self, unsigned short index):
        self.index = index
    cdef indexAdd(self, unsigned short n):
        self.index += n
    cdef indexSub(self, unsigned short n):
        self.index -= n
    cdef getData(self, unsigned char dataSize):
        return self.configSpace.csReadValue(self.index, dataSize, False)
    cdef setData(self, unsigned long long data, unsigned char dataSize):
        self.configSpace.csWriteValue(self.index, data, dataSize)
    cdef run(self):
        self.configSpace  = ConfigSpace(self.registerSize)
        self.configSpace.run()

cdef class CRT(VGA_REGISTER_RAW):
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_CRT_DATA_LENGTH, vga, main)

cdef class DAC(VGA_REGISTER_RAW): # PEL
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_DAC_DATA_LENGTH, vga, main)
        self.mask = 0xff
    cdef setData(self, unsigned long long data, unsigned char dataSize):
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        self.indexAdd(1)
    cdef getMask(self):
        return self.mask
    cdef setMask(self, unsigned char value):
        self.mask = value


cdef class GDC(VGA_REGISTER_RAW):
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_GDC_DATA_LENGTH, vga, main)

cdef class Sequencer(VGA_REGISTER_RAW):
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_SEQ_DATA_LENGTH, vga, main)

cdef class ExtReg(VGA_REGISTER_RAW):
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_EXTREG_DATA_LENGTH, vga, main)
        self.miscOutReg = VGA_EXTREG_PROCESS_RAM
    cdef getMiscOutReg(self):
        return self.miscOutReg
    cdef setMiscOutReg(self, unsigned char value):
        self.miscOutReg = value

cdef class AttrCtrlReg(VGA_REGISTER_RAW):
    def __init__(self, object vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_ATTRCTRLREG_DATA_LENGTH, vga, main)
        self.flipFlop = False
    cdef setIndexData(self, unsigned long long data, unsigned char dataSize):
        if (not self.flipFlop):
            self.setIndex(data)
        else:
            self.setData(data, dataSize)
        self.flipFlop = not self.flipFlop



cdef class Vga:
    def __init__(self, object main):
        self.main = main
        self.seq = Sequencer(self, self.main)
        self.crt = CRT(self, self.main)
        self.gdc = GDC(self, self.main)
        self.dac = DAC(self, self.main)
        self.extreg = ExtReg(self, self.main)
        self.attrctrlreg = AttrCtrlReg(self, self.main)
        self.processVideoMem = True
        self.ui = None
        if (not self.main.noUI):
            self.ui = PygameUI(self, self.main)
    cdef setProcessVideoMem(self, unsigned char processVideoMem):
        self.processVideoMem = processVideoMem
    cdef unsigned char getCorrectPage(self, unsigned char page):
        if (page == 0xff):
            page = (<Mm>self.main.mm).mmPhyReadValueUnsigned(VGA_CURRENT_PAGE_ADDR, 1)
        elif (page > 7):
            self.main.printMsg("VGA::getCorrectPage: page: {0:d}", page)
        return page
    cdef writeCharacterTeletype(self, unsigned char c, short attr, unsigned char page, unsigned char updateCursor):
        cdef unsigned char x, y, i
        cdef unsigned short cursorPos
        cdef unsigned long address
        page = self.getCorrectPage(page)
        cursorPos = self.getCursorPosition(page)
        y, x = cursorPos>>8, cursorPos&0xff
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
            self.setCursorPosition(page, (y<<8)|x)
    cdef writeCharacter(self, unsigned long address, unsigned char c, short attr):
        cdef bytes charData
        if (attr == -1):
            charData = bytes( [c] )
            (<Mm>self.main.mm).mmPhyWrite(address, charData, 1)
        else:
            charData = bytes( [c, attr] )
            (<Mm>self.main.mm).mmPhyWrite(address, charData, 2)
    cdef getAddrOfPos(self, unsigned char page, unsigned char x, unsigned char y):
        cdef unsigned long offset
        page = self.getCorrectPage(page)
        offset = ((y*80)+x)*2
        return VGA_TEXTMODE_ADDR+(page*0x1000)+offset
    cdef unsigned short getCursorPosition(self, unsigned char page): # return x, y
        cdef unsigned short pos
        page = self.getCorrectPage(page)
        if (page > 7):
            self.main.printMsg("VGA::getCursorPosition: page > 7 (page: {0:d})", page)
            return 0
        pos = (<Mm>self.main.mm).mmPhyReadValueUnsigned(VGA_CURSOR_BASE_ADDR+(page*2), 2)
        return pos
    cdef setCursorPosition(self, unsigned char page, unsigned short pos):
        page = self.getCorrectPage(page)
        if (page > 7):
            self.main.printMsg("VGA::setCursorPosition: page > 7 (page: {0:d})", page)
            return
        (<Mm>self.main.mm).mmPhyWriteValue(VGA_CURSOR_BASE_ADDR+(page*2), pos, 2)
    cdef scrollDown(self, unsigned char page):
        cdef bytes oldData
        cdef unsigned long oldAddr
        self.setProcessVideoMem(False)
        page = self.getCorrectPage(page)
        oldAddr = self.getAddrOfPos(page, 0, 0)
        oldData = (<Mm>self.main.mm).mmPhyRead(oldAddr+160, 3840) # 3840==24*80*2
        (<Mm>self.main.mm).mmPhyWrite(oldAddr, oldData, 3840)
        (<Mm>self.main.mm).mmPhyWrite(oldAddr+3840, b'\x00'*160, 160)
        self.setProcessVideoMem(True)
        oldData = (<Mm>self.main.mm).mmPhyRead(oldAddr, 4000)
        (<Mm>self.main.mm).mmPhyWrite(oldAddr, oldData, 4000)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
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
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
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
    cdef VRamAddMemArea(self):
        (<Mm>self.main.mm).mmAddArea(VGA_TEXTMODE_ADDR, 4000, False, <MmArea>VRamArea)
        ##(<Mm>self.main.mm).mmAddArea(VGA_MEMAREA_ADDR, 0x4000, False, VRamArea)
    cdef run(self):
        self.seq.run()
        self.crt.run()
        self.gdc.run()
        self.dac.run()
        self.extreg.run()
        self.attrctrlreg.run()
        ####
        self.VRamAddMemArea()
        if (self.ui):
            self.ui.run()
        #self.main.platform.addReadHandlers((0x3c1, 0x3c5, 0x3cc, 0x3c8, 0x3da), self)
        #self.main.platform.addWriteHandlers((0x3c0, 0x3c2, 0x3c4, 0x3c5, 0x3c6, 0x3c7, 0x3c8, 0x3c9, 0x3ce, \
        #                                     0x3cf, 0x3d4, 0x3d5, 0x400, 0x401, 0x402, 0x403, 0x500, 0x504), self)


