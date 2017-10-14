////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_env.svh
//
// Purpose:
//          UVM env for AXI UVM environment
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
class axi_env extends uvm_env;
  `uvm_component_utils(axi_env)


  axi_agent_config       m_agent_config;
  axi_sequencer          m_driver_seqr;
  axi_sequencer          m_responder_seqr;

  axi_agent        m_axidriver_agent;
  axi_agent        m_axiresponder_agent;

  memory           m_memory;

  extern function new (string name="axi_env", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);

endclass : axi_env

function axi_env::new (string name="axi_env", uvm_component parent=null);
  super.new(name, parent);
endfunction : new

function void axi_env::build_phase (uvm_phase phase);
  super.build_phase(phase);

  m_axidriver_agent    = axi_agent::type_id::create("m_axidriver_agent", this);
  m_axidriver_agent.m_config = axi_agent_config::type_id::create("m_axidriver_agent.m_config", this);

  m_axidriver_agent.m_config.m_active            = UVM_ACTIVE;
  m_axidriver_agent.m_config.drv_type            = e_DRIVER;
  m_axidriver_agent.m_config.bready_toggle_pattern  = 32'h0000_0001;
  m_axidriver_agent.m_config.rready_toggle_pattern  = 32'hfffF_FFFF;

  m_axiresponder_agent = axi_agent::type_id::create("m_axiresponder_agent", this);
  m_axiresponder_agent.m_config = axi_agent_config::type_id::create("m_axiresponder_agent.m_config", this);


  assert(m_axiresponder_agent.m_config.randomize()) else begin
    `uvm_error(this.get_type_name(), $sformatf("Unable to randomize %s", m_axiresponder_agent.m_config.get_name()));
  end

  m_axiresponder_agent.m_config.m_active            = UVM_ACTIVE;
  m_axiresponder_agent.m_config.drv_type            = e_RESPONDER;
 // m_axiresponder_agent.m_config.awready_toggle_mask = 32'hFFFF_FFFF;
//  m_axiresponder_agent.m_config.wready_toggle_mask  = 32'hFfFF_FFFF;

  m_memory = memory::type_id::create("m_memory", this);
  uvm_config_db #(memory)::set(null, "*", "m_memory", m_memory);
  m_axiresponder_agent.m_memory = m_memory;
  m_axidriver_agent.m_memory    = m_memory;

  // m_wb_agent = wb_agent::type_id::create("m_wb_agent", this);
endfunction : build_phase

function void axi_env::connect_phase (uvm_phase phase);
  super.connect_phase(phase);

  m_driver_seqr    = m_axidriver_agent.m_seqr;
  m_responder_seqr = m_axiresponder_agent.m_seqr;

endfunction : connect_phase
