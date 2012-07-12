

include "globals.pxi"

DEF PCI_DEVICE_CONFIG_SIZE  = 256
DEF PCIE_DEVICE_CONFIG_SIZE = 4096

DEF PCI_VENDOR_ID = 0x00
DEF PCI_DEVICE_ID = 0x02
DEF PCI_CLASS_DEVICE = 0x0a
DEF PCI_HEADER_TYPE = 0x0e

DEF PCI_PRIMARY_BUS = 0x18
DEF PCI_SECONDARY_BUS = 0x19
DEF PCI_SUBORDINATE_BUS = 0x1a

DEF PCI_CLASS_BRIDGE_HOST = 0x0600
DEF PCI_CLASS_BRIDGE_PCI  = 0x0604
DEF PCI_VENDOR_ID_INTEL   = 0x8086
DEF PCI_DEVICE_ID_INTEL_430FX = 0x122d

DEF PCI_HEADER_TYPE_BRIDGE = 1
DEF PCI_RESET_VALUE = 0x02


cdef class PciAddress:
    def __init__(self, unsigned int address):
        self.calculateAddress(address)
    cdef void calculateAddress(self, unsigned int address):
        self.enableBit = (address&0x80000000)!=0
        self.bus = <unsigned char>(address>>16)
        self.device = (address>>11)&0x1f
        self.function = (address>>8)&0x7
        self.register = <unsigned char>address

cdef class PciDevice:
    def __init__(self, PciBus bus, Pci pci, object main):
        self.bus = bus
        self.pci = pci
        self.main = main
        self.configSpace = ConfigSpace(PCI_DEVICE_CONFIG_SIZE, self.main)
    cdef void reset(self):
        if (self.configSpace):
            self.configSpace.csResetData()
    cdef unsigned int getData(self, unsigned char function, unsigned char register, unsigned char dataSize):
        cdef unsigned int bitMask = (<Misc>self.main.misc).getBitMaskFF(dataSize)
        if (function != 0):
            self.main.notice("PciDevice::getData: function {0:d} != 0.", function)
            return bitMask
        return self.configSpace.csReadValueUnsigned(register, dataSize)
    cdef void setData(self, unsigned char function, unsigned char register, unsigned int data, unsigned char dataSize):
        if (function != 0):
            self.main.notice("PciDevice::getData: function {0:d} != 0.", function)
            return
        self.configSpace.csWriteValue(register, data, dataSize)
    cdef void setVendorId(self, unsigned short vendorId):
        self.setData(0, PCI_VENDOR_ID, vendorId, OP_SIZE_WORD)
    cdef void setDeviceId(self, unsigned short deviceId):
        self.setData(0, PCI_DEVICE_ID, deviceId, OP_SIZE_WORD)
    cdef void setClassDevice(self, unsigned short classDevice):
        self.setData(0, PCI_CLASS_DEVICE, classDevice, OP_SIZE_WORD)
    cdef void setVendorDeviceId(self, unsigned short vendorId, unsigned short deviceId):
        self.setVendorId(vendorId)
        self.setDeviceId(deviceId)
    cdef void run(self):
        pass
        #self.configSpace = ConfigSpace(PCI_DEVICE_CONFIG_SIZE, self.main)

cdef class PciBridge(PciDevice):
    def __init__(self, PciBus bus, Pci pci, object main):
        PciDevice.__init__(self, bus, pci, main)
    cdef void run(self):
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
        if (deviceHandle):
            return deviceHandle
        return None
    cdef void run(self):
        cdef unsigned char deviceIndex
        cdef PciDevice deviceHandle
        for deviceIndex, deviceHandle in self.deviceList.items():
            if (deviceHandle):
                deviceHandle.run()
    ####



