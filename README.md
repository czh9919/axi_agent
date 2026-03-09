### AXI-Lite UVM Agent

本工程提供一个**支持 Active / Passive** 的 **AXI-Lite** UVM Agent（含协议检查、覆盖率、总线监视），并给出一个可直接跑通的 demo testbench 与简化 RTL（含错误响应）。协议范围当前只覆盖 **AXI4-Lite**，但代码结构预留了 future upgrade 到 full AXI 的扩展点。

本工程还未经过测试
---

### 目录结构

- **`agent/`**：AXI-Lite UVM 组件与接口
  - `axi_lite_if.sv`：AXI-Lite interface（master/slave/monitor modport）
  - `axi_lite_pkg.sv`：UVM package（config/trans/driver/monitor/checker/coverage/agent）
  - `axi_lite_seq_lib.sv`：基础 sequence（write/read/smoke）
  - `include/`：放置 `axi_lite_pkg` 相关 `svh/sv` include 文件（统一 +incdir）
  - `axi_lite_agent.f`：agent 编译 filelist
- **`tb/`**：testbench
  - `axi_lite_env.sv`：env（组装 master/slave agent）
  - `axi_lite_test.sv`：基础 test（跑 smoke sequence）
  - `top_tb.sv`：顶层 TB（时钟/复位、virtual interface 配置、实例化 RTL）
  - `tb.f`：tb 编译 filelist
- **`rtl/`**：简化 RTL demo
  - `axi_lite_slave.sv`：AXI-Lite slave（带 OKAY/SLVERR 错误响应）
  - `axi_lite_master.sv`：demo master shell（可替换为真实 SoC master）
  - `rtl.f`：rtl 编译 filelist

---

### 支持能力（按你的需求对齐）

- **Active / Passive**
  - Active：创建 sequencer/driver，主动驱动总线（master/slave 都支持）
  - Passive：只创建 monitor（协议检查 + coverage + bus monitor）
- **AXI-Lite 协议范围**
  - 覆盖单拍 read/write（AW/W/B，AR/R）
  - 响应支持 `OKAY(2'b00)` / `SLVERR(2'b10)`
- **工业风要点**
  - monitor 内聚合：bus monitor + protocol checker + basic functional coverage
  - slave driver / rtl 都支持错误响应（越界返回 SLVERR）
- **Multiple instance + Virtual interface**
  - 通过 `uvm_config_db` 对不同 agent path 下注入不同 `vif/cfg`，可扩展成数组/多端口 SoC
- **Future upgrade（预留点）**
  - `axi_lite_config` 预留 burst/prot 等开关位（后续加 full AXI 字段与多拍逻辑）

---

### 快速运行（示例）

你只需要把三个 `.f` filelist 喂给仿真器即可：

- **VCS 示例**

```bash
vcs -full64 -sverilog -ntb_opts uvm \
  -f rtl/rtl.f \
  -f tb/tb.f
./simv +UVM_TESTNAME=axi_lite_base_test
```

- **Questa/Modelsim 示例**

```bash
vlib work
vlog -sv -f rtl/rtl.f -f tb/tb.f
vsim -c top_tb -do "run -all; quit" +UVM_TESTNAME=axi_lite_base_test
```

> 注意：不同仿真器的 UVM 编译选项略有区别，上面只是常见写法；如果你用的是特定版本（如 VCS/Questa 的具体版本），我可以按你的工具链把命令行整理成一条可直接复制的。

---

### Active / Passive 使用方式

- **默认 demo（SoC-like）**
  - `tb/axi_lite_test.sv` 中 master/slave 都配置为 `UVM_ACTIVE`
  - master 跑 `axi_lite_smoke_seq`，slave driver 负责响应

- **IP verification 场景（DUT 自己驱动总线，你只做监控/检查/覆盖）**
  - 把对应 agent 的 `cfg.is_active = UVM_PASSIVE`
  - 只保留 monitor：协议检查 + 覆盖率 + 总线监控

---

### 多实例（Multiple instance）建议写法

当你有多个 AXI-Lite 端口时，建议：
- 在 `env` 里把 `m_master_agt/m_slave_agt` 改成数组（或 `uvm_component` 容器）
- 对每个实例：
  - `cfg.agent_id = i`
  - `uvm_config_db::set(null, "uvm_test_top.m_env.m_master_agt[i]", "vif", vif_i);`

---

### 已知说明（当前 demo 的取舍）

- `rtl/axi_lite_master.sv` 是 **demo shell**（tie-off），真实 SoC 中你会有 CPU/master IP 来驱动总线；
  - 如果你希望 demo 完全不依赖 UVM driver，而由 RTL master 自己发起访问，我也可以再补一个“可编程 RTL master”版本。
- monitor 目前是“轻量级工业风”：以 handshake/resp 为主做检查与 coverage；
  - 若你希望更严格（例如 stable 规则、valid 持续规则、握手超时等），建议改为 SVA + bind（我也可以帮你补齐）。

