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
// This filecontains cover properties that can't be gathered by the monitor.
// 

// Back to back write address transactions
always @(posedge clk) begin
  back2back_writeaddress: cover property((awvalid===1 && awready===1) ##1 (awvalid===1 & awready===1)) $display("Back to back write addresses @ %t", $time);
end

// back to back write data transactions
always @(posedge clk) begin
  back2back_writedata: cover property((wvalid===1 && wready===1 && wlast===1) ##1 (wvalid===1 & wready===1)) $display("Back to back write data @ %t", $time);
end

// back to back write response transactions
always @(posedge clk) begin
  back2back_writeresponse: cover property((bvalid===1 && bready===1) ##1 (bvalid===1 & bready===1)) $display("Back to back write response @ %t", $time);
end
    
// Back to back read address transactions
always @(posedge clk) begin
  back2back_readaddress: cover property((arvalid===1 && arready===1) ##1 (arvalid===1 & arready===1)) $display("Back to back read addresses @ %t", $time);
end

// back to back read data transactions
always @(posedge clk) begin
  back2back_readdata: cover property((rvalid===1 && rready===1 && rlast===1) ##1 (rvalid===1 & rready===1)) $display("Back to back read data @ %t", $time);
end
