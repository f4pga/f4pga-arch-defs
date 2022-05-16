#!/bin/bash -e
if [[ $VERBOSE -gt 0 ]]; then
  set -x
fi

OUTPUT=$(mktemp $(basename $1).output.XXX)

set +e
"$@" > $OUTPUT 2>&1
RESULT=$?
set -e
if [[ $RESULT -ne 0 ]]  || [[ $VERBOSE -gt 0 ]]; then
  cat $OUTPUT
fi
rm $OUTPUT
exit $RESULT
