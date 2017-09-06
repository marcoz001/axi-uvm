package axi_pkg;

// Ugh, we now have a dependency on uvm in the RTL.
// @Todo: check if abstract class can be a simple class and not a component or object
import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi_if_abstract.svh"

//AXI ENUMS...
  
typedef enum {e_DRIVER, e_RESPONDER} driver_type_t;

endpackage : axi_pkg
