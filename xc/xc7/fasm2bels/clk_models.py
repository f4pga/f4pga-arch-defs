import re

from .verilog_modeling import Bel, Site

BUFHCE_RE = re.compile('BUFHCE_X([0-9]+)Y([0-9]+)')


def get_bufg_site(db, grid, tile, generic_site):
    y = int(generic_site[generic_site.find('Y') + 1:])
    if '_TOP_' in tile:
        y += 16

    site_name = 'BUFGCTRL_X0Y{}'.format(y)

    gridinfo = grid.gridinfo_at_tilename(tile)

    tile = db.get_tile_type(gridinfo.tile_type)

    for site in tile.get_instance_sites(gridinfo):
        if site.name == site_name:
            return site

    assert False, (tile, generic_site)


def bufhce_xy(site):
    m = BUFHCE_RE.fullmatch(site)
    assert m is not None, site

    return int(m.group(1)), int(m.group(2))


def get_bufhce_site(db, grid, tile, generic_site):
    x, y = bufhce_xy(generic_site)

    gridinfo = grid.gridinfo_at_tilename(tile)

    tile = db.get_tile_type(gridinfo.tile_type)

    for site in tile.get_instance_sites(gridinfo):
        instance_x, instance_y = bufhce_xy(site.name)

        if instance_x == x and y == (instance_y % 12):
            return site

    assert False, (tile, generic_site)


def process_bufg(conn, top, tile, features):
    bufgs = {}
    for f in features:
        parts = f.feature.split('.')

        if parts[1] != 'BUFGCTRL':
            continue

        if parts[2] not in bufgs:
            bufgs[parts[2]] = []

        bufgs[parts[2]].append(f)

    for bufg, features in bufgs.items():
        set_features = set()

        for f in features:
            if f.value == 0:
                continue

            parts = f.feature.split('.')

            set_features.add('.'.join(parts[3:]))

        if 'IN_USE' not in set_features:
            continue

        bufg_site = get_bufg_site(
            top.db, top.grid, tile, features[0].feature.split('.')[2]
        )
        site = Site(features, site=bufg_site)

        bel = Bel('BUFGCTRL')
        bel.parameters['IS_IGNORE0_INVERTED'] = int(
            'IS_IGNORE0_INVERTED' not in set_features
        )
        bel.parameters['IS_IGNORE1_INVERTED'] = int(
            'IS_IGNORE1_INVERTED' not in set_features
        )
        bel.parameters['IS_CE0_INVERTED'] = int('ZINV_CE0' not in set_features)
        bel.parameters['IS_CE1_INVERTED'] = int('ZINV_CE1' not in set_features)
        bel.parameters['IS_S0_INVERTED'] = int('ZINV_S0' not in set_features)
        bel.parameters['IS_S1_INVERTED'] = int('ZINV_S1' not in set_features)
        bel.parameters['PRESELECT_I0'] = '"TRUE"' if (
            'ZPRESELECT_I0' not in set_features
        ) else '"FALSE"'
        bel.parameters['PRESELECT_I1'] = '"TRUE"' if int(
            'PRESELECT_I1' in set_features
        ) else '"FALSE"'
        bel.parameters['INIT_OUT'] = int('INIT_OUT' in set_features)

        for sink in ('I0', 'I1', 'S0', 'S1', 'CE0', 'CE1', 'IGNORE0',
                     'IGNORE1'):
            site.add_sink(bel, sink, sink)

        site.add_source(bel, 'O', 'O')

        site.add_bel(bel)

        top.add_site(site)


def process_hrow(conn, top, tile, features):
    bufhs = {}
    for f in features:
        parts = f.feature.split('.')

        if parts[1] != 'BUFHCE':
            continue

        if parts[2] not in bufhs:
            bufhs[parts[2]] = []

        bufhs[parts[2]].append(f)

    for bufh, features in bufhs.items():
        set_features = set()

        for f in features:
            if f.value == 0:
                continue

            parts = f.feature.split('.')

            set_features.add('.'.join(parts[3:]))

        if 'IN_USE' not in set_features:
            continue

        bufhce_site = get_bufhce_site(
            top.db, top.grid, tile, features[0].feature.split('.')[2]
        )
        site = Site(features, site=bufhce_site)

        bel = Bel('BUFHCE')
        if 'CE_TYPE.ASYNC' in set_features:
            bel.parameters['CE_TYPE'] = '"ASYNC"'
        else:
            bel.parameters['CE_TYPE'] = '"SYNC"'
        bel.parameters['IS_CE_INVERTED'] = int('ZINV_CE' not in set_features)
        bel.parameters['INIT_OUT'] = int('INIT_OUT' in set_features)

        for sink in ('I', 'CE'):
            site.add_sink(bel, sink, sink)

        site.add_source(bel, 'O', 'O')

        site.add_bel(bel)

        top.add_site(site)
