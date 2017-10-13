////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_if_abstract.svh
//
// Purpose:
//          abstract base class for polymorphic interface class (axi_if_concrete) for AXI UVM environment
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
class axi_if_abstract extends uvm_object;
  `uvm_object_utils(axi_if_abstract)

  extern function new (string name="axi_if_abstract");

   // extern virtual task write(bit [63:0] addr, bit [7:0] data[], bit [7:0] id);
      extern virtual task read(
        output bit [63:0] addr,
        output bit [7:0]  data[],
        output int        len,
        output bit [7:0]  id);

    extern virtual task wait_for_awvalid;
    extern virtual task wait_for_awready_awvalid;

    extern virtual task set_awready(bit state);
    extern virtual task set_awvalid(bit state);
    extern virtual task set_wready(bit state);
    extern virtual task set_wvalid(bit state);
    extern virtual task set_bready(bit state);
    extern virtual task set_bvalid(bit state);

    extern virtual task set_rready(bit state);
    extern virtual task set_rvalid(bit state);


    extern virtual task wait_for_clks(int cnt=1);

    extern virtual function enable_awready_toggle_pattern(bit [31:0] pattern);
    extern virtual function disable_awready_toggle_pattern();
    extern virtual function enable_wready_toggle_pattern( bit [31:0] pattern);
    extern virtual function disable_wready_toggle_pattern();

    //extern virtual task set_wready_toggle_mask(bit [31:0] mask);
    //extern virtual task clr_wready_toggle_mask();
    extern virtual task set_bready_toggle_mask(bit [31:0] mask);
    extern virtual task clr_bready_toggle_mask();
    extern virtual task wait_for_not_in_reset;

    extern virtual task wait_for_wready();
    extern virtual task wait_for_bvalid();

    extern virtual task     write_aw(axi_seq_item_aw_vector_s s, bit valid=1'b1);
    extern virtual task     write_w (axi_seq_item_w_vector_s  s, bit waitforwready=0);
    extern virtual task write_b(axi_seq_item_b_vector_s s, bit valid=1'b1);

    extern virtual function void read_b  (output axi_seq_item_b_vector_s  s);

    extern virtual task read_aw(output axi_seq_item_aw_vector_s s);
    extern virtual task read_w(output axi_seq_item_w_vector_s  s);

    extern virtual function bit get_awready_awvalid;
    extern virtual function bit get_awready;


    extern virtual function bit get_wready_wvalid;
    extern virtual function bit get_wready;
    extern virtual function bit get_wvalid;

    extern virtual function bit get_bready_bvalid;
    extern virtual function bit get_bvalid;
    extern virtual function bit get_bready;


    extern virtual task wait_for_write_address  (output axi_seq_item_aw_vector_s s);
    extern virtual task wait_for_write_data     (output axi_seq_item_w_vector_s  s);
    extern virtual task wait_for_write_response (output axi_seq_item_b_vector_s  s);

    // Read Channels
    extern virtual function bit get_arready_arvalid;
    extern virtual function bit get_arready;


    extern virtual function bit get_rready_rvalid;
    extern virtual function bit get_rready;
    extern virtual function bit get_rvalid;

    extern virtual task set_arvalid(bit state);
      extern virtual task     write_ar(axi_seq_item_ar_vector_s s, bit valid=1'b1);
    //extern virtual task     write_w (axi_seq_item_w_vector_s  s, bit waitforwready=0);

    extern virtual function enable_arready_toggle_pattern(bit [31:0] pattern);
    extern virtual function disable_arready_toggle_pattern();

    extern virtual function enable_rready_toggle_pattern( bit [31:0] pattern);
    extern virtual function disable_rready_toggle_pattern();

    extern virtual task read_ar                (output axi_seq_item_ar_vector_s s);
    extern virtual task wait_for_read_address  (output axi_seq_item_ar_vector_s s);

      extern virtual task     write_r(axi_seq_item_r_vector_s  s, bit waitforrready=0);

endclass : axi_if_abstract

function axi_if_abstract::new (string name="axi_if_abstract");
  super.new(name);
endfunction : new

/*
task axi_if_abstract::write(bit [63:0] addr, bit [7:0] data[], bit [7:0] id);
  `uvm_error(this.get_type_name(), "WARNING. Virtual function write() not defined.")
