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
/*! \class axi_responder
 *  \brief Logic to act as an AXI slave (responder) for all 5 channels
 */
class axi_responder extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_responder)

  axi_if_abstract vif;
  axi_agent_config    m_config;
  memory              m_memory;

  mailbox #(axi_seq_item) writeaddress_mbx  = new(0);  //unbounded mailboxes
  mailbox #(axi_seq_item) writedata_mbx     = new(0);
  mailbox #(axi_seq_item) writeresponse_mbx = new(0);
  mailbox #(axi_seq_item) readaddress_mbx   = new(0);
  mailbox #(axi_seq_item) readdata_mbx      = new(0);

  extern function      new (string name="axi_responder", uvm_component parent=null);

  extern function void build_phase     (uvm_phase phase);
  extern function void connect_phase   (uvm_phase phase);
  extern task          run_phase       (uvm_phase phase);

  extern task          write_address   ();
  extern task          write_data      ();
  extern task          write_response  ();
  extern task          read_address    ();
  extern task          read_data       ();

endclass : axi_responder

/*! \brief Constructor
 *
 * Doesn't actually do anything except call parent constructor */
function axi_responder::new (string name = "axi_responder", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

/*! \brief Creates the virtual interface */
function void axi_responder::build_phase (uvm_phase phase);
  super.build_phase(phase);

  vif = axi_if_abstract::type_id::create("vif", this);
endfunction : build_phase

/*! \brief
 *
 * Nothing to connect so doesn't actually do anything except call parent connect phase
 */
function void axi_responder::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

/*! \brief Launches channel responder threads and then acts as a dispatcher
 *
 * After launching 5 different threads (one for each channel), this task
 * acts as a dispatcher.  It waits for TLM packets and then stuffs them
 * into the appropriate thread's mailbox.   IE: If it's an AXI write packet
 * then it puts the packet into the write_address's mailbox so it can handle it.
 * It the waits for the next TLM packet.
 * NOTE: it does not wait for the other thread to finish processing the packet,
 * it just puts it in the mailbox and then immediately waits for the next packet.
*/
task axi_responder::run_phase(uvm_phase phase);

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

      axi_uvm_pkg::e_READ_DATA  : begin
        readdata_mbx.put(item);
      end

   endcase

  end // forever

endtask : run_phase

/*! \brief Write Address channel thread
 *
 *  Actually does almost nothing.  The monitor handles taking AXI write data and storing
 *  it into memory and loadable logic in the axi_if handles awready.
 *  This task is basically part of a chain that guarantees that a write response
 *  won't be sent back before both write address and write data have been received.
 *  \todo: clean up this task. Destroy that chain.
 */
task axi_responder::write_address;

  axi_seq_item             item;
  axi_seq_item_aw_vector_s s;

  vif.enable_awready_toggle_pattern(m_config.awready_toggle_pattern);

  forever begin
    writeaddress_mbx.get(item);

    writedata_mbx.put(item);
  end
endtask : write_address



/*! \brief Write Data channel thread
 *
 *  Actually does almost nothing.  The monitor handles taking AXI write data and storing
 *  it into memory and loadable logic in the axi_if handles awready.
 *  This task is basically part of a chain that guarantees that a write response
 *  won't be sent back before both write address and write data have been received.
 *  \todo: clean up this task. Destroy that chain.
 */
task axi_responder::write_data;

  int          i;
  axi_seq_item item;
  axi_seq_item litem;
  int          datacnt;
  axi_seq_item_w_vector_s s;
  bit foo;
  bit wlast;

  vif.enable_wready_toggle_pattern(m_config.wready_toggle_pattern);

  forever begin
     writedata_mbx.get(item);
    `uvm_info(this.get_type_name(),
              $sformatf("axi_responder::write_data - Waiting for data for %s",
                        item.convert2string()),
              UVM_INFO)
    wlast=1'b0;
    while (wlast != 1'b1) begin
      vif.wait_for_write_data(.s(s));
      wlast=s.wlast;
    end
    // \todo: Dont' rely on wlast

     writeresponse_mbx.put(item);
  end
endtask : write_data

/*! \brief Write Response channel thread
 *
 * -#  Deassert bvalid
 * -#  Wait for TLM item in mailbox
 * -#  Initialize variables
 * -#  Write out
 * -#  if ready and valid, wait X clocks where x>=0, then check for any more queued items
 * -#  if avail, then fetch and goto 'Initialize variables' step.
 * -#  if no items to be driven on next clk,  drive all write response signals low
 *     and goto 'Wait for TLM item in mailbox' step.
 * \\todo: response values are hardcoded.   Get from response seq?
*/
task axi_responder::write_response;
  axi_seq_item item=null;
  axi_seq_item_b_vector_s s;


   bit [ADDR_WIDTH-1:0] aligned_addr;

  int minval;
  int maxval;
  int wait_clks_before_next_b;

  vif.set_bvalid(1'b0);
  forever begin

    if (item == null) begin
       writeresponse_mbx.get(item);
       `uvm_info(this.get_type_name(),
                 $sformatf("axi_responder::write_response - Waiting for data for %s",
                        item.convert2string()),
              UVM_INFO)
    end

    vif.wait_for_clks(.cnt(1));

      // if done with this xfer (write address is only one clock, done with valid & ready
      if (vif.get_bready_bvalid == 1'b1) begin

          item=null;

          minval=m_config.min_clks_between_b_transfers;
          maxval=m_config.max_clks_between_b_transfers;
          wait_clks_before_next_b=$urandom_range(maxval,minval);

          // Check if delay wanted
        if (wait_clks_before_next_b==0) begin
             // if not, check if there's another item

           if (writeresponse_mbx.try_get(item)) begin

           end
          end
       end

       // Initialize values

        // Update values <- No need in write address (only one clk per)

       // Write out
       if (item != null) begin
          s.bid   = 'h3;
          s.bresp = 'h1;
          vif.write_b(.s(s), .valid(1'b1));
         if (wait_clks_before_next_b > 0) begin
            vif.wait_for_clks(.cnt(wait_clks_before_next_b-1)); // -1 because another wait
                                                                // at beginning of loop
          end
       end   // if (item != null)

    // No item for next clock, so close out bus
    if (item == null) begin
          s.bid   = 'h0;
          s.bresp = 'h0;
      vif.write_b(.s(s), .valid(1'b0));
          vif.wait_for_clks(.cnt(1));
    end

    end // forever

endtask : write_response

/*! \brief Read Address channel thread
 *
 *  Does nothing.  The monitor handles taking AXI read data transfers and
 * creating a read data packet that gets sent to the read data channel thread.
 */
task axi_responder::read_address;
  vif.enable_arready_toggle_pattern(m_config.arready_toggle_pattern);
endtask : read_address

/*! \brief Read Data channel thread
 *
 * -# Deassert rvalid
 * -# wait for tlm packet (responder packet from axi_monitor)
 * -# loop through data
 * -# if ready and valid, wait X clocks where x>=0, then check for any more queued items
 * -# if avail, then fetch and goto 'Loop through data' step.
 * -# if no items to be driven on next clk,  drive all read data signals low
 *    and goto 'Wait for TLM item in mailbox' step.
*/
task axi_responder::read_data;
  axi_seq_item item=null;
  axi_seq_item cloned_item;
  axi_seq_item_r_vector_s s;


  int n=0;
  int j;

  int minval;
  int maxval;
  int wait_clks_before_next_r;
  int offset;
  int beat_cntr=0;
  int beat_cntr_max;
  bit [7:0] rdata[];
  bit strb []; // throwaway
  int validcntr;
  int validcntr_max;
  int valid_assert_bit;
  int clks_without_rvalid_or_rready;

  vif.set_rvalid(1'b0);
  forever begin

    if (item == null) begin
       readdata_mbx.get(item);
       beat_cntr=0;
      beat_cntr_max=axi_pkg::calculate_axlen(.addr(item.addr),
                                             .burst_size(item.burst_size),
                                             .burst_length(item.len)) + 1;
      validcntr=0;
      validcntr_max=item.valid.size();
      clks_without_rvalid_or_rready=0;
    end
    // Look at this only one per loop, so there's no race condition of it
    // changing mid-loop.

    vif.wait_for_clks(.cnt(1));

    // defaults. not needed but  I think is cleaner in sim
    s.rvalid = 'b0;
    s.rdata  = 'hfeed_beef;
    s.rid    = 'h0;
    // s.rstrb  = 'h0;
    s.rlast  = 1'b0;

    // Check if done with this transfer
    if (vif.get_rready()==1'b1 && vif.get_rvalid() == 1'b1) begin
/*
      if (iaxi_incompatible_rready_toggling_mode == 1'b0) begin
        if (++validcntr >= validcntr_max) begin
          validcntr=0;
        end
      end
*/
      beat_cntr++;


      if (beat_cntr >= beat_cntr_max) begin

        item = null;


          minval=m_config.min_clks_between_r_transfers;
          maxval=m_config.max_clks_between_r_transfers;
          wait_clks_before_next_r=$urandom_range(maxval,minval);

          // Check if delay wanted
        if (wait_clks_before_next_r==0) begin
             // if not, check if there's another item

          if (readdata_mbx.try_get(item)) begin
                beat_cntr=0;
                beat_cntr_max=axi_pkg::calculate_axlen(.addr(item.addr),
                                                       .burst_size(item.burst_size),
                                                       .burst_length(item.len)) + 1;
                validcntr=0;
                validcntr_max=item.valid.size();
                clks_without_rvalid_or_rready=0;
            end

          end
       end
    end  // (vif.get_rready()==1'b1 && vif.get_rvalid() == 1'b1)




    // Update values
    if (item != null) begin
       // if too long withoutsending any data, then add an extra valid.
       // it is entirely possible for ready and valid to not have overlap,
       // which will hang the sim.  Add additional valids to counteract.
       // \Todo: Need to report all this to help with reproducing bugs
       if (vif.get_rready()==1'b0 && vif.get_rvalid() == 1'b0) begin
          clks_without_rvalid_or_rready++;
          if (clks_without_rvalid_or_rready > m_config.clks_without_rvalid_or_rready_max) begin
            j=item.valid.size();

            valid_assert_bit=$urandom_range(j-1,0);
            item.valid[valid_assert_bit] = 1'b1;
            `uvm_info("axi_driver::write_data",
                      $sformatf("%0d clocks without ready/valid overlap.  Setting another valid[], bit %0d, to 1", clks_without_rvalid_or_rready, valid_assert_bit),
                      UVM_INFO)
            clks_without_rvalid_or_rready=0;
         end
       end

       s.rvalid = item.valid[validcntr];



      `uvm_info(this.get_type_name(),
                $sformatf("Calling get_beat_N_data:  %s",
                          item.convert2string()),
                UVM_HIGH)

      item.get_beat_N_data(.beat_cnt(beat_cntr),
                           .data_bus_bytes(vif.get_data_bus_width()/8),
                           .data(rdata),
                           .wstrb(strb),
                           .wlast(s.rlast));

      for (int x=0;x<vif.get_data_bus_width()/8;x++) begin
        s.rdata[x*8+:8] = rdata[x];
      end

       // Write out
       vif.write_r(.s(s));


             // if invalid-toggling-mode is enabled, then allow deasserting valid
       // before ready asserts.
       // Default is to stay asserted, and only allow deasssertion after ready asserts.
       // if invalid-toggling-mode is enabled, then allow deasserting valid
       // before ready asserts.
       // Default is to stay asserted, and only allow deasssertion after ready asserts.
      if (vif.get_rready()==1'b1 && vif.get_rvalid() == 1'b1) begin
          validcntr++;
          `uvm_info(this.get_type_name(),
                    $sformatf("debuga validcntr=%0d",validcntr),
                    UVM_HIGH)
      end else if (m_config.axi_incompatible_rvalid_toggling_mode == 1'b1) begin
         validcntr++;
         `uvm_info(this.get_type_name(),
                   $sformatf("debugb validcntr=%0d",validcntr),
                UVM_HIGH)
      end else if (vif.get_rvalid() == 1'b0) begin
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
       s.rvalid = 1'b0;
       s.rlast  = 1'b0;
       s.rdata  = 'h0;
 //    s.wid    = 'h0; AXI3 only
       // s.rstrb  = 'h0;

      vif.write_r(.s(s));

      if (wait_clks_before_next_r > 0) begin
        vif.wait_for_clks(.cnt(wait_clks_before_next_r-1));
                                        // -1 because another wait
                                        // at beginning of loop
       end
    end // if (item == null
  end // forever
endtask : read_data
