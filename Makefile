RM=rm -rf

all:
	rm -f *.cpython-32.so
	python3.2 setup.py build_ext
	cp -a build/lib.linux-x86_64-3.2/*.cpython-32.so .
clean:
	$(RM) build/ *.c *.so
