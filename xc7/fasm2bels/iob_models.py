from .verilog_modeling import Bel, Site


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

    return iob_site, iologic_tile, ilogic_site, ologic_site


def has_feature_with_part(site, part):
    """
    Returns True when a given site has a feature which contains a particular
    part.
    """
    for feature in site.set_features:
        parts = feature.split(".")
        if part in parts:
            return True

    return False


def has_feature_containing(site, substr):
    """
    Returns True when a given site has a feature which contains a given substring.
    """
    for feature in site.set_features:
        if substr in feature:
            return True

    return False


def append_obuf_iostandard_params(
        top, site, bel, possible_iostandards, slew="SLOW"
):
    """
    Appends IOSTANDARD, DRIVE and SLEW parameters to the bel. Those parameters
    have to be explicitly provided in the top.iostandard_defs dict. If parameters
    from the dict contradicts those decoded from fasm, an error is printed.
    """

    # Check if we have external information about the IOSTANDARD and DRIVE of
    # that site
    if site.site.name in top.iostandard_defs:
        iostd_def = top.iostandard_defs[site.site.name]

        iostandard = iostd_def["IOSTANDARD"]
        drive = iostd_def["DRIVE"]

        # Check if this is possible according to decoded fasm
        is_valid = (iostandard, drive, slew) in possible_iostandards
        if not is_valid:
            print(
                "IOSTANDARD+DRIVE+SLEW settings provided for {} do not match"
                "their counterparts decoded from the fasm".format(
                    site.site.name
                )
            )
            return

        bel.parameters["IOSTANDARD"] = '"{}"'.format(iostandard)
        bel.parameters["DRIVE"] = '"{}"'.format(drive)

    # Slew rate
    bel.parameters["SLEW"] = '"{}"'.format(slew)


def append_ibuf_iostandard_params(top, site, bel, possible_iostandards):
    """
    Appends IOSTANDARD parameter to the bel. The parameter has to be explicitly
    provided in the top.iostandard_defs dict. If the parameter from the dict
    contradicts the one decoded from fasm, an error is printed.
    """

    # Check if we have external information about the IOSTANDARD
    if site.site.name in top.iostandard_defs:
        iostd_def = top.iostandard_defs[site.site.name]
        iostandard = iostd_def["IOSTANDARD"]

        # Check if this is possible according to decoded fasm
        is_valid = iostandard in possible_iostandards
        if not is_valid:
            print(
                "IOSTANDARD setting provided for {} do not match"
                "its counterpart decoded from the fasm".format(site.site.name)
            )
            return

        bel.parameters["IOSTANDARD"] = '"{}"'.format(iostandard)


