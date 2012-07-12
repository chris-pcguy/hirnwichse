
from misc cimport Misc
from mm cimport ConfigSpace
from pic cimport Pic


cdef class PciAddress:
    cdef unsigned char enableBit, bus, device, function, register
    cdef void calculateAddress(self, unsigned int address)


cdef class PciDevice:
    cpdef object main
    cdef Pci pci
    cdef PciBus bus
    cdef ConfigSpace configSpace
    cdef void reset(self)
    cdef unsigned int getData(self, unsigned char function, unsigned char register, unsigned char dataSize)
    cdef void setData(self, unsigned char function, unsigned char register, unsigned int data, unsigned char dataSize)
    cdef void setVendorId(self, unsigned short vendorId)
    cdef void setDeviceId(self, unsigned short deviceId)
    cdef void setClassDevice(self, unsigned short classDevice)
    cdef void setVendorDeviceId(self, unsigned short vendorId, unsigned short deviceId)
    cdef void run(self)

cdef class PciBridge(PciDevice):
    pass

cdef class PciBus:
    cpdef object main
    cdef Pci pci
    cdef dict deviceList
    cdef PciDevice getDeviceByIndex(self, unsigned char index)
    cdef void run(self)

cdef class Pci:
    cpdef object main
    cdef dict busList
    cdef unsigned char pciReset, elcr1, elcr2
    cdef unsigned int address
    cdef PciDevice getDevice(self, unsigned char bus, unsigned char device)
    cdef unsigned int readRegister(self, unsigned int address, unsigned char dataSize)
    cdef void writeRegister(self, unsigned int address, unsigned int data, unsigned char dataSize)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize)
    cdef void run(self)


