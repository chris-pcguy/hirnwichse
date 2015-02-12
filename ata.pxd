
from hirnwichse_main cimport Hirnwichse
from cmos cimport Cmos
from pic cimport Pic
from mm cimport ConfigSpace
from pci cimport Pci, PciDevice

cdef class AtaDrive:
    cpdef object fp
    cdef AtaController ataController
    cdef ConfigSpace configSpace
    cdef unsigned char driveId, driveType, isLoaded, isWriteProtected, sectorShift
    cdef unsigned short sectorSize, driveCode
    cdef unsigned long int sectors
    cdef bytes filename
    cdef unsigned int ChsToSector(self, unsigned char cylinder, unsigned char head, unsigned char sector)
    cdef inline unsigned short readValue(self, unsigned char index)
    cdef inline void writeValue(self, unsigned char index, unsigned short value)
    cdef void reset(self)
    cdef void loadDrive(self, bytes filename)
    cdef bytes readBytes(self, unsigned long int offset, unsigned int size)
    cdef bytes readSectors(self, unsigned long int sector, unsigned int count) # count in sectors
    cdef void writeBytes(self, unsigned long int offset, unsigned int size, bytes data)
    cdef void writeSectors(self, unsigned long int sector, unsigned int count, bytes data)
    cdef void run(self)


cdef class AtaController:
    cdef Ata ata
    cdef tuple drive
    cdef bytes result, data
    cdef unsigned char controllerId, driveId, useLBA, useLBA48, irqEnabled, HOB, doReset, driveBusy, resetInProgress, driveReady, errorRegister, \
        drq, seekComplete, err, irq, cmd, sector, head, sectorCountFlipFlop, sectorHighFlipFlop, sectorMiddleFlipFlop, sectorLowFlipFlop
    cdef unsigned int sectorCount, cylinder
    cdef unsigned long int lba
    cdef void reset(self, unsigned char swReset)
    cdef inline void LbaToCHS(self)
    cdef void convertToLBA28(self)
    cdef void raiseAtaIrq(self)
    cdef void lowerAtaIrq(self)
    cdef void abortCommand(self)
    cdef void errorCommand(self, unsigned char errorRegister)
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


