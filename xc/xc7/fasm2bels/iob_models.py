from .utils import eprint
from .verilog_modeling import Bel, Site

# Mapping of IOB type to its IO ports
IOB_PORTS = {
    "IBUF": ("I", ),
    "IBUF_INTERMDISABLE": ("I", ),
    "IBUF_IBUFDISABLE": ("I", ),
    "OBUF": ("O", ),
    "OBUFT": ("O", ),
    "IOBUF": ("IO", ),
    "IOBUF_INTERMDISABLE": ("IO", ),
    "IBUFDS": (
        "I",
        "IB",
    ),
    "OBUFDS": (
        "O",
        "OB",
    ),
    "OBUFTDS": (
        "O",
        "OB",
    ),
    "IOBUFDS": (
        "IO",
        "IOB",
    ),
}

DRIVE_NOT_ALLOWED = ["SSTL135", "SSTL15"]


def get_iob_site(db, grid, tile, site):
    """ Return the prjxray.tile.Site objects and tiles for the given IOB site.

    Returns tuple of (iob_site, iologic_tile, ilogic_site, ologic_site)

    iob_site is the relevant prjxray.tile.Site object for the IOB.
    ilogic_site is the relevant prjxray.tile.Site object for the ILOGIC
    connected to the IOB.
    ologic_site is the relevant prjxray.tile.Site object for the OLOGIC
    connected to the IOB.

    iologic_tile is the tile containing the ilogic_site and ologic_site.

    """
    gridinfo = grid.gridinfo_at_tilename(tile)
    tile_type = db.get_tile_type(gridinfo.tile_type)

    sites = sorted(tile_type.get_instance_sites(gridinfo), key=lambda x: x.y)

    if len(sites) == 1:
        iob_site = sites[0]
    else:
        iob_site = sites[1 - int(site[-1])]

    loc = grid.loc_of_tilename(tile)

    if gridinfo.tile_type.startswith('LIOB33'):
        dx = 1
    elif gridinfo.tile_type.startswith('RIOB33'):
        dx = -1
    else:
        assert False, gridinfo.tile_type

    iologic_tile = grid.tilename_at_loc((loc.grid_x + dx, loc.grid_y))
    ioi3_gridinfo = grid.gridinfo_at_loc((loc.grid_x + dx, loc.grid_y))

    ioi3_tile_type = db.get_tile_type(ioi3_gridinfo.tile_type)
    ioi3_sites = ioi3_tile_type.get_instance_sites(ioi3_gridinfo)

    ilogic_site = None
    ologic_site = None

    target_ilogic_site = iob_site.name.replace('IOB', 'ILOGIC')
    target_ologic_site = iob_site.name.replace('IOB', 'OLOGIC')

    for site in ioi3_sites:
        if site.name == target_ilogic_site:
            assert ilogic_site is None
            ilogic_site = site

        if site.name == target_ologic_site:
            assert ologic_site is None
            ologic_site = site

    assert ilogic_site is not None
    assert ologic_site is not None

    return iob_site, iologic_tile, ilogic_site, ologic_site, gridinfo.pin_functions[
        iob_site.name]


