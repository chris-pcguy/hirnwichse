
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


PCI_CLASS_BRIDGE_PCI = 0x0604
PCI_VENDOR_ID_INTEL  = 0x8086
PCI_DEVICE_ID_INTEL_430FX = 0x122d

PCI_HEADER_TYPE_BRIDGE = 1

class PciDevice:
    def __init__(self, bus, pci, main):
        self.bus = bus
        self.pci = pci
        self.main = main
        self.configSpace = mm.ConfigSpace(PCI_DEVICE_CONFIG_SIZE, self.main)
    def getData(self, function, register, dataSize):
        bitMask = self.main.misc.getBitMask(dataSize)
        if (function != 0):
            self.main.exitError("PciDevice::getData: function {0:d} != 0.", function)
            return bitMask
        return self.configSpace.csReadValue(register, dataSize)
    def setData(self, function, register, data, dataSize):
        if (function != 0):
            self.main.exitError("PciDevice::getData: function {0:d} != 0.", function)
            return
        self.configSpace.csWriteValue(register, data, dataSize)
    def setVendorId(self, vendorId):
        self.setData(0, PCI_VENDOR_ID, vendorId, misc.OP_SIZE_16BIT)
    def setDeviceId(self, deviceId):
        self.setData(0, PCI_DEVICE_ID, deviceId, misc.OP_SIZE_16BIT)
    def setClassDevice(self, classDevice):
        self.setData(0, PCI_CLASS_DEVICE, classDevice, misc.OP_SIZE_16BIT)
    def setVendorDeviceId(self, vendorId, deviceId):
        self.setVendorId(vendorId)
        self.setDeviceId(deviceId)

class PciBridge(PciDevice):
    def __init__(self, bus, pci, main):
        PciDevice.__init__(self, bus, pci, main)
        self.setVendorDeviceId(PCI_VENDOR_ID_INTEL, PCI_DEVICE_ID_INTEL_430FX)
        self.setClassDevice(PCI_CLASS_BRIDGE_PCI)
        self.setData(0, PCI_PRIMARY_BUS, 0, misc.OP_SIZE_8BIT)
        self.setData(0, PCI_HEADER_TYPE, PCI_HEADER_TYPE_BRIDGE, misc.OP_SIZE_8BIT)
    

class PciBus:
    def __init__(self, pci, main):
        self.pci = pci
        self.main = main
        self.deviceList = {0x00: PciBridge(self, self.pci, self.main), 0x01: PciBridge(self, self.pci, self.main)}
    def getDeviceByIndex(self, index):
        deviceHandle = self.deviceList.get(index)
        return deviceHandle



class Pci:
    def __init__(self, main):
        self.main = main
        self.ports = (0xcf8, 0xcf9, 0xcfc, 0xcfd, 0xcfe, 0xcff)
        self.address = 0
        self.busList = {0x00: PciBus(self, self.main)}
    def parseAddress(self, address):
        enableBit = (address&0x80000000)!=0
        bus = (address>>16)&0xff
        device = (address>>11)&0x1f
        function = (address>>8)&0x7
        register = address&0xff ####&0xfc
        return enableBit, bus, device, function, register
    def getDevice(self, address):
        enableBit, bus, device, function, register = self.parseAddress(address)
        busHandle = self.busList.get(bus)
        if (busHandle):
            if (hasattr(busHandle, 'getDeviceByIndex')):
                deviceHandle = busHandle.getDeviceByIndex(device)
                if (deviceHandle):
                    return deviceHandle
    def readRegister(self, address, dataSize):
        bitMask = self.main.misc.getBitMask(dataSize)
        deviceHandle = self.getDevice(address)
        if (deviceHandle):
            enableBit, bus, device, function, register = self.parseAddress(address)
            return deviceHandle.getData(function, register, dataSize)
        return bitMask
    def writeRegister(self, address, data, dataSize):
        deviceHandle = self.getDevice(address)
        if (deviceHandle):
            enableBit, bus, device, function, register = self.parseAddress(address)
            deviceHandle.setData(function, register, data, dataSize)
    def inPort(self, ioPortAddr, dataSize):
        if (dataSize in (misc.OP_SIZE_8BIT, misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT)):
            if (ioPortAddr in (0xcfc, 0xcfd, 0xcfe, 0xcff)):
                return self.readRegister((self.address&0xfffffffc)+(ioPortAddr&3), dataSize)
            else:
                self.main.printMsg("inPort: port {0:#04x} is not supported. (dataSize {1:d})", ioPortAddr, dataSize)
        else:
            self.main.exitError("inPort: dataSize {0:d} not supported.", dataSize)
        return 0
    def outPort(self, ioPortAddr, data, dataSize):
        if (dataSize in (misc.OP_SIZE_8BIT, misc.OP_SIZE_16BIT, misc.OP_SIZE_32BIT)):
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


