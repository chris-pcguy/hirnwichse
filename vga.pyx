
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"

from sys import stdout
from time import time


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
            elif (index == VGA_CRT_OVERFLOW_REG_INDEX):
                data = (self.getData(dataSize)&(~VGA_CRT_OFREG_LC8))|(data&VGA_CRT_OFREG_LC8)
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        if (index == VGA_CRT_OVERFLOW_REG_INDEX):
            self.vga.vde &= 0xff
            if (data & (1<<1)):
                self.vga.vde |= 0x100
            if (data & (1<<6)):
                self.vga.vde |= 0x200
        elif (index == VGA_CRT_MAX_SCANLINE_REG_INDEX):
            self.vga.charHeight = (data&0x1f)+1
        elif (index in (0x0c, 0x0d)):
            temp = self.vga.videoMemBaseWithOffset-self.vga.videoMemBase
            if (index == 0x0c): # high byte
                temp = (temp & 0x00ff) | (data << 8)
            elif (index == 0x0d): # low byte
                temp = (temp & 0xff00) | data
            self.vga.videoMemBaseWithOffset = self.vga.videoMemBase+temp
        elif (index == 0x11):
            self.protectRegisters = (data&VGA_CRT_PROTECT_REGISTERS) != 0
        elif (index == VGA_CRT_VDE_REG_INDEX):
            self.vga.vde &= 0x300
            self.vga.vde |= data
        elif (index in (VGA_CRT_OFFSET_INDEX, VGA_CRT_UNDERLINE_LOCATION_INDEX, VGA_CRT_MODE_CTRL_INDEX)):
            self.vga.textOffset = self.csReadValueUnsigned(VGA_CRT_OFFSET_INDEX, OP_SIZE_BYTE) << 2
            self.vga.offset = self.csReadValueUnsigned(VGA_CRT_OFFSET_INDEX, OP_SIZE_BYTE) << 1
            if ((self.csReadValueUnsigned(VGA_CRT_UNDERLINE_LOCATION_INDEX, OP_SIZE_BYTE)&VGA_CRT_UNDERLINE_LOCATION_DW) != 0):
                self.vga.offset <<= 2
            elif ((self.csReadValueUnsigned(VGA_CRT_MODE_CTRL_INDEX, OP_SIZE_BYTE)&VGA_CRT_MODE_CTRL_INDEX) == 0):
                self.vga.offset <<= 1

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
        if (self.getIndex() == VGA_GDC_RESET_REG_INDEX):
            self.vga.resetReg = data&0xf
        elif (self.getIndex() == VGA_GDC_ENABLE_RESET_REG_INDEX):
            self.vga.enableResetReg = data&0xf
        elif (self.getIndex() == VGA_GDC_DATA_ROTATE_INDEX):
            self.vga.rotateCount = data&7
            self.vga.logicOp = (data>>3)&3
        elif (self.getIndex() == VGA_GDC_READ_MAP_SEL_INDEX):
            self.vga.readMap = data&3
        elif (self.getIndex() == VGA_GDC_MODE_REG_INDEX):
            self.vga.oddEvenReadDisabled = (data&0x10)==0
            self.vga.readMode = (data >> 3)&1
            self.vga.writeMode = data&3
            if (self.vga.readMode):
                self.main.exitError("TODO: readMode==1 isn't implemented yet!")
                return
        elif (self.getIndex() == VGA_GDC_MISC_GREG_INDEX):
            data = ((data >> 2) & VGA_GDC_MEMBASE_MASK)
            if (data == VGA_GDC_MEMBASE_A0000_128K):
                self.vga.videoMemBase = 0xa0000
                self.vga.videoMemSize = 0x20000
            elif (data == VGA_GDC_MEMBASE_A0000_64K):
                self.vga.videoMemBase = 0xa0000
                self.vga.videoMemSize = 0x10000
            elif (data == VGA_GDC_MEMBASE_B0000_32K):
                self.vga.videoMemBase = 0xb0000
                self.vga.videoMemSize = 0x08000
            elif (data == VGA_GDC_MEMBASE_B8000_32K):
                self.vga.videoMemBase = 0xb8000
                self.vga.videoMemSize = 0x08000
            self.vga.videoMemBaseWithOffset = self.vga.videoMemBase+self.vga.crt.csReadValueUnsigned(0xc, OP_SIZE_WORD)
            self.vga.needLoadFont = True
            #self.vga.graphicalMode = (data&VGA_GDC_ALPHA_DIS) != 0
        elif (self.getIndex() == VGA_GDC_BIT_MASK_INDEX):
            self.vga.bitMask = data

