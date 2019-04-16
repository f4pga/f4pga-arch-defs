#add_file_target(FILE ff.pb_type.xml SCANNER_TYPE xml)
#add_file_target(FILE ff.model.xml SCANNER_TYPE xml)


foreach(SRC
        fdce_zini.sim.v
        fdpe_zini.sim.v
        fdre_zini.sim.v
        fdse_zini.sim.v
        ldce_zini.sim.v
        ldpe_zini.sim.v
        ff_async.sim.v
        ff_sync.sim.v
        latch.sim.v
        )

    add_file_target(FILE ${SRC} SCANNER_TYPE verilog)
    get_filename_component(BASE ${SRC} NAME_WE)
    string(TOUPPER BASE_UPPER ${BASE})
    v2x(
        NAME ${BASE}
        TOP_MODULE ${BASE_UPPER}
        SRCS ${SRC}
        )
endforeach()

add_file_target(FILE slice_ff.sim.v SCANNER_TYPE verilog)
v2x(
    NAME slice_ff
    OUTPUT_NAME ff
    TOP_MODULE SLICE_FF
    SRCS slice_ff.sim.v
    )


