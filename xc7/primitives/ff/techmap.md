|     Yosys        |  D  |  C  |  E  |  G  |  R  |  Q  ||  Xilinx  |  D  |  Q  |  C  |  CE  |  GE  |  R   | CLR | PRE ||  Type | Clk Edge |      |
| ---------------- | --- | --- | --- | --- | --- | --- || -------- | --- | --- | --- | ---- | ---- | ---- | --- | --- || ----- | -------- | ---- |
| `\$_DFF_P_`      |  D  |  C  |     |     |     |  Q  || `FDRE`   |  D  |  Q  |  C  | 1'b1 |      | 1'b0 |     |     ||  SYNC | Positive |      |
| `\$_DFF_PN0_`    |  D  |  C  |     |     |  R  |  Q  || `FDCE`   |  D  |  Q  |  C  | 1'b1 |      |      | !R  |     || ASYNC | Positive |      |
| `\$_DFF_PP0_`    |  D  |  C  |     |     |  R  |  Q  || `FDCE`   |  D  |  Q  |  C  | 1'b1 |      |      |  R  |     || ASYNC | Positive |      |
| `\$_DFF_PN1_`    |  D  |  C  |     |     |  R  |  Q  || `FDPE`   |  D  |  Q  |  C  | 1'b1 |      |      |     | !R  || ASYNC | Positive |      |
| `\$_DFF_PP1_`    |  D  |  C  |     |     |  R  |  Q  || `FDPE`   |  D  |  Q  |  C  | 1'b1 |      |      |     |  R  || ASYNC | Positive |      |
| `\$_DFFE_PP_`    |  D  |  C  |  E  |     |     |  Q  || `FDRE`   |  D  |  Q  |  C  |  E   |      | 1'b0 |     |     ||  SYNC | Positive |      |
| `\$_DFF_N_`      |  D  |  C  |     |     |     |  Q  || `FDRE_1` |  D  |  Q  |  C  | 1'b1 |      | 1'b0 |     |     ||  SYNC | Negative |      |
| `\$_DFF_NN0_`    |  D  |  C  |     |     |  R  |  Q  || `FDCE_1` |  D  |  Q  |  C  | 1'b1 |      |      | !R  |     || ASYNC | Negative |      |
| `\$_DFF_NP0_`    |  D  |  C  |     |     |  R  |  Q  || `FDCE_1` |  D  |  Q  |  C  | 1'b1 |      |      |  R  |     || ASYNC | Negative |      |
| `\$_DFF_NN1_`    |  D  |  C  |     |     |  R  |  Q  || `FDPE_1` |  D  |  Q  |  C  | 1'b1 |      |      |     | !R  || ASYNC | Negative |      |
| `\$_DFF_NP1_`    |  D  |  C  |     |     |  R  |  Q  || `FDPE_1` |  D  |  Q  |  C  | 1'b1 |      |      |     |  R  || ASYNC | Negative |      |
| `\$_DFFE_NP_`    |  D  |  C  |  E  |     |     |  Q  || `FDRE_1` |  D  |  Q  |  C  |  E   |      | 1'b0 |     |     ||  SYNC | Negative |      |
| ---------------- | --- | --- | --- | --- | --- | --- || -------- | --- | --- | --- | ---- | ---- | ---- | --- | --- || ----- | -------- | ---- |
| `\$_DLATCH_P_`   |  D  |  E  |     |     |     |  Q  || `LDPE`   |  D  |  Q  |  E  |      |      |      |     |     || LATCH |          |      |
|                  |  D  |  E  |     |     |     |  Q  || `LDCE`   |  D  |  Q  |  E  |      |      |      |     |     || LATCH |          |      |



