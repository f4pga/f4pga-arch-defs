#!/bin/bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"

ROOT_DIR=$(realpath $CURRENT_DIR/../../../../../)
IBEX_DIR=$ROOT_DIR/third_party/ibex
RELATIVE_IBEX_DIR=$(realpath --relative-to $ROOT_DIR $CURRENT_DIR)
IBEX_TEST_BUILD_DIR=$(realpath $ROOT_DIR/build/$RELATIVE_IBEX_DIR)

LOG_FILE=$IBEX_TEST_BUILD_DIR/generate.log

help () {
   echo ""
   echo "Generates sources for the Ibex example and copies them to the example build directory"
   echo ""
   echo "Usage: $0 [--only-deps]"
   echo "    --only-deps"
   echo "        If only-deps flag is supplied script prints the dependencies"
   echo "        to stdout without copying the source files to the build directory"
}

# Validate arguments

if [ "$#" == 1 ] && [ "$1" == "--only-deps" ]; then
    ONLY_DEPS=true
fi

if [ $# -ge 1 ] && [ "$1" != "--only-deps" ]; then
   help
   exit 1
fi

# Save reference to stdout

exec 3<&1

# Redirect stdout and stderr to log file

touch $LOG_FILE
exec &>$LOG_FILE

# Create temporary directory for applying patches

TMP_DIR=$(mktemp -d)
IBEX_TMP_DIR=$TMP_DIR/ibex

# Copy ibex directory to tmp directory

cp -r $IBEX_DIR $IBEX_TMP_DIR

# Apply patches

cd $IBEX_TMP_DIR
patch -p1 < $CURRENT_DIR/ibex.patch
fusesoc --cores-root=$IBEX_TMP_DIR run --target=synth --setup lowrisc:ibex:top_artya7 --part xc7a35ticsg324-1L

# Get a list of the source files

EDA_YAML_PATH=$IBEX_TMP_DIR/build/lowrisc_ibex_top_artya7_0.1/synth-vivado/lowrisc_ibex_top_artya7_0.1.eda.yml

if [ ! -e $EDA_YAML_PATH ]; then
  echo "ERROR: Wrong path to EDA YAML file!"
  echo "Check if the main lowrisc_ibex_top_artya7_x version is still valid!"
fi

if [ $ONLY_DEPS ]; then
    # Redirect output to stdout
    exec 1>&3
    python3 $ROOT_DIR/utils/fusesoc_get_sources.py $EDA_YAML_PATH
else
    DEPS=$(python3 $ROOT_DIR/utils/fusesoc_get_sources.py $EDA_YAML_PATH)
    for file in $DEPS;
    do
        find $IBEX_TMP_DIR/build -name $file -exec cp {} $IBEX_TEST_BUILD_DIR/ \; \
            -exec echo "Copying $file ... " \;
    done

    # Redirect output to stdout
    exec 1>&3
    cat $LOG_FILE
fi

# Remove generated tmp directory

rm -rf $IBEX_TMP_DIR
