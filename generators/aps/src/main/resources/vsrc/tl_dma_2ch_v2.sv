module tl_dma_multichannel #(
  parameter TL_AW = 32,       // TileLink address width
  parameter TL_DW = 64,       // TileLink data width (beatBytes * 8)
  parameter TL_SW = 1,        // TileLink source width (bits)
  parameter TL_SINKW = 3,     // TileLink sink width
  parameter N_CH = 2,         // Number of DMA channels (1 to 2**TL_SW)
  parameter ISAX_AW = 32
)(
  input  logic        clock,
  input  logic        reset,

  // ========================================
  // External Control Interface (per-channel packed arrays, indexed by channel ID)
  // ========================================
  input  logic [N_CH-1:0][TL_AW-1:0]  cfg_write_cpu_addr,
  input  logic [N_CH-1:0][TL_AW-1:0]  cfg_write_isax_addr,
  input  logic [N_CH-1:0][TL_AW-1:0]  cfg_read_cpu_addr,
  input  logic [N_CH-1:0][TL_AW-1:0]  cfg_read_isax_addr,
  input  logic [N_CH-1:0][3:0]        cfg_read_length,     // Transfer length (log2 bytes)
  input  logic [N_CH-1:0][3:0]        cfg_write_length,    // Transfer length (log2 bytes)
  input  logic [N_CH-1:0][7:0]        cfg_read_stride_x,   // ISAX memory stride X for read (cpu to isax)
  input  logic [N_CH-1:0][7:0]        cfg_read_stride_y,   // ISAX memory stride Y for read (cpu to isax)
  input  logic [N_CH-1:0][7:0]        cfg_write_stride_x,  // ISAX memory stride X for write (isax to cpu)
  input  logic [N_CH-1:0][7:0]        cfg_write_stride_y,  // ISAX memory stride Y for write (isax to cpu)
  input  logic [N_CH-1:0]             cfg_write_en,        // isax to cpu
  input  logic [N_CH-1:0]             cfg_read_en,         // cpu to isax
  output logic [N_CH-1:0]             ch_idle,
  output logic [N_CH-1:0]             ch_idle_ready,

  output logic [ISAX_AW-1:0]isax_mem_addr,
  output logic              isax_mem_wvalid,
  output logic              isax_mem_rvalid0,
  output logic              isax_mem_rvalid1,
  output logic [TL_DW-1:0]  isax_mem_wdata,
  input  logic [TL_DW-1:0]  isax_mem_rdata,

  // ========================================
  // TileLink A Channel (DMA Requests)
  // NOTE: Port names have 'dma_' prefix due to nested Bundle structure in Chisel
  // ========================================
  output logic              dma_tl_a_valid,
  input  logic              dma_tl_a_ready,
  output logic [2:0]        dma_tl_a_bits_opcode,
  output logic [2:0]        dma_tl_a_bits_param,
  output logic [3:0]        dma_tl_a_bits_size,
  output logic [TL_SW-1:0]  dma_tl_a_bits_source,
  output logic [TL_AW-1:0]  dma_tl_a_bits_address,
  output logic [TL_DW/8-1:0]dma_tl_a_bits_mask,
  output logic [TL_DW-1:0]  dma_tl_a_bits_data,
  output logic              dma_tl_a_bits_corrupt,

  // ========================================
  // TileLink D Channel (DMA Responses)
  // ========================================
  input  logic              dma_tl_d_valid,
  output logic              dma_tl_d_ready,
  input  logic [2:0]        dma_tl_d_bits_opcode,
  input  logic [1:0]        dma_tl_d_bits_param,
  input  logic [3:0]        dma_tl_d_bits_size,
  input  logic [TL_SW-1:0]  dma_tl_d_bits_source,
  input  logic [TL_SINKW-1:0]dma_tl_d_bits_sink,
  input  logic              dma_tl_d_bits_denied,
  input  logic [TL_DW-1:0]  dma_tl_d_bits_data,
  input  logic              dma_tl_d_bits_corrupt
);

  // TileLink Opcodes
  localparam TL_GET = 3'd4;
  localparam TL_PUT_FULL = 3'd0;
  localparam TL_ACCESS_ACK = 3'd0;
  localparam TL_ACCESS_ACK_DATA = 3'd1;

  localparam BEAT_BYTES = TL_DW / 8;

  // State machine
  typedef enum logic [2:0] {
    IDLE,
    READ_REQ,
    READ_WAIT,
    WRITE_WAIT,
    DONE
  } chn_state_t;

  chn_state_t state [N_CH];
  chn_state_t state_next [N_CH];

  // Per-channel signals (arrays)
  logic cfg_start [N_CH];
  logic [7:0] transfer_cnt [N_CH];
  logic dma_ack_happened [N_CH];
  logic [N_CH-1:0] dma_transfer_last_element;
  logic [N_CH-1:0] dma_transfer_last_element_two;
  logic [N_CH-1:0] dma_transfer_no_element;
  logic [N_CH-1:0] cha_is_channel;
  logic [N_CH-1:0] chd_is_channel;
  logic [TL_AW-1:0] ch_cpu_addr  [N_CH];
  logic [TL_AW-1:0] ch_isax_addr [N_CH];
  logic [TL_AW-1:0] ch_isax_addr_next [N_CH];
  logic [3:0] ch_length    [N_CH];
  logic [7:0] ch_stride_x  [N_CH];
  logic [7:0] ch_tile_offset [N_CH];   // Offset within tile row
  logic [15:0] ch_stride_xy [N_CH];    // Precomputed stride_x * stride_y to shorten critical path
  logic [N_CH-1:0] dma_tl_a_handshaked;
  logic [N_CH-1:0] dma_tl_a_handshaked_write;
  logic [N_CH-1:0] dma_tl_d_handshaked;
  logic [N_CH-1:0] dma_tl_d_handshaked_write;
  logic [N_CH-1:0] dma_tl_d_handshaked_read;

  // Generate per-channel logic
  for (genvar i = 0; i < N_CH; i++) begin : gen_ch
    assign cfg_start[i] = ((cfg_write_en[i] && (cfg_write_length[i] > 0)) ||
                           (cfg_read_en[i] && (cfg_read_length[i] > 0))) &&
                          (state[i] == IDLE);
    assign ch_idle_ready[i] = 1'b1;
    assign ch_idle[i] = (state[i] == IDLE);
    assign dma_transfer_last_element[i] = (transfer_cnt[i] == TL_DW / 8);
    assign dma_transfer_last_element_two[i] = (transfer_cnt[i] == 2 * TL_DW / 8);
    assign dma_transfer_no_element[i] = (transfer_cnt[i] == 0);
    assign cha_is_channel[i] = (dma_tl_a_bits_source == i);
    assign chd_is_channel[i] = (dma_tl_d_bits_source == i);
    assign dma_tl_a_handshaked[i] = dma_tl_a_valid && dma_tl_a_ready && cha_is_channel[i];
    assign dma_tl_d_handshaked[i] = dma_tl_d_valid && dma_tl_d_ready && chd_is_channel[i];
    assign dma_tl_a_handshaked_write[i] = dma_tl_a_handshaked[i] && (dma_tl_a_bits_opcode == TL_PUT_FULL);
    assign dma_tl_d_handshaked_write[i] = dma_tl_d_handshaked[i] && (dma_tl_d_bits_opcode == TL_ACCESS_ACK);
    assign dma_tl_d_handshaked_read[i] = dma_tl_d_handshaked[i] && (dma_tl_d_bits_opcode == TL_ACCESS_ACK_DATA);
  end

  assign dma_tl_a_bits_mask = '1;
  assign dma_tl_a_bits_corrupt = 1'b0;
  assign dma_tl_a_bits_param = 3'd0;
  assign dma_tl_d_ready = 1'b1;

  // fsm for each channel
  for (genvar i = 0; i < N_CH; i++) begin : gen_chn_fsm
    always_ff @(posedge clock) begin
      if (reset) begin
        state[i] <= IDLE;
      end else begin
        state[i] <= state_next[i];
      end
    end

    always_comb begin
      case (state[i])
        IDLE: begin
          if (cfg_start[i] && cfg_read_en[i]) begin
            state_next[i] = READ_REQ;
          end
          else if (cfg_start[i] && cfg_write_en[i]) begin
            state_next[i] = WRITE_WAIT;
          end
          else begin
            state_next[i] = IDLE;
          end
        end
        READ_REQ: begin // command sending
          if (dma_tl_a_handshaked[i]) begin
            state_next[i] = READ_WAIT;
          end
          else begin
            state_next[i] = READ_REQ;
          end
        end
        READ_WAIT: begin // command sended, read data receiveing
          if (dma_tl_d_handshaked_read[i] && dma_transfer_last_element[i]) begin
            state_next[i] = DONE;
          end
          else begin
            state_next[i] = READ_WAIT;
          end
        end
        WRITE_WAIT: begin // command sended, write data sending
          if (
            ((dma_tl_a_handshaked[i] && dma_transfer_last_element[i]) || dma_transfer_no_element[i]) && // a-channel last handshake happened or happening
            (dma_ack_happened[i] || (dma_tl_d_handshaked_write[i])) // d-channel handshake happened or happening
          ) begin
            state_next[i] = DONE;
          end
          else begin
            state_next[i] = WRITE_WAIT;
          end
        end
        DONE: begin
          state_next[i] = IDLE;
        end
        default: state_next[i] = IDLE;
      endcase
    end

    always_ff @(posedge clock) begin
      if (reset) begin
        transfer_cnt[i] <= '0;
      end
      if (cfg_write_en[i]) begin
        ch_cpu_addr[i] <= cfg_write_cpu_addr[i];
        ch_length[i] <= cfg_write_length[i];
        ch_stride_x[i] <= cfg_write_stride_x[i];
        ch_stride_xy[i] <= cfg_write_stride_x[i] * cfg_write_stride_y[i];  // Precompute stride_x * stride_y
        ch_tile_offset[i] <= 8'd0;  // Reset tile offset
        transfer_cnt[i] <= (1 << cfg_write_length[i]);
      end
      else if (cfg_read_en[i]) begin
        ch_cpu_addr[i] <= cfg_read_cpu_addr[i];
        ch_length[i] <= cfg_read_length[i];
        ch_stride_x[i] <= cfg_read_stride_x[i];
        ch_stride_xy[i] <= cfg_read_stride_x[i] * cfg_read_stride_y[i];  // Precompute stride_x * stride_y
        ch_tile_offset[i] <= 8'd0;  // Reset tile offset
        transfer_cnt[i] <= (1 << cfg_read_length[i]);
      end
      else if (dma_tl_d_handshaked_read[i] || dma_tl_a_handshaked_write[i]) begin
        transfer_cnt[i] <= (transfer_cnt[i] > 0) ? (transfer_cnt[i] - TL_DW/8) : transfer_cnt[i];

        // Tiling logic: check if next offset would reach stride_x boundary
        if ((ch_tile_offset[i] + TL_DW/8 >= ch_stride_x[i]) && (ch_stride_x[i] != 0)) begin
          // Jump to next tile row: current_addr + stride_x * stride_y - tile_offset
          ch_tile_offset[i] <= 8'd0;
        end else begin
          ch_tile_offset[i] <= ch_tile_offset[i] + TL_DW/8;
        end
      end
    end

    always_comb begin
      if (cfg_write_en[i])
        ch_isax_addr_next[i] = cfg_write_isax_addr[i];
      else if (cfg_read_en[i])
        ch_isax_addr_next[i] = cfg_read_isax_addr[i];
      else if (dma_tl_d_handshaked_read[i] || dma_tl_a_handshaked_write[i]) begin
        if ((ch_tile_offset[i] + TL_DW/8 >= ch_stride_x[i]) && (ch_stride_x[i] != 0)) begin
          // Jump to next tile row: current_addr + stride_x * stride_y - tile_offset
          ch_isax_addr_next[i] = ch_isax_addr[i] + {16'd0, ch_stride_xy[i]} - {24'd0, ch_tile_offset[i]};
        end else begin
          // Normal increment within tile row
          ch_isax_addr_next[i] = ch_isax_addr[i] + TL_DW/8;
        end
      end
      else
        ch_isax_addr_next[i] = ch_isax_addr[i];
    end

    always_ff @(posedge clock) begin
      ch_isax_addr[i] <= ch_isax_addr_next[i];
    end

    always_ff @(posedge clock) begin
      if (reset) begin
        dma_ack_happened[i] <= 'd0;
      end
      else if (cfg_start[i]) begin
        dma_ack_happened[i] <= 1'b0;
      end
      else if (dma_tl_d_handshaked_write[i]) begin
        dma_ack_happened[i] <= 1'b1;
      end
    end
  end

  // idle, data (prefetch, put && fetch, put_last); cmd (write_cmd, read_cmd)
  typedef enum logic [3:0] {
    G_IDLE,
    G_READ_CMD,
    G_PREFETCH,
    G_PUT_AND_FETCH,
    G_PUT_LAST
  } glbl_state_t;

  glbl_state_t glbl_state, glbl_state_next;
  logic [N_CH-1:0] glbl_channel, glbl_channel_next;

  // Per-channel request signals for arbiter
  logic [N_CH-1:0] ch_read_cmd_req;    // Channel wants to send read command
  logic [N_CH-1:0] ch_data_req;        // Channel has data to transfer (WRITE_WAIT)

  // Generate request signals from per-channel state
  for (genvar i = 0; i < N_CH; i++) begin : gen_arb_req
    assign ch_read_cmd_req[i]  = (state[i] == READ_REQ);
    assign ch_data_req[i]      = (state[i] == WRITE_WAIT);
  end

  // Lowest-set-bit isolation: x & -x gives one-hot of lowest requester
  wire [N_CH-1:0] read_cmd_grant  = ch_read_cmd_req  & (-ch_read_cmd_req);
  wire [N_CH-1:0] data_grant      = ch_data_req      & (-ch_data_req);

  // Combine one-hot channel with handshake/status signals
  wire glbl_a_handshaked    = |(glbl_channel & dma_tl_a_handshaked);
  wire glbl_transfer_last   = |(glbl_channel & dma_transfer_last_element);
  wire glbl_transfer_last_two   = |(glbl_channel & dma_transfer_last_element_two);
  wire glbl_transfer_none   = |(glbl_channel & dma_transfer_no_element);

  wire [TL_SW-1:0] glbl_channel_bin = onehot_to_binary(glbl_channel);
  // Arbiter: command has higher priority than data channel
  // Within same priority, lower channel index wins (x & -x isolates lowest set bit)
  always_comb begin
    glbl_state_next = glbl_state;
    glbl_channel_next = glbl_channel;

    case (glbl_state)
      G_IDLE: begin
        // Priority 1: Read command requests
        if (|ch_read_cmd_req) begin
          glbl_state_next = G_READ_CMD;
          glbl_channel_next = read_cmd_grant;
        end
        // Priority 2: Data transfer requests (lowest)
        else if (|ch_data_req) begin
          glbl_state_next = G_PREFETCH;
          glbl_channel_next = data_grant;
        end
      end

      G_READ_CMD: begin
        if (glbl_a_handshaked) glbl_state_next = G_IDLE;
      end

      G_PREFETCH: begin
        glbl_state_next = G_PUT_AND_FETCH;
      end

      G_PUT_AND_FETCH: begin
        if (glbl_a_handshaked && glbl_transfer_last_two) begin
          glbl_state_next = G_PUT_LAST;
        end
      end

      G_PUT_LAST: begin
        if (state[glbl_channel_bin] != WRITE_WAIT) begin
          glbl_state_next = G_IDLE;
        end
      end

      default: glbl_state_next = G_IDLE;
    endcase
  end

  // Global state register
  always_ff @(posedge clock) begin
    if (reset) begin
      glbl_state <= G_IDLE;
      glbl_channel <= '0;
    end else begin
      glbl_state <= glbl_state_next;
      glbl_channel <= glbl_channel_next;
    end
  end

  assign isax_mem_wvalid = |dma_tl_d_handshaked_read;
  assign isax_mem_wdata = dma_tl_d_bits_data;
  assign isax_mem_addr = |dma_tl_d_handshaked_read ? ch_isax_addr[dma_tl_d_bits_source][ISAX_AW-1:0] : // read
                        ch_isax_addr_next[glbl_channel_bin]; // write
  assign isax_mem_rvalid0 = (glbl_state == G_PREFETCH || glbl_state == G_PUT_AND_FETCH);
  assign isax_mem_rvalid1 = (glbl_state == G_PUT_AND_FETCH || glbl_state == G_PUT_LAST);
  assign dma_tl_a_bits_data = isax_mem_rdata;

  // One-hot to binary conversion
  function automatic logic [TL_SW-1:0] onehot_to_binary(input logic [N_CH-1:0] onehot);
    logic [TL_SW-1:0] result;
    integer i;
    begin
      result = '0;
      for (i = 0; i < N_CH; i = i + 1) begin
        if (onehot[i]) result = i[TL_SW-1:0];
      end
      onehot_to_binary = result;
    end
  endfunction

  assign dma_tl_a_bits_source = glbl_channel_bin;
  assign dma_tl_a_bits_address = ch_cpu_addr[glbl_channel_bin];
  assign dma_tl_a_bits_size = ch_length[glbl_channel_bin];
  assign dma_tl_a_bits_opcode = (glbl_state == G_READ_CMD) ? TL_GET : TL_PUT_FULL;
  assign dma_tl_a_valid = (glbl_state == G_READ_CMD) || (((glbl_state == G_PUT_AND_FETCH) || (glbl_state == G_PUT_LAST)) && !dma_transfer_no_element[glbl_channel_bin]);
  
endmodule