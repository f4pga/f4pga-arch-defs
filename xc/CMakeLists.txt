set(UPDATE_ARCH_TIMINGS ${symbiflow-arch-defs_SOURCE_DIR}/utils/update_arch_timings.py)
set(UPDATE_PACK_PATTERNS ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/add_pack_patterns.py)

#add global targets for scripts used in arch generation
add_file_target(FILE ${UPDATE_ARCH_TIMINGS} ABSOLUTE)
add_file_target(FILE ${UPDATE_PACK_PATTERNS} ABSOLUTE)

add_subdirectory(common)
add_subdirectory(xc7)
