class axi_env extends uvm_env;
  `uvm_component_utils(axi_env)
  
  axi_sequencer m_seqr;
  axi_agent     m_axi_agent;
  
  extern function new (string name="axi_env", uvm_component parent=null);
      
  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);

endclass : axi_env
    
function axi_env::new (string name="axi_env", uvm_component parent=null);
  super.new(name, parent);
endfunction : new
    
function void axi_env::build_phase (uvm_phase phase);
  super.build_phase(phase);
 
  m_axi_agent = axi_agent::type_id::create("m_axi_agent", this);
  // m_wb_agent = wb_agent::type_id::create("m_wb_agent", this);
endfunction : build_phase
  
function void axi_env::connect_phase (uvm_phase phase);
  super.connect_phase(phase);

  m_seqr = m_axi_agent.m_seqr;
endfunction : connect_phase
