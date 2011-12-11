
import misc, mm, time
cimport mm

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
        cdef unsigned long long extMemSizeInK
        self.configSpace.csResetData()
        self.writeValue(CMOS_STATUS_REGISTER_B, 0x06, OP_SIZE_BYTE)
        self.writeValue(CMOS_STATUS_REGISTER_D, 0x80, OP_SIZE_BYTE)
        self.writeValue(CMOS_EQUIPMENT_BYTE, 0x21, OP_SIZE_BYTE)
        self.writeValue(CMOS_BASE_MEMORY_L, 0x80, OP_SIZE_BYTE)
        self.writeValue(CMOS_BASE_MEMORY_H, 0x02, OP_SIZE_BYTE)
        extMemSizeInK = (self.main.memSize//1024)-640
        if (extMemSizeInK > 16384): # 16M
            extMemSizeInK = 16384   # 16M
        self.writeValue(CMOS_EXT_MEMORY_L, extMemSizeInK&0xff, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY_H, (extMemSizeInK>>8)&0xff, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY_L2, self.readValue(CMOS_EXT_MEMORY_L, OP_SIZE_BYTE), OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY_H2, self.readValue(CMOS_EXT_MEMORY_H, OP_SIZE_BYTE), OP_SIZE_BYTE)
        extMemSizeInK //= 64 # next two lines will need the memSize in 64K-blocks
        self.writeValue(CMOS_EXT_MEMORY2_L, extMemSizeInK&0xff, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY2_H, (extMemSizeInK>>8)&0xff, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_BIOS_CFG, 0x20, OP_SIZE_BYTE) # boot from floppy first.
        ##self.updateTime()
    cpdef updateTime(self):
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
            second  = self.main.misc.decToBcd(second)
            minute  = self.main.misc.decToBcd(minute)
            hour    = self.main.misc.decToBcd(hour)
            wday    = self.main.misc.decToBcd(wday)
            mday    = self.main.misc.decToBcd(mday)
            month   = self.main.misc.decToBcd(month)
            year    = self.main.misc.decToBcd(year)
            century = self.main.misc.decToBcd(century)
        self.writeValue(CMOS_CURRENT_SECOND, second, OP_SIZE_BYTE)
        self.writeValue(CMOS_CURRENT_MINUTE, minute, OP_SIZE_BYTE)
        self.writeValue(CMOS_CURRENT_HOUR, hour, OP_SIZE_BYTE)
        self.writeValue(CMOS_DAY_OF_WEEK, wday, OP_SIZE_BYTE)
        self.writeValue(CMOS_DAY_OF_MONTH, mday, OP_SIZE_BYTE)
        self.writeValue(CMOS_MONTH, month, OP_SIZE_BYTE)
        self.writeValue(CMOS_YEAR_NO_CENTURY, year, OP_SIZE_BYTE)
        self.writeValue(CMOS_CENTURY, century, OP_SIZE_BYTE)
    cpdef makeCheckSum(self):
        cdef unsigned short checkSum = self.main.misc.checksum(bytes(self.configSpace.csRead(0x10, 0x1e))) # 0x10..0x2d
        self.writeValue(CMOS_CHECKSUM_L, checkSum&0xff, OP_SIZE_BYTE)
        self.writeValue(CMOS_CHECKSUM_H, (checkSum>>8)&0xff, OP_SIZE_BYTE)
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x70):
                return self.cmosIndex
            elif (ioPortAddr == 0x71):
                if (self.cmosIndex <= 0x9 or self.cmosIndex == CMOS_CENTURY):
                    self.updateTime()
                return self.readValue(self.cmosIndex, OP_SIZE_BYTE)
            elif (ioPortAddr == 0x510): # qemu cfg read handler
                return 0
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cpdef outPort(self, unsigned short ioPortAddr, unsigned char data, unsigned char dataSize):
        if (dataSize == OP_SIZE_BYTE):
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
            if (ioPortAddr == 0x510): # qemu cfg write handler
                pass
            else:
                self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cpdef run(self):
        self.configSpace = mm.ConfigSpace(128)
        self.configSpace.run()
        self.reset()
        ##self.updateTime()
        self.main.platform.addHandlers((0x70, 0x71), self)
        self.main.platform.addReadHandlers((0x511,), self)
        self.main.platform.addWriteHandlers((0x510,), self)



