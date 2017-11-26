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

/*! \package axi_pkg
 *  \brief enums, defines, typedefs needed in AXI */
package axi_pkg;

// Ugh, we now have a dependency on uvm in the RTL.
// @Todo: check if abstract class can be a simple class and not a component or object
import uvm_pkg::*;
`include "uvm_macros.svh"

import params_pkg::*;


parameter C_AXI_ID_WIDTH = params_pkg::AXI_ID_WIDTH;   /*!< bit width of the ID fields
                                 * - awid
                                 * - wid [AXI3]
                                 * - bid
                                 * - arid
                                 * - rid
                                 */
parameter C_AXI_DATA_WIDTH = params_pkg::AXI_DATA_WIDTH; /*!< bit width of data bus.
                                  * Valid values:
                                  * - 8
                                  * - 16
                                  * - 32
                                  * - 64
                                  * - 128
                                  * - 256
                                  * - 512
                                  * - 1024
                                  */
parameter C_AXI_ADDR_WIDTH = params_pkg::AXI_ADDR_WIDTH; /*!< bit width of address bus.
                                  * Valid values:
                                  * - 32
                                  * - 64
                                  */

parameter C_AXI_LEN_WIDTH = params_pkg::AXI_LEN_WIDTH; /*!< bit width of awlen and arlen bus.
                                  * Valid values:
                                  * - 4 - AXI3
                                  * - 8 - AXI4 (burst_type=e_INCR)
                                  */



/*! \typedef burst_size_t */
/** \brief Size of beat in bytes. (How many bytes of the data bus are used each beat(clk).
*/
typedef enum logic [2:0] {e_1BYTE    = 3'b000, /**< Transfer 1 byte per beat (regardless of bus width) */
                          e_2BYTES   = 3'b001, /**< Transfer 2 bytes per beat (regardles of bus width). Bus must be at least 2-bytes wide */
                          e_4BYTES   = 3'b010, /**< Transfer 4 bytes per beat (regardles of bus width). Bus must be at least 4-bytes wide */
                          e_8BYTES   = 3'b011, /**< Transfer 8 bytes per beat (regardles of bus width). Bus must be at least 8-bytes wide */
                          e_16BYTES  = 3'b100, /**< Transfer 16 bytes per beat (regardles of bus width). Bus must be at least 16-bytes wide */
                          e_32BYTES  = 3'b101, /**< Transfer 32 bytes per beat (regardles of bus width). Bus must be at least 32-bytes wide */
                          e_64BYTES  = 3'b110, /**< Transfer 64 bytes per beat (regardles of bus width). Bus must be at least 64-bytes wide */
                          e_128BYTES = 3'b111 /**< Transfer 128 bytes per beat (regardles of bus width). Bus must be at least 128-bytes wide */
                         } burst_size_t;

/*! \typedef burst_type_t */
/** \brief Does the address stay fixed, increment, or wrap during the burst?
*/
typedef enum logic [1:0] {e_FIXED    = 2'b00, /**< The address doesn't change during the burst. Example: burstin to fifo */
                          e_INCR     = 2'b01, /**< The address increments during the burst. Example: bursting to memmory */
                          e_WRAP     = 2'b10, /**< The address wraps to a lower address once it hits the higher address. Refer to AXI Spec section A3.4.1 for details.  Example:  cache line accesses */
                          e_RESERVED = 2'b11
                         } burst_type_t;

/*! \typedef response_type_t */
/** \brief Write response values
*/
typedef enum logic [1:0] {e_OKAY    = 2'b00, /**< Normal access success. */
                          e_EXOKAY  = 2'b01, /**< Exlusive access okay. */
                          e_SLVERR  = 2'b10, /**< Slave error. Slave received data successfully but wants to return error condition */
                          e_DECERR  = 2'b11  /**< Decode error.  Generated typically by interconnect to signify no slave at that address */
                         } response_type_t;





/*! \struct axi_seq_item_aw_vector_s
 *  \brief This packed struct is used to send write address channel information between the DUT and TB.
 *
 * Packed structs are emulator friendly
 */
typedef struct packed {
  logic [C_AXI_ID_WIDTH-1:0]	 awid;  /*!< Write address ID tag - A matching write response ID, bid, will be expected */
  logic [C_AXI_ADDR_WIDTH-1:0]   awaddr; /*!< Starting burst address */
  logic                          awvalid; /*!< Values on write address channel are valid and won't change until awready is recieved */
  logic                          awready; /*!< Slave is ready to receive write address channel information */
  logic [C_AXI_LEN_WIDTH-1:0]    awlen;   /*!< Length, in beats/clks, of the matching write data burst */
  logic [2:0]                    awsize;  /*!< beat size.  How many bytes wide are the beats in the write data transfer */
  logic [1:0]                    awburst; /*!< address burst mode.  fixed, incrementing, or wrap */
  logic [0:0]                    awlock; /*!< Used for locked transactions in AXI3 */
  logic [3:0]                    awcache; /*!< Memory type. See AXI spec Memory Type A4-65 */
  logic [2:0]                    awprot; /*!< Protected transaction.  AXI4 only */
  logic [3:0]                    awqos; /*!< Quality of service. AXI4 only */

} axi_seq_item_aw_vector_s;

localparam int AXI_SEQ_ITEM_AW_NUM_BITS = $bits(axi_seq_item_aw_vector_s); /*!< Used to calculate the length of the bit vector
                                                                             containing the packed write address struct  */

/** \brief Bit vector containing packed write address channel values */
typedef bit[AXI_SEQ_ITEM_AW_NUM_BITS-1:0] axi_seq_item_aw_vector_t;



/*! \struct axi_seq_item_w_vector_s
 *  \brief This packed struct is used to send write data channel information between the DUT and TB.
 *
 * Packed structs are emulator friendly
 */
typedef struct packed {
  logic [C_AXI_DATA_WIDTH-1:0]   wdata; /*!< Write Data    */
  logic [C_AXI_DATA_WIDTH/8-1:0] wstrb;  /*!< Write strobe.  Indicates which byte lanes hold valid data.    */
  logic                          wlast;/*!<  Write last.  Indicates last beat in a write burst.   */
  logic                          wvalid;/*!<  Write valid.  Values on write data channel are valid and won't change until wready is recieved   */
  logic [C_AXI_ID_WIDTH-1:0]     wid;/*!<  Write ID tag.  AXI3 only   */

} axi_seq_item_w_vector_s;

localparam int AXI_SEQ_ITEM_W_NUM_BITS = $bits(axi_seq_item_w_vector_s);  /*!< Used to calculate the length of the bit vector
                                                                               containing the packed write data struct */

/** \brief Bit vector containing packed write data channel values */
typedef bit[AXI_SEQ_ITEM_W_NUM_BITS-1:0] axi_seq_item_w_vector_t;


/*! \struct axi_seq_item_b_vector_s
 *  \brief This packed struct is used to send write response channel information between the DUT and TB.
 *
 * Packed structs are emulator friendly
 */
typedef struct packed {
  logic [C_AXI_ID_WIDTH-1:0]     bid; /*!< Write Response ID tag    */
  logic [1:0]                    bresp; /*!< Write Response.Indicates status of the write data transaction.    */
} axi_seq_item_b_vector_s;

localparam int AXI_SEQ_ITEM_B_NUM_BITS = $bits(axi_seq_item_b_vector_s); /*!< Used to calculate the length of the bit vector
                                                                              containing the packed write response struct */

/** \brief Bit vector containing packed write response channel values */
typedef bit[AXI_SEQ_ITEM_B_NUM_BITS-1:0] axi_seq_item_b_vector_t;

/*! \struct axi_seq_item_ar_vector_s
 *  \brief This packed struct is used to send read address channel information between the DUT and TB.
 *
 * Packed structs are emulator friendly
 */
typedef struct packed {
  logic [C_AXI_ID_WIDTH-1:0]	 arid; /*!< Read address ID tag - A matching read data ID, rid, will be expected */
  logic [C_AXI_ADDR_WIDTH-1:0]   araddr; /*!< Starting burst address */
  logic                          arvalid;/*!< Values on read address channel are valid and won't change until arready is recieved */
  logic                          arready;/*!< Slave is ready to receive read address channel information */
  logic [C_AXI_LEN_WIDTH-1:0]    arlen;/*!< Length, in beats/clks, of the matching read data burst */
  logic [2:0]  arsize;/*!< beat size.  How many bytes wide are the beats in the write data transfer */
  logic [1:0]  arburst;/*!< address burst mode.  fixed, incrementing, or wrap */
  logic [0:0]                    arlock; /*!< Used for locked transactions in AXI3 */
  logic [3:0]                    arcache;/*!< Memory type. See AXI spec Memory Type A4-65 */
  logic [2:0]                    arprot;/*!< Protected transaction.  AXI4 only */
  logic [3:0]                    arqos;/*!< Quality of service. AXI4 only */

} axi_seq_item_ar_vector_s;

localparam int AXI_SEQ_ITEM_AR_NUM_BITS = $bits(axi_seq_item_ar_vector_s);    /*!< Used to calculate the length of the bit vector
                                                                                   containing the packed read address struct */

/** \brief Bit vector containing packed read address channel values */
typedef bit[AXI_SEQ_ITEM_AR_NUM_BITS-1:0] axi_seq_item_ar_vector_t;


/*! \struct axi_seq_item_r_vector_s
 *  \brief This packed struct is used to send read data channel information between the DUT and TB.
 *
 * Packed structs are emulator friendly
 */
typedef struct packed {
  logic [C_AXI_DATA_WIDTH-1:0]   rdata; /*!< Write Data  */
  logic [1:0]                    rresp; /*!< Read Response.Indicates status of the read data transfer (of the same beat). */
  logic                          rlast; /*!< Read last.  Indicates last beat in a read burst. */
  logic                          rvalid; /*!< Write valid.  Values on read data channel are valid and won't change until rready is recieved*/
  logic [C_AXI_ID_WIDTH-1:0]     rid; /*!< Read ID tag. */

} axi_seq_item_r_vector_s;

localparam int AXI_SEQ_ITEM_R_NUM_BITS = $bits(axi_seq_item_r_vector_s);     /*!< Used to calculate the length of the bit vector
                                                                                  containing the packed read data struct */

/** \brief Bit vector containing packed read data channel values */
typedef bit[AXI_SEQ_ITEM_R_NUM_BITS-1:0] axi_seq_item_r_vector_t;

/** \brief calculate burst_size aligned address
 *
 * The AXI function to calculate aligned address is:
 * Aligned_Address = (Address/(2**burst_size)*(2**burst_size)
 * Zeroing out the bottom burst_size bits does the same thing
 * which is much more eaily synthesizable.
 * @param address - starting address
 * @param burst_size - how many bytes wide is the beat
 * @returns the burst_size aligned address
*/
function bit [C_AXI_ADDR_WIDTH-1:0] calculate_burst_aligned_address(
  input bit [C_AXI_ADDR_WIDTH-1:0] address,
  input bit [2:0]                  burst_size);


  bit [C_AXI_ADDR_WIDTH-1:0] aligned_address;

  // This can be done in a nice function, but this case
  // is immediatly understandable.
  aligned_address = address;
  case (burst_size)
    e_1BYTE    : aligned_address      = address;
    e_2BYTES   : aligned_address[0]   = 1'b0;
    e_4BYTES   : aligned_address[1:0] = 2'b00;
    e_8BYTES   : aligned_address[2:0] = 3'b000;
    e_16BYTES  : aligned_address[3:0] = 4'b0000;
    e_32BYTES  : aligned_address[4:0] = 5'b0_0000;
    e_64BYTES  : aligned_address[5:0] = 6'b00_0000;
    e_128BYTES : aligned_address[6:0] = 7'b000_0000;
  endcase

  `uvm_info("axi_pkg::calculatate-aligned_adress",
            $sformatf("address: 0x%0x burst_size:%0d alignedaddress: 0x%0x",
                      address, burst_size, aligned_address),
            UVM_HIGH)

  return aligned_address;

