////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017, Matt Dew @ Dew Technologies, LLC
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
/*! \class axi_responder_seq
 *  \brief Forever running sequence that setups up responder *ready toggle patterns, then receives TLM packet from monitor and sends to responder.
 */
class axi_responder_seq extends axi_seq;

  `uvm_object_utils(axi_responder_seq)

  `uvm_declare_p_sequencer (axi_sequencer)


  logic [7:0] mem [];

  extern function   new (string name="axi_responder_seq");
  extern task       body;

endclass : axi_responder_seq

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function axi_responder_seq::new (string name="axi_responder_seq");
  super.new(name);
endfunction : new

/*! \brief Does all the work.
 *
 * -# Creates constrained random awready toggle pattern
 * -# Sends it
 * -# Creates constrained random wready toggle pattern
 * -# Sends it
 * -# Creates constrained random arready toggle pattern
 * -# Sends it
 * -# In a forever loop,
 *       waits for TLM packets from monitor
 *       sends them on to responder
 */
task axi_responder_seq::body;
     axi_seq_item drv_item;
     axi_seq_item item;

  `uvm_info(this.get_type_name(), "YO~! starting responder_seq", UVM_HIGH)

     forever begin
       // recommended by verilab but doesn't
       // this break the child-doesn't-know-about-parent model?

       // Get from monitor (or wherever)

       p_sequencer.request_fifo.get(drv_item);


              `uvm_info(this.get_type_name(),
                 $sformatf(" <-HEY0HEY0HEY0 -> %s",
                           drv_item.convert2string()),
                 UVM_HIGH)
       // SEnd to responder

       start_item(drv_item);
       finish_item(drv_item);

       `uvm_info(this.get_type_name(),
                 $sformatf(" <-HEY1HEY1HEY1 -> %s",
                           drv_item.convert2string()),
                 UVM_HIGH)
     end

endtask : body
