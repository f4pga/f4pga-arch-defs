# SRL32 initialization test

This test checks initialization of SRL32. The register is initialized with a
pattern. The SRL is configured to fixed delay of 32, the output Q i connected
to input D so the data is looped.

This test works on the Basys3 board.

LED[15]   - Just blinks to verify if the design is alive.
LED[14]   - Shows random data from the output of one SRL32.
LED[13:0] - Individual error indicators for all tested SRL32s.

SW[0]    - Reset.
SW[1]    - Chooses between latched and non-latched error indication.
SW[2]    - Forces and error on all SRL32s. ONCE USED TO CLEAR THE ERROR YOU NEED
           TO RE-PROGRAM THE BOARD.

