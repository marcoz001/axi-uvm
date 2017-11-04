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

/*! \class memory
 *  \brief Extremely simple memory model with just write() and read() methods.
 */
class memory extends uvm_component;
  `uvm_component_utils(memory)

  bit [7:0] mem[*];

  extern function new(string name="memory", uvm_component parent=null);
  extern virtual function void write(input bit [63:0] addr, input bit [7:0] data);
  extern virtual function bit [7:0] read (input bit [63:0] addr);

endclass : memory

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function memory::new(string name="memory", uvm_component parent=null);
   super.new(name, parent);
endfunction : new

/*! \brief Writes into memory
 *
 */
function void memory::write(input bit [63:0] addr, input bit [7:0] data);
  `uvm_info(this.get_type_name(), $sformatf("write mem(0x%0x)=0x%0x", addr, data), UVM_HIGH)
  mem[addr] = data;
endfunction : write

/*! \brief Reads from memory
 *
 * uses an associative array.  If reading from unwritten address, 'z is returned.
*/
function bit [7:0] memory::read(input bit [63:0] addr);
  if (mem.exists(addr))  begin
    `uvm_info(this.get_type_name(), $sformatf("read mem(0x%0x)=0x%0x", addr, mem[addr]), UVM_HIGH)

    return mem[addr];
  end else begin
    `uvm_info(this.get_type_name(),
              $sformatf("read unwritten memory address [0x%0x]", addr),
              UVM_HIGH)
    return 'z;
  end
endfunction : read
