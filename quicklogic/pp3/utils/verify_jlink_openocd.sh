#!/bin/bash

# look for duplicated configuration cript footer,
# exit with 1 if duplicate found (bad script format)

# $1 - jlink/openocd script
# $2 - output file


cat $1 | grep '0x40004d[0-9]\{2\}' |  awk '{print $2}' | sort | uniq -d > $2
[ -s $2 ] && exit 1 || exit 0
