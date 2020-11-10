# Copyright (C) 2020  The Symbiflow Authors.
#
# Use of this source code is governed by a ISC-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/ISC
#
# SPDX-License-Identifier: ISC

import os
import glob
import shlex

from jinja2 import Environment, FileSystemLoader


class SymbiflowArchDefCollector:
    """Base class for symbiflow-arch-defs collectors. The collectors are
       used for generating indexes of primitives or architecture models."""

    def __init__(self, rootdir, generatedir, searchdirs):
        """Collector constructor

        Args:
            rootdir (str): The repository root
            generatedir (str): An output directory for the generated RST files
            searchdirs (list): Directories to be searched for input files.
                The directory paths should be relative to the repository root
                given in the class constructor.
        """

        assert os.path.exists(
            rootdir
        ), "Repository root does not exist! {}".format(rootdir)
        self.rootdir = rootdir

        new_searchdirs = list()
        if isinstance(searchdirs, list):
            for d in searchdirs:
                new_dir = os.path.join(self.rootdir, d)
                new_searchdirs.append(new_dir)
                assert os.path.exists(
                    new_dir
                ), "Search directory does not exist! {}".format(new_dir)

        self.searchdirs = new_searchdirs
        self.generatedir = generatedir

        self.elements = dict()
        for d in self.searchdirs:
            self._find_files(d)

    def _find_files(self, searchdir):
        raise NotImplementedError(
            "A child collector should implement this method"
        )

    def generate_docs(self, *args):
        raise NotImplementedError(
            "A child collector should implement this method"
        )


class ArchsCollector(SymbiflowArchDefCollector):
    """Used to generate Sphinx RST files from architecture XML files"""

    ARCH_PATTERN = "*arch.xml"
    RST_TEMPLATE_PATH = "templates/arch.rst.template"

    def _find_files(self, searchdir):
        """Search for architecture files recursively

        Args:
            searchdir (str): A directory to be searched for input files.
        """

        arch_search = os.path.join(searchdir, "**", self.ARCH_PATTERN)
        arch_files = glob.glob(arch_search, recursive=True)

        for f in arch_files:
            # Select the name of the directory that contains the file
            # as a new dictionary key
            name = (f.split(os.sep))[-2]
            if name not in self.elements.keys():
                self.elements.update({name: f})

    def generate_docs(self):
        """Generate RST files from all the found architecture XMLs

        The method uses the Jinja template stored in a
        self.RST_TEMPLATE_PATH directory.
        """

        os.makedirs(self.generatedir, exist_ok=True)

        for name, path in self.elements.items():
            if os.path.exists(path):
                arch_path = os.path.relpath(path, self.generatedir)
            else:
                arch_path = None

            out_name = "{}.rst".format(name)
            out_file = os.path.join(self.generatedir, out_name)

            jinja_dict = {
                "arch_name": name,
                "arch_path": arch_path,
                "title_underline": '=' * len(name)
            }

            with open(out_file, "w") as fd:
                env = Environment(loader=FileSystemLoader('.'))
                template = env.get_template(self.RST_TEMPLATE_PATH)
                template.stream(**jinja_dict).dump(fd)


