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
/*! \class axi_agent
 *  \brief Encapsulates driver, monitor, coverage collector, a local memory
 *
 * A configuration object, axi_agent_config contains all the information needed
 * by this agent to:
 * - Be active (drive signals) or passive (just listen like a monitor)
 * - Enable driver and sequencer
 * - Enable a master driver or slave driver (responder)
 * - Enable coverage collector
 * - Enable scoreboard
 */
class axi_agent extends uvm_agent;
  `uvm_component_utils(axi_agent)

  uvm_analysis_port #(axi_seq_item) ap;

  axi_agent_config    m_config;
  axi_driver          m_driver;
  axi_responder       m_responder;
  axi_monitor         m_monitor;
  axi_scoreboard      m_scoreboard;

  axi_sequencer       m_seqr;
  axi_coveragecollector m_coveragecollector;
  memory              m_memory;  /*!< Local memory pointer.  Can point to global if desired */

  extern function new (string name="axi_agent", uvm_component parent=null);
  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);

endclass : axi_agent

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function axi_agent::new (string name="axi_agent", uvm_component parent=null);
  super.new(name, parent);
endfunction : new

/*! \brief Create sub-components as configured
 *
 * Look for a config object,if one isn't found in the uvm_config_db then create one
 * and use its defauls for configuring.
 */
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
     if (m_config.drv_type  == e_DRIVER) begin
        m_driver     = axi_driver::type_id::create("m_driver",  this);
        m_driver.m_config = m_config;
        m_driver.m_memory = m_memory;
     end else begin
        m_responder  = axi_responder::type_id::create("m_responder",  this);
        m_responder.m_config = m_config;
        m_responder.m_memory = m_memory;
     end
  end
     m_seqr    = axi_sequencer::type_id::create("m_seqr", this);


  m_monitor = axi_monitor::type_id::create("m_monitor", this);
  m_monitor.m_config=m_config;
  if (m_config.has_scoreboard == 1'b1) begin
     m_scoreboard = axi_scoreboard::type_id::create("m_scoreboard", this);
  end
  if (m_config.has_coverage == 1'b1) begin
     m_coveragecollector = axi_coveragecollector::type_id::create("m_coveragecollector", this);
  end
  // \todo: every agent has memory?
  m_monitor.m_memory = m_memory;
endfunction : build_phase

function void axi_agent::connect_phase (uvm_phase phase);
   super.connect_phase(phase);

   if (m_config.m_active == UVM_ACTIVE) begin
      if (m_config.drv_type  == e_DRIVER) begin
         m_driver.seq_item_port.connect(m_seqr.seq_item_export);
      end else begin
         m_responder.seq_item_port.connect(m_seqr.seq_item_export);
         m_monitor.driver_activity_ap.connect(m_seqr.request_export);

      end
  end

  if (m_config.has_scoreboard == 1'b1) begin
     m_monitor.ap.connect(m_scoreboard.analysis_export);
  end

  if (m_config.has_coverage == 1'b1) begin
     m_monitor.ap.connect(m_coveragecollector.analysis_export);
  end

  m_monitor.ap.connect(ap);

endfunction : connect_phase
