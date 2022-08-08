.. _Packages:

Pre-built architecture files
############################

The Continuous Integration (CI) system in this repository builds and uploads the various Architecture Definition data
files as tarballs.
Those can be used along with yosys, vpr, nextpnr, etc. to synthesize and place-and-route HDL designs.

For each vendor, a common package needs to be extracted.
Then, for each family, an additional package might be required.
For instance, the following script installs packages for all the supported Xilinx 7-Series devices and for QuickLogic's
EOS-S3:

.. sourcecode:: bash

    F4PGA_TIMESTAMP='20220803-160711'
    F4PGA_HASH='df6d9e5'

    case $FPGA_FAM in
      xc7)    F4PGA_PACKAGES='install-xc7 xc7a50t_test xc7a100t_test xc7a200t_test xc7z010_test' ;;
      eos-s3) F4PGA_PACKAGES='install-ql ql-eos-s3_wlcsp' ;;
    esac

    for PKG in $F4PGA_PACKAGES; do
      wget -qO- https://storage.googleapis.com/symbiflow-arch-defs/artifacts/prod/foss-fpga-tools/symbiflow-arch-defs/continuous/install/${F4PGA_TIMESTAMP}/symbiflow-arch-defs-${PKG}-${F4PGA_HASH}.tar.xz \
        | tar -xJC ${F4PGA_INSTALL_DIR}/${FPGA_FAM}
    done

Moreover, a set of text files with links to the latest tarballs is generated and uploaded to both a dedicated
`GCS bucket <https://storage.cloud.google.com/symbiflow-arch-defs-gha/>`__ and as assets of
:gh:`GitHub Release 'latest' <SymbiFlow/f4pga-arch-defs/releases/tag/latest>`.
In order to get those, use the following command in the for loop:

.. sourcecode:: bash

    wget -qO- $(wget -qO- https://github.com/SymbiFlow/f4pga-arch-defs/releases/download/latest/symbiflow-${PKG}-latest) \
      | tar -xJC ${F4PGA_INSTALL_DIR}/${FPGA_FAM}
