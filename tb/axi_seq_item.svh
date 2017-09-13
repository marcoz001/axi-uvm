class axi_seq_item extends uvm_sequence_item;
  `uvm_object_utils(axi_seq_item)

    //widths are top-level parameters. but we're setting to max here.
    // A recommendation from veloce docs
    rand  bit [6:0]    id;
    rand  bit [63:0]   addr;
    rand  bit          valid []; // keep valid with data,
  // then can also toggle independently and have easy playback on failure
  // @Todo: play around more with the do_record
  
    rand  bit [7:0]    data  [];
    rand  bit          wstrb [];
    rand  bit          wlast [];
    rand  int          len;  
    rand  burst_size_t burst_size; // Burst size
    rand  burst_type_t burst_type;
          logic [0:0]  lock   = 'h0;
          logic [3:0]  cache  = 'h0;
          logic [2:0]  prot   = 'h0;
          logic [3:0]  qos    = 'h0;
  
    rand  cmd_t        cmd; // read or write

  constraint easier_testing {len > 40;
                             len < 60;
                             (len % 4) == 0;}
  
  
    constraint max_len {len > 0;
                        len < 256*128;} // AXI4 is 256-beat burst by 128-byte wide
    constraint valid_c { solve len before valid;
                         valid.size() == len*2; }
    constraint data_c {  solve len before data; 
                         data.size() == len; }
    constraint wstrb_c { solve len before wstrb;
                         wstrb.size() == len; }
    constraint wlast_c { solve len before wlast;
                        wlast.size() == len/4;
                       } //only the last bit is set, do that in post-randomize
  
    extern function        new        (string name="axi_seq_item");
    extern function string convert2string;
    extern function void   do_copy    (uvm_object rhs);
    extern function bit    do_compare (uvm_object rhs, uvm_comparer comparer);
    extern function void   do_print   (uvm_printer printer);
      
    extern function void   post_randomize;
      
    extern static function void   aw_from_class(
      ref    axi_seq_item             t,
      output axi_seq_item_aw_vector_s v);
      
    extern static function void   aw_to_class(
      ref    axi_seq_item             t,
      input  axi_seq_item_aw_vector_s v);

    extern static function void   w_from_class(
      input  [31:0]                  wdata,
      input  [3:0]                   wstrb,
      input                          wvalid,
      input                          wlast,
      output axi_seq_item_w_vector_s v);
      
    extern static function void   w_to_class(
      output  [31:0]                  wdata,
      output  [3:0]                   wstrb,
      output                          wvalid,
      output                          wlast,
      input  axi_seq_item_w_vector_s  v);
      
endclass : axi_seq_item
    
function axi_seq_item::new (string name="axi_seq_item");
  super.new(name);
endfunction : new
      
function string axi_seq_item::convert2string;
    string s;
    string sdata;
    $sformat(s, "%s", super.convert2string());
    $sformat(s, "%s Addr = 0x%0x ", s, addr);
  $sformat(s, "%s ID = 0x%0x",   s, id);
  $sformat(s, "%s Len = 0x%0x  (0x%0x)",   s, len, len/4);
    $sformat(s, "%s BurstSize = 0x%0x (%s)",   s, burst_size, burst_size.name);
    $sformat(s, "%s BurstType = 0x%0x (%s)",   s, burst_type, burst_type.name);
  
  
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
          int j;

  super.post_randomize;
//  data=new[len];
  //wstrb=new[len];
  //valid=new[len*2];  // only need one per beat instead of one per byte,
                     // we won't use the extras.
  for (int i=0; i < len; i++) begin
    data[i] = i;
    wstrb[i]=i; // $random();
   // wlast[i]=1'b0;
    //valid[i]=$random();
    //valid[i+len]=$random();
    //    data[i] = $random;
  end
  
  j=wlast.size();
  for (int i=0;i<j;i++) begin
    wlast[i] = 1'b1;
  end
  wlast[0] = 1'b1;
/*
  j=valid.size();
  for (int i=0;i<j;i++) begin
    valid[i] = 1'b1;
  end
*/
  
  //assert(valid.randomize()) else begin
  //  `uvm_error(this.get_type_name, "Unable to randomize valid");
  //end
endfunction : post_randomize
  
  
static function void axi_seq_item::aw_from_class(
  ref  axi_seq_item             t,
  output axi_seq_item_aw_vector_s v);
    
  axi_seq_item_aw_vector_s s;
    
     s.awid    = t.id;
     s.awaddr  = t.addr;
     s.awlen   = t.len;
     s.awsize  = t.burst_size;
     s.awburst = t.burst_type;
     s.awlock  = t.lock; 
     s.awcache = t.cache;
     s.awprot  = t.prot;
     s.awqos   = t.qos;
    v = s;
endfunction : aw_from_class
 
static function void axi_seq_item::aw_to_class(
  ref    axi_seq_item             t,
  input  axi_seq_item_aw_vector_s v);
    axi_seq_item_aw_vector_s s;
    s = v;
    
   // t = new();
    
     t.id          = s.awid;
     t.addr        = s.awaddr;
     t.len         = s.awlen;
     t.burst_size  = s.awsize;
     t.burst_type  = s.awburst;
     t.lock        = s.awlock; 
     t.cache       = s.awcache;
     t.prot        = s.awprot;
     t.qos         = s.awqos;

endfunction : aw_to_class
          
      
static function void axi_seq_item::w_from_class(
  input  [31:0]                  wdata,
  input  [3:0]                   wstrb,
  input                          wvalid,
  input                          wlast,
  output axi_seq_item_w_vector_s v);
    
  axi_seq_item_w_vector_s s;
    
     s.wdata   = wdata;
     s.wstrb   = wstrb;
     s.wlast   = wlast;
     s.wvalid  = wvalid;

  v = s;
endfunction : w_from_class
 
static function void axi_seq_item::w_to_class(
  output  [31:0]                  wdata,
  output  [3:0]                   wstrb,
  output                          wvalid,
  output                          wlast,
  input  axi_seq_item_w_vector_s  v);
  
    axi_seq_item_w_vector_s s;

    s = v;
    
//    t = new();
    
     wdata   = s.wdata;
     wstrb   = s.wstrb;
     wlast   = s.wlast;
     wvalid  = s.wvalid;

endfunction : w_to_class
          
