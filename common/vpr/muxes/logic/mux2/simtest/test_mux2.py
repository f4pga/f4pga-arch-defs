"""
Test mux2 correctness
"""

import cocotb
from cocotb.regression import TestFactory
from cocotb.result import TestFailure
from cocotb.triggers import Timer


@cocotb.coroutine
def mux2_basic_test(dut, inputs=(1, 0, 0)):
    """Test for MUX2 options."""

    yield Timer(2)
    I0, I1, S0 = inputs
    dut.I0 = I0
    dut.I1 = I1
    dut.S0 = S0
    if S0:
        expected = I1
    else:
        expected = I0
    yield Timer(2)

    if dut.O != expected:  # noqa: E741
        raise TestFailure(
            'Result is incorrect for I0(%d) I1(%d) S0(%d): %s(O) != %s (expected)'
            % (I0, I1, S0, dut.O, expected)
        )
    else:
        dut._log.info(
            'I0(%d) I1(%d) S0(%d) output(%d) Ok!' % (I0, I1, S0, dut.O)
        )


factory = TestFactory(mux2_basic_test)
input_permutations = [
    (x, y, z) for x in [0, 1] for y in [0, 1] for z in [0, 1]
]
factory.add_option("inputs", input_permutations)
factory.generate_tests()
