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