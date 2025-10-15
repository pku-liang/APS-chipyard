module rockettile_dcache_data_arrays_0_ext(
  input  [11:0] RW0_addr,
  input         RW0_clk,
  input  [31:0] RW0_wdata,
  output [31:0] RW0_rdata,
  input         RW0_en,
  input         RW0_wmode,
  input  [3:0]  RW0_wmask
);

tc_sram #(
    .NumWords  ( 4096 ),
    .DataWidth ( 32   ),
    .NumPorts  ( 1    ),
    .Latency   ( 1    )
) i_sram (
    .clk_i (RW0_clk),
    .rst_ni (1'b1),

    .req_i   ( RW0_en      ),  // write enable | read enable
    .we_i    ( RW0_wmode   ),  // write enable
    .addr_i  ( RW0_addr    ),

    .wdata_i ( RW0_wdata   ),
    .be_i    ( RW0_wmask   ),  // byte enable
    .rdata_o ( RW0_rdata   )   // read data out
);
endmodule

module rockettile_icache_tag_array_0_ext(
  input  [5:0]  RW0_addr,
  input         RW0_clk,
  input  [20:0] RW0_wdata,
  output [20:0] RW0_rdata,
  input         RW0_en,
  input         RW0_wmode
);

wire [64:0] rdata_o;
tc_sram #(
    .NumWords  ( 64   ),
    .DataWidth ( 64   ),
    .NumPorts  ( 1    ),
    .Latency   ( 1    )
) i_sram (
    .clk_i (RW0_clk),
    .rst_ni (1'b1),

    .req_i   ( RW0_en      ),  // write enable | read enable
    .we_i    ( RW0_wmode   ),  // write enable
    .addr_i  ( RW0_addr    ),

    .wdata_i ( {43'b0, RW0_wdata}   ),
    .be_i    ( 8'hff     ),  // byte enable
    .rdata_o ( rdata_o   )   // read data out
);
  assign RW0_rdata = rdata_o[20:0];
  
endmodule

module rockettile_icache_data_arrays_0_0_ext(
  input  [9:0]  RW0_addr,
  input         RW0_clk,
  input  [31:0] RW0_wdata,
  output [31:0] RW0_rdata,
  input         RW0_en,
  input         RW0_wmode
);

tc_sram #(
    .NumWords  ( 1024 ),
    .DataWidth ( 32   ),
    .NumPorts  ( 1    ),
    .Latency   ( 1    )
) i_sram (
    .clk_i (RW0_clk),
    .rst_ni (1'b1),

    .req_i   ( RW0_en      ),  // write enable | read enable
    .we_i    ( RW0_wmode   ),  // write enable
    .addr_i  ( RW0_addr    ),

    .wdata_i ( RW0_wdata   ),
    .be_i    ( 8'hff       ),  // byte enable
    .rdata_o ( RW0_rdata   )   // read data out
);
endmodule