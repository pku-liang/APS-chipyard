module aps_rocc_wrapper #(
  parameter TL_AW = 32,       // TileLink address width
  parameter TL_DW = 64,       // TileLink data width (beatBytes * 8)
  parameter TL_SW = 1,        // TileLink source width
  parameter TL_SINKW = 3,      // TileLink sink width
  parameter ISAX_AW = 32      // ISAX memory address width
)(
    input           clock,
    input           reset,

    //////////// ROCC COMMAND /////////////
    output          rocc_cmd_ready,
    input           rocc_cmd_valid,
    input [ 6: 0]   rocc_cmd_bits_inst_funct,
    input [ 4: 0]   rocc_cmd_bits_inst_rs2,
    input [ 4: 0]   rocc_cmd_bits_inst_rs1,
    input           rocc_cmd_bits_inst_xd,
    input           rocc_cmd_bits_inst_xs1,
    input           rocc_cmd_bits_inst_xs2,
    input [ 4: 0]   rocc_cmd_bits_inst_rd,
    input [ 6: 0]   rocc_cmd_bits_inst_opcode,
    input [31: 0]   rocc_cmd_bits_rs1,
    input [31: 0]   rocc_cmd_bits_rs2,
    input           rocc_cmd_bits_status_debug,
    input           rocc_cmd_bits_status_cease,
    input           rocc_cmd_bits_status_wfi,
    input [31: 0]   rocc_cmd_bits_status_isa,
    input [ 1: 0]   rocc_cmd_bits_status_dprv,
    input           rocc_cmd_bits_status_dv,
    input [ 1: 0]   rocc_cmd_bits_status_prv,
    input           rocc_cmd_bits_status_v,
    input           rocc_cmd_bits_status_sd,
    input [22: 0]   rocc_cmd_bits_status_zero2,
    input           rocc_cmd_bits_status_mpv,
    input           rocc_cmd_bits_status_gva,
    input           rocc_cmd_bits_status_mbe,
    input           rocc_cmd_bits_status_sbe,
    input [ 1: 0]   rocc_cmd_bits_status_sxl,
    input [ 1: 0]   rocc_cmd_bits_status_uxl,
    input           rocc_cmd_bits_status_sd_rv32,
    input [ 7: 0]   rocc_cmd_bits_status_zero1,
    input           rocc_cmd_bits_status_tsr,
    input           rocc_cmd_bits_status_tw,
    input           rocc_cmd_bits_status_tvm,
    input           rocc_cmd_bits_status_mxr,
    input           rocc_cmd_bits_status_sum,
    input           rocc_cmd_bits_status_mprv,
    input [ 1: 0]   rocc_cmd_bits_status_xs,
    input [ 1: 0]   rocc_cmd_bits_status_fs,
    input [ 1: 0]   rocc_cmd_bits_status_vs,
    input [ 1: 0]   rocc_cmd_bits_status_mpp,
    input           rocc_cmd_bits_status_spp,
    input           rocc_cmd_bits_status_mpie,
    input           rocc_cmd_bits_status_ube,
    input           rocc_cmd_bits_status_spie,
    input           rocc_cmd_bits_status_upie,
    input           rocc_cmd_bits_status_mie,
    input           rocc_cmd_bits_status_hie,
    input           rocc_cmd_bits_status_sie,
    input           rocc_cmd_bits_status_uie,
    /////////////////// ROCC RESPONSE ///////////////
    input           rocc_resp_ready,
    output          rocc_resp_valid,
    output [ 4: 0]  rocc_resp_bits_rd,
    output [31: 0]  rocc_resp_bits_data,
    /////////////////// ROCC MEM REQ ////////////////
    input           rocc_mem_req_ready,
    output          rocc_mem_req_valid,
    output [31: 0]  rocc_mem_req_bits_addr,
    output [ 6: 0]  rocc_mem_req_bits_tag,
    output [ 4: 0]  rocc_mem_req_bits_cmd,
    output [ 1: 0]  rocc_mem_req_bits_size,
    output          rocc_mem_req_bits_signed,
    output          rocc_mem_req_bits_phys,
    output          rocc_mem_req_bits_no_alloc,
    output          rocc_mem_req_bits_no_xcpt,
    output          rocc_mem_req_bits_no_resp,
    output [ 1: 0]  rocc_mem_req_bits_dprv,
    output          rocc_mem_req_bits_dv,
    output [31: 0]  rocc_mem_req_bits_data,
    output [ 3: 0]  rocc_mem_req_bits_mask,
    output          rocc_mem_s1_kill,
    output [31: 0]  rocc_mem_s1_data_data,
    output [ 3: 0]  rocc_mem_s1_data_mask,
    input           rocc_mem_s2_nack,
    input           rocc_mem_s2_nack_cause_raw,
    output          rocc_mem_s2_kill,
    input           rocc_mem_s2_uncached,
    input [31: 0]   rocc_mem_s2_paddr,
    input [31: 0]   rocc_mem_s2_gpa,
    input           rocc_mem_s2_gpa_is_pte,
    input           rocc_mem_resp_valid,
    input [31: 0]   rocc_mem_resp_bits_addr,
    input [ 6: 0]   rocc_mem_resp_bits_tag,
    input [ 4: 0]   rocc_mem_resp_bits_cmd,
    input [ 1: 0]   rocc_mem_resp_bits_size,
    input           rocc_mem_resp_bits_signed,
    input [31: 0]   rocc_mem_resp_bits_data,
    input [ 3: 0]   rocc_mem_resp_bits_mask,
    input           rocc_mem_resp_bits_replay,
    input           rocc_mem_resp_bits_has_data,
    input [31: 0]   rocc_mem_resp_bits_data_word_bypass,
    input [31: 0]   rocc_mem_resp_bits_data_raw,
    input [31: 0]   rocc_mem_resp_bits_store_data,
    input [ 1: 0]   rocc_mem_resp_bits_dprv,
    input           rocc_mem_resp_bits_dv,
    input           rocc_mem_replay_next,
    input           rocc_mem_s2_xcpt_ma_ld,
    input           rocc_mem_s2_xcpt_ma_st,
    input           rocc_mem_s2_xcpt_pf_ld,
    input           rocc_mem_s2_xcpt_pf_st,
    input           rocc_mem_s2_xcpt_gf_ld,
    input           rocc_mem_s2_xcpt_gf_st,
    input           rocc_mem_s2_xcpt_ae_ld,
    input           rocc_mem_s2_xcpt_ae_st,
    input           rocc_mem_ordered,
    input           rocc_mem_store_pending,
    input           rocc_mem_perf_acquire,
    input           rocc_mem_perf_release,
    input           rocc_mem_perf_grant,
    input           rocc_mem_perf_tlbMiss,
    input           rocc_mem_perf_blocked,
    input           rocc_mem_perf_canAcceptStoreThenLoad,
    input           rocc_mem_perf_canAcceptStoreThenRMW,
    input           rocc_mem_perf_canAcceptLoadThenLoad,
    input           rocc_mem_perf_storeBufferEmptyAfterLoad,
    input           rocc_mem_perf_storeBufferEmptyAfterStore,
    output          rocc_mem_keep_clock_enabled,
    input           rocc_mem_clock_enabled,

    //////////////////// ROCC AUX ////////////////////////////
    output          rocc_busy,


    // ========================================
    // TileLink A Channel (DMA Requests)
    // NOTE: Port names have 'dma_' prefix due to nested Bundle structure in Chisel
    // ========================================
    output logic        dma_tl_a_valid,
    input  logic        dma_tl_a_ready,
    output logic [2:0]  dma_tl_a_bits_opcode,
    output logic [2:0]  dma_tl_a_bits_param,
    output logic [3:0]  dma_tl_a_bits_size,
    output logic [TL_SW-1:0] dma_tl_a_bits_source,
    output logic [TL_AW-1:0] dma_tl_a_bits_address,
    output logic [TL_DW/8-1:0] dma_tl_a_bits_mask,
    output logic [TL_DW-1:0] dma_tl_a_bits_data,
    output logic        dma_tl_a_bits_corrupt,

    // ========================================
    // TileLink D Channel (DMA Responses)
    // ========================================
    input  logic        dma_tl_d_valid,
    output logic        dma_tl_d_ready,
    input  logic [2:0]  dma_tl_d_bits_opcode,
    input  logic [1:0]  dma_tl_d_bits_param,
    input  logic [3:0]  dma_tl_d_bits_size,
    input  logic [TL_SW-1:0] dma_tl_d_bits_source,
    input  logic [TL_SINKW-1:0] dma_tl_d_bits_sink,
    input  logic        dma_tl_d_bits_denied,
    input  logic [TL_DW-1:0] dma_tl_d_bits_data,
    input  logic        dma_tl_d_bits_corrupt
  );

  // DMA ISAX memory interface signals
  logic [ISAX_AW-1:0] dma_isax_mem_addr;
  logic dma_isax_mem_wvalid;
  logic dma_isax_mem_rvalid0;
  logic dma_isax_mem_rvalid1;
  logic [TL_DW-1:0] dma_isax_mem_wdata;
  logic [TL_DW-1:0] dma_isax_mem_rdata;


  // Instantiate multi-channel TileLink DMA
  // Channel 0: connected to aps_module
  // Channel 1: tied off (disabled)
  localparam N_CH = 2;

  // Per-channel config arrays
  logic [N_CH-1:0][TL_AW-1:0] cfg_write_cpu_addr  ;
  logic [N_CH-1:0][TL_AW-1:0] cfg_write_isax_addr ;
  logic [N_CH-1:0][TL_AW-1:0] cfg_read_cpu_addr   ;
  logic [N_CH-1:0][TL_AW-1:0] cfg_read_isax_addr  ;
  logic [N_CH-1:0][3:0]       cfg_read_length     ;
  logic [N_CH-1:0][3:0]       cfg_write_length    ;
  logic [N_CH-1:0][7:0]       cfg_read_stride_x   ;
  logic [N_CH-1:0][7:0]       cfg_read_stride_y   ;
  logic [N_CH-1:0][7:0]       cfg_write_stride_x  ;
  logic [N_CH-1:0][7:0]       cfg_write_stride_y  ;
  logic [N_CH-1:0]            cfg_write_en        ;
  logic [N_CH-1:0]            cfg_read_en         ;
  logic [N_CH-1:0]            ch_idle             ;
  logic [N_CH-1:0]            ch_idle_ready       ;

  aps_module #(
    .ISAX_AW(ISAX_AW)
  ) u_aps_module (
    .clock(clock),
    .reset(reset),
    .rocc_cmd_ready(rocc_cmd_ready),
    .rocc_cmd_valid(rocc_cmd_valid),
    .rocc_cmd_bits_inst_funct(rocc_cmd_bits_inst_funct),
    .rocc_cmd_bits_inst_rs2(rocc_cmd_bits_inst_rs2),
    .rocc_cmd_bits_inst_rs1(rocc_cmd_bits_inst_rs1),
    .rocc_cmd_bits_inst_xd(rocc_cmd_bits_inst_xd),
    .rocc_cmd_bits_inst_xs1(rocc_cmd_bits_inst_xs1),
    .rocc_cmd_bits_inst_xs2(rocc_cmd_bits_inst_xs2),
    .rocc_cmd_bits_inst_rd(rocc_cmd_bits_inst_rd),
    .rocc_cmd_bits_inst_opcode(rocc_cmd_bits_inst_opcode),
    .rocc_cmd_bits_rs1(rocc_cmd_bits_rs1),
    .rocc_cmd_bits_rs2(rocc_cmd_bits_rs2),
    .rocc_resp_ready(rocc_resp_ready),
    .rocc_resp_valid(rocc_resp_valid),
    .rocc_resp_bits_rd(rocc_resp_bits_rd),
    .rocc_resp_bits_data(rocc_resp_bits_data),
    .rocc_mem_req_ready(rocc_mem_req_ready),
    .rocc_mem_req_valid(rocc_mem_req_valid),
    .rocc_mem_req_bits_addr(rocc_mem_req_bits_addr),
    .rocc_mem_req_bits_tag(rocc_mem_req_bits_tag),
    .rocc_mem_req_bits_cmd(rocc_mem_req_bits_cmd),
    .rocc_mem_req_bits_size(rocc_mem_req_bits_size),
    .rocc_mem_req_bits_signed(rocc_mem_req_bits_signed),
    .rocc_mem_req_bits_phys(rocc_mem_req_bits_phys),
    .rocc_mem_req_bits_data(rocc_mem_req_bits_data),
    .rocc_mem_req_bits_mask(rocc_mem_req_bits_mask),
    .rocc_mem_resp_valid(rocc_mem_resp_valid),
    .rocc_mem_resp_bits_addr(rocc_mem_resp_bits_addr),
    .rocc_mem_resp_bits_tag(rocc_mem_resp_bits_tag),
    .rocc_mem_resp_bits_cmd(rocc_mem_resp_bits_cmd),
    .rocc_mem_resp_bits_size(rocc_mem_resp_bits_size),
    .rocc_mem_resp_bits_signed(rocc_mem_resp_bits_signed),
    .rocc_mem_resp_bits_data(rocc_mem_resp_bits_data),
    .rocc_mem_resp_bits_mask(rocc_mem_resp_bits_mask),
    .rocc_busy(rocc_busy),

    // Burst interface - connect to DMA ISAX memory interface
    // burst_read: CPU->ISAX transfer, DMA writes data to ISAX (main reads from burst)
    .burst_read_0_addr(dma_isax_mem_addr),
    .burst_read_0_enable(dma_isax_mem_rvalid0),     // DMA ready to provide read data
    .burst_read_0_ready(/* unused */),      // Main ready to accept write (not used correctly, output from main)
    .burst_read_1_res0(dma_isax_mem_rdata),
    .burst_read_1_enable(dma_isax_mem_rvalid1),     // DMA ready to provide read data
    .burst_read_1_ready(/* unused */),      // Main ready to accept write (not used correctly, output from main)
    // burst_write: ISAX->CPU transfer, DMA reads data from ISAX (main writes to burst)
    .burst_write_addr(dma_isax_mem_addr),
    .burst_write_data(dma_isax_mem_wdata),
    .burst_write_enable(dma_isax_mem_wvalid),    // DMA ready to accept write data
    .burst_write_ready(/* unused */),     // Main ready to provide read (not used correctly, output from main)

    // DMA control interface - connect to DMA controller
    // CPU->ISAX Channel 0: read from CPU memory, write to ISAX memory (read_en triggers DMA GET)
    .dma_cpu_to_isax_ch0_cpu_addr(cfg_read_cpu_addr[0]),
    .dma_cpu_to_isax_ch0_isax_addr(cfg_read_isax_addr[0]),
    .dma_cpu_to_isax_ch0_length(cfg_read_length[0]),
    .dma_cpu_to_isax_ch0_stride_x(cfg_read_stride_x[0]),
    .dma_cpu_to_isax_ch0_stride_y(cfg_read_stride_y[0]),
    .dma_cpu_to_isax_ch0_ready(ch_idle[0]),
    .dma_cpu_to_isax_ch0_enable(cfg_read_en[0]),
    // ISAX->CPU Channel 0: read from ISAX memory, write to CPU memory (write_en triggers DMA PUT)
    .dma_isax_to_cpu_ch0_cpu_addr(cfg_write_cpu_addr[0]),
    .dma_isax_to_cpu_ch0_isax_addr(cfg_write_isax_addr[0]),
    .dma_isax_to_cpu_ch0_length(cfg_write_length[0]),
    .dma_isax_to_cpu_ch0_stride_x(cfg_write_stride_x[0]),
    .dma_isax_to_cpu_ch0_stride_y(cfg_write_stride_y[0]),
    .dma_isax_to_cpu_ch0_ready(ch_idle[0]),
    .dma_isax_to_cpu_ch0_enable(cfg_write_en[0]),

    // CPU->ISAX Channel 1: read from CPU memory, write to ISAX memory (read_en triggers DMA GET)
    .dma_cpu_to_isax_ch1_cpu_addr(cfg_read_cpu_addr[1]),
    .dma_cpu_to_isax_ch1_isax_addr(cfg_read_isax_addr[1]),
    .dma_cpu_to_isax_ch1_length(cfg_read_length[1]),
    .dma_cpu_to_isax_ch1_stride_x(cfg_read_stride_x[1]),
    .dma_cpu_to_isax_ch1_stride_y(cfg_read_stride_y[1]),
    .dma_cpu_to_isax_ch1_ready(ch_idle[1]),
    .dma_cpu_to_isax_ch1_enable(cfg_read_en[1]),
    // ISAX->CPU Channel 1: read from ISAX memory, write to CPU memory (write_en triggers DMA PUT)
    .dma_isax_to_cpu_ch1_cpu_addr(cfg_write_cpu_addr[1]),
    .dma_isax_to_cpu_ch1_isax_addr(cfg_write_isax_addr[1]),
    .dma_isax_to_cpu_ch1_length(cfg_write_length[1]),
    .dma_isax_to_cpu_ch1_stride_x(cfg_write_stride_x[1]),
    .dma_isax_to_cpu_ch1_stride_y(cfg_write_stride_y[1]),
    .dma_isax_to_cpu_ch1_ready(ch_idle[1]),
    .dma_isax_to_cpu_ch1_enable(cfg_write_en[1]),

    // Poll for idle - Channel 0
    .dma_poll_for_idle_ch0_ready(ch_idle[0]),      // ready = idle status
    .dma_poll_for_idle_ch0_res0(1'b1),             // res0 = always 1
    // Poll for idle - Channel 1
    .dma_poll_for_idle_ch1_ready(ch_idle[1]),      // ready = idle status
    .dma_poll_for_idle_ch1_res0(1'b1)              // res0 = always 1
  );

  tl_dma_multichannel #(
    .TL_AW(TL_AW),
    .TL_DW(TL_DW),
    .TL_SW(TL_SW),
    .TL_SINKW(TL_SINKW),
    .N_CH(N_CH),
    .ISAX_AW(ISAX_AW)
  ) u_tilelink_dma (
    .clock(clock),
    .reset(reset),

    // Control interface (per-channel arrays)
    .cfg_write_cpu_addr(cfg_write_cpu_addr),
    .cfg_write_isax_addr(cfg_write_isax_addr),
    .cfg_read_cpu_addr(cfg_read_cpu_addr),
    .cfg_read_isax_addr(cfg_read_isax_addr),
    .cfg_read_length(cfg_read_length),
    .cfg_write_length(cfg_write_length),
    .cfg_read_stride_x(cfg_read_stride_x),
    .cfg_read_stride_y(cfg_read_stride_y),
    .cfg_write_stride_x(cfg_write_stride_x),
    .cfg_write_stride_y(cfg_write_stride_y),
    .cfg_write_en(cfg_write_en),
    .cfg_read_en(cfg_read_en),
    .ch_idle(ch_idle),
    .ch_idle_ready(ch_idle_ready),

    // ISAX memory interface
    .isax_mem_addr(dma_isax_mem_addr),
    .isax_mem_wvalid(dma_isax_mem_wvalid),
    .isax_mem_rvalid0(dma_isax_mem_rvalid0),
    .isax_mem_rvalid1(dma_isax_mem_rvalid1),
    .isax_mem_wdata(dma_isax_mem_wdata),
    .isax_mem_rdata(dma_isax_mem_rdata),

    // TileLink A Channel
    .dma_tl_a_valid(dma_tl_a_valid),
    .dma_tl_a_ready(dma_tl_a_ready),
    .dma_tl_a_bits_opcode(dma_tl_a_bits_opcode),
    .dma_tl_a_bits_param(dma_tl_a_bits_param),
    .dma_tl_a_bits_size(dma_tl_a_bits_size),
    .dma_tl_a_bits_source(dma_tl_a_bits_source),
    .dma_tl_a_bits_address(dma_tl_a_bits_address),
    .dma_tl_a_bits_mask(dma_tl_a_bits_mask),
    .dma_tl_a_bits_data(dma_tl_a_bits_data),
    .dma_tl_a_bits_corrupt(dma_tl_a_bits_corrupt),

    // TileLink D Channel
    .dma_tl_d_valid(dma_tl_d_valid),
    .dma_tl_d_ready(dma_tl_d_ready),
    .dma_tl_d_bits_opcode(dma_tl_d_bits_opcode),
    .dma_tl_d_bits_param(dma_tl_d_bits_param),
    .dma_tl_d_bits_size(dma_tl_d_bits_size),
    .dma_tl_d_bits_source(dma_tl_d_bits_source),
    .dma_tl_d_bits_sink(dma_tl_d_bits_sink),
    .dma_tl_d_bits_denied(dma_tl_d_bits_denied),
    .dma_tl_d_bits_data(dma_tl_d_bits_data),
    .dma_tl_d_bits_corrupt(dma_tl_d_bits_corrupt)
  );


  assign rocc_mem_req_bits_no_alloc = 'd0;
  assign rocc_mem_req_bits_no_xcpt = 'd0;
  assign rocc_mem_req_bits_no_resp = 'd0;
  assign rocc_mem_req_bits_dprv = 2'b11;
  assign rocc_mem_req_bits_dv = rocc_cmd_bits_status_dv;
  assign rocc_mem_s1_kill = 'd0;
  assign rocc_mem_s1_data_data = 'd0;
  assign rocc_mem_s1_data_mask = 'd0;
  assign rocc_mem_s2_kill = 'd0;
  assign rocc_mem_keep_clock_enabled = 'd1;

endmodule

module aps_module #(
  parameter ISAX_AW = 32      // ISAX memory address width
) (
    input                                clock,
    input                                reset,

    //////////// ROCC COMMAND /////////////
    output          rocc_cmd_ready,
    input           rocc_cmd_valid,
    input [ 6: 0]   rocc_cmd_bits_inst_funct,
    input [ 4: 0]   rocc_cmd_bits_inst_rs2,
    input [ 4: 0]   rocc_cmd_bits_inst_rs1,
    input           rocc_cmd_bits_inst_xd,
    input           rocc_cmd_bits_inst_xs1,
    input           rocc_cmd_bits_inst_xs2,
    input [ 4: 0]   rocc_cmd_bits_inst_rd,
    input [ 6: 0]   rocc_cmd_bits_inst_opcode,
    input [31: 0]   rocc_cmd_bits_rs1,
    input [31: 0]   rocc_cmd_bits_rs2,
    /////////////////// ROCC RESPONSE ///////////////
    input           rocc_resp_ready,
    output          rocc_resp_valid,
    output [ 4: 0]  rocc_resp_bits_rd,
    output [31: 0]  rocc_resp_bits_data,
    /////////////////// ROCC MEM REQ ////////////////
    input           rocc_mem_req_ready,
    output          rocc_mem_req_valid,
    output [31: 0]  rocc_mem_req_bits_addr,
    output [ 6: 0]  rocc_mem_req_bits_tag,
    output [ 4: 0]  rocc_mem_req_bits_cmd,
    output [ 1: 0]  rocc_mem_req_bits_size,
    output          rocc_mem_req_bits_signed,
    output          rocc_mem_req_bits_phys,
    output [31: 0]  rocc_mem_req_bits_data,
    output [ 3: 0]  rocc_mem_req_bits_mask,
    /////////////////// ROCC MEM RESP /////////////////////
    input           rocc_mem_resp_valid,
    input [31: 0]   rocc_mem_resp_bits_addr,
    input [ 6: 0]   rocc_mem_resp_bits_tag,
    input [ 4: 0]   rocc_mem_resp_bits_cmd,
    input [ 1: 0]   rocc_mem_resp_bits_size,
    input           rocc_mem_resp_bits_signed,
    input [31: 0]   rocc_mem_resp_bits_data,
    input [ 3: 0]   rocc_mem_resp_bits_mask,
    //////////////////// ROCC AUX ////////////////////////////
    output          rocc_busy,

    // ========================================
    // Burst Read/Write Interface
    // ========================================
    input  logic [31:0] burst_read_0_addr,
    input  logic        burst_read_0_enable,
    output logic        burst_read_0_ready,
    output logic [63:0] burst_read_1_res0,
    input  logic        burst_read_1_enable,
    output logic        burst_read_1_ready,
    input  logic [31:0] burst_write_addr,
    input  logic [63:0] burst_write_data,
    input  logic        burst_write_enable,
    output logic        burst_write_ready,

    // ========================================
    // DMA Control Interface (CPU to ISAX)
    // ========================================
    output logic [31:0] dma_cpu_to_isax_ch0_cpu_addr,
    output logic [ISAX_AW-1:0] dma_cpu_to_isax_ch0_isax_addr,
    output logic [3:0]  dma_cpu_to_isax_ch0_length,
    output logic [7:0]  dma_cpu_to_isax_ch0_stride_x,
    output logic [7:0]  dma_cpu_to_isax_ch0_stride_y,
    input  logic        dma_cpu_to_isax_ch0_ready,
    output logic        dma_cpu_to_isax_ch0_enable,

    // ========================================
    // DMA Control Interface (ISAX to CPU)
    // ========================================
    output logic [31:0] dma_isax_to_cpu_ch0_cpu_addr,
    output logic [ISAX_AW-1:0] dma_isax_to_cpu_ch0_isax_addr,
    output logic [3:0]  dma_isax_to_cpu_ch0_length,
    output logic [7:0]  dma_isax_to_cpu_ch0_stride_x,
    output logic [7:0]  dma_isax_to_cpu_ch0_stride_y,
    input  logic        dma_isax_to_cpu_ch0_ready,
    output logic        dma_isax_to_cpu_ch0_enable,

    // ========================================
    // DMA Poll for Idle
    // ========================================
    input  logic        dma_poll_for_idle_ch0_ready,
    input  logic        dma_poll_for_idle_ch0_res0,


    // ========================================
    // DMA Control Interface (CPU to ISAX)
    // ========================================
    output logic [31:0] dma_cpu_to_isax_ch1_cpu_addr,
    output logic [ISAX_AW-1:0] dma_cpu_to_isax_ch1_isax_addr,
    output logic [3:0]  dma_cpu_to_isax_ch1_length,
    output logic [7:0]  dma_cpu_to_isax_ch1_stride_x,
    output logic [7:0]  dma_cpu_to_isax_ch1_stride_y,
    input  logic        dma_cpu_to_isax_ch1_ready,
    output logic        dma_cpu_to_isax_ch1_enable,

    // ========================================
    // DMA Control Interface (ISAX to CPU)
    // ========================================
    output logic [31:0] dma_isax_to_cpu_ch1_cpu_addr,
    output logic [ISAX_AW-1:0] dma_isax_to_cpu_ch1_isax_addr,
    output logic [3:0]  dma_isax_to_cpu_ch1_length,
    output logic [7:0]  dma_isax_to_cpu_ch1_stride_x,
    output logic [7:0]  dma_isax_to_cpu_ch1_stride_y,
    input  logic        dma_isax_to_cpu_ch1_ready,
    output logic        dma_isax_to_cpu_ch1_enable,

    // ========================================
    // DMA Poll for Idle
    // ========================================
    input  logic        dma_poll_for_idle_ch1_ready,
    input  logic        dma_poll_for_idle_ch1_res0
);

  // Internal signals for main module to FIFO
  logic        main_mem_req_valid;
  logic        main_mem_req_ready;
  logic [31:0] main_mem_req_bits_addr;
  logic [ 6:0] main_mem_req_bits_tag;
  logic [ 4:0] main_mem_req_bits_cmd;
  logic [ 1:0] main_mem_req_bits_size;
  logic        main_mem_req_bits_signed;
  logic        main_mem_req_bits_phys;
  logic [31:0] main_mem_req_bits_data;
  logic [ 3:0] main_mem_req_bits_mask;

  main u_main(
    .clk                                      ( clock                         ),
    .rst                                      ( reset                         ),

    // RoCC command interface
    .rocc_cmd_rocc_cmd_funct                  ( rocc_cmd_bits_inst_funct      ),
    .rocc_cmd_rocc_cmd_opcode                 ( rocc_cmd_bits_inst_opcode     ),
    .rocc_cmd_rocc_cmd_rd                     ( rocc_cmd_bits_inst_rd         ),
    .rocc_cmd_rocc_cmd_rs1                    ( rocc_cmd_bits_inst_rs1        ),
    .rocc_cmd_rocc_cmd_rs1data                ( rocc_cmd_bits_rs1             ),
    .rocc_cmd_rocc_cmd_rs2                    ( rocc_cmd_bits_inst_rs2        ),
    .rocc_cmd_rocc_cmd_rs2data                ( rocc_cmd_bits_rs2             ),
    .rocc_cmd_rocc_cmd_xd                     ( rocc_cmd_bits_inst_xd         ),
    .rocc_cmd_rocc_cmd_xs1                    ( rocc_cmd_bits_inst_xs1        ),
    .rocc_cmd_rocc_cmd_xs2                    ( rocc_cmd_bits_inst_xs2        ),
    .rocc_cmd_enable                          ( rocc_cmd_valid                ),
    .rocc_cmd_ready                           ( rocc_cmd_ready                ),

    // RoCC response interface
    .rocc_resp_rocc_resp_to_bus_result_rd     ( rocc_resp_bits_rd             ),
    .rocc_resp_rocc_resp_to_bus_result_rddata ( rocc_resp_bits_data           ),
    .rocc_resp_rocc_resp_to_bus_enable        ( rocc_resp_valid               ),
    .rocc_resp_rocc_resp_to_bus_ready         ( rocc_resp_ready               ),

    // Hella command interface (now connects to FIFO input)
    .hella_cmd_hella_cmd_to_bus_cmd_addr      ( main_mem_req_bits_addr        ),
    .hella_cmd_hella_cmd_to_bus_cmd_cmd       ( main_mem_req_bits_cmd         ),
    .hella_cmd_hella_cmd_to_bus_cmd_data      ( main_mem_req_bits_data        ),
    .hella_cmd_hella_cmd_to_bus_cmd_mask      ( main_mem_req_bits_mask        ),
    .hella_cmd_hella_cmd_to_bus_cmd_phys      ( main_mem_req_bits_phys        ),
    .hella_cmd_hella_cmd_to_bus_cmd_signed    ( main_mem_req_bits_signed      ),
    .hella_cmd_hella_cmd_to_bus_cmd_size      ( main_mem_req_bits_size        ),
    .hella_cmd_hella_cmd_to_bus_cmd_tag       ( main_mem_req_bits_tag         ),
    .hella_cmd_hella_cmd_to_bus_enable        ( main_mem_req_valid            ),
    .hella_cmd_hella_cmd_to_bus_ready         ( main_mem_req_ready            ),

    // Hella response interface
    .hella_resp_hella_resp_data               ( rocc_mem_resp_bits_data       ),
    .hella_resp_hella_resp_cmd                ( rocc_mem_resp_bits_cmd        ),
    .hella_resp_hella_resp_size               ( rocc_mem_resp_bits_size       ),
    .hella_resp_hella_resp_signed             ( rocc_mem_resp_bits_signed     ),
    .hella_resp_hella_resp_tag                ( rocc_mem_resp_bits_tag        ),
    .hella_resp_enable                        ( rocc_mem_resp_valid           ),
    .hella_resp_ready                         ( /* unused */                  ),

    // Burst interface - pass through to aps_module ports
    .burst_read_0_addr                          ( burst_read_0_addr               ),
    .burst_read_0_enable                        ( burst_read_0_enable             ),
    .burst_read_0_ready                         ( burst_read_0_ready              ),
    .burst_read_1_res0                          ( burst_read_1_res0               ),
    .burst_read_1_enable                        ( burst_read_1_enable             ),
    .burst_read_1_ready                         ( burst_read_1_ready              ),
    .burst_write_addr                         ( burst_write_addr              ),
    .burst_write_data                         ( burst_write_data              ),
    .burst_write_enable                       ( burst_write_enable            ),
    .burst_write_ready                        ( burst_write_ready             ),

    // DMA control interface - pass through to aps_module ports
    .dma_cpu_to_isax_ch0_cpu_addr                 ( dma_cpu_to_isax_ch0_cpu_addr      ),
    .dma_cpu_to_isax_ch0_isax_addr                ( dma_cpu_to_isax_ch0_isax_addr     ),
    .dma_cpu_to_isax_ch0_length                   ( dma_cpu_to_isax_ch0_length        ),
    .dma_cpu_to_isax_ch0_stride_x                 ( dma_cpu_to_isax_ch0_stride_x      ),
    .dma_cpu_to_isax_ch0_stride_y                 ( dma_cpu_to_isax_ch0_stride_y      ),
    .dma_cpu_to_isax_ch0_ready                    ( dma_cpu_to_isax_ch0_ready         ),
    .dma_cpu_to_isax_ch0_enable                   ( dma_cpu_to_isax_ch0_enable        ),
    .dma_isax_to_cpu_ch0_cpu_addr                 ( dma_isax_to_cpu_ch0_cpu_addr      ),
    .dma_isax_to_cpu_ch0_isax_addr                ( dma_isax_to_cpu_ch0_isax_addr     ),
    .dma_isax_to_cpu_ch0_length                   ( dma_isax_to_cpu_ch0_length        ),
    .dma_isax_to_cpu_ch0_stride_x                 ( dma_isax_to_cpu_ch0_stride_x      ),
    .dma_isax_to_cpu_ch0_stride_y                 ( dma_isax_to_cpu_ch0_stride_y      ),
    .dma_isax_to_cpu_ch0_ready                    ( dma_isax_to_cpu_ch0_ready         ),
    .dma_isax_to_cpu_ch0_enable                   ( dma_isax_to_cpu_ch0_enable        ),

    // Poll for idle - internal only, not exposed to wrapper
    .dma_poll_for_idle_ch0_res0                   ( dma_poll_for_idle_ch0_res0        ),
    .dma_poll_for_idle_ch0_ready                  ( dma_poll_for_idle_ch0_ready       ),

    // DMA control interface - pass through to aps_module ports
    .dma_cpu_to_isax_ch1_cpu_addr                 ( dma_cpu_to_isax_ch1_cpu_addr      ),
    .dma_cpu_to_isax_ch1_isax_addr                ( dma_cpu_to_isax_ch1_isax_addr     ),
    .dma_cpu_to_isax_ch1_length                   ( dma_cpu_to_isax_ch1_length        ),
    .dma_cpu_to_isax_ch1_stride_x                 ( dma_cpu_to_isax_ch1_stride_x      ),
    .dma_cpu_to_isax_ch1_stride_y                 ( dma_cpu_to_isax_ch1_stride_y      ),
    .dma_cpu_to_isax_ch1_ready                    ( dma_cpu_to_isax_ch1_ready         ),
    .dma_cpu_to_isax_ch1_enable                   ( dma_cpu_to_isax_ch1_enable        ),
    .dma_isax_to_cpu_ch1_cpu_addr                 ( dma_isax_to_cpu_ch1_cpu_addr      ),
    .dma_isax_to_cpu_ch1_isax_addr                ( dma_isax_to_cpu_ch1_isax_addr     ),
    .dma_isax_to_cpu_ch1_length                   ( dma_isax_to_cpu_ch1_length        ),
    .dma_isax_to_cpu_ch1_stride_x                 ( dma_isax_to_cpu_ch1_stride_x      ),
    .dma_isax_to_cpu_ch1_stride_y                 ( dma_isax_to_cpu_ch1_stride_y      ),
    .dma_isax_to_cpu_ch1_ready                    ( dma_isax_to_cpu_ch1_ready         ),
    .dma_isax_to_cpu_ch1_enable                   ( dma_isax_to_cpu_ch1_enable        ),

    // Poll for idle - internal only, not exposed to wrapper
    .dma_poll_for_idle_ch1_res0                   ( dma_poll_for_idle_ch1_res0        ),
    .dma_poll_for_idle_ch1_ready                  ( dma_poll_for_idle_ch1_ready       )
  );

  // Hella command FIFO to break combinational loop
  hella_cmd_fifo u_hella_cmd_fifo (
    .clock(clock),
    .reset(reset),

    // Input from main module
    .in_valid(main_mem_req_valid),
    .in_ready(main_mem_req_ready),
    .in_bits_addr(main_mem_req_bits_addr),
    .in_bits_tag(main_mem_req_bits_tag),
    .in_bits_cmd(main_mem_req_bits_cmd),
    .in_bits_size(main_mem_req_bits_size),
    .in_bits_signed(main_mem_req_bits_signed),
    .in_bits_phys(main_mem_req_bits_phys),
    .in_bits_data(main_mem_req_bits_data),
    .in_bits_mask(main_mem_req_bits_mask),

    // Output to RoCC mem interface
    .out_valid(rocc_mem_req_valid),
    .out_ready(rocc_mem_req_ready),
    .out_bits_addr(rocc_mem_req_bits_addr),
    .out_bits_tag(rocc_mem_req_bits_tag),
    .out_bits_cmd(rocc_mem_req_bits_cmd),
    .out_bits_size(rocc_mem_req_bits_size),
    .out_bits_signed(rocc_mem_req_bits_signed),
    .out_bits_phys(rocc_mem_req_bits_phys),
    .out_bits_data(rocc_mem_req_bits_data),
    .out_bits_mask(rocc_mem_req_bits_mask)
  );

  reg rocc_busy_reg;
  always @(posedge clock) begin
    if (reset) begin
      rocc_busy_reg <= 1'b0;
    end
    else begin
      if (rocc_cmd_valid && rocc_cmd_ready) begin
        rocc_busy_reg <= 1'b1;
      end
      else if (rocc_resp_valid && rocc_resp_ready) begin
        rocc_busy_reg <= 1'b0;
      end
    end
  end
  assign rocc_busy = rocc_busy_reg;

