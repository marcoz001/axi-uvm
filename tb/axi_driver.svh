class axi_driver extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_driver)
  
  axi_if_abstract vif;
  axi_agent_config    m_config;
  
  extern function new (string name="axi_driver", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
  extern function void end_of_elaboration_phase (uvm_phase phase);
  extern task          run_phase                (uvm_phase phase);
    
  extern task          write(ref axi_seq_item item);
    
  extern task          driver_run_phase;
  extern task          responder_run_phase;
    
endclass : axi_driver    
    
function axi_driver::new (
  string        name   = "axi_driver",
  uvm_component parent = null);
  
  super.new(name, parent);
endfunction : new
    
function void axi_driver::build_phase (uvm_phase phase);
  super.build_phase(phase);
  
  vif = axi_if_abstract::type_id::create("vif", this);

endfunction : build_phase
  
function void axi_driver::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

function void axi_driver::end_of_elaboration_phase (uvm_phase phase);
  super.end_of_elaboration_phase(phase);
endfunction : end_of_elaboration_phase
    
task axi_driver::run_phase(uvm_phase phase);

  if (m_config.drv_type == e_DRIVER) begin
     driver_run_phase;
  end else if (m_config.drv_type == e_RESPONDER) begin
     responder_run_phase;
  end
  
endtask : run_phase

task axi_driver::driver_run_phase;

  axi_seq_item item;
  
    vif.set_awvalid(1'b0);
 
  
  `uvm_info(this.get_type_name(), "driver_run_phase", UVM_INFO)
  forever begin    
  
    seq_item_port.get_next_item(item);  
      if (item.cmd == WRITE) begin
         write(item);
      end else begin
        vif.read(item.addr, item.data, item.len, item.id);
      end
      `uvm_info(this.get_type_name(), $sformatf("%s", item.convert2string()), UVM_INFO)

    `uvm_info(this.get_type_name(), "waiting on driver_run_phase.item_done()", UVM_INFO)
      seq_item_port.item_done();
    `uvm_info(this.get_type_name(), "waiting on driver_run_phase.item_done() - done", UVM_INFO)
      
  end
endtask : driver_run_phase
    
task axi_driver::responder_run_phase;
  axi_seq_item item;
  
  item = axi_seq_item::type_id::create("item", this);
 
  `uvm_info(this.get_type_name(), "HEY< YOU< responder_run_phase", UVM_INFO)
  vif.set_awready_toggle_mask(m_config.awready_toggle_mask);
  
  vif.wait_for_not_in_reset();
  forever begin
    
    `uvm_info(this.get_type_name(), "waiting on get_next_item()", UVM_INFO)
    seq_item_port.get_next_item(item);  
    `uvm_info(this.get_type_name(), "waiting on get_next_item() - done", UVM_INFO)

    `uvm_info(this.get_type_name(), "waiting on wait_for_awvalid()", UVM_INFO)
    vif.wait_for_awready_awvalid();
    `uvm_info(this.get_type_name(), "waiting on wait_for_awvalid() - done", UVM_INFO)
    //$cast(item, original_item.clone());
    vif.read(.addr(item.addr), .data(item.data), .len(item.len), .id(item.id));
    `uvm_info(this.get_type_name(), $sformatf("%s", item.convert2string()), UVM_INFO)

    `uvm_info(this.get_type_name(), "waiting on responder_run_phase.item_done()", UVM_INFO)
    seq_item_port.item_done();
    `uvm_info(this.get_type_name(), "waiting on responder_run_phase.item_done() - done", UVM_INFO)
    
    
    vif.wait_for_clks(.cnt(1));
    
  end
endtask : responder_run_phase
    
    // write and read() helper functions to talk to the write() and read() functions in the interface/bfm.  Should this ever actually get used in an emulator, code changes are kept together.
task axi_driver::write(ref axi_seq_item item);
   vif.write(item.addr, item.data, item.id);
endtask : write