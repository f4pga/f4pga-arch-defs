import fasm
from .verilog_modeling import Bel, Site


def get_init(features, target_feature, invert, width):
    """ Returns INIT argument for specified feature.

    features: List of fasm.SetFeature objects
    target_feature (str): Target feature prefix (e.g. INIT_A or INITP_0).
    invert (bool): Controls whether output value should be bit inverted.
    width (int): Bit width of INIT value.

    Returns int

    """
    init = 0

    for f in features:
        if f.feature.startswith(target_feature):
            for canon_f in fasm.canonical_features(f):
                if canon_f.start is None:
                    init |= 1
                else:
                    init |= (1 << canon_f.start)

    if invert:
        init ^= (2**width) - 1

    return "{width}'b{init:0b}".format(width=width, init=init)


def get_bram_site(db, grid, tile, site):
    """ Return the prjxray.tile.Site object for the given BRAM site. """
    gridinfo = grid.gridinfo_at_tilename(tile)
    tile_type = db.get_tile_type(gridinfo.tile_type)

    if site == 'RAMB18_Y0':
        target_type = 'FIFO18E1'
    elif site == 'RAMB18_Y1':
        target_type = 'RAMB18E1'
    else:
        assert False, site

    sites = tile_type.get_instance_sites(gridinfo)
    for site in sites:
        if site.type == target_type:
            return site

    assert False, sites


