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
/*! \class axi_scoreboard
 *  \brief scoreboard
 *
 * Tracks number of Write Address transactions and Write Response transactions
 *
 */
class axi_scoreboard extends uvm_subscriber #(axi_seq_item);
  `uvm_component_utils(axi_scoreboard)



  extern function new (string name="axi_scoreboard", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
  extern task          run_phase                (uvm_phase phase);


  extern virtual function void write                    (axi_seq_item t);

  int write_address_cntr=0;
  int write_response_cntr=0;

endclass : axi_scoreboard

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function axi_scoreboard::new (string name="axi_scoreboard", uvm_component parent=null);
  super.new(name, parent);
endfunction : new

/*! \brief currently does nothing
 *
 * Doesn't actually do anything except call parent build_phase */
function void axi_scoreboard::build_phase (uvm_phase phase);
  super.build_phase(phase);
endfunction : build_phase

/*! \brief currently does nothing
 *
 * Doesn't actually do anything except call parent connect_phase */
function void axi_scoreboard::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

/*! \brief currently does nothing
 *
 */
task axi_scoreboard::run_phase(uvm_phase phase);
endtask : run_phase

/*! \brief Updates counters
 *
 * Currently just updates two counters. */
function void axi_scoreboard::write(axi_seq_item t);
  `uvm_info("SCOREBOARD", $sformatf("%s", t.convert2string()), UVM_HIGH)

  case(t.cmd)
     e_WRITE : begin
       write_address_cntr++;
       `uvm_info("SCOREBOARD",
                 $sformatf("write_address_cntr=%0d", write_address_cntr),
                 UVM_HIGH)
     end
     e_WRITE_RESPONSE : begin
       write_response_cntr++;
       `uvm_info("SCOREBOARD",
                 $sformatf("write_response_cntr=%0d", write_response_cntr),
                 UVM_HIGH)

     end

  endcase

endfunction : write
