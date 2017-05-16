
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"

from sys import stdout
from time import time

# stolen from bochs
cdef uint32_t CCDAT[16]
CCDAT = (
    0x00000000,
    0xff000000,
    0x00ff0000,
    0xffff0000,
    0x0000ff00,
    0xff00ff00,
    0x00ffff00,
    0xffffff00,
    0x000000ff,
    0xff0000ff,
    0x00ff00ff,
    0xffff00ff,
    0x0000ffff,
    0xff00ffff,
    0x00ffffff,
    0xffffffff,
)


cdef extern from "Python.h":
    bytes PyBytes_FromStringAndSize(char *, Py_ssize_t)


cdef class VGA_REGISTER_RAW:
    def __init__(self, uint32_t registerSize, Vga vga):
        self.vga  = vga
        self.index = 0
        self.configSpace = ConfigSpace(registerSize, self.vga.main)
    cdef void reset(self):
        self.configSpace.csResetData(0)
        self.index = 0
    cdef uint16_t getIndex(self):
        return self.index
    cdef void setIndex(self, uint16_t index):
        self.index = index
    cdef void indexAdd(self, uint16_t n):
        self.index += n
    cdef void indexSub(self, uint16_t n):
        self.index -= n
    cdef uint32_t getData(self, uint8_t dataSize):
        if (self.index >= self.configSpace.csSize):
            return 0
        return self.configSpace.csReadValueUnsigned(self.index, dataSize)
    cdef void setData(self, uint32_t data, uint8_t dataSize):
        if (self.index >= self.configSpace.csSize):
            return
        self.configSpace.csWriteValue(self.index, data, dataSize)

cdef class CRT(VGA_REGISTER_RAW):
    def __init__(self, Vga vga):
        VGA_REGISTER_RAW.__init__(self, VGA_CRT_AREA_SIZE, vga)
        self.protectRegisters = False
    cdef void setData(self, uint32_t data, uint8_t dataSize):
        cdef uint16_t index = self.getIndex()
        if (self.protectRegisters):
            if (index >= 0x00 and index <= 0x06):
                return
            elif (index == VGA_CRT_OVERFLOW_REG_INDEX):
                data = (self.getData(dataSize)&(~VGA_CRT_OFREG_LC8))|(data&VGA_CRT_OFREG_LC8)
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        if (index == VGA_CRT_OVERFLOW_REG_INDEX):
            self.vga.vde = self.vga.vde&0xff
            if (data & (1<<1)):
                self.vga.vde = self.vga.vde|0x100
            if (data & (1<<6)):
                self.vga.vde = self.vga.vde|0x200
        elif (index == VGA_CRT_MAX_SCANLINE_REG_INDEX):
            self.vga.charHeight = (data&0x1f)+1
        elif (index in (0x0c, 0x0d)):
            self.vga.setStartAddress()
        elif (index == 0x11):
            self.protectRegisters = (data&VGA_CRT_PROTECT_REGISTERS) != 0
        elif (index == VGA_CRT_VDE_REG_INDEX):
            self.vga.vde = self.vga.vde&0x300
            self.vga.vde = self.vga.vde|data
        elif (index in (VGA_CRT_OFFSET_INDEX, VGA_CRT_UNDERLINE_LOCATION_INDEX, VGA_CRT_MODE_CTRL_INDEX)):
            self.vga.offset = self.configSpace.csReadValueUnsignedByte(VGA_CRT_OFFSET_INDEX) << 1
            if ((self.configSpace.csReadValueUnsignedByte(VGA_CRT_UNDERLINE_LOCATION_INDEX)&VGA_CRT_UNDERLINE_LOCATION_DW) != 0):
                self.vga.addressSizeShift = 2
            elif ((self.configSpace.csReadValueUnsignedByte(VGA_CRT_MODE_CTRL_INDEX)&VGA_CRT_MODE_CTRL_WORD_BYTE) == 0):
                self.vga.addressSizeShift = 1
            else:
                self.vga.addressSizeShift = 0

cdef class DAC(VGA_REGISTER_RAW): # PEL
    def __init__(self, Vga vga):
        VGA_REGISTER_RAW.__init__(self, VGA_DAC_AREA_SIZE, vga)
        self.readIndex = self.writeIndex = 0
        self.readCycle = self.writeCycle = 0
        self.mask = 0xff
        self.state = 0x01
    cdef uint8_t getWriteIndex(self):
        return self.writeIndex
    cdef void setReadIndex(self, uint8_t index):
        self.readIndex = index
        self.readCycle = 0
        self.state = 0x03
    cdef void setWriteIndex(self, uint8_t index):
        self.writeIndex = index
        self.writeCycle = 0
        self.state = 0x00
    cdef uint32_t getData(self, uint8_t dataSize):
        cdef uint32_t retData = 0x3f
        if (dataSize != 1):
            self.vga.main.exitError("DAC::getData: dataSize != 1 (dataSize: %u)", dataSize)
            return retData
        if (self.state == 0x03):
            retData = self.configSpace.csReadValueUnsignedByte((self.readIndex*3)+self.readCycle)&0x3f
            self.readCycle += 1
            if (self.readCycle >= 3):
                self.readCycle = 0
                self.readIndex += 1
        return retData
    cdef void setData(self, uint32_t data, uint8_t dataSize):
        if (dataSize != 1):
            self.vga.main.exitError("DAC::setData: dataSize != 1 (dataSize: %u)", dataSize)
            return
        if (self.state != 0x00):
            return
        self.configSpace.csWriteValueByte((self.writeIndex*3)+self.writeCycle, data&0x3f)
        self.writeCycle += 1
        if (self.writeCycle >= 3):
            self.writeCycle = 0
            self.writeIndex += 1
            #self.vga.refreshScreen = True
    cdef uint8_t getMask(self):
        return self.mask
    cdef uint8_t getState(self):
        return self.state
    cdef void setMask(self, uint8_t value):
        self.mask = value
        IF COMP_DEBUG:
            if (self.mask != 0xff):
                self.vga.main.notice("DAC::setMask: mask == 0x%02x", self.mask)


