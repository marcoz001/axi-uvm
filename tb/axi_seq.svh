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
  assert( item.randomize() with {cmd        == e_WRITE; 
                                 burst_size == e_4BYTES;
                                 burst_type == e_INCR;}) else begin
           `uvm_error(this.get_type_name(),
                      $sformatf("Unable to randomize %s",  item.get_full_name()));
        end
        finish_item(item);
   fork
     begin
  `uvm_info(this.get_type_name(), "waiting on get_response()", UVM_INFO)

  get_response(item);
  `uvm_info(this.get_type_name(), "waiting on get_response() - done", UVM_INFO)
     end
  join_none
  `uvm_info(this.get_type_name(), $sformatf("%s", item.convert2string()), UVM_HIGH)
  
  wait fork;
endtask : body
    

