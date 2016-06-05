
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"


DEF READBACK_DONT_LATCH_COUNT  = 0x20
DEF READBACK_DONT_LATCH_STATUS = 0x10


cdef class PitChannel:
    def __init__(self, Pit pit, uint8_t channelId):
        self.pit = pit
        self.channelId = channelId
        self.bcdMode = 0 # 0 == binary; 1 == BCD
        self.counterMode = 0 # 0-5 valid, 6,7 not
        self.counterWriteMode = 0 # 1 == LSB ; 2 == MSB ; 0/3 == LSB;MSB
        self.readBackStatusValue = 0
        self.counterValue = self.counterStartValue = self.counterLatchValue = self.tempTimerValue = 0
        self.counterFlipFlop = self.timerEnabled = self.readBackStatusIssued = self.resetChannel = False
        self.threadObject = None
    cdef void readBackCount(self) nogil:
        self.counterLatchValue = self.counterValue
    cdef void readBackStatus(self) nogil:
        self.readBackStatusValue = self.bcdMode
        self.readBackStatusValue |= self.counterMode<<1
        self.readBackStatusValue |= self.counterWriteMode<<4
    cdef void mode0Func(self) nogil:
        if (self.channelId == 0): # just raise IRQ on channel0
            (<Pic>self.pit.main.platform.pic).lowerIrq(0)
        elif (self.channelId == 2 and (<PS2>self.pit.main.platform.ps2).ppcbT2Gate):
            (<PS2>self.pit.main.platform.ps2).ppcbT2Out = False
        #with nogil:
        usleep(self.tempTimerValue)
        self.counterValue = 0
        if (self.channelId == 0): # just raise IRQ on channel0
            (<Pic>self.pit.main.platform.pic).raiseIrq(0)
        elif (self.channelId == 2 and (<PS2>self.pit.main.platform.ps2).ppcbT2Gate):
            (<PS2>self.pit.main.platform.ps2).ppcbT2Out = True
        #else:
        #self.pit.main.notice("PitChannel::mode0Func: counterMode {0:d} used channelId {1:d}.", self.counterMode, self.channelId)
        self.timerEnabled = False
    cdef void mode2Func(self) nogil: # TODO
        cdef uint8_t clear
        cdef uint64_t i
        while (self.timerEnabled and (not self.pit.main.quitEmu)):
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
            with nogil:
            #IF 1:
                if (self.channelId != 3):
                    #self.pit.main.notice("PitChannel::mode2Func: before while")
                    #self.pit.main.notice("PitChannel::mode2Func({0:d}): counterValue=={1:d}", self.channelId, self.counterStartValue)
                    self.counterValue = self.counterStartValue
                    #with nogil:
                    #    #usleep(self.tempTimerValue)
                    #    usleep(0)
                    #    #usleep(1)
                    #    #usleep(100)
                    #    #usleep(3000)
                    #if (self.counterMode == 3 and self.counterValue&0x1):
                    #    self.counterValue -= 1
                    while ((((self.counterMode == 3 and self.counterValue >= 3) or (self.counterMode != 3 and self.counterValue >= 2)) and self.counterValue <= (BITMASK_WORD+1)) and self.timerEnabled and (not self.pit.main.quitEmu)):
                    #while ((self.counterValue >= 4 and self.counterValue <= (BITMASK_WORD+1)) and self.timerEnabled and (not self.pit.main.quitEmu)):
                        #for i in range(60):
                        #    pass
                        if (self.counterMode == 3):
                            self.counterValue -= 2
                        else:
                            self.counterValue -= 1
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
                            #usleep(self.tempTimerValue)
                            #with nogil:
                            usleep(0)
                            #usleep(1)
                            #usleep(5)
                            #usleep(10)
                            #usleep(25)
                            #usleep(50)
                            #usleep(100)
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
                    #self.counterValue = 1 # to be sure
                    #self.pit.main.notice("PitChannel::mode2Func({0:d}): after while", self.channelId)
                else:
                    #usleep(self.tempTimerValue)
                    usleep(0)
                    #usleep(1)
                    #usleep(100)
                    #usleep(3000)
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
                    (<Cmos>self.pit.main.platform.cmos).periodicFunc()
            else:
                IF COMP_DEBUG:
                    with gil:
                        self.pit.main.notice("PitChannel::mode2Func: counterMode {0:d} used channelId {1:d}.", self.counterMode, self.channelId)
    cpdef timerFunc(self): # TODO
        if (self.timerEnabled):
            if (self.counterMode == 0):
                self.mode0Func()
            elif (self.counterMode in (2, 3)):
                self.mode2Func()
            else:
                self.pit.main.exitError("timerFunc: counterMode {0:d} is unknown.", self.counterMode)
                return
    cpdef runTimer(self):
        self.resetChannel = False
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
                self.counterStartValue = self.pit.main.misc.bcdToDec(self.counterStartValue)
            if (self.counterMode == 3):
                #self.counterStartValue &= 0xffffe
                #self.counterStartValue &= 0xfffe
                #self.counterStartValue &= 0xfffffffe
                if (self.counterStartValue == 0):
                    self.pit.main.exitError("runTimer: counterValue is 0")
                    return
            self.counterValue = self.counterStartValue
            self.tempTimerValue = round(1.0e6/(1193182.0/self.counterValue))
            #if (self.counterMode == 0):
            #    self.tempTimerValue <<= 4 # TODO: HACK!
            #    #self.tempTimerValue <<= 6 # TODO: HACK!
            #if (self.counterMode == 3):
            #    self.tempTimerValue >>= 1
            if (self.counterMode not in (0, 2, 3)):
                self.pit.main.exitError("runTimer: counterMode {0:d} not supported yet. (channelId: {1:d})", self.counterMode, self.channelId)
                return
            elif (self.counterMode == 2 and self.channelId == 2):
                self.pit.main.exitError("runTimer: is it ok to use mode-{0:d} with channelId-{1:d} and cpu clock measures?", \
                self.counterMode, self.channelId)
                return
            elif (self.channelId == 2 and (<PS2>self.pit.main.platform.ps2).ppcbT2Gate):
                (<PS2>self.pit.main.platform.ps2).ppcbT2Out = False
        self.timerEnabled = False
        if (self.threadObject):
            self.threadObject.join()
            self.threadObject = None
        self.timerEnabled = True
        if (not self.pit.main.quitEmu):
            self.threadObject = self.pit.main.misc.createThread(self.timerFunc, True)

