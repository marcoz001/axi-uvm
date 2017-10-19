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
/*! \class axi_coveragecollector
 *  \brief Collects coverage
 *
 * or will, currently does nothing.
 */
class axi_coveragecollector extends uvm_subscriber #(axi_seq_item);

  `uvm_component_utils(axi_coveragecollector)


  extern function new(string name="axi_coveragecollector", uvm_component parent=null);
  extern virtual function void write(axi_seq_item t);

endclass : axi_coveragecollector

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function axi_coveragecollector::new(string name="axi_coveragecollector", uvm_component parent=null);
   super.new(name, parent);
endfunction : new

/*! \brief currently does nothing.
 *
 * will update coverage bins, etc.
 */
function void axi_coveragecollector::write(axi_seq_item t);
  `uvm_info(this.get_type_name(), $sformatf("%s", t.convert2string()), UVM_HIGH)
endfunction : write
