
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

from threading import Thread


cdef class Misc:
    def __init__(self, Hirnwichse main):
        self.main = main
    cdef object createThread(self, object threadFunc, object classObject):
        cdef object threadObject
        threadObject = Thread(target=threadFunc, args=(classObject,))
        threadObject.start()
        return threadObject


