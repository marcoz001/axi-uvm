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
//! abstract base class for polymorphic interface class (axi_if_concrete) for AXI UVM environment
/*! This class is extended by a class called axi_if_concrete that is nested inside axi_if.
 *  The class methods have access to the interface's internals so can drive signals, read signals, etc.
 *  The class also registers with the uvm_config_db and does a set_type_override so we get the
 * concrete class instead of the abstract class.  This lets us use a class and not have to parameterize
 * an interface and all the UVC stuff that talks to it.
 * All the functions and tasks are for the testbench to talk to the DUT as efficiently as possible but in an understandable way.
  @see axi_if.sv
*/
class axi_if_abstract extends uvm_object;
  `uvm_object_utils(axi_if_abstract)

    extern function new (string name="axi_if_abstract");

    extern virtual function int get_data_bus_width;

    extern virtual task wait_for_clks(int cnt=1);
    extern virtual task wait_for_not_in_reset;

    extern virtual task wait_for_awready_awvalid;
    extern virtual task wait_for_awvalid;
    extern virtual task wait_for_wready();
    extern virtual task wait_for_bvalid();

    extern virtual task wait_for_write_address  (output axi_seq_item_aw_vector_s s);
    extern virtual task wait_for_write_data     (output axi_seq_item_w_vector_s  s);
    extern virtual task wait_for_write_response (output axi_seq_item_b_vector_s  s);
    extern virtual task wait_for_read_address   (output axi_seq_item_ar_vector_s s);
    extern virtual task wait_for_read_data      (output axi_seq_item_r_vector_s  s);

    extern virtual function bit get_awready_awvalid;
    extern virtual function bit get_awready;
    extern virtual function bit get_wready_wvalid;
    extern virtual function bit get_wvalid;
    extern virtual function bit get_wready;
    extern virtual function bit get_bready_bvalid;
    extern virtual function bit get_bvalid;
    extern virtual function bit get_bready;
    extern virtual function bit get_arready_arvalid;
    extern virtual function bit get_arready;
    extern virtual function bit get_rready_rvalid;
    extern virtual function bit get_rvalid;
    extern virtual function bit get_rready;

    extern virtual task set_awvalid(bit state);
    extern virtual task set_awready(bit state);
    extern virtual task set_wvalid(bit state);
    extern virtual task set_wready(bit state);
    extern virtual task set_bvalid(bit state);
    extern virtual task set_bready(bit state);
    extern virtual task set_arvalid(bit state);
    extern virtual task set_rvalid(bit state);
    extern virtual task set_rready(bit state);


    extern virtual function void enable_awready_toggle_pattern(bit [31:0] pattern);
    extern virtual function void disable_awready_toggle_pattern();
    extern virtual function void enable_wready_toggle_pattern( bit [31:0] pattern);
    extern virtual function void disable_wready_toggle_pattern();
    extern virtual function void enable_bready_toggle_pattern( bit [31:0] pattern);
    extern virtual function void disable_bready_toggle_pattern();
    extern virtual function void enable_arready_toggle_pattern(bit [31:0] pattern);
    extern virtual function void disable_arready_toggle_pattern();
    extern virtual function void enable_rready_toggle_pattern( bit [31:0] pattern);
    extern virtual function void disable_rready_toggle_pattern();

    extern virtual function void write_aw(axi_seq_item_aw_vector_s s, bit valid=1'b1);
    extern virtual function void write_w (axi_seq_item_w_vector_s  s);
    extern virtual function void write_b (axi_seq_item_b_vector_s s,  bit valid=1'b1);
    extern virtual function void read_aw (output axi_seq_item_aw_vector_s s);
    extern virtual function void read_w  (output axi_seq_item_w_vector_s  s);
    extern virtual function void read_b  (output axi_seq_item_b_vector_s  s);


    extern virtual function void write_ar(axi_seq_item_ar_vector_s s, bit valid=1'b1);
    extern virtual function void write_r (axi_seq_item_r_vector_s  s);
    extern virtual function void read_ar (output axi_seq_item_ar_vector_s s);
    extern virtual function void read_r  (output axi_seq_item_r_vector_s  s);


endclass : axi_if_abstract

function axi_if_abstract::new (string name="axi_if_abstract");
  super.new(name);
endfunction : new

//! returns data bus width
/*! This function allows the driver to retrieve the data bus width from the interface.
 */
function int axi_if_abstract::get_data_bus_width;
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function get_data_bus_width() not defined.")
  return -1;
endfunction : get_data_bus_width

//! used for waiting
/*! The testbench side is entirely event driven (or is meant to be).
 * This function is called to wait for time
 */
task axi_if_abstract::wait_for_clks(int cnt=1);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_clks() not defined.")
endtask : wait_for_clks

//! Wait for reset to deassert
task axi_if_abstract::wait_for_not_in_reset;
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_not_in_reset() not defined.")
endtask : wait_for_not_in_reset;

//! Wait for both awready awvalid to assert.
/*! Used to know when the write address has been received and acknowledged by slave
*/
task axi_if_abstract::wait_for_awready_awvalid;
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_awready_awvalid() not defined.")
endtask : wait_for_awready_awvalid

//! Wait for awvalid to assert.
/*! Used to wait for when a valid write address is on the channel.
*/
task axi_if_abstract::wait_for_awvalid;
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_awvalid() not defined.")
endtask : wait_for_awvalid

//! Wait for awready to assert.
/*! Used to wait for when the slave is ready for write data
*/
task axi_if_abstract::wait_for_wready();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_wready() not defined.")
endtask : wait_for_wready

//! Wait for bvalid to assert.
/*! Used to wait for when a valid write response is on the channel.
*/
task axi_if_abstract::wait_for_bvalid();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_bvalid() not defined.")
endtask : wait_for_bvalid

//! Wait for a valid write address to be acknowledged and return it.
/*! Used to wait for, and return, a valid write address.
   @return  values on the write address channel.
*/
task axi_if_abstract::wait_for_write_address(output axi_seq_item_aw_vector_s s);
    `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_write_address() not defined.")
