#!/usr/bin/env python3

from pathlib import Path
from typing import List

from setuptools import (
    setup as setuptools_setup,
)


packagePath = Path(__file__).resolve().parent
requirementsFile = packagePath / "requirements.txt"


# Read requirements file and add them to package dependency list
def get_requirements(file: Path) -> List[str]:
    requirements = []
    with file.open("r") as fh:
        for line in fh.read().splitlines():
            if line.startswith("#") or line == "":
                continue
            elif line.startswith("-r"):
                # Remove the first word/argument (-r)
                filename = " ".join(line.split(" ")[1:])
                requirements += get_requirements(file.parent / filename)
            elif line.startswith("https"):
                # Convert 'URL#NAME' to 'NAME @ URL'
                splitItems = line.split("#")
                requirements.append("{} @ {}".format(splitItems[1], splitItems[0]))
            else:
                requirements.append(line)
    return requirements


setuptools_setup(
    name=packagePath.name,
    version="0.0.0",
    license="Apache-2.0",
    author="F4PGA Authors",
    description="F4PGA.",
    url="https://github.com/chipsalliance/f4pga",
    packages=["f4pga"],
    package_dir={"f4pga": "."},
    classifiers=[],
    python_requires='>=3.6',
    install_requires=list(set(get_requirements(requirementsFile))),
    entry_points={
        "console_scripts": [
            "f4pga = f4pga.__init__:main",
        ]
    },
)
