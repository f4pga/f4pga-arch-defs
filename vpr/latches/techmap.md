
# D-Flipflops

| Name              | Data In (D) | Clock (C) | Clock Enable (CE) | Set (S) | Reset (R) | Data Out (Q) |
| ----------------- | ----------- | --------- | ----------------- | ------- | --------- | ------------ |

| Name              | Data In (D) | Gate (G)  | Gate Enable (GE)  | Set (S) | Reset (R) | Data Out (Q) |
| ----------------- | ----------- | --------- | ----------------- | ------- | --------- | ------------ |


## Negative Edge Clock

| Name              | D | C | CE  | S | R | Q |
| ----------------- | - | - | --- | - | - | - |
| `$_SR_NN_`        |   |   |     | S | R | Q |
| `$_SR_NP_`        |   |   |     | S | R | Q |
| `$_DFF_N_`        | D | C |     |   |   | Q |
| `$_DFF_NN0_`      | D | C |     |   | R | Q |
| `$_DFF_NN1_`      | D | C |     |   | R | Q |
| `$_DFF_NP0_`      | D | C |     |   | R | Q |
| `$_DFF_NP1_`      | D | C |     |   | R | Q |
| `$__DFFS_NN0_`    | D | C |     |   | R | Q |
| `$__DFFS_NN1_`    | D | C |     |   | R | Q |
| `$__DFFS_NP0_`    | D | C |     |   | R | Q |
| `$__DFFS_NP1_`    | D | C |     |   | R | Q |
| `$_DFFE_NN_`      | D | C |  E  |   |   | Q |
| `$_DFFE_NP_`      | D | C |  E  |   |   | Q |
| `$__DFFE_NN0`     | D | C |  E  |   | R | Q |
| `$__DFFE_NN1`     | D | C |  E  |   | R | Q |
| `$__DFFE_NP0`     | D | C |  E  |   | R | Q |
| `$__DFFE_NP1`     | D | C |  E  |   | R | Q |
| `$__DFFSE_NN0`    | D | C |  E  |   | R | Q |
| `$__DFFSE_NN1`    | D | C |  E  |   | R | Q |
| `$__DFFSE_NP0`    | D | C |  E  |   | R | Q |
| `$__DFFSE_NP1`    | D | C |  E  |   | R | Q |
| `$_DFFSR_NNN_`    | D | C |     | S | R | Q |
| `$_DFFSR_NNP_`    | D | C |     | S | R | Q |
| `$_DFFSR_NPN_`    | D | C |     | S | R | Q |
| `$_DFFSR_NPP_`    | D | C |     | S | R | Q |

### Positive Edge Clock

| Name              | D | C | CE  | S | R | Q |
| ----------------- | - | - | --- | - | - | - |
| `$_SR_PN_`        |   |   |     | S | R | Q |
| `$_SR_PP_`        |   |   |     | S | R | Q |
| `$_DFF_P_`        | D | C |     |   |   | Q |
| `$_DFF_PN0_`      | D | C |     |   | R | Q |
| `$_DFF_PN1_`      | D | C |     |   | R | Q |
| `$_DFF_PP0_`      | D | C |     |   | R | Q |
| `$_DFF_PP1_`      | D | C |     |   | R | Q |
| `$__DFFS_PN0_`    | D | C |     |   | R | Q |
| `$__DFFS_PN1_`    | D | C |     |   | R | Q |
| `$__DFFS_PP0_`    | D | C |     |   | R | Q |
| `$__DFFS_PP1_`    | D | C |     |   | R | Q |
| `$_DFFE_PN_`      | D | C |  E  |   |   | Q |
| `$_DFFE_PP_`      | D | C |  E  |   |   | Q |
| `$__DFFE_PN0`     | D | C |  E  |   | R | Q |
| `$__DFFE_PN1`     | D | C |  E  |   | R | Q |
| `$__DFFE_PP0`     | D | C |  E  |   | R | Q |
| `$__DFFE_PP1`     | D | C |  E  |   | R | Q |
| `$__DFFSE_PN0`    | D | C |  E  |   | R | Q |
| `$__DFFSE_PN1`    | D | C |  E  |   | R | Q |
| `$__DFFSE_PP0`    | D | C |  E  |   | R | Q |
| `$__DFFSE_PP1`    | D | C |  E  |   | R | Q |
| `$_DFFSR_PNN_`    | D | C |     | S | R | Q |
| `$_DFFSR_PNP_`    | D | C |     | S | R | Q |
| `$_DFFSR_PPN_`    | D | C |     | S | R | Q |
| `$_DFFSR_PPP_`    | D | C |     | S | R | Q |

# D-latch

## Negative Enable

| Name              | D | G | GE  | S | R | Q |
| ----------------- | - | - | --- | - | - | - |
| `$_DLATCH_N_`     | D | E |     |   |   | Q |
| `$_DLATCHSR_NNN_` | D | E |     | S | R | Q |
| `$_DLATCHSR_NNP_` | D | E |     | S | R | Q |
| `$_DLATCHSR_NPN_` | D | E |     | S | R | Q |
| `$_DLATCHSR_NPP_` | D | E |     | S | R | Q |

Missing
 - Gate Enable?

## Positive Enable

| Name              | D | G | GE  | S | R | Q |
| ----------------- | - | - | --- | - | - | - |
| `$_DLATCHSR_PNN_` | D | E |     | S | R | Q |
| `$_DLATCHSR_PNP_` | D | E |     | S | R | Q |
| `$_DLATCHSR_PPN_` | D | E |     | S | R | Q |
| `$_DLATCHSR_PPP_` | D | E |     | S | R | Q |
| `$_DLATCH_P_`     | D | E |     |   |   | Q |

## Implicit Clock

| Name              | D | C | E | S | R | Q |
| ----------------- | - | - | - | - | - | - |
| `$_FF_`           | D |   |   |   |   | Q |
