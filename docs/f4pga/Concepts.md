# Fundamental concepts

If you want to create a new sfbuild project, it's highly recommended that you
read this section first.

## sfbuild

_**sfbuild**_ is a modular build system designed to handle various
_Verilog-to-bitsream_ flows for FPGAs. It works by wrapping the necessary tools
in python scripts, which are called **sfbuild modules**. The modules are then
referenced in a **platform's flow definition** files along configurations specific
for given platform. These files for come included as a part of _**sfbuild**_ for the
following platforms:

* x7a50t
* x7a100t
* x7a200t (_soon_)

You can also write your own **platform's flow definition** file if you want to bring
support to a different device.

Each project that uses _**sfbuild**_ to perform any flow should include a _.json_
file describing the project. The purpose of that file is to configure inputs
for the flow and possibly override configuration values if necessary.

## Modules

A **module** (also referred to as **sfbuild module** in sistuations where there might
be confusion between Python's _modules_ and sfbuild's _modules_) is a python scripts
that wraps a tool used within **Symbilfow's** ecosystem. The main purpouse of this
wrapper is to provide a unified interface for sfbuild to use and configure the tool
as well as provide information about files required and produced by the tool.

## Dependecies

A **dependency** is any file, directory or a list of such that a **module** takes as
its input or produces on its output.

Modules specify their dependencies by using symbolic names instead of file paths.
The files they produce are also given symbolic names and paths which are either set
through **project's flow configuration** file or derived from the paths of the
dependencies taken by the module.

## Target

**Target** is a dependency that the user has asked sfbuild to produce.

## Flow

A **flow** is set of **modules** executed in a right order to produce a **target**.

## .symbicache

All **dependencies** are tracked by a modification tracking system which stores hashes
of the files (directories get always `'0'` hash) in `.symbicache` file in the root of
the project. When _**sfbuild**_ constructs a **flow**, it will try to omit execution
of modules which would receive the same data on their input. There's a strong
_assumption_ there that a **module**'s output remains unchanged if the input
doconfiguring esn't
change, ie. **modules** are deterministic.

## Resolution

A **dependency** is said to be **resolved** if it meets one of the following
critereia:

* it exists on persistent storage and its hash matches the one stored in .symbicache
* there exists such **flow** that all of the dependieces of its modules are
  **resolved** and it produces the **dependency** in question.

## Platform's flow definition

**Platform's flow definition** is a piece of data describing a space of flows for a
given platform, serialized into a _JSON_.
It's stored in a file that's named after the device's name under `sfbuild/platforms`.

**Platform's flow definition** contains a list of modules available for constructing
flows and defines a set of values which the modules can reference. In case of some
modules it  may also define a set of parameters used during their construction.
`mkdirs` module uses that to allow production of of multiple directories as separate
dependencies. This however is an experimental feature which possibly will be
removed in favor of having multiple instances of the same module with renameable
ouputs.

Not all **dependencies** have to be **resolved** at this stage, a **platform's flow
definition** for example won't be able to provide a list of source files needed in a
**flow**.

## Projects's flow configuration

Similarly to **platform's flow definition**, **Projects's flow configuration** is a
_JSON_ that is used to configure **modules**. There are however a couple differences
here and there.

* The most obvious one is that this file is unique for a project and
  is provided by the user of _**sfbuild**_.

* The other difference is that it doesn't list **modules** available for the
  platform.

* All the values provided in **projects's flow configuration** will override those
  provided in **platform's flow definition**.

* It can contain sections with configurations for different platforms.

* Unlike **platform's flow definition** it can give explicit paths to dependencies.

* At this stage all mandatory **dependencies** should be resolved.

Typically **projects's flow configuration** will be used to resolve dependencies
for _HDL source code_ and _device constraints_.
