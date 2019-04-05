#!/bin/bash

usage() {
  if [ -n "$1" ]; then
    echo "$1" > /dev/stderr;
  fi
  echo "Usage: $0 -y <yapf_exec> [-c] [-f]" > /dev/stderr
  exit 1
}

run() {
  eval $1
  res=$?
  if [[ $res != 0 ]]; then
    echo $2 > /dev/stderr
  fi
  return $res
  }

check_file() {
  run "$1 -d $2 > /dev/null" "yapf needs to reformat $2"
  return $?
}

format_file() {
  run "$1 -i $2" "yapf failed to format $2"
  return $?
}

do_check=0;
do_format=0;

YAPF=yapf
while getopts "cfy:" opt; do
  case $opt in
    c)
      do_check=1;
      ;;
    f)
      do_format=1;
      ;;
    y)
      YAPF=$OPTARG
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND - 1))

if [ -n "$*" ]; then
  usage "leftover args: '$*'"
fi

if [ $do_check == $do_format ]; then
  usage "Provide exactly one option"
fi

ret=0
# using git will only check and format files in the git index. This avoids
# formatting temporary files and files in submodules
TOP_DIR=`git rev-parse --show-toplevel`
for file in $(git ls-tree --full-tree --name-only -r HEAD | grep "\.py$"); do
  if [ $do_check != 0 ]; then
    check_file $YAPF $TOP_DIR/$file;
    res=$?
  elif [ $do_format != 0 ]; then
    format_file $YAPF $TOP_DIR/$file;
    res=$?
  fi;

  if [[ $res != 0 ]]; then
    ((ret++))
  fi
done

exit $ret
