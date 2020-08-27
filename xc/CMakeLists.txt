set(ALL_XC7_DIFF_FASM_VERILOG TRUE CACHE BOOL "Link target diff_fasm to all_xc7_diff_fasm for Verilog/XDC inputs?")
set(ALL_XC7_DIFF_FASM_INTERCHANGE TRUE CACHE BOOL "Link target diff_fasm to all_xc7_diff_fasm for interchange inputs?")

add_subdirectory(common)

# Create rapidwright target, and populate it with RAPIDWRIGHT_INSTALLED variable
prepare_rapidwright()

add_subdirectory(xc7)
add_subdirectory(xcu)
