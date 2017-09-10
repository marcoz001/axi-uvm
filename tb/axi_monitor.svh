class axi_monitor extends uvm_monitor;
  `uvm_component_utils(axi_monitor)
  
  uvm_analysis_port #(axi_seq_item) ap;
  
  uvm_analysis_port #(axi_seq_item) driver_activity_ap; // detect driver activity
                                                        // used to kick off slave seq
  axi_if_abstract     vif;
  axi_agent_config    m_config;

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
  if (m_config.drv_type == e_RESPONDER) begin
     driver_activity_ap=new("driver_activity_ap", this);
  end

  vif=axi_if_abstract::type_id::create("vif", this);

endfunction : build_phase
  
function void axi_monitor::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

    
task axi_monitor::run_phase(uvm_phase phase);
   axi_seq_item original_item;
   axi_seq_item item;
  
  vif.wait_for_not_in_reset();
  original_item = axi_seq_item::type_id::create("original_item");
   forever begin
     vif.wait_for_awready_awvalid();
     `uvm_info(this.get_type_name, "YO, detected an awvalid", UVM_HIGH)

     $cast(item, original_item.clone());
     ap.write(item);
     
     if (m_config.drv_type == e_RESPONDER) begin
       driver_activity_ap.write(item);
     end
     
     vif.wait_for_clks(.cnt(1));
     
   end
endtask : run_phase
  