
ctypedef void (*SetINTR)(self, unsigned char)


cdef class PicChannel:
    cpdef public object main
    cdef public Pic pic
    cdef unsigned char master, cmdByte, irqBasePort, mappedSlavesOnMasterMask, \
                        slaveOnThisMasterIrq, needRegister
    cdef public unsigned char step, inInit, irq, intr, imr, isr, irr, autoEOI, rotateOnAutoEOI, lowestPriority, polled, \
                                specialMask, IRQ_in, edgeLevel
    cdef reset(self)
    cdef clearHighestInterrupt(self)
    cdef servicePicChannel(self)
    cdef raiseIrq(self, unsigned char irq)
    cdef lowerIrq(self, unsigned char irq)
    cdef getCmdByte(self)
    cdef setCmdByte(self, unsigned char cmdByte)
    cdef getIrqBasePort(self)
    cdef setIrqBasePort(self, unsigned char irqBasePort)
    cdef setMasterSlaveMap(self, unsigned char value)
    cdef setFlags(self, unsigned char flags)
    cdef setNeededRegister(self, unsigned char needRegister)
    cdef getNeededRegister(self)
    cdef run(self)

cdef class Pic:
    cpdef public object main
    cdef object cpuObject
    cdef SetINTR setINTR
    cdef public tuple channels
    cdef raiseIrq(self, unsigned char irq)
    cdef lowerIrq(self, unsigned char irq)
    cdef unsigned char IAC(self)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef run(self)


