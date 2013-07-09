
from misc cimport Misc
from mm cimport Mm, MmArea
from pic cimport Pic


cdef class PciAddress:
    cdef unsigned char enableBit, bus, device, function, register
    cdef unsigned int getMmAddress(self)
    cdef void calculateAddress(self, unsigned int address)


cdef class PciDevice:
    cpdef object main
    cdef Pci pci
    cdef PciBus bus
    cdef unsigned char deviceIndex, barsEnabled # barsEnabled is a bitmask
    cdef void reset(self)
    cdef unsigned char checkWriteAccess(self, unsigned int mmAddress, unsigned char dataSize)
    cdef inline unsigned int getMmAddress(self, unsigned char bus, unsigned char device, unsigned char function, unsigned short register)
    cdef unsigned int getData(self, unsigned int mmAddress, unsigned char dataSize)
    cdef void setData(self, unsigned int mmAddress, unsigned int data, unsigned char dataSize)
    cdef void setVendorId(self, unsigned short vendorId)
    cdef void setDeviceId(self, unsigned short deviceId)
    cdef void setDeviceClass(self, unsigned short deviceClass)
    cdef void setVendorDeviceId(self, unsigned short vendorId, unsigned short deviceId)
    cdef void run(self)

cdef class PciBridge(PciDevice):
    cdef void setData(self, unsigned int mmAddress, unsigned int data, unsigned char dataSize)

cdef class PciBus:
    cpdef object main
    cdef Pci pci
    cdef dict deviceList
    cdef unsigned char busIndex
    cdef PciDevice addDevice(self)
    cdef PciDevice getDeviceByIndex(self, unsigned char index)
    cdef void run(self)

cdef class Pci:
    cpdef object main
    cdef dict busList
    cdef unsigned char pciReset, elcr1, elcr2
    cdef unsigned int address
    cdef PciDevice addDevice(self)
    cdef PciDevice getDevice(self, unsigned char bus, unsigned char device)
    cdef unsigned int readRegister(self, unsigned int address, unsigned char dataSize)
    cdef void writeRegister(self, unsigned int address, unsigned int data, unsigned char dataSize)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)


