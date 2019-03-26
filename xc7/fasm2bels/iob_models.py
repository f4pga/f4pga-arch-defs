from .verilog_modeling import Bel, Site

def get_iob_site(db, grid, tile, site):
    gridinfo = grid.gridinfo_at_tilename(tile)
    tile_type = db.get_tile_type(gridinfo.tile_type)

    sites = sorted(tile_type.get_instance_sites(gridinfo), key=lambda x: x.y)

    if len(sites) == 1:
        iob_site = sites[0]
    else:
        iob_site = sites[1-int(site[-1])]

    loc = grid.loc_of_tilename(tile)

    if gridinfo.tile_type.startswith('LIOB33'):
        dx = 1
    elif gridinfo.tile_type.startswith('RIOB33'):
        dx = -1
    else:
        assert False, gridinfo.tile_type

    iologic_tile = grid.tilename_at_loc((loc.grid_x+dx, loc.grid_y))
    ioi3_gridinfo = grid.gridinfo_at_loc((loc.grid_x+dx, loc.grid_y))

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

def get_drive(iostandard, drive):
    parts = drive.split('.')

    drive = parts[-1]
    assert drive[0] == 'I', drive

    if '_' not in drive:
        return int(drive[1:])
    else:
        assert iostandard in ['LVCMOS18', 'LVCMOS33', 'LVTTL']
        drives = sorted([int(d[1:]) for d in drive.split('_')])

        if iostandard == 'LVCMOS18':
            return min(drives)

        if drives == [12, 16]:
            if iostandard == 'LVCMOS33':
                return 12
            else:
                return 16
        elif drives == [8, 12]:
            return 8


def add_output_parameters(bel, site):
    assert 'IOSTANDARD' in bel.parameters

    if site.has_feature('SLEW.FAST'):
        bel.parameters['SLEW'] = '"FAST"'
    elif site.has_feature('SLEW.SLOW'):
        bel.parameters['SLEW'] = '"SLOW"'
    else:
        assert False

    drive = None
    for f in site.set_features:
        if 'DRIVE' in f:
            assert drive is None
            drive  = f
            break

    iostandard = bel.parameters['IOSTANDARD']
    assert iostandard[0] == '"'
    assert iostandard[-1] == '"'
    assert iostandard[1:-1] in drive

    bel.parameters['DRIVE'] = get_drive(iostandard[1:-1], drive)


def process_iob(top, iob):
    assert top.iostandard is not None

    aparts = iob[0].feature.split('.')
    iob_site, iologic_tile, ilogic_site, ologic_site = get_iob_site(top.db,
            top.grid, aparts[0], aparts[1])

    site = Site(iob, iob_site)

    INTERMDISABLE_USED = site.has_feature('INTERMDISABLE.I')
    IBUFDISABLE_USED = site.has_feature('IBUFDISABLE.I')

    top_wire = None
    ilogic_active = False
    ologic_active = False

    if site.has_feature('IN_ONLY'):
        if not site.has_feature('ZINV_D'):
            return

        ilogic_active = True

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

        top_wire = top.add_top_in_port(aparts[0], iob_site.name, 'IPAD')
        bel.connections['I'] = top_wire

        # Note this looks weird, but the BEL pin is O, and the site wire is
        # called I, so it is in fact correct.
        site.add_source(bel, bel_pin='O', source='I')

        bel.parameters['IOSTANDARD'] = '"{}"'.format(top.iostandard)

        site.add_bel(bel)
    elif site.has_feature('INOUT'):
        assert site.has_feature('ZINV_D')

        ilogic_active = True
        ologic_active = True

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

        top_wire = top.add_top_inout_port(aparts[0], iob_site.name, 'IOPAD')
        bel.connections['IO'] = top_wire

        # Note this looks weird, but the BEL pin is O, and the site wire is
        # called I, so it is in fact correct.
        site.add_source(bel, bel_pin='O', source='I')

        site.add_sink(bel, 'T', 'T')

        # Note this looks weird, but the BEL pin is I, and the site wire is
        # called O, so it is in fact correct.
        site.add_sink(bel, bel_pin='I', sink='O')

        bel.parameters['IOSTANDARD'] = '"{}"'.format(top.iostandard)

        add_output_parameters(bel, site)

        site.add_site(bel)
    else:
        has_output = False
        for f in site.set_features:
            if 'DRIVE' in f:
                has_output = True
                break

        if not has_output:
            # Naked pull options are not supported
            assert site.has_feature('PULLTYPE.PULLDOWN')
        else:
            # TODO: Could be a OBUFT?
            bel = Bel('OBUF')
            top_wire = top.add_top_out_port(aparts[0], iob_site.name, 'OPAD')
            bel.connections['O'] = top_wire

            # Note this looks weird, but the BEL pin is I, and the site wire
            # is called O, so it is in fact correct.
            site.add_sink(bel, bel_pin='I', sink='O')

            bel.parameters['IOSTANDARD'] = '"{}"'.format(top.iostandard)

            add_output_parameters(bel, site)
            site.add_bel(bel)
            ologic_active = True

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

    if ilogic_active:
        # TODO: Handle IDDR or ISERDES
        site = Site(iob, tile=iologic_tile, site=ilogic_site)
        site.sources['O'] = None
        site.sinks['D'] = []
        site.outputs['O'] = 'D'
        top.add_site(site)

    if ologic_active:
        # TODO: Handle ODDR or OSERDES
        site = Site(iob, tile=iologic_tile, site=ologic_site)
        site.sources['OQ'] = None
        site.sinks['D1'] = []
        site.outputs['OQ'] = 'D1'
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
