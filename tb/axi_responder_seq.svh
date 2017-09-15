////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_responder_seq.svh
//
// Purpose:	
//          UVM responder sequence for AXI UVM environment
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
class axi_responder_seq extends axi_seq; 
    
  `uvm_object_utils(axi_responder_seq)
  
  `uvm_declare_p_sequencer (axi_sequencer)
  
  
  logic [7:0] mem [];
  
  extern function   new (string name="axi_responder_seq");
  extern task       body;

endclass : axi_responder_seq
    
    function axi_responder_seq::new (string name="axi_responder_seq");
  super.new(name);
endfunction : new
    
task axi_responder_seq::body;
     axi_seq_item drv_item;

  axi_seq_item original_item;
     axi_seq_item item;
 
     original_item=axi_seq_item::type_id::create("original_item");
  item=axi_seq_item::type_id::create("item");
  
  `uvm_info(this.get_type_name(), "YO~! starting responder_seq", UVM_INFO)
     
     forever begin
       // $cast(item, original_item.clone());
//       `uvm_info(this.get_type_name(), "waiting on p_sequencer", UVM_INFO)
       p_sequencer.request_fifo.get(drv_item); 
       // recommended by verilab but doesn't
       // this break the child-doesn't-know-about-parent model?
       
//       `uvm_info(this.get_type_name(), "waiting on p_sequencer - done", UVM_HIGH)

 //      `uvm_info(this.get_type_name(), "start_item()", UVM_HIGH)
       start_item(item);
 //      item.randomize();
 //      `uvm_info(this.get_type_name(), "start_item() - done", UVM_INFO)
 //      item.addr=64'hBABE_BAEB;
 //      `uvm_info(this.get_type_name(), $sformatf(" <-HEY0HEY0HEY0 -> %s", item.convert2string()), UVM_INFO)
 //      `uvm_info(this.get_type_name(), "finish_item()", UVM_INFO)

       finish_item(item);
 //      `uvm_info(this.get_type_name(), "finish_item() - done", UVM_INFO)

  //     `uvm_info(this.get_type_name(), $sformatf(" <-HEYHEYHEY -> %s", item.convert2string()), UVM_INFO)
     end
  
endtask : body
    