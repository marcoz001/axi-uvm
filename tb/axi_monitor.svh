////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_monitor.svh
//
// Purpose:
//          UVM monitor for AXI UVM environment
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



/*
\todo: monitor each channel and send whole burst out ap
       update memory on each beat

*/

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

  // will move this out of monitor but for now it's quick and easy experimentation
  axi_seq_item_w_vector_s  w_q[$];
  axi_seq_item_r_vector_s  r_q[$];
  //axi_seq_item_aw_vector_s aw_q[$];
  //axi_seq_item_b_vector_s  b_q[$];
  //axi_seq_item   aw_mbx;
  mailbox #(axi_seq_item) aw_mbx  = new(0);
  mailbox #(axi_seq_item) ar_mbx  = new(0);
  // used to kick off slave seq
  axi_if_abstract     vif;
  axi_agent_config    m_config;
  memory              m_memory;

  extern function new (string name="axi_monitor", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
  extern task          run_phase                (uvm_phase phase);


  extern task monitor_write_address();
  extern task monitor_write_data();
  extern task monitor_write_response();

  extern task monitor_read_address();
  extern task monitor_read_data();

endclass : axi_monitor

/*! \brief Constructor */
function axi_monitor::new (string name="axi_monitor", uvm_component parent=null);
  super.new(name, parent);
endfunction : new

function void axi_monitor::build_phase (uvm_phase phase);
  super.build_phase(phase);
  //aw_mbx=new();

  ap=new("ap", this);
  if (m_config.drv_type == e_RESPONDER) begin
     driver_activity_ap=new("driver_activity_ap", this);
  end

  vif=axi_if_abstract::type_id::create("vif", this);

endfunction : build_phase

function void axi_monitor::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase


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
task axi_monitor::monitor_write_address();
   axi_seq_item             original_item;
   axi_seq_item             item;
    axi_seq_item item2;
   axi_seq_item_aw_vector_s aw_s;

   original_item = axi_seq_item::type_id::create("original_item");
   original_item.len=0;


  forever begin
    vif.wait_for_write_address(.s(aw_s));
    `uvm_info(this.get_type_name(), "wait_for_write_address - DONE", UVM_HIGH)

    $cast(item, original_item.clone());
    axi_seq_item::aw_to_class(.t(item), .v(aw_s));
    item.cmd         = axi_uvm_pkg::e_WRITE;

    // Queue up so write data channel monitor knows
    aw_mbx.put(item);
    ap.write(item);
    `uvm_info("WRITE_ADDRESS", $sformatf("Item; %s", item.convert2string()), UVM_HIGH)

//    if (m_config.drv_type == e_RESPONDER) begin
//       driver_activity_ap.write(item);
//    end

  end  // forever
endtask : monitor_write_address

    /*
    write to address in aw_q[0] + offset
    offset is inc'd each write.  once offset=awlen, then pop addr and reset offset
    if addr comes in while some data already in fifo?

    can we just packet everything between wlast pulses as a packet? and just ship out
    to the analysis port/
    writing to the agent's memory requires an address
    // AXI spec says data can arrive before data, but order must match
    */
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
task axi_monitor::monitor_write_data();
  axi_seq_item_w_vector_s  w_s;
  axi_seq_item   item=null;
  axi_seq_item cloned_item=null;

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
      if (aw_mbx.num() > 0) begin
        aw_mbx.get(item);
        $cast(cloned_item, item.clone());
        cloned_item.cmd=e_WRITE_DATA;
        cloned_item.initialize();

        //
        cloned_item.wstrb = new[cloned_item.len];
        cloned_item.data  = new[cloned_item.len];
      end
    end

    // if anything in data queue, write it out
    if (item != null) begin
    while (w_q.size() > 0) begin

       w_s=w_q.pop_front();
       `uvm_info(this.get_type_name(),
                 $sformatf("Lower_Byte_Lane=%0d, Upper_Byte_Lane=%0d, offset=%0d",
                           cloned_item.Lower_Byte_Lane, cloned_item.Upper_Byte_Lane,
                           cloned_item.dataoffset),
                 UVM_HIGH)
       for (int i=cloned_item.Lower_Byte_Lane;i<=cloned_item.Upper_Byte_Lane;i++) begin
          // wstrb may not be asserted. check
          if (w_s.wstrb[i]==1'b1) begin
             m_memory.write(cloned_item.Start_Address+cloned_item.dataoffset,
                            w_s.wdata[i*8+:8]);
             cloned_item.data[cloned_item.dataoffset]=w_s.wdata[i*8+:8];
          end
         // record wstrb as well so anything else that
         // needs or wants to fiddle with data, can.
          cloned_item.wstrb[cloned_item.dataoffset]=w_s.wstrb[i];
          cloned_item.dataoffset++;
       end
       cloned_item.update_address();
       if (w_s.wlast == 1'b1) begin // @Todo: count, dont rely on wlast?
          ap.write(cloned_item);
       end
    end // while
    end// if
  end  // forever
endtask : monitor_write_data

/*! \brief monitors Write Response channel and sends out TLM pkt
 * Loop
 *    Wait for activity on the Write Response Channel
 *    Convert into an axi_seq_item
 *    Send out analysis port
*/
task axi_monitor::monitor_write_response();

  axi_seq_item_b_vector_s  b_s;
  axi_seq_item item;
  axi_seq_item cloned_item;

  item = axi_seq_item::type_id::create("item");
  forever begin
    vif.wait_for_write_response(.s(b_s));
    `uvm_info(this.get_type_name(), "wait_for_write_response - DONE", UVM_HIGH)

    $cast(cloned_item, item.clone()); // Clone is faster than creating new
    axi_seq_item::b_to_class(.t(cloned_item), .v(b_s));
    cloned_item.cmd         = axi_uvm_pkg::e_WRITE_RESPONSE;
    ap.write(cloned_item);

  end  //forever

endtask : monitor_write_response

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
task axi_monitor::monitor_read_address();
  axi_seq_item_ar_vector_s ar_s;
  axi_seq_item             item;
  axi_seq_item             cloned_item;
  axi_seq_item             cloned2_item;
  int offset=0;
  int beatcnt=0;

  if (m_config.drv_type != axi_uvm_pkg::e_RESPONDER) begin
     return;
  end

      item = axi_seq_item::type_id::create("item");


  forever begin

    vif.wait_for_read_address(.s(ar_s));
//    aw_q.push_back(aw_s);

    `uvm_info(this.get_type_name(), "wait_for_read_address - DONE", UVM_HIGH)

//    `uvm_info("AR_TO_CLASS",
//              $sformatf("id:0x%0x  addr:0x%0x len:%d", ar_s.arid, ar_s.araddr, ar_s.arlen),
//              UVM_INFO)

    $cast(cloned_item, item.clone());
    axi_seq_item::ar_to_class(.t(cloned_item), .v(ar_s));
    cloned_item.cmd  = axi_uvm_pkg::e_READ;
    //item.len=(ar_s.arlen+1)*4;
    cloned_item.initialize();
    cloned_item.data=new[cloned_item.len];
    offset=0;

    //for (int z=0;z<ar_s.arlen;z++) begin
    //  for (int y=0;y<cloned_item.Number_Bytes;y++) begin
    for (int z=0;z<cloned_item.len;z++) begin
        cloned_item.data[offset]=m_memory.read(ar_s.araddr+z);
        offset++;
        // \todo; this will fail wrapped address
      end
    //end
    //end


    `uvm_info("AR_TO_CLASS_post", $sformatf("%s", cloned_item.convert2string()), UVM_HIGH)
   // item.initialize();
    //$cast(item2, item.clone());

    // Now send seq item containing expected read data to slave responder
    // If you wanna test data corruption, this seq item is an easy place to do it.

    ap.write(cloned_item);
    ar_mbx.put(cloned_item);
    `uvm_info("MONITOR_READ_ADDRESS", $sformatf("Item; %s", cloned_item.convert2string()), UVM_HIGH)
    if (m_config.drv_type == e_RESPONDER) begin
      // Sending a pkt with actual data to be put on on the read data channel.
      // so this becomes a read data packet instead of a read (addr) packet
      $cast(cloned2_item, cloned_item.clone());
      cloned2_item.cmd  = axi_uvm_pkg::e_READ_DATA;
      driver_activity_ap.write(cloned2_item);
    end

  end


endtask : monitor_read_address

/*! \brief monitors Read Data channel and sends out TLM pkt
 * Loop
 *    Wait for activity on the Read Data Channel,store in queue
 *    Once read address packet received, store queue contents into tlm pkt
 *    When rlast received, send out analysis port
*/
task axi_monitor::monitor_read_data();

    axi_seq_item_r_vector_s r_s;
  axi_seq_item             item=null;
  axi_seq_item             cloned_item=null;

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
        if (ar_mbx.num() > 0) begin
           ar_mbx.get(item);
           $cast(cloned_item, item.clone());
           cloned_item.cmd=e_READ_DATA;
           cloned_item.initialize();
           cloned_item.data  = new[cloned_item.len];
        end
     end

     if (item != null) begin
     // if anything in data queue, write it out
     while (r_q.size() > 0) begin

        r_s=r_q.pop_front();
        for (int i=cloned_item.Lower_Byte_Lane;i<=cloned_item.Upper_Byte_Lane;i++) begin
          cloned_item.data[cloned_item.dataoffset++]=r_s.rdata[i*8+:8];
        end
        cloned_item.update_address();
        if (r_s.rlast == 1'b1) begin // @Todo: count, dont rely on wlast?
           ap.write(cloned_item);
           cloned_item=null;
           item=null;
        end
     end // while
     end // if
  end  // forever


endtask : monitor_read_data

/*! \brief Starts the monitoring threads */
task axi_monitor::run_phase(uvm_phase phase);
  fork
    monitor_write_address();
    monitor_write_data();
    monitor_write_response();

    monitor_read_address();
    monitor_read_data();

  join
endtask : run_phase
