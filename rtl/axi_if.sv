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

  

  logic [C_AXI_ID_WIDTH-1:0]	 iawid;
  logic [C_AXI_ADDR_WIDTH-1:0]   iawaddr;
  logic                          iawvalid;
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
  
  
  assign awid    = iawid;
  assign awaddr  = iawaddr;
  assign awvalid = iawvalid;
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
     iawvalid = 1'b0;
     iawlen   = 'z;
     iawsize  = 'z;
     iawburst = 2'b10;
     iawlock  = 'h0; 
     iawcache = 'h0;
     iawprot  = 'h0;
     iawqos   = 'h0;
  
     iwready = 'z;
     iwdata  = 'z;
     iwstrb  = 'z;
     iwlast  = 1'b0;
     iwvalid = 'h0;
  
     ibid    = 'z;
     ibresp  = 'z;
     ibvalid = 'b0;
     ibready = 1'b1;
    
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
  
import axi_pkg::*;

//  extern task  write(bit [63:0] addr, bit [63:0] data);


  
  
class axi_if_concrete extends axi_if_abstract;
  `uvm_object_utils(axi_if_concrete)
  
  function new (string name="axi_if_concrete");  
    super.new(name);
  endfunction : new
  
  //@Todo: how to have data[] be veloce friendly? 
  //       
  task write(bit [63:0] addr, bit [7:0] data[], bit [7:0] id);
     $display("YO, axi_if.write");
    @(posedge clk);

      iawvalid <= 1'b1;
      iawaddr  <= addr;
      iawid    <= id;
      iawlen   = 'h0;
      iawsize  = 3'b010;

    @(posedge clk);
      iawvalid <= 1'b0;

    @(posedge clk);
      iwvalid <= 1'b1; 
      iwdata  = 'hdeadbeef;
      iwstrb  = 'hF;
      iwlast  = 'b1;

    if (wready != 1'b1) 
      @(posedge wready);
    
    @(posedge clk);
      iwvalid <= 1'b0;
    
  endtask : write

  
  task wait_for_awvalid; // _and_awready ?
    @(posedge awvalid);
  endtask : wait_for_awvalid;
  
  // @Todo: dynamic arrays (data[]) obviously don't work on a real Veloce
  // but for the sake of simplicity
  task read(bit [63:0] addr, bit [7:0] data[], bit [7:0] id);
      $display("YO, axi_if.read");
    @(posedge clk);

      iarready <= 1'b1;
      iaraddr  <= addr;
      
      iarid    <= id;

    @(posedge clk);
      iarready <= 1'b0;
    
  endtask : read
  
  
  
  
endclass : axi_if_concrete
  
    function void use_concrete_class;

    axi_if_abstract::type_id::set_type_override( axi_if_concrete::get_type());
     
     `uvm_info("blah", $sformatf("%m -- HEY, running set_inst_override in _if"), UVM_INFO)
   endfunction : use_concrete_class
  
  
endinterface : axi_if

