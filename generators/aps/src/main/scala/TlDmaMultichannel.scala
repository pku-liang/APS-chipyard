package aps

import chisel3._
import chisel3.util._
import freechips.rocketchip.tilelink._

class DmaTransferConfig(cpuAddrWidth: Int, isaxAddrWidth: Int) extends Bundle {
  val cpuAddr = UInt(cpuAddrWidth.W)
  val isaxAddr = UInt(isaxAddrWidth.W)
  val length = UInt(4.W)
  val strideX = UInt(8.W)
  val strideY = UInt(8.W)
  val enable = Bool()
}

class DmaChannelConfig(cpuAddrWidth: Int, isaxAddrWidth: Int) extends Bundle {
  val write = new DmaTransferConfig(cpuAddrWidth, isaxAddrWidth)
  val read = new DmaTransferConfig(cpuAddrWidth, isaxAddrWidth)
}

class DmaChannelStatus extends Bundle {
  val idle = Bool()
}

class IsaxMemPort(addrWidth: Int, dataWidth: Int) extends Bundle {
  val addr = Output(UInt(addrWidth.W))
  val wvalid = Output(Bool())
  val rvalid0 = Output(Bool())
  val rvalid1 = Output(Bool())
  val wdata = Output(UInt(dataWidth.W))
  val rdata = Input(UInt(dataWidth.W))
}

class TlDmaMultichannelIO(
  tlParams: TLBundleParameters,
  nCh: Int,
  isaxAddrWidth: Int)
    extends Bundle {
  val channels = Input(Vec(nCh, new DmaChannelConfig(tlParams.addressBits, isaxAddrWidth)))
  val status = Output(Vec(nCh, new DmaChannelStatus))
  val isax = new IsaxMemPort(isaxAddrWidth, tlParams.dataBits)
  val tlA = Decoupled(new TLBundleA(tlParams))
  val tlD = Flipped(Decoupled(new TLBundleD(tlParams)))
}

