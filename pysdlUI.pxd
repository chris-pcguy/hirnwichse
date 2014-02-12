
from misc cimport Misc
from ps2 cimport PS2


cdef class PysdlUI:
    cpdef object main, vga
    cpdef object window, screen
    cdef bytes fontData
    cdef tuple screenSize, charSize
    cdef unsigned char replicate8Bit, msbBlink
    cpdef initPysdl(self)
    cpdef quitFunc(self)
    cpdef clearScreen(self)
    cpdef object getCharRect(self, unsigned char x, unsigned char y)
    cpdef object getBlankChar(self, unsigned int bgColor)
    cpdef object putChar(self, unsigned char x, unsigned char y, unsigned char character, unsigned char colors) # returns rect
    cpdef setRepeatRate(self, unsigned short delay, unsigned short interval)
    cdef unsigned char keyToScancode(self, unsigned int key)
    cpdef handleEvent(self, object event)
    cpdef updateScreen(self, tuple rectList)
    cpdef handleEvents(self)
    cpdef run(self)



