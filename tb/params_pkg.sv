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
`ifndef _PARAMS_PKG
`define _PARAMS_PKG
/*! \package params_pkg
 *  \brief Parameters used in the design and testbench are kept here.
 *
 *  The top level module, tb, in this case, imports this package and references it
 *  to set the design and tb parameters.
 *  For example, in tb.sv:
 *    import params_pkg::*;
 *    parameter C_AXI_ID_WIDTH   = params_pkg::AXI_ID_WIDTH;
 *    @see tb.sv
 */
package params_pkg;

// The obvious question is what to do with multiple instantiations of
// different sizes?
  parameter AXI_ID_WIDTH   = 4;
  parameter AXI_ADDR_WIDTH = 32;
  parameter AXI_DATA_WIDTH = 256;
  parameter AXI_LEN_WIDTH  = 8;


endpackage : params_pkg

`endif