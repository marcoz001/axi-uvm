////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_pkg.sv
//
// Purpose:	
//          enums, defines, typedefs needed in AXI 
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

package axi_pkg;

// Ugh, we now have a dependency on uvm in the RTL.
// @Todo: check if abstract class can be a simple class and not a component or object
import uvm_pkg::*;
`include "uvm_macros.svh"



//AXI ENUMS...


//typedef enum {e_DRIVER, e_RESPONDER} driver_type_t;

typedef enum logic [2:0] {e_1BYTE    = 3'b000,
                          e_2BYTES   = 3'b001,
                          e_4BYTES   = 3'b010,
                          e_8BYTES   = 3'b011,
                          e_16BYTES  = 3'b100,
                          e_32BYTES  = 3'b101,
                          e_64BYTES  = 3'b110,
                          e_128BYTES = 3'b111 } burst_size_t;

typedef enum logic [1:0] {e_FIXED    = 2'b00,
                          e_INCR     = 2'b01,
                          e_WRAP     = 2'b10,
                          e_RESERVED = 2'b11 } burst_type_t;

typedef enum logic [1:0] {e_OKAY    = 2'b00,
                          e_EXOKAY  = 2'b01,
                          e_SLVERR  = 2'b10,
                          e_DECERR  = 2'b11} response_type_t;


parameter C_AXI_ID_WIDTH = 6;
parameter C_AXI_DATA_WIDTH = 32;
parameter C_AXI_ADDR_WIDTH = 32;


typedef struct packed {
  logic [C_AXI_ID_WIDTH-1:0]	 awid;
  logic [C_AXI_ADDR_WIDTH-1:0]   awaddr;
  logic                          awvalid;
  logic                          awready;
  logic [7:0]                    awlen;
//  burst_size_t                    awsize;
//  burst_type_t                    awburst;
  logic [2:0]  awsize;
  logic [1:0]  awburst;
  logic [0:0]                    awlock;
  logic [3:0]                    awcache;
  logic [2:0]                    awprot;
  logic [3:0]                    awqos;
  
} axi_seq_item_aw_vector_s;

localparam int AXI_SEQ_ITEM_AW_NUM_BITS = $bits(axi_seq_item_aw_vector_s);
typedef bit[AXI_SEQ_ITEM_AW_NUM_BITS-1:0] axi_seq_item_aw_vector_t;



typedef struct packed {
  logic [C_AXI_DATA_WIDTH-1:0]   wdata;
  logic [C_AXI_DATA_WIDTH/8-1:0] wstrb;
  logic                          wlast;
  logic                          wvalid;
  logic [C_AXI_ID_WIDTH-1:0]     wid;
  
} axi_seq_item_w_vector_s;

localparam int AXI_SEQ_ITEM_W_NUM_BITS = $bits(axi_seq_item_w_vector_s);
typedef bit[AXI_SEQ_ITEM_W_NUM_BITS-1:0] axi_seq_item_w_vector_t;


typedef struct packed {
  logic [C_AXI_ID_WIDTH-1:0]     bid;
  logic [1:0]                    bresp;
} axi_seq_item_b_vector_s;

localparam int AXI_SEQ_ITEM_B_NUM_BITS = $bits(axi_seq_item_b_vector_s);
typedef bit[AXI_SEQ_ITEM_B_NUM_BITS-1:0] axi_seq_item_b_vector_t;

`include "axi_if_abstract.svh"

endpackage : axi_pkg
