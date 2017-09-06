class axi_seq extends uvm_sequence #(axi_seq_item);
  
    `uvm_object_utils(axi_seq)
  

  
  extern function   new (string name="axi_seq");
  extern task       body;

endclass : axi_seq
    
function axi_seq::new (string name="axi_seq");
  super.new(name);
endfunction : new
    
task axi_seq::body;
     axi_seq_item original_item;
     axi_seq_item item;
 
     original_item=axi_seq_item::type_id::create("original_item");
  
  `uvm_info(this.get_type_name(), "YO~! starting axi_sq", UVM_INFO)
     
        $cast(item, original_item.clone());
        start_item(item);
  assert( item.randomize() with {cmd==WRITE;});
        finish_item(item);
       `uvm_info(this.get_type_name(), $sformatf("%s", item.convert2string()), UVM_HIGH)
  
endtask : body
    

