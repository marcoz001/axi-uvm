class axi_agent_config extends uvm_object;
  `uvm_object_utils(axi_agent_config)
  
  uvm_active_passive_enum m_active    = UVM_PASSIVE;
  driver_type_t           drv_type;
  
  // Use toggle patterns. The interface can directly handle all the ready* toggling
  // without requiring the driver.
  rand bit[31:0] awready_toggle_mask;
  rand bit[31:0]  wready_toggle_mask;
  rand bit[31:0]  bready_toggle_mask;
  
  extern function new (string name="axi_agent_config");
      
endclass : axi_agent_config

function axi_agent_config::new (string name="axi_agent_config");
  super.new(name);
endfunction : new
  