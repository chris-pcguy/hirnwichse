
from mm cimport Mm
from registers cimport Registers
from vga cimport Vga
from floppy cimport Floppy, FloppyController, FloppyDrive

include "globals.pxi"

DEF DISKETTE_RET_STATUS_ADDR = 0x441 # byte


cdef class PythonBios:
    def __init__(self, object main):
        self.main = main
    cpdef interrupt(self, unsigned char intNum):
        cdef unsigned long memAddr, logicalSector
        cdef unsigned short ax, cx, dx, bx, bp, i, count, cylinder, cursorPos
        cdef unsigned char currMode, ah, al, bh, bl, dh, dl, fdcNum, updateCursor, c, attr, attrInBuf, sector, head
        cdef bytes data
        #return False
        ax = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_AX, False)
        cx = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_CX, False)
        dx = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_DX, False)
        bx = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_BX, False)
        bp = (<Registers>self.main.cpu.registers).regRead(CPU_REGISTER_BP, False)
        ah, al = ax>>8, ax&0xff
        ch, cl = cx>>8, cx&0xff
        dh, dl = dx>>8, dx&0xff
        bh, bl = bx>>8, bx&0xff
        if (intNum == 0x10): # video; TODO: REWORK THIS AND THE VGA MODULE TOO!!!
            #return False
            currMode = (<Mm>self.main.mm).mmPhyReadValueUnsigned(VGA_CURRENT_MODE_ADDR, 1)
            self.main.debug("PythonBios::videoFuncs: ax: {0:#06x}, currMode: {1:#04x}", ax, currMode)
            if (ah == 0x02): # set cursor position
                (<Vga>self.main.platform.vga).setCursorPosition(bh, dx)
                return True
            elif (ah == 0x03): # get cursor position
                dx = (<Vga>self.main.platform.vga).getCursorPosition(bh)
                cx = (<Mm>self.main.mm).mmPhyReadValueUnsigned(VGA_CURRENT_CURSOR_TYPE_ADDR, 2)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_DX, dx)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_CX, cx)
                return True
            elif (ah == 0x0f): # get currMode; write it to AL
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AL, currMode)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AH, 80)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_BH, (<Vga>self.main.platform.vga).getCorrectPage(0xff))
                return True
            elif (currMode <= 0x7 or currMode in (0x12, 0x13)):
                if (ah in (0x09, 0x0a, 0x0e)): # AH in (0x09, 0x0A, 0x0E) / PRINT CHARACTER
                    #if (currMode in (0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x12, 0x13)):
                    if (currMode in (0x0, 0x1, 0x2, 0x3, 0x7, 0x12, 0x13)):
                        count = 1
                        if (ah in (0x09, 0x0a)):
                            count = cx
                        elif (ah == 0x0e):
                            bh = 0xff # according to vgabios, AH:0x0e must print on the current page (0xff)!!
                        for i in range(count):
                            # ah==0x09: bl for textmode/graphicsmode;; ah==0x0e: bl for textmode
                            if (currMode in (0x00, 0x01, 0x02, 0x03, 0x07) and ah == 0x09):
                                (<Vga>self.main.platform.vga).writeCharacterTeletype(al, bl, bh, ah==0x0e)
                            else:
                                (<Vga>self.main.platform.vga).writeCharacterTeletype(al, -1, bh, ah==0x0e)
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
                        (<Vga>self.main.platform.vga).setCursorPosition(bh, dx)
                        if (attrInBuf):
                            count *= 2
                        data = (<Registers>self.main.cpu.registers).mmRead(bp, count, CPU_SEGMENT_ES, False)
                        for i in range(0, count, attrInBuf+1):
                            c = data[i]
                            if (attrInBuf):
                                attr = data[i+1]
                            (<Vga>self.main.platform.vga).writeCharacterTeletype(c, attr, bh, True)
                        if (not updateCursor):
                            (<Vga>self.main.platform.vga).setCursorPosition(bh, dx)
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
            if (dl not in (0, 1) or (not (<FloppyDrive>(<FloppyController>(<Floppy>self.main.platform.floppy).controller[fdcNum]).drive[dl]).isLoaded)):
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
                memAddr = (<Registers>self.main.cpu.registers).segRead(CPU_SEGMENT_ES)<<4
                memAddr += bx
                logicalSector = (<FloppyDrive>(<FloppyController>(<Floppy>self.main.platform.floppy).controller[fdcNum]).drive[dl]).ChsToSector(cylinder, head, sector)
                data = (<FloppyDrive>(<FloppyController>(<Floppy>self.main.platform.floppy).controller[fdcNum]).drive[dl]).readSectors(logicalSector, count)
                (<Mm>self.main.mm).mmPhyWrite(memAddr, data, count*512)
                self.setRetError(False, al)
                return True
            elif (ah == 0x8):
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_DH, \
                (<FloppyDrive>(<FloppyController>(<Floppy>self.main.platform.floppy).controller[fdcNum]).drive[dl]).media.heads)
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_CX, \
                ((<FloppyDrive>(<FloppyController>(<Floppy>self.main.platform.floppy).controller[fdcNum]).drive[dl]).media.tracks<<8) | \
                ((<FloppyDrive>(<FloppyController>(<Floppy>self.main.platform.floppy).controller[fdcNum]).drive[dl]).media.sectors))
                (<Registers>self.main.cpu.registers).regWrite(CPU_REGISTER_AL, 0)
                (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, False)
            elif (not (dl & 0x80)):
                self.main.printMsg("PythonBios::interrupt: intNum 0x13 (floppy) ax {0:#06x} not supported yet in PythonBIOS.", ax)
        return False
    cdef setRetError(self, unsigned char newCF, unsigned short ax): # for use with floppy
        (<Registers>self.main.cpu.registers).setEFLAG( FLAG_CF, newCF )
        (<Registers>self.main.cpu.registers).regWrite( CPU_REGISTER_AX, ax )
        (<Mm>self.main.mm).mmPhyWriteValue(DISKETTE_RET_STATUS_ADDR, ax>>8, OP_SIZE_BYTE)
    cdef run(self):
        pass


