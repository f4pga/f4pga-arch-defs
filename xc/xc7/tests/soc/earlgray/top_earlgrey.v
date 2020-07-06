module top_earlgrey (
	clk_i,
	rst_ni,
	clk_usb_48mhz_i,
	jtag_tck_i,
	jtag_tms_i,
	jtag_trst_ni,
	jtag_td_i,
	jtag_td_o,
	mio_in_i,
	mio_out_o,
	mio_oe_o,
	dio_spi_device_sck_i,
	dio_spi_device_csb_i,
	dio_spi_device_mosi_i,
	dio_spi_device_miso_o,
	dio_spi_device_miso_en_o,
	dio_uart_rx_i,
	dio_uart_tx_o,
	dio_uart_tx_en_o,
	dio_usbdev_sense_i,
	dio_usbdev_pullup_o,
	dio_usbdev_pullup_en_o,
	dio_usbdev_dp_i,
	dio_usbdev_dp_o,
	dio_usbdev_dp_en_o,
	dio_usbdev_dn_i,
	dio_usbdev_dn_o,
	dio_usbdev_dn_en_o,
	scanmode_i
);
	localparam top_pkg_FLASH_BANKS = 2;
	localparam top_pkg_FLASH_PAGES_PER_BANK = 256;
	localparam top_pkg_FLASH_WORDS_PER_PAGE = 256;
	parameter signed [31:0] alert_handler_reg_pkg_NAlerts = 1;
	parameter signed [31:0] alert_handler_reg_pkg_N_ESC_SEV = 4;
	localparam top_pkg_FLASH_BKW = 1;
	localparam top_pkg_FLASH_BYTES_PER_WORD = 4;
	localparam top_pkg_FLASH_PGW = 8;
	localparam top_pkg_FLASH_WDW = 8;
	localparam [31:0] alert_pkg_NAlerts = alert_handler_reg_pkg_NAlerts;
	localparam [31:0] alert_pkg_N_ESC_SEV = alert_handler_reg_pkg_N_ESC_SEV;
	localparam [63:0] dm_ExceptionAddress = dm_HaltAddress + 8;
	localparam [63:0] dm_HaltAddress = 64'h800;
	localparam top_pkg_FLASH_AW = (top_pkg_FLASH_BKW + top_pkg_FLASH_PGW) + top_pkg_FLASH_WDW;
	localparam top_pkg_FLASH_DW = top_pkg_FLASH_BYTES_PER_WORD * 8;
	localparam top_pkg_TL_AIW = 8;
	localparam top_pkg_TL_AW = 32;
	localparam top_pkg_TL_DBW = top_pkg_TL_DW >> 3;
	localparam top_pkg_TL_DIW = 1;
	localparam top_pkg_TL_DUW = 16;
	localparam top_pkg_TL_DW = 32;
	localparam top_pkg_TL_SZW = $clog2($clog2(32 >> 3) + 1);
	parameter IbexPipeLine = 0;
	input clk_i;
	input rst_ni;
	input clk_usb_48mhz_i;
	input jtag_tck_i;
	input jtag_tms_i;
	input jtag_trst_ni;
	input jtag_td_i;
	output jtag_td_o;
	input [31:0] mio_in_i;
	output wire [31:0] mio_out_o;
	output wire [31:0] mio_oe_o;
	input dio_spi_device_sck_i;
	input dio_spi_device_csb_i;
	input dio_spi_device_mosi_i;
	output wire dio_spi_device_miso_o;
	output wire dio_spi_device_miso_en_o;
	input dio_uart_rx_i;
	output wire dio_uart_tx_o;
	output wire dio_uart_tx_en_o;
	input dio_usbdev_sense_i;
	output wire dio_usbdev_pullup_o;
	output wire dio_usbdev_pullup_en_o;
	input dio_usbdev_dp_i;
	output wire dio_usbdev_dp_o;
	output wire dio_usbdev_dp_en_o;
	input dio_usbdev_dn_i;
	output wire dio_usbdev_dn_o;
	output wire dio_usbdev_dn_en_o;
	input scanmode_i;
	localparam JTAG_IDCODE = {4'h0, 16'h4F54, 11'h426, 1'b1};
	parameter ArbiterImpl = "PPC";
	localparam [2:0] AccessAck = 3'h 0;
	localparam [2:0] PutFullData = 3'h 0;
	localparam [2:0] AccessAckData = 3'h 1;
	localparam [2:0] PutPartialData = 3'h 1;
	localparam [2:0] Get = 3'h 4;
	localparam TL_AW = 32;
	localparam TL_DW = 32;
	localparam TL_AIW = 8;
	localparam TL_DIW = 1;
	localparam TL_DUW = 16;
	localparam TL_DBW = TL_DW >> 3;
	localparam TL_SZW = $clog2($clog2(32 >> 3) + 1);
	localparam FLASH_BANKS = 2;
	localparam FLASH_PAGES_PER_BANK = 256;
	localparam FLASH_WORDS_PER_PAGE = 256;
	localparam FLASH_BYTES_PER_WORD = 4;
	localparam FLASH_BKW = 1;
	localparam FLASH_PGW = 8;
	localparam FLASH_WDW = 8;
	localparam FLASH_AW = (FLASH_BKW + FLASH_PGW) + FLASH_WDW;
	localparam FLASH_DW = FLASH_BYTES_PER_WORD * 8;
	localparam [31:0] ADDR_SPACE_ROM = 32'h 00008000;
	localparam [31:0] ADDR_SPACE_DEBUG_MEM = 32'h 1a110000;
	localparam [31:0] ADDR_SPACE_RAM_MAIN = 32'h 10000000;
	localparam [31:0] ADDR_SPACE_EFLASH = 32'h 20000000;
	localparam [95:0] ADDR_SPACE_PERI = {32'h 40000000, 32'h 40080000, 32'h 40150000};
	localparam [31:0] ADDR_SPACE_FLASH_CTRL = 32'h 40030000;
	localparam [31:0] ADDR_SPACE_HMAC = 32'h 40120000;
	localparam [31:0] ADDR_SPACE_AES = 32'h 40110000;
	localparam [31:0] ADDR_SPACE_RV_PLIC = 32'h 40090000;
	localparam [31:0] ADDR_SPACE_PINMUX = 32'h 40070000;
	localparam [31:0] ADDR_SPACE_ALERT_HANDLER = 32'h 40130000;
	localparam [31:0] ADDR_SPACE_NMI_GEN = 32'h 40140000;
	localparam [31:0] ADDR_MASK_ROM = 32'h 00003fff;
	localparam [31:0] ADDR_MASK_DEBUG_MEM = 32'h 00000fff;
	localparam [31:0] ADDR_MASK_RAM_MAIN = 32'h 0000ffff;
	localparam [31:0] ADDR_MASK_EFLASH = 32'h 0007ffff;
	localparam [95:0] ADDR_MASK_PERI = {32'h 00020fff, 32'h 00000fff, 32'h 00000fff};
	localparam [31:0] ADDR_MASK_FLASH_CTRL = 32'h 00000fff;
	localparam [31:0] ADDR_MASK_HMAC = 32'h 00000fff;
	localparam [31:0] ADDR_MASK_AES = 32'h 00000fff;
	localparam [31:0] ADDR_MASK_RV_PLIC = 32'h 00000fff;
	localparam [31:0] ADDR_MASK_PINMUX = 32'h 00000fff;
	localparam [31:0] ADDR_MASK_ALERT_HANDLER = 32'h 00000fff;
	localparam [31:0] ADDR_MASK_NMI_GEN = 32'h 00000fff;
	localparam signed [31:0] N_HOST = 3;
	localparam signed [31:0] N_DEVICE = 12;
	localparam TlCorei = 0;
	localparam TlRom = 0;
	localparam TlCored = 1;
	localparam TlDebugMem = 1;
	localparam TlAlertHandler = 10;
	localparam TlNmiGen = 11;
	localparam TlDmSba = 2;
	localparam TlRamMain = 2;
	localparam TlEflash = 3;
	localparam TlPeri = 4;
	localparam TlFlashCtrl = 5;
	localparam TlHmac = 6;
	localparam TlAes = 7;
	localparam TlRvPlic = 8;
	localparam TlPinmux = 9;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_corei_h_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_corei_h_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_cored_h_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_cored_h_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_dm_sba_h_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_dm_sba_h_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_debug_mem_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_debug_mem_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_uart_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_uart_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_gpio_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_gpio_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_spi_device_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_spi_device_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_flash_ctrl_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_flash_ctrl_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_rv_timer_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_rv_timer_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_aes_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_aes_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_hmac_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_hmac_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_rv_plic_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_rv_plic_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_pinmux_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_pinmux_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_alert_handler_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_alert_handler_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_nmi_gen_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_nmi_gen_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_usbdev_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_usbdev_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_rom_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_rom_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_ram_main_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_ram_main_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_eflash_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_eflash_d_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_main_h_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_main_h_d2h;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_AW) + ((top_pkg_TL_DBW - 1) >= 0 ? top_pkg_TL_DBW : 2 - top_pkg_TL_DBW)) + top_pkg_TL_DW) + 17) - 1:0] tl_peri_d_h2d;
	wire [((((((7 + ((top_pkg_TL_SZW - 1) >= 0 ? top_pkg_TL_SZW : 2 - top_pkg_TL_SZW)) + top_pkg_TL_AIW) + top_pkg_TL_DIW) + top_pkg_TL_DW) + top_pkg_TL_DUW) + 2) - 1:0] tl_peri_d_d2h;
	assign tl_main_h_h2d = tl_peri_d_h2d;
	assign tl_peri_d_d2h = tl_main_h_d2h;
	wire lc_rst_n;
	wire sys_rst_n;
	wire sys_fixed_rst_n;
	wire spi_device_rst_n;
	wire usb_rst_n;
	wire main_clk;
	wire fixed_clk;
	wire usb_clk;
	wire [31:0] m2p;
	wire [31:0] p2m;
	wire [31:0] p2m_en;
	wire cio_uart_rx_p2d;
	wire cio_uart_tx_d2p;
	wire cio_uart_tx_en_d2p;
	wire [31:0] cio_gpio_gpio_p2d;
	wire [31:0] cio_gpio_gpio_d2p;
	wire [31:0] cio_gpio_gpio_en_d2p;
	wire cio_spi_device_sck_p2d;
	wire cio_spi_device_csb_p2d;
	wire cio_spi_device_mosi_p2d;
	wire cio_spi_device_miso_d2p;
	wire cio_spi_device_miso_en_d2p;
	wire cio_usbdev_sense_p2d;
	wire cio_usbdev_dp_p2d;
	wire cio_usbdev_dn_p2d;
	wire cio_usbdev_pullup_d2p;
	wire cio_usbdev_pullup_en_d2p;
	wire cio_usbdev_dp_d2p;
	wire cio_usbdev_dp_en_d2p;
	wire cio_usbdev_dn_d2p;
	wire cio_usbdev_dn_en_d2p;
	wire [78:0] intr_vector;
	wire intr_uart_tx_watermark;
	wire intr_uart_rx_watermark;
	wire intr_uart_tx_empty;
	wire intr_uart_rx_overflow;
	wire intr_uart_rx_frame_err;
	wire intr_uart_rx_break_err;
	wire intr_uart_rx_timeout;
	wire intr_uart_rx_parity_err;
	wire [31:0] intr_gpio_gpio;
	wire intr_spi_device_rxf;
	wire intr_spi_device_rxlvl;
	wire intr_spi_device_txlvl;
	wire intr_spi_device_rxerr;
	wire intr_spi_device_rxoverflow;
	wire intr_spi_device_txunderflow;
	wire intr_flash_ctrl_prog_empty;
	wire intr_flash_ctrl_prog_lvl;
	wire intr_flash_ctrl_rd_full;
	wire intr_flash_ctrl_rd_lvl;
	wire intr_flash_ctrl_op_done;
	wire intr_flash_ctrl_op_error;
	wire intr_rv_timer_timer_expired_0_0;
	wire intr_hmac_hmac_done;
	wire intr_hmac_fifo_full;
	wire intr_hmac_hmac_err;
	wire intr_alert_handler_classa;
	wire intr_alert_handler_classb;
	wire intr_alert_handler_classc;
	wire intr_alert_handler_classd;
	wire intr_nmi_gen_esc0;
	wire intr_nmi_gen_esc1;
	wire intr_nmi_gen_esc2;
	wire intr_nmi_gen_esc3;
	wire intr_usbdev_pkt_received;
	wire intr_usbdev_pkt_sent;
	wire intr_usbdev_disconnected;
	wire intr_usbdev_host_lost;
	wire intr_usbdev_link_reset;
	wire intr_usbdev_link_suspend;
	wire intr_usbdev_link_resume;
	wire intr_usbdev_av_empty;
	wire intr_usbdev_rx_full;
	wire intr_usbdev_av_overflow;
	wire intr_usbdev_link_in_err;
	wire intr_usbdev_rx_crc_err;
	wire intr_usbdev_rx_pid_err;
	wire intr_usbdev_rx_bitstuff_err;
	wire intr_usbdev_frame;
	wire intr_usbdev_connected;
	wire [0:0] irq_plic;
	wire [0:0] msip;
	wire [6:0] irq_id;
	wire [6:0] unused_irq_id;
	assign unused_irq_id = irq_id;
	wire [((alert_pkg_NAlerts - 1) >= 0 ? (alert_pkg_NAlerts * 2) + -1 : ((2 - alert_pkg_NAlerts) * 2) + (((alert_pkg_NAlerts - 1) * 2) - 1)):((alert_pkg_NAlerts - 1) >= 0 ? 0 : (alert_pkg_NAlerts - 1) * 2)] alert_tx;
	wire [((alert_pkg_NAlerts - 1) >= 0 ? (alert_pkg_NAlerts * 4) + -1 : ((2 - alert_pkg_NAlerts) * 4) + (((alert_pkg_NAlerts - 1) * 4) - 1)):((alert_pkg_NAlerts - 1) >= 0 ? 0 : (alert_pkg_NAlerts - 1) * 4)] alert_rx;
	wire [((alert_pkg_N_ESC_SEV - 1) >= 0 ? (alert_pkg_N_ESC_SEV * 2) + -1 : ((2 - alert_pkg_N_ESC_SEV) * 2) + (((alert_pkg_N_ESC_SEV - 1) * 2) - 1)):((alert_pkg_N_ESC_SEV - 1) >= 0 ? 0 : (alert_pkg_N_ESC_SEV - 1) * 2)] esc_tx;
	wire [((alert_pkg_N_ESC_SEV - 1) >= 0 ? (alert_pkg_N_ESC_SEV * 2) + -1 : ((2 - alert_pkg_N_ESC_SEV) * 2) + (((alert_pkg_N_ESC_SEV - 1) * 2) - 1)):((alert_pkg_N_ESC_SEV - 1) >= 0 ? 0 : (alert_pkg_N_ESC_SEV - 1) * 2)] esc_rx;
	assign main_clk = clk_i;
	assign fixed_clk = clk_i;
	assign usb_clk = clk_usb_48mhz_i;
	wire ndmreset_req;
	assign lc_rst_n = rst_ni;
	assign sys_rst_n = (scanmode_i ? lc_rst_n : ~ndmreset_req & lc_rst_n);
	assign sys_fixed_rst_n = sys_rst_n;
	assign spi_device_rst_n = sys_rst_n;
	reg [1:0] usb_rst_q;
	always @(posedge usb_clk) usb_rst_q <= {usb_rst_q[0], sys_rst_n};
	assign usb_rst_n = sys_rst_n & usb_rst_q[1];
	wire debug_req;
	rv_core_ibex #(
		.PMPEnable(0),
		.PMPGranularity(0),
		.PMPNumRegions(4),
		.MHPMCounterNum(8),
		.MHPMCounterWidth(40),
		.RV32E(0),
		.RV32M(1),
		.DbgTriggerEn(1),
		.DmHaltAddr(ADDR_SPACE_DEBUG_MEM + dm_HaltAddress),
		.DmExceptionAddr(ADDR_SPACE_DEBUG_MEM + dm_ExceptionAddress),
		.PipeLine(IbexPipeLine)
	) core(
		.clk_i(main_clk),
		.rst_ni(sys_rst_n),
		.test_en_i(1'b0),
		.hart_id_i(32'b0),
		.boot_addr_i(ADDR_SPACE_ROM),
		.tl_i_o(tl_corei_h_h2d),
		.tl_i_i(tl_corei_h_d2h),
		.tl_d_o(tl_cored_h_h2d),
		.tl_d_i(tl_cored_h_d2h),
		.irq_software_i(msip),
		.irq_timer_i(intr_rv_timer_timer_expired_0_0),
		.irq_external_i(irq_plic),
		.irq_fast_i(15'b0),
		.irq_nm_i(1'b0),
		.debug_req_i(debug_req),
		.fetch_enable_i(1'b1),
		.core_sleep_o()
	);
	rv_dm #(
		.NrHarts(1),
		.IdcodeValue(JTAG_IDCODE)
	) u_dm_top(
		.clk_i(main_clk),
		.rst_ni(lc_rst_n),
		.testmode_i(1'b0),
		.ndmreset_o(ndmreset_req),
		.dmactive_o(),
		.debug_req_o(debug_req),
		.unavailable_i(1'b0),
		.tl_d_i(tl_debug_mem_d_h2d),
		.tl_d_o(tl_debug_mem_d_d2h),
		.tl_h_o(tl_dm_sba_h_h2d),
		.tl_h_i(tl_dm_sba_h_d2h),
		.tck_i(jtag_tck_i),
		.tms_i(jtag_tms_i),
		.trst_ni(jtag_trst_ni),
		.td_i(jtag_td_i),
		.td_o(jtag_td_o),
		.tdo_oe_o()
	);
	wire rom_req;
	wire [11:0] rom_addr;
	wire [31:0] rom_rdata;
	wire rom_rvalid;
	tlul_adapter_sram #(
		.SramAw(12),
		.SramDw(32),
		.Outstanding(2),
		.ErrOnWrite(1)
	) tl_adapter_rom(
		.clk_i(main_clk),
		.rst_ni(sys_rst_n),
		.tl_i(tl_rom_d_h2d),
		.tl_o(tl_rom_d_d2h),
		.req_o(rom_req),
		.gnt_i(1'b1),
		.we_o(),
		.addr_o(rom_addr),
		.wdata_o(),
		.wmask_o(),
		.rdata_i(rom_rdata),
		.rvalid_i(rom_rvalid),
		.rerror_i(2'b00)
	);
	prim_rom #(
		.Width(32),
		.Depth(4096)
	) u_rom_rom(
		.clk_i(main_clk),
		.rst_ni(sys_rst_n),
		.cs_i(rom_req),
		.addr_i(rom_addr),
		.dout_o(rom_rdata),
		.dvalid_o(rom_rvalid)
	);
	wire ram_main_req;
	wire ram_main_we;
	wire [13:0] ram_main_addr;
	wire [31:0] ram_main_wdata;
	wire [31:0] ram_main_wmask;
	wire [31:0] ram_main_rdata;
	wire ram_main_rvalid;
	tlul_adapter_sram #(
		.SramAw(14),
		.SramDw(32),
		.Outstanding(2)
	) tl_adapter_ram_main(
		.clk_i(main_clk),
		.rst_ni(sys_rst_n),
		.tl_i(tl_ram_main_d_h2d),
		.tl_o(tl_ram_main_d_d2h),
		.req_o(ram_main_req),
		.gnt_i(1'b1),
		.we_o(ram_main_we),
		.addr_o(ram_main_addr),
		.wdata_o(ram_main_wdata),
		.wmask_o(ram_main_wmask),
		.rdata_i(ram_main_rdata),
		.rvalid_i(ram_main_rvalid),
		.rerror_i(2'b00)
	);
	prim_ram_1p #(
		.Width(32),
		.Depth(16384),
		.DataBitsPerMask(8)
	) u_ram1p_ram_main(
		.clk_i(main_clk),
		.rst_ni(sys_rst_n),
		.req_i(ram_main_req),
		.write_i(ram_main_we),
		.addr_i(ram_main_addr),
		.wdata_i(ram_main_wdata),
		.wmask_i(ram_main_wmask),
		.rvalid_o(ram_main_rvalid),
		.rdata_o(ram_main_rdata)
	);
	wire [((5 + top_pkg_FLASH_AW) + top_pkg_FLASH_DW) - 1:0] flash_ctrl_eflash_flash_req;
	wire [((3 + top_pkg_FLASH_DW) + 1) - 1:0] flash_ctrl_eflash_flash_rsp;
	wire flash_host_req;
	wire flash_host_req_rdy;
	wire flash_host_req_done;
	wire [FLASH_DW - 1:0] flash_host_rdata;
	wire [FLASH_AW - 1:0] flash_host_addr;
	tlul_adapter_sram #(
		.SramAw(FLASH_AW),
		.SramDw(FLASH_DW),
		.Outstanding(2),
		.ByteAccess(0),
		.ErrOnWrite(1)
	) tl_adapter_eflash(
		.clk_i(main_clk),
		.rst_ni(lc_rst_n),
		.tl_i(tl_eflash_d_h2d),
		.tl_o(tl_eflash_d_d2h),
		.req_o(flash_host_req),
		.gnt_i(flash_host_req_rdy),
		.we_o(),
		.addr_o(flash_host_addr),
		.wdata_o(),
		.wmask_o(),
		.rdata_i(flash_host_rdata),
		.rvalid_i(flash_host_req_done),
		.rerror_i(2'b00)
	);
	flash_phy #(
		.NumBanks(FLASH_BANKS),
		.PagesPerBank(FLASH_PAGES_PER_BANK),
		.WordsPerPage(FLASH_WORDS_PER_PAGE),
		.DataWidth(32)
	) u_flash_eflash(
		.clk_i(main_clk),
		.rst_ni(lc_rst_n),
		.host_req_i(flash_host_req),
		.host_addr_i(flash_host_addr),
		.host_req_rdy_o(flash_host_req_rdy),
		.host_req_done_o(flash_host_req_done),
		.host_rdata_o(flash_host_rdata),
		.flash_ctrl_i(flash_ctrl_eflash_flash_req),
		.flash_ctrl_o(flash_ctrl_eflash_flash_rsp)
	);
	uart uart(
		.tl_i(tl_uart_d_h2d),
		.tl_o(tl_uart_d_d2h),
		.cio_rx_i(cio_uart_rx_p2d),
		.cio_tx_o(cio_uart_tx_d2p),
		.cio_tx_en_o(cio_uart_tx_en_d2p),
		.intr_tx_watermark_o(intr_uart_tx_watermark),
		.intr_rx_watermark_o(intr_uart_rx_watermark),
		.intr_tx_empty_o(intr_uart_tx_empty),
		.intr_rx_overflow_o(intr_uart_rx_overflow),
		.intr_rx_frame_err_o(intr_uart_rx_frame_err),
		.intr_rx_break_err_o(intr_uart_rx_break_err),
		.intr_rx_timeout_o(intr_uart_rx_timeout),
		.intr_rx_parity_err_o(intr_uart_rx_parity_err),
		.clk_i(fixed_clk),
		.rst_ni(sys_fixed_rst_n)
	);
	gpio gpio(
		.tl_i(tl_gpio_d_h2d),
		.tl_o(tl_gpio_d_d2h),
		.cio_gpio_i(cio_gpio_gpio_p2d),
		.cio_gpio_o(cio_gpio_gpio_d2p),
		.cio_gpio_en_o(cio_gpio_gpio_en_d2p),
		.intr_gpio_o(intr_gpio_gpio),
		.clk_i(fixed_clk),
		.rst_ni(sys_fixed_rst_n)
	);
	spi_device spi_device(
		.tl_i(tl_spi_device_d_h2d),
		.tl_o(tl_spi_device_d_d2h),
		.cio_sck_i(cio_spi_device_sck_p2d),
		.cio_csb_i(cio_spi_device_csb_p2d),
		.cio_mosi_i(cio_spi_device_mosi_p2d),
		.cio_miso_o(cio_spi_device_miso_d2p),
		.cio_miso_en_o(cio_spi_device_miso_en_d2p),
		.intr_rxf_o(intr_spi_device_rxf),
		.intr_rxlvl_o(intr_spi_device_rxlvl),
		.intr_txlvl_o(intr_spi_device_txlvl),
		.intr_rxerr_o(intr_spi_device_rxerr),
		.intr_rxoverflow_o(intr_spi_device_rxoverflow),
		.intr_txunderflow_o(intr_spi_device_txunderflow),
		.scanmode_i(scanmode_i),
		.clk_i(fixed_clk),
		.rst_ni(spi_device_rst_n)
	);
	flash_ctrl flash_ctrl(
		.tl_i(tl_flash_ctrl_d_h2d),
		.tl_o(tl_flash_ctrl_d_d2h),
		.intr_prog_empty_o(intr_flash_ctrl_prog_empty),
		.intr_prog_lvl_o(intr_flash_ctrl_prog_lvl),
		.intr_rd_full_o(intr_flash_ctrl_rd_full),
		.intr_rd_lvl_o(intr_flash_ctrl_rd_lvl),
		.intr_op_done_o(intr_flash_ctrl_op_done),
		.intr_op_error_o(intr_flash_ctrl_op_error),
		.flash_o(flash_ctrl_eflash_flash_req),
		.flash_i(flash_ctrl_eflash_flash_rsp),
		.clk_i(main_clk),
		.rst_ni(lc_rst_n)
	);
	rv_timer rv_timer(
		.tl_i(tl_rv_timer_d_h2d),
		.tl_o(tl_rv_timer_d_d2h),
		.intr_timer_expired_0_0_o(intr_rv_timer_timer_expired_0_0),
		.clk_i(fixed_clk),
		.rst_ni(sys_fixed_rst_n)
	);
	aes aes(
		.tl_i(tl_aes_d_h2d),
		.tl_o(tl_aes_d_d2h),
		.clk_i(main_clk),
		.rst_ni(sys_rst_n)
	);
	hmac hmac(
		.tl_i(tl_hmac_d_h2d),
		.tl_o(tl_hmac_d_d2h),
		.intr_hmac_done_o(intr_hmac_hmac_done),
		.intr_fifo_full_o(intr_hmac_fifo_full),
		.intr_hmac_err_o(intr_hmac_hmac_err),
		.alert_tx_o(alert_tx[2 * ((alert_pkg_NAlerts - 1) >= 0 ? ((alert_pkg_NAlerts - 1) >= 0 ? 0 : 0) : 0 - (((alert_pkg_NAlerts - 1) >= 0 ? 0 : 0) - (alert_pkg_NAlerts - 1)))+:2]),
		.alert_rx_i(alert_rx[4 * ((alert_pkg_NAlerts - 1) >= 0 ? ((alert_pkg_NAlerts - 1) >= 0 ? 0 : 0) : 0 - (((alert_pkg_NAlerts - 1) >= 0 ? 0 : 0) - (alert_pkg_NAlerts - 1)))+:4]),
		.clk_i(main_clk),
		.rst_ni(sys_rst_n)
	);
	rv_plic rv_plic(
		.tl_i(tl_rv_plic_d_h2d),
		.tl_o(tl_rv_plic_d_d2h),
		.intr_src_i(intr_vector),
		.irq_o(irq_plic),
		.irq_id_o(irq_id),
		.msip_o(msip),
		.clk_i(main_clk),
		.rst_ni(sys_rst_n)
	);
	pinmux pinmux(
		.tl_i(tl_pinmux_d_h2d),
		.tl_o(tl_pinmux_d_d2h),
		.periph_to_mio_i(p2m),
		.periph_to_mio_oe_i(p2m_en),
		.mio_to_periph_o(m2p),
		.mio_out_o(mio_out_o),
		.mio_oe_o(mio_oe_o),
		.mio_in_i(mio_in_i),
		.clk_i(main_clk),
		.rst_ni(sys_rst_n)
	);
	alert_handler alert_handler(
		.tl_i(tl_alert_handler_d_h2d),
		.tl_o(tl_alert_handler_d_d2h),
		.intr_classa_o(intr_alert_handler_classa),
		.intr_classb_o(intr_alert_handler_classb),
		.intr_classc_o(intr_alert_handler_classc),
		.intr_classd_o(intr_alert_handler_classd),
		.crashdump_o(),
		.entropy_i(1'b0),
		.alert_rx_o(alert_rx),
		.alert_tx_i(alert_tx),
		.esc_rx_i(esc_rx),
		.esc_tx_o(esc_tx),
		.clk_i(main_clk),
		.rst_ni(sys_rst_n)
	);
	nmi_gen nmi_gen(
		.tl_i(tl_nmi_gen_d_h2d),
		.tl_o(tl_nmi_gen_d_d2h),
		.intr_esc0_o(intr_nmi_gen_esc0),
		.intr_esc1_o(intr_nmi_gen_esc1),
		.intr_esc2_o(intr_nmi_gen_esc2),
		.intr_esc3_o(intr_nmi_gen_esc3),
		.esc_rx_o(esc_rx),
		.esc_tx_i(esc_tx),
		.clk_i(main_clk),
		.rst_ni(sys_rst_n)
	);
	usbdev usbdev(
		.tl_i(tl_usbdev_d_h2d),
		.tl_o(tl_usbdev_d_d2h),
		.cio_d_i(1'b0),
		.cio_d_o(),
		.cio_se0_o(),
		.cio_dp_i(cio_usbdev_dp_p2d),
		.cio_dn_i(cio_usbdev_dn_p2d),
		.cio_dp_o(cio_usbdev_dp_d2p),
		.cio_dn_o(cio_usbdev_dn_d2p),
		.cio_sense_i(cio_usbdev_sense_p2d),
		.cio_oe_o(cio_usbdev_dp_en_d2p),
		.cio_tx_mode_se_o(),
		.cio_pullup_en_o(cio_usbdev_pullup_en_d2p),
		.cio_suspend_o(),
		.intr_pkt_received_o(intr_usbdev_pkt_received),
		.intr_pkt_sent_o(intr_usbdev_pkt_sent),
		.intr_disconnected_o(intr_usbdev_disconnected),
		.intr_host_lost_o(intr_usbdev_host_lost),
		.intr_link_reset_o(intr_usbdev_link_reset),
		.intr_link_suspend_o(intr_usbdev_link_suspend),
		.intr_link_resume_o(intr_usbdev_link_resume),
		.intr_av_empty_o(intr_usbdev_av_empty),
		.intr_rx_full_o(intr_usbdev_rx_full),
		.intr_av_overflow_o(intr_usbdev_av_overflow),
		.intr_link_in_err_o(intr_usbdev_link_in_err),
		.intr_rx_crc_err_o(intr_usbdev_rx_crc_err),
		.intr_rx_pid_err_o(intr_usbdev_rx_pid_err),
		.intr_rx_bitstuff_err_o(intr_usbdev_rx_bitstuff_err),
		.intr_frame_o(intr_usbdev_frame),
		.intr_connected_o(intr_usbdev_connected),
		.clk_i(fixed_clk),
		.clk_usb_48mhz_i(usb_clk),
		.rst_ni(sys_fixed_rst_n),
		.rst_usb_48mhz_ni(usb_rst_n)
	);
	assign cio_usbdev_dn_en_d2p = cio_usbdev_dp_en_d2p;
	assign cio_usbdev_pullup_d2p = 1'b1;
	assign intr_vector = {intr_usbdev_connected, intr_usbdev_frame, intr_usbdev_rx_bitstuff_err, intr_usbdev_rx_pid_err, intr_usbdev_rx_crc_err, intr_usbdev_link_in_err, intr_usbdev_av_overflow, intr_usbdev_rx_full, intr_usbdev_av_empty, intr_usbdev_link_resume, intr_usbdev_link_suspend, intr_usbdev_link_reset, intr_usbdev_host_lost, intr_usbdev_disconnected, intr_usbdev_pkt_sent, intr_usbdev_pkt_received, intr_nmi_gen_esc3, intr_nmi_gen_esc2, intr_nmi_gen_esc1, intr_nmi_gen_esc0, intr_alert_handler_classd, intr_alert_handler_classc, intr_alert_handler_classb, intr_alert_handler_classa, intr_hmac_hmac_err, intr_hmac_fifo_full, intr_hmac_hmac_done, intr_flash_ctrl_op_error, intr_flash_ctrl_op_done, intr_flash_ctrl_rd_lvl, intr_flash_ctrl_rd_full, intr_flash_ctrl_prog_lvl, intr_flash_ctrl_prog_empty, intr_spi_device_txunderflow, intr_spi_device_rxoverflow, intr_spi_device_rxerr, intr_spi_device_txlvl, intr_spi_device_rxlvl, intr_spi_device_rxf, intr_uart_rx_parity_err, intr_uart_rx_timeout, intr_uart_rx_break_err, intr_uart_rx_frame_err, intr_uart_rx_overflow, intr_uart_tx_empty, intr_uart_rx_watermark, intr_uart_tx_watermark, intr_gpio_gpio};
	xbar_main u_xbar_main(
		.clk_main_i(main_clk),
		.clk_fixed_i(fixed_clk),
		.rst_main_ni(sys_rst_n),
		.rst_fixed_ni(sys_fixed_rst_n),
		.tl_corei_i(tl_corei_h_h2d),
		.tl_corei_o(tl_corei_h_d2h),
		.tl_cored_i(tl_cored_h_h2d),
		.tl_cored_o(tl_cored_h_d2h),
		.tl_dm_sba_i(tl_dm_sba_h_h2d),
		.tl_dm_sba_o(tl_dm_sba_h_d2h),
		.tl_rom_o(tl_rom_d_h2d),
		.tl_rom_i(tl_rom_d_d2h),
		.tl_debug_mem_o(tl_debug_mem_d_h2d),
		.tl_debug_mem_i(tl_debug_mem_d_d2h),
		.tl_ram_main_o(tl_ram_main_d_h2d),
		.tl_ram_main_i(tl_ram_main_d_d2h),
		.tl_eflash_o(tl_eflash_d_h2d),
		.tl_eflash_i(tl_eflash_d_d2h),
		.tl_peri_o(tl_peri_d_h2d),
		.tl_peri_i(tl_peri_d_d2h),
		.tl_flash_ctrl_o(tl_flash_ctrl_d_h2d),
		.tl_flash_ctrl_i(tl_flash_ctrl_d_d2h),
		.tl_hmac_o(tl_hmac_d_h2d),
		.tl_hmac_i(tl_hmac_d_d2h),
		.tl_aes_o(tl_aes_d_h2d),
		.tl_aes_i(tl_aes_d_d2h),
		.tl_rv_plic_o(tl_rv_plic_d_h2d),
		.tl_rv_plic_i(tl_rv_plic_d_d2h),
		.tl_pinmux_o(tl_pinmux_d_h2d),
		.tl_pinmux_i(tl_pinmux_d_d2h),
		.tl_alert_handler_o(tl_alert_handler_d_h2d),
		.tl_alert_handler_i(tl_alert_handler_d_d2h),
		.tl_nmi_gen_o(tl_nmi_gen_d_h2d),
		.tl_nmi_gen_i(tl_nmi_gen_d_d2h),
		.scanmode_i(scanmode_i)
	);
	xbar_peri u_xbar_peri(
		.clk_peri_i(fixed_clk),
		.rst_peri_ni(sys_fixed_rst_n),
		.tl_main_i(tl_main_h_h2d),
		.tl_main_o(tl_main_h_d2h),
		.tl_uart_o(tl_uart_d_h2d),
		.tl_uart_i(tl_uart_d_d2h),
		.tl_gpio_o(tl_gpio_d_h2d),
		.tl_gpio_i(tl_gpio_d_d2h),
		.tl_spi_device_o(tl_spi_device_d_h2d),
		.tl_spi_device_i(tl_spi_device_d_d2h),
		.tl_rv_timer_o(tl_rv_timer_d_h2d),
		.tl_rv_timer_i(tl_rv_timer_d_d2h),
		.tl_usbdev_o(tl_usbdev_d_h2d),
		.tl_usbdev_i(tl_usbdev_d_d2h),
		.scanmode_i(scanmode_i)
	);
	assign p2m = cio_gpio_gpio_d2p;
	assign p2m_en = cio_gpio_gpio_en_d2p;
	assign {cio_gpio_gpio_p2d} = m2p;
	assign cio_spi_device_sck_p2d = dio_spi_device_sck_i;
	assign cio_spi_device_csb_p2d = dio_spi_device_csb_i;
	assign cio_spi_device_mosi_p2d = dio_spi_device_mosi_i;
	assign dio_spi_device_miso_o = cio_spi_device_miso_d2p;
	assign dio_spi_device_miso_en_o = cio_spi_device_miso_en_d2p;
	assign cio_uart_rx_p2d = dio_uart_rx_i;
	assign dio_uart_tx_o = cio_uart_tx_d2p;
	assign dio_uart_tx_en_o = cio_uart_tx_en_d2p;
	assign cio_usbdev_sense_p2d = dio_usbdev_sense_i;
	assign dio_usbdev_pullup_o = cio_usbdev_pullup_d2p;
	assign dio_usbdev_pullup_en_o = cio_usbdev_pullup_en_d2p;
	assign cio_usbdev_dp_p2d = dio_usbdev_dp_i;
	assign dio_usbdev_dp_o = cio_usbdev_dp_d2p;
	assign dio_usbdev_dp_en_o = cio_usbdev_dp_en_d2p;
	assign cio_usbdev_dn_p2d = dio_usbdev_dn_i;
	assign dio_usbdev_dn_o = cio_usbdev_dn_d2p;
	assign dio_usbdev_dn_en_o = cio_usbdev_dn_en_d2p;
endmodule
