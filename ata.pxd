
from libc.stdint cimport *
from cpython.ref cimport PyObject, Py_INCREF

from hirnwichse_main cimport Hirnwichse
from cmos cimport Cmos
from pic cimport Pic
from mm cimport ConfigSpace
from pci cimport Pci, PciDevice

cdef class AtaDrive:
    cdef object fp
    cdef AtaController ataController
    cdef ConfigSpace configSpace
    cdef uint8_t driveId, driveType, isLoaded, isWriteProtected, isLocked, sectorShift, senseKey, senseAsc
    cdef uint16_t sectorSize, driveCode
    cdef uint64_t sectors
    cdef bytes filename
    cdef uint64_t ChsToSector(self, uint32_t cylinder, uint8_t head, uint8_t sector)
    cdef inline void writeValue(self, uint8_t index, uint16_t value)
    cdef void reset(self)
    cdef void loadDrive(self, bytes filename)
    cdef bytes readBytes(self, uint64_t offset, uint32_t size)
    cdef inline bytes readSectors(self, uint64_t sector, uint32_t count) # count in sectors
    cdef void writeBytes(self, uint64_t offset, uint32_t size, bytes data)
    cdef inline void writeSectors(self, uint64_t sector, uint32_t count, bytes data)
    cdef void run(self)


cdef class AtaController:
    cdef Ata ata
    cdef PyObject *drive[2]
    cdef bytes result, data
    cdef uint8_t controllerId, driveId, useLBA, useLBA48, irqEnabled, HOB, doReset, driveBusy, resetInProgress, driveReady, \
        errorRegister, drq, seekComplete, err, irq, cmd, sector, head, sectorCountFlipFlop, sectorHighFlipFlop, sectorMiddleFlipFlop, \
        sectorLowFlipFlop, indexPulse, indexPulseCount, features, sectorCountByte, multipleSectors, busmasterCommand, busmasterStatus, mdmaMode, udmaMode
    cdef uint32_t sectorCount, cylinder, busmasterAddress
    cdef uint64_t lba
    cdef void setSignature(self, uint8_t driveId)
    cdef void reset(self, uint8_t swReset) nogil
    cdef inline void LbaToCHS(self)
    cdef void convertToLBA28(self)
    cdef void raiseAtaIrq(self, uint8_t withDRQ, uint8_t doIRQ)
    cdef void lowerAtaIrq(self)
    cdef void abortCommand(self)
    cdef void errorCommand(self, uint8_t errorRegister)
    cdef void nopCommand(self)
    cdef void handlePacket(self)
    cdef void handleBusmaster(self)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize)
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef void run(self)


cdef class Ata:
    cdef Hirnwichse main
    cdef PyObject *controller[2]
    cdef PciDevice pciDevice
    cdef uint32_t base4Addr, base4AddrMasked
    cdef void reset(self) nogil
    cdef uint8_t isBusmaster(self, uint16_t ioPortAddr)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize)
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize)
    cdef void run(self)


