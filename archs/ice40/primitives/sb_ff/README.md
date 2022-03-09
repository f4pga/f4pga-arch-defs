
## Tile Level Flip Flop Configuration

 * `# PosClk` -- Flip flop uses positive edge clock (no actual value, so just uses a comment).
 * `NegClk` -- Flip flop uses negative edge clock.

 * Use a clock enable signal -- Any signal connected to the `CEN` input, otherwise `CEN` == 1.
   - When a `CEN` input in use, the flip flop type name has `E` in it's name.

 * Use a set/reset signal -- Any signal connected to the `S_R` input, otherwise `S_R` == 0.
   - When a `S_R` input in use, the flip flop type name has either a `S` or `R` in the name.

## Cell Level Flip Flop Configuration

 * `enable_dff` / `DffEnable` - Use the flip flip -- Cell Level

### Set/Reset Signal

#### Set or Reset

 * `Set_NoReset` - When `S_R` == 1, flip flop value is forced to `1'b1`
 * `# Reset` - When `S_R` == 1, flip flop value is forced to `1'b0`

#### Set/Reset Asynchronous

 * `AsyncSetReset` - When set, the `S_R` is asynchronous to the clock.
 * `# SyncSetReset` - When set, the `S_R` is synchronous to the clock
   - Synchronous set/reset flip flops have an extra `S` in the name.

## Naming

### Lattice Naming

 `DFF` (`N`) (`E`) (`S`<sub>1</sub>) (`R`|`S`<sub>2</sub>)

  * `N`             -- Negative clock
  * `E`             -- Clock enable signal used.
  * `S`<sub>1</sub> -- Synchronous Set/Reset signal used.
  * `R`             -- When Set/Reset signal asserted, value is set to zero.
  * `S`<sub>2</sub> -- When Set/Reset signal asserted, value is set to one.

### Yosys Internal Naming

 `$_DFF` (`E`) (`SR`) `_` `N`|`P`<sub>1</sub> (`N`|`P`)<sub>2</sub> (`N0`|`N1`|`P0`|`P1`)<sub>3</sub> `_`

  * `E` - Clock enable signal used.
  * `SR` - Both Set and Reset signals.
  * `N`<sub>1</sub> - Negative edge clock.
  * `P`<sub>1</sub> - Positive edge clock.
  * `N`<sub>2</sub> - Negative level clock enable.
  * `P`<sub>2</sub> - Positive level clock enable.
  * `N0`<sub>3</sub> - Negative level reset signal (on negative level, force contents to zero).
  * `P0`<sub>3</sub> - Positive level reset signal (on positive level, force contents to zero).
  * `N1`<sub>3</sub> - Negative level set signal (on negative level, force contents to one).
  * `P1`<sub>3</sub> - Positive level set signal (on positive level, force contents to one).


## Flip Flop Configuration Table

NegClk |  cen | SR | async | set_norest | type name | packs if the same
-------|------|----|-------|------------|-----------|------------------
   0   |   0  |  0 |   X   |     X      | DFF       | A
   0   |   1  |  0 |   X   |     X      | DFFE      | B
   0   |   0  |  1 |   0   |     0      | DFFSR     | C
   0   |   0  |  1 |   0   |     1      | DFFSS     | C
   0   |   0  |  1 |   1   |     0      | DFFR      | C
   0   |   0  |  1 |   1   |     1      | DFFS      | C
   0   |   1  |  1 |   0   |     1      | DFFESS    | D
   0   |   1  |  1 |   0   |     0      | DFFESR    | D
   0   |   1  |  1 |   1   |     0      | DFFER     | D
   0   |   1  |  1 |   1   |     1      | DFFES     | D
   1   |   0  |  0 |   X   |     X      | DFFN      | a
   1   |   1  |  0 |   X   |     X      | DFFNE     | b
   1   |   0  |  1 |   0   |     0      | DFFNSR    | c
   1   |   0  |  1 |   0   |     1      | DFFNSS    | c
   1   |   0  |  1 |   1   |     0      | DFFNR     | c
   1   |   0  |  1 |   1   |     1      | DFFNS     | c
   1   |   1  |  1 |   0   |     1      | DFFNESS   | d
   1   |   1  |  1 |   0   |     0      | DFFNESR   | d
   1   |   1  |  1 |   1   |     0      | DFFNER    | d
   1   |   1  |  1 |   1   |     1      | DFFNES    | d
