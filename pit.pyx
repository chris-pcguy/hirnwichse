
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

include "globals.pxi"


DEF READBACK_DONT_LATCH_COUNT  = 0x20
DEF READBACK_DONT_LATCH_STATUS = 0x10

cdef class PitChannel:
    def __init__(self, Pit pit, unsigned char channelId):
        self.pit = pit
        self.channelId = channelId
        self.bcdMode = 0 # 0 == binary; 1 == BCD
        self.counterMode = 0 # 0-5 valid, 6,7 not
        self.counterWriteMode = 0 # 1 == LSB ; 2 == MSB ; 0/3 == LSB;MSB
        self.readBackStatusValue = 0
        self.counterValue = self.counterStartValue = self.counterLatchValue = self.tempTimerValue = 0
        self.counterFlipFlop = self.timerEnabled = self.readBackStatusIssued = self.resetChannel = False
        self.threadObject = None
    cdef void readBackCount(self):
        self.counterLatchValue = self.counterValue
    cdef void readBackStatus(self):
        self.readBackStatusValue = self.bcdMode
        self.readBackStatusValue |= self.counterMode<<1
        self.readBackStatusValue |= self.counterWriteMode<<4
    cdef void mode0Func(self):
        if (self.channelId == 0): # just raise IRQ on channel0
            (<Pic>self.pit.main.platform.pic).lowerIrq(0)
        elif (self.channelId == 2 and (<PS2>self.pit.main.platform.ps2).ppcbT2Gate):
            (<PS2>self.pit.main.platform.ps2).ppcbT2Out = False
        with nogil:
            usleep(self.tempTimerValue)
        self.counterValue = 0
        if (self.channelId == 0): # just raise IRQ on channel0
            (<Pic>self.pit.main.platform.pic).raiseIrq(0)
        elif (self.channelId == 2 and (<PS2>self.pit.main.platform.ps2).ppcbT2Gate):
            (<PS2>self.pit.main.platform.ps2).ppcbT2Out = True
        #else:
        self.pit.main.notice("PitChannel::mode0Func: counterMode {0:d} used channelId {1:d}.", self.counterMode, self.channelId)
        self.timerEnabled = False
    cdef void mode2Func(self): # TODO
        cdef unsigned char clear
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
            if (self.channelId != 3):
                #self.pit.main.notice("PitChannel::mode2Func: before while")
                self.counterValue = self.counterStartValue
                self.pit.main.notice("PitChannel::mode2Func({0:d}): counterValue=={1:d}", self.channelId, self.counterValue)
                with nogil:
                    #usleep(self.tempTimerValue)
                    usleep(1)
                    #usleep(100)
                while ((self.counterValue >= 2 and self.counterValue <= (BITMASK_WORD+1)) and self.timerEnabled and (not self.pit.main.quitEmu)):
                    if (self.counterMode == 3 and self.counterValue >= 3):
                        self.counterValue -= 2 # HACK
                    else:
                        self.counterValue -= 1 # HACK
                    #self.pit.main.notice("PitChannel::mode2Func: in while")
                    #if (not (self.counterValue&0xff)):
                    if (not (self.counterValue&0x7f)):
                    #if (not (self.counterValue&0x3f)):
                        with nogil:
                            #usleep(self.tempTimerValue)
                            usleep(1)
                            #usleep(100)
                self.counterValue = 1 # to be sure
                self.pit.main.notice("PitChannel::mode2Func({0:d}): after while", self.channelId)
            with nogil:
                usleep(self.tempTimerValue)
            if (self.channelId == 0): # just raise IRQ on channel0
                #clear = (<Pic>self.pit.main.platform.pic).isClear(0)
                #self.pit.main.notice("PitChannel::mode2Func: raiseIrq(0)")
                if (clear):
                #if (clear and self.pit.main.cpu.savedCs != 0x0028):
                    self.pit.main.notice("PitChannel::mode2Func: raiseIrq(0): clear")
                    (<Pic>self.pit.main.platform.pic).raiseIrq(0)
            elif (self.channelId == 2 and (<PS2>self.pit.main.platform.ps2).ppcbT2Gate):
                (<PS2>self.pit.main.platform.ps2).ppcbT2Out = True
            elif (self.channelId == 3):
                if (clear):
                    self.pit.main.notice("PitChannel::mode2Func: raiseIrq(CMOS_RTC_IRQ): clear")
                    (<Cmos>self.pit.main.platform.cmos).periodicFunc()
            else:
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
            self.counterStartValue -= 1
            if (self.bcdMode):
                self.pit.main.notice("PitChannel::runTimer: WARNING: TODO: bcdMode may not work!")
                self.counterStartValue = self.pit.main.misc.bcdToDec(self.counterStartValue)
            if (self.counterMode == 3):
                #self.counterStartValue &= 0xffffe
                self.counterStartValue &= 0xfffe
                if (self.counterStartValue == 0):
                    self.pit.main.exitError("runTimer: counterValue is 0")
                    return
            self.counterValue = self.counterStartValue
            self.tempTimerValue = round(1.0e6/(1193182.0/self.counterValue))
            if (self.counterMode == 0):
                self.tempTimerValue <<= 4 # TODO: HACK!
                #self.tempTimerValue <<= 6 # TODO: HACK!
            if (self.counterMode == 3):
                self.tempTimerValue >>= 1
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
        self.main = main
        self.channels = (PitChannel(self, 0), PitChannel(self, 1),\
                         PitChannel(self, 2)) # channel 0-2
        (<Cmos>self.main.platform.cmos).rtcChannel = PitChannel(self, 3)
    cpdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef PitChannel channel
        cdef unsigned char channelId, retVal
        self.main.notice("PIT::inPort_1: port {0:#06x} with dataSize {1:d}.", ioPortAddr, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channelId = ioPortAddr&3
                channel = self.channels[channelId]
                if (channel.readBackStatusIssued):
                    channel.readBackStatusIssued = False
                    retVal = channel.readBackStatusValue
                elif (channel.counterWriteMode == 1): # LSB
                    retVal = <unsigned char>channel.counterValue
                elif (channel.counterWriteMode == 2): # MSB
                    retVal = <unsigned char>(channel.counterValue>>8)
                elif (channel.counterWriteMode in (0, 3)): # LSB;MSB
                    if (not channel.counterFlipFlop):
                        if (channel.counterWriteMode == 0): # TODO?
                            retVal = <unsigned char>channel.counterLatchValue
                        else:
                            retVal = <unsigned char>channel.counterValue
                    else:
                        if (channel.counterWriteMode == 0):
                            retVal = <unsigned char>(channel.counterLatchValue>>8)
                        else:
                            retVal = <unsigned char>(channel.counterValue>>8)
                    channel.counterFlipFlop = not channel.counterFlipFlop
                else:
                    self.main.exitError("inPort: unknown counterWriteMode: {0:d}.", channel.counterWriteMode)
                self.main.notice("PIT::inPort_2: port {0:#06x} with dataSize {1:d} and retVal {2:#04x}.", ioPortAddr, dataSize, retVal)
                return retVal
            elif (ioPortAddr == 0x43):
                self.main.notice("inPort: read from PIT command port 0x43 is ignored.")
                return 0
            else:
                self.main.exitError("inPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
        else:
            self.main.exitError("inPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        return 0
    cpdef outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        cdef PitChannel channel
        cdef unsigned char channelId, bcd, modeNumber, counterWriteMode, i
        self.main.notice("PIT::outPort: port {0:#06x} with data {1:#06x} and dataSize {2:d}.", ioPortAddr, data, dataSize)
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in (0x40, 0x41, 0x42)):
                channelId = ioPortAddr&3
                channel = self.channels[channelId]
                if (channel.counterWriteMode in (0, 3)): # LSB;MSB
                    if (not channel.counterFlipFlop):
                        channel.counterStartValue = <unsigned char>data
                    else:
                        channel.counterStartValue |= (<unsigned char>data)<<8
                    channel.counterFlipFlop = not channel.counterFlipFlop
                elif (channel.counterWriteMode in (1, 2)): # 1==LSB/2==MSB
                    channel.counterStartValue = <unsigned char>data
                    if (channel.counterWriteMode == 2): # MSB
                        channel.counterStartValue <<= 8
                    channel.counterFlipFlop = False
                if (not channel.counterFlipFlop and channel.resetChannel):
                    channel.runTimer()
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
                                channel = self.channels[i]
                                if (not (data&READBACK_DONT_LATCH_COUNT)):
                                    channel.readBackCount()
                                if (not (data&READBACK_DONT_LATCH_STATUS)):
                                    channel.readBackStatus()
                                    channel.readBackStatusIssued = True
                    #self.main.exitError("outPort: read-back not supported.")
                    return
                if (bcd): # BCD
                    self.main.exitError("outPort: BCD not supported yet.")
                    return
                if (modeNumber in (6, 7)):
                    modeNumber -= 4
                channel = self.channels[channelId]
                channel.bcdMode = bcd
                channel.counterMode = modeNumber
                channel.counterWriteMode = counterWriteMode
                channel.counterFlipFlop = False
                if (not channel.counterWriteMode):
                    channel.counterLatchValue = channel.counterValue
                if (counterWriteMode and channelId != 3):
                    channel.resetChannel = True
            else:
                self.main.exitError("outPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
        else:
            self.main.exitError("outPort: port {0:#04x} with dataSize {1:d} not supported. (data: {2:#06x})", ioPortAddr, dataSize, data)
    cdef void run(self):
        pass
        #self.main.platform.addHandlers((0x40, 0x41, 0x42, 0x43), self)


