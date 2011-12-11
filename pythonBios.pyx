import misc, registers, vga

include "globals.pxi"

DISKETTE_RET_STATUS_ADDR = 0x441 # byte


cdef class PythonBios:
    cpdef public object main, cpu, registers
    def __init__(self, object main):
        self.main = main
    cpdef interrupt(self, unsigned char intNum):
        cdef unsigned long memAddr, logicalSector, i
        cdef unsigned short ax, cx, dx, bx, bp, count, cylinder, cursorPos
        cdef unsigned char currMode, ah, al, bh, bl, dh, dl, fdcNum, updateCursor, c, attr, attrInBuf, sector, head
        cdef bytes data
        ax = self.registers.regRead(CPU_REGISTER_AX, False)
        cx = self.registers.regRead(CPU_REGISTER_CX, False)
        dx = self.registers.regRead(CPU_REGISTER_DX, False)
        bx = self.registers.regRead(CPU_REGISTER_BX, False)
        bp = self.registers.regRead(CPU_REGISTER_BP, False)
        ah, al = ax>>8, ax&0xff
        ch, cl = cx>>8, cx&0xff
        dh, dl = dx>>8, dx&0xff
        bh, bl = bx>>8, bx&0xff
        if (intNum == 0x10): # video; TODO
            #return False
            currMode = self.main.mm.mmPhyReadValue(vga.VGA_CURRENT_MODE_ADDR, 1, False)
            if (ah == 0x02): # set cursor position
                self.main.platform.vga.setCursorPosition(bh, dx)
            elif (ah == 0x0f): # get currMode; write it to AL
                self.registers.regWrite(CPU_REGISTER_AL, currMode)
            elif (currMode <= 0x7 or currMode in (0x12, 0x13)):
                #self.main.printMsg("PythonBios::interrupt: int 0x10: AX: {0:#06x} (currMode: {1:d})", ax, currMode)
                if (ah in (0x09, 0x0a, 0x0e)): # AH in (0x09, 0x0A, 0x0E) / PRINT CHARACTER
                    if (currMode in (0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x12, 0x13)):
                        count = 1
                        if (ah in (0x09, 0x0a)):
                            count = cx
                        for i in range(count):
                            if ((currMode in (0x4, 0x5, 0x6, 0x12, 0x13)) and (ah in (0x09, 0x0e))):
                                self.main.platform.vga.writeCharacterTeletype(al, bl, 0xff, ah==0x0e) # page 0xff == current page
                            else:
                                self.main.platform.vga.writeCharacterTeletype(al, -1, 0xff, ah==0x0e) # page 0xff == current page
                            cursorPos = self.main.platform.vga.getCursorPosition(bh)
                            if (ax == 0x0e0a and (cursorPos>>8) > 24):
                                self.main.platform.vga.scrollDown(bh)
                                #self.main.printMsg("PythonBios::interrupt: int 0x10: ax==0x0e0a, cursorPos=={0:#06x}", cursorPos)
                                self.main.platform.vga.setCursorPosition(bh, cursorPos-0x100)
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
                        self.main.platform.vga.setCursorPosition(bh, dx)
                        if (attrInBuf):
                            count *= 2
                        data = self.main.mm.mmRead(bp, count, CPU_SEGMENT_ES, False)
                        for i in range(0, count, attrInBuf+1):
                            c = data[i]
                            if (attrInBuf):
                                attr = data[i+1]
                            self.main.platform.vga.writeCharacterTeletype(c, attr, bh, True)
                            cursorPos = self.main.platform.vga.getCursorPosition(bh)
                            if (c == 0x0a and (cursorPos>>8) > 24):
                                self.main.platform.vga.scrollDown(bh)
                                self.main.platform.vga.setCursorPosition(bh, cursorPos-0x100)
                        if (not updateCursor):
                            self.main.platform.vga.setCursorPosition(bh, dx)
                        return True
                    else:
                        self.main.printMsg("PythonBios::interrupt: int: 0x10 AH: 0x13: currMode {0:d} not supported here. (ax: {1:#06x})", currMode, ax)
                        return False
                else: # AH
                    self.main.printMsg("PythonBios::interrupt: int: 0x10: AX {0:#06x} is not supported here. (currMode: {1:d})", ax, currMode)
                    return False
            else:
                self.main.printMsg("PythonBios::interrupt: int: 0x10: currMode {0:d} not supported here. (ax: {1:#06x})", currMode, ax)
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
                    self.main.printMsg("PythonBios::interrupt: cl-bits #6 and/or #7 are set, but floppy was selected.")
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
                ##self.main.printMsg("pythonBios: 1234_1: logicalSector: {0:d}, count: {1:d}, dataLen: {2:d}", logicalSector, count, len(data))
                self.main.mm.mmPhyWrite(memAddr, data, count*512)
                self.setRetError(False, al)
                return True
            elif (not (dl & 0x80)):
                self.main.printMsg("PythonBios::interrupt: intNum 0x13 (floppy) ax {0:#06x} not supported yet in PythonBIOS.", ax)
        return False
    cdef setRetError(self, unsigned char newCF, unsigned short ax): # for use with floppy
        self.registers.setEFLAG( FLAG_CF, newCF )
        self.registers.regWrite( CPU_REGISTER_AX, ax )
        self.main.mm.mmPhyWriteValue(DISKETTE_RET_STATUS_ADDR, ax>>8, OP_SIZE_BYTE)
    cpdef run(self):
        self.cpu = self.main.cpu
        self.registers = self.cpu.registers


