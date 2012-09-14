

include "globals.pxi"
include "cpu_globals.pxi"

DEF DISKETTE_RET_STATUS_ADDR = 0x441 # byte


cdef class PythonBios:
    def __init__(self, object main):
        self.main = main
    cpdef unsigned char interrupt(self, unsigned char intNum):
        cdef unsigned int memAddr, logicalSector
        cdef unsigned short ax, cx, dx, bx, bp, i, count, cylinder, cursorPos
        cdef unsigned char currMode, ah, al, bh, bl, dh, dl, fdcNum, fdCount, \
                            updateCursor, c, attr, attrInBuf, sector, head, tempByte
        cdef bytes data
        #return False
        ax = (<Registers>self.main.cpu.registers).regReadUnsignedWord(CPU_REGISTER_AX)
        cx = (<Registers>self.main.cpu.registers).regReadUnsignedWord(CPU_REGISTER_CX)
        dx = (<Registers>self.main.cpu.registers).regReadUnsignedWord(CPU_REGISTER_DX)
        bx = (<Registers>self.main.cpu.registers).regReadUnsignedWord(CPU_REGISTER_BX)
        bp = (<Registers>self.main.cpu.registers).regReadUnsignedWord(CPU_REGISTER_BP)
        ah, al = ax>>8, <unsigned char>ax
        ch, cl = cx>>8, <unsigned char>cx
        dh, dl = dx>>8, <unsigned char>dx
        bh, bl = bx>>8, <unsigned char>bx
        if (intNum == 0x10): # video; TODO: REWORK THIS AND THE VGA MODULE TOO!!!
            #return False
            currMode = (<Mm>self.main.mm).mmPhyReadValueUnsignedByte(VGA_MODE_ADDR)
            ##self.main.debug("PythonBios::videoFuncs: ax: {0:#06x}, currMode: {1:#04x}", ax, currMode)
            if (ah == 0x02): # set cursor position
                (<Vga>self.main.platform.vga).setCursorPosition(bh, dx)
                return True
            elif (ah == 0x03): # get cursor position
                dx = (<Vga>self.main.platform.vga).getCursorPosition(bh)
                cx = (<Mm>self.main.mm).mmPhyReadValueUnsignedWord(VGA_CURSOR_TYPE_ADDR)
                (<Registers>self.main.cpu.registers).regWriteWord(CPU_REGISTER_DX, dx)
                (<Registers>self.main.cpu.registers).regWriteWord(CPU_REGISTER_CX, cx)
                return True
            elif (ah == 0x06): # scroll up
                (<Vga>self.main.platform.vga).scrollUp(0xff, bh, al)
                return True
            elif (ah == 0x0f): # get currMode; write it to AL
                (<Registers>self.main.cpu.registers).regWriteLowByte(CPU_REGISTER_AL, (currMode|\
                    ((<Mm>self.main.mm).mmPhyReadValueUnsignedByte(VGA_VIDEO_CTL_ADDR)&0x80)))
                (<Registers>self.main.cpu.registers).regWriteHighByte(CPU_REGISTER_AH, 80) # number of columns
                (<Registers>self.main.cpu.registers).regWriteHighByte(CPU_REGISTER_BH, (<Vga>self.main.platform.vga).getCorrectPage(0xff))
                return True
            elif (currMode <= 0x7 or currMode in (0x12, 0x13)):
                if (ah in (0x09, 0x0a, 0x0e)): # AH in (0x09, 0x0A, 0x0E) / PRINT CHARACTER
                    #if (currMode in (0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x12, 0x13)):
                    if (currMode in (0x0, 0x1, 0x2, 0x3, 0x7, 0x12, 0x13)):
                        # ah==0x09: bl for textmode/graphicsmode;; ah==0x0e: bl for textmode
                        if (ah == 0x0e):
                            (<Vga>self.main.platform.vga).writeCharacterTeletype(al, -1, 0xff)
                        elif (ah == 0x09):
                            (<Vga>self.main.platform.vga).writeCharacterNoTeletype(al, bl, bh, cx)
                        else: # ah == 0x0a
                            (<Vga>self.main.platform.vga).writeCharacterNoTeletype(al, -1, bh, cx)
                        return True
                    else:
                        self.main.notice("PythonBios::interrupt: int: 0x10 AH: 0x0e: currMode {0:d} not supported here. (ax: {1:#04x})", currMode, ax)
                        return False
                elif (ah == 0x13): # AH == 0x13
                    if (currMode in (0x0, 0x1, 0x2, 0x3, 0x7)):
                        updateCursor = al&1
                        attrInBuf = (al&2)!=0
                        count = cx
                        attr = bl
                        (<Vga>self.main.platform.vga).setCursorPosition(bh, dx)
                        #if (attrInBuf): # TODO
                        #    count *= 2
                        data = (<Registers>self.main.cpu.registers).mmRead(bp, count, CPU_SEGMENT_ES, False)
                        for i in range(0, count, attrInBuf+1):
                            c = data[i]
                            if (attrInBuf):
                                attr = data[i+1]
                            (<Vga>self.main.platform.vga).writeCharacterTeletype(c, attr, bh)
                        if (not updateCursor):
                            (<Vga>self.main.platform.vga).setCursorPosition(bh, dx)
                        return True
                    else:
                        self.main.notice("PythonBios::interrupt: int: 0x10 AH: 0x13: currMode {0:d} not supported here. (ax: {1:#06x})", currMode, ax)
                        return False
                else: # AH
                    self.main.notice("PythonBios::interrupt: int: 0x10: AX {0:#06x} is not supported here. (currMode: {1:d})", ax, currMode)
                    return False
            else:
                self.main.notice("PythonBios::interrupt: int: 0x10: currMode {0:d} not supported here. (ax: {1:#06x})", currMode, ax)
                return False
        elif (intNum == 0x13): # data storage; floppy
            fdcNum = 0
            if (dl in (2, 3)):
                fdcNum = 1
            if (dl not in (0, 1, 2, 3) or (not (<FloppyDrive>(<FloppyController>(<Floppy>self.main.platform.floppy).controller[fdcNum]).drive[dl]).isLoaded)):
                if (dl not in (0, 1, 2, 3)):
                    self.main.notice("INT_0x13(AX=={0:#06x}): drive dl({1:#04x}) is not in (0, 1, 2, 3).", ax, dl)
                else:
                    self.main.notice("INT_0x13(AX=={0:#06x}): drive dl({1:#04x}) is not loaded.", ax, dl)
                # TODO: set correct error code.
                ###self.setRetError(True, 0x8000)
                self.setRetError(True, 0x100)
                return True
            elif (ah == 0x2):
                if ( ((cl >> 6)&3 != 0) and not (dl & 0x80) ):
                    self.main.notice("PythonBios::interrupt: cl-bits #6 and/or #7 are set, but floppy was selected.")
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
                tempByte = (<Cmos>self.main.platform.cmos).readValue(CMOS_FLOPPY_DRIVE_TYPE, OP_SIZE_BYTE)
                fdCount = 0
                if ((fdCount & 0xf0) != 0):
                    fdCount += 1
                if ((fdCount & 0x0f) != 0):
                    fdCount += 1
                if (dl > 1):
                    (<Registers>self.main.cpu.registers).regWriteWord(CPU_REGISTER_AX, 0)
                    (<Registers>self.main.cpu.registers).regWriteWord(CPU_REGISTER_BX, 0)
                    (<Registers>self.main.cpu.registers).regWriteWord(CPU_REGISTER_CX, 0)
                    (<Registers>self.main.cpu.registers).regWriteWord(CPU_REGISTER_DX, fdCount)
                    (<Registers>self.main.cpu.registers).segWrite(CPU_SEGMENT_ES, 0)
                    (<Registers>self.main.cpu.registers).regWriteWord(CPU_REGISTER_DI, 0)
                    (<Registers>self.main.cpu.registers).setEFLAG(FLAG_CF, True)
                    return True
                (<Registers>self.main.cpu.registers).regWriteHighByte(CPU_REGISTER_DH, \
                    ((<FloppyMedia>(<FloppyDrive>(<FloppyController>(<Floppy>self.main.platform.floppy).controller[fdcNum]).drive[dl]).media).heads-1))
                (<Registers>self.main.cpu.registers).regWriteLowByte(CPU_REGISTER_DL, fdCount)
                (<Registers>self.main.cpu.registers).regWriteWord(CPU_REGISTER_CX, \
                    ((<FloppyMedia>((<FloppyDrive>(<FloppyController>(<Floppy>self.main.platform.floppy).controller[fdcNum]).drive[dl]).media).tracks<<8) | \
                    (<FloppyMedia>((<FloppyDrive>(<FloppyController>(<Floppy>self.main.platform.floppy).controller[fdcNum]).drive[dl]).media).sectorsPerTrack)))
                # fdCount is fdType here.
                fdCount = (<Cmos>self.main.platform.cmos).readValue(CMOS_FLOPPY_DRIVE_TYPE, OP_SIZE_BYTE)
                if (dl == 0):
                    fdCount >>= 4
                elif (dl == 1):
                    fdCount &= 0x0f
                (<Registers>self.main.cpu.registers).regWriteWord(CPU_REGISTER_BX, fdCount)
                memAddr = (<Mm>self.main.mm).mmPhyReadValueUnsigned((0x78), OP_SIZE_DWORD) # INT 0x1E: 0x78==OFFSET; 0x7A==SEGMENT
                (<Registers>self.main.cpu.registers).segWrite(CPU_SEGMENT_ES, (memAddr>>16))
                (<Registers>self.main.cpu.registers).regWriteWord(CPU_REGISTER_DI, <unsigned short>memAddr)
                self.setRetError(False, 0)
                return True
            elif (not (dl & 0x80)):
                if (ah == 0x41):
                    self.setRetError(True, 0x100)
                    return True
                self.main.notice("PythonBios::interrupt: intNum 0x13 (floppy) ax {0:#06x} not supported yet in PythonBIOS.", ax)
        return False
    cdef void setRetError(self, unsigned char newCF, unsigned short ax): # for use with floppy
        (<Registers>self.main.cpu.registers).setEFLAG( FLAG_CF, newCF )
        (<Registers>self.main.cpu.registers).regWriteWord( CPU_REGISTER_AX, ax )
        (<Mm>self.main.mm).mmPhyWriteValue(DISKETTE_RET_STATUS_ADDR, ax>>8, OP_SIZE_BYTE)
    cdef void run(self):
        pass


