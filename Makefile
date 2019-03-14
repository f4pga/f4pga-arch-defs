.PHONY: all env

all: env
	cd build && make

clean:
	rm -rf build

env:
	git submodule init
	git submodule update --init --recursive
	mkdir -p build && cd build && cmake ..
