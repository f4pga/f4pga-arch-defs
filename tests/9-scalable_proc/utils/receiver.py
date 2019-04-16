#!/usr/bin/env python3
import argparse
import serial

from rom_generator import generate_rom_data

# =============================================================================


def generate_expected_pattern(length, dump=False):

    # Use the same generator as for ROM
    input_data = generate_rom_data(length)

    # Simulate processing of the data
    output_data = []
    for data_word in input_data:

        # Decode input word
        v0 = data_word >> 16
        v1 = data_word & 0x0000FFFF

        # Process
        u = (v0 * v1) & 0xFFFFFFFF

        # Store
        output_data.append(u)

        if dump:
            print("%04X * %04X = %08X" % (v0, v1, u))

    # Join lists, convert to strings
    return [("%08X" % v, "%08X" % u) for v, u in zip(input_data, output_data)]


# =============================================================================


def main():

    # Argument parser
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--port", type=str, default="/dev/ttyUSB1", help="Serial port"
    )
    parser.add_argument("--baud", type=int, default=9600, help="Baud rate")
    parser.add_argument("--rom-size", type=int, default=64, help="ROM size")
    parser.add_argument(
        "--verbose", type=int, default=0, help="Verbosity level"
    )

    args = parser.parse_args()

    # Generate the expected pattern
    pattern = generate_expected_pattern(
        args.rom_size, True if args.verbose > 0 else False
    )

    # Open the port
    print("Opening '%s' at %d" % (args.port, args.baud))
    with serial.Serial(args.port, baudrate=args.baud, timeout=0.5) as port:

        port.reset_input_buffer()

        in_sync = False
        sync_cnt = 0
        pat_index = 0

        # Read and process data
        print("Waiting for pattern...")
        while (True):

            # Read line
            line = port.readline()
            if len(line) == 0:
                continue

            # Decode
            try:
                line = line.decode("ascii")
            except UnicodeDecodeError as ex:
                print("Warning:", repr(ex))
                continue

            # Strip
            line = line.strip()

            # Invalid line length
            if (len(line) % 8) != 0:
                print("Warning: Got len=%d ('%s')" % (len(line), line))
                continue

            # Split the line into 32-bit words
            words = [line[8 * i:8 * i + 8] for i in range(len(line) // 8)]
            if args.verbose >= 1:
                print("".join([word + " " for word in words]))

            # Process words
            for word in words:

                # Not in sync
                if not in_sync:

                    # Got a match
                    if word == pattern[pat_index][1]:
                        print(
                            "rx:'%s' pat:'%s' V" %
                            (word, pattern[pat_index][1])
                        )
                        sync_cnt += 1
                        pat_index = (pat_index + 1) % int(len(pattern))

                    # Got a mismatch
                    else:
                        if sync_cnt != 0:
                            print(
                                "rx:'%s' pat:'%s' X (!)" %
                                (word, pattern[pat_index][1])
                            )
                        sync_cnt = 0
                        pat_index = 0

                    # Got enough
                    if sync_cnt >= 5:
                        print(
                            "Got %d consecutive matches. In sync." % sync_cnt
                        )
                        in_sync = True

                # In sync
                else:

                    # Got a match
                    if word == pattern[pat_index][1]:
                        pat_index = (pat_index + 1) % len(pattern)
                        sync_cnt += 1
                        if sync_cnt % 1000 == 0:
                            print('In sync, sync_cnt = {}'.format(sync_cnt))
                    # Got a mismatch
                    else:
                        print(
                            "MISMATCH! (rx='%s', pat='%s'), Sync lost!" %
                            (word, pattern[pat_index][1])
                        )
                        in_sync = False
                        sync_cnt = 0
                        pat_index = 0


# =============================================================================

if __name__ == "__main__":
    main()
