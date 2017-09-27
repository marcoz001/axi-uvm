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
     axi_seq_item item;

   item = axi_seq_item::type_id::create("item");

  
  `uvm_info(this.get_type_name(), "YO~! starting responder_seq", UVM_INFO)
     
    // set up toggle pattern in responder
       item.toggle_pattern = 32'h5A30_C123;
       item.toggle_pattern = 32'hFFFF_FFFF;
       item.toggle_pattern = 32'h5555_5555;
//       item.toggle_pattern = 32'h0000_0001;

  item.cmd            = e_SETAWREADYTOGGLEPATTERN;
       start_item(item);
       finish_item(item);
  
  

     forever begin
       // recommended by verilab but doesn't
       // this break the child-doesn't-know-about-parent model?
       p_sequencer.request_fifo.get(drv_item); 

       start_item(drv_item);
       finish_item(drv_item);
       `uvm_info(this.get_type_name(), 
                 $sformatf(" <-HEY0HEY0HEY0 -> %s", 
                           drv_item.convert2string()), 
                 UVM_INFO)
     end
  
endtask : body
    