#!/usr/bin/env python3

import os
import argparse

from litex_boards.targets.arty import _CRG as arty_CRG
from litex_boards.targets.nexys_video import _CRG as nexys_video_CRG
from liteeth.phy.mii import LiteEthPHYMII
from litex.soc.cores.led import LedChaser
from litex_boards.platforms import arty, nexys_video
from litex.soc.integration.soc_core import SoCCore
from litex.soc.integration.builder import Builder
from litex.soc.integration.soc_core import soc_core_args, soc_core_argdict
from litex.build.xilinx.vivado import vivado_build_args, vivado_build_argdict

from litedram.modules import MT41K128M16
from litedram.phy import s7ddrphy


class BaseSoC(SoCCore):
    def __init__(
            self,
            toolchain="vivado",
            sys_clk_freq=int(80e6),
            with_ethernet=False,
            with_ram=False,
            with_sata=False,
            board="a7-35",
            **kwargs
    ):

        if board in ["a7-35", "a7-100"]:
            platform = arty.Platform(variant=board, toolchain=toolchain)
            SoCCore.__init__(
                self,
                platform,
                sys_clk_freq,
                ident="LiteX SoC on Arty A7",
                ident_version=False,
                **kwargs
            )
            self.submodules.crg = arty_CRG(platform, sys_clk_freq)
        elif board == "nexys_video":
            platform = nexys_video.Platform(toolchain)
            SoCCore.__init__(
                self,
                platform,
                sys_clk_freq,
                ident="LiteX SoC on Nexys Video",
                ident_version=True,
                **kwargs
            )
            self.submodules.crg = nexys_video_CRG(
                platform, sys_clk_freq, toolchain
            )

        # DDR3 SDRAM -------------------------------------------------------------------------------
        if with_ram:
            self.submodules.ddrphy = s7ddrphy.A7DDRPHY(
                platform.request("ddram"),
                memtype="DDR3",
                nphases=4,
                sys_clk_freq=sys_clk_freq
            )
            self.add_csr("ddrphy")
            self.add_sdram(
                "sdram",
                phy=self.ddrphy,
                module=MT41K128M16(sys_clk_freq, "1:4"),
                origin=self.mem_map["main_ram"],
                size=kwargs.get("max_sdram_size", 0x40000000),
                l2_cache_size=kwargs.get("l2_size", 8192),
                l2_cache_min_data_width=kwargs.get("min_l2_data_width", 128),
                l2_cache_reverse=True
            )

        if with_ethernet:
            self.submodules.ethphy = LiteEthPHYMII(
                clock_pads=self.platform.request("eth_clocks"),
                pads=self.platform.request("eth")
            )
            self.add_csr("ethphy")
            self.add_ethernet(phy=self.ethphy)

        if with_sata and board == "nexys_video":
            from litex.build.generic_platform import Subsignal, Pins
            from litesata.phy import LiteSATAPHY

            # IOs
            _sata_io = [
                # AB09-FMCRAID / https://www.dgway.com/AB09-FMCRAID_E.html
                (
                    "fmc2sata", 0,
                    Subsignal("clk_p", Pins("LPC:GBTCLK0_M2C_P")),
                    Subsignal("clk_n", Pins("LPC:GBTCLK0_M2C_N")),
                    Subsignal("tx_p", Pins("LPC:DP0_C2M_P")),
                    Subsignal("tx_n", Pins("LPC:DP0_C2M_N")),
                    Subsignal("rx_p", Pins("LPC:DP0_M2C_P")),
                    Subsignal("rx_n", Pins("LPC:DP0_M2C_N"))
                ),
            ]
            platform.add_extension(_sata_io)

            # PHY
            self.submodules.sata_phy = LiteSATAPHY(
                platform.device,
                pads=platform.request("fmc2sata"),
                gen="gen2",
                clk_freq=sys_clk_freq,
                data_width=16
            )
            self.add_csr("sata_phy")

            # Core
            self.add_sata(phy=self.sata_phy, mode="read+write")

        self.submodules.leds = LedChaser(
            pads=platform.request_all("user_led"), sys_clk_freq=sys_clk_freq
        )
        self.add_csr("leds")


def main():
    parser = argparse.ArgumentParser(description="LiteX SoC on Arty A7")
    parser.add_argument("--load", action="store_true", help="Load bitstream")
    parser.add_argument("--build", action="store_true", help="Build bitstream")
    parser.add_argument("--build-name", default="top", help="Build name")
    parser.add_argument(
        "--toolchain",
        default="vivado",
        help="Gateware toolchain to use, vivado or symbiflow (default)"
    )
    parser.add_argument(
        "--with-ethernet", action="store_true", help="Enable Ethernet support"
    )
    parser.add_argument(
        "--with-ram", action="store_true", help="Enable Main RAM"
    )
    parser.add_argument(
        "--with-sata",
        action="store_true",
        help="Enable SATA support (over FMCRAID)"
    )
    parser.add_argument(
        "--board", default="a7-35", help="Specifies LiteX Board"
    )
    parser.add_argument("--builddir", help="Build directory")

    soc_core_args(parser)
    vivado_build_args(parser)
    args = parser.parse_args()

    if args.board not in ["a7-35", "a7-100", "nexys_video"]:
        raise ValueError("Unsupported board!")

    soc = BaseSoC(
        toolchain=args.toolchain,
        sys_clk_freq=int(80e6),
        with_ethernet=args.with_ethernet,
        with_ram=args.with_ram,
        with_sata=args.with_sata,
        board=args.board,
        **soc_core_argdict(args)
    )

    builder = Builder(soc, output_dir=args.builddir)
    builder_kwargs = vivado_build_argdict(
        args
    ) if args.toolchain == "vivado" else {}
    builder.build(**builder_kwargs, run=args.build, build_name=args.build_name)

    if args.load:
        prog = soc.platform.create_programmer()
        prog.load_bitstream(
            os.path.join(builder.gateware_dir, soc.build_name + ".bit")
        )


if __name__ == "__main__":
    main()