cdef class GDC(VGA_REGISTER_RAW):
    def __init__(self, Vga vga):
        VGA_REGISTER_RAW.__init__(self, VGA_GDC_AREA_SIZE, vga)
    cdef void setData(self, uint32_t data, uint8_t dataSize):
        cdef uint16_t index
        #cdef uint32_t temp1, temp2
        index = self.getIndex()
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        if (index == VGA_GDC_RESET_REG_INDEX):
            self.vga.resetReg = data&0xf
        elif (index == VGA_GDC_ENABLE_RESET_REG_INDEX):
            self.vga.enableResetReg = data&0xf
        elif (index == VGA_GDC_COLOR_COMPARE_INDEX):
            self.vga.colorCompare = data&0xf
        elif (index == VGA_GDC_DATA_ROTATE_INDEX):
            self.vga.rotateCount = data&7
            self.vga.logicOp = (data>>3)&3
        elif (index == VGA_GDC_READ_MAP_SEL_INDEX):
            self.vga.readMap = data&3
        elif (index == VGA_GDC_MODE_REG_INDEX):
            self.vga.shift256 = (data&0x40)!=0
            if ((data&0x20)!=0 and not self.vga.shift256):
                self.vga.main.exitError("Vga::GDC: TODO: shift256 == 0 and shiftReg == 1")
                return
            self.vga.oddEvenReadDisabled = (data&0x10)==0
            self.vga.readMode = (data >> 3)&1
            self.vga.writeMode = data&3
        elif (index == VGA_GDC_MISC_GREG_INDEX):
            if (self.vga.refreshScreen and self.vga.writeMap): # TODO: FIXME: HACK
                self.vga.refreshScreenFunction()
            #temp1 = self.vga.videoMemBase
            #temp2 = self.vga.videoMemSize
            self.vga.alphaDis = (data&VGA_GDC_ALPHA_DIS) != 0
            #self.vga.alphaDis = True
            self.vga.chainOddEven = (data&VGA_GDC_CHAIN_ODD_EVEN) != 0
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
            IF COMP_DEBUG:
                self.vga.main.notice("GDC::setData: videoMemBase==0x%05x; videoMemSize==%u", self.vga.videoMemBase, self.vga.videoMemSize)
            self.vga.needLoadFont = True
            #if (temp1 != self.vga.videoMemBase or temp2 != self.vga.videoMemSize):
            #    self.vga.refreshScreen = True
            #if (self.vga.refreshScreen and self.vga.writeMap): # TODO: FIXME: HACK
            #    self.vga.refreshScreenFunction()
        elif (index == VGA_GDC_COLOR_DONT_CARE_INDEX):
            self.vga.colorDontCare = data&0xf
        elif (index == VGA_GDC_BIT_MASK_INDEX):
            self.vga.bitMask = data

cdef class Sequencer(VGA_REGISTER_RAW):
    def __init__(self, Vga vga):
        VGA_REGISTER_RAW.__init__(self, VGA_SEQ_AREA_SIZE, vga)
    cdef void setData(self, uint32_t data, uint8_t dataSize):
        cdef uint8_t charSelA, charSelB
        cdef uint16_t index = self.getIndex()
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        if (index == VGA_SEQ_CLOCKING_MODE_REG_INDEX):
            self.vga.ui.mode9Bit = (data&VGA_SEQ_MODE_9BIT) == 0
            #self.vga.refreshScreen = True
        elif (index == VGA_SEQ_PLANE_SEL_INDEX):
            #if (data&0xf and self.vga.writeMap != data&0xf):
            #if (self.vga.writeMap==0xf and (data&0xf)!=0xf):
            #if 1:
            #    self.vga.refreshScreen = True
            #    #self.vga.main.notice("Sequencer::setData: test1: data&0xf==0x%x; writeMap==0x%x", data&0xf, self.vga.writeMap)
            self.vga.writeMap = data&0xf
        elif (index == VGA_SEQ_CHARMAP_SEL_INDEX):
            charSelA = data&0b101100
            charSelB = data&0b010011
            self.vga.charSelA = ((charSelA>>2)&3)|(charSelA>>3)
            self.vga.charSelB = (charSelB&3)|(charSelB>>3)
            self.vga.needLoadFont = True
            #self.vga.refreshScreen = True
        elif (index == VGA_SEQ_MEM_MODE_INDEX):
            self.vga.chain4 = (data&8)!=0
            self.vga.oddEvenWriteDisabled = (data&4)!=0
            self.vga.extMem = (data&2)!=0
            #self.vga.graphicalMode = (data&1) == 0
            #self.vga.refreshScreen = True

