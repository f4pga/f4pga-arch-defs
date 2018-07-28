def n_template(name, prefixes, srcs, apply_v2x=False, **kwargs):
  for prefix in prefixes:
    for src in srcs:
      output_file = src.replace('ntemplate.', '').replace('N', prefix)
      native.genrule(
          name = prefix + name,
          srcs = [src],
          outs = [output_file],
          cmd = "$(location //utils:n) " + prefix + " $< $@",
          tools = ["//utils:n"],
          **kwargs
          )

      if apply_v2x:
        v2x(prefix + name, [output_file], **kwargs)

def mux_gen(name, mux_name, type, width, split_inputs=None,
            inputs=None, split_selects=None, selects=None, subckt=None,
            comment=None, output=None, data_width=None, ntemplate_prefixes=None,
            **kwargs):
  if type == 'routing':
    if subckt != None:
      fail('Can not use subckt=' + subckt + ' with routing mux.')
  elif type == 'logic':
    pass
  else:
    fail('mux_gen type must be "routing" or "logic".')

  if inputs != None:
    if split_inputs == None:
      split_inputs = True

    if not split_inputs:
      fail('inputs=' + inputs + ' specified but split_inputs=' + split_inputs + ' is not True.')

  if split_inputs == None:
    split_inputs = False

  if selects != None:
    if split_selects == None:
      split_selects = True

    if not split_selects:
      fail('selects=' + selects + ' specified but split_selects=' + split_selects + ' is not True.')

  if split_selects == None:
    split_selects = False

  mux_gen_args = (
      ' --outdir $(@D) --outfilename ' + name + ' --type ' + type +
      ' --width ' + str(width) + ' --name-mux ' + mux_name
      )

  if comment != None:
    mux_gen_args += ' --comment ' + comment

  if output != None:
    mux_gen_args += ' --name-out ' + output

  if split_inputs:
    mux_gen_args += ' --split-inputs 1'

  if inputs:
    mux_gen_args += ' --name-inputs ' + ','.join(inputs)

  if split_selects:
    mux_gen_args += ' --split-selects 1'

  if selects:
    mux_gen_args += ' --name-selects ' + ','.join(selects)

  if subckt:
    mux_gen_args += ' --subckt ' + subckt

  if data_width:
    mux_gen_args += ' --data-width ' + data_width

  outputs = [name + '.sim.v', name + '.pb_type.xml', name + '.model.xml']
  native.genrule(
      name = name,
      srcs = ['//vpr/muxes/logic/mux%d:mux%d.sim.v' % (width, width)],
      outs = outputs,
      cmd = ('$(location //utils:mux_gen) ' + mux_gen_args),
      tools = [
          "//utils:mux_gen",
          ],
      **kwargs
      )

  if name.startswith('ntemplate.') and ntemplate_prefixes != None:
    for output in outputs:
      n_template(
          name = output.replace('ntemplate.', ''),
          prefixes = ntemplate_prefixes,
          srcs = [output],
          **kwargs
          )

def v2x(name, srcs, top_module=None, **kwargs):
  for src in srcs:
    if not src.endswith('.sim.v'):
      fail('File ' + src + ' does not end with .sim.v')

  top_arg = ''
  if top_module != None:
    top_arg = '--top ' + top_module

  includes = [
    '$(GENDIR)/$$(dirname $(location ' + srcs[0] + '))',
    '$$(dirname $(location ' + srcs[0] + '))',
    '.',
    ]
  include_arg = '--includes ' + ','.join(includes)

  native.genrule(
      name = name + '_pb_type',
      srcs = srcs,
      outs = [name + '.pb_type.xml'],
      cmd = '$(location //utils/vlog:vlog_to_pbtype) ' + top_arg + ' -o $@ $(location ' + srcs[0] + ') ' + include_arg,
      tools = ['//utils/vlog:vlog_to_pbtype'],
      **kwargs
      )

  native.genrule(
      name = name + '_model',
      srcs = srcs,
      outs = [name + '.model.xml'],
      cmd = '$(location //utils/vlog:vlog_to_model) ' + top_arg + ' -o $@ $(location ' + srcs[0] + ') ' + include_arg,
      tools = ['//utils/vlog:vlog_to_model'],
      **kwargs
      )
