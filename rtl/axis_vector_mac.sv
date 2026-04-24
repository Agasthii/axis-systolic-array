`timescale 1ns/1ps

module axis_vector_mac #(
  parameter R  = 4, WK = 8, WX = 8, WA = 32, WY = 32
)(
  input  logic clk, rstn, 
  input  logic s_valid, s_last, m_ready,
  input  logic [R*WX-1:0] sx_data,
  input  logic [R*WK-1:0] sk_data,
  input  logic [R*WA-1:0] sa_data,
  output logic m_valid, m_last, s_ready,
  output logic [R*WY-1:0] m_data
);
  logic stall, en;

  always_comb begin
    stall   = m_valid & !m_ready;
    en      = !stall;
    s_ready = en;
  end
  
  always_ff @(posedge clk) begin
    if (!rstn) begin
      m_valid <= 1'b0;
      m_last  <= 1'b0;
    end else if (en) begin
      m_valid <= s_valid;
      m_last  <= s_valid & s_last;
    end
  end

  vector_mac #(
    .R(R),.WK(WK),.WX(WX),.WA(WA),.WY(WY)
    ) VECTOR_MAC (.*);

endmodule
