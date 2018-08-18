.PHONY: all

all:
	mkdir -p build && cd build && cmake .. && make