cdef class AttrCtrlReg(VGA_REGISTER_RAW):
    def __init__(self, Vga vga):
        VGA_REGISTER_RAW.__init__(self, VGA_ATTRCTRLREG_AREA_SIZE, vga)
        self.configSpace.csWriteValueByte(VGA_ATTRCTRLREG_CONTROL_REG_INDEX, VGA_ATTRCTRLREG_CONTROL_REG_LGE)
        self.setFlipFlop(False)
        self.setIndex(0)
    cdef void setIndex(self, uint16_t index):
        VGA_REGISTER_RAW.setIndex(self, index)
        self.paletteEnabled = (index & VGA_ATTRCTRLREG_PALETTE_ENABLED) == 0
    cdef void setFlipFlop(self, uint8_t flipFlop):
        self.flipFlop = flipFlop
    cdef void setIndexData(self, uint32_t data, uint8_t dataSize):
        if (not self.flipFlop):
            self.setIndex(data)
        else:
            self.setData(data, dataSize)
        self.setFlipFlop(not self.flipFlop)
    cdef void setData(self, uint32_t data, uint8_t dataSize):
        cdef uint16_t index = self.getIndex()
        if (index < 0x10 and not self.paletteEnabled):
            return
        VGA_REGISTER_RAW.setData(self, data, dataSize)
        #with gil:
        IF 1:
            if (self.vga.ui and index == VGA_ATTRCTRLREG_CONTROL_REG_INDEX):
                self.vga.ui.replicate8Bit = (data&VGA_ATTRCTRLREG_CONTROL_REG_LGE) != 0
                self.vga.ui.msbBlink = (data&VGA_ATTRCTRLREG_CONTROL_REG_BLINK) != 0
                self.vga.palette54 = (data&VGA_ATTRCTRLREG_CONTROL_REG_PALETTE54) != 0
                self.vga.graphicalMode = (data&VGA_ATTRCTRLREG_CONTROL_REG_GRAPHICAL_MODE) != 0
                self.vga.enable8Bit = (data&VGA_ATTRCTRLREG_CONTROL_REG_8BIT) != 0
                self.vga.setStartAddress()
                return
        if (index == VGA_ATTRCTRLREG_COLOR_PLANE_ENABLE_REG_INDEX):
            self.vga.colorPlaneEnable = data&0xf
        elif (index == VGA_ATTRCTRLREG_COLOR_SELECT_REG_INDEX):
            self.vga.colorSelect = data&0xf
        #self.vga.refreshScreen = True


