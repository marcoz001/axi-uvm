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
/*! \class axi_sequencer
 *  \brief Normal sequencer with an extra analysis fifo and export
 *
 * Allows the monitor and responder to create a slave sequence where
 * we drive the slave/responder outputs.
 */
class axi_sequencer extends uvm_sequencer #(axi_seq_item);
  `uvm_component_utils(axi_sequencer)

  uvm_analysis_export   #(axi_seq_item) request_export;
  uvm_tlm_analysis_fifo #(axi_seq_item) request_fifo;


  extern function      new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);

endclass : axi_sequencer

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function axi_sequencer::new(string name, uvm_component parent);
   super.new(name, parent);
endfunction : new

/*! \brief Creates the analysis export and analysis fifo */
function void axi_sequencer::build_phase(uvm_phase phase);
    super.build_phase(phase);
    request_fifo = new("request_fifo", this);
    request_export =  new("request_export", this);
endfunction : build_phase

/*! \brief Connects the analysis export and fifo  */
function void axi_sequencer::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  request_export.connect(request_fifo.analysis_export);
endfunction : connect_phase

