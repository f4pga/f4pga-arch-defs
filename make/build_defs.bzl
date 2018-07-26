def n_template(name, prefixes, srcs):
  for prefix in prefixes:
    for src in srcs:
      output_file = src.replace('ntemplate.', '').replace('N', prefix)
      native.genrule(
          name = prefix + name,
          srcs = [src],
          outs = [output_file],
          cmd = "$(location //utils:n) " + prefix + " $< $@",
          tools = ["//utils:n"],
          )

def mux_gen(name, mux_name, type, width, split_inputs=None,
            inputs=None, split_selects=None, selects=None, subckt=None,
            comment=None, output=None, data_width=None, ntemplate_prefixes=None):
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
      srcs = [],
      outs = outputs,
      cmd = ('$(location //utils:mux_gen) ' + mux_gen_args),
      tools = [
          "//utils:mux_gen",
          ],
      )

  if name.startswith('ntemplate.') and ntemplate_prefixes != None:
    for output in outputs:
      n_template(
          name = output.replace('ntemplate.', ''),
          prefixes = ntemplate_prefixes,
          srcs = [output],
          )
