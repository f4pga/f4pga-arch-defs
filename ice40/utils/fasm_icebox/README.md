The tool to generate FASM features attempts to minimize divergence from icebox naming.

Differences from IceStorm names:
 - `/` marks are replaced with `_` to meet [FASM](https://github.com/SymbiFlow/fasm/blob/master/docs/specification.rst#formal-syntax-specification-of-a-line-of-a-fasm-file) naming convention
 - RAM
   - RamConfig CBIT[0-3] are combined into READ_MODE and WRITE_MODE
 - IO
   - IE and REN are inverted from icebox polarity
   - PINTYPE are not forwarded and instead SimpleInput and SimpleOutput features cover those bits


TODO:
 - [ ] RAMCONFIG CBITS
   - [X] Supports READ_MODE adn WRITE_MODE
   - [ ] Support RAM Cascade bits
   - [X] PowerUp inverted for 1k parts
 - [X] IE inverted for 1k parts
 - [X] REN inverted
 - [ ] Colbuf
   - All are on for now, but it's probably power hungry
   - [ ] Need to rework routing to represent Column Buffers
 - [ ] beyond simple IO
   - Should rework solution by in tech mapping and passing parameters

Push down to IceStorm:
 - [ ] store tiles as 2D bit arrays for manipulation in iceconfig
 - [ ] empty_*() methods should init to lowest power config IE bits so buffers are off
