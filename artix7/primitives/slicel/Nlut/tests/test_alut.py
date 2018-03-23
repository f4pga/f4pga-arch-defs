import cocotb
from cocotb.binary import BinaryValue
from cocotb.triggers import Timer
from cocotb.result import TestFailure
from cocotb.regression import TestFactory
from cocotb.generators.bit import random_50_percent

import random

class LutModel:
  def __init__(self, init, inputs):
    self.init = init
    self.inputs = BinaryValue(inputs)

  @property
  def O5(self):
    print 'asd %s'%self.init.binstr
    print 'asd %s'%self.inputs.integer
    return eval(self.init.binstr[-1-self.inputs.integer])

  @property
  def O6(self):
    return eval(self.init.binstr[-1-self.inputs.integer])

@cocotb.coroutine
def lut_basic_test(dut, inputs):
  """Test for LUT options"""

  yield Timer(1)

  for ii in range(6):
    setattr(dut, 'A%d'%(ii + 1), inputs & (1<<ii))
  yield Timer(1)
  model = LutModel(dut.INIT.value, inputs)

  if dut.O5 != model.O5 or dut.O6 != model.O6:
    raise TestFailure('No match (dut:model) O5(%d:%d) O6(%d:%d)'%(dut.O5, model.O5, dut.O6, model.O6))
  else:
    dut._log.info('Match')


factory = TestFactory(lut_basic_test)
input_permutations = range(2**6)
factory.add_option("inputs", input_permutations)
factory.generate_tests()
