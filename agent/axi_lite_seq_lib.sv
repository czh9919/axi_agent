import uvm_pkg::*;
`include "uvm_macros.svh"
import axi_lite_pkg::*;

// Basic write sequence
class axi_lite_write_seq extends uvm_sequence #(axi_lite_trans);
  `uvm_object_utils(axi_lite_write_seq)

  rand bit [AXI_LITE_ADDR_WIDTH-1:0] addr;
  rand bit [AXI_LITE_DATA_WIDTH-1:0] data;
  rand bit [(AXI_LITE_DATA_WIDTH/8)-1:0] strb;

  function new(string name="axi_lite_write_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi_lite_trans tr;
    `uvm_create(tr)
    tr.cmd  = AXI_LITE_WRITE;
    tr.addr = addr;
    tr.data = data;
    tr.strb = (strb == '0) ? '1 : strb;
    `uvm_send(tr)
  endtask
endclass

// Basic read sequence
class axi_lite_read_seq extends uvm_sequence #(axi_lite_trans);
  `uvm_object_utils(axi_lite_read_seq)

  rand bit [AXI_LITE_ADDR_WIDTH-1:0] addr;

  function new(string name="axi_lite_read_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi_lite_trans tr;
    `uvm_create(tr)
    tr.cmd  = AXI_LITE_READ;
    tr.addr = addr;
    tr.strb = '1;
    `uvm_send(tr)
  endtask
endclass

// Simple smoke sequence: write + read back
class axi_lite_smoke_seq extends uvm_sequence #(axi_lite_trans);
  `uvm_object_utils(axi_lite_smoke_seq)

  function new(string name="axi_lite_smoke_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi_lite_write_seq wr_seq;
    axi_lite_read_seq  rd_seq;

    repeat (10) begin
      wr_seq = axi_lite_write_seq::type_id::create("wr_seq");
      rd_seq = axi_lite_read_seq ::type_id::create("rd_seq");

      wr_seq.randomize() with { addr inside {[32'h0:32'hFF]}; };
      rd_seq.addr = wr_seq.addr;

      wr_seq.start(m_sequencer);
      rd_seq.start(m_sequencer);
    end
  endtask
endclass

