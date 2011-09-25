import misc, mm


CMOS_STATUS_REGISTER_A = 0xa
CMOS_STATUS_REGISTER_B = 0xb
CMOS_STATUS_REGISTER_C = 0xc
CMOS_STATUS_REGISTER_D = 0xd
CMOS_FLOPPY_DRIVE_TYPE = 0x10
CMOS_EQUIPMENT_BYTE    = 0x14
CMOS_BASE_MEMORY_L     = 0x15
CMOS_BASE_MEMORY_H     = 0x16
CMOS_EXT_MEMORY_L      = 0x17
CMOS_EXT_MEMORY_H      = 0x18
CMOS_EXT_MEMORY_L2     = 0x30
CMOS_EXT_MEMORY_H2     = 0x31
CMOS_EXT_MEMORY2_L     = 0x34
CMOS_EXT_MEMORY2_H     = 0x35
CMOS_EXT_BIOS_CFG      = 0x2d
CMOS_CHECKSUM_H        = 0x2e
CMOS_CHECKSUM_L        = 0x2f


cdef class Cmos:
    cdef object main, configSpace
    cdef unsigned char cmosIndex, port80h_data
    def __init__(self, object main):
        self.main = main
        self.cmosIndex = 0
        self.port80h_data = 0
    def reset(self):
        self.configSpace = mm.ConfigSpace(128, self.main)
        self.configSpace.csWriteValue(CMOS_STATUS_REGISTER_B, 0x06, misc.OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_STATUS_REGISTER_D, 0x80, misc.OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_FLOPPY_DRIVE_TYPE, 0x40, misc.OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_EQUIPMENT_BYTE, 0x21, misc.OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_BASE_MEMORY_L, 0x80, misc.OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_BASE_MEMORY_H, 0x02, misc.OP_SIZE_BYTE)
        cdef unsigned long long extMemSizeInK = (self.main.memSize//1024)-640
        if (extMemSizeInK > 16384): # 16M
            extMemSizeInK = 16384   # 16M
        self.configSpace.csWriteValue(CMOS_EXT_MEMORY_L, extMemSizeInK&0xff, misc.OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_EXT_MEMORY_H, (extMemSizeInK>>8)&0xff, misc.OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_EXT_MEMORY_L2, self.configSpace.csReadValue(CMOS_EXT_MEMORY_L, misc.OP_SIZE_BYTE), misc.OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_EXT_MEMORY_H2, self.configSpace.csReadValue(CMOS_EXT_MEMORY_H, misc.OP_SIZE_BYTE), misc.OP_SIZE_BYTE)
        cdef unsigned long long extMemSizeIn64K = extMemSizeInK//64
        self.configSpace.csWriteValue(CMOS_EXT_MEMORY2_L, extMemSizeIn64K&0xff, misc.OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_EXT_MEMORY2_H, (extMemSizeIn64K>>8)&0xff, misc.OP_SIZE_BYTE)
        
        self.configSpace.csWriteValue(CMOS_EXT_BIOS_CFG, 0x20, misc.OP_SIZE_BYTE) # boot from floppy first.
    def makeCheckSum(self):
        cdef unsigned short checkSum = 0
        for i in range(0x10, 0x2e): # 0x10..0x2d
            checkSum += self.configSpace.csReadValue(i, misc.OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_CHECKSUM_L, checkSum&0xff, misc.OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_CHECKSUM_H, (checkSum>>8)&0xff, misc.OP_SIZE_BYTE)
    def inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            if (ioPortAddr == 0x70):
                return self.cmosIndex
            elif (ioPortAddr == 0x71):
                return self.configSpace.csReadValue(self.cmosIndex, misc.OP_SIZE_BYTE)
            elif (ioPortAddr == 0x80):
                return self.port80h_data
            elif (ioPortAddr == 0x510): # qemu cfg read handler
                return 0
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, unsigned short ioPortAddr, int data, unsigned char dataSize):
        if (dataSize == misc.OP_SIZE_BYTE):
            if (ioPortAddr == 0x70):
                self.cmosIndex = data&(~0x80)
            elif (ioPortAddr == 0x71):
                self.configSpace.csWriteValue(self.cmosIndex, data, misc.OP_SIZE_BYTE)
                if (self.cmosIndex == CMOS_EXT_MEMORY_L):
                    self.configSpace.csWriteValue(CMOS_EXT_MEMORY_L2, data, misc.OP_SIZE_BYTE)
                elif (self.cmosIndex == CMOS_EXT_MEMORY_H):
                    self.configSpace.csWriteValue(CMOS_EXT_MEMORY_H2, data, misc.OP_SIZE_BYTE)
                elif (self.cmosIndex == CMOS_EXT_MEMORY_L2):
                    self.configSpace.csWriteValue(CMOS_EXT_MEMORY_L, data, misc.OP_SIZE_BYTE)
                elif (self.cmosIndex == CMOS_EXT_MEMORY_H2):
                    self.configSpace.csWriteValue(CMOS_EXT_MEMORY_H, data, misc.OP_SIZE_BYTE)
                self.makeCheckSum()
            elif (ioPortAddr == 0x80):
                self.port80h_data = data
        else:
            if (ioPortAddr == 0x510): # qemu cfg write handler
                pass
            else:
                self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.reset()
        self.main.platform.addReadHandlers((0x70, 0x71, 0x80,0x511), self.inPort)
        self.main.platform.addWriteHandlers((0x70, 0x71, 0x80,0x510), self.outPort)



