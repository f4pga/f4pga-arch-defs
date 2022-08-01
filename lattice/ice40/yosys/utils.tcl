proc clean_processes {} {
    proc_clean
    proc_rmdead
    proc_prune
    proc_init
    proc_arst
    proc_mux
    proc_dlatch
    proc_dff
    proc_memwr
    proc_clean
}
