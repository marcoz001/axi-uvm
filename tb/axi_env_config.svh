class axi_env_config extends uvm_object;
  `uvm_object_utils(axi_env_config)
  
  extern function new (string name="axi_env_config");
    
endclass : axi_env_config
    
function axi_env_config::new (string name="axi_env_config");
  super.new(name);
endfunction : new
  