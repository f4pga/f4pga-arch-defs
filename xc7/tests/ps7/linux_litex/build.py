import edalize
import os

work_root = 'build'

files = [
  {'name' : os.path.realpath('wb2axi.sv'), 'file_type' : 'systemVerilogSource'},
  {'name' : os.path.realpath('VexRiscv_LinuxNoDspFmax.v'), 'file_type' : 'verilogSource'},
  {'name' : os.path.realpath('top.v'), 'file_type' : 'verilogSource'},
  {'name' : os.path.realpath('AxiPeriph.v'), 'file_type' : 'verilogSource'},
  {'name' : os.path.realpath('top_ps7.v'), 'file_type' : 'verilogSource'},
  {'name' : os.path.realpath('zybo.xdc'), 'file_type' : 'xdc'},
  {'name' : os.path.realpath('mem.init'), 'file_type' : 'mem'},
  {'name' : os.path.realpath('mem_1.init'), 'file_type' : 'mem'},
]

tool = 'vivado'

edam = {
  'files' : files,
  'name'  : 'axi_regs',
  'toplevel': 'top',
  'tool_options' : {'vivado' : {'part' : 'xc7z010clg400-1'}}
  }

backend = edalize.get_edatool(tool)(edam=edam, work_root=work_root)

os.makedirs(work_root, exist_ok = True)
backend.configure("")
backend.build()

