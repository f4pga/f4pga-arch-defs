from .verilog_modeling import Site, Bel

# =============================================================================


def get_ps7_site(db):
    """
    Looks for tile and site that contains the PS7 in the tilegrid.
    """

    # Check if there are any PSS tiles. If not then there is no PS7
    pss_tiles = [t for t in db.get_tile_types() if t.startswith("PSS")]
    if len(pss_tiles) == 0:
        return None, None

    # Loop over the gird and find the PS7
    grid = db.grid()
    for tile_name in grid.tiles():
        if tile_name.startswith("PSS"):
            gridinfo = grid.gridinfo_at_tilename(tile_name)

            tile_type = db.get_tile_type(gridinfo.tile_type)
            sites = tile_type.get_instance_sites(gridinfo)
            sites = [s for s in sites if s.type == "PS7"]

            if len(sites) > 0:
                return tile_name, sites[0]

    # No PS7 found
    return None, None


def insert_ps7(top, pss_tile, ps7_site, ps7_ports):
    """
    Adds the PS7 instance to the design
    """

    # Add the site+bel
    site = Site(None, ps7_site, pss_tile)
    bel = Bel("PS7")

    # Add sources and sinks
    for name, port in ps7_ports.items():

        # Add only "normal" ports that go to the PL.
        if port["class"] != "normal":
            continue

        # Choose adder func.
        if port["direction"] == "output":
            add = site.add_source
        elif port["direction"] == "input":
            add = site.add_sink
        else:
            assert False, (
                name,
                port,
            )

        # Add
        if port["width"] == 1:
            add(bel, name, name)
        else:
            for i in range(port["min"], port["max"] + 1):
                add(bel, "{}[{}]".format(name, i), "{}{}".format(name, i))

    # Add everything
    site.add_bel(bel, bel.name)

    site.set_post_route_cleanup_function(cleanup_ps7)
    top.add_site(site)


def cleanup_ps7(top, site):
    """
    Removes the PS7 site if not connected to the PL fabric through any
    active PIP.
    """

    # Get the PS7 (if any)
    ps7 = site.maybe_get_bel("PS7")
    if ps7 is None:
        return

    # Filters out 0 and 1 from a sink/source list
    def filter_consts(items):
        return [s for s in items if s not in [0, 1]]

    # Check if there is at least one active source on the PS7 site. If so then
    # return (no cleanup).
    for source in site.sources:
        sinks = filter_consts(top.find_sinks_from_source(site, source))
        if len(sinks):
            return

    # Check if there is at least one active sink on the PS7 site. If so then
    # return (no cleanup).
    for sink in site.sinks:
        sources = filter_consts(top.find_sources_from_sink(site, sink))
        if len(sources):
            return

    # Remove the PS7 as it is not connected
    top.remove_bel(site, ps7)
