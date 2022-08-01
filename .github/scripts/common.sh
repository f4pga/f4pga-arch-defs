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

  export MAX_CORES=${MAX_CORES:-$(nproc)}
  export VPR_NUM_WORKERS=${MAX_CORES}

  echo "MAX_CORES: $MAX_CORES"

  start_section "$2"
    ninja_status=0
    #ninja -k$max_fail_tests -j${MAX_CORES} $target || ninja_status=$?
    ninja -t graph $target | dot -Tpng -o$target.png
    exit 1
  end_section

  # When the build fails, produce the failure output in a clear way
  if [ ${MAX_CORES} -ne 1 -a $ninja_status -ne 0 ]; then
    start_section "${RED}Build failure output..${NC}"
    ninja -j1 $target
    end_section
    exit 1
  fi
  return $ninja_status
}

start_section () {
  echo -e "::group::${PURPLE}[F4PGA] Architecture Definitions${NC}: - $1${NC}"
  SECONDS=0
  echo -e "${GRAY}-------------------------------------------------------------------${NC}"
}

end_section () {
  echo -e "${GRAY}-------------------------------------------------------------------${NC}"
  echo '::endgroup::'
  duration=$SECONDS
  printf "${GRAY}took $(($duration / 60)) min $(($duration % 60)) sec.${NC}\n"
}

enable_vivado () {
  heading 'Creating Vivado Symbolic Link'
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
