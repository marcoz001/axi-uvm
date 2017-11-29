////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017, Matt Dew @ Dew Technologies, LLC
//
// This program is free software (logic verification): you can redistribute it
// and/or modify it under the terms of the GNU Lesser General Public License (LGPL)
// as published by the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License
// for more details.
//
// License:	LGPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/lgpl.html
//
//
// Author's intent:  If you use this AXI verification code and find or fix bugs
//                   or make improvements, then share those fixes or improvements.
//                   If you use this in a bigger project, I don't care about,
//                   or want, any changes or code outside this block.
//                   Example: If you use this in an SoC simulation/testbench
//                            I don't want, or care about, your SoC or other blocks.
//                            I just care about the enhancements to these AXI files.
//                   That's why I have choosen the LGPL instead of the GPL.
////////////////////////////////////////////////////////////////////////////////
/*! \class axi_seq_item
 *  \brief contains all data and functions related to axi and usage
 *
 * In addition to variables like addr,len, id, this alsocontains functions that could be moved into axi_uvm_pkg to save object space. Things like calculating aligned_address from address.
 * \todo: this seq_item is laughably large.  Don't judge me, I've seen your 'temporary' code too. ;)
 */
class axi_seq_item extends uvm_sequence_item;
  `uvm_object_utils(axi_seq_item)

  //localparam ADDR_WIDTH = 32;
  //localparam ID_WIDTH = 7;

    //widths are top-level parameters. but we're setting to max here.
    // A recommendation from veloce docs
    rand axi_protocol_version_t                   protocol; // AXI3 or AXI4
    rand bit                    [ADDR_WIDTH-1:0]  addr;
    rand bit                    [7:0]             data  [];
    rand int                              len;//      =0;

    rand bit                    [ID_WIDTH-1:0]    id;
    rand logic                  [2:0]             burst_size; // Burst size
    rand logic                  [1:0]             burst_type;


    rand bit                                      valid    []; // keep valid with data,
  // then can also toggle independently and have easy playback on failure
  // @Todo: play around more with the do_record

    rand  bit                                     wstrb [];
    rand  bit                                     wlast [];
  bit                   [LEN_WIDTH-1:0]           axlen;    //used by monitor and coverage

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

  //int validcntr;
 // int validcntr_max;



  const shortint c_AXI3_MAXBEATCNT=16;
  const shortint c_AXI4_MAXBEATCNT=256;

//  burst_size_t  foo [];
//  constraint foo_c {burst_size inside {foo};}

  constraint protocol_c   { solve protocol   before len;
                           if (LEN_WIDTH < 8) {
                             protocol == e_AXI3;
                           }
                          }
//                            protocol inside { axi_uvm_pkg::e_AXI4, axi_uvm_pkg::e_AXI4};}
  //
  constraint burst_type_c { solve burst_type before addr;
                            burst_type != axi_pkg::e_RESERVED; }

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

                         if ((burst_type == axi_pkg::e_FIXED || burst_type == axi_pkg::e_WRAP) &&
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
                      //len < 10000;

                      if ((burst_type == axi_pkg::e_FIXED) && (burst_size == axi_pkg::e_1BYTE)) {
                        len <= (1*c_AXI3_MAXBEATCNT);
                      } else if ((burst_type == axi_pkg::e_FIXED) && (burst_size == axi_pkg::e_2BYTES)) {
                          len[0] == 1'b0;
                        len <= (2*c_AXI3_MAXBEATCNT);
                      } else if ((burst_type == axi_pkg::e_FIXED) && (burst_size == axi_pkg::e_4BYTES)) {
                           len[1:0] == 2'b00;
                        len <= (4*c_AXI3_MAXBEATCNT);
                      } else if ((burst_type == axi_pkg::e_FIXED) && (burst_size == axi_pkg::e_8BYTES)) {
                           len[2:0] == 3'b000;
                        len <= (8*c_AXI3_MAXBEATCNT);
                      } else if ((burst_type == axi_pkg::e_FIXED) && (burst_size == axi_pkg::e_16BYTES)) {
                           len[3:0] == 4'b0000;
                        len <= (16*c_AXI3_MAXBEATCNT);
                      } else if ((burst_type == axi_pkg::e_FIXED) && (burst_size == axi_pkg::e_32BYTES)) {
                           len[4:0] == 5'b0_0000;
                        len <= (32*c_AXI3_MAXBEATCNT);
                      } else if ((burst_type == axi_pkg::e_FIXED) && (burst_size == axi_pkg::e_64BYTES)) {
                           len[5:0] == 6'b00_0000;
                        len <= (64*c_AXI3_MAXBEATCNT);
                      } else if ((burst_type == axi_pkg::e_FIXED) && (burst_size == axi_pkg::e_128BYTES)) {
                           len[6:0] == 7'b000_0000;
                        len <= (128*c_AXI3_MAXBEATCNT);


                      // wrap is slightly more difficult.
                      // per spec:A3.4.1, "the length of the burst must be 2,4,8 or 16 beats
                      // however it can be different bytes within those bursts.
                      // IE:   2 beat burst,of 4 byte beats could be length=(5,6,7,8) bytes
                      //       2 beat burst of 2 byte beats could be length=(3,4) bytes
                      } else if (burst_type == axi_pkg::e_WRAP && (burst_size == axi_pkg::e_1BYTE))
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


                     // else if ((protocol == axi_uvm_pkg::e_AXI4) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_1BYTE))
                      //  len <= c_AXI4_MAXBEATCNT;
                      else if ((protocol == axi_uvm_pkg::e_AXI4) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_2BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI4_MAXBEATCNT) - byte'(addr[0]);
                      else if ((protocol == axi_uvm_pkg::e_AXI4) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_4BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI4_MAXBEATCNT) - byte'(addr[1:0]);
                      else if ((protocol == axi_uvm_pkg::e_AXI4) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_8BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI4_MAXBEATCNT) - byte'(addr[2:0]);
                      else if ((protocol == axi_uvm_pkg::e_AXI4) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_16BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI4_MAXBEATCNT) - byte'(addr[3:0]);
                      else if ((protocol == axi_uvm_pkg::e_AXI4) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_32BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI4_MAXBEATCNT) - byte'(addr[4:0]);
                      else if ((protocol == axi_uvm_pkg::e_AXI4) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_64BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI4_MAXBEATCNT) - byte'(addr[5:0]);
                      else if ((protocol == axi_uvm_pkg::e_AXI4) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_128BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI4_MAXBEATCNT) - byte'(addr[6:0]);

                    //  else if ((protocol == axi_uvm_pkg::e_AXI3) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_1BYTE))
                    //    len <= c_AXI3_MAXBEATCNT;
                      else if ((protocol == axi_uvm_pkg::e_AXI3) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_2BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI3_MAXBEATCNT) - byte'(addr[0]);
                      else if ((protocol == axi_uvm_pkg::e_AXI3) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_4BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI3_MAXBEATCNT) - byte'(addr[1:0]);
                      else if ((protocol == axi_uvm_pkg::e_AXI3) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_8BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI3_MAXBEATCNT) - byte'(addr[2:0]);

                      else if ((protocol == axi_uvm_pkg::e_AXI3) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_16BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI3_MAXBEATCNT) - byte'(addr[3:0]);
                      else if ((protocol == axi_uvm_pkg::e_AXI3) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_32BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI3_MAXBEATCNT) - byte'(addr[4:0]);
                      else if ((protocol == axi_uvm_pkg::e_AXI3) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_64BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI3_MAXBEATCNT) - byte'(addr[5:0]);
                      else if ((protocol == axi_uvm_pkg::e_AXI3) && (burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_128BYTES))
                        len <= ((2**byte'(burst_size)) * c_AXI3_MAXBEATCNT) - byte'(addr[6:0]);
                      // some weird problem with Riviera Pro that won't access those above. so I put them here
                      else if ((burst_type == axi_pkg::e_INCR) && (burst_size == axi_pkg::e_1BYTE)) {
                        if (protocol == axi_uvm_pkg::e_AXI4) {
                          len <= c_AXI4_MAXBEATCNT;
                        } else {
                          len <= c_AXI3_MAXBEATCNT ;
                        }
                          } else {
                         len == 0;
                       }
                          }
//these aredonein post-randomize
//    constraint valid_c { solve len before valid;
//                        valid.size() == len; }
//    constraint data_c {  solve len before data;
//                         data.size() == len; }
//    constraint wstrb_c { solve len before wstrb;
//                         wstrb.size() == len; }

  //constraint wlast_c { solve len before wlast;
    //                    wlast.size() == len/4;
    //                   } //only the last bit is set, do that in post-randomize

    // UVM sequence item functions
    extern function        new        (string name="axi_seq_item");
    extern function string convert2string;
    extern function void   do_copy    (uvm_object rhs);
    extern function bit    do_compare (uvm_object rhs, uvm_comparer comparer);
    extern function void   do_print   (uvm_printer printer);

    extern function void   pre_randomize;
    extern function void   post_randomize;


    extern function void get_beat_N_data(input  int beat_cnt,
                                         input  int      data_bus_bytes,
                                         ref    bit[7:0] data[],
                                         ref    bit      wstrb[],
                                         output bit      wlast);


endclass : axi_seq_item

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function axi_seq_item::new (string name="axi_seq_item");
  super.new(name);


//  foo = new[1];
//  foo[0] = e_2BYTES;

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
    $sformat(s, "%s Protocol: %s", s, protocol.name);
    $sformat(s, "%s Cmd: %s   ", s, cmd.name);
    $sformat(s, "%s Addr = 0x%0x ", s, addr);
    $sformat(s, "%s ID = 0x%0x ",   s, id);
    $sformat(s, "%s Len = 0x%0x (%0d) ",   s, len,len);
    $sformat(s, "%s BurstSize = 0x%0x ",   s, burst_size);
    $sformat(s, "%s BurstType = 0x%0x ",   s, burst_type);
    $sformat(s, "%s BID = 0x%0x",   s, bid);
    $sformat(s, "%s BRESP = 0x%0x",   s, bresp);

/*
    j=data.size();
    sdata="";
    for (int i =0; i< j; i++) begin
       $sformat(sdata, "%s 0x%02x ", sdata, data[i]);
    end
    $sformat(s, "%s Data[]: %s", s, sdata);

    j=valid.size();
    sdata="";
    for (int i =0; i< j; i++) begin
      $sformat(sdata, "%s%0b", sdata, valid[i]);
    end
    $sformat(s, "%s valid[]: %s", s, sdata);


    j=wstrb.size();
    sdata="";
    for (int i =0; i< j; i++) begin
      $sformat(sdata, "%s %b ", sdata, wstrb[i]);
    end
    $sformat(s, "%s wstrb[]: %s", s, sdata);
*/

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


function void axi_seq_item::pre_randomize;
  `uvm_info(this.get_type_name(), "Starting pre_randomize", UVM_HIGH)

  `uvm_info(this.get_type_name(), "Done pre_randomize", UVM_HIGH)
endfunction : pre_randomize

/*! \brief Tweak things after randomization
 *
 * Currenly being used to reset the data[] to incrementing pattern
 * ending with 'FE. This is for easier debugging.
 * More love coming.
*/
function void axi_seq_item::post_randomize;
  int j;
  string valid_s;
  int valid_asserts;
  int valid_assert_bit;

  `uvm_info(this.get_type_name(), "Starting post_randomize", UVM_HIGH)


  super.post_randomize;


  data=new[len];
  wstrb=new[len];
  valid=new[len];  // only need one per beat instead of one per byte,
                     // we won't use the extras.
  // \todo: howto guaranteesufficient valid


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


     valid_asserts = 0;
     j=valid.size();
     for (int i=0;i<j;i++) begin
        valid[i] = $random;
        if (valid[i] == 1'b1) begin
           valid_asserts++;
        end
     end

     // valid must be asserted at least once to avoid never sending data.
     if (valid_asserts==0) begin
       valid_assert_bit=$urandom_range(j-1,0);
       valid[valid_assert_bit] = 1'b1;
       `uvm_info("axi_seq_item.post_randomize()",$sformatf("All zeros. Settin bit %0d to 1", valid_assert_bit), UVM_INFO)
     end

     valid_s="";
     for (int i=0;i<j;i++) begin
        $sformat(valid_s, "%s%0b", valid_s, valid[i]);
     end

     data[len-1] = 'hFE; // specific value to eaily identify last byte
  end // if (cmd == e_WRITE)


//  if ($clog2(len) > (LEN_WIDTH*(2**burst_size)) begin
//    `uvm_error("POST_RANDOMIZATION", $sformatf("LEN OVERRUN ERROR. Protocol = %s.  Len=%0d(0x%0x), burst_size=%0d but LEN_WIDTH=%0d.", protocol.name, len, len, burst_size,LEN_WIDTH))
//  end


  `uvm_info(this.get_type_name(), "Done post_randomize", UVM_HIGH)
  //assert(valid.randomize()) else begin
  //  `uvm_error(this.get_type_name, "Unable to randomize valid");
  //end
endfunction : post_randomize

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
function void axi_seq_item::get_beat_N_data(
  input  int      beat_cnt,
  input  int      data_bus_bytes,
  ref    bit[7:0] data[],
  ref    bit      wstrb[],
  output bit      wlast);

  int Lower_Byte_Lane;
  int Upper_Byte_Lane;
  int data_offset;
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


  last_beat_cnt = axi_pkg::calculate_axlen(.addr         (addr),
                                           .burst_size   (burst_size),
                                           .burst_length (len));
  //last_beat_cnt -= 1;

  if (beat_cnt == last_beat_cnt) begin
     wlast = 1'b1;
  end else begin
     wlast = 1'b0;
  end


  axi_pkg::get_beat_N_byte_lanes(.addr         (addr),
                        .burst_size   (burst_size),
                                 .burst_length (len),
                                 .burst_type   (burst_type),
                        .beat_cnt        (beat_cnt),
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

