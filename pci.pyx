

include "globals.pxi"


cdef class PciAddress:
    def __init__(self, unsigned int address):
        self.calculateAddress(address)
    cdef unsigned int getMmAddress(self):
        #return (PCI_MEM_BASE | (self.bus<<PCI_BUS_SHIFT) | (self.device<<PCI_DEVICE_SHIFT) | (self.function<<PCI_FUNCTION_SHIFT) | self.register)
        return ((self.function<<PCI_FUNCTION_SHIFT) | self.register)
    cdef void calculateAddress(self, unsigned int address):
        self.enableBit = (address>>31)
        self.bus = (address>>PCI_BUS_SHIFT)&BITMASK_BYTE
        self.device = (address>>PCI_DEVICE_SHIFT)&0x1f
        self.function = (address>>PCI_FUNCTION_SHIFT)&0x7
        self.register = address&BITMASK_BYTE

cdef class PciDevice:
    def __init__(self, PciBus bus, Pci pci, object main, unsigned char deviceIndex):
        self.bus = bus
        self.pci = pci
        self.main = main
        self.deviceIndex = deviceIndex
        self.readOnly = False
        self.configSpace = ConfigSpace(PCI_FUNCTION_CONFIG_SIZE, self.main)
        self.configSpace.csResetData(BITMASK_BYTE)
        self.configSpace.csWriteValue(PCI_ROM_ADDRESS, 0, OP_SIZE_DWORD)
        self.configSpace.csWriteValue(PCI_HEADER_TYPE, PCI_HEADER_TYPE_STANDARD, OP_SIZE_BYTE)
    cdef void reset(self):
        pass
    cdef unsigned char checkWriteAccess(self, unsigned int mmAddress, unsigned int data, unsigned char dataSize): # return true means allowed
        cdef unsigned char offset, headerType, function
        cdef unsigned int origData
        offset = mmAddress&0xff
        function = (mmAddress >> PCI_FUNCTION_SHIFT) & 0x7
        if (function): # TODO
            self.main.notice("PciDevice::checkWriteAccess: function ({0:#04x}) != 0x00", function)
        if (offset+dataSize > PCI_BASE_ADDRESS_0 and offset < PCI_BASE_ADDRESS_5+4):
            if (self.readOnly):
                return False # TODO
            if ((offset & 3) != 0):
                self.main.notice("PciDevice::checkWriteAccess: unaligned access!")
            headerType = self.getData((mmAddress & 0xffffff00) | PCI_HEADER_TYPE, OP_SIZE_BYTE)
            if (headerType >= 0x02):
                self.main.notice("PciDevice::checkWriteAccess: headerType ({0:#04x}) >= 0x02", headerType)
                return True
            elif (headerType == 0x01):
                if (offset >= PCI_BASE_ADDRESS_2):
                    return True
            ###data = self.configSpace.csReadValueUnsigned(mmAddress & 0xfffffffc, OP_SIZE_DWORD)
            if (data == BITMASK_DWORD):
                return False
            data = 0xffffffff if (data & 0x1) else 0xfff00008
            self.configSpace.csWriteValue(mmAddress & 0xfffffffc, data, OP_SIZE_DWORD)
            return False
        elif (offset == PCI_ROM_ADDRESS):
            origData = self.configSpace.csReadValueUnsigned(mmAddress & 0xfffffffc, OP_SIZE_DWORD)
            if (self.readOnly):
                return False
        return True
    cdef inline unsigned int getMmAddress(self, unsigned char bus, unsigned char device, unsigned char function, unsigned char register):
        #return (PCI_MEM_BASE | (bus<<PCI_BUS_SHIFT) | ((device&0x1f)<<PCI_DEVICE_SHIFT) | ((function&0x7)<<PCI_FUNCTION_SHIFT) | register)
        return (((function&0x7)<<PCI_FUNCTION_SHIFT) | register)
    cdef unsigned int getData(self, unsigned int mmAddress, unsigned char dataSize):
        return self.configSpace.csReadValueUnsigned(mmAddress, dataSize)
    cdef void setData(self, unsigned int mmAddress, unsigned int data, unsigned char dataSize):
        if (not self.checkWriteAccess(mmAddress, data, dataSize)):
            return
        self.configSpace.csWriteValue(mmAddress, data, dataSize)
    cdef void setVendorId(self, unsigned short vendorId):
        self.setData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_VENDOR_ID), vendorId, OP_SIZE_WORD)
    cdef void setDeviceId(self, unsigned short deviceId):
        self.setData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_DEVICE_ID), deviceId, OP_SIZE_WORD)
    cdef void setDeviceClass(self, unsigned short deviceClass):
        self.setData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_DEVICE_CLASS), deviceClass, OP_SIZE_WORD)
    cdef void setVendorDeviceId(self, unsigned short vendorId, unsigned short deviceId):
        self.setVendorId(vendorId)
        self.setDeviceId(deviceId)
    cdef void setReadOnly(self, unsigned char readOnly):
        self.readOnly = readOnly
    cdef void run(self):
        pass

