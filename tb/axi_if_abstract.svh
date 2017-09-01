class axi_if_abstract extends uvm_object;
  `uvm_object_utils(axi_if_abstract)
  
  extern function new (string name="axi_if_abstract");
  
    extern virtual task write(bit [63:0] addr, bit [7:0] data[], bit [7:0] id);
      extern virtual task read(bit [63:0] addr, bit [7:0] data[], bit [7:0] id);
  extern virtual task wait_for_awvalid;
  
endclass : axi_if_abstract;
    
function axi_if_abstract::new (string name="axi_if_abstract");  
  super.new(name);
endfunction : new
    
    
    task axi_if_abstract::write(bit [63:0] addr, bit [7:0] data[], bit [7:0] id);
  `uvm_warning(this.get_type_name(), "WARNING. Virtual function write() not defined.")
endtask : write

    task axi_if_abstract::read(bit [63:0] addr, bit [7:0] data[], bit [7:0] id);
  `uvm_warning(this.get_type_name(), "WARNING. Virtual function read() not defined.")
endtask : read

    
task axi_if_abstract::wait_for_awvalid;
  `uvm_warning(this.get_type_name(), "WARNING. Virtual function wait_for_awvalid() not defined.")
endtask : wait_for_awvalid