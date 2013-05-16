

include "globals.pxi"

DEF PCI_DEVICE_CONFIG_SIZE = 4096

DEF PCI_VENDOR_ID = 0x00
DEF PCI_DEVICE_ID = 0x02
DEF PCI_CLASS_DEVICE = 0x0a
DEF PCI_HEADER_TYPE = 0x0e
DEF PCI_BIST = 0xf
DEF PCI_BASE_ADDRESS_0 = 0x10
DEF PCI_BASE_ADDRESS_1 = 0x14
DEF PCI_BASE_ADDRESS_2 = 0x18
DEF PCI_BASE_ADDRESS_3 = 0x1c
DEF PCI_BASE_ADDRESS_4 = 0x20
DEF PCI_BASE_ADDRESS_5 = 0x24
DEF PCI_BRIDGE_MEM_BASE = 0x20
DEF PCI_BRIDGE_MEM_LIMIT = 0x22

DEF PCI_PRIMARY_BUS = 0x18
DEF PCI_SECONDARY_BUS = 0x19
DEF PCI_SUBORDINATE_BUS = 0x1a

DEF PCI_CLASS_BRIDGE_HOST = 0x0600
DEF PCI_CLASS_BRIDGE_PCI  = 0x0604
DEF PCI_VENDOR_ID_INTEL   = 0x8086
DEF PCI_DEVICE_ID_INTEL_440FX = 0x1237

DEF PCI_HEADER_TYPE_BRIDGE = 1
DEF PCI_RESET_VALUE = 0x02


DEF PCI_BAR0_ENABLED_MASK = 0x1
DEF PCI_BAR1_ENABLED_MASK = 0x2
DEF PCI_BAR2_ENABLED_MASK = 0x4
DEF PCI_BAR3_ENABLED_MASK = 0x8
DEF PCI_BAR4_ENABLED_MASK = 0x10
DEF PCI_BAR5_ENABLED_MASK = 0x20

cdef unsigned int PCI_MEM_BASE = 0xc0000000


cdef class PciAddress:
    def __init__(self, unsigned int address):
        self.calculateAddress(address)
    cdef unsigned int getMmAddress(self):
        return (PCI_MEM_BASE | (self.bus<<20) | (self.device<<15) | (self.function<<12) | (self.register))
    cdef void calculateAddress(self, unsigned int address):
        self.enableBit = (address>>31)
        self.bus = <unsigned char>(address>>16)
        self.device = (address>>11)&0x1f
        self.function = (address>>8)&0x7
        self.register = <unsigned char>address

cdef class PciDevice:
    def __init__(self, PciBus bus, Pci pci, object main, unsigned char deviceIndex):
        self.bus = bus
        self.pci = pci
        self.main = main
        self.deviceIndex = deviceIndex
    cdef void reset(self):
        pass
    cdef unsigned char checkWriteAccess(self, unsigned int mmAddress, unsigned char dataSize): # return true means allowed
        cdef unsigned char offset, headerType
        offset = mmAddress&0xff
        if (offset+dataSize > PCI_BASE_ADDRESS_0 and offset < PCI_BASE_ADDRESS_5+4):
            if ((offset & 3) != 0):
                self.main.notice("PciDevice::checkWriteAccess: unaligned access!")
            headerType = self.getData((mmAddress & 0xffffff00) | PCI_HEADER_TYPE, OP_SIZE_BYTE)
            if (headerType >= 0x02):
                self.main.notice("PciDevice::checkWriteAccess: headerType >= 0x02")
                return True
            elif (headerType == 0x01):
                if (offset >= PCI_BASE_ADDRESS_2):
                    return True
            (<Mm>self.main.mm).mmPhyWriteValue(mmAddress & 0xfffffffc, 0x00, OP_SIZE_DWORD)
            return False
        return True
    cdef inline unsigned int getMmAddress(self, unsigned char bus, unsigned char device, unsigned char function, unsigned short register):
        return (PCI_MEM_BASE | (bus<<20) | ((device&0x1f)<<15) | ((function&0x7)<<12) | (register))
    cdef unsigned int getData(self, unsigned int mmAddress, unsigned char dataSize):
        return (<Mm>self.main.mm).mmPhyReadValueUnsigned(mmAddress, dataSize)
    cdef void setData(self, unsigned int mmAddress, unsigned int data, unsigned char dataSize):
        if (not self.checkWriteAccess(mmAddress, dataSize)):
            return
        (<Mm>self.main.mm).mmPhyWriteValue(mmAddress, data, dataSize)
    cdef void setVendorId(self, unsigned short vendorId):
        self.setData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_VENDOR_ID), vendorId, OP_SIZE_WORD)
    cdef void setDeviceId(self, unsigned short deviceId):
        self.setData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_DEVICE_ID), deviceId, OP_SIZE_WORD)
    cdef void setClassDevice(self, unsigned short classDevice):
        self.setData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_CLASS_DEVICE), classDevice, OP_SIZE_WORD)
    cdef void setVendorDeviceId(self, unsigned short vendorId, unsigned short deviceId):
        self.setVendorId(vendorId)
        self.setDeviceId(deviceId)
    cdef void run(self):
        pass