cdef class Pit:
    def __init__(self, Hirnwichse main):
        cdef PitChannel channel0, channel1, channel2
        self.main = main
        channel0 = PitChannel(self, 0)
        channel1 = PitChannel(self, 1)
        channel2 = PitChannel(self, 2)
        self.channels[0] = <PyObject*>channel0
        self.channels[1] = <PyObject*>channel1
        self.channels[2] = <PyObject*>channel2
        (<Cmos>self.main.platform.cmos).rtcChannel = PitChannel(self, 3)
        Py_INCREF(channel0)
        Py_INCREF(channel1)
        Py_INCREF(channel2)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil:
        cdef uint8_t channelId, retVal
        cdef uint32_t temp
        IF COMP_DEBUG:
        #IF 1:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("PIT::inPort_1: port {0:#06x} with dataSize {1:d}.", ioPortAddr, dataSize)
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
                    with gil:
                        self.main.exitError("inPort: unknown counterWriteMode: {0:d}.", (<PitChannel>self.channels[channelId]).counterWriteMode)
                IF COMP_DEBUG:
                #IF 1:
                    if (self.main.debugEnabled):
                        with gil:
                            self.main.notice("PIT::inPort_2: port {0:#06x} with dataSize {1:d} and retVal {2:#04x}.", ioPortAddr, dataSize, retVal)
                return retVal
            elif (ioPortAddr == 0x43):
                with gil:
                    self.main.notice("inPort: read from PIT command port 0x43 is ignored.")
                return 0
            else:
                with gil:
                    self.main.exitError("inPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
        else:
            with gil:
                self.main.exitError("inPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        return 0
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil:
        cdef uint8_t channelId, bcd, modeNumber, counterWriteMode, i
        IF COMP_DEBUG:
        #IF 1:
            if (self.main.debugEnabled):
                with gil:
                    self.main.notice("PIT::outPort: port {0:#06x} with data {1:#06x} and dataSize {2:d}.", ioPortAddr, data, dataSize)
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
                        with gil:
                            self.main.exitError("outPort: reserved should be clear.")
                        return
                    if (not (data&READBACK_DONT_LATCH_STATUS)):
                        with gil:
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
                    with gil:
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
                with gil:
                    self.main.exitError("outPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
        else:
            with gil:
                self.main.exitError("outPort: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", ioPortAddr, dataSize, data)
    cdef void run(self):
        pass
        #self.main.platform.addHandlers((0x40, 0x41, 0x42, 0x43), self)


