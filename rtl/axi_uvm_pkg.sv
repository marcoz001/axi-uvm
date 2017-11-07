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

/*! \package axi_uvm_pkg
 *  \brief Systemverilog package for AXI UVM environment */
package axi_uvm_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"


//import params_pkg::*;

localparam ADDR_WIDTH = 32; //params_pkg::AXI_ADDR_WIDTH;

import axi_pkg::*;

/*! \typedef axi_protocol_version_t */
/** \brief Version 3 or Version 4
 *
 * A few differences:
 * - AXI4 has no WID
 * - if burst_type=e_INCR, then AxLEN can be to 256[2**8], instead of just 16 [2**4]
*/
typedef enum bit {e_AXI3, e_AXI4} axi_protocol_version_t;

/*! \typedef cmd_t */
/** \brief Command type - what is the purpose of this packet?
*/
typedef enum int {e_WRITE                    = 0, /**< AXI Write - Driver handles */
                  e_READ                     = 1, /**< AXI Read  - Driver handles */
                  e_READ_DATA                = 2, /**< Read Data - Responder handles */
                  e_WRITE_DATA,
                  e_WRITE_RESPONSE,
                  e_SETAWREADYTOGGLEPATTERN,      /**< Set awready toggle pattern - responder handles */
                  e_SETWREADYTOGGLEPATTERN,  /**< Set wready toggle pattern - responder handles */
                  e_SETARREADYTOGGLEPATTERN,  /**< Set bready toggle pattern - driver handles */

                  e_SET_MIN_CLKS_BETWEEN_AW_TRANSFERS, /**< Set minimum pause between aw xfers - Driver uses */
                  e_SET_MAX_CLKS_BETWEEN_W_TRANSFERS   /**< Set maximum pause between aw xfers - Driver uses */


                 } cmd_t;

/*! \typedef driver_type_t */
/** \brief Config variable that tells axi_driver whether it is a master driver or slave driver(responder)
 *
 * \todo: Split driver and responder into different components.
*/
typedef enum {e_DRIVER,  /**< Agent is a master */
              e_RESPONDER  /**< Agent is a slave/responder */
             } driver_type_t;


/*! \brief Calculate number of beats/clks in this burst.
 *
 * If the transfer is too large, this function will return a bogus result
 * The caller is responsible for insuring safety.
 * \todo: check if size (length + address-misalignment) is too large
 */
function int calculate_beats(
    input bit [ADDR_WIDTH-1:0] addr,
    input int burst_size,
  input int burst_length);

  int beats;
  bit [ADDR_WIDTH-1:0] aligned_addr;


     aligned_addr=axi_pkg::calculate_aligned_address(.address(addr),
                                            .burst_size(burst_size));
        // address - starting address
        // burst_length - total length of burst (in bytes)
        // data_bus_bytes - width of data bus (in bytes)
        // number_bytes - number of bytes per beat (must be consistent throughout burst)
        //              - this matches data_bus_bytes unless doing a partial transfer
  beats = $ceil(real'(real'((addr-aligned_addr)+burst_length)/real'(2**burst_size)));
  // \todo: something easily synthesizable might be nice insttead of $ceil()

 // `uvm_info("CALCULATE BEATS", $sformatf("addr:0x%0x  aligned-addr: 0x%0x   burst_length: %0d    number_bytes: %0d beats [((0x%0x-0x%0x)+%0d)/%0d]=0x%0x", addr, aligned_addr, burst_length, number_bytes, addr, aligned_addr, burst_length,number_bytes,beats), UVM_HIGH)

  return beats;
endfunction : calculate_beats



`include "memory.svh"

`include "axi_agent_config.svh"

`include "axi_seq_item.svh"
`include "axi_sequencer.svh"
`include "axi_seq.svh"
`include "axi_responder_seq.svh"

`include "axi_driver.svh"
`include "axi_responder.svh"
`include "axi_monitor.svh"
`include "axi_scoreboard.svh"
`include "axi_coveragecollector.svh"

`include "axi_agent.svh"

`include "axi_env_config.svh"
`include "axi_env.svh"


`include "axi_base_test.svh"

endpackage : axi_uvm_pkg