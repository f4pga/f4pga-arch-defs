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
