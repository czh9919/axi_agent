// Simple synthesizable AXI-Lite slave RTL with error response support
module axi_lite_slave #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
) (
  input  logic ACLK,
  input  logic ARESETn,

  // AXI-Lite write address channel
  input  logic [ADDR_WIDTH-1:0] AWADDR,
  input  logic                   AWVALID,
  output logic                   AWREADY,

  // AXI-Lite write data channel
  input  logic [DATA_WIDTH-1:0] WDATA,
  input  logic [(DATA_WIDTH/8)-1:0] WSTRB,
  input  logic                   WVALID,
  output logic                   WREADY,

  // AXI-Lite write response channel
  output logic [1:0]             BRESP,
  output logic                   BVALID,
  input  logic                   BREADY,

  // AXI-Lite read address channel
  input  logic [ADDR_WIDTH-1:0] ARADDR,
  input  logic                   ARVALID,
  output logic                   ARREADY,

  // AXI-Lite read data channel
  output logic [DATA_WIDTH-1:0] RDATA,
  output logic [1:0]             RRESP,
  output logic                   RVALID,
  input  logic                   RREADY
);

  // Simple memory
  logic [DATA_WIDTH-1:0] mem [0:255];

  // Simple address range (OKAY inside [0, 255], SLVERR outside)
  localparam int BASE_ADDR = 0;
  localparam int HIGH_ADDR = 255;

  // Write FSM
  typedef enum logic [1:0] {WR_IDLE, WR_DATA, WR_RESP} wr_state_e;
  wr_state_e wr_state;
  logic [ADDR_WIDTH-1:0] wr_addr;

  // Read FSM
  typedef enum logic [1:0] {RD_IDLE, RD_DATA} rd_state_e;
  rd_state_e rd_state;
  logic [ADDR_WIDTH-1:0] rd_addr;

  // Write channel
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      wr_state <= WR_IDLE;
      AWREADY  <= 0;
      WREADY   <= 0;
      BVALID   <= 0;
      BRESP    <= 2'b00;
    end else begin
      case (wr_state)
        WR_IDLE: begin
          AWREADY <= 1;
          WREADY  <= 0;
          BVALID  <= 0;
          if (AWVALID && AWREADY) begin
            wr_addr  <= AWADDR;
            AWREADY  <= 0;
            WREADY   <= 1;
            wr_state <= WR_DATA;
          end
        end
        WR_DATA: begin
          if (WVALID && WREADY) begin
            WREADY <= 0;
            if (wr_addr[7:0] >= BASE_ADDR && wr_addr[7:0] <= HIGH_ADDR) begin
              mem[wr_addr[7:0]] <= WDATA;
              BRESP <= 2'b00; // OKAY
            end else begin
              BRESP <= 2'b10; // SLVERR
            end
            BVALID  <= 1;
            wr_state <= WR_RESP;
          end
        end
        WR_RESP: begin
          if (BVALID && BREADY) begin
            BVALID  <= 0;
            wr_state <= WR_IDLE;
          end
        end
      endcase
    end
  end

  // Read channel
  always_ff @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      rd_state <= RD_IDLE;
      ARREADY  <= 0;
      RVALID   <= 0;
      RDATA    <= '0;
      RRESP    <= 2'b00;
    end else begin
      case (rd_state)
        RD_IDLE: begin
          ARREADY <= 1;
          RVALID  <= 0;
          if (ARVALID && ARREADY) begin
            rd_addr <= ARADDR;
            ARREADY <= 0;
            rd_state <= RD_DATA;
          end
        end
        RD_DATA: begin
          if (!RVALID) begin
            if (rd_addr[7:0] >= BASE_ADDR && rd_addr[7:0] <= HIGH_ADDR) begin
              RDATA <= mem[rd_addr[7:0]];
              RRESP <= 2'b00; // OKAY
            end else begin
              RDATA <= '0;
              RRESP <= 2'b10; // SLVERR
            end
            RVALID <= 1;
          end else if (RVALID && RREADY) begin
            RVALID  <= 0;
            rd_state <= RD_IDLE;
          end
        end
      endcase
    end
  end

endmodule

