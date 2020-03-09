from .verilog_modeling import Site, Bel


def process_hclk_ioi3(conn, top, tile, features):
    have_idelayctrl = False

    for f in features:
        if f.value == 0:
            continue

        if 'HCLK_IOI_IDELAYCTRL_REFCLK' in f.feature:
            have_idelayctrl = True
            continue

        if 'VREF' in f.feature:
            # HCLK_IOI3_X113Y26.VREF.V_675_MV
            tile, vref_str, vref_value = f.feature.split('.')
            assert vref_str == 'VREF', f
            v_str, value, mv_str = vref_value.split('_')
            assert v_str == 'V', f
            assert mv_str == 'MV', f

            iobank = top.find_iobank(tile.split('_')[-1])

            top.add_extra_tcl_line(
                'set_property INTERNAL_VREF 0.{VREF} [get_iobanks {iobank}]'.
                format(VREF=value, iobank=iobank)
            )

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
