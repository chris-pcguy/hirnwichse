
import misc, mm


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
    cdef object main, pci, bus, configSpace
    def __init__(self, object bus, object pci, object main):
        self.bus = bus
        self.pci = pci
        self.main = main
        self.configSpace = mm.ConfigSpace(PCI_DEVICE_CONFIG_SIZE, self.main)
    def getData(self, unsigned char function, unsigned char register, unsigned char dataSize):
        cdef unsigned long bitMask = self.main.misc.getBitMask(dataSize)
        if (function != 0):
            self.main.exitError("PciDevice::getData: function {0:d} != 0.", function)
            return bitMask
        return self.configSpace.csReadValue(register, dataSize)
    def setData(self, unsigned char function, unsigned char register, unsigned long long data, unsigned char dataSize):
        if (function != 0):
            self.main.exitError("PciDevice::getData: function {0:d} != 0.", function)
            return
        self.configSpace.csWriteValue(register, data, dataSize)
    def setVendorId(self, int vendorId):
        self.setData(0, PCI_VENDOR_ID, vendorId, misc.OP_SIZE_WORD)
    def setDeviceId(self, int deviceId):
        self.setData(0, PCI_DEVICE_ID, deviceId, misc.OP_SIZE_WORD)
    def setClassDevice(self, int classDevice):
        self.setData(0, PCI_CLASS_DEVICE, classDevice, misc.OP_SIZE_WORD)
    def setVendorDeviceId(self, int vendorId, int deviceId):
        self.setVendorId(vendorId)
        self.setDeviceId(deviceId)

cdef class PciBridge(PciDevice):
    def __init__(self, object bus, object pci, object main):
        PciDevice.__init__(self, bus, pci, main)
        self.setVendorDeviceId(PCI_VENDOR_ID_INTEL, PCI_DEVICE_ID_INTEL_430FX)
        self.setClassDevice(PCI_CLASS_BRIDGE_HOST)
        self.setData(0, PCI_PRIMARY_BUS, 0, misc.OP_SIZE_BYTE)
        self.setData(0, PCI_HEADER_TYPE, PCI_HEADER_TYPE_BRIDGE, misc.OP_SIZE_BYTE)
    

cdef class PciBus:
    cdef object pci, main
    cdef dict deviceList
    def __init__(self, object pci, object main):
        self.pci = pci
        self.main = main
        self.deviceList = {0x00: PciBridge(self, self.pci, self.main)}
    def getDeviceByIndex(self, int index):
        deviceHandle = self.deviceList.get(index)
        return deviceHandle



cdef class Pci:
    cdef object main
    cdef tuple ports
    cdef dict busList
    cdef unsigned long address
    def __init__(self, object main):
        self.main = main
        self.ports = (0xcf8, 0xcf9, 0xcfc, 0xcfd, 0xcfe, 0xcff)
        self.address = 0
        self.busList = {0x00: PciBus(self, self.main)}
    def parseAddress(self, unsigned long address):
        enableBit = (address&0x80000000)!=0
        bus = (address>>16)&0xff
        device = (address>>11)&0x1f
        function = (address>>8)&0x7
        register = address&0xff ####&0xfc
        return enableBit, bus, device, function, register
    def getDevice(self, unsigned long address):
        enableBit, bus, device, function, register = self.parseAddress(address)
        busHandle = self.busList.get(bus)
        if (busHandle):
            if (hasattr(busHandle, 'getDeviceByIndex')):
                deviceHandle = busHandle.getDeviceByIndex(device)
                if (deviceHandle):
                    return deviceHandle
    def readRegister(self, unsigned long address, unsigned char dataSize):
        bitMask = self.main.misc.getBitMask(dataSize)
        deviceHandle = self.getDevice(address)
        if (deviceHandle):
            enableBit, bus, device, function, register = self.parseAddress(address)
            return deviceHandle.getData(function, register, dataSize)
        return bitMask
    def writeRegister(self, unsigned long address, unsigned long long data, unsigned char dataSize):
        deviceHandle = self.getDevice(address)
        if (deviceHandle):
            enableBit, bus, device, function, register = self.parseAddress(address)
            deviceHandle.setData(function, register, data, dataSize)
    def inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        if (dataSize in (misc.OP_SIZE_BYTE, misc.OP_SIZE_WORD, misc.OP_SIZE_DWORD)):
            if (ioPortAddr in (0xcfc, 0xcfd, 0xcfe, 0xcff)):
                return self.readRegister((self.address&0xfffffffc)+(ioPortAddr&3), dataSize)
            else:
                self.main.printMsg("inPort: port {0:#04x} is not supported. (dataSize {1:d})", ioPortAddr, dataSize)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, unsigned short ioPortAddr, unsigned long long data, unsigned char dataSize):
        if (dataSize in (misc.OP_SIZE_BYTE, misc.OP_SIZE_WORD, misc.OP_SIZE_DWORD)):
            if (ioPortAddr == 0xcf8):
                self.address = data
            elif (ioPortAddr in (0xcfc, 0xcfd, 0xcfe, 0xcff)):
                self.writeRegister((self.address&0xfffffffc)+(ioPortAddr&3), data, dataSize)
            else:
                self.main.printMsg("outPort: port {0:#04x} is not supported. (data == {1:#04x}, dataSize {2:d})", ioPortAddr, data, dataSize)
        else:
            self.main.exitError("outPort: dataSize {0:d} not supported.", dataSize)
        return
    def run(self):
        self.main.platform.addReadHandlers(self.ports, self.inPort)
        self.main.platform.addWriteHandlers(self.ports, self.outPort)


