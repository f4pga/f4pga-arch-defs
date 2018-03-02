#!/bin/bash

NAME=$(basename $1 .xml)
OUTPUT=$(dirname $1)/$NAME.xml

cat > $OUTPUT <<EOF
 <pb_type name="$NAME">
   <input  name="I" num_pins="1" equivalent="false"/>
   <output name="O" num_pins="1" equivalent="false"/>
   <pb_type name="DUMMY" num_pb="1" blif_model=".subckt DUMMY">
    <input  name="I" num_pins="1" equivalent="false"/>
    <output name="O" num_pins="1" equivalent="false"/>
    <delay_constant in_port="DUMMY.I" max="10e-12" out_port="DUMMY.O"/>
   </pb_type>
   <interconnect>
    <direct name="I" input="$NAME.I" output="DUMMY.I" />
    <direct name="O" input="DUMMY.O" output="$NAME.O" />
   </interconnect>
   <fc default_in_type="frac" default_in_val="1.0" default_out_type="frac" default_out_val="1.0">
    <fc_override fc_type="abs" fc_val="0" segment_name="global" />
   </fc>
   <pinlocations pattern="custom">
    <loc side="right"  xoffset="0" yoffset="0">$NAME.I</loc>
    <loc side="left"   xoffset="0" yoffset="0">$NAME.O</loc>
   </pinlocations>
  </pb_type>
EOF

echo "Generated dummy $OUTPUT"
