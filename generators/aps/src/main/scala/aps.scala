package aps

import chisel3._
import chisel3.util._
import chisel3.experimental.IntParam

import org.chipsalliance.cde.config.{Field, Parameters, Config}
import freechips.rocketchip.tile._
import freechips.rocketchip.diplomacy._

case class APSConfig(
  backend: String,
  arch: String,
  core_count: Int,
  top_module: String,
  name: String,
  vsrc: List[String],
  maxBurstBytes: Int = 256,
  nXacts: Int = 1
) {
  require(maxBurstBytes > 0 && (maxBurstBytes & (maxBurstBytes - 1)) == 0,
    s"maxBurstBytes must be power of 2, got: $maxBurstBytes")
  require(nXacts > 0 && nXacts <= 16,
    s"nXacts must be in range [1, 16], got: $nXacts")
}

class WithAPSAccel(config: APSConfig) extends Config((site, here, up) => {
  case BuildRoCC => up(BuildRoCC) ++ Seq(
    (p:Parameters) => {
      val rocc = LazyModule(new APSBlackbox(OpcodeSet.all, Nil, config)(p))
      rocc
    }
  )
})

// class WithAPSAccel extends Config((site, here, up) => {
//   case BuildRoCC => up(BuildRoCC) ++ Seq(
//     (p:Parameters) => {
//       val regWidth = 64
//       val apsCSRs = Seq(CustomCSR(0x810, (BigInt(1) << 32) - 1, Some(0)))
//       // val apsCSRs = Nil
//       val rocc = LazyModule(new APSBlackboxExample(OpcodeSet.all, "blackbox", apsCSRs)(p))
//       rocc
//     }
//   )
// })

import org.chipsalliance.diplomacy.lazymodule._
import freechips.rocketchip.diplomacy.{LazyModule, LazyModuleImp, IdRange}
import freechips.rocketchip.tilelink._
import freechips.rocketchip.subsystem.{BaseSubsystem, FBUS}
import freechips.rocketchip.rocket.HellaCacheIO

class ApsDMABlackBoxIO(tlParams: TLBundleParameters)(implicit p: Parameters) extends Bundle {
  val tl_a = Decoupled(new TLBundleA(tlParams))
  val tl_d = Flipped(Decoupled(new TLBundleD(tlParams)))
}

class RoCCCoreIOForAPS(val nRoCCCSRs: Int = 0)(implicit p: Parameters) extends CoreBundle()(p) {
  val cmd = Flipped(Decoupled(new RoCCCommand))
  val resp = Decoupled(new RoCCResponse)
  val mem = new HellaCacheIO
  val busy = Output(Bool())
  val csrs = Flipped(Vec(nRoCCCSRs, new CustomCSRIO))
}

class APSBlackbox(opcodes: OpcodeSet, csrList: Seq[CustomCSR], config: APSConfig)(implicit p: Parameters)
    extends LazyRoCC(opcodes, 0, false, csrList) {

  // Override tldmaNode with TileLink client node for DMA operations
  // This node will be connected to tlMasterXbar in HasLazyRoCC trait
  override val atlNode = TLClientNode(Seq(TLMasterPortParameters.v1(
    Seq(TLClientParameters(
      name = config.top_module,
      sourceId = IdRange(0, config.nXacts),  // Support nXacts concurrent transactions
      requestFifo = true  // Maintain request ordering for same sourceId
    ))
  )))

  override lazy val module = new APSBlackboxModuleImp(this, config)
}

class APSBlackboxModuleImp(outer: APSBlackbox, config: APSConfig)(implicit p: Parameters)
    extends LazyRoCCModuleImp(outer)
    with RequireSyncReset
    with HasCoreParameters {


  // Get TileLink edge and bundle from tldmaNode
  val (tl, edge) = outer.atlNode.out(0)

  // TileLink parameters
  val tlParams = tl.params
  val beatBytes = edge.manager.beatBytes
  val addressBits = tlParams.addressBits
  val dataBits = tlParams.dataBits
  val sourceBits = tlParams.sourceBits
  val sinkBits = tlParams.sinkBits

  val blackbox = {
    val roccIo = io
    Module(
      new BlackBox() with HasBlackBoxPath {
        val io = IO( new Bundle {
                      val clock = Input(Clock())
                      val reset = Input(Reset())
                      val rocc = new RoCCCoreIOForAPS(outer.roccCSRs.size)
                      val dma = new ApsDMABlackBoxIO(tlParams)(p)
                    })

        override def desiredName: String = config.top_module

        val chipyardDir = System.getProperty("user.dir")
        config.vsrc.foreach { file =>
          val absolutePath = if (new java.io.File(file).isAbsolute) {
            file
          } else {
            s"$chipyardDir/$file"
          }
          addPath(absolutePath)
        }
      }
    )
  }

  blackbox.io.clock := clock
  blackbox.io.reset := reset

  blackbox.io.rocc.cmd <> io.cmd
  io.resp <> blackbox.io.rocc.resp
  io.mem <> blackbox.io.rocc.mem
  io.busy := blackbox.io.rocc.busy
  io.csrs <> blackbox.io.rocc.csrs

  // ========================================
  // TileLink DMA Interface Connection
  // ========================================
  // Connect TileLink A/D channels to BlackBox
  // The BlackBox can issue DMA requests through this interface

  // A channel: Requests from accelerator to memory
  tl.a <> blackbox.io.dma.tl_a

  // D channel: Responses from memory to accelerator
  blackbox.io.dma.tl_d <> tl.d

  // Tie off unused TileLink channels (B, C, E)
  // These are only used for cache coherency, which DMA doesn't need
  tl.b.ready := false.B  // Don't accept probe requests
  tl.c.valid := false.B  // Don't send probe responses
  tl.e.valid := false.B  // Don't send grant acknowledgements

  // ========================================
  // Assertions and Sanity Checks
  // ========================================

  // Verify TileLink transactions are within supported range
  when (tl.a.fire) {
    // Check size is within max burst size
    val maxLgSize = log2Ceil(config.maxBurstBytes)
    assert(tl.a.bits.size <= maxLgSize.U,
      s"TileLink request size exceeds maxBurstBytes ($maxLgSize)")

    // Check source ID is within allocated range
    assert(tl.a.bits.source < config.nXacts.U,
      s"TileLink source ID exceeds nXacts (${config.nXacts})")
  }
}