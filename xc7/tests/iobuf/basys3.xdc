set_property PACKAGE_PIN V17 [get_ports in[ 0]]
set_property PACKAGE_PIN V16 [get_ports in[ 1]]
set_property PACKAGE_PIN W16 [get_ports in[ 2]]
set_property PACKAGE_PIN W17 [get_ports in[ 3]]
set_property PACKAGE_PIN W15 [get_ports in[ 4]]
set_property PACKAGE_PIN V15 [get_ports in[ 5]]
set_property PACKAGE_PIN W14 [get_ports in[ 6]]
set_property PACKAGE_PIN W13 [get_ports in[ 7]]
set_property PACKAGE_PIN V2  [get_ports in[ 8]]
set_property PACKAGE_PIN T3  [get_ports in[ 9]]
set_property PACKAGE_PIN T2  [get_ports in[10]]
set_property PACKAGE_PIN R3  [get_ports in[11]]

set_property PACKAGE_PIN U16 [get_ports out[ 0]]
set_property PACKAGE_PIN E19 [get_ports out[ 1]]
set_property PACKAGE_PIN U19 [get_ports out[ 2]]
set_property PACKAGE_PIN V19 [get_ports out[ 3]]
set_property PACKAGE_PIN W18 [get_ports out[ 4]]
set_property PACKAGE_PIN U15 [get_ports out[ 5]]
set_property PACKAGE_PIN U14 [get_ports out[ 6]]
set_property PACKAGE_PIN V14 [get_ports out[ 7]]
set_property PACKAGE_PIN V13 [get_ports out[ 8]]
set_property PACKAGE_PIN V3  [get_ports out[ 9]]
set_property PACKAGE_PIN W3  [get_ports out[10]]
set_property PACKAGE_PIN U3  [get_ports out[11]]

set_property PACKAGE_PIN K17 [get_ports jc1]
set_property PACKAGE_PIN M18 [get_ports jc2]
set_property PACKAGE_PIN N17 [get_ports jc3]

foreach port [get_ports] {
    set_property IOSTANDARD LVCMOS33 $port
    set_property SLEW FAST $port
}
