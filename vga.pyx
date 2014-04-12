
from sys import stdout

include "globals.pxi"


cdef class VGA_REGISTER_RAW(ConfigSpace):
    def __init__(self, unsigned int registerSize, Vga vga, object main):
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
    cdef unsigned int getData(self, unsigned char dataSize):
        return self.csReadValueUnsigned(self.index, dataSize)
    cdef void setData(self, unsigned int data, unsigned char dataSize):
        self.csWriteValue(self.index, data, dataSize)

cdef class CRT(VGA_REGISTER_RAW):
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_CRT_AREA_SIZE, vga, main)
        self.protectRegisters = False
    cdef void setData(self, unsigned int data, unsigned char dataSize):
        cdef unsigned int temp
        cdef unsigned short index = self.getIndex()
        if (self.protectRegisters):
            if (index >= 0x00 and index <= 0x06):
                return
            elif (index == 0x07):
                data = (self.getData(dataSize)&(~VGA_CRT_OFREG_LC8))|(data&VGA_CRT_OFREG_LC8)
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        if (index in (0x0c, 0x0d)):
            temp = self.vga.videoMemBaseWithOffset-self.vga.videoMemBase
            if (index == 0x0c): # high byte
                temp = (temp & 0x00ff) | (data << 8)
            elif (index == 0x0d): # low byte
                temp = (temp & 0xff00) | data
            self.vga.videoMemBaseWithOffset = self.vga.videoMemBase+temp
        elif (index == 0x11):
            self.protectRegisters = (data&VGA_CRT_PROTECT_REGISTERS) != 0

cdef class DAC(VGA_REGISTER_RAW): # PEL
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_DAC_AREA_SIZE, vga, main)
        self.readIndex = self.writeIndex = 0
        self.readCycle = self.writeCycle = 0
        self.mask = 0xff
        self.state = 0x01
    cdef unsigned short getReadIndex(self):
        return self.readIndex
    cdef unsigned short getWriteIndex(self):
        return self.writeIndex
    cdef void setReadIndex(self, unsigned short index):
        self.readIndex = index
        self.readCycle = 0
        self.state = 0x03
    cdef void setWriteIndex(self, unsigned short index):
        self.writeIndex = index
        self.writeCycle = 0
        self.state = 0x00
    cdef unsigned int getData(self, unsigned char dataSize):
        cdef unsigned int retData
        if (dataSize != 1):
            self.main.exitError("DAC::getData: dataSize != 1 (dataSize: {0:d})", dataSize)
        if (self.state == 0x03):
            retData = self.csReadValueUnsigned((self.readIndex*3)+self.readCycle, 1)
            self.readCycle += 1
            if (self.readCycle >= 3):
                self.readCycle = 0
                self.readIndex += 1
        else:
            retData = 0x3f
        return retData
    cdef void setData(self, unsigned int data, unsigned char dataSize):
        if (dataSize != 1):
            self.main.exitError("DAC::setData: dataSize != 1 (dataSize: {0:d})", dataSize)
        #elif (data >= 0x40):
        #    self.main.exitError("DAC::setData: data >= 0x40 (data: {0:#04x})", data)
        self.csWriteValue((self.writeIndex*3)+self.writeCycle, data&0x3f, 1)
        self.writeCycle += 1
        if (self.writeCycle >= 3):
            self.writeCycle = 0
            self.writeIndex += 1
    cdef unsigned char getMask(self):
        return self.mask
    cdef unsigned char getState(self):
        return self.state
    cdef void setMask(self, unsigned char value):
        self.mask = value
        if (self.mask != 0xff):
            self.main.notice("DAC::setMask: mask == {0:#04x}", self.mask)


cdef class GDC(VGA_REGISTER_RAW):
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_GDC_AREA_SIZE, vga, main)
    cdef void setData(self, unsigned int data, unsigned char dataSize):
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        if (self.getIndex() == VGA_GDC_MISC_GREG_INDEX):
            if ((data & VGA_GDC_MEMBASE_MASK) == VGA_GDC_MEMBASE_A0000_128K):
                self.vga.videoMemBase = 0xa0000
                self.vga.videoMemSize = 0x20000
            elif ((data & VGA_GDC_MEMBASE_MASK) == VGA_GDC_MEMBASE_A0000_64K):
                self.vga.videoMemBase = 0xa0000
                self.vga.videoMemSize = 0x10000
            elif ((data & VGA_GDC_MEMBASE_MASK) == VGA_GDC_MEMBASE_B0000_32K):
                self.vga.videoMemBase = 0xb0000
                self.vga.videoMemSize = 0x08000
            elif ((data & VGA_GDC_MEMBASE_MASK) == VGA_GDC_MEMBASE_B8000_32K):
                self.vga.videoMemBase = 0xb8000
                self.vga.videoMemSize = 0x08000
            self.vga.needLoadFont = True

