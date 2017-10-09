////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_seq_item.svh
//
// Purpose:
//          UVM sequence item for AXI UVM environment
//
// Creator:	Matt Dew
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017, Matt Dew
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
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
    rand  int          len=0;
    //rand  burst_size_t burst_size; // Burst size
    //rand  burst_type_t burst_type;
         logic [7:0] awlen;      // calculated later using the addr and len properties.
    rand logic [2:0] burst_size; // Burst size
  rand logic [1:0] burst_type;

          logic [0:0]  lock   = 'h0;
          logic [3:0]  cache  = 'h0;
          logic [2:0]  prot   = 'h0;
          logic [3:0]  qos    = 'h0;

          logic [6-1:0] bid   = 'hF;
          logic [1:0]   bresp = 'h3;

    rand  cmd_t        cmd; // read or write

  rand   logic [31:0] toggle_pattern = 32'hFFFF_FFFF;


 // rand int number_bytes;

  // These variables below are used by anything operating on the
  // bus itself that needs to calculate addresses and wstrbs
  // IE: drivers and monitors
  // Putting this logic here guarantees the logic is with the data
  // The downside is it enlarges the sequence item. ;(
  // Could/Should(?) put it in axi_pkg or axi_uvm_pkg?
  // if in axi_pkg the logic could be  synthesizable functions
  // and then a non-UVM BFM could easily be created

  bit [63:0] Start_Address;
  bit [63:0] Aligned_Address;
  bit        aligned;
  int        Number_Bytes;
  int        iNumber_Bytes;
  int        Burst_Length_Bytes;
  int        Data_Bus_Bytes;

  bit [63:0] Lower_Wrap_Boundary;
  bit [63:0] Upper_Wrap_Boundary;
  int        Lower_Byte_Lane;
  int        Upper_Byte_Lane;
  bit  [1:0] Mode;
 // bit [63:0] addr;
  int        dtsize;
  int n=0;
  int validcntr;
  int validcntr_max;
  int dataoffset=0;
  int initialized=0;





/*
  constraint easier_testing {len >= 'h10;
                             len < 60;
                             (len % 4) == 0;}
 */
  //constraint number_bytes_c {number_bytes == 2;}
  //constraint burst_size_c {burst_size == axi_pkg::e_2BYTES;}


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

    extern function bit [63:0] calculate_aligned_address(
     input bit [63:0] addr,
     input int        number_bytes);

    extern function int calculate_beats(
      input bit [63:0] addr,
      input int        number_bytes,
      input int        burst_length);

    extern function void update_wstrb(
      input bit [63:0] addr,
      input bit        wstrb [],
      const ref bit [7:0]  data [],
      input int        number_bytes,
      input int        burst_length,
      ref   bit        new_wstrb [],
      ref   bit [7:0]  new_data [],
      output int       new_beat_cnt);

      extern function void update_address();
        extern function void initialize();
          extern function void update();  // update_address vs update ?


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

    extern static function void  b_from_class(
      input  [5:0]     bid,
      input  [1:0]     bresp,
      output axi_seq_item_b_vector_s v);

    extern static function void  b_to_class(
      output  [5:0]     bid,
      output  [1:0]     bresp,
      input axi_seq_item_b_vector_s v);


endclass : axi_seq_item

function axi_seq_item::new (string name="axi_seq_item");
  super.new(name);
endfunction : new

function string axi_seq_item::convert2string;
    string s;
    string sdata;
  int j=0;
    $sformat(s, "%s", super.convert2string());
    $sformat(s, "%s Addr = 0x%0x ", s, addr);
    $sformat(s, "%s ID = 0x%0x",   s, id);
    $sformat(s, "%s Len = 0x%0x  (0x%0x)",   s, len, len/4);
    $sformat(s, "%s BurstSize = 0x%0x ",   s, burst_size);
    $sformat(s, "%s BurstType = 0x%0x ",   s, burst_type);
    $sformat(s, "%s BID = 0x%0x",   s, bid);
    $sformat(s, "%s BRESP = 0x%0x",   s, bresp);



  $sformat(s, "%s Start_Address = 0x%0x ", s, Start_Address);
  $sformat(s, "%s Aligned_Address = 0x%0x ", s, Aligned_Address);
  $sformat(s, "%s aligned = %0d ", s, aligned);
  $sformat(s, "%s Number_Bytes = %0d ", s, Number_Bytes);
  $sformat(s, "%s iNumber_Bytes = %0d ", s, iNumber_Bytes);
  $sformat(s, "%s Burst_Length_Bytes = %0d ", s, Burst_Length_Bytes);
  $sformat(s, "%s Data_Bus_Bytes = %0d ", s, Data_Bus_Bytes);

  $sformat(s, "%s Lower_Wrap_Boundary = 0x%0x ", s, Lower_Wrap_Boundary);
  $sformat(s, "%s Upper_Wrap_Boundary = 0x%0x ", s, Upper_Wrap_Boundary);
  $sformat(s, "%s Lower_Byte_Lane = %0d ", s, Lower_Byte_Lane);
  $sformat(s, "%s Upper_Byte_Lane = %0d ", s, Upper_Byte_Lane);
  $sformat(s, "%s Mode = %0d ", s, Mode);
 // bit [63:0] addr;
  $sformat(s, "%s dtsize = %0d ", s, dtsize);