cdef class Sequencer(VGA_REGISTER_RAW):
    def __init__(self, Vga vga, object main):
        VGA_REGISTER_RAW.__init__(self, VGA_SEQ_AREA_SIZE, vga, main)
    cdef void setData(self, unsigned int data, unsigned char dataSize):
        cdef unsigned char charSelA, charSelB
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        if (self.getIndex() == VGA_SEQ_CLOCKING_MODE_REG_INDEX):
            self.vga.ui.mode9Bit = (data&VGA_SEQ_MODE_9BIT) == 0
        elif (self.getIndex() == VGA_SEQ_PLANE_SEL_INDEX):
            if (not data):
                self.main.exitError("Sequencer::setData: no planes were selected! data == 0")
                return
            self.vga.writeMap = data&15
        elif (self.getIndex() == VGA_SEQ_CHARMAP_SEL_INDEX):
            charSelA = data&0b101100
            charSelB = data&0b010011
            self.vga.charSelA = ((charSelA>>2)&3)|(charSelA>>3)
            self.vga.charSelB = (charSelB&3)|(charSelB>>3)
            self.vga.needLoadFont = True
        elif (self.getIndex() == VGA_SEQ_MEM_MODE_INDEX):
            self.vga.chain4 = (data&8)!=0
            self.vga.oddEvenWriteDisabled = (data&4)!=0
            self.vga.extMem = (data&2)!=0
            #self.vga.graphicalMode = (data&1) == 0

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
            self.vga.graphicalMode = (data&VGA_ATTRCTRLREG_CONTROL_REG_GRAPHICAL_MODE) != 0


