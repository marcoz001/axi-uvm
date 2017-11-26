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
/*! \class axi_sequential_writes_seq
 *  \brief Writes to memory over AXI, backdoor memory readback and verify
 *
 *  miscompares are flagged.
 */
class axi_sequential_writes_seq extends axi_seq;

  `uvm_object_utils(axi_sequential_writes_seq)

  extern function   new (string name="axi_sequential_writes_seq");
  extern task       body;

endclass : axi_sequential_writes_seq


/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor
 */
function axi_sequential_writes_seq::new (string name="axi_sequential_writes_seq");
  super.new(name);
endfunction : new


/*! \brief Does all the work.
 *
 * -# Creates constrained random AXI write packet
 * -# Sends it
 * -# Backdoor read of memory to verify correctly written
 */

task axi_sequential_writes_seq::body;

  bit [ADDR_WIDTH-1:0] addr_lo;
  bit [ADDR_WIDTH-1:0] addr_hi;
  bit [ID_WIDTH-1:0]   xid;

  axi_seq_item write_item;

  if (!uvm_config_db #(memory)::get(null, "", "m_memory", m_memory)) begin
      `uvm_fatal(this.get_type_name,
                  "Unable to fetch m_memory from config db.")
  end

  // Clear memory
  // AXI write
  // direct readback of memory
  //  check that addresses before Axi start address are still 0
  //  chck expected data
  //  check that addresses after axi start_addres+length are still 0

  for (int xfer_cnt=0;xfer_cnt<xfers_to_send;xfer_cnt++) begin

    // clear memory
    if (clearmemory==1) begin
       for (int i=0;i<window_size;i++) begin
          m_memory.write(i, 'h0);
       end
    end

    write_item = axi_seq_item::type_id::create("write_item");


    // Not sure why I have to define and set these and
    // then use them in the randomize with {} but
    // Riviera Pro works better like this.
    addr_lo = xfer_cnt*window_size;
    addr_hi = addr_lo+'h100;
    xid     = xfer_cnt[ID_WIDTH-1:0];
    start_item(write_item);

    `uvm_info(this.get_type_name(),
              $sformatf("item %0d id:0x%0x addr_lo: 0x%0x  addr_hi: 0x%0x",
                        xfer_cnt, xid, addr_lo,addr_hi),
              UVM_HIGH)


    assert( write_item.randomize() with {
                                         cmd        == e_WRITE;
                                         burst_size <= local::max_burst_size;
                                         id         == local::xid;
                                         addr       >= local::addr_lo;
                                         addr       <  local::addr_hi;
                                        })
    // If valid specified, then pass it to seq item.
    if (valid.size() > 0) begin
       write_item.valid = new[valid.size()](valid);
    end

    `uvm_info("DATA",
              $sformatf("\n\n\nItem %0d:  %s",
                        xfer_cnt, write_item.convert2string()),
              UVM_INFO)
    finish_item(write_item);

    get_response(write_item);

    if (!m_memory.seq_item_check(.item       (write_item),
                                 .lower_addr (xfer_cnt*window_size),
                                 .upper_addr ((xfer_cnt+1)*window_size))) begin
        `uvm_info("MISCOMPARE","Miscompare error", UVM_INFO)
    end


  end  //for


endtask : body

