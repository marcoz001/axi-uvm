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


import params_pkg::*;

localparam ADDR_WIDTH = params_pkg::AXI_ADDR_WIDTH;
localparam ID_WIDTH   = params_pkg::AXI_ID_WIDTH;

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
`include "axi_seq_item.svh"


/*! \brief Pull values out of axi_seq_item and stuff into a axi_seq_item_aw_vector_s
 *
 * This funcion returns a ready-to-be used struct so awlen and awaddr are calcuated
 * in this function.
 * @param t an axi_seq_item
 * @return v a packed struct of type axi_seq_item_aw_vector_s
 */
function automatic  void aw_from_class(
  ref  axi_seq_item             t,
  output axi_seq_item_aw_vector_s v);

  axi_seq_item_aw_vector_s s;

   s.awid    = t.id;

  s.awaddr  = axi_pkg::calculate_burst_aligned_address(.address(t.addr),
                                                 .burst_size(t.burst_size));

  s.awlen     = axi_pkg::calculate_axlen(.addr         (t.addr),
                                         .burst_size   (t.burst_size),
                                         .burst_length (t.len));

   s.awsize  = t.burst_size;
   s.awburst = t.burst_type;
   s.awlock  = t.lock;
   s.awcache = t.cache;
   s.awprot  = t.prot;
   s.awqos   = t.qos;

    v = s;
endfunction : aw_from_class

/*! \brief Pull values out of a axi_seq_item_aw_vector_s and stuffs them into an axi_seq_item
 *
 * t.len is converted from awlen into a byte len. It uses burst_size (bytes per beat) * beats_per_burst to give a maximum byte length.
 * @return t an axi_seq_item
 * @param v a packed struct of type axi_seq_item_aw_vector_s
 */
function automatic void aw_to_class(
  ref    axi_seq_item             t,
  input  axi_seq_item_aw_vector_s v);
    axi_seq_item_aw_vector_s s;
    s = v;

// \todo: should we detect if t==null and do something?
   // t = new();

     t.id          = s.awid;
     t.addr        = s.awaddr;
     t.len         = (s.awlen+1)*(2**s.awsize);
     t.burst_size  = s.awsize;
     t.burst_type  = s.awburst;
     t.lock        = s.awlock;
     t.cache       = s.awcache;
     t.prot        = s.awprot;
     t.qos         = s.awqos;

endfunction : aw_to_class


/*! \brief take values from write response channel and stuff into a axi_seq_item_b_vector_s
 *
 * @param bid - Write Response ID tag
 * @param bresp - Write Response
 * @return v - packed struct of type axi_seq_item_b_vector_s
 */
function automatic void b_from_class(
  input  [ID_WIDTH-1:0]     bid,
  input  [1:0]              bresp,
  output axi_seq_item_b_vector_s v);

  axi_seq_item_b_vector_s s;

     s.bid     = bid;
     s.bresp   = bresp;

  v = s;
endfunction : b_from_class

/*! \brief return values from a axi_seq_item_b_vector_s and return an axi_seq_item
 *
 * @param v - packed struct of type axi_seq_item_b_vector_s
 * @return t - an axi_seq_item
 */
function automatic void b_to_class(
   ref    axi_seq_item t,
   input  axi_seq_item_b_vector_s  v);

    axi_seq_item_b_vector_s s;

     s = v;

     t.bid   = s.bid;
     t.bresp = s.bresp;

endfunction : b_to_class

/*! \brief take values from an axi_seq_item and stuff into a axi_seq_item_ar_vector_s
 *
 * This funcion returns a ready-to-be used struct so arlen and araddr are calcuated
 * in this function.
 *
 * @param t - The axi_seq_item is passed by reference
 * @return v - packed struct of type axi_seq_item_ar_vector_s
 */
function automatic void ar_from_class(
  ref  axi_seq_item             t,
  output axi_seq_item_ar_vector_s v);

  axi_seq_item_ar_vector_s s;

  s.arid    = t.id;

  s.araddr  = axi_pkg::calculate_burst_aligned_address(.address(t.addr),
                                                  .burst_size(t.burst_size));

  s.arlen   = axi_pkg::calculate_axlen(.addr         (t.addr),
                                       .burst_size   (t.burst_size),
                                       .burst_length (t.len));

  s.arsize  = t.burst_size;
  s.arburst = t.burst_type;
  s.arlock  = t.lock;
  s.arcache = t.cache;
  s.arprot  = t.prot;
  s.arqos   = t.qos;

  `uvm_info("axi_seq_item::ar_from_class",
            $sformatf("addr:0x%0x  number_bytes: %0d, araddr:0x%0x",
                      t.addr,2**t.burst_size, s.araddr),
            UVM_HIGH)

  v = s;
endfunction : ar_from_class

/*! \brief Pull values out of a axi_seq_item_ar_vector_s and stuffs them into an axi_seq_item
 *
 * t.len is converted from arlen into a byte len. It uses burst_size (bytes per beat) * beats_per_burst to give a maximum byte length.
 * @param t - an axi_seq_item
 * @return v - a packed struct of type axi_seq_item_ar_vector_s
 */
function automatic void ar_to_class(
  ref    axi_seq_item             t,
  input  axi_seq_item_ar_vector_s v);
    axi_seq_item_ar_vector_s s;
    s = v;

    // \todo: should we detect if t==null and do something?
   // t = new();

     t.id          = s.arid;
     t.addr        = s.araddr;
     t.len         = (s.arlen+1)*(2**s.arsize);
     t.burst_size  = s.arsize;
     t.burst_type  = s.arburst;
     t.lock        = s.arlock;
     t.cache       = s.arcache;
     t.prot        = s.arprot;
     t.qos         = s.arqos;

endfunction : ar_to_class




`include "axi_agent_config.svh"

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