/*
assert (len == data.size()) else begin
    `uvm_error(this.get_type_name(), $sformatf("member 'len [%d]' does not match data.size() [%d]", len, data.size()))
  end
*/
  j=data.size();
  for (int i =0; i< j; i++) begin
      $sformat(sdata, "%s 0x%02x ", sdata, data[i]);
    end
  $sformat(s, "%s Data: %s", s, sdata);

    return s;
endfunction : convert2string

function void axi_seq_item::do_copy(uvm_object rhs);
    int i;
    int j;
    axi_seq_item _rhs;
    $cast(_rhs, rhs);
    super.do_copy(rhs);

    addr  = _rhs.addr;
    id    = _rhs.id;
    len   = _rhs.len;

    burst_size = _rhs.burst_size;
    burst_type = _rhs.burst_type;
    lock       = _rhs.lock;
    cache      = _rhs.cache;
    prot       = _rhs.prot;
    qos        = _rhs.qos;

    bid        = _rhs.bid;
    bresp      = _rhs.bresp;

    cmd        = _rhs.cmd;
/*
    j=_rhs.data.size();
    data  = new[j];
    for (int i=0;i<j;i++) begin
      data[i]  = _rhs.data[i];
    end
  */
  data=new[_rhs.data.size()](_rhs.data);

    j=_rhs.wstrb.size();
    wstrb  = new[j];
    for (int i=0;i<j;i++) begin
      wstrb[i]  = _rhs.wstrb[i];
    end

    j=_rhs.valid.size();
    valid  = new[j];
    for (int i=0;i<j;i++) begin
      valid[i]  = _rhs.valid[i];
    end

    j=_rhs.wlast.size();
    wlast  = new[j];
    for (int i=0;i<j;i++) begin
      wlast[i] = _rhs.wlast[i];
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
    wstrb[i]=1'b1; // $random();
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


  j=valid.size();
  for (int i=0;i<j;i++) begin
    valid[i] = $random;
  end

  valid[0] = 1'b1;
  valid[1] = 1'b1;
  valid[2] = 1'b0;


  data[len-1] = 'hFE; // specific value to eaily identify last byte

  //assert(valid.randomize()) else begin
  //  `uvm_error(this.get_type_name, "Unable to randomize valid");
  //end
endfunction : post_randomize



function void axi_seq_item::update_address;
  if (Mode != axi_pkg::e_FIXED) begin
     if (aligned) begin
        addr = Aligned_Address + Number_Bytes;
        if (Mode == axi_pkg::e_WRAP) begin
           // WRAP mode is always aligned
           if (addr >= Upper_Wrap_Boundary) begin
              addr = Lower_Wrap_Boundary;
           end
        end
     end else begin // (if aligned)
          addr    = Aligned_Address + Number_Bytes;
          aligned = 1'b1;
     end // (if aligned)
  end // (Mode)

  update();
endfunction : update_address

