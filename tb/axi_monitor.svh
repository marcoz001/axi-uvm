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
class axi_monitor extends uvm_monitor;
  `uvm_component_utils(axi_monitor)

  uvm_analysis_port #(axi_seq_item) ap;

  uvm_analysis_port #(axi_seq_item) driver_activity_ap; // detect driver activity

  uvm_analysis_port #(axi_seq_item) write_address_ap;
  uvm_analysis_port #(axi_seq_item) write_data_ap;
  uvm_analysis_port #(axi_seq_item) write_response_ap;
  uvm_analysis_port #(axi_seq_item) read_address_ap;
  uvm_analysis_port #(axi_seq_item) read_data_ap;

  // will move this out of monitor but for now it's quick and easy experimentation
  axi_seq_item_w_vector_s  w_q[$];
  //axi_seq_item_aw_vector_s aw_q[$];
  //axi_seq_item_b_vector_s  b_q[$];
  axi_seq_item   aw_q[$];


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

endclass : axi_monitor


function axi_monitor::new (string name="axi_monitor", uvm_component parent=null);
  super.new(name, parent);
endfunction : new

function void axi_monitor::build_phase (uvm_phase phase);
  super.build_phase(phase);

  ap=new("ap", this);
  if (m_config.drv_type == e_RESPONDER) begin
     driver_activity_ap=new("driver_activity_ap", this);
  end

  write_address_ap  = new("write_address_ap",  this);
  write_data_ap     = new("write_data_ap",     this);
  write_response_ap = new("write_response_ap", this);
  read_address_ap   = new("read_address_ap",   this);
  read_data_ap      = new("read_data_ap",      this);


  vif=axi_if_abstract::type_id::create("vif", this);

endfunction : build_phase

function void axi_monitor::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

//    Good article here:
//https://verificationacademy.com/verification-horizons/june-2013-volume-9-issue-2/Monitors-Monitors-Everywhere-Who-Is-Monitoring-the-Monitors

/*
Each channel has an analysis port.  If data arrives 1st, it doesn't matter. scoreboard can wait on address before reading data.
have 5 forever loops just waiting for *valid/ready and appropriate signals.
// 5 diff seq items? or 1 with 5 different modes/types (cmd_t)?

what about memory?
1) use write/read API?
2) make it a subscriber to all those analysis ports?



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
//    aw_q.push_back(aw_s);

    //`uvm_info(this.get_type_name(), "got addr", UVM_INFO)

//     if (m_config.drv_type == axi_uvm_pkg::e_RESPONDER) begin
//         m_memory.write(aw_s.awaddr, 'hef);
//     end

    $cast(item, original_item.clone());

    axi_seq_item::aw_to_class(.t(item), .v(aw_s));
    item.cmd         = axi_uvm_pkg::e_WRITE;
   // item.initialize();
    $cast(item2, item.clone());

    aw_q.push_back(item2);

    ap.write(item);

    if (m_config.drv_type == e_RESPONDER) begin
       driver_activity_ap.write(item);
    end

  end
endtask : monitor_write_address

    /*
    write to address in aw_q[0] + offset
    offset is inc'd each write.  once offset=awlen, then pop addr and reset offset
    if addr comes in while some data already in fifo?
    */
task axi_monitor::monitor_write_data();
  axi_seq_item_w_vector_s  w_s;
  int offset=0;
  int maxoffset=0;
  bit [31:0] data;
  bit [63:0] addr;

  if (m_config.drv_type != axi_uvm_pkg::e_RESPONDER) begin
    return;
  end

  forever begin
                `uvm_info(this.get_type_name(),
                          "========> wait_for_write_data()",
                  UVM_HIGH)

    vif.wait_for_write_data(.s(w_s));

                `uvm_info(this.get_type_name(),
                          "========> wait_for_write_data() - DONE",
                  UVM_HIGH)

      // if no address received, then store data until address arrives.
      // AXI spec says data can arrive before data, but order must match
      w_q.push_back(w_s);

      if (aw_q.size() != 0) begin

        // if the address is available, then take everything out of the
        // data queue and put it in the item.
        // awsize is needed in case this is a partial burst (awsize != databussize)
        //
//        addr=aw_q[0].addr;
        if (aw_q[0].initialized != 1'b1) begin
          for (int j=0;j<4;j++)  begin
            if (w_s.wstrb[j] == 1'b1) begin
              aw_q[0].addr += j;
              aw_q[0].Start_Address=aw_q[0].addr;
              aw_q[0].initialize();
              offset=0;
              break;
            end

          end
          //offset=0;

        end
        maxoffset=aw_q[0].len;


         // if anything in data queue, write it out

         while (w_q.size() > 0) begin


           w_s=w_q.pop_front();
            `uvm_info(this.get_type_name(),
                      $sformatf("Lower_Byte_Lane=%0d, Upper_Byte_Lane=%0d, offset=%0d", aw_q[0].Lower_Byte_Lane, aw_q[0].Upper_Byte_Lane, offset),
                  UVM_HIGH)
           for (int i=aw_q[0].Lower_Byte_Lane;i<=aw_q[0].Upper_Byte_Lane;i++) begin
               // wstrb may not be asserted. check
               if (w_s.wstrb[i]==1'b1) begin
                 m_memory.write(aw_q[0].Start_Address+offset, w_s.wdata[i*8+:8]);
               end
               offset++;

            end
            aw_q[0].update_address();
           if (w_s.wlast == 1'b1) begin // @Todo: count, dont rely on wlast
             aw_q.pop_front();
           end

         end

      end
  //  `uvm_info(this.get_type_name(), "got data", UVM_INFO)

  end  // forever
endtask : monitor_write_data

task axi_monitor::monitor_write_response();
  axi_seq_item_b_vector_s  b_s;

  if (m_config.drv_type != axi_uvm_pkg::e_RESPONDER) begin
    return;
  end


  forever begin
    vif.wait_for_write_response(.s(b_s));
 //   b_q.push_front(b_s);
    `uvm_info(this.get_type_name(), "got response", UVM_INFO)

  end
endtask : monitor_write_response



task axi_monitor::run_phase(uvm_phase phase);
  fork
    monitor_write_address();
    monitor_write_data();
    monitor_write_response();

  join
endtask : run_phase
