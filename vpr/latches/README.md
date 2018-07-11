
The most common type of flipflop found in FPGAs is the D-flipflop.

The primary attributes of D-flipflops are;


 * `C` - How the latching is trigger;
   - Positive clock edge
   - Negative clock edge
   - Positive enable (latch)
   - Negative enable (latch)

 * `E` - Enable signal


 * `S` - Set functionality
 * `R` - Reset functionality
 * `SR` - Sometimes combined into one Set / Reset signal
  - Set and reset can be either synchronous or asynchronous.

These attributes combined to form;

 * `$_<Type><Features>_<Polarity>_`

 * `DLATCH`, `DFF`

 * `$_DFF_P_` - Positive edge triggered D flipflop.
 * `$_DFFE_PP_` - Positive edge triggered D flipflop with positive level enable.
 * ...

