from .verilog_modeling import Site  # , Bel


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

    # TODO: Support IDDR, ISERDES etc
    assert not site.has_feature("IDDR_OR_ISERDES.IN_USE")
    assert not site.has_feature("ISERDES.IN_USE")
    assert not site.has_feature("IDELAY.IN_USE")

    site.sources['O'] = None
    site.sinks['D'] = []
    site.outputs['O'] = 'D'
    top.add_site(site)


def process_ologic(top, features):

    aparts = features[0].feature.split('.')
    # tile_name = aparts[0]
    ioi_site = get_ioi_site(top.db, top.grid, aparts[0], aparts[1])

    site = Site(features, ioi_site)

    # TODO: Support OSERDES etc.
    assert not site.has_feature("OSERDES.IN_USE")

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
