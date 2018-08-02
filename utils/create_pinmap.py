import json
import csv
import argparse

def get_module_ports(j, module):
  if module not in j['modules']:
    raise LookupError('module %s not in module list %s' % (module, ', '.join(j['modules'].keys())))

  for port in j['modules'][module]['ports']:
    bits = j['modules'][module]['ports'][port]['bits']
    if len(bits) > 1:
      for idx, _ in enumerate(bits):
        yield '%s[%d]' % (port, idx)
    else:
      yield port


def main():
  parser = argparse.ArgumentParser(description='Creates a pinmap file for a module for a given package.')

  parser.add_argument('--design_json', help='Yosys JSON design input.')
  parser.add_argument('--pinmap_csv', help='CSV pinmap definition.')
  parser.add_argument('--module', help='Name of module to generate pindef for.')

  args = parser.parse_args()
  pins = []
  with open(args.pinmap_csv) as f:
    for row in csv.DictReader(f):
      pins.append(row['name'])

  pinidx = 0

  with open(args.design_json) as f:
    j = json.load(f)
    for port in get_module_ports(j, args.module):
      print('set_io %s %s' % (port, pins[pinidx]))
      pinidx += 1

if __name__ == '__main__':
  main()
