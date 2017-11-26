////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017, Matt Dew @ Dew Technologies, LLC
//
// This program is free software (logic verification): you can redistribute it
// and/or modify it under the terms of the GNU Lesser General Public License (LGPL)
// as published by the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
// for more details.
//
// License:	LGPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/lgpl.html
//
//
// Author's intent:  If you use this AXI verification code and find or fix bugs
//                   or make improvements, then share those fixes or improvements.
//                   If you use this in a bigger project, I don't care about,
//                   or want, any changes or code outside this block.
//                   Example: If you use this in an SoC simulation/testbench
//                            I don't want, or care about, your SoC or other blocks.
//                            I just care about the enhancements to these AXI files.
//                   That's why I have choosen the LGPL instead of the GPL.
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



  bit    rvalid [];
  bit    wvalid [];

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
  rand byte min_clks_between_aw_transfers=0;
  rand byte max_clks_between_aw_transfers=0;

  rand byte min_clks_between_w_transfers=0;
  rand byte max_clks_between_w_transfers=0;

  rand byte min_clks_between_b_transfers=0;
  rand byte max_clks_between_b_transfers=0;

  rand byte min_clks_between_ar_transfers=0;
  rand byte max_clks_between_ar_transfers=0;

  rand byte min_clks_between_r_transfers=0;
  rand byte max_clks_between_r_transfers=0;


  // AXI spec, A3.2.2,  states once valid is asserted,it must stay asserted until
  // ready asserts.  These varibles let us toggle valid to beat on the ready/valid
  // logic
  bit axi_incompatible_awvalid_toggling_mode=0;
  bit  axi_incompatible_wvalid_toggling_mode=0;
  bit  axi_incompatible_bvalid_toggling_mode=0;
  //bit axi_incompatible_arvalid_toggling_mode=0;
  bit  axi_incompatible_rvalid_toggling_mode=0;
// \todo:issing ar toggling mode

  // Prevent ready and valid not overlapping, which results in data never sending,
  // which hangs the sim.
  byte clks_without_wvalid_or_wready_max=25;
  byte clks_without_rvalid_or_rready_max=25;


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
