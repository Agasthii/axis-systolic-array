`timescale 1ns/1ps

module vector_mac #(
  parameter R  = 4,
  parameter WK = 8,
  parameter WX = 8,
  parameter WA = 32,
  parameter WY = 32
)(
  input  wire                  clk,
  input  wire                  rstn,
  input  wire                  en,

  input  wire [R*WK-1:0]       sk_data,
  input  wire [R*WX-1:0]       sx_data,
  input  wire [R*WA-1:0]       sa_data,

  output reg  [R*WY-1:0]       m_data
);

  localparam MUL_W = WK + WX;
  localparam ACC_W = ((MUL_W > WA) ? MUL_W : WA) + 1;

  wire [R*WY-1:0] y_data;

  genvar r;
  generate
    for (r = 0; r < R; r = r + 1) begin : GEN_LANE
      wire signed [WK-1:0]    k_lane;
      wire signed [WX-1:0]    x_lane;
      wire signed [WA-1:0]    a_lane;
      wire signed [ACC_W-1:0] y_lane;

      assign k_lane = sk_data[(r+1)*WK-1 -: WK];
      assign x_lane = sx_data[(r+1)*WX-1 -: WX];
      assign a_lane = sa_data[(r+1)*WA-1 -: WA];
      assign y_lane = $signed(k_lane) * $signed(x_lane) + $signed(a_lane);

      assign y_data[(r+1)*WY-1 -: WY] = y_lane[WY-1:0];
    end
  endgenerate

  always @(posedge clk) begin
    if (!rstn)
      m_data <= '0;
    else if (en)
      m_data <= y_data;
  end

endmodule
