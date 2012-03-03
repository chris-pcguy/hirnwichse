
from sys import stdout

include "globals.pxi"



cdef class VRamArea(MmArea):
    def __init__(self, Mm mmObj, unsigned long mmBaseAddr, unsigned long mmAreaSize, unsigned char mmReadOnly):
        MmArea.__init__(self, mmObj, mmBaseAddr, mmAreaSize, mmReadOnly)
        self.memBaseAddrTextmodeBaseDiff = VGA_TEXTMODE_ADDR-self.mmBaseAddr
    cdef void mmAreaWrite(self, unsigned long mmAddr, char *data, unsigned long dataSize): # dataSize(type int) is count in bytes
        MmArea.mmAreaWrite(self, mmAddr, data, dataSize)
        # TODO: hardcoded to 80x25
        if (mmAddr < VGA_TEXTMODE_ADDR or mmAddr+dataSize > VGA_TEXTMODE_ADDR+4000):
            return
        if (self.main.pyroUI is None):
            return
        if ((<Vga>self.main.platform.vga).getProcessVideoMem() and (<ExtReg>(<Vga>self.main.platform.vga).extreg).getMiscOutReg()&VGA_EXTREG_PROCESS_RAM):
            mmAddr -= self.mmBaseAddr
            self.handleVRamWrite(mmAddr, dataSize)
    cpdef handleVRamWrite(self, unsigned long mmAreaAddr, unsigned long dataSize):
        cpdef list rectList
        cpdef unsigned char x, y
        cpdef bytes charstr
        rectList = list()
        if (mmAreaAddr % 2): # odd
            mmAreaAddr -= 1
        if (dataSize % 2):
            dataSize += 1
        # TODO: hardcoded to 80x25
        dataSize = min(dataSize, 4000) # 80*25*2
        while (dataSize > 0):
            y, x = divmod((mmAreaAddr-self.memBaseAddrTextmodeBaseDiff)//2, 80)
            charstr = bytes(self.mmAreaData[mmAreaAddr:mmAreaAddr+2])
            ###if ((<PygameUI>(<Vga>self.main.platform.vga).ui)):
            rectList.append(self.main.pyroUI.putChar(x, y, chr(charstr[0]), charstr[1]))
            mmAreaAddr += 2
            if (dataSize <= 2):
                break
            dataSize   -= 2
        ###if ((<PygameUI>(<Vga>self.main.platform.vga).ui)):
        self.main.pyroUI.updateScreen(rectList)


cdef class VGA_REGISTER_RAW(ConfigSpace):
    def __init__(self, unsigned long registerSize, Vga vga, object main):
        self.vga  = vga
        self.index = 0
        ConfigSpace.__init__(self, registerSize, main)
    cdef void reset(self):
        self.csResetData()
        self.index = 0
    cdef unsigned short getIndex(self):
        return self.index
    cdef void setIndex(self, unsigned short index):
        self.index = index
    cdef void indexAdd(self, unsigned short n):
        self.index += n
    cdef void indexSub(self, unsigned short n):
        self.index -= n
    cdef unsigned long getData(self, unsigned char dataSize):
        return self.csReadValueUnsigned(self.index, dataSize)
    cdef void setData(self, unsigned long data, unsigned char dataSize):
        self.csWriteValue(self.index, data, dataSize)

cdef class CRT(VGA_REGISTER_RAW):
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_CRT_AREA_SIZE, vga, main)

cdef class DAC(VGA_REGISTER_RAW): # PEL
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_DAC_AREA_SIZE, vga, main)
        self.readIndex = self.writeIndex = 0
        self.mask = 0xff
    cdef unsigned short getReadIndex(self):
        return self.readIndex
    cdef unsigned short getWriteIndex(self):
        return self.writeIndex
    cdef void setReadIndex(self, unsigned short index):
        self.readIndex = index
    cdef void setWriteIndex(self, unsigned short index):
        self.writeIndex = index
    cdef unsigned long getData(self, unsigned char dataSize):
        cdef unsigned long retData
        retData = self.csReadValueUnsigned(self.readIndex, dataSize)
        self.readIndex += dataSize
        return retData
    cdef void setData(self, unsigned long data, unsigned char dataSize):
        self.csWriteValue(self.writeIndex, data, dataSize)
        self.writeIndex += dataSize
    cdef unsigned char getMask(self):
        return self.mask
    cdef void setMask(self, unsigned char value):
        self.mask = value


cdef class GDC(VGA_REGISTER_RAW):
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_GDC_AREA_SIZE, vga, main)

