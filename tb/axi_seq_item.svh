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
/*! \class axi_seq_item
 *  \brief contains all data and functions related to axi and usage
 *
 * In addition to variables like addr,len, id, this alsocontains functions that could be moved into axi_uvm_pkg to save object space. Things like calculating aligned_address from address.
 * \todo: this seq_item is laughably large.  Don't judge me, I've seen your 'temporary' code too. ;)
 */
class axi_seq_item extends uvm_sequence_item;
  `uvm_object_utils(axi_seq_item)

  localparam ADDR_WIDTH = 64;
  localparam ID_WIDTH = 7;

    //widths are top-level parameters. but we're setting to max here.
    // A recommendation from veloce docs
    rand axi_protocol_version_t                   protocol; // AXI3 or AXI4
    rand bit                    [ADDR_WIDTH-1:0]  addr;
    rand bit                    [7:0]             data  [];
    rand int                                      len      =0;

    rand bit                    [ID_WIDTH-1:0]    id;
    rand logic                  [2:0]             burst_size; // Burst size
    rand logic                  [1:0]             burst_type;


    rand bit                                      valid    []; // keep valid with data,
  // then can also toggle independently and have easy playback on failure
  // @Todo: play around more with the do_record

    rand  bit                                     wstrb [];
    rand  bit                                     wlast [];

   //rand  burst_size_t burst_size; // Burst size
    //rand  burst_type_t burst_type;

          logic [0:0]  lock   = 'h0;
          logic [3:0]  cache  = 'h0;
          logic [2:0]  prot   = 'h0;
          logic [3:0]  qos    = 'h0;

          logic [ID_WIDTH-1:0] bid   = 'hF;
          logic [1:0]   bresp = 'h3;

    rand  cmd_t        cmd; // read or write

  rand   logic [31:0] toggle_pattern = 32'hFFFF_FFFF;

  // These variables below are used by anything operating on the
  // bus itself that needs to calculate addresses and wstrbs
  // IE: drivers and monitors
  // Putting this logic here guarantees the logic is with the data
  // The downside is it enlarges the sequence item. ;(
  // Could/Should(?) put it in axi_pkg or axi_uvm_pkg?
  // if in axi_pkg the logic could be  synthesizable functions
  // and then a non-UVM BFM could easily be created

  int validcntr;
  int validcntr_max;



  const int c_AXI3_MAXBEATCNT=16;
  const int c_AXI4_MAXBEATCNT=256;



  constraint protocol_c   { solve protocol   before addr; }
  constraint burst_type_c { solve burst_type before addr; }

  // Address must be aligned if burst_type==Fixed
  // per spec, sect. a3.4.1, fixed and wrap burst types have alignment requirements
  constraint addr_c     { solve addr before burst_size;
                          // if 2 byte aligned, zero out lowest 1 addr bit,
                          // if 4 byte aligned, zero out lowest 2 addr bits
                          // if 8 byte aligned, zero out lowest 3 addr bits
                          // ...
                         // but if I try this:
                         // if ((burst_type == axi_pkg::e_FIXED || burst_type == axi_pkg::e_WRAP) &&
                         //     (burst_size != axi_pkg::e_1BYTE))
                         //   addr[burst_size-1:0] == 'h0;
                         // at least one tool complains about ""Expected a constant as index:"
                         // Better way??

                         if ((burst_type == axi_pkg::e_FIXED) &&
                             (burst_size == axi_pkg::e_2BYTES))
                           addr[0] == 1'b0;
                         else if ((burst_type == axi_pkg::e_FIXED || burst_type == axi_pkg::e_WRAP) &&
                                  (burst_size == axi_pkg::e_4BYTES))
                           addr[1:0] == 2'b00;
                         else if ((burst_type == axi_pkg::e_FIXED || burst_type == axi_pkg::e_WRAP) &&
                                  (burst_size == axi_pkg::e_8BYTES))
                           addr[2:0] == 3'b000;
                         else if ((burst_type == axi_pkg::e_FIXED || burst_type == axi_pkg::e_WRAP) &&
                                  (burst_size == axi_pkg::e_16BYTES))
                           addr[3:0] == 4'b0000;
                         else if ((burst_type == axi_pkg::e_FIXED || burst_type == axi_pkg::e_WRAP) &&
                                  (burst_size == axi_pkg::e_32BYTES))
                           addr[4:0] == 5'b00000;
                         else if ((burst_type == axi_pkg::e_FIXED || burst_type == axi_pkg::e_WRAP) &&
                                  (burst_size == axi_pkg::e_64BYTES))
                           addr[5:0] == 6'b00_0000;
                         else if ((burst_type == axi_pkg::e_FIXED || burst_type == axi_pkg::e_WRAP) &&
                                  (burst_size == axi_pkg::e_128BYTES))
                           addr[6:0] == 7'b000_0000;

                        }
  constraint burst_size_c {solve burst_size before len; }


  constraint max_len {len > 0;
                      len < 10000;
                      if      (cmd == axi_uvm_pkg::e_SETAWREADYTOGGLEPATTERN)
                         len == 1;
                      else if (cmd == axi_uvm_pkg::e_SETWREADYTOGGLEPATTERN)
                         len == 1;
                      else if (cmd == axi_uvm_pkg::e_SETARREADYTOGGLEPATTERN)
                         len == 1;

                      if ((burst_type == axi_pkg::e_FIXED) &&
                               (burst_size == axi_pkg::e_2BYTES))
                          len[0] == 1'b0;
                      else if ((burst_type == axi_pkg::e_FIXED) &&
                                  (burst_size == axi_pkg::e_4BYTES))
                           len[1:0] == 2'b00;
                      else if ((burst_type == axi_pkg::e_FIXED) &&
                                  (burst_size == axi_pkg::e_8BYTES))
                           len[2:0] == 3'b000;

                      // wrap is slightly more difficult.
                      // per spec:A3.4.1, "the length of the burst must be 2,4,8 or 16 beats
                      // however it can be different bytes within those bursts.
                      // IE:   2 beat burst,of 4 byte beats could be length=(5,6,7,8) bytes
                      //       2 beat burst of 2 byte beats could be length=(3,4) bytes
                      else if (burst_type == axi_pkg::e_WRAP && (burst_size == axi_pkg::e_1BYTE))
                        len inside {2, 4, 8, 16};
                      else if (burst_type == axi_pkg::e_WRAP && (burst_size == axi_pkg::e_2BYTES))
                        len inside {3,4, 7,8, 15,16, 31,32};
                      else if (burst_type == axi_pkg::e_WRAP && (burst_size == axi_pkg::e_4BYTES))
                        len inside {[5:8], [13:16], [29:32], [61:64]};
                      else if (burst_type == axi_pkg::e_WRAP && (burst_size == axi_pkg::e_8BYTES))
                        len inside {[9:16], [25:32], [57:64], [121:128]};

                      else if (burst_type == axi_pkg::e_WRAP && (burst_size == axi_pkg::e_16BYTES))
                        len inside {[17:32], [49:64], [113:128], [241:256]};
                      else if (burst_type == axi_pkg::e_WRAP && (burst_size == axi_pkg::e_32BYTES))
                        len inside {[33:64], [97:128], [225:256], [481:512]};
                      else if (burst_type == axi_pkg::e_WRAP && (burst_size == axi_pkg::e_64BYTES))
                        len inside {[65:128], [193:256], [449:512], [960:1024]};

                      else if (burst_type == axi_pkg::e_WRAP && (burst_size == axi_pkg::e_128BYTES))
                        len inside {[129:256], [385:512], [897:1024], [1921:2048]};


                      if ((protocol == axi_uvm_pkg::e_AXI4) &&
                               (burst_type == axi_pkg::e_INCR))

                           len < ((2**burst_size) * c_AXI4_MAXBEATCNT) -
                        (addr-int'(addr/(2**burst_size))*(2**burst_size));
                      else
                        len < ((2**burst_size) * c_AXI3_MAXBEATCNT)-
                        (addr-int'(addr/(2**burst_size))*(2**burst_size));
                        // 16 for everything except AXI4 incr.
                        //@Todo: take into account non-aligned addr

                       }



    constraint valid_c { solve len before valid;
                        valid.size() == len*1; }
    constraint data_c {  solve len before data;
                         data.size() == len; }
    constraint wstrb_c { solve len before wstrb;
                         wstrb.size() == len; }
    //constraint wlast_c { solve len before wlast;
    //                    wlast.size() == len/4;
    //                   } //only the last bit is set, do that in post-randomize

    // UVM sequence item functions
    extern function        new        (string name="axi_seq_item");
    extern function string convert2string;
    extern function void   do_copy    (uvm_object rhs);
    extern function bit    do_compare (uvm_object rhs, uvm_comparer comparer);
    extern function void   do_print   (uvm_printer printer);

    extern function void   post_randomize;

    // Custom functions
    extern function bit [ADDR_WIDTH-1:0] calculate_aligned_address(
     input bit [ADDR_WIDTH-1:0] addr,
     input int        number_bytes);

    extern function int calculate_beats(
      input bit [ADDR_WIDTH-1:0] addr,
      input int        number_bytes,
      input int        burst_length);

    extern function bit[ADDR_WIDTH-1:0] get_next_address(input int beat_cnt,
                                                         input int lane,
                                                         input int data_bus_bytes);


    extern function void get_beat_N_data(input  int beat_cnt,
                                         input  int      data_bus_bytes,
                                         ref    bit[7:0] data[],
                                         ref    bit      wstrb[],
                                         output bit      wlast);

      extern function void get_beat_N_byte_lanes(input  int beat_cnt,
                                            input  int data_bus_bytes,
                                            output int Lower_Byte_Lane,
                                            output int Upper_Byte_Lane,
                                            output int offset);


    extern  function void   aw_from_class(
      ref    axi_seq_item             t,
      output axi_seq_item_aw_vector_s v);

    extern static function void   aw_to_class(
      ref    axi_seq_item             t,
      input  axi_seq_item_aw_vector_s v);

    extern static function void  b_from_class(
      input  [ID_WIDTH-1:0]     bid,
      input  [1:0]     bresp,
      output axi_seq_item_b_vector_s v);

    extern static function void  b_to_class(
      ref   axi_seq_item            t,
      input axi_seq_item_b_vector_s v);


    extern function void   ar_from_class(
      ref    axi_seq_item             t,
      output axi_seq_item_ar_vector_s v);

    extern static function void   ar_to_class(
      ref    axi_seq_item             t,
      input  axi_seq_item_ar_vector_s v);

endclass : axi_seq_item

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function axi_seq_item::new (string name="axi_seq_item");
  super.new(name);
endfunction : new

/*! \brief Convert item's variable into one printable string.
 *
 */
function string axi_seq_item::convert2string;
    string s;
    string sdata;
    int j=0;
    sdata="";
    $sformat(s, "%s", super.convert2string());
    $sformat(s, "%s Cmd: %s   ", s, cmd.name);
    $sformat(s, "%s Addr = 0x%0x ", s, addr);
    $sformat(s, "%s ID = 0x%0x ",   s, id);
    $sformat(s, "%s Len = 0x%0x (%0d) ",   s, len,len);
    $sformat(s, "%s BurstSize = 0x%0x ",   s, burst_size);
    $sformat(s, "%s BurstType = 0x%0x ",   s, burst_type);
    $sformat(s, "%s BID = 0x%0x",   s, bid);
    $sformat(s, "%s BRESP = 0x%0x",   s, bresp);

    j=data.size();
    for (int i =0; i< j; i++) begin
       $sformat(sdata, "%s 0x%02x ", sdata, data[i]);
    end
    $sformat(s, "%s Data[]: %s", s, sdata);

    j=wstrb.size();
    sdata="";
    for (int i =0; i< j; i++) begin
      $sformat(sdata, "%s %b ", sdata, wstrb[i]);
    end
    $sformat(s, "%s wstrb[]: %s", s, sdata);


    return s;
endfunction : convert2string

/*! \brief Deep copy
 *
 * Deep copy everything */
function void axi_seq_item::do_copy(uvm_object rhs);
    int i;
    int j;
    axi_seq_item _rhs;
    $cast(_rhs, rhs);
    super.do_copy(rhs);

    addr       = _rhs.addr;
    id         = _rhs.id;
    len        = _rhs.len;

    burst_size = _rhs.burst_size;
    burst_type = _rhs.burst_type;
    lock       = _rhs.lock;
    cache      = _rhs.cache;
    prot       = _rhs.prot;
    qos        = _rhs.qos;

    bid        = _rhs.bid;
    bresp      = _rhs.bresp;

    cmd        = _rhs.cmd;

    data       = new[_rhs.data.size()](_rhs.data);
    wstrb      = new[_rhs.wstrb.size()](_rhs.wstrb);
    valid      = new[_rhs.valid.size()](_rhs.valid);
    wlast      = new[_rhs.wlast.size()](_rhs.wlast);

endfunction : do_copy

/*! \brief Deep compare
 *
 * Compare everything
 * \todo:  This function needs some attention.
 */
function bit axi_seq_item::do_compare(uvm_object rhs, uvm_comparer comparer);
  axi_seq_item _rhs;
  bit comp=1;

  return 0; // this function needs love, fail until love received.
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

/*! \brief  prints out immediate object, but no parents' stuff.
 *
 */
function void axi_seq_item::do_print(uvm_printer printer);
  printer.m_string = convert2string();
endfunction : do_print

/*! \brief Tweak things after randomization
 *
 * Currenly being used to reset the data[] to incrementing pattern
 * ending with 'FE. This is for easier debugging.
 * More love coming.
*/
function void axi_seq_item::post_randomize;
  int j;

  super.post_randomize;
//  data=new[len];
  //wstrb=new[len];
  //valid=new[len*2];  // only need one per beat instead of one per byte,
                     // we won't use the extras.
  if (cmd == e_WRITE) begin
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
        valid[i] = 'b1; // $random;
     end


//  valid[0] = 1'b1;
//  valid[1] = 1'b1;
//  valid[2] = 1'b0;


     data[len-1] = 'hFE; // specific value to eaily identify last byte
  end // if (cmd == e_WRITE)

  //assert(valid.randomize()) else begin
  //  `uvm_error(this.get_type_name, "Unable to randomize valid");
  //end
