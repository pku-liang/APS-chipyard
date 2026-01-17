// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Thomas Benz <tbenz@iis.ee.ethz.ch>
// - Tobias Senti <tsenti@student.ethz.ch>
// - Paul Scheffler <paulsc@iis.ee.ethz.ch>

module tc_sram_blackbox #(
  parameter int unsigned NumWords     = 32'd0,
  parameter int unsigned DataWidth    = 32'd0,
  parameter int unsigned ByteWidth    = 32'd0,
  parameter int unsigned NumPorts     = 32'd0,
  parameter int unsigned Latency      = 32'd0,
  parameter              SimInit      = "none",
  parameter bit          PrintSimCfg  = 1'b0,
  parameter              ImplKey      = "none"
) ();
endmodule

// one tie-off per macro to avoid port size mismatch warnings
`define IHP13_TC_SRAM_64x64_TIEOFF \
  .A_BIST_CLK   (  1'b0 ), \
  .A_BIST_ADDR  (  6'd0 ), \
  .A_BIST_DIN   ( 64'd0 ), \
  .A_BIST_BM    ( 64'd0 ), \
  .A_BIST_MEN   (  1'b0 ), \
  .A_BIST_WEN   (  1'b0 ), \
  .A_BIST_REN   (  1'b0 ), \
  .A_BIST_EN    (  1'b0 ), \
  .A_DLY        (  1'b0 )

`define IHP13_TC_SRAM_256x64_TIEOFF \
  .A_BIST_CLK   (  1'b0 ), \
  .A_BIST_ADDR  (  8'd0 ), \
  .A_BIST_DIN   ( 64'd0 ), \
  .A_BIST_BM    ( 64'd0 ), \
  .A_BIST_MEN   (  1'b0 ), \
  .A_BIST_WEN   (  1'b0 ), \
  .A_BIST_REN   (  1'b0 ), \
  .A_BIST_EN    (  1'b0 ), \
  .A_DLY        (  1'b0 )
  
`define IHP13_TC_SRAM_512x64_TIEOFF \
  .A_BIST_CLK   (  1'b0 ), \
  .A_BIST_ADDR  (  9'd0 ), \
  .A_BIST_DIN   ( 64'd0 ), \
  .A_BIST_BM    ( 64'd0 ), \
  .A_BIST_MEN   (  1'b0 ), \
  .A_BIST_WEN   (  1'b0 ), \
  .A_BIST_REN   (  1'b0 ), \
  .A_BIST_EN    (  1'b0 ), \
  .A_DLY        (  1'b0 )

`define IHP13_TC_SRAM_1024x64_TIEOFF \
  .A_BIST_CLK   (  1'b0 ), \
  .A_BIST_ADDR  ( 10'd0 ), \
  .A_BIST_DIN   ( 64'd0 ), \
  .A_BIST_BM    ( 64'd0 ), \
  .A_BIST_MEN   (  1'b0 ), \
  .A_BIST_WEN   (  1'b0 ), \
  .A_BIST_REN   (  1'b0 ), \
  .A_BIST_EN    (  1'b0 ), \
  .A_DLY        (  1'b0 )

`define IHP13_TC_SRAM_2048x64_TIEOFF \
  .A_BIST_CLK   (  1'b0 ), \
  .A_BIST_ADDR  ( 11'd0 ), \
  .A_BIST_DIN   ( 64'd0 ), \
  .A_BIST_BM    ( 64'd0 ), \
  .A_BIST_MEN   (  1'b0 ), \
  .A_BIST_WEN   (  1'b0 ), \
  .A_BIST_REN   (  1'b0 ), \
  .A_BIST_EN    (  1'b0 ), \
  .A_DLY        (  1'b0 )

module tc_sram #(
  parameter int unsigned NumWords     = 32'd1024,
  parameter int unsigned DataWidth    = 32'd128,
  parameter int unsigned ByteWidth    = 32'd8,
  parameter int unsigned NumPorts     = 32'd2,
  parameter int unsigned Latency      = 32'd1,
  parameter              SimInit      = "none",
  parameter bit          PrintSimCfg  = 1'b0,
  parameter              ImplKey      = "none",
  // DEPENDENT PARAMETERS, DO NOT OVERWRITE!
  parameter int unsigned AddrWidth = (NumWords > 32'd1) ? $clog2(NumWords) : 32'd1,
  parameter int unsigned BeWidth   = (DataWidth + ByteWidth - 32'd1) / ByteWidth
) (
  input  logic                 clk_i,
  input  logic                 rst_ni,
  input  logic  [NumPorts-1:0] req_i,
  input  logic  [NumPorts-1:0] we_i,
  input  [AddrWidth-1:0] [NumPorts-1:0] addr_i,
  input  [DataWidth-1:0] [NumPorts-1:0] wdata_i,
  input  [BeWidth-1:0]   [NumPorts-1:0] be_i,
  output [DataWidth-1:0] [NumPorts-1:0] rdata_o
);

  localparam P1L1 = (NumPorts == 1 & Latency == 1);

  // Assemble bit mask
  logic [DataWidth-1:0] [NumPorts-1:0] bm;

  for (genvar p = 0; p < NumPorts; ++p) begin : gen_bm_ports
      for (genvar b = 0; b < DataWidth; ++b) begin : gen_bm_bits
        assign bm[p][b] = be_i[p][b/ByteWidth];
      end
  end

  // Generate desired cuts
  if (NumWords == 64 && DataWidth == 64 && P1L1) begin: gen_64x64xBx1
    logic [63:0] wdata64, rdata64, bm64;
    
    assign rdata_o = rdata64;
    assign wdata64 = wdata_i;
    assign bm64    = bm;
    

    RM_IHPSG13_1P_64x64_c2_bm_bist i_cut (
      .A_CLK   ( clk_i    ),
      .A_ADDR  ( addr_i [0][5:0] ),
      .A_BM    ( bm64     ),
      .A_MEN   ( req_i    ),
      .A_WEN   ( we_i     ),
      .A_REN   ( ~we_i    ),
      .A_DIN   ( wdata64  ),
      .A_DOUT  ( rdata64  ),
     `IHP13_TC_SRAM_64x64_TIEOFF
    );

  end else if (NumWords == 256 & DataWidth == 64 & P1L1) begin : gen_256x64xBx1
    logic [63:0] wdata64, rdata64, bm64;
    
    assign rdata_o = rdata64;
    assign wdata64 = wdata_i;
    assign bm64    = bm;

    RM_IHPSG13_1P_256x64_c2_bm_bist i_cut (
      .A_CLK   ( clk_i    ),
      .A_ADDR  ( addr_i [0][7:0] ),
      .A_BM    ( bm64     ),
      .A_MEN   ( req_i    ),
      .A_WEN   ( we_i     ),
      .A_REN   ( ~we_i    ),
      .A_DIN   ( wdata64  ),
      .A_DOUT  ( rdata64  ),
     `IHP13_TC_SRAM_256x64_TIEOFF
    );

  end else if (NumWords == 512 & DataWidth == 64 & P1L1) begin : gen_512x64xBx1
    logic [63:0] wdata64, rdata64, bm64;
    
    assign rdata_o = rdata64;
    assign wdata64 = wdata_i;
    assign bm64    = bm;

    RM_IHPSG13_1P_512x64_c2_bm_bist i_cut (
      .A_CLK   ( clk_i    ),
      .A_ADDR  ( addr_i [0][8:0] ),
      .A_BM    ( bm64     ),
      .A_MEN   ( req_i    ),
      .A_WEN   ( we_i     ),
      .A_REN   ( ~we_i    ),
      .A_DIN   ( wdata64  ),
      .A_DOUT  ( rdata64  ),
     `IHP13_TC_SRAM_512x64_TIEOFF
    );

  end else if (NumWords == 1024 & DataWidth == 64 & P1L1) begin : gen_1024x64xBx1
    logic [63:0] wdata64, rdata64, bm64;
    
    assign rdata_o = rdata64;
    assign wdata64 = wdata_i;
    assign bm64    = bm;

    RM_IHPSG13_1P_1024x64_c2_bm_bist i_cut (
       .A_CLK   ( clk_i    ),
       .A_ADDR  ( addr_i [0][9:0] ),
       .A_BM    ( bm64     ),
       .A_MEN   ( req_i    ),
       .A_WEN   ( we_i     ),
       .A_REN   ( ~we_i    ),
       .A_DIN   ( wdata64  ),
       .A_DOUT  ( rdata64  ),
       `IHP13_TC_SRAM_1024x64_TIEOFF
      );

  end else if (NumWords == 2048 & DataWidth == 64 & P1L1) begin : gen_2048x64xBx1
    logic [63:0] wdata64, rdata64, bm64;
    
    assign rdata_o = rdata64;
    assign wdata64 = wdata_i;
    assign bm64    = bm;

    RM_IHPSG13_1P_2048x64_c2_bm_bist i_cut (
       .A_CLK   ( clk_i    ),
       .A_ADDR  ( addr_i [0][10:0] ),
       .A_BM    ( bm64     ),
       .A_MEN   ( req_i    ),
       .A_WEN   ( we_i     ),
       .A_REN   ( ~we_i    ),
       .A_DIN   ( wdata64  ),
       .A_DOUT  ( rdata64  ),
       `IHP13_TC_SRAM_2048x64_TIEOFF
      );
  
  end else if (NumWords == 128 && DataWidth == 32 && P1L1) begin: gen_128x32xBx1
    logic [63:0] wdata64, rdata64, bm64;
    logic sel_d, sel_q;

    // muxing neighboring bits instead of upper/lower 32bit reduces routing
    always_comb begin : gen_bit_interleaving
      for (int i = 0; i < 32; i++) begin
          // duplicate each bit
          wdata64[2*i]   = wdata_i[0][i]; // even bits (active if addr LSB is 0)
          bm64[2*i]      = bm[0][i] & ~addr_i[0][0];
          wdata64[2*i+1] = wdata_i[0][i]; // odd bits  (active if addr LSB is 1)
          bm64[2*i+1]    = bm[0][i] & addr_i[0][0];

          if(~sel_q) begin
            rdata_o[0][i] = rdata64[2*i];   // even bits
          end else begin
            rdata_o[0][i] = rdata64[2*i+1]; // odd bitss
          end
      end
    end

    // LSB needed for read in next cycle
    assign sel_d = addr_i[0][0];

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_mem_sel_q
      if(~rst_ni)             sel_q <= '0;
      else if (req_i & ~we_i) sel_q <= sel_d;
    end

    RM_IHPSG13_1P_64x64_c2_bm_bist i_cut (
     .A_CLK   ( clk_i   ),
     .A_ADDR  ( addr_i [0][6:1] ),
     .A_BM    ( bm64    ),
     .A_MEN   ( req_i   ),
     .A_WEN   ( we_i    ),
     .A_REN   ( ~we_i   ),
     .A_DIN   ( wdata64 ),
     .A_DOUT  ( rdata64 ),
     `IHP13_TC_SRAM_64x64_TIEOFF
    );
  end else if (NumWords == 512 && DataWidth == 32 && P1L1) begin: gen_512x32xBx1
    logic [63:0] wdata64, rdata64, bm64;
    logic sel_d, sel_q;

    // muxing neighboring bits instead of upper/lower 32bit reduces routing
    always_comb begin : gen_bit_interleaving
      for (int i = 0; i < 32; i++) begin
          // duplicate each bit
          wdata64[2*i]   = wdata_i[0][i]; // even bits (active if addr LSB is 0)
          bm64[2*i]      = bm[0][i] & ~addr_i[0][0];
          wdata64[2*i+1] = wdata_i[0][i]; // odd bits  (active if addr LSB is 1)
          bm64[2*i+1]    = bm[0][i] & addr_i[0][0];

          if(~sel_q) begin
            rdata_o[0][i] = rdata64[2*i];   // even bits
          end else begin
            rdata_o[0][i] = rdata64[2*i+1]; // odd bitss
          end
      end
    end

    // LSB needed for read in next cycle
    assign sel_d = addr_i[0][0];

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_mem_sel_q
      if(~rst_ni)             sel_q <= '0;
      else if (req_i & ~we_i) sel_q <= sel_d;
    end

    RM_IHPSG13_1P_256x64_c2_bm_bist i_cut (
     .A_CLK   ( clk_i   ),
     .A_ADDR  ( addr_i [0][8:1] ),
     .A_BM    ( bm64    ),
     .A_MEN   ( req_i   ),
     .A_WEN   ( we_i    ),
     .A_REN   ( ~we_i   ),
     .A_DIN   ( wdata64 ),
     .A_DOUT  ( rdata64 ),
     `IHP13_TC_SRAM_256x64_TIEOFF
    );

  end else if (NumWords == 1024 && DataWidth == 32 && P1L1) begin: gen_1024x32xBx1
    logic [63:0] wdata64, rdata64, bm64;
    logic sel_d, sel_q;

    // muxing neighboring bits instead of upper/lower 32bit reduces routing
    always_comb begin : gen_bit_interleaving
      for (int i = 0; i < 32; i++) begin
          // duplicate each bit
          wdata64[2*i]   = wdata_i[0][i]; // even bits (active if addr LSB is 0)
          bm64[2*i]      = bm[0][i] & ~addr_i[0][0];
          wdata64[2*i+1] = wdata_i[0][i]; // odd bits  (active if addr LSB is 1)
          bm64[2*i+1]    = bm[0][i] & addr_i[0][0];

          if(~sel_q) begin
            rdata_o[0][i] = rdata64[2*i];   // even bits
          end else begin
            rdata_o[0][i] = rdata64[2*i+1]; // odd bits
          end
      end
    end

    // LSB needed for read in next cycle
    assign sel_d = addr_i[0][0];

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_mem_sel_q
      if(~rst_ni)             sel_q <= '0;
      else if (req_i & ~we_i) sel_q <= sel_d;
    end

    RM_IHPSG13_1P_512x64_c2_bm_bist i_cut (
     .A_CLK   ( clk_i   ),
     .A_ADDR  ( addr_i [0][9:1] ),
     .A_BM    ( bm64    ),
     .A_MEN   ( req_i   ),
     .A_WEN   ( we_i    ),
     .A_REN   ( ~we_i   ),
     .A_DIN   ( wdata64 ),
     .A_DOUT  ( rdata64 ),
     `IHP13_TC_SRAM_512x64_TIEOFF
    );
  end else if (NumWords == 2048 && DataWidth == 32 && P1L1) begin: gen_2048x32xBx1
    logic [63:0] wdata64, rdata64, bm64;
    logic sel_d, sel_q;

    // muxing neighboring bits instead of upper/lower 32bit reduces routing
    always_comb begin : gen_bit_interleaving
      for (int i = 0; i < 32; i++) begin
          // duplicate each bit
          wdata64[2*i]   = wdata_i[0][i]; // even bits (active if addr LSB is 0)
          bm64[2*i]      = bm[0][i] & ~addr_i[0][0];
          wdata64[2*i+1] = wdata_i[0][i]; // odd bits  (active if addr LSB is 1)
          bm64[2*i+1]    = bm[0][i] & addr_i[0][0];

          if(~sel_q) begin
            rdata_o[0][i] = rdata64[2*i];   // even bits
          end else begin
            rdata_o[0][i] = rdata64[2*i+1]; // odd bits
          end
      end
    end

    // LSB needed for read in next cycle
    assign sel_d = addr_i[0][0];

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_mem_sel_q
      if(~rst_ni)             sel_q <= '0;
      else if (req_i & ~we_i) sel_q <= sel_d;
    end

    RM_IHPSG13_1P_1024x64_c2_bm_bist i_cut (
     .A_CLK   ( clk_i   ),
     .A_ADDR  ( addr_i [0][10:1] ),
     .A_BM    ( bm64    ),
     .A_MEN   ( req_i   ),
     .A_WEN   ( we_i    ),
     .A_REN   ( ~we_i   ),
     .A_DIN   ( wdata64 ),
     .A_DOUT  ( rdata64 ),
     `IHP13_TC_SRAM_1024x64_TIEOFF
    );

  end else if (NumWords == 4096 && DataWidth == 32 && P1L1) begin: gen_4096x32xBx1
    logic [63:0] wdata64, rdata64, bm64;
    logic sel_d, sel_q;

    // muxing neighboring bits instead of upper/lower 32bit reduces routing
    always_comb begin : gen_bit_interleaving
      for (int i = 0; i < 32; i++) begin
          // duplicate each bit
          wdata64[2*i]   = wdata_i[0][i]; // even bits (active if addr LSB is 0)
          bm64[2*i]      = bm[0][i] & ~addr_i[0][0];
          wdata64[2*i+1] = wdata_i[0][i]; // odd bits  (active if addr LSB is 1)
          bm64[2*i+1]    = bm[0][i] & addr_i[0][0];

          if(~sel_q) begin
            rdata_o[0][i] = rdata64[2*i];   // even bits
          end else begin
            rdata_o[0][i] = rdata64[2*i+1]; // odd bits
          end
      end
    end

    // LSB needed for read in next cycle
    assign sel_d = addr_i[0][0];

    always_ff @(posedge clk_i or negedge rst_ni) begin : proc_mem_sel_q
      if(~rst_ni)             sel_q <= '0;
      else if (req_i & ~we_i) sel_q <= sel_d;
    end

    RM_IHPSG13_1P_2048x64_c2_bm_bist i_cut (
     .A_CLK   ( clk_i   ),
     .A_ADDR  ( addr_i [0][11:1] ),
     .A_BM    ( bm64    ),
     .A_MEN   ( req_i   ),
     .A_WEN   ( we_i    ),
     .A_REN   ( ~we_i   ),
     .A_DIN   ( wdata64 ),
     .A_DOUT  ( rdata64 ),
     `IHP13_TC_SRAM_2048x64_TIEOFF
    );

  end else if (NumWords == 2048 & DataWidth == 64 & P1L1) begin : gen_2048x64xBx1
    logic [63:0] wdata64, rdata64, bm64;

    assign rdata_o = rdata64;
    assign wdata64 = wdata_i;
    assign bm64    = bm;

    RM_IHPSG13_1P_2048x64_c2_bm_bist i_cut (
       .A_CLK   ( clk_i    ),
       .A_ADDR  ( addr_i [0][10:0] ),
       .A_BM    ( bm64     ),
       .A_MEN   ( req_i    ),
       .A_WEN   ( we_i     ),
       .A_REN   ( ~we_i    ),
       .A_DIN   ( wdata64  ),
       .A_DOUT  ( rdata64  ),
       `IHP13_TC_SRAM_2048x64_TIEOFF
      );

  end else if (NumWords == 1024 && DataWidth == 128 && P1L1) begin: gen_1024x128xBx1
    // Use two parallel 1024x64 SRAMs for 128-bit width
    logic [63:0] wdata64_lo, wdata64_hi;
    logic [63:0] rdata64_lo, rdata64_hi;
    logic [63:0] bm64_lo, bm64_hi;

    assign wdata64_lo = wdata_i[0][63:0];
    assign wdata64_hi = wdata_i[0][127:64];
    assign bm64_lo    = bm[0][63:0];
    assign bm64_hi    = bm[0][127:64];
    assign rdata_o = {rdata64_hi, rdata64_lo};

    RM_IHPSG13_1P_1024x64_c2_bm_bist i_cut_lo (
       .A_CLK   ( clk_i    ),
       .A_ADDR  ( addr_i [0][9:0] ),
       .A_BM    ( bm64_lo  ),
       .A_MEN   ( req_i    ),
       .A_WEN   ( we_i     ),
       .A_REN   ( ~we_i    ),
       .A_DIN   ( wdata64_lo ),
       .A_DOUT  ( rdata64_lo ),
       `IHP13_TC_SRAM_1024x64_TIEOFF
    );

    RM_IHPSG13_1P_1024x64_c2_bm_bist i_cut_hi (
       .A_CLK   ( clk_i    ),
       .A_ADDR  ( addr_i [0][9:0] ),
       .A_BM    ( bm64_hi  ),
       .A_MEN   ( req_i    ),
       .A_WEN   ( we_i     ),
       .A_REN   ( ~we_i    ),
       .A_DIN   ( wdata64_hi ),
       .A_DOUT  ( rdata64_hi ),
       `IHP13_TC_SRAM_1024x64_TIEOFF
    );

  end else begin : gen_blackbox

  `ifndef SYNTHESIS
    initial $fatal("No tc_sram for %m: NumWords %0d, DataWidth %0d NumPorts %0d, Latency %0d",
        NumWords, DataWidth, NumPorts);
  `endif

  // Instantiate a non-linkable blackbox with parameters for debugging
  `ifdef SYNTHESIS
    (* dont_touch = "true" *)
    tc_sram_blackbox #(
      .NumWords     ( NumWords    ),
      .DataWidth    ( DataWidth   ),
      .ByteWidth    ( ByteWidth   ),
      .NumPorts     ( NumPorts    ),
      .Latency      ( Latency     ),
      .SimInit      ( SimInit     ),
      .PrintSimCfg  ( PrintSimCfg ),
      .ImplKey      ( ImplKey     )
    ) i_sram_blackbox ();
  `endif

end

endmodule
