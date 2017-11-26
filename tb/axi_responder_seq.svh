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
