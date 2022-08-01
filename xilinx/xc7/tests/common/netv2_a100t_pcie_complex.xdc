# pcie_pipe_clk
set_property LOC J19 [get_ports {pcie_pipe_clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {pcie_pipe_clk}]

# pcie_rst_n
set_property LOC E18 [get_ports {pcie_rst_n}]
set_property IOSTANDARD LVCMOS33 [get_ports {pcie_rst_n}]

# pcie_clk_p
set_property LOC F6 [get_ports {pcie_clk_p}]

# pcie_clk_n
set_property LOC E6 [get_ports {pcie_clk_n}]

# pcie_rx_p
set_property LOC B8 [get_ports {pcie_rx_p}]

# pcie_rx_n
set_property LOC A8 [get_ports {pcie_rx_n}]

# pcie_tx_p
set_property LOC B4 [get_ports {pcie_tx_p}]

# pcie_tx_n
set_property LOC A4 [get_ports {pcie_tx_n}]

# drprdy
set_property LOC P20 [get_ports {drprdy}]