def process_bram_site(top, features, set_features):
    if 'IN_USE' not in set_features:
        return

    aparts = features[0].feature.split('.')
    bram_site = get_bram_site(top.db, top.grid, aparts[0], aparts[1])
    site = Site(features, bram_site)

    bel = Bel('RAMB18E1')
    site.add_bel(bel)

    # Parameters

    def make_target_feature(feature):
        return '{}.{}.{}'.format(aparts[0], aparts[1], feature)

    parameter_binds = [
        ('INIT_A', 'ZINIT_A', True, 18),
        ('INIT_B', 'ZINIT_B', True, 18),
        ('SRVAL_A', 'ZSRVAL_A', True, 18),
        ('SRVAL_B', 'ZSRVAL_B', True, 18),
    ]

    for pidx in range(8):
        parameter_binds.append(
            ('INITP_0{}'.format(pidx), 'INITP_0{}'.format(pidx), False, 256)
        )

    for idx in range(0x40):
        parameter_binds.append(
            ('INIT_{:02X}'.format(idx), 'INIT_{:02X}'.format(idx), False, 256)
        )

    for vparam, fparam, invert, width in parameter_binds:
        bel.parameters[vparam] = get_init(
            features, make_target_feature(fparam), invert=invert, width=width
        )

    bel.parameters['DOA_REG'] = int('DOA_REG' in set_features)
    bel.parameters['DOB_REG'] = int('DOB_REG' in set_features)
    """
     SDP_READ_WIDTH_36 = SDP_READ_WIDTH_36
     READ_WIDTH_A_18 = READ_WIDTH_A_18
     READ_WIDTH_A_9 = READ_WIDTH_A_9
     READ_WIDTH_A_4 = READ_WIDTH_A_4
     READ_WIDTH_A_2 = READ_WIDTH_A_2
     READ_WIDTH_A_1 = READ_WIDTH_A_1
     READ_WIDTH_B_18 = READ_WIDTH_B_18
     READ_WIDTH_B_9 = READ_WIDTH_B_9
     READ_WIDTH_B_4 = READ_WIDTH_B_4
     READ_WIDTH_B_2 = READ_WIDTH_B_2
     READ_WIDTH_B_1 = READ_WIDTH_B_1
    """

    RAM_MODE = '"TDP"'
    if 'SDP_READ_WIDTH_36' in set_features:
        assert 'READ_WIDTH_A_1' in set_features or 'READ_WIDTH_A_18' in set_features
        assert 'READ_WIDTH_B_18' in set_features
        READ_WIDTH_A = 36
        READ_WIDTH_B = 0
        RAM_MODE = '"SDP"'
    else:
        if 'READ_WIDTH_A_1' in set_features:
            READ_WIDTH_A = 1
        elif 'READ_WIDTH_A_2' in set_features:
            READ_WIDTH_A = 2
        elif 'READ_WIDTH_A_4' in set_features:
            READ_WIDTH_A = 4
        elif 'READ_WIDTH_A_9' in set_features:
            READ_WIDTH_A = 9
        elif 'READ_WIDTH_A_18' in set_features:
            READ_WIDTH_A = 18
        else:
            assert False

        if 'READ_WIDTH_B_1' in set_features:
            READ_WIDTH_B = 1
        elif 'READ_WIDTH_B_2' in set_features:
            READ_WIDTH_B = 2
        elif 'READ_WIDTH_B_4' in set_features:
            READ_WIDTH_B = 4
        elif 'READ_WIDTH_B_9' in set_features:
            READ_WIDTH_B = 9
        elif 'READ_WIDTH_B_18' in set_features:
            READ_WIDTH_B = 18
        else:
            assert False
    """
     SDP_WRITE_WIDTH_36 = SDP_WRITE_WIDTH_36
     WRITE_WIDTH_A_18 = WRITE_WIDTH_A_18
     WRITE_WIDTH_A_9 = WRITE_WIDTH_A_9
     WRITE_WIDTH_A_4 = WRITE_WIDTH_A_4
     WRITE_WIDTH_A_2 = WRITE_WIDTH_A_2
     WRITE_WIDTH_A_1 = WRITE_WIDTH_A_1
     WRITE_WIDTH_B_18 = WRITE_WIDTH_B_18
     WRITE_WIDTH_B_9 = WRITE_WIDTH_B_9
     WRITE_WIDTH_B_4 = WRITE_WIDTH_B_4
     WRITE_WIDTH_B_2 = WRITE_WIDTH_B_2
     WRITE_WIDTH_B_1 = WRITE_WIDTH_B_1
    """

    if 'SDP_WRITE_WIDTH_36' in set_features:
        assert 'WRITE_WIDTH_A_18' in set_features
        assert 'WRITE_WIDTH_B_18' in set_features
        WRITE_WIDTH_A = 0
        WRITE_WIDTH_B = 36
        RAM_MODE = '"SDP"'
    else:
        if 'WRITE_WIDTH_A_1' in set_features:
            WRITE_WIDTH_A = 1
        elif 'WRITE_WIDTH_A_2' in set_features:
            WRITE_WIDTH_A = 2
        elif 'WRITE_WIDTH_A_4' in set_features:
            WRITE_WIDTH_A = 4
        elif 'WRITE_WIDTH_A_9' in set_features:
            WRITE_WIDTH_A = 9
        elif 'WRITE_WIDTH_A_18' in set_features:
            WRITE_WIDTH_A = 18
        else:
            assert False

        if 'WRITE_WIDTH_B_1' in set_features:
            WRITE_WIDTH_B = 1
        elif 'WRITE_WIDTH_B_2' in set_features:
            WRITE_WIDTH_B = 2
        elif 'WRITE_WIDTH_B_4' in set_features:
            WRITE_WIDTH_B = 4
        elif 'WRITE_WIDTH_B_9' in set_features:
            WRITE_WIDTH_B = 9
        elif 'WRITE_WIDTH_B_18' in set_features:
            WRITE_WIDTH_B = 18
        else:
            assert False

    bel.parameters['RAM_MODE'] = RAM_MODE
    bel.parameters['READ_WIDTH_A'] = READ_WIDTH_A
    bel.parameters['READ_WIDTH_B'] = READ_WIDTH_B
    bel.parameters['WRITE_WIDTH_A'] = WRITE_WIDTH_A
    bel.parameters['WRITE_WIDTH_B'] = WRITE_WIDTH_B
    """
     ZINV_CLKARDCLK = ZINV_CLKARDCLK
     ZINV_CLKBWRCLK = ZINV_CLKBWRCLK
     ZINV_ENARDEN = ZINV_ENARDEN
     ZINV_ENBWREN = ZINV_ENBWREN
     ZINV_RSTRAMARSTRAM = ZINV_RSTRAMARSTRAM
     ZINV_RSTRAMB = ZINV_RSTRAMB
     ZINV_RSTREGARSTREG = ZINV_RSTREGARSTREG
     ZINV_RSTREGB = ZINV_RSTREGB
     ZINV_REGCLKARDRCLK = ZINV_REGCLKARDRCLK
     ZINV_REGCLKB = ZINV_REGCLKB
    """
    for wire in (
            'CLKARDCLK',
            'CLKBWRCLK',
            'ENARDEN',
            'ENBWREN',
            'RSTRAMARSTRAM',
            'RSTRAMB',
            'RSTREGARSTREG',
            'RSTREGB',
    ):
        bel.parameters['IS_{}_INVERTED'.format(wire)
                       ] = int(not 'ZINV_{}'.format(wire) in set_features)
    """
     WRITE_MODE_A_NO_CHANGE = WRITE_MODE_A_NO_CHANGE
     WRITE_MODE_A_READ_FIRST = WRITE_MODE_A_READ_FIRST
     WRITE_MODE_B_NO_CHANGE = WRITE_MODE_B_NO_CHANGE
     WRITE_MODE_B_READ_FIRST = WRITE_MODE_B_READ_FIRST
    """
    if 'WRITE_MODE_A_NO_CHANGE' in set_features:
        bel.parameters['WRITE_MODE_A'] = '"NO_CHANGE"'
    elif 'WRITE_MODE_A_READ_FIRST' in set_features:
        bel.parameters['WRITE_MODE_A'] = '"READ_FIRST"'
    else:
        bel.parameters['WRITE_MODE_A'] = '"WRITE_FIRST"'

    if 'WRITE_MODE_B_NO_CHANGE' in set_features:
        bel.parameters['WRITE_MODE_B'] = '"NO_CHANGE"'
    elif 'WRITE_MODE_B_READ_FIRST' in set_features:
        bel.parameters['WRITE_MODE_B'] = '"READ_FIRST"'
    else:
        bel.parameters['WRITE_MODE_B'] = '"WRITE_FIRST"'

    fifo_site = bram_site.type == 'FIFO18E1'

    fifo_site_wire_map = {
        'REGCEAREGCE': 'REGCE',
        'REGCLKARDRCLK': 'RDRCLK',
        'RSTRAMARSTRAM': 'RST',
        'RSTREGARSTREG': 'RSTREG',
        'ENBWREN': 'WREN',
        'CLKBWRCLK': 'WRCLK',
        'ENARDEN': 'RDEN',
        'CLKARDCLK': 'RDCLK',
    }

    for idx in range(16):
        fifo_site_wire_map['DOADO{}'.format(idx)] = 'DO{}'.format(idx)
        fifo_site_wire_map['DOBDO{}'.format(idx)] = 'DO{}'.format(idx + 16)

    for idx in range(2):
        fifo_site_wire_map['DOPADOP{}'.format(idx)] = 'DOP{}'.format(idx)
        fifo_site_wire_map['DOPBDOP{}'.format(idx)] = 'DOP{}'.format(idx + 2)

    def make_wire(wire_name):
        if fifo_site and wire_name in fifo_site_wire_map:
            return fifo_site_wire_map[wire_name]
        else:
            return wire_name

    for input_wire in [
            "CLKARDCLK",
            "CLKBWRCLK",
            "ENARDEN",
            "ENBWREN",
            "REGCEAREGCE",
            "REGCEB",
            "RSTRAMARSTRAM",
            "RSTRAMB",
            "RSTREGARSTREG",
            "RSTREGB",
    ]:
        wire_name = make_wire(input_wire)
        site.add_sink(bel, input_wire, wire_name)

    for input_wire, width in [
            # TODO: Add RAMB36 support.
            # Detect when ADDRATIEHIGH and ADDRBTIEHIGH are not tied high,
            # emit RAMB36 in that case.
            #("ADDRATIEHIGH", 2),
            #("ADDRBTIEHIGH", 2),
        ("ADDRARDADDR", 14),
        ("ADDRBWRADDR", 14),
        ("DIADI", 16),
        ("DIBDI", 16),
        ("DIPADIP", 2),
        ("DIPBDIP", 2),
    ]:
        for idx in range(width):
            wire_name = make_wire('{}{}'.format(input_wire, idx))
            site.add_sink(bel, '{}[{}]'.format(input_wire, idx), wire_name)

    # TODO: Add RAMB36 support.
    # In RAMB36, WEA and WEBWE don't double up like this
    if WRITE_WIDTH_A < 18:
        site.add_sink(bel, "WEA[0]", "WEA0")
    else:
        site.add_sink(bel, "WEA[0]", "WEA0")
        site.add_sink(bel, "WEA[1]", "WEA2")

    if WRITE_WIDTH_B < 18:
        site.add_sink(bel, "WEBWE[0]", "WEBWE0")
    elif WRITE_WIDTH_B == 18:
        site.add_sink(bel, "WEBWE[0]", "WEBWE0")
        site.add_sink(bel, "WEBWE[1]", "WEBWE2")
    else:
        assert WRITE_WIDTH_B == 36
        site.add_sink(bel, "WEBWE[0]", "WEBWE0")
        site.add_sink(bel, "WEBWE[1]", "WEBWE2")
        site.add_sink(bel, "WEBWE[2]", "WEBWE4")
        site.add_sink(bel, "WEBWE[3]", "WEBWE6")

    for output_wire, width in [
        ('DOADO', 16),
        ('DOPADOP', 2),
        ('DOBDO', 16),
        ('DOPBDOP', 2),
    ]:
        for idx in range(width):
            wire_name = make_wire('{}{}'.format(output_wire, idx))
            pin_name = '{}[{}]'.format(output_wire, idx)
            site.add_source(bel, pin_name, wire_name)

    top.add_site(site)


