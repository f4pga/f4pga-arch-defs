#!/bin/bash
INPUT_DIRS="adder dff lut2 ."
THIS_TOP="test_pb"

for dir in $INPUT_DIRS; do
	if [ "$dir" = "." ]; then
		TOP=$THIS_TOP
	else
		TOP=$dir
	fi
	../vlog_to_model.py --top $TOP -o ${dir}/model.xml ${dir}/sim.v
	../vlog_to_pbtype.py --top $TOP -o ${dir}/pb_type.xml ${dir}/sim.v
done

xmllint --xinclude --nsclean --noblanks --format ./pb_type.xml > ./merged.xml
