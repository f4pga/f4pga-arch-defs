# SRL32 Shift test

This test checks whether multiple SRL32s shift data correctly. The test uses a
small ROM with a random data which is fed through SRL32 and then compared to
its delayed version read from the same ROM. The delay is being changed
automatically in a loop.

This test works on the Basys3 board.

LED[15]   - Just blinks to verify if the design is alive.
LED[14]   - Shows random data from the output of one SRL32.
LED[13:0] - Individual error indicators for all tested SRL32s.

SW[0]    - Reset.
SW[1]    - Chooses between latched and non-latched error indication.
SW[2]    - Forces and error on all SRL32s.

