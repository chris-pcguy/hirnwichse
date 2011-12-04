import misc, registers, vga

include "globals.pxi"

DISKETTE_RET_STATUS_ADDR = 0x441 # byte


cdef class PythonBios:
    cpdef public object main, cpu, registers
    def __init__(self, object main):
        self.main = main
    cpdef interrupt(self, unsigned char intNum):
        cdef unsigned long memAddr, logicalSector
        cdef unsigned short ax, cx, dx, bx, bp, count, cylinder
        cdef unsigned char currMode, ah, al, bh, bl, dh, dl, fdcNum, updateCursor, c, attr, attrInBuf, sector, head
        cdef bytes data
        cdef tuple cursorPos
        ax = self.registers.regRead(CPU_REGISTER_AX, False)
        cx = self.registers.regRead(CPU_REGISTER_CX, False)
        dx = self.registers.regRead(CPU_REGISTER_DX, False)
        bx = self.registers.regRead(CPU_REGISTER_BX, False)
        bp = self.registers.regRead(CPU_REGISTER_BP, False)
        ah, al = ax>>8, ax&0xff
        ch, cl = cx>>8, cx&0xff
        dh, dl = dx>>8, dx&0xff
        bh, bl = bx>>8, bx&0xff
        if (intNum == 0x10): # video
            currMode = self.main.mm.mmPhyReadValue(vga.VGA_CURRENT_MODE_ADDR, 1, False)
            if (currMode <= 0x7 or currMode in (0x12, 0x13)):
                if (ah == 0x0e): # AH == 0x0E
                    if (currMode in (0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x12, 0x13)):
                        ##if (currMode not in (0x4, 0x5, 0x6) and bl == 0):
                        ##    bl = 0x07
                        if (currMode in (0x4, 0x5, 0x6, 0x12, 0x13)):
                            self.main.platform.vga.writeCharacterTeletype(al, bl, 0xff) # page 0xff == current page
                        else:
                            self.main.platform.vga.writeCharacterTeletype(al, -1, 0xff) # page 0xff == current page
                        cursorPos = self.main.platform.vga.getCursorPosition(bh)
                        if (al == 0x0a and cursorPos[1] > 24):
                            self.main.platform.vga.scrollDown(bh)
                            self.main.platform.vga.setCursorPosition(bh, cursorPos[0], cursorPos[1]-1)
                        return True
                    else:
                        self.main.printMsg("PythonBios::interrupt: int: 0x10 AH: 0x0e: currMode {0:d} not supported here. (ax: {1:#04x})", currMode, ax)
                        return False
                elif (ah == 0x13): # AH == 0x13
                    if (currMode in (0x0, 0x1, 0x2, 0x3, 0x7)):
                        updateCursor = al in (0x1, 0x3)
                        attrInBuf = al in (0x2, 0x3)
                        count = cx
                        attr = bl
                        self.main.platform.vga.setCursorPosition(bh, dl, dh)
                        if (attrInBuf):
                            count *= 2
                        data = self.main.mm.mmRead(bp, count, CPU_SEGMENT_ES, False)
                        for i in range(0, count, attrInBuf+1):
                            c = data[i]
                            if (attrInBuf):
                                attr = data[i+1]
                            self.main.platform.vga.writeCharacterTeletype(c, attr, bh)
                            cursorPos = self.main.platform.vga.getCursorPosition(bh)
                            if (c == 0x0a and cursorPos[1] > 24):
                                self.main.platform.vga.scrollDown(bh)
                                self.main.platform.vga.setCursorPosition(bh, cursorPos[0], cursorPos[1]-1)
                        if (not updateCursor):
                            self.main.platform.vga.setCursorPosition(bh, dl, dh)
                        return True
                    else:
                        self.main.printMsg("PythonBios::interrupt: int: 0x10 AH: 0x13: currMode {0:d} not supported here. (ax: {1:#04x})", currMode, ax)
                        return False
                else: # AH
                    return False
            else:
                self.main.printMsg("PythonBios::interrupt: int: 0x10: currMode {0:d} not supported here. (ax: {1:#04x})", currMode, ax)
                return False
        elif (intNum == 0x13): # data storage; floppy
            fdcNum = 0
            #self.main.printMsg("PythonBios::interrupt: intNum 0x13 (floppy) AX {0:#06x} not supported yet in PythonBIOS.", ax)
            #return False
            if (dl not in (0, 1) or (not self.main.platform.floppy.controller[fdcNum].drive[dl].isLoaded)):
                self.setRetError(True, 0x8000)
                return True
            elif (ah == 0x2):
                if ( ((cl >> 6)&3 != 0) and (dl in (0, 1)) ):
                    self.main.printMsg("PythonBios::interrupt: floppy was selected, but cl-bits #6 and/or #7 are set.")
                    return False
                cylinder = (((cl>>6)&3)<<8)|ch
                head = dh
                sector = cl&0x3f
                count = al
                if (dl > 1 or head > 1 or sector == 0 or count == 0 or count > 72):
                    self.setRetError(True, 0x100)
                    return True
                memAddr = self.registers.segRead(CPU_SEGMENT_ES)<<4
                memAddr += bx
                logicalSector = self.main.platform.floppy.controller[fdcNum].drive[dl].ChsToSector(cylinder, head, sector)
                data = self.main.platform.floppy.controller[fdcNum].drive[dl].readSectors(logicalSector, count)
                self.main.printMsg("pythonBios: 1234_1: logicalSector: {0:d}, count: {1:d}, dataLen: {2:d}", logicalSector, count, len(data))
                self.main.mm.mmPhyWrite(memAddr, data, count*512)
                self.setRetError(False, al)
                return True
            elif (not (dl & 0x80)):
                self.main.printMsg("PythonBios::interrupt: intNum 0x13 (floppy) ah {0:#04x} not supported yet in PythonBIOS.", ah)
        return False
    cdef setRetError(self, unsigned char newCF, unsigned short ax): # for use with floppy
        self.registers.setEFLAG( FLAG_CF, newCF )
        self.registers.regWrite( CPU_REGISTER_AX, ax )
        self.main.mm.mmPhyWriteValue(DISKETTE_RET_STATUS_ADDR, ax>>8, OP_SIZE_BYTE)
    cpdef run(self):
        self.cpu = self.main.cpu
        self.registers = self.cpu.registers