def append_obuf_iostandard_params(
        top, site, bel, possible_iostandards, slew="SLOW", in_term=None
):
    """
    Appends IOSTANDARD, DRIVE and SLEW parameters to the bel. The IOSTANDARD
    and DRIVE parameters have to be read from an EBLIF file. If parameters
    from the EBLIF contradicts those decoded from fasm, an error is printed.
    """

    # Check if we have IO settings information for the site read from EBLIF
    iosettings = top.get_site_iosettings(site.site.name)

    # We don't. Use the default IOSTANDARD
    if iosettings is None:
        iosettings = {
            "IOSTANDARD": top.default_iostandard,
            "DRIVE": top.default_drive
        }

    # SSTL135/SSTL15 must have no DRIVE setting. If present, the DRIVE setting
    # gets removes, as it was set by DEFAULT in the EBLIF
    if iosettings["IOSTANDARD"] in DRIVE_NOT_ALLOWED:
        iosettings["DRIVE"] = None

    iostandard = iosettings.get("IOSTANDARD", None)
    drive = iosettings.get("DRIVE", None)

    # Check if this is possible according to decoded fasm
    is_valid = (iostandard, drive, slew) in possible_iostandards
    if not is_valid:
        eprint(
            "IOSTANDARD+DRIVE+SLEW settings provided for {} do not match "
            "their counterparts decoded from the fasm".format(site.site.name)
        )

        eprint("Requested:")
        eprint(" IOSTANDARD={}, DRIVE={}".format(iostandard, drive))

        eprint("Candidates are:")
        eprint(" IOSTANDARD        | DRIVE  | SLEW |")
        eprint("-------------------|--------|------|")
        for i, d, s in possible_iostandards:
            eprint(
                " {}| {}| {}|".format(
                    i.ljust(18),
                    str(d).ljust(7), s.ljust(5)
                )
            )
        eprint("")

        # Demote NSTD-1 to warning
        top.disable_drc("NSTD-1")

    # Valid
    else:
        bel.parameters["IOSTANDARD"] = '"{}"'.format(iostandard)

        if drive is not None:
            bel.parameters["DRIVE"] = '"{}"'.format(drive)

    # Input termination (here for inouts)
    if in_term is not None:
        for port in IOB_PORTS[bel.module]:
            top.add_extra_tcl_line(
                "set_property IN_TERM {} [get_ports {}]".format(
                    in_term, bel.connections[port]
                )
            )

    # Slew rate
    bel.parameters["SLEW"] = '"{}"'.format(slew)


def append_ibuf_iostandard_params(
        top, site, bel, possible_iostandards, in_term=None
):
    """
    Appends IOSTANDARD parameter to the bel. The parameter has to be decoded
    from the EBLIF file. If the parameter from the EBLIF contradicts the one
    decoded from fasm, an error is printed.
    """

    # Check if we have IO settings information for the site read from EBLIF
    iosettings = top.get_site_iosettings(site.site.name)

    # We don't. Use the default IOSTANDARD
    if iosettings is None:
        iosettings = {
            "IOSTANDARD": top.default_iostandard,
            "DRIVE": top.default_drive
        }

    # SSTL135/SSTL15 must have no DRIVE setting. If present, the DRIVE setting
    # gets removes, as it was set by DEFAULT in the EBLIF
    if iosettings["IOSTANDARD"] in DRIVE_NOT_ALLOWED:
        iosettings["DRIVE"] = None

    iostandard = iosettings.get("IOSTANDARD", None)

    # Check if this is possible according to decoded fasm
    is_valid = iostandard in possible_iostandards
    if not is_valid:
        eprint(
            "IOSTANDARD setting provided for {} do not match "
            "its counterpart decoded from the fasm".format(site.site.name)
        )

        eprint("Requested:")
        eprint(" {}".format(iostandard))

        eprint("Candidates are:")
        for i in possible_iostandards:
            eprint(" {}".format(i.ljust(15)))
        eprint("")

        # Demote NSTD-1 to warning
        top.disable_drc("NSTD-1")

    # Valid
    else:
        bel.parameters["IOSTANDARD"] = '"{}"'.format(iostandard)

    # Input termination
    if in_term is not None:
        for port in IOB_PORTS[bel.module]:
            top.add_extra_tcl_line(
                "set_property IN_TERM {} [get_ports {}]".format(
                    in_term, bel.connections[port]
                )
            )


