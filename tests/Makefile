
SUBDIRS=$(sort $(wildcard [0-9]-*))
ARCHS=$(sort $(basename $(notdir $(wildcard make/arch/*.mk))))

list:
	@echo "Tests are:"
	@for D in $(SUBDIRS); do echo "   $$D"; done
	@echo ""
	@echo "Architectures are:"
	@for A in $(ARCHS); do echo "   $$A"; done
	@echo ""

all.%:
	echo "echo Running for $*"; \
	for D in $(SUBDIRS); do \
		echo "$$D for $*"; \
		(cd $$D; make ARCH=$* all || exit 1) || break 2; \
	done; \


all:
	for A in $(ARCHS); do \
		echo "echo Running for $$A"; \
		for D in $(SUBDIRS); do \
			echo "$$D for $$A"; \
			(cd $$D; make ARCH=$$A all || exit 1) || break 2; \
		done; \
	done

clean:
	for A in $(ARCHS); do \
		echo "echo Running for $$A"; \
		for D in $(SUBDIRS); do \
			echo "$$D for $$A"; \
			(cd $$D; make ARCH=$$A clean || exit 1) || break 2; \
		done; \
		(cd 0-const && make ARCH=$$A clean-dev); \
	done