cdef class Sequencer(VGA_REGISTER_RAW):
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_SEQ_AREA_SIZE, vga, main)

cdef class ExtReg(VGA_REGISTER_RAW):
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_EXTREG_AREA_SIZE, vga, main)
        self.miscOutReg = VGA_EXTREG_PROCESS_RAM
    cdef unsigned char getMiscOutReg(self):
        return self.miscOutReg
    cdef void setMiscOutReg(self, unsigned char value):
        self.miscOutReg = value

cdef class AttrCtrlReg(VGA_REGISTER_RAW):
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_ATTRCTRLREG_AREA_SIZE, vga, main)
        self.clearFlipFlop()
    cdef void clearFlipFlop(self):
        self.flipFlop = False
    cdef unsigned long getIndexData(self, unsigned char dataSize):
        cdef unsigned long retVal
        if (not self.flipFlop):
            retVal = self.getIndex()
        else:
            retVal = self.getData(dataSize)
        self.flipFlop = not self.flipFlop
        return retVal
    cdef void setIndexData(self, unsigned long data, unsigned char dataSize):
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
    cdef void setProcessVideoMem(self, unsigned char processVideoMem):
        self.processVideoMem = processVideoMem
    cdef unsigned char getProcessVideoMem(self):
        return self.processVideoMem
    cdef unsigned char getCorrectPage(self, unsigned char page):
        if (page == 0xff):
            page = (<Mm>self.main.mm).mmPhyReadValueUnsigned(VGA_PAGE_ADDR, 1)
        elif (page > 7):
            self.main.printMsg("VGA::getCorrectPage: page > 7 (page: {0:d})", page)
        return page
    cdef void writeCharacterTeletype(self, unsigned char c, short attr, unsigned char page, unsigned char updateCursor):
        cdef unsigned char x, y, i
        cdef unsigned short cursorPos
        cdef unsigned long address
        page = self.getCorrectPage(page)
        cursorPos = self.getCursorPosition(page)
        y, x = (cursorPos>>8)&0xff, cursorPos&0xff
        address = self.getAddrOfPos(page, x, y)
        if (c == 0x7): # beep
            pass
        elif (c == 0x8): # BS == backspace
            if (x > 0):
                x -= 1
        elif (c == 0x9): # TAB == horizontal tabulator
            for i in range( 8-(x%8) ):
                self.writeCharacter(address, 0x20, attr) # space
                x += 1
        elif (c == 0xa): # LF == Newline/Linefeed
            y += 1
        elif (c == 0xd): # CR == carriage return
            x = 0
        else:
            self.writeCharacter(address, c, attr)
            x += 1
        if (x == 80):
            x = 0
            y += 1
        if (y == 25):
            self.scrollUp(page, attr, 1)
            y -= 1
        cursorPos = ((y<<8)|x)
        if (updateCursor):
            self.setCursorPosition(page, cursorPos)
    cdef void writeCharacter(self, unsigned long address, unsigned char c, short attr):
        if (attr == -1):
            (<Mm>self.main.mm).mmPhyWriteValue(address, c, 1)
            return
        (<Mm>self.main.mm).mmPhyWriteValue(address, ((<unsigned short>attr<<8)|c), 2)
    cdef unsigned long getAddrOfPos(self, unsigned char page, unsigned char x, unsigned char y):
        cdef unsigned long offset
        page = self.getCorrectPage(page)
        offset = ((y*80)+x)<<1
        return ((VGA_TEXTMODE_ADDR+(0x1000*page))+offset)
    cdef unsigned short getCursorPosition(self, unsigned char page): # returns y, x
        cdef unsigned short pos
        page = self.getCorrectPage(page)
        if (page > 7):
            self.main.printMsg("VGA::getCursorPosition: page > 7 (page: {0:d})", page)
            return 0
        pos = (<Mm>self.main.mm).mmPhyReadValueUnsigned(VGA_CURSOR_BASE_ADDR+(page<<1), 2)
        return pos
    cdef void setCursorPosition(self, unsigned char page, unsigned short pos):
        page = self.getCorrectPage(page)
        if (page > 7):
            self.main.printMsg("VGA::setCursorPosition: page > 7 (page: {0:d})", page)
            return
        (<Mm>self.main.mm).mmPhyWriteValue(VGA_CURSOR_BASE_ADDR+(page<<1), pos, 2)
    cdef void scrollUp(self, unsigned char page, short attr, unsigned short lines):
        cdef bytes oldData
        cdef unsigned long oldAddr, dataSize
        self.setProcessVideoMem(False)
        page = self.getCorrectPage(page)
        oldAddr = self.getAddrOfPos(page, 0, 0)
        if (lines == 0):
            lines = 25
            dataSize = 4000 # 160*25
        else:
            dataSize = 160*lines
            (<Mm>self.main.mm).mmPhyCopy(oldAddr, oldAddr+dataSize, 4000-dataSize)
        if (attr == -1):
            attr = (<Mm>self.main.mm).mmPhyReadValueUnsigned(self.getAddrOfPos(page, 79, 24)+1, 1)
        oldData = bytes([ 0x20, attr ])*80*lines
        (<Mm>self.main.mm).mmPhyWrite(oldAddr+(4000-dataSize), oldData, dataSize)
        self.setProcessVideoMem(True)
        oldData = (<Mm>self.main.mm).mmPhyRead(oldAddr, 4000)
        (<Mm>self.main.mm).mmPhyWrite(oldAddr, oldData, 4000)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned long retVal
        retVal = 0xff
        if (dataSize != OP_SIZE_BYTE):
            self.main.exitError("inPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        elif (ioPortAddr == 0x3c0):
            retVal = self.attrctrlreg.getIndex()
        elif (ioPortAddr == 0x3c1):
            retVal = self.attrctrlreg.getData(dataSize)
        elif (ioPortAddr == 0x3c5):
            retVal = self.seq.getData(dataSize)
        elif (ioPortAddr == 0x3c6):
            retVal = self.dac.getMask()
        elif (ioPortAddr == 0x3c7):
            retVal = self.dac.getReadIndex()
        elif (ioPortAddr == 0x3c8):
            retVal = self.dac.getWriteIndex()
        elif (ioPortAddr == 0x3c9):
            retVal = self.dac.getData(dataSize)
        elif (ioPortAddr == 0x3cc):
            retVal = self.extreg.getMiscOutReg()
        elif (ioPortAddr == 0x3da):
            self.attrctrlreg.clearFlipFlop()
        else:
            self.main.exitError("inPort: port {0:#04x} isn't supported. (dataSize byte)", ioPortAddr)
        return retVal&BITMASK_BYTE
    cdef void outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x400): # Bochs' Panic Port
                stdout.write(chr(data))
                stdout.flush()
            elif (ioPortAddr == 0x401): # Bochs' Panic Port2
                stdout.write(chr(data))
                stdout.flush()
            elif (ioPortAddr in (0x402,0x500,0x504)): # Bochs' Info Port
                stdout.write(chr(data))
                stdout.flush()
            elif (ioPortAddr == 0x403): # Bochs' Debug Port
                stdout.write(chr(data))
                stdout.flush()
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
            elif (ioPortAddr == 0x3c7):
                self.dac.setReadIndex(data)
            elif (ioPortAddr == 0x3c8):
                self.dac.setWriteIndex(data)
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
                self.main.exitError("outPort: port {0:#04x} isn't supported. (dataSize byte, data {1:#04x})", ioPortAddr, data)
        elif (dataSize == OP_SIZE_WORD):
            if (ioPortAddr in (0x3c4, 0x3ce, 0x3d4)):
                self.outPort(ioPortAddr, data&BITMASK_BYTE, OP_SIZE_BYTE)
                self.outPort(ioPortAddr+1, (data>>8)&BITMASK_BYTE, OP_SIZE_BYTE)
            else:
                self.main.exitError("outPort: port {0:#04x} isn't supported. (dataSize word, data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: port {0:#04x} with dataSize {1:d} isn't supported.", ioPortAddr, dataSize)
        return
    cdef void VRamAddMemArea(self):
        (<Mm>self.main.mm).mmAddArea(VGA_MEMAREA_ADDR, 0x20000, False, <MmArea>VRamArea)
    cdef void run(self):
        self.VRamAddMemArea()
        self.seq.run()
        self.crt.run()
        self.gdc.run()
        self.dac.run()
        self.extreg.run()
        self.attrctrlreg.run()
        ####
        if (self.ui is not None):
            (<PygameUI>self.ui).run()
        #self.main.platform.addReadHandlers((0x3c0, 0x3c1, 0x3c5, 0x3cc, 0x3c8, 0x3da), self)
        #self.main.platform.addWriteHandlers((0x3c0, 0x3c2, 0x3c4, 0x3c5, 0x3c6, 0x3c7, 0x3c8, 0x3c9, 0x3ce, \
        #                                     0x3cf, 0x3d4, 0x3d5, 0x400, 0x401, 0x402, 0x403, 0x500, 0x504), self)


