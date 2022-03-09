import re

USAGE_PATTERN = re.compile(r'^Netlist +([0-9]+)\sblocks of type: (.*)$')


def parse_usage(pack_log):
    """ Yield (block, count) from pack_log file.

    Args:
        pack_log (str): Path pack.log file generated from VPR.

    Yields:
        (block, count): Tuple of block name and count of block type.

    """
    with open(pack_log) as f:
        for line in f:
            m = re.match(USAGE_PATTERN, line.strip())
            if m:
                yield (m.group(2), int(m.group(1)))
