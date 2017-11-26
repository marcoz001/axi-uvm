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
/*! \class axi_pipelined_writes_seq
 *  \brief Writes to memory over AXI, backdoor readback
 *
 * Writes are pipelined so multiple in flight at once.
 *
 *  miscompares are flagged.
 */
class axi_pipelined_writes_seq extends axi_seq;

  `uvm_object_utils(axi_pipelined_writes_seq)

  axi_seq_item write_item [];

    int transaction_id;

  // all write responses have been received
  // Reads can go ahead
  event writes_done;


  typedef struct {
    bit [ADDR_WIDTH-1:0] laddr;
    bit [ADDR_WIDTH-1:0] uaddr;
  } mem_chk_s;

  mem_chk_s mem_chk_array [*];


  extern function   new (string name="axi_pipelined_writes_seq");
  extern task       body;
  extern function void response_handler(uvm_sequence_item response);

endclass : axi_pipelined_writes_seq


// This response_handler function is enabled to keep the sequence response FIFO empty
/*! \brief Handles write responses, including verifying memory via backdoor reads.
 *
 */
function automatic void axi_pipelined_writes_seq::response_handler(uvm_sequence_item response);

  axi_seq_item item;
  int xfer_cnt;
  int id;

  bit [ADDR_WIDTH-1:0] lower_addr;
  bit [ADDR_WIDTH-1:0] upper_addr;
  $cast(item,response);

  xfer_cnt=item.id;
  if (item.cmd== e_WRITE_RESPONSE) begin
   xfers_done++;

  id=item.get_transaction_id();

  lower_addr = mem_chk_array[id].laddr;
  upper_addr = mem_chk_array[id].uaddr;

   if (!m_memory.seq_item_check(.item       (item),
                                .lower_addr (lower_addr),
                                .upper_addr (upper_addr))) begin
        `uvm_info("MISCOMPARE","Miscompare error", UVM_INFO)
      end

  if (xfers_done >= xfers_to_send) begin
     `uvm_info("axi_seq::response_handler::sending event ",
               $sformatf("xfers_done:%0d  xfers_to_send: %0d  sending event",
                         xfers_done, xfers_to_send),
               UVM_INFO)
    ->writes_done;
  end

end
  `uvm_info(this.get_type_name(),
            $sformatf("SEQ_response_handler xfers_done=%0d/%0d.   Item: %s",
                      xfers_done, xfers_to_send, item.convert2string()),
            UVM_INFO)


endfunction: response_handler

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor
 */
function axi_pipelined_writes_seq::new (string name="axi_pipelined_writes_seq");
  super.new(name);
endfunction : new


/*! \brief Does all the work.
 *
 * -# Creates constrained random AXI write packet
 * -# Sends it
 * -# Backdoor read of memory to verify correctly written
 * -# Creates constrained random AXI read packet with same len and address as write packet
 * -# Sends it
 * -# Verifies read back data with written data.
 *
 *  two modes:
 *     Serial, Write_addr,  then write, then resp.  Repeat
 *     Parallel - Multiple write_adr, then multiple write_data, then multiple  resp, repeat
 */
task axi_pipelined_writes_seq::body;

  string s;

  bit [ADDR_WIDTH-1:0] addr_lo;
  bit [ADDR_WIDTH-1:0] addr_hi;
  bit [ID_WIDTH-1:0] xid;

  xfers_done=0;

  write_item = new [xfers_to_send];

  use_response_handler(1); // Enable Response Handler

  if (!uvm_config_db #(memory)::get(null, "", "m_memory", m_memory)) begin
    `uvm_fatal(this.get_type_name, "Unable to fetch m_memory from config db. Using defaults")
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

    write_item[xfer_cnt] = axi_seq_item::type_id::create("write_item");
    write_item[xfer_cnt].set_transaction_id(transaction_id++);

    // Not sure why I have to define and set these and
    // then use them in the randomize with {} but
    // Riviera Pro works better like this.
    addr_lo=xfer_cnt*window_size;
    addr_hi=addr_lo+'h100;
    xid =xfer_cnt[ID_WIDTH-1:0];


    mem_chk_array[write_item[xfer_cnt].get_transaction_id()].laddr =addr_lo;
    mem_chk_array[write_item[xfer_cnt].get_transaction_id()].uaddr =addr_lo+window_size;


    start_item(write_item[xfer_cnt]);

    `uvm_info(this.get_type_name(),
              $sformatf("item %0d id:0x%0x addr_lo: 0x%0x  addr_hi: 0x%0x",
                        xfer_cnt, xid, addr_lo,addr_hi),
              UVM_INFO)


    assert( write_item[xfer_cnt].randomize() with {
                                         cmd        == e_WRITE;
                                         burst_size <= local::max_burst_size;
                                         id         == local::xid;
                                         addr       >= local::addr_lo;
                                         addr       <  local::addr_hi;
    })
    // If valid specified, then pass it to seq item.
    if (valid.size() > 0) begin
       write_item[xfer_cnt].valid = new[valid.size()](valid);
    end

    `uvm_info("DATA", $sformatf("\n\n\nItem %0d:  %s", xfer_cnt, write_item[xfer_cnt].convert2string()), UVM_INFO)
    finish_item(write_item[xfer_cnt]);


  end  //for


  `uvm_info("READBACK", "writes done. waiting for event trigger", UVM_INFO)
  wait (writes_done.triggered);
  `uvm_info("READBACK", "event trigger detected1111", UVM_INFO)

  `uvm_info(this.get_type_name(), "SEQ ALL DONE", UVM_INFO)

endtask : body

