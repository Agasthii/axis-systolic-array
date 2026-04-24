`timescale 1ns/1ps
`include "config.svh"

module axis_vector_mac_tb;
  localparam
    R          = `R,
    WK         = `WK,
    WX         = `WX,
    WA         = 32,
    WY         = `WY,
    P_VALID    = `VALID_PROB,
    P_READY    = `READY_PROB,
    CLK_PERIOD = `CLK_PERIOD,
    NUM_EXP    = 50,
    MIN_BEATS  = 1,
    MAX_BEATS  = 64;

  logic clk = 0;
  logic rstn = 0;
  initial forever #(CLK_PERIOD/2) clk = ~clk;

  logic s_ready, sk_valid, sk_last, sx_valid, sx_last, sa_valid, sa_last;
  logic m_ready, m_valid, m_last;

  logic [R-1:0][WK-1:0] sk_data;
  logic [R-1:0][WX-1:0] sx_data;
  logic [R-1:0][WA-1:0] sa_data;
  logic [R-1:0][WY-1:0] m_data;
  logic [R-1:0] m_keep;

  wire s_valid = sk_valid & sx_valid & sa_valid;
  wire s_last  = sk_last  & sx_last  & sa_last;

  wire sk_ready = s_ready & sx_valid & sa_valid;
  wire sx_ready = s_ready & sk_valid & sa_valid;
  wire sa_ready = s_ready & sk_valid & sx_valid;

  assign m_keep = '1;

  axis_vector_mac #(
    .R (R ),
    .WK(WK),
    .WX(WX),
    .WA(WA),
    .WY(WY)
  ) DUT (
    .clk    (clk),
    .rstn   (rstn),
    .s_valid(s_valid),
    .s_ready(s_ready),
    .s_last (s_last),
    .sk_data(sk_data),
    .sx_data(sx_data),
    .sa_data(sa_data),
    .m_valid(m_valid),
    .m_ready(m_ready),
    .m_last (m_last),
    .m_data (m_data)
  );

  axis_source #(.WORD_W(WK), .BUS_W(WK*R), .PROB_VALID(P_VALID)) source_k (
    .clk(clk), .s_valid(sk_valid), .s_ready(sk_ready),
    .s_last(sk_last), .s_keep(), .s_data(sk_data)
  );

  axis_source #(.WORD_W(WX), .BUS_W(WX*R), .PROB_VALID(P_VALID)) source_x (
    .clk(clk), .s_valid(sx_valid), .s_ready(sx_ready),
    .s_last(sx_last), .s_keep(), .s_data(sx_data)
  );

  axis_source #(.WORD_W(WA), .BUS_W(WA*R), .PROB_VALID(P_VALID)) source_a (
    .clk(clk), .s_valid(sa_valid), .s_ready(sa_ready),
    .s_last(sa_last), .s_keep(), .s_data(sa_data)
  );

  axis_sink #(.WORD_W(WY), .BUS_W(WY*R), .PROB_READY(P_READY)) sink_y (
    .clk(clk), .m_valid(m_valid), .m_ready(m_ready),
    .m_last(m_last), .m_keep(m_keep), .m_data(m_data)
  );

  typedef logic signed [WK-1:0] kq_t [$];
  typedef logic signed [WX-1:0] xq_t [$];
  typedef logic signed [WA-1:0] aq_t [$];
  typedef logic signed [WY-1:0] yq_t [$];

  kq_t k_packets [NUM_EXP];
  xq_t x_packets [NUM_EXP];
  aq_t a_packets [NUM_EXP];
  yq_t y_packets [NUM_EXP];
  yq_t e_packets [NUM_EXP];

  task automatic random_k_packet(output logic signed [WK-1:0] q [$], input int n_words);
    q = {};
    repeat (n_words)
      q.push_back($signed(WK'($urandom())));
  endtask

  task automatic random_x_packet(output logic signed [WX-1:0] q [$], input int n_words);
    q = {};
    repeat (n_words)
      q.push_back($signed(WX'($urandom())));
  endtask

  task automatic random_a_packet(output logic signed [WA-1:0] q [$], input int n_words);
    q = {};
    repeat (n_words)
      q.push_back($signed(WA'($urandom())));
  endtask

  task automatic build_expected(
    input  logic signed [WK-1:0] k_packet [$],
    input  logic signed [WX-1:0] x_packet [$],
    input  logic signed [WA-1:0] a_packet [$],
    output logic signed [WY-1:0] y_packet [$]
  );
    longint signed result;

    y_packet = {};
    foreach (k_packet[i]) begin
      result = (longint'($signed(k_packet[i])) * longint'($signed(x_packet[i]))) +
               longint'($signed(a_packet[i]));
      y_packet.push_back(WY'(result));
    end
  endtask

  initial begin
    int n_words;

    $dumpfile("axis_vector_mac.vcd");
    $dumpvars;

    for (int n = 0; n < NUM_EXP; n++) begin
      n_words = R * $urandom_range(MIN_BEATS, MAX_BEATS);
      random_k_packet(k_packets[n], n_words);
      random_x_packet(x_packets[n], n_words);
      random_a_packet(a_packets[n], n_words);
      build_expected(k_packets[n], x_packets[n], a_packets[n], e_packets[n]);
    end

    repeat (5) @(posedge clk);
    rstn <= 1'b1;

    for (int n = 0; n < NUM_EXP; n++)
      source_k.axis_push_packet(k_packets[n]);
  end

  initial begin
    wait(rstn);
    for (int n = 0; n < NUM_EXP; n++)
      source_x.axis_push_packet(x_packets[n]);
  end

  initial begin
    wait(rstn);
    for (int n = 0; n < NUM_EXP; n++)
      source_a.axis_push_packet(a_packets[n]);
  end

  initial begin
    wait(rstn);
    $display("Waiting for packets to be received...");

    for (int n = 0; n < NUM_EXP; n++) begin
      sink_y.axis_pull_packet(y_packets[n]);

      if (y_packets[n] == e_packets[n])
        $display("Packet[%0d]: Outputs match", n);
      else begin
        $display("Packet[%0d]: Expected:\n%p\nReceived:\n%p", n, e_packets[n], y_packets[n]);
        $fatal(1, "Failed");
      end
    end

    $finish();
  end

  initial begin
    #(1000000*CLK_PERIOD);
    $fatal(1, "Timeout");
  end

endmodule
