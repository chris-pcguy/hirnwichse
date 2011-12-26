
import misc, time
from misc cimport Misc

include "globals.pxi"


cdef class Cmos:
    def __init__(self, object main):
        self.main = main
        self.cmosIndex = 0
    cdef unsigned long readValue(self, unsigned char index, unsigned char size):
        return self.configSpace.csReadValue(index, size, False)
    cdef writeValue(self, unsigned char index, unsigned long value, unsigned char size):
        self.configSpace.csWriteValue(index, value, size)
    cdef reset(self):
        cdef unsigned long long memSizeInK, extMemSizeInK, extMemSizeIn64K
        memSizeInK = extMemSizeInK = extMemSizeIn64K = 0
        self.configSpace.csResetData()
        self.writeValue(CMOS_STATUS_REGISTER_B, 0x06, OP_SIZE_BYTE)
        self.writeValue(CMOS_STATUS_REGISTER_D, 0x80, OP_SIZE_BYTE)
        self.writeValue(CMOS_EQUIPMENT_BYTE, 0x21, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_BIOS_CFG, 0x20, OP_SIZE_BYTE) # boot from floppy first.
        self.writeValue(CMOS_BASE_MEMORY_L, 0x80, OP_SIZE_BYTE)
        self.writeValue(CMOS_BASE_MEMORY_H, 0x02, OP_SIZE_BYTE)
        memSizeInK = (self.main.memSize//1024)
        if (memSizeInK > 1024): # if we have over 1MB physical memory ...
            extMemSizeInK = (memSizeInK - 1024) # ... extMemSizeInK is all physical memory over 1MB as KB ...
        if (extMemSizeInK > 0xfc00): # ... with an maximal value of 0xfc00 == 63MB extended memory == 64MB physical memory.
            extMemSizeInK = 0xfc00
        self.writeValue(CMOS_EXT_MEMORY_L, extMemSizeInK&0xff, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY_L2, extMemSizeInK&0xff, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY_H, (extMemSizeInK>>8)&0xff, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY_H2, (extMemSizeInK>>8)&0xff, OP_SIZE_BYTE)
        if (memSizeInK > 16384):
            extMemSizeIn64K = ((memSizeInK - 16384) // 64)
        if (extMemSizeIn64K > 0xbf00):
            extMemSizeIn64K = 0xbf00
        self.writeValue(CMOS_EXT_MEMORY2_L, extMemSizeIn64K&0xff, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY2_H, (extMemSizeIn64K>>8)&0xff, OP_SIZE_BYTE)
        # TODO: set here the physical memory over 4GB if we need it...
        # ... or if we're able to handle it anywhere in the future... oO
        ##self.updateTime()
    cdef updateTime(self):
        cdef unsigned char second, minute, hour, mday, wday, month, year, statusb, century
        statusb = self.readValue(CMOS_STATUS_REGISTER_B, OP_SIZE_BYTE)
        self.dt = time.localtime()
        second  = self.dt.tm_sec
        minute  = self.dt.tm_min
        hour    = self.dt.tm_hour
        wday    = self.dt.tm_wday
        mday    = self.dt.tm_mday
        month   = self.dt.tm_mon
        century, year = divmod(self.dt.tm_year, 100)
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
            second  = (<Misc>self.main.misc).decToBcd(second)
            minute  = (<Misc>self.main.misc).decToBcd(minute)
            hour    = (<Misc>self.main.misc).decToBcd(hour)
            wday    = (<Misc>self.main.misc).decToBcd(wday)
            mday    = (<Misc>self.main.misc).decToBcd(mday)
            month   = (<Misc>self.main.misc).decToBcd(month)
            year    = (<Misc>self.main.misc).decToBcd(year)
            century = (<Misc>self.main.misc).decToBcd(century)
        self.writeValue(CMOS_CURRENT_SECOND, second, OP_SIZE_BYTE)
        self.writeValue(CMOS_CURRENT_MINUTE, minute, OP_SIZE_BYTE)
        self.writeValue(CMOS_CURRENT_HOUR, hour, OP_SIZE_BYTE)
        self.writeValue(CMOS_DAY_OF_WEEK, wday, OP_SIZE_BYTE)
        self.writeValue(CMOS_DAY_OF_MONTH, mday, OP_SIZE_BYTE)
        self.writeValue(CMOS_MONTH, month, OP_SIZE_BYTE)
        self.writeValue(CMOS_YEAR_NO_CENTURY, year, OP_SIZE_BYTE)
        self.writeValue(CMOS_CENTURY, century, OP_SIZE_BYTE)
    cdef makeCheckSum(self):
        cdef unsigned short checkSum = (<Misc>self.main.misc).checksum(bytes(self.configSpace.csRead(0x10, 0x1e))) # 0x10..0x2d
        self.writeValue(CMOS_CHECKSUM_L, checkSum&0xff, OP_SIZE_BYTE)
        self.writeValue(CMOS_CHECKSUM_H, (checkSum>>8)&0xff, OP_SIZE_BYTE)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x70):
                return self.cmosIndex
            elif (ioPortAddr == 0x71):
                if (self.cmosIndex <= 0x9 or self.cmosIndex == CMOS_CENTURY):
                    self.updateTime()
                return self.readValue(self.cmosIndex, OP_SIZE_BYTE)
            elif (ioPortAddr == 0x510): # qemu cfg read handler
                self.main.debug("inPort: qemu cfg port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
                return 0
            else:
                self.main.exitError("inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported. (port: {0:#06x})", dataSize, ioPortAddr)
        return 0
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            data &= BITMASK_BYTE
            if (ioPortAddr == 0x70):
                self.cmosIndex = data&0x7f #(~0x80)
            elif (ioPortAddr == 0x71):
                self.writeValue(self.cmosIndex, data, OP_SIZE_BYTE)
                if (self.cmosIndex == CMOS_STATUS_REGISTER_A):
                    self.main.printMsg("CMOS::outPort: RTC not supported yet.")
                elif (self.cmosIndex == CMOS_EXT_MEMORY_L):
                    self.writeValue(CMOS_EXT_MEMORY_L2, data, OP_SIZE_BYTE)
                elif (self.cmosIndex == CMOS_EXT_MEMORY_H):
                    self.writeValue(CMOS_EXT_MEMORY_H2, data, OP_SIZE_BYTE)
                elif (self.cmosIndex == CMOS_EXT_MEMORY_L2):
                    self.writeValue(CMOS_EXT_MEMORY_L, data, OP_SIZE_BYTE)
                elif (self.cmosIndex == CMOS_EXT_MEMORY_H2):
                    self.writeValue(CMOS_EXT_MEMORY_H, data, OP_SIZE_BYTE)
                self.makeCheckSum()
            else:
                self.main.exitError("outPort: port {0:#06x} not supported. (data: {1:#04x}, dataSize byte)", ioPortAddr, data)
        else:
            if (ioPortAddr == 0x510): # qemu cfg write handler
                self.main.debug("outPort: qemu cfg port {0:#06x} not supported. (data: {1:#04x}, dataSize byte)", ioPortAddr, data)
            else:
                self.main.exitError("outPort: dataSize {0:d} not supported. (port: {1:#06x})", dataSize, ioPortAddr)
        return
    cdef run(self):
        self.configSpace = ConfigSpace(128)
        self.configSpace.run()
        self.reset()
        ##self.updateTime()
        #self.main.platform.addHandlers((0x70, 0x71), self)
        #self.main.platform.addReadHandlers((0x511,), self)
        #self.main.platform.addWriteHandlers((0x510,), self)



