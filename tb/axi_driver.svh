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
class axi_driver extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_driver)

  axi_if_abstract vif;
  axi_agent_config    m_config;

  mailbox #(axi_seq_item) driver_writeaddress_mbx  = new(0);  //unbounded mailboxes
  mailbox #(axi_seq_item) driver_writedata_mbx     = new(0);
  mailbox #(axi_seq_item) driver_writeresponse_mbx = new(0);

  // probably unnecessary but
  // having different variables
  // makes it easier for me to follow (less confusing)
  mailbox #(axi_seq_item) responder_writeaddress_mbx  = new(0);  //unbounded mailboxes
  mailbox #(axi_seq_item) responder_writedata_mbx     = new(0);
  mailbox #(axi_seq_item) responder_writeresponse_mbx = new(0);


  extern function new (string name="axi_driver", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
  extern function void end_of_elaboration_phase (uvm_phase phase);
  extern task          run_phase                (uvm_phase phase);

  //extern task          write(ref axi_seq_item item);


  extern task          driver_run_phase;
  extern task          responder_run_phase;

  extern task          driver_write_address;
  extern task          driver_write_data;
  extern task          driver_write_response;

  extern task          responder_write_address;
  extern task          responder_write_data;
  extern task          responder_write_response;

    reg foo;

   // If multiple write transfers are queued,
   // this allows easily testing back to back or pausing between write address transfers.
  int min_clks_between_aw_transfers=0;
  int max_clks_between_aw_transfers=0;

   // If multiple write transfers are queued,
   // this allows easily testing back to back or pausing between write address transfers.
  int min_clks_between_w_transfers=0;
  int max_clks_between_w_transfers=5;



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

  if (m_config.drv_type == e_DRIVER) begin
     driver_run_phase;
  end else if (m_config.drv_type == e_RESPONDER) begin
     responder_run_phase;
  end

endtask : run_phase

task axi_driver::driver_run_phase;

  axi_seq_item item;

  vif.set_awvalid(1'b0);
  vif.set_wvalid(1'b0);
  vif.set_bready_toggle_mask(m_config.bready_toggle_mask);

  fork
    driver_write_address();
    driver_write_data();
    driver_write_response();
  join_none

  forever begin
    // Using item_done also triggers get_response() in the seq.
    seq_item_port.get(item);
    if (item.cmd == e_WRITE) begin
      driver_writeaddress_mbx.put(item);
    end
  end  //forever
endtask : driver_run_phase

task axi_driver::responder_run_phase;
  axi_seq_item item;

  item = axi_seq_item::type_id::create("item", this);


    fork
    responder_write_address();
    responder_write_data();
    responder_write_response();
  join_none


  `uvm_info(this.get_type_name(), "HEY< YOU< responder_run_phase", UVM_INFO)
  //vif.s_awready_toggle_mask(m_config.awready_toggle_mask);
  vif.set_wready_toggle_mask(m_config.wready_toggle_mask);

  vif.wait_for_not_in_reset();
  forever begin

    item = axi_seq_item::type_id::create("item", this);
    seq_item_port.get(item);
    `uvm_info(this.get_type_name(), $sformatf("DRVa: %s", item.convert2string()), UVM_INFO)

    if (item.cmd == axi_uvm_pkg::e_SETAWREADYTOGGLEPATTERN) begin
      `uvm_info(this.get_type_name(), $sformatf("Setting awready toggle patter: 0x%0x", item.toggle_pattern), UVM_INFO)
      vif.enable_awready_toggle_pattern(.pattern(item.toggle_pattern));
    end else begin
       responder_writeaddress_mbx.put(item);
    end
  end

endtask : responder_run_phase

/*
   driver_write_address - driver write address phase
   1. wait for TLM item to get queued
   2. initialize variables
   3. write out
   4. if ready and valid, wait X (x>=0 clks), then check for any more queued items
   5. if avail, then fetch and goto step 2.
   6. if no items to be drivein on next clk, the drive all write address signals low
      and goto step 1.
*/
task axi_driver::driver_write_address;

  axi_seq_item item=null;
  axi_seq_item_aw_vector_s v;

  int validcntr=0;
  int validcntr_max;
  bit ivalid;

   bit [63:0] aligned_addr;

  int minval;
  int maxval;
  int wait_clks_before_next_aw;

  int item_needs_init=1;

  forever begin

    if (item == null) begin
       driver_writeaddress_mbx.get(item);
       item_needs_init=1;
    end

    vif.wait_for_clks(.cnt(1));

      // if done with this xfer (write address is only one clock, done with valid & ready
       if (vif.get_awready_awvalid == 1'b1) begin
          driver_writedata_mbx.put(item);
          item=null;

          minval=min_clks_between_aw_transfers;
          maxval=max_clks_between_aw_transfers;
          wait_clks_before_next_aw=$urandom_range(maxval,minval);

          // Check if delay wanted
          if (wait_clks_before_next_aw==0) begin
             // if not, check if there's another item
             driver_writeaddress_mbx.try_get(item);
             if (item!=null) begin
                item_needs_init=1;
             end
          end
       end
       // Initialize values
       if (item_needs_init==1) begin
          axi_seq_item::aw_from_class(.t(item), .v(v));
          v.awlen  = item.calculate_beats(.addr(item.addr),
                                          .number_bytes(item.number_bytes),
                                          .burst_length(item.len));

          v.awaddr = item.calculate_aligned_address(.addr(v.awaddr),
                                                    .number_bytes(4));
          validcntr=0;
          validcntr_max=item.valid.size()-1; // don't go past end
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

endtask : driver_write_address

/*
   driver_write_data - driver write data phase
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
task axi_driver::driver_write_data;
  axi_seq_item item=null;
  axi_seq_item_w_vector_s s;

  bit [63:0] Start_Address;
  bit [63:0] Aligned_Address;
  bit        aligned;
  int        Number_Bytes;
  int        iNumber_Bytes;
  int        Burst_Length_Bytes;
  int        Data_Bus_Bytes;

  bit [63:0] Lower_Wrap_Boundary;
  bit [63:0] Upper_Wrap_Boundary;
  int        Lower_Byte_Lane;
  int        Upper_Byte_Lane;
  bit  [1:0] Mode;
  bit [63:0] addr;
  int        dtsize;
  int n=0;
  int        validcntr;
  int dataoffset=0;
  int item_needs_init;

  int minval;
  int maxval;
  int wait_clks_before_next_w;

  forever begin

    if (item == null) begin
       driver_writedata_mbx.get(item);
       item_needs_init=1;
    end

    vif.wait_for_clks(.cnt(1));

    // defaults. not needed but  I think is cleaner in sim
    s.wvalid = 'b0;
    s.wdata  = 'hfeed_beef;
    s.wstrb  = 'h0;
    s.wlast  = 1'b0;

    // Check if done with this transfer
    if (vif.get_wready()==1'b1 && vif.get_wvalid() == 1'b1) begin
       n =  dataoffset;
       aligned = 1;

       if (n>=Burst_Length_Bytes) begin
          driver_writeresponse_mbx.put(item);
          item = null;
          n=0;
          dataoffset=0;

          minval=min_clks_between_w_transfers;
          maxval=max_clks_between_w_transfers;
          wait_clks_before_next_w=$urandom_range(maxval,minval);

          // Check if delay wanted
          if (wait_clks_before_next_w==0) begin
             // if not, check if there's another item
             driver_writedata_mbx.try_get(item);

             if (item != null) begin
                item_needs_init=1;
             end
          end
       end
    end  // (vif.get_wready()==1'b1 && vif.get_wvalid() == 1'b1)

    // Initialize values
    if (item_needs_init == 1) begin
       addr           = item.addr;
       Start_Address  = item.addr;
       Number_Bytes   = item.number_bytes;
       Burst_Length_Bytes   = item.len;
       Data_Bus_Bytes    = 4; // @Todo: parameter? fetch from cfg_db?
       Mode              = item.burst_type;
       Aligned_Address   = (int'(addr/Number_Bytes) * Number_Bytes);
       aligned           = (Aligned_Address == addr);
       dtsize            = Number_Bytes * Burst_Length_Bytes;
       validcntr         = 0;
       if (item.burst_type == axi_pkg::e_WRAP) begin
          Lower_Wrap_Boundary = (int'(addr/dtsize) * dtsize);
          Upper_Wrap_Boundary = Lower_Wrap_Boundary + dtsize;
       end else begin
          Lower_Wrap_Boundary = 'h0;
          Upper_Wrap_Boundary = -1;
       end
       item_needs_init=0;
    end // (item_needs_init == 1)

    // Update values
    if (item != null) begin
       if ((Burst_Length_Bytes - n) < Number_Bytes) begin
          iNumber_Bytes = Burst_Length_Bytes - n;
       end else begin
          iNumber_Bytes = Number_Bytes;
       end
       if (aligned) begin
          Lower_Byte_Lane = 0;
          Upper_Byte_Lane = Lower_Byte_Lane + iNumber_Bytes - 1;
       end else begin
          Lower_Byte_Lane = addr - Aligned_Address;
          Upper_Byte_Lane = Aligned_Address + iNumber_Bytes - 1;
       end
       s.wvalid = item.valid[validcntr++]; // 1'b1;
       s.wstrb  = 'h0;
       s.wdata  = 'h0;
       s.wlast  = 1'b0;
       dataoffset=n;
       for (int j=Lower_Byte_Lane;j<=Upper_Byte_Lane;j++) begin
          s.wdata[j*8+:8] = item.data[dataoffset++];
          s.wstrb[j]      = 1'b1;
          if (dataoffset>=Burst_Length_Bytes) begin
             s.wlast=1'b1;
             break;
          end
       end // for

       // Write out
       vif.write_w(.s(s),.waitforwready(0));
    end // (item != null)

    // No item for next clock, so close out bus
    if (item == null) begin
       s.wvalid = 1'b0;
       s.wlast  = 1'b0;
       s.wdata  = 'h0;
 //    s.wid    = 'h0; AXI3 only
       s.wstrb  = 'h0;

       vif.write_w(.s(s),.waitforwready(0));

       if (wait_clks_before_next_w > 0) begin
          vif.wait_for_clks(.cnt(wait_clks_before_next_w-1));
                                        // -1 because another wait
                                        // at beginning of loop
       end
    end // if (item == null
  end // forever
endtask : driver_write_data



task axi_driver::driver_write_response;

  axi_seq_item            item;
  axi_seq_item_b_vector_s s;

  forever begin
    driver_writeresponse_mbx.get(item);
    `uvm_info(this.get_type_name(), "HEY, driver_write_response!!!!", UVM_INFO)
  //  vif.wait_for_bvalid();
    vif.read_b(.s(s));
    item.bid   = s.bid;
    item.bresp = s.bresp;
 //   `uvm_info(this.get_type_name(), "HEY, HEY, waiting on seq_item_port.put()", UVM_INFO)
    seq_item_port.put(item);
  //  `uvm_info(this.get_type_name(), "HEY, HEY, waiting on seq_item_port.put() - done", UVM_INFO)
    `uvm_info(this.get_type_name(), $sformatf("driver_write_response: %s", item.convert2string()), UVM_INFO)

  end
endtask : driver_write_response



task axi_driver::responder_write_address;

  axi_seq_item             item;
  axi_seq_item_aw_vector_s s;


  forever begin
    responder_writeaddress_mbx.get(item);
    `uvm_info(this.get_type_name(), "axi_driver::responder_write_address Getting address", UVM_INFO)
    vif.read_aw(.s(s));
    axi_seq_item::aw_to_class(.t(item), .v(s));

    item.data=new[item.len];
    item.wlast=new[item.len];
    item.wstrb=new[item.len];

    responder_writedata_mbx.put(item);
  end
endtask : responder_write_address



task axi_driver::responder_write_data;

  int          i;
  axi_seq_item item;
  axi_seq_item litem;
  int          datacnt;
  axi_seq_item_w_vector_s s;
  bit foo;

  forever begin
     responder_writedata_mbx.get(item);
    `uvm_info(this.get_type_name(),
              $sformatf("axi_driver::responder_write_data - Waiting for data for %s",
                        item.convert2string()),
              UVM_INFO)

      i=0;
      while (i<item.len/4) begin
         vif.wait_for_clks(.cnt(1));
        if (vif.get_wready_wvalid() == 1'b1)  begin
           vif.read_w(s);
           axi_seq_item::w_to_class(
            {item.data[i*4+3],
             item.data[i*4+2],
             item.data[i*4+1],
             item.data[i*4+0]},
            {item.wstrb[i*4+3],
             item.wstrb[i*4+2],
             item.wstrb[i*4+1],
             item.wstrb[i*4+0]},
            foo,
            item.wlast[i],
            .v(s));

           i++;
        `uvm_info(this.get_type_name(),
                  $sformatf("axi_driver::responder_write_data GOT %d for data for %s", i,
                        item.convert2string()),
              UVM_INFO)
      end

    end
        `uvm_info(this.get_type_name(),
                  $sformatf("axi_driver::responder_write_data responder_writeresponse_mbx.put - %s",
                        item.convert2string()),
              UVM_INFO)
     responder_writeresponse_mbx.put(item);
  end
endtask : responder_write_data

task axi_driver::responder_write_response;

  axi_seq_item item;
  axi_seq_item_b_vector_s s;

  forever begin
     responder_writeresponse_mbx.get(item);

    while (item != null) begin
      s.bid   = 'h3;
      s.bresp = 'h1;
      vif.write_b(.s(s), .valid(1'b1));

      item = null;
      responder_writeresponse_mbx.try_get(item);

      if (item == null) begin
        s.bid = 'h0;
        s.bresp = 'h0;
        vif.write_b(.s(s), .valid(1'b0));
      end
    end // while
  end  //forever

endtask : responder_write_response