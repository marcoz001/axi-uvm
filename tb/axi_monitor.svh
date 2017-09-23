////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_monitor.svh
//
// Purpose:	
//          UVM monitor for AXI UVM environment
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
class axi_monitor extends uvm_monitor;
  `uvm_component_utils(axi_monitor)
  
  uvm_analysis_port #(axi_seq_item) ap;
  
  uvm_analysis_port #(axi_seq_item) driver_activity_ap; // detect driver activity
                                                        // used to kick off slave seq
  axi_if_abstract     vif;
  axi_agent_config    m_config;

  extern function new (string name="axi_monitor", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
  extern task          run_phase                (uvm_phase phase);

endclass : axi_monitor

    
function axi_monitor::new (string name="axi_monitor", uvm_component parent=null);
  super.new(name, parent);
endfunction : new
    
function void axi_monitor::build_phase (uvm_phase phase);
  super.build_phase(phase);

  ap=new("ap", this);
  if (m_config.drv_type == e_RESPONDER) begin
     driver_activity_ap=new("driver_activity_ap", this);
  end

  vif=axi_if_abstract::type_id::create("vif", this);

endfunction : build_phase
  
function void axi_monitor::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

    
task axi_monitor::run_phase(uvm_phase phase);
   axi_seq_item             original_item;
   axi_seq_item             item;
    axi_seq_item item2;
   axi_seq_item_aw_vector_s aw_s;
  
  vif.wait_for_not_in_reset();
  original_item = axi_seq_item::type_id::create("original_item");
  original_item.len=0;
  
  forever begin
 // `uvm_info(this.get_type_name, "waiting on wait_for_awvalid()", UVM_INFO)
  //vif.wait_for_awvalid();
    // vif.wait_for_awready_awvalid();
    vif.wait_for_write_address(.s(aw_s));
    
//    vif.read_aw(.s(aw_s));
     $cast(item, original_item.clone());
//    item = axi_seq_item::type_id::create("item");

    axi_seq_item::aw_to_class(.t(item), .v(aw_s));
    item.cmd = axi_uvm_pkg::e_WRITE;
    $cast(item2, item);

 //   `uvm_info(this.get_type_name, "waiting on wait_for_awvalid() - done", UVM_INFO)
 //       `uvm_info(this.get_type_name(), 
 //                 $sformatf("axi_MONITOR %s",
 //                       item.convert2string()), 
 //             UVM_INFO)

     ap.write(item);
     
     if (m_config.drv_type == e_RESPONDER) begin
       driver_activity_ap.write(item2);
     end
     
//     vif.wait_for_clks(.cnt(1));
     
   end
endtask : run_phase
  