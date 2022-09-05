#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Updated documentation of the configuration options is available at
# https://www.sphinx-doc.org/en/master/usage/configuration.html

from pathlib import Path

# import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))

# -- General configuration -------------------------------------------------------------------------

project = 'F4PGA Architecture Definitions'
author = 'Various'
copyright = f'{author}, 2018 - 2022'

# TODO:
# These should be pulled from git-describe (if `git` is available).
version = 'latest'  # The short X.Y version.
release = 'latest'  # The full version, including alpha/beta/rc tags.

master_doc = 'index'

extensions = [
    'sphinx.ext.autodoc', 'sphinx.ext.extlinks', 'sphinx.ext.intersphinx',
    'sphinxcontrib.images', 'myst_parser'
]

templates_path = ['_templates']

source_suffix = {'.rst': 'restructuredtext', '.md': 'markdown'}

language = None

exclude_patterns = ['_buld']

pygments_style = 'default'

rst_prolog = """
.. IMPORTANT::
  Since May 2022, packages providing Architecture Definition assets do *not* include CLI
  utilities/wrappers to interact with Yosys, Verilog-to-Routing, etc.
  For backwards compatibility, end-users can install Python package ``f4pga`` from
  :gh:`chipsalliance/f4pga`.
  For instance:
  ``pip install https://github.com/chipsalliance/f4pga/archive/main.zip#subdirectory=f4pga``.
"""

todo_include_todos = False

# -- Options for HTML output -----------------------------------------------------------------------

html_show_sourcelink = True

html_theme = 'sphinx_f4pga_theme'

html_theme_options = {
    'repo_name': 'f4pga/f4pga-arch-defs',
    'github_url': 'https://github.com/f4pga/f4pga-arch-defs',
    'globaltoc_collapse': True,
    'color_primary': 'indigo',
    'color_accent': 'blue',
}

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

html_logo = str(Path(html_static_path[0]) / 'logo.svg')
html_favicon = str(Path(html_static_path[0]) / 'favicon.svg')

# -- Options for HTMLHelp output -------------------------------------------------------------------

# Output file base name for HTML help builder.
htmlhelp_basename = 'f4pga-arch-defsdoc'

# -- Options for LaTeX output ----------------------------------------------------------------------

latex_elements = {}

latex_documents = [
    (
        master_doc, 'f4pga-arch-defs.tex', 'f4pga-arch-defs Documentation',
        'Various', 'manual'
    ),
]

# -- Options for manual page output ----------------------------------------------------------------

man_pages = [
    (
        master_doc, 'f4pga-arch-defs', 'f4pga-arch-defs Documentation',
        [author], 1
    )
]

# -- Options for Texinfo output --------------------------------------------------------------------

texinfo_documents = [
    (
        master_doc, 'f4pga-arch-defs', 'f4pga-arch-defs Documentation', author,
        'f4pga-arch-defs', 'One line description of project.', 'Miscellaneous'
    ),
]

# -- Sphinx.Ext.InterSphinx ------------------------------------------------------------------------

intersphinx_mapping = {
    'python': ('https://docs.python.org/3.6/', None),
    'f4pga': ('https://f4pga.readthedocs.io/en/latest/', None),
    'examples': ('https://f4pga-examples.readthedocs.io/en/latest', None),
    'prjxray': ('https://prjxray.readthedocs.io/en/latest/', None),
    'constraints': ('https://hdl.github.io/constraints/', None),
    "vtr": ("https://docs.verilogtorouting.org/en/latest/", None),
}

# -- Sphinx.Ext.ExtLinks ---------------------------------------------------------------------------

extlinks = {
    'wikipedia': ('https://en.wikipedia.org/wiki/%s', 'wikipedia:'),
    'gh': ('https://github.com/%s', 'gh:'),
    'ghsharp': ('https://github.com/SymbiFlow/f4pga-arch-defs/issues/%s', '#'),
    'ghissue':
        ('https://github.com/SymbiFlow/f4pga-arch-defs/issues/%s', 'issue #'),
    'ghpull':
        (
            'https://github.com/SymbiFlow/f4pga-arch-defs/pull/%s',
            'pull request #'
        ),
    'ghsrc':
        ('https://github.com/SymbiFlow/f4pga-arch-defs/blob/master/%s', '')
}
