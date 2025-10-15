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
  vsrc: List[String]
)

class WithAPSAccel(aps_config: APSConfig) extends Config((site, here, up) => {
  case BuildRoCC => up(BuildRoCC) ++ Seq(
    (p:Parameters) => {
      val rocc = LazyModule(new APSBlackbox(OpcodeSet.all, aps_config.vsrc, aps_config.top_module, Nil)(p))
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

import freechips.rocketchip.rocket.HellaCacheIO

class RoCCCoreIOForAPS(val nRoCCCSRs: Int = 0)(implicit p: Parameters) extends CoreBundle()(p) {
  val cmd = Flipped(Decoupled(new RoCCCommand))
  val resp = Decoupled(new RoCCResponse)
  val mem = new HellaCacheIO
  val busy = Output(Bool())
  val csrs = Flipped(Vec(nRoCCCSRs, new CustomCSRIO))
}

class APSBlackbox(opcodes: OpcodeSet, blackBoxFiles: List[String], topModule: String, csrList: Seq[CustomCSR])(implicit p: Parameters)
    extends LazyRoCC(opcodes, 0, false, csrList) {
  override lazy val module = new APSBlackboxModuleImp(this, blackBoxFiles, topModule)
}

class APSBlackboxModuleImp(outer: APSBlackbox, blackBoxFiles: List[String], topModule: String)(implicit p: Parameters)
    extends LazyRoCCModuleImp(outer)
    with RequireSyncReset
    with HasCoreParameters {
  val blackbox = {
    val roccIo = io
    Module(
      new BlackBox() with HasBlackBoxPath {
        val io = IO( new Bundle {
                      val clock = Input(Clock())
                      val reset = Input(Reset())
                      val rocc = new RoCCCoreIOForAPS(outer.roccCSRs.size)
                    })
        override def desiredName: String = topModule
        val chipyardDir = System.getProperty("user.dir")
        blackBoxFiles.foreach { file =>
          addPath(file)
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
}