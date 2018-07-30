import os
import os.path
import glob

def read_ntemplate_file(root):
  with open(os.path.join(root, 'Makefile.N')) as f:
    for l in f:
      if l.startswith('NTEMPLATE_VALUES='):
        return l.split('=')[1].split(' ')

def convert_mux_into_cmake(root, ntemplate):
  args = {}
  with open(os.path.join(root, 'Makefile.mux')) as f:
    for l in f:
      if l.startswith('MUX_'):
        key, value = l.split(' = ')
        key = key[4:]

        if key == 'OUTFILE':
          key = 'NAME'

        args[key] = value.strip()

  if ntemplate:
    args['NTEMPLATE_PREFIXES'] = '%s' % ';'.join(ntemplate)

  return """\
MUX_GEN(
  NAME %s
%s
  )""" % (
      args['NAME'],
      '\n'.join('  %s %s' % (k, args[k]) for k in sorted(args.keys()) if k != 'NAME'),
  )

def create_ntemplate_into_cmake(root, ntemplate, apply_v2x):
  template = ''

  for path in glob.glob(os.path.join(root, 'ntemplate.*')):
    filename = os.path.basename(path)
    name = '.'.join(filename.split('.')[1:])
    prefixes = ';'.join(ntemplate)

    template += """\
MAKE_FILE_TARGET(
  FILE %s
  )

N_TEMPLATE(
  NAME %s
  PREFIXES %s
  SRCS %s
  %s
  )

""" % (
    filename,
    name,
    prefixes,
    filename,
    'APPLY_V2X\n' if apply_v2x else ''
  )

  return template

def create_v2x_template(root):
  template = ''

  for path in glob.glob(os.path.join(root, '*.sim.v')):
    filename = os.path.basename(path)
    name = filename.split('.')[0]

    template += """\
MAKE_FILE_TARGET(
  FILE %s
  )

V2X(
  NAME %s
  SRCS %s
  )

""" % (
    filename,
    name,
    filename
  )

def add_subdirectory_commands(cmake_directories, subdirectory_list):
  for subdir in cmake_directories:
    while subdir != '.':
      up_one = os.path.dirname(subdir)
      subdirectory_list[up_one].add(subdir)
      subdir = up_one

  for subdir in cmake_directories:
    if subdirectory_list[subdir]:
      cmake_directories[subdir] = cmake_directories[subdir] + '\n' + '\n'.join('add_subdirectory(%s)' % d for d in subdirectory_list[subdirectory_list])

def write_new_cmakelists(cmake_directories):
  for subdir in cmake_directories:
    with open(os.path.join(subdir, 'CMakeLists.txt'), 'w') as f:
      f.write(cmake_directories[subdir])

def create_cmake_files():
  with open('CMakeLists.txt') as f:
    root_lines = f.readlines()

  root_lines = [l for l in root_lines if l.find('add_subdirectory') == -1]

  cmake_directories = {}
  subdirectory_list = {}

  cmake_directories['.'] = '\n'.join(root_lines)

  for root, _, files in os.walk('.'):
    ntemplate = None
    apply_v2x = False
    mux_gen = False
    template = None

    if 'Makefile.N' in files:
      ntemplate = read_ntemplate_file

    if 'Makefile.mux' in files:
      template = convert_mux_into_cmake(root, ntemplate)
      mux_gen = True
      ntemplate = None

    if 'Makefile.v2x' in files:
      assert not mux_gen
      apply_v2x = True

    if ntemplate:
      template = create_ntemplate_into_cmake(root, ntemplate, apply_v2x)
      apply_v2x = False

    if apply_v2x:
      template = create_v2x_template(root)

    if template:
      cmake_directories[root] = template
      subdirectory_list[root] = set()

  add_subdirectory_commands(cmake_directories, subdirectory_list)
  write_new_cmakelists(cmake_directories)

if __name__ == '__main__':
  create_cmake_files()
