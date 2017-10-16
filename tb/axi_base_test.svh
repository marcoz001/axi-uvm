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
 */
class axi_base_test extends uvm_test;
  
  `uvm_component_utils(axi_base_test)
  
  axi_env m_env;
  axi_seq m_seq;
  axi_responder_seq  m_resp_seq  ;
  
  function new (string name="axi_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    m_env = axi_env::type_id::create("m_env", this);
    
    m_seq = axi_seq::type_id::create("m_seq");
    m_resp_seq = axi_responder_seq::type_id::create("m_resp_seq");
    
    
  endfunction : build_phase
  
  task run_phase(uvm_phase phase);
        phase.raise_objection(this);

    #200

    fork
        m_resp_seq.start(m_env.m_responder_seqr);
    join_none

    #800
    //fork
      m_seq.start(m_env.m_driver_seqr);
    //join_none
    
    #2000
    
     phase.drop_objection(this);
  endtask : run_phase
  
  
endclass : axi_base_test