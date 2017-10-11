////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_uvm_pkg.sv
//
// Purpose:
//          Systemverilog package for AXI UVM environment
//
// Creator:	Matt Dew
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017, Matt Dew
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////


package axi_uvm_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import axi_pkg::*;

typedef enum int {e_WRITE                             = 0,
                  e_READ                              = 1,
                  e_SETAWREADYTOGGLEPATTERN           = 2,
                  e_SETWREADYTOGGLEPATTERN            = 3,
                  e_SET_MIN_CLKS_BETWEEN_AW_TRANSFERS = 4, // Minimum pause between aw xfers
                  e_SET_MAX_CLKS_BETWEEN_W_TRANSFERS  = 5  // maximum pause between aw xfers

                 /*
                 e_WRITEADDRESS,
                 e_WRITEDATA,
                 e_WRITERESPONSE,
                 e_READADDRESS,
                 e_READDATA,
                 */
                 } cmd_t;


//

typedef enum {e_DRIVER, e_RESPONDER} driver_type_t;

`include "memory.svh"

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