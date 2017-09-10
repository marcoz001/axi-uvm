package axi_uvm_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi_pkg::*;

typedef enum bit {e_WRITE=0, e_READ=1} cmd_t;

  
`include "axi_agent_config.svh"

`include "axi_seq_item.svh"
`include "axi_sequencer.svh"
`include "axi_seq.svh"
`include "axi_responder_seq.svh"

`include "axi_driver.svh"
`include "axi_monitor.svh"
`include "axi_coveragecollector.svh"

`include "axi_agent.svh"

`include "axi_env_config.svh"
`include "axi_env.svh"


`include "axim2wbsp_base_test.svh"

endpackage : axi_uvm_pkg