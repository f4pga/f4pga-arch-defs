# make-env setup -------------------------------------------------------------

TOP_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

# A pip `requirements.txt` file.
# https://pip.pypa.io/en/stable/reference/pip_install/#requirements-file-format
REQUIREMENTS_FILE := requirements.txt
#
# A conda `environment.yml` file.
# https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html
ENVIRONMENT_FILE := environment.yml

include ../third_party/make-env/conda.mk

# Makefile for Sphinx documentation ------------------------------------------

# You can set these variables from the command line.
SPHINXOPTS      =
SPHINXBUILD     = python -msphinx
SPHINXAUTOBUILD = sphinx-autobuild
SOURCEDIR       = .
BUILDDIR        = build
GENERATEDDIR    = $(SOURCEDIR)/generated

LIVEHTML_HOST   = 127.0.0.1
LIVEHTML_PORT   = 8000
LIVEHTMLOPTS    = --host $(LIVEHTML_HOST) --port $(LIVEHTML_PORT) --open-browser -d $(GENERATEDDIR)

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
sphinx_formats = html dirhtml singlehtml pickle json htmlhelp qthelp devhelp \
                 epub latex latexpdf latexpdfja text man texinfo info gettext \
                 changes xml pseudoxml linkcheck doctest coverage

clear-generated:
	-rm -rf $(GENERATEDDIR)

.PHONY: clear-generated

$(sphinx_formats): | $(CONDA_ENV_PYTHON) clear-generated
	@$(IN_CONDA_ENV) $(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

livehtml: | $(CONDA_ENV_PYTHON) clear-generated
	@$(IN_CONDA_ENV) $(SPHINXAUTOBUILD) $(LIVEHTMLOPTS) "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
