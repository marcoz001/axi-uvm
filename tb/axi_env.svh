class axi_env extends uvm_env;
  `uvm_component_utils(axi_env)
  
  
  axi_agent_config       m_agent_config;
  axi_sequencer          m_driver_seqr;
  axi_sequencer          m_responder_seqr;

  axi_agent        m_axidriver_agent;
  axi_agent        m_axiresponder_agent;
  
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
  m_axiresponder_agent = axi_agent::type_id::create("m_axiresponder_agent", this);

    m_axidriver_agent.m_config = axi_agent_config::type_id::create("m_axidriver_agent.m_config", this);

  m_axiresponder_agent.m_config = axi_agent_config::type_id::create("m_axiresponder_agent.m_config", this);
  
  
  m_axidriver_agent.m_config.m_active            = UVM_ACTIVE;
  m_axidriver_agent.m_config.drv_type            = e_DRIVER;
  m_axidriver_agent.m_config.bready_toggle_mask  = 32'hA55A_CCCC;

  assert(m_axiresponder_agent.m_config.randomize()) else begin
    `uvm_error(this.get_type_name(), $sformatf("Unable to randomize %s", m_axiresponder_agent.m_config.get_name()));
  end
  
  m_axiresponder_agent.m_config.m_active            = UVM_ACTIVE;
  m_axiresponder_agent.m_config.drv_type            = e_RESPONDER;
  m_axiresponder_agent.m_config.awready_toggle_mask = 32'h0000_0001;
  m_axiresponder_agent.m_config.wready_toggle_mask  = 32'hFFFF_FFFF;
  
  // m_wb_agent = wb_agent::type_id::create("m_wb_agent", this);
endfunction : build_phase
  
function void axi_env::connect_phase (uvm_phase phase);
  super.connect_phase(phase);

  m_driver_seqr    = m_axidriver_agent.m_seqr;
  m_responder_seqr = m_axiresponder_agent.m_seqr;
  
endfunction : connect_phase
