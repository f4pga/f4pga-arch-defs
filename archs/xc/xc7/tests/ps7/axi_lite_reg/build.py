import edalize
import os

work_root = 'build'

files = [
    {
        'name': os.path.realpath('AxiPeriph.v'),
        'file_type': 'verilogSource'
    },
    {
        'name': os.path.realpath('axi_reg.v'),
        'file_type': 'verilogSource'
    },
    {
        'name': os.path.realpath('zybo.xdc'),
        'file_type': 'xdc'
    },
]

tool = 'vivado'

edam = {
    'files': files,
    'name': 'axi_regs',
    'toplevel': 'top',
    'tool_options': {
        'vivado': {
            'part': 'xc7z010clg400-1'
        }
    }
}

backend = edalize.get_edatool(tool)(edam=edam, work_root=work_root)

os.makedirs(work_root, exist_ok=True)
backend.configure("")
backend.build()
