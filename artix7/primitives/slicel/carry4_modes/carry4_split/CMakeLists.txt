add_subdirectory(carry4_Nmux)
add_subdirectory(carry4_Nxor)

MAKE_FILE_TARGET(FILE carry4_split.sim.v)

V2X(
  NAME carry4_split
  SRCS
    carry4_split.sim.v
    carry4_Nmux/carry4_amux.sim.v
    carry4_Nmux/carry4_bmux.sim.v
    carry4_Nmux/carry4_cmux.sim.v
    carry4_Nmux/carry4_dmux.sim.v
    carry4_Nxor/carry4_axor.sim.v
    carry4_Nxor/carry4_bxor.sim.v
    carry4_Nxor/carry4_cxor.sim.v
    carry4_Nxor/carry4_dxor.sim.v
  )
