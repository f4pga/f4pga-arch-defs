#!/usr/bin/env python3

#
# This file is part of LiteX.
#
# Copyright (c) 2020 Antmicro <www.antmicro.com>
# Copyright (c) 2020 Florent Kermarrec <florent@enjoy-digital.fr>
# SPDX-License-Identifier: BSD-2-Clause

import argparse

from migen import *

from litex.build.generic_platform import *
from litex.build.xilinx.vivado import _xdc_separator, _format_xdc, _build_xdc
from litex.build.xilinx.ise import _format_ucf, _build_ucf

from litex.soc.integration.soc_core import *
from litex.soc.integration.builder import *
from litex.soc.interconnect import wishbone
from litex.soc.interconnect import axi

from litex.soc.cores.pwm import PWM
from litex.soc.cores.gpio import GPIOTristate
from litex.soc.cores.spi import SPIMaster, SPISlave
from litex.soc.cores.clock import S7MMCM
from litex.soc.cores.led import *
from litex.soc.cores.prm import *

# Platform -----------------------------------------------------------------------------------------

_io = [
    ("sys_clk", 0, Pins(1)),
    ("sys_rst", 0, Pins(1)),
]

# Platform -----------------------------------------------------------------------------------------

class Platform(GenericPlatform):
    def __init__(self, io, top, constr=None):
        GenericPlatform.__init__(self, "", io)
        self.top = top
        self.constr = constr

    def build(self, fragment, build_dir, **kwargs):
        os.makedirs(build_dir, exist_ok=True)
        os.chdir(build_dir)
        top_output = self.get_verilog(fragment, name=self.top)
        named_sc, named_pc = self.resolve_signals(top_output.ns)
        top_file = self.top + ".v"
        top_output.write(top_file)

        if self.constr is not None:
            if self.constr == "ucf":
                tools.write_to_file(self.top + ".ucf", _build_ucf(named_sc, named_pc))
            elif self.constr == "xdc":
                tools.write_to_file(self.top + ".xdc", _build_xdc(named_sc, named_pc))
            else:
                raise OSError("Unsupported constraints type")

# LiteXCore ----------------------------------------------------------------------------------------

class LiteXCore(SoCMini):
    def __init__(self, sys_clk_freq=int(100e6),
        with_pwm        = False,
        with_mmcm       = False,
        with_gpio       = False, gpio_width=32,
        with_led_chaser = False, leds_width=4,
        with_spi_master = False, spi_master_data_width=8, spi_master_clk_freq=8e6,
        prm             = False,
        **kwargs):

        platform = Platform(_io, top=kwargs["top"], constr=kwargs["constr"])

        # UART
        if kwargs["with_uart"]:
            platform.add_extension([
                ("serial", 0,
                    Subsignal("tx",  Pins(1)),
                    Subsignal("rx", Pins(1)),
                )
            ])

        # CRG --------------------------------------------------------------------------------------
        if not prm:
            self.submodules.crg = CRG(platform.request("sys_clk"), rst=platform.request("sys_rst"))

        # SoCMini ----------------------------------------------------------------------------------
        SoCMini.__init__(self, platform, clk_freq=sys_clk_freq, **kwargs)
        SoCMini.mem_map["csr"] = kwargs["csr_base"]

        bus = None
        # Wishbone Master
        if kwargs["bus"] == "wishbone":
            bus = wishbone.Interface()
            self.bus.add_master(master=bus)
            if not prm:
                platform.add_extension(bus.get_ios("wb"))
                bus_pads = platform.request("wb")
                self.comb += bus.connect_to_pads(bus_pads, mode="slave")

        # AXI-Lite Master
        if kwargs["bus"] == "axi":
            bus = axi.AXILiteInterface(data_width=32, address_width=32)
            wb_bus = wishbone.Interface()
            axi2wb = axi.AXILite2Wishbone(bus, wb_bus)
            self.submodules += axi2wb
            self.bus.add_master(master=wb_bus)
            if not prm:
                platform.add_extension(bus.get_ios("axi"))
                bus_pads = platform.request("axi")
                self.comb += bus.connect_to_pads(bus_pads, mode="slave")

        # PRM
        if prm:
            assert bus is not None
            roi_outs = []
            roi_ins = []
            if with_led_chaser:
                roi_outs += [PRMConnector("leds", Signal(leds_width))]
            self.submodules.prm = PRM(
                platform = platform,
                bus      = bus,
                bus_type = kwargs["bus"],
                mode     = "roi",
                roi_ins  = roi_ins,
                roi_outs = roi_outs)
            self.submodules.crg = CRG(self.prm.get_clk_pad(), rst=self.prm.get_rst_pad())

        # MMCM
        if with_mmcm:
            platform.add_extension([
                ("clkgen", 0,
                    Subsignal("ref", Pins(1)),
                    Subsignal("out0", Pins(1)),
                    Subsignal("out1", Pins(1)),
                    Subsignal("locked", Pins(1)),
                )
            ])

            self.clock_domains.cd_out0 = ClockDomain(reset_less=True)
            self.clock_domains.cd_out1 = ClockDomain(reset_less=True)
            self.submodules.mmcm = mmcm = S7MMCM()
            mmcm.expose_drp()
            self.add_csr("mmcm")

            clkgen = platform.request("clkgen")

            mmcm.register_clkin(clkgen.ref, 100e6)
            mmcm.create_clkout(self.cd_out0, 148.5e6, with_reset=False)
            mmcm.create_clkout(self.cd_out1, 742.5e6, with_reset=False)

            self.comb += [
                clkgen.out0.eq(self.cd_out0.clk),
                clkgen.out1.eq(self.cd_out1.clk),
                clkgen.locked.eq(mmcm.locked),
            ]

        # SPI Master
        if with_spi_master:
            platform.add_extension([
                ("spi_master", 0,
                    Subsignal("clk",  Pins(1)),
                    Subsignal("cs_n", Pins(1)),
                    Subsignal("mosi", Pins(1)),
                    Subsignal("miso", Pins(1)),
                )
            ])
            self.submodules.spi_master = SPIMaster(
                pads         = platform.request("spi_master"),
                data_width   = spi_master_data_width,
                sys_clk_freq = sys_clk_freq,
                spi_clk_freq = spi_master_clk_freq,
            )
            self.add_csr("spi_master")

        # PWM
        if with_pwm:
            platform.add_extension([("pwm", 0, Pins(1))])
            self.submodules.pwm = PWM(platform.request("pwm"))
            self.add_csr("pwm")

        # GPIO
        if with_gpio:
            platform.add_extension([("gpio", 0, Pins(gpio_width))])
            self.submodules.gpio = GPIOTristate(platform.request("gpio"))
            self.add_csr("gpio")

        # LedChaser
        if with_led_chaser:
            if not prm:
                platform.add_extension([("leds", 0, Pins(leds_width))])
                self.submodules.leds = LedChaser(
                    pads = platform.request("leds"),
                    sys_clk_freq = sys_clk_freq)
            else:
                for roi_o in self.prm.roi_outs:
                    if roi_o.name == "leds":
                        led_pads = roi_o
                        break
                self.submodules.leds = LedChaser(
                    pads = led_pads.get_core_io_all(),
                    sys_clk_freq = sys_clk_freq)
            self.add_csr("leds")

        # IRQs
        for name, loc in sorted(self.irq.locs.items()):
            module = getattr(self, name)
            platform.add_extension([("irq_"+name, 0, Pins(1))])
            irq_pin = platform.request("irq_"+name)
            self.comb += irq_pin.eq(module.ev.irq)

