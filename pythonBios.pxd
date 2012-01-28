
from mm cimport Mm
from cmos cimport Cmos
from registers cimport Registers
from vga cimport Vga
from floppy cimport Floppy, FloppyController, FloppyDrive, FloppyMedia


cdef class PythonBios:
    cpdef object main
    cpdef unsigned char interrupt(self, unsigned char intNum)
    cdef setRetError(self, unsigned char newCF, unsigned short ax)
    cdef run(self)