endtask : wait_for_write_address

//! Wait for a valid write data to be acknowledged and return it.
/*! Used to wait for, and return, a valid write data beat.
   @return  values on the write data channel.
*/
task axi_if_abstract::wait_for_write_data(output axi_seq_item_w_vector_s s);
    `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_write_data() not defined.")
endtask : wait_for_write_data

//! Wait for a valid write response to be acknowledged and return it.
/*! Used to wait for, and return, a valid write response.
   @return  values on the write response channel.
*/
task axi_if_abstract::wait_for_write_response(output axi_seq_item_b_vector_s s);
    `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_write_response() not defined.")
endtask : wait_for_write_response

//! Wait for a valid read address to be acknowledged and return it.
/*! Used to wait for, and return, a valid read address.
   @return  values on the read address channel.
*/
task axi_if_abstract::wait_for_read_address(output axi_seq_item_ar_vector_s s);
    `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_read_address() not defined.")
endtask : wait_for_read_address

//! Wait for a valid read data to be acknowledged and return it.
/*! Used to wait for, and return, a valid read data.
   @return  values on the read data channel.
*/
task axi_if_abstract::wait_for_read_data(output axi_seq_item_r_vector_s s);
    `uvm_error(this.get_type_name(),
             "WARNING. Virtual task wait_for_read_address() not defined.")
endtask : wait_for_read_data

//! Get the value of awready and awvalid.
/*!  (Is the write address channel currently being acknowledged by the slave?)
 *  One function instead of two seperate to save a call from testbench land to RTL land
 *  (this only really matters in emulator and even then not that much.)
 *  @return true if both awvalid and awready are asserted else false
*/
function bit axi_if_abstract::get_awready_awvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_awready_awvalid() not defined.")
  return 0;
endfunction : get_awready_awvalid


//! Get the value of awready
/*! (Is the slave currently ready for a write address?)
 *  @return value of awready
*/
function bit axi_if_abstract::get_awready();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_awready() not defined.")
  return 0;
endfunction : get_awready