# Build -------------------------------------------------------------------------------------------

def soc_argdict(args):
    ret = {}
    for arg in [
        "sys_clk_freq",
        "bus",
        "top",
        "constr",
        "with_pwm",
        "with_mmcm",
        "with_uart",
        "uart_fifo_depth",
        "with_ctrl",
        "with_timer",
        "with_gpio",
        "gpio_width",
        "with_led_chaser",
        "leds_width",
        "with_spi_master",
        "spi_master_data_width",
        "spi_master_clk_freq",
        "csr_base",
        "csr_data_width",
        "csr_address_width",
        "csr_paging",
        "prm"]:
        ret[arg] = getattr(args, arg)
    return ret

def main():
    parser = argparse.ArgumentParser(description="LiteX standalone core generator")

    # Clock frequency
    parser.add_argument("--sys-clk-freq",          type=int, default=int(100e6), help="System clock frequency (default: 100MHz)")

    # Bus
    parser.add_argument("--bus",                   default="wishbone",    type=str, help="Type of Bus (wishbone, axi)")

    # Top name
    parser.add_argument("--top",                   default="litex_core",  type=str, help="Name of top module")

    # Output directory
    parser.add_argument("--output_dir",            default="build",       type=str, help="Output directory")

    # Cores
    parser.add_argument("--with-pwm",              action="store_true",   help="Add PWM core")
    parser.add_argument("--with-mmcm",             action="store_true",   help="Add MMCM (Xilinx 7-series) core")
    parser.add_argument("--with-uart",             action="store_true",   help="Add UART core")
    parser.add_argument("--uart-fifo-depth",       default=16, type=int,  help="UART FIFO depth (default=16)")
    parser.add_argument("--with-ctrl",             action="store_true",   help="Add bus controller core")
    parser.add_argument("--with-timer",            action="store_true",   help="Add timer core")
    parser.add_argument("--with-spi-master",       action="store_true",   help="Add SPI master core")
    parser.add_argument("--spi-master-data-width", default=8,   type=int, help="SPI master data width")
    parser.add_argument("--spi-master-clk-freq",   default=8e6, type=int, help="SPI master output clock frequency")
    parser.add_argument("--with-gpio",             action="store_true",   help="Add GPIO core")
    parser.add_argument("--gpio-width",            default=32,  type=int, help="GPIO signals width")
    parser.add_argument("--with-led-chaser",       action="store_true",   help="Add LedChaser core")
    parser.add_argument("--leds-width",            default=4,   type=int, help="LedChaser signals width")
    parser.add_argument("--prm",                   action="store_true",   help="Mark generated core as PRM")

    # CSR settings
    parser.add_argument("--csr-base",          default=0x0,   type=lambda x: int(x,0), help="CSR base address for generated core")
    parser.add_argument("--csr-data-width",    default=8,     type=int,                help="CSR bus data-width (8 or 32, default=8)")
    parser.add_argument("--csr-address-width", default=14,    type=int,                help="CSR bus address-width")
    parser.add_argument("--csr-paging",        default=0x800, type=lambda x: int(x,0), help="CSR bus paging")

    # Constraints type
    parser.add_argument("--constr", default="xdc", type=str, help="Generate constraints of given type")

    builder_args(parser)
    args = parser.parse_args()

    soc     = LiteXCore(**soc_argdict(args))
    builder = Builder(soc, **builder_argdict(args))
    builder_kwargs = {}
    builder.build(**builder_kwargs)


if __name__ == "__main__":
    main()
