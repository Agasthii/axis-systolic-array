`timescale 1ns/1ps

module axis_vector_mac #(
  parameter R  = 4,
  parameter WK = 8,
  parameter WX = 8,
  parameter WA = 32,
  parameter WY = 32
)(
  input  wire                  clk,
  input  wire                  rstn,

  input  wire                  s_valid,
  output wire                  s_ready,
  input  wire                  s_last,

  input  wire [R*WK-1:0]       sk_data,
  input  wire [R*WX-1:0]       sx_data,
  input  wire [R*WA-1:0]       sa_data,

  output wire                  m_valid,
  input  wire                  m_ready,
  output wire                  m_last,
  output wire [R*WY-1:0]       m_data
);

  reg m_valid_reg;
  reg m_last_reg;

  wire stall = m_valid_reg & !m_ready;
  wire en    = !stall;

  assign s_ready = en;
  assign m_valid = m_valid_reg;
  assign m_last  = m_last_reg;

  always @(posedge clk) begin
    if (!rstn) begin
      m_valid_reg <= 1'b0;
      m_last_reg  <= 1'b0;
    end else if (en) begin
      m_valid_reg <= s_valid;
      m_last_reg  <= s_valid & s_last;
    end
  end

  vector_mac #(
    .R (R ),
    .WK(WK),
    .WX(WX),
    .WA(WA),
    .WY(WY)
  ) VECTOR_MAC (
    .clk    (clk),
    .rstn   (rstn),
    .en     (en),
    .sk_data(sk_data),
    .sx_data(sx_data),
    .sa_data(sa_data),
    .m_data (m_data)
  );

endmodule
