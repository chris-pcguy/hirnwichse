
from hirnwichse_main cimport Hirnwichse
from cmos cimport Cmos
from pic cimport Pic
from mm cimport ConfigSpace
from pci cimport Pci, PciDevice

cdef class AtaDrive:
    cpdef object fp
    cdef AtaController ataController
    cdef ConfigSpace configSpace
    cdef unsigned char driveId, driveType, isLoaded, isWriteProtected, isLocked, sectorShift, senseKey, senseAsc
    cdef unsigned short sectorSize, driveCode
    cdef unsigned long int sectors
    cdef bytes filename
    cdef unsigned long int ChsToSector(self, unsigned int cylinder, unsigned char head, unsigned char sector) nogil
    cdef inline unsigned short readValue(self, unsigned char index)
    cdef inline void writeValue(self, unsigned char index, unsigned short value)
    cdef void reset(self) nogil
    cdef void loadDrive(self, bytes filename)
    cdef bytes readBytes(self, unsigned long int offset, unsigned int size)
    cdef inline bytes readSectors(self, unsigned long int sector, unsigned int count) # count in sectors
    cdef void writeBytes(self, unsigned long int offset, unsigned int size, bytes data)
    cdef inline void writeSectors(self, unsigned long int sector, unsigned int count, bytes data)
    cdef void run(self) nogil


cdef class AtaController:
    cdef Ata ata
    cdef tuple drive
    cdef bytes result, data
    cdef unsigned char controllerId, driveId, useLBA, useLBA48, irqEnabled, HOB, doReset, driveBusy, resetInProgress, driveReady, \
        errorRegister, drq, seekComplete, err, irq, cmd, sector, head, sectorCountFlipFlop, sectorHighFlipFlop, sectorMiddleFlipFlop, \
        sectorLowFlipFlop, indexPulse, indexPulseCount, features, sectorCountByte, multipleSectors
    cdef unsigned int sectorCount, cylinder
    cdef unsigned long int lba
    cdef void setSignature(self, unsigned char driveId)
    cdef void reset(self, unsigned char swReset)
    cdef inline void LbaToCHS(self) nogil
    cdef void convertToLBA28(self) nogil
    cdef void raiseAtaIrq(self, unsigned char withDRQ, unsigned char doIRQ)
    cdef void lowerAtaIrq(self) nogil
    cdef void abortCommand(self)
    cdef void errorCommand(self, unsigned char errorRegister)
    cdef void nopCommand(self)
    cdef void handlePacket(self)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)


cdef class Ata:
    cdef Hirnwichse main
    cdef tuple controller
    cdef PciDevice pciDevice
    cdef void reset(self)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)


