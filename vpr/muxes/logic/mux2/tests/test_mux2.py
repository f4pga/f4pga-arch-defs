# Simple tests for an adder module
import cocotb
from cocotb.triggers import Timer
from cocotb.result import TestFailure
#from adder_model import adder_model
#import random


@cocotb.test()
def mux2_test(dut):
    """Test for MUX2 options"""
    opts = [(x,y,z, x&~z | y&z) for x in [0,1] for y in [0,1] for z in [0,1]]

    yield Timer(2)
    for I0, I1, S0, _ in opts:
      dut.I0 = I0
      dut.I1 = I1
      dut.S0 = S0
      if S0:
        expected = I1
      else:
        expected = I0
      yield Timer(2)

      if dut.O != expected:
        raise TestFailure(
            'Result is incorrect for I0(%d) I1(%d) S0(%d): %s(O) != %s (expected)' % (I0, I1, S0, dut.O, expected))
      else:
        dut._log.info('I0(%d) I1(%d) S0(%d) output(%d) Ok!'%(I0, I1, S0, dut.O))
