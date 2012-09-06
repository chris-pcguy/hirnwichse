
from misc cimport Misc
from mm cimport Mm
from X86Platform cimport Platform
from cpu cimport Cpu
from pic cimport Pic, SetINTR
from isadma cimport IsaDma, SetHRQ


cdef class ChEmu:
    cpdef object parser, cmdArgs
    cdef public Misc misc
    cdef public Mm mm
    cdef public Platform platform
    cdef public Cpu cpu
    cdef public unsigned char quitEmu, debugEnabled, exitIfCpuHalted, noUI, exitOnTripleFault, forceFloppyDiskType
    cdef public unsigned int memSize
    cdef public bytes romPath, biosFilename, vgaBiosFilename, fdaFilename, fdbFilename, hdaFilename, hdbFilename
    cpdef parseArgs(self)
    cpdef quitFunc(self)
    cpdef runThreadFunc(self)
    cpdef reset(self, unsigned char resetHardware)
    cpdef run(self)



