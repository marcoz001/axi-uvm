class axi_if_abstract extends uvm_object;
  `uvm_object_utils(axi_if_abstract)
  
  extern function new (string name="axi_if_abstract");
  
    extern virtual task write(bit [63:0] addr, bit [7:0] data[], bit [7:0] id);
      extern virtual task read(output bit [63:0] addr, output bit [7:0] data[], output int len, output bit [7:0] id);
    extern virtual task wait_for_awvalid;
    extern virtual task wait_for_awready_awvalid;
        
    extern virtual task set_awready(bit state);
    extern virtual task set_awvalid(bit state);
    extern virtual task wait_for_clks(int cnt=1);
    extern virtual task set_awready_toggle_mask(bit [31:0] mask);
    extern virtual task clr_awready_toggle_mask();
    extern virtual task wait_for_not_in_reset;

      
endclass : axi_if_abstract;
    
function axi_if_abstract::new (string name="axi_if_abstract");  
  super.new(name);
endfunction : new
    
    
    task axi_if_abstract::write(bit [63:0] addr, bit [7:0] data[], bit [7:0] id);
  `uvm_warning(this.get_type_name(), "WARNING. Virtual function write() not defined.")
endtask : write

      task axi_if_abstract::read(output bit [63:0] addr, output bit [7:0] data[], output int len, output bit [7:0] id);
  `uvm_warning(this.get_type_name(), "WARNING. Virtual function read() not defined.")
endtask : read

    
task axi_if_abstract::wait_for_awvalid;
  `uvm_warning(this.get_type_name(), "WARNING. Virtual task wait_for_awvalid() not defined.")
endtask : wait_for_awvalid
      
      
task axi_if_abstract::wait_for_awready_awvalid;
  `uvm_warning(this.get_type_name(), "WARNING. Virtual task wait_for_awready_awvalid() not defined.")
endtask : wait_for_awready_awvalid
      
task axi_if_abstract::set_awready(bit state);
  `uvm_warning(this.get_type_name(), "WARNING. Virtual task set_awready() not defined.")
endtask : set_awready
      
task axi_if_abstract::set_awvalid(bit state);
  `uvm_warning(this.get_type_name(), "WARNING. Virtual task set_awvalid() not defined.")
endtask : set_awvalid
      
task axi_if_abstract::wait_for_clks(int cnt=1);
  `uvm_warning(this.get_type_name(), "WARNING. Virtual task wait_for_clks() not defined.")
endtask : wait_for_clks
      
task axi_if_abstract::set_awready_toggle_mask(bit [31:0] mask);
  `uvm_warning(this.get_type_name(), "WARNING. Virtual task set_awready_toggle_mask() not defined.")
endtask : set_awready_toggle_mask
      
task axi_if_abstract::clr_awready_toggle_mask();
  `uvm_warning(this.get_type_name(), "WARNING. Virtual task clr_awready_toggle_mask() not defined.")
endtask : clr_awready_toggle_mask
      
task axi_if_abstract::wait_for_not_in_reset;
  `uvm_warning(this.get_type_name(), "WARNING. Virtual task wait_for_not_in_reset() not defined.")
endtask : wait_for_not_in_reset;