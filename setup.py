#!/usr/bin/env python3.2

from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

ext_modules = [Extension("cpu", ["cpu.pyx"]), Extension("mm", ["mm.pyx"]), Extension("platform", ["platform.pyx"]), Extension("pic", ["pic.pyx"]), Extension("vga", ["vga.pyx"])]

setup(
  name = 'chemu',
  cmdclass = {'build_ext': build_ext},
  ext_modules = ext_modules
)

