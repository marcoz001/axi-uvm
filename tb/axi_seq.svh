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

  int addr_width=0;
  int data_width=0;
  int id_width=0;
  int len_width=0;

  memory m_memory;

  extern function   new (string name="axi_seq");
  extern task       body;
  extern function void response_handler(uvm_sequence_item response);

  extern function set_addr_width(int width=0);
  extern function set_data_width(int width=0);
  extern function set_id_width(int width=0);
  extern function set_len_width(int width=0);

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

/*! \brief Set Address bus width
 *
 * AXI supports multiple bus widths, parameterized at runtime.
 * We have to tell the sequence so we can randomize accordingly.
 * IE: If the addr bus width is 32, don't try to use 64 bits.
 */
function axi_seq::set_addr_width (int width=0);
  this.addr_width = width;
endfunction : set_addr_width

/*! \brief Set Data bus width
 *
 * AXI supports multiple bus widths, parameterized at runtime.
 * We have to tell the sequence so we can randomize accordingly.
 * IE: If the data bus width is 32, don't send a burst_size=64bits.
 */
function axi_seq::set_data_width (int width=0);
  this.data_width = width;
endfunction : set_data_width

/*! \brief Set ID vector width
 *
 * AXI supports  ID widths, parameterized at runtime.
 * We have to tell the sequence so we can randomize accordingly.
 */
function axi_seq::set_id_width (int width=0);
  this.id_width = width;
endfunction : set_id_width

/*! \brief Set length vector width
 *
 * AXI supports 2 different AxLEN widths, parameterized at runtime.
 * 4-bit and 8-bit.
 * We have to tell the sequence so we can randomize accordingly.
 *
 */
function axi_seq::set_len_width (int width=0);
  this.len_width = width;
