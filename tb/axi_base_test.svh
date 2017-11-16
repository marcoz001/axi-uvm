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
/*! \class axi_base_test
 * \brief base test.  AXI tests are to be extended from this test.
 *
 * This test creates the driver sequence and the responder sequence.
 * Tests that extend this, can type_override to change the sequence.
 * // \todo: what if want to restart a seq?
 */
class axi_base_test extends uvm_test;

  `uvm_component_utils(axi_base_test)

  axi_env m_env;
  axi_seq m_seq;
  axi_responder_seq  m_resp_seq;

  //memory m_memory;

  function new (string name="axi_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);

    int transactions;

    super.build_phase(phase);

    m_env = axi_env::type_id::create("m_env", this);

    m_seq = axi_seq::type_id::create("m_seq");

    if ($value$plusargs("transactions=%d", transactions)) begin
    `uvm_info("plusargs", $sformatf("TRANSACTIONS: %0d", transactions), UVM_INFO)
       m_seq.set_transaction_count(transactions);
  end



    m_resp_seq = axi_responder_seq::type_id::create("m_resp_seq");

   //if (!uvm_config_db #(memory)::get(null, "", "m_memory", m_memory)) begin
   //    `uvm_fatal(this.get_type_name,
   //               "Unable to fetch m_memory from config db.")
  //  end

    //max_burst_size=$clog2(data_width/8);

  endfunction : build_phase

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    fork
       m_resp_seq.start(m_env.m_responder_seqr);
    join_none

    m_seq.start(m_env.m_driver_seqr);

    phase.drop_objection(this);
  endtask : run_phase


endclass : axi_base_test