endfunction : calculate_burst_aligned_address


/** \brief calculate bus-siz aligned address
 *
 * The AXI function to calculate aligned address is:
 * Aligned_Address = (Address/(2**bus_size)*(2**bus_sze)
 * Zeroing out the bottom burst_size bits does the same thing
 * which is much more eaily synthesizable.
 * @param addr - starting address
 * @param bus_size - how many bytes wide is the bus
 * @returns the bus_size aligned address
 * \todo: bus_size could be byte instead of int?
*/
function bit [C_AXI_ADDR_WIDTH-1:0] calculate_bus_aligned_address(
  input bit [C_AXI_ADDR_WIDTH-1:0] addr,
  input int                       bus_size);

  bit [C_AXI_ADDR_WIDTH-1:0] aligned_address;

  string msg_s;

  aligned_address = addr;

  case (bus_size)
    2**e_1BYTE    : aligned_address      = addr;
    2**e_2BYTES   : aligned_address[0]   = 1'b0;
    2**e_4BYTES   : aligned_address[1:0] = 2'b00;
    2**e_8BYTES   : aligned_address[2:0] = 3'b000;
    2**e_16BYTES  : aligned_address[3:0] = 4'b0000;
    2**e_32BYTES  : aligned_address[4:0] = 5'b0_0000;
    2**e_64BYTES  : aligned_address[5:0] = 6'b00_0000;
    2**e_128BYTES : aligned_address[6:0] = 7'b000_0000;
  endcase


  msg_s="";
  $sformat(msg_s, "%s addr: 0x%0x", msg_s, addr);
  $sformat(msg_s, "%s aligned_address: 0x%0x", msg_s, aligned_address);
  $sformat(msg_s, "%s bus_size: 0x%0x", msg_s, bus_size);



  `uvm_info("calculate_bus_aligned_address", msg_s,UVM_HIGH)

  return aligned_address;

endfunction : calculate_bus_aligned_address


/** \brief calculate awlen or arlen
 *
 *  Calculate the number of beats -1
 * for a burst.  Subtract one because
 * awlen and arlen are one less than
 * the transfer count.  awlen=0,
 * means 1 beat.
 * @param addr - starting address
 * @param burst_size - how many bytes wide is the beat
 * @param burst_length - how many bytes long is the burst
 * @returns the burst_size aligned address
*/
function bit [C_AXI_LEN_WIDTH-1:0] calculate_axlen(
  input bit [C_AXI_ADDR_WIDTH-1:0] addr,
  input bit [2:0]                  burst_size,
  input shortint                   burst_length);


  byte unalignment_offset;
  shortint total_length;
  shortint shifter;
  shortint ishifter;
  bit [C_AXI_LEN_WIDTH-1:0] beats;

  string msg_s;

  unalignment_offset = calculate_unalignment_offset(
                            .addr(addr),
                            .burst_size(burst_size));

  total_length=burst_length + unalignment_offset;

  shifter = shortint'(total_length/(2**burst_size));

  ishifter = shifter*(2**burst_size);

  if (ishifter != total_length) begin
    shifter += 1;
  end

  beats = shifter - 1;


  msg_s="";
  $sformat(msg_s, "%s addr: 0x%0x",     msg_s, addr);
  $sformat(msg_s, "%s burst_size: %0d", msg_s, burst_size);
  $sformat(msg_s, "%s unalignment_offset: %0d", msg_s, unalignment_offset);
  $sformat(msg_s, "%s burst_length: %0d", msg_s, burst_length);
  $sformat(msg_s, "%s total_length: %0d", msg_s, total_length);
  $sformat(msg_s, "%s shifter: %0d", msg_s, shifter);
  $sformat(msg_s, "%s ishifter: %0d", msg_s, ishifter);

  `uvm_info("axi_pkg::calculate_beats",
            msg_s,
            UVM_HIGH)

  return beats;

