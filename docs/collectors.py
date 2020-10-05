#!/usr/bin/env python3

import os
import glob
import shlex

from jinja2 import Environment, FileSystemLoader


class ArchsCollector:
    """Used to generate Sphinx RST files from architecture XML files"""

    ARCH_PATTERN = "*arch.xml"
    RST_TEMPLATE_PATH = "templates/arch.rst.template"

    def __init__(self, rootdir):
        """ArchsCollector constructor

        Args:
            rootdir (str): The repository root
        """
        assert os.path.exists(
            rootdir
        ), "Repository root does not exist! {}".format(rootdir)

        self.archs = dict()
        self.rootdir = rootdir

    def generate_docs(self, generatedir, searchdirs):
        """Generate RST files with architecture XML description

        Args:
            generatedir (str): An output directory for the generated RST files
            searchdirs (str or list): A list of directories to be searched for
                input files. The directory paths should be relative to
                the repository root given in the class constructor.
        """

        # Convert relative paths to absolute (using repository root)
        new_searchdirs = list()
        if isinstance(searchdirs, list):
            for d in searchdirs:
                new_dir = os.path.join(self.rootdir, d)
                new_searchdirs.append(new_dir)
                assert os.path.exists(
                    new_dir
                ), "Search directory does not exist! {}".format(searchdirs)
        else:
            new_dir = os.path.join(self.rootdir, d)
            new_searchdirs.append(new_dir)
            assert os.path.exists(
                new_dir
            ), "Search directory does not exist! {}".format(searchdirs)

        # Find architecture XML files
        self.archs = dict()
        for d in new_searchdirs:
            self._find_files(d)

        # Generate RST documentation
        self._generate_rst_files(generatedir)

    def _find_files(self, searchdir):
        """Search for arch files recursively

        Args:
            searchdir (str): A directory to be searched for input files.
        """

        arch_search = os.path.join(searchdir, "**", self.ARCH_PATTERN)
        arch_files = glob.glob(arch_search, recursive=True)

        for f in arch_files:
            # Select the name of the directory that contains the file
            # as a new dictionary key
            name = (f.split(os.sep))[-2]
            if name not in self.archs.keys():
                self.archs.update({name: f})

    def _generate_rst_files(self, generatedir):
        """Generate RST files from all the found architecture XMLs

        The method uses the Jinja template stored in a
        self.RST_TEMPLATE_PATH directory.

        Args:
            generatedir (str): An output directory for the generated RST files
        """

        os.makedirs(generatedir, exist_ok=True)

        for name, path in self.archs.items():
            if os.path.exists(path):
                arch_path = os.path.relpath(path, generatedir)
            else:
                arch_path = None

            out_name = "{}.rst".format(name)
            out_file = os.path.join(generatedir, out_name)

            jinja_dict = {"arch_name": name, "arch_path": arch_path}

            with open(out_file, "w") as fd:
                env = Environment(loader=FileSystemLoader('.'))
                template = env.get_template(self.RST_TEMPLATE_PATH)
                template.stream(**jinja_dict).dump(fd)


class ModelsCollector:
    """Used to generate Sphinx RST files from models of primitives"""

    PB_TYPE_PATTERN = "*.pb_type.xml"
    MODEL_PATTERN = "*model.xml"
    SIM_PATTERN = "*sim.v"

    RST_TEMPLATE_PATH = "templates/model.rst.template"

    def __init__(self, rootdir):
        """ModelsCollector constructor

        Args:
            rootdir (str): The repository root
        """
        assert os.path.exists(
            rootdir
        ), "Repository root does not exist! {}".format(rootdir)

        self.models = dict()
        self.rootdir = rootdir

    def generate_docs(self, generatedir, searchdirs, skip_diagrams=list()):
        """Generate RST files with architecture XML description

        Args:
            generatedir (str): An output directory for the generated RST files
            searchdirs (str or list): A list of directories to be searched for
                input files. The directory paths should be relative to
                the repository root given in the class constructor.
            skip_diagrams (list): A list of models whose diagrams should
                not be generated. In particular, the list should contain files
                that are problematic for Yosys or netlistsvg.
        """
        assert isinstance(
            searchdirs, list
        ), "searchdirs argument should be a list!"

        new_searchdirs = list()
        if isinstance(searchdirs, list):
            for d in searchdirs:
                new_dir = os.path.join(self.rootdir, d)
                new_searchdirs.append(new_dir)
                assert os.path.exists(
                    new_dir
                ), "Search directory does not exist! {}".format(d)

        # Find all the models
        self.models = dict()
        for d in new_searchdirs:
            self._find_files(d)

        # Generate RST documentation
        self._generate_rst_files(generatedir, skip_diagrams)

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

            if base not in self.models.keys():
                self.models.update(
                    {base: {
                        "pb_type": None,
                        "model": None,
                        "sim": None
                    }}
                )

            self.models[base][model_type] = f

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

    def _generate_rst_files(self, generatedir, skip_diagrams):
        """Generate RST files from all the found models

        The method uses the Jinja template stored in a
        self.RST_TEMPLATE_PATH directory.

        Args:
            generatedir (str): An output directory for the generated RST files
            skip_diagrams (list): A list of models whose diagrams should
                not be generated. In particular, the list should contain files
                that are problematic for Yosys or netlistsvg.
        """

        # Ensure that output directory exists
        os.makedirs(generatedir, exist_ok=True)

        # Get input file paths relative to the docs source directory
        for name, abs_paths in self.models.items():
            model_paths = dict()
            for model_type in ["pb_type", "model", "sim"]:
                if abs_paths[model_type] is not None and os.path.exists(
                        abs_paths[model_type]):
                    model_paths[model_type] = os.path.relpath(
                        abs_paths[model_type], generatedir
                    )
                else:
                    model_paths[model_type] = None

            # Create an output file name
            out_name = "{}.rst".format(name)
            out_file = os.path.join(generatedir, out_name)

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
