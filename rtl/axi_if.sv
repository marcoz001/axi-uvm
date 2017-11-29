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
//! bindable interface for AXI UVM environment
/*! This interface contains all functions and tasks for the testbench
 * to communicate with the DUT.  They are meant to be called using the
 * embedded class axi_if_concrete, which extends axi_if_abstract.
  @see axi_if_abstract.sv
*/
interface axi_if #(
                      parameter C_AXI_ID_WIDTH   = 6,
                      parameter C_AXI_ADDR_WIDTH = 32,
                      parameter C_AXI_DATA_WIDTH = 32,
                      parameter C_AXI_LEN_WIDTH = 8
                     )(
                     input wire clk,
                     input wire reset,

                     inout wire                          awready,  // Slave is ready to accept
                     inout wire [C_AXI_ID_WIDTH-1:0]	 awid,     // Write ID
                     inout wire [C_AXI_ADDR_WIDTH-1:0]   awaddr,   // Write address
                     inout wire [C_AXI_LEN_WIDTH-1:0]    awlen,    // Write Burst Length
                     inout wire [2:0]                    awsize,   // Write Burst size
                     inout wire [1:0]                    awburst,  // Write Burst type
                     inout wire [0:0]                    awlock,   // Write lock type
                     inout wire [3:0]                    awcache,  // Write Cache type
                     inout wire [2:0]                    awprot,   // Write Protection type
                     inout wire [3:0]                    awqos,    // Write Quality of Svc
                     inout wire                          awvalid,  // Write address valid

                     // AXI write data channel signals
                     inout wire                          wready,  // Write data ready
                     inout wire [C_AXI_DATA_WIDTH-1:0]   wdata,   // Write data
                     inout wire [C_AXI_DATA_WIDTH/8-1:0] wstrb,   // Write strobes
                     inout wire                          wlast,   // Last write transaction
                     inout wire                          wvalid,  // Write valid

                     // AXI write response channel signals
                     inout wire [C_AXI_ID_WIDTH-1:0]     bid,     // Response ID
                     inout wire [1:0]                    bresp,   // Write response
                     inout wire                          bvalid,  // Write reponse valid
                     inout wire                          bready,   // Response ready

                     // AXI read address channel signals
                     inout  wire                         arready, // Read address ready
                     inout  wire [C_AXI_ID_WIDTH-1:0]    arid,    // Read ID
                     inout  wire [C_AXI_ADDR_WIDTH-1:0]  araddr,  // Read address
                     inout  wire [C_AXI_LEN_WIDTH-1:0]   arlen,   // Read Burst Length
                     inout  wire [2:0]                   arsize,  // Read Burst size
                     inout  wire [1:0]                   arburst, // Read Burst type
                     inout  wire [0:0]                   arlock,  // Read lock type
                     inout  wire [3:0]                   arcache, // Read Cache type
                     inout  wire [2:0]                   arprot,  // Read Protection type
                     inout  wire [3:0]                   arqos,   // Read Protection type
                     inout  wire                         arvalid, // Read address valid

                     // AXI read data channel signals
                     inout  wire [C_AXI_ID_WIDTH-1:0]    rid,    // Response ID
                     inout  wire [1:0]                   rresp,  // Read response
                     inout  wire                         rvalid, // Read reponse valid
                     inout  wire [C_AXI_DATA_WIDTH-1:0]  rdata,  // Read data
                     inout  wire                         rlast,  // Read last
                     inout  wire                         rready  // Read Response ready
                    );
  import axi_pkg::*;



  logic [C_AXI_ID_WIDTH-1:0]	 iawid;
  logic [C_AXI_ADDR_WIDTH-1:0]   iawaddr;
  logic                          iawvalid;
  logic                          iawready;
  logic [C_AXI_LEN_WIDTH-1:0]    iawlen;
  logic [2:0]                    iawsize;
  logic [1:0]                    iawburst;
  logic [0:0]                    iawlock;
  logic [3:0]                    iawcache;
  logic [2:0]                    iawprot;
  logic [3:0]                    iawqos;

                     // AXI write data channel signals
  logic                          iwready;
  logic [C_AXI_DATA_WIDTH-1:0]   iwdata;
  logic [C_AXI_DATA_WIDTH/8-1:0] iwstrb;
  logic                          iwlast;
  logic                          iwvalid;

                     // AXI write response channel signals
  logic [C_AXI_ID_WIDTH-1:0]     ibid;
  logic [1:0]                    ibresp;
  logic                          ibvalid;
  logic                          ibready;

   // AXI read address channel signals
  logic                          iarready;
  logic  [C_AXI_ID_WIDTH-1:0]    iarid;
  logic  [C_AXI_ADDR_WIDTH-1:0]  iaraddr;
  logic  [C_AXI_LEN_WIDTH-1:0]   iarlen;
  logic  [2:0]                   iarsize;
  logic  [1:0]                   iarburst;
  logic  [0:0]                   iarlock;
  logic  [3:0]                   iarcache;
  logic  [2:0]                   iarprot;
  logic  [3:0]                   iarqos;
  logic                          iarvalid;

                     // AXI read data channel signals
  logic [C_AXI_ID_WIDTH-1:0]     irid;
  logic [1:0]                    irresp;
  logic                          irvalid;
  logic [C_AXI_DATA_WIDTH-1:0]   irdata;
  logic                          irlast;
  logic                          irready;


  logic [31:0] awready_toggle_pattern;
  bit          awready_toggle_pattern_enable=0;

  logic [31:0]  wready_toggle_pattern;
  bit           wready_toggle_pattern_enable=0;

  logic [31:0]  bready_toggle_pattern;
  bit           bready_toggle_pattern_enable=0;

  logic [31:0]  arready_toggle_pattern;
  bit           arready_toggle_pattern_enable=0;

  logic [31:0]  rready_toggle_pattern;
  bit           rready_toggle_pattern_enable=0;

  assign awid    = iawid;
  assign awaddr  = iawaddr;
  assign awvalid = iawvalid;
  assign awready = iawready;
  assign awlen   = iawlen;
  assign awsize  = iawsize;
  assign awburst = iawburst;
  assign awlock  = iawlock;
  assign awcache = iawcache;
  assign awprot  = iawprot;
  assign awqos   = iawqos;

  assign wready  = iwready;
  assign wdata   = iwdata;
  assign wstrb   = iwstrb;
  assign wlast   = iwlast;
  assign wvalid  = iwvalid;

  assign bid     = ibid;
  assign bresp   = ibresp;
  assign bvalid  = ibvalid;
  assign bready  = ibready;

  assign arready = iarready;
  assign arid    = iarid;
  assign araddr  = iaraddr;
  assign arlen   = iarlen;
  assign arsize  = iarsize;
  assign arburst = iarburst;
  assign arlock  = iarlock;
  assign arcache = iarcache;
  assign arprot  = iarprot;
  assign arqos   = iarqos;
  assign arvalid = iarvalid;

  assign rid     = irid;
  assign rresp   = irresp;
  assign rvalid  = irvalid;
  assign rdata   = irdata;
  assign rlast   = irlast;
  assign rready  = irready;


  initial begin
     iawid    = 'z;
     iawaddr  = 'z;
     iawvalid = 'z;
     iawready = 'z;
     iawlen   = 'z;
     iawsize  = 'z;
     iawburst = 'z;
     iawlock  = 'z;
     iawcache = 'z;
     iawprot  = 'z;
     iawqos   = 'z;

     iwready = 'z;
     iwdata  = 'z;
     iwstrb  = 'z;
     iwlast  = 'z;
     iwvalid = 'z;

     ibid    = 'z;
     ibresp  = 'z;
     ibvalid = 'z;
     ibready = 'z;

     iarready = 'z;
     iarid    = 'z;
     iaraddr  = 'z;
     iarlen   = 'z;
     iarsize  = 'z;
     iarburst = 'z;
     iarlock  = 'z;
     iarcache = 'z;
     iarprot  = 'z;
     iarqos   = 'z;
     iarvalid = 'z;

     irid     = 'z;
     irresp   = 'z;
     irvalid  = 'z;
     irdata   = 'z;
     irlast   = 'z;
     irready  = 'z;

  end