class TlDmaMultichannel(
  tlParams: TLBundleParameters,
  nCh: Int = 2,
  isaxAddrWidth: Int = 32)
    extends Module {
  require(nCh > 0, s"nCh must be positive, got $nCh")
  require(nCh <= (1 << tlParams.sourceBits),
    s"nCh=$nCh exceeds TileLink source capacity ${1 << tlParams.sourceBits}")

  val io = IO(new TlDmaMultichannelIO(tlParams, nCh, isaxAddrWidth))

  val beatBytes = tlParams.dataBits / 8
  val beatBytesU = beatBytes.U(8.W)
  val allMask = Fill(tlParams.dataBits / 8, 1.U(1.W))

  object ChannelState extends ChiselEnum {
    val idle, readReq, readWait, writeWait, done = Value
  }

  object GlobalState extends ChiselEnum {
    val idle, readCmd, prefetch, putAndFetch, putLast = Value
  }

  val state = RegInit(VecInit.fill(nCh)(ChannelState.idle))
  val stateNext = Wire(Vec(nCh, ChannelState()))

  val transferCnt = RegInit(VecInit.fill(nCh)(0.U(8.W)))
  val dmaAckHappened = RegInit(VecInit.fill(nCh)(false.B))

  val chCpuAddr = Reg(Vec(nCh, UInt(tlParams.addressBits.W)))
  val chIsaxAddr = Reg(Vec(nCh, UInt(isaxAddrWidth.W)))
  val chIsaxAddrNext = Wire(Vec(nCh, UInt(isaxAddrWidth.W)))
  val chLength = Reg(Vec(nCh, UInt(4.W)))
  val chStrideX = Reg(Vec(nCh, UInt(8.W)))
  val chTileOffset = Reg(Vec(nCh, UInt(8.W)))
  val chStrideXY = Reg(Vec(nCh, UInt(16.W)))

  val arbState = RegInit(GlobalState.idle)
  val arbStateNext = WireDefault(arbState)
  val arbChannel = RegInit(0.U(nCh.W))
  val arbChannelNext = WireDefault(arbChannel)

  val selectedChannel = OHToUInt(arbChannel)
  def perChannel(f: Int => Bool): Vec[Bool] = VecInit((0 until nCh).map(f))

  val startReq = perChannel { i =>
    val writeCfg = io.channels(i).write
    val readCfg = io.channels(i).read
    val writeStart = writeCfg.enable && (writeCfg.length > 0.U)
    val readStart = readCfg.enable && (readCfg.length > 0.U)
    (writeStart || readStart) && (state(i) === ChannelState.idle)
  }
  val dmaTransferLastElement = perChannel(i => transferCnt(i) === beatBytesU)
  val dmaTransferLastElementTwo = perChannel(i => transferCnt(i) === (2 * beatBytes).U(8.W))
  val transferEmpty = perChannel(i => transferCnt(i) === 0.U)
  val dmaTlAHandshaked = perChannel(i => io.tlA.fire && (io.tlA.bits.source === i.U))
  val dmaTlAHandshakedWrite = perChannel(i =>
    dmaTlAHandshaked(i) && (io.tlA.bits.opcode === TLMessages.PutFullData))
  val dmaTlDHandshaked = perChannel(i => io.tlD.fire && (io.tlD.bits.source === i.U))
  val dmaTlDHandshakedWrite = perChannel(i =>
    dmaTlDHandshaked(i) && (io.tlD.bits.opcode === TLMessages.AccessAck))
  val dmaTlDHandshakedRead = perChannel(i =>
    dmaTlDHandshaked(i) && (io.tlD.bits.opcode === TLMessages.AccessAckData))

  io.tlD.ready := true.B
  io.tlA.bits.param := 0.U
  io.tlA.bits.mask := allMask
  io.tlA.bits.data := io.isax.rdata
  io.tlA.bits.corrupt := false.B

  def loadTransfer(i: Int, cfg: DmaTransferConfig): Unit = {
    chCpuAddr(i) := cfg.cpuAddr
    chLength(i) := cfg.length
    chStrideX(i) := cfg.strideX
    chStrideXY(i) := cfg.strideX * cfg.strideY
    chTileOffset(i) := 0.U
    transferCnt(i) := ((1.U(16.W) << cfg.length)(7, 0))
  }

  for (i <- 0 until nCh) {
    val writeCfg = io.channels(i).write
    val readCfg = io.channels(i).read
    val wrapsTile = (chTileOffset(i) + beatBytesU >= chStrideX(i)) && (chStrideX(i) =/= 0.U)

    io.status(i).idle := state(i) === ChannelState.idle

    stateNext(i) := state(i)
    switch(state(i)) {
      is(ChannelState.idle) {
        when(startReq(i) && readCfg.enable) {
          stateNext(i) := ChannelState.readReq
        }.elsewhen(startReq(i) && writeCfg.enable) {
          stateNext(i) := ChannelState.writeWait
        }.otherwise {
          stateNext(i) := ChannelState.idle
        }
      }
      is(ChannelState.readReq) {
        stateNext(i) := Mux(dmaTlAHandshaked(i), ChannelState.readWait, ChannelState.readReq)
      }
      is(ChannelState.readWait) {
        stateNext(i) := Mux(dmaTlDHandshakedRead(i) && dmaTransferLastElement(i), ChannelState.done, ChannelState.readWait)
      }
      is(ChannelState.writeWait) {
        val writeDone =
          ((dmaTlAHandshaked(i) && dmaTransferLastElement(i)) || transferEmpty(i)) &&
            (dmaAckHappened(i) || dmaTlDHandshakedWrite(i))
        stateNext(i) := Mux(writeDone, ChannelState.done, ChannelState.writeWait)
      }
      is(ChannelState.done) {
        stateNext(i) := ChannelState.idle
      }
    }

    state(i) := stateNext(i)

    when(writeCfg.enable) {
      loadTransfer(i, writeCfg)
    }.elsewhen(readCfg.enable) {
      loadTransfer(i, readCfg)
    }.elsewhen(dmaTlDHandshakedRead(i) || dmaTlAHandshakedWrite(i)) {
      when(transferCnt(i) > 0.U) {
        transferCnt(i) := transferCnt(i) - beatBytesU
      }
      chTileOffset(i) := Mux(wrapsTile, 0.U, chTileOffset(i) + beatBytesU)
    }

    chIsaxAddrNext(i) := chIsaxAddr(i)
    when(writeCfg.enable) {
      chIsaxAddrNext(i) := writeCfg.isaxAddr
    }.elsewhen(readCfg.enable) {
      chIsaxAddrNext(i) := readCfg.isaxAddr
    }.elsewhen(dmaTlDHandshakedRead(i) || dmaTlAHandshakedWrite(i)) {
      when(wrapsTile) {
        chIsaxAddrNext(i) := chIsaxAddr(i) + chStrideXY(i) - chTileOffset(i)
      }.otherwise {
        chIsaxAddrNext(i) := chIsaxAddr(i) + beatBytes.U
      }
    }

    chIsaxAddr(i) := chIsaxAddrNext(i)

    when(startReq(i)) {
      dmaAckHappened(i) := false.B
    }.elsewhen(dmaTlDHandshakedWrite(i)) {
      dmaAckHappened(i) := true.B
    }
  }

  val chReadCmdReq = VecInit((0 until nCh).map(i => state(i) === ChannelState.readReq))
  val chDataReq = VecInit((0 until nCh).map(i => state(i) === ChannelState.writeWait))
  val readCmdGrant = PriorityEncoderOH(chReadCmdReq.asUInt)
  val dataGrant = PriorityEncoderOH(chDataReq.asUInt)

  val arbAHandshaked = (arbChannel & dmaTlAHandshaked.asUInt).orR
  val arbTransferLastTwo = (arbChannel & dmaTransferLastElementTwo.asUInt).orR

  switch(arbState) {
    is(GlobalState.idle) {
      when(chReadCmdReq.asUInt.orR) {
        arbStateNext := GlobalState.readCmd
        arbChannelNext := readCmdGrant
      }.elsewhen(chDataReq.asUInt.orR) {
        arbStateNext := GlobalState.prefetch
        arbChannelNext := dataGrant
      }
    }
    is(GlobalState.readCmd) {
      when(arbAHandshaked) {
        arbStateNext := GlobalState.idle
      }
    }
    is(GlobalState.prefetch) {
      arbStateNext := GlobalState.putAndFetch
    }
    is(GlobalState.putAndFetch) {
      when(arbAHandshaked && arbTransferLastTwo) {
        arbStateNext := GlobalState.putLast
      }
    }
    is(GlobalState.putLast) {
      when(state(selectedChannel) =/= ChannelState.writeWait) {
        arbStateNext := GlobalState.idle
      }
    }
  }

  arbState := arbStateNext
  arbChannel := arbChannelNext

  io.isax.wvalid := dmaTlDHandshakedRead.asUInt.orR
  io.isax.wdata := io.tlD.bits.data
  io.isax.addr := Mux(
    dmaTlDHandshakedRead.asUInt.orR,
    chIsaxAddr(io.tlD.bits.source)(isaxAddrWidth - 1, 0),
    chIsaxAddrNext(selectedChannel)(isaxAddrWidth - 1, 0))
  io.isax.rvalid0 := (arbState === GlobalState.prefetch) || (arbState === GlobalState.putAndFetch)
  io.isax.rvalid1 := (arbState === GlobalState.putAndFetch) || (arbState === GlobalState.putLast)

  io.tlA.bits.source := selectedChannel
  io.tlA.bits.address := chCpuAddr(selectedChannel)
  io.tlA.bits.size := chLength(selectedChannel)
  io.tlA.bits.opcode := Mux(arbState === GlobalState.readCmd, TLMessages.Get, TLMessages.PutFullData)
  io.tlA.valid := (arbState === GlobalState.readCmd) ||
    (((arbState === GlobalState.putAndFetch) || (arbState === GlobalState.putLast)) &&
      !transferEmpty(selectedChannel))
}
