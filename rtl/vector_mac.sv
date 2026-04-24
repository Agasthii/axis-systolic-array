`timescale 1ns/1ps

module vector_mac #(
  parameter R  = 4, WK = 8, WX = 8, WA = 32, WY = 32
)(
  input  logic clk, rstn, en,
  input  logic [R-1:0][WK-1:0] sk_data,
  input  logic [R-1:0][WX-1:0] sx_data,
  input  logic [R-1:0][WA-1:0] sa_data,
  output logic [R-1:0][WY-1:0] m_data
);
  genvar r;
  generate
    for (r = 0; r < R; r = r + 1)
      always @(posedge clk)
        if (!rstn)    m_data <= '0;
        else if (en)  m_data <= $signed(sk_data[r]) * $signed(sx_data[r]) + $signed(sa_data[r]);
  endgenerate
endmodule
