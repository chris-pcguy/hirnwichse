
import misc, mm
cimport mm

include "globals.pxi"

PCI_DEVICE_CONFIG_SIZE  = 256
PCIE_DEVICE_CONFIG_SIZE = 4096

PCI_VENDOR_ID = 0x00
PCI_DEVICE_ID = 0x02
PCI_CLASS_DEVICE = 0x0a
PCI_HEADER_TYPE = 0x0e

PCI_PRIMARY_BUS = 0x18
PCI_SECONDARY_BUS = 0x19
PCI_SUBORDINATE_BUS = 0x1a

PCI_CLASS_BRIDGE_HOST = 0x0600
PCI_CLASS_BRIDGE_PCI  = 0x0604
PCI_VENDOR_ID_INTEL   = 0x8086
PCI_DEVICE_ID_INTEL_430FX = 0x122d

PCI_HEADER_TYPE_BRIDGE = 1

cdef class PciDevice:
    cpdef object main, pci, bus
    cpdef mm.ConfigSpace configSpace
    def __init__(self, object bus, object pci, object main):
        self.bus = bus
        self.pci = pci
        self.main = main
    cpdef reset(self):
        self.configSpace.csResetData()
    cpdef getData(self, unsigned char function, unsigned char register, unsigned char dataSize):
        cdef unsigned long bitMask = self.main.misc.getBitMaskFF(dataSize)
        if (function != 0):
            self.main.exitError("PciDevice::getData: function {0:d} != 0.", function)
            return bitMask
        return self.configSpace.csReadValue(register, dataSize)
    cpdef setData(self, unsigned char function, unsigned char register, unsigned long long data, unsigned char dataSize):
        if (function != 0):
            self.main.exitError("PciDevice::getData: function {0:d} != 0.", function)
            return
        self.configSpace.csWriteValue(register, data, dataSize)
    cpdef setVendorId(self, unsigned short vendorId):
        self.setData(0, PCI_VENDOR_ID, vendorId, OP_SIZE_WORD)
    cpdef setDeviceId(self, unsigned short deviceId):
        self.setData(0, PCI_DEVICE_ID, deviceId, OP_SIZE_WORD)
    cpdef setClassDevice(self, unsigned short classDevice):
        self.setData(0, PCI_CLASS_DEVICE, classDevice, OP_SIZE_WORD)
    cpdef setVendorDeviceId(self, unsigned short vendorId, unsigned short deviceId):
        self.setVendorId(vendorId)
        self.setDeviceId(deviceId)
    cpdef run(self):
        self.configSpace = mm.ConfigSpace(PCI_DEVICE_CONFIG_SIZE)
        self.configSpace.run()

cdef class PciBridge(PciDevice):
    def __init__(self, object bus, object pci, object main):
        PciDevice.__init__(self, bus, pci, main)
    cpdef run(self):
        PciDevice.run(self)
        self.setVendorDeviceId(PCI_VENDOR_ID_INTEL, PCI_DEVICE_ID_INTEL_430FX)
        self.setClassDevice(PCI_CLASS_BRIDGE_HOST)
        self.setData(0, PCI_PRIMARY_BUS, 0, OP_SIZE_BYTE)
        self.setData(0, PCI_HEADER_TYPE, PCI_HEADER_TYPE_BRIDGE, OP_SIZE_BYTE)

cdef class PciBus:
    cpdef object pci, main
    cpdef dict deviceList
    def __init__(self, object pci, object main):
        self.pci = pci
        self.main = main
        self.deviceList = {0x00: PciBridge(self, self.pci, self.main)}
    cpdef getDeviceByIndex(self, unsigned char index):
        deviceHandle = self.deviceList.get(index)
        return deviceHandle
    cpdef run(self):
        cdef unsigned char devid
        cdef PciDevice devobj
        for devid, devobj in self.deviceList.items():
            devobj.run()
    ####



cdef class Pci:
    cpdef object main
    cpdef tuple ports
    cpdef dict busList
    cdef unsigned long address
    def __init__(self, object main):
        self.main = main
        self.ports = (0xcf8, 0xcf9, 0xcfc, 0xcfd, 0xcfe, 0xcff)
        self.address = 0
        self.busList = {0x00: PciBus(self, self.main)}
    cpdef parseAddress(self, unsigned long address):
        cdef unsigned char enableBit, bus, device, function, register
        enableBit = (address&0x80000000)!=0
        bus = (address>>16)&0xff
        device = (address>>11)&0x1f
        function = (address>>8)&0x7
        register = address&0xff ####&0xfc
        return enableBit, bus, device, function, register
    cpdef getDevice(self, unsigned long address):
        enableBit, bus, device, function, register = self.parseAddress(address)
        busHandle = self.busList.get(bus)
        if (busHandle):
            if (hasattr(busHandle, 'getDeviceByIndex')):
                deviceHandle = busHandle.getDeviceByIndex(device)
                if (deviceHandle):
                    return deviceHandle
    cpdef readRegister(self, unsigned long address, unsigned char dataSize):
        bitMask = self.main.misc.getBitMaskFF(dataSize)
        deviceHandle = self.getDevice(address)
        if (deviceHandle):
            enableBit, bus, device, function, register = self.parseAddress(address)
            return deviceHandle.getData(function, register, dataSize)
        return bitMask
    cpdef writeRegister(self, unsigned long address, unsigned long long data, unsigned char dataSize):
        deviceHandle = self.getDevice(address)
        if (deviceHandle):
            enableBit, bus, device, function, register = self.parseAddress(address)
            deviceHandle.setData(function, register, data, dataSize)
    cpdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)):
            if (ioPortAddr in (0xcfc, 0xcfd, 0xcfe, 0xcff)):
                return self.readRegister((self.address&0xfffffffc)+(ioPortAddr&3), dataSize)
            else:
                self.main.printMsg("inPort: port {0:#04x} is not supported. (dataSize {1:d})", ioPortAddr, dataSize)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cpdef outPort(self, unsigned short ioPortAddr, unsigned long long data, unsigned char dataSize):
        if (dataSize in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)):
            if (ioPortAddr == 0xcf8):
                self.address = data
            elif (ioPortAddr in (0xcfc, 0xcfd, 0xcfe, 0xcff)):
                self.writeRegister((self.address&0xfffffffc)+(ioPortAddr&3), data, dataSize)
            else:
                self.main.printMsg("outPort: port {0:#04x} is not supported. (data == {1:#04x}, dataSize {2:d})", ioPortAddr, data, dataSize)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cpdef run(self):
        cdef unsigned char busid
        cdef PciBus busobj
        for busid, busobj in self.busList.items():
            busobj.run()
        self.main.platform.addHandlers(self.ports, self)


