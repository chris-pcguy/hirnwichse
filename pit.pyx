
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"

import prctl

DEF READBACK_DONT_LATCH_COUNT  = 0x20
DEF READBACK_DONT_LATCH_STATUS = 0x10


cdef class PitChannel:
    def __init__(self, Pit pit, uint8_t channelId):
        self.pit = pit
        self.channelId = channelId
        self.bcdMode = 0 # 0 == binary; 1 == BCD
        self.localCounterMode = self.counterMode = 0 # 0-5 valid, 6,7 not
        self.counterWriteMode = 0 # 1 == LSB ; 2 == MSB ; 0/3 == LSB;MSB
        self.readBackStatusValue = 0
        self.counterValue = self.counterStartValue = self.counterLatchValue = self.tempTimerValue = 0
        self.counterFlipFlop = self.timerEnabled = self.readBackStatusIssued = self.resetChannel = False
        self.threadObject = None
    cdef uint16_t bcdToDec(self, uint16_t bcd):
        return int(hex(bcd)[2:], 10)
    cdef void readBackCount(self) nogil:
        self.counterLatchValue = self.counterValue
    cdef void readBackStatus(self) nogil:
        self.readBackStatusValue = self.bcdMode
        self.readBackStatusValue |= self.counterMode<<1
        self.readBackStatusValue |= self.counterWriteMode<<4
    cdef void mode0Func(self):
        if (self.channelId == 0): # just raise IRQ on channel0
            (<Pic>self.pit.main.platform.pic).lowerIrq(0)
        elif (self.channelId == 2 and (<PS2>self.pit.main.platform.ps2).ppcbT2Gate):
            (<PS2>self.pit.main.platform.ps2).ppcbT2Out = False
        #self.pit.main.notice("PitChannel::mode0Func: self.tempTimerValue %u", self.tempTimerValue)
        with nogil:
            usleep(self.tempTimerValue)
        if (not self.timerEnabled or self.pit.main.quitEmu):
            return
        self.counterValue = 0
        if (self.channelId == 0): # just raise IRQ on channel0
            (<Pic>self.pit.main.platform.pic).raiseIrq(0)
        elif (self.channelId == 2 and (<PS2>self.pit.main.platform.ps2).ppcbT2Gate):
            (<PS2>self.pit.main.platform.ps2).ppcbT2Out = True
        #else:
        #self.pit.main.notice("PitChannel::mode0Func: counterMode %u used channelId %u.", self.localCounterMode, self.channelId)
        self.timerEnabled = False
    cdef void mode2Func(self): # TODO
        cdef uint8_t clear
        cdef uint64_t i
        #prctl.set_name("Pit::%u%u_1".format(self.channelId, self.localCounterMode))
        while (self.timerEnabled and not self.pit.main.quitEmu and self.localCounterMode in (2,3)):
            #prctl.set_name("Pit::%u%u_2".format(self.channelId, self.localCounterMode))
            #self.main.notice("PitChannel::mode2Func: loop1 begin")
            with nogil:
            #IF 1:
                if (self.channelId == 0): # just raise IRQ on channel0
                    clear = (<Pic>self.pit.main.platform.pic).isClear(0)
                    #self.pit.main.notice("PitChannel::mode2Func: lowerIrq(0)")
                    if (clear):
                        #self.pit.main.notice("PitChannel::mode2Func: lowerIrq(0): clear")
                        (<Pic>self.pit.main.platform.pic).lowerIrq(0)
                elif (self.channelId == 2 and (<PS2>self.pit.main.platform.ps2).ppcbT2Gate):
                    (<PS2>self.pit.main.platform.ps2).ppcbT2Out = False
                elif (self.channelId == 3):
                    clear = (<Pic>self.pit.main.platform.pic).isClear(CMOS_RTC_IRQ) and (<Pic>self.pit.main.platform.pic).isClear(IRQ_SECOND_PIC)
                    if (clear):
                        (<Pic>self.pit.main.platform.pic).lowerIrq(CMOS_RTC_IRQ)
                #with gil:
                #    prctl.set_name("Pit::%u%u_10".format(self.channelId, self.localCounterMode))
                if (self.channelId != 3):
                    #with gil:
                    #    prctl.set_name("Pit::%u%u_14".format(self.channelId, self.localCounterMode))
                    #self.pit.main.notice("PitChannel::mode2Func: before while")
                    #self.pit.main.notice("PitChannel::mode2Func(%u): counterValue==%u", self.channelId, self.counterStartValue)
                    self.counterValue = self.counterStartValue&0xffffe
                    #with nogil:
                    #    #usleep(self.tempTimerValue)
                    #    usleep(0)
                    #    #usleep(1)
                    #    #usleep(100)
                    #    #usleep(3000)
                    #if (self.localCounterMode == 3 and self.counterValue&0x1):
                    #    self.counterValue -= 1
                    #while ((((self.localCounterMode == 3 and self.counterValue >= 3) or (self.localCounterMode != 3 and self.counterValue >= 2)) and self.counterValue <= (BITMASK_WORD+1)) and self.timerEnabled and (not self.pit.main.quitEmu)):
                    #while ((self.counterValue >= 4 and self.counterValue <= (BITMASK_WORD+1)) and self.timerEnabled and (not self.pit.main.quitEmu)):
                    if (self.localCounterMode == 3):
                        #i = 2
                        i = 4 # HACK
                    else:
                        #i = 1
                        i = 2 # HACK
                    #with gil:
                    #    prctl.set_name("Pit::%u%u_15".format(self.channelId, self.localCounterMode))
                    #while ((((self.localCounterMode == 3 and self.counterValue >= 3) or (self.localCounterMode != 3 and self.counterValue >= 2)) and self.counterValue <= (BITMASK_WORD+1)) and self.timerEnabled and (not self.pit.main.quitEmu)):
                    #while ((self.counterValue >= 4 and self.counterValue <= (BITMASK_WORD+1)) and self.timerEnabled and (not self.pit.main.quitEmu)):
                    while (self.counterValue >= 0 and self.counterValue <= (BITMASK_WORD+1) and self.timerEnabled and not self.pit.main.quitEmu and (self.localCounterMode == 2 or self.localCounterMode == 3)):
                        #self.main.notice("PitChannel::mode2Func: loop2 begin")
                        #for i in range(60):
                        #    pass
                        self.counterValue -= i
                        #self.pit.main.notice("PitChannel::mode2Func: in while")
                        #if (not (self.counterValue&0x1fff)):
                        #if (not (self.counterValue&0xfff)):
                        #if (not (self.counterValue&0xff)):
                        #if (not (self.counterValue&0x7f)):
                        #if (not (self.counterValue&0x3f)):
                        #if (not (self.counterValue&0x1f)):
                        #if (not (self.counterValue&0xf)):
                        #if (not (self.counterValue&0x7)):
                        if (not (self.counterValue&0x3)):
                        #if (not (self.counterValue&0x1)):
                        #IF 1:
                        #IF 0:
                            #with gil:
                            #    prctl.set_name("Pit::%u%u_16_0x%02x".format(self.channelId, self.localCounterMode, self.counterValue))
                            #usleep(self.tempTimerValue)
                            #with nogil:
                            usleep(0)
                            #usleep(1)
                            #usleep(5)
                            #usleep(10)
                            #usleep(25)
                            #usleep(50)
                            #usleep(100)
                            #with gil:
                            #    prctl.set_name("Pit::%u%u_17".format(self.channelId, self.localCounterMode))
                        #for i in range(1000000):
                        #for i in range(50000):
                        #for i in range(30000):
                        #for i in range(10000):
                        #for i in range(5000):
                        #for i in range(4000):
                        #for i in range(2500):
                        #for i in range(2000):
                        #for i in range(1000):
                        #for i in range(250):
                        #for i in range(100):
                        #for i in range(60):
                        #for i in range(1):
                        #    pass
                    #with gil:
                    #    prctl.set_name("Pit::%u%u_18".format(self.channelId, self.localCounterMode))
                    if (not self.timerEnabled or self.pit.main.quitEmu):
                        break
                    #self.counterValue = 1 # to be sure
                    #self.pit.main.notice("PitChannel::mode2Func(%u): after while", self.channelId)
                    #with gil:
                    #    prctl.set_name("Pit::%u%u_19".format(self.channelId, self.localCounterMode))
                else:
                    #with gil:
                    #    prctl.set_name("Pit::%u%u_12".format(self.channelId, self.localCounterMode))
                    #usleep(self.tempTimerValue)
                    usleep(0)
                    #usleep(1)
                    #usleep(100)
                    #usleep(3000)
                    #with gil:
                    #    prctl.set_name("Pit::%u%u_13".format(self.channelId, self.localCounterMode))
                #with gil:
                #    prctl.set_name("Pit::%u%u_11".format(self.channelId, self.localCounterMode))
                if (self.channelId == 0): # just raise IRQ on channel0
                    #clear = (<Pic>self.pit.main.platform.pic).isClear(0)
                    #self.pit.main.notice("PitChannel::mode2Func: raiseIrq(0)")
                    if (clear):
                    #if (clear and self.pit.main.cpu.savedCs != 0x0028):
                        #self.pit.main.notice("PitChannel::mode2Func: raiseIrq(0): clear")
                        (<Pic>self.pit.main.platform.pic).raiseIrq(0)
                elif (self.channelId == 2 and (<PS2>self.pit.main.platform.ps2).ppcbT2Gate):
                    (<PS2>self.pit.main.platform.ps2).ppcbT2Out = True
                elif (self.channelId == 3):
                    if (clear):
                        #self.pit.main.notice("PitChannel::mode2Func: raiseIrq(CMOS_RTC_IRQ): clear")
                        with gil:
                            (<Cmos>self.pit.main.platform.cmos).periodicFunc()
                else:
                    IF COMP_DEBUG:
                        self.pit.main.notice("PitChannel::mode2Func: counterMode %u used channelId %u.", self.localCounterMode, self.channelId)
            #prctl.set_name("Pit::%u%u_3".format(self.channelId, self.localCounterMode))
        #prctl.set_name("Pit::%u%u_4".format(self.channelId, self.localCounterMode))
    cdef void timerFunc(self): # TODO
        prctl.set_name("Pit::%u%u_0".format(self.channelId, self.localCounterMode))
        if (self.timerEnabled):
            if (self.localCounterMode == 0):
                self.mode0Func()
            elif (self.localCounterMode in (2, 3)):
                self.mode2Func()
            else:
                self.pit.main.exitError("timerFunc: counterMode %u is unknown.", self.localCounterMode)
                return
        #prctl.set_name("Pit::%u%u_5".format(self.channelId, self.localCounterMode))
        #with nogil:
        #    usleep(3000000)
        #prctl.set_name("Pit::%u%u_6".format(self.channelId, self.localCounterMode))
    cdef void runTimer(self):
        self.resetChannel = False
        self.localCounterMode = self.counterMode
        if (self.channelId == 1):
            self.pit.main.notice("PitChannel::runTimer: PIT-Channel 1 is ancient.")
        elif (self.channelId != 3):
            if (self.counterStartValue == 0):
                #self.counterStartValue = 0x10000
                self.counterStartValue = 0xffff # TODO: HACK
            if (self.counterStartValue & 1):
                self.counterStartValue -= 1
            if (self.bcdMode):
                self.pit.main.notice("PitChannel::runTimer: WARNING: TODO: bcdMode may not work!")
                self.counterStartValue = self.bcdToDec(self.counterStartValue)
            if (self.localCounterMode == 3):
                #self.counterStartValue &= 0xffffe
                #self.counterStartValue &= 0xfffe
                #self.counterStartValue &= 0xfffffffe
                if (self.counterStartValue == 0):
                    self.pit.main.exitError("runTimer: counterValue is 0")
                    return
            self.counterValue = self.counterStartValue
            self.tempTimerValue = round(1.0e6/(1193182.0/self.counterValue))
            #if (self.localCounterMode == 0):
            #    self.tempTimerValue <<= 4 # TODO: HACK!
            #    #self.tempTimerValue <<= 6 # TODO: HACK!
            #if (self.localCounterMode == 3):
            #    self.tempTimerValue >>= 1
            if (self.localCounterMode not in (0, 2, 3)):
                self.pit.main.exitError("runTimer: counterMode %u not supported yet. (channelId: %u)", self.localCounterMode, self.channelId)
                return
            elif (self.localCounterMode == 2 and self.channelId == 2):
                self.pit.main.exitError("runTimer: is it ok to use mode-%u with channelId-%u and cpu clock measures?", self.localCounterMode, self.channelId)
                return
            elif (self.channelId == 2 and (<PS2>self.pit.main.platform.ps2).ppcbT2Gate):
                (<PS2>self.pit.main.platform.ps2).ppcbT2Out = False
        self.timerEnabled = False
        if (self.threadObject):
            self.threadObject.join()
            #self.threadObject.cancel()
            #self.threadObject.result()
            self.threadObject = None
        if (not self.pit.main.quitEmu):
            self.timerEnabled = True
            self.threadObject = self.pit.main.misc.createThread(self.timerFunc, self)

