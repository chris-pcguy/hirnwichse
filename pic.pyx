
include "globals.pxi"


PIC_PIC1_BASE = 0x20
PIC_PIC1_COMMAND = PIC_PIC1_BASE
PIC_PIC1_DATA = PIC_PIC1_BASE+1

PIC_PIC1_PORTS = (PIC_PIC1_COMMAND, PIC_PIC1_DATA)


PIC_PIC2_BASE = 0xA0
PIC_PIC2_COMMAND = PIC_PIC2_BASE
PIC_PIC2_DATA = PIC_PIC2_BASE+1

PIC_PIC2_PORTS = (PIC_PIC2_COMMAND, PIC_PIC2_DATA)


PIC_MASTER = 0
PIC_SLAVE  = 1

PIC_GET_ICW4 = 0x01
PIC_SINGLE_MODE_NO_ICW3 = 0x02
PIC_CMD_INITIALIZE = 0x10
PIC_EOI = 0x20

PIC_DATA_STEP_ICW1 = 1
PIC_DATA_STEP_ICW2 = 2
PIC_DATA_STEP_ICW3 = 3
PIC_DATA_STEP_ICW4 = 4

PIC_FLAG_SHOULD_BE_SET_ON_PC = 0x1
PIC_FLAG_AUTO_EOI = 0x2

PIC_NEED_IRR = 1
PIC_NEED_ISR = 2


cdef class PicChannel:
    cdef public object main, pic
    cdef unsigned char master, step, cmdByte, maskByte, irqBasePort, flags, mappedSlavesOnMasterMask, \
                        slaveOnThisMasterIrq, inInit, isr, irr, needRegister
    def __init__(self, object pic, object main, unsigned char master):
        self.pic    = pic
        self.main   = main
        self.master = master
        self.reset()
    def reset(self):
        self.step = PIC_DATA_STEP_ICW1
        self.cmdByte = 0
        self.irqBasePort = 0x8
        self.maskByte = 0xf8
        self.flags = 0x1
        self.isr = 0
        self.irr = 0
        self.needRegister = PIC_NEED_IRR
        self.inInit = False
        if (not self.master):
            self.irqBasePort = 0x70 
            self.maskByte = 0xde
        self.mappedSlavesOnMasterMask = 0x4 # master
        self.slaveOnThisMasterIrq = 2 # slave
    def gotEOI(self):
        for irq in range(8):
            if (self.isr & (1<<irq)):
                self.isr &= ~(1<<irq)
                return
    def handleLowestIrq(self):
        for irq in range(8):
            if (self.irr & (1<<irq)):
                self.handleIrq(irq)
                return
    def handleIrq(self, unsigned char irq):
        self.irr &= ~(1<<irq)
        self.isr |= 1<<irq
        if (self.master and irq == 2):
            self.pic.channels[1].handleLowestIrq()
        else:
            self.main.cpu.opcodes.interrupt(intNum=(self.irqBasePort+irq), hwInt=True)
    def raiseIrq(self, unsigned char irq):
        cdef unsigned char isIrqMasked = (self.maskByte & (1<<irq))
        if (not isIrqMasked and not (self.isr&(1<<irq)) ):
            self.irr |= 1<<irq
            if (not self.master): # TODO: TO..
                self.pic.raiseIrq(2) # ..DO
            self.main.cpu.setAsync()
    def getStep(self):
        return self.step
    def setStep(self, unsigned char step):
        self.step = step
    def getCmdByte(self):
        return self.cmdByte
    def setCmdByte(self, unsigned char cmdByte):
        self.cmdByte = cmdByte
    def getMaskByte(self):
        return self.maskByte
    def setMaskByte(self, unsigned char maskByte):
        self.maskByte = maskByte
    def getIrqBasePort(self):
        return self.irqBasePort
    def setIrqBasePort(self, unsigned char irqBasePort):
        self.irqBasePort = irqBasePort
        if (self.irqBasePort % 8):
            self.main.exitError("Notice: setIrqBasePort: (self.irqBasePort {0:#04x} MODULO 8) != 0. (channel{1:d})", irqBasePort, self.master==False)
    def setMasterSlaveMap(self, unsigned char value):
        if (self.master):
            self.mappedSlavesOnMasterMask = value
        else:
            self.slaveOnThisMasterIrq = value
    def getFlags(self):
        return self.flags
    def setFlags(self, unsigned char flags):
        self.flags = flags
        if (not (self.flags & PIC_FLAG_SHOULD_BE_SET_ON_PC)):
            self.main.exitError("Warning: setFlags: self.flags {0:#04x}, PIC_FLAG_SHOULD_BE_SET_ON_PC not set! (channel{1:d})", flags, self.master==False)
    def getIsr(self):
        return self.isr
    def getIrr(self):
        return self.irr
    def setNeededRegister(self, unsigned char picReg):
        self.needRegister = picReg
    def getNeededRegister(self):
        return self.needRegister
    



