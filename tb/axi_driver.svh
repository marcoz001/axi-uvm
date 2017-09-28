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
      vif.enable_awready_toggle_pattern(.pattern(item.toggle_pattern));
    end else begin
       responder_writeaddress_mbx.put(item);
    end
  end
                                        
endtask : responder_run_phase
    /*
// DataTransfer() from AXI Spec. A3.4.2
task axi_driver::DataTransfer(bit [63:0]          start_address,
                              int                 number_bytes,
                              int                 burst_length,
                              int                 data_bus_bytes,
                              axi_transfer_mode_t mode,
                              bit                 iswrite);
    // Data_Bus_Bytes is the number of 8-bit byte lanes in the bus
    // Mode is the AXI transfer mode
    // IsWrite is TRUE fora  write, and FALSE for a read
    // Burst_Length = beat cnt
    // dtsize is data transfer size (total bytes)
  
  
    bit [63:0] addr;
    bit [63:0] aligned_address;
    bit        aligned;
    int        dtsize;
  
    addr            = start_address;
    aligned_address = (int(addr/number_bytes) * number_bytes);
    aligned         = (aligned_address == addr);
    dtdize          = Number_Bytes * Burst_Length;
    
  if (item.burst_type == axi_pkg::e_WRAP) begin
       Lower_Wrap_Boundary = (int(addr/dtdize) * dtsize);
       Upper_Wrap_Boundary = Lower_Wrap_Boundary + dtsize;
    end
    
    for (int n=1; n<Burst_Length; n++) begin
       Lower_Byte_Lane = addr - (int(addr/Data_Bus_Bytes)) * Data_Bus_Bytes;
       if (aligned) begin
          Upper_Byte_Lane = Lower_Byte_Lane + Number_Bytes - 1;
       end else begin
          Upper_Byte_Lane = Aligned_Address + Number_Butes - 1 - (int(addr/Data_Bus_Bytes)) * Data_Bus_Bytes;
       end
       
       
      if (iswrite) begin
          dwrite(addr, low_byte, high_byte);
      else
          dread(addr,low_byte, high_byte);
        
      // Increment address if necessary
        if (item.burst_type != axi_pkg::e_FIXED) begin
          if (aligned) begin
            addr = addr + Number_Bytes;
            if (item.burst_type == axi_pkg::e_WRAP) begin
              // WRAP mode is always aligned
              if (addr >= Uper_Wrap_Boundar) begin
                addr = Lower_Wrap_Boundary;
              end
            end
          end else begin
            addr    = addr + Number_Bytes;
            aligned = 1'b1;
          end
        end // (item.burst_type != axi_pkg::e_FIXED)
    end
    
endtask : datatransfer    
    */
    