|          |           |                           | Clock               |                       | Mode         |        || CE  |   CLR  |  PRE   |   R    |
| -------- | --------- | ------------------------- | ------------------- | --------------------- | ------------ | ------ || --- | ------ | ------ | ------ |
| `FD`     | Primitive | D Flip-Flop               |                     |                       |              |        ||  1  |        |        |        |
| `FDE`    | Primitive | D Flip-Flop               |                     | Clock Enable          |              |        ||  E  |        |        |        |
| `FDC`    | Primitive | D Flip-Flop               |                     |                       | Asynchronous | Clear  ||  1  | Clear  |        |        |
| `FDCE`   | Primitive | D Flip-Flop               |                     | Clock Enable          | Asynchronous | Clear  ||  E  | Clear  |        |        |
| `FDP`    | Primitive | D Flip-Flop               |                     |                       | Asynchronous | Preset ||  1  |        | Preset |        |
| `FDPE`   | Primitive | D Flip-Flop               |                     | Clock Enable          | Asynchronous | Preset ||  E  |        | Preset |        |
| `FDR`    | Primitive | D Flip-Flop               |                     |                       | Synchronous  | Reset  ||  1  |        |        | Reset  |
| `FDRE`   | Primitive | D Flip-Flop               |                     | Clock Enable          | Synchronous  | Reset  ||  E  |        |        | Reset  |
| `FDS`    | Primitive | D Flip-Flop               |                     |                       | Synchronous  | Set    ||  1  |        |        | Set    |
| `FDSE`   | Primitive | D Flip-Flop               |                     | Clock Enable          | Synchronous  | Set    ||  E  |        |        | Set    |
| -------- | --------- | ------------------------- | ------------------- | --------------------- | ------------ | ------ || --- | ------ | ------ | ------ |
| `FD_1`   | Primitive | D Flip-Flop               | Negative-Edge Clock |                       |              |        ||  1  |        |        |        |
| `FDE_1 ` | Primitive | D Flip-Flop               | Negative-Edge Clock | Negative Clock Enable |              |        || !E  |        |        |        |
| `FDC_1 ` | Primitive | D Flip-Flop               | Negative-Edge Clock |                       | Asynchronous | Clear  ||  1  | Clear  |        |        |
| `FDCE_1` | Primitive | D Flip-Flop               | Negative-Edge Clock | Clock Enable          | Asynchronous | Clear  ||  E  | Clear  |        |        |
| `FDP_1 ` | Primitive | D Flip-Flop               | Negative-Edge Clock |                       | Asynchronous | Preset ||  1  |        | Preset |        |
| `FDPE_1` | Primitive | D Flip-Flop               | Negative-Edge Clock | Clock Enable          | Asynchronous | Preset ||  E  |        | Preset |        |
| `FDR_1 ` | Primitive | D Flip-Flop               | Negative-Edge Clock |                       | Synchronous  | Reset  ||  1  |        |        | Reset  |
| `FDRE_1` | Primitive | D Flip-Flop               | Negative-Edge Clock | Clock Enable          | Synchronous  | Reset  ||  E  |        |        | Reset  |
| `FDS_1 ` | Primitive | D Flip-Flop               | Negative-Edge Clock |                       | Synchronous  | Set    ||  1  |        |        | Set    |
| `FDSE_1` | Primitive | D Flip-Flop               | Negative-Edge Clock | Clock Enable          | Synchronous  | Set    ||  E  |        |        | Set    |
| -------- | --------- | ------------------------- | ------------------- | --------------------- | ------------ | ------ || --- | ------ | ------ | ------ |
| `LD`     | Primitive | D Latch                   |                     |                       |              |        ||     |        |        |        |
| `LDE`    | Primitive | D Latch                   |                     | Gate Enable           |              |        ||     |        |        |        |
| `LDC`    | Primitive | D Latch                   |                     |                       | Asynchronous | Clear  ||     | Clear  |        |        |
| `LDCE`   | Primitive | D Latch                   |                     | Gate Enable           | Asynchronous | Clear  ||     | Clear  |        |        |
| `LDP`    | Primitive | D Latch                   |                     |                       | Asynchronous | Preset ||     |        | Preset |        |
| `LDPE`   | Primitive | D Latch                   |                     | Gate Enable           | Asynchronous | Preset ||     |        | Preset |        |
| -------- | --------- | ------------------------- | ------------------- | --------------------- | ------------ | ------ || --- | ------ | ------ | ------ |
| `LD_1`   | Primitive | D Latch                   | Inverted Gate       |                       |              |        ||     |        |        |        |
| `LDE_1`  | Primitive | D Latch                   | Inverted Gate       | Gate Enable           |              |        ||     |        |        |        |
| `LDC_1`  | Primitive | D Latch                   | Inverted Gate       |                       | Asynchronous | Clear  ||     | Clear  |        |        |
| `LDCE_1` | Primitive | D Latch                   | Inverted Gate       | Gate Enable           | Asynchronous | Clear  ||     | Clear  |        |        |
| `LDP_1`  | Primitive | D Latch                   | Inverted Gate       |                       | Asynchronous | Preset ||     |        | Preset |        |
| `LDPE_1` | Primitive | D Latch                   | Inverted Gate       | Gate Enable           | Asynchronous | Preset ||     |        | Preset |        |
| -------- | --------- | ------------------------- | ------------------- | --------------------- | ------------ | ------ || --- | ------ | ------ | ------ |

