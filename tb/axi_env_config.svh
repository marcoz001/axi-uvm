////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_env_config.svh
//
// Purpose:
//          UVM environment configuration object for AXI UVM environment
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
/*! \class axi_env_config
 *  \brief Configuration object for axi_env
 *
 * Currently does nothing.
 */
class axi_env_config extends uvm_object;
  `uvm_object_utils(axi_env_config)

  extern function new (string name="axi_env_config");

endclass : axi_env_config

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function axi_env_config::new (string name="axi_env_config");
  super.new(name);
endfunction : new
