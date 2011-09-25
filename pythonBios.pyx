import misc, registers, vga


cdef class PythonBios:
    cdef public object main, cpu, registers
    def __init__(self, object main):
        self.main = main
    def interrupt(self, unsigned char intNum):
        cdef unsigned long vgaAddr, logicalSector
        cdef unsigned short ax, cx, dx, bx, bp, count, cylinder
        cdef unsigned char currMode, ah, al, bh, bl, dh, dl, updateCursor, c, attr, attrInBuf, sector, head
        cdef bytes data
        ax = self.registers.regRead(registers.CPU_REGISTER_AX)
        cx = self.registers.regRead(registers.CPU_REGISTER_CX)
        dx = self.registers.regRead(registers.CPU_REGISTER_DX)
        bx = self.registers.regRead(registers.CPU_REGISTER_BX)
        bp = self.registers.regRead(registers.CPU_REGISTER_BP)
        ah, al = ax>>8, ax&0xff
        ch, cl = cx>>8, cx&0xff
        dh, dl = dx>>8, dx&0xff
        bh, bl = bx>>8, bx&0xff
        if (intNum == 0x10): # video
            currMode = self.main.mm.mmPhyReadValue(vga.VGA_CURRENT_MODE_ADDR, 1)
            if (currMode <= 0x7):
                if (ah == 0x0e): # AH == 0x0E
                    if (currMode not in (0x4, 0x5, 0x6) and bl == 0):
                        bl = 0x07
                    self.main.platform.vga.writeCharacterTeletype(al, bl, bh, updateCursor=True)
                    return True
                elif (ah == 0x13): # AH == 0x13
                    if (currMode in (0x0, 0x1, 0x2, 0x3, 0x7)):
                        updateCursor = al in (0x1, 0x3)
                        attrInBuf = al in (0x2, 0x3)
                        count = cx
                        attr = bl
                        self.setCursorPosition(bh, dl, dh)
                        if (attrInBuf):
                            count *= 2
                        data = self.main.mm.mmRead(bp, count, segId=registers.CPU_SEGMENT_ES, allowOverride=False)
                        for i in range(0, count, attrInBuf+1):
                            c = data[i]
                            if (attrInBuf):
                                attr = data[i+1]
                            self.main.platform.vga.writeCharacterTeletype(c, attr, bh, updateCursor=True)
                        if (not updateCursor):
                            self.setCursorPosition(bh, dl, dh)
                        return True
            else:
                self.main.printMsg("PythonBios::interrupt: currMode {0:d} not supported yet.", currMode)
        elif (intNum == 0x13): # data storage; floppy
            ##self.main.printMsg("PythonBios::interrupt: intNum: {0:#04x}, ax: {1:#06x}", intNum, ax)
            if (ah == 0x2):
                if (dl not in (0x0,0x1)):
                    self.setError(0x80)
                    return False
                if ( ((cl >> 6)&3 != 0) and (dl in (0, 1)) ):
                    self.main.printMsg("PythonBios::interrupt: floppy was selected, but cl-bits #6 and/or #7 are set.")
                    return False
                cylinder = ((cl>>6)&3)|ch
                head = dh
                sector = cl&0x3f
                count = al
                logicalSector = self.main.platform.floppy.ChsToSector(cylinder, head, sector)
                if (logicalSector >= 2800 or count == 0):
                    self.setError(0x10)
                    return False
                data = self.main.platform.floppy.floppy[dl].readSectors(logicalSector, count)
                self.main.mm.mmWrite(bx, data, count*512, segId=registers.CPU_SEGMENT_ES, allowOverride=False)
                self.setError(0)
                self.main.platform.floppy.setMsr(0xc0)
                self.main.platform.floppy.raiseFloppyIrq()
                return True
        return False
    def setError(self, unsigned char errorCode):
        self.registers.setEFLAG( registers.FLAG_CF, errorCode!=0 )
        self.registers.regWrite( registers.CPU_REGISTER_AH, errorCode )
    def run(self):
        self.cpu = self.main.cpu
        self.registers = self.cpu.registers
        pass