cdef class Vga:
    def __init__(self, object main):
        self.main = main
        self.videoMemBaseWithOffset = self.videoMemBase = 0xb8000
        self.videoMemSize = 0x08000
        self.needLoadFont = False
        self.readMap = self.writeMap = self.charSelA = self.charSelB = self.chain4 = self.oddEvenReadDisabled = self.oddEvenWriteDisabled = self.extMem = self.readMode = \
            self.writeMode = self.resetReg = self.enableResetReg = self.logicOp = self.rotateCount = self.graphicalMode = 0
        self.offset = 80
        self.textOffset = 160
        self.bitMask = 0xff
        self.charHeight = 16
        self.vde = 399
        self.miscReg = VGA_EXTREG_PROCESS_RAM | VGA_EXTREG_COLOR_MODE
        self.seq = Sequencer(self, self.main)
        self.crt = CRT(self, self.main)
        self.gdc = GDC(self, self.main)
        self.dac = DAC(self, self.main)
        self.attrctrlreg = AttrCtrlReg(self, self.main)
        self.processVideoMem = True
        self.newTimer = self.oldTimer = 0.0
        self.latchReg = [0, 0, 0, 0]
        self.plane0 = ConfigSpace(VGA_PLANE_SIZE, self.main)
        self.plane1 = ConfigSpace(VGA_PLANE_SIZE, self.main)
        self.plane2 = ConfigSpace(VGA_PLANE_SIZE, self.main)
        self.plane3 = ConfigSpace(VGA_PLANE_SIZE, self.main)
        self.pciDevice = (<Pci>self.main.platform.pci).addDevice()
        self.pciDevice.setVendorDeviceId(0x1234, 0x1111)
        self.pciDevice.setDeviceClass(PCI_CLASS_VGA)
        #self.pciDevice.setBarSize(6, 16)
        #self.pciDevice.setData(PCI_ROM_ADDRESS, ((VGA_ROM_BASE << 10) | 0x1), OP_SIZE_DWORD)
        self.ui = None
        if (not self.main.noUI):
            self.ui = PysdlUI(self, self.main)
    cpdef unsigned int getColor(self, unsigned char color): # RGBA
        cdef unsigned char red, green, blue
        if (color >= 0x10):
            self.main.exitError("Vga::getColor: color_1 >= 0x10 (color_1=={0:#04x})", color)
            return 0xff
        color = (<unsigned char>self.attrctrlreg.csData[color])
        if (color >= 0x40):
            self.main.exitError("Vga::getColor: color_2 >= 0x40 (color_2=={0:#04x})", color)
            return 0xff
        red, green, blue = self.dac.csRead(color*3, 3)
        red <<= 2
        green <<= 2
        blue <<= 2
        return ((red << 24) | (green << 16) | (blue << 8) | 0xff)
    cdef void readFontData(self): # TODO
        cdef unsigned short fontDataAddressA, fontDataAddressB
        cdef unsigned int posdata
        if (not self.ui or not self.needLoadFont):
            return
        if (not self.extMem):
            self.main.notice("readFontData: what should I do here?")
        fontDataAddressA =  (self.charSelA&3)<<14
        fontDataAddressA |= VGA_FONTAREA_SIZE if (self.charSelA&4) else 0
        fontDataAddressB =  (self.charSelB&3)<<14
        fontDataAddressB |= VGA_FONTAREA_SIZE if (self.charSelB&4) else 0
        self.ui.charSize = (9 if (self.ui.mode9Bit) else 8, self.charHeight)
        self.ui.fontDataA = self.plane2.csRead(fontDataAddressA, VGA_FONTAREA_SIZE)
        self.ui.fontDataB = self.plane2.csRead(fontDataAddressB, VGA_FONTAREA_SIZE)
        self.needLoadFont = False
    cdef void setProcessVideoMem(self, unsigned char processVideoMem):
        self.processVideoMem = processVideoMem
    cdef unsigned char getProcessVideoMem(self):
        return self.processVideoMem
    cdef unsigned char translateByte(self, unsigned char data, unsigned char plane): # this function is 'inspired'/stolen from the ReactOS project. Thanks! :-)
        cdef unsigned char bitMask
        bitMask = self.bitMask
        if (self.writeMode == 1):
            return self.latchReg[plane]
        elif (self.writeMode != 2):
            data = (data >> self.rotateCount) | (data << (8 - self.rotateCount))
        else:
            data = 0xff if (data & (1 << plane)) else 0x00
        if (not self.writeMode):
            if (self.enableResetReg & (1 << plane)):
                data = 0xff if (self.resetReg & (1 << plane)) else 0x00
        if (self.writeMode != 3):
            if (self.logicOp == 1):
                data &= self.latchReg[plane]
            elif (self.logicOp == 2):
                data |= self.latchReg[plane]
            elif (self.logicOp == 3):
                data ^= self.latchReg[plane]
        else:
            bitMask &= data
            data = 0xff if (self.resetReg & (1 << plane)) else 0x00
        data = ((data & bitMask) | (self.latchReg[plane] & (~bitMask)))
        return data
    cdef bytes vgaAreaRead(self, MmArea mmArea, unsigned int offset, unsigned int dataSize):
        cdef unsigned char selectedPlanes
        cdef unsigned int tempOffset, i
        cdef bytes retStr
        if (not self.ui):
            self.main.notice("vgaAreaRead: not self.ui")
            return b'\x00'*dataSize
        if (not (self.getProcessVideoMem()) or not (self.miscReg&VGA_EXTREG_PROCESS_RAM)):
            self.main.notice("vgaAreaRead: not (self.getProcessVideoMem()) or not (self.miscReg&VGA_EXTREG_PROCESS_RAM)")
            return b'\x00'*dataSize
        if (offset >= self.videoMemBaseWithOffset and (offset+dataSize) <= (self.videoMemBaseWithOffset+self.videoMemSize)):
            for i in range(dataSize):
                tempOffset = (offset-self.videoMemBaseWithOffset)
                if (self.chain4):
                    selectedPlanes = (tempOffset & 3)
                    tempOffset >>= 2
                elif (not self.oddEvenReadDisabled):
                    selectedPlanes = (tempOffset & 1)
                    tempOffset >>= 1
                else:
                    selectedPlanes = self.readMap
                offset += 1
            self.latchReg[0] = (<unsigned char>self.plane0.csData[tempOffset])
            self.latchReg[1] = (<unsigned char>self.plane1.csData[tempOffset])
            self.latchReg[2] = (<unsigned char>self.plane2.csData[tempOffset])
            self.latchReg[3] = (<unsigned char>self.plane3.csData[tempOffset])
            return bytes([self.latchReg[selectedPlanes]])
        return (<Mm>self.main.mm).mmAreaRead(mmArea, offset, dataSize)
    cdef void vgaAreaWrite(self, MmArea mmArea, unsigned int offset, unsigned int dataSize):
        #cdef list rectList
        cdef unsigned char selectedPlanes, data, color
        cdef unsigned short x, y, rows
        cdef unsigned int tempOffset, i, origOffset, pixelData
        if (not self.ui):
            return
        if (not (self.getProcessVideoMem()) or not (self.miscReg&VGA_EXTREG_PROCESS_RAM)):
            return
        if (not self.writeMap):
            return
        origOffset = offset
        if (offset >= self.videoMemBaseWithOffset and (offset+dataSize) <= (self.videoMemBaseWithOffset+self.videoMemSize)):
            for i in range(dataSize):
                tempOffset = (offset-self.videoMemBaseWithOffset)
                selectedPlanes = self.writeMap
                if (self.chain4):
                    selectedPlanes &= (tempOffset & 3)
                    tempOffset >>= 2
                elif (not self.oddEvenWriteDisabled):
                    if ((tempOffset & 1) == 0):
                        selectedPlanes &= 5 # plane 0 and 2
                    else:
                        selectedPlanes &= 10 # plane 1 and 3
                    tempOffset >>= 1
                data = mmArea.data[offset]
                if (selectedPlanes & 1):
                    self.plane0.csWrite(tempOffset, self.translateByte(data, 0), OP_SIZE_BYTE)
                if (selectedPlanes & 2):
                    self.plane1.csWrite(tempOffset, self.translateByte(data, 1), OP_SIZE_BYTE)
                if (selectedPlanes & 4):
                    self.plane2.csWrite(tempOffset, self.translateByte(data, 2), OP_SIZE_BYTE)
                if (selectedPlanes & 8):
                    self.plane3.csWrite(tempOffset, self.translateByte(data, 3), OP_SIZE_BYTE)
                offset += 1
        else:
            return
        offset = origOffset
        tempOffset = (offset-self.videoMemBaseWithOffset)
        if (self.graphicalMode):
            if (not self.chain4 and (tempOffset >= VGA_PLANE_SIZE or dataSize > VGA_PLANE_SIZE)):
                self.main.exitError("vgaAreaWrite: self.extMem and dataSize > VGA_PLANE_SIZE (dataSize: {0:d})", dataSize)
                return
            for i in range(dataSize):
                if (not self.chain4):
                    y, x = divmod(tempOffset, 80)
                    pixelData = (<unsigned char>self.plane0.csData[tempOffset])
                    pixelData |= (<unsigned char>self.plane1.csData[tempOffset])<<8
                    pixelData |= (<unsigned char>self.plane2.csData[tempOffset])<<16
                    pixelData |= (<unsigned char>self.plane3.csData[tempOffset])<<24
                    for i in range(8):
                        color = 0
                        if (pixelData & (1<<(((~i)&7)+24))):
                            color |= 0x8
                        if (pixelData & (1<<(((~i)&7)+16))):
                            color |= 0x4
                        if (pixelData & (1<<(((~i)&7)+8))):
                            color |= 0x2
                        if (pixelData & (1<<(((~i)&7)))):
                            color |= 0x1
                        self.ui.putPixel((x<<3)+i, y, color)
                else:
                    y, x = divmod(tempOffset, 320)
                    self.ui.putPixel(x, y, mmArea.data[offset])
                offset     += 1
                tempOffset += 1
            self.newTimer = time()
            if (self.newTimer - self.oldTimer >= 0.05):
                self.oldTimer = self.newTimer
                self.ui.updateScreen()
            return
        if (self.needLoadFont):
            self.readFontData()
        #rectList = list()
        rows = (self.vde+1)//self.charHeight
        dataSize = min(dataSize, self.textOffset*rows) # default: 80*25*2
        if (self.chain4):
            tempOffset >>= 2
        elif (not self.oddEvenWriteDisabled):
            tempOffset >>= 1
        for i in range(dataSize):
            y, x = divmod(tempOffset, self.textOffset>>1)
            #rectList.append(self.ui.putChar(x, y, (<unsigned char>self.plane0.csData[tempOffset]), (<unsigned char>self.plane1.csData[tempOffset])))
            self.ui.putChar(x, y, (<unsigned char>self.plane0.csData[tempOffset]), (<unsigned char>self.plane1.csData[tempOffset]))
            tempOffset += 1
        self.newTimer = time()
        if (self.newTimer - self.oldTimer >= 0.05):
            self.oldTimer = self.newTimer
            self.ui.updateScreen()
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned int retVal
        retVal = BITMASK_BYTE
        self.main.debug("inPort: port {0:#06x} with dataSize {1:d}.", ioPortAddr, dataSize)
        if (dataSize != OP_SIZE_BYTE):
            if (dataSize == OP_SIZE_WORD and ioPortAddr in (0x1ce, 0x1cf)): # vbe dispi index/vbe dispi data
                return BITMASK_WORD
            self.main.exitError("inPort: port {0:#06x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        elif (ioPortAddr in (0x1ce, 0x1cf)): # vbe dispi index/vbe dispi data
            return BITMASK_BYTE
        elif ((ioPortAddr >= 0x3b0 and ioPortAddr <= 0x3bf) and (self.miscReg & VGA_EXTREG_COLOR_MODE) != 0):
            self.main.notice("Vga::inPort: Trying to use mono-ports while being in color-mode.")
            return BITMASK_BYTE
        elif ((ioPortAddr >= 0x3d0 and ioPortAddr <= 0x3df) and (self.miscReg & VGA_EXTREG_COLOR_MODE) == 0):
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
            retVal = self.miscReg
        elif (ioPortAddr in (0x3b4, 0x3d4)):
            retVal = self.crt.getIndex()
        elif (ioPortAddr in (0x3b5, 0x3d5)):
            retVal = self.crt.getData(dataSize)
        elif (ioPortAddr in (0x3ba, 0x3ca, 0x3da)):
            self.attrctrlreg.setFlipFlop(False)
        else:
            self.main.exitError("inPort: port {0:#06x} isn't supported. (dataSize byte)", ioPortAddr)
        return retVal&BITMASK_BYTE
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (ioPortAddr not in (0x400, 0x401, 0x402, 0x403, 0x500, 0x504)):
            self.main.debug("outPort: port {0:#06x} with data {1:#06x} and dataSize {2:d}.", ioPortAddr, data, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            if ((ioPortAddr >= 0x3b0 and ioPortAddr <= 0x3bf) and (self.miscReg & VGA_EXTREG_COLOR_MODE) != 0):
                self.main.notice("Vga::outPort: Trying to use mono-ports while being in color-mode.")
                return
            elif ((ioPortAddr >= 0x3d0 and ioPortAddr <= 0x3df) and (self.miscReg & VGA_EXTREG_COLOR_MODE) == 0):
                self.main.notice("Vga::outPort: Trying to use color-ports while being in mono-mode.")
                return
            elif (ioPortAddr in (0x1ce, 0x1cf)): # vbe dispi index/vbe dispi data
                return
            elif (ioPortAddr == 0x3c0):
                self.attrctrlreg.setIndexData(data, dataSize)
            elif (ioPortAddr == 0x3c2):
                self.miscReg = data
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
                self.main.exitError("outPort: port {0:#06x} isn't supported. (dataSize byte, data {1:#04x})", ioPortAddr, data)
        elif (dataSize == OP_SIZE_WORD):
            if (ioPortAddr in (0x1ce, 0x1cf)): # vbe dispi index/vbe dispi data
                return
            elif (ioPortAddr in (0x3b4, 0x3c4, 0x3ce, 0x3d4)):
                self.outPort(ioPortAddr, data&BITMASK_BYTE, OP_SIZE_BYTE)
                self.outPort(ioPortAddr+1, (data>>8)&BITMASK_BYTE, OP_SIZE_BYTE)
            else:
                self.main.exitError("outPort: port {0:#06x} isn't supported. (dataSize word, data {1:#06x})", ioPortAddr, data)
        else:
            self.main.exitError("outPort: port {0:#06x} with dataSize {1:d} isn't supported.", ioPortAddr, dataSize)
        return
    cpdef run(self):
        if (self.ui):
            self.ui.run()


