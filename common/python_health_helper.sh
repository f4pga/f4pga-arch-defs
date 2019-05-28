#!/bin/bash

usage() {
  if [ -n "$1" ]; then
    echo "$1" > /dev/stderr;
  fi
  echo "Usage: $0 -y <yapf_exec> -p lint_program<> [-l|-c|-f]" > /dev/stderr
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

lint_file() {
  run "$1 $2" "lint failed on $2"
  return $?
}

check_file() {
  run "$1 -d $2 > /dev/null" "yapf needs to reformat $2"
  return $?
}

format_file() {
  run "$1 -i $2" "yapf failed to format $2"
  return $?
}

do_check=0
do_format=0
do_lint=0

yapf_exec=yapf
lint_exec=pyflakes
while getopts "lcfy:p:" opt; do
  case $opt in
    c)
      do_check=1;
      ;;
    f)
      do_format=1;
      ;;
    y)
      yapf_exec=$OPTARG
      ;;
    p)
      lint_exec=$OPTARG
      ;;
    l)
      do_lint=1;
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

if (( do_check + do_format + do_lint != 1 )); then
  usage "Provide exactly one option"
fi

ret=0
# using git will only check and format files in the git index. This avoids
# formatting temporary files and files in submodules
TOP_DIR=`git rev-parse --show-toplevel`
for file in $(git ls-tree --full-tree --name-only -r HEAD | grep "\.py$"); do
  if [ $do_check != 0 ]; then
    check_file $yapf_exec $TOP_DIR/$file;
    res=$?
  elif [ $do_format != 0 ]; then
    format_file "$yapf_exec" $TOP_DIR/$file;
    res=$?
  elif [ $do_lint != 0 ]; then
    lint_file "$lint_exec" $TOP_DIR/$file;
    res=$?
  fi;

  if [[ $res != 0 ]]; then
    ((ret++))
  fi
done

exit $ret