cdef class Pci:
    def __init__(self, object main):
        self.main = main
        self.pciReset = False
        self.address = self.elcr1 = self.elcr2 = 0
        self.busList = {0x00: PciBus(self, self.main)}
    cdef PciDevice getDevice(self, unsigned char busIndex, unsigned char deviceIndex):
        cdef PciBus busHandle
        cdef PciDevice deviceHandle
        busHandle = self.busList.get(busIndex)
        if (busHandle):
            if (hasattr(busHandle, 'getDeviceByIndex')):
                deviceHandle = busHandle.getDeviceByIndex(deviceIndex)
                if (deviceHandle):
                    return deviceHandle
        return None
    cdef unsigned int readRegister(self, unsigned int address, unsigned char dataSize):
        cdef PciDevice deviceHandle
        cdef PciAddress pciAddressHandle
        cdef unsigned int bitMask
        bitMask = (<Misc>self.main.misc).getBitMaskFF(dataSize)
        pciAddressHandle = PciAddress(address)
        deviceHandle = self.getDevice(pciAddressHandle.bus, pciAddressHandle.device)
        if (deviceHandle):
            if (not pciAddressHandle.enableBit):
                self.main.notice("Pci::readRegister: Warning: tried to read from configSpace without enableBit set.")
            return deviceHandle.getData(pciAddressHandle.function, pciAddressHandle.register, pciAddressHandle.dataSize)
        return bitMask
    cdef void writeRegister(self, unsigned int address, unsigned int data, unsigned char dataSize):
        cdef PciDevice deviceHandle
        cdef PciAddress pciAddressHandle
        pciAddressHandle = PciAddress(address)
        deviceHandle = self.getDevice(pciAddressHandle.bus, pciAddressHandle.device)
        if (deviceHandle):
            if (not pciAddressHandle.enableBit):
                self.main.notice("Pci::writeRegister: Warning: tried to write to configSpace without enableBit set.")
            deviceHandle.setData(pciAddressHandle.function, pciAddressHandle.register, data, dataSize)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)):
            if (ioPortAddr == 0x4d0):
                return self.elcr1
            elif (ioPortAddr == 0x4d1):
                return self.elcr2
            elif (ioPortAddr == 0xcf8):
                return self.address
            elif (ioPortAddr == 0xcf9):
                return (self.pciReset and PCI_RESET_VALUE)
            elif (ioPortAddr in (0xcfc, 0xcfd, 0xcfe, 0xcff)):
                return self.readRegister((self.address&0xfffffffc)+(ioPortAddr&3), dataSize)
            self.main.exitError("inPort: port {0:#04x} is not supported. (dataSize {1:d})", ioPortAddr, dataSize)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        if (dataSize in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)):
            if (ioPortAddr == 0x4d0):
                data &= 0xf8
                if (data != self.elcr1):
                    self.elcr1 = data
                    (<Pic>self.main.platform.pic).setMode(0, self.elcr1)
            elif (ioPortAddr == 0x4d1):
                data &= 0xde
                if (data != self.elcr2):
                    self.elcr2 = data
                    (<Pic>self.main.platform.pic).setMode(1, self.elcr2)
            elif (ioPortAddr == 0xcf8):
                self.address = data
            elif (ioPortAddr == 0xcf9):
                self.pciReset = (data & PCI_RESET_VALUE) != 0
                if (data & 0x04):
                    if (self.pciReset):
                        self.main.reset(True)
                    else:
                        self.main.reset(False)
            elif (ioPortAddr in (0xcfc, 0xcfd, 0xcfe, 0xcff)):
                self.writeRegister((self.address&0xfffffffc)+(ioPortAddr&3), data, dataSize)
            else:
                self.main.exitError("outPort: port {0:#04x} is not supported. (data == {1:#04x}, dataSize {2:d})", ioPortAddr, data, dataSize)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    cdef void run(self):
        cdef unsigned char busIndex
        cdef PciBus busHandle
        for busIndex, busHandle in self.busList.items():
            if (busHandle):
                busHandle.run()