cdef class Sequencer(VGA_REGISTER_RAW):
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_SEQ_AREA_SIZE, vga, main)

cdef class ExtReg(VGA_REGISTER_RAW):
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_EXTREG_AREA_SIZE, vga, main)
        self.miscOutReg = VGA_EXTREG_PROCESS_RAM | VGA_EXTREG_COLOR_MODE
    cdef unsigned char getColorEmulation(self):
        return (self.miscOutReg & VGA_EXTREG_COLOR_MODE) != 0
    cdef unsigned char getMiscOutReg(self):
        return self.miscOutReg
    cdef void setMiscOutReg(self, unsigned char value):
        self.miscOutReg = value

cdef class AttrCtrlReg(VGA_REGISTER_RAW):
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_ATTRCTRLREG_AREA_SIZE, vga, main)
        self.videoEnabled = True
        self.csWriteValue(VGA_ATTRCTRLREG_CONTROL_REG_INDEX, VGA_ATTRCTRLREG_CONTROL_REG_LGE, 1)
        self.setFlipFlop(False)
    cdef void setIndex(self, unsigned short index):
        cdef unsigned char prevVideoEnabled = self.videoEnabled
        VGA_REGISTER_RAW.setIndex(self, index&0x1f)
        self.videoEnabled = (index & VGA_ATTRCTRLREG_VIDEO_ENABLED) != 0
        if (not self.videoEnabled):
            if (self.vga.ui):
                self.vga.ui.clearScreen()
        elif (not prevVideoEnabled):
            if (self.vga.ui):
                self.vga.ui.updateScreen()
    cdef void setFlipFlop(self, unsigned char flipFlop):
        self.flipFlop = flipFlop
    cdef void setIndexData(self, unsigned int data, unsigned char dataSize):
        if (not self.flipFlop):
            self.setIndex(data)
        else:
            self.setData(data, dataSize)
        self.setFlipFlop(not self.flipFlop)
    cdef unsigned int getData(self, unsigned char dataSize):
        cdef unsigned short index = self.getIndex()
        cdef unsigned int data = VGA_REGISTER_RAW.getData(self, dataSize)
        return data
    cdef void setData(self, unsigned int data, unsigned char dataSize):
        cdef unsigned short index = self.getIndex()
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        if ((index >= 0x00 and index <= 0x0f) and data >= 0x40):
            self.main.exitError("AttrCtrlReg::setData: palette_access: data >= 0x40 (data: {0:#04x})", data)
        elif (self.vga.ui and index == VGA_ATTRCTRLREG_CONTROL_REG_INDEX):
            self.vga.ui.replicate8Bit = (data&VGA_ATTRCTRLREG_CONTROL_REG_LGE) != 0
            self.vga.ui.msbBlink = (data&VGA_ATTRCTRLREG_CONTROL_REG_BLINK) != 0


