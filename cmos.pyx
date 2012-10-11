
from time import gmtime

include "globals.pxi"


cdef class Cmos:
    def __init__(self, object main):
        self.main = main
        self.dt = self.oldDt = None
        self.cmosIndex = 0
        self.equipmentDefaultValue = 0x0
    cdef inline void setEquipmentDefaultValue(self, unsigned char value):
        self.equipmentDefaultValue = value
    cdef unsigned char getEquipmentDefaultValue(self):
        return self.equipmentDefaultValue
    cdef unsigned int readValue(self, unsigned char index, unsigned char size):
        return self.configSpace.csReadValueUnsigned(index, size)
    cdef inline void writeValue(self, unsigned char index, unsigned int value, unsigned char size):
        self.configSpace.csWriteValue(index, value, size)
    cdef void reset(self):
        cdef unsigned int memSizeInK, extMemSizeInK, extMemSizeIn64K
        memSizeInK = extMemSizeInK = extMemSizeIn64K = 0
        self.configSpace.csResetData()
        self.writeValue(CMOS_STATUS_REGISTER_B, 0x02, OP_SIZE_BYTE)
        self.writeValue(CMOS_STATUS_REGISTER_D, 0x80, OP_SIZE_BYTE)
        self.writeValue(CMOS_EQUIPMENT_BYTE, self.getEquipmentDefaultValue(), OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_BIOS_CFG, 0x20, OP_SIZE_BYTE) # boot from floppy first.
        self.writeValue(CMOS_BASE_MEMORY_L, 0x80, OP_SIZE_BYTE)
        self.writeValue(CMOS_BASE_MEMORY_H, 0x02, OP_SIZE_BYTE)
        memSizeInK = (self.main.memSize<<10)
        if (memSizeInK > 1024): # if we have over 1MB physical memory ...
            extMemSizeInK = (memSizeInK - 1024) # ... extMemSizeInK is all physical memory over 1MB as KB ...
        if (extMemSizeInK > 0xfc00): # ... with an maximal value of 0xfc00 == 63MB extended memory == 64MB physical memory.
            extMemSizeInK = 0xfc00
        self.writeValue(CMOS_EXT_MEMORY_L, <unsigned char>extMemSizeInK, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY_L2, <unsigned char>extMemSizeInK, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY_H, <unsigned char>(extMemSizeInK>>8), OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY_H2, <unsigned char>(extMemSizeInK>>8), OP_SIZE_BYTE)
        if (memSizeInK > 16384):
            extMemSizeIn64K = ((memSizeInK - 16384) // 64)
        if (extMemSizeIn64K > 0xbf00):
            extMemSizeIn64K = 0xbf00
        self.writeValue(CMOS_EXT_MEMORY2_L, <unsigned char>extMemSizeIn64K, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY2_H, <unsigned char>(extMemSizeIn64K>>8), OP_SIZE_BYTE)
        # TODO: set here the physical memory over 4GB if we need it...
        # ... or if we're able to handle it anywhere in the future... oO
        ##self.updateTime()
    cdef void updateTime(self):
        cdef unsigned char second, minute, hour, mday, wday, month, year, statusb, century
        self.oldDt = self.dt
        self.dt = gmtime()
        if (self.oldDt and self.dt and self.dt == self.oldDt):
            return
        statusb = self.readValue(CMOS_STATUS_REGISTER_B, OP_SIZE_BYTE)
        second  = self.dt.tm_sec
        minute  = self.dt.tm_min
        hour    = self.dt.tm_hour
        wday    = self.dt.tm_wday
        mday    = self.dt.tm_mday
        month   = self.dt.tm_mon
        century, year = divmod(self.dt.tm_year, 100)
        if (not statusb&CMOS_STATUSB_24HOUR):
            if (hour == 0):
                hour = 12
            elif (hour >= 12):
                if (hour > 12):
                    hour -= 12
                hour |= 0x80
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
    cdef void makeCheckSum(self):
        cdef unsigned short checkSum = (<Misc>self.main.misc).checksum(bytes(self.configSpace.csRead(0x10, 0x1e))) # 0x10..0x2d
        self.writeValue(CMOS_CHECKSUM_L, <unsigned char>checkSum, OP_SIZE_BYTE)
        self.writeValue(CMOS_CHECKSUM_H, (checkSum>>8), OP_SIZE_BYTE)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char tempIndex
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x70):
                return self.cmosIndex
            elif (ioPortAddr == 0x71):
                tempIndex = self.cmosIndex&0x7f
                if (tempIndex <= 0x9 or tempIndex == CMOS_CENTURY):
                    self.updateTime()
                return self.readValue(tempIndex, OP_SIZE_BYTE)
            else:
                self.main.exitError("inPort: port {0:#06x} not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported. (port: {0:#06x})", dataSize, ioPortAddr)
        return BITMASK_BYTE
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef unsigned char tempIndex
        if (dataSize == OP_SIZE_BYTE):
            data = <unsigned char>data
            if (ioPortAddr == 0x70):
                self.cmosIndex = data
            elif (ioPortAddr == 0x71):
                tempIndex = self.cmosIndex&0x7f
                self.writeValue(tempIndex, data, OP_SIZE_BYTE)
                if (tempIndex == CMOS_STATUS_REGISTER_A):
                    self.main.notice("CMOS::outPort: RTC not supported yet.")
                elif (tempIndex == CMOS_EXT_MEMORY_L):
                    self.writeValue(CMOS_EXT_MEMORY_L2, data, OP_SIZE_BYTE)
                elif (tempIndex == CMOS_EXT_MEMORY_H):
                    self.writeValue(CMOS_EXT_MEMORY_H2, data, OP_SIZE_BYTE)
                elif (tempIndex == CMOS_EXT_MEMORY_L2):
                    self.writeValue(CMOS_EXT_MEMORY_L, data, OP_SIZE_BYTE)
                elif (tempIndex == CMOS_EXT_MEMORY_H2):
                    self.writeValue(CMOS_EXT_MEMORY_H, data, OP_SIZE_BYTE)
                self.makeCheckSum()
            else:
                self.main.exitError("outPort: port {0:#06x} not supported. (data: {1:#04x}, dataSize byte)", ioPortAddr, data)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported. (port: {1:#06x})", dataSize, ioPortAddr)
        return
    cdef void run(self):
        self.configSpace = ConfigSpace(128, self.main)
        self.reset()
        ##self.updateTime()
        #self.main.platform.addHandlers((0x70, 0x71), self)