cdef class PciBridge(PciDevice):
    def __init__(self, PciBus bus, Pci pci, object main, unsigned char deviceIndex):
        PciDevice.__init__(self, bus, pci, main, deviceIndex)
    cdef void setData(self, unsigned int mmAddress, unsigned int data, unsigned char dataSize):
        #cdef unsigned int addr, limit
        PciDevice.setData(self, mmAddress, data, dataSize)
        #if (((mmAddress&0xff) == PCI_BRIDGE_MEM_LIMIT and dataSize == 2) or ((mmAddress&0xff) == PCI_BRIDGE_MEM_BASE and dataSize == 4)):
        #    addr = <unsigned int>self.getData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_BRIDGE_MEM_BASE), OP_SIZE_WORD)<<16
        #    limit = <unsigned int>self.getData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_BRIDGE_MEM_LIMIT), OP_SIZE_WORD)<<16
        #    
    cdef void run(self):
        PciDevice.run(self)
        self.setVendorDeviceId(PCI_VENDOR_ID_INTEL, PCI_DEVICE_ID_INTEL_440FX)
        self.setClassDevice(PCI_CLASS_BRIDGE_HOST)
        self.setData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_PRIMARY_BUS), 0, OP_SIZE_BYTE)
        self.setData(self.getMmAddress(self.bus.busIndex, self.deviceIndex, 0, PCI_HEADER_TYPE), PCI_HEADER_TYPE_BRIDGE, OP_SIZE_BYTE)

cdef class PciBus:
    def __init__(self, Pci pci, object main, unsigned char busIndex):
        self.pci = pci
        self.main = main
        self.busIndex = busIndex
        self.deviceList = {0x00: PciBridge(self, self.pci, self.main, 0)}
    cdef PciDevice getDeviceByIndex(self, unsigned char index):
        cdef PciDevice deviceHandle
        deviceHandle = self.deviceList.get(index)
        if (deviceHandle):
            return deviceHandle
        return None
    cdef void run(self):
        cdef unsigned char deviceIndex
        cdef PciDevice deviceHandle
        cdef MmArea mmArea
        mmArea = (<Mm>self.main.mm).mmAddArea((PCI_MEM_BASE|(<unsigned int>self.busIndex<<20)), False)
        (<Mm>self.main.mm).mmMallocArea(mmArea, 0xff)
        for deviceIndex, deviceHandle in self.deviceList.items():
            if (deviceHandle):
                deviceHandle.run()
    ####



cdef class Pci:
    def __init__(self, object main):
        self.main = main
        self.pciReset = False
        self.address = self.elcr1 = self.elcr2 = 0
        self.busList = {0x00: PciBus(self, self.main, 0)}
    cdef PciDevice getDevice(self, unsigned char busIndex, unsigned char deviceIndex):
        cdef PciBus busHandle
        cdef PciDevice deviceHandle
        busHandle = self.busList.get(busIndex)
        if (busHandle):
            deviceHandle = busHandle.getDeviceByIndex(deviceIndex)
            if (deviceHandle):
                return deviceHandle
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


