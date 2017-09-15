// How much can be done in this interface determins how much the driver and seq do.
// This interface MUST REMAIN veloce friendly.  How to handle burst data drives
// much of the design.


interface axi_if #(
                      parameter C_AXI_ID_WIDTH   = 6,
                      parameter C_AXI_ADDR_WIDTH = 32,
                      parameter C_AXI_DATA_WIDTH = 32
                     )(
                     input wire clk,
                     input wire reset,

                     inout wire                          awready,  // Slave is ready to accept
                     inout wire [C_AXI_ID_WIDTH-1:0]	 awid,     // Write ID
                     inout wire [C_AXI_ADDR_WIDTH-1:0]   awaddr,   // Write address
                     inout wire [7:0]                    awlen,    // Write Burst Length
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
                     inout  wire [7:0]                   arlen,   // Read Burst Length
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
  logic [7:0]                    iawlen;
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
  logic  [7:0]                   iarlen;
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

  
  logic [31:0] awready_toggle_mask;
  bit          awready_toggle_mask_enable=0;

  logic [31:0]  wready_toggle_mask;
  bit           wready_toggle_mask_enable=0;
  
  logic [31:0]  bready_toggle_mask;
  bit           bready_toggle_mask_enable=0;


  
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
     iarlock  = 'h0;
     iarcache = 'h0;
     iarprot  = 'h0;
     iarqos   = 'h0;
     iarvalid = 'b0;
  
     irid     = 'z;
     irresp   = 'z;
     irvalid  = 'z;
     irdata   = 'z;
     irlast   = 'z;
     irready  = 'b0;
  
  end
  


//  extern task  write(bit [63:0] addr, bit [63:0] data);

   driver_type_t m_type;
  
 import uvm_pkg::*;
`include "uvm_macros.svh"
  
class axi_if_concrete extends axi_if_abstract;
  `uvm_object_utils(axi_if_concrete)
  
  function new (string name="axi_if_concrete");  
    super.new(name);
  endfunction : new
  
  //@Todo: how to have data[] be veloce friendly? 
  //  either just write words/ctl lines directly
  // or put most of logic in i/f
  /*
  task write(bit [63:0] addr, bit [7:0] data[], bit [7:0] id);
     $display("YO, axi_if.write");
//    @(negedge clk);
//      iawvalid <= 1'b0;

    @(negedge clk);
      iawvalid <= 1'b1;
      iawaddr  <= addr;
      iawid    <= id;
      iawlen   <= 'h0;
      iawsize  <= 3'b010;

    @(negedge clk);
     while (awready != 1'b1) begin
       @(negedge clk);
     end

     iawvalid <= 1'b0;

    
  endtask : write
*/
  task write_aw(axi_seq_item_aw_vector_s s);
    
    
     wait_for_clks(.cnt(1));
    
     iawvalid <= 1'b1;
     iawid    <= s.awid;
     iawaddr  <= s.awaddr;
     iawlen   <= s.awlen;
     iawsize  <= s.awsize;
     iawburst <= s.awburst;
     iawlock  <= s.awlock; 
     iawcache <= s.awcache;
     iawprot  <= s.awprot;
     iawqos   <= s.awqos;

     wait_for_clks(.cnt(1));
     while (awready != 1'b1) begin
        wait_for_clks(.cnt(1));
     end
    
     iawvalid <= 1'b0;
     iawid    <= 'z;
     iawaddr  <= 'z;
     iawlen   <= 'z;
     iawsize  <= 'z;
     iawburst <= 'z;
     iawlock  <= 'z; 
     iawcache <= 'z;
     iawprot  <= 'z;
     iawqos   <= 'z;

    
  endtask : write_aw
  
    
  task write_w(axi_seq_item_w_vector_s  s, bit waitforwready=0);
  //  $display("write_w - start");
   wait_for_clks(.cnt(1));
  // @(posedge clk) begin
     
      if (waitforwready == 1'b1) begin
 //     $display("write_w - waitforwready");
         while (wready != 1'b1) begin
 //          $display("write_w - waiting on clk/wready");

 //          @(posedge clk);
             wait_for_clks(.cnt(1));
         end
      end  
    
    //if (wready == 1'b1) begin //  && wvalid == 1'b1) begin
    iwvalid <= s.wvalid; // 1'b1;
    
    iwdata  <= s.wdata;
    iwstrb  <= s.wstrb;
    iwlast  <= s.wlast;
  //end
  //end
endtask : write_w
  
  
  // ********************
  task read_aw(output axi_seq_item_aw_vector_s s);
    

    
    
   // $display("YO, axi_if.write_aw");
    
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

   
  endtask : read_aw
  
  
  // ********************
  task read_w(output axi_seq_item_w_vector_s  s);

    
    s.wvalid = wvalid;
    
    s.wdata = wdata;
    s.wstrb = wstrb;
    s.wlast = wlast;

endtask : read_w 


  task wait_for_not_in_reset;
    wait (reset == 1'b0);
  endtask : wait_for_not_in_reset;
  
task wait_for_awvalid;
  @(posedge awvalid);  
endtask : wait_for_awvalid;
  
task wait_for_awready_awvalid;

  if (awready == 1'b1 && awvalid == 1'b1) 
    return;
  else  if (awvalid == 1'b1)
    @(posedge awready);
  else  if (awready == 1'b1)
    @(posedge awvalid);

endtask : wait_for_awready_awvalid
  
  // @Todo: dynamic arrays (data[]) obviously don't work on a real Veloce
  // but for the sake of simplicity
task read(output bit [63:0] addr, output bit [7:0] data[], output int len, output bit [7:0] id);
      $display("YO, axi_if.read");
   // @(posedge clk);

    id   = awid;
    addr = awaddr;
    data = new[4];
    data[3]=8'hde;
    data[2]=8'had;
    data[1]=8'hbe;
    data[0]=8'hef;
    len=4;
    
    //data = 'h0; // awdata;
    //  iarready <= 1'b1;
    //  iaraddr  <= addr;
      
    //  iarid    <= id;

    //@(posedge clk);
    //  iarready <= 1'b0;
    
endtask : read
  
task set_awready(bit state);
    wait_for_clks(.cnt(1));
    iawready <= state;
endtask : set_awready

task set_awvalid(bit state);
  wait_for_clks(.cnt(1));
  iawvalid <= state;
endtask : set_awvalid
  
task set_wready(bit state);
  wait_for_clks(.cnt(1));
    iwready <= state;
endtask : set_wready

task set_wvalid(bit state);
  wait_for_clks(.cnt(1));
  iwvalid <= state;
endtask : set_wvalid
  
task set_bready(bit state);
  wait_for_clks(.cnt(1));
    ibready <= state;
endtask : set_bready

task set_bvalid(bit state);
  wait_for_clks(.cnt(1));
  ibvalid <= state;
endtask : set_bvalid
  
  
  // wait for n clock cycles. Default: 1
  task wait_for_clks(int cnt=1);
    if (cnt==0) return;
      
    repeat (cnt) @(posedge clk);
  endtask : wait_for_clks
  
  
task wait_for_wready;
  while (wready != 1'b1)
    wait_for_clks(.cnt(1));
  
  //@(posedge clk);
  //while (wready != 1'b1) 
  //    @(posedge clk);

endtask : wait_for_wready
  
  
function bit get_wready_wvalid;
  return wvalid & wready;
endfunction : get_wready_wvalid;
  
task set_awready_toggle_mask(bit [31:0] mask);
    awready_toggle_mask=mask;
    awready_toggle_mask_enable=1;
endtask : set_awready_toggle_mask
  
function bit get_wready;
  return wready;
endfunction : get_wready
  
function bit get_wvalid;
  return wvalid;
endfunction : get_wvalid
  
function bit get_bready;
  return bready;
endfunction : get_bready
  
function bit get_bvalid;
  return bvalid;
endfunction : get_bvalid
  
  
task wait_for_bvalid;
  @(posedge bvalid);
endtask : wait_for_bvalid
  
task clr_awready_toggle_mask();
     awready_toggle_mask_enable =0;
endtask : clr_awready_toggle_mask
  
task set_wready_toggle_mask(bit [31:0] mask);
    wready_toggle_mask=mask;
    wready_toggle_mask_enable=1;
endtask : set_wready_toggle_mask
  
  
task clr_wready_toggle_mask();
     wready_toggle_mask_enable =0;
endtask : clr_wready_toggle_mask

task set_bready_toggle_mask(bit [31:0] mask);
    bready_toggle_mask=mask;
    bready_toggle_mask_enable=1;
endtask : set_bready_toggle_mask
  
  
task clr_bready_toggle_mask();
     bready_toggle_mask_enable =0;
endtask : clr_bready_toggle_mask

  function void read_b(output axi_seq_item_b_vector_s  s);
  s.bid   = bid;
  s.bresp = bresp;
endfunction : read_b
  
endclass : axi_if_concrete

  initial begin
//iawready <= 1'b1;
//iwready <= 1'b1;
    ibready <= 1'b1;
//ibresp <= 'h0;
//ibid <= 'h0;
  end
 
  initial begin
    forever begin
      @(posedge clk) begin
        if (wlast == 1'b1) begin
          ibvalid <= 1'b1;
          ibid <= 'h3;
          ibresp <= 'h2;
        end else begin
          ibvalid <= 1'b0;
          ibid <= 'h0;
          ibresp <= 'h0;
        end
      end
      
    end
  end
  
  
  

// *ready toggling  
initial begin
   forever begin
     @(posedge clk) begin
        if (awready_toggle_mask_enable == 1'b1) begin
            awready_toggle_mask[31:0] <= {awready_toggle_mask[30:0], awready_toggle_mask[31]};
            iawready                  <= awready_toggle_mask[31];
         end
      end
   end
end
  
initial begin
   forever begin
     @(posedge clk) begin
        if (wready_toggle_mask_enable == 1'b1) begin
            wready_toggle_mask[31:0] <= {wready_toggle_mask[30:0], wready_toggle_mask[31]};
            iwready                 <= wready_toggle_mask[31];
        end
      end
   end
end

initial begin
   forever begin
     @(posedge clk) begin
         if (bready_toggle_mask_enable == 1'b1) begin
            bready_toggle_mask[31:0] <= {bready_toggle_mask[30:0], bready_toggle_mask[31]};
            ibready                  <= bready_toggle_mask[31];
         end
      end
   end
end
  
  function void use_concrete_class(axi_pkg::driver_type_t drv_type);

   m_type=drv_type;

   axi_if_abstract::type_id::set_type_override( axi_if_concrete::get_type());
   // `uvm_info("blah", $sformatf("%m -- HEY, running set_inst_override in _if"), UVM_INFO)

endfunction : use_concrete_class

endinterface : axi_if