endfunction : calculate_axlen

/** \brief calculate how unaligned the address is from the burst size
 *
 * @param addr - starting address
 * @param burst_size - how many bytes wide is the beat
 * @returns how many bytes the address is unaligned from the burst_size
*/
function byte calculate_unalignment_offset(
  input bit [C_AXI_ADDR_WIDTH-1:0] addr,
  input byte                  burst_size);

  byte unalignment_offset;

    case (burst_size)
      e_1BYTE    : unalignment_offset = 0;
      e_2BYTES   : unalignment_offset = byte'(addr[0]);
      e_4BYTES   : unalignment_offset = byte'(addr[1:0]);
      e_8BYTES   : unalignment_offset = byte'(addr[2:0]);
      e_16BYTES  : unalignment_offset = byte'(addr[3:0]);
      e_32BYTES  : unalignment_offset = byte'(addr[4:0]);
      e_64BYTES  : unalignment_offset = byte'(addr[5:0]);
      e_128BYTES : unalignment_offset = byte'(addr[6:0]);
  endcase

  return unalignment_offset;


endfunction : calculate_unalignment_offset


/** \brief calculate the wrap boundaries for a given burst
 *
 * @param addr - starting address
 * @param burst_size - how many bytes wide is the beat
 * @param burst_length - how many bytes is the burst
 * @return Lower_Wrap_Boundary - Lower Wrap Boundary Address
 * @return Upper_Wrap_Boundary - Upper Wrap Boundary Address
 * \todo: simplify the logic needed for the math in this function
*/
function void calculate_wrap_boundary(
  input bit [C_AXI_ADDR_WIDTH-1:0] addr,
  input bit [2:0]                  burst_size,
  input shortint                   burst_length,
  output bit [C_AXI_ADDR_WIDTH-1:0] Lower_Wrap_Boundary,
  output bit [C_AXI_ADDR_WIDTH-1:0] Upper_Wrap_Boundary);


  int max_beat_cnt;
  int dtsize;
  bit [C_AXI_ADDR_WIDTH-1:0] Aligned_Address;

  max_beat_cnt = calculate_axlen(.addr         (addr),
                                 .burst_size   (burst_size),
                                 .burst_length (burst_length)) + 1;

  Aligned_Address=calculate_burst_aligned_address(.address(addr),
                                            .burst_size(burst_size));


  dtsize = (2**burst_size) * max_beat_cnt;

  Lower_Wrap_Boundary = (int'(Aligned_Address/dtsize) * dtsize);
  Upper_Wrap_Boundary = Lower_Wrap_Boundary + dtsize;

endfunction : calculate_wrap_boundary


/*! \brief Get next address for reading/writing to memory
 *
 * Takes into account burst_type. IE: e_FIXED, e_INCR, e_WRAP
 * This function is stateful.  When called it updates an internal variable that holds the current address.
 * @param addr - starting address
 * @param burst_size - how many bytes wide is the beat
 * @param burst_length - how many bytes is the burst
 * @param burst_type - Fixed, Incrementing or Wrap
 * @param beat_cnt - beat count the memory address corresponds to. Used with lane.
 * @param lane - lane thememory address correspons to. Usedwith beat_cnt
 * @param data_bus_bytes - how wide is the bus?
 * @return memory address that corresponds to the addr + beat_cnt/lane byte
 */
function bit[C_AXI_ADDR_WIDTH-1:0] get_next_address(
  input bit [C_AXI_ADDR_WIDTH-1:0] addr,
  input bit [2:0]                  burst_size,
  input shortint                   burst_length,
  input bit [1:0]                  burst_type,
  input int beat_cnt,
  input int lane,
  input int data_bus_bytes);

  bit [C_AXI_ADDR_WIDTH-1:0] tmp_addr;

  int Lower_Byte_Lane;
  int Upper_Byte_Lane;
  int data_offset;
  int Lower_Wrap_Boundary;
  int Upper_Wrap_Boundary;
  string s;
  string msg_s;


  calculate_wrap_boundary(.addr                (addr),
                          .burst_size          (burst_size),
                          .burst_length        (burst_length),
                          .Lower_Wrap_Boundary (Lower_Wrap_Boundary),
                          .Upper_Wrap_Boundary (Upper_Wrap_Boundary));

  get_beat_N_byte_lanes(.addr         (addr),
                        .burst_size   (burst_size),
                        .burst_length (burst_length),
                        .burst_type   (burst_type),
                        .beat_cnt     (beat_cnt),
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
    `uvm_error("AXI_PKG::get_next_address", $sformatf("Unknown burst_type: %0d", burst_type))
  end

  msg_s="";

  $sformat(msg_s, "%s beat_cnt:%0d",              msg_s, beat_cnt);
 // $sformat(msg_s, "%s max_beat_cnt:%0d",          msg_s, max_beat_cnt);
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




 /*! \brief return byte lanes that contain valid data
 *
 * given the beat number and how wide the bus is, return
 * which lanes to get data from and also what offset from start address
 * to write to.
 *
 * @param addr - starting address
 * @param burst_size - how many bytes wide is the beat
 * @param burst_length - how many bytes is the burst
 * @param burst_type - Fixed, Incrementing or Wrap
 * @param beat_cnt which beat in the burst, starting at 0.
 * @param data_bus_bytes - how wide is the bus (the driver/responder can get this from the interface
 * @param Lower_Byte_Lane - Lower valid byte lane
 * @param Upper_Byte_Lane - Upper valid byte lane
 * @param offset - offset from Start_Address.  Can be used to write to memory.
 */
function void get_beat_N_byte_lanes(
  input bit       [C_AXI_ADDR_WIDTH-1:0] addr,
  input bit [2:0] burst_size,
  input shortint  burst_length,
  input bit [1:0]                  burst_type,
  input  int beat_cnt,
  input  int data_bus_bytes,
  output int Lower_Byte_Lane,
  output int Upper_Byte_Lane,
  output int offset);



   bit [63:0] Aligned_Start_Address;
  bit [63:0] Address_N;
  bit [63:0] Bus_Aligned_Address;
  bit [63:0] Bus_Aligned_Address_N;

  string s;
  string msg_s;

  int a;
  int b;

  Aligned_Start_Address=calculate_burst_aligned_address(.address(addr),
                                                  .burst_size(burst_size));
  Address_N = Aligned_Start_Address+(beat_cnt*(2**burst_size));



  // **********************
 // a = int'(addr/data_bus_bytes) * data_bus_bytes;
  Bus_Aligned_Address = calculate_bus_aligned_address(.addr(addr),
                                                  .bus_size(data_bus_bytes));
  Bus_Aligned_Address_N = calculate_bus_aligned_address(.addr(Address_N),
                                                  .bus_size(data_bus_bytes));


    // Adjust Lower_Byte_lane up if unaligned.
      if (burst_type == e_FIXED) begin
      //  if (beat_cnt==0) begin
           Lower_Byte_Lane = addr - Bus_Aligned_Address;
           Upper_Byte_Lane = Aligned_Start_Address + (2**burst_size) - 1 -
                             Bus_Aligned_Address;

           offset = beat_cnt*(2**burst_size);


      end  else begin

        if (beat_cnt==0) begin
           Lower_Byte_Lane = addr - Bus_Aligned_Address;
           Upper_Byte_Lane = Aligned_Start_Address + (2**burst_size) - 1 -
                             Bus_Aligned_Address;

           offset = 0;

        end else begin
           Lower_Byte_Lane = Address_N - Bus_Aligned_Address_N;
           Upper_Byte_Lane = Lower_Byte_Lane + (2**burst_size) - 1;

           offset = Address_N - addr;
        end
      end

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




`include "axi_if_abstract.svh"

endpackage : axi_pkg