def decode_iostandard_params(site, diff=False):
    """
    Collects all IOSTANDARD+DRIVE and IOSTANDARD+SLEW. Collect also possible
    input IOSTANDARDS.
    """

    iostd_drive = {}
    iostd_slew = {}
    iostd_in = set()
    iostd_out = []

    iostd_prefix = "DIFF_" if diff else ""

    for feature in site.features:
        parts = feature.split(".")

        if "DRIVE" in parts:
            idx = parts.index("DRIVE")

            if parts[idx + 1] == "I_FIXED":
                drives = [None]
            else:
                drives_str = parts[idx + 1].replace("_I_FIXED", "")
                drives = [int(s[1:]) for s in drives_str.split("_")]

            iostds = [s for s in parts[idx - 1].split("_")]

            for ios in iostds:
                if ios not in iostd_drive.keys():
                    iostd_drive[ios] = set()

                if ios in DRIVE_NOT_ALLOWED:
                    iostd_drive[ios].add(None)
                else:
                    for drv in drives:
                        iostd_drive[ios].add(drv)

        if "SLEW" in parts:
            idx = parts.index("SLEW")

            slew = parts[idx + 1]
            iostds = [s for s in parts[idx - 1].split("_")]

            for ios in iostds:
                if ios not in iostd_slew.keys():
                    iostd_slew[ios] = slew

        if "IN" in parts or "IN_ONLY" in parts:
            iostd_in |= set([iostd_prefix + s for s in parts[-2].split("_")])

    # Possible output configurations
    for iostd in set(list(iostd_drive.keys())) | set(list(iostd_slew.keys())):
        if iostd in iostd_drive and iostd in iostd_slew:
            for drive in iostd_drive[iostd]:
                iostd_out.append(
                    (
                        iostd_prefix + iostd,
                        drive,
                        iostd_slew[iostd],
                    )
                )

    return iostd_in, iostd_out


def decode_in_term(site):
    """
    Decodes input termination setting.
    """
    for term in ["40", "50", "60"]:
        if site.has_feature("IN_TERM.UNTUNED_SPLIT_" + term):
            return "UNTUNED_SPLIT_" + term

    return None


def add_pull_bel(site, wire):
    """
    Adds an appropriate PULL bel to the given site based on decoded fasm
    features.
    """

    if site.has_feature('PULLTYPE.PULLDOWN'):
        bel = Bel('PULLDOWN')
        bel.connections['O'] = wire
        site.add_bel(bel)
    elif site.has_feature('PULLTYPE.KEEPER'):
        bel = Bel('KEEPER')
        bel.connections['O'] = wire
        site.add_bel(bel)
    elif site.has_feature('PULLTYPE.PULLUP'):
        bel = Bel('PULLUP')
        bel.connections['O'] = wire
        site.add_bel(bel)