class ModelsCollector(SymbiflowArchDefCollector):
    """Used to generate Sphinx RST files from primitive models"""

    PB_TYPE_PATTERN = "*.pb_type.xml"
    MODEL_PATTERN = "*model.xml"
    SIM_PATTERN = "*sim.v"

    RST_TEMPLATE_PATH = "templates/model.rst.template"

    def _update_models(self, file_list, model_type):
        """Update the dictionary of models

        Args:
            file_list (str): A list of files used to update the model dictionary
            model_type (str): A type of model files stored in the file_list.
                Should be one of:
                    - "pb_type" - for xxx.pb_type.xml
                    - "model" - for xxx.model.xml
                    - "sim" - for xxx.sim.v
        """
        assert model_type in ["pb_type", "model", "sim"]

        for f in file_list:
            fbase = os.path.basename(f)
            base, ext = fbase.split(os.extsep, 1)

            if base == "ntemplate":
                continue

            if base not in self.elements.keys():
                self.elements.update(
                    {base: {
                        "pb_type": None,
                        "model": None,
                        "sim": None
                    }}
                )

            self.elements[base][model_type] = f

    def _find_files(self, searchdir):
        """Find the model files

        Args:
            searchdir (str): A directory to be searched for input files.
        """
        pb_type_search = os.path.join(searchdir, "**", self.PB_TYPE_PATTERN)
        pb_type_files = glob.glob(pb_type_search, recursive=True)
        self._update_models(pb_type_files, "pb_type")

        model_search = os.path.join(searchdir, "**", self.MODEL_PATTERN)
        model_files = glob.glob(model_search, recursive=True)
        self._update_models(model_files, "model")

        sim_search = os.path.join(searchdir, "**", self.SIM_PATTERN)
        sim_files = glob.glob(sim_search, recursive=True)
        self._update_models(sim_files, "sim")

    def generate_docs(self, skip_diagrams=list()):
        """Generate RST files from all the found models

        The method uses the Jinja template stored in a
        self.RST_TEMPLATE_PATH directory.

        Args:
            skip_diagrams (list): A list of models whose diagrams should
                not be generated. In particular, the list should contain files
                that are problematic for Yosys or netlistsvg.
        """

        # Ensure that output directory exists
        os.makedirs(self.generatedir, exist_ok=True)

        # Get input file paths relative to the docs source directory
        for name, abs_paths in self.elements.items():
            model_paths = dict()
            for model_type in ["pb_type", "model", "sim"]:
                if abs_paths[model_type] is not None and os.path.exists(
                        abs_paths[model_type]):
                    model_paths[model_type] = os.path.relpath(
                        abs_paths[model_type], self.generatedir
                    )
                else:
                    model_paths[model_type] = None

            # Create an output file name
            out_name = "{}.rst".format(name)
            out_file = os.path.join(self.generatedir, out_name)

            # Open the input file and check the module name and whether
            # a HDL diagram can be generated
            module_name = None
            generate_diagrams = True

            if abs_paths["sim"] is not None:
                with open(abs_paths["sim"]) as sp:
                    data = sp.read()
                    module_name = data.split(
                        "module", maxsplit=1
                    )[-1].split(maxsplit=1)[0].split("(")[0]

                sim_dir = os.path.dirname(abs_paths["sim"])
                with open(abs_paths["sim"]) as sp:
                    # Check whether all includes are accessible
                    for src_line in sp:
                        line = src_line.strip()
                        if line.startswith("`include"):
                            fields = shlex.split(line)
                            assert len(fields) == 2, fields
                            dep_src = fields[1]
                            dep_path = os.path.realpath(
                                os.path.join(sim_dir, dep_src)
                            )
                            if not os.path.exists(dep_path):
                                generate_diagrams = False

            # Skip diagram generation for the modules in the skip_diagram list
            # and for the "ntemplate" models
            if name in skip_diagrams or "ntemplate" in name:
                generate_diagrams = False
                print("Skipping diagram generation for {}".format(name))

            jinja_dict = {
                "model_name": name,
                "title_underline": '=' * len(name),
                "module_name": module_name,
                "generate_diagrams": generate_diagrams,
                "sim_path": model_paths["sim"],
                "pb_type_path": model_paths["pb_type"],
                "model_path": model_paths["model"]
            }

            with open(out_file, "w") as fd:
                env = Environment(loader=FileSystemLoader('.'))
                template = env.get_template(self.RST_TEMPLATE_PATH)
                template.stream(**jinja_dict).dump(fd)


# Sphinx Extension part


def generate_archs(app, config):
    assert "repository_root" in config, "'repository_root' should be an element of the ArchCollector config"  # noqa: E501
    assert "projects" in config, "'projects' should be an element of the ArchCollector config"

    root = config["repository_root"]
    for prj in config["projects"]:
        assert "generatedir" in prj, "'generatedir' should be an element of the project setting"
        assert "searchdirs" in prj, "'searchdirs' should be an element of the project setting"

        ac = ArchsCollector(root, prj["generatedir"], prj["searchdirs"])
        ac.generate_docs()


def generate_models(app, config):
    assert "repository_root" in config, "'repository_root' should be an element of the ModelCollector config"  # noqa: E501
    assert "projects" in config, "'projects' should be an element of the ModelCollector config"

    for prj in config["projects"]:
        assert "generatedir" in prj, "'generatedir' should be an element of the project setting"
        assert "searchdirs" in prj, "'searchdirs' should be an element of the project setting"

        mc = ModelsCollector(
            config["repository_root"], prj["generatedir"], prj["searchdirs"]
        )
        skip_diagrams = prj["skip_diagrams"] if "skip_diagrams" in prj else []
        mc.generate_docs(skip_diagrams)


def setup(app):
    app.add_event("collectors_generate_arch")
    app.add_event("collectors_generate_model")
    app.connect('collectors_generate_arch', generate_archs)
    app.connect("collectors_generate_model", generate_models)

    return {
        'version': '0.1',
        'parallel_read_safe': True,
        'parallel_write_safe': True,
    }
