# MMCME2_ADV tests

Allows to vrify MMCME2_ADV functionality in hardware

Switches:
- SW0: Reset (active high)
- SW1: PLL PWRDWN port (active high)
- SW2: CLKINSEL. When low CLKIN=100MHz, when high CLLKIN=50MHz.

LEDs:
- LED0: blinks at 23.841Hz / 11.920Hz
- LED1: blinks at 11.920Hz /  5.960Hz
- LED2: blinks at 7.947HZ / 3.9735Hz
- LED3: blinks at 5.960Hz / 2.980Hz
- LED4: blinks at 4.768Hz / 2.384Hz
- LED5: blinks at 3.973Hz / 1.9865Hz
- LED6: PLL LOCK indicator (lit when locked)

There are 3 test variants:
- `mmcm_int_basys3` - Internal feedback
- `mmcm_buf_basys3` - Feedback through a BUFG
- `mmcm_ext_basys3` - External feedback. Need to short `JC.1` and `JC.2` on the Basys3 board.
