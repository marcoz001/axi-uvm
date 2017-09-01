class axi_monitor extends uvm_monitor;
  `uvm_component_utils(axi_monitor)
  
  uvm_analysis_port #(axi_seq_item) ap;
  
  axi_if_abstract vif;

  extern function new (string name="axi_monitor", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
  extern task          run_phase                (uvm_phase phase);

endclass : axi_monitor

    
function axi_monitor::new (string name="axi_monitor", uvm_component parent=null);
  super.new(name, parent);
endfunction : new
    
function void axi_monitor::build_phase (uvm_phase phase);
  super.build_phase(phase);

  ap=new("ap", this);
  vif=axi_if_abstract::type_id::create("vif", this);
endfunction : build_phase
  
function void axi_monitor::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

    
task axi_monitor::run_phase(uvm_phase phase);
   axi_seq_item original_item;
   axi_seq_item item;
  
  original_item = axi_seq_item::type_id::create("original_item");
   forever begin
      vif.wait_for_awvalid;
     `uvm_info(this.get_type_name, "YO, detected an awvalid", UVM_INFO)

     $cast(item, original_item.clone());
     ap.write(item);
     
   end
endtask : run_phase
  