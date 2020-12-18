#!/usr/bin/env python3

import os
import argparse

from migen import *

import arty

from litex.soc.cores.clock import *
from litex.soc.cores.prm import *
from litex.soc.integration.soc import SoCRegion
from litex.soc.integration.soc_core import *
from litex.soc.integration.soc_sdram import *
from litex.soc.integration.builder import *
from litex.soc.cores.led import LedChaser
from litex.soc.cores.icap import *

from litedram.modules import MT41K128M16
from litedram.phy import s7ddrphy

from liteeth.phy.mii import LiteEthPHYMII

# CRG ----------------------------------------------------------------------------------------------

class _CRG(Module):
    def __init__(self, platform, sys_clk_freq):
        self.rst = Signal()
        self.clock_domains.cd_sys       = ClockDomain()
        self.clock_domains.cd_sys4x     = ClockDomain(reset_less=True)
        self.clock_domains.cd_sys4x_dqs = ClockDomain(reset_less=True)
        self.clock_domains.cd_idelay    = ClockDomain()
        self.clock_domains.cd_eth       = ClockDomain()
        #self.clock_domains.cd_prm       = ClockDomain()

        # # #

        self.submodules.pll = pll = S7PLL(speedgrade=-1)
        self.comb += pll.reset.eq(~platform.request("cpu_reset") | self.rst)
        pll.register_clkin(platform.request("clk100"), 100e6)
        pll.create_clkout(self.cd_sys,       sys_clk_freq)
        pll.create_clkout(self.cd_sys4x,     4*sys_clk_freq)
        pll.create_clkout(self.cd_sys4x_dqs, 4*sys_clk_freq, phase=90)
        pll.create_clkout(self.cd_idelay,    200e6)
        pll.create_clkout(self.cd_eth,       25e6)
        #pll.create_clkout(self.cd_prm, sys_clk_freq, prm=True, prm_clk=platform.request("prm_clk"))
        #self.specials += Instance("SYN_OBUF", i_I=self.rst, o_O=platform.request("prm_rst"))

        self.submodules.idelayctrl = S7IDELAYCTRL(self.cd_idelay)

        self.comb += platform.request("eth_ref_clk").eq(self.cd_eth.clk)

# BaseSoC ------------------------------------------------------------------------------------------

class BaseSoC(SoCCore):
    def __init__(self, prm_csr_base=0x83000000, toolchain="symbiflow", sys_clk_freq=int(100e6), with_ethernet=False, **kwargs):
        platform = arty.Platform(toolchain=toolchain)

        # SoCCore ----------------------------------------------------------------------------------
        SoCCore.__init__(self, platform, sys_clk_freq,
            ident          = "LiteX SoC on Arty A7",
            **kwargs)

        # CRG --------------------------------------------------------------------------------------
        self.submodules.crg = _CRG(platform, sys_clk_freq)

        # DDR3 SDRAM -------------------------------------------------------------------------------
        if not self.integrated_main_ram_size:
            self.submodules.ddrphy = s7ddrphy.A7DDRPHY(platform.request("ddram"),
                memtype        = "DDR3",
                nphases        = 4,
                sys_clk_freq   = sys_clk_freq)
            self.add_csr("ddrphy")
            self.add_sdram("sdram",
                phy                     = self.ddrphy,
                module                  = MT41K128M16(sys_clk_freq, "1:4"),
                origin                  = self.mem_map["main_ram"],
                size                    = kwargs.get("max_sdram_size", 0x40000000),
                l2_cache_size           = kwargs.get("l2_size", 8192),
                l2_cache_min_data_width = kwargs.get("min_l2_data_width", 128),
                l2_cache_reverse        = True
            )

        # Ethernet / Etherbone ---------------------------------------------------------------------
        if with_ethernet:
            self.submodules.ethphy = LiteEthPHYMII(
                clock_pads = self.platform.request("eth_clocks"),
                pads       = self.platform.request("eth"))
            self.add_csr("ethphy")
            if with_ethernet:
                self.add_ethernet(phy=self.ethphy)

        # PRM -------------------------------------------------------------------------------------
        bus = wishbone.Interface()
        prm_region = SoCRegion(origin=self.mem_map.get("prm", prm_csr_base), size=0x800, cached=False)
        self.bus.add_slave(name="prm", slave=bus, region=prm_region)
        roi_outs = [PRMConnector("leds", platform.request_all("user_led"))]
        self.submodules.prm = PRM(
            platform    = platform,
            bus         = bus,
            bus_type    = "wishbone",
            mode        = "overlay",
            roi_outs    = roi_outs)

        # TODO: add ICAP as soon as ICAP model will be available in SymbiFlow
        #self.submodules.icap = ICAPBitstream()
        #self.add_csr("icap")

# Build --------------------------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="LiteX SoC on Arty A7")
    parser.add_argument("--toolchain",        default="symbiflow", help="Toolchain use to build (default: symbiflow)")
    parser.add_argument("--build",            action="store_true", help="Build bitstream")
    parser.add_argument("--load",             action="store_true", help="Load bitstream")
    parser.add_argument("--sys-clk-freq",     default=100e6,       help="System clock frequency (default: 100MHz)")
    parser.add_argument("--with-ethernet",    action="store_true", help="Enable Ethernet support")
    parser.add_argument("--output_dir",       default="arty_soc",  help="Build directory name")
    parser.add_argument("--prm-csr-base",     default=0x83000000,  type=lambda x: int(x,0), help="CSR base address reserved for PRM core")
    builder_args(parser)
    soc_sdram_args(parser)
    args = parser.parse_args()

    assert not (args.with_ethernet)
    soc = BaseSoC(
        prm_csr_base   = args.prm_csr_base,
        toolchain      = args.toolchain,
        sys_clk_freq   = int(float(args.sys_clk_freq)),
        with_ethernet  = args.with_ethernet,
        **soc_sdram_argdict(args)
    )
    builder = Builder(soc, **builder_argdict(args))
    builder_kwargs = {}
    builder.build(**builder_kwargs, run=args.build)

    if args.load:
        prog = soc.platform.create_programmer()
        prog.load_bitstream(os.path.join(builder.gateware_dir, soc.build_name + ".bit"))

if __name__ == "__main__":
    main()
