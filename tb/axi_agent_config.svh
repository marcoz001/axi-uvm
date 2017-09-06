class axi_agent_config extends uvm_object;
  `uvm_object_utils(axi_agent_config)
  
  uvm_active_passive_enum m_active    = UVM_PASSIVE;
  driver_type_t           drv_type;
  
  extern function new (string name="axi_agent_config");
      
endclass : axi_agent_config

function axi_agent_config::new (string name="axi_agent_config");
  super.new(name);
endfunction : new
  