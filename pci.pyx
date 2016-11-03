
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

include "globals.pxi"


cdef class PciAddress:
    def __init__(self, uint32_t address):
        self.calculateAddress(address)
    cdef uint32_t getMmAddress(self):
        #return (PCI_MEM_BASE | (self.bus<<PCI_BUS_SHIFT) | (self.device<<PCI_DEVICE_SHIFT) | (self.function<<PCI_FUNCTION_SHIFT) | self.register)
        #return ((self.function<<PCI_FUNCTION_SHIFT) | self.register)
        return self.register
    cdef void calculateAddress(self, uint32_t address):
        self.enableBit = (address>>31)
        self.bus = <uint8_t>(address>>PCI_BUS_SHIFT)
        self.device = (address>>PCI_DEVICE_SHIFT)&0x1f
        self.function = (address>>PCI_FUNCTION_SHIFT)&0x7
        self.register = <uint8_t>address

cdef class PciDevice:
    def __init__(self, PciBus bus, Pci pci, uint8_t deviceIndex):
        self.bus = bus
        self.pci = pci
        self.deviceIndex = deviceIndex
        for i in range(7):
            self.barSize[i] = 0
        self.configSpace = ConfigSpace(PCI_FUNCTION_CONFIG_SIZE, self.pci.main)
        self.configSpace.csWriteValue(PCI_HEADER_TYPE, PCI_HEADER_TYPE_STANDARD, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(PCI_COMMAND, 0x4, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(PCI_STATUS, 0x200, OP_SIZE_WORD)
    cdef void reset(self):
        pass
    cdef uint8_t checkWriteAccess(self, uint32_t mmAddress, uint32_t data, uint8_t dataSize) nogil: # return true means allowed
        cdef uint8_t offset, headerType, function, memBarType, barIndex
        cdef uint32_t origData
        offset = mmAddress&0xff
        function = (mmAddress >> PCI_FUNCTION_SHIFT) & 0x7
        if (function): # TODO
            if (self.pci.main.debugEnabled):
                self.pci.main.notice("PciDevice::checkWriteAccess: function (0x%02x) != 0x00", function)
            return False
        if (offset == PCI_COMMAND):
            headerType = self.getData(PCI_HEADER_TYPE, OP_SIZE_BYTE)
            function = 0
            headerType = 6 if (headerType == 0) else 2
            for barIndex in range(headerType):
                if (self.barSize[barIndex]):
                    with gil:
                        origData = self.configSpace.csReadValueUnsigned((mmAddress & <uint32_t>0xffffff00)+PCI_BASE_ADDRESS_0+(barIndex<<2), OP_SIZE_DWORD)
                    if (origData and ((origData & <uint32_t>0xfffffff0) != <uint32_t>0xfffffff0)):
                        if (origData & 1):
                            function |= 1
                        else:
                            function |= 2
            data &= 0x404
            data |= function
            with gil:
                self.configSpace.csWriteValue(mmAddress, data, OP_SIZE_WORD)
            return False
        elif (offset+dataSize > PCI_BASE_ADDRESS_0 and offset < PCI_BRIDGE_ROM_ADDRESS+OP_SIZE_DWORD):
            if (self.pci.main.debugEnabled and (offset & 3) != 0):
                self.pci.main.notice("PciDevice::checkWriteAccess: unaligned access!")
            barIndex = (offset - 0x10) >> 2
            headerType = self.getData(PCI_HEADER_TYPE, OP_SIZE_BYTE)
            if (headerType >= 0x02):
                if (self.pci.main.debugEnabled):
                    self.pci.main.notice("PciDevice::checkWriteAccess: headerType (0x%02x) >= 0x02", headerType)
                return True
            elif (headerType == 0x01):
                if (offset in (PCI_BRIDGE_IO_BASE_LOW, PCI_BRIDGE_IO_LIMIT_LOW, PCI_BRIDGE_PREF_MEM_BASE_LOW, PCI_BRIDGE_PREF_MEM_LIMIT_LOW, \
                  PCI_BRIDGE_PREF_MEM_BASE_HIGH, PCI_BRIDGE_PREF_MEM_LIMIT_HIGH, PCI_BRIDGE_IO_BASE_HIGH, PCI_BRIDGE_IO_LIMIT_HIGH)):
                    return False
                elif (offset >= PCI_BASE_ADDRESS_2 and offset != PCI_BRIDGE_ROM_ADDRESS):
                    return True
            if (offset >= PCI_BASE_ADDRESS_0 and offset <= PCI_BASE_ADDRESS_5):
                if (not self.barSize[barIndex]):
                    return False
                with gil:
                    origData = self.configSpace.csReadValueUnsigned(offset, OP_SIZE_DWORD)
                memBarType = (origData >> 1) & 0x3
                if (not (origData & 1) and memBarType != 0): #if (memBarType in (1, 2, 3)):
                    self.pci.main.exitError("PciDevice::checkWriteAccess: unsupported memBarType (%u)", memBarType)
                    return True
                #elif ((data & <uint32_t>0xfffffff0) == <uint32_t>0xfffffff0):
                #if ((data & <uint32_t>0xfffff800) == <uint32_t>0xfffff800):
                if ((data & <uint32_t>0xfffffff0) in (<uint32_t>0xfffffff0, <uint32_t>0xfff0)):
                    data = (BITMASK_DWORD & (~((1<<self.barSize[barIndex]) - 1)))
                    #data = (origData & (~((1<<self.barSize[barIndex]) - 1)))
                    #data = (origData & (~((1<<self.barSize[barIndex]) - 1)))>>self.barSize[barIndex]
                #data = (origData & (~((1<<self.barSize[barIndex]) - 1)))
                if (origData & 1):
                    #data &= ~3
                    #data |= origData & 3
                    data |= 1
                #else:
                #    data &= ~7
                #    data |= origData & 7
            elif ((not headerType and offset == PCI_ROM_ADDRESS) or (headerType == 1 and offset == PCI_BRIDGE_ROM_ADDRESS)):
                barIndex = 6
                if (not self.barSize[barIndex]):
                    return False
                with gil:
                    origData = self.configSpace.csReadValueUnsigned(offset, OP_SIZE_DWORD)
                if ((data & <uint32_t>0xfffff800) == <uint32_t>0xfffff800):
                    data = (BITMASK_DWORD & (~((1<<self.barSize[barIndex]) - 1))) # TODO: is this correct?
                    #data = (origData & (~((1<<self.barSize[barIndex]) - 1)))
                    #data = (origData & (~((1<<self.barSize[barIndex]) - 1)))>>self.barSize[barIndex]
                #data = (origData & (~((1<<self.barSize[barIndex]) - 1)))
            with gil:
                self.configSpace.csWriteValue(mmAddress, data, OP_SIZE_DWORD)
            return False
        return True
    cdef uint32_t getData(self, uint32_t mmAddress, uint8_t dataSize) nogil:
        cdef uint32_t data
        with gil:
            data = self.configSpace.csReadValueUnsigned(mmAddress, dataSize)
        IF COMP_DEBUG:
            self.pci.main.notice("PciDevice::getData: mmAddress==0x%08x; data==0x%08x; dataSize==%u", mmAddress, data, dataSize)
        return data
    cdef void setData(self, uint32_t mmAddress, uint32_t data, uint8_t dataSize) nogil:
        if (not self.checkWriteAccess(mmAddress, data, dataSize)):
            IF COMP_DEBUG:
                self.pci.main.notice("PciDevice::setData: check says false: mmAddress==0x%08x; data==0x%08x; dataSize==%u", mmAddress, data, dataSize)
            return
        IF COMP_DEBUG:
            self.pci.main.notice("PciDevice::setData: check says true: mmAddress==0x%08x; data==0x%08x; dataSize==%u", mmAddress, data, dataSize)
        with gil:
            self.configSpace.csWriteValue(mmAddress, data, dataSize)
    cdef void setVendorId(self, uint16_t vendorId):
        self.setData(PCI_VENDOR_ID, vendorId, OP_SIZE_WORD)
    cdef void setDeviceId(self, uint16_t deviceId):
        self.setData(PCI_DEVICE_ID, deviceId, OP_SIZE_WORD)
    cdef void setDeviceClass(self, uint16_t deviceClass):
        self.setData(PCI_DEVICE_CLASS, deviceClass, OP_SIZE_WORD)
    cdef void setVendorDeviceId(self, uint16_t vendorId, uint16_t deviceId):
        self.setVendorId(vendorId)
        self.setDeviceId(deviceId)
    cdef void setBarSize(self, uint8_t barIndex, uint8_t barSize):
        self.barSize[barIndex] = barSize
    cdef void run(self):
        pass

cdef class PciBridge(PciDevice):
    def __init__(self, PciBus bus, Pci pci, uint8_t deviceIndex):
        PciDevice.__init__(self, bus, pci, deviceIndex)
        self.setVendorDeviceId(PCI_VENDOR_ID_INTEL, PCI_DEVICE_ID_INTEL_440FX)
        self.setDeviceClass(PCI_CLASS_BRIDGE_HOST)
        self.configSpace.csWriteValue(PCI_COMMAND, 0x6, OP_SIZE_WORD)
        self.configSpace.csWriteValue(PCI_STATUS, 0x280, OP_SIZE_WORD)
    cdef void setData(self, uint32_t mmAddress, uint32_t data, uint8_t dataSize) nogil:
        #cdef uint32_t addr, limit
        PciDevice.setData(self, mmAddress, data, dataSize)
        #if (((mmAddress&0xff) == PCI_BRIDGE_MEM_LIMIT and dataSize == 2) or ((mmAddress&0xff) == PCI_BRIDGE_MEM_BASE and dataSize == 4)):
        #    addr = <uint32_t>self.getData(PCI_BRIDGE_MEM_BASE, OP_SIZE_WORD)<<16
        #    limit = <uint32_t>self.getData(PCI_BRIDGE_MEM_LIMIT, OP_SIZE_WORD)<<16
        #    
    cdef void run(self):
        PciDevice.run(self)

cdef class Pci2Isa(PciDevice):
    def __init__(self, PciBus bus, Pci pci, uint8_t deviceIndex):
        cdef uint8_t i, j
        for i in range(16):
            self.irqRegistry[i] = 0
            for j in range(4):
                self.irqLevel[j][i] = 0
        PciDevice.__init__(self, bus, pci, deviceIndex)
        self.setVendorDeviceId(PCI_VENDOR_ID_INTEL, 0x7000)
        self.setDeviceClass(PCI_CLASS_BRIDGE_ISA)
        self.configSpace.csWriteValue(PCI_COMMAND, 0x7, OP_SIZE_WORD)
        self.configSpace.csWriteValue(PCI_STATUS, 0x200, OP_SIZE_WORD)
        self.configSpace.csWriteValue(PCI_HEADER_TYPE, 0x80, OP_SIZE_BYTE)
        self.reset()
    cdef void reset(self):
        cdef uint8_t i
        PciDevice.reset(self)
        self.configSpace.csWriteValue(0x05, 0x00, OP_SIZE_WORD)
        self.configSpace.csWriteValue(0x07, 0x02, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0x4c, 0x4d, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0x4e, 0x03, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0x4f, 0x00, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0x69, 0x02, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0x70, 0x80, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0x76, 0x0c, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0x77, 0x0c, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0x78, 0x02, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0x79, 0x00, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0x80, 0x00, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0x82, 0x00, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0xa0, 0x08, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0xa2, 0x00, OP_SIZE_WORD)
        self.configSpace.csWriteValue(0xa4, 0x00, OP_SIZE_DWORD)
        self.configSpace.csWriteValue(0xa8, 0x0f, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0xaa, 0x00, OP_SIZE_WORD)
        self.configSpace.csWriteValue(0xac, 0x00, OP_SIZE_BYTE)
        self.configSpace.csWriteValue(0xae, 0x00, OP_SIZE_BYTE)
        for i in range(4):
            #pci_set_irq(0x08, i+1, 0);
            self.pciUnregisterIrq(i, 0x80)
    cdef void pciRegisterIrq(self, uint8_t pirq, uint8_t irq) nogil:
        if ((irq < 16) and (((1 << irq) & 0xdef8) != 0)):
            if (PciDevice.getData(self, 0x60+pirq, OP_SIZE_BYTE) < 16):
                self.pciUnregisterIrq(pirq, irq)
            PciDevice.setData(self, 0x60+pirq, irq, OP_SIZE_BYTE)
            if (not (self.irqRegistry[irq])):
                pass
                #DEV_register_irq(irq, "PIIX3 IRQ routing");
            self.irqRegistry[irq] |= (1 << pirq)
    cdef void pciUnregisterIrq(self, uint8_t pirq, uint8_t irq) nogil:
        cdef uint8_t oldData = PciDevice.getData(self, 0x60+pirq, OP_SIZE_BYTE)
        if (oldData < 16):
            self.irqRegistry[oldData] &= ~(1 << pirq)
            if (not self.irqRegistry[oldData]):
                pass
                #BX_P2I_THIS pci_set_irq(0x08, pirq+1, 0);
                #DEV_unregister_irq(oldirq, "PIIX3 IRQ routing");
            PciDevice.setData(self, 0x60+pirq, irq, OP_SIZE_BYTE)
    cdef void setData(self, uint32_t mmAddress, uint32_t data, uint8_t dataSize) nogil:
        cdef uint32_t oldData
        if (mmAddress == 0x6 or (mmAddress >= 0x10 and mmAddress < 0x34)):
            return
        oldData = PciDevice.getData(self, mmAddress, dataSize)
        PciDevice.setData(self, mmAddress, data, dataSize)
        if (0x4 >= mmAddress and 0x4 < (mmAddress+dataSize)):
            data = PciDevice.getData(self, 0x4, OP_SIZE_BYTE)
            PciDevice.setData(self, 0x4, (data & 0x8) | 7, dataSize)
        if (0x5 >= mmAddress and 0x5 < (mmAddress+dataSize)):
            data = PciDevice.getData(self, 0x5, OP_SIZE_BYTE)
            PciDevice.setData(self, 0x5, data & 1, dataSize)
        if (0x7 >= mmAddress and 0x7 < (mmAddress+dataSize)):
            data = PciDevice.getData(self, 0x7, OP_SIZE_BYTE)
            PciDevice.setData(self, 0x7, (oldData & (~(data & 0x78))) | 2, dataSize)
        if (0x4e >= mmAddress and 0x4e < (mmAddress+dataSize)):
            data = PciDevice.getData(self, 0x4e, OP_SIZE_BYTE)
            if ((data & 0x4) != (oldData & 0x4)):
                pass
                #DEV_mem_set_bios_write((value8 & 0x04) != 0);
        if (0x4f >= mmAddress and 0x4f < (mmAddress+dataSize)):
            data = PciDevice.getData(self, 0x4f, OP_SIZE_BYTE)
            PciDevice.setData(self, 0x4f, data & 1, dataSize)
        if (0x60 >= mmAddress and 0x60 < (mmAddress+dataSize)):
            data &= 0x8f
            if (data != oldData):
                if (data >= 0x80):
                    self.pciUnregisterIrq(0, data)
                else:
                    self.pciRegisterIrq(0, data)
        if (0x61 >= mmAddress and 0x61 < (mmAddress+dataSize)):
            data &= 0x8f
            if (data != oldData):
                if (data >= 0x80):
                    self.pciUnregisterIrq(1, data)
                else:
                    self.pciRegisterIrq(1, data)
        if (0x62 >= mmAddress and 0x62 < (mmAddress+dataSize)):
            data &= 0x8f
            if (data != oldData):
                if (data >= 0x80):
                    self.pciUnregisterIrq(2, data)
                else:
                    self.pciRegisterIrq(2, data)
        if (0x63 >= mmAddress and 0x63 < (mmAddress+dataSize)):
            data &= 0x8f
            if (data != oldData):
                if (data >= 0x80):
                    self.pciUnregisterIrq(3, data)
                else:
                    self.pciRegisterIrq(3, data)
        if (0x6a >= mmAddress and 0x6a < (mmAddress+dataSize)):
            data = PciDevice.getData(self, 0x6a, OP_SIZE_BYTE)
            PciDevice.setData(self, 0x6a, data & 0xd7, dataSize)
        if (0x80 >= mmAddress and 0x80 < (mmAddress+dataSize)):
            data = PciDevice.getData(self, 0x80, OP_SIZE_BYTE)
            PciDevice.setData(self, 0x80, data & 0x7f, dataSize)
    cdef void run(self):
        PciDevice.run(self)

cdef class PciBus:
    def __init__(self, Pci pci, uint8_t busIndex):
        self.pci = pci
        self.busIndex = busIndex
        self.deviceList = [PciBridge(self, self.pci, 0)]
        #self.deviceList = [PciBridge(self, self.pci, 0), Pci2Isa(self, self.pci, 1)]
    cdef PciDevice addDevice(self):
        cdef PciDevice pciDevice
        cdef uint8_t deviceLength = len(self.deviceList)
        pciDevice = PciDevice(self, self.pci, deviceLength)
        pciDevice.run()
        self.deviceList.append(pciDevice)
        return pciDevice
    cdef PciDevice getDeviceByIndex(self, uint8_t deviceIndex):
        cdef PciDevice deviceHandle
        cdef uint8_t deviceLength = len(self.deviceList)
        if (deviceIndex < deviceLength):
            deviceHandle = self.deviceList[deviceIndex]
            if (deviceHandle is not None):
                return deviceHandle
        return None
    cdef void run(self):
        cdef PciDevice deviceHandle
        for deviceHandle in self.deviceList:
            if (deviceHandle is not None):
                deviceHandle.run()
    ####



cdef class Pci:
    def __init__(self, Hirnwichse main):
        self.main = main
        self.pciReset = False
        self.address = self.elcr1 = self.elcr2 = 0
        self.busList = [PciBus(self, 0)]
    cdef PciDevice addDevice(self):
        cdef PciBus pciBus
        cdef PciDevice pciDevice
        pciBus = self.busList[0]
        pciDevice = pciBus.addDevice()
        return pciDevice
    cdef PciDevice getDevice(self, uint8_t busIndex, uint8_t deviceIndex):
        cdef PciBus busHandle
        cdef PciDevice deviceHandle
        cdef uint8_t busLength = len(self.busList)
        if (busIndex < busLength):
            busHandle = self.busList[busIndex]
            if (busHandle is not None):
                deviceHandle = busHandle.getDeviceByIndex(deviceIndex)
                if (deviceHandle is not None):
                    return deviceHandle
        return None
    cdef uint32_t readRegister(self, uint32_t address, uint8_t dataSize):
        cdef PciDevice deviceHandle
        cdef PciAddress pciAddressHandle
        cdef uint32_t bitMask
        pciAddressHandle = PciAddress(address)
        deviceHandle = self.getDevice(pciAddressHandle.bus, pciAddressHandle.device)
        if (deviceHandle):
            if (not pciAddressHandle.enableBit or pciAddressHandle.function):
                self.main.notice("Pci::readRegister: Warning: tried to read without enableBit or with function set.")
            else:
                return deviceHandle.getData(pciAddressHandle.getMmAddress(), dataSize)
        else:
            if (self.main.debugEnabled):
                self.main.notice("Pci::readRegister: deviceHandle is NULL")
        bitMask = BITMASKS_FF[dataSize]
        return bitMask
    cdef void writeRegister(self, uint32_t address, uint32_t data, uint8_t dataSize):
        cdef PciDevice deviceHandle
        cdef PciAddress pciAddressHandle
        pciAddressHandle = PciAddress(address)
        deviceHandle = self.getDevice(pciAddressHandle.bus, pciAddressHandle.device)
        if (deviceHandle):
            if (not pciAddressHandle.enableBit or pciAddressHandle.function):
                self.main.notice("Pci::writeRegister: Warning: tried to write without enableBit or with function set.")
            else:
                deviceHandle.setData(pciAddressHandle.getMmAddress(), data, dataSize)
                if (deviceHandle == self.main.platform.ata.pciDevice):
                    if ((address&BITMASK_BYTE) >= PCI_BASE_ADDRESS_4 and ((address&BITMASK_BYTE)+dataSize) <= (PCI_BASE_ADDRESS_4+OP_SIZE_DWORD)):
                    #if (PCI_BASE_ADDRESS_4 in range(address, dataSize)):
                    #IF 1:
                        #if (self.getData(PCI_DEVICE_CLASS, OP_SIZE_WORD) == PCI_CLASS_PATA):
                        IF 1:
                            #self.main.notice("Pci::writeRegister: test1")
                            self.main.platform.ata.base4Addr = deviceHandle.getData((pciAddressHandle.getMmAddress()&<uint32_t>0xffffff00)|PCI_BASE_ADDRESS_4, OP_SIZE_DWORD)
                            #self.main.notice("Pci::writeRegister: test2")
    cdef uint32_t inPort(self, uint16_t ioPortAddr, uint8_t dataSize) nogil:
        cdef uint32_t ret = BITMASK_DWORD
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
                with gil:
                    ret = self.readRegister((self.address&<uint32_t>0xfffffffc)+(ioPortAddr&3), dataSize)
            else:
                self.main.exitError("PCI::inPort: port 0x%04x is not supported. (dataSize %u)", ioPortAddr, dataSize)
        else:
            self.main.exitError("PCI::inPort: port 0x%04x with dataSize %u not supported.", ioPortAddr, dataSize)
        if (self.main.debugEnabled):
            self.main.notice("PCI::inPort: port 0x%04x. (dataSize %u; ret 0x%04x)", ioPortAddr, dataSize, ret)
        return ret
    cdef void outPort(self, uint16_t ioPortAddr, uint32_t data, uint8_t dataSize) nogil:
        if (self.main.debugEnabled):
            self.main.notice("PCI::outPort: port 0x%04x. (dataSize %u; data 0x%04x)", ioPortAddr, dataSize, data)
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
                    with gil:
                        if (self.pciReset):
                            self.main.reset(True)
                        else:
                            self.main.reset(False)
            elif (ioPortAddr in (0xcfc, 0xcfd, 0xcfe, 0xcff)):
                with gil:
                    self.writeRegister((self.address&<uint32_t>0xfffffffc)+(ioPortAddr&3), data, dataSize)
            else:
                self.main.exitError("PCI::outPort: port 0x%04x is not supported. (data == 0x%02x, dataSize %u)", ioPortAddr, data, dataSize)
        else:
            self.main.exitError("PCI::outPort: dataSize %u not supported.", dataSize)
        return
    cdef void run(self):
        cdef uint8_t busIndex
        cdef PciBus busHandle
        for busHandle in self.busList:
            if (busHandle):
                busHandle.run()


