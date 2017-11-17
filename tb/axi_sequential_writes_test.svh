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
/*! \class axi_sequential_writes_test
 * \brief Sequential AXI writes. No pipelining.
 *
 * Send WriteAddress, then Write, then Write Response, then backdoor read
 * the memory and verify. Then repeat.
 */
class axi_sequential_writes_test extends axi_base_test;

  `uvm_component_utils(axi_sequential_writes_test)

  function new (string name="axi_sequential_writes_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);

    axi_seq::type_id::set_type_override(axi_sequential_writes_seq::get_type(), 1);

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