//! Get the value of wready and wvalid.
/*! (Is the write data channel currently being acknowledged by the slave?)
 *  One function instead of two seperate to save a call from testbench land to RTL land
 *  (this only really matters in emulator and even then not that much.)
 *  @return true if both wvalid and wready are asserted else false
*/
function bit axi_if_abstract::get_wready_wvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_wready_wvalid() not defined.")
  return 0;
endfunction : get_wready_wvalid

//! Get the value of wvalid
/*! (Is the write data currently valid?)
 *  @return value of awready
*/
function bit axi_if_abstract::get_wvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_wvalid() not defined.")
  return 0;
endfunction : get_wvalid

//! Get the value of wready
/*! (Is the slave currently ready for a write data?)
 *  @return value of wready
*/
function bit axi_if_abstract::get_wready();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_wready() not defined.")
  return 0;
endfunction : get_wready

//! Get the value of bready and bvalid.
/*! (Is the write response channel currently being acknowledged by the slave?)
 *  One function instead of two seperate to save a call from testbench land to RTL land
 *  (this only really matters in emulator and even then not that much.)
 *  @return true if both bvalid and bready are asserted else false
*/
function bit axi_if_abstract::get_bready_bvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_bready_bvalid() not defined.")
  return 0;
endfunction : get_bready_bvalid

//! Get the value of bvalid
/*! (Is the write response currently valid?)
 *  @return value of bvalid
*/
function bit axi_if_abstract::get_bvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_bvalid() not defined.")
  return 0;
endfunction : get_bvalid

//! Get the value of bready
/*! (Is the master currently ready for a write response?)
 *  @return value of bready
*/
function bit axi_if_abstract::get_bready();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_bready() not defined.")
  return 0;
endfunction : get_bready

//! Get the value of arready and arvalid.
/*! (Is the read address channel currently being acknowledged by the slave?)
 *  One function instead of two seperate to save a call from testbench land to RTL land
 *  (this only really matters in emulator and even then not that much.)
 *  @return true if both arvalid and arready are asserted else false
*/
function bit axi_if_abstract::get_arready_arvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_arready_arvalid() not defined.")
  return 0;
endfunction : get_arready_arvalid

//! Get the value of arready
/*! (Is the slave currently ready for a read address?)
 *  @return value of arready
*/
function bit axi_if_abstract::get_arready();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_arready() not defined.")
  return 0;
endfunction : get_arready

//! Get the value of rready and rvalid.
/*! (Is the read data channel currently being acknowledged by the slave?)
 *  One function instead of two seperate to save a call from testbench land to RTL land
 *  (this only really matters in emulator and even then not that much.)
 *  @return true if both rvalid and rready are asserted else false
*/
function bit axi_if_abstract::get_rready_rvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_rready_rvalid() not defined.")
  return 0;
endfunction : get_rready_rvalid

//! Get the value of rvalid
/*! (Is the read data currently valid?)
 *  @return value of awready
*/
function bit axi_if_abstract::get_rvalid();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_rvalid() not defined.")
  return 0;
endfunction : get_rvalid

