#!/bin/bash
INPUT_DIRS="adder dff lut2 ."
THIS_TOP="tests"

for dir in $INPUT_DIRS; do
	if [ "$dir" = "." ]; then
		TOP=$THIS_TOP
	else
		TOP=$dir
	fi
	../vlog_to_model.py --top $TOP -o ${dir}/${TOP}.model.xml ${dir}/${TOP}.sim.v
	../vlog_to_pbtype.py --top $TOP -o ${dir}/${TOP}.pb_type.xml ${dir}/${TOP}.sim.v
done

xmllint --xinclude --nsclean --noblanks --format ./tests.pb_type.xml > ./merged.xml
