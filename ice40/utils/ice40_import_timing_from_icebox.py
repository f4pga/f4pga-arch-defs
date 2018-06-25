#!/usr/bin/env python3
#
#  Copyright (C) 2018  Tim 'mithro' Ansell <me@mith.ro>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
"""
Import the timing information from icebox into the following forms;

 * Stuff Verilog to Routing can use
 * [Standard Delay Format (SDF) format](https://en.wikipedia.org/wiki/Standard_Delay_Format) (for usage with .sim.v) models.



--



icestorm/icefuzz/timings_hx1k.html

"""


"""

# Standard Delay Format

Standard Delay Format (SDF) is an IEEE standard for the representation and
interpretation of timing data for use at any stage of an electronic design
process. It finds wide applicability in design flows, and forms an efficient
bridge between Dynamic timing verification and Static timing analysis

It has usually two sections: one for interconnect delays and the other for cell delays.

SDF format can be used for back-annotation as well as forward-annotation.



## Header

```
(DELAYFILE
    (SDFVERSION "2.1")
    (DESIGN "top")
    (VENDOR "verilog-to-routing")
    (PROGRAM "vpr")
    (VERSION "8.0.0-dev+vpr-7.0.5-6031-gc3f04a1d2-dirty")
    (DIVIDER /)
    (TIMESCALE 1 ps)
```

```
        //Writes out the SDF
        void print_sdf(int depth=0) {
            sdf_os_ << indent(depth) << "(DELAYFILE\n";
            sdf_os_ << indent(depth+1) << "(SDFVERSION \"2.1\")\n";
            sdf_os_ << indent(depth+1) << "(DESIGN \""<< top_module_name_ << "\")\n";
            sdf_os_ << indent(depth+1) << "(VENDOR \"verilog-to-routing\")\n";
            sdf_os_ << indent(depth+1) << "(PROGRAM \"vpr\")\n";
            sdf_os_ << indent(depth+1) << "(VERSION \"" << vtr::VERSION << "\")\n";
            sdf_os_ << indent(depth+1) << "(DIVIDER /)\n";
            sdf_os_ << indent(depth+1) << "(TIMESCALE 1 ps)\n";
            sdf_os_ << "\n";

            //Interconnect
            for(const auto& kv : logical_net_sinks_) {
                auto atom_net_id = kv.first;
                auto driver_iter = logical_net_drivers_.find(atom_net_id);
                VTR_ASSERT(driver_iter != logical_net_drivers_.end());
                auto driver_wire = driver_iter->second.first;
                auto driver_tnode = driver_iter->second.second;

                for(auto& sink_wire_tnode_pair : kv.second) {
                    auto sink_wire = sink_wire_tnode_pair.first;
                    auto sink_tnode = sink_wire_tnode_pair.second;

                    sdf_os_ << indent(depth+1) << "(CELL\n";
                    sdf_os_ << indent(depth+2) << "(CELLTYPE \"fpga_interconnect\")\n";
                    sdf_os_ << indent(depth+2) << "(INSTANCE " << escape_sdf_identifier(interconnect_name(driver_wire, sink_wire)) << ")\n";
                    sdf_os_ << indent(depth+2) << "(DELAY\n";
                    sdf_os_ << indent(depth+3) << "(ABSOLUTE\n";

                    double delay = get_delay_ps(driver_tnode, sink_tnode);

                    std::stringstream delay_triple;
                    delay_triple << "(" << delay << ":" << delay << ":" << delay << ")";

                    sdf_os_ << indent(depth+4) << "(IOPATH datain dataout " << delay_triple.str() << " " << delay_triple.str() << ")\n";
                    sdf_os_ << indent(depth+3) << ")\n";
                    sdf_os_ << indent(depth+2) << ")\n";
                    sdf_os_ << indent(depth+1) << ")\n";
                    sdf_os_ << indent(depth) << "\n";
                }
            }

            //Cells
            for(const auto& inst : cell_instances_) {
                inst->print_sdf(sdf_os_, depth+1);
            }

            sdf_os_ << indent(depth) << ")\n";
        }
```

## Escaping

//Escapes the given identifier to be safe for verilog
std::string escape_verilog_identifier(const std::string identifier) {
    //Verilog allows escaped identifiers
    //
    //The escaped identifiers start with a literal back-slash '\'
    //followed by the identifier and are terminated by white space
    //
    //We pre-pend the escape back-slash and append a space to avoid
    //the identifier gobbling up adjacent characters like commas which
    //are not actually part of the identifier
    std::string prefix = "\\";
    std::string suffix = " ";
    std::string escaped_name = prefix + identifier + suffix;

    return escaped_name;
}

//Returns true if c is categorized as a special character in SDF
bool is_special_sdf_char(char c) {
    //From section 3.2.5 of IEEE1497 Part 3 (i.e. the SDF spec)
    //Special characters run from:
    //    ! to # (ASCII decimal 33-35)
    //    % to / (ASCII decimal 37-47)
    //    : to @ (ASCII decimal 58-64)
    //    [ to ^ (ASCII decimal 91-94)
    //    ` to ` (ASCII decimal 96)
    //    { to ~ (ASCII decimal 123-126)
    //
    //Note that the spec defines _ (decimal code 95) and $ (decimal code 36)
    //as non-special alphanumeric characters.
    //
    //However it inconsistently also lists $ in the list of special characters.
    //Since the spec allows for non-special characters to be escaped (they are treated
    //normally), we treat $ as a special character to be safe.
    //
    //Note that the spec appears to have rendering errors in the PDF availble
    //on IEEE Xplore, listing the 'LEFT-POINTING DOUBLE ANGLE QUOTATION MARK'
    //character (decimal code 171) in place of the APOSTROPHE character '
    //with decimal code 39 in the special character list. We assume code 39.
    if((c >= 33 && c <= 35) ||
       (c == 36) || // $
       (c >= 37 && c <= 47) ||
       (c >= 58 && c <= 64) ||
       (c >= 91 && c <= 94) ||
       (c == 96) ||
       (c >= 123 && c <= 126)) {
        return true;
    }

    return false;
}

//Escapes the given identifier to be safe for sdf
std::string escape_sdf_identifier(const std::string identifier) {
    //SDF allows escaped characters
    //
    //We look at each character in the string and escape it if it is
    //a special character
    std::string escaped_name;

    for(char c : identifier) {
        if(is_special_sdf_char(c)) {
            //Escape the special character
            escaped_name += '\\';
        }
        escaped_name += c;
    }

    return escaped_name;
}

## Interconnect

 ???

```sdf
    (CELL
        (CELLTYPE "fpga_interconnect")
        (INSTANCE routing_segment_clk_output_0_0_to_SB_DFF_\$auto\$simplemap\.cc\:420\:simplemap_dff\$87_clock_0_0)
        (DELAY
            (ABSOLUTE
                (IOPATH datain dataout (1.35e+13:1.35e+13:1.35e+13) (1.35e+13:1.35e+13:1.35e+13))
            )
        )
    )
```



## LUT

```cpp
        void print_sdf(std::ostream& os, int depth) override {
            os << indent(depth) << "(CELL\n";
            os << indent(depth+1) << "(CELLTYPE \"" << type() << "\")\n";
            os << indent(depth+1) << "(INSTANCE " << escape_sdf_identifier(instance_name()) << ")\n";

            if(!timing_arcs().empty()) {
                os << indent(depth+1) << "(DELAY\n";
                os << indent(depth+2) << "(ABSOLUTE\n";

                for(auto& arc : timing_arcs()) {
                    double delay_ps = arc.delay();

                    std::stringstream delay_triple;
                    delay_triple << "(" << delay_ps << ":" << delay_ps << ":" << delay_ps << ")";

                    os << indent(depth+3) << "(IOPATH ";
                    //Note we do not escape the last index of multi-bit signals since they are used to
                    //match multi-bit ports
                    os << escape_sdf_identifier(arc.source_name()) << "[" << arc.source_ipin() << "]" << " ";

                    VTR_ASSERT(arc.sink_ipin() == 0); //Should only be one output
                    os << escape_sdf_identifier(arc.sink_name()) << " ";
                    os << delay_triple.str() << " " << delay_triple.str() << ")\n";
                }
                os << indent(depth+2) << ")\n";
                os << indent(depth+1) << ")\n";
            }

            os << indent(depth) << ")\n";
            os << indent(depth) << "\n";
        }
```

```sdf
    (CELL
        (CELLTYPE "LUT_K")
        (INSTANCE lut_\$abc\$1289\$n57_1)
        (DELAY
            (ABSOLUTE
                (IOPATH in[0] out (10:10:10) (10:10:10))
                (IOPATH in[1] out (10:10:10) (10:10:10))
                (IOPATH in[2] out (10:10:10) (10:10:10))
                (IOPATH in[3] out (10:10:10) (10:10:10))
            )
        )
    )
```


## Latch

```cpp
        void print_sdf(std::ostream& os, int depth=0) override {
            VTR_ASSERT(type_ == Type::RISING_EDGE);

            os << indent(depth) << "(CELL\n";
            os << indent(depth+1) << "(CELLTYPE \"" << "DFF" << "\")\n";
            os << indent(depth+1) << "(INSTANCE " << escape_sdf_identifier(instance_name_) << ")\n";

            //Clock to Q
            if(!std::isnan(tcq_)) {
                os << indent(depth+1) << "(DELAY\n";
                os << indent(depth+2) << "(ABSOLUTE\n";
                    double delay_ps = get_delay_ps(tcq_);

                    std::stringstream delay_triple;
                    delay_triple << "(" << delay_ps << ":" << delay_ps << ":" << delay_ps << ")";

                    os << indent(depth+3) << "(IOPATH " << "(posedge clock) Q " << delay_triple.str() << " " << delay_triple.str() << ")\n";
                os << indent(depth+2) << ")\n";
                os << indent(depth+1) << ")\n";
            }

            //Setup/Hold
            if(!std::isnan(tsu_) || !std::isnan(thld_)) {
                os << indent(depth+1) << "(TIMINGCHECK\n";
                if(!std::isnan(tsu_)) {
                    std::stringstream setup_triple;
                    double setup_ps = get_delay_ps(tsu_);
                    setup_triple << "(" << setup_ps << ":" << setup_ps << ":" << setup_ps << ")";
                    os << indent(depth+2) << "(SETUP D (posedge clock) " << setup_triple.str() << ")\n";
                }
                if(!std::isnan(thld_)) {
                    std::stringstream hold_triple;
                    double hold_ps = get_delay_ps(thld_);
                    hold_triple << "(" << hold_ps << ":" << hold_ps << ":" << hold_ps << ")";
                    os << indent(depth+2) << "(HOLD D (posedge clock) " << hold_triple.str() << ")\n";
                }
            }
            os << indent(depth+1) << ")\n";
            os << indent(depth) << ")\n";
            os << indent(depth) << "\n";
        }
```

## Blackbox

```cpp
        void print_sdf(std::ostream& os, int depth=0) override {
            os << indent(depth) << "(CELL\n";
            os << indent(depth+1) << "(CELLTYPE \"" << type_name_ << "\")\n";
            os << indent(depth+1) << "(INSTANCE " << escape_sdf_identifier(inst_name_) << ")\n";
            os << indent(depth+1) << "(DELAY\n";

            if(!timing_arcs_.empty() || !ports_tcq_.empty()) {
                os << indent(depth+2) << "(ABSOLUTE\n";

                //Combinational paths
                for(const auto& arc : timing_arcs_) {
                    double delay_ps = get_delay_ps(arc.delay());

                    std::stringstream delay_triple;
                    delay_triple << "(" << delay_ps << ":" << delay_ps << ":" << delay_ps << ")";

                    //Note that we explicitly do not escape the last array indexing so an SDF
                    //reader will treat the ports as multi-bit
                    //
                    //We also only put the last index in if the port has multiple bits
                    os << indent(depth+3) << "(IOPATH ";
                    os << escape_sdf_identifier(arc.source_name());
                    if(find_port_size(arc.source_name()) > 1) {
                        os << "[" << arc.source_ipin() << "]";
                    }
                    os << " ";
                    os << escape_sdf_identifier(arc.sink_name());
                    if(find_port_size(arc.sink_name()) > 1) {
                        os << "[" << arc.sink_ipin() << "]";
                    }
                    os << " ";
                    os << delay_triple.str();
                    os << ")\n";
                }

                //Clock-to-Q delays
                for(auto kv : ports_tcq_) {
                    double clock_to_q_ps = get_delay_ps(kv.second);

                    std::stringstream delay_triple;
                    delay_triple << "(" << clock_to_q_ps << ":" << clock_to_q_ps << ":" << clock_to_q_ps << ")";

                    os << indent(depth+3) << "(IOPATH (posedge clock) " << escape_sdf_identifier(kv.first) << " " << delay_triple.str() << " " << delay_triple.str() << ")\n";
                }
                os << indent(depth+2) << ")\n"; //ABSOLUTE
            }
            os << indent(depth+1) << ")\n"; //DELAY

            if(!ports_tsu_.empty() || !ports_thld_.empty()) {
                //Setup checks
                os << indent(depth+1) << "(TIMINGCHECK\n";
                for(auto kv : ports_tsu_) {
                    double setup_ps = get_delay_ps(kv.second);

                    std::stringstream delay_triple;
                    delay_triple << "(" << setup_ps << ":" << setup_ps << ":" << setup_ps << ")";

                    os << indent(depth+2) << "(SETUP " << escape_sdf_identifier(kv.first) << " (posedge clock) " << delay_triple.str() << ")\n";
                }
                for(auto kv : ports_thld_) {
                    double hold_ps = get_delay_ps(kv.second);

                    std::stringstream delay_triple;
                    delay_triple << "(" << hold_ps << ":" << hold_ps << ":" << hold_ps << ")";

                    os << indent(depth+2) << "(HOLD " << escape_sdf_identifier(kv.first) << " (posedge clock) " << delay_triple.str() << ")\n";
                }
                os << indent(depth+1) << ")\n"; //TIMINGCHECK
            }
            os << indent(depth) << ")\n"; //CELL
        }
```

```sdf
    (CELL
        (CELLTYPE "SB_DFF")
        (INSTANCE SB_DFF_\$auto\$simplemap\.cc\:420\:simplemap_dff\$87)
        (DELAY
        )
    )
```

"""







