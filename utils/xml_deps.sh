#!/bin/bash

UTILS_SRC="$(realpath ${BASH_SOURCE[0]})"
UTILS_DIR="$(dirname "${UTILS_SRC}")"
TOP_DIR="$(realpath "${UTILS_DIR}/..")"

OUTPUT_FILE=$1
INPUT_FILE=$2

(
	# Declare a dep on us
	echo "$OUTPUT_FILE: $UTILS_SRC"
	echo ""

	# Figure out all included files
	TO_VISIT=($INPUT_FILE)
	INDEX=0
	while [ "x${TO_VISIT[INDEX]}" != "x" ]
	do
		FILE=${TO_VISIT[INDEX]}
		INCLUDES=$(grep 'xi:include' $FILE | sed -e's/.*href="\([^"]*\)".*/\1/g')
		TO_VISIT+=($INCLUDES)
		INDEX=$(( $INDEX + 1 ))
	done

	# Declare deps on included files
	INDEX=1
	while [ "x${TO_VISIT[INDEX]}" != "x" ]
	do
		FILE="$(realpath ${TO_VISIT[INDEX]})"
		echo "${TO_VISIT[0]}: $FILE"
		echo "$OUTPUT_FILE: $FILE"
		echo ""
		INDEX=$(( $INDEX + 1 ))
	done
) > $OUTPUT_FILE