def process_iob(top, iob):
    """
    Processes an IOB
    """

    aparts = iob[0].feature.split('.')
    tile_name = aparts[0]
    iob_site, iologic_tile, ilogic_site, ologic_site = get_iob_site(
        top.db, top.grid, aparts[0], aparts[1]
    )

    # It seems that this IOB is always configured as an input at least in
    # Artix7. So skip it here.
    if iob_site.name == "IOB_X0Y44":
        return

    site = Site(iob, iob_site)

    INTERMDISABLE_USED = site.has_feature('INTERMDISABLE.I')
    IBUFDISABLE_USED = site.has_feature('IBUFDISABLE.I')

    # Collect all IOSTANDARD+DRIVE and IOSTANDARD+SLEW. Collect also possible
    # input IOSTANDARDS.
    iostd_drive = {}
    iostd_slew = {}
    iostd_in = set()

    for feature in site.set_features:
        parts = feature.split(".")

        if "DRIVE" in parts:
            idx = parts.index("DRIVE")

            drives = [int(s[1:]) for s in parts[idx + 1].split("_")]
            iostds = [s for s in parts[idx - 1].split("_")]

            for ios in iostds:
                if ios not in iostd_drive.keys():
                    iostd_drive[ios] = set()
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
            iostd_in |= set([s for s in parts[-2].split("_")])

    # Possible output configurations
    iostd_out = []
    for iostd in set(list(iostd_drive.keys())) | set(list(iostd_slew.keys())):
        if iostd in iostd_drive and iostd in iostd_slew:
            for drive in iostd_drive[iostd]:
                iostd_out.append((
                    iostd,
                    drive,
                    iostd_slew[iostd],
                ))

    # Buffer direction
    is_input = has_feature_with_part(site, "IN") or has_feature_with_part(
        site, "IN_ONLY"
    )
    is_inout = has_feature_with_part(site, "IN") and has_feature_with_part(
        site, "DRIVE"
    )
    is_output = not has_feature_with_part(site, "IN") and \
        has_feature_with_part(site, "DRIVE")

    # Sanity check. Can be only one or neither of them
    assert (is_input + is_inout + is_output) <= 1

    top_wire = None

    # Input only
    if is_input:

        # Options are:
        # IBUF, IBUF_IBUFDISABLE, IBUF_INTERMDISABLE
        if INTERMDISABLE_USED:
            bel = Bel('IBUF_INTERMDISABLE')
            site.add_sink(bel, 'INTERMDISABLE', 'INTERMDISABLE')

            if IBUFDISABLE_USED:
                site.add_sink(bel, 'IBUFDISABLE', 'IBUFDISABLE')
            else:
                bel.connections['IBUFDISABLE'] = 0

        elif IBUFDISABLE_USED:
            bel = Bel('IBUF_IBUFDISABLE')
            site.add_sink(bel, 'IBUFDISABLE', 'IBUFDISABLE')

        else:
            bel = Bel('IBUF')

        top_wire = top.add_top_in_port(tile_name, iob_site.name, 'IPAD')
        bel.connections['I'] = top_wire

        # Note this looks weird, but the BEL pin is O, and the site wire is
        # called I, so it is in fact correct.
        site.add_source(bel, bel_pin='O', source='I')

        append_ibuf_iostandard_params(top, site, bel, iostd_in)

        site.add_bel(bel)

    # Tri-state
    elif is_inout:

        # Options are:
        # IOBUF or IOBUF_INTERMDISABLE
        if INTERMDISABLE_USED or IBUFDISABLE_USED:
            bel = Bel('IOBUF_INTERMDISABLE')

            if INTERMDISABLE_USED:
                site.add_sink(bel, 'INTERMDISABLE', 'INTERMDISABLE')
            else:
                bel.connections['INTERMDISABLE'] = 0

            if IBUFDISABLE_USED:
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

        slew = "FAST" if has_feature_containing(site, "SLEW.FAST") else "SLOW"
        append_obuf_iostandard_params(top, site, bel, iostd_out, slew)

        site.add_site(bel)

    # Output
    elif is_output:

        # TODO: Could be a OBUFT?
        bel = Bel('OBUF')
        top_wire = top.add_top_out_port(tile_name, iob_site.name, 'OPAD')
        bel.connections['O'] = top_wire

        # Note this looks weird, but the BEL pin is I, and the site wire
        # is called O, so it is in fact correct.
        site.add_sink(bel, bel_pin='I', sink='O')

        slew = "FAST" if has_feature_containing(site, "SLEW.FAST") else "SLOW"
        append_obuf_iostandard_params(top, site, bel, iostd_out, slew)

        site.add_bel(bel)

    # Neither
    else:
        # Naked pull options are not supported
        assert site.has_feature('PULLTYPE.PULLDOWN')

    # Pull
    if top_wire is not None:
        if site.has_feature('PULLTYPE.PULLDOWN'):
            bel = Bel('PULLDOWN')
            bel.connections['O'] = top_wire
            site.add_bel(bel)
        elif site.has_feature('PULLTYPE.KEEPER'):
            bel = Bel('KEEPER')
            bel.connections['O'] = top_wire
            site.add_bel(bel)
        elif site.has_feature('PULLTYPE.PULLUP'):
            bel = Bel('PULLUP')
            bel.connections['O'] = top_wire
            site.add_bel(bel)

    top.add_site(site)


def process_iobs(conn, top, tile, features):
    iobs = {
        '0': [],
        '1': [],
    }

    for f in features:
        parts = f.feature.split('.')

        if not parts[1].startswith('IOB_Y'):
            continue

        iobs[parts[1][-1]].append(f)

    for iob in iobs:
        if len(iobs[iob]) > 0:
            process_iob(top, iobs[iob])
