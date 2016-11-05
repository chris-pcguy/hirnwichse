
from libc.stdint cimport *

from hirnwichse_main cimport Hirnwichse
from mm cimport ConfigSpace
from pic cimport Pic


cdef class PciAddress:
    cdef uint8_t enableBit, bus, device, function, register
    cdef uint32_t getMmAddress(self)
    cdef void calculateAddress(self, uint32_t address)


cdef class PciDevice:
    cdef Pci pci
    cdef PciBus bus
    cdef ConfigSpace configSpace
    cdef uint8_t deviceIndex
    cdef uint8_t barSize[7] # size in bits
    cdef void reset(self)
    cdef uint8_t checkWriteAccess(self, uint32_t mmAddress, uint32_t data, uint8_t dataSize) nogil
    cdef uint32_t getData(self, uint32_t mmAddress, uint8_t dataSize) nogil
    cdef void setData(self, uint32_t mmAddress, uint32_t data, uint8_t dataSize) nogil
    cdef void setVendorId(self, uint16_t vendorId)
    cdef void setDeviceId(self, uint16_t deviceId)
    cdef void setDeviceClass(self, uint16_t deviceClass)
    cdef void setVendorDeviceId(self, uint16_t vendorId, uint16_t deviceId)
    cdef void setBarSize(self, uint8_t barIndex, uint8_t barSize)
    cdef void run(self)

cdef class PciBridge(PciDevice):
    cdef void setData(self, uint32_t mmAddress, uint32_t data, uint8_t dataSize) nogil
    cdef void run(self)

cdef class Pci2Isa(PciDevice):
    cdef uint8_t irqRegistry[16]
    cdef uint8_t irqLevel[4][16]
    cdef void reset(self)
    cdef void pciRegisterIrq(self, uint8_t pirq, uint8_t irq) nogil
    cdef void pciUnregisterIrq(self, uint8_t pirq, uint8_t irq) nogil
    cdef void setData(self, uint32_t mmAddress, uint32_t data, uint8_t dataSize) nogil
    cdef void run(self)

cdef class PciBus:
    cdef Pci pci
    cdef list deviceList
    cdef uint8_t busIndex
    cdef PciDevice addDevice(self)
    cdef PciDevice getDeviceByIndex(self, uint8_t index)
    cdef void run(self)

cdef class Pci:
    cdef Hirnwichse main
    cdef PciAddress pciAddressHandle
    cdef list busList
    cdef uint8_t pciReset, elcr1, elcr2
    cdef uint32_t address
    cdef PciDevice addDevice(self)
    cdef PciDevice getDevice(self, uint8_t bus, uint8_t device)
    cdef uint32_t readRegister(self, uint32_t address, uint8_t dataSize)
    cdef void writeRegister(self, uint32_t address, uint32_t data, uint8_t dataSize)
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil
    cdef void run(self)


