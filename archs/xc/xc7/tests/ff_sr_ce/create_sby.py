import argparse
import sys


def write_template(f, num_ff, ff_type):
    template = """
[options]
mode prove
depth 50
timeout 600
aigsmt z3

[engines]
abc pdr

[script]
read_verilog +/xilinx/cells_sim.v
read_verilog -sv ff_type.v
read_verilog -sv ff_ce_sr_{num_ff}_{ff_type}.v
rename top gold
read_verilog -sv top_bit.v
rename top gate
miter -equiv -make_assert gold gate miter
prep -top miter

[files]
ff_ce_sr_{num_ff}_{ff_type}/artix7-xc7a50t-basys3-roi-virt-xc7a50t-basys3-test/top_bit.v
ff_ce_sr_{num_ff}_{ff_type}.v
ff_type.v
"""
    print(template.format(num_ff=num_ff, ff_type=ff_type, file=f))


def main():
    parser = argparse.ArgumentParser(
        description="Creates SymbiYosys project file for proving FF CE/SR."
    )
    parser.add_argument('--num_ff', required=True, type=int)
    parser.add_argument('--ff_type', required=True)

    args = parser.parse_args()

    write_template(f=sys.stdout, num_ff=args.num_ff, ff_type=args.ff_type)


if __name__ == "__main__":
    main()
