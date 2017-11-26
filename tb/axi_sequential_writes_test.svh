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
/*! \class axi_sequential_writes_test
 * \brief Sequential AXI writes. No pipelining.
 *
 * Send WriteAddress, then Write, then Write Response, then backdoor read
 * the memory and verify. Then repeat.
 */
class axi_sequential_writes_test extends axi_base_test;

  `uvm_component_utils(axi_sequential_writes_test)

  axi_agent_config  driver_agent_config;
  axi_agent_config  responder_agent_config;

  function new (string name="axi_sequential_writes_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);

    axi_seq::type_id::set_type_override(axi_sequential_writes_seq::get_type(), 1);

    driver_agent_config = axi_agent_config::type_id::create("driver_agent_config", this);


    assert(driver_agent_config.randomize() with {
                                                 //bready_toggle_pattern == 32'hFFFF_FFFF;
                                                 //rready_toggle_pattern == 32'hFFFF_FFFF;

                                                 // these don't matter for sequential since
                                                 // they wont be back to back
                                                 min_clks_between_ar_transfers == 0;
                                                 max_clks_between_ar_transfers == 3;
                                                 min_clks_between_aw_transfers == 0;
                                                 max_clks_between_aw_transfers == 3;
                                                 min_clks_between_w_transfers  == 0;
                                                 max_clks_between_w_transfers  == 3;
                                              });

    driver_agent_config.m_active            = UVM_ACTIVE;
    driver_agent_config.drv_type            = e_DRIVER;


    //driver_agent_config.wvalid              = new[2];
    //driver_agent_config.wvalid[0]           = 1'b1;
    //driver_agent_config.wvalid[1]           = 1'b0;


    //  Put the agent_config handle into config_db
    uvm_config_db #(axi_agent_config)::set(null, "*", "m_axidriver_agent.m_config", driver_agent_config);


    responder_agent_config = axi_agent_config::type_id::create("responder_agent_config", this);


  assert(responder_agent_config.randomize() with {
                                                  //awready_toggle_pattern == 32'hFFFF_FFFF;
                                                  // wready_toggle_pattern == 32'hFFFF_FFFF;
                                                  //arready_toggle_pattern == 32'hFFFF_FFFF;

                                                  min_clks_between_r_transfers == 0;
                                                  max_clks_between_r_transfers == 3;
                                                  min_clks_between_b_transfers == 0;
                                                  max_clks_between_b_transfers == 3;

                                                  });

  responder_agent_config.m_active            = UVM_ACTIVE;
  responder_agent_config.drv_type            = e_RESPONDER;
  //responder_agent_config.axi_incompatible_wvalid_toggling_mode=1;



  //  Put the agent_config handle into config_db
    uvm_config_db #(axi_agent_config)::set(null, "*", "m_axiresponder_agent.m_config", responder_agent_config);



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


endclass : axi_sequential_writes_test
