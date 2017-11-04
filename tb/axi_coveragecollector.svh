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
 * Write Address and Read Address simple coverage (burst_size, burst_type and awlen)
 */
class axi_coveragecollector extends uvm_subscriber #(axi_seq_item);

  `uvm_component_utils(axi_coveragecollector)

  covergroup aw_cg with function sample(axi_seq_item item);
  //option.name = "aw";
  option.per_instance = 0;

    BURSTSIZE : coverpoint item.burst_size {
      bins e_1BYTE    = {axi_pkg::e_1BYTE};
      bins e_2BYTES   = {axi_pkg::e_2BYTES};
      bins e_4BYTES   = {axi_pkg::e_4BYTES};
      bins e_8BYTES   = {axi_pkg::e_8BYTES};
      bins e_16BYTES  = {axi_pkg::e_16BYTES};
      bins e_32BYTES  = {axi_pkg::e_32BYTES};
      bins e_64BYTES  = {axi_pkg::e_64BYTES};
      bins e_128BYTES = {axi_pkg::e_128BYTES};
    }

    BURSTTYPE : coverpoint item.burst_type {
      bins e_FIXED   = {axi_pkg::e_FIXED};
      bins e_INCR    = {axi_pkg::e_INCR};
      bins e_WRAP    = {axi_pkg::e_WRAP};
    }

   // AWLEN : coverpoint item.awlen[3:0];

    /* awcache, awlock, awprot, awqos here someday */

  endgroup: aw_cg

  covergroup ar_cg with function sample(axi_seq_item item);
  //option.name = "aw";
  option.per_instance = 0;

    BURSTSIZE : coverpoint item.burst_size {
      bins e_1BYTE    = {axi_pkg::e_1BYTE};
      bins e_2BYTES   = {axi_pkg::e_2BYTES};
      bins e_4BYTES   = {axi_pkg::e_4BYTES};
      bins e_8BYTES   = {axi_pkg::e_8BYTES};
      bins e_16BYTES  = {axi_pkg::e_16BYTES};
      bins e_32BYTES  = {axi_pkg::e_32BYTES};
      bins e_64BYTES  = {axi_pkg::e_64BYTES};
      bins e_128BYTES = {axi_pkg::e_128BYTES};
    }

    BURSTTYPE : coverpoint item.burst_type {
      bins e_FIXED   = {axi_pkg::e_FIXED};
      bins e_INCR    = {axi_pkg::e_INCR};
      bins e_WRAP    = {axi_pkg::e_WRAP};
    }

  //  ARLEN : coverpoint item.arlen[3:0];

    /* awcache, awlock, awprot, awqos here someday */

  endgroup: ar_cg



  extern function new(string name="axi_coveragecollector", uvm_component parent=null);
  extern virtual function void write(axi_seq_item t);

endclass : axi_coveragecollector

/*! \brief Constructor
 *
 * allocates covergroups */
function axi_coveragecollector::new(string name="axi_coveragecollector", uvm_component parent=null);
   super.new(name, parent);

      aw_cg = new();
      ar_cg = new();

endfunction : new

/*! \brief covergroup sampling
 *
 * will update coverage bins, etc.
 */
function void axi_coveragecollector::write(axi_seq_item t);
  `uvm_info(this.get_type_name(), $sformatf("%s", t.convert2string()), UVM_HIGH)

  case (t.cmd)
    axi_uvm_pkg::e_WRITE : begin
       aw_cg.sample(t);
      end

      axi_uvm_pkg::e_READ  : begin
        ar_cg.sample(t);
      end

   endcase

endfunction : write
