.PHONY: all env

all: env
	cd build && $(MAKE)

clean:
	rm -rf build

env:
	git submodule init
	git submodule update --init --recursive
	mkdir -p build && cd build && cmake ..

.PHONY: Makefile

%: env
	cd build && $(MAKE) $@
