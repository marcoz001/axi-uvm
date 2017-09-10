class axi_driver extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_driver)
  
  axi_if_abstract vif;
  axi_agent_config    m_config;
  
  mailbox driver_writeaddress_mbx  = new(0);  //unbounded mailboxes
  mailbox driver_writedata_mbx     = new(0);
  mailbox driver_writeresponse_mbx = new(0);

  // probably unnecessary but
  // having different variables
  // makes it easier for me to follow (less confusing)
  mailbox responder_writeaddress_mbx  = new(0);  //unbounded mailboxes
  mailbox responder_writedata_mbx     = new(0);
  mailbox responder_writeresponse_mbx = new(0);

  
  extern function new (string name="axi_driver", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
  extern function void end_of_elaboration_phase (uvm_phase phase);
  extern task          run_phase                (uvm_phase phase);
    
  extern task          write(ref axi_seq_item item);
    
    
  extern task          driver_run_phase;
  extern task          responder_run_phase;
    
  extern task          driver_write_address;
  extern task          driver_write_data;
  extern task          driver_write_response;

  extern task          responder_write_address;
  extern task          responder_write_data;
  extern task          responder_write_response;

    
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
    vif.set_wvalid(1'b0);

    vif.set_bready_toggle_mask(m_config.bready_toggle_mask);

  
  fork
    driver_write_address();
    driver_write_data();
    driver_write_response();
  join_none
  
  `uvm_info(this.get_type_name(), "driver_run_phase", UVM_INFO)
  forever begin    
  
    seq_item_port.get_next_item(item);  
    if (item.cmd == e_WRITE) begin
      driver_writeaddress_mbx.put(item);
//         write(item);
      //end else begin
      //  vif.read(item.addr, item.data, item.len, item.id);
      end
      `uvm_info(this.get_type_name(), $sformatf("%s", item.convert2string()), UVM_INFO)

    //`uvm_info(this.get_type_name(), "waiting on driver_run_phase.item_done()", UVM_INFO)
      seq_item_port.item_done();
    //`uvm_info(this.get_type_name(), "waiting on driver_run_phase.item_done() - done", UVM_INFO)
    `uvm_info(this.get_type_name(), "waiting on driver_run_phase.seq_item_port.put() ", UVM_INFO)
    #500ns 
    
    seq_item_port.put(item);  
    `uvm_info(this.get_type_name(), "waiting on driver_run_phase.seq_item_port.put() - done", UVM_INFO)
      
  end
endtask : driver_run_phase
    
task axi_driver::responder_run_phase;
  axi_seq_item item;
  
  item = axi_seq_item::type_id::create("item", this);

  
    fork
    responder_write_address();
    responder_write_data();
    responder_write_response();
  join_none

  
  //`uvm_info(this.get_type_name(), "HEY< YOU< responder_run_phase", UVM_INFO)
  vif.set_awready_toggle_mask(m_config.awready_toggle_mask);
  vif.set_wready_toggle_mask(m_config.wready_toggle_mask);
  vif.set_bvalid(1'b0);
  
  vif.wait_for_not_in_reset();
  forever begin
    
   // `uvm_info(this.get_type_name(), "waiting on get_next_item()", UVM_INFO)
    seq_item_port.get_next_item(item);  
   // `uvm_info(this.get_type_name(), "waiting on get_next_item() - done", UVM_INFO)

   // `uvm_info(this.get_type_name(), "waiting on wait_for_awvalid()", UVM_INFO)
    vif.wait_for_awready_awvalid();
   // `uvm_info(this.get_type_name(), "waiting on wait_for_awvalid() - done", UVM_INFO)
    //$cast(item, original_item.clone());
    `uvm_info(this.get_type_name(), $sformatf("DRVa: %s", item.convert2string()), UVM_INFO)

    //vif.read(.addr(item.addr), .data(item.data), .len(item.len), .id(item.id));
    //vif.write_data(
    //write(item);
   // `uvm_info(this.get_type_name(), $sformatf("DRVb: %s", item.convert2string()), UVM_INFO)

   // `uvm_info(this.get_type_name(), "waiting on responder_run_phase.item_done()", UVM_INFO)
    seq_item_port.item_done();
   // `uvm_info(this.get_type_name(), "waiting on responder_run_phase.item_done() - done", UVM_INFO)
    `uvm_info(this.get_type_name(), "waiting on responder_run_phase.seq_item_port.put() ", UVM_INFO)
responder_writeaddress_mbx.put(item);
//responder_writeresponse_mbx.get(item);
//    seq_item_port.put(item);  
    `uvm_info(this.get_type_name(), "waiting on responder_run_phase.seq_item_port.put() - done", UVM_INFO)
    
    vif.wait_for_clks(.cnt(1));
    
  end
endtask : responder_run_phase
    
    // write and read() helper functions to talk to the write() and read() functions in the interface/bfm.  Should this ever actually get used in an emulator, code changes are kept together.
/*

task axi_driver::write(ref axi_seq_item item);
  axi_seq_item_aw_vector_s v;
  
  axi_seq_item::aw_from_class(.t(item), .v(v));
  vif.write_aw(.s(v));
  
    
   //vif.write(item.addr, item.data, item.id);
endtask : write
*/  
    
task axi_driver::driver_write_address;
  
  axi_seq_item item;
  axi_seq_item_aw_vector_s v;
  
  forever begin
     // grab next address
     driver_writeaddress_mbx.get(item);
    
  
     axi_seq_item::aw_from_class(.t(item), .v(v));
     vif.write_aw(.s(v));

    
     driver_writedata_mbx.put(item);

  end
  
endtask : driver_write_address
    
task axi_driver::driver_write_data;
  axi_seq_item item;
  int i=0;
  int validcntr=0; 
  logic [31:0]  idata;
  logic [3:0]   iwstrb;
  bit           ivalid;
  
  forever begin
     driver_writedata_mbx.get(item);

    i=0;
    validcntr=0;
    while (i<item.len/4) begin
      vif.wait_for_clks(.cnt(1));
      if (vif.get_ready_valid() == 1'b1)  begin
        i++;
        validcntr++;
      end
      idata={item.data[i*4+3],
             item.data[i*4+2],
             item.data[i*4+1],
             item.data[i*4+0]};
      iwstrb={item.wstrb[i*4+3],
              item.wstrb[i*4+2],
              item.wstrb[i*4+1],
              item.wstrb[i*4+0]};
      ivalid=item.valid[validcntr];
      vif.write_w(.data(idata), .wstrb(iwstrb), .valid(ivalid));
      if (ivalid == 1'b0) begin
        validcntr++;
      end
      
    end
    vif.set_wvalid(1'b0);
    
     driver_writeresponse_mbx.put(item);
  end    


endtask : driver_write_data
    
task axi_driver::driver_write_response;
  
  axi_seq_item item;
  
  forever begin
     driver_writeresponse_mbx.get(item);
  end    
endtask : driver_write_response

task axi_driver::responder_write_address;
  
  axi_seq_item item;
  
  forever begin
     responder_writeaddress_mbx.get(item);
    responder_writedata_mbx.put(item);
  end    
endtask : responder_write_address
    
task axi_driver::responder_write_data;
  
  axi_seq_item item;
  
  forever begin
     responder_writedata_mbx.get(item);
     responder_writeresponse_mbx.put(item);
  end    
endtask : responder_write_data
    
task axi_driver::responder_write_response;
  
  axi_seq_item item;
  
  forever begin
     responder_writeresponse_mbx.get(item);
          vif.wait_for_clks(.cnt(1));
    vif.set_bvalid(1'b1);
    vif.set_bvalid(1'b0);
        seq_item_port.put(item);  
  end    
endtask : responder_write_response