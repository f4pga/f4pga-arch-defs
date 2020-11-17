#!/usr/bin/env python3

import argparse
import os

from litex.soc.integration.builder import Builder

from linux.soc_linux import SoCLinux, video_resolutions

kB = 1024

# Board definition----------------------------------------------------------------------------------


class Board:
    soc_kwargs = {"integrated_rom_size": 0x10000, "sys_clk_freq": int(60e6)}

    def __init__(self, soc_cls=None, soc_capabilities={}, bitstream_ext=""):
        self.soc_cls = soc_cls
        self.soc_capabilities = soc_capabilities
        self.bitstream_ext = bitstream_ext

    def load(self, filename):
        prog = self.platform.create_programmer()
        prog.load_bitstream(filename)

    def flash(self):
        raise NotImplementedError


# Arty support -------------------------------------------------------------------------------------


class Arty(Board):
    SPIFLASH_PAGE_SIZE = 256
    SPIFLASH_SECTOR_SIZE = 64 * kB
    SPIFLASH_DUMMY_CYCLES = 11

    def __init__(self):
        from litex_boards.targets import arty
        Board.__init__(
            self,
            arty.BaseSoC,
            soc_capabilities={
                # Communication
                "serial",
                "ethernet",
                # Storage
                "spiflash",
                # "sdcard",
                # GPIOs
                "leds",
                "rgb_led",
                "switches",
                # Buses
                "spi",
                "i2c",
                # Monitoring
                # "xadc",
                # 7-Series specific
                # "mmcm",
                # "icap_bitstream",
            },
            bitstream_ext=".bit"
        )


class ArtyA7(Arty):
    SPIFLASH_DUMMY_CYCLES = 7


# Main ---------------------------------------------------------------------------------------------

supported_boards = {
    # Xilinx
    "a7-35": ArtyA7,
    "a7-100": ArtyA7,
}


def main():
    description = "Linux on LiteX-VexRiscv\n\n"
    description += "Available boards:\n"
    for name in supported_boards.keys():
        description += "- " + name + "\n"
    parser = argparse.ArgumentParser(
        description=description, formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("--board", required=True, help="FPGA board")
    parser.add_argument("--device", default=None, help="FPGA device")
    parser.add_argument("--build", action="store_true", help="Build bitstream")
    parser.add_argument(
        "--load", action="store_true", help="Load bitstream (to SRAM)"
    )
    parser.add_argument(
        "--flash",
        action="store_true",
        help="Flash bitstream/images (to SPI Flash)"
    )
    parser.add_argument(
        "--doc", action="store_true", help="Build documentation"
    )
    parser.add_argument(
        "--local-ip", default="192.168.1.50", help="Local IP address"
    )
    parser.add_argument(
        "--remote-ip",
        default="192.168.1.100",
        help="Remote IP address of TFTP server"
    )
    parser.add_argument(
        "--spi-data-width",
        type=int,
        default=8,
        help="SPI data width (maximum transfered bits per xfer)"
    )
    parser.add_argument(
        "--spi-clk-freq", type=int, default=1e6, help="SPI clock frequency"
    )
    parser.add_argument(
        "--video", default="1920x1080_60Hz", help="Video configuration"
    )
    parser.add_argument("--builddir", default="build", help="Build directory")
    args = parser.parse_args()

    # Board(s) selection ---------------------------------------------------------------------------
    if args.board == "all":
        board_names = list(supported_boards.keys())
    else:
        args.board = args.board.lower()
        args.board = args.board.replace(" ", "_")
        board_names = [args.board]

    # Board(s) iteration ---------------------------------------------------------------------------
    for board_name in board_names:
        board = supported_boards[board_name]()

        # SoC parameters ---------------------------------------------------------------------------
        soc_kwargs = Board.soc_kwargs
        soc_kwargs.update(board.soc_kwargs)
        if args.device is not None:
            soc_kwargs.update(device=args.device)
        if "usb_fifo" in board.soc_capabilities:
            soc_kwargs.update(uart_name="usb_fifo")
        if "usb_acm" in board.soc_capabilities:
            soc_kwargs.update(uart_name="usb_acm")
        if "ethernet" in board.soc_capabilities:
            soc_kwargs.update(with_ethernet=True)

        # SoC creation -----------------------------------------------------------------------------
        soc = SoCLinux(board.soc_cls, **soc_kwargs)
        board.platform = soc.platform

        # SoC peripherals --------------------------------------------------------------------------
        if board_name in ["arty", "arty_a7"]:
            from litex_boards.platforms.arty import _sdcard_pmod_io
            board.platform.add_extension(_sdcard_pmod_io)

        if "mmcm" in board.soc_capabilities:
            soc.add_mmcm(2)
        if "spiflash" in board.soc_capabilities:
            soc.add_spi_flash(dummy_cycles=board.SPIFLASH_DUMMY_CYCLES)
            soc.add_constant("SPIFLASH_PAGE_SIZE", board.SPIFLASH_PAGE_SIZE)
            soc.add_constant(
                "SPIFLASH_SECTOR_SIZE", board.SPIFLASH_SECTOR_SIZE
            )
        if "spisdcard" in board.soc_capabilities:
            soc.add_spi_sdcard()
        if "sdcard" in board.soc_capabilities:
            soc.add_sdcard()
        if "ethernet" in board.soc_capabilities:
            soc.configure_ethernet(
                local_ip=args.local_ip, remote_ip=args.remote_ip
            )
        # if "leds" in board.soc_capabilities:
        # soc.add_leds()
        if "rgb_led" in board.soc_capabilities:
            soc.add_rgb_led()
        if "switches" in board.soc_capabilities:
            soc.add_switches()
        if "spi" in board.soc_capabilities:
            soc.add_spi(args.spi_data_width, args.spi_clk_freq)
        if "i2c" in board.soc_capabilities:
            soc.add_i2c()
        if "xadc" in board.soc_capabilities:
            soc.add_xadc()
        if "framebuffer" in board.soc_capabilities:
            assert args.video in video_resolutions.keys(
            ), "Unsupported video resolution"
            video_settings = video_resolutions[args.video]
            soc.add_framebuffer(video_settings)
        if "icap_bitstream" in board.soc_capabilities:
            soc.add_icap_bitstream()
        soc.configure_boot()

        # Build ------------------------------------------------------------------------------------
        build_dir = args.builddir
        builder = Builder(
            soc,
            output_dir=build_dir,
            csr_json=os.path.join(build_dir, "csr.json"),
            bios_options=["TERM_MINI"]
        )
        builder.build(build_name="top", run=args.build)

        # DTS --------------------------------------------------------------------------------------
        # soc.generate_dts(build_dir, board_name)
        # soc.compile_dts(build_dir, board_name)

        # Machine Mode Emulator --------------------------------------------------------------------
        # soc.compile_emulator(build_dir)

        # Load FPGA bitstream ----------------------------------------------------------------------
        if args.load:
            board.load(
                filename=os.path.join(
                    build_dir, board_name, "gateware", "top" +
                    board.bitstream_ext
                )
            )

        # Generate SoC documentation ---------------------------------------------------------------
        if args.doc:
            soc.generate_doc(board_name)


if __name__ == "__main__":
    main()
