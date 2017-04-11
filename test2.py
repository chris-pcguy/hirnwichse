#!/usr/bin/env python3.6
#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True, profile=False, c_string_type=bytes

import os
from sys import exit
from time import sleep
import concurrent.futures

class TestClass:
    def __init__(self):
        self.executor = concurrent.futures.ThreadPoolExecutor(max_workers=5)
        self.i = 0
        self.j1 = 0
        self.j2 = 0
        self.j3 = 0
    def func1(self):
        self.j1 += 1
        print("j1", self.j1)
        while self.j1:
        #while True:
            print("func1")
            self.i += 1
            sleep(1)
    def func2(self):
        self.j2 += 1
        print("j2", self.j2)
        while True:
            print("func2", self.i)
            sleep(2)
    def func3(self):
        self.j3 += 1
        print("j3", self.j3)
        while True:
            print("func3", self.i)
            sleep(4)
            self.j1 = 0
    def run(self):
        print("run1")
        a=self.executor.submit(self.func1)
        print("run2")
        self.executor.submit(self.func2)
        print("run3")
        self.executor.submit(self.func3)
        print("run4")
        self.executor.submit(self.func3)
        print("run5")
        self.executor.submit(self.func3)
        print("run6")
        sleep(10)
        #print(a.cancel())
        a.result()
        self.executor.submit(self.func3)
        print("run7")
        self.executor.submit(self.func3)
        print("run8")
        self.executor.submit(self.func3)
        print("run9")

if (__name__ == '__main__'):
    testclass = TestClass()
    testclass.run()

