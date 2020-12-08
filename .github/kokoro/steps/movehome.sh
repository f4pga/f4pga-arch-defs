#!/bin/bash

echo
echo "========================================"
echo "Moving home directory."
echo "----------------------------------------"
echo
echo "Old home directory: ${HOME}"
echo
mkdir home
cp -r $HOME/. home/
export HOME=$(pwd)/home
echo "New home directory: ${HOME}"
echo "                    $(echo ~/)"
