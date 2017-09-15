class axi_driver extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_driver)
  
  axi_if_abstract vif;
  axi_agent_config    m_config;
  
  mailbox #(axi_seq_item) driver_writeaddress_mbx  = new(0);  //unbounded mailboxes
  mailbox #(axi_seq_item) driver_writedata_mbx     = new(0);
  mailbox #(axi_seq_item) driver_writeresponse_mbx = new(0);

  // probably unnecessary but
  // having different variables
  // makes it easier for me to follow (less confusing)
  mailbox #(axi_seq_item) responder_writeaddress_mbx  = new(0);  //unbounded mailboxes
  mailbox #(axi_seq_item) responder_writedata_mbx     = new(0);
  mailbox #(axi_seq_item) responder_writeresponse_mbx = new(0);

  
  extern function new (string name="axi_driver", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
  extern function void end_of_elaboration_phase (uvm_phase phase);
  extern task          run_phase                (uvm_phase phase);
    
  //extern task          write(ref axi_seq_item item);
    
    
  extern task          driver_run_phase;
  extern task          responder_run_phase;
    
  extern task          driver_write_address;
  extern task          driver_write_data;
  extern task          driver_write_response;

  extern task          responder_write_address;
  extern task          responder_write_data;
  extern task          responder_write_response;
   
    reg foo;
    
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
  axi_seq_item item2;
  
    vif.set_awvalid(1'b0);
    vif.set_wvalid(1'b0);

    vif.set_bready_toggle_mask(m_config.bready_toggle_mask);

  
  fork
    driver_write_address();
    driver_write_data();
    driver_write_response();
  join_none
  
  forever begin    
//    seq_item_port.get_next_item(item);  
//    $cast(item2,item.clone());
//    #1ns 
    //    seq_item_port.item_done(item); 
    // Using item_done also triggers get_response() in the seq.

    seq_item_port.get(item);  
    $cast(item2,item.clone());
    item2.set_id_info(item);
    //#3ns 
    if (item2.cmd == e_WRITE) begin
      driver_writeaddress_mbx.put(item2);
    end
 //   `uvm_info(this.get_type_name(), $sformatf("driver_run_phase: %s", item.convert2string()), UVM_INFO)
//    seq_item_port.item_done(item);
    //#1500
    //`uvm_info(this.get_type_name(), "HEY, HEY, waiting on seq_item_port.put()", UVM_INFO)
    
   // seq_item_port.put(item2);  
   // `uvm_info(this.get_type_name(), "HEY, HEY, waiting on seq_item_port.put() - done", UVM_INFO)

  
  end  //forever
endtask : driver_run_phase
    
task axi_driver::responder_run_phase;
  axi_seq_item item;
  
  item = axi_seq_item::type_id::create("item", this);

  
    fork
    responder_write_address();
    responder_write_data();
    responder_write_response();
  join_none

  
  `uvm_info(this.get_type_name(), "HEY< YOU< responder_run_phase", UVM_INFO)
  vif.set_awready_toggle_mask(m_config.awready_toggle_mask);
  vif.set_wready_toggle_mask(m_config.wready_toggle_mask);
  vif.set_bvalid(1'b0);
  
  vif.wait_for_not_in_reset();
  //forever begin
    
    `uvm_info(this.get_type_name(), "waiting on get_next_item()", UVM_INFO)
    item = axi_seq_item::type_id::create("item", this);
    seq_item_port.get_next_item(item);  
    `uvm_info(this.get_type_name(), "waiting on get_next_item() - done", UVM_INFO)

    `uvm_info(this.get_type_name(), "waiting on wait_for_awready_awvalid()", UVM_INFO)
    //vif.wait_for_awready_awvalid();
    
    `uvm_info(this.get_type_name(), "waiting on wait_for_awready_awvalid() - done", UVM_INFO)
    //$cast(item, original_item.clone());
    `uvm_info(this.get_type_name(), $sformatf("DRVa: %s", item.convert2string()), UVM_INFO)

    //vif.read(.addr(item.addr), .data(item.data), .len(item.len), .id(item.id));
    //vif.write_data(
    //write(item);
   // `uvm_info(this.get_type_name(), $sformatf("DRVb: %s", item.convert2string()), UVM_INFO)

   // `uvm_info(this.get_type_name(), "waiting on responder_run_phase.item_done()", UVM_INFO)
    //seq_item_port.item_done();
   // `uvm_info(this.get_type_name(), "waiting on responder_run_phase.item_done() - done", UVM_INFO)
   // `uvm_info(this.get_type_name(), "waiting on responder_run_phase.seq_item_port.put() ", UVM_INFO)
responder_writeaddress_mbx.put(item);
//responder_writeresponse_mbx.get(item);
//    seq_item_port.put(item);  
  //  `uvm_info(this.get_type_name(), "waiting on responder_run_phase.seq_item_port.put() - done", UVM_INFO)
    
    vif.wait_for_clks(.cnt(1));
    
 // end
endtask : responder_run_phase

    
task axi_driver::driver_write_address;
  
  axi_seq_item item;
  axi_seq_item_aw_vector_s v;
  
  forever begin
     // grab next address

     driver_writeaddress_mbx.get(item);
    `uvm_info(this.get_type_name(), $sformatf("driver_write_address: %s", item.convert2string()), UVM_INFO)

    while (item != null) begin
       axi_seq_item::aw_from_class(.t(item), .v(v));
      vif.write_aw(.s(v), .valid(1'b1));

       driver_writedata_mbx.put(item);
      
       item=null;
    
       driver_writeaddress_mbx.try_get(item);
      if (item==null) begin
        vif.write_aw(.s(v), .valid(1'b0));
      end
    end  
  end
  
endtask : driver_write_address
    
    
task axi_driver::driver_write_data;
  axi_seq_item item=null;
  int i=0;
  int validcntr=0;
  bit rv;
  int pktcnt=0;

  
  axi_seq_item_w_vector_s s;
  
  forever begin

    driver_writedata_mbx.get(item);

    i=0;
    validcntr=0;

    while (item != null) begin  

       // defaults. not needed but  I think is cleaner
       s.wvalid = 'b0;
       s.wdata  = 'hfeed_beef;
       s.wstrb  = i;//'h0;
       s.wlast  = 1'b0;

      if (i<item.len/4) begin
        s.wvalid=item.valid[validcntr];
        s.wdata={item.data[i*4+3],item.data[i*4+2],item.data[i*4+1],item.data[i*4+0]};
        s.wstrb=i;//item.wstrb[validcntr]; 
        if (i==(item.len/4-1)) begin
           s.wlast=1'b1;//item.wlast[i];
        end else begin
           s.wlast=1'b0;
        end
      end
      vif.write_w(.s(s),.waitforwready(1));

      validcntr++;
      if (i==(item.len/4 -1)) begin
         if ((vif.get_wready() == 1'b1) && (s.wvalid==1'b1)) begin

            driver_writeresponse_mbx.put(item);
            item=null;  // explicitly set to null, don't rely on try_get below

            validcntr=0;
            i=0;
  
           driver_writedata_mbx.try_get(item);
         // if no next xfer, then not back to back so drive signals low again
           if (item==null) begin
              s.wvalid = 1'b0;
              s.wlast  = 1'b0;
              s.wdata  = 'h0;
              s.wstrb  = 'h0;
             vif.write_w(.s(s),.waitforwready(1));
           end
        end
      end else if (i<item.len/4) begin
        if ((vif.get_wready() == 1'b1) && (s.wvalid==1'b1)) begin
           i++;
        end
      end

    end    
end

endtask : driver_write_data
    
task axi_driver::driver_write_response;
  
  axi_seq_item            item;
  axi_seq_item_b_vector_s s;
  
  forever begin
    driver_writeresponse_mbx.get(item);
 //   `uvm_info(this.get_type_name(), "HEY, driver_write_response!!!!", UVM_INFO)
    vif.wait_for_bvalid();
    vif.read_b(.s(s));
    item.bid   = s.bid;
    item.bresp = s.bresp;
 //   `uvm_info(this.get_type_name(), "HEY, HEY, waiting on seq_item_port.put()", UVM_INFO)
    seq_item_port.put(item);  
  //  `uvm_info(this.get_type_name(), "HEY, HEY, waiting on seq_item_port.put() - done", UVM_INFO)
    `uvm_info(this.get_type_name(), $sformatf("driver_write_response: %s", item.convert2string()), UVM_INFO)
    
  end    
endtask : driver_write_response

    
    
task axi_driver::responder_write_address;
  
  axi_seq_item             item;
  axi_seq_item_aw_vector_s s;
  
  
  forever begin
    responder_writeaddress_mbx.get(item);
    `uvm_info(this.get_type_name(), "axi_driver::responder_write_address Getting address", UVM_INFO)
    vif.read_aw(.s(s));
    axi_seq_item::aw_to_class(.t(item), .v(s));
    
    item.data=new[item.len];
    item.wlast=new[item.len];
    item.wstrb=new[item.len];
      
    responder_writedata_mbx.put(item);
  end    
endtask : responder_write_address
    
    
    
task axi_driver::responder_write_data;
  
  int          i;
  axi_seq_item item;
  axi_seq_item litem;
  int          datacnt;
  axi_seq_item_w_vector_s s;
  bit foo;
  
  forever begin
     responder_writedata_mbx.get(item);
    `uvm_info(this.get_type_name(), 
              $sformatf("axi_driver::responder_write_data - Waiting for data for %s",
                        item.convert2string()), 
              UVM_INFO)
    
      i=0;
      while (i<item.len/4) begin
         vif.wait_for_clks(.cnt(1));
        if (vif.get_wready_wvalid() == 1'b1)  begin
           vif.read_w(s);
           axi_seq_item::w_to_class(
            {item.data[i*4+3],
             item.data[i*4+2],
             item.data[i*4+1],
             item.data[i*4+0]},
            {item.wstrb[i*4+3],
             item.wstrb[i*4+2],
             item.wstrb[i*4+1],
             item.wstrb[i*4+0]},
            foo,
            item.wlast[i],
            .v(s));
         
           i++;
        `uvm_info(this.get_type_name(), 
                  $sformatf("axi_driver::responder_write_data GOT %d for data for %s", i,
                        item.convert2string()), 
              UVM_INFO)
      end
      
    end
        `uvm_info(this.get_type_name(), 
                  $sformatf("axi_driver::responder_write_data responder_writeresponse_mbx.put - %s",
                        item.convert2string()), 
              UVM_INFO)
     responder_writeresponse_mbx.put(item);
  end    
endtask : responder_write_data
    
task axi_driver::responder_write_response;
  
  axi_seq_item item;
  
  forever begin
     responder_writeresponse_mbx.get(item);
          vif.wait_for_clks(.cnt(1));
    vif.set_bvalid(1'b1);
          vif.wait_for_clks(.cnt(1));
    vif.set_bvalid(1'b0);
       // seq_item_port.put(item);  
  end    
endtask : responder_write_response