cdef class PciBridge(PciDevice):
    def __init__(self, PciBus bus, Pci pci, object main, unsigned char deviceIndex):
        PciDevice.__init__(self, bus, pci, main, deviceIndex)
        self.setVendorDeviceId(PCI_VENDOR_ID_INTEL, PCI_DEVICE_ID_INTEL_440FX)
        self.setDeviceClass(PCI_CLASS_BRIDGE_HOST)
        self.setData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_PRIMARY_BUS), 0, OP_SIZE_BYTE)
        self.setData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_HEADER_TYPE), PCI_HEADER_TYPE_BRIDGE, OP_SIZE_BYTE)
    cdef void setData(self, unsigned int mmAddress, unsigned int data, unsigned char dataSize):
        #cdef unsigned int addr, limit
        PciDevice.setData(self, mmAddress, data, dataSize)
        #if (((mmAddress&0xff) == PCI_BRIDGE_MEM_LIMIT and dataSize == 2) or ((mmAddress&0xff) == PCI_BRIDGE_MEM_BASE and dataSize == 4)):
        #    addr = <unsigned int>self.getData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_BRIDGE_MEM_BASE), OP_SIZE_WORD)<<16
        #    limit = <unsigned int>self.getData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_BRIDGE_MEM_LIMIT), OP_SIZE_WORD)<<16
        #    
    cdef void run(self):
        PciDevice.run(self)

cdef class PciBus:
    def __init__(self, Pci pci, object main, unsigned char busIndex):
        self.pci = pci
        self.main = main
        self.busIndex = busIndex
        self.deviceList = [PciBridge(self, self.pci, self.main, 0)]
    cdef PciDevice addDevice(self):
        cdef PciDevice pciDevice
        cdef unsigned char deviceLength = len(self.deviceList)
        pciDevice = PciDevice(self, self.pci, self.main, deviceLength)
        pciDevice.run()
        self.deviceList.append(pciDevice)
        return pciDevice
    cdef PciDevice getDeviceByIndex(self, unsigned char index):
        cdef PciDevice deviceHandle
        try:
            deviceHandle = self.deviceList[index]
            if (deviceHandle):
                return deviceHandle
        except IndexError:
            pass
        return None
    cdef void run(self):
        cdef unsigned char deviceIndex
        cdef PciDevice deviceHandle
        for deviceHandle in self.deviceList:
            if (deviceHandle):
                deviceHandle.run()
    ####



cdef class Pci:
    def __init__(self, object main):
        self.main = main
        self.pciReset = False
        self.address = self.elcr1 = self.elcr2 = 0
        self.busList = [PciBus(self, self.main, 0)]
    cdef PciDevice addDevice(self):
        cdef PciBus pciBus
        cdef PciDevice pciDevice
        pciBus = self.busList[0]
        pciDevice = pciBus.addDevice()
        return pciDevice
    cdef PciDevice getDevice(self, unsigned char busIndex, unsigned char deviceIndex):
        cdef PciBus busHandle
        cdef PciDevice deviceHandle
        try:
            busHandle = self.busList[busIndex]
            if (busHandle):
                deviceHandle = busHandle.getDeviceByIndex(deviceIndex)
                if (deviceHandle):
                    return deviceHandle
        except IndexError:
            pass
        return None
    cdef unsigned int readRegister(self, unsigned int address, unsigned char dataSize):
        cdef PciDevice deviceHandle
        cdef PciAddress pciAddressHandle
        cdef unsigned int bitMask
        pciAddressHandle = PciAddress(address)
        deviceHandle = self.getDevice(pciAddressHandle.bus, pciAddressHandle.device)
        if (deviceHandle):
            if (not pciAddressHandle.enableBit):
                self.main.notice("Pci::readRegister: Warning: tried to read without enableBit set.")
            return deviceHandle.getData(pciAddressHandle.getMmAddress(), dataSize)
        else:
            self.main.debug("Pci::readRegister: deviceHandle is NULL")
        bitMask = BITMASKS_FF[dataSize]
        return bitMask
    cdef void writeRegister(self, unsigned int address, unsigned int data, unsigned char dataSize):
        cdef PciDevice deviceHandle
        cdef PciAddress pciAddressHandle
        pciAddressHandle = PciAddress(address)
        deviceHandle = self.getDevice(pciAddressHandle.bus, pciAddressHandle.device)
        if (deviceHandle):
            if (not pciAddressHandle.enableBit):
                self.main.notice("Pci::writeRegister: Warning: tried to write without enableBit set.")
            deviceHandle.setData(pciAddressHandle.getMmAddress(), data, dataSize)
    cdef unsigned int inPort(self, unsigned short ioPortAddr, unsigned char dataSize):
        cdef unsigned int ret = BITMASK_DWORD
        if (dataSize in (OP_SIZE_BYTE, OP_SIZE_WORD, OP_SIZE_DWORD)):
            if (ioPortAddr == 0x4d0):
                ret = self.elcr1
            elif (ioPortAddr == 0x4d1):
                ret = self.elcr2
            elif (ioPortAddr == 0xcf8):
                ret = self.address
            elif (ioPortAddr == 0xcf9):
                ret = (self.pciReset and PCI_RESET_VALUE)
            elif (ioPortAddr in (0xcfc, 0xcfd, 0xcfe, 0xcff)):
                ret = self.readRegister((self.address&0xfffffffc)+(ioPortAddr&3), dataSize)
            else:
                self.main.exitError("inPort: port {0:#04x} is not supported. (dataSize {1:d})", ioPortAddr, dataSize)
        else:
            self.main.exitError("inPort: port {0:#04x} with dataSize {1:d} not supported.", ioPortAddr, dataSize)
        self.main.debug("inPort: port {0:#04x}. (dataSize {1:d}; ret {2:#06x})", ioPortAddr, dataSize, ret)
        return ret
    cdef void outPort(self, unsigned short ioPortAddr, unsigned int data, unsigned char dataSize):
        self.main.debug("outPort: port {0:#04x}. (dataSize {1:d}; data {2:#06x})", ioPortAddr, dataSize, data)
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
        for busHandle in self.busList:
            if (busHandle):
                busHandle.run()


