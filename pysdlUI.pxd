
from libc.stdint cimport *

from hirnwichse_main cimport Hirnwichse
from vga cimport Vga
#from misc cimport Misc
from ps2 cimport PS2


cdef class PysdlUI:
    cdef Vga vga
    cdef object window, screen, renderer
    cdef bytes fontDataA, fontDataB
    cdef tuple screenSize, charSize
    cdef dict points
    #cdef list points
    cdef uint8_t mode9Bit, replicate8Bit, msbBlink
    cdef void initPysdl(self)
    cdef void quitFunc(self)
    cdef void clearScreen(self)
    cdef void putPixel(self, uint16_t x, uint16_t y, uint8_t colors) # doesn't returns rect
    cdef void putChar(self, uint16_t x, uint16_t y, uint8_t character, uint8_t colors) # doesn't returns rect
    cdef void setRepeatRate(self, uint16_t delay, uint16_t interval)
    cdef uint8_t keyToScancode(self, uint32_t key)
    cdef void handleSingleEvent(self, object event)
    cdef void updateScreen(self)
    cdef void handleEventsWithoutWaiting(self)
    cdef void handleEvents(self)
    cdef void run(self)



