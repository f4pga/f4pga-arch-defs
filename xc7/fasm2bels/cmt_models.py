import fasm
from .verilog_modeling import Bel, Site

# =============================================================================

# A lookup table for content of the TABLE register to get the BANDWIDTH
# setting. Values taken from XAPP888 reference design.
PLL_BANDWIDTH_LOOKUP = {

    # LOW
    0b0010111100: "LOW",
    0b0010011100: "LOW",
    0b0010110100: "LOW",
    0b0010010100: "LOW",
    0b0010100100: "LOW",
    0b0010111000: "LOW",
    0b0010000100: "LOW",
    0b0010011000: "LOW",
    0b0010101000: "LOW",
    0b0010110000: "LOW",
    0b0010001000: "LOW",
    0b0011110000: "LOW",
    0b0010010000: "LOW",

    # OPTIMIZED and HIGH are the same
    0b0011011100: "OPTIMIZED",
    0b0101111100: "OPTIMIZED",
    0b0111111100: "OPTIMIZED",
    0b0111101100: "OPTIMIZED",
    0b1101011100: "OPTIMIZED",
    0b1110101100: "OPTIMIZED",
    0b1110110100: "OPTIMIZED",
    0b1111110100: "OPTIMIZED",
    0b1111011100: "OPTIMIZED",
    0b1111101100: "OPTIMIZED",
    0b1111110100: "OPTIMIZED",
    0b1111001100: "OPTIMIZED",
    0b1110010100: "OPTIMIZED",
    0b1111010100: "OPTIMIZED",
    0b0111011000: "OPTIMIZED",
    0b0101110000: "OPTIMIZED",
    0b1100000100: "OPTIMIZED",
    0b0100001000: "OPTIMIZED",
    0b0010100000: "OPTIMIZED",
    0b0011010000: "OPTIMIZED",
    0b0010100000: "OPTIMIZED",
    0b0100110000: "OPTIMIZED",
    0b0010010000: "OPTIMIZED",
}

# =============================================================================

def get_pll_site(db, grid, tile, site):
    """ Return the prjxray.tile.Site object for the given PLL site. """
    gridinfo = grid.gridinfo_at_tilename(tile)
    tile_type = db.get_tile_type(gridinfo.tile_type)

    sites = list(tile_type.get_instance_sites(gridinfo))
    assert len(sites) == 1, sites

    return sites[0]


def decode_multi_bit_feature(features, target_feature):
    """
    Decodes a "multi-bit" fasm feature. If not present returns 0.
    """
    value = 0

    for f in features:
        last_part = f.feature.split('.')[-1]
        if last_part.startswith(target_feature):
            for canon_f in fasm.canonical_features(f):
                if canon_f.start is None:
                    value |= 1
                else:
                    value |= (1 << canon_f.start)

    return value


