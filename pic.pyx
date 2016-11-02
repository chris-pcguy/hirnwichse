
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"


DEF PIC_PIC1_COMMAND = 0x20
DEF PIC_PIC1_DATA = PIC_PIC1_COMMAND+1
DEF PIC_PIC2_COMMAND = 0xA0
DEF PIC_PIC2_DATA = PIC_PIC2_COMMAND+1
DEF PIC_PIC1_PORTS = (PIC_PIC1_COMMAND, PIC_PIC1_DATA)
DEF PIC_PIC2_PORTS = (PIC_PIC2_COMMAND, PIC_PIC2_DATA)

DEF PIC_MASTER = 0
DEF PIC_SLAVE  = 1
DEF PIC_GET_ICW4 = 0x01
DEF PIC_SINGLE_MODE_NO_ICW3 = 0x02
DEF PIC_CMD_INITIALIZE = 0x10
DEF PIC_EOI = 0x20
DEF PIC_DATA_STEP_ICW1 = 1
DEF PIC_DATA_STEP_ICW2 = 2
DEF PIC_DATA_STEP_ICW3 = 3
DEF PIC_DATA_STEP_ICW4 = 4
DEF PIC_FLAG_80x86 = 0x1
DEF PIC_FLAG_AUTO_EOI = 0x2
DEF PIC_NEED_IRR = 1
DEF PIC_NEED_ISR = 2



