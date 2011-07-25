
###import sys, argparse, threading, time, atexit

###cimport platform, mm, cpu, misc


cdef class ChEmu:
    ##cpdef object parser, cmdArgs, misc, platform, mm, cpu
    cpdef object parser, cmdArgs
    cpdef public object mm, misc, cpu, platform
    cpdef public int exitIfCpuHalted, debugEnabled, testModeEnabled
    cpdef long memSize
    cpdef str testModePrefix, testModeSuffix
    cpdef public str romPath, biosName, vgaBiosName
    ###def __init__(self)
    #def exitError(self, str errorStr, *errorStrArguments, int errorExitCode=1)
    #def debug(self, str debugStr, *debugStrArguments)
    #def printMsg(self, str msgStr, *msgStrArguments)
    cpdef saveMemToFile(self, long addr, long size, str prefix=?, str suffix=?)
    cpdef run(self)