def process_single_ended_iob(top, iob):
    """
    Processes a single-ended IOB.
    """

    aparts = iob[0].feature.split('.')
    tile_name = aparts[0]
    iob_site, iologic_tile, ilogic_site, ologic_site, pin_functions = get_iob_site(
        top.db, top.grid, aparts[0], aparts[1]
    )

    # It seems that this IOB is always configured as an input at least in
    # Artix7. So skip it here.
    #
    # FIXME: This will prevent from correctly decoding a design when that one
    # is used in it.
    if 'PUDC' in pin_functions:
        return

    site = Site(iob, iob_site)

    intermdisable_used = site.has_feature('INTERMDISABLE.I')
    ibufdisable_used = site.has_feature('IBUFDISABLE.I')

    # Decode IOSTANDARD parameters
    iostd_in, iostd_out = decode_iostandard_params(site)
    in_term = decode_in_term(site)

    # Buffer direction
    is_input = (
        site.has_feature_with_part("IN")
        or site.has_feature_with_part("IN_ONLY")
    ) and not site.has_feature_with_part("DRIVE")
    is_inout = site.has_feature_with_part("IN") and site.has_feature_with_part(
        "DRIVE"
    )
    is_output = not site.has_feature_with_part("IN") and \
        site.has_feature_with_part("DRIVE")

    # Sanity check. Can be only one or neither of them
    assert (is_input + is_inout + is_output) <= 1, (
        tile_name,
        is_input,
        is_output,
        is_inout,
    )

    top_wire = None

    # Input only
    if is_input:

        # Options are:
        # IBUF, IBUF_IBUFDISABLE, IBUF_INTERMDISABLE
        if intermdisable_used:
            bel = Bel('IBUF_INTERMDISABLE')
            site.add_sink(bel, 'INTERMDISABLE', 'INTERMDISABLE')

            if ibufdisable_used:
                site.add_sink(bel, 'IBUFDISABLE', 'IBUFDISABLE')
            else:
                bel.connections['IBUFDISABLE'] = 0

        elif ibufdisable_used:
            bel = Bel('IBUF_IBUFDISABLE')
            site.add_sink(bel, 'IBUFDISABLE', 'IBUFDISABLE')

        else:
            bel = Bel('IBUF')

        top_wire = top.add_top_in_port(tile_name, iob_site.name, 'IPAD')
        bel.connections['I'] = top_wire

        # Note this looks weird, but the BEL pin is O, and the site wire is
        # called I, so it is in fact correct.
        site.add_source(bel, bel_pin='O', source='I')

        append_ibuf_iostandard_params(top, site, bel, iostd_in, in_term)

        site.add_bel(bel)

    # Tri-state
    elif is_inout:

        # Options are:
        # IOBUF or IOBUF_INTERMDISABLE
        if intermdisable_used or ibufdisable_used:
            bel = Bel('IOBUF_INTERMDISABLE')

            if intermdisable_used:
                site.add_sink(bel, 'INTERMDISABLE', 'INTERMDISABLE')
            else:
                bel.connections['INTERMDISABLE'] = 0

            if ibufdisable_used:
                site.add_sink(bel, 'IBUFDISABLE', 'IBUFDISABLE')
            else:
                bel.connections['IBUFDISABLE'] = 0
        else:
            bel = Bel('IOBUF')

        top_wire = top.add_top_inout_port(tile_name, iob_site.name, 'IOPAD')
        bel.connections['IO'] = top_wire

        # Note this looks weird, but the BEL pin is O, and the site wire is
        # called I, so it is in fact correct.
        site.add_source(bel, bel_pin='O', source='I')

        site.add_sink(bel, 'T', 'T')

        # Note this looks weird, but the BEL pin is I, and the site wire is
        # called O, so it is in fact correct.
        site.add_sink(bel, bel_pin='I', sink='O')

        slew = "FAST" if site.has_feature_containing("SLEW.FAST") else "SLOW"
        append_obuf_iostandard_params(top, site, bel, iostd_out, slew, in_term)

        site.add_bel(bel)

    # Output
    elif is_output:

        # TODO: Could be a OBUFT?
        bel = Bel('OBUF')
        top_wire = top.add_top_out_port(tile_name, iob_site.name, 'OPAD')
        bel.connections['O'] = top_wire

        # Note this looks weird, but the BEL pin is I, and the site wire
        # is called O, so it is in fact correct.
        site.add_sink(bel, bel_pin='I', sink='O')

        slew = "FAST" if site.has_feature_containing("SLEW.FAST") else "SLOW"
        append_obuf_iostandard_params(top, site, bel, iostd_out, slew, in_term)

        site.add_bel(bel)

    # Neither
    else:
        # Naked pull options are not supported
        assert site.has_feature('PULLTYPE.PULLDOWN'), tile_name

    # Pull
    if top_wire is not None:
        add_pull_bel(site, top_wire)

    top.add_site(site)


