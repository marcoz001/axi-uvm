class axi_responder_seq extends axi_seq; 
    
  `uvm_object_utils(axi_responder_seq)
  
  extern function   new (string name="axi_responder_seq");
  extern task       body;

endclass : axi_responder_seq
    
    function axi_responder_seq::new (string name="axi_responder_seq");
  super.new(name);
endfunction : new
    
task axi_responder_seq::body;
     axi_seq_item original_item;
     axi_seq_item item;
 
     original_item=axi_seq_item::type_id::create("original_item");
     
//     forever begin
        $cast(item, original_item.clone());
        start_item(item);
  //assert( item.randomize() with {cmd==WRITE;});
        finish_item(item);
       `uvm_info(this.get_type_name(), $sformatf(" <-HEYHEYHEY -> %s", item.convert2string()), UVM_HIGH)
//     end
  
endtask : body
    