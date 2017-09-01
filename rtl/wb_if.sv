interface wb_if #(parameter C_AXI_ADDR_WIDTH = 32,
                  parameter C_AXI_DATA_WIDTH = 32)
                 (input wire                          clk,
                  input wire                          reset,
                  inout	wire                          cyc,
                  inout wire                          stb,
                  inout wire                          we,
                  inout wire [C_AXI_ADDR_WIDTH-1:0]   addr,
                  inout wire [C_AXI_DATA_WIDTH-1:0]   indata,
                  inout wire [C_AXI_DATA_WIDTH/8-1:0] sel,
                  inout wire                          ack,
                  inout wire                          stall,
                  inout wire [C_AXI_DATA_WIDTH-1:0]   outdata,
                  inout wire                          err
                 );
  
  logic                          icyc;
  logic                          istb;
  logic                          iwe;
  logic [C_AXI_ADDR_WIDTH-1:0]   iaddr;
  logic [C_AXI_DATA_WIDTH-1:0]   iindata;
  logic [C_AXI_DATA_WIDTH/8-1:0] isel;
  logic                          iack;
  logic                          istall;
  logic [C_AXI_DATA_WIDTH-1:0]   ioutdata;
  logic                          ierr;
  
  assign cyc     = icyc;
  assign stb     = istb;
  assign we      = iwe;
  assign addr    = iaddr;
  assign indata  = iindata;
  assign sel     = isel;
  assign ack     = iack;
  assign stall   = istall;
  assign outdata = ioutdata;
  assign err     = ierr;
  
initial begin
  
  icyc     = 'z;
  istb     = 'z;
  iwe      = 'z;
  iaddr    = 'z;
  iindata  = 'z;
  isel     = 'z;
  iack     = 1'b1;
  istall   = 1'b0;
  ioutdata = 'z;
  ierr     = 1'b0;
  
  
  
end


  
  
  
  
endinterface : wb_if