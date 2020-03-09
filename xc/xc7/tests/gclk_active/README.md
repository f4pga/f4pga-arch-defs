# GCLK through test

Verifies whether `CLK_HROW_R_CK_GCLKx_ACTIVE` fasm features are emitted correctly.

The test consists of one clock input at the bottom clock region that goes through a bufg to an IO pad on the topmost clock region. The clock has to pass through `CLK_HROW` tile(s). For those tiles that the signal clock pases through, the `CLK_HROW_R_CK_GCLKx_ACTIVE` feature must be emitted even though that thete is no active bel in such a tile.