endtask : write
*/

task axi_if_abstract::read(
  output bit [63:0] addr,
  output bit [7:0]  data[],
  output int        len,
  output bit [7:0]  id);

  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function read() not defined.")

endtask : read


task axi_if_abstract::wait_for_awvalid;
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_awvalid() not defined.")
endtask : wait_for_awvalid


task axi_if_abstract::wait_for_awready_awvalid;
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_awready_awvalid() not defined.")
endtask : wait_for_awready_awvalid

task axi_if_abstract::set_awready(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_awready() not defined.")
endtask : set_awready

task axi_if_abstract::set_awvalid(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_awvalid() not defined.")
endtask : set_awvalid

task axi_if_abstract::set_wready(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_wready() not defined.")
endtask : set_wready

task axi_if_abstract::set_wvalid(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_wvalid() not defined.")
endtask : set_wvalid

task axi_if_abstract::set_bready(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_bready() not defined.")
endtask : set_bready

task axi_if_abstract::set_bvalid(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_bvalid() not defined.")
endtask : set_bvalid


task axi_if_abstract::wait_for_clks(int cnt=1);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_clks() not defined.")
endtask : wait_for_clks

function axi_if_abstract::enable_awready_toggle_pattern(bit [31:0] pattern);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function enable_awready_toggle_pattern() not defined.")
endfunction : enable_awready_toggle_pattern

function axi_if_abstract::disable_awready_toggle_pattern();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task disable_awready_toggle_pattern() not defined.")
endfunction : disable_awready_toggle_pattern

function axi_if_abstract::enable_wready_toggle_pattern(bit [31:0] pattern);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function enable_wready_toggle_pattern() not defined.")
endfunction : enable_wready_toggle_pattern

function axi_if_abstract::disable_wready_toggle_pattern();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task disable_wready_toggle_pattern() not defined.")
endfunction : disable_wready_toggle_pattern


task axi_if_abstract::set_bready_toggle_mask(bit [31:0] mask);
    `uvm_error(this.get_type_name(),
               "WARNING. Virtual task set_bready_toggle_mask() not defined.")
endtask : set_bready_toggle_mask

task axi_if_abstract::clr_bready_toggle_mask();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task clr_bready_toggle_mask() not defined.")
endtask : clr_bready_toggle_mask

task axi_if_abstract::wait_for_not_in_reset;
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_not_in_reset() not defined.")
endtask : wait_for_not_in_reset;

task axi_if_abstract::write_aw(axi_seq_item_aw_vector_s s, bit valid=1'b1);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task write_aw() not defined.")
endtask : write_aw

task axi_if_abstract::write_w(axi_seq_item_w_vector_s  s, bit waitforwready=0);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task write_w() not defined.")
endtask : write_w

task axi_if_abstract::write_b(axi_seq_item_b_vector_s s, bit valid=1'b1);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task write_b() not defined.")
endtask : write_b

task axi_if_abstract::read_aw(output axi_seq_item_aw_vector_s s);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task read_aw() not defined.")
endtask : read_aw

task axi_if_abstract::read_w(output axi_seq_item_w_vector_s  s);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task read_w() not defined.")
endtask : read_w

function bit axi_if_abstract::get_awready_awvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_awready_awvalid() not defined.")
endfunction : get_awready_awvalid

function bit axi_if_abstract::get_awready();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_awready() not defined.")
endfunction : get_awready


task axi_if_abstract::wait_for_wready();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_wready() not defined.")
endtask : wait_for_wready



function bit axi_if_abstract::get_wready_wvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_wready_wvalid() not defined.")
endfunction : get_wready_wvalid

function bit axi_if_abstract::get_wready();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_wready() not defined.")
endfunction : get_wready

function bit axi_if_abstract::get_wvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_wvalid() not defined.")
endfunction : get_wvalid

function bit axi_if_abstract::get_bready_bvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_bready_bvalid() not defined.")
endfunction : get_bready_bvalid


function bit axi_if_abstract::get_bready();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_bready() not defined.")
endfunction : get_bready

function bit axi_if_abstract::get_bvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_bvalid() not defined.")
endfunction : get_bvalid

task axi_if_abstract::wait_for_bvalid();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_bvalid() not defined.")
endtask : wait_for_bvalid

function void axi_if_abstract::read_b(output axi_seq_item_b_vector_s  s);
    `uvm_error(this.get_type_name(),
             "WARNING. Virtual task read_b() not defined.")
endfunction : read_b

task axi_if_abstract::wait_for_write_address(output axi_seq_item_aw_vector_s s);
    `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_write_address() not defined.")

endtask : wait_for_write_address

task axi_if_abstract::wait_for_write_data(output axi_seq_item_w_vector_s s);
    `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_write_data() not defined.")

endtask : wait_for_write_data

task axi_if_abstract::wait_for_write_response(output axi_seq_item_b_vector_s s);
    `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_write_response() not defined.")

endtask : wait_for_write_response



// Read Channels
function bit axi_if_abstract::get_arready_arvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_arready_arvalid() not defined.")
endfunction : get_arready_arvalid

function bit axi_if_abstract::get_arready();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_arready() not defined.")
endfunction : get_arready

//task axi_if_abstract::wait_for_rready();
//  `uvm_error(this.get_type_name(),
//             "WARNING. Virtual task wait_for_rready() not defined.")
//endtask : wait_for_rready

function bit axi_if_abstract::get_rready_rvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_rready_rvalid() not defined.")
endfunction : get_rready_rvalid

function bit axi_if_abstract::get_rready();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_rready() not defined.")
endfunction : get_rready

function bit axi_if_abstract::get_rvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_rvalid() not defined.")
endfunction : get_rvalid

task axi_if_abstract::set_arvalid(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_arvalid() not defined.")
endtask : set_arvalid

task axi_if_abstract::set_rready(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_rready() not defined.")
endtask : set_rready

task axi_if_abstract::set_rvalid(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_rvalid() not defined.")
endtask : set_rvalid

task axi_if_abstract::write_ar(axi_seq_item_ar_vector_s s, bit valid=1'b1);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task write_ar() not defined.")
endtask : write_ar

task axi_if_abstract::read_ar(output axi_seq_item_ar_vector_s s);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task read_ar() not defined.")
endtask : read_ar

task axi_if_abstract::wait_for_read_address(output axi_seq_item_ar_vector_s s);
    `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_read_address() not defined.")

endtask : wait_for_read_address

        task axi_if_abstract::write_r(axi_seq_item_r_vector_s  s, bit waitforrready=0);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task write_r() not defined.")
endtask : write_r



function axi_if_abstract::enable_arready_toggle_pattern(bit [31:0] pattern);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function enable_arready_toggle_pattern() not defined.")
endfunction : enable_arready_toggle_pattern

function axi_if_abstract::disable_arready_toggle_pattern();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task disable_arready_toggle_pattern() not defined.")
endfunction : disable_arready_toggle_pattern

function axi_if_abstract::enable_rready_toggle_pattern(bit [31:0] pattern);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function enable_rready_toggle_pattern() not defined.")
endfunction : enable_rready_toggle_pattern

function axi_if_abstract::disable_rready_toggle_pattern();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task disable_rready_toggle_pattern() not defined.")
endfunction : disable_rready_toggle_pattern