.PHONY: all env

all: env
	cd build && $(MAKE)

clean:
	rm -rf build

env:
	git submodule init
	git submodule update --init --recursive
	mkdir -p build && cd build && cmake ${CMAKE_FLAGS} ..

build/Makefile:
	make env

.PHONY: Makefile

%: build/Makefile
	cd build && $(MAKE) $@
