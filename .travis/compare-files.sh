#!/bin/bash

source .travis/common.sh

SORT="sort -s"

# Get a list of current files
CURRENT_FILES=$(mktemp --suffix=.current.files)
echo -e "Files which *currently* exist" > $CURRENT_FILES
echo "-------------------" >> $CURRENT_FILES
utils/listfiles.py | sed -e"s@^$PWD/@@" | $SORT >> $CURRENT_FILES

# Get a list of possible files
POSSIBLE_FILES=$(mktemp --suffix=.possible.files)
echo -e "Files which *could* exist" > $POSSIBLE_FILES
echo "-------------------" >> $POSSIBLE_FILES
make files | $SORT >> $POSSIBLE_FILES

colordiff \
	--side-by-side \
	-W 200 \
	\
	$CURRENT_FILES $POSSIBLE_FILES

$SPACER

git status

$SPACER

rm -f $CURRENT_FILES $POSSIBLE_FILES