cdef class PicChannel:
    def __init__(self, Pic pic, uint8_t master):
        self.pic    = pic
        self.master = master
    cdef void reset(self) nogil:
        self.inInit = False
        self.step = PIC_DATA_STEP_ICW1
        self.cmdByte = 0
        self.irqBasePort = 0x8
        self.autoEOI = False
        self.rotateOnAutoEOI = False
        self.polled = False
        self.specialMask = False
        self.lowestPriority = 7
        self.irq = 0
        self.imr = 0xff
        self.isr = 0
        self.irr = 0
        self.intr = False
        self.IRQ_in = 0
        self.edgeLevel = 0
        self.needRegister = PIC_NEED_IRR
        if (not self.master):
            self.irqBasePort = 0x70
        self.mappedSlavesOnMasterMask = 0x4 # master
        self.slaveOnThisMasterIrq = 2 # slave
    cdef void clearHighestInterrupt(self) nogil:
        cdef uint8_t irq, lowestPriority, highestPriority
        lowestPriority = self.lowestPriority
        highestPriority = lowestPriority+1
        if (highestPriority > 7):
            highestPriority = 0
        irq = highestPriority
        while (not self.pic.main.quitEmu):
            if (self.isr & (1<<irq)):
                self.isr &= ~(1<<irq)
                break
            irq += 1
            if (irq > 7):
                irq = 0
            if (irq == highestPriority):
                break
    cdef void servicePicChannel(self) nogil:
        cdef uint8_t highestPriority, irq, maxIrq, unmaskedRequests
        if (self.intr):
            return
        highestPriority = self.lowestPriority+1
        if (highestPriority > 7):
            highestPriority = 0
        maxIrq = highestPriority
        if (not self.specialMask and self.isr):
            while (not (self.isr & (1 << maxIrq)) and not self.pic.main.quitEmu):
                maxIrq += 1
                if (maxIrq > 7):
                    maxIrq = 0
            if (maxIrq == highestPriority):
                return
            if (maxIrq > 7):
                with gil:
                    self.pic.main.exitError("PicChannel::servicePicChannel: maxIrq > 7")
        unmaskedRequests = self.irr & (~self.imr)
        if (unmaskedRequests):
            irq = highestPriority
            while (not self.pic.main.quitEmu):
                if (not (self.specialMask and (self.isr & (1 << irq)))):
                    if (unmaskedRequests & (1 << irq)):
                        self.intr = True
                        self.irq = irq
                        if (self.master):
                            self.pic.main.cpu.setINTR(True)
                        else:
                            self.pic.raiseIrq(2)
                        return
                irq += 1
                if (irq > 7):
                    irq = 0
                if (irq == maxIrq):
                    break
    cdef void raiseIrq(self, uint8_t irq) nogil:
        cdef uint8_t mask
        mask = (1 << (irq&7))
        if (not (self.IRQ_in & mask)):
            #self.pic.main.notice("PicChannel::raiseIrq({0:d}): irq=={1:d}", (not self.master, irq))
            self.IRQ_in |= mask
            self.irr |= mask
            self.servicePicChannel()
    cdef void lowerIrq(self, uint8_t irq) nogil:
        cdef uint8_t mask
        mask = (1 << (irq&7))
        if (self.IRQ_in & mask):
            self.IRQ_in &= (~mask)
            self.irr &= (~mask)
    cdef uint8_t getCmdByte(self) nogil:
        return self.cmdByte
    cdef void setCmdByte(self, uint8_t cmdByte) nogil:
        self.cmdByte = cmdByte
    cdef uint8_t getIrqBasePort(self) nogil:
        return self.irqBasePort
    cdef void setIrqBasePort(self, uint8_t irqBasePort) nogil:
        self.irqBasePort = irqBasePort
        if (self.irqBasePort & 7):
            with gil:
                self.pic.main.exitError("setIrqBasePort: (self.irqBasePort {0:#04x} MODULO 8) != 0. (channel{1:d})", (irqBasePort, not self.master))
    cdef void setMasterSlaveMap(self, uint8_t value) nogil:
        if (self.master):
            self.mappedSlavesOnMasterMask = value
        else:
            self.slaveOnThisMasterIrq = value
    cdef void setFlags(self, uint8_t flags) nogil:
        self.autoEOI = (flags&2)!=0
        if (not (flags & PIC_FLAG_80x86)):
            with gil:
                self.pic.main.exitError("setFlags: flags {0:#04x}, PIC_FLAG_80x86 not set! (channel{1:d})", (flags, self.master==False))
    cdef void setNeededRegister(self, uint8_t needRegister) nogil:
        self.needRegister = needRegister
    cdef uint8_t getNeededRegister(self) nogil:
        if (self.needRegister == PIC_NEED_IRR):
            return self.irr
        elif (self.needRegister == PIC_NEED_ISR):
            return self.isr
        else:
            with gil:
                self.pic.main.exitError("PicChannel::getNeededRegister: self.needRegister not in (PIC_NEED_IRR, PIC_NEED_ISR).")
            return 0
    cdef void run(self) nogil:
        self.reset()

