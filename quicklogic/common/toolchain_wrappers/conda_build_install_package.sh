#!/bin/bash
echo -e "\e[1;34mInstallation starting for conda based symbiflow\e[0m"
echo -e "\e[1;34mQuickLogic Corporation\e[0m"

if [ -z "$INSTALL_DIR" ]
then
	echo -e "\e[1;31m\$INSTALL_DIR is not set, please set and then proceed!\e[0m"
	echo -e "\e[1;31mExample: \"export INSTALL_DIR=/<custom_location>\". \e[0m"
	exit 0
elif [ -d "$INSTALL_DIR/conda" ]; then
	echo -e "\e[1;32m $INSTALL_DIR/conda already exists, please clean up and re-install ! \e[0m"
	exit 0
else
	echo -e "\e[1;32m\$INSTALL_DIR is set to $INSTALL_DIR ! \e[0m"
fi

mkdir -p $INSTALL_DIR

wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O conda_installer.sh
bash conda_installer.sh -b -p $INSTALL_DIR/conda && rm conda_installer.sh
source "$INSTALL_DIR/conda/etc/profile.d/conda.sh"
echo "include-system-site-packages=false" >> $INSTALL_DIR/conda/pyvenv.cfg
CONDA_FLAGS="-y --override-channels -c defaults -c conda-forge"
conda update $CONDA_FLAGS -q conda
curl https://storage.googleapis.com/symbiflow-arch-defs-install/quicklogic-arch-defs-63c3d8f9.tar.gz --output arch.tar.gz
tar -C $INSTALL_DIR -xvf arch.tar.gz && rm arch.tar.gz
conda install $CONDA_FLAGS -c litex-hub/label/main yosys="0.9_5266_g0fb4224e 20210301_104249_py37"
conda install $CONDA_FLAGS -c litex-hub/label/main symbiflow-yosys-plugins="1.0.0_7_307_gc14d794=20210420_072542"
conda install $CONDA_FLAGS -c litex-hub/label/main vtr-optimized="8.0.0_3452_ge7d45e013 20210318_102115"
conda install $CONDA_FLAGS -c litex-hub iverilog
conda install $CONDA_FLAGS -c tfors gtkwave
conda install $CONDA_FLAGS make lxml simplejson intervaltree git pip
conda activate
pip install python-constraint
pip install serial
pip install git+https://github.com/QuickLogic-Corp/quicklogic-fasm@318abca
pip install git+https://github.com/QuickLogic-Corp/ql_fasm@e7d0f2fdf5c404b621b24e78fdea51fcb1937672
conda deactivate
