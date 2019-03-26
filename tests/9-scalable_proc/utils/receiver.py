#!/usr/bin/env python3
import argparse

import serial

# =============================================================================

def generate_expected_pattern(dump=False):

    pattern = []

    for i in range(512):
        v0 = i*2
        v1 = i*2 + 1

        inp_word = (v0 << 16) | v1
        out_word = v0 * v1

        inp_str = "%08X" % inp_word
        out_str = "%08X" % out_word

        if dump:
            print("'%s' -> '%s'" % (inp_str, out_str))

        pattern.append((inp_str, out_str))

    return pattern

# =============================================================================

def main():

    # Argument parser
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=str, default="/dev/ttyUSB1", help="Serial port")
    parser.add_argument("--baud", type=int, default=115200, help="Baud rate")
    parser.add_argument("--verbose", type=int, default=0, help="Verbosity level")

    args = parser.parse_args()

    # Generate the expected pattern
    pattern = generate_expected_pattern(True if args.verbose > 0 else False)

    # Open the port
    print("Opening '%s' at %d" % (args.port, args.baud))
    with serial.Serial(args.port, baudrate=args.baud, timeout=0.5) as port:

        port.reset_input_buffer()

        in_sync   = False
        sync_cnt  = 0
        pat_index = 0

        # Read and process data
        print("Waiting for pattern...")
        while(True):

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
            line  = line.strip()

            # Invalid line length
            if (len(line) % 8) != 0:
                print("Warning: Got len=%d ('%s')" % (len(line), line))
                continue

            # Split the line into 32-bit words
            words = [line[8*i:8*i+8] for i in range(len(line) // 8)]
            if args.verbose >= 1:
                print("".join([word + " " for word in words]))

            # Process words
            for word in words:
                
                # Not in sync
                if not in_sync:

                    # Got a match
                    if word == pattern[pat_index][1]:
                        print("rx:'%s' pat:'%s' V" % (word, pattern[pat_index][1]))
                        sync_cnt  += 1
                        pat_index  = (pat_index + 1) % int(len(pattern))

                    # Got a mismatch
                    else:
                        if sync_cnt != 0:
                            print("rx:'%s' pat:'%s' X (!)" % (word, pattern[pat_index][1]))
                        sync_cnt   = 0
                        pat_index  = 0

                    # Got enough
                    if sync_cnt >= 5:
                        print("Got %d consecutive matches. In sync." % sync_cnt)
                        in_sync = True

                # In sync
                else:

                    # Got a match
                    if word == pattern[pat_index][1]:
                        pat_index  = (pat_index + 1) % len(pattern)
                    # Got a mismatch
                    else:
                        print("MISMATCH! (rx='%s', pat='%s'), Sync lost!" % (word, pattern[pat_index][1]))
                        in_sync    = False
                        sync_cnt   = 0
                        pat_index  = 0

# =============================================================================


if __name__ == "__main__":
    main()

