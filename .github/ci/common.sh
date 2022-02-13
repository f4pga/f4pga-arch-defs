# Make stderr and stdout line buffered.
# stdbuf -i0 -oL -eL

# Close STDERR FD
exec 2<&-
# Redirect STDERR to STDOUT
exec 2>&1

# Some colors, use it like following;
# echo -e "Hello ${YELLOW}yellow${NC}"
GRAY='\033[0;90m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

if ! declare -F action_nanoseconds &>/dev/null; then
function action_nanoseconds() {
  return 0;
}
fi
export -f action_nanoseconds

if ! declare -F action_fold &>/dev/null; then
function action_fold() {
  if [ "$1" = "start" ]; then
    echo "::group::$2"
    SECONDS=0
  else
    duration=$SECONDS
    echo "::endgroup::"
    printf "${GRAY}took $(($duration / 60)) min $(($duration % 60)) sec.${NC}\n"
  fi
  return 0;
}
fi
export -f action_fold

if [ -z "$DATESTR" ]; then
  if [ -z "$DATESHORT" ]; then
    export DATESTR=$(date -u +%Y%m%d%H%M%S)
    echo "Setting long date string of $DATESTR"
  else
    export DATESTR=$(date -u +%y%m%d%H%M)
    echo "Setting short date string of $DATESTR"
  fi
fi

make_target () {
  target=$1
  max_fail_tests=${3:-1}

  if [ ! -v MAX_CORES ]; then
    export MAX_CORES=$(nproc)
    echo "Setting MAX_CORES to $MAX_CORES"
  fi;

  export VPR_NUM_WORKERS=${MAX_CORES}

  start_section "symbiflow.$target" "$2"
  ninja_status=0
  ninja -k$max_fail_tests -j${MAX_CORES} $target || ninja_status=$?
  end_section "symbiflow.$target"

  # When the build fails, produce the failure output in a clear way
  if [ ${MAX_CORES} -ne 1 -a $ninja_status -ne 0 ]; then
    start_section "symbiflow.failure" "${RED}Build failure output..${NC}"
    ninja -j1 $target
    end_section "symbiflow.failure"
    exit 1
  else
    return $ninja_status
  fi
}

run_section () {
  start_section $1 "$2 ($3)"
  $3
  end_section $1
}

start_section () {
  action_fold start "$1"
  echo -e "${PURPLE}SymbiFlow Arch Defs${NC}: - $2${NC}"
  echo -e "${GRAY}-------------------------------------------------------------------${NC}"
}

end_section () {
  echo -e "${GRAY}-------------------------------------------------------------------${NC}"
  action_fold end "$1"
}

enable_vivado () {
  echo
  echo "======================================="
  echo "Creating Vivado Symbolic Link"
  echo "---------------------------------------"
  ln -s /mnt/aux/Xilinx /opt/Xilinx
  ls /opt/Xilinx/Vivado
  export XRAY_VIVADO_SETTINGS="/opt/Xilinx/Vivado/$1/settings64.sh"
  source /opt/Xilinx/Vivado/$1/settings64.sh
  vivado -version
}

heading () {
  echo
  echo "========================================"
  echo "$@"
  echo "----------------------------------------"
}