def process_pll(conn, top, tile_name, features):
    """
    Processes the PLL site
    """

    # Filter only PLL related features
    pll_features = [f for f in features if 'PLLE2.' in f.feature]
    if len(pll_features) == 0:
        return

    # Create the site
    site = Site(
        pll_features,
        get_pll_site(top.db, top.grid, tile=tile_name, site='PLLE2_ADV')
    )

    # If the PLL is not used then skip the rest
    if not site.has_feature("IN_USE"):
        return

    # Create the PLLE2_ADV bel and add its ports
    pll = Bel('PLLE2_ADV')

    for i in range(6):
        site.add_sink(pll, 'DADDR[{}]'.format(i), 'DADDR{}'.format(i))

    for i in range(15):
        site.add_sink(pll, 'DI[{}]'.format(i), 'DI{}'.format(i))

    site.add_sink(pll, 'DCLK', 'DCLK')
    site.add_sink(pll, 'DEN', 'DEN')
    site.add_sink(pll, 'DWE', 'DWE')
    site.add_sink(pll, 'CLKIN1', 'CLKIN1')
    site.add_sink(pll, 'CLKIN2', 'CLKIN2')
    site.add_sink(pll, 'CLKINSEL', 'CLKINSEL')
    site.add_sink(pll, 'CLKFBIN', 'CLKFBIN')
    site.add_sink(pll, 'RST', 'RST')
    site.add_sink(pll, 'PWRDWN', 'PWRDWN')

    site.add_source(pll, 'DRDY', 'DRDY')
    site.add_source(pll, 'LOCKED', 'LOCKED')

    for i in range(15):
        site.add_source(pll, 'DO[{}]'.format(i), 'DO{}'.format(i))

    # Process clock outputs
    clkouts = ['FBOUT'] + ['OUT{}'.format(i) for i in range(6)]

    for clkout in clkouts:
        if site.has_feature('CLK{}_CLKOUT1_OUTPUT_ENABLE'.format(clkout)):

            # Add output source
            site.add_source(pll, 'CLK' + clkout, 'CLK' + clkout)

            # Calculate the divider and duty cycle
            high_time = decode_multi_bit_feature(
                features, 'CLK{}_CLKOUT1_HIGH_TIME'.format(clkout)
            )
            low_time = decode_multi_bit_feature(
                features, 'CLK{}_CLKOUT1_LOW_TIME'.format(clkout)
            )

            if decode_multi_bit_feature(features,
                                        'CLK{}_CLKOUT2_EDGE'.format(clkout)):
                high_time += 0.5
                low_time = max(0, low_time - 0.5)

            divider = int(high_time + low_time)
            duty = high_time / (low_time + high_time)

            if site.has_feature('CLK{}_CLKOUT2_NO_COUNT'.format(clkout)):
                divider = 1
                duty = 0.5

            if clkout == 'FBOUT':
                pll.parameters['CLKFBOUT_MULT'] = divider
            else:
                pll.parameters['CLK{}_DIVIDE'.format(clkout)] = divider
                pll.parameters['CLK{}_DUTY_CYCLE'.format(clkout)
                               ] = "{0:.3f}".format(duty)

            # Phase shift
            delay = decode_multi_bit_feature(
                features, 'CLK{}_CLKOUT2_DELAY_TIME'.format(clkout)
            )
            phase = decode_multi_bit_feature(
                features, 'CLK{}_CLKOUT1_PHASE_MUX'.format(clkout)
            )

            phase = float(delay) + phase / 8.0  # Delay in VCO cycles
            phase = 360.0 * phase / divider  # Phase of CLK in degrees

            if clkout == 'FBOUT':
                pll.parameters['CLKFBOUT_PHASE'] = "{0:.3f}".format(phase)
            else:
                pll.parameters['CLK{}_PHASE'.format(clkout)
                               ] = "{0:.3f}".format(phase)

    # Input clock divider
    high_time = decode_multi_bit_feature(features, 'DIVCLK_DIVCLK_HIGH_TIME')
    low_time = decode_multi_bit_feature(features, 'DIVCLK_DIVCLK_LOW_TIME')

    divider = high_time + low_time

    if site.has_feature('DIVCLK_DIVCLK_NO_COUNT'):
        divider = 1

    pll.parameters['DIVCLK_DIVIDE'] = divider

    # Startup wait
    pll.parameters['STARTUP_WAIT'] = '"TRUE"' if site.has_feature(
        'STARTUP_WAIT'
    ) else '"FALSE"'

    # Bandwidth
    table = decode_multi_bit_feature(features, 'TABLE')
    if table in PLL_BANDWIDTH_LOOKUP:
        pll.parameters['BANDWIDTH'] =\
            '"{}"'.format(PLL_BANDWIDTH_LOOKUP[table])

    # Compensation  TODO: Probably need to rework database tags for those.
    if site.has_feature('COMPENSATION.INTERNAL'):
        pll.parameters['COMPENSATION'] = '"INTERNAL"'
    elif site.has_feature('COMPENSATION.BUF_IN_OR_EXTERNAL_OR_ZHOLD_CLKIN_BUF'):
        pll.parameters['COMPENSATION'] = '"BUF_IN"'

    # Built-in inverters
    pll.parameters['IS_CLKINSEL_INVERTED'] =\
        "1'b1" if site.has_feature('INV_CLKINSEL') else "1'b0"
    pll.parameters['IS_PWRDWN_INVERTED'] =\
        "1'b1" if site.has_feature('ZINV_PWRDWN') else "1'b0"
    pll.parameters['IS_RST_INVERTED'] =\
        "1'b1" if site.has_feature('ZINV_RST') else "1'b0"

    # Add the bel and site
    site.add_bel(pll)
    top.add_site(site)
