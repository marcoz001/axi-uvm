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

/*! \package axi_pkg
 *  \brief enums, defines, typedefs needed in AXI */
package axi_pkg;

// Ugh, we now have a dependency on uvm in the RTL.
// @Todo: check if abstract class can be a simple class and not a component or object
import uvm_pkg::*;
`include "uvm_macros.svh"


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


parameter C_AXI_ID_WIDTH = 6;   /*!< bit width of the ID fields
                                 * - awid
                                 * - wid [AXI3]
                                 * - bid
                                 * - arid
                                 * - rid
                                 */
parameter C_AXI_DATA_WIDTH = 32; /*!< bit width of data bus.
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
parameter C_AXI_ADDR_WIDTH = 32; /*!< bit width of address bus.
                                  * Valid values:
                                  * - 32
                                  * - 64
                                  */


/*! \struct axi_seq_item_aw_vector_s
 *  \brief This packed struct is used to send write address channel information between the DUT and TB.
 *
 * Packed structs are emulator friendly
 */
typedef struct packed {
  logic [C_AXI_ID_WIDTH-1:0]	 awid;  //*<YOOHOO
  logic [C_AXI_ADDR_WIDTH-1:0]   awaddr; /*!< an integer value */
  logic                          awvalid;
  logic                          awready;
  logic [7:0]                    awlen;
  logic [2:0]                    awsize;
  logic [1:0]                    awburst;
  logic [0:0]                    awlock;
  logic [3:0]                    awcache;
  logic [2:0]                    awprot;
  logic [3:0]                    awqos;

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
  logic [C_AXI_DATA_WIDTH-1:0]   wdata;
  logic [C_AXI_DATA_WIDTH/8-1:0] wstrb;
  logic                          wlast;
  logic                          wvalid;
  logic [C_AXI_ID_WIDTH-1:0]     wid;

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
  logic [C_AXI_ID_WIDTH-1:0]     bid;
  logic [1:0]                    bresp;
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
                                 /*! Read Address ID */
  logic [C_AXI_ID_WIDTH-1:0]	 arid;
  logic [C_AXI_ADDR_WIDTH-1:0]   araddr;
  logic                          arvalid;
  logic                          arready;
  logic [7:0]                    arlen;
  logic [2:0]  arsize;
  logic [1:0]  arburst;
  logic [0:0]                    arlock;
  logic [3:0]                    arcache;
  logic [2:0]                    arprot;
  logic [3:0]                    arqos;

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
  logic [C_AXI_DATA_WIDTH-1:0]   rdata; /*!< an integer value */
  logic [1:0]                    rresp; /*!< an integer value */
  logic                          rlast; /*!< an integer value */
  logic                          rvalid; /*!< an integer value */
  logic [C_AXI_ID_WIDTH-1:0]     rid; /*!< an integer value */

} axi_seq_item_r_vector_s;

localparam int AXI_SEQ_ITEM_R_NUM_BITS = $bits(axi_seq_item_r_vector_s);     /*!< Used to calculate the length of the bit vector
                                                                                  containing the packed read data struct */

/** \brief Bit vector containing packed read data channel values */
typedef bit[AXI_SEQ_ITEM_R_NUM_BITS-1:0] axi_seq_item_r_vector_t;


`include "axi_if_abstract.svh"

endpackage : axi_pkg