endfunction : set_len_width

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
  bit [7:0] expected_data;
  int window_size='h1000;

  int clearmemory=1;
  int precheck=1;
  int postcheck=1;

  bit [63:0] iaddr;

  int max_beat_cnt;
  int dtsize;
  bit [63:0] Lower_Wrap_Boundary;
  bit [63:0] Upper_Wrap_Boundary;

  bit [63:0]  pre_check_start_addr;
  bit [63:0]  pre_check_stop_addr;

  bit [63:0]  check_start_addr;
  bit [63:0]  check_stop_addr;

  bit [63:0]  post_check_start_addr;
  bit [63:0]  post_check_stop_addr;

  int idatacntr;
  int miscompare_cntr;
  string write_item_s;
  string read_item_s;
  string expected_data_s;
  string msg_s;
  string localbuffer_s;
  int rollover_cnt;

  bit [7:0] expected_data_array [];

  bit [2:0] max_burst_size;
      int yy;
      bit [7:0] localbuffer [];

  xfers_done=0;

  //use_response_handler(1); // Enable Response Handler

  if (!uvm_config_db #(memory)::get(null, "", "m_memory", m_memory)) begin
    `uvm_fatal(this.get_type_name, "Unable to fetch m_memory from config db. Using defaults")
    end

  xfers_to_send=10;

  // If addr_width==0, then the setter hasn't been called. Try to fetch from
  // config db.
  if (addr_width == 0) begin
    if (!uvm_config_db #(int)::get(null, "", "AXI_ADDR_WIDTH", addr_width)) begin
        `uvm_fatal(this.get_type_name,
                   "Unable to fetch AXI_ADDR_WIDTH from config db. Using defaults")
     end
  end

  // If data_width==0, then the setter hasn't been called. Try to fetch from
  // config db.
  if (data_width == 0) begin
     if (!uvm_config_db #(int)::get(null, "", "AXI_DATA_WIDTH", data_width)) begin
        `uvm_fatal(this.get_type_name,
                   "Unable to fetch AXI_DATA_WIDTH from config db. Using defaults")
     end
  end

  // If id_width==0, then the setter hasn't been called. Try to fetch from
  // config db.
  if (id_width == 0) begin
    if (!uvm_config_db #(int)::get(null, "", "AXI_ID_WIDTH", id_width)) begin
        `uvm_fatal(this.get_type_name,
                   "Unable to fetch AXI_ID_WIDTH from config db. Using defaults")
     end
  end

  // If id_width==0, then the setter hasn't been called. Try to fetch from
  // config db.
  if (len_width == 0) begin
    if (!uvm_config_db #(int)::get(null, "", "AXI_LEN_WIDTH", len_width)) begin
        `uvm_fatal(this.get_type_name,
                   "Unable to fetch AXI_LEN_WIDTH from config db. Using defaults")
     end
  end

  // Clear memory
  // AXI write
  // direct readback of memory
  //  check that addresses before Axi start address are still 0
  //  chck expected data
  //  check that addresses after axi start_addres+length are still 0

  for (int i=0;i<xfers_to_send;i++) begin

    // clear memory
    if (clearmemory==1) begin
       for (int i=0;i<window_size;i++) begin
          m_memory.write(i, 'h0);
       end
    end

    write_item = axi_seq_item::type_id::create("write_item");
    read_item  = axi_seq_item::type_id::create("read_item");

    max_burst_size=$clog2(data_width/8);

    `uvm_info(this.get_type_name(),
              $sformatf("DATA_BUS_WIDTH:  %0d  max_burst_size: %0d",
                        data_width, max_burst_size),
              UVM_INFO)

    start_item(write_item);
    assert( write_item.randomize() with {//protocol   ==     e_AXI3;
                                         cmd        ==     e_WRITE;
                                        //burst_size inside {e_1BYTE};
                                         burst_size <=    local::max_burst_size;
                                         //burst_type inside {e_FIXED, e_INCR, e_WRAP};
                                         //id == local::i;
      addr <= 'h100;
                                         //(addr + len) <= local::window_size;

      // Protocol: e_AXI3 Cmd: e_WRITE    Addr = 0xb5  ID = 0x67  Len = 0x2 (2)  BurstSize = 0x0  BurstType = 0x2  B
    //  col: e_AXI4 Cmd: e_WRITE    Addr = 0xd5  ID = 0x6f  Len = 0x8 (8)  BurstSize = 0x0  BurstType = 0x0
      //

    }
                                   ) else begin
         `uvm_fatal(this.get_type_name(),
                    $sformatf("Unable to randomize %s",  write_item.get_full_name()));
         end  //assert

    `uvm_info("DATA", $sformatf("\n\n\nItem %0d:  %s", i, write_item.convert2string()), UVM_INFO)
    finish_item(write_item);

    get_response(write_item);

    //***** Readback
    `uvm_info("...", "Now reading back from memory to verify", UVM_LOW)



    if (write_item.burst_type == e_WRAP) begin


      //max_beat_cnt = write_item.calculate_beats(.addr         (write_item.addr),
      //                                          .number_bytes (2**write_item.burst_size),
      //                                          .burst_length (write_item.len));
      max_beat_cnt = axi_pkg::calculate_axlen(.addr(write_item.addr),
                                              .burst_size(write_item.burst_size),
                                              .burst_length(write_item.len)) + 1;

      dtsize = (2**write_item.burst_size) * max_beat_cnt;

      Lower_Wrap_Boundary = (int'(write_item.addr/dtsize) * dtsize);
      Upper_Wrap_Boundary = Lower_Wrap_Boundary + dtsize;

      pre_check_start_addr = 0;
      pre_check_stop_addr  = Lower_Wrap_Boundary;

      check_start_addr     = Lower_Wrap_Boundary;
      check_stop_addr      = Upper_Wrap_Boundary;

      post_check_start_addr      = Upper_Wrap_Boundary;
      post_check_stop_addr       = window_size;

    end else begin
       pre_check_start_addr=0;
       pre_check_stop_addr= write_item.addr; // only different if burst_type=e_WRAP;

       check_start_addr=write_item.addr;
       check_stop_addr=write_item.addr+write_item.len;

       post_check_start_addr=write_item.addr+write_item.len;
       post_check_stop_addr=window_size;
    end


    // compare pre-data
    if (precheck==1) begin
        expected_data='h0;
        for (int i=pre_check_start_addr;i<pre_check_stop_addr;i++) begin
             read_data=m_memory.read(i);
             assert(expected_data==read_data) else begin
                `uvm_error("e_FIXED miscompare",
                           $sformatf("expected: 0x%0x   actual:0x%0x",
                                     expected_data,
                                     read_data))
             end
          end
     end // if precheck

     // compare data
     if (write_item.burst_type == e_FIXED) begin

       miscompare_cntr=0;
       expected_data_array=new[write_item.data.size()];

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
        read_data     = m_memory.read(write_item.addr+y);
         if (expected_data!=read_data) begin
            miscompare_cntr++;
         end
      end


     assert (miscompare_cntr==0) else begin
        write_item_s="";
//        read_item_s="";
        expected_data_s="";
        localbuffer_s="";

       for (int z=0;z<write_item.data.size();z++) begin
          $sformat(write_item_s, "%s 0x%2x", write_item_s, write_item.data[z]);
        end


        for (int z=0;z<expected_data_array.size();z++) begin
          $sformat(expected_data_s, "%s 0x%2x", expected_data_s, expected_data_array[z]);
        end

        for (int z=0;z<localbuffer.size();z++) begin
          $sformat(localbuffer_s, "%s 0x%2x", localbuffer_s, localbuffer[z]);
        end


        `uvm_error("AXI READBACK e_FIXED miscompare",
                   $sformatf("%0d miscompares between expected and actual data items.  \nExpected: %s \nWritten: %s  \nLocalbuffer: %s", miscompare_cntr, expected_data_s, write_item_s, localbuffer_s ));
      end




     end else if (write_item.burst_type == e_INCR) begin
       for (int z=0;z<write_item.len;z++) begin
          expected_data=write_item.data[z];
         read_data=m_memory.read(write_item.addr+z);
          //s=$sformatf("%s 0x%0x", s, read_data);
          assert(expected_data==read_data) else begin
            `uvm_error("e_INCR miscompare",
                       $sformatf("addr:0x%0x expected: 0x%0x   actual:0x%0x",
                                  write_item.addr+z,
                                  expected_data,
                                  read_data))
          end
       end
     end else if (write_item.burst_type == e_WRAP) begin

       if (write_item.addr + write_item.len < Upper_Wrap_Boundary) begin
         expected_data='h0;
         for (int z=Lower_Wrap_Boundary;z<write_item.addr;z++) begin
           read_data=m_memory.read(z);
            assert(expected_data==read_data) else begin
              `uvm_fatal("e_WRAP miscompare",
                       $sformatf("expected: 0x%0x   actual:0x%0x",
                                 expected_data,
                                 read_data))
            end
         end

         for (int z=0;z<write_item.len;z++) begin
            expected_data=write_item.data[z];
           read_data=m_memory.read(write_item.addr+z);
            assert(expected_data==read_data) else begin
               `uvm_fatal("e_WRAP miscompare",
                          $sformatf("expected: 0x%0x   actual:0x%0x",
                                    expected_data,
                                    read_data))
            end
         end

         expected_data='h0;
         for (int z=write_item.addr+write_item.len;z<Upper_Wrap_Boundary;z++) begin
           read_data=m_memory.read(z);
           assert(expected_data==read_data) else begin
              `uvm_fatal("e_WRAP miscompare",
                       $sformatf("expected: 0x%0x   actual:0x%0x",
                                 expected_data,
                                 read_data))
            end
         end


       end else begin // data actually wraps.

         // compare beginning of data, which is towards the end of the boundary window
         for (int i=write_item.addr; i<Upper_Wrap_Boundary; i++) begin
            expected_data=write_item.data[i-write_item.addr];
            read_data=m_memory.read(i);
            assert(expected_data==read_data) else begin
               `uvm_error("e_WRAP miscompare",
                          $sformatf("expected: 0x%0x   actual:0x%0x",
                                    expected_data,
                                    read_data))
            end
         end

         // at which offset did the wrap occur?  compar that starting at lower_wrap_boundary

         rollover_cnt=write_item.len-((write_item.addr+write_item.len)-Upper_Wrap_Boundary);
         for (int i=rollover_cnt;i<write_item.len;i++) begin
           expected_data=write_item.data[i];
           read_data=m_memory.read(Lower_Wrap_Boundary+(i-rollover_cnt));
            assert(expected_data==read_data) else begin
              msg_s="";
              for (int j=Lower_Wrap_Boundary;j<Upper_Wrap_Boundary;j++) begin
                $sformat(msg_s, "%s 0x%2x", msg_s, m_memory.read(j));
              end
               `uvm_fatal("e_WRAP miscompare",
                          $sformatf("Wrap Window contents: [0x%0x - 0x%0x]: %s   expected: 0x%0x   actual:[0x%0x]=0x%0x (rollover_cnt: 0x%0x)",
                                    Lower_Wrap_Boundary,
                                    Upper_Wrap_Boundary-1,
                                    msg_s,
                                    expected_data,
                                    Lower_Wrap_Boundary+(i-rollover_cnt),
                                    read_data,
                                    rollover_cnt))
            end
         end

         // `uvm_warning(this.get_type_name(),
         //              "Not currently verifying eWRAP AXi readback data if data actually wraps.")
       end




     end else begin
        `uvm_fatal(this.get_type_name(), $sformatf("Invalid burst_type: %0d", write_item.burst_type))
     end


      // compare post-data
      if (postcheck==1) begin
         expected_data='h0;
        for (int i=post_check_start_addr;i<post_check_stop_addr;i++) begin
            read_data=m_memory.read(i);
            assert(expected_data==read_data) else begin
               `uvm_error("e_FIXED miscompare",
                          $sformatf("expected: 0x%0x   actual:0x%0x",
                                    expected_data,
                                    read_data))
            end
         end
      end // if postcheck



    // Now AXI readback
    `uvm_info("READBACK", "Now READING BACK via AXI", UVM_INFO)


    start_item(read_item);
    assert( read_item.randomize() with {protocol   ==     write_item.protocol;
                                        cmd        ==     e_READ;
                                        burst_size == write_item.burst_size;
                                         //burst_size inside {e_1BYTE,e_2BYTES,e_4BYTES};
                                         burst_type ==     write_item.burst_type;
                                         addr       ==     write_item.addr;
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

 //   `uvm_info("...", "Now comparing AXI readback to AXI write data", UVM_INFO)

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
           `uvm_error("AXI READBACK e_INCR miscompare",
                       $sformatf("expected: 0x%0x   actual:0x%0x",
                                 expected_data,
                                 read_data))
         end
      end
    end else begin
      `uvm_error(this.get_type_name(),
                 $sformatf("Unsupported burst type", write_item.burst_type))

    end


    `uvm_info("..", "...", UVM_HIGH)

  end  //for

  // #10us

  `uvm_info(this.get_type_name(), "SEQ ALL DONE", UVM_INFO)

endtask : body