cdef class Pic:
    cdef public object main
    cdef public tuple channels
    def __init__(self, object main):
        self.main = main
        self.channels = (PicChannel(self, self.main, True), PicChannel(self, self.main, False))
    def handleIrq(self, unsigned char irq):
        if (irq > 15):
            self.main.exitError("handleIrq: invalid irq! (irq: {0:d})", irq)
        if (irq >= 8):
            return self.channels[1].handleIrq(irq-8)
        return self.channels[0].handleIrq(irq)
    def raiseIrq(self, unsigned char irq):
        if (irq > 15):
            self.main.exitError("raiseIrq: invalid irq! (irq: {0:d})", irq)
        if (irq == 2):
            irq = 9
        if (irq >= 8):
            return self.channels[1].raiseIrq(irq-8)
        return self.channels[0].raiseIrq(irq)
    def inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned char channel, oldStep, neededRegister
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in PIC_PIC1_PORTS):
                channel = 0
            elif (ioPortAddr in PIC_PIC2_PORTS):
                channel = 1
            if (ioPortAddr in (PIC_PIC1_COMMAND, PIC_PIC2_COMMAND)):
                neededRegister = self.channels[channel].getNeededRegister()
                if (neededRegister == PIC_NEED_IRR):
                    return self.channels[channel].getIrr()
                elif (neededRegister == PIC_NEED_ISR):
                    return self.channels[channel].getIsr()
                else:
                    self.main.exitError("inPort: ioPortAddr {0:#04x} need neededRegister to be in (PIC_NEED_IRR, PIC_NEED_ISR) (dataSize == byte).", ioPortAddr)
                    return 0
            elif (ioPortAddr in (PIC_PIC1_DATA, PIC_PIC2_DATA)):
                oldStep = self.channels[channel].getStep()
                if (oldStep == PIC_DATA_STEP_ICW1): # not cmd to exec, so set mask
                    return self.channels[channel].getMaskByte()
                else: # wrong step
                    self.main.exitError("inPort: oldStep {0:d} not supported (ioPortAddr == {1:#04x}, dataSize == byte).", oldStep, ioPortAddr)
            else:
                self.main.exitError("inPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, unsigned short ioPortAddr, unsigned char data, unsigned char dataSize):
        cdef unsigned char channel, oldStep, cmdByte
        if (dataSize == OP_SIZE_BYTE):
            if (ioPortAddr in PIC_PIC1_PORTS):
                channel = 0
            elif (ioPortAddr in PIC_PIC2_PORTS):
                channel = 1
            else: # wrong ioPortAddr
                self.main.exitError("outPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
                return
            oldStep = self.channels[channel].getStep()
            
            if (ioPortAddr in (PIC_PIC1_COMMAND, PIC_PIC2_COMMAND)):
                self.channels[channel].setCmdByte(data)
                if (data & PIC_EOI):
                    self.channels[channel].gotEOI()
                elif (data & PIC_CMD_INITIALIZE and oldStep == PIC_DATA_STEP_ICW1):
                    self.channels[channel].setStep(PIC_DATA_STEP_ICW2)
                elif (data == 0x0a and oldStep == PIC_DATA_STEP_ICW1): # IRR wanted
                    self.channels[channel].setNeededRegister(PIC_NEED_IRR)
                elif (data == 0x0b and oldStep == PIC_DATA_STEP_ICW1): # ISR wanted
                    self.channels[channel].setNeededRegister(PIC_NEED_ISR)
                else:
                    self.main.printMsg("outPort: setCmd: cmdByte {0:#04x} not supported (ioPortAddr == {1:#04x}, oldStep == {2:d}, dataSize == byte).", data, ioPortAddr, oldStep)
            elif (ioPortAddr in (PIC_PIC1_DATA, PIC_PIC2_DATA)):
                if (oldStep == PIC_DATA_STEP_ICW1): # not cmd to exec, so set mask
                    self.channels[channel].setMaskByte(data)
                elif (oldStep == PIC_DATA_STEP_ICW2):
                    cmdByte = self.channels[channel].getCmdByte()
                    self.channels[channel].setIrqBasePort(data)
                    if (cmdByte & PIC_SINGLE_MODE_NO_ICW3 and \
                        cmdByte & PIC_GET_ICW4):
                        self.channels[channel].setStep(PIC_DATA_STEP_ICW4)
                    elif (cmdByte & PIC_SINGLE_MODE_NO_ICW3 and \
                        not (cmdByte & PIC_GET_ICW4)):
                        self.channels[channel].setStep(PIC_DATA_STEP_ICW1)
                    elif (not (cmdByte & PIC_SINGLE_MODE_NO_ICW3)):
                        self.channels[channel].setStep(PIC_DATA_STEP_ICW3)
                    else: # wrong cmdByte
                        self.main.printMsg("outPort: ICW2: cmdByte {0:#04x} not supported (ioPortAddr == {1:#04x}, dataSize == byte).", cmdByte, ioPortAddr)
                elif (oldStep == PIC_DATA_STEP_ICW3):
                    self.channels[channel].setMasterSlaveMap(data)
                    if (self.channels[channel].getCmdByte() & PIC_GET_ICW4):
                        self.channels[channel].setStep(PIC_DATA_STEP_ICW4)
                    else:
                        self.channels[channel].setStep(PIC_DATA_STEP_ICW1)
                elif (oldStep == PIC_DATA_STEP_ICW4):
                    self.channels[channel].setFlags(data)
                    self.channels[channel].setStep(PIC_DATA_STEP_ICW1)
                else: # wrong step
                    self.main.exitError("outPort: oldStep {0:d} not supported (ioPortAddr == {1:#04x}, dataSize == byte).", oldStep, ioPortAddr)
            else: # wrong ioPortAddr
                self.main.exitError("outPort: ioPortAddr {0:#04x} not supported (dataSize == byte).", ioPortAddr)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers((0x20, 0x21, 0xa0, 0xa1), self.inPort)
        self.main.platform.addWriteHandlers((0x20, 0x21, 0xa0, 0xa1), self.outPort)


