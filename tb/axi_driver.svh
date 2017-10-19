////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_driver.svh
//
// Purpose:
//          UVM driver for AXI UVM environment
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
class axi_driver_pre extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_driver_pre)

    axi_if_abstract vif;
  axi_agent_config    m_config;
  memory              m_memory;


  extern function new (string name="axi_driver_pre", uvm_component parent=null);

endclass : axi_driver_pre

function axi_driver_pre::new (
  string        name   = "axi_driver_pre",
  uvm_component parent = null);

  super.new(name, parent);
endfunction : new



class axi_driver extends axi_driver_pre;
  `uvm_component_utils(axi_driver)

 // axi_if_abstract vif;
 // axi_agent_config    m_config;
 // memory              m_memory;

  mailbox #(axi_seq_item) writeaddress_mbx  = new(0);  //unbounded mailboxes
  mailbox #(axi_seq_item) writedata_mbx     = new(0);
  mailbox #(axi_seq_item) writeresponse_mbx = new(0);

  mailbox #(axi_seq_item) readaddress_mbx  = new(0);
  mailbox #(axi_seq_item) readdata_mbx     = new(0);

  extern function new (string name="axi_driver", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
  extern function void end_of_elaboration_phase (uvm_phase phase);
  extern task          run_phase                (uvm_phase phase);

  extern task          write_address;
  extern task          write_data;
  extern task          write_response;

  extern task          read_address;
  extern task          read_data;

   // If multiple write transfers are queued,
   // this allows easily testing back to back or pausing between write address transfers.
  int min_clks_between_aw_transfers=0;
  int max_clks_between_aw_transfers=0;

  int min_clks_between_w_transfers=0;
  int max_clks_between_w_transfers=0;

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

endclass : axi_driver

function axi_driver::new (
  string        name   = "axi_driver",
  uvm_component parent = null);

  super.new(name, parent);
endfunction : new

function void axi_driver::build_phase (uvm_phase phase);
  super.build_phase(phase);

  vif = axi_if_abstract::type_id::create("vif", this);

endfunction : build_phase

function void axi_driver::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

function void axi_driver::end_of_elaboration_phase (uvm_phase phase);
  super.end_of_elaboration_phase(phase);
endfunction : end_of_elaboration_phase

task axi_driver::run_phase(uvm_phase phase);


  axi_seq_item item;
  axi_seq_item cloned_item;

    fork
       write_address();
       write_data();
       write_response();

       read_address();
       read_data();
    join_none


  forever begin

    seq_item_port.get(item);
    $cast(cloned_item, item.clone());

    `uvm_info("axi_driver::run_phase",
              $sformatf("YO: %s", item.convert2string()),
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


/*
   write_address - driver write address phase
   1. wait for TLM item to get queued
   2. initialize variables
   3. write out
   4. if ready and valid, wait X (x>=0 clks), then check for any more queued items
   5. if avail, then fetch and goto step 2.
   6. if no items to be drivein on next clk, the drive all write address signals low
      and goto step 1.
*/
task axi_driver::write_address;

  axi_seq_item item=null;
  axi_seq_item_aw_vector_s v;

   bit [63:0] aligned_addr;

  int minval;
  int maxval;
  int wait_clks_before_next_aw;

  int item_needs_init=1;

  vif.set_awvalid(1'b0);

  forever begin

    if (item == null) begin
       writeaddress_mbx.get(item);
      `uvm_info("axi_driver::write_address",
                $sformatf("Item: %s", item.convert2string()),
                UVM_INFO)
       item_needs_init=1;
    end

    vif.wait_for_clks(.cnt(1));

      // if done with this xfer (write address is only one clock, done with valid & ready
       if (vif.get_awready_awvalid == 1'b1) begin
          writedata_mbx.put(item);
          item=null;

          minval=min_clks_between_aw_transfers;
          maxval=max_clks_between_aw_transfers;
          wait_clks_before_next_aw=$urandom_range(maxval,minval);

          // Check if delay wanted
          if (wait_clks_before_next_aw==0) begin
             // if not, check if there's another item
             writeaddress_mbx.try_get(item);
             if (item!=null) begin
                item_needs_init=1;
             end
          end
       end
       // Initialize values
       if (item_needs_init==1) begin
          item.aw_from_class(.t(item), .v(v));

          item_needs_init=0;
       end

        // Update values <- No need in write address (only one clk per)

       // Write out
       if (item != null) begin
          vif.write_aw(.s(v), .valid(1'b1));
          if (wait_clks_before_next_aw > 0) begin
             vif.wait_for_clks(.cnt(wait_clks_before_next_aw-1)); // -1 because another wait
                                                                // at beginning of loop
          end
       end   // if (item != null)

    // No item for next clock, so close out bus
    if (item == null) begin
         v.awaddr  = 'h0;
         v.awid    = 'h0;
         v.awsize  = 'h0;
         v.awburst = 'h0;
         vif.write_aw(.s(v), .valid(1'b0));
         vif.wait_for_clks(.cnt(1));
    end

    end // forever

endtask : write_address

/*
   write_data - driver write data phase
   1. wait for TLM item to get queued
   2. initialize variables
   3. loop
   4.    update variables when wready & wvalid (slave has received current beat)
   5.    write out
   6. if wlast and ready and valid, wait X (x>=0 clks), then check for any more queued items
   7. if avail, then fetch and goto step 2.
   8. if no items to be drivein on next clk, the drive all write data signals low
      and goto step 1.
*/
task axi_driver::write_data;
  axi_seq_item item=null;
  axi_seq_item_w_vector_s s;

  bit iaxi_incompatible_wready_toggling_mode;

  int n=0;

  int minval;
  int maxval;
  int wait_clks_before_next_w;

  vif.set_wvalid(1'b0);
  forever begin

    if (item == null) begin
       writedata_mbx.get(item);
      item.initialize();
      `uvm_info("axi_driver::write_data",
                $sformatf("Item: %s", item.convert2string()),
                UVM_INFO)
    end

    // Look at this only one per loop, so there's no race condition of it
    // changing mid-loop.
    iaxi_incompatible_wready_toggling_mode = axi_incompatible_wready_toggling_mode;

    vif.wait_for_clks(.cnt(1));

    // defaults. not needed but  I think is cleaner in sim
    s.wvalid = 'b0;
    s.wdata  = 'hfeed_beef;
    s.wstrb  = 'h0;
    s.wlast  = 1'b0;

    // Check if done with this transfer
    if (vif.get_wready()==1'b1 && vif.get_wvalid() == 1'b1) begin
      item.dataoffset = n;
      if (iaxi_incompatible_wready_toggling_mode == 1'b0) begin
         item.validcntr++;
      end

      item.update_address();

      if (item.dataoffset>=item.Burst_Length_Bytes) begin //F
          writeresponse_mbx.put(item);
          item = null;

          minval=min_clks_between_w_transfers;
          maxval=max_clks_between_w_transfers;
          wait_clks_before_next_w=$urandom_range(maxval,minval);

          // Check if delay wanted
          if (wait_clks_before_next_w==0) begin
             // if not, check if there's another item
             writedata_mbx.try_get(item);

             if (item != null) begin
               item.initialize();
             end
          end
       end
    end  // (vif.get_wready()==1'b1 && vif.get_wvalid() == 1'b1)


    // Update values
    if (item != null) begin

      if (item.validcntr >=  item.validcntr_max) begin
         item.validcntr=0;
       end

       //
       // if invalid-toggling-mode is enabled, then allow deasserting valid
       // before ready asserts.
       // Default is to stay asserted, and only allow deasssertion after ready asserts.
       if (iaxi_incompatible_wready_toggling_mode == 1'b0) begin
          if (vif.get_wvalid() == 1'b0) begin
             item.validcntr++;
          end
       end else begin
             item.validcntr++;
       end

       s.wvalid = item.valid[item.validcntr]; // 1'b1;
       s.wstrb  = 'h0;
       s.wdata  = 'h0;
       s.wlast  = 1'b0;
       n=item.dataoffset;
      for (int j=item.Lower_Byte_Lane;j<=item.Upper_Byte_Lane;j++) begin
        s.wdata[j*8+:8] = item.data[n++];
          s.wstrb[j]      = 1'b1;
        if (n>=item.Burst_Length_Bytes) begin
             s.wlast=1'b1;
             break;
          end
       end // for

       // Write out
       vif.write_w(.s(s));


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



task axi_driver::write_response;

  axi_seq_item            item;
  axi_seq_item_b_vector_s s;

  vif.enable_bready_toggle_pattern(m_config.bready_toggle_pattern);

  forever begin
    writeresponse_mbx.get(item);
 //   `uvm_info(this.get_type_name(), "HEY, write_response!!!!", UVM_INFO)
  //  vif.wait_for_bvalid();
    vif.read_b(.s(s));
    item.bid   = s.bid;
    item.bresp = s.bresp;
 //   `uvm_info(this.get_type_name(), "HEY, HEY, waiting on seq_item_port.put()", UVM_INFO)
    seq_item_port.put(item);
  //  `uvm_info(this.get_type_name(), "HEY, HEY, waiting on seq_item_port.put() - done", UVM_INFO)
  //  `uvm_info(this.get_type_name(), $sformatf("write_response: %s", item.convert2string()), UVM_INFO)

  end
endtask : write_response



task axi_driver::read_address;

  axi_seq_item item=null;
  axi_seq_item_ar_vector_s v;

   bit [63:0] aligned_addr;

  int minval;
  int maxval;
  int wait_clks_before_next_ar;

  int item_needs_init=1;

  vif.set_arvalid(1'b0);

  forever begin

    if (item == null) begin
       readaddress_mbx.get(item);
       item_needs_init=1;
    end

    vif.wait_for_clks(.cnt(1));

      // if done with this xfer (write address is only one clock, done with valid & ready
    if (vif.get_arready_arvalid == 1'b1) begin
          readdata_mbx.put(item);
          item=null;

          minval=min_clks_between_ar_transfers;
          maxval=max_clks_between_ar_transfers;
          wait_clks_before_next_ar=$urandom_range(maxval,minval);

          // Check if delay wanted
      if (wait_clks_before_next_ar==0) begin
             // if not, check if there's another item
             readaddress_mbx.try_get(item);
             if (item!=null) begin
                item_needs_init=1;
             end
          end
       end
       // Initialize values
       if (item_needs_init==1) begin
          item.ar_from_class(.t(item), .v(v));
          //v.arlen  = item.calculate_beats(.addr(item.addr),
         //                                 .number_bytes(2**item.burst_size), //item.number_bytes
          //                                .burst_length(item.len));

          //v.arlen = v.arlen-1; // value is one less than cnt. IE: awlen=0, then 1 beat

          //v.araddr = item.calculate_aligned_address(.addr(v.araddr),
          //                                          .number_bytes(4));
          item_needs_init=0;
       end

        // Update values <- No need in write address (only one clk per)

       // Write out
       if (item != null) begin
          vif.write_ar(.s(v), .valid(1'b1));
         if (wait_clks_before_next_ar > 0) begin
           vif.wait_for_clks(.cnt(wait_clks_before_next_ar-1)); // -1 because another wait
                                                                // at beginning of loop
          end
       end   // if (item != null)

    // No item for next clock, so close out bus
    if (item == null) begin
         v.araddr  = 'h0;
         v.arid    = 'h0;
         v.arsize  = 'h0;
         v.arburst = 'h0;
         v.arlen   = 'h0;
         vif.write_ar(.s(v), .valid(1'b0));
         vif.wait_for_clks(.cnt(1));
    end

    end // forever

endtask : read_address

task axi_driver::read_data;

  axi_seq_item_r_vector_s  r_s;
  axi_seq_item item=null;

  vif.enable_rready_toggle_pattern(.pattern(m_config.rready_toggle_pattern));

  forever begin

    if (item == null) begin
  readdata_mbx.get(item);
  item.initialize();
  item.data=new[item.len];
  item.dataoffset=0;
      `uvm_info(this.get_type_name(), $sformatf("%s", item.convert2string()), UVM_HIGH)
    end


 // forever begin
    vif.wait_for_read_data(.s(r_s));

    `uvm_info(this.get_type_name(),$sformatf("r_s.data: 0x%0x   LowerLane:%0d   Upperlane:%0d   dataoffset=%0d", r_s.rdata,item.Lower_Byte_Lane,item.Upper_Byte_Lane, item.dataoffset),
             UVM_HIGH)


    for (int z=item.Lower_Byte_Lane;z<=item.Upper_Byte_Lane;z++) begin
      if (item.dataoffset < item.len) begin
         item.data[item.dataoffset++] = r_s.rdata[z*8+:8];
      end
    //  `uvm_info("DATAOFFSET",
     //           $sformatf("data: 0x%0x -- item:0x%0x -- offset:%0d", r_s.rdata[z*8+:8], item.data[item.dataoffset-1], item.dataoffset-1),
      //          UVM_INFO)

    end
    item.update_address();
    // `uvm_info("read_data", "YO, got beat:", UVM_INFO)
    if (r_s.rlast == 1'b1) begin
     // `uvm_info("read_data", "YO, got rlast:", UVM_INFO)
      seq_item_port.put(item);
      item=null;
    end
  end   //forever

//end


endtask : read_data


