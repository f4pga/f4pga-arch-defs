""" Tool for reading bram test output and outputting human readable output.

"""
import argparse
import serial
from collections import deque, namedtuple
import struct
import itertools
import enum


class RamTestState(enum.Enum):
    START = 1
    VERIFY_INIT = 2
    WRITE_ZEROS = 3
    VERIFY_ZEROS = 4
    WRITE_ONES = 5
    VERIFY_ONES = 6
    WRITE_10 = 7
    VERIFY_10 = 8
    WRITE_01 = 9
    VERIFY_01 = 10
    WRITE_RANDOM = 11
    VERIFY_RANDOM = 12
    RESTART_LOOP = 13


Result = namedtuple('Results', 'error_count loop_count')
Error = namedtuple('Error', 'state address expected_value actual_value')

RESULT_LOG = '<BBHBB'
RESULT_LOG_SIZE = struct.calcsize(RESULT_LOG)

ERROR_LOG = '<BBHHHBB'
ERROR_LOG_SIZE = struct.calcsize(ERROR_LOG)


def process_buffer(data):
    while data:
        while data:
            first_char = bytes((data[0], ))
            if first_char in [b'E', b'L']:
                break

            data.popleft()

        if not data:
            return

        first_char = bytes((data[0], ))

        if first_char == b'L' and len(data) >= RESULT_LOG_SIZE:
            log = bytes(itertools.islice(data, 0, RESULT_LOG_SIZE))
            data.popleft()

            header, error_count, loop_count, cr, lf = struct.unpack(
                RESULT_LOG, log
            )

            if cr == ord('\r') and lf == ord('\n'):
                yield Result(error_count=error_count, loop_count=loop_count)

        elif first_char == b'E' and len(data) >= ERROR_LOG_SIZE:
            log = bytes(itertools.islice(data, 0, ERROR_LOG_SIZE))
            data.popleft()

            header, state, address, expected_value, actual_value, cr, lf = struct.unpack(
                ERROR_LOG, log
            )

            if cr == ord('\r') and lf == ord('\n'):
                try:
                    state = RamTestState(state)
                except Exception:
                    continue

                yield Error(
                    state=RamTestState(state),
                    address=hex(address),
                    expected_value=hex(expected_value),
                    actual_value=hex(actual_value)
                )
        else:
            return


def main():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument('uart')
    parser.add_argument('--file', action='store_true')
    parser.add_argument('--baudrate', '-B', type=int, default=500000)

    args = parser.parse_args()

    if args.file:
        with open(args.uart, 'rb') as f:
            data = deque(f.read())
            for log in process_buffer(data):
                print(log)
    else:
        data = deque()
        with serial.Serial(port=args.uart, baudrate=args.baudrate,
                           timeout=.200, inter_byte_timeout=.200) as s:
            while True:
                buf = s.read(10 * 1024)
                data.extend(buf)

                for log in process_buffer(data):
                    print(log)


if __name__ == '__main__':
    main()
