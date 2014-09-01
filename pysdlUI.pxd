
from misc cimport Misc
from ps2 cimport PS2


cdef class PysdlUI:
    cpdef object main, vga
    cpdef object window, screen
    cdef bytes fontData
    cdef tuple screenSize, charSize
    cdef unsigned char replicate8Bit, msbBlink, graphicalMode
    cpdef initPysdl(self)
    cpdef quitFunc(self)
    cpdef clearScreen(self)
    cpdef object getCharRect(self, unsigned short x, unsigned short y)
    cpdef object getBlankChar(self, unsigned int bgColor)
    cpdef object putPixel(self, unsigned short x, unsigned short y, unsigned char colors) # returns rect
    cpdef object putChar(self, unsigned short x, unsigned short y, unsigned char character, unsigned char colors) # returns rect
    cpdef setRepeatRate(self, unsigned short delay, unsigned short interval)
    cdef unsigned char keyToScancode(self, unsigned int key)
    cpdef handleSingleEvent(self, object event)
    cpdef updateScreen(self)
    cpdef handleEventsWithoutWaiting(self)
    cpdef handleEvents(self)
    cpdef run(self)



