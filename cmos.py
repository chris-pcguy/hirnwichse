import misc


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
CMOS_CHECKSUM_H        = 0x2e
CMOS_CHECKSUM_L        = 0x2f


class Cmos:
    def __init__(self, main):
        self.main = main
        self.cmosData = bytearray(256)
        ##self.cmosData = numpy.zeros(256, dtype=numpy.bytes_, order='C')
        self.cmosIndex = 0
        self.port80h_data = 0

        self.cmosData[CMOS_STATUS_REGISTER_B] = 0x06
        self.cmosData[CMOS_STATUS_REGISTER_D] = 0x80
        self.cmosData[CMOS_FLOPPY_DRIVE_TYPE] = 0x40
        self.cmosData[CMOS_EQUIPMENT_BYTE]    = 0x29
        self.cmosData[CMOS_BASE_MEMORY_L]     = 0x80
        self.cmosData[CMOS_BASE_MEMORY_H]     = 0x02
        self.cmosData[CMOS_EXT_MEMORY_L]      = 0x00
        self.cmosData[CMOS_EXT_MEMORY_H]      = 0x3c
        self.cmosData[CMOS_EXT_MEMORY_L2]     = self.cmosData[CMOS_EXT_MEMORY_L]
        self.cmosData[CMOS_EXT_MEMORY_H2]     = self.cmosData[CMOS_EXT_MEMORY_H]
        
    def makeCheckSum(self):
        checkSum = 0
        for i in range(0x10, 0x2e): # 0x10..0x2d
            checkSum += self.cmosData[i]
        self.cmosData[CMOS_CHECKSUM_L] = checkSum&0xff
        self.cmosData[CMOS_CHECKSUM_H] = (checkSum>>8)&0xff
    def inPort(self, ioPortAddr, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr == 0x70):
                return self.cmosIndex
            elif (ioPortAddr == 0x71):
                return self.cmosData[self.cmosIndex]
            elif (ioPortAddr == 0x80):
                return self.port80h_data
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, ioPortAddr, data, dataSize):
        if (dataSize == misc.OP_SIZE_8BIT):
            if (ioPortAddr == 0x70):
                self.cmosIndex = data
            elif (ioPortAddr == 0x71):
                self.cmosData[self.cmosIndex] = data
                if (self.cmosIndex == CMOS_EXT_MEMORY_L):
                    self.cmosData[CMOS_EXT_MEMORY_L2] = data
                elif (self.cmosIndex == CMOS_EXT_MEMORY_H):
                    self.cmosData[CMOS_EXT_MEMORY_H2] = data
                elif (self.cmosIndex == CMOS_EXT_MEMORY_L2):
                    self.cmosData[CMOS_EXT_MEMORY_L] = data
                elif (self.cmosIndex == CMOS_EXT_MEMORY_H2):
                    self.cmosData[CMOS_EXT_MEMORY_H] = data
                self.makeCheckSum()
            elif (ioPortAddr == 0x80):
                self.port80h_data = data
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers((0x70, 0x71, 0x80), self.inPort)
        self.main.platform.addWriteHandlers((0x70, 0x71, 0x80), self.outPort)