| -------- | --------- | ------------------------- | ------------------- | --------------------- | ------------ | ------ || --- | ------ | ------ | ------ |
| `FD4CE`  | Macro     |  4-Bit Data Register      |                     | Clock Enable          | Asynchronous | Clear  ||     | Clear  |        |        |
| `FD8CE`  | Macro     |  8-Bit Data Register      |                     | Clock Enable          | Asynchronous | Clear  ||     | Clear  |        |        |
| `FD16CE` | Macro     | 16-Bit Data Register      |                     | Clock Enable          | Asynchronous | Clear  ||     | Clear  |        |        |
| `FD4RE`  | Macro     |  4-Bit Data Register      |                     | Clock Enable          | Synchronous  | Reset  ||     |        |        | Reset  |
| `FD8RE`  | Macro     |  8-Bit Data Register      |                     | Clock Enable          | Synchronous  | Reset  ||     |        |        | Reset  |
| `FD16RE` | Macro     | 16-Bit Data Register      |                     | Clock Enable          | Synchronous  | Reset  ||     |        |        | Reset  |
| -------- | --------- | ------------------------- | ------------------- | --------------------- | ------------ | ------ || --- | ------ | ------ | ------ |
| `FJKC`   | Macro     | J-K Flip-Flop             |                     |                       | Asynchronous | Clear  ||     | Clear  |        |        |
| `FJKCE`  | Macro     | J-K Flip-Flop             |                     | Clock Enable          | Asynchronous | Clear  ||     | Clear  |        |        |
| `FJKP`   | Macro     | J-K Flip-Flop             |                     |                       | Asynchronous | Preset ||     |        | Preset |        |
| `FJKPE`  | Macro     | J-K Flip-Flop             |                     | Clock Enable          | Asynchronous | Preset ||     |        | Preset |        |
| -------- | --------- | ------------------------- | ------------------- | --------------------- | ------------ | ------ || --- | ------ | ------ | ------ |
| `FTP`    | Macro     | Toggle Flip-Flop          |                     |                       | Asynchronous | Preset ||     |        | Preset |        |
| `FTPE`   | Macro     | Toggle Flip-Flop          |                     | Clock Enable          | Asynchronous | Preset ||     |        | Preset |        |
| `FTPLE`  | Macro     | Toggle/Loadable Flip-Flop |                     | Clock Enable          | Asynchronous | Preset ||     |        | Preset |        |
| `FTC`    | Macro     | Toggle Flip-Flop          |                     |                       | Asynchronous | Clear  ||     | Clear  |        |        |
| `FTCE`   | Macro     | Toggle Flip-Flop          |                     | Clock Enable          | Asynchronous | Clear  ||     | Clear  |        |        |
| `FTCLE`  | Macro     | Toggle/Loadable Flip-Flop |                     | Clock Enable          | Asynchronous | Clear  ||     | Clear  |        |        |
| `FTCLEX` | Macro     | Toggle/Loadable Flip-Flop |                     | Clock Enable          | Asynchronous | Clear  ||     | Clear  |        |        |
| -------- | --------- | ------------------------- | ------------------- | --------------------- | ------------ | ------ || --- | ------ | ------ | ------ |
