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
/*! \class axi_pipelined_reads_test
 * \brief Pipelined AXI reads.
 *
 * Send multiple WriteAddress transfers, then wait for all the write data and write
 * resposes to finish. Verify memory as each write responses returns.
 */
class axi_pipelined_reads_test extends axi_base_test;

  `uvm_component_utils(axi_pipelined_reads_test)


  axi_agent_config  driver_agent_config;
  axi_agent_config  responder_agent_config;

  function new (string name="axi_pipelined_reads_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);


  driver_agent_config = axi_agent_config::type_id::create("driver_agent_config", this);


  assert(driver_agent_config.randomize() with {
                                             //  bready_toggle_pattern == 32'hFFFF_FFFF;
                                             //  rready_toggle_pattern == 32'hFFFF_FFFF;

                                               min_clks_between_ar_transfers == 0;
                                               max_clks_between_ar_transfers == 3;
                                               min_clks_between_aw_transfers == 0;
                                               max_clks_between_aw_transfers == 3;
                                               min_clks_between_w_transfers  == 0;
                                               max_clks_between_w_transfers  == 3;
                                              });

  driver_agent_config.m_active            = UVM_ACTIVE;
  driver_agent_config.drv_type            = e_DRIVER;

  //  Put the agent_config handle into config_db
  uvm_config_db #(axi_agent_config)::set(null, "*", "m_axidriver_agent.m_config", driver_agent_config);


  responder_agent_config = axi_agent_config::type_id::create("responder_agent_config", this);


  assert(responder_agent_config.randomize() with {
                                                 // awready_toggle_pattern == 32'hFFFF_FFFF;
                                                 //  wready_toggle_pattern == 32'hFFFF_FFFF;
                                                 // arready_toggle_pattern == 32'hFFFF_FFFF;

                                                  min_clks_between_r_transfers == 0;
                                                  max_clks_between_r_transfers == 3;
                                                  min_clks_between_b_transfers == 0;
                                                  max_clks_between_b_transfers == 3;

                                                  });

  responder_agent_config.m_active            = UVM_ACTIVE;
  responder_agent_config.drv_type            = e_RESPONDER;

  //  Put the agent_config handle into config_db
    uvm_config_db #(axi_agent_config)::set(null, "*", "m_axiresponder_agent.m_config", responder_agent_config);


    axi_seq::type_id::set_type_override(axi_pipelined_reads_seq::get_type(), 1);

    super.build_phase(phase);

  endfunction : build_phase

  task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    fork
       m_resp_seq.start(m_env.m_responder_seqr);
    join_none

    m_seq.start(m_env.m_driver_seqr);


     phase.drop_objection(this);
  endtask : run_phase


endclass : axi_pipelined_reads_test
