////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_seq.svh
//
// Purpose:
//          UVM sequence for AXI UVM environment
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
  `uvm_info(this.get_type_name(), $sformatf("SEQ_response_handler xfers_done=%0d.   Item: %s",xfers_done, response.convert2string()), UVM_INFO)

endfunction: response_handler


function axi_seq::new (string name="axi_seq");
  super.new(name);
endfunction : new

task axi_seq::body;
     axi_seq_item original_item;
     axi_seq_item item;
     axi_seq_item cloned_item;
  axi_seq_item rsp;
  int xfers_to_send=0;
  string s;
  bit [7:0] read_data;

  xfers_done=0;
  original_item=axi_seq_item::type_id::create("original_item");

  use_response_handler(1); // Enable Response Handler

  if (!uvm_config_db #(memory)::get(null, "", "m_memory", m_memory)) begin
    `uvm_fatal(this.get_type_name, "Unable to fetch m_memory from config db. Using defaults")
    end



  xfers_to_send=1;

  for (int i=0;i<xfers_to_send;i++) begin
     $cast(item, original_item.clone());
     start_item(item);
     assert( item.randomize() with {cmd        == e_WRITE;
                                    burst_size inside {e_1BYTE,e_2BYTES,e_4BYTES};
                                    burst_type == e_INCR;
                                    addr       <  'h1000;
                                    //len        ==  'h10;
                                    len        >  'h0;
                                    len        <=  'h40;}
                                   ) else begin
         `uvm_error(this.get_type_name(),
                    $sformatf("Unable to randomize %s",  item.get_full_name()));
     end  //assert
    $cast(cloned_item, item.clone());
     finish_item(item);
    `uvm_info("DATA", $sformatf("Sending a transfer. Starting_addr: 0x%0x, bytelen: %0d (0x%0x), (burst_size: 0x%0x", item.addr, item.len, item.len, item.burst_size), UVM_INFO)
     #10us

    `uvm_info("...", "Now reading back from memory to verify", UVM_INFO)
    s=$sformatf("Addr[0x%0x/(len:%d)]=", item.Start_Address, item.len);

    for (int z=0;z<item.len;z++) begin
      read_data=m_memory.read(item.Start_Address+z);
      s=$sformatf("%s 0x%0x", s, read_data);
      if (z<item.len-1) begin
         assert (int'(read_data) == z) else begin
           `uvm_error("miscompare", $sformatf("expected: 0x%0x   actual:0x%0x", z, read_data))
         end
      end else begin
        assert (int'(read_data) == 'hFE) else begin
          `uvm_error("miscompare", $sformatf("expected: 0x%0x   actual:0x%0x", 'hFE, read_data))
         end
      end

    end

    `uvm_info("COMPARE", $sformatf("%s", s), UVM_INFO);


    // Now AXI readback
    `uvm_info("READBACK", "Now READING BACK", UVM_INFO)

    start_item(cloned_item);
    cloned_item.cmd=e_READ;
    finish_item(cloned_item);
     #10us
    `uvm_info("..", "...", UVM_HIGH)
  end  //for

  wait (xfers_to_send == xfers_done);
  `uvm_info(this.get_type_name(), "SEQ ALL DONE", UVM_INFO)

endtask : body


