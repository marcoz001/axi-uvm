class axi_seq extends uvm_sequence #(axi_seq_item);
  
    `uvm_object_utils(axi_seq)
  
  int xfers_done=0;
  
  extern function   new (string name="axi_seq");
  extern task       body;
  extern function void response_handler(uvm_sequence_item response);
endclass : axi_seq
    
    
// This response_handler function is enabled to keep the sequence response FIFO empty
function void axi_seq::response_handler(uvm_sequence_item response);
   xfers_done++;
   `uvm_info(this.get_type_name(), $sformatf("SEQ_response_handler xfers_done=%d.   Item: %s",xfers_done, response.convert2string()), UVM_INFO)

endfunction: response_handler
    
    
function axi_seq::new (string name="axi_seq");
  super.new(name);
endfunction : new
    
task axi_seq::body;
     axi_seq_item original_item;
     axi_seq_item item;
  axi_seq_item rsp;
  int xfers_to_send=0;

  xfers_done=0;
  original_item=axi_seq_item::type_id::create("original_item");
  
  use_response_handler(1); // Enable Response Handler
  
  xfers_to_send=3;

  for (int i=0;i<xfers_to_send;i++) begin
     $cast(item, original_item.clone());
     start_item(item);
     assert( item.randomize() with {cmd        == e_WRITE; 
                                    burst_size == e_4BYTES;
                                    burst_type == e_INCR;}) else begin
         `uvm_error(this.get_type_name(),
                    $sformatf("Unable to randomize %s",  item.get_full_name()));
     end  //assert
     finish_item(item);
  end  //for 
 
  wait (xfers_to_send == xfers_done);
  `uvm_info(this.get_type_name(), "SEQ ALL DONE", UVM_INFO)
    
endtask : body
    

