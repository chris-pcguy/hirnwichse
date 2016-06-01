
from libc.stdint cimport *

from hirnwichse_main cimport Hirnwichse
from vga cimport Vga
#from misc cimport Misc
from ps2 cimport PS2


cdef class PysdlUI:
    cdef Vga vga
    cpdef object window, screen, renderer
    cdef bytes fontDataA, fontDataB
    cdef tuple screenSize, charSize
    cdef dict points
    #cdef list points
    cdef uint8_t mode9Bit, replicate8Bit, msbBlink
    cpdef initPysdl(self)
    cpdef quitFunc(self)
    cpdef clearScreen(self)
    cdef void putPixel(self, uint16_t x, uint16_t y, uint8_t colors) nogil # doesn't returns rect
    cdef void putChar(self, uint16_t x, uint16_t y, uint8_t character, uint8_t colors) # doesn't returns rect
    cpdef setRepeatRate(self, uint16_t delay, uint16_t interval)
    cdef uint8_t keyToScancode(self, uint32_t key)
    cpdef handleSingleEvent(self, object event)
    cpdef updateScreen(self)
    cpdef handleEventsWithoutWaiting(self)
    cpdef handleEvents(self)
    cpdef run(self)



