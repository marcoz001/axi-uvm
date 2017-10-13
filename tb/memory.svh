class memory extends uvm_component;
  `uvm_component_utils(memory)

  bit [7:0] mem[*];

  extern function new(string name="memory", uvm_component parent=null);
  extern virtual function void write(input bit [63:0] addr, input bit [7:0] data);
  extern virtual function bit [7:0] read (input bit [63:0] addr);

endclass : memory

function memory::new(string name="memory", uvm_component parent=null);
   super.new(name, parent);
endfunction : new

function void memory::write(input bit [63:0] addr, input bit [7:0] data);
  `uvm_info(this.get_type_name(), $sformatf("write mem(0x%0x)=0x%0x", addr, data), UVM_INFO)
  mem[addr] = data;
endfunction : write

function bit [7:0] memory::read(input bit [63:0] addr);

  if (mem.exists(addr))  begin
    `uvm_info(this.get_type_name(), $sformatf("read mem(0x%0x)=0x%0x", addr, mem[addr]), UVM_INFO)

    return mem[addr];
  end else begin
    `uvm_info(this.get_type_name(),
              $sformatf("read unwritten memory address [0x%0x]", addr),
              UVM_HIGH)
    return 'z;
  end
endfunction : read
