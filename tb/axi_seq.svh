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
/*! \class axi_seq
 *  \brief Writes to memory over AXI, backdoor readback, then AXI readback
 *
 *  miscompares are flagged.
 */
class axi_seq extends uvm_sequence #(axi_seq_item);

  `uvm_object_utils(axi_seq)

//  const int axi_readback  = 1;
  const int clearmemory   = 0;
  const int window_size   = 'h1_0000;
  int xfers_to_send = 1;

  bit valid [];

  bit [2:0] max_burst_size;

  int xfers_done=0;

  memory m_memory;

  extern function   new (string name="axi_seq");
  extern task       body;

  extern function void set_transaction_count(int count);
  extern function bit compare_items (ref axi_seq_item write_item, ref axi_seq_item read_item);

endclass : axi_seq

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor
 */
function axi_seq::new (string name="axi_seq");

  int dwidth;
  super.new(name);


  // Getting width is done here in the constructor because
  // it is used in randomize(), which is done before body() is called

  `uvm_info(this.get_type_name(),
            "Looking for AXI_DATA_WIDTH in uvm_config_db",
            UVM_MEDIUM)

  if (!uvm_config_db #(int)::get(null, "", "AXI_DATA_WIDTH", dwidth)) begin
    `uvm_fatal(this.get_type_name(),
               "Unable to fetch AXI_DATA_WIDTH from config db.")
  end

  max_burst_size=$clog2(dwidth/8);

endfunction : new


/*! \brief How many transactions?
 *
 * This method sets how many transactions to send
 * (Write Address, Write Data, Write Response) is one traction
 * (Read Address, Read Data) is one transaction
 * @param count - how many transactions to send
 */
function void axi_seq::set_transaction_count(int count);

   `uvm_info(this.get_type_name(),
             $sformatf("set_transaction_count(%0d)",count),
             UVM_INFO)


  xfers_to_send = count;
endfunction : set_transaction_count

task axi_seq::body;
endtask : body


/*! \brief Compares the write-item with the corresponding read_item
 *
 * THis isn't the same as a do_compare() method in the axi_seq_item
 * because the readback is depenent on which burst_type
 * Although it could probably exist as aseperate method in the seqitem.
 * @param write_item - the original item
 * @param read_item  - the item after memory readback
 * @return True if no miscompares, false if miscompares
 */
function bit axi_seq::compare_items (ref axi_seq_item write_item, ref axi_seq_item read_item);

  bit [2:0] max_burst_size;
  int yy;
  bit [7:0] localbuffer [];
  bit [7:0] read_data;
  bit [7:0] expected_data;
  int idatacntr;
  int miscompare_cntr;
  string write_item_s;
  string read_item_s;
  string expected_data_s;
  string msg_s;
  string localbuffer_s;
  int rollover_cnt;

  bit [7:0] expected_data_array [];


    if (write_item.burst_type==e_FIXED) begin

      idatacntr=2**write_item.burst_size;

      // compare every nth byte with the same offset byte in last beat.
      // should look like only the last beat got sent repeatedly
      // construct the expected array,, then compare against actual.
      // if miscompare, print original, readback and (calculated) expected.

      miscompare_cntr=0;
      expected_data_array=new[read_item.data.size()];

      // brute force, not elegant at all.
      // write to local buffer, then compare that buffer (repeated) with the axi readback


      yy=0;
      localbuffer=new[2**write_item.burst_size];
      for (int y=0;y<localbuffer.size();y++) begin
         localbuffer[y]='h0;
      end
      for (int y=0;y<write_item.len;y++) begin
        localbuffer[yy++]=write_item.data[y];
        if (yy >= 2**write_item.burst_size) begin
          yy=0;
        end
      end

      yy=0;
      for (int y=0; y<expected_data_array.size(); y++) begin
        expected_data_array[y]=localbuffer[yy++];
        if (yy >= localbuffer.size()) begin
          yy=0;
        end
      end

      for (int y=0;y<read_item.data.size();y++) begin
         expected_data = expected_data_array[y];
         read_data     = read_item.data[y];
         if (expected_data!=read_data) begin
            miscompare_cntr++;
         end
      end

      assert (miscompare_cntr==0) else begin
        write_item_s="";
        read_item_s="";
        expected_data_s="";
        localbuffer_s="";

       for (int z=0;z<write_item.data.size();z++) begin
          $sformat(write_item_s, "%s 0x%2x", write_item_s, write_item.data[z]);
        end

        for (int z=0;z<read_item.data.size();z++) begin
          $sformat(read_item_s, "%s 0x%2x", read_item_s, read_item.data[z]);
        end

        for (int z=0;z<expected_data_array.size();z++) begin
          $sformat(expected_data_s, "%s 0x%2x", expected_data_s, expected_data_array[z]);
        end

        for (int z=0;z<localbuffer.size();z++) begin
          $sformat(localbuffer_s, "%s 0x%2x", localbuffer_s, localbuffer[z]);
        end


        `uvm_error("AXI READBACK e_FIXED miscompare",
                   $sformatf("%0d miscompares between expected and actual data items.  \nExpected: %s \n  Actual: %s;  \nWritten: %s  \nLocalbuffer: %s", miscompare_cntr, expected_data_s, read_item_s, write_item_s, localbuffer_s ));
      end

      ///   ........................

    end else if (write_item.burst_type==e_INCR || write_item.burst_type==e_WRAP) begin
      for (int z=0;z<write_item.len;z++) begin
         read_data=read_item.data[z];
         expected_data=write_item.data[z];
         assert(expected_data==read_data) else begin
           miscompare_cntr++;
           `uvm_error("AXI READBACK e_INCR miscompare",
                       $sformatf("expected: 0x%0x   actual:0x%0x",
                                 expected_data,
                                 read_data))
         end
      end
    end else begin
           miscompare_cntr++;
      `uvm_error(this.get_type_name(),
                 $sformatf("Unsupported burst type %0d", write_item.burst_type))

    end

return (miscompare_cntr == 0);
endfunction : compare_items