function void axi_seq_item::initialize;
//    addr           = item.addr;
    Start_Address     = addr;
    Number_Bytes      = 2**int'(burst_size); // number_bytes; // Partial or Full transfers.
    Burst_Length_Bytes = len;
    Data_Bus_Bytes    = 4; // @Todo: parameter? fetch from cfg_db?
    Mode              = burst_type;
    Aligned_Address   = (int'(addr/Number_Bytes) * Number_Bytes);
    aligned           = (Aligned_Address == addr);
    dtsize            = Number_Bytes * 16; // 16 beats/AXI3 burst urst_Length_Bytes;
    validcntr         = 0;
    validcntr_max     = valid.size()-1; // don't go past end
    if (burst_type == axi_pkg::e_WRAP) begin
       Lower_Wrap_Boundary = (int'(addr/dtsize) * dtsize);
       Upper_Wrap_Boundary = Lower_Wrap_Boundary + dtsize;
    end else begin
       Lower_Wrap_Boundary = 'h0;
       Upper_Wrap_Boundary = -1;
    end
    initialized=1;
    dataoffset=0;

  update();
endfunction : initialize

function void axi_seq_item::update;
    iNumber_Bytes = Number_Bytes;
    Aligned_Address   = (int'(addr/iNumber_Bytes) * iNumber_Bytes);

    Lower_Byte_Lane   = addr - (int'(addr/Data_Bus_Bytes)) * Data_Bus_Bytes;
    // Adjust Lower_Byte_lane up if unaligned.
    if (aligned) begin
       Upper_Byte_Lane = Lower_Byte_Lane + iNumber_Bytes - 1;
    end else begin
       Upper_Byte_Lane = Aligned_Address + iNumber_Bytes - 1
                         - (int'(addr/Data_Bus_Bytes)) * Data_Bus_Bytes;
    end

    //  `uvm_info("INFO", $sformatf("Lower_Byte_Lane: %0d  Upper_Byte_lane: %0d    addr:0x%0x, aligned-addr: 0x%0x  Data_Bus_Bytes:%0d  Number_Bytes: %0d  aligned: %b",  Lower_Byte_Lane, Upper_Byte_Lane, addr, Aligned_Address, Data_Bus_Bytes, iNumber_Bytes, aligned), UVM_INFO)


endfunction : update


function bit [63:0] axi_seq_item::calculate_aligned_address(
  input bit [63:0] addr,
  input int number_bytes);

  bit [63:0] aligned_address ;

        // address - starting address
        // data_bus_bytes - width of data bus (in bytes)
        // number_bytes - number of bytes per beat (must be consistent throughout burst)
        //              - unless doing a partial transfer, this matches data_bus_bytes
        //

        aligned_address = int'(addr/number_bytes)*number_bytes;
        return aligned_address;

endfunction : calculate_aligned_address

function int axi_seq_item::calculate_beats(
    input bit [63:0] addr,
    input int number_bytes,
    input int burst_length);

  int beats;
  bit [63:0] aligned_addr;

  aligned_addr=calculate_aligned_address(.addr(addr),
                                         .number_bytes(number_bytes));

        // address - starting address
        // burst_length - total length of burst (in bytes)
        // data_bus_bytes - width of data bus (in bytes)
        // number_bytes - number of bytes per beat (must be consistent throughout burst)
        //              - this matches data_bus_bytes unless doing a partial transfer
  beats = ((addr-aligned_addr)+burst_length)/number_bytes;
  return beats;
endfunction : calculate_beats

      // update wstrb[] array account for aligned_address.
      // basically, if address isn't aligned, then
      // shift wstrb by (addr-aligned_addr) and insert
      // 0's so those addresses aren't written.
      // Also adjust for partial tranfer if applicable.
function void axi_seq_item::update_wstrb(
        input bit [63:0] addr,
        input bit        wstrb [],
        const ref bit [7:0] data [],
        input int number_bytes,
        input int burst_length,
        ref   bit       new_wstrb [],
        ref   bit [7:0] new_data [],
        output int      new_beat_cnt);

        bit [63:0] aligned_addr ;

       real z;
        //bit new_wstrb[];
        int wstrb_size;

        int alignment_offset;

        aligned_addr=calculate_aligned_address(.addr(addr),
                                         .number_bytes(number_bytes));

        alignment_offset = addr-aligned_addr;
        wstrb_size       = wstrb.size();

        new_wstrb = new[alignment_offset+wstrb_size];
        new_data  = new[alignment_offset+wstrb_size];

        for (int i=0;i<alignment_offset;i++) begin
           new_wstrb[i] = 1'b0;
           new_data[i]  = 7'h00;
        end

        for (int i=0, j=alignment_offset; i<wstrb_size; i++,j++) begin
            new_wstrb[j] = wstrb[i];
            new_data[j]  = data[i];
        end

  // round up beatcnt
  z = real'(((real'(alignment_offset+burst_length))/real'(number_bytes)));
  if (int'(z) == z) begin
     new_beat_cnt = z;
  end else begin
     new_beat_cnt = z+1;
  end

  `uvm_info(this.get_type_name(), $sformatf("XXXXXXXXXXXX alignment_offset: %d; burst_length: %d; new_length:%d; z:%f; new_beat_cnt: %d", alignment_offset, burst_length, new_data.size(), z, new_beat_cnt), UVM_INFO)

endfunction : update_wstrb

 function void axi_seq_item::aw_from_class(
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

 function void axi_seq_item::aw_to_class(
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


 function void axi_seq_item::w_from_class(
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

 function void axi_seq_item::w_to_class(
  output  [31:0]                  wdata,
  output  [3:0]                   wstrb,
  output                          wvalid,
  output                          wlast,
  input  axi_seq_item_w_vector_s  v);

    axi_seq_item_w_vector_s s;

    s = v;

     wdata   = s.wdata;
     wstrb   = s.wstrb;
     wlast   = s.wlast;
     wvalid  = s.wvalid;

endfunction : w_to_class

 function void axi_seq_item::b_from_class(
  input  [5:0]     bid,
  input  [1:0]     bresp,
  output axi_seq_item_b_vector_s v);

  axi_seq_item_b_vector_s s;

     s.bid     = bid;
     s.bresp   = bresp;

  v = s;
endfunction : b_from_class

 function void axi_seq_item::b_to_class(
  output  [5:0]     bid,
  output  [1:0]     bresp,
  input  axi_seq_item_b_vector_s  v);

    axi_seq_item_b_vector_s s;

    s = v;

     bid   = s.bid;
     bresp = s.bresp;

endfunction : b_to_class
