# SRL32 MC31 output test

Routes signal through DOUTMUX.AMC31 and checks whether data coming out of
there is shifted by 32 cycles w.r.t. data input to a SRL32

This test works on the Basys3 board.

LED[15]   - Just blinks to verify if the design is alive.
LED[14]   - Shows random data from the output of one SRL32.
LED[13:0] - Individual error indicators for all tested SRL32s.

SW[0]    - Reset.
SW[1]    - Chooses between latched and non-latched error indication.
SW[2]    - Forces an error on all SRL32s.

