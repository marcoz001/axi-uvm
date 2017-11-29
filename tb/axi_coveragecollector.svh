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

    AWLEN : coverpoint item.axlen[LEN_WIDTH-1:0] {
       bins bin0       = {0};
       bins bin1_14    = {[1:14]};
       bins bin15      = {15};
       bins bin16_254  = {[16:254]};
       bins bin255     = {255};
   }
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

    ARLEN : coverpoint item.axlen[LEN_WIDTH-1:0] {
       bins bin0       = {0};
       bins bin1_14    = {[1:14]};
       bins bin15      = {15};
       bins bin16_254  = {[16:254]};
       bins bin255     = {255};
   }

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
