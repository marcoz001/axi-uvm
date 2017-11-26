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

/*! \class memory
 *  \brief Extremely simple memory model with just write() and read() methods.
 */
class memory extends uvm_component;
  `uvm_component_utils(memory)

  bit [7:0] mem[*];

  //localparam addr_width=params_pkg::AXI_ADDR_WIDTH;//64;

  extern function new(string name="memory", uvm_component parent=null);
  extern virtual function void write(input bit [ADDR_WIDTH-1:0] addr, input bit [7:0] data);
  extern virtual function bit [7:0] read (input bit [ADDR_WIDTH-1:0] addr);
  extern function bit seq_item_check(ref   axi_seq_item         item,
                                     input bit [ADDR_WIDTH-1:0] lower_addr,
                                     input bit [ADDR_WIDTH-1:0] upper_addr);

endclass : memory

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function memory::new(string name="memory", uvm_component parent=null);
   super.new(name, parent);
endfunction : new

/*! \brief Writes into memory
 *
 */
function automatic void memory::write(input bit [ADDR_WIDTH-1:0] addr, input bit [7:0] data);
  `uvm_info(this.get_type_name(), $sformatf("write mem(0x%0x)=0x%0x", addr, data), UVM_HIGH)
  mem[addr] = data;
endfunction : write

/*! \brief Reads from memory
 *
 * uses an associative array.  If reading from unwritten address, 'z is returned.
*/
function automatic bit [7:0] memory::read(input bit [ADDR_WIDTH-1:0] addr);
  if (mem.exists(addr))  begin
    `uvm_info(this.get_type_name(), $sformatf("read mem(0x%0x)=0x%0x", addr, mem[addr]), UVM_HIGH)

    return mem[addr];
  end else begin
    `uvm_info(this.get_type_name(),
              $sformatf("read unwritten memory address [0x%0x]", addr),
              UVM_HIGH)
    return 'z;
  end
endfunction : read