endfunction : post_randomize


/*! \brief Calculate aligned address from current address.
 *
 * Used to guarantee transfers are aligned on the bus for
 * most efficient bus usage
 * @param addr - starting address
 * @param number_bytes - number of bytes per beat (must be consistent throughout burst)
 *                       unless doing a partial transfer, this matches data_bus_bytes
 */
function bit [axi_seq_item::ADDR_WIDTH-1:0] axi_seq_item::calculate_aligned_address(
  input bit [ADDR_WIDTH-1:0] addr,
  input int number_bytes);

  bit [ADDR_WIDTH-1:0] aligned_address ;


  aligned_address = (int'(addr/number_bytes))*number_bytes;
  `uvm_info("FUNCTION: calculate_aligned_address",
            $sformatf("(int'(%0d/%0d))*%0d)=%0d",
                      addr, number_bytes,number_bytes,aligned_address),
            UVM_HIGH)
        return aligned_address;

endfunction : calculate_aligned_address

/*! \brief Get next address for reading/writing to memory
 *
 * Takes into account burst_type. IE: e_FIXED, e_INCR, e_WRAP
 * This function is stateful.  When called it updates an internal variable that holds the current address.
 */
function bit[axi_seq_item::ADDR_WIDTH-1:0] axi_seq_item::get_next_address(
  input int beat_cnt,
  input int lane,
  input int data_bus_bytes);

  bit [ADDR_WIDTH-1:0] tmp_addr;

  int Lower_Byte_Lane;
  int Upper_Byte_Lane;
  int data_offset=0;
  int Lower_Wrap_Boundary;
  int Upper_Wrap_Boundary;
  string s;
  string msg_s;

  int max_beat_cnt;
  int dtsize;

  bit [63:0] Aligned_Address;

  Aligned_Address=calculate_aligned_address(.addr         (addr),
                                            .number_bytes ((2**burst_size)));

  max_beat_cnt = calculate_beats(.addr(addr),
                                 .number_bytes(2**burst_size),
                                 .burst_length(len));

  dtsize = (2**burst_size) * max_beat_cnt;

  Lower_Wrap_Boundary = (int'(Aligned_Address/dtsize) * dtsize);
//  Lower_Wrap_Boundary = (int'(addr(/max_beat_cnt
  Upper_Wrap_Boundary = Lower_Wrap_Boundary + dtsize;

  get_beat_N_byte_lanes(.beat_cnt(beat_cnt),
                        .data_bus_bytes(data_bus_bytes),
                        .Lower_Byte_Lane(Lower_Byte_Lane),
                        .Upper_Byte_Lane(Upper_Byte_Lane),
                        .offset(data_offset));

  if (burst_type == e_FIXED) begin
    tmp_addr=addr+(lane - Lower_Byte_Lane);
  end else if (burst_type == e_INCR) begin
    tmp_addr=addr+data_offset+(lane - Lower_Byte_Lane);

  end else if (burst_type == e_WRAP) begin

        tmp_addr=addr+data_offset+(lane - Lower_Byte_Lane);

    if (tmp_addr >= Upper_Wrap_Boundary) begin
      tmp_addr = Lower_Wrap_Boundary+(tmp_addr-Upper_Wrap_Boundary);
    end
// \todo:do we have to worry about double-wrap?
  end else begin
    `uvm_error(this.get_type_name(), $sformatf("Unknown burst_type: %0d", burst_type))
  end

  msg_s="";

  $sformat(msg_s, "%s beat_cnt:%0d",              msg_s, beat_cnt);
  $sformat(msg_s, "%s max_beat_cnt:%0d",          msg_s, max_beat_cnt);
  $sformat(msg_s, "%s lane:%0d",                  msg_s, lane);
  $sformat(msg_s, "%s Lower_Byte_Lane:%0d",       msg_s, Lower_Byte_Lane);
  $sformat(msg_s, "%s Upper_Byte_Lane:%0d",       msg_s, Upper_Byte_Lane);
  $sformat(msg_s, "%s Lower_Wrap_Boundary:%0d(0x%0x)", msg_s, Lower_Wrap_Boundary, Lower_Wrap_Boundary);
  $sformat(msg_s, "%s Upper_Wrap_Boundary:%0d(0x%0x)", msg_s, Upper_Wrap_Boundary, Upper_Wrap_Boundary);
  $sformat(msg_s, "%s number_bytes:%0d",          msg_s, (2**burst_size));
  $sformat(msg_s, "%s data_offset:%0d",           msg_s, data_offset);
  $sformat(msg_s, "%s tmp_addr:%0d(0x%0x)",       msg_s, tmp_addr, tmp_addr);

  `uvm_info("axi_seq_item::get_next_address", msg_s, UVM_HIGH)

  return tmp_addr;

endfunction : get_next_address;


/*! \brief return beat values for write data and read data channels
 *
 * given the beat number and how wide the bus is, return
 * field values that can be placed directly on the bus.
 *
 * @param beat_cnt which beat inthe burst, starting at 0.
 * @param data_bus_bytes - how wide is the bus (the driver/responder can get this from the interface
 * @param data - data to be put on wdata/rdata busses (dynamic array, depth=data_bus_bytes)
 * @param wstrb - byte strobes, to be put on wstrb bus (dynamic array, depth=data_bus_bytes)
 * @param wlast - just what you think it is.
 */
function void axi_seq_item::get_beat_N_data(input  int beat_cnt,
                                            input  int      data_bus_bytes,
                                            ref    bit[7:0] data[],
                                            ref    bit      wstrb[],
                                            output bit      wlast);

  int Lower_Byte_Lane;
  int Upper_Byte_Lane;
  int data_offset=0;
  int last_beat_cnt;

  string data_s;
  string msg_s;
  string wstrb_s;


  if (data.size() != data_bus_bytes) begin
    data    = new[data_bus_bytes];
  end
  for (int z=0;z<data_bus_bytes;z++) begin
    data[z] = 'h0;
  end


  if (wstrb.size() != data_bus_bytes) begin
    wstrb    = new[data_bus_bytes];
  end
  for (int z=0;z<data_bus_bytes;z++) begin
      wstrb[z] = 'b0;
  end

  last_beat_cnt = calculate_beats(.addr         (addr),
                                  .number_bytes (2**burst_size),
                                  .burst_length (len)) - 1;
  if (beat_cnt == last_beat_cnt) begin
     wlast = 1'b1;
  end else begin
     wlast = 1'b0;
  end


  get_beat_N_byte_lanes(.beat_cnt        (beat_cnt),
                        .data_bus_bytes  (data_bus_bytes),
                        .Lower_Byte_Lane (Lower_Byte_Lane),
                        .Upper_Byte_Lane (Upper_Byte_Lane),
                        .offset          (data_offset));


  for (int i=Lower_Byte_Lane;i<=Upper_Byte_Lane;i++) begin
    if (data_offset+i-Lower_Byte_Lane < len) begin
       wstrb[i] = 1'b1;
       data[i] = this.data[data_offset+i-Lower_Byte_Lane];
    end
  end

  data_s  = " ";
  wstrb_s = " ";
  for (int i=data_bus_bytes-1; i>=0;i--) begin
    $sformat(data_s,  " %s 0x%2x", data_s,  data[i]);
    $sformat(wstrb_s, " %s%0b",   wstrb_s, wstrb[i]);
  end

  msg_s="";
  $sformat(msg_s, "%s beat_cnt:%0d",        msg_s, beat_cnt);
  $sformat(msg_s, "%s Lower_Byte_Lane:%0d", msg_s, Lower_Byte_Lane);
  $sformat(msg_s, "%s Upper_Byte_Lane:%0d", msg_s, Upper_Byte_Lane);
  $sformat(msg_s, "%s data_offset:%0d",     msg_s, data_offset);

  $sformat(msg_s, "%s wstrb:%s",            msg_s, wstrb_s);
  $sformat(msg_s, "%s data:%s",             msg_s, data_s);

  `uvm_info("axi_seq_item::get_beat_N_data", msg_s, UVM_HIGH)

endfunction : get_beat_N_data

 /*! \brief return byte lanes that contain valid data
 *
 * given the beat number and how wide the bus is, return
 * which lanes to get data from and also what offset from start address
 * to write to.
 *
 * @param beat_cnt which beat inthe burst, starting at 0.
 * @param data_bus_bytes - how wide is the bus (the driver/responder can get this from the interface
 * @param Lower_Byte_Lane - Lower valid byte lane
 * @param Upper_Byte_Lane - Upper valid byte lane
 * @param offset - offset from Start_Address.  Can be used to write to memory.
 */
function void axi_seq_item::get_beat_N_byte_lanes(input  int beat_cnt,
                                            input  int data_bus_bytes,
                                            output int Lower_Byte_Lane,
                                            output int Upper_Byte_Lane,
                                            output int offset);



   bit [63:0] Aligned_Start_Address;
  //bit [63:0] iaddr;
  bit [63:0] Address_N;
  int Lower_Byte_Lane;
  int Upper_Byte_Lane;
  int offset=0;
  string s;
  string msg_s;

  Aligned_Start_Address=calculate_aligned_address(.addr         (addr),
                                                  .number_bytes ((2**burst_size)));

  Address_N = Aligned_Start_Address+(beat_cnt*(2**burst_size));


    // Adjust Lower_Byte_lane up if unaligned.
      if (burst_type == e_FIXED) begin
      //  if (beat_cnt==0) begin
           Lower_Byte_Lane = addr -
                             (int'(addr/data_bus_bytes)) * data_bus_bytes;
           Upper_Byte_Lane = Aligned_Start_Address + (2**burst_size) - 1 -
                             (int'(addr/data_bus_bytes)) * data_bus_bytes;

           offset = beat_cnt*(2**burst_size);

      //  end else begin
      //     Lower_Byte_Lane = Address_N -
      //                       (int'(Address_N/data_bus_bytes)) * data_bus_bytes;
      //     Upper_Byte_Lane = Lower_Byte_Lane + (2**burst_size) - 1;

      //     offset = Address_N - addr;
      //  end

      end  else begin

//  if (beat_cnt==0 || burst_type == e_FIXED) begin
        if (beat_cnt==0) begin
           Lower_Byte_Lane = addr -
                             (int'(addr/data_bus_bytes)) * data_bus_bytes;
           Upper_Byte_Lane = Aligned_Start_Address + (2**burst_size) - 1 -
                             (int'(addr/data_bus_bytes)) * data_bus_bytes;

           offset = 0;

        end else begin
           Lower_Byte_Lane = Address_N -
                             (int'(Address_N/data_bus_bytes)) * data_bus_bytes;
           Upper_Byte_Lane = Lower_Byte_Lane + (2**burst_size) - 1;

           offset = Address_N - addr;
        end
      end
  `uvm_info("axi_seq_item::get_beat_N_byte_lanes",
            $sformatf(" %0d - (int'(%0d/%0d)) * %0d =%0d",
                      Address_N,  Address_N,  data_bus_bytes,   data_bus_bytes,Lower_Byte_Lane ),
            UVM_HIGH)

//  `uvm_info("axi_seq_item::get_beat_N_byte_lanes",
//            $sformatf("beat_cnt:%0d data_bus_bytes:%0d number_Bytes: %0d Start_Address: 0x%0x Aligned_Start_Address: 0x%0x Address_N: 0x%0x  Lower_Byte_Lane:%0d Upper_Byte_Lane:%0d offset:%0d",
//                      beat_cnt, data_bus_bytes,(2**burst_size), addr, Aligned_Start_Address, Address_N,  Lower_Byte_Lane, Upper_Byte_Lane, offset),
//            UVM_HIGH)

      msg_s="";
      $sformat(msg_s, "%s beat_cnt:%0d",        msg_s, beat_cnt);
      $sformat(msg_s, "%s data_bus_bytes:%0d",  msg_s, data_bus_bytes);
      $sformat(msg_s, "%s NumberBytes (2**burst_size):%0d",  msg_s, (2**burst_size));

      $sformat(msg_s, "%s addr:%0d",            msg_s, addr);
      $sformat(msg_s, "%s Aligned_Start_Address:%0d",  msg_s, Aligned_Start_Address);
      $sformat(msg_s, "%s Address_N:%0d",  msg_s, Address_N);
      $sformat(msg_s, "%s Lower_Byte_Lane:%0d", msg_s, Lower_Byte_Lane);
      $sformat(msg_s, "%s Upper_Byte_Lane:%0d", msg_s, Upper_Byte_Lane);
      $sformat(msg_s, "%s offset:%0d",          msg_s, offset);

  `uvm_info("axi_seq_item::get_beat_N_byte_lanes", msg_s, UVM_HIGH)


endfunction : get_beat_N_byte_lanes


/*! \brief Calculate number of beats/clks in this burst.
 *
 * If the transfer is too large, this function will return a bogus result
 * The caller is responsible for insuring safety.
 * \todo: check if size (length + address-misalignment) is too large
 */
function int axi_seq_item::calculate_beats(
    input bit [ADDR_WIDTH-1:0] addr,
    input int number_bytes,
    input int burst_length);

  int beats;
  bit [ADDR_WIDTH-1:0] aligned_addr;

  aligned_addr=calculate_aligned_address(.addr(addr),
                                         .number_bytes(number_bytes));


        // address - starting address
        // burst_length - total length of burst (in bytes)
        // data_bus_bytes - width of data bus (in bytes)
        // number_bytes - number of bytes per beat (must be consistent throughout burst)
        //              - this matches data_bus_bytes unless doing a partial transfer
  beats = $ceil(real'(real'((addr-aligned_addr)+burst_length)/real'(number_bytes)));
  // \todo: something easily synthesizable might be nice insttead of $ceil()

  `uvm_info("CALCULATE BEATS", $sformatf("addr:0x%0x  aligned-addr: 0x%0x   burst_length: %0d    number_bytes: %0d beats [((0x%0x-0x%0x)+%0d)/%0d]=0x%0x", addr, aligned_addr, burst_length, number_bytes, addr, aligned_addr, burst_length,number_bytes,beats), UVM_HIGH)

  return beats;
endfunction : calculate_beats

/*! \brief Pull values out of axi_seq_item and stuff into a axi_seq_item_aw_vector_s
 *
 * This funcion returns a ready-to-be used struct so awlen and awaddr are calcuated
 * in this function.
 * @param t an axi_seq_item
 * @return v a packed struct of type axi_seq_item_aw_vector_s
 */
function void axi_seq_item::aw_from_class(
  ref  axi_seq_item             t,
  output axi_seq_item_aw_vector_s v);

  axi_seq_item_aw_vector_s s;

   s.awid    = t.id;
   s.awaddr  = calculate_aligned_address(.addr(t.addr),
                                        .number_bytes(2**t.burst_size));

   s.awlen   = calculate_beats(.addr         (t.addr),
                               .number_bytes (2**t.burst_size),
                               .burst_length (t.len));
   s.awlen   = s.awlen-1;
   s.awsize  = t.burst_size;
   s.awburst = t.burst_type;
   s.awlock  = t.lock;
   s.awcache = t.cache;
   s.awprot  = t.prot;
   s.awqos   = t.qos;

    v = s;
endfunction : aw_from_class

/*! \brief Pull values out of a axi_seq_item_aw_vector_s and stuffs them into an axi_seq_item
 *
 * t.len is converted from awlen into a byte len. It uses burst_size (bytes per beat) * beats_per_burst to give a maximum byte length.
 * @return t an axi_seq_item
 * @param v a packed struct of type axi_seq_item_aw_vector_s
 */
function void axi_seq_item::aw_to_class(
  ref    axi_seq_item             t,
  input  axi_seq_item_aw_vector_s v);
    axi_seq_item_aw_vector_s s;
    s = v;

// \todo: should we detect if t==null and do something?
   // t = new();

     t.id          = s.awid;
     t.addr        = s.awaddr;
     t.len         = (s.awlen+1)*(2**s.awsize);
     t.burst_size  = s.awsize;
     t.burst_type  = s.awburst;
     t.lock        = s.awlock;
     t.cache       = s.awcache;
     t.prot        = s.awprot;
     t.qos         = s.awqos;

endfunction : aw_to_class


/*! \brief take values from write response channel and stuff into a axi_seq_item_b_vector_s
 *
 * @param bid - Write Response ID tag
 * @param bresp - Write Response
 * @return v - packed struct of type axi_seq_item_b_vector_s
 */
function void axi_seq_item::b_from_class(
  input  [ID_WIDTH-1:0]     bid,
  input  [1:0]              bresp,
  output axi_seq_item_b_vector_s v);

  axi_seq_item_b_vector_s s;

     s.bid     = bid;
     s.bresp   = bresp;

  v = s;
endfunction : b_from_class

/*! \brief return values from a axi_seq_item_b_vector_s and return an axi_seq_item
 *
 * @param v - packed struct of type axi_seq_item_b_vector_s
 * @return t - an axi_seq_item
 */
function void axi_seq_item::b_to_class(
   ref    axi_seq_item t,
   input  axi_seq_item_b_vector_s  v);

    axi_seq_item_b_vector_s s;

     s = v;

     t.bid   = s.bid;
     t.bresp = s.bresp;

endfunction : b_to_class

/*! \brief take values from an axi_seq_item and stuff into a axi_seq_item_ar_vector_s
 *
 * This funcion returns a ready-to-be used struct so arlen and araddr are calcuated
 * in this function.
 *
 * @param t - The axi_seq_item is passed by reference
 * @return v - packed struct of type axi_seq_item_ar_vector_s
 */
function void axi_seq_item::ar_from_class(
  ref  axi_seq_item             t,
  output axi_seq_item_ar_vector_s v);

  axi_seq_item_ar_vector_s s;

  s.arid    = t.id;
  s.araddr  = calculate_aligned_address(.addr(t.addr),
                                        .number_bytes(2**t.burst_size));
  s.arlen   = calculate_beats(.addr  (t.addr),
                              .number_bytes (2**t.burst_size),
                              .burst_length (t.len));
  s.arlen   = s.arlen-1;

  s.arsize  = t.burst_size;
  s.arburst = t.burst_type;
  s.arlock  = t.lock;
  s.arcache = t.cache;
  s.arprot  = t.prot;
  s.arqos   = t.qos;

  `uvm_info("axi_seq_item::ar_from_class",
            $sformatf("addr:0x%0x  number_bytes: %0d, araddr:0x%0x",
                      t.addr,2**t.burst_size, s.araddr),
            UVM_HIGH)

  v = s;
endfunction : ar_from_class

/*! \brief Pull values out of a axi_seq_item_ar_vector_s and stuffs them into an axi_seq_item
 *
 * t.len is converted from arlen into a byte len. It uses burst_size (bytes per beat) * beats_per_burst to give a maximum byte length.
 * @param t - an axi_seq_item
 * @return v - a packed struct of type axi_seq_item_ar_vector_s
 */
function void axi_seq_item::ar_to_class(
  ref    axi_seq_item             t,
  input  axi_seq_item_ar_vector_s v);
    axi_seq_item_ar_vector_s s;
    s = v;

    // \todo: should we detect if t==null and do something?
   // t = new();

     t.id          = s.arid;
     t.addr        = s.araddr;
     t.len         = (s.arlen+1)*(2**s.arsize);
     t.burst_size  = s.arsize;
     t.burst_type  = s.arburst;
     t.lock        = s.arlock;
     t.cache       = s.arcache;
     t.prot        = s.arprot;
     t.qos         = s.arqos;

endfunction : ar_to_class
