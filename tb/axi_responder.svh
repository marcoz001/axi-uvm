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
/*! \class axi_responder
 *  \brief Logic to act as an AXI slave (responder) for all 5 channels
 */
class axi_responder extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_responder)

  axi_if_abstract vif;
  axi_agent_config    m_config;
  memory              m_memory;

  mailbox #(axi_seq_item) readaddress_mbx  = new(0);
  mailbox #(axi_seq_item) readdata_mbx     = new(0);

  // probably unnecessary but
  // having different variables
  // makes it easier for me to follow (less confusing)
  mailbox #(axi_seq_item) writeaddress_mbx  = new(0);  //unbounded mailboxes
  mailbox #(axi_seq_item) writedata_mbx     = new(0);
  mailbox #(axi_seq_item) writeresponse_mbx = new(0);


  extern function new (string name="axi_responder", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
  extern task          run_phase                (uvm_phase phase);

  extern task          write_address;
  extern task          write_data;
  extern task          write_response;

  extern task          read_address;
  extern task          read_data;

   // If multiple write transfers are queued,
   // this allows easily testing back to back or pausing between write address transfers.
  int min_clks_between_b_transfers=0;
  int max_clks_between_b_transfers=0;

  // AXI spec, A3.2.2,  states once valid is asserted,it must stay asserted until
    // ready asserts.  These varibles let us toggle valid to beat on the ready/valid
    // logic
  bit axi_incompatible_awready_toggling_mode=0;
  bit axi_incompatible_wready_toggling_mode=0;
  bit axi_incompatible_bready_toggling_mode=0;



   int min_clks_between_ar_transfers=0;
   int max_clks_between_ar_transfers=0;

   int min_clks_between_r_transfers=0;
   int max_clks_between_r_transfers=0;

   bit axi_incompatible_rready_toggling_mode=0;

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
 * Nothing to connect so doesn't actually do anything except call parent connect phase */
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

      axi_uvm_pkg::e_SETAWREADYTOGGLEPATTERN : begin
         vif.enable_awready_toggle_pattern(.pattern(item.toggle_pattern));
      end
      axi_uvm_pkg::e_SETWREADYTOGGLEPATTERN : begin
         vif.enable_wready_toggle_pattern(.pattern(item.toggle_pattern));
      end
      axi_uvm_pkg::e_SETARREADYTOGGLEPATTERN : begin
         vif.enable_arready_toggle_pattern(.pattern(item.toggle_pattern));
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


  forever begin
    writeaddress_mbx.get(item);
    //`uvm_info(this.get_type_name(), "======>>>> axi_responder::write_address Getting address", UVM_HIGH)
    //vif.read_aw(.s(s));
    //axi_seq_item::aw_to_class(.t(item), .v(s));

    //item.data=new[item.len];
    //item.wlast=new[item.len];
    //item.wstrb=new[item.len];

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

  forever begin
     writedata_mbx.get(item);
    `uvm_info(this.get_type_name(),
              $sformatf("axi_responder::write_data - Waiting for data for %s",
                        item.convert2string()),
              UVM_HIGH)
    wlast=1'b0;
    while (wlast != 1'b1) begin
      vif.wait_for_clks(.cnt(1));
      vif.read_w(.s(s));
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


   bit [63:0] aligned_addr;

  int minval;
  int maxval;
  int wait_clks_before_next_b;

  int item_needs_init=1;

  vif.set_bvalid(1'b0);
  forever begin

    if (item == null) begin
       writeresponse_mbx.get(item);
       `uvm_info(this.get_type_name(),
                 $sformatf("axi_responder::write_response - Waiting for data for %s",
                        item.convert2string()),
              UVM_HIGH)
       item_needs_init=1;
    end

    vif.wait_for_clks(.cnt(1));

      // if done with this xfer (write address is only one clock, done with valid & ready
      if (vif.get_bready_bvalid == 1'b1) begin
      //    driver_writedata_mbx.put(item);
          item=null;

          minval=min_clks_between_b_transfers;
          maxval=max_clks_between_b_transfers;
          wait_clks_before_next_b=$urandom_range(maxval,minval);

          // Check if delay wanted
        if (wait_clks_before_next_b==0) begin
             // if not, check if there's another item
             writeresponse_mbx.try_get(item);
             if (item!=null) begin
                item_needs_init=1;
             end
          end
       end

       // Initialize values
       if (item_needs_init==1) begin
          item_needs_init=0;
       end

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

  bit iaxi_incompatible_rready_toggling_mode;

  int n=0;

  int minval;
  int maxval;
  int wait_clks_before_next_r;
  int offset;
  int beat_cntr=0;
  int beat_cntr_max;
  bit [7:0] rdata[];
  bit strb []; // throwaway

  vif.set_rvalid(1'b0);
  forever begin

    if (item == null) begin
       readdata_mbx.get(item);
       beat_cntr=0;

    end

    // Look at this only one per loop, so there's no race condition of it
    // changing mid-loop.
    iaxi_incompatible_rready_toggling_mode = axi_incompatible_rready_toggling_mode;

    vif.wait_for_clks(.cnt(1));

    // defaults. not needed but  I think is cleaner in sim
    s.rvalid = 'b0;
    s.rdata  = 'hfeed_beef;
    s.rid    = 'h0;
    // s.rstrb  = 'h0;
    s.rlast  = 1'b0;

    // Check if done with this transfer
    if (vif.get_rready()==1'b1 && vif.get_rvalid() == 1'b1) begin

      if (iaxi_incompatible_rready_toggling_mode == 1'b0) begin
         item.validcntr++;
      end

      beat_cntr++;

      beat_cntr_max=item.calculate_beats(.addr(item.addr),
                                         .number_bytes(2**item.burst_size),
                                         .burst_length(item.len));
      if (beat_cntr >= beat_cntr_max) begin
          //writeresponse_mbx.put(item);
        item = null;


          minval=min_clks_between_r_transfers;
          maxval=max_clks_between_r_transfers;
          wait_clks_before_next_r=$urandom_range(maxval,minval);

          // Check if delay wanted
        if (wait_clks_before_next_r==0) begin
             // if not, check if there's another item
             readdata_mbx.try_get(item);


          end
       end
    end  // (vif.get_rready()==1'b1 && vif.get_rvalid() == 1'b1)




    // Update values
    if (item != null) begin

       s.rvalid = 1'b1; // item.valid[item.validcntr]; // 1'b1;



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
      if (iaxi_incompatible_rready_toggling_mode == 1'b0) begin
         if (vif.get_rvalid() == 1'b0) begin
             item.validcntr++;
          end
       end else begin
             item.validcntr++;
       end
       if (item.validcntr >=  item.validcntr_max) begin
         item.validcntr=0;
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