"""
Verilog to Routing Timing models

The best documentation to understand Verilog to Routing Timing models is the
[Primitive Block Timing Modeling Tutorial](https://docs.verilogtorouting.org/en/latest/tutorials/arch/timing_modeling/#arch-model-timing-tutorial).

There is also useful information in the
[Post-Implementation Timing Simulation](https://docs.verilogtorouting.org/en/latest/tutorials/timing_simulation/)
section of the docs.


## [Combinational Block](https://docs.verilogtorouting.org/en/latest/tutorials/arch/timing_modeling/#arch-model-timing-tutorial)

```
<model name="adder">
  <input_ports>
    <port name="a" combinational_sink_ports="sum cout"/>
    <port name="b" combinational_sink_ports="sum cout"/>
    <port name="cin" combinational_sink_ports="sum cout"/>
  </input_ports>
  <output_ports>
    <port name="sum"/>
    <port name="cout"/>
  </output_ports>
</model>

<pb_type name="adder" blif_model=".subckt adder" num_pb="1">
  <input name="a" num_pins="1"/>
  <input name="b" num_pins="1"/>
  <input name="cin" num_pins="1"/>
  <output name="cout" num_pins="1"/>
  <output name="sum" num_pins="1"/>

  <delay_constant max="300e-12" in_port="adder.a" out_port="adder.sum"/>
  <delay_constant max="300e-12" in_port="adder.b" out_port="adder.sum"/>
  <delay_constant max="300e-12" in_port="adder.cin" out_port="adder.sum"/>
  <delay_constant max="300e-12" in_port="adder.a" out_port="adder.cout"/>
  <delay_constant max="300e-12" in_port="adder.b" out_port="adder.cout"/>
  <delay_constant max="10e-12" in_port="adder.cin" out_port="adder.cout"/>
</pb_type>
```

## [Sequential block (no internal paths)](https://docs.verilogtorouting.org/en/latest/tutorials/arch/timing_modeling/#sequential-block-no-internal-paths)

```
<model name="dff">
  <input_ports>
    <port name="d" clock="clk"/>
    <port name="clk" is_clock="1"/>
  </input_ports>
  <output_ports>
    <port name="q" clock="clk/>
  </output_ports>
</model>

<pb_type name="ff" blif_model=".subckt dff" num_pb="1">
  <input name="D" num_pins="1"/>
  <output name="Q" num_pins="1"/>
  <clock name="clk" num_pins="1"/>

  <T_setup value="66e-12" port="ff.D" clock="clk"/>
  <T_clock_to_Q max="124e-12" port="ff.Q" clock="clk"/>
</pb_type>
```

# Interconnect Timing

## Nodes

```<timing R="float" C="float">```

This optional subtag contains information used for timing analysis

Required Attributes:
 * R - The resistance that goes through this node. This is only the metal
       resistance, it does not include the resistance of the switch that leads
       to another routing resource node.

 * C - The total capacitance of this node. This includes the metal capacitance,
       input capacitance of all the switches hanging off the node, the output
       capacitance of all the switches to the node, and the connection box
       buffer capacitances that hangs off it.

## Switches


```<timing R="float" cin="float" Cout="float" Tdel="float/>```

This optional subtag contains information used for timing analysis. Without it,
the program assums all subtags to contain a value of 0.

Optional Attributes:
 * R, Cin, Cout – The resistance, input capacitance and output capacitance of the switch.
 * Tdel – Switch’s intrinsic delay. It can be outlined that the delay through an unloaded switch is Tdel + R * Cout.

```<sizing mux_trans_size="int" buf_size="float"/>```

The sizing information contains all the information needed for area calculation.
Required Attributes:
 * mux_trans_size – The area of each transistor in the segment’s driving mux. This is measured in minimum width transistor units.
 * buf_size – The area of the buffer. If this is set to zero, the area is calculated from the resistance.

## Segments

```<timing R_per_meter="float" C_per_meter="float">```
This optional tag defines the timing information of this segment.

Optional Attributes:
 * R_per_meter, C_per_meter – The resistance and capacitance of a routing track, per unit logic block length.



```
<delay_constant max="float" min="float" in_port="string" out_port="string"/>
```


Describe a timing matrix for all edges going from in_port to out_port.

 * Number of rows of matrix should equal the number of inputs,
 * Number of columns should equal the number of outputs.

To specify both max and min delays two <delay_matrix> should be used.

Example: The following defines a delay matrix for a 4-bit input port in, and
3-bit output port out:
```xml
<delay_matrix type="max" in_port="in" out_port="out">
    1.2e-10 1.4e-10 3.2e-10
    4.6e-10 1.9e-10 2.2e-10
    4.5e-10 6.7e-10 3.5e-10
    7.1e-10 2.9e-10 8.7e-10
</delay>
```

```
<T_setup value="float" port="string" clock="string"/>
<T_hold value="float" port="string" clock="string"/>
<T_clock_to_Q max="float" min="float" port="string" clock="string"/>
```

```
<pb_type name="seq_foo" blif_model=".subckt seq_foo" num_pb="1">
    <input name="in" num_pins="4"/>
    <output name="out" num_pins="1"/>
    <clock name="clk" num_pins="1"/>

    <!-- external -->
    <T_setup value="80e-12" port="seq_foo.in" clock="clk"/>
    <T_clock_to_Q max="20e-12" port="seq_foo.out" clock="clk"/>

    <!-- internal -->
    <T_clock_to_Q max="10e-12" port="seq_foo.in" clock="clk"/>
    <delay_constant max="0.9e-9" in_port="seq_foo.in" out_port="seq_foo.out"/>
    <T_setup value="90e-12" port="seq_foo.out" clock="clk"/>
</pb_type>
```

```
<model name="simple_pll">
  <input_ports>
    <port name="in_clock" is_clock="1"/>
  <input_ports/>
  <output_ports>
    <port name="out_clock" is_clock="1"/>
  <output_ports/>
</model>
```



<clock C_wire="float" C_wire_per_m="float" buffer_size={"float"|"auto"}/>
Optional Attributes:
 * C_wire – The absolute capacitance, in Farads, of the wire between each clock buffer.
 * C_wire_per_m – The wire capacitance, in Farads per Meter.
 * buffer_size – The size of each clock buffer.

"""



