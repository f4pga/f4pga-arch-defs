#!/bin/bash
#
# Copyright (C) 2021  Symbiflow Authors.
#
# Use of this source code is governed by a ISC-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/ISC
#
# SPDX-License-Identifier: ISC

# Fix up things related to Xilinx tool chain.

ls -l ~/.Xilinx
sudo chown -R $USER ~/.Xilinx

export XILINX_LOCAL_USER_DATA=no

echo "========================================"
echo "Mounting image with Vivado 2020.2"
echo "----------------------------------------"
sudo mkdir -p /opt/Xilinx2020_2
sudo mount UUID=998e6c94-9f32-48cf-8d7b-74f70d97e332 /opt/Xilinx2020_2
export URAY_VIVADO_SETTINGS=/opt/Xilinx2020_2/Vivado/2020.2/settings64.sh