cdef class Vga:
    def __init__(self, object main):
        self.main = main
        self.videoMemBaseWithOffset = self.videoMemBase = 0xb8000
        self.videoMemSize = 0x08000
        self.needLoadFont = False
        self.seq = Sequencer(self, self.main)
        self.crt = CRT(self, self.main)
        self.gdc = GDC(self, self.main)
        self.dac = DAC(self, self.main)
        self.extreg = ExtReg(self, self.main)
        self.attrctrlreg = AttrCtrlReg(self, self.main)
        self.processVideoMem = True
        self.pciDevice = (<Pci>self.main.platform.pci).addDevice()
        self.pciDevice.setVendorDeviceId(0x1234, 0x1111)
        self.pciDevice.setDeviceClass(PCI_CLASS_VGA)
        self.pciDevice.setData(PCI_ROM_ADDRESS, (VGA_ROM_BASE | 0x1), OP_SIZE_DWORD)
        self.pciDevice.setReadOnly(True)
        self.ui = None
        if (not self.main.noUI):
            self.ui = PysdlUI(self, self.main)
    cpdef unsigned int getColor(self, unsigned char color): # RGBA
        cdef unsigned char red, green, blue
        if (color >= 0x10):
            self.main.exitError("Vga::getColor: color_1 >= 0x10 (color_1=={0:#04x})", color)
            return (0, 0, 0)
        color = self.attrctrlreg.csReadValueUnsigned(color, 1)
        if (color >= 0x40):
            self.main.exitError("Vga::getColor: color_2 >= 0x40 (color_2=={0:#04x})", color)
            return (0, 0, 0)
        red, green, blue = self.dac.csRead(color*3, 3)
        red <<= 2
        green <<= 2
        blue <<= 2
        return ((red << 24) | (green << 16) | (blue << 8) | 0xff)
    cdef void readFontData(self): # TODO
        cdef unsigned char charHeight
        cdef unsigned int posdata
        if (not self.ui or not self.needLoadFont):
            return
        charHeight = (<Mm>self.main.mm).mmPhyReadValueUnsignedWord(VGA_VIDEO_CHAR_HEIGHT)
        posdata = (<Mm>self.main.mm).mmGetAbsoluteAddressForInterrupt(0x43)
        self.ui.charSize = (UI_CHAR_WIDTH, charHeight)
        self.ui.fontData = (<Mm>self.main.mm).mmPhyRead(posdata, VGA_FONTAREA_SIZE)
        self.needLoadFont = False
    cdef void setProcessVideoMem(self, unsigned char processVideoMem):
        self.processVideoMem = processVideoMem
    cdef unsigned char getProcessVideoMem(self):
        return self.processVideoMem
    cdef unsigned char getCorrectPage(self, unsigned char page):
        if (page == 0xff):
            page = (<Mm>self.main.mm).mmPhyReadValueUnsignedByte(VGA_ACTUAL_PAGE_ADDR)
        elif (page > 7):
            self.main.exitError("VGA::getCorrectPage: page > 7 (page: {0:d})", page)
        return page
    cdef void writeCharacterTeletype(self, unsigned char c, signed short attr, unsigned char page):
        cdef unsigned char x, y, i, rows
        cdef unsigned short cursorPos, cols
        cdef unsigned int address
        page = self.getCorrectPage(page)
        cols = (<Mm>self.main.mm).mmPhyReadValueUnsignedWord(VGA_COLUMNS_ADDR)
        rows = (<Mm>self.main.mm).mmPhyReadValueUnsignedByte(VGA_ROWS_ADDR)+1
        cursorPos = self.getCursorPosition(page)
        y, x = (cursorPos>>8), cursorPos&BITMASK_BYTE
        address = self.getAddrOfPos(x, y)
        if (c == 0x7): # beep
            pass
        elif (c == 0x8): # BS == backspace
            if (x > 0):
                x -= 1
        elif (c == 0x9): # TAB == horizontal tabulator
            for i in range(8 - (x & 7)):
                self.writeCharacter(address, 0x20, attr) # space
                x += 1
        elif (c == 0xa): # LF == Newline/Linefeed
            y += 1
        elif (c == 0xd): # CR == carriage return
            x = 0
        else:
            self.writeCharacter(address, c, attr)
            x += 1
        if (x >= cols):
            x -= cols
            y += 1
        if (y >= rows):
            self.scrollUp(attr, 1)
            y = rows-1
        cursorPos = ((y<<8)|x)
        self.setCursorPosition(page, cursorPos)
    cdef void writeCharacterNoTeletype(self, unsigned char c, signed short attr, unsigned char page, unsigned short count):
        cdef unsigned char x, y
        cdef unsigned short cursorPos, cols
        cdef unsigned int address
        page = self.getCorrectPage(page)
        cols = (<Mm>self.main.mm).mmPhyReadValueUnsignedWord(VGA_COLUMNS_ADDR)
        cursorPos = self.getCursorPosition(page)
        x, y = cursorPos&BITMASK_BYTE, (cursorPos>>8)
        for i in range(count):
            address = self.getAddrOfPos(x, y)
            self.writeCharacter(address, c, attr)
            x += 1
            if (x >= cols):
                x -= cols
                y += 1
    cdef void writeCharacter(self, unsigned int address, unsigned char c, signed short attr):
        if (attr == -1):
            (<Mm>self.main.mm).mmPhyWriteValue(address, c, OP_SIZE_BYTE)
            return
        (<Mm>self.main.mm).mmPhyWriteValue(address, <unsigned short>((<unsigned short>attr<<8)|c), OP_SIZE_WORD)
    cdef unsigned int getAddrOfPos(self, unsigned char x, unsigned char y):
        cdef unsigned char page, rows
        cdef unsigned short cols
        cdef unsigned int offset
        page = self.getCorrectPage(0xff)
        cols = (<Mm>self.main.mm).mmPhyReadValueUnsignedWord(VGA_COLUMNS_ADDR)
        rows = (<Mm>self.main.mm).mmPhyReadValueUnsignedByte(VGA_ROWS_ADDR)+1
        offset = ((((cols*rows*2)|0x00ff)+1)*page)+(((y*cols)+x)<<1)
        return (self.videoMemBaseWithOffset+offset)
    cdef unsigned short getCursorPosition(self, unsigned char page): # returns y, x
        cdef unsigned short pos
        page = self.getCorrectPage(page)
        if (page > 7):
            self.main.exitError("VGA::getCursorPosition: page > 7 (page: {0:d})", page)
            return 0
        pos = (<Mm>self.main.mm).mmPhyReadValueUnsignedWord(VGA_CURSOR_BASE_ADDR+(page<<1))
        return pos
    cdef void setCursorPosition(self, unsigned char page, unsigned short pos):
        page = self.getCorrectPage(page)
        if (page > 7):
            self.main.exitError("VGA::setCursorPosition: page > 7 (page: {0:d})", page)
            return
        (<Mm>self.main.mm).mmPhyWriteValue(VGA_CURSOR_BASE_ADDR+(page<<1), pos, OP_SIZE_WORD)
    cdef void scrollUp(self, signed short attr, unsigned short lines):
        cdef bytes oldData
        cdef unsigned char rows
        cdef unsigned short cols
        cdef unsigned int oldAddr, dataSize, fullSize
        self.setProcessVideoMem(False)
        cols = (<Mm>self.main.mm).mmPhyReadValueUnsignedWord(VGA_COLUMNS_ADDR)
        rows = (<Mm>self.main.mm).mmPhyReadValueUnsignedByte(VGA_ROWS_ADDR)+1
        fullSize = cols*rows*2
        oldAddr = self.getAddrOfPos(0, 0)
        if (lines == 0):
            lines = rows
            dataSize = fullSize # default: 80*25*2
        else:
            dataSize = cols*2*lines # default: 80*2*lines
            (<Mm>self.main.mm).mmPhyCopy(oldAddr, oldAddr+dataSize, fullSize-dataSize)
        if (attr == -1):
            attr = (<Mm>self.main.mm).mmPhyReadValueUnsignedByte(self.getAddrOfPos(cols-1, rows-1)+1)
        oldData = bytes([ 0x20, attr ])*cols*lines
        (<Mm>self.main.mm).mmPhyWrite(oldAddr+(fullSize-dataSize), oldData, dataSize)
        self.setProcessVideoMem(True)
        oldData = (<Mm>self.main.mm).mmPhyRead(oldAddr, fullSize)
        (<Mm>self.main.mm).mmPhyWrite(oldAddr, oldData, fullSize)
    cdef vgaAreaWrite(self, MmArea mmArea, unsigned int offset, unsigned int dataSize):
        #cdef list rectList
        cdef unsigned char x, y, rows
        cdef unsigned short cols
        if (not self.ui):
            return
        if (not (self.getProcessVideoMem()) or not (self.extreg.getMiscOutReg()&VGA_EXTREG_PROCESS_RAM)):
            return
        if (self.videoMemBase != 0xb8000): # only text-mode is supported yet.
            return
        if (self.needLoadFont):
            self.readFontData()
        #rectList = list()
        offset &= 0xffffe
        cols = (<Mm>self.main.mm).mmPhyReadValueUnsignedWord(VGA_COLUMNS_ADDR)
        rows = (<Mm>self.main.mm).mmPhyReadValueUnsignedByte(VGA_ROWS_ADDR)+1
        dataSize = min(dataSize, cols*rows*2) # default: 80*25*2
        while (dataSize > 0 and not self.main.quitEmu):
            y, x = divmod((offset-self.videoMemBaseWithOffset)//2, cols)
            #rectList.append(self.ui.putChar(x, y, mmArea.data[offset], mmArea.data[offset+1]))
            self.ui.putChar(x, y, mmArea.data[offset], mmArea.data[offset+1])
            if (dataSize <= 2):
                break
            offset   += 2
            dataSize -= 2
        self.ui.updateScreen()
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned int retVal
        retVal = BITMASK_BYTE
        if (dataSize != OP_SIZE_BYTE):
            if (dataSize == OP_SIZE_WORD and ioPortAddr in (0x1ce, 0x1cf)): # vbe dispi index/vbe dispi data
                return BITMASK_WORD
            self.main.exitError("inPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        elif (ioPortAddr in (0x1ce, 0x1cf)): # vbe dispi index/vbe dispi data
            return BITMASK_BYTE
        elif ((ioPortAddr >= 0x3b0 and ioPortAddr <= 0x3bf) and self.extreg.getColorEmulation()):
            self.main.notice("Vga::inPort: Trying to use mono-ports while being in color-mode.")
            return BITMASK_BYTE
        elif ((ioPortAddr >= 0x3d0 and ioPortAddr <= 0x3df) and not self.extreg.getColorEmulation()):
            self.main.notice("Vga::inPort: Trying to use color-ports while being in mono-mode.")
            return BITMASK_BYTE
        elif (ioPortAddr == 0x3c0):
            retVal = self.attrctrlreg.getIndex()
        elif (ioPortAddr == 0x3c1):
            retVal = self.attrctrlreg.getData(dataSize)
        elif (ioPortAddr == 0x3c5):
            retVal = self.seq.getData(dataSize)
        elif (ioPortAddr == 0x3c6):
            retVal = self.dac.getMask()
        elif (ioPortAddr == 0x3c7):
            retVal = self.dac.getState()
        elif (ioPortAddr == 0x3c8):
            retVal = self.dac.getWriteIndex()
        elif (ioPortAddr == 0x3c9):
            retVal = self.dac.getData(dataSize)
        elif (ioPortAddr == 0x3cc):
            retVal = self.extreg.getMiscOutReg()
        elif (ioPortAddr in (0x3b4, 0x3d4)):
            retVal = self.crt.getIndex()
        elif (ioPortAddr in (0x3b5, 0x3d5)):
            retVal = self.crt.getData(dataSize)
        elif (ioPortAddr in (0x3ba, 0x3ca, 0x3da)):
            self.attrctrlreg.setFlipFlop(False)
        else:
            self.main.exitError("inPort: port {0:#04x} isn't supported. (dataSize byte)", ioPortAddr)
        return retVal&BITMASK_BYTE
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if ((ioPortAddr >= 0x3b0 and ioPortAddr <= 0x3bf) and self.extreg.getColorEmulation()):
                self.main.notice("Vga::outPort: Trying to use mono-ports while being in color-mode.")
                return
            elif ((ioPortAddr >= 0x3d0 and ioPortAddr <= 0x3df) and not self.extreg.getColorEmulation()):
                self.main.notice("Vga::outPort: Trying to use color-ports while being in mono-mode.")
                return
            elif (ioPortAddr in (0x1ce, 0x1cf)): # vbe dispi index/vbe dispi data
                return
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
            elif (ioPortAddr in (0x3b4, 0x3d4)):
                self.crt.setIndex(data)
            elif (ioPortAddr in (0x3b5, 0x3d5)):
                self.crt.setData(data, dataSize)
            elif (ioPortAddr in (0x3ba, 0x3ca, 0x3da)):
                return
            elif (ioPortAddr == 0x400): # Bochs' Panic Port
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
            else:
                self.main.exitError("outPort: port {0:#04x} isn't supported. (dataSize byte, data {1:#04x})", ioPortAddr, data)
        elif (dataSize == OP_SIZE_WORD):
            if (ioPortAddr in (0x1ce, 0x1cf)): # vbe dispi index/vbe dispi data
                return
            elif (ioPortAddr in (0x3b4, 0x3c4, 0x3ce, 0x3d4)):
                self.outPort(ioPortAddr, data&BITMASK_BYTE, OP_SIZE_BYTE)
                self.outPort(ioPortAddr+1, (data>>8)&BITMASK_BYTE, OP_SIZE_BYTE)
            else:
                self.main.exitError("outPort: port {0:#04x} isn't supported. (dataSize word, data {1:#04x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: port {0:#04x} with dataSize {1:d} isn't supported.", ioPortAddr, dataSize)
        return
    cpdef run(self):
        if (self.ui):
            self.ui.run()


