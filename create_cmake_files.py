import os
import os.path
import glob

def quote_if_space(s):
  if s.find(' ') != -1:
    return '"' + s + '"'
  else:
    return s

def create_file_template(filename):
  return """\
MAKE_FILE_TARGET(
  FILE %s%s
  )
""" % (filename, get_scanner(filename))

def read_ntemplate_file(root):
  with open(os.path.join(root, 'Makefile.N')) as f:
    for l in f:
      if l.startswith('NTEMPLATE_VALUES='):
        return l.split('=')[1].strip().split(' ')

def get_scanner(filename):
  _, ext = os.path.splitext(filename)
  if ext == '.v':
    return '\n  SCANNER_TYPE verilog'
  else:
    return ''

def convert_mux_into_cmake(root, ntemplate):
  args = {}
  with open(os.path.join(root, 'Makefile.mux')) as f:
    for l in f:
      if l.startswith('MUX_'):
        key, value = l.split(' = ')
        key = key[4:]

        if key == 'NAME':
          key = 'MUX_NAME'

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
      '\n'.join('  %s %s' % (k, quote_if_space(args[k])) for k in sorted(args.keys()) if k != 'NAME'),
  )

def create_ntemplate_into_cmake(root, ntemplate, apply_v2x, filelist):
  template = ''

  for path in glob.glob(os.path.join(root, 'ntemplate.*')):
    filename = os.path.basename(path)
    name = '.'.join(filename.split('.')[1:])
    prefixes = ';'.join(ntemplate)

    filelist.add(filename)

    template += """\
N_TEMPLATE(
  NAME %s
  PREFIXES %s
  SRCS %s
  %s
  )

""" % (
    name,
    prefixes,
    filename,
    'APPLY_V2X\n' if apply_v2x else ''
  )

  return template

def create_v2x_template(root, filelist):
  template = ''

  for path in glob.glob(os.path.join(root, '*.sim.v')):
    filename = os.path.basename(path)
    name = filename.split('.')[0]

    filelist.add(filename)
    template += """\
V2X(
  NAME %s
  SRCS %s
  )

""" % (
    name,
    filename
  )

  return template

def add_subdirectory_commands(cmake_directories):
  new_subdirs = set()
  subdirectory_list = {}

  for subdir in cmake_directories:
    subdirectory_list[subdir] = set()

  for subdir in cmake_directories:
    while subdir != '.':
      up_one = os.path.dirname(subdir)

      if up_one not in subdirectory_list:
        subdirectory_list[up_one] = set()
        new_subdirs.add(up_one)

      subdirectory_list[up_one].add(os.path.basename(subdir))
      subdir = up_one

  for subdir in new_subdirs:
    if subdir not in cmake_directories:
      cmake_directories[subdir] = ''

  for subdir in cmake_directories:
    if subdirectory_list[subdir]:
      commands = '\n'.join('add_subdirectory(%s)' % d for d in sorted(subdirectory_list[subdir]))
      if subdir == '.':
        cmake_directories[subdir] = cmake_directories[subdir] + '\n' + commands
      else:
        cmake_directories[subdir] = commands + '\n' + cmake_directories[subdir]

def write_new_cmakelists(cmake_directories):
  for subdir in cmake_directories:
    with open(os.path.join(subdir, 'CMakeLists.txt'), 'w') as f:
      f.write(cmake_directories[subdir])

def create_cmake_files():
  with open('CMakeLists.txt') as f:
    root_lines = f.readlines()

  root_lines = [l.rstrip() for l in root_lines if l.find('add_subdirectory') == -1]

  cmake_directories = {}

  cmake_directories['.'] = '\n'.join(root_lines)

  for root, _, files in os.walk('.'):
    ntemplate = None
    apply_v2x = False
    mux_gen = False
    template = None
    filelist = set()

    if 'Makefile.N' in files:
      ntemplate = read_ntemplate_file(root)

    if 'Makefile.mux' in files:
      template = convert_mux_into_cmake(root, ntemplate)
      mux_gen = True
      ntemplate = None

    if 'Makefile.v2x' in files:
      assert not mux_gen
      apply_v2x = True

    if ntemplate:
      template = create_ntemplate_into_cmake(root, ntemplate, apply_v2x, filelist)
      apply_v2x = False

    if apply_v2x:
      template = create_v2x_template(root, filelist)

    for f in files:
      if f.endswith('.sim.v'):
        filelist.add(f)

    if filelist and not template:
      template = ''

    if template:
      template = '\n'.join(create_file_template(f) for f in filelist) + template

    if template:
      cmake_directories[root] = template

  add_subdirectory_commands(cmake_directories)
  write_new_cmakelists(cmake_directories)

if __name__ == '__main__':
  create_cmake_files()