cdef class Vga:
    def __init__(self, Hirnwichse main):
        self.main = main
        self.videoMemBase = 0xb8000
        self.videoMemSize = 0x08000
        self.romBaseReal = VGA_ROM_BASE
        self.romBaseRealPlusSize = self.romBaseReal+SIZE_64KB
        self.needLoadFont = False
        self.readMap = self.writeMap = self.charSelA = self.charSelB = self.chain4 = self.chainOddEven = self.oddEvenReadDisabled = self.oddEvenWriteDisabled = self.extMem = self.readMode = self.logicOp = self.rotateCount = \
            self.graphicalMode = self.palette54 = self.enable8Bit = self.shift256 = self.colorSelect = self.colorCompare = self.startAddress = self.refreshScreen = self.retrace = self.addressSizeShift = self.alphaDis = 0
        self.colorDontCare = self.colorPlaneEnable = 0xf
        self.offset = 80
        self.bitMask = 0xff
        self.charHeight = 16
        self.vde = 399
        self.miscReg = 0xc0 | VGA_EXTREG_PROCESS_RAM | VGA_EXTREG_COLOR_MODE
        self.seq = Sequencer(self)
        self.crt = CRT(self)
        self.gdc = GDC(self)
        self.dac = DAC(self)
        self.attrctrlreg = AttrCtrlReg(self)
        self.processVideoMem = True
        self.newTimer = self.oldTimer = 0.0
        self.latchReg = [0, 0, 0, 0]
        self.plane0 = ConfigSpace(VGA_PLANE_SIZE, self.main)
        self.plane1 = ConfigSpace(VGA_PLANE_SIZE, self.main)
        self.plane2 = ConfigSpace(VGA_PLANE_SIZE, self.main)
        self.plane3 = ConfigSpace(VGA_PLANE_SIZE, self.main)
        IF 1: # needed for SeaBIOS
            self.pciDevice = self.main.platform.pci.addDevice()
            self.pciDevice.setVendorDeviceId(0x1234, 0x1111)
            self.pciDevice.setDeviceClass(PCI_CLASS_VGA)
            #self.pciDevice.setBarSize(0, 24)
            #self.pciDevice.setBarSize(2, 12)
            self.pciDevice.setBarSize(6, 16)
            #self.pciDevice.setData(PCI_BASE_ADDRESS_0, 0x8, OP_SIZE_DWORD)
            self.pciDevice.setData(PCI_ROM_ADDRESS, ((self.romBaseReal << 10) | 0x1), OP_SIZE_DWORD)
            #self.pciDevice.setData(PCI_COMMAND, 0x3, OP_SIZE_BYTE)
            self.pciDevice.setData(PCI_COMMAND, 0x0, OP_SIZE_BYTE)
        self.ui = None
        if (not self.main.noUI):
            self.ui = PysdlUI(self)
    cdef void setStartAddress(self):
        cdef uint32_t temp
        temp = self.startAddress
        self.startAddress = self.crt.configSpace.csReadValueUnsignedByte(0xc)<<8
        self.startAddress |= self.crt.configSpace.csReadValueUnsignedByte(0xd)
        #self.main.notice("setStartAddress: startAddress==0x%04x", self.startAddress)
        if (not self.graphicalMode):
            self.startAddress <<= 1
        if (temp != self.startAddress):
            #self.refreshScreenFunction()
            self.refreshScreen = True
    cdef uint32_t getColor(self, uint16_t color): # RGBA
        cdef uint8_t red, green, blue
        if (not self.enable8Bit):
            if (color >= 0x10):
                self.main.notice("Vga::getColor: color_1 >= 0x10 (color_1==0x%02x)", color)
                return 0
            color &= self.colorPlaneEnable
            color = (<uint8_t>self.attrctrlreg.configSpace.csData[color])
            if (color >= 0x40):
                self.main.notice("Vga::getColor: color_2 >= 0x40 (color_2==0x%02x)", color)
                return 0
            if (self.palette54):
                color = (color & 0xf) | (self.colorSelect << 4)
            else:
                color = (color & 0x3f) | ((self.colorSelect & 0xc) << 4)
        color &= self.dac.mask
        color *= 3
        red = (<uint8_t>self.dac.configSpace.csData[color]) << 2
        green = (<uint8_t>self.dac.configSpace.csData[color+1]) << 2
        blue = (<uint8_t>self.dac.configSpace.csData[color+2]) << 2
        #with gil:
        #    #red, green, blue = self.dac.configSpace.csRead(color, 3)
        #    red, green, blue = self.dac.configSpace.csData[color:color+3]
        #red, green, blue = red << 2, green << 2, blue << 2
        return ((red << 16) | (green << 8) | blue)
    cdef void readFontData(self): # TODO
        cdef uint16_t fontDataAddressA, fontDataAddressB
        #with gil:
        IF 1:
            if (not self.ui or not self.needLoadFont):
                return
        if (not self.extMem):
            self.main.notice("readFontData: what should I do here?")
        #if (self.charSelA):
        #IF 1:
        fontDataAddressA =  (self.charSelA&3)<<14
        fontDataAddressA |= VGA_FONTAREA_SIZE if (self.charSelA&4) else 0
        #if (self.charSelB):
        #IF 1:
        fontDataAddressB =  (self.charSelB&3)<<14
        fontDataAddressB |= VGA_FONTAREA_SIZE if (self.charSelB&4) else 0
        #with gil:
        IF 1:
            self.ui.charSize = (9 if (self.ui.mode9Bit) else 8, self.charHeight)
            self.ui.fontDataA = self.plane2.csRead(fontDataAddressA, VGA_FONTAREA_SIZE)
            self.ui.fontDataB = self.plane2.csRead(fontDataAddressB, VGA_FONTAREA_SIZE)
        self.needLoadFont = False
    cdef uint32_t translateBytes(self, uint32_t data): # this function is 'inspired'/stolen from the ReactOS project. Thanks! :-)
        cdef uint32_t bitMask, temp
        bitMask = (self.bitMask<<24)|(self.bitMask<<16)|(self.bitMask<<8)|self.bitMask
        if (self.writeMode == 1):
            data = self.latchReg[0]<<24
            data |= self.latchReg[1]<<16
            data |= self.latchReg[2]<<8
            data |= self.latchReg[3]
            return data
        elif (self.writeMode != 2):
            data = ((data >> self.rotateCount) | (data << (8 - self.rotateCount)))&BITMASK_BYTE
            data = (data<<24)|(data<<16)|(data<<8)|data
        else:
            temp = data
            data = (0xff if (temp & 1) else 0x00) << 24
            data |= (0xff if (temp & 2) else 0x00) << 16
            data |= (0xff if (temp & 4) else 0x00) << 8
            data |= (0xff if (temp & 8) else 0x00)
        if (not self.writeMode):
            if (self.enableResetReg & 1):
                data &= 0x00ffffffUL
                data |= (0xff if (self.resetReg & 1) else 0x00) << 24
            if (self.enableResetReg & 2):
                data &= 0xff00ffffUL
                data |= (0xff if (self.resetReg & 2) else 0x00) << 16
            if (self.enableResetReg & 4):
                data &= 0xffff00ffUL
                data |= (0xff if (self.resetReg & 4) else 0x00) << 8
            if (self.enableResetReg & 8):
                data &= 0xffffff00UL
                data |= 0xff if (self.resetReg & 8) else 0x00
        if (self.writeMode != 3):
            if (self.logicOp == 1):
                data &= (self.latchReg[0]<<24)|0x00ffffffUL
                data &= (self.latchReg[1]<<16)|0xff00ffffUL
                data &= (self.latchReg[2]<<8)|0xffff00ffUL
                data &= self.latchReg[3]|0xffffff00UL
            elif (self.logicOp == 2):
                data |= self.latchReg[0]<<24
                data |= self.latchReg[1]<<16
                data |= self.latchReg[2]<<8
                data |= self.latchReg[3]
            elif (self.logicOp == 3):
                data ^= self.latchReg[0]<<24
                data ^= self.latchReg[1]<<16
                data ^= self.latchReg[2]<<8
                data ^= self.latchReg[3]
        else:
            bitMask &= data
            data = (0xff if (self.resetReg & 1) else 0x00) << 24
            data |= (0xff if (self.resetReg & 2) else 0x00) << 16
            data |= (0xff if (self.resetReg & 4) else 0x00) << 8
            data |= 0xff if (self.resetReg & 8) else 0x00
        temp = (self.latchReg[0]<<24)|(self.latchReg[1]<<16)|(self.latchReg[2]<<8)|self.latchReg[3]
        data = ((data & bitMask) | (temp & (~bitMask)))
        return data
    cdef void refreshScreenFunction(self):
        cdef uint8_t temp
        cdef uint32_t size
        #with gil:
        #    if (self.ui and self.graphicalMode):
        #        self.ui.updateScreen()
        self.refreshScreen = False
        #return
        temp = self.writeMap
        self.writeMap = 0
        size = (self.videoMemSize-self.startAddress)%self.videoMemSize
        if (not size):
            size = self.videoMemSize
        IF COMP_DEBUG:
            self.main.notice("Vga::refreshScreenFunction: before vgaAreaWrite")
        self.vgaAreaWrite(self.videoMemBase+self.startAddress, size)
        #self.vgaAreaWrite(self.videoMemBase, self.videoMemSize)
        self.writeMap = temp
        #with gil:
        #    if (self.ui and self.graphicalMode):
        #        self.ui.updateScreen()
    cdef char *vgaAreaReadHandler(self, uint32_t offset, uint32_t dataSize):
        cdef uint32_t latchReg
        cdef uint8_t selectedPlanes
        cdef uint32_t tempOffset = BITMASK_DWORD, i
        cdef bytes retStr
        #if (self.main.debugEnabled):
        IF 0:
            self.main.notice("Vga::vgaAreaRead: offset==0x%05x; dataSize==%u", offset, dataSize)
        if (not self.ui):
            self.main.notice("Vga::vgaAreaRead: not self.ui")
            return bytes(dataSize)
        if (not self.processVideoMem or not (self.miscReg&VGA_EXTREG_PROCESS_RAM)):
            self.main.notice("Vga::vgaAreaRead: not self.processVideoMem or not (self.miscReg&VGA_EXTREG_PROCESS_RAM)")
            return bytes(dataSize)
        #if ((self.alphaDis or self.graphicalMode or (self.writeMap == 0x4)) and offset >= self.videoMemBase and (offset+dataSize) <= (self.videoMemBase+self.videoMemSize)):
        if ((self.alphaDis or self.graphicalMode) and offset >= self.videoMemBase and (offset+dataSize) <= (self.videoMemBase+self.videoMemSize)):
            retStr = b''
            for i in range(dataSize):
                tempOffset = (offset+i-self.videoMemBase)
                if (self.chain4):
                    selectedPlanes = (tempOffset & 3)
                    tempOffset &= 0xfffc
                elif (self.chainOddEven and not self.oddEvenReadDisabled):
                    selectedPlanes = (tempOffset & 1)
                    tempOffset &= 0xfffe
                else:
                    selectedPlanes = self.readMap
                if (not self.readMode):
                    #if (self.main.debugEnabled):
                    IF COMP_DEBUG:
                        self.main.notice("Vga::vgaAreaRead: selectedPlanes==%u; chain4==%u; not oERD==%u; readMap==%u; dataSize==%u; i==%u, tempOffset==0x%04x; offset==0x%05x; vMB==0x%05x; sA==0x%05x", selectedPlanes, self.chain4, not self.oddEvenReadDisabled, self.readMap, dataSize, i, tempOffset, offset, self.videoMemBase, self.startAddress)
                    if (not selectedPlanes):
                        retStr += bytes([(<uint8_t>self.plane0.csData[tempOffset])])
                    elif (selectedPlanes == 1):
                        retStr += bytes([(<uint8_t>self.plane1.csData[tempOffset])])
                    elif (selectedPlanes == 2):
                        retStr += bytes([(<uint8_t>self.plane2.csData[tempOffset])])
                    elif (selectedPlanes == 3):
                        retStr += bytes([(<uint8_t>self.plane3.csData[tempOffset])])
            if (tempOffset != BITMASK_DWORD):
                self.latchReg[0] = (<uint8_t>self.plane0.csData[tempOffset])
                self.latchReg[1] = (<uint8_t>self.plane1.csData[tempOffset])
                self.latchReg[2] = (<uint8_t>self.plane2.csData[tempOffset])
                self.latchReg[3] = (<uint8_t>self.plane3.csData[tempOffset])
            if (self.readMode):
                IF COMP_DEBUG:
                    self.main.notice("Vga::vgaAreaRead: readMode==1")
                latchReg = self.latchReg[0]<<24
                latchReg |= self.latchReg[1]<<16
                latchReg |= self.latchReg[2]<<8
                latchReg |= self.latchReg[3]
                latchReg ^= CCDAT[self.colorCompare]
                latchReg &= CCDAT[self.colorDontCare]
                retStr += bytes([<uint8_t>(~(<uint8_t>(latchReg>>24) | <uint8_t>(latchReg>>16) | <uint8_t>(latchReg>>8) | <uint8_t>latchReg))])
                if (len(retStr) != dataSize):
                    self.main.exitError("Vga::vgaAreaRead: len(retStr)==%u != dataSize==%u", len(retStr), dataSize)
                    return bytes(dataSize)
            IF COMP_DEBUG:
                self.main.notice("Vga::vgaAreaRead: test2: offset==0x%05x; dataSize==%u; data==%s", offset, dataSize, <bytes>repr(retStr).encode())
            return retStr
        retStr = PyBytes_FromStringAndSize( self.main.mm.data+offset, <Py_ssize_t>dataSize)
        #if (self.main.debugEnabled):
        #IF 0:
        IF COMP_DEBUG:
            self.main.notice("Vga::vgaAreaRead: test1: offset==0x%05x; dataSize==%u; data==%s", offset, dataSize, <bytes>repr(retStr).encode())
        return retStr
    cdef char *vgaAreaRead(self, uint32_t offset, uint32_t dataSize):
        #with gil:
        IF 1:
            return self.vgaAreaReadHandler(offset, dataSize)
    cdef void vgaAreaWriteHandler(self, uint32_t offset, uint32_t dataSize):
        #cdef list rectList
        cdef uint8_t selectedPlanes = 0xf, color
        cdef uint16_t x, y, rows
        cdef uint32_t tempOffset, i, j, k, pixelData, data
        #with gil:
        IF 1:
        #IF 0:
            #if (self.main.debugEnabled):
            #IF 0:
            #IF 1:
            IF COMP_DEBUG:
                self.main.notice("Vga::vgaAreaWrite: offset==0x%05x; dataSize==%u; data==%s", offset, dataSize, <bytes>repr(self.main.mm.data[offset:offset+dataSize]).encode())
            if (self.ui is None):
                return
        if (not self.processVideoMem or not (self.miscReg&VGA_EXTREG_PROCESS_RAM)):
            return
        #if (self.main.debugEnabled):
        #IF 0:
        #IF COMP_DEBUG:
        #    with gil:
        #        self.main.notice("Vga::vgaAreaWrite: writeMap==0x%x; videoMemBase==0x%05x; videoMemSize==%u", self.writeMap, self.videoMemBase, self.videoMemSize)
        #if (offset == 0xb94ee and dataSize == 2):
        #    self.main.debugEnabled = True
        if (self.refreshScreen and self.writeMap): # TODO: FIXME: HACK
            #if (dataSize != self.videoMemSize and dataSize != 32768):
            self.refreshScreenFunction()
            #with gil:
            #    self.ui.updateScreen()
        if (not (offset >= self.videoMemBase and (offset+dataSize) <= (self.videoMemBase+self.videoMemSize))):
            return
        if (self.writeMap):
            for i in range(dataSize):
                selectedPlanes = self.writeMap
                tempOffset = (offset+i-self.videoMemBase)
                if (self.chain4):
                    selectedPlanes &= 1 << (tempOffset&3)
                    tempOffset &= 0xfffc
                elif (self.chainOddEven and not self.oddEvenWriteDisabled):
                    if ((tempOffset & 1) == 0):
                        selectedPlanes &= 1 # plane 2 and 0
                    else:
                        selectedPlanes &= 2 # plane 3 and 1
                    if ((self.miscReg & VGA_EXTREG_ODD_EVEN_PAGE_SELECT) != 0):
                        selectedPlanes |= (selectedPlanes&3)<<2
                    tempOffset &= 0xfffe
                #tempOffset = (tempOffset<<self.addressSizeShift)%self.videoMemSize
                data = self.main.mm.data[offset+i]
                #if (self.main.debugEnabled):
                #IF 1:
                IF COMP_DEBUG:
                    self.main.notice("Vga::vgaAreaWrite: writeMap==0x%x; selectedPlanes==0x%x", self.writeMap, selectedPlanes)
                    self.main.notice("Vga::vgaAreaWrite: chainOddEven==%d; oddEvenWriteDisabled==%d, oddEvenPageSelect==%d", self.chainOddEven, self.oddEvenWriteDisabled, (self.miscReg & VGA_EXTREG_ODD_EVEN_PAGE_SELECT) != 0)
                data = self.translateBytes(data)
                if (selectedPlanes & 1):
                    self.plane0.csWriteValueByte(tempOffset, (data>>24)&BITMASK_BYTE)
                if (selectedPlanes & 2):
                    self.plane1.csWriteValueByte(tempOffset, (data>>16)&BITMASK_BYTE)
                if (selectedPlanes & 4):
                    self.plane2.csWriteValueByte(tempOffset, (data>>8)&BITMASK_BYTE)
                if (selectedPlanes & 8):
                    self.plane3.csWriteValueByte(tempOffset, data&BITMASK_BYTE)
        #else:
        #    selectedPlanes = 0xf
        #    #selectedPlanes = 0
        rows = (self.vde+1)
        tempOffset = (offset-self.videoMemBase)
        #tempOffset = (tempOffset<<self.addressSizeShift)%self.videoMemSize
        if (self.graphicalMode):
            if (not self.chain4 and (tempOffset >= VGA_PLANE_SIZE or dataSize > VGA_PLANE_SIZE)):
                self.main.notice("Vga::vgaAreaWrite_1: writeMap==0x%x; videoMemBase==0x%05x; videoMemSize==%u", self.writeMap, self.videoMemBase, self.videoMemSize)
                self.main.exitError("Vga::vgaAreaWrite: not chain4 and (tempOffset > VGA_PLANE_SIZE or dataSize > VGA_PLANE_SIZE) (offset: 0x%05x; tempOffset: 0x%05x; dataSize: %u)", offset, tempOffset, dataSize)
                return
            for j in range(dataSize):
                tempOffset = (offset+j-self.videoMemBase)
                if (self.chain4):
                    tempOffset &= 0xfffc
                elif (self.chainOddEven and not self.oddEvenWriteDisabled):
                    tempOffset &= 0xfffe
                tempOffset = (tempOffset<<self.addressSizeShift)%self.videoMemSize
                pixelData = (<uint8_t>self.plane0.csData[tempOffset])
                pixelData |= (<uint8_t>self.plane1.csData[tempOffset])<<8
                pixelData |= (<uint8_t>self.plane2.csData[tempOffset])<<16
                pixelData |= (<uint8_t>self.plane3.csData[tempOffset])<<24
                if (not self.chain4):
                    #y = ((tempOffset-self.startAddress)%self.videoMemSize)//self.offset
                    #x = ((tempOffset-self.startAddress)%self.videoMemSize)%self.offset
                    y, x = divmod((tempOffset-self.startAddress)%self.videoMemSize, self.offset)
                    #y *= self.charHeight
                    if (y >= rows):
                        break
                    for i in range(8):
                        if (not self.shift256):
                            color = 0
                            if (pixelData & (1<<(((~i)&7)+24))):
                                color |= 0x8
                            if (pixelData & (1<<(((~i)&7)+16))):
                                color |= 0x4
                            if (pixelData & (1<<(((~i)&7)+8))):
                                color |= 0x2
                            if (pixelData & (1<<(((~i)&7)))):
                                color |= 0x1
                        else:
                            if (selectedPlanes not in (0, 0xf) and not (selectedPlanes&(1<<(i>>1)))):
                                continue
                            data = (pixelData >> ((i&6)<<2))&0xff
                            color = (self.attrctrlreg.configSpace.csData[data>>4]&0xf)<<4
                            color |= (self.attrctrlreg.configSpace.csData[data&0xf]&0xf)
                        #self.main.notice("Vga::vgaAreaWrite: putPixel: (x<<3)+i: %u; y: %u; color: 0x%02x", (x<<3)+i, y, color)
                        #self.main.notice("Vga::vgaAreaWrite: putPixel: test2: EIP: 0x%04x, CS: 0x%04x", self.main.cpu.savedEip, self.main.cpu.savedCs)
                        #for k in range(self.charHeight):
                        #    self.ui.putPixel((x<<3)+i, y+k, color)
                        #with gil:
                        self.ui.putPixel((x<<3)+i, y, color)
                else:
                    #y = ((tempOffset-self.startAddress)%self.videoMemSize)//(self.offset<<2)
                    #x = ((tempOffset-self.startAddress)%self.videoMemSize)%(self.offset<<2)
                    #y, x = divmod((tempOffset-self.startAddress)%self.videoMemSize, self.offset<<2)
                    y, x = divmod((tempOffset-self.startAddress)%self.videoMemSize, self.offset)
                    y *= self.charHeight
                    if (y >= rows):
                        break
                    x <<= 1
                    #selectedPlanes = tempOffset&3
                    color = (pixelData >> (selectedPlanes<<3))
                    if (not self.enable8Bit):
                        self.main.exitError("Vga::vgaAreaWrite: TODO: not enable8Bit")
                        return
                    for k in range(self.charHeight):
                        #with gil:
                        self.ui.putPixel(x, y+k, color)
                        self.ui.putPixel(x+1, y+k, color)
                    #self.ui.putPixel(x, y, color)
            #with gil:
            self.newTimer = time()
            #if (self.newTimer - self.oldTimer >= 0.05):
            if (self.newTimer - self.oldTimer >= 0.075):
                self.oldTimer = self.newTimer
                self.ui.updateScreen(False)
            return
        if (self.needLoadFont):
            self.readFontData()
        if (self.writeMap & 3 or not self.writeMap):
        #IF 1:
            #rectList = list()
            #if (self.chain4):
            #    tempOffset &= 0xfffc
            #el
            if (self.chainOddEven and not self.oddEvenWriteDisabled):
                tempOffset &= 0xfffe
            tempOffset = (tempOffset<<self.addressSizeShift)%self.videoMemSize
            #IF COMP_DEBUG:
            IF 0:
                offset &= 0xffffe
            rows //= self.charHeight
            #dataSize = max(1, dataSize>>1)
            dataSize = max(1, dataSize)
            for i in range(dataSize):
                #y = ((tempOffset-self.startAddress)%self.videoMemSize)//(self.offset<<1)
                #x = ((tempOffset-self.startAddress)%self.videoMemSize)%(self.offset<<1)
                y, x = divmod((tempOffset-self.startAddress)%self.videoMemSize, self.offset<<1)
                #y, x = divmod((tempOffset-self.startAddress)%self.videoMemSize, self.offset)
                x >>= 1
                if (y >= rows):
                    break
                #if (self.alphaDis):
                #IF 0:
                IF 1:
                    #if ((self.miscReg & VGA_EXTREG_ODD_EVEN_PAGE_SELECT) != 0):
                    #    rectList.append(self.ui.putChar(x, y, <uint8_t>(self.plane2.csData[tempOffset]), <uint8_t>(self.plane3.csData[tempOffset])))
                    #else:
                    #    rectList.append(self.ui.putChar(x, y, <uint8_t>(self.plane0.csData[tempOffset]), <uint8_t>(self.plane1.csData[tempOffset])))
                    #if (self.main.debugEnabled):
                    #IF 0:
                    IF COMP_DEBUG:
                        #if ((self.miscReg & VGA_EXTREG_ODD_EVEN_PAGE_SELECT) != 0):
                        #    self.main.notice("Vga::vgaAreaWrite: x==%u; y==%u; ch==0x%02x;%c; cl==0x%02x: tempOffset==0x%04x; self.offset==%u; offset==0x%05x; vMB==0x%05x; sA==0x%05x", x, y, <uint8_t>(self.plane2.csData[tempOffset]), <uint8_t>(self.plane2.csData[tempOffset]), <uint8_t>(self.plane3.csData[tempOffset]), tempOffset, self.offset, offset, self.videoMemBase, self.startAddress)
                        #else:
                        self.main.notice("Vga::vgaAreaWrite: x==%u; y==%u; ch==0x%02x;%c; cl==0x%02x: tempOffset==0x%04x; self.offset==%u; offset==0x%05x; vMB==0x%05x; sA==0x%05x", x, y, <uint8_t>(self.plane0.csData[tempOffset]), <uint8_t>(self.plane0.csData[tempOffset]), <uint8_t>(self.plane1.csData[tempOffset]), tempOffset, self.offset, offset, self.videoMemBase, self.startAddress)
                    #with gil:
                    #if ((self.miscReg & VGA_EXTREG_ODD_EVEN_PAGE_SELECT) != 0):
                    #    self.ui.putChar(x, y, <uint8_t>(self.plane2.csData[tempOffset]), <uint8_t>(self.plane3.csData[tempOffset]))
                    #else:
                    self.ui.putChar(x, y, <uint8_t>(self.plane0.csData[tempOffset]), <uint8_t>(self.plane1.csData[tempOffset]))
                    tempOffset += 2
                #else:
                ELSE:
                    #rectList.append(self.ui.putChar(x, y, <uint8_t>(self.main.mm.data[offset]), <uint8_t>(self.main.mm.data[offset+1])))
                    #if (self.main.debugEnabled):
                    #IF 0:
                    IF COMP_DEBUG:
                        self.main.notice("Vga::vgaAreaWrite: x==%u; y==%u; ch==0x%02x;%c; cl==0x%02x: tempOffset==0x%04x; self.offset==%u; offset==0x%05x; vMB==0x%05x; sA==0x%05x", x, y, <uint8_t>(self.main.mm.data[offset]), <uint8_t>(self.main.mm.data[offset]), <uint8_t>(self.main.mm.data[offset+1]), tempOffset, self.offset, offset, self.videoMemBase, self.startAddress)
                    #with gil:
                    self.ui.putChar(x, y, <uint8_t>(self.main.mm.data[offset]), <uint8_t>(self.main.mm.data[offset+1]))
                    offset += 2
        #with gil:
        self.newTimer = time()
        #if (self.newTimer - self.oldTimer >= 0.05):
        if (self.newTimer - self.oldTimer >= 0.075):
            self.oldTimer = self.newTimer
            self.ui.updateScreen(False)
    cdef void vgaAreaWrite(self, uint32_t offset, uint32_t dataSize):
        #with gil:
        IF 1:
            self.vgaAreaWriteHandler(offset, dataSize)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize):
        cdef uint32_t retVal
        retVal = BITMASK_BYTE
        IF COMP_DEBUG:
            self.main.notice("Vga::inPort_1: port 0x%04x with dataSize %u.", ioPortAddr, dataSize)
        if (dataSize != OP_SIZE_BYTE):
            if (dataSize == OP_SIZE_WORD and ioPortAddr in (0x1ce, 0x1cf)): # vbe dispi index/vbe dispi data
                return BITMASK_WORD
            self.main.exitError("inPort: port 0x%04x with dataSize %u not supported.", ioPortAddr, dataSize)
        elif (ioPortAddr in (0x1ce, 0x1cf)): # vbe dispi index/vbe dispi data
            return BITMASK_BYTE
        elif ((ioPortAddr >= 0x3b0 and ioPortAddr <= 0x3bf) and (self.miscReg & VGA_EXTREG_COLOR_MODE) != 0):
            IF COMP_DEBUG:
                self.main.notice("Vga::inPort: Trying to use mono-ports while being in color-mode.")
            return BITMASK_BYTE
        elif ((ioPortAddr >= 0x3d0 and ioPortAddr <= 0x3df) and (self.miscReg & VGA_EXTREG_COLOR_MODE) == 0):
            IF COMP_DEBUG:
                self.main.notice("Vga::inPort: Trying to use color-ports while being in mono-mode.")
            return BITMASK_BYTE
        elif (ioPortAddr == 0x3c0):
            retVal = self.attrctrlreg.getIndex()
        elif (ioPortAddr == 0x3c1):
            retVal = self.attrctrlreg.getData(dataSize)
        elif (ioPortAddr == 0x3c2):
            retVal = 0
        elif (ioPortAddr == 0x3c4):
            retVal = self.seq.getIndex()
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
        elif (ioPortAddr == 0x3ce):
            retVal = self.gdc.getIndex()
        elif (ioPortAddr == 0x3cf):
            retVal = self.gdc.getData(dataSize)
        elif (ioPortAddr in (0x3b4, 0x3d4)):
            retVal = self.crt.getIndex()
        elif (ioPortAddr in (0x3b5, 0x3d5)):
            retVal = self.crt.getData(dataSize)
        elif (ioPortAddr in (0x3ba, 0x3ca, 0x3da)):
            retVal = 0x00
            if (self.retrace): # HACK
                retVal |= 0x9
            self.retrace = not self.retrace
            self.attrctrlreg.setFlipFlop(False)
        else:
            self.main.exitError("inPort: port 0x%04x isn't supported. (dataSize byte)", ioPortAddr)
        IF COMP_DEBUG:
            self.main.notice("Vga::inPort_2: port 0x%04x with dataSize %u and retVal 0x%02x.", ioPortAddr, dataSize, retVal)
        return <uint8_t>retVal
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize):
        #self.refreshScreen = True
        if (ioPortAddr not in (0x400, 0x401, 0x402, 0x403, 0x500, 0x504)):
            IF COMP_DEBUG:
                self.main.notice("Vga::outPort: port 0x%04x with data 0x%04x and dataSize %u.", ioPortAddr, data, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            if ((ioPortAddr >= 0x3b0 and ioPortAddr <= 0x3bf) and (self.miscReg & VGA_EXTREG_COLOR_MODE) != 0):
                IF COMP_DEBUG:
                    self.main.notice("Vga::outPort: Trying to use mono-ports while being in color-mode.")
                return
            elif ((ioPortAddr >= 0x3d0 and ioPortAddr <= 0x3df) and (self.miscReg & VGA_EXTREG_COLOR_MODE) == 0):
                IF COMP_DEBUG:
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
                #with gil:
                IF 1:
                    stdout.write(chr(data))
                    stdout.flush()
            elif (ioPortAddr == 0x401): # Bochs' Panic Port2
                #with gil:
                IF 1:
                    stdout.write(chr(data))
                    stdout.flush()
            elif (ioPortAddr in (0x402,0x500,0x504)): # Bochs' Info Port
                #with gil:
                IF 1:
                    stdout.write(chr(data))
                    stdout.flush()
            elif (ioPortAddr == 0x403): # Bochs' Debug Port
                #with gil:
                IF 1:
                    stdout.write(chr(data))
                    stdout.flush()
            elif (ioPortAddr == 0x8900):
                self.main.exitError("Vga::outPort: port 0x%04x APM shutdown. (dataSize byte, data 0x%02x)", ioPortAddr, data)
            else:
                self.main.exitError("Vga::outPort: port 0x%04x isn't supported. (dataSize byte, data 0x%02x)", ioPortAddr, data)
        elif (dataSize == OP_SIZE_WORD):
            if (ioPortAddr in (0x1ce, 0x1cf)): # vbe dispi index/vbe dispi data
                return
            elif (ioPortAddr in (0x3b4, 0x3c4, 0x3ce, 0x3d4)):
                self.outPort(ioPortAddr, <uint8_t>data, OP_SIZE_BYTE)
                self.outPort(ioPortAddr+1, <uint8_t>(data>>8), OP_SIZE_BYTE)
            elif (ioPortAddr == 0xb004):
                self.main.exitError("Vga::outPort: port 0x%04x ACPI shutdown. (dataSize word, data 0x%02x)", ioPortAddr, data)
            else:
                IF COMP_DEBUG:
                    self.main.notice("Vga::outPort: port 0x%04x isn't supported. (dataSize word, data 0x%04x)", ioPortAddr, data)
        else:
            IF COMP_DEBUG:
                self.main.notice("Vga::outPort: port 0x%04x with dataSize %u isn't supported. (data 0x%04x)", ioPortAddr, dataSize, data)
        return
    cdef void run(self):
        #self.plane0.csResetData(BITMASK_BYTE)
        #self.plane1.csResetData(BITMASK_BYTE)
        #self.plane3.csResetData(BITMASK_BYTE)
        if (self.ui):
            self.ui.run()


