
from misc cimport Misc
from mm cimport Mm
from X86Platform cimport Platform
from cpu cimport Cpu

ctypedef void (*SetHRQ)(self, unsigned char)
ctypedef void (*SetINTR)(self, unsigned char)


cdef class ChEmu:
    cpdef public object pyroDaemon, _pyroDaemon, pyroURI_Main, pyroURI_UI, pyroURI_PS2, pyroUI
    cpdef object parser, cmdArgs
    cpdef public str _pyroId
    cdef public Misc misc
    cdef public Mm mm
    cdef public Platform platform
    cdef public Cpu cpu
    cdef unsigned char debugEnabled
    cdef public unsigned char quitEmu, exitIfCpuHalted, exitCode, noUI, exitOnTripleFault, forceFloppyDiskType
    cdef public unsigned long long memSize
    cdef public bytes romPath, biosFilename, vgaBiosFilename, fdaFilename, fdbFilename
    cpdef isRunning(self)
    cpdef parseArgs(self)
    cpdef quitFunc(self)
    cpdef run(self)



