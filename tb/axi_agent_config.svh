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
/*! \class axi_agent_config
 *  \brief Configuration object for an axi_agent.
 *
 * Contains all the information needed for an agent to:
 * - Be active (drive signals) or passive (just listen like a monitor)
 * - Enable driver and sequencer
 * - Enable a master driver or slave driver (responder)
 * - Enable coverage collector
 * - Enable scoreboard
 */
class axi_agent_config extends uvm_object;
  `uvm_object_utils(axi_agent_config)

  //defaults
  uvm_active_passive_enum m_active       = UVM_PASSIVE; /*!< Active or passive */
  driver_type_t           drv_type       = e_DRIVER; /*<! Driver or responder */

  bit                     has_scoreboard = 1'b1; /*<! Enable scoreboard? */
  bit                     has_coverage   = 1'b1; /*<! Turn on coverage collection? */

  // Use toggle patterns. The interface can directly handle all the ready* toggling
  // without requiring the driver.
  // Keep it to where in the future the responder sequences could do this by
  // directly toggling the *ready signals
  // used if master driver
  rand bit[31:0]  bready_toggle_pattern;
  rand bit[31:0]  rready_toggle_pattern;

  // used if slave driver / responder
  rand bit[31:0]  awready_toggle_pattern;
  rand bit[31:0]  wready_toggle_pattern;
  rand bit[31:0]  arready_toggle_pattern;
  
  // If multiple write transfers are queued,
  // this allows easily testing back to back or pausing between write address transfers.
  int min_clks_between_aw_transfers=1;
  int max_clks_between_aw_transfers=2;

  int min_clks_between_w_transfers=1;
  int max_clks_between_w_transfers=1;

  int min_clks_between_b_transfers=0;
  int max_clks_between_b_transfers=0;

  // AXI spec, A3.2.2,  states once valid is asserted,it must stay asserted until
  // ready asserts.  These varibles let us toggle valid to beat on the ready/valid
  // logic
  bit axi_incompatible_awready_toggling_mode=0;
  bit axi_incompatible_wready_toggling_mode=0;
  bit axi_incompatible_bready_toggling_mode=0;
  bit axi_incompatible_rready_toggling_mode=0;
// \todo:issing ar toggling mode

  int min_clks_between_ar_transfers=0;
  int max_clks_between_ar_transfers=0;

  int min_clks_between_r_transfers=0;
  int max_clks_between_r_transfers=10;

   //
   // If multiple write transfers are queued,
   // this allows easily testing back to back or pausing between write address transfers.


  extern function new (string name="axi_agent_config");

endclass : axi_agent_config

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function axi_agent_config::new (string name="axi_agent_config");
  super.new(name);
endfunction : new
