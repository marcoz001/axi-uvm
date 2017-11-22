
PARAMSFILE = ../tb/params_pkg.sv
RTLFILES = ../rtl/axi_pkg.sv ../rtl/axi_if.sv
TBFILES  = ../rtl/axi_uvm_pkg.sv ../tb/tb.sv

UVM_TESTNAME ?= axi_base_test
transactions ?= 1


comp:
	vlog -O0 -novopt -sv +incdir+`pwd`/../tb +incdir+$(UVM_HOME)/src $(PARAMSFILE) $(RTLFILES) $(TBFILES) /opt/mentor/questasim_10.6/questasim/verilog_src/questa_uvm_pkg-1.2/src/questa_uvm_pkg.sv $(UVM_HOME)/src/uvm_pkg.sv

#	vlog -sv +incdir+$(UVM_HOME)/src /opt/mentor/questasim_10.6/questasim/verilog_src/questa_uvm_pkg-1.2/src/questa_uvm_pkg.sv


uvm.lib:
	vlog -work uvm.lib -sv +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv

uvm_dpi:
	rm -f uvm_dpi
	mkdir uvm_dpi
	g++ -m64 -fPIC -DQUESTA -g -W -shared -I/opt/mentor/questasim_10.6/questasim/include $(UVM_HOME)/src/dpi/uvm_dpi.cc -o uvm_dpi/uvm_dpi.so

	
sim:
	vsim -c -sv_lib uvm_dpi/uvm_dpi -L uvm.lib -assertcover -coverage +UVM_TESTNAME=$(UVM_TESTNAME) +transactions=$(transactions) tb -do 'coverage save -onexit coverage.ucdb; run -all'
	vcover report coverage.ucdb

sim_gui:
	vsim -novopt -sv_lib uvm_dpi/uvm_dpi -L uvm.lib +UVM_TESTNAME=$(UVM_TESTNAME) tb

coverage:
	vcover report -html -details coverage.ucdb


clean:
	rm -fr work covhtmlreport coverage.ucdb