cdef class Pit:
    def __init__(self, Hirnwichse main):
        cdef PitChannel channel0, channel1, channel2, channel3
        self.main = main
        channel0 = PitChannel(self, 0)
        channel1 = PitChannel(self, 1)
        channel2 = PitChannel(self, 2)
        channel3 = PitChannel(self, 3)
        self.channels[0] = <PyObject*>channel0
        self.channels[1] = <PyObject*>channel1
        self.channels[2] = <PyObject*>channel2
        (<Cmos>self.main.platform.cmos).rtcChannel = <PyObject*>channel3
        Py_INCREF(channel0)
        Py_INCREF(channel1)
        Py_INCREF(channel2)
        Py_INCREF(channel3)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil:
        cdef uint8_t channelId, retVal
        cdef uint32_t temp
        IF COMP_DEBUG:
        #IF 1:
            if (self.main.debugEnabled):
                self.main.notice("PIT::inPort_1: port 0x%04x with dataSize %u.", ioPortAddr, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channelId = ioPortAddr&3
                temp = (<PitChannel>self.channels[channelId]).counterValue
                if ((<PitChannel>self.channels[channelId]).readBackStatusIssued):
                    (<PitChannel>self.channels[channelId]).readBackStatusIssued = False
                    retVal = (<PitChannel>self.channels[channelId]).readBackStatusValue
                elif ((<PitChannel>self.channels[channelId]).counterWriteMode == 1): # LSB
                    retVal = <uint8_t>temp
                elif ((<PitChannel>self.channels[channelId]).counterWriteMode == 2): # MSB
                    retVal = <uint8_t>(temp>>8)
                elif ((<PitChannel>self.channels[channelId]).counterWriteMode in (0, 3)): # LSB;MSB
                    if (not (<PitChannel>self.channels[channelId]).counterFlipFlop):
                        if ((<PitChannel>self.channels[channelId]).counterWriteMode == 0): # TODO?
                            retVal = <uint8_t>(<PitChannel>self.channels[channelId]).counterLatchValue
                        else:
                            retVal = <uint8_t>temp
                    else:
                        if ((<PitChannel>self.channels[channelId]).counterWriteMode == 0):
                            retVal = <uint8_t>((<PitChannel>self.channels[channelId]).counterLatchValue>>8)
                        else:
                            retVal = <uint8_t>(temp>>8)
                    (<PitChannel>self.channels[channelId]).counterFlipFlop = not (<PitChannel>self.channels[channelId]).counterFlipFlop
                else:
                    self.main.exitError("inPort: unknown counterWriteMode: %u.", (<PitChannel>self.channels[channelId]).counterWriteMode)
                IF COMP_DEBUG:
                #IF 1:
                    if (self.main.debugEnabled):
                        self.main.notice("PIT::inPort_2: port 0x%04x with dataSize %u and retVal 0x%02x.", ioPortAddr, dataSize, retVal)
                return retVal
            elif (ioPortAddr == 0x43):
                self.main.notice("inPort: read from PIT command port 0x43 is ignored.")
                return 0
            else:
                self.main.exitError("inPort: ioPortAddr 0x%02x not supported (dataSize == byte).", ioPortAddr)
        else:
            self.main.exitError("inPort: port 0x%02x with dataSize %u not supported.", ioPortAddr, dataSize)
        return 0
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil:
        cdef uint8_t channelId, bcd, modeNumber, counterWriteMode, i
        IF COMP_DEBUG:
        #IF 1:
            if (self.main.debugEnabled):
                self.main.notice("PIT::outPort: port 0x%04x with data 0x%04x and dataSize %u.", ioPortAddr, data, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channelId = ioPortAddr&3
                if ((<PitChannel>self.channels[channelId]).counterWriteMode in (0, 3)): # LSB;MSB
                    if (not (<PitChannel>self.channels[channelId]).counterFlipFlop):
                        (<PitChannel>self.channels[channelId]).counterStartValue = <uint8_t>data
                    else:
                        (<PitChannel>self.channels[channelId]).counterStartValue = (<PitChannel>self.channels[channelId]).counterStartValue|((<uint8_t>data)<<8)
                    (<PitChannel>self.channels[channelId]).counterFlipFlop = not (<PitChannel>self.channels[channelId]).counterFlipFlop
                elif ((<PitChannel>self.channels[channelId]).counterWriteMode in (1, 2)): # 1==LSB/2==MSB
                    (<PitChannel>self.channels[channelId]).counterStartValue = <uint8_t>data
                    if ((<PitChannel>self.channels[channelId]).counterWriteMode == 2): # MSB
                        (<PitChannel>self.channels[channelId]).counterStartValue = (<PitChannel>self.channels[channelId]).counterStartValue<<8
                    (<PitChannel>self.channels[channelId]).counterFlipFlop = False
                if (not (<PitChannel>self.channels[channelId]).counterFlipFlop and (<PitChannel>self.channels[channelId]).resetChannel):
                    with gil:
                        (<PitChannel>self.channels[channelId]).runTimer()
            elif (ioPortAddr == 0x43):
                bcd = data&1
                modeNumber = (data>>1)&7
                counterWriteMode = (data>>4)&3
                channelId = (data>>6)&3
                if (channelId == 3):
                    if (bcd): # not bcd, reserved!
                        self.main.exitError("outPort: reserved should be clear.")
                        return
                    if (not (data&READBACK_DONT_LATCH_STATUS)):
                        self.main.exitError("outPort: latch status isn't supported yet.")
                        return
                    if (modeNumber): # not modeNumber, channels!
                        for i in range(3):
                            if ((data & (2 << i)) != 0):
                                if (not (data&READBACK_DONT_LATCH_COUNT)):
                                    (<PitChannel>self.channels[i]).readBackCount()
                                if (not (data&READBACK_DONT_LATCH_STATUS)):
                                    (<PitChannel>self.channels[i]).readBackStatus()
                                    (<PitChannel>self.channels[i]).readBackStatusIssued = True
                    #self.main.exitError("outPort: read-back not supported.")
                    return
                if (bcd): # BCD
                    self.main.exitError("outPort: BCD not supported yet.")
                    return
                if (modeNumber in (6, 7)):
                    modeNumber -= 4
                (<PitChannel>self.channels[channelId]).bcdMode = bcd
                (<PitChannel>self.channels[channelId]).counterMode = modeNumber
                (<PitChannel>self.channels[channelId]).counterWriteMode = counterWriteMode
                (<PitChannel>self.channels[channelId]).counterFlipFlop = False
                if (not (<PitChannel>self.channels[channelId]).counterWriteMode):
                    (<PitChannel>self.channels[channelId]).counterLatchValue = (<PitChannel>self.channels[channelId]).counterValue
                if (counterWriteMode and channelId != 3):
                    (<PitChannel>self.channels[channelId]).resetChannel = True
            else:
                self.main.exitError("outPort: ioPortAddr 0x%02x not supported (dataSize == byte).", ioPortAddr)
        else:
            self.main.exitError("outPort: port 0x%02x with dataSize %u not supported. (data: 0x%04x)", ioPortAddr, dataSize, data)
    cdef void run(self):
        pass


