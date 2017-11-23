
PARAMS_STRING ?= id-5_addr-32_data-8_len-8
PARAMSFILE    = $(PARAMS_PKGS_DIR)/params_pkg_$(PARAMS_STRING).sv
RTLFILES      = ../rtl/axi_pkg.sv ../rtl/axi_if.sv
TBFILES       = ../rtl/axi_uvm_pkg.sv ../tb/tb.sv

UVM_TESTNAME ?= axi_base_test
transactions ?= 1
REGRESSION_TESTS = axi_sequential_reads_test axi_sequential_writes_test axi_pipelined_reads_test axi_pipelined_writes_test

LOG_DIR      = logs
COVERAGE_DIR = coverage
PARAMS_PKGS_TEMPLATE = params_pkg.sv_TMPL
PARAMS_PKGS_DIR = params_pkgs
MERGED_COVERAGE_UCDB =/merged_coverage.ucdb

all: uvm_dpi uvm.lib params_pkgs comp sim coverage_report

ALL_PARAM_PKGS = $(patsubst $(PARAMS_PKGS_DIR)/params_pkg_%.sv,%,$(wildcard $(PARAMS_PKGS_DIR)/params_pkg_*.sv))

params_pkgs:
	./gen_params_pkg.py --template $(PARAMS_PKGS_TEMPLATE) --outputdir=$(PARAMS_PKGS_DIR)

regression: uvm_dpi uvm.lib params_pkgs comp
	@$(foreach rtest, $(REGRESSION_TESTS), $(foreach var,$(ALL_PARAM_PKGS), make comp_params_pkg sim UVM_TESTNAME=$(rtest) PARAMS_STRING=$(var) transactions=10;))

comp_params_pkg:
	vlog -O0 -novopt -sv +incdir+`pwd`/../tb +incdir+$(UVM_HOME)/src $(PARAMSFILE)

comp: comp_params_pkg
	vlog -assertdebug -O0 -novopt -sv +incdir+`pwd`/../tb +incdir+$(UVM_HOME)/src $(RTLFILES) $(TBFILES) /opt/mentor/questasim_10.6/questasim/verilog_src/questa_uvm_pkg-1.2/src/questa_uvm_pkg.sv $(UVM_HOME)/src/uvm_pkg.sv



uvm.lib:
	vlog -work uvm.lib -sv +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv

uvm_dpi:
	rm -f uvm_dpi
	mkdir uvm_dpi
	g++ -m64 -fPIC -DQUESTA -g -W -shared -I/opt/mentor/questasim_10.6/questasim/include $(UVM_HOME)/src/dpi/uvm_dpi.cc -o uvm_dpi/uvm_dpi.so

$(LOG_DIR):
	mkdir -p $(LOG_DIR)

$(COVERAGE_DIR):
	mkdir -p $(COVERAGE_DIR)
	
sim: $(COVERAGE_DIR) $(LOG_DIR)
	vsim -assertdebug -l $(LOG_DIR)/$(UVM_TESTNAME)_$(PARAMS_STRING).log -c -sv_lib uvm_dpi/uvm_dpi -L uvm.lib -assertcover -coverage +UVM_TESTNAME=$(UVM_TESTNAME) +transactions=$(transactions) tb -do 'coverage save -onexit $(COVERAGE_DIR)/coverage_$(UVM_TESTNAME)_$(PARAMS_STRING).ucdb; run -all'

sim_gui:
	vsim -novopt -sv_lib uvm_dpi/uvm_dpi -L uvm.lib +UVM_TESTNAME=$(UVM_TESTNAME) +transactions=$(transactions) tb

coverage_report:
	-rm $(COVERAGE_DIR)/$(MERGED_COVERAGE_UCDB)
	vcover merge $(COVERAGE_DIR)/$(MERGED_COVERAGE_UCDB) $(COVERAGE_DIR)/coverage_*.ucdb
	vcover report -html -details $(COVERAGE_DIR)/$(MERGED_COVERAGE_UCDB)


clean:
	rm -fr work $(LOG_DIR) $(COVERAGE_DIR) covhtmlreport coverage.ucdb dump.vcd  transcript  uvm_dpi  uvm.lib $(PARAMS_PKGS_DIR)
