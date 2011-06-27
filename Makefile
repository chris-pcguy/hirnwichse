RM=rm -rf

all:
	python3.2 setup.py build_ext --inplace

clean:
	$(RM) build/ *.c *.so