def process_bram(conn, top, tile, features):
    tile_features = set()

    brams = {'RAMB18_Y0': [], 'RAMB18_Y1': []}

    bram_features = {'RAMB18_Y0': set(), 'RAMB18_Y1': set()}

    for f in features:
        if f.value == 0:
            continue

        parts = f.feature.split('.')

        tile_features.add('.'.join(parts[1:]))

        if parts[1] in brams:
            bram_features[parts[1]].add('.'.join(parts[2:]))
            brams[parts[1]].append(f)
    """
    FIFO config:

    EN_SYN 27_171
    FIRST_WORD_FALL_THROUGH 27_170
    ZALMOST_EMPTY_OFFSET[12:0] 27_288
    ZALMOST_FULL_OFFSET[12:0] 27_32

    RAMB18 config:

    RAMB18_Y[01].FIFO_MODE 27_169
    RAMB18_Y[01].IN_USE 27_220 27_221

    RAMB18_Y[01].DOA_REG 27_251
    RAMB18_Y[01].DOB_REG 27_248
    RAMB18_Y[01].RDADDR_COLLISION_HWCONFIG_DELAYED_WRITE !27_224
    RAMB18_Y[01].RDADDR_COLLISION_HWCONFIG_PERFORMANCE 27_224
    RAMB18_Y[01].READ_WIDTH_A_1 !27_283 !27_284 !27_285
    RAMB18_Y[01].READ_WIDTH_A_2 !27_283 !27_284 27_285
    RAMB18_Y[01].READ_WIDTH_A_4 !27_283 27_284 !27_285
    RAMB18_Y[01].READ_WIDTH_A_9 !27_283 27_284 27_285
    RAMB18_Y[01].READ_WIDTH_A_18 27_283 !27_284 !27_285
    RAMB18_Y[01].READ_WIDTH_B_1 !27_275 !27_276 !27_277
    RAMB18_Y[01].READ_WIDTH_B_2 !27_275 !27_276 27_277
    RAMB18_Y[01].READ_WIDTH_B_4 !27_275 27_276 !27_277
    RAMB18_Y[01].READ_WIDTH_B_9 !27_275 27_276 27_277
    RAMB18_Y[01].READ_WIDTH_B_18 27_275 !27_276 !27_277
    RAMB18_Y[01].RSTREG_PRIORITY_A_REGCE 27_196
    RAMB18_Y[01].RSTREG_PRIORITY_A_RSTREG !27_196
    RAMB18_Y[01].RSTREG_PRIORITY_B_REGCE 27_195
    RAMB18_Y[01].RSTREG_PRIORITY_B_RSTREG !27_195

    RAMB18_Y[01].ZINV_CLKARDCLK 27_213
    RAMB18_Y[01].ZINV_CLKBWRCLK 27_211
    RAMB18_Y[01].ZINV_ENARDEN 27_208
    RAMB18_Y[01].ZINV_ENBWREN 27_205
    RAMB18_Y[01].ZINV_REGCLKARDRCLK 27_216
    RAMB18_Y[01].ZINV_REGCLKB 27_212
    RAMB18_Y[01].ZINV_RSTRAMARSTRAM 27_204
    RAMB18_Y[01].ZINV_RSTRAMB 27_203
    RAMB18_Y[01].ZINV_RSTREGARSTREG 27_200
    RAMB18_Y[01].ZINV_RSTREGB 27_197
    RAMB18_Y[01].ZINIT_A[17:0] 27_249
    RAMB18_Y[01].ZINIT_B[17:0] 27_255
    RAMB18_Y[01].ZSRVAL_A[17:0]
    RAMB18_Y[01].ZSRVAL_B[17:0]
    RAMB18_Y[01].SDP_READ_WIDTH_36 27_272
    RAMB18_Y[01].SDP_WRITE_WIDTH_36 27_280
    RAMB18_Y[01].WRITE_MODE_A_NO_CHANGE 27_256
    RAMB18_Y[01].WRITE_MODE_A_READ_FIRST 27_264
    RAMB18_Y[01].WRITE_MODE_B_NO_CHANGE 27_252
    RAMB18_Y[01].WRITE_MODE_B_READ_FIRST 27_253
    RAMB18_Y[01].WRITE_WIDTH_A_1 !27_267 !27_268 !27_269
    RAMB18_Y[01].WRITE_WIDTH_A_2 !27_267 !27_268 27_269
    RAMB18_Y[01].WRITE_WIDTH_A_4 !27_267 27_268 !27_269
    RAMB18_Y[01].WRITE_WIDTH_A_9 !27_267 27_268 27_269
    RAMB18_Y[01].WRITE_WIDTH_A_18 27_267 !27_268 !27_269
    RAMB18_Y[01].WRITE_WIDTH_B_1 !27_259 !27_260 !27_261
    RAMB18_Y[01].WRITE_WIDTH_B_2 !27_259 !27_260 27_261
    RAMB18_Y[01].WRITE_WIDTH_B_4 !27_259 27_260 !27_261
    RAMB18_Y[01].WRITE_WIDTH_B_9 !27_259 27_260 27_261
    RAMB18_Y[01].WRITE_WIDTH_B_18 27_259 !27_260 !27_261

    RAMB36 config:

    RAMB36.EN_ECC_READ
    RAMB36.EN_ECC_WRITE
    RAMB36.RAM_EXTENSION_A_LOWER
    RAMB36.RAM_EXTENSION_A_NONE_OR_UPPER
    RAMB36.RAM_EXTENSION_B_LOWER
    RAMB36.RAM_EXTENSION_B_NONE_OR_UPPER
    """

    for features in bram_features.values():
        # TODO: Add support for FIFO mode
        assert 'FIFO_MODE' not in features

    # TODO: Add support for data cascade.
    assert 'RAMB36.RAM_EXTENSION_A_NONE_OR_UPPER' in tile_features
    assert 'RAMB36.RAM_EXTENSION_B_NONE_OR_UPPER' in tile_features

    # TODO: Add support for RAMB36.
    assert 'RAMB36.EN_ECC_READ' not in tile_features
    assert 'RAMB36.EN_ECC_WRITE' not in tile_features

    for bram in brams:
        process_bram_site(top, brams[bram], bram_features[bram])
