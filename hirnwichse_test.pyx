
# cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=True

from threading import Event, Thread
from time import sleep

cdef class HirnwichseTest:
    def __init__(self):
        self.threadObject = None
        self.eventObject = Event()
        self.timerEnabled = True
    cpdef object createThread(self, object threadFunc, unsigned char startIt):
        cpdef object threadObject
        threadObject = Thread(target=threadFunc)
        if (startIt):
            threadObject.start()
        return threadObject
    cpdef runThread(self):
        print("entered thread")
        while (self.timerEnabled and not self.eventObject.is_set()):
            sleep(2)
            print("loop thread")
        print("leave thread")
    cpdef run(self):
        print("entered run")
        self.threadObject = self.createThread(self.runThread, True)
        sleep(10)
        #self.eventObject.set()
        self.timerEnabled = False
        self.threadObject.join()
        print("leave run")



