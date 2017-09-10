class axi_responder_seq extends axi_seq; 
    
  `uvm_object_utils(axi_responder_seq)
  
  `uvm_declare_p_sequencer (axi_sequencer)
  
  
  logic [7:0] mem [];
  
  extern function   new (string name="axi_responder_seq");
  extern task       body;

endclass : axi_responder_seq
    
    function axi_responder_seq::new (string name="axi_responder_seq");
  super.new(name);
endfunction : new
    
task axi_responder_seq::body;
     axi_seq_item drv_item;

  axi_seq_item original_item;
     axi_seq_item item;
 
     original_item=axi_seq_item::type_id::create("original_item");
  item=axi_seq_item::type_id::create("item");
  
  `uvm_info(this.get_type_name(), "YO~! starting responder_seq", UVM_INFO)
     
     forever begin
       // $cast(item, original_item.clone());
//       `uvm_info(this.get_type_name(), "waiting on p_sequencer", UVM_INFO)
       p_sequencer.request_fifo.get(drv_item); 
       // recommended by verilab but doesn't
       // this break the child-doesn't-know-about-parent model?
       
//       `uvm_info(this.get_type_name(), "waiting on p_sequencer - done", UVM_HIGH)

 //      `uvm_info(this.get_type_name(), "start_item()", UVM_HIGH)
       start_item(item);
 //      item.randomize();
 //      `uvm_info(this.get_type_name(), "start_item() - done", UVM_INFO)
 //      item.addr=64'hBABE_BAEB;
 //      `uvm_info(this.get_type_name(), $sformatf(" <-HEY0HEY0HEY0 -> %s", item.convert2string()), UVM_INFO)
 //      `uvm_info(this.get_type_name(), "finish_item()", UVM_INFO)

       finish_item(item);
 //      `uvm_info(this.get_type_name(), "finish_item() - done", UVM_INFO)

  //     `uvm_info(this.get_type_name(), $sformatf(" <-HEYHEYHEY -> %s", item.convert2string()), UVM_INFO)
     end
  
endtask : body
    