endmodule

// ============================================================================
// FIFO for Hella Command Interface
// 2-entry FIFO to break combinational loops between valid and ready
// ============================================================================
module hella_cmd_fifo (
  input  logic        clock,
  input  logic        reset,

  // Input interface
  input  logic        in_valid,
  output logic        in_ready,
  input  logic [31:0] in_bits_addr,
  input  logic [ 6:0] in_bits_tag,
  input  logic [ 4:0] in_bits_cmd,
  input  logic [ 1:0] in_bits_size,
  input  logic        in_bits_signed,
  input  logic        in_bits_phys,
  input  logic [31:0] in_bits_data,
  input  logic [ 3:0] in_bits_mask,

  // Output interface
  output logic        out_valid,
  input  logic        out_ready,
  output logic [31:0] out_bits_addr,
  output logic [ 6:0] out_bits_tag,
  output logic [ 4:0] out_bits_cmd,
  output logic [ 1:0] out_bits_size,
  output logic        out_bits_signed,
  output logic        out_bits_phys,
  output logic [31:0] out_bits_data,
  output logic [ 3:0] out_bits_mask
);

  // FIFO storage (2 entries) - separate arrays for tool compatibility
  logic [31:0] fifo_addr [2];
  logic [ 6:0] fifo_tag  [2];
  logic [ 4:0] fifo_cmd  [2];
  logic [ 1:0] fifo_size [2];
  logic        fifo_signed [2];
  logic        fifo_phys [2];
  logic [31:0] fifo_data [2];
  logic [ 3:0] fifo_mask [2];

  logic [1:0] count;  // 0, 1, or 2 entries

  // Write and read pointers
  logic wr_ptr;
  logic rd_ptr;

  // Handshake signals
  logic do_enq;
  logic do_deq;

  assign do_enq = in_valid && in_ready;
  assign do_deq = out_valid && out_ready;

  // FIFO full/empty logic
  assign in_ready = (count < 2'd2);
  assign out_valid = (count > 2'd0);

  // FIFO control logic
  always_ff @(posedge clock) begin
    if (reset) begin
      count <= 2'd0;
      wr_ptr <= 1'b0;
      rd_ptr <= 1'b0;
    end else begin
      case ({do_enq, do_deq})
        2'b10: begin  // Enqueue only
          count <= count + 2'd1;
          wr_ptr <= wr_ptr + 1'b1;
        end
        2'b01: begin  // Dequeue only
          count <= count - 2'd1;
          rd_ptr <= rd_ptr + 1'b1;
        end
        2'b11: begin  // Both enqueue and dequeue
          // count stays the same
          wr_ptr <= wr_ptr + 1'b1;
          rd_ptr <= rd_ptr + 1'b1;
        end
        default: begin
          // No change
        end
      endcase
    end
  end

  // Write data into FIFO
  always_ff @(posedge clock) begin
    if (do_enq) begin
      fifo_addr[wr_ptr]   <= in_bits_addr;
      fifo_tag[wr_ptr]    <= in_bits_tag;
      fifo_cmd[wr_ptr]    <= in_bits_cmd;
      fifo_size[wr_ptr]   <= in_bits_size;
      fifo_signed[wr_ptr] <= in_bits_signed;
      fifo_phys[wr_ptr]   <= in_bits_phys;
      fifo_data[wr_ptr]   <= in_bits_data;
      fifo_mask[wr_ptr]   <= in_bits_mask;
    end
  end

  // Read data from FIFO (combinational read)
  assign out_bits_addr   = fifo_addr[rd_ptr];
  assign out_bits_tag    = fifo_tag[rd_ptr];
  assign out_bits_cmd    = fifo_cmd[rd_ptr];
  assign out_bits_size   = fifo_size[rd_ptr];
  assign out_bits_signed = fifo_signed[rd_ptr];
  assign out_bits_phys   = fifo_phys[rd_ptr];
  assign out_bits_data   = fifo_data[rd_ptr];
  assign out_bits_mask   = fifo_mask[rd_ptr];

endmodule