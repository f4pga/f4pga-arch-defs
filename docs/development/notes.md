# Notes

Since Architecture Definitions rely on yosys and VPR, it may be useful to override the default packaged binaries with
locally supplied binaries.
The build system allows this via environment variables matching the executable name.
Here is a list of common environment variables to defined when doing local yosys and VPR development.

* YOSYS : Path to yosys executable to use.
* VPR : Path to VPR executable to use.
* GENFASM : Path genfasm executable to use.

There are more binaries that are packaged (e.g. VVP), but the packaged versions are typically good enough for most use
cases.

After setting or clearing one of these environment variables, CMake needs to be re-run.
