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

/*! \class axi_monitor
 *  \brief monitors all 5 channels for activity
 *
 * - Sends Write Address, Write Response and Read Address out on each clock
 * - Sends entire Write Data and Read Data out together
 * - Driver
 * - * Updates agent memory on each write data beat
 * - Responder
 * - * Sends a read data sequence to the responder when a read address transaction is detected
 * Main cover properties and assertions are here.
 */

class axi_monitor extends uvm_monitor;
  `uvm_component_utils(axi_monitor)

  uvm_analysis_port #(axi_seq_item) ap;
  uvm_analysis_port #(axi_seq_item) driver_activity_ap; // detect driver activity

  axi_if_abstract     vif;
  axi_agent_config    m_config;
  memory              m_memory;

  mailbox #(axi_seq_item) writedata_mbx  = new(0);
  mailbox #(axi_seq_item) readdata_mbx   = new(0);


  extern function new (string name="axi_monitor", uvm_component parent=null);

  extern function void build_phase     (uvm_phase phase);
  extern function void connect_phase   (uvm_phase phase);
  extern task          run_phase       (uvm_phase phase);

  extern task          write_address   ();
  extern task          write_data      ();
  extern task          write_response  ();
  extern task          read_address    ();
  extern task          read_data       ();

endclass : axi_monitor

/*! \brief Constructor */
function axi_monitor::new (string name="axi_monitor", uvm_component parent=null);
  super.new(name, parent);
endfunction : new

/*! \brief Creates the analysis port and virtual interface
 *
 */
function void axi_monitor::build_phase (uvm_phase phase);
  super.build_phase(phase);

  ap=new("ap", this);
  driver_activity_ap=new("driver_activity_ap", this);

  vif=axi_if_abstract::type_id::create("vif", this);

endfunction : build_phase

function void axi_monitor::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase


/*! \brief Starts the monitoring threads */
task axi_monitor::run_phase(uvm_phase phase);
  fork
    write_address();
    write_data();
    write_response();
    read_address();
    read_data();

  join
endtask : run_phase


/*! \brief monitors Write Address channel
 *
 * and sends out TLM pkt.
 * If this monitor's agent is a responder, then also creates another
 * TLM packet for Write Data channel monitoring thread to use
 * Loop
 *    Wait for activity on the Write Address Channel
 *    Convert into an axi_seq_item
 *    Send out analysis port
 *    Add to Write Data Channel monitoring thread's queue
*/
task axi_monitor::write_address();
   axi_seq_item             original_item;
   axi_seq_item             item;
  axi_seq_item  cloned2_item;
    axi_seq_item item2;
   axi_seq_item_aw_vector_s aw_s;

   original_item = axi_seq_item::type_id::create("original_item");
   original_item.len=0;


  forever begin
    vif.wait_for_write_address(.s(aw_s));
    `uvm_info(this.get_type_name(), "wait_for_write_address - DONE", UVM_INFO)

    $cast(item, original_item.clone());
    axi_uvm_pkg::aw_to_class(.t(item), .v(aw_s));
    item.cmd         = axi_uvm_pkg::e_WRITE;



    if (m_config.drv_type == e_RESPONDER) begin
      // Sending a pkt with actual data to be put on on the read data channel.
      // so this becomes a read data packet instead of a read (addr) packet
      $cast(cloned2_item, item.clone());
      //cloned2_item.cmd  = axi_uvm_pkg::e_WRITE;
      driver_activity_ap.write(cloned2_item);
    end


    // Queue up so write data channel monitor knows
    writedata_mbx.put(item);
    ap.write(item);
    `uvm_info("WRITE_ADDRESS", $sformatf("Item; %s", item.convert2string()), UVM_HIGH)

    // \todo sync up var name between methods


  end  // forever
endtask : write_address


/*! \brief monitors Write Data channel
 *
 * and sends out TLM pkt.
 * Loop
 *    Wait for activity on the Write Data Channel
 *    and push it into a queue
 *    When a write address isavailable,
 *    - pop all queued write data into the write address packet.
 *    - write to m_memory (likely the agent's local memory memory instantiation
 *    Once number of expected beats is received (matches awlen), then send out analysis port
*/
task axi_monitor::write_data();
  axi_seq_item_w_vector_s  w_s;
  axi_seq_item   item=null;
  axi_seq_item cloned_item=null;
  bit [ADDR_WIDTH-1:0] write_addr;
  int beat_cntr=0;
  int Lower_Byte_Lane;
  int Upper_Byte_Lane;
  int offset;
  string msg_s;
    axi_seq_item_w_vector_s  w_q[$];

  if (m_config.drv_type != axi_uvm_pkg::e_RESPONDER) begin
    return;
  end

  forever begin
                `uvm_info(this.get_type_name(),
                          "========> wait_for_write_data()",
                  UVM_HIGH)

    vif.wait_for_write_data(.s(w_s));
    `uvm_info(this.get_type_name(), "wait_for_write_data - DONE", UVM_HIGH)

    //  Can we just queue the data no matter what and
    // if the addresshasn'tarrived, we don't sit and poll continuosly
    // for and address.
    // What happens if we don't get an address until after wlast?
    w_q.push_back(w_s);

    if (item == null) begin
      if (writedata_mbx.num() > 0) begin
        writedata_mbx.get(item);
        $cast(cloned_item, item.clone());
        cloned_item.cmd=e_WRITE_DATA;
        cloned_item.wstrb = new[cloned_item.len];
        cloned_item.data  = new[cloned_item.len];

        beat_cntr=0;
      end
    end

    // if anything in data queue, write it out
    if (item != null) begin
    while (w_q.size() > 0) begin

       w_s=w_q.pop_front();

      axi_pkg::get_beat_N_byte_lanes(.addr         (item.addr),
                                     .burst_size   (item.burst_size),
                                     .burst_length (item.len),
                                     .burst_type   (item.burst_type),
                                     .beat_cnt        (beat_cntr),
                                 .data_bus_bytes  (vif.get_data_bus_width()/8),
                                .Lower_Byte_Lane  (Lower_Byte_Lane),
                                 .Upper_Byte_Lane (Upper_Byte_Lane),
                                 .offset          (offset));

      msg_s="";
      $sformat(msg_s, "%s beat_cntr:%0d",       msg_s, beat_cntr);
      $sformat(msg_s, "%s data_bus_bytes:%0d",  msg_s, vif.get_data_bus_width()/8);
      $sformat(msg_s, "%s Lower_Byte_Lane:%0d", msg_s, Lower_Byte_Lane);
      $sformat(msg_s, "%s Upper_Byte_Lane:%0d", msg_s, Upper_Byte_Lane);
      $sformat(msg_s, "%s offset:%0d",          msg_s, offset);

      `uvm_info("MONITOR::write_data", msg_s, UVM_HIGH)

      msg_s="wstrb: ";
      for (int x=(vif.get_data_bus_width()/8)-1;x>=0;x--) begin
        $sformat(msg_s, "%s%0b", msg_s, w_s.wstrb[x]);
      end
      `uvm_info("MONITOR::write_data", msg_s, UVM_HIGH)

      for (int x=Lower_Byte_Lane;x<=Upper_Byte_Lane;x++) begin
        // use get_next_address() to keep addresslogicall nice and in oneplace.
        // Upper and Lower Wrap Boundaries are set once the write address received


        write_addr=axi_pkg::get_next_address(
          .addr(item.addr),
          .burst_size(item.burst_size),
          .burst_length(item.len),
          .burst_type(item.burst_type),
          .beat_cnt(beat_cntr),
                                                .lane(x),
                                               .data_bus_bytes(vif.get_data_bus_width()/8));

        if (w_s.wstrb[x] == 1'b1) begin
          `uvm_info("M_MEMORY.WRITE",
                    $sformatf("[0x%0x] = 0x%2x", write_addr, w_s.wdata[x*8+:8]),
                    UVM_HIGH)
          m_memory.write(write_addr, w_s.wdata[x*8+:8]);
        end

      end

       beat_cntr++;
       if (w_s.wlast == 1'b1) begin // @Todo: count, dont rely on wlast?

          ap.write(cloned_item);
         item=null;
         beat_cntr=0;
       end
    end // while
    end// if
  end  // forever
endtask : write_data

/*! \brief monitors Write Response channel and sends out TLM pkt
 * Loop
 *    Wait for activity on the Write Response Channel
 *    Convert into an axi_seq_item
 *    Send out analysis port
*/
task axi_monitor::write_response();

  axi_seq_item_b_vector_s  b_s;
  axi_seq_item item;
  axi_seq_item cloned_item;

  item = axi_seq_item::type_id::create("item");
  forever begin
    vif.wait_for_write_response(.s(b_s));
    `uvm_info(this.get_type_name(), "wait_for_write_response - DONE", UVM_HIGH)

    $cast(cloned_item, item.clone()); // Clone is faster than creating new
    axi_uvm_pkg::b_to_class(.t(cloned_item), .v(b_s));
    cloned_item.cmd         = axi_uvm_pkg::e_WRITE_RESPONSE;
    ap.write(cloned_item);

  end  //forever

endtask : write_response

/*! \brief monitors Read Address channel
 *
 * and sends out TLM pkt.
 * If this monitor's agent is a responder, then also creates another
 * TLM packet for Read Data channel monitoring thread to use to
 * send back to the master
 * Loop
 *    Wait for activity on the Write Address Channel
 *    Convert into an axi_seq_item
 *    Send out analysis port
 *    If responder, read from agent's memory, create another TLM packet
 *            and send to Read Data channel to send back to master
*/
task axi_monitor::read_address();
  axi_seq_item_ar_vector_s ar_s;
  axi_seq_item             item;
  axi_seq_item             cloned_item;
  axi_seq_item             cloned2_item;
  bit [7:0] read_data;
  bit [ADDR_WIDTH-1:0] read_addr;
  int offset=0;
  int doffset;
  int beatcnt=0;
  int beat_cnt_max;
    int Lower_Byte_Lane;
    int Upper_Byte_Lane;
  string msg_s;
  string valid_s;
  int j;
  int valid_asserts;
  int valid_assert_bit;


  if (m_config.drv_type != axi_uvm_pkg::e_RESPONDER) begin
     return;
  end

      item = axi_seq_item::type_id::create("item");


  forever begin

    vif.wait_for_read_address(.s(ar_s));


    `uvm_info(this.get_type_name(), "wait_for_read_address - DONE", UVM_HIGH)


    $cast(cloned_item, item.clone());
    axi_uvm_pkg::ar_to_class(.t(cloned_item), .v(ar_s));
    cloned_item.cmd  = axi_uvm_pkg::e_READ;

    cloned_item.data=new[cloned_item.len];
    offset=0;
    doffset=0;

    `uvm_info("axi_monitor::read_address",
              $sformatf("rvalid.size=%0d", m_config.rvalid.size),
                    UVM_INFO)

    valid_asserts = 0;
    if (m_config.rvalid.size > 0) begin
      cloned_item.valid=new[m_config.rvalid.size](m_config.rvalid);
    end else begin
       cloned_item.valid=new[cloned_item.len];
       j=cloned_item.valid.size();
       for (int i=0;i<j;i++) begin
          cloned_item.valid[i] = $random;
       end
    end

    j=cloned_item.valid.size();
    for (int i=0;i<j;i++) begin
       if (cloned_item.valid[i] == 1'b1) begin
          valid_asserts++;
          break;
       end
    end

    if (valid_asserts==0) begin
       valid_assert_bit=$urandom_range(j-1,0);
       cloned_item.valid[valid_assert_bit] = 1'b1;
       `uvm_info("axi_monitor",
                 $sformatf("All zeros. Settin bit %0d to 1", valid_assert_bit),
                 UVM_INFO)
    end

    valid_s="";
    for (int i=0;i<j;i++) begin
       $sformat(valid_s, "%s%0b", valid_s, cloned_item.valid[i]);
    end


    beat_cnt_max=axi_pkg::calculate_axlen(.addr         (cloned_item.addr),
                                          .burst_size   (cloned_item.burst_size),
                                          .burst_length (cloned_item.len)) + 1;

    for (int beat_cntr=0;beat_cntr<beat_cnt_max;beat_cntr++) begin

          axi_pkg::get_beat_N_byte_lanes(.addr         (cloned_item.addr),
                        .burst_size   (cloned_item.burst_size),
                                         .burst_length (cloned_item.len),
                        .burst_type   (cloned_item.burst_type),
            .beat_cnt(beat_cntr),
                                 .data_bus_bytes(vif.get_data_bus_width()/8),
                                .Lower_Byte_Lane(Lower_Byte_Lane),
                                .Upper_Byte_Lane(Upper_Byte_Lane),
                                .offset(offset));

      msg_s="";
      $sformat(msg_s, "%s beat_cntr:%0d",       msg_s, beat_cntr);
      $sformat(msg_s, "%s beat_cnt_max:%0d",    msg_s, beat_cnt_max);
      $sformat(msg_s, "%s data_bus_bytes:%0d",  msg_s, vif.get_data_bus_width()/8);
      $sformat(msg_s, "%s Lower_Byte_Lane:%0d", msg_s, Lower_Byte_Lane);
      $sformat(msg_s, "%s Upper_Byte_Lane:%0d", msg_s, Upper_Byte_Lane);
      $sformat(msg_s, "%s offset:%0d",          msg_s, offset);


      `uvm_info("axi_monitor::read_address", msg_s, UVM_HIGH)


      for (int x=Lower_Byte_Lane;x<=Upper_Byte_Lane;x++) begin
        // use get_next_address() to keep addresslogicall nice and in oneplace.
        // Upper and Lower Wrap Boundaries are set once the write address received

        read_addr=axi_pkg::get_next_address(
          .addr(cloned_item.addr),
          .burst_size(cloned_item.burst_size),
          .burst_length(cloned_item.len),
          .burst_type(cloned_item.burst_type),
          .beat_cnt(beat_cntr),
                                               .lane(x),
                                              .data_bus_bytes(vif.get_data_bus_width()/8));
        //if (w_s.wstrb[x] == 1'b1) begin
        `uvm_info("M_MEMORY.READ",
                  $sformatf("[0x%0x] = 0x%2x", read_addr, m_memory.read(read_addr)),
                  UVM_HIGH)
        cloned_item.data[doffset++] = m_memory.read(read_addr);
        //end
      end


    end


    `uvm_info("AR_TO_CLASS-poost", $sformatf("%s", cloned_item.convert2string()), UVM_HIGH)




    if (m_config.drv_type == e_RESPONDER) begin
      // Sending a pkt with actual data to be put on on the read data channel.
      // so this becomes a read data packet instead of a read (addr) packet
      $cast(cloned2_item, cloned_item.clone());
      cloned2_item.cmd  = axi_uvm_pkg::e_READ_DATA;
      driver_activity_ap.write(cloned2_item);
    end

    // Now send seq item containing expected read data to slave responder
    // If you wanna test data corruption, this seq item is an easy place to do it.

    ap.write(cloned_item);
    readdata_mbx.put(cloned_item);

  end


endtask : read_address

/*! \brief monitors Read Data channel and sends out TLM pkt
 * Loop
 *    Wait for activity on the Read Data Channel,store in queue
 *    Once read address packet received, store queue contents into tlm pkt
 *    When rlast received, send out analysis port
*/
task axi_monitor::read_data();

    axi_seq_item_r_vector_s r_s;
  axi_seq_item             item=null;
  axi_seq_item             cloned_item=null;

  int beat_cntr=0;
  int Lower_Byte_Lane;
  int Upper_Byte_Lane;
  int offset;
  string msg_s;
    axi_seq_item_r_vector_s  r_q[$];

    //if (m_config.drv_type != axi_uvm_pkg::e_RESPONDER) begin
    // return;
  //end

   forever begin
                `uvm_info(this.get_type_name(),
                          "========> wait_for_read_data()",
                  UVM_HIGH)

     vif.wait_for_read_data(.s(r_s));
     `uvm_info(this.get_type_name(), "wait_for_read_data - DONE", UVM_HIGH)

     // AXI spec requires read address before read data. (otherwise how do you know
     //  what to send back?)However, we will allow it and the error will get caught
     // and shown
     r_q.push_back(r_s);

     if (item == null) begin
        if (readdata_mbx.num() > 0) begin
           readdata_mbx.get(item);
           $cast(cloned_item, item.clone());
           cloned_item.cmd=e_READ_DATA;
         //  cloned_item.initialize();
           cloned_item.data  = new[cloned_item.len];
        end
     end

     if (item != null) begin
     // if anything in data queue, write it out
     while (r_q.size() > 0) begin

        r_s=r_q.pop_front();

        if (r_s.rlast == 1'b1) begin // @Todo: count, dont rely on wlast?
           ap.write(cloned_item);
           cloned_item=null;
           item=null;
        end
     end // while
     end // if
  end  // forever


endtask : read_data

