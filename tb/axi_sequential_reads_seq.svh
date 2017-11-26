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
/*! \class axi_sequential_reads_seq
 *  \brief Writes to memory over AXI, backdoor readback, then AXI readback
 *
 *  miscompares are flagged.
 */
class axi_sequential_reads_seq extends axi_seq;

  `uvm_object_utils(axi_sequential_reads_seq)

  extern function   new (string name="axi_sequential_reads_seq");
  extern task       body;

endclass : axi_sequential_reads_seq

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor
 */
    function axi_sequential_reads_seq::new (string name="axi_sequential_reads_seq");
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
task axi_sequential_reads_seq::body;

  bit [ADDR_WIDTH-1:0] addr_lo;
  bit [ADDR_WIDTH-1:0] addr_hi;
  bit [ID_WIDTH-1:0] xid;

  int max_beat_cnt;
  int dtsize;
  bit [ADDR_WIDTH-1:0] Lower_Wrap_Boundary;
  bit [ADDR_WIDTH-1:0] Upper_Wrap_Boundary;
  bit [ADDR_WIDTH-1:0] write_addr;

  axi_seq_item read_item;

  xfers_done=0;


  if (!uvm_config_db #(memory)::get(null, "", "m_memory", m_memory)) begin
    `uvm_fatal(this.get_type_name(),
               "Unable to fetch m_memory from config db. Using defaults")
    end

  // Clear memory
  // backdoor write to memory
  // AXI readback of memory

  for (int xfer_cnt=0;xfer_cnt<xfers_to_send;xfer_cnt++) begin

    // clear memory
    if (clearmemory==1) begin
       for (int i=0;i<window_size;i++) begin
          m_memory.write(i, 'h0);
       end
    end


    read_item = axi_seq_item::type_id::create("read_item");


    // Not sure why I have to define and set these and
    // then use them in the randomize with {} but
    // Riviera Pro works better like this.
    addr_lo = xfer_cnt*window_size;
    addr_hi = addr_lo+'h100;
    xid     = xfer_cnt[ID_WIDTH-1:0];


    `uvm_info(this.get_type_name(),
              $sformatf("item %0d id:0x%0x addr_lo: 0x%0x  addr_hi: 0x%0x",
                        xfer_cnt, xid, addr_lo,addr_hi),
              UVM_INFO)


     assert( read_item.randomize() with {
                                         cmd        == e_READ;
                                         burst_size <= local::max_burst_size;
                                         id         == local::xid;
                                         addr       >= local::addr_lo;
                                         addr       <  local::addr_hi;
    })

     `uvm_info("DATA", $sformatf("\n\n\nItem %0d:  %s",
                                  xfer_cnt, read_item.convert2string()),
                UVM_INFO)


      //backdoor fill memory
      case (read_item.burst_type)
        e_FIXED : begin

          Lower_Wrap_Boundary = read_item.addr;
          Upper_Wrap_Boundary = Lower_Wrap_Boundary + (2**read_item.burst_size);

        end
        e_INCR : begin
          Lower_Wrap_Boundary = read_item.addr;
          Upper_Wrap_Boundary = Lower_Wrap_Boundary + read_item.len;

        end
        e_WRAP : begin
           max_beat_cnt = axi_pkg::calculate_axlen(.addr(read_item.addr),
                                                  .burst_size(read_item.burst_size),
                                                  .burst_length(read_item.len)) + 1;

          dtsize = (2**read_item.burst_size) * max_beat_cnt;

          Lower_Wrap_Boundary = (int'(read_item.addr/dtsize) * dtsize);
          Upper_Wrap_Boundary = Lower_Wrap_Boundary + dtsize;

        end
      endcase

      write_addr = read_item.addr;
      for (int i=0;i<read_item.len;i++) begin
         m_memory.write(write_addr, i[7:0]);
         write_addr++;
         if (write_addr >= Upper_Wrap_Boundary) begin
            write_addr = Lower_Wrap_Boundary;
         end
      end


    start_item  (read_item);
    finish_item (read_item);
    get_response(read_item);



    assert(m_memory.seq_item_check(.item(read_item),
                                   .lower_addr(addr_lo),
                                   .upper_addr(addr_hi)));


  end  //for

  `uvm_info(this.get_type_name(), "SEQ ALL DONE", UVM_INFO)

endtask : body