cdef class Pic:
    def __init__(self, Hirnwichse main):
        cdef PicChannel master, slave
        self.main = main
        master = PicChannel(self, True)
        self.channels[0] = <PyObject*>master
        slave = PicChannel(self, False)
        self.channels[1] = <PyObject*>slave
        Py_INCREF(master)
        Py_INCREF(slave)
    cdef void setMode(self, uint8_t channel, uint8_t edgeLevel) nogil:
        (<PicChannel>self.channels[channel]).edgeLevel = edgeLevel
    cdef void raiseIrq(self, uint8_t irq) nogil:
        cdef uint8_t ma_sl = False
        #self.main.notice("Pic::raiseIrq: irq=={0:d}", (irq,))
        if (irq > 15):
            with gil:
                self.main.exitError("raiseIrq: invalid irq! (irq: {0:d})", (irq,))
            return
        elif (irq >= 8):
            ma_sl = True
            irq -= 8
        (<PicChannel>self.channels[ma_sl]).raiseIrq(irq)
    cdef void lowerIrq(self, uint8_t irq) nogil:
        cdef uint8_t ma_sl = False
        #with gil:
        #    self.main.notice("Pic::lowerIrq: irq=={0:d}", (irq,))
        if (irq > 15):
            with gil:
                self.main.exitError("lowerIrq: invalid irq! (irq: {0:d})", (irq,))
            return
        elif (irq >= 8):
            ma_sl = True
            irq -= 8
        (<PicChannel>self.channels[ma_sl]).lowerIrq(irq)
    cdef uint8_t isClear(self, uint8_t irq) nogil:
        cdef uint8_t temp1, temp2, temp3, ma_sl = False
        if (irq > 15):
            IF COMP_DEBUG:
                with gil:
                    self.main.exitError("isClear: invalid irq! (irq: {0:d})", (irq,))
            return 0
        if (irq >= 8):
            ma_sl = True
            irq = 8
        temp1 = (<PicChannel>self.channels[ma_sl]).isr & (1<<irq) # partly commented out because the
        temp2 = (<PicChannel>self.channels[ma_sl]).irr & (1<<irq) # PS/2 keyboard has a lower priority.
        temp3 = (<PicChannel>self.channels[ma_sl]).imr & (1<<irq)
        #self.main.notice("Pic::isClear({0:d},{1:d}): temp1=={2:d}; temp2=={3:d}; temp3=={4:d}; (<PicChannel>self.channels[ma_sl]).intr=={5:d}", (irq, ma_sl, temp1, temp2, temp3, (<PicChannel>self.channels[ma_sl]).intr))
        if (not temp1 and temp2 and (<PicChannel>self.channels[ma_sl]).intr):
            self.main.cpu.registers.ssInhibit = True
            self.main.cpu.asyncEvent = True
        return not (temp1 or temp2 or temp3 or (<PicChannel>self.channels[ma_sl]).intr)
        #return not (temp1 or temp2 or temp3)
        #return not (temp2 or temp3 or (<PicChannel>self.channels[ma_sl]).intr)
        #return not (temp1 or temp3 or (<PicChannel>self.channels[ma_sl]).intr)
        #return not (temp1 or temp2 or (<PicChannel>self.channels[ma_sl]).intr)
        #return not (temp1 or (<PicChannel>self.channels[ma_sl]).intr)
        #return not (temp1)
        #return not (temp1 or temp3)
    cdef uint8_t IAC(self):
        cdef PicChannel master, slave
        cdef uint8_t vector
        master = <PicChannel>self.channels[0]
        slave = <PicChannel>self.channels[1]
        self.main.cpu.setINTR(False)
        master.intr = False
        if (not master.irr):
            self.main.notice("Pic::IAC: spurious master irq=={0:d}", (master.irq,))
            return master.getIrqBasePort()+7
        if (not (master.edgeLevel & (1 << master.irq))):
            master.irr &= ~(1 << master.irq)
        if (not master.autoEOI):
            master.isr |= (1 << master.irq)
        elif (master.rotateOnAutoEOI):
            master.lowestPriority = master.irq
        if (master.irq != 2):
            vector = master.getIrqBasePort() + master.irq
        else:
            slave.intr = False
            master.IRQ_in &= 0xfb
            if (not slave.irr):
                self.main.notice("Pic::IAC: spurious slave irq=={0:d}", (slave.irq,))
                return slave.getIrqBasePort()+7
            vector = slave.getIrqBasePort() + slave.irq
            if (not (slave.edgeLevel & (1 << slave.irq))):
                slave.irr &= ~(1 << slave.irq)
            if (not slave.autoEOI):
                slave.isr |= (1 << slave.irq)
            elif (slave.rotateOnAutoEOI):
                slave.lowestPriority = slave.irq
            slave.servicePicChannel()
        master.servicePicChannel()
        return vector
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil:
        cdef uint8_t channel
        if (self.main.debugEnabled):
            with gil:
                self.main.debug("Pic::inPort: ioPortAddr=={0:#06x}; dataSize=={1:d}", (ioPortAddr, dataSize))
        if (ioPortAddr in PIC_PIC1_PORTS):
            channel = 0
        elif (ioPortAddr in PIC_PIC2_PORTS):
            channel = 1
        if (dataSize == OP_SIZE_BYTE):
            if ((<PicChannel>self.channels[channel]).polled):
                (<PicChannel>self.channels[channel]).clearHighestInterrupt()
                (<PicChannel>self.channels[channel]).polled = False
                (<PicChannel>self.channels[channel]).servicePicChannel()
                return (<PicChannel>self.channels[channel]).irq
            elif (ioPortAddr in (PIC_PIC1_COMMAND, PIC_PIC2_COMMAND)):
                return (<PicChannel>self.channels[channel]).getNeededRegister()
            elif (ioPortAddr in (PIC_PIC1_DATA, PIC_PIC2_DATA)):
                return (<PicChannel>self.channels[channel]).imr
            else:
                with gil:
                    self.main.exitError("inPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", (ioPortAddr,))
        else:
                with gil:
                    self.main.exitError("inPort: port {0:#04x} with dataSize {1:d} not supported.", (ioPortAddr, dataSize))
        return 0
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil:
        cdef uint8_t channel, oldStep, cmdByte, specialMask, poll, readOp
        if (self.main.debugEnabled):
            with gil:
                self.main.debug("Pic::outPort: ioPortAddr=={0:#06x}; data=={1:#04x}; dataSize=={2:d}", (ioPortAddr, data, dataSize))
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in PIC_PIC1_PORTS):
                channel = 0
            elif (ioPortAddr in PIC_PIC2_PORTS):
                channel = 1
            else: # wrong ioPortAddr
                with gil:
                    self.main.exitError("outPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", (ioPortAddr,))
                return
            oldStep = (<PicChannel>self.channels[channel]).step
            if (ioPortAddr in (PIC_PIC1_COMMAND, PIC_PIC2_COMMAND)):
                if (data & PIC_CMD_INITIALIZE):
                    (<PicChannel>self.channels[channel]).inInit = True
                    (<PicChannel>self.channels[channel]).imr = 0
                    (<PicChannel>self.channels[channel]).isr = 0
                    (<PicChannel>self.channels[channel]).irr = 0
                    (<PicChannel>self.channels[channel]).intr = False
                    (<PicChannel>self.channels[channel]).autoEOI = False
                    (<PicChannel>self.channels[channel]).rotateOnAutoEOI = False
                    (<PicChannel>self.channels[channel]).lowestPriority = 7
                    (<PicChannel>self.channels[channel]).setCmdByte(data)
                    (<PicChannel>self.channels[channel]).step = PIC_DATA_STEP_ICW2
                    if (channel):
                        (<PicChannel>self.channels[0]).IRQ_in = (<PicChannel>self.channels[0]).IRQ_in&0xfb
                    else:
                        self.main.cpu.setINTR(False)
                    if (data & 0x02 or data & 0x08):
                        with gil:
                            self.main.exitError("outPort: setCmd: cmdByte {0:#04x} not supported (ioPortAddr == {1:#04x}, dataSize == byte).", (data, ioPortAddr))
                    return
                elif ((data & 0x18) == 0x08):
                    specialMask = (data & 0x60) >> 5
                    poll = (data & 0x04) >> 2
                    readOp = data & 0x03
                    if (poll):
                        (<PicChannel>self.channels[channel]).polled = True
                        return
                    if (readOp == 0x02): # IRR is needed
                        (<PicChannel>self.channels[channel]).setNeededRegister(PIC_NEED_IRR)
                    elif (readOp == 0x03): # ISR is needed
                        (<PicChannel>self.channels[channel]).setNeededRegister(PIC_NEED_ISR)
                    if (specialMask == 0x02):
                        (<PicChannel>self.channels[channel]).specialMask = False
                    elif (specialMask == 0x03):
                        (<PicChannel>self.channels[channel]).specialMask = True
                        (<PicChannel>self.channels[channel]).servicePicChannel()
                    return
                elif (data in (0x00, 0x80)):
                    (<PicChannel>self.channels[channel]).rotateOnAutoEOI = (data != 0)
                elif (data in (0x20, 0xa0)):
                    (<PicChannel>self.channels[channel]).clearHighestInterrupt()
                    if (data == 0xa0):
                        (<PicChannel>self.channels[channel]).lowestPriority = (<PicChannel>self.channels[channel]).lowestPriority+1
                        if ((<PicChannel>self.channels[channel]).lowestPriority > 7):
                            (<PicChannel>self.channels[channel]).lowestPriority = 0
                    (<PicChannel>self.channels[channel]).servicePicChannel()
                elif (data >= 0x60 and data <= 0x67):
                    (<PicChannel>self.channels[channel]).isr = (<PicChannel>self.channels[channel]).isr&(~(1 << (data&0x07)))
                    (<PicChannel>self.channels[channel]).servicePicChannel()
                elif (data >= 0xc0 and data <= 0xc7):
                    (<PicChannel>self.channels[channel]).lowestPriority = (data&0x07)
                elif (data >= 0xe0 and data <= 0xe7):
                    (<PicChannel>self.channels[channel]).isr = (<PicChannel>self.channels[channel]).isr&(~(1 << (data&0x07)))
                    (<PicChannel>self.channels[channel]).lowestPriority = (data&0x07)
                    (<PicChannel>self.channels[channel]).servicePicChannel()
                elif (data in (0x02, 0x40)):
                    pass
                else:
                    with gil:
                        self.main.exitError("outPort: setCmd: cmdByte {0:#04x} not supported (ioPortAddr == {1:#04x}, oldStep == {2:d}, dataSize == byte).", (data, ioPortAddr, oldStep))
            elif (ioPortAddr in (PIC_PIC1_DATA, PIC_PIC2_DATA)):
                cmdByte = (<PicChannel>self.channels[channel]).getCmdByte()
                if (not (<PicChannel>self.channels[channel]).inInit): # set mask if (<PicChannel>self.channels[channel]).inInit is False
                    (<PicChannel>self.channels[channel]).imr = data
                    (<PicChannel>self.channels[channel]).servicePicChannel()
                elif (oldStep == PIC_DATA_STEP_ICW2):
                    (<PicChannel>self.channels[channel]).setIrqBasePort(data)
                    if (cmdByte & PIC_SINGLE_MODE_NO_ICW3):
                        if (cmdByte & PIC_GET_ICW4):
                            (<PicChannel>self.channels[channel]).step = PIC_DATA_STEP_ICW4
                        else:
                            (<PicChannel>self.channels[channel]).inInit = False
                    else:
                        (<PicChannel>self.channels[channel]).step = PIC_DATA_STEP_ICW3
                elif (oldStep == PIC_DATA_STEP_ICW3):
                    (<PicChannel>self.channels[channel]).setMasterSlaveMap(data)
                    if (cmdByte & PIC_GET_ICW4):
                        (<PicChannel>self.channels[channel]).step = PIC_DATA_STEP_ICW4
                    else:
                        (<PicChannel>self.channels[channel]).inInit = False
                elif (oldStep == PIC_DATA_STEP_ICW4):
                    (<PicChannel>self.channels[channel]).setFlags(data)
                    (<PicChannel>self.channels[channel]).inInit = False
                else: # wrong step
                    with gil:
                        self.main.exitError("outPort: oldStep {0:d} not supported (ioPortAddr == {1:#04x}, dataSize == byte).", (oldStep, ioPortAddr))
            else: # wrong ioPortAddr
                with gil:
                    self.main.exitError("outPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", (ioPortAddr,))
        else:
            with gil:
                self.main.exitError("outPort: dataSize {0:d} not supported.", (dataSize,))
        return
    cdef void run(self) nogil:
        (<PicChannel>self.channels[0]).run()
        (<PicChannel>self.channels[1]).run()
        #self.main.platform.addHandlers((0x20, 0x21, 0xa0, 0xa1), self)


