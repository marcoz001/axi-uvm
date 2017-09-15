////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_agent_config.svh
//
// Purpose:	
//          UVM agent configuration object for AXI UVM environment
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
class axi_agent_config extends uvm_object;
  `uvm_object_utils(axi_agent_config)
  
  uvm_active_passive_enum m_active    = UVM_PASSIVE;
  driver_type_t           drv_type;
  
  // Use toggle patterns. The interface can directly handle all the ready* toggling
  // without requiring the driver.
  rand bit[31:0] awready_toggle_mask;
  rand bit[31:0]  wready_toggle_mask;
  rand bit[31:0]  bready_toggle_mask;
  
  extern function new (string name="axi_agent_config");
      
endclass : axi_agent_config

function axi_agent_config::new (string name="axi_agent_config");
  super.new(name);
endfunction : new
  