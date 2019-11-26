from .verilog_modeling import Site, Bel


def get_ioi_site(db, grid, tile, site):
    """
    Returns a prxjray.tile.Site object for given ILOGIC/OLOGIC/IDELAY site.
    """

    gridinfo = grid.gridinfo_at_tilename(tile)
    tile_type = db.get_tile_type(gridinfo.tile_type)

    site_type, site_y = site.split("_")

    sites = tile_type.get_instance_sites(gridinfo)
    sites = [s for s in sites if site_type in s.name]
    sites.sort(key=lambda s: s.y)

    if len(sites) == 1:
        iob_site = sites[0]
    else:
        iob_site = sites[1 - int(site[-1])]

    return iob_site


def process_idelay(top, features):

    aparts = features[0].feature.split('.')
    # tile_name = aparts[0]
    ioi_site = get_ioi_site(top.db, top.grid, aparts[0], aparts[1])

    site = Site(features, ioi_site)

    # TODO: Support IDELAY
    assert not site.has_feature("IN_USE")


def process_ilogic(top, features):

    aparts = features[0].feature.split('.')
    # tile_name = aparts[0]
    ioi_site = get_ioi_site(top.db, top.grid, aparts[0], aparts[1])

    site = Site(features, ioi_site)

    # TODO: support IDELAY
    assert not site.has_feature("IDELAY.IN_USE")

    if site.has_feature("ISERDES.IN_USE") and site.has_feature(
            "IDDR_OR_ISERDES.IN_USE"):
        # ISERDES
        bel = Bel('ISERDESE2')

        data_rate = None
        if site.has_feature("ISERDES.DATA_RATE.SDR"):
            data_rate = '"SDR"'
        else:
            data_rate = '"DDR"'
        bel.parameters['DATA_RATE'] = data_rate

        # TODO: There shouldn't be mixed width in FASM features.
        #       Probably it is worth revisiting the fuzzer, as it
        #       is not possible to determine the width in case there
        #       is a multiple choice in the fasm features.
        data_width = None
        if site.has_feature("ISERDES.DATA_WIDTH.W3"):
            data_width = 3
        elif site.has_feature("ISERDES.DATA_WIDTH.W4_6"):
            data_width = 6
        elif site.has_feature("ISERDES.DATA_WIDTH.W5_7"):
            data_width = 7
        elif site.has_feature("ISERDES.DATA_WIDTH.W8"):
            data_width = 8
        else:
            data_width = 2

        bel.parameters['DATA_WIDTH'] = data_width

        interface = None
        if site.has_feature("ISERDES.INTERFACE_TYPE.MEMORY_DDR3"):
            interface = '"MEMORY_DDR3"'
        elif site.has_feature("ISERDES.INTERFACE_TYPE.NOT_MEMORY"
                              ) and site.has_feature(
                                  "ISERDES.INTERFACE_TYPE.Z_MEMORY"):
            interface = '"NETWORKING"'
        elif site.has_feature("ISERDES.INTERFACE_TYPE.OVERSAMPLE"):
            interface = '"OVERSAMPLE"'
        else:
            assert False

        bel.parameters['INTERFACE_TYPE'] = interface

        site.add_source(bel, 'O', 'O')

        site.add_sink(bel, 'CLK', 'CLK')
        site.add_sink(bel, 'CLKB', 'CLKB')
        site.add_sink(bel, 'CLKDIV', 'CLKDIV')

        site.add_sink(bel, 'RST', 'SR')

        if site.has_feature('ZINV_D'):
            bel.parameters['IS_D_INVERTED'] = 0
        else:
            bel.parameters['IS_D_INVERTED'] = 1

        if site.has_feature('IFF.ZINV_C'):
            bel.parameters['IS_CLK_INVERTED'] = 0
            bel.parameters['IS_CLKB_INVERTED'] = 1
        else:
            bel.parameters['IS_CLK_INVERTED'] = 1
            bel.parameters['IS_CLKB_INVERTED'] = 0

        num_ce = None
        if site.has_feature('ISERDES.NUM_CE.N2'):
            num_ce = 2
        else:
            num_ce = 1

        bel.parameters['NUM_CE'] = num_ce

        site.add_sink(bel, 'CE1', 'CE1')
        site.add_sink(bel, 'CE2', 'CE2')

        site.add_sink(bel, 'D', 'D')

        for i in range(1, 9):
            port_q = 'Q{}'.format(i)
            site.add_source(bel, port_q, port_q)

        site.add_bel(bel)
    else:
        site.sources['O'] = None
        site.sinks['D'] = []
        site.outputs['O'] = 'D'

    top.add_site(site)


