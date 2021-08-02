from setuptools import setup

setup(
    name = 'sf_module',
    version = '0.0.1',
    author = 'antmicro',
    packages = ['sf_module'],
    license = 'ISC',
    description = 'Framework required to write Symbiflow modules',
    install_requires = ['colorama']
)