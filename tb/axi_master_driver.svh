class axi_master_driver extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_master_driver)
  
  axi_if_abstract vif;

  
  extern function new (string name="axi_master_driver", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
  extern function void end_of_elaboration_phase (uvm_phase phase);
  extern task          run_phase                (uvm_phase phase);
    
  extern task          write(ref axi_seq_item item);
    
endclass : axi_master_driver    
    
function axi_master_driver::new (
  string        name   = "axi_master_driver",
  uvm_component parent = null);
  
  super.new(name, parent);
endfunction : new
    
function void axi_master_driver::build_phase (uvm_phase phase);
  super.build_phase(phase);
  
  vif = axi_if_abstract::type_id::create("vif", this);

endfunction : build_phase
  
function void axi_master_driver::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

function void axi_master_driver::end_of_elaboration_phase (uvm_phase phase);
  super.end_of_elaboration_phase(phase);
endfunction : end_of_elaboration_phase
    
task axi_master_driver::run_phase(uvm_phase phase);

    axi_seq_item item;
        
    forever begin    
      seq_item_port.get_next_item(item);  
      if (item.cmd == WRITE) begin
         write(item);
      end else begin
        vif.read(item.addr, item.data, item.id);
      end
      `uvm_info(this.get_type_name(), $sformatf("%s", item.convert2string()), UVM_INFO)

      seq_item_port.item_done();
      
    end
    
endtask : run_phase
    
    
    
    // write and read() helper functions to talk to the write() and read() functions in the interface/bfm.  Should this ever actually get used in an emulator, code changes are kept together.
    
    task axi_master_driver::write(ref axi_seq_item item);
      
      vif.write(item.addr, item.data, item.id);
      
endtask : write