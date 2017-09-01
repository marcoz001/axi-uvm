class axi_coveragecollector extends uvm_subscriber #(axi_seq_item);
  
  `uvm_component_utils(axi_coveragecollector)
  
    
  extern function new(string name="axi_coveragecollector", uvm_component parent=null);
  extern virtual function void write(axi_seq_item t);
    
endclass : axi_coveragecollector
    
function axi_coveragecollector::new(string name="axi_coveragecollector", uvm_component parent=null);
   super.new(name, parent);
endfunction : new
    
function void axi_coveragecollector::write(axi_seq_item t);
        `uvm_info(this.get_type_name(), $sformatf("%s", t.convert2string()), UVM_INFO)
endfunction : write
      