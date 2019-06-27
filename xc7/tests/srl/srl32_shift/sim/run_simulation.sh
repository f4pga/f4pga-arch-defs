#!/bin/bash
iverilog -c sim_sources.cf -s tb -DSIMULATION -o tb.vvp -v

if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit -1
fi

vvp tb.vvp

