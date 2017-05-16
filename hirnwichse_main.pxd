
from libc.stdint cimport *
from libc.stdio cimport printf, fflush, stdout
from libc.string cimport strcpy, strcat
from libc.stdlib cimport exit as exitt

from misc cimport Misc
from mm cimport Mm
from X86Platform cimport Platform
from cpu cimport Cpu

cdef extern from "stdarg.h":
    ctypedef struct va_list:
        pass
    ctypedef struct fake_type:
        pass
    void va_start(va_list, void* arg)
    void* va_arg(va_list, fake_type)
    void va_end(va_list)
    int vprintf(const char *format, va_list ap)
    fake_type int_type "int"

cdef class Hirnwichse:
    cdef object parser, cmdArgs #, executor
    cdef Misc misc
    cdef Mm mm
    cdef Platform platform
    cdef Cpu cpu
    cdef uint8_t quitEmu, debugEnabled, exitIfCpuHalted, noUI, exitOnTripleFault, fdaType, fdbType, debugHalt, bootFrom, debugEnabledTest
    cdef uint32_t memSize
    cdef bytes romPath, biosFilename, vgaBiosFilename, fdaFilename, fdbFilename, hdaFilename, hdbFilename, cdrom1Filename, cdrom2Filename, serial1Filename, serial2Filename, serial3Filename, serial4Filename
    cdef void parseArgs(self)
    cdef void quitFunc(self)
    cdef void exitError(self, char *msg, ...)
    cdef void debug(self, char *msg, ...)
    cdef void notice(self, char *msg, ...)
    cdef void reset(self, uint8_t resetHardware)
    cpdef void run(self, uint8_t infiniteCycles)



