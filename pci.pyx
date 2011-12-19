
import misc
from misc cimport Misc

include "globals.pxi"


cdef class PciDevice:
    def __init__(self, PciBus bus, Pci pci, object main):
        self.bus = bus
        self.pci = pci
        self.main = main
        self.configSpace = None
    cdef reset(self):
        if (self.configSpace is not None):
            self.configSpace.csResetData()
    cdef unsigned long getData(self, unsigned char function, unsigned char register, unsigned char dataSize):
        cdef unsigned long bitMask = (<Misc>self.main.misc).getBitMaskFF(dataSize)
        if (function != 0):
            self.main.printMsg("PciDevice::getData: function {0:d} != 0.", function)
            return bitMask
        return self.configSpace.csReadValue(register, dataSize, False)
    cdef setData(self, unsigned char function, unsigned char register, unsigned long data, unsigned char dataSize):
        if (function != 0):
            self.main.printMsg("PciDevice::getData: function {0:d} != 0.", function)
            return
        self.configSpace.csWriteValue(register, data, dataSize)
    cdef setVendorId(self, unsigned short vendorId):
        self.setData(0, PCI_VENDOR_ID, vendorId, OP_SIZE_WORD)
    cdef setDeviceId(self, unsigned short deviceId):
        self.setData(0, PCI_DEVICE_ID, deviceId, OP_SIZE_WORD)
    cdef setClassDevice(self, unsigned short classDevice):
        self.setData(0, PCI_CLASS_DEVICE, classDevice, OP_SIZE_WORD)
    cdef setVendorDeviceId(self, unsigned short vendorId, unsigned short deviceId):
        self.setVendorId(vendorId)
        self.setDeviceId(deviceId)
    cdef run(self):
        self.configSpace = ConfigSpace(PCI_DEVICE_CONFIG_SIZE)
        if (self.configSpace is not None):
            self.configSpace.run()

cdef class PciBridge(PciDevice):
    def __init__(self, PciBus bus, Pci pci, object main):
        PciDevice.__init__(self, bus, pci, main)
    cdef run(self):
        PciDevice.run(self)
        self.setVendorDeviceId(PCI_VENDOR_ID_INTEL, PCI_DEVICE_ID_INTEL_430FX)
        self.setClassDevice(PCI_CLASS_BRIDGE_HOST)
        self.setData(0, PCI_PRIMARY_BUS, 0, OP_SIZE_BYTE)
        self.setData(0, PCI_HEADER_TYPE, PCI_HEADER_TYPE_BRIDGE, OP_SIZE_BYTE)

cdef class PciBus:
    def __init__(self, Pci pci, object main):
        self.pci = pci
        self.main = main
        self.deviceList = {0x00: PciBridge(self, self.pci, self.main)}
    cdef PciDevice getDeviceByIndex(self, unsigned char index):
        cdef PciDevice deviceHandle
        deviceHandle = self.deviceList.get(index)
        if (deviceHandle is not None):
            return deviceHandle
        return None
    cdef run(self):
        cdef unsigned char deviceIndex
        cdef PciDevice deviceHandle
        for deviceIndex, deviceHandle in self.deviceList.items():
            if (deviceHandle is not None):
                deviceHandle.run()
    ####



cdef class Pci:
    def __init__(self, object main):
        self.main = main
        self.address = 0
        self.busList = {0x00: PciBus(self, self.main)}
    cdef tuple parseAddress(self, unsigned long address):
        cdef unsigned char enableBit, bus, device, function, register
        enableBit = (address&0x80000000)!=0
        bus = (address>>16)&0xff
        device = (address>>11)&0x1f
        function = (address>>8)&0x7
        register = address&0xff ####&0xfc
        return enableBit, bus, device, function, register
    cdef PciDevice getDevice(self, unsigned long address):
        cdef PciBus busHandle
        cdef PciDevice deviceHandle
        cdef unsigned char enableBit, bus, device, function, register
        enableBit, bus, device, function, register = self.parseAddress(address)
        busHandle = self.busList.get(bus)
        if (busHandle is not None):
            if (hasattr(busHandle, 'getDeviceByIndex')):
                deviceHandle = busHandle.getDeviceByIndex(device)
                if (deviceHandle is not None):
                    return deviceHandle
        return None
    cdef unsigned long readRegister(self, unsigned long address, unsigned char dataSize):
        cdef PciDevice deviceHandle
        cdef unsigned char enableBit, bus, device, function, register
        cdef unsigned long bitMask
        bitMask = (<Misc>self.main.misc).getBitMaskFF(dataSize)
        deviceHandle = self.getDevice(address)
        if (deviceHandle is not None):
            enableBit, bus, device, function, register = self.parseAddress(address)
            return deviceHandle.getData(function, register, dataSize)
        return bitMask
    cdef writeRegister(self, unsigned long address, unsigned long data, unsigned char dataSize):
        cdef PciDevice deviceHandle
        cdef unsigned char enableBit, bus, device, function, register
        deviceHandle = self.getDevice(address)
        if (deviceHandle is not None):
            enableBit, bus, device, function, register = self.parseAddress(address)
            deviceHandle.setData(function, register, data, dataSize)
    cdef unsigned long inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)):
            if (ioPortAddr in (0xcfc, 0xcfd, 0xcfe, 0xcff)):
                return self.readRegister((self.address&0xfffffffc)+(ioPortAddr&3), dataSize)
            self.main.exitError("inPort: port {0:#04x} is not supported. (dataSize {1:d})", ioPortAddr, dataSize)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cdef outPort(self, unsigned short ioPortAddr, unsigned long data, unsigned char dataSize):
        if (dataSize in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)):
            if (ioPortAddr == 0xcf8):
                self.address = data
            elif (ioPortAddr in (0xcfc, 0xcfd, 0xcfe, 0xcff)):
                self.writeRegister((self.address&0xfffffffc)+(ioPortAddr&3), data, dataSize)
            else:
                self.main.exitError("outPort: port {0:#04x} is not supported. (data == {1:#04x}, dataSize {2:d})", ioPortAddr, data, dataSize)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cdef run(self):
        cdef unsigned char busIndex
        cdef PciBus busHandle
        for busIndex, busHandle in self.busList.items():
            if (busHandle is not None):
                busHandle.run()
        #self.main.platform.addHandlers(PCI_CONTROLLER_PORTS, self)


