import misc, mm, time

include "globals.pxi"

CMOS_CURRENT_SECOND    = 0x00
CMOS_ALARM_SECOND      = 0x01
CMOS_CURRENT_MINUTE    = 0x02
CMOS_ALARM_MINUTE      = 0x03
CMOS_CURRENT_HOUR      = 0x04
CMOS_ALARM_HOUR        = 0x05
CMOS_DAY_OF_WEEK       = 0x06
CMOS_DAY_OF_MONTH      = 0x07
CMOS_MONTH             = 0x08
CMOS_YEAR              = 0x09 # year without century: e.g.  00 - 99
CMOS_STATUS_REGISTER_A = 0x0a
CMOS_STATUS_REGISTER_B = 0x0b
CMOS_STATUS_REGISTER_C = 0x0c
CMOS_STATUS_REGISTER_D = 0x0d
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


CMOS_STATUSB_24HOUR = 0x02
CMOS_STATUSB_BIN    = 0x04

cdef class Cmos:
    cdef object main, configSpace, dt
    cdef unsigned char cmosIndex, port80h_data
    def __init__(self, object main):
        self.main = main
        self.cmosIndex = 0
        self.port80h_data = 0
        self.reset()
    def reset(self):
        self.configSpace = mm.ConfigSpace(128, self.main)
        self.configSpace.csWriteValue(CMOS_STATUS_REGISTER_B, 0x06, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_STATUS_REGISTER_D, 0x80, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_FLOPPY_DRIVE_TYPE, 0x40, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_EQUIPMENT_BYTE, 0x21, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_BASE_MEMORY_L, 0x80, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_BASE_MEMORY_H, 0x02, OP_SIZE_BYTE)
        cdef unsigned long long extMemSizeInK = (self.main.memSize//1024)-640
        if (extMemSizeInK > 16384): # 16M
            extMemSizeInK = 16384   # 16M
        self.configSpace.csWriteValue(CMOS_EXT_MEMORY_L, extMemSizeInK&0xff, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_EXT_MEMORY_H, (extMemSizeInK>>8)&0xff, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_EXT_MEMORY_L2, self.configSpace.csReadValue(CMOS_EXT_MEMORY_L, OP_SIZE_BYTE), OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_EXT_MEMORY_H2, self.configSpace.csReadValue(CMOS_EXT_MEMORY_H, OP_SIZE_BYTE), OP_SIZE_BYTE)
        cdef unsigned long long extMemSizeIn64K = extMemSizeInK//64
        self.configSpace.csWriteValue(CMOS_EXT_MEMORY2_L, extMemSizeIn64K&0xff, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_EXT_MEMORY2_H, (extMemSizeIn64K>>8)&0xff, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_EXT_BIOS_CFG, 0x20, OP_SIZE_BYTE) # boot from floppy first.
        self.updateTime()
    def updateTime(self):
        cdef unsigned char second, minute, hour, mday, wday, month, year, statusb
        statusb = self.configSpace.csReadValue(CMOS_STATUS_REGISTER_B, OP_SIZE_BYTE)
        self.dt = time.localtime()
        second  = self.dt.tm_sec
        minute  = self.dt.tm_min
        hour    = self.dt.tm_hour
        wday    = self.dt.tm_wday
        mday    = self.dt.tm_mday
        month   = self.dt.tm_mon
        year    = self.dt.tm_year%100
        if (not statusb&CMOS_STATUSB_24HOUR):
            if (hour >= 12):
                hour %= 12
                if (hour == 0):
                    hour = 12
                hour |= 80
            elif (hour == 0):
                hour = 12
        wday += 2
        wday %= 7
        if (wday == 0):
            wday = 7
        if (not statusb&CMOS_STATUSB_BIN):
            second = self.main.misc.decToBcd(second)
            minute = self.main.misc.decToBcd(minute)
            hour   = self.main.misc.decToBcd(hour)
            wday   = self.main.misc.decToBcd(wday)
            mday   = self.main.misc.decToBcd(mday)
            month  = self.main.misc.decToBcd(month)
            year   = self.main.misc.decToBcd(year)
        self.configSpace.csWriteValue(CMOS_CURRENT_SECOND, second, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_CURRENT_MINUTE, minute, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_CURRENT_HOUR, hour, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_DAY_OF_WEEK, wday, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_DAY_OF_MONTH, mday, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_MONTH, month, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_YEAR, year, OP_SIZE_BYTE)
    def makeCheckSum(self):
        cdef unsigned short checkSum = self.main.misc.checksum(bytes(self.configSpace.csRead(0x10, 0x1e))) # 0x10..0x2d
        self.configSpace.csWriteValue(CMOS_CHECKSUM_L, checkSum&0xff, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(CMOS_CHECKSUM_H, (checkSum>>8)&0xff, OP_SIZE_BYTE)
    def inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x70):
                return self.cmosIndex
            elif (ioPortAddr == 0x71):
                return self.configSpace.csReadValue(self.cmosIndex, OP_SIZE_BYTE)
            elif (ioPortAddr == 0x80):
                return self.port80h_data
            elif (ioPortAddr == 0x510): # qemu cfg read handler
                return 0
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, unsigned short ioPortAddr, int data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x70):
                self.cmosIndex = data&(~0x80)
            elif (ioPortAddr == 0x71):
                self.configSpace.csWriteValue(self.cmosIndex, data, OP_SIZE_BYTE)
                if (self.cmosIndex == CMOS_EXT_MEMORY_L):
                    self.configSpace.csWriteValue(CMOS_EXT_MEMORY_L2, data, OP_SIZE_BYTE)
                elif (self.cmosIndex == CMOS_EXT_MEMORY_H):
                    self.configSpace.csWriteValue(CMOS_EXT_MEMORY_H2, data, OP_SIZE_BYTE)
                elif (self.cmosIndex == CMOS_EXT_MEMORY_L2):
                    self.configSpace.csWriteValue(CMOS_EXT_MEMORY_L, data, OP_SIZE_BYTE)
                elif (self.cmosIndex == CMOS_EXT_MEMORY_H2):
                    self.configSpace.csWriteValue(CMOS_EXT_MEMORY_H, data, OP_SIZE_BYTE)
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
        self.main.platform.addReadHandlers((0x70, 0x71, 0x80,0x511), self.inPort)
        self.main.platform.addWriteHandlers((0x70, 0x71, 0x80,0x510), self.outPort)