//  extern task  write(bit [63:0] addr, bit [63:0] data);

 //  driver_type_t m_type;

 import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_if_concrete extends axi_if_abstract;
  `uvm_object_utils(axi_if_concrete)

function new (string name="axi_if_concrete");
    super.new(name);
endfunction : new

function int get_data_bus_width;
   return C_AXI_DATA_WIDTH;
endfunction : get_data_bus_width

// wait for n clock cycles. Default: 1
task wait_for_clks(int cnt=1);
    if (cnt==0) return;

    repeat (cnt) @(posedge clk);
endtask : wait_for_clks

task wait_for_not_in_reset;
    wait (reset == 1'b0);
endtask : wait_for_not_in_reset;

task wait_for_awready_awvalid;

  if (awready == 1'b1 && awvalid == 1'b1)
    return;
  else  if (awvalid == 1'b1)
    @(posedge awready);
  else  if (awready == 1'b1)
    @(posedge awvalid);
  else
    @(posedge awvalid or posedge awready)  wait_for_awready_awvalid();

endtask : wait_for_awready_awvalid

task wait_for_awvalid;
  @(posedge awvalid);
endtask : wait_for_awvalid;

task wait_for_wready;
  while (wready != 1'b1)
    wait_for_clks(.cnt(1));
endtask : wait_for_wready

task wait_for_bvalid;
  @(posedge bvalid);
endtask : wait_for_bvalid

task wait_for_write_address(output axi_seq_item_aw_vector_s s);
    //wait_for_awready_awvalid();
  forever begin
    @(posedge clk) begin
      if (awready == 1'b1 && awvalid== 1'b1) begin
        read_aw(.s(s));
        return;
      end
    end
  end
endtask : wait_for_write_address

task wait_for_write_data(output axi_seq_item_w_vector_s s);

  forever begin
    @(posedge clk) begin
      if (wready == 1'b1 && wvalid== 1'b1) begin
        read_w(.s(s));
        return;
      end
    end
  end
endtask : wait_for_write_data

task wait_for_write_response(output axi_seq_item_b_vector_s s);

  forever begin
    @(posedge clk) begin
      if (bready == 1'b1 && bvalid== 1'b1) begin
        read_b(.s(s));
        return;
      end
    end
  end
endtask : wait_for_write_response

task wait_for_read_address(output axi_seq_item_ar_vector_s s);
    //wait_for_awready_awvalid();
  forever begin
    @(posedge clk) begin
      if (arready == 1'b1 && arvalid== 1'b1) begin
        read_ar(.s(s));
        return;
      end
    end
  end
endtask : wait_for_read_address

task wait_for_read_data(output axi_seq_item_r_vector_s s);

  forever begin
    @(posedge clk) begin
      if (rready == 1'b1 && rvalid== 1'b1) begin
        read_r(.s(s));
        return;
      end
    end
  end
endtask : wait_for_read_data

function bit get_awready_awvalid;
  return awready & awvalid;
endfunction : get_awready_awvalid;

function bit get_awready;
  return awready;
endfunction : get_awready;

function bit get_wready_wvalid;
  return wvalid & wready;
endfunction : get_wready_wvalid;

function bit get_wvalid;
  return wvalid;
endfunction : get_wvalid

function bit get_wready;
  return wready;
endfunction : get_wready

function bit get_bready_bvalid;
  return bready & bvalid;
endfunction : get_bready_bvalid;

function bit get_bvalid;
  return bvalid;
endfunction : get_bvalid

function bit get_bready;
  return bready;
endfunction : get_bready

function bit get_arready_arvalid;
  return arready & arvalid;
endfunction : get_arready_arvalid;

function bit get_arready;
  return arready;
endfunction : get_arready;

function bit get_rready_rvalid;
  return rvalid & rready;
endfunction : get_rready_rvalid;

function bit get_rvalid;
  return rvalid;
endfunction : get_rvalid

function bit get_rready;
  return rready;
endfunction : get_rready

task set_awvalid(bit state);
  wait_for_clks(.cnt(1));
  iawvalid <= state;
endtask : set_awvalid

task set_awready(bit state);
    wait_for_clks(.cnt(1));
    iawready <= state;
endtask : set_awready

task set_wvalid(bit state);
  wait_for_clks(.cnt(1));
  iwvalid <= state;
endtask : set_wvalid

task set_wready(bit state);
  wait_for_clks(.cnt(1));
    iwready <= state;
endtask : set_wready

task set_bvalid(bit state);
  wait_for_clks(.cnt(1));
  ibvalid <= state;
endtask : set_bvalid

task set_bready(bit state);
  wait_for_clks(.cnt(1));
    ibready <= state;
endtask : set_bready

task set_arvalid(bit state);
  wait_for_clks(.cnt(1));
  iarvalid <= state;
endtask : set_arvalid

task set_rvalid(bit state);
  wait_for_clks(.cnt(1));
  irvalid <= state;
endtask : set_rvalid

task set_rready(bit state);
  wait_for_clks(.cnt(1));
    irready <= state;
endtask : set_rready

function void enable_awready_toggle_pattern(bit [31:0] pattern);
    awready_toggle_pattern=pattern;
    awready_toggle_pattern_enable=1;
endfunction : enable_awready_toggle_pattern

function void disable_awready_toggle_pattern();
     awready_toggle_pattern_enable = 0;
endfunction : disable_awready_toggle_pattern

function void enable_wready_toggle_pattern(bit [31:0] pattern);
    wready_toggle_pattern=pattern;
    wready_toggle_pattern_enable=1;
endfunction : enable_wready_toggle_pattern

function void disable_wready_toggle_pattern();
     wready_toggle_pattern_enable = 0;
endfunction : disable_wready_toggle_pattern

function void enable_bready_toggle_pattern(bit [31:0] pattern);
    bready_toggle_pattern=pattern;
    bready_toggle_pattern_enable=1;
endfunction : enable_bready_toggle_pattern

function void disable_bready_toggle_pattern();
     bready_toggle_pattern_enable = 0;
endfunction : disable_bready_toggle_pattern

function void enable_arready_toggle_pattern(bit [31:0] pattern);
    arready_toggle_pattern=pattern;
    arready_toggle_pattern_enable=1;
endfunction : enable_arready_toggle_pattern

function void disable_arready_toggle_pattern();
     arready_toggle_pattern_enable = 0;
endfunction : disable_arready_toggle_pattern

function void enable_rready_toggle_pattern(bit [31:0] pattern);
    rready_toggle_pattern=pattern;
    rready_toggle_pattern_enable=1;
endfunction : enable_rready_toggle_pattern

function void disable_rready_toggle_pattern();
     rready_toggle_pattern_enable = 0;
endfunction : disable_rready_toggle_pattern


function void write_aw(axi_seq_item_aw_vector_s s, bit valid=1'b1);

     iawvalid <= valid;
     iawid    <= s.awid;
     iawaddr  <= s.awaddr;
     iawlen   <= s.awlen;
     iawsize  <= s.awsize;
     iawburst <= s.awburst;
     iawlock  <= s.awlock;
     iawcache <= s.awcache;
     iawprot  <= s.awprot;
     iawqos   <= s.awqos;


endfunction : write_aw


function void write_w(axi_seq_item_w_vector_s  s);

    iwvalid <= s.wvalid;
    iwdata  <= s.wdata;
    iwstrb  <= s.wstrb;
    iwlast  <= s.wlast;

endfunction : write_w

function void write_b(axi_seq_item_b_vector_s s, bit valid=1'b1);

  ibvalid <= valid;
  ibid    <= s.bid;
  ibresp  <= s.bresp;

endfunction : write_b

function void read_aw(output axi_seq_item_aw_vector_s s);

     s.awvalid = awvalid;
     s.awid    = awid;
     s.awaddr  = awaddr;
     s.awlen   = awlen;
    s.awsize  = awsize;
    s.awburst = awburst;
     s.awlock  = awlock;
     s.awcache = awcache;
     s.awprot  = awprot;
     s.awqos   = awqos;

endfunction : read_aw


function void read_w(output axi_seq_item_w_vector_s  s);

    s.wvalid = wvalid;
    s.wdata = wdata;
    s.wstrb = wstrb;
    s.wlast = wlast;

endfunction : read_w

function void read_b(output axi_seq_item_b_vector_s  s);
  s.bid   = bid;
  s.bresp = bresp;
endfunction : read_b


function void write_ar(axi_seq_item_ar_vector_s s, bit valid=1'b1);

     iarvalid <= valid;
     iarid    <= s.arid;
     iaraddr  <= s.araddr;
     iarlen   <= s.arlen;
     iarsize  <= s.arsize;
     iarburst <= s.arburst;
     iarlock  <= s.arlock;
     iarcache <= s.arcache;
     iarprot  <= s.arprot;
     iarqos   <= s.arqos;


endfunction : write_ar

function void write_r(axi_seq_item_r_vector_s  s);

    irvalid <= s.rvalid;
    irdata  <= s.rdata;
    //irstrb  <= s.rstrb;
    irlast  <= s.rlast;
    irid     <= s.rid;

endfunction : write_r


function void read_ar(output axi_seq_item_ar_vector_s s);

     s.arvalid = arvalid;
     s.arid    = arid;
     s.araddr  = araddr;
     s.arlen   = arlen;
     s.arsize  = arsize;
     s.arburst = arburst;
     s.arlock  = arlock;
     s.arcache = arcache;
     s.arprot  = arprot;
     s.arqos   = arqos;

endfunction : read_ar

function void read_r(output axi_seq_item_r_vector_s  s);

    s.rvalid = rvalid;
    s.rdata  = rdata;
    s.rlast  = rlast;
    s.rid    = rid;
    s.rresp  = rresp;

endfunction : read_r

endclass : axi_if_concrete


// *ready toggling
initial begin
   forever begin
     @(posedge clk) begin
       if (awready_toggle_pattern_enable == 1'b1) begin
         awready_toggle_pattern[31:0] <= {awready_toggle_pattern[30:0], awready_toggle_pattern[31]};
            iawready                  <= awready_toggle_pattern[31];
         end
      end
   end
end


initial begin
   forever begin
     @(posedge clk) begin
       if (wready_toggle_pattern_enable == 1'b1) begin
         wready_toggle_pattern[31:0] <= {wready_toggle_pattern[30:0], wready_toggle_pattern[31]};
            iwready                 <= wready_toggle_pattern[31];
        end
      end
   end
end

initial begin
   forever begin
     @(posedge clk) begin
       if (bready_toggle_pattern_enable == 1'b1) begin
         bready_toggle_pattern[31:0] <= {bready_toggle_pattern[30:0], bready_toggle_pattern[31]};
            ibready                 <= bready_toggle_pattern[31];
        end
      end
   end
end



initial begin
   forever begin
     @(posedge clk) begin
       if (arready_toggle_pattern_enable == 1'b1) begin
         arready_toggle_pattern[31:0] <= {arready_toggle_pattern[30:0],
                                          arready_toggle_pattern[31]};

            iarready                  <= arready_toggle_pattern[31];
         end
      end
   end
end

initial begin
   forever begin
     @(posedge clk) begin
       if (rready_toggle_pattern_enable == 1'b1) begin
         rready_toggle_pattern[31:0] <= {rready_toggle_pattern[30:0],
                                          rready_toggle_pattern[31]};

            irready                  <= rready_toggle_pattern[31];
         end
      end
   end
end


  function void use_concrete_class(); //axi_pkg::driver_type_t drv_type);

//   m_type=drv_type;

   axi_if_abstract::type_id::set_type_override( axi_if_concrete::get_type());
   // `uvm_info("blah", $sformatf("%m -- HEY, running set_inst_override in _if"), UVM_INFO)

endfunction : use_concrete_class

`include "axi_sva.svh"


endinterface : axi_if


