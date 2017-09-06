class axi_seq_item extends uvm_sequence_item;
  `uvm_object_utils(axi_seq_item)

    rand bit [63:0] addr;
         bit [7:0]  data [];  
    randc bit [3:0]  len;// data len not AXI burstlen.
    rand bit [6:0]  id;      // these are top level parameters in DUT. how get here?
    rand cmd_t      cmd;


    extern function        new        (string name="axi_seq_item");
    extern function string convert2string;
    extern function void   do_copy    (uvm_object rhs);
    extern function bit    do_compare (uvm_object rhs, uvm_comparer comparer);
    extern function void   do_print   (uvm_printer printer);
      
    extern function void   post_randomize;
      
      

endclass : axi_seq_item
    
function axi_seq_item::new (string name="axi_seq_item");
  super.new(name);
endfunction : new
      
function string axi_seq_item::convert2string;
    string s;
    string sdata;
    $sformat(s, "%s", super.convert2string());
    $sformat(s, "%s Addr = 0x%0x ", s, addr);
    $sformat(s, "%s ID = 0x%0x ",   s, id);
    $sformat(s, "%s Len = 0x%0x ",   s, len);

  for (int i =0; i< len; i++) begin
      $sformat(sdata, "%s 0x%02x ", sdata, data[i]);
    end
    $sformat(s, "%s %s", s, sdata);
  
    return s;
endfunction : convert2string
 
function void axi_seq_item::do_copy(uvm_object rhs);
    
    axi_seq_item _rhs;
    $cast(_rhs, rhs);
    super.do_copy(rhs);

    addr  = _rhs.addr;
    id  = _rhs.id;
    len  = _rhs.len;

    for (int i=0;i<len;i++) begin
      data[i]  = _rhs.data[i];
    end
  
  
endfunction : do_copy
  
function bit axi_seq_item::do_compare(uvm_object rhs, uvm_comparer comparer);
  axi_seq_item _rhs;
  bit comp=1;
    
  if(!$cast(_rhs, rhs)) begin
    return 0;
  end 
 
  for (int i=0;i<len;i++) begin
    comp &= (data[i] == _rhs.data[i]);
  end
  return (super.do_compare(rhs, comparer) &&
          (addr == _rhs.addr) &&
          (len == _rhs.len)   &&
          (id == _rhs.id)     &&
          comp
         );
endfunction : do_compare

function void axi_seq_item::do_print(uvm_printer printer);
  printer.m_string = convert2string();
endfunction : do_print
  
        
function void axi_seq_item::post_randomize;
  super.post_randomize;
          
  data=new[len];

  for (int i=0; i < len; i++) begin
    data[i] = i;
//    data[i] = $random;
  end  
          
endfunction : post_randomize