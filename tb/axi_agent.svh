////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_agent.sv
//
// Purpose:	
//          UVM agent for AXI UVM environment
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
class axi_agent extends uvm_agent;
  `uvm_component_utils(axi_agent)
  
  uvm_analysis_port #(axi_seq_item) ap;
  
  
  axi_agent_config    m_config;
  axi_driver          m_driver;
  axi_monitor         m_monitor;
  axi_sequencer       m_seqr;
  axi_coveragecollector m_coveragecollector;
  memory              m_memory;
  
  extern function new (string name="axi_agent", uvm_component parent=null);
  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
      
endclass : axi_agent
     
function axi_agent::new (string name="axi_agent", uvm_component parent=null);
  super.new(name, parent);
endfunction : new
    
function void axi_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  if (m_config == null) begin
    if (!uvm_config_db #(axi_agent_config)::get(this, "", "m_config", m_config)) begin
      `uvm_info(this.get_type_name, "Unable to fetch axi_agent_config from config db. Using defaults", UVM_INFO)
    end 
    // Create config object. 
    m_config = axi_agent_config::type_id::create("m_config", this);
    
  end
  
  ap = new("ap", this);
  
  if (m_config.m_active == UVM_ACTIVE) begin
     m_driver  = axi_driver::type_id::create("m_driver",  this);
     m_seqr    = axi_sequencer::type_id::create("m_seqr", this);

     m_driver.m_config = m_config;
    
  end

  m_monitor = axi_monitor::type_id::create("m_monitor", this);
  m_monitor.m_config=m_config;
  m_coveragecollector = axi_coveragecollector::type_id::create("m_coveragecollector", this);

  if (m_config.drv_type == axi_uvm_pkg::e_RESPONDER) begin
     m_memory = memory::type_id::create("m_memory", this);
     m_monitor.m_memory = m_memory;
  end
endfunction : build_phase
    
function void axi_agent::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
  
  if (m_config.m_active == UVM_ACTIVE) begin
   m_driver.seq_item_port.connect(m_seqr.seq_item_export);
  end
  
  m_monitor.ap.connect(m_coveragecollector.analysis_export);
  m_monitor.ap.connect(ap);

  if (m_config.drv_type == e_RESPONDER) begin
    m_monitor.driver_activity_ap.connect(m_seqr.request_export); 
  end

endfunction : connect_phase
