#!/usr/bin/env python3
"""
Generates a number of random MMCM configuration cases.

The scripts uses Jinja2 template of a MMCM design to generate the given number
of random MMCM configurations. Generated designs are intended to be used for
verification of MMCM register content calculation perforemd in VPR techmap.
"""
import argparse
import random
from collections import namedtuple

import jinja2

# =============================================================================

ClkOut = namedtuple("ClkOut", "index enabled divide duty phase")

# =============================================================================


def generate_case():
    """
    Generates a single set of parameters for MMCM
    """

    def gen_mult_and_phase(frac_en):
        """
        For CLKFBOUT
        """

        # Fractional multiplier ranges from 2.0 to 64.0. The step is 1/8.
        if frac_en:

            # Make sure to generate a fractional value
            while True:
                mult = random.uniform(2.0, 64.0)
                mult = int(mult * 8.0 + 0.5) / 8.0

                if mult != int(mult):
                    break

        # Integer divider ranges from 2 to 64
        else:
            mult = random.randint(2, 64)

        phase = random.uniform(0.0, +180.0)

        # The phase shift requires to be quantized into 45 / mult steps.
        quant = 45.0 / mult
        phase = int((phase + quant/2) / quant) * quant

        return mult, phase

    def gen_div_and_phase(frac_en):
        """
        For CLKOUTn
        """

        # Fractional multiplier ranges from 2.0 to 128.0. The step is 1/8.
        if frac_en:

            # Make sure to generate a fractional value
            while True:
                divide = random.uniform(2.0, 128.0)
                divide = int(divide * 8.0 + 0.5) / 8.0

                if divide != int(divide):
                    break

        # Integer divider ranges from 2 to 128
        else:
            divide = random.randint(1, 128)

        phase = random.uniform(0.0, +180.0)

        # The phase shift requires to be quantized into 45 / mult steps.
        quant = 45.0 / divide
        phase = int((phase + quant/2) / quant) * quant

        return divide, phase

    params = {}

    # Other settings
    params["bandwidth"] = random.choice(("LOW", "HIGH", "OPTIMIZED",))

    # Input clock divider (1 to 106)
    params["divclk_divide"] = random.randint(1, 106)

    # Feedback clock
    frac_en = random.random() > 0.5
    mult, phase = gen_mult_and_phase(frac_en)

    params["clkfbout_mult"] = mult
    params["clkfbout_phase"] = phase

    # Clock outputs
    params["clkout"] = []
    for i in range(7):

        # Fractional divider is only available for CLKOUT0
        frac_en = random.random() > 0.5
        if i > 0:
            frac_en = False

        divide, phase = gen_div_and_phase(frac_en)

        # Duty cycle must be 50% when fractional divider is enabled
        duty = 0.5#random.uniform(0.10, 0.90)
        if frac_en:
            duty = 0.5

        params["clkout"].append(ClkOut(
            index = i,
            enabled = random.random() > 0.20,
            divide = divide,
            duty = duty,
            phase = phase 
        ))

    return params


def validate_params(params):
    """
    Validates MMCM parameters agains legal VCO frequency range. Makes Vivado
    don't complain.
    """

    # VCO operating ranges [MHz] (for xc7a35tcsg324-1 speed grade -1)
    vco_range = (600.0, 1200.0)

    mul = params["clkfbout_mult"]
    div = params["divclk_divide"]

    # It is impossible to meet VCO freq. constraints both for 100MHz and 50Mhz
    # input. Hence we check only for 100.
    for f_clkin in (100.0,):

        f_vco = f_clkin * mul / div

        if f_vco < vco_range[0]:
            return False
        if f_vco > vco_range[1]:
            return False

    return True


def make_integers(params):
    """
    Convert fractional parameter to integers by multiplying by the required
    constant and rounding.

    - Multipliers, dividers and phases need to be multiplied by 1000

    - Duty cycle needs to be expressed in % times 1000 hence the ratio is
      multiplied by 100000

    """

    for key in ["clkfbout_mult", "clkfbout_phase"]:
        params[key] = int(params[key] * 1000)

    for i, clkout in enumerate(params["clkout"]):
        fields = clkout._asdict()

        if i == 0:
            fields["divide"] = int(fields["divide"] * 1000)

        fields["duty"] = int(fields["duty"] * 100000)
        fields["phase"] = int(fields["phase"] * 1000)

        params["clkout"][i] = ClkOut(**fields)

    return params

# =============================================================================


def main():

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument(
        "--template",
        type=str,
        default="mmcm_random_case.tpl",
        help="Design template"
    )
    parser.add_argument(
        "--output",
        type=str,
        default="mmcm_random_case{:d}.v",
        help="Output file name pattern to be used with str.format()"
    )
    parser.add_argument(
        "--count",
        type=int,
        default=10,
        help="Number of cases to generate"
    )
    parser.add_argument(
        "--vpr",
        action="store_true",
        help="Convert fractional MMCM parameters to integers (as required by the techmap for VPR)"
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=1,
        help="Random generator seed"
    )

    args = parser.parse_args()

    random.seed(args.seed)

    # Load the template
    with open(args.template, "r") as fp:
        template = jinja2.Template(fp.read())

    # Generate cases
    for i in range(args.count):

        # Generate random MMCM configuration
        while True:
            params = generate_case()
            if validate_params(params):
                break

        # Convert floating point parameters to intergers
        if args.vpr:
            params = make_integers(params)

        ks = sorted(list(params.keys()))
        for k in ks:
            print(k, params[k])

        # Render and save the template
        vlog = template.render(**params)

        fname = args.output.format(i)
        with open(fname, "w") as fp:
            fp.write(vlog)

# =============================================================================


if __name__ == "__main__":
    main()