task axi_driver::driver_write_address;
  
  axi_seq_item item;
  axi_seq_item_aw_vector_s v;

  int validcntr=0;
  int validcntr_max;
  bit ivalid;
  
   bit [63:0] aligned_addr;
  
  
  forever begin

    if (item == null) begin
     driver_writeaddress_mbx.get(item);
     axi_seq_item::aw_from_class(.t(item), .v(v));
      v.awlen  = item.calculate_beats(.addr(item.addr),
                                      .number_bytes(item.number_bytes),
                                      .burst_length(item.len));
      
      v.awaddr = item.calculate_aligned_address(.addr(v.awaddr),
                                                .number_bytes(4));
      validcntr=0;
      validcntr_max=item.valid.size()-1; // don't go past end
    end
    
    if (item != null) begin
       vif.wait_for_clks(.cnt(1));

       ivalid=item.valid[validcntr];
       if (vif.get_awready_awvalid == 1'b1) begin
         driver_writedata_mbx.put(item);
         item=null;
         validcntr=0;
         ivalid=0;
         v.awaddr = 'h0;
         v.awid='h0;
         v.awsize='h0;
         v.awburst = 'h0;

         driver_writeaddress_mbx.try_get(item);
         if (item!=null) begin
           axi_seq_item::aw_from_class(.t(item), .v(v));
           v.awlen  = item.calculate_beats(.addr(v.awaddr),
                                           .number_bytes(4),
                                           .burst_length(item.len));
      
           v.awaddr = item.calculate_aligned_address(.addr(v.awaddr),
                                                     .number_bytes(4));
           
           
           ivalid=item.valid[validcntr];
           validcntr_max=item.valid.size()-1; // don't go past end
           
         end
      end
    end  

    vif.write_aw(.s(v), .valid(ivalid));
    validcntr++;
    if (validcntr > validcntr_max) begin
      validcntr=0;
    end

  end  // forever
    
endtask : driver_write_address

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
  
  forever begin

    if (item == null) begin
       driver_writedata_mbx.get(item);
       item_needs_init=1;
    end
    
    if (item != null) begin  

      vif.wait_for_clks(.cnt(1));

      `uvm_info(this.get_type_name(), "INIT != NULL", UVM_INFO)
      
       // defaults. not needed but  I think is cleaner in sim
//       s.wvalid = 'b0;
//       s.wdata  = 'hfeed_beef;
//       s.wstrb  = 'h0;
//       s.wlast  = 1'b0;

       if (vif.get_wready()==1'b1 && vif.get_wvalid() == 1'b1) begin
          n =  dataoffset;
         if (aligned == 0)
            aligned = 1;

         `uvm_info("ATSTART", $sformatf("n:%0d, Burst_Length_Bytes:%0d", n, Burst_Length_Bytes), UVM_INFO)          
          if (n>=Burst_Length_Bytes) begin
             driver_writeresponse_mbx.put(item);
             item = null;  
             driver_writedata_mbx.try_get(item);
             n=0;
             dataoffset=0;
             if (item != null) begin
                `uvm_info("FOO", "next item avail!", UVM_INFO)
                item_needs_init=1;
             end else begin
                `uvm_info("FOO", "Nooooo next item avail!", UVM_INFO)
             end
          end
       end  // (vif.get_wready()==1'b1 && vif.get_wvalid() == 1'b1)
      
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

             //n = 0;
             item_needs_init=0;
//          end else begin
//             aligned=1;
/*
        // Increment address if necessary
         if (item.burst_type != axi_pkg::e_FIXED) begin
            if (aligned) begin
               addr = addr + Number_Bytes;
               if (item.burst_type == axi_pkg::e_WRAP) begin
                  // WRAP mode is always aligned
                  if (addr >= Upper_Wrap_Boundary) begin
                     addr = Lower_Wrap_Boundary;
                  end
               end
            end else begin
               addr    = addr + Number_Bytes;
               aligned = 1'b1;
           end
         end // (item.burst_type != axi_pkg::e_FIXED)        
*/
          end // (item_needs_init == 1)
       
       
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
          `uvm_info(this.get_type_name(), $sformatf("0000 - Lower_Byte_Lane: %0d; Uper_Byte_Lane: %0d; dataoffset:%0d, n:%0d, iNumber_Bytes:%0d; Aligned_Addr:0x%0x, addr:0x%0x; aligned:%b, item_needs_init:%0d", Lower_Byte_Lane, Upper_Byte_Lane, dataoffset, n, iNumber_Bytes, Aligned_Address, addr, aligned, item_needs_init), UVM_INFO)
      
          s.wvalid = item.valid[validcntr++]; // 1'b1;
          s.wstrb  = 'h0;
          s.wdata  = 'h0;
          s.wlast  = 1'b0;
        
          dataoffset=n;
          `uvm_info(this.get_type_name(), $sformatf("AAAA - Lower_Byte_Lane: %0d; Uper_Byte_Lane: %0d; dataoffset:%0d, n:%0d, iNumber_Bytes:%0d; Aligned_Addr:0x%0x, addr:0x%0x; aligned:%b, item_needs_init:%0d", Lower_Byte_Lane, Upper_Byte_Lane, dataoffset, n, iNumber_Bytes, Aligned_Address, addr, aligned, item_needs_init), UVM_INFO)
          for (int j=Lower_Byte_Lane;j<=Upper_Byte_Lane;j++) begin
             s.wdata[j*8+:8] = item.data[dataoffset++];
             s.wstrb[j]      = 1'b1;

             if (dataoffset>=Burst_Length_Bytes) begin
                s.wlast=1'b1;
                break;
             end
          end // for
         `uvm_info(this.get_type_name(), $sformatf("BBBB- Lower_Byte_Lane: %0d; Uper_Byte_Lane: %0d; dataoffset:%0d n:%0d", Lower_Byte_Lane, Upper_Byte_Lane, dataoffset, n), UVM_INFO)

          vif.write_w(.s(s),.waitforwready(0));

      //end // for (n...)
      
//      `uvm_info(this.get_type_name(), $sformatf("n:%0d, dataoffset=%0d, Burst_length_Bytes: %0d", n, dataoffset, Burst_Length_Bytes), UVM_INFO)
      end // (item != null) 
    end
      
      if (item == null) begin

         s.wvalid = 1'b0;
         s.wlast  = 1'b0;
         s.wdata  = 'h0;
 //      s.wid    = 'h0; AXI3 only
         s.wstrb  = 'h0;
        
         vif.wait_for_clks(.cnt(1));
         vif.write_w(.s(s),.waitforwready(0));
    //  end else begin
     //    item_needs_init=1;
      end
     
  end // forever
endtask : driver_write_data    
    
    
    
    
    
/*    
task axi_driver::driver_write_data;
  axi_seq_item item=null;
  int i=0;
  int validcntr=0;
  bit rv;
  int pktcnt=0;
  int new_beat_cnt;

  
  axi_seq_item_w_vector_s s;
  bit iwstrb [];
  bit [7:0] new_data []; 
  
  forever begin

    driver_writedata_mbx.get(item);
    item.update_wstrb(.addr  (item.addr), 
                      .wstrb (item.wstrb),
                      .data         (item.data),
                      .number_bytes (4),
                      .burst_length (item.len),
                      .new_wstrb    (iwstrb),
                      .new_data     (new_data),
                      .new_beat_cnt (new_beat_cnt));
           


    i=0;
    validcntr=0;

    while (item != null) begin  

       // defaults. not needed but  I think is cleaner
       s.wvalid = 'b0;
       s.wdata  = 'hfeed_beef;
       s.wstrb  = i;//'h0;
       s.wlast  = 1'b0;

     // if (i<item.len/4) begin
      if (i<new_beat_cnt) begin
        s.wvalid=item.valid[validcntr];
        for (int j=0;j<4;j++) begin
//        s.wdata={item.data[i*4+3],item.data[i*4+2],item.data[i*4+1],item.data[i*4+0]};
//        s.wstrb=iwstrb; // i;//item.wstrb[validcntr]; 
          s.wdata[j*8+:8] = new_data[i*4+j];
          s.wstrb[j]      = iwstrb[j+i];
        end
//        if (i==(item.len/4-1)) begin
        if (i==(new_beat_cnt-1)) begin
        s.wlast=1'b1;//item.wlast[i];
        end else begin
           s.wlast=1'b0;
        end
      end
      vif.write_w(.s(s),.waitforwready(1));

      validcntr++;
      
      //if (i==(item.len/4 -1)) begin
      if (i==(new_beat_cnt - 1)) begin
         if ((vif.get_wready() == 1'b1) && (s.wvalid==1'b1)) begin

            driver_writeresponse_mbx.put(item);
            item=null;  // explicitly set to null, don't rely on try_get below

            validcntr=0;
            i=0;
  
           driver_writedata_mbx.try_get(item);
         // if no next xfer, then not back to back so drive signals low again
           if (item==null) begin
              s.wvalid = 1'b0;
              s.wlast  = 1'b0;
              s.wdata  = 'h0;
              s.wstrb  = 'h0;
             vif.write_w(.s(s),.waitforwready(1));
           end
        end
      end else //if (i<item.len/4) begin
        if (i<new_beat_cnt) begin
        if ((vif.get_wready() == 1'b1) && (s.wvalid==1'b1)) begin
           i++;
        end
      end

    end    
end

endtask : driver_write_data
*/
    
    
    
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