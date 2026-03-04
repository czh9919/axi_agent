package axi_lite_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Basic parameters (can be overridden via type parameters if needed)
  parameter int AXI_LITE_ADDR_WIDTH = 32;
  parameter int AXI_LITE_DATA_WIDTH = 32;

  // Forward declarations
  class axi_lite_config;
  class axi_lite_trans;
  class axi_lite_master_sequencer;
  class axi_lite_slave_sequencer;
  class axi_lite_master_driver;
  class axi_lite_slave_driver;
  class axi_lite_monitor;
  class axi_lite_protocol_checker;
  class axi_lite_cov;
  class axi_lite_master_agent;
  class axi_lite_slave_agent;

  typedef enum {AXI_LITE_READ, AXI_LITE_WRITE} axi_lite_cmd_e;

  // ------------------------------------------------------------
  // Configuration object
  // ------------------------------------------------------------
  class axi_lite_config extends uvm_object;
    `uvm_object_utils(axi_lite_config)

    // Active / passive
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    // Virtual interface handle (master modport for master agent, slave for slave agent)
    virtual interface axi_lite_if #(AXI_LITE_ADDR_WIDTH, AXI_LITE_DATA_WIDTH) vif;

    // Allow multiple instances by ID
    string agent_name;
    int    agent_id;

    // Protocol check enable
    bit enable_protocol_check = 1;

    // Future extension: full AXI options reserved
    bit enable_burst      = 0;
    bit enable_prot_bits  = 0;

    function new(string name="axi_lite_config");
      super.new(name);
    endfunction
  endclass : axi_lite_config

  // ------------------------------------------------------------
  // Transaction
  // ------------------------------------------------------------
  class axi_lite_trans extends uvm_sequence_item;
    `uvm_object_utils(axi_lite_trans)

    rand axi_lite_cmd_e cmd;
    rand bit [AXI_LITE_ADDR_WIDTH-1:0] addr;
    rand bit [AXI_LITE_DATA_WIDTH-1:0] data;
    rand bit [(AXI_LITE_DATA_WIDTH/8)-1:0] strb;

    // Response
    bit [1:0] resp;

    // Constraints for AXI-Lite alignment
    constraint c_align {
      addr[1:0] == 2'b00;
    }

    function new(string name="axi_lite_trans");
      super.new(name);
    endfunction

    function string convert2string();
      return $sformatf("cmd=%s addr=0x%0h data=0x%0h strb=0x%0h resp=0x%0h",
                       cmd.name(), addr, data, strb, resp);
    endfunction
  endclass : axi_lite_trans

  // ------------------------------------------------------------
  // Master Sequencer
  // ------------------------------------------------------------
  class axi_lite_master_sequencer extends uvm_sequencer #(axi_lite_trans);
    `uvm_component_utils(axi_lite_master_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass : axi_lite_master_sequencer

  // ------------------------------------------------------------
  // Slave Sequencer (for programmable slave behavior)
  // ------------------------------------------------------------
  class axi_lite_slave_sequencer extends uvm_sequencer #(axi_lite_trans);
    `uvm_component_utils(axi_lite_slave_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass : axi_lite_slave_sequencer

  // ------------------------------------------------------------
  // Master Driver
  // ------------------------------------------------------------
  class axi_lite_master_driver extends uvm_driver #(axi_lite_trans);
    `uvm_component_utils(axi_lite_master_driver)

    axi_lite_config m_cfg;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(axi_lite_config)::get(this, "", "cfg", m_cfg))
        `uvm_fatal(get_type_name(), "axi_lite_config not found for master driver")
    endfunction

    task run_phase(uvm_phase phase);
      axi_lite_trans tr;
      forever begin
        seq_item_port.get_next_item(tr);
        if (tr.cmd == AXI_LITE_WRITE)
          drive_write(tr);
        else
          drive_read(tr);
        seq_item_port.item_done();
      end
    endtask

    task drive_write(axi_lite_trans tr);
      // Simple single-beat write
      @(posedge m_cfg.vif.ACLK);
      // Address and data can be driven in parallel for AXI-Lite
      m_cfg.vif.AWADDR  <= tr.addr;
      m_cfg.vif.AWVALID <= 1'b1;
      m_cfg.vif.WDATA   <= tr.data;
      m_cfg.vif.WSTRB   <= tr.strb;
      m_cfg.vif.WVALID  <= 1'b1;
      // Handshake
      do @(posedge m_cfg.vif.ACLK); while (!m_cfg.vif.AWREADY);
      m_cfg.vif.AWVALID <= 1'b0;

      do @(posedge m_cfg.vif.ACLK); while (!m_cfg.vif.WREADY);
      m_cfg.vif.WVALID <= 1'b0;

      // Wait for response
      m_cfg.vif.BREADY <= 1'b1;
      do @(posedge m_cfg.vif.ACLK); while (!m_cfg.vif.BVALID);
      tr.resp = m_cfg.vif.BRESP;
      m_cfg.vif.BREADY <= 1'b0;
    endtask

    task drive_read(axi_lite_trans tr);
      @(posedge m_cfg.vif.ACLK);
      m_cfg.vif.ARADDR  <= tr.addr;
      m_cfg.vif.ARVALID <= 1'b1;
      // Address handshake
      do @(posedge m_cfg.vif.ACLK); while (!m_cfg.vif.ARREADY);
      m_cfg.vif.ARVALID <= 1'b0;

      // Data phase
      m_cfg.vif.RREADY <= 1'b1;
      do @(posedge m_cfg.vif.ACLK); while (!m_cfg.vif.RVALID);
      tr.data = m_cfg.vif.RDATA;
      tr.resp = m_cfg.vif.RRESP;
      m_cfg.vif.RREADY <= 1'b0;
    endtask
  endclass : axi_lite_master_driver

  // ------------------------------------------------------------
  // Slave Driver (simple memory-mapped slave with error support)
  // ------------------------------------------------------------
  class axi_lite_slave_driver extends uvm_driver #(axi_lite_trans);
    `uvm_component_utils(axi_lite_slave_driver)

    axi_lite_config m_cfg;

    // Simple memory model
    bit [AXI_LITE_DATA_WIDTH-1:0] mem [bit [AXI_LITE_ADDR_WIDTH-1:0]];

    // Address range for OKAY response; others return SLVERR
    bit [AXI_LITE_ADDR_WIDTH-1:0] base_addr = 'h0000_0000;
    bit [AXI_LITE_ADDR_WIDTH-1:0] size_bytes = 'h0001_0000;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(axi_lite_config)::get(this, "", "cfg", m_cfg))
        `uvm_fatal(get_type_name(), "axi_lite_config not found for slave driver")
    endfunction

    task run_phase(uvm_phase phase);
      fork
        handle_write_channel();
        handle_read_channel();
      join
    endtask

    // Write address/data/response
    task handle_write_channel();
      m_cfg.vif.AWREADY <= 0;
      m_cfg.vif.WREADY  <= 0;
      m_cfg.vif.BVALID  <= 0;
      m_cfg.vif.BRESP   <= 0;
      forever begin
        @(posedge m_cfg.vif.ACLK);
        // Accept address
        if (m_cfg.vif.AWVALID && !m_cfg.vif.AWREADY)
          m_cfg.vif.AWREADY <= 1;
        else
          m_cfg.vif.AWREADY <= 0;

        // Accept data
        if (m_cfg.vif.WVALID && !m_cfg.vif.WREADY)
          m_cfg.vif.WREADY <= 1;
        else
          m_cfg.vif.WREADY <= 0;

        if (m_cfg.vif.AWVALID && m_cfg.vif.AWREADY &&
            m_cfg.vif.WVALID  && m_cfg.vif.WREADY) begin
          // Perform write and generate response
          bit [AXI_LITE_ADDR_WIDTH-1:0] addr = m_cfg.vif.AWADDR;
          bit [1:0] resp;
          if (addr >= base_addr && addr < (base_addr + size_bytes)) begin
            mem[addr] = m_cfg.vif.WDATA;
            resp = 2'b00; // OKAY
          end
          else begin
            resp = 2'b10; // SLVERR
          end
          // Issue response
          m_cfg.vif.BRESP  <= resp;
          m_cfg.vif.BVALID <= 1;
          do @(posedge m_cfg.vif.ACLK); while (!m_cfg.vif.BREADY);
          m_cfg.vif.BVALID <= 0;
        end
      end
    endtask

    // Read address/data
    task handle_read_channel();
      m_cfg.vif.ARREADY <= 0;
      m_cfg.vif.RVALID  <= 0;
      m_cfg.vif.RRESP   <= 0;
      forever begin
        @(posedge m_cfg.vif.ACLK);
        if (m_cfg.vif.ARVALID && !m_cfg.vif.ARREADY)
          m_cfg.vif.ARREADY <= 1;
        else
          m_cfg.vif.ARREADY <= 0;

        if (m_cfg.vif.ARVALID && m_cfg.vif.ARREADY) begin
          bit [AXI_LITE_ADDR_WIDTH-1:0] addr = m_cfg.vif.ARADDR;
          bit [AXI_LITE_DATA_WIDTH-1:0] rdata;
          bit [1:0] resp;
          if (addr >= base_addr && addr < (base_addr + size_bytes)) begin
            rdata = mem.exists(addr) ? mem[addr] : '0;
            resp  = 2'b00; // OKAY
          end
          else begin
            rdata = '0;
            resp  = 2'b10; // SLVERR
          end
          m_cfg.vif.RDATA  <= rdata;
          m_cfg.vif.RRESP  <= resp;
          m_cfg.vif.RVALID <= 1;
          do @(posedge m_cfg.vif.ACLK); while (!m_cfg.vif.RREADY);
          m_cfg.vif.RVALID <= 0;
        end
      end
    endtask
  endclass : axi_lite_slave_driver

  // ------------------------------------------------------------
  // Monitor + protocol checking + coverage
  // ------------------------------------------------------------
  class axi_lite_monitor extends uvm_component;
    `uvm_component_utils(axi_lite_monitor)

    axi_lite_config m_cfg;

    uvm_analysis_port #(axi_lite_trans) ap;

    axi_lite_protocol_checker checker;
    axi_lite_cov              cov;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(axi_lite_config)::get(this, "", "cfg", m_cfg))
        `uvm_fatal(get_type_name(), "axi_lite_config not found for monitor")

      checker = axi_lite_protocol_checker::type_id::create("checker", this);
      cov     = axi_lite_cov::type_id::create("cov", this);
    endfunction

    task run_phase(uvm_phase phase);
      forever begin
        @(posedge m_cfg.vif.ACLK);
        if (!m_cfg.vif.ARESETn) continue;

        // Simple write transaction sampling
        if (m_cfg.vif.AWVALID && m_cfg.vif.AWREADY &&
            m_cfg.vif.WVALID  && m_cfg.vif.WREADY) begin
          axi_lite_trans tr = axi_lite_trans::type_id::create("mon_wr_tr");
          tr.cmd  = AXI_LITE_WRITE;
          tr.addr = m_cfg.vif.AWADDR;
          tr.data = m_cfg.vif.WDATA;
          tr.strb = m_cfg.vif.WSTRB;
          // response will be captured later
          ap.write(tr);
          if (m_cfg.enable_protocol_check) checker.check_write_handshake(m_cfg.vif);
          cov.sample(tr, m_cfg.vif.BRESP);
        end

        // Simple read transaction sampling
        if (m_cfg.vif.ARVALID && m_cfg.vif.ARREADY) begin
          // Wait for RVALID in a non-blocking style is skipped in monitor
          axi_lite_trans tr2 = axi_lite_trans::type_id::create("mon_rd_tr");
          tr2.cmd  = AXI_LITE_READ;
          tr2.addr = m_cfg.vif.ARADDR;
          ap.write(tr2);
        end

        if (m_cfg.vif.RVALID && m_cfg.vif.RREADY) begin
          axi_lite_trans tr3 = axi_lite_trans::type_id::create("mon_rd_data_tr");
          tr3.cmd  = AXI_LITE_READ;
          tr3.data = m_cfg.vif.RDATA;
          tr3.resp = m_cfg.vif.RRESP;
          ap.write(tr3);
          if (m_cfg.enable_protocol_check) checker.check_read_handshake(m_cfg.vif);
          cov.sample(tr3, m_cfg.vif.RRESP);
        end
      end
    endtask
  endclass : axi_lite_monitor

  // ------------------------------------------------------------
  // Industrial-style protocol checker (assertion-like checks in SV code)
  // ------------------------------------------------------------
  class axi_lite_protocol_checker extends uvm_component;
    `uvm_component_utils(axi_lite_protocol_checker)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    // Basic handshake checks for write
    virtual task check_write_handshake(virtual axi_lite_if vif);
      // Here we just check that valid/ready were both high on clk edge,
      // more complex temporal checks can be added as SVA in future.
      if (!(vif.AWVALID && vif.AWREADY))
        `uvm_error(get_type_name(), "Write address handshake violation (AW)")
      if (!(vif.WVALID && vif.WREADY))
        `uvm_error(get_type_name(), "Write data handshake violation (W)")
      if (!(vif.BVALID && vif.BREADY))
        `uvm_error(get_type_name(), "Write response handshake violation (B)")
    endtask

    // Basic handshake checks for read
    virtual task check_read_handshake(virtual axi_lite_if vif);
      if (!(vif.ARVALID && vif.ARREADY))
        `uvm_error(get_type_name(), "Read address handshake violation (AR)")
      if (!(vif.RVALID && vif.RREADY))
        `uvm_error(get_type_name(), "Read data handshake violation (R)")
    endtask
  endclass : axi_lite_protocol_checker

  // ------------------------------------------------------------
  // Basic functional coverage (industrial but not over-complicated)
  // ------------------------------------------------------------
  class axi_lite_cov extends uvm_component;
    `uvm_component_utils(axi_lite_cov)

    axi_lite_cmd_e cov_cmd;
    bit [AXI_LITE_ADDR_WIDTH-1:0] cov_addr;
    bit [1:0] cov_resp;

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

    // Simple sample clock
    bit cov_sample_clk;

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

  // ------------------------------------------------------------
  // Master Agent
  // ------------------------------------------------------------
  class axi_lite_master_agent extends uvm_agent;
    `uvm_component_utils(axi_lite_master_agent)

    axi_lite_config          cfg;
    axi_lite_master_sequencer seqr;
    axi_lite_master_driver    drv;
    axi_lite_monitor          mon;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(axi_lite_config)::get(this, "", "cfg", cfg))
        `uvm_fatal(get_type_name(), "axi_lite_config not found for master agent")

      if (cfg.is_active == UVM_ACTIVE) begin
        seqr = axi_lite_master_sequencer::type_id::create("seqr", this);
        drv  = axi_lite_master_driver   ::type_id::create("drv",  this);
        uvm_config_db#(axi_lite_config)::set(this, "drv", "cfg", cfg);
      end

      mon  = axi_lite_monitor::type_id::create("mon", this);
      uvm_config_db#(axi_lite_config)::set(this, "mon", "cfg", cfg);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (cfg.is_active == UVM_ACTIVE) begin
        drv.seq_item_port.connect(seqr.seq_item_export);
      end
    endfunction
  endclass : axi_lite_master_agent

  // ------------------------------------------------------------
  // Slave Agent (industrial-style, error response supported)
  // ------------------------------------------------------------
  class axi_lite_slave_agent extends uvm_agent;
    `uvm_component_utils(axi_lite_slave_agent)

    axi_lite_config         cfg;
    axi_lite_slave_sequencer seqr;
    axi_lite_slave_driver    drv;
    axi_lite_monitor         mon;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if (!uvm_config_db#(axi_lite_config)::get(this, "", "cfg", cfg))
        `uvm_fatal(get_type_name(), "axi_lite_config not found for slave agent")

      // For industrial-style slave, we usually run active to respond to master
      if (cfg.is_active == UVM_ACTIVE) begin
        seqr = axi_lite_slave_sequencer::type_id::create("seqr", this);
        drv  = axi_lite_slave_driver   ::type_id::create("drv",  this);
        uvm_config_db#(axi_lite_config)::set(this, "drv", "cfg", cfg);
      end

      mon  = axi_lite_monitor::type_id::create("mon", this);
      uvm_config_db#(axi_lite_config)::set(this, "mon", "cfg", cfg);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (cfg.is_active == UVM_ACTIVE) begin
        drv.seq_item_port.connect(seqr.seq_item_export);
      end
    endfunction
  endclass : axi_lite_slave_agent

endpackage : axi_lite_pkg

