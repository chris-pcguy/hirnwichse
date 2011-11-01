
include "globals.pxi"


cdef class PicChannel:
    cpdef public object main, pic
    cdef unsigned char master, cmdByte, irqBasePort, mappedSlavesOnMasterMask, \
                        slaveOnThisMasterIrq, needRegister
    cdef public unsigned char step, inInit, irq, intr, imr, isr, irr, autoEOI, rotateOnAutoEOI, lowestPriority, polled, \
                                specialMask, IRQ_in, edgeLevel
    def __init__(self, object pic, object main, unsigned char master):
        self.pic    = pic
        self.main   = main
        self.master = master
    cpdef reset(self):
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
    cpdef clearHighestInterrupt(self):
        cdef unsigned char irq, lowestPrioriry, highestPriority
        lowestPriority = self.lowestPriority
        highestPriority = lowestPriority+1
        if (highestPriority > 7):
            highestPriority = 0
        irq = highestPriority
        while (True):
            if (self.isr & (1<<irq)):
                self.isr &= ~(1<<irq)
                break
            irq += 1
            if (irq > 7):
                irq = 0
            if (irq == highestPriority):
                break
    cpdef servicePicChannel(self):
        cdef unsigned char highestPriority, irq, maxIrq, unmaskedRequests
        highestPriority = self.lowestPriority+1
        if (highestPriority > 7):
            highestPriority = 0
        if (self.intr):
            return
        maxIrq = highestPriority
        if (not self.specialMask):
            if (self.isr):
                while (not (self.isr & (1 << maxIrq)) ):
                    maxIrq += 1
                    if (maxIrq > 7):
                        maxIrq = 0
                if (maxIrq == highestPriority):
                    return
                if (maxIrq > 7):
                    self.main.exitError("PicChannel::servicePicChannel: error: maxIrq > 7")
        unmaskedRequests = self.irr & (~self.imr)
        if (unmaskedRequests):
            irq = highestPriority
            while (True):
                if ( not (self.specialMask and ((self.isr >> irq) & 0x01)) ):
                    if (unmaskedRequests & (1 << irq)):
                        self.intr = True
                        self.irq = irq
                        if (self.master):
                            self.main.cpu.setIrq(True)
                        else:
                            self.pic.raiseIrq(2)
                        return
                irq += 1
                if (irq > 7):
                    irq = 0
                if (irq == maxIrq):
                    break
    cpdef raiseIrq(self, unsigned char irq):
        cdef unsigned char mask
        mask = 1 << (irq&7)
        if (not (self.IRQ_in & mask)):
            self.IRQ_in |= mask
            self.irr |= mask
            self.servicePicChannel()
    cpdef lowerIrq(self, unsigned char irq):
        cdef unsigned char mask
        mask = 1 << (irq&7)
        if (self.IRQ_in & mask):
            self.IRQ_in &= ~mask
            self.irr &= ~mask
    cpdef getCmdByte(self):
        return self.cmdByte
    cpdef setCmdByte(self, unsigned char cmdByte):
        self.cmdByte = cmdByte
    cpdef getIrqBasePort(self):
        return self.irqBasePort
    cpdef setIrqBasePort(self, unsigned char irqBasePort):
        self.irqBasePort = irqBasePort
        if (self.irqBasePort % 8):
            self.main.exitError("Notice: setIrqBasePort: (self.irqBasePort {0:#04x} MODULO 8) != 0. (channel{1:d})", irqBasePort, self.master==False)
    cpdef setMasterSlaveMap(self, unsigned char value):
        if (self.master):
            self.mappedSlavesOnMasterMask = value
        else:
            self.slaveOnThisMasterIrq = value
    cpdef setFlags(self, unsigned char flags):
        self.autoEOI = (flags&2)!=0
        if (not (flags & PIC_FLAG_80x86)):
            self.main.exitError("Warning: setFlags: flags {0:#04x}, PIC_FLAG_80x86 not set! (channel{1:d})", flags, self.master==False)
    cpdef setNeededRegister(self, unsigned char needRegister):
        self.needRegister = needRegister
    cpdef getNeededRegister(self):
        if (self.needRegister == PIC_NEED_IRR):
            return self.irr
        elif (self.needRegister == PIC_NEED_ISR):
            return self.isr
        else:
            self.main.exitError("PicChannel::getNeededRegister: self.needRegister not in (PIC_NEED_IRR, PIC_NEED_ISR).")
            return
    cpdef run(self):
        self.reset()

