
from mm cimport ConfigSpace


cdef class PciDevice:
    cpdef public object main
    cdef public Pci pci
    cdef public PciBus bus
    cdef ConfigSpace configSpace
    cdef reset(self)
    cdef getData(self, unsigned char function, unsigned char register, unsigned char dataSize)
    cdef setData(self, unsigned char function, unsigned char register, unsigned long long data, unsigned char dataSize)
    cdef setVendorId(self, unsigned short vendorId)
    cdef setDeviceId(self, unsigned short deviceId)
    cdef setClassDevice(self, unsigned short classDevice)
    cdef setVendorDeviceId(self, unsigned short vendorId, unsigned short deviceId)
    cdef run(self)

cdef class PciBridge(PciDevice):
    cdef run(self)

cdef class PciBus:
    cpdef public object main
    cdef public Pci pci
    cdef dict deviceList
    cdef getDeviceByIndex(self, unsigned char index)
    cdef run(self)

cdef class Pci:
    cpdef object main
    cdef dict busList
    cdef unsigned long address
    cdef parseAddress(self, unsigned long address)
    cdef getDevice(self, unsigned long address)
    cdef readRegister(self, unsigned long address, unsigned char dataSize)
    cdef writeRegister(self, unsigned long address, unsigned long long data, unsigned char dataSize)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize)
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize)
    cdef run(self)


