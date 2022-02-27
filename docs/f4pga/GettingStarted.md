# Getting started

To use _**sfbuild**_ you need a working python 3 installation which should be icluded
as a part of conda virtual environment set up during symbiflow installation.
_**sfbuild**_ installs along _**Symbiflow**_ with any version of toolchain. However,
only _XC7_ architectures are supported currently and _Quicklogic_ support is a work
in progress. _**sfbuild**_'s installation directory is `bin/sfbuild`, under your
_**Symbiflow**_ installation directory. `sfbuild.py` is the script that you should
run to use _**sfbuild**_.

To get started with a project that already uses sfbuild, go to the project's
directory and run the following line to build a bitstream:
```
$ python3 /path/to/sfbuild.py flow.json -p platform_name -t bitstream
```

Substitute `platform_name` by the name of the target platform (eg. `x7a50t`).
`flow.json` should be a **project's flow configuration** file included with the
project. If you are unsure if you got the right file, you can check an example of
the contents of such file shown in the "_Using sfbuild to build a target_" section.

The location of the file containing bitstream will be indicated by sfbuild after the
flow completes. Look for a line like this one on stdout.:

```
Target `bitstream` -> build/arty_35/top.bit
```
