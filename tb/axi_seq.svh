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
/*! \class axi_seq
 *  \brief Writes to memory over AXI, backdoor readback, then AXI readback
 *
 *  miscompares are flagged.
 */
class axi_seq extends uvm_sequence #(axi_seq_item);

    `uvm_object_utils(axi_seq)

  int xfers_done=0;

  memory m_memory;

  extern function   new (string name="axi_seq");
  extern task       body;
  extern function void response_handler(uvm_sequence_item response);
endclass : axi_seq


// This response_handler function is enabled to keep the sequence response FIFO empty
function void axi_seq::response_handler(uvm_sequence_item response);
   xfers_done++;
  `uvm_info(this.get_type_name(), $sformatf("SEQ_response_handler xfers_done=%0d.   Item: %s",xfers_done, response.convert2string()), UVM_HIGH)

endfunction: response_handler

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor
 */
function axi_seq::new (string name="axi_seq");
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
 */
task axi_seq::body;

  axi_seq_item write_item;
  axi_seq_item read_item;

  int xfers_to_send=0;
  string s;
  bit [7:0] read_data;

  xfers_done=0;

  //use_response_handler(1); // Enable Response Handler

  if (!uvm_config_db #(memory)::get(null, "", "m_memory", m_memory)) begin
    `uvm_fatal(this.get_type_name, "Unable to fetch m_memory from config db. Using defaults")
    end



  xfers_to_send=1;

  for (int i=0;i<xfers_to_send;i++) begin
     write_item=axi_seq_item::type_id::create("write_item");
     read_item=axi_seq_item::type_id::create("read_item");


    start_item(write_item);
    assert( write_item.randomize() with {cmd        ==     e_WRITE;
                                         burst_size inside {e_1BYTE,e_2BYTES,e_4BYTES};
                                         burst_type ==     e_INCR;
                                         addr       <      'h4;
                                         len        >      'h0;
                                         len        <=     'h3C;
                                        }
                                   ) else begin
         `uvm_error(this.get_type_name(),
                    $sformatf("Unable to randomize %s",  write_item.get_full_name()));
         end  //assert


    finish_item(write_item);
    `uvm_info("DATA", $sformatf("Sending a transfer. Starting_addr: 0x%0x, bytelen: %0d (0x%0x), (burst_size: 0x%0x", write_item.addr, write_item.len, write_item.len, write_item.burst_size), UVM_HIGH)
    get_response(write_item);


    `uvm_info("...", "Now reading back from memory to verify", UVM_LOW)
    s=$sformatf("Addr[0x%0x/(len:%d)]=", write_item.Start_Address, write_item.len);

    for (int z=0;z<write_item.len;z++) begin
      read_data=m_memory.read(write_item.Start_Address+z);
      s=$sformatf("%s 0x%0x", s, read_data);
      if (z<write_item.len-1) begin
         assert (int'(read_data) == z) else begin
           `uvm_error("miscompare", $sformatf("expected: 0x%0x   actual:0x%0x", z, read_data))
         end
      end else begin
        assert (int'(read_data) == 'hFE) else begin
          `uvm_error("miscompare", $sformatf("expected: 0x%0x   actual:0x%0x", 'hFE, read_data))
         end
      end

    end


    `uvm_info("COMPARE", $sformatf("%s", s), UVM_HIGH);


    // Now AXI readback
    `uvm_info("READBACK", "Now READING BACK", UVM_INFO)


    start_item(read_item);
    assert( read_item.randomize() with {cmd        ==     e_READ;
                                         burst_size inside {e_1BYTE,e_2BYTES,e_4BYTES};
                                         burst_type ==     write_item.burst_type;
                                         addr       ==     write_item.Start_Address;
                                        len        ==     write_item.len;}
                                                                          ) else begin
         `uvm_error(this.get_type_name(),
                    $sformatf("Unable to randomize %s",  read_item.get_full_name()));
         end  //assert


    finish_item(read_item);

    get_response(read_item);   //response_handler above deals with this

    `uvm_info(this.get_type_name(),
              $sformatf("GOT RESPONSE. item=%s", read_item.convert2string()),
              UVM_INFO)

    `uvm_info("...", "Now comparing AXI readback to AXI write data", UVM_INFO)
    for (int z=0;z<write_item.len;z++) begin
      assert (write_item.data[z] == read_item.data[z]) else begin
        `uvm_warning("MISCOMPARE",
                     $sformatf("Expected(Written) Data: 0x%0x  Actual(Readback) Data: 0x%0x",
                               write_item.data[z],read_item.data[z]))
      end

    end


    `uvm_info("..", "...", UVM_HIGH)

  end  //for


  `uvm_info(this.get_type_name(), "SEQ ALL DONE", UVM_INFO)

endtask : body


