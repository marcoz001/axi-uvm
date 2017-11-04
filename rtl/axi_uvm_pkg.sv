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