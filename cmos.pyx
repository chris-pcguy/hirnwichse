
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"

from time import gmtime
import prctl


cdef class Cmos:
    def __init__(self, Hirnwichse main):
        self.main = main
        self.dt = self.oldDt = None
        self.cmosIndex = self.statusB = self.rtcDelay = 0
        self.equipmentDefaultValue = 0x4
        self.configSpace = ConfigSpace(128, self.main)
    cdef uint16_t decToBcd(self, uint16_t dec):
        return int(str(dec), 16)
    cdef inline uint32_t readValue(self, uint8_t index, uint8_t size):
        cdef uint32_t value
        value = self.configSpace.csReadValueUnsigned(index, size)
        #IF 1:
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Cmos::readValue: index==0x%02x; value==0x%02x; size==%u", index, value, size)
        return value
    cdef inline void writeValue(self, uint8_t index, uint32_t value, uint8_t size):
        #IF 1:
        IF COMP_DEBUG:
            if (self.main.debugEnabled):
                self.main.notice("Cmos::writeValue: index==0x%02x; value==0x%02x; size==%u", index, value, size)
        self.configSpace.csWriteValue(index, value, size)
    cdef void reset(self):
        cdef uint32_t memSizeInK, extMemSizeInK, extMemSizeIn64K
        memSizeInK = extMemSizeInK = extMemSizeIn64K = 0
        self.configSpace.csResetData(0)
        self.writeValue(CMOS_STATUS_REGISTER_A, 0x26, OP_SIZE_BYTE)
        self.writeValue(CMOS_STATUS_REGISTER_B, 0x02, OP_SIZE_BYTE)
        self.writeValue(CMOS_STATUS_REGISTER_D, 0x80, OP_SIZE_BYTE)
        self.writeValue(CMOS_EQUIPMENT_BYTE, self.getEquipmentDefaultValue(), OP_SIZE_BYTE)
        if (self.main.bootFrom == BOOT_FROM_FD): # boot from floppy first.
            self.writeValue(CMOS_EXT_BIOS_CFG, 0x20, OP_SIZE_BYTE)
            self.writeValue(CMOS_BOOT_FROM_1_2, (BOOT_FROM_HD<<4)|BOOT_FROM_FD, OP_SIZE_BYTE) # FD;HD;CD
            self.writeValue(CMOS_BOOT_FROM_3, (BOOT_FROM_CD<<4), OP_SIZE_BYTE)
        elif (self.main.bootFrom == BOOT_FROM_HD): # boot from harddisk first.
            self.writeValue(CMOS_EXT_BIOS_CFG, 0x00, OP_SIZE_BYTE)
            self.writeValue(CMOS_BOOT_FROM_1_2, (BOOT_FROM_FD<<4)|BOOT_FROM_HD, OP_SIZE_BYTE) # HD;FD;CD
            self.writeValue(CMOS_BOOT_FROM_3, (BOOT_FROM_CD<<4), OP_SIZE_BYTE)
        elif (self.main.bootFrom == BOOT_FROM_CD): # boot from cd first
            self.writeValue(CMOS_EXT_BIOS_CFG, 0x00, OP_SIZE_BYTE)
            self.writeValue(CMOS_BOOT_FROM_1_2, (BOOT_FROM_FD<<4)|BOOT_FROM_CD, OP_SIZE_BYTE) # CD;FD;HD
            self.writeValue(CMOS_BOOT_FROM_3, (BOOT_FROM_HD<<4), OP_SIZE_BYTE)
        self.writeValue(CMOS_BASE_MEMORY_L, 0x80, OP_SIZE_BYTE)
        self.writeValue(CMOS_BASE_MEMORY_H, 0x02, OP_SIZE_BYTE)
        memSizeInK = (self.main.memSize<<10)
        if (memSizeInK > 1024): # if we have over 1MB physical memory ...
            extMemSizeInK = (memSizeInK - 1024) # ... extMemSizeInK is all physical memory over 1MB as KB ...
        if (extMemSizeInK > 0xfc00): # ... with an maximal value of 0xfc00 == 63MB extended memory == 64MB physical memory.
            extMemSizeInK = 0xfc00
        self.writeValue(CMOS_EXT_MEMORY_L, <uint8_t>extMemSizeInK, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY_L2, <uint8_t>extMemSizeInK, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY_H, <uint8_t>(extMemSizeInK>>8), OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY_H2, <uint8_t>(extMemSizeInK>>8), OP_SIZE_BYTE)
        if (memSizeInK > 16384):
            extMemSizeIn64K = ((memSizeInK - 16384) // 64)
        if (extMemSizeIn64K > 0xbf00):
            extMemSizeIn64K = 0xbf00
        self.writeValue(CMOS_EXT_MEMORY2_L, <uint8_t>extMemSizeIn64K, OP_SIZE_BYTE)
        self.writeValue(CMOS_EXT_MEMORY2_H, <uint8_t>(extMemSizeIn64K>>8), OP_SIZE_BYTE)
        # TODO: set here the physical memory over 4GB if we need it...
        # ... or if we're able to handle it anytime in the future... oO
        ##self.updateTime()
    cdef void updateTime(self):
        cdef uint8_t second, minute, hour, mday, wday, month, year, century
        self.statusB = self.readValue(CMOS_STATUS_REGISTER_B, OP_SIZE_BYTE)
        if (self.statusB&0x80):
            return
        self.oldDt = self.dt
        self.dt = gmtime()
        if (self.oldDt and self.dt and self.dt == self.oldDt):
            return
        second  = self.dt.tm_sec
        minute  = self.dt.tm_min
        hour    = self.dt.tm_hour
        wday    = self.dt.tm_wday
        mday    = self.dt.tm_mday
        month   = self.dt.tm_mon
        century, year = divmod(self.dt.tm_year, 100)
        if (not self.statusB&CMOS_STATUSB_24HOUR):
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
        if (not self.statusB&CMOS_STATUSB_BIN):
            second  = self.decToBcd(second)
            minute  = self.decToBcd(minute)
            hour    = self.decToBcd(hour)
            wday    = self.decToBcd(wday)
            mday    = self.decToBcd(mday)
            month   = self.decToBcd(month)
            year    = self.decToBcd(year)
            century = self.decToBcd(century)
        self.writeValue(CMOS_CURRENT_SECOND, second, OP_SIZE_BYTE)
        self.writeValue(CMOS_CURRENT_MINUTE, minute, OP_SIZE_BYTE)
        self.writeValue(CMOS_CURRENT_HOUR, hour, OP_SIZE_BYTE)
        self.writeValue(CMOS_DAY_OF_WEEK, wday, OP_SIZE_BYTE)
        self.writeValue(CMOS_DAY_OF_MONTH, mday, OP_SIZE_BYTE)
        self.writeValue(CMOS_MONTH, month, OP_SIZE_BYTE)
        self.writeValue(CMOS_YEAR_NO_CENTURY, year, OP_SIZE_BYTE)
        self.writeValue(CMOS_CENTURY, century, OP_SIZE_BYTE)
    cdef void secondsThreadFunc(self):
        cdef uint8_t statusA
        prctl.set_name("Cmos::secondsThreadFunc")
        with nogil:
            usleep(1000000)
        statusA = self.readValue(CMOS_STATUS_REGISTER_A, OP_SIZE_BYTE)
        if ((statusA & 0x60) == 0x60):
            return
        if ((self.statusB & 0x80) != 0):
            return
        self.writeValue(CMOS_STATUS_REGISTER_A, (statusA | 0x80), OP_SIZE_BYTE)
        self.updateTime()
        #self.main.misc.createThread(self.uipThreadFunc, self)
        self.uipThreadFunc()
    cdef void uipThreadFunc(self):
        with nogil:
            #usleep(244)
            usleep(244000)
        self.updateTime()
        if ((self.statusB & 0x10) != 0):
            self.writeValue(CMOS_STATUS_REGISTER_C, (self.readValue(CMOS_STATUS_REGISTER_C, OP_SIZE_BYTE) | 0x90), OP_SIZE_BYTE)
            (<Pic>self.main.platform.pic).raiseIrq(CMOS_RTC_IRQ)
        self.writeValue(CMOS_STATUS_REGISTER_A, (self.readValue(CMOS_STATUS_REGISTER_A, OP_SIZE_BYTE) & 0x7f), OP_SIZE_BYTE)
    cdef void periodicFunc(self):
        if ((self.statusB & 0x40) != 0):
            self.writeValue(CMOS_STATUS_REGISTER_C, (self.readValue(CMOS_STATUS_REGISTER_C, OP_SIZE_BYTE) | 0xc0), OP_SIZE_BYTE)
            (<Pic>self.main.platform.pic).raiseIrq(CMOS_RTC_IRQ)
    cdef void makeCheckSum(self):
        cdef uint16_t checkSum
        checkSum = sum(self.configSpace.csRead(0x10, 0x1e)) # 0x10..0x2d
        self.writeValue(CMOS_CHECKSUM_L, <uint8_t>checkSum, OP_SIZE_BYTE)
        self.writeValue(CMOS_CHECKSUM_H, <uint8_t>(checkSum>>8), OP_SIZE_BYTE)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil:
        cdef uint8_t tempIndex, ret = BITMASK_BYTE
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr == 0x70):
                ret = self.cmosIndex
            elif (ioPortAddr == 0x71):
                tempIndex = self.cmosIndex&0x7f
                with gil:
                    if (tempIndex <= 0x9 or tempIndex == CMOS_CENTURY):
                        self.updateTime()
                    ret = self.readValue(tempIndex, OP_SIZE_BYTE)
                    if (tempIndex == CMOS_STATUS_REGISTER_C):
                        self.writeValue(tempIndex, 0, OP_SIZE_BYTE)
                        (<Pic>self.main.platform.pic).lowerIrq(CMOS_RTC_IRQ)
            else:
                self.main.exitError("CMOS::inPort: port 0x%04x not supported. (dataSize byte)", ioPortAddr)
        else:
            self.main.exitError("CMOS::inPort: dataSize %u not supported. (port: 0x%04x)", dataSize, ioPortAddr)
            return ret
        IF COMP_DEBUG:
            self.main.notice("CMOS::inPort: port 0x%04x; ret: 0x%02x, dataSize byte", ioPortAddr, ret)
        return ret
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil:
        cdef uint8_t tempIndex, timeBase, selectionBits
        if (dataSize == OP_SIZE_BYTE):
            IF COMP_DEBUG:
                self.main.notice("CMOS::outPort: port 0x%04x; data: 0x%02x, dataSize byte", ioPortAddr, data)
            data = <uint8_t>data
            if (ioPortAddr == 0x70):
                self.cmosIndex = data
            elif (ioPortAddr == 0x71):
                tempIndex = self.cmosIndex&0x7f
                if (tempIndex in (0xc, 0xd)):
                    return
                with gil:
                    if (tempIndex == CMOS_STATUS_REGISTER_A):
                        self.main.notice("CMOS::outPort: RTC is not fully supported yet. (data==0x%02x)", data)
                        timeBase = (data>>4)&7
                        selectionBits = data&0xf
                        if (timeBase != 0x2):
                            self.main.exitError("CMOS::outPort: RTC timebase != 0x2. (data==0x%02x)", data)
                            return
                        if (not selectionBits):
                            self.rtcDelay = 0
                        elif (selectionBits in (0x1, 0x2)):
                            self.main.exitError("CMOS::outPort: RTC selection bits in (1, 2). (data==0x%02x)", data)
                            return
                        else:
                            self.rtcDelay = round(1.0e6/(65536.0/(1<<selectionBits)))
                    elif (tempIndex == CMOS_STATUS_REGISTER_B):
                        data &= 0xf7
                        if ((data & 0x80)!=0):
                            data &= 0xef
                        if ((data & 0x20)!=0):
                            self.main.exitError("CMOS::outPort: statusB alarm set. (data==0x%02x)", data)
                            return
                        if ((data & 0x1)!=0):
                            self.main.exitError("CMOS::outPort: daylight set. (data==0x%02x)", data)
                            return
                        (<PitChannel>self.rtcChannel).timerEnabled = False
                        with gil:
                            if ((<PitChannel>self.rtcChannel).threadObject):
                                (<PitChannel>self.rtcChannel).threadObject.join()
                                #(<PitChannel>self.rtcChannel).threadObject.cancel()
                                #(<PitChannel>self.rtcChannel).threadObject.result()
                                (<PitChannel>self.rtcChannel).threadObject = None
                        if (self.rtcDelay and (data & 0x40)!=0):
                            (<PitChannel>self.rtcChannel).counterMode = 2
                            (<PitChannel>self.rtcChannel).tempTimerValue = self.rtcDelay
                            (<PitChannel>self.rtcChannel).runTimer()
                        self.statusB = data
                    elif (tempIndex == CMOS_EXT_MEMORY_L):
                        self.writeValue(CMOS_EXT_MEMORY_L2, data, OP_SIZE_BYTE)
                    elif (tempIndex == CMOS_EXT_MEMORY_H):
                        self.writeValue(CMOS_EXT_MEMORY_H2, data, OP_SIZE_BYTE)
                    elif (tempIndex == CMOS_EXT_MEMORY_L2):
                        self.writeValue(CMOS_EXT_MEMORY_L, data, OP_SIZE_BYTE)
                    elif (tempIndex == CMOS_EXT_MEMORY_H2):
                        self.writeValue(CMOS_EXT_MEMORY_H, data, OP_SIZE_BYTE)
                    self.writeValue(tempIndex, data, OP_SIZE_BYTE)
                    self.makeCheckSum()
            else:
                self.main.exitError("CMOS::outPort: port 0x%04x not supported. (data: 0x%02x, dataSize byte)", ioPortAddr, data)
        else:
            self.main.exitError("CMOS::outPort: dataSize %u not supported. (port: 0x%04x)", dataSize, ioPortAddr)
        return
    cdef void run(self):
        self.reset()
        self.main.misc.createThread(self.secondsThreadFunc, self)
        ##self.updateTime()
        #self.main.platform.addHandlers((0x70, 0x71), self)