//! Get the value of rready
/*! (Is the master currently ready for a read data?)
 *  @return value of rready
*/
function bit axi_if_abstract::get_rready();
   `uvm_error(this.get_type_name(),
              "WARNING. Virtual function get_rready() not defined.")
  return 0;
endfunction : get_rready

//! Set the value of awvalid
/*! (true=write address is valid; false=write address is not valid)
 *  @param state - value to drive awvalid
*/
task axi_if_abstract::set_awvalid(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_awvalid() not defined.")
endtask : set_awvalid

//! Set the value of awready
/*! (true=slave is ready for write address; false=slave is not ready.)
 *  @param state - value to drive awready
*/
task axi_if_abstract::set_awready(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_awready() not defined.")
endtask : set_awready

//! Set the value of wvalid
/*! (true=write data is valid; false=write data is not valid)
 *  @param state - value to drive wvalid
*/
task axi_if_abstract::set_wvalid(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_wvalid() not defined.")
endtask : set_wvalid

//! Set the value of wready
/*! (true=slave is ready for write data; false=slave is not ready.)
 *  @param state - value to drive wready
*/
task axi_if_abstract::set_wready(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_wready() not defined.")
endtask : set_wready

//! Set the value of bvalid
/*! (true=write response is valid; false=write response is not valid)
 *  @param state - value to drive bvalid
*/
task axi_if_abstract::set_bvalid(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_bvalid() not defined.")
endtask : set_bvalid

//! Set the value of bready
/*! (true=master is ready for write response; false=master is not ready.)
 *  @param state - value to drive bready
*/
task axi_if_abstract::set_bready(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_bready() not defined.")
endtask : set_bready

//! Set the value of arvalid
/*! (true=read address is valid; false=read address is not valid)
 *  @param state - value to drive arvalid
*/
task axi_if_abstract::set_arvalid(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_arvalid() not defined.")
endtask : set_arvalid

//! Set the value of rvalid
/*! (true=read data is valid; false=read data is not valid)
 *  @param state - value to drive rvalid
*/
task axi_if_abstract::set_rvalid(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_rvalid() not defined.")
endtask : set_rvalid

//! Set the value of rready
/*! (true=master is ready for read data; false=master is not ready.)
 *  @param state - value to drive rready
*/
task axi_if_abstract::set_rready(bit state);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task set_rready() not defined.")
endtask : set_rready

//! Set the value of awready toggle pattern and enable toggling
/*! awready can be toggled pseudo randonly with a repeating 32-bit pattern
 *  @param pattern - barrel register value to use to toggle awready
*/
function void axi_if_abstract::enable_awready_toggle_pattern(bit [31:0] pattern);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function enable_awready_toggle_pattern() not defined.")
endfunction : enable_awready_toggle_pattern

//! Disable awready toggling.
/*! @todo: what happens when disabled..
 *
*/
function void axi_if_abstract::disable_awready_toggle_pattern();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task disable_awready_toggle_pattern() not defined.")
endfunction : disable_awready_toggle_pattern

//! Set the value of wready toggle pattern and enable toggling
/*! wready can be toggled pseudo randonly with a repeating 32-bit pattern
 *  @param pattern - barrel register value to use to toggle wready
*/
function void axi_if_abstract::enable_wready_toggle_pattern(bit [31:0] pattern);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function enable_wready_toggle_pattern() not defined.")
endfunction : enable_wready_toggle_pattern

//! Disable wready toggling.
/*! @todo: what happens when disabled..
 *
*/
function void axi_if_abstract::disable_wready_toggle_pattern();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task disable_wready_toggle_pattern() not defined.")
endfunction : disable_wready_toggle_pattern

//! Set the value of bready toggle pattern and enable toggling
/*! bready can be toggled pseudo randonly with a repeating 32-bit pattern
 *  @param pattern - barrel register value to use to toggle bready
*/
function void axi_if_abstract::enable_bready_toggle_pattern(bit [31:0] pattern);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function enable_bready_toggle_pattern() not defined.")
endfunction : enable_bready_toggle_pattern

//! Disable bready toggling.
/*! @todo: what happens when disabled..
 *
*/
function void axi_if_abstract::disable_bready_toggle_pattern();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task disable_bready_toggle_pattern() not defined.")
endfunction : disable_bready_toggle_pattern

//! Set the value of arready toggle pattern and enable toggling
/*! arready can be toggled pseudo randonly with a repeating 32-bit pattern
 *  @param pattern - barrel register value to use to toggle arready
*/
function void axi_if_abstract::enable_arready_toggle_pattern(bit [31:0] pattern);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function enable_arready_toggle_pattern() not defined.")
endfunction : enable_arready_toggle_pattern

//! Disable arready toggling.
/*! @todo: what happens when disabled..
 *
*/
function void axi_if_abstract::disable_arready_toggle_pattern();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task disable_arready_toggle_pattern() not defined.")
endfunction : disable_arready_toggle_pattern

//! Set the value of rready toggle pattern and enable toggling
/*! rready can be toggled pseudo randonly with a repeating 32-bit pattern
 *  @param pattern - barrel register value to use to toggle rready
*/
function void axi_if_abstract::enable_rready_toggle_pattern(bit [31:0] pattern);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function enable_rready_toggle_pattern() not defined.")
endfunction : enable_rready_toggle_pattern

//! Disable rready toggling.
/*! @todo: what happens when disabled..
 *
*/
function void axi_if_abstract::disable_rready_toggle_pattern();
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual task disable_rready_toggle_pattern() not defined.")
endfunction : disable_rready_toggle_pattern

//! Drive all the signals on the write address channel with the specified values.
/*! s is a packed struct to ease usage in an emulator environment(like Veloce)
 *  @param s - packed struct containing all write address channel signal values (except awvalid)
 *  @param valid - value to drive on awvalid
*/
function void axi_if_abstract::write_aw(axi_seq_item_aw_vector_s s, bit valid=1'b1);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function write_aw() not defined.")
endfunction : write_aw

//! Drive all the signals on the write data channel with the specified values.
/*! s is a packed struct to ease usage in an emulator environment(like Veloce)
 *  @param s - packed struct containing all write data channel signal values
 * @todo: is this parameter still used anywhere?
*/
function void axi_if_abstract::write_w(axi_seq_item_w_vector_s  s);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function write_w() not defined.")
endfunction : write_w

//! Drive all the signals on the write response channel with the specified values.
/*! s is a packed struct to ease usage in an emulator environment(like Veloce)
 *  @param s - packed struct containing all write response channel signal values (except bvalid)
 *  @param valid - value to drive on bvalid
*/
function void axi_if_abstract::write_b(axi_seq_item_b_vector_s s, bit valid=1'b1);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function write_b() not defined.")
endfunction : write_b

//! Get the values on the write address channel
/*! s is a packed struct to ease usage in an emulator environment (like Veloce).
 *  @return packed struct of write address channel signal values.
*/
function void axi_if_abstract::read_aw(output axi_seq_item_aw_vector_s s);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function read_aw() not defined.")
endfunction : read_aw

//! Get the values on the write data channel
/*! s is a packed struct to ease usage in an emulator environment (like Veloce).
 *  @return packed struct of write data channel signal values.
*/
function void axi_if_abstract::read_w(output axi_seq_item_w_vector_s  s);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function read_w() not defined.")
endfunction : read_w

//! Get the values on the write response channel
/*! s is a packed struct to ease usage in an emulator environment (like Veloce).
 *  @return packed struct of write response channel signal values.
*/
function void axi_if_abstract::read_b(output axi_seq_item_b_vector_s  s);
    `uvm_error(this.get_type_name(),
             "WARNING. Virtual function read_b() not defined.")
