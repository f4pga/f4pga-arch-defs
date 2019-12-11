from .verilog_modeling import Site, Bel


def process_hclk_ioi3(conn, top, tile, features):
    have_idelayctrl = False

    for f in features:
        if 'HCLK_IOI_IDELAYCTRL_REFCLK' in f.feature:
            have_idelayctrl = True
            break

    if not have_idelayctrl:
        return

    gridinfo = top.grid.gridinfo_at_tilename(tile)
    tile_type = top.db.get_tile_type(gridinfo.tile_type)

    idelayctrl_sites = [
        site for site in tile_type.get_instance_sites(gridinfo)
        if site.type == 'IDELAYCTRL'
    ]
    assert len(idelayctrl_sites) == 1, tile

    site = Site([], tile=tile, site=idelayctrl_sites[0])

    idelayctrl = Bel('IDELAYCTRL')
    site.add_source(idelayctrl, 'RDY', 'RDY')
    site.add_sink(idelayctrl, 'RST', 'RST')
    site.add_sink(idelayctrl, 'REFCLK', 'REFCLK')
    site.add_bel(idelayctrl)

    top.add_site(site)