def process_ologic(top, features):

    aparts = features[0].feature.split('.')
    # tile_name = aparts[0]
    ioi_site = get_ioi_site(top.db, top.grid, aparts[0], aparts[1])

    site = Site(features, ioi_site)

    if site.has_feature("OSERDES.IN_USE"):
        # OSERDES
        bel = Bel('OSERDESE2')

        data_rate_oq = None
        if site.has_feature("OSERDES.DATA_RATE_OQ.DDR"):
            data_rate_oq = '"DDR"'
        elif site.has_feature("OSERDES.DATA_RATE_OQ.SDR"):
            data_rate_oq = '"SDR"'
        else:
            assert False
        bel.parameters['DATA_RATE_OQ'] = data_rate_oq

        data_rate_tq = None
        if site.has_feature("OSERDES.DATA_RATE_TQ.DDR"):
            data_rate_tq = '"DDR"'
        elif site.has_feature("OSERDES.DATA_RATE_TQ.SDR"):
            data_rate_tq = '"SDR"'
        elif site.has_feature("OSERDES.DATA_RATE_TQ.BUF"):
            data_rate_tq = '"BUF"'
        else:
            assert False
        bel.parameters['DATA_RATE_TQ'] = data_rate_tq

        data_width = None
        if site.has_feature("OSERDES.DATA_WIDTH.W2"):
            data_width = 2
        elif site.has_feature("OSERDES.DATA_WIDTH.W3"):
            data_width = 3
        elif site.has_feature("OSERDES.DATA_WIDTH.W4"):
            data_width = 4
        elif site.has_feature("OSERDES.DATA_WIDTH.W5"):
            data_width = 5
        elif site.has_feature("OSERDES.DATA_WIDTH.W6"):
            data_width = 6
        elif site.has_feature("OSERDES.DATA_WIDTH.W7"):
            data_width = 7
        elif site.has_feature("OSERDES.DATA_WIDTH.W8"):
            data_width = 8
        else:
            assert False

        bel.parameters['DATA_WIDTH'] = data_width

        bel.parameters['TRISTATE_WIDTH'] = "4" if site.has_feature(
            "OSERDES.TRISTATE_WIDTH.W4"
        ) else "1"
        bel.parameters['SERDES_MODE'] = '"SLAVE"' if site.has_feature(
            "OSERES.SERDES_MODE.SLAVE"
        ) else '"MASTER"'

        site.add_source(bel, 'OQ', 'OQ')
        site.add_source(bel, 'TQ', 'TQ')

        site.add_sink(bel, 'CLK', 'CLK')
        site.add_sink(bel, 'CLKDIV', 'CLKDIV')

        for i in range(1, 9):
            site.add_sink(bel, 'D{}'.format(i), 'D{}'.format(i))

            inverted = ("IS_D{}_INVERTED".format(i))
            if site.has_feature(inverted):
                bel.parameters[inverted] = 1

        for i in range(1, 5):
            site.add_sink(bel, 'T{}'.format(i), 'T{}'.format(i))

            if not site.has_feature("ZINV_T{}".format(i)):
                bel.parameters["IS_T{}_INVERTED".format(i)] = 1

        site.add_sink(bel, 'OCE', 'OCE')
        site.add_sink(bel, 'TCE', 'TCE')

        site.add_sink(bel, 'RST', 'SR')

        site.add_bel(bel)

    else:
        # PASS THROUGH
        site.sources['OQ'] = None
        site.sinks['D1'] = []
        site.outputs['OQ'] = 'D1'

        site.sources['TQ'] = None
        site.sinks['T1'] = []
        site.outputs['TQ'] = 'T1'

    top.add_site(site)


def process_ioi(conn, top, tile, features):

    idelay = {
        "0": [],
        "1": [],
    }
    ilogic = {
        "0": [],
        "1": [],
    }
    ologic = {
        "0": [],
        "1": [],
    }

    for f in features:
        site = f.feature.split('.')[1]

        if site.startswith('IDELAY_Y'):
            idelay[site[-1]].append(f)
        if site.startswith('ILOGIC_Y'):
            ilogic[site[-1]].append(f)
        if site.startswith('OLOGIC_Y'):
            ologic[site[-1]].append(f)

    for features in idelay.values():
        if len(features):
            process_idelay(top, features)

    for features in ilogic.values():
        if len(features):
            process_ilogic(top, features)

    for features in ologic.values():
        if len(features):
            process_ologic(top, features)
