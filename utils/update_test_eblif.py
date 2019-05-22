#!/usr/bin/env python3

import sys


def remove_brackets(port):
    return (port.replace("[", "")).replace("]", "")


def process_line(line, inputs, outputs):

    if not line.startswith(".subckt"):
        return line

    newline = list()
    line_to_process = line.split()[2:]
    newline.append(" ".join(line.split()[:2]))
    for port in line_to_process:
        port = port.split("=")
        if port[1] in inputs or port[1] in outputs:
            port[1] = remove_brackets(port[1])
        newline.append("=".join(port))

    return " ".join(newline)


def main(argv):

    if len(argv) != 3:
        print("Usage: {} <inputfile> <outputfile>".format(argv[0]))
        return 1

    infile = argv[1]
    outfile = argv[2]

    inputs = list()
    outputs = list()
    body = list()
    with open(infile, "r") as fp:
        for line in fp:
            if line.startswith(".inputs"):
                inputs = line.split()[1:]
                continue
            if line.startswith(".outputs"):
                outputs = line.split()[1:]
                continue
            if line.startswith(".model"):
                model = line.split()[1]
                continue

            if line.startswith(".names") or (not line.startswith(".")):
                continue

            body.append(process_line(line, inputs, outputs))

    newinputs = list()
    newoutputs = list()

    for port in inputs:
        newinputs.append(remove_brackets(port))
    for port in outputs:
        newoutputs.append(remove_brackets(port))

    with open(outfile, "w") as fp:
        fp.write(".model {}\n".format(model))
        fp.write(".inputs {}\n".format(" ".join(newinputs)))
        fp.write(".outputs {}\n".format(" ".join(newoutputs)))
        for line in body:
            fp.write("{}\n".format(line))


if __name__ == "__main__":
    sys.exit(main(sys.argv))
