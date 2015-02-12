
from hirnwichse_main cimport Hirnwichse

cdef class PicChannel:
    cdef Pic pic
    cdef unsigned char master, cmdByte, irqBasePort, mappedSlavesOnMasterMask, \
                        slaveOnThisMasterIrq, needRegister, step, inInit, irq, \
                        imr, intr, isr, irr, autoEOI, rotateOnAutoEOI, lowestPriority, \
                        polled, specialMask, IRQ_in, edgeLevel
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
    cdef Hirnwichse main
    cdef tuple channels
    cdef void setMode(self, unsigned char channel, unsigned char edgeLevel)
    cdef void raiseIrq(self, unsigned char irq)
    cdef void lowerIrq(self, unsigned char irq)
    cdef unsigned char isClear(self, unsigned char irq)
    cdef unsigned char IAC(self)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)


