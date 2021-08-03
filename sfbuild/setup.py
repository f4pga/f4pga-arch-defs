from setuptools import setup

setup(
    name = 'sfbuild',
    version = '0.0.1',
    author = 'antmicro',
    packages = ['sf_module', 'sf_common'],
    license = 'ISC',
    description = 'Framework required to write Symbiflow modules',
    install_requires = ['colorama']
)