// Copyright 2016 by the authors
//
// Copyright and related rights are licensed under the Solderpad
// Hardware License, Version 0.51 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a
// copy of the License at http://solderpad.org/licenses/SHL-0.51.
// Unless required by applicable law or agreed to in writing,
// software, hardware and materials distributed under this License is
// distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the
// License.
//
// Authors:
//    Stefan Wallentowitz <stefan@wallentowitz.de>

module wb2axi
  #(parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter AXI_ID_WIDTH = 1,
    parameter AXI_ID = 0)
   (
    input                     clk,
    input                     rst,

    // Wishbone signals
    input                     wb_cyc_i,
    input                     wb_stb_i,
    input                     wb_we_i,
    input [ADDR_WIDTH-1:0]    wb_adr_i,
    input [DATA_WIDTH-1:0]    wb_dat_i,
    input [DATA_WIDTH/8-1:0]  wb_sel_i,
    input [2:0]               wb_cti_i,
    input [1:0]               wb_bte_i,
    output                    wb_ack_o,
    output                    wb_err_o,
    output                    wb_rty_o,
    output [DATA_WIDTH-1:0]   wb_dat_o,

    // AXI signals
    output [AXI_ID_WIDTH-1:0] m_axi_awid,
    output [ADDR_WIDTH-1:0]   m_axi_awaddr,
    output [7:0]              m_axi_awlen,
    output [2:0]              m_axi_awsize,
    output [1:0]              m_axi_awburst,
    output [3:0]              m_axi_awcache,
    output [2:0]              m_axi_awprot,
    output [3:0]              m_axi_awqos,
    output                    m_axi_awvalid,
    input                     m_axi_awready,

    output [AXI_ID_WIDTH-1:0] m_axi_wid,
    output [DATA_WIDTH-1:0]   m_axi_wdata,
    output [DATA_WIDTH/8-1:0] m_axi_wstrb,
    output                    m_axi_wlast,
    output                    m_axi_wvalid,
    input                     m_axi_wready,

    input [AXI_ID_WIDTH-1:0]  m_axi_bid,
    input [1:0]               m_axi_bresp,
    input                     m_axi_bvalid,
    output                    m_axi_bready,

    output [AXI_ID_WIDTH-1:0] m_axi_arid,
    output [ADDR_WIDTH-1:0]   m_axi_araddr,
    output [7:0]              m_axi_arlen,
    output [2:0]              m_axi_arsize,
    output [1:0]              m_axi_arburst,
    output [3:0]              m_axi_arcache,
    output [2:0]              m_axi_arprot,
    output [3:0]              m_axi_arqos,
    output                    m_axi_arvalid,
    input                     m_axi_arready,

    input [AXI_ID_WIDTH-1:0]  m_axi_rid,
    input [DATA_WIDTH-1:0]    m_axi_rdata,
    input [1:0]               m_axi_rresp,
    input                     m_axi_rlast,
    input                     m_axi_rvalid,
    output                    m_axi_rready
    );


   assign m_axi_awid = AXI_ID;
   assign m_axi_awaddr = wb_adr_i;
   assign m_axi_awlen = 0;
   assign m_axi_awsize = $clog2(DATA_WIDTH) - 3;
   assign m_axi_awburst = 2'b01;
   assign m_axi_awcache = 4'b0000;
   assign m_axi_awprot = 3'b000;
   assign m_axi_awqos = 4'b0000;

   assign m_axi_wdata = wb_dat_i;
   assign m_axi_wstrb = wb_sel_i;
   assign m_axi_wlast = 1;

   assign m_axi_arid = AXI_ID;
   assign m_axi_araddr = wb_adr_i;
   assign m_axi_arlen = 0;
   assign m_axi_arsize = $clog2(DATA_WIDTH) - 3;
   assign m_axi_arburst = 2'b01;
   assign m_axi_arcache = 4'b0000;
   assign m_axi_arprot = 3'b000;
   assign m_axi_arqos = 4'b0000;

   logic                             write_transfer;
   logic                             read_transfer;

   assign write_transfer = (wb_cyc_i & wb_stb_i) & wb_we_i;
   assign read_transfer = (wb_cyc_i & wb_stb_i) & !wb_we_i;

   reg                               awdone, wdone, ardone;

   always @(posedge clk) begin
      if (rst) begin
         awdone <= 0;
         wdone <= 0;
         ardone <= 0;
      end else begin
         if (awdone & m_axi_bvalid)
           awdone <= 0;
         else if (write_transfer & m_axi_awready)
           awdone <= 1;

         if (wdone & m_axi_bvalid)
           wdone <= 0;
         else if (write_transfer & m_axi_wready)
           wdone <= 1;

         if (ardone & m_axi_rvalid)
           ardone <= 0;
         else if (read_transfer & m_axi_arready)
           ardone <= 1;
      end
   end

   assign m_axi_awvalid = write_transfer & !awdone;
   assign m_axi_wvalid = write_transfer & !wdone;
   assign m_axi_arvalid = read_transfer & !ardone;

   assign m_axi_bready = 1;
   assign m_axi_rready = 1;

   logic transfer_done, transfer_success;
   assign transfer_done = m_axi_bvalid | m_axi_rvalid;
   assign transfer_success = (m_axi_bvalid & !m_axi_bresp[1]) |
                             (m_axi_rvalid & !m_axi_rresp[1]);

   assign wb_ack_o = transfer_done & transfer_success;
   assign wb_err_o = transfer_done & !transfer_success;
   assign wb_rty_o = 0;

   assign wb_dat_o = m_axi_rdata;


endmodule // wb2axi


