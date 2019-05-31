import argparse

CARRY_TEMPLATE = r"""module top (
    input clk,
    input carry_fabric,
    output out
);
    wire [{depth}-1:0] a;
    wire [{depth}-1:0] b;
    wire [{depth}-1:0] c;

    LFSR #(.POLY(5)) a_src(
        .clk(clk),
        .out(a)
        );

    LFSR #(.POLY(9)) b_src(
        .clk(clk),
        .out(b)
        );

    assign carry = {carry};
    assign c = a + b + carry;
    assign out = c[{depth}-1];
endmodule

module LFSR (
    input clk,
    output [{depth}-1:0] out
    );
    parameter POLY = 1;

    reg [{depth}-1:0] r = 1;
    assign out = r;
    wire f;
    assign f = ^(POLY & ~r);
    always @( posedge clk)
      r <= {{r[{depth}-1:1], ~f}};
endmodule"""


def main():
    parser = argparse.ArgumentParser(
        description="Generates top.v for carry stress test."
    )

    parser.add_argument('--init', choices=['0', '1', 'fabric'], required=True)
    parser.add_argument('--carry_depth', type=int, required=True)

    args = parser.parse_args()

    carry = args.init
    if args.init == 'fabric':
        carry = 'carry_fabric'

    print(CARRY_TEMPLATE.format(
        carry=carry,
        depth=args.carry_depth,
    ))


if __name__ == '__main__':
    main()
