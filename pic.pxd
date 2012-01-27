
ctypedef void (*SetINTR)(self, unsigned char)


cdef class PicChannel:
    cpdef object main
    cdef Pic pic
    cdef unsigned char master, cmdByte, irqBasePort, mappedSlavesOnMasterMask, \
                        slaveOnThisMasterIrq, needRegister
    cdef unsigned char step, inInit, irq, intr, imr, isr, irr, autoEOI, rotateOnAutoEOI, lowestPriority, polled, \
                                specialMask, IRQ_in, edgeLevel
    cdef reset(self)
    cdef clearHighestInterrupt(self)
    cdef servicePicChannel(self)
    cpdef raiseIrq(self, unsigned char irq)
    cpdef lowerIrq(self, unsigned char irq)
    cdef getCmdByte(self)
    cdef setCmdByte(self, unsigned char cmdByte)
    cdef getIrqBasePort(self)
    cdef setIrqBasePort(self, unsigned char irqBasePort)
    cdef setMasterSlaveMap(self, unsigned char value)
    cdef setFlags(self, unsigned char flags)
    cdef getNeededRegister(self)
    cdef setNeededRegister(self, unsigned char needRegister)
    cdef run(self)

cdef class Pic:
    cpdef public object main, _pyroDaemon
    cpdef public str _pyroId
    cdef tuple channels
    cpdef raiseIrq(self, unsigned char irq)
    cpdef lowerIrq(self, unsigned char irq)
    cdef unsigned char IAC(self)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef run(self)