def process_differential_iob(top, iob, in_diff, out_diff):
    """
    Processes a differential-ended IOB.
    """

    assert in_diff or out_diff

    aparts = iob['S'][0].feature.split('.')
    tile_name = aparts[0]
    iob_site_s, iologic_tile, ilogic_site_s, ologic_site_s, _ = get_iob_site(
        top.db, top.grid, aparts[0], aparts[1]
    )

    aparts = iob['M'][0].feature.split('.')
    tile_name = aparts[0]
    iob_site_m, iologic_tile, ilogic_site_m, ologic_site_m, _ = get_iob_site(
        top.db, top.grid, aparts[0], aparts[1]
    )

    site_s = Site(iob['S'], iob_site_s)
    site_m = Site(iob['M'], iob_site_m)
    site = Site(iob['S'] + iob['M'], tile_name, merged_site=True)

    intermdisable_used = site.has_feature('INTERMDISABLE.I')
    ibufdisable_used = site.has_feature('IBUFDISABLE.I')

    top_wire_n = None
    top_wire_p = None

    # Decode IOSTANDARD parameters
    iostd_in, iostd_out = decode_iostandard_params(site, diff=True)
    in_term = decode_in_term(site)

    # Differential input
    if in_diff and not out_diff:
        assert False, (tile_name, "Differential inputs not supported yet!")

    # Differential output / inout
    elif out_diff:

        if in_diff:

            top_wire_n = top.add_top_inout_port(
                tile_name, iob_site_s.name, 'IOPAD_N'
            )
            top_wire_p = top.add_top_inout_port(
                tile_name, iob_site_m.name, 'IOPAD_P'
            )

            # Options are:
            # IOBUFDS or IOBUFDS_INTERMDISABLE
            # TODO: There are also IOBUFDS_DIFF_OUT* and variants with DCI
            if intermdisable_used or ibufdisable_used:
                bel = Bel('IOBUFDS_INTERMDISABLE')

                if intermdisable_used:
                    site_m.add_sink(bel, 'INTERMDISABLE', 'INTERMDISABLE')
                else:
                    bel.connections['INTERMDISABLE'] = 0

                if ibufdisable_used:
                    site_m.add_sink(bel, 'IBUFDISABLE', 'IBUFDISABLE')
                else:
                    bel.connections['IBUFDISABLE'] = 0
            else:
                bel = Bel('IOBUFDS')

            bel.connections['IOB'] = top_wire_n
            bel.connections['IO'] = top_wire_p

            # For IOBUFDS add the O pin
            site_m.add_source(bel, bel_pin='O', source='I')

        else:

            top_wire_n = top.add_top_out_port(
                tile_name, iob_site_s.name, 'OPAD_N'
            )
            top_wire_p = top.add_top_out_port(
                tile_name, iob_site_m.name, 'OPAD_P'
            )

            # Since we cannot distinguish between OBUFDS and OBUFTDS we add the
            # "T" one. If it is the OBUFDS then the T input will be forced to 0.
            bel = Bel('OBUFTDS')

            bel.connections['OB'] = top_wire_n
            bel.connections['O'] = top_wire_p

        # Note this looks weird, but the BEL pin is I, and the site wire
        # is called O, so it is in fact correct.
        site_m.add_sink(bel, bel_pin='I', sink='O')
        site_m.add_sink(bel, bel_pin='T', sink='T')

        slew = "FAST" if site.has_feature_containing("SLEW.FAST") else "SLOW"
        append_obuf_iostandard_params(
            top, site_m, bel, iostd_out, slew, in_term
        )

        site_m.add_bel(bel)

    # Pulls
    if top_wire_n is not None:
        add_pull_bel(site_s, top_wire_n)
    if top_wire_p is not None:
        add_pull_bel(site_m, top_wire_p)

    top.add_site(site_m)
    top.add_site(site_s)


def process_iobs(conn, top, tile, features):

    site_map = {
        'IOB_Y1': 'S',
        'IOB_Y0': 'M',
    }

    iobs = {
        'S': [],
        'M': [],
    }

    out_diff = False
    in_diff = False

    for f in features:
        parts = f.feature.split('.')

        # Detect differential IO
        if parts[-1] == "OUT_DIFF":
            out_diff = True
        if parts[-1] == "IN_DIFF":
            in_diff = True

        if not parts[1].startswith('IOB_Y'):
            continue

        # Map site name to 'M' or 'S'
        ms = site_map[parts[1]]
        assert ms in iobs, ms
        iobs[ms].append(f)

    # Differential
    if in_diff or out_diff:
        process_differential_iob(top, iobs, in_diff, out_diff)

    # Single ended
    else:
        for iob, features in iobs.items():
            if len(features) > 0:
                process_single_ended_iob(top, features)