/*! \brief Compares an axi_seq_item's data and burst_type against expected matching memory contents
 *
 * This function takes into account fixed, incrementing and wrapped burst types.
 * That includes accounting for burst_size.
*/
function automatic bit memory::seq_item_check(
                ref   axi_seq_item         item,
                input bit [ADDR_WIDTH-1:0] lower_addr,
                input bit [ADDR_WIDTH-1:0] upper_addr);


  const int postcheck     = 1;
  const int precheck      = 1;


  int max_beat_cnt;
  int dtsize;

  bit [ADDR_WIDTH-1:0] Lower_Wrap_Boundary;
  bit [ADDR_WIDTH-1:0] Upper_Wrap_Boundary;
  bit [ADDR_WIDTH-1:0] iaddr;

  bit [ADDR_WIDTH-1:0]  pre_check_start_addr;
  bit [ADDR_WIDTH-1:0]  pre_check_stop_addr;

  bit [ADDR_WIDTH-1:0]  check_start_addr;
  bit [ADDR_WIDTH-1:0]  check_stop_addr;

  bit [ADDR_WIDTH-1:0]  post_check_start_addr;
  bit [ADDR_WIDTH-1:0]  post_check_stop_addr;


 //  string write_item_s;
  int idatacntr;
  int miscompare_cntr;
  string write_item_s;
  string read_item_s;
  string expected_data_s;
  string actual_data_s;
  string msg_s;
  string localbuffer_s;
  int rollover_cnt;

  bit [7:0] expected_data_array [];
  bit [7:0] actual_data_array [];

  bit [2:0] max_burst_size;
  int yy;
  bit [7:0] localbuffer [];
  bit [7:0] read_data;
  bit [7:0] expected_data;


  assert (item != null);

  if (item == null) begin
    `uvm_fatal(this.get_type_name(), "Item is null")
  end




    //***** Readback
    `uvm_info("...", "Now reading back from memory to verify", UVM_LOW)


    if (item.burst_type == e_WRAP) begin


      max_beat_cnt = axi_pkg::calculate_axlen(.addr(item.addr),
                                              .burst_size(item.burst_size),
                                              .burst_length(item.len)) + 1;

      dtsize = (2**item.burst_size) * max_beat_cnt;

      Lower_Wrap_Boundary = (int'(item.addr/dtsize) * dtsize);
      Upper_Wrap_Boundary = Lower_Wrap_Boundary + dtsize;

      pre_check_start_addr  = lower_addr;
      pre_check_stop_addr   = Lower_Wrap_Boundary;

      check_start_addr      = Lower_Wrap_Boundary;
      check_stop_addr       = Upper_Wrap_Boundary;

      post_check_start_addr = Upper_Wrap_Boundary;
      post_check_stop_addr  = upper_addr;

    end else begin
       pre_check_start_addr = lower_addr;
       pre_check_stop_addr  = item.addr; // only different if burst_type=e_WRAP;

       check_start_addr     = item.addr;
       check_stop_addr      = item.addr+item.len;

       post_check_start_addr = item.addr+item.len;
       post_check_stop_addr = upper_addr;
    end

    msg_s="";
  $sformat(msg_s, "%s Item: %s",                     msg_s, item.convert2string());
  $sformat(msg_s, "%s pre_check_start_addr: 0x%0x",  msg_s, pre_check_start_addr);
  $sformat(msg_s, "%s pre_check_stop_addr: 0x%0x",   msg_s, pre_check_stop_addr);
  $sformat(msg_s, "%s check_start_addr: 0x%0x",      msg_s, check_start_addr);
  $sformat(msg_s, "%s check_stop_addr: 0x%0x",       msg_s, check_stop_addr);
  $sformat(msg_s, "%s post_check_start_addr: 0x%0x", msg_s, post_check_start_addr);
  $sformat(msg_s, "%s post_check_stop_addr: 0x%0x",  msg_s, post_check_stop_addr);
  $sformat(msg_s, "%s Lower_Wrap_Boundary: 0x%0x",   msg_s, Lower_Wrap_Boundary);
  $sformat(msg_s, "%s Upper_Wrap_Boundary: 0x%0x",   msg_s, Upper_Wrap_Boundary);


    `uvm_info("CHECK MEMORY",
            msg_s,
            UVM_INFO)



     miscompare_cntr=0;

    // compare pre-data
    if (precheck==1) begin
        expected_data='h0;
        for (int i=pre_check_start_addr;i<pre_check_stop_addr;i++) begin
             read_data=read(i);
             assert(expected_data==read_data) else begin
                miscompare_cntr++;
               `uvm_error("MEMORY PRE-CHECK miscompare",
                          $sformatf("Address: 0x%0x expected: 0x%0x   actual:0x%0x",
                                    i,
                                     expected_data,
                                     read_data))
             end
          end
     end // if precheck

     // compare data
     if (item.burst_type == e_FIXED) begin

       expected_data_array = new[2**item.burst_size];
       actual_data_array   = new[2**item.burst_size];
       localbuffer         = new[2**item.burst_size];
      // brute force, not elegant at all.
      // write to local buffer, then compare that buffer (repeated) with the axi readback


      yy=0;

      for (int y=0;y<localbuffer.size();y++) begin
         localbuffer[y]='h0;
      end
      for (int y=0;y<item.len;y++) begin
        localbuffer[yy++]=item.data[y];
        if (yy >= 2**item.burst_size) begin
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
/*
      for (int y=0;y<item.data.size();y++) begin
         expected_data = expected_data_array[y];
         read_data     = read(item.addr+y);
        actual_data_array[y] = read_data;
         if (expected_data!=read_data) begin
            miscompare_cntr++;
         end
      end
*/

       // on a fixed burst, we only need to compare last beat of data
       for (int y=0;y<localbuffer.size();y++) begin
          expected_data = expected_data_array[y];
          read_data     = read(item.addr+y);
          actual_data_array[y] = read_data;
          if (expected_data!=read_data) begin
             miscompare_cntr++;
          end
       end

     assert (miscompare_cntr==0) else begin
         write_item_s="";
//        read_item_s="";
         expected_data_s="";
         actual_data_s="";
         localbuffer_s="";

         for (int z=0;z<item.data.size();z++) begin
            $sformat(write_item_s, "%s 0x%2x", write_item_s, item.data[z]);
         end


        for (int z=0;z<expected_data_array.size();z++) begin
          $sformat(expected_data_s, "%s 0x%2x", expected_data_s, expected_data_array[z]);
        end

       for (int z=0;z<actual_data_array.size();z++) begin
         $sformat(actual_data_s, "%s 0x%2x", actual_data_s, actual_data_array[z]);
        end

        for (int z=0;z<localbuffer.size();z++) begin
          $sformat(localbuffer_s, "%s 0x%2x", localbuffer_s, localbuffer[z]);
        end

        msg_s="";
       $sformat(msg_s, "%s %0d miscompares between expected and actual data items.", msg_s, miscompare_cntr );
       $sformat(msg_s, "%s \nExpected:    %s", msg_s, expected_data_s);
       $sformat(msg_s, "%s \nActual:      %s", msg_s, actual_data_s);
       $sformat(msg_s, "%s \nWritten:     %s", msg_s, write_item_s);
       $sformat(msg_s, "%s \nLocalbuffer: %s", msg_s, localbuffer_s);

        `uvm_error("READBACK e_FIXED miscompare", msg_s);
      end




     end else if (item.burst_type == e_INCR) begin
       for (int z=0;z<item.len;z++) begin
          expected_data=item.data[z];
         read_data=read(item.addr+z);
          //s=$sformatf("%s 0x%0x", s, read_data);
          assert(expected_data==read_data) else begin
                miscompare_cntr++;
            `uvm_error("e_INCR miscompare",
                       $sformatf("addr:0x%0x expected: 0x%0x   actual:0x%0x",
                                  item.addr+z,
                                  expected_data,
                                  read_data))
          end
       end
     end else if (item.burst_type == e_WRAP) begin

       if (item.addr + item.len < Upper_Wrap_Boundary) begin
         expected_data='h0;
         for (int z=Lower_Wrap_Boundary;z<item.addr;z++) begin
           read_data=read(z);
            assert(expected_data==read_data) else begin
                miscompare_cntr++;
              `uvm_fatal("e_WRAP miscompare",
                       $sformatf("expected: 0x%0x   actual:0x%0x",
                                 expected_data,
                                 read_data))
            end
         end

         for (int z=0;z<item.len;z++) begin
            expected_data=item.data[z];
           read_data=read(item.addr+z);
            assert(expected_data==read_data) else begin
                miscompare_cntr++;
               `uvm_fatal("e_WRAP miscompare",
                          $sformatf("expected: 0x%0x   actual:0x%0x",
                                    expected_data,
                                    read_data))
            end
         end

         expected_data='h0;
         for (int z=item.addr+item.len;z<Upper_Wrap_Boundary;z++) begin
           read_data=read(z);
           assert(expected_data==read_data) else begin
                miscompare_cntr++;
              `uvm_fatal("e_WRAP miscompare",
                       $sformatf("expected: 0x%0x   actual:0x%0x",
                                 expected_data,
                                 read_data))
            end
         end


       end else begin // data actually wraps.

         // compare beginning of data, which is towards the end of the boundary window
         for (int i=item.addr; i<Upper_Wrap_Boundary; i++) begin
            expected_data=item.data[i-item.addr];
            read_data=read(i);
            assert(expected_data==read_data) else begin
                miscompare_cntr++;
               `uvm_error("e_WRAP miscompare",
                          $sformatf("expected: 0x%0x   actual:0x%0x",
                                    expected_data,
                                    read_data))
            end
         end

         // at which offset did the wrap occur?  compar that starting at lower_wrap_boundary

         rollover_cnt=item.len-((item.addr+item.len)-Upper_Wrap_Boundary);
         for (int i=rollover_cnt;i<item.len;i++) begin
           expected_data=item.data[i];
           read_data=read(Lower_Wrap_Boundary+(i-rollover_cnt));
            assert(expected_data==read_data) else begin
                miscompare_cntr++;
              msg_s="";
              for (int j=Lower_Wrap_Boundary;j<Upper_Wrap_Boundary;j++) begin
                $sformat(msg_s, "%s 0x%2x", msg_s, read(j));
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
                miscompare_cntr++;
        `uvm_fatal(this.get_type_name(), $sformatf("Invalid burst_type: %0d", item.burst_type))
     end


      // compare post-data
      if (postcheck==1) begin
         expected_data='h0;
        for (int i=post_check_start_addr;i<post_check_stop_addr;i++) begin
            read_data=read(i);
            assert(expected_data==read_data) else begin
                miscompare_cntr++;
              `uvm_error("MEMORY POST-CHECK miscompare",
                          $sformatf("expected: 0x%0x   actual:0x%0x",
                                    expected_data,
                                    read_data))
            end
         end
      end // if postcheck


return (miscompare_cntr == 0);

endfunction : seq_item_check
