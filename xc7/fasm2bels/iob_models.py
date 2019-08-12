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


def process_iob(top, iob):

    aparts = iob[0].feature.split('.')
    tile_name = aparts[0]
    iob_site, iologic_tile, ilogic_site, ologic_site = get_iob_site(
        top.db, top.grid, aparts[0], aparts[1]
    )

    site = Site(iob, iob_site)

    INTERMDISABLE_USED = site.has_feature('INTERMDISABLE.I')
    IBUFDISABLE_USED = site.has_feature('IBUFDISABLE.I')

    # Buffer direction
    is_input  = has_feature_with_part(site, "IN") or has_feature_with_part(site, "IN_ONLY")
    is_inout  = has_feature_with_part(site, "IN") and has_feature_with_part(site, "DRIVE")
    is_output = not has_feature_with_part(site, "IN") and has_feature_with_part(site, "DRIVE")

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

        # Slew rate
        if has_feature_containing(site, "SLEW.FAST"):
            bel.parameters["SLEW"] = '"FAST"'
        else:
            bel.parameters["SLEW"] = '"SLOW"'

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

        # Slew rate
        if has_feature_containing(site, "SLEW.FAST"):
            bel.parameters["SLEW"] = '"FAST"'
        else:
            bel.parameters["SLEW"] = '"SLOW"'

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
