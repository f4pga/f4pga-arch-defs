#!/usr/bin/env python3
"""
Utilities related to performance measurement.
"""
import time

# =============================================================================


def get_memory_usage():
    """
    Returns memory usage of the current process in GB.
    WORKS ONLY ON A LINUX SYSTEM.
    """

    status = None
    result = {'peak': 0.0, 'rss': 0.0}

    try:
        # This will only work on systems with a /proc file system
        # (like Linux).
        status = open('/proc/self/status')
        for line in status:
            parts = line.split()
            key = parts[0][2:-1].lower()
            if key in result:
                result[key] = int(parts[1]) / (1024*1024)

    finally:

        if status is not None:
            status.close()

    return result


# =============================================================================


class MemoryLog(object):
    """
    Memory usage logging helper class.

    Create object of the MemoryLog type, provide it with the log file name.
    Then at each important point of the script call its "checkpoint" method.
    """

    def __init__(self, file_name):
        self.fp = open(file_name, "w")
        self.t0 = time.time()
        self._write("Time [s], Label, Peak [GB], RSS [GB]\n")

    def _write(self, s):
        self.fp.write(s)
        self.fp.flush()

    def checkpoint(self, label):
        mem = get_memory_usage()
        self._write("{:.1f}, {}, {:.2f}, {:.2f}\n".format(time.time() - self.t0, label, mem["peak"], mem["rss"]))

