
ctypedef void (*SetINTR)(self, unsigned char)

cdef class PicChannel:
    cpdef object main
    cdef Pic pic
    cdef unsigned char master, cmdByte, irqBasePort, mappedSlavesOnMasterMask, \
                        slaveOnThisMasterIrq, needRegister
    cdef unsigned char step, inInit, irq, intr, imr, isr, irr, autoEOI, rotateOnAutoEOI, lowestPriority, polled, \
                                specialMask, IRQ_in, edgeLevel
    cdef void reset(self)
    cdef void clearHighestInterrupt(self)
    cdef void servicePicChannel(self)
    cdef void raiseIrq(self, unsigned char irq)
    cdef void lowerIrq(self, unsigned char irq)
    cdef unsigned char getCmdByte(self)
    cdef void setCmdByte(self, unsigned char cmdByte)
    cdef unsigned char getIrqBasePort(self)
    cdef void setIrqBasePort(self, unsigned char irqBasePort)
    cdef void setMasterSlaveMap(self, unsigned char value)
    cdef void setFlags(self, unsigned char flags)
    cdef unsigned char getNeededRegister(self)
    cdef void setNeededRegister(self, unsigned char needRegister)
    cdef void run(self)

cdef class Pic:
    cpdef public object main
    cdef object cpuInstance
    cdef SetINTR setINTR
    cdef tuple channels
    cdef void raiseIrq(self, unsigned char irq)
    cdef void lowerIrq(self, unsigned char irq)
    cdef unsigned char IAC(self)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef void run(self)


