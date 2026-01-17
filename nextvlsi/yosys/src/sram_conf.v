// module rockettile_dcache_data_arrays_0_ext(
//   input  [11:0] RW0_addr,
//   input         RW0_clk,
//   input  [31:0] RW0_wdata,
//   output [31:0] RW0_rdata,
//   input         RW0_en,
//   input         RW0_wmode,
//   input  [3:0]  RW0_wmask
// );

// tc_sram #(
//     .NumWords  ( 4096 ),
//     .DataWidth ( 32   ),
//     .NumPorts  ( 1    ),
//     .Latency   ( 1    )
// ) i_sram (
//     .clk_i (RW0_clk),
//     .rst_ni (1'b1),

//     .req_i   ( RW0_en      ),  // write enable | read enable
//     .we_i    ( RW0_wmode   ),  // write enable
//     .addr_i  ( RW0_addr    ),

//     .wdata_i ( RW0_wdata   ),
//     .be_i    ( RW0_wmask   ),  // byte enable
//     .rdata_o ( RW0_rdata   )   // read data out
// );
// endmodule

// module rockettile_icache_tag_array_0_ext(
//   input  [5:0]  RW0_addr,
//   input         RW0_clk,
//   input  [20:0] RW0_wdata,
//   output [20:0] RW0_rdata,
//   input         RW0_en,
//   input         RW0_wmode
// );

// wire [64:0] rdata_o;
// tc_sram #(
//     .NumWords  ( 64   ),
//     .DataWidth ( 64   ),
//     .NumPorts  ( 1    ),
//     .Latency   ( 1    )
// ) i_sram (
//     .clk_i (RW0_clk),
//     .rst_ni (1'b1),

//     .req_i   ( RW0_en      ),  // write enable | read enable
//     .we_i    ( RW0_wmode   ),  // write enable
//     .addr_i  ( RW0_addr    ),

//     .wdata_i ( {43'b0, RW0_wdata}   ),
//     .be_i    ( 8'hff     ),  // byte enable
//     .rdata_o ( rdata_o   )   // read data out
// );
//   assign RW0_rdata = rdata_o[20:0];
  
// endmodule

// module rockettile_icache_data_arrays_0_0_ext(
//   input  [9:0]  RW0_addr,
//   input         RW0_clk,
//   input  [31:0] RW0_wdata,
//   output [31:0] RW0_rdata,
//   input         RW0_en,
//   input         RW0_wmode
// );

// tc_sram #(
//     .NumWords  ( 1024 ),
//     .DataWidth ( 32   ),
//     .NumPorts  ( 1    ),
//     .Latency   ( 1    )
// ) i_sram (
//     .clk_i (RW0_clk),
//     .rst_ni (1'b1),

//     .req_i   ( RW0_en      ),  // write enable | read enable
//     .we_i    ( RW0_wmode   ),  // write enable
//     .addr_i  ( RW0_addr    ),

//     .wdata_i ( RW0_wdata   ),
//     .be_i    ( 8'hff       ),  // byte enable
//     .rdata_o ( RW0_rdata   )   // read data out
// );
// endmodule

module rockettile_dcache_data_arrays_0(
  input  [9:0]   RW0_addr,
  input          RW0_en,
  input          RW0_clk,
  input          RW0_wmode,
  input  [127:0] RW0_wdata,
  output [127:0] RW0_rdata,
  input  [15:0]  RW0_wmask
);

tc_sram #(
    .NumWords  ( 1024 ),
    .DataWidth ( 128  ),
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

module rockettile_dcache_data_arrays_1(
  input  [9:0]   RW0_addr,
  input          RW0_en,
  input          RW0_clk,
  input          RW0_wmode,
  input  [127:0] RW0_wdata,
  output [127:0] RW0_rdata,
  input  [15:0]  RW0_wmask
);

tc_sram #(
    .NumWords  ( 1024 ),
    .DataWidth ( 128  ),
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

module rockettile_dcache_tag_array(
  input  [4:0]  RW0_addr,
  input         RW0_en,
  input         RW0_clk,
  input         RW0_wmode,
  input  [87:0] RW0_wdata,
  output [87:0] RW0_rdata,
  input  [3:0]  RW0_wmask
);

// Manual register-based implementation (no small SRAM available)
reg [87:0] mem [0:31];
reg [87:0] rdata_reg;

always @(posedge RW0_clk) begin
  if (RW0_en) begin
    if (RW0_wmode) begin
      // Write with byte mask (each mask bit controls 22 bits)
      if (RW0_wmask[0]) mem[RW0_addr][21:0]  <= RW0_wdata[21:0];
      if (RW0_wmask[1]) mem[RW0_addr][43:22] <= RW0_wdata[43:22];
      if (RW0_wmask[2]) mem[RW0_addr][65:44] <= RW0_wdata[65:44];
      if (RW0_wmask[3]) mem[RW0_addr][87:66] <= RW0_wdata[87:66];
    end else begin
      // Read
      rdata_reg <= mem[RW0_addr];
    end
  end
end

assign RW0_rdata = rdata_reg;

endmodule

module rockettile_icache_tag_array(
  input  [4:0]  RW0_addr,
  input         RW0_en,
  input         RW0_clk,
  input         RW0_wmode,
  input  [83:0] RW0_wdata,
  output [83:0] RW0_rdata,
  input  [3:0]  RW0_wmask
);

// Manual register-based implementation (no small SRAM available)
reg [83:0] mem [0:31];
reg [83:0] rdata_reg;

always @(posedge RW0_clk) begin
  if (RW0_en) begin
    if (RW0_wmode) begin
      // Write with byte mask (each mask bit controls 21 bits)
      if (RW0_wmask[0]) mem[RW0_addr][20:0]  <= RW0_wdata[20:0];
      if (RW0_wmask[1]) mem[RW0_addr][41:21] <= RW0_wdata[41:21];
      if (RW0_wmask[2]) mem[RW0_addr][62:42] <= RW0_wdata[62:42];
      if (RW0_wmask[3]) mem[RW0_addr][83:63] <= RW0_wdata[83:63];
    end else begin
      // Read
      rdata_reg <= mem[RW0_addr];
    end
  end
end

assign RW0_rdata = rdata_reg;

endmodule

module rockettile_icache_data_arrays_0(
  input  [9:0]   RW0_addr,
  input          RW0_en,
  input          RW0_clk,
  input          RW0_wmode,
  input  [127:0] RW0_wdata,
  output [127:0] RW0_rdata,
  input  [3:0]   RW0_wmask
);

tc_sram #(
    .NumWords  ( 1024 ),
    .DataWidth ( 128  ),
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

module rockettile_icache_data_arrays_1(
  input  [9:0]   RW0_addr,
  input          RW0_en,
  input          RW0_clk,
  input          RW0_wmode,
  input  [127:0] RW0_wdata,
  output [127:0] RW0_rdata,
  input  [3:0]   RW0_wmask
);

tc_sram #(
    .NumWords  ( 1024 ),
    .DataWidth ( 128  ),
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
