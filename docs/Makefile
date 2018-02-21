# Minimal makefile for Sphinx documentation
#

# Disable make's inbuilt rules
.SUFFIXES:


# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = $(VENV_ROOT)/bin/sphinx-build
SPHINXPROJ    = SymbiFlowArchitectureDefinitions
SOURCEDIR     = .
BUILDDIR      = _build
VENV_ROOT     = $(BUILDDIR)/_venv

# Set up a virtualenv
$(VENV_ROOT)/bin/python3:
	virtualenv -p python3 $(VENV_ROOT)

ACTIVATE = source $(VENV_ROOT)/bin/activate

# Put it first so that "make" without argument is like "make help".
#-------------------------------------------
help: $(SPHINXBUILD)
	@$(SPHINXRUN) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help

# Install the requirements into the virtualenv
#-------------------------------------------
$(VENV_ROOT)/requirements.stamp: requirements.txt $(VENV_ROOT)/bin/python3
	$(ACTIVATE); pip install -r requirements.txt
	@touch $(VENV_ROOT)/requirements.stamp

$(SPHINXBUILD): $(VENV_ROOT)/requirements.stamp $(VENV_ROOT)/bin/python3
	@touch $<

distclean:
	rm -rf _build $(VENV_ROOT) .Makefile.d
	mkdir -p _build
	mkdir -p $(VENV_ROOT)

SPHINXRUN = $(ACTIVATE); $(VENV_ROOT)/bin/python3 $(VENV_ROOT)/bin/sphinx-build

.PHONY: distclean

# Generate targets for all the other sphinx commands.
#-------------------------------------------
SPHINXCMD = $(SPHINXRUN) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
SPHINXSUBCMD = $(SPHINXRUN) -M $$@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.Makefile.d: $(SPHINXBUILD) Makefile
	$(SPHINXRUN) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O) \
		| grep "^ " \
		| sed -e's/^ \+//' -e's|^\([^ ]*\) \+.*$$|\1: $(SPHINXBUILD)\n\t$(SPHINXSUBCMD)\n\n.PHONY: \1\n\n|' \
		> .Makefile.d

-include .Makefile.d

# Get the intersphinx inventory files.
#-------------------------------------------
INTERSPHINX_FILES := $(shell $(ACTIVATE); python -c "import conf; print('\n'.join(n[-1][-1] for n in conf.intersphinx_mapping.values()))")
# Python only method for downloading the inv files.
#@URL="$(shell $(ACTIVATE); python3 -c "import conf; print([n[0] for n in conf.intersphinx_mapping.values() if n[-1][-1] == '$@'][0])")"; \
#    $(ACTIVATE); python -c "import urllib.request; url='$${URL}objects.inv'; print('Downloading '+url+' -> $@'); urllib.request.urlretrieve(url, '$@')"
$(INTERSPHINX_FILES): conf.py Makefile
	@mkdir -p _build/intersphinx/
	@rm -f $@
	@URL="$(shell $(ACTIVATE); python3 -c "import conf; print([n[0]+'/objects.inv' for n in conf.intersphinx_mapping.values() if n[-1][-1] == '$@'][0])")"; \
		wget "$$URL" -O "$@"
	@du -h $@
	@touch $@

inv: $(INTERSPHINX_FILES)
	@true

.PHONY: inv


tools:
	rm -rf tools
	$(ACTIVATE); sphinx-apidoc --implicit-namespaces -o tools ../utils

.PHONY: utils
