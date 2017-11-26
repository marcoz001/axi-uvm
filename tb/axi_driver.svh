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
/*! \class axi_driver
 *  \brief Logic to act as an AXI master for all 5 channels
 */
class axi_driver extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_driver)

  axi_if_abstract     vif;
  axi_agent_config    m_config;
  memory              m_memory;

  mailbox #(axi_seq_item) writeaddress_mbx  = new(0);  //unbounded mailboxes
  mailbox #(axi_seq_item) writedata_mbx     = new(0);
  mailbox #(axi_seq_item) writeresponse_mbx = new(0);
  mailbox #(axi_seq_item) readaddress_mbx   = new(0);
  mailbox #(axi_seq_item) readdata_mbx      = new(0);

  extern function new (string name="axi_driver", uvm_component parent=null);

  extern function void build_phase     (uvm_phase phase);
  extern function void connect_phase   (uvm_phase phase);
  extern task          run_phase       (uvm_phase phase);

  extern task          write_address   ();
  extern task          write_data      ();
  extern task          write_response  ();
  extern task          read_address    ();
  extern task          read_data       ();


endclass : axi_driver

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function axi_driver::new (string name = "axi_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

/*! \brief Creates the virtual interface */
function void axi_driver::build_phase (uvm_phase phase);
  super.build_phase(phase);

  vif = axi_if_abstract::type_id::create("vif", this);
endfunction : build_phase

/*! \brief
 *
 * Nothing to connect so doesn't actually do anything except call parent connect phase */
function void axi_driver::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase


/*! \brief Launches channel driver threads and then acts as a dispatcher
 *
 * After launching 5 different threads (one for each channel), this task
 * acts as a dispatcher.  It waits for TLM packets and then stuffs them
 * into the appropriate thread's mailbox.   IE: If it's an AXI write packet
 * then it puts the packet into the write_address's mailbox so it can handle it.
 * It the waits for the next TLM packet.
 * NOTE: it does not wait for the other thread to finish processing the packet,
 * it just puts it in the mailbox and then immediately waits for the next packet.
*/
task axi_driver::run_phase(uvm_phase phase);

  axi_seq_item item;

    fork
       write_address();
       write_data();
       write_response();
       read_address();
       read_data();
    join_none


  forever begin

    seq_item_port.get(item);

    `uvm_info(this.get_type_name(),
              $sformatf("Item: %s", item.convert2string()),
              UVM_INFO)

    case (item.cmd)
      axi_uvm_pkg::e_WRITE : begin
        writeaddress_mbx.put(item);
      end
      axi_uvm_pkg::e_READ  : begin
        readaddress_mbx.put(item);
      end

   endcase

  end // forever

endtask : run_phase


/*! \brief Write Address channel thread
 *
 * -#  Deassert awvalid
 * -#  Wait for TLM item in mailbox
 * -#  Initialize variables
 * -#  Write out
 * -#  if ready and valid, wait X clocks where x>=0, then check for any more queued items
 * -#  if avail, then fetch and goto 'Initialize variables' step.
 * -#  if no items to be driven on next clk,  drive all write address signals low
 *     and goto 'Wait for TLM item in mailbox' step.
*/
task axi_driver::write_address;

  axi_seq_item item=null;
  axi_seq_item_aw_vector_s v;

  bit [ADDR_WIDTH-1:0] aligned_addr;

  bit [7:0] wdata [];
  bit wstrb [];

  int minval;
  int maxval;
  int wait_clks_before_next_aw;


  vif.set_awvalid(1'b0);

  vif.wait_for_not_in_reset();

  forever begin

    if (item == null) begin
       writeaddress_mbx.get(item);
      `uvm_info("axi_driver::write_address",
                $sformatf("Item: %s", item.convert2string()),
                UVM_HIGH)

       axi_uvm_pkg::aw_from_class(.t(item), .v(v));
    end

    vif.wait_for_clks(.cnt(1));

      // if done with this xfer (write address is only one clock, done with valid & ready
       if (vif.get_awready_awvalid == 1'b1) begin
          writedata_mbx.put(item);
          item=null;

          minval=m_config.min_clks_between_aw_transfers;
          maxval=m_config.max_clks_between_aw_transfers;
          wait_clks_before_next_aw=$urandom_range(maxval,minval);

          // Check if delay wanted
          if (wait_clks_before_next_aw==0) begin
             // if not, check if there's another item

            if (writeaddress_mbx.try_get(item)) begin
                    `uvm_info("axi_driver::write_address",
                $sformatf("Item: %s", item.convert2string()),
                UVM_HIGH)

                axi_uvm_pkg::aw_from_class(.t(item), .v(v));
             end
          end
       end
       // Initialize values  <-no need

       // Update values <- No need in write address (only one clk per)

       // Write out
       if (item != null) begin
          vif.write_aw(.s(v), .valid(1'b1));
       end  else begin// if (item != null)

    // No item for next clock, so close out bus
         v.awaddr  = 'h0;
         v.awid    = 'h0;
         v.awsize  = 'h0;
         v.awburst = 'h0;
         vif.write_aw(.s(v), .valid(1'b0));


        if (wait_clks_before_next_aw > 0) begin
           vif.wait_for_clks(.cnt(wait_clks_before_next_aw-1)); // -1 because another wait
                                                                // // at beginning of loop
        end
    end


    end // forever

endtask : write_address

/*! \brief Write Data channel thread
 *
 * -# Deassert wvalid
 * -# wait for TLM item to get queued
 * -# initialize variables
 * -# loop
 * -#    update variables when wready & wvalid (slave has received current beat)
 * -#    write out
 * -#    if wlast and ready and valid, wait X clocks where x>=0, then check for any more queued items
 * -#    if avail, then fetch and goto 'Initialize variables' step.
 * -#    if no items to be driven on next clk, the drive all write data signals low
         and goto 'Wait for TLM item to get queued' step.
*/
task axi_driver::write_data;
  axi_seq_item item=null;
  axi_seq_item_w_vector_s s;

  bit[7:0] wdata[];
  bit      wstrb[];

  int n=0;

  int minval;
  int maxval;
  int wait_clks_before_next_w;
  int beat_cntr=0;
  int beat_cntr_max;
  int validcntr;
  int validcntr_max;
  int j;
  int valid_asserts;
  int valid_assert_bit;

  int clks_without_wvalid_or_wready;

  vif.set_wvalid(1'b0);
  forever begin

    if (item == null) begin
       writedata_mbx.get(item);

       if (m_config.wvalid.size > 0) begin
         item.valid=new[m_config.wvalid.size](m_config.wvalid);
       end else begin
         item.valid=new[item.len];
         for (int i=0;i<item.len;i++) begin
           item.valid[i]=$random;
         end
       end

       valid_asserts = 0;
       j=item.valid.size();
       for (int i=0;i<j;i++) begin
          item.valid[i] = $random;
         if (item.valid[i] == 1'b1) begin
             valid_asserts++;
          end
       end


       // valid must be asserted at least once to avoid never sending data.
       if (valid_asserts==0) begin
          valid_assert_bit=$urandom_range(j-1,0);
          item.valid[valid_assert_bit] = 1'b1;
          `uvm_info("axi_driver::write_data",
                    $sformatf("All zeros. Settin bit %0d to 1", valid_assert_bit),
                    UVM_HIGH)
       end


      validcntr=0;
      validcntr_max=item.valid.size();

      beat_cntr=0;
      beat_cntr_max=axi_pkg::calculate_axlen(.addr(item.addr),
                                             .burst_size(item.burst_size),
                                             .burst_length(item.len)) + 1;

      clks_without_wvalid_or_wready=0;
      `uvm_info("axi_driver::write_data",
                $sformatf("Item: %s", item.convert2string()),
                UVM_HIGH)

    end


    vif.wait_for_clks(.cnt(1));


    // Check if done with this transfer

    if (vif.get_wready()==1'b1 && vif.get_wvalid() == 1'b1) begin

      beat_cntr++;

      `uvm_info("axi_driver::write_data",
                $sformatf("beat_cntr:%0d  beat_cntr_max: %0d", beat_cntr, beat_cntr_max),
                UVM_HIGH)


      if (beat_cntr >= beat_cntr_max) begin
          writeresponse_mbx.put(item);
          item = null;


          minval=m_config.min_clks_between_w_transfers;
          maxval=m_config.max_clks_between_w_transfers;
          wait_clks_before_next_w=$urandom_range(maxval,minval);

          // Check if delay wanted
          if (wait_clks_before_next_w==0) begin
             // if not, check if there's another item

            if (writedata_mbx.try_get(item)) begin
                  `uvm_info("axi_driver::write_data",
                $sformatf("Item: %s", item.convert2string()),
                UVM_HIGH)

                if (m_config.wvalid.size > 0) begin
                   item.valid=new[m_config.wvalid.size](m_config.wvalid);
                end else begin
                   item.valid=new[item.len];
                  for (int i=0;i<item.len;i++) begin
                      item.valid[i]=$random;
                   end
                end

                valid_asserts = 0;
                j=item.valid.size();
                for (int i=0;i<j;i++) begin
                   item.valid[i] = $random;
                  if (item.valid[i] == 1'b1) begin
                       valid_asserts++;
                   end
                end


                // valid must be asserted at least once to avoid never sending data.
              if (valid_asserts==0) begin
                   valid_assert_bit=$urandom_range(j-1,0);
                   item.valid[valid_assert_bit] = 1'b1;
                   `uvm_info("axi_driver::write_data",
                             $sformatf("All zeros. Settin bit %0d to 1", valid_assert_bit),
                             UVM_HIGH)
                end

                validcntr=0;
                validcntr_max=item.valid.size();

                beat_cntr=0;
                beat_cntr_max=axi_pkg::calculate_axlen(.addr(item.addr),
                                                       .burst_size(item.burst_size),
                                                       .burst_length(item.len)) + 1;
                clks_without_wvalid_or_wready=0;
            end

          end
       end
    end  // (vif.get_wready()==1'b1 && vif.get_wvalid() == 1'b1)


    // Update values
    if (item != null) begin
       // if too long withoutsending any data, then add an extra valid.
       // it is entirely possible for ready and valid to not have overlap,
       // which will hang the sim.  Add additional valids to counteract.
       // \Todo: Need to report all this to help with reproducing bugs
       if (vif.get_wready()==1'b0 && vif.get_wvalid() == 1'b0) begin
          clks_without_wvalid_or_wready++;
          if (clks_without_wvalid_or_wready > m_config.clks_without_wvalid_or_wready_max) begin
            j=item.valid.size();

            valid_assert_bit=$urandom_range(j-1,0);
            item.valid[valid_assert_bit] = 1'b1;
            `uvm_info("axi_driver::write_data",
                      $sformatf("%0d clocks without ready/valid overlap.  Setting another valid[], bit %0d, to 1", clks_without_wvalid_or_wready, valid_assert_bit),
                      UVM_INFO)
            clks_without_wvalid_or_wready=0;
         end
       end

       s.wvalid = item.valid[validcntr]; // 1'b1;

      `uvm_info(this.get_type_name(),
                $sformatf("Calling get_beat_N_data:  %s",
                          item.convert2string()),
                UVM_HIGH)

      item.get_beat_N_data(.beat_cnt(beat_cntr),
                           .data_bus_bytes(vif.get_data_bus_width()/8),
                            .data(wdata),
                            .wstrb(wstrb),
                            .wlast(s.wlast));

      for (int x=0;x<vif.get_data_bus_width()/8;x++) begin
        s.wdata[x*8+:8] = wdata[x];
        s.wstrb[x]      = wstrb[x];
      end

       // Write out
       vif.write_w(.s(s));


       // if invalid-toggling-mode is enabled, then allow deasserting valid
       // before ready asserts.
       // Default is to stay asserted, and only allow deasssertion after ready asserts.
       if (vif.get_wready()==1'b1 && vif.get_wvalid() == 1'b1) begin
          validcntr++;
          `uvm_info(this.get_type_name(),
                    $sformatf("debuga validcntr=%0d",validcntr),
                    UVM_HIGH)
       end else if (m_config.axi_incompatible_wvalid_toggling_mode == 1'b1) begin
         validcntr++;
         `uvm_info(this.get_type_name(),
                   $sformatf("debugb validcntr=%0d",validcntr),
                UVM_HIGH)
       end else if (vif.get_wvalid() == 1'b0) begin
         validcntr++;
         `uvm_info(this.get_type_name(),
                   $sformatf("debugc validcntr=%0d",validcntr),
                UVM_HIGH)

        end
       if (validcntr >=  validcntr_max) begin
         validcntr=0;
       end


    end // (item != null)

    // No item for next clock, so close out bus
    if (item == null) begin
       s.wvalid = 1'b0;
       s.wlast  = 1'b0;
       s.wdata  = 'h0;
 //    s.wid    = 'h0; AXI3 only
       s.wstrb  = 'h0;

       vif.write_w(.s(s));

       if (wait_clks_before_next_w > 0) begin
          vif.wait_for_clks(.cnt(wait_clks_before_next_w-1));
                                        // -1 because another wait
                                        // at beginning of loop
       end
    end // if (item == null
  end // forever
endtask : write_data




/*! \brief Write Response channel thread
 *
 *  Wait for write response (bvalid and bready)
 *  Convert to TLM itemand send back to sequence
 * \todo: this task needs to be cleaned up.  it doesn't actually wait for response
 *
*/
task axi_driver::write_response;

  axi_seq_item            item;
  axi_seq_item_b_vector_s s;

  vif.enable_bready_toggle_pattern(m_config.bready_toggle_pattern);

  // \todo: Ch to be like others. wait for write_resonse, add to quque, then
  // process.
  // // need timeout on get ???

  forever begin
    writeresponse_mbx.get(item);

    item.cmd = e_WRITE_RESPONSE;
    vif.wait_for_write_response(.s(s));
    item.bid   = s.bid;
    item.bresp = s.bresp;
    seq_item_port.put(item);


  end
endtask : write_response


/*! \brief Read Address channel thread
 *
 * -#  Deassert arvalid
 * -#  Wait for TLM item in mailbox
 * -#  Initialize variables
 * -#  Write out
 * -#  if ready and valid, wait X clocks where x>=0, then check for any more queued items
 * -#  if avail, then fetch and goto 'Initialize variables' step.
 * -#  if no items to be driven on next clk,  drive all read address signals low
 *     and goto 'Wait for TLM item in mailbox' step.
*/
task axi_driver::read_address;

  axi_seq_item item=null;
  axi_seq_item_ar_vector_s v;

   bit [ADDR_WIDTH-1:0] aligned_addr;


  int minval;
  int maxval;
  int wait_clks_before_next_ar;


  vif.set_arvalid(1'b0);

  vif.wait_for_not_in_reset();

  forever begin

    if (item == null) begin
       readaddress_mbx.get(item);
      `uvm_info("axi_driver::read_address",
                $sformatf("Item: %s", item.convert2string()),
                UVM_HIGH)

       axi_uvm_pkg::ar_from_class(.t(item), .v(v));
    end

    vif.wait_for_clks(.cnt(1));

      // if done with this xfer (write address is only one clock, done with valid & ready
       if (vif.get_arready_arvalid == 1'b1) begin
          readdata_mbx.put(item);
          item=null;

          minval=m_config.min_clks_between_ar_transfers;
          maxval=m_config.max_clks_between_ar_transfers;
          wait_clks_before_next_ar=$urandom_range(maxval,minval);

          // Check if delay wanted
          if (wait_clks_before_next_ar==0) begin
             // if not, check if there's another item

            if (readaddress_mbx.try_get(item)) begin

                axi_uvm_pkg::ar_from_class(.t(item), .v(v));
             end
          end
       end
       // Initialize values  <-no need

       // Update values <- No need in write address (only one clk per)

       // Write out
       if (item != null) begin
          vif.write_ar(.s(v), .valid(1'b1));
       end  else begin// if (item != null)

    // No item for next clock, so close out bus
    // if (item == null) begin
         v.araddr  = 'h0;
         v.arid    = 'h0;
         v.arsize  = 'h0;
         v.arburst = 'h0;
         vif.write_ar(.s(v), .valid(1'b0));
    // end

        if (wait_clks_before_next_ar > 0) begin
           vif.wait_for_clks(.cnt(wait_clks_before_next_ar-1)); // -1 because another wait
                                                                // // at beginning of loop
        end
    end


    end // forever
endtask : read_address


/*! \brief monitors Read Data channel and sends out TLM pkt
 *
 * This task should match the corresponding on in axi_monitor but
 * it doesn't yet
 * \todo: match read_data task in axi_monitor
 * Instead it waits for a pkt in its mailbox.  This packet will come
 * from read_address once it has put the address out on the bus.
 * The just continually waits for a valid and ready beat on the channel
 * and stores it in that packet it got from read address.
 * When rlast received, send out analysis port and goes back to
 * waiting for next pkt from read address.
*/
task axi_driver::read_data;

   axi_seq_item_r_vector_s  r_s;
   axi_seq_item_r_vector_s  r_q[$];
   axi_seq_item   item=null;
   axi_seq_item cloned_item=null;
   bit [ADDR_WIDTH-1:0] read_addr;
   int beat_cntr=0;
   int beat_cntr_max=0;
   int Lower_Byte_Lane;
   int Upper_Byte_Lane;
   int offset;
   string msg_s;

  vif.enable_rready_toggle_pattern(.pattern(m_config.rready_toggle_pattern));

   forever begin
      `uvm_info(this.get_type_name(),
                "========> wait_for_read_data()",
                UVM_HIGH)

      vif.wait_for_read_data(.s(r_s));
      `uvm_info(this.get_type_name(), "wait_for_read_data - DONE", UVM_HIGH)

      //  Can we just queue the data no matter what and
      // if the addresshasn'tarrived, we don't sit and poll continuosly
      // for and address.
      // What happens if we don't get an address until after wlast?
      r_q.push_back(r_s);

      if (item == null) begin
        if (readdata_mbx.num() > 0) begin
          readdata_mbx.get(item);
          $cast(cloned_item, item.clone());
          cloned_item.set_id_info(item);

          cloned_item.cmd=e_READ_DATA;
          cloned_item.data  = new[cloned_item.len];

          beat_cntr=0;
          beat_cntr_max=axi_pkg::calculate_axlen(.addr         (cloned_item.addr),
                                                 .burst_size   (cloned_item.burst_size),
                                                 .burst_length (cloned_item.len)) + 1;
        end  // if .num > 0
      end // if item == null

      // if anything in data queue, write it out
      if (item != null) begin
         while (item != null && r_q.size() > 0) begin

            r_s=r_q.pop_front();
            axi_pkg::get_beat_N_byte_lanes(.addr         (cloned_item.addr),
                                           .burst_size   (cloned_item.burst_size),
                                           .burst_length (cloned_item.len),
                                           .burst_type   (cloned_item.burst_type),
                                           .beat_cnt        (beat_cntr),
                                           .data_bus_bytes  (vif.get_data_bus_width()/8),
                                           .Lower_Byte_Lane  (Lower_Byte_Lane),
                                           .Upper_Byte_Lane (Upper_Byte_Lane),
                                           .offset          (offset));

            msg_s="";
           $sformat(msg_s, "%s beat_cntr:%0d",       msg_s, beat_cntr);
           $sformat(msg_s, "%s beat_cntr_max:%0d",   msg_s, beat_cntr_max);
           $sformat(msg_s, "%s data_bus_bytes:%0d",  msg_s, vif.get_data_bus_width()/8);
           $sformat(msg_s, "%s Lower_Byte_Lane:%0d", msg_s, Lower_Byte_Lane);
           $sformat(msg_s, "%s Upper_Byte_Lane:%0d", msg_s, Upper_Byte_Lane);
           $sformat(msg_s, "%s offset:%0d",          msg_s, offset);

           // `uvm_info("driver::read_data", msg_s, UVM_INFO)

           msg_s="data: 0x";
           for (int z=(vif.get_data_bus_width()/8)-1;z>=0;z--) begin
             $sformat(msg_s, "%s%02x", msg_s, r_s.rdata[z*8+:8]);
           end
           // `uvm_info("driver::read_data", msg_s, UVM_INFO)

           for (int z=Lower_Byte_Lane;z<=Upper_Byte_Lane;z++) begin
              if (offset < cloned_item.len) begin
                 cloned_item.data[offset++] = r_s.rdata[z*8+:8];
              end
           end

           beat_cntr++;
           // if (r_s.rlast == 1'b1) begin // @Todo: count, dont rely on wlast?
           if (beat_cntr >= beat_cntr_max) begin
              // ap.write(cloned_item);
              seq_item_port.put(cloned_item);
             item=null;
             beat_cntr=0;
           end  // if .wlast == 1
        end // while
     end// if
  end  // forever

endtask : read_data