endfunction : read_b

//! Drive all the signals on the read address channel with the specified values.
/*! s is a packed struct to ease usage in an emulator environment(like Veloce)
 *  @param s - packed struct containing all read address channel signal values (except arvalid)
 *  @param valid - value to drive on arvalid
*/
function void axi_if_abstract::write_ar(axi_seq_item_ar_vector_s s, bit valid=1'b1);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function write_ar() not defined.")
endfunction : write_ar

//! Get the values on the read address channel
/*! s is a packed struct to ease usage in an emulator environment (like Veloce).
 *  @return packed struct of read address channel signal values.
*/
function void axi_if_abstract::read_ar(output axi_seq_item_ar_vector_s s);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function read_ar() not defined.")
endfunction : read_ar

//! Drive all the signals on the read data channel with the specified values.
/*! s is a packed struct to ease usage in an emulator environment(like Veloce)
 *  @param s - packed struct containing all read data channel signal values
*/
function void axi_if_abstract::write_r(axi_seq_item_r_vector_s  s);
  `uvm_error(this.get_type_name(),
             "WARNING. Virtual function write_r() not defined.")
endfunction : write_r

//! Get the values on the read data channel
/*! s is a packed struct to ease usage in an emulator environment (like Veloce).
 *  @return packed struct of read data channel signal values.
*/
function void axi_if_abstract::read_r(output axi_seq_item_r_vector_s  s);
    `uvm_error(this.get_type_name(),
             "WARNING. Virtual function read_r() not defined.")
endfunction : read_r


      /*
      3. what does disabling toggle patterns do?
      */
