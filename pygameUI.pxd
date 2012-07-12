
from misc cimport Misc
from ps2 cimport PS2


cdef class PygameUI:
    cpdef public object main, vga
    cpdef object screen
    cdef bytes fontData
    cdef tuple screenSize, charSize
    cdef unsigned char replicate8Bit, msbBlink
    cpdef initPygame(self)
    cpdef quitFunc(self)
    cpdef clearScreen(self)
    cpdef object getCharRect(self, unsigned char x, unsigned char y)
    cpdef object getBlankChar(self, tuple bgColor)
    cpdef object putChar(self, unsigned char x, unsigned char y, unsigned char character, unsigned char colors) # returns rect
    cpdef setRepeatRate(self, unsigned short delay, unsigned short interval)
    cdef unsigned char keyToScancode(self, unsigned short key)
    cpdef handleEvent(self, object event)
    cpdef updateScreen(self, list rectList)
    cpdef handleEvents(self)
    cpdef run(self)



