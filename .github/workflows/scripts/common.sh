# Make stderr and stdout line buffered.
# stdbuf -i0 -oL -eL

# Close STDERR FD
exec 2<&-
# Redirect STDERR to STDOUT
exec 2>&1

# Some colors, use it like following;
# echo -e "Hello ${YELLOW}yellow${NC}"
GRAY='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

SPACER="echo -e ${GRAY} - ${NC}"

if ! declare -F action_nanoseconds &>/dev/null; then
function action_nanoseconds() {
	return 0;
}
fi
export -f action_nanoseconds
if ! declare -F action_fold &>/dev/null; then
function action_fold() {
	return 0;
}
fi
export -f action_fold
if ! declare -F action_time_start &>/dev/null; then
function action_time_start() {
	return 0;
}
fi
export -f action_time_start
if ! declare -F action_time_finish &>/dev/null; then
function action_time_finish() {
	return 0;
}
fi
export -f action_time_finish
if [ -z "$DATESTR" ]; then
	if [ -z "$DATESHORT" ]; then
		export DATESTR=$(date -u +%Y%m%d%H%M%S)
		echo "Setting long date string of $DATESTR"
	else
		export DATESTR=$(date -u +%y%m%d%H%M)
		echo "Setting short date string of $DATESTR"
	fi
fi

function make_target() {
  target=$1

  if [ ! -v MAKE_JOBS ]; then
    export MAKE_JOBS=$(nproc)
    echo "Setting MAKE_JOBS to $MAKE_JOBS"
  fi;

  export VPR_NUM_WORKERS=${MAKE_JOBS}

  start_section "symbiflow.$target" "$2"
  make_status=0
  make -k -j${MAKE_JOBS} $target || make_status=$?
  end_section "symbiflow.$target"

  # When the build fails, produce the failure output in a clear way
  if [ ${MAKE_JOBS} -ne 1 -a $make_status -ne 0 ]; then
    start_section "symbiflow.failure" "${RED}Build failure output..${NC}"
    make -j1 $target
    end_section "symbiflow.failure"
    exit 1
  else
    return $make_status
  fi
}

function run_section() {
	start_section $1 "$2 ($3)"
	$3
	end_section $1
}

function start_section() {
	action_fold start "$1"
	action_time_start
	echo -e "${PURPLE}SymbiFlow Arch Defs${NC}: - $2${NC}"
	echo -e "${GRAY}-------------------------------------------------------------------${NC}"
}

function end_section() {
	echo -e "${GRAY}-------------------------------------------------------------------${NC}"
	action_time_finish
	action_fold end "$1"
}

export PATH=$PWD/env/conda/bin:$PATH
export CC=gcc-6
export CXX=g++-6
