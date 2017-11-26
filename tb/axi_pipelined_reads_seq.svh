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
/*! \class axi_pipelined_reads_seq
 *  \brief Backdoor memory writes, then reads from memory over AXI
 *
 * Reads are pipelined so multiple in flight at once.
 *
 *  miscompares are flagged.
 */
class axi_pipelined_reads_seq extends axi_seq;

  `uvm_object_utils(axi_pipelined_reads_seq)

  axi_seq_item read_item [];

  int transaction_id;

  // all write responses have been received
  // Reads can go ahead
  event reads_done;


  typedef struct {
    bit [ADDR_WIDTH-1:0] laddr;
    bit [ADDR_WIDTH-1:0] uaddr;
  } mem_chk_s;

  mem_chk_s mem_chk_array [*];

  extern function   new (string name="axi_pipelined_reads_seq");
  extern task       body;
  extern function void response_handler(uvm_sequence_item response);

endclass : axi_pipelined_reads_seq


// This response_handler function is enabled to keep the sequence response FIFO empty
/*! \brief Handles write responses, including verifying memory via backdoor reads.
 *
 */
function automatic void axi_pipelined_reads_seq::response_handler(uvm_sequence_item response);

  axi_seq_item item;
  int xfer_cnt;
  int id;

  bit [ADDR_WIDTH-1:0] lower_addr;
  bit [ADDR_WIDTH-1:0] upper_addr;

  $cast(item,response);

  xfer_cnt=item.id;


  if (item.cmd == e_READ_DATA) begin

   xfers_done++;

   id=item.get_transaction_id();

  lower_addr = mem_chk_array[id].laddr;
  upper_addr = mem_chk_array[id].uaddr;


    `uvm_info("LLLLLLLLLLLLLLL",
              $sformatf("SEQ_response_handler id:%0d uaddr=0x%0x laddr=0x%0x",
                      id, lower_addr, upper_addr),
            UVM_INFO)

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
    ->reads_done;
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
function axi_pipelined_reads_seq::new (string name="axi_pipelined_reads_seq");
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
task axi_pipelined_reads_seq::body;

  string s;

  bit [ADDR_WIDTH-1:0] addr_lo;
  bit [ADDR_WIDTH-1:0] addr_hi;
  bit [ID_WIDTH-1:0] xid;

  int max_beat_cnt;
    int dtsize;
    bit [ADDR_WIDTH-1:0] Lower_Wrap_Boundary;
    bit [ADDR_WIDTH-1:0] Upper_Wrap_Boundary;
    bit [ADDR_WIDTH-1:0] write_addr;


  xfers_done=0;

  read_item = new [xfers_to_send];

  //mem_chk_array = new [xfers_to_send];



  use_response_handler(1); // Enable Response Handler

  if (!uvm_config_db #(memory)::get(null, "", "m_memory", m_memory)) begin
    `uvm_fatal(this.get_type_name, "Unable to fetch m_memory from config db.")
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

    read_item[xfer_cnt] = axi_seq_item::type_id::create("read_item");
    read_item[xfer_cnt].set_transaction_id(transaction_id++);

    // Not sure why I have to define and set these and
    // then use them in the randomize with {} but
    // Riviera Pro works better like this.
    addr_lo=xfer_cnt*window_size;
    addr_hi=addr_lo+'h100;
    xid =xfer_cnt[ID_WIDTH-1:0];


    mem_chk_array[read_item[xfer_cnt].get_transaction_id()].laddr =addr_lo;
    mem_chk_array[read_item[xfer_cnt].get_transaction_id()].uaddr =addr_lo+window_size;


    assert( read_item[xfer_cnt].randomize() with {
                                         cmd        == e_READ;
                                         burst_size <= local::max_burst_size;
                                         id         == local::xid;
                                         addr       >= local::addr_lo;
                                         addr       <  local::addr_hi;
      len < 5;
    })




      //backdoor fill memory
      case (read_item[xfer_cnt].burst_type)
        e_FIXED : begin

          Lower_Wrap_Boundary = read_item[xfer_cnt].addr;
          Upper_Wrap_Boundary = Lower_Wrap_Boundary + (2**read_item[xfer_cnt].burst_size);

        end
        e_INCR : begin
          Lower_Wrap_Boundary = read_item[xfer_cnt].addr;
          Upper_Wrap_Boundary = Lower_Wrap_Boundary + read_item[xfer_cnt].len;

        end
        e_WRAP : begin
           max_beat_cnt = axi_pkg::calculate_axlen(.addr(read_item[xfer_cnt].addr),
                                                  .burst_size(read_item[xfer_cnt].burst_size),
                                                  .burst_length(read_item[xfer_cnt].len)) + 1;

          dtsize = (2**read_item[xfer_cnt].burst_size) * max_beat_cnt;

          Lower_Wrap_Boundary = (int'(read_item[xfer_cnt].addr/dtsize) * dtsize);
          Upper_Wrap_Boundary = Lower_Wrap_Boundary + dtsize;

        end
      endcase

      write_addr = read_item[xfer_cnt].addr;
      for (int i=0;i<read_item[xfer_cnt].len;i++) begin
         m_memory.write(write_addr, i[7:0]);
         write_addr++;
         if (write_addr >= Upper_Wrap_Boundary) begin
            write_addr = Lower_Wrap_Boundary;
         end
      end

     start_item(read_item[xfer_cnt]);

        `uvm_info("YOYOYOYOYOYO",
                $sformatf("Transactionid: %0d", read_item[xfer_cnt].get_transaction_id()),
                UVM_INFO)

    `uvm_info(this.get_type_name(),
              $sformatf("item %0d id:0x%0x addr_lo: 0x%0x  addr_hi: 0x%0x",
                        xfer_cnt, xid, addr_lo,addr_hi),
              UVM_INFO)



    // If valid specified, then pass it to seq item.
    if (valid.size() > 0) begin
       read_item[xfer_cnt].valid = new[valid.size()](valid);
    end

    `uvm_info("DATA", $sformatf("\n\n\nItem %0d:  %s", xfer_cnt, read_item[xfer_cnt].convert2string()), UVM_INFO)
    finish_item(read_item[xfer_cnt]);

  end  //for


  `uvm_info("READBACK", "writes done. waiting for event trigger", UVM_INFO)
  wait (reads_done.triggered);
  `uvm_info("READBACK", "event trigger detected1111", UVM_INFO)

  `uvm_info(this.get_type_name(), "SEQ ALL DONE", UVM_INFO)

endtask : body

