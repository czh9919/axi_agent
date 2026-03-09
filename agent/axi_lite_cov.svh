// ------------------------------------------------------------
// Basic functional coverage (industrial but not over-complicated)
// ------------------------------------------------------------
class axi_lite_cov extends uvm_component;
  `uvm_component_utils(axi_lite_cov)

  axi_lite_cmd_e cov_cmd;
  bit [AXI_LITE_ADDR_WIDTH-1:0] cov_addr;
  bit [1:0] cov_resp;

  // Simple sample clock
  bit cov_sample_clk;

  covergroup cg_axi_lite @(posedge cov_sample_clk);
    option.per_instance = 1;

    cmd_cp: coverpoint cov_cmd {
      bins rd = {AXI_LITE_READ};
      bins wr = {AXI_LITE_WRITE};
    }

    addr_cp: coverpoint cov_addr[7:2] {
      bins low  = {[0:15]};
      bins mid  = {[16:47]};
      bins high = default;
    }

    resp_cp: coverpoint cov_resp {
      bins okay   = {2'b00};
      bins slverr = {2'b10};
    }

    cmd_resp_cross: cross cmd_cp, resp_cp;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_axi_lite = new();
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      #1ns;
      cov_sample_clk = ~cov_sample_clk;
    end
  endtask

  function void sample(axi_lite_trans tr, bit [1:0] resp);
    cov_cmd  = tr.cmd;
    cov_addr = tr.addr;
    cov_resp = resp;
    cg_axi_lite.sample();
  endfunction
endclass : axi_lite_cov