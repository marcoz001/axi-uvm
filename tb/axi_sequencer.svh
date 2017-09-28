////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_sequencer.svh
//
// Purpose:
//          UVM sequencer for AXI UVM environment
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
class axi_sequencer extends uvm_sequencer #(axi_seq_item);
  `uvm_component_utils(axi_sequencer)

  uvm_analysis_export   #(axi_seq_item) request_export;
  uvm_tlm_analysis_fifo #(axi_seq_item) request_fifo;


  extern function      new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);

endclass : axi_sequencer


function axi_sequencer::new(string name, uvm_component parent);
   super.new(name, parent);
endfunction : new

function void axi_sequencer::build_phase(uvm_phase phase);
    super.build_phase(phase);
    request_fifo = new("request_fifo", this);
    request_export =  new("request_export", this);
endfunction : build_phase

function void axi_sequencer::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  request_export.connect(request_fifo.analysis_export);
endfunction : connect_phase

