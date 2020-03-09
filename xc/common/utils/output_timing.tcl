set timing_utils [lindex $argv 0]
set timing_json [lindex $argv 1]

source $timing_utils
output_timing $timing_json
