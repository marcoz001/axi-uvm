/*! \mainpage AXI Muckbucket
 * \section intro_sec Introduction
 * This is an AXI testbench. It uses UVM so unfortunately iverilog isn't sufficient. (I hope this changes soon.)
 * - Dual-top testbench
 * - Slave responder, no BFM (currently)
 * - Supports AXI3 and AXI4
 * - Supports all AXI data widths (8,16,32,64,128,256,512 and 1024)
 * - Supports 32-bit and 64-bit address widths
 * - Supports full and partial transfers.
 * - Supports aligned and unaligned transfers.
 * - Supports Fixed, Incrementing and Wrapped transfers.
 * - Supports toggling *ready and *valid. Including AXI-incompatibly mode which randomly asserts and deasserts valid before ready asserts.
 * - Fixed burst_type must be aligned. Unaligned Fixed transfers are not supported.
 * - Testbench side is event driven.  No #'delays, no @clock, etc
 * - Emulator friendly (TB side is event driven. no @clock or # delays)
 * - Pipelined AXI driver
 * - back to back transfers with 0 in-between wait clocks.
 * - Polymorphic interface
 * - params_pkg.sv contains all dut parameters
 * - A master driver - acts as an AXI master
 * - A slave driver  - acts as an AXI slave
 * - Coverage collector
 * - Scoreboard (counts address packets and response packets)
 *
 * Good whitepaper on slave sequences:
 * http://www.verilab.com/files/reactive_slaves_presentation.pdf
 * http://www.verilab.com/files/litterick_uvm_slaves2_paper.pdf
 *
 * Parallel/pipelined driver:
 * https://www.quora.com/What-is-the-best-way-to-model-an-out-of-order-transaction-driver-in-UVM
 *
 * Monitors
 * https://verificationacademy.com/verification-horizons/june-2013-volume-9-issue-2/Monitors-Monitors-Everywhere-Who-Is-Monitoring-the-Monitors
 *
 * verification plan (put in seperate doc):
 * - For each supported data width:
 * -    check all 3 burst_types(e_FIXED, e_INCR, e_WRAP)
 * -    all possible burst_sizes (including invalid, make sure they fail)
 * -    all possible lens (only have a couple coverbins though,or any cross will be too large.)
 * -       min (1),  max, everything in-between ?
 * -    stable *ready
 * -    toggling *ready
 * -    stable *valid
 * -    toggling *valid
 * -    AXI-incompabible *valid toggling (valid deasserts before ready asserts)
 * - back-to-back bursts (aw,w,b,ar,r)
 * - one clock delay between bursts (aw,w,b,ar,r)
 * - serial mode (aw, then w, then b, repeat)   (ar, then r, repeat)
 * - pipelined (multiple aw, then multiple w, then multiple b, repeat)   (multiple ar,then multiple r,repeat)
 *
*/