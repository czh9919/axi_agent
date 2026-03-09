// ------------------------------------------------------------
// Monitor + protocol checking + coverage
// ------------------------------------------------------------
class axi_lite_monitor extends uvm_component;
  `uvm_component_utils(axi_lite_monitor)

  axi_lite_config m_cfg;

  uvm_analysis_port #(axi_lite_trans) ap;

  axi_lite_protocol_checker axi_checker;
  axi_lite_cov              cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(axi_lite_config)::get(this, "", "cfg", m_cfg))
      `uvm_fatal(get_type_name(), "axi_lite_config not found for monitor")

    axi_checker = axi_lite_protocol_checker::type_id::create("axi_checker", this);
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
        if (m_cfg.enable_protocol_check) axi_checker.check_write_handshake(m_cfg.vif);
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
        if (m_cfg.enable_protocol_check) axi_checker.check_read_handshake(m_cfg.vif);
        cov.sample(tr3, m_cfg.vif.RRESP);
      end
    end
  endtask
endclass : axi_lite_monitor