cdef class Pic:
    cpdef public object main
    cdef public tuple channels
    def __init__(self, object main):
        self.main = main
        self.channels = (PicChannel(self, self.main, True), PicChannel(self, self.main, False))
    cpdef raiseIrq(self, unsigned char irq):
        if (irq > 15):
            self.main.exitError("raiseIrq: invalid irq! (irq: {0:d})", irq)
        if (irq >= 8):
            return self.channels[1].raiseIrq(irq-8)
        return self.channels[0].raiseIrq(irq)
    cpdef lowerIrq(self, unsigned char irq):
        if (irq > 15):
            self.main.exitError("lowerIrq: invalid irq! (irq: {0:d})", irq)
        if (irq >= 8):
            return self.channels[1].lowerIrq(irq-8)
        return self.channels[0].lowerIrq(irq)
    cpdef IAC(self):
        cpdef object master, slave
        cdef unsigned char vector
        master, slave = self.channels
        self.main.cpu.setIrq(False)
        master.intr = False
        if (not master.irr):
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
            master.IRQ_in &= ~(1 << 2)
            if (not slave.irr):
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
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char channel, oldStep
        if (ioPortAddr in PIC_PIC1_PORTS):
            channel = 0
        elif (ioPortAddr in PIC_PIC2_PORTS):
            channel = 1
        if (dataSize == OP_SIZE_BYTE):
            if (self.channels[channel].polled):
                self.channels[channel].clearHighestInterrupt()
                self.channels[channel].polled = False
                self.channels[channel].servicePicChannel()
                return self.channels[channel].irq
            elif (ioPortAddr in (PIC_PIC1_COMMAND, PIC_PIC2_COMMAND)):
                return self.channels[channel].getNeededRegister()
            elif (ioPortAddr in (PIC_PIC1_DATA, PIC_PIC2_DATA)):
                return self.channels[channel].imr
            else:
                self.main.exitError("inPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cpdef outPort(self, unsigned short ioPortAddr, unsigned char data, unsigned char dataSize):
        cdef unsigned char channel, oldStep, cmdByte, specialMask, poll, readOp
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in PIC_PIC1_PORTS):
                channel = 0
            elif (ioPortAddr in PIC_PIC2_PORTS):
                channel = 1
            else: # wrong ioPortAddr
                self.main.exitError("outPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
                return
            oldStep = self.channels[channel].step
            if (ioPortAddr in (PIC_PIC1_COMMAND, PIC_PIC2_COMMAND)):
                if (data & PIC_CMD_INITIALIZE):
                    self.channels[channel].inInit = True
                    self.channels[channel].imr = 0
                    self.channels[channel].isr = 0
                    self.channels[channel].irr = 0
                    self.channels[channel].intr = False
                    self.channels[channel].autoEOI = False
                    self.channels[channel].rotateOnAutoEOI = False
                    self.channels[channel].lowestPriority = 7
                    self.channels[channel].setCmdByte(data)
                    self.channels[channel].step = PIC_DATA_STEP_ICW2
                    if (channel == 1):
                        self.channels[0].IRQ_in &= 0xfb
                    if (data & 0x02 or data & 0x08):
                        self.main.exitError("outPort: setCmd: cmdByte {0:#04x} not supported (ioPortAddr == {1:#04x}, dataSize == byte).", data, ioPortAddr)
                    return
                elif ((data & 0x18) == 0x08):
                    specialMask = (data & 0x60) >> 5
                    poll = (data & 0x04) >> 2
                    readOp = data & 0x03
                    if (poll):
                        self.channels[channel].polled = True
                        return
                    if (readOp == 0x02): # IRR is needed
                        self.channels[channel].setNeededRegister(PIC_NEED_IRR)
                    elif (readOp == 0x03): # ISR is needed
                        self.channels[channel].setNeededRegister(PIC_NEED_ISR)
                    if (specialMask == 0x02):
                        self.channels[channel].specialMask = False
                    elif (specialMask == 0x03):
                        self.channels[channel].specialMask = True
                        self.channels[channel].servicePicChannel()
                    return
                elif (data in (0x00, 0x80)):
                    self.channels[channel].rotateOnAutoEOI = (data != 0)
                elif (data in (0x20, 0xa0)):
                    self.channels[channel].clearHighestInterrupt()
                    if (data == 0xa0):
                        self.channels[channel].lowestPriority += 1
                        if (self.channels[channel].lowestPriority > 7):
                            self.channels[channel].lowestPriority = 0
                    self.channels[channel].servicePicChannel()
                elif (data >= 0x60 and data <= 0x67):
                    self.channels[channel].isr &= ~(1 << (data&0x07))
                    self.channels[channel].servicePicChannel()
                elif (data >= 0xc0 and data <= 0xc7):
                    self.channels[channel].lowestPriority = (data&0x07)
                elif (data >= 0xe0 and data <= 0xe7):
                    self.channels[channel].isr &= ~(1 << (data&0x07))
                    self.channels[channel].lowestPriority = (data&0x07)
                    self.channels[channel].servicePicChannel()
                elif (data in (0x02, 0x40)):
                    pass
                else:
                    self.main.printMsg("outPort: setCmd: cmdByte {0:#04x} not supported (ioPortAddr == {1:#04x}, oldStep == {2:d}, dataSize == byte).", data, ioPortAddr, oldStep)
            elif (ioPortAddr in (PIC_PIC1_DATA, PIC_PIC2_DATA)):
                cmdByte = self.channels[channel].getCmdByte()
                if (not self.channels[channel].inInit): # set mask if self.channels[channel].inInit is False
                    self.channels[channel].imr = data
                    self.channels[channel].servicePicChannel()
                elif (oldStep == PIC_DATA_STEP_ICW2):
                    self.channels[channel].setIrqBasePort(data)
                    if (cmdByte & PIC_SINGLE_MODE_NO_ICW3):
                        if (cmdByte & PIC_GET_ICW4):
                            self.channels[channel].step = PIC_DATA_STEP_ICW4
                        else:
                            self.channels[channel].inInit = False
                    else:
                        self.channels[channel].step = PIC_DATA_STEP_ICW3
                elif (oldStep == PIC_DATA_STEP_ICW3):
                    self.channels[channel].setMasterSlaveMap(data)
                    if (cmdByte & PIC_GET_ICW4):
                        self.channels[channel].step = PIC_DATA_STEP_ICW4
                    else:
                        self.channels[channel].inInit = False
                elif (oldStep == PIC_DATA_STEP_ICW4):
                    self.channels[channel].setFlags(data)
                    self.channels[channel].inInit = False
                else: # wrong step
                    self.main.exitError("outPort: oldStep {0:d} not supported (ioPortAddr == {1:#04x}, dataSize == byte).", oldStep, ioPortAddr)
            else: # wrong ioPortAddr
                self.main.exitError("outPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cpdef run(self):
        for channel in self.channels:
            channel.run()
        self.main.platform.addReadHandlers((0x20, 0x21, 0xa0, 0xa1), self)
        self.main.platform.addWriteHandlers((0x20, 0x21, 0xa0, 0xa1), self)


