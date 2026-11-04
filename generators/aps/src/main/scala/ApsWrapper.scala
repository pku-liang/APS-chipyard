package aps

import chisel3._
import chisel3.experimental.requireIsChiselType
import chisel3.reflect.DataMirror.internal.chiselTypeClone
import chisel3.util._
import chisel3.util.HasBlackBoxPath
import freechips.rocketchip.rocket.HellaCacheWriteData
import freechips.rocketchip.tile.HasCoreParameters
import freechips.rocketchip.tilelink._
import org.chipsalliance.cde.config.Parameters
import scala.collection.immutable.ListMap

class HellaCmdBundle extends Bundle {
  val addr = UInt(32.W)
  val tag = UInt(8.W)
  val cmd = UInt(5.W)
  val size = UInt(2.W)
  val signed = Bool()
  val phys = Bool()
  val data = UInt(32.W)
  val mask = UInt(4.W)
}

class HellaCmdFifo extends Module {
  val io = IO(new Bundle {
    val in = Flipped(Decoupled(new HellaCmdBundle))
    val out = Decoupled(new HellaCmdBundle)
  })

  val entries = Reg(Vec(2, new HellaCmdBundle))
  val count = RegInit(0.U(2.W))
  val wrPtr = RegInit(false.B)
  val rdPtr = RegInit(false.B)

  val doEnq = io.in.fire
  val doDeq = io.out.fire

  io.in.ready := count < 2.U
  io.out.valid := count > 0.U
  io.out.bits := entries(rdPtr.asUInt)

  when(doEnq) {
    entries(wrPtr.asUInt) := io.in.bits
  }

  switch(Cat(doEnq, doDeq)) {
    is("b10".U) {
      count := count + 1.U
      wrPtr := ~wrPtr
    }
    is("b01".U) {
      count := count - 1.U
      rdPtr := ~rdPtr
    }
    is("b11".U) {
      wrPtr := ~wrPtr
      rdPtr := ~rdPtr
    }
  }
}

class MainBlackBoxIO(csrNames: Seq[String], csrWidth: Int,
                     completionIds: Seq[Int] = Nil) extends Record {
  private def csrPortPrefix(name: String): String = s"csr_$name"

  private def fields: Seq[(String, Data)] = Seq(
    "clk" -> Input(Clock()),
    "rst" -> Input(Bool()),
    "burst_read_0_enable" -> Input(Bool()),
    "burst_read_0_ready" -> Output(Bool()),
    "burst_read_0_addr" -> Input(UInt(32.W)),
    "burst_read_1_enable" -> Input(Bool()),
    "burst_read_1_ready" -> Output(Bool()),
    "burst_read_1_" -> Output(UInt(64.W)),
    "burst_write_enable" -> Input(Bool()),
    "burst_write_ready" -> Output(Bool()),
    "burst_write_addr" -> Input(UInt(32.W)),
    "burst_write_data" -> Input(UInt(64.W)),
    "rocc_cmd_enable" -> Input(Bool()),
    "rocc_cmd_ready" -> Output(Bool()),
    "rocc_cmd_rocc_cmd_funct" -> Input(UInt(7.W)),
    "rocc_cmd_rocc_cmd_rs1" -> Input(UInt(5.W)),
    "rocc_cmd_rocc_cmd_rs2" -> Input(UInt(5.W)),
    "rocc_cmd_rocc_cmd_rd" -> Input(UInt(5.W)),
    "rocc_cmd_rocc_cmd_xs1" -> Input(Bool()),
    "rocc_cmd_rocc_cmd_xs2" -> Input(Bool()),
    "rocc_cmd_rocc_cmd_xd" -> Input(Bool()),
    "rocc_cmd_rocc_cmd_opcode" -> Input(UInt(7.W)),
    "rocc_cmd_rocc_cmd_rs1data" -> Input(UInt(32.W)),
    "rocc_cmd_rocc_cmd_rs2data" -> Input(UInt(32.W)),
    "hella_resp_enable" -> Input(Bool()),
    "hella_resp_ready" -> Output(Bool()),
    "hella_resp_hella_resp_data" -> Input(UInt(32.W)),
    "hella_resp_hella_resp_tag" -> Input(UInt(8.W)),
    "hella_resp_hella_resp_cmd" -> Input(UInt(5.W)),
    "hella_resp_hella_resp_size" -> Input(UInt(2.W)),
    "hella_resp_hella_resp_signed" -> Input(Bool()),
    "dma_cpu_to_isax_ch0_cpu_addr" -> Output(UInt(32.W)),
    "dma_cpu_to_isax_ch0_isax_addr" -> Output(UInt(32.W)),
    "dma_cpu_to_isax_ch0_length" -> Output(UInt(4.W)),
    "dma_cpu_to_isax_ch0_stride_x" -> Output(UInt(8.W)),
    "dma_cpu_to_isax_ch0_stride_y" -> Output(UInt(8.W)),
    "dma_cpu_to_isax_ch0_ready" -> Input(Bool()),
    "dma_cpu_to_isax_ch0_enable" -> Output(Bool()),
    "dma_isax_to_cpu_ch0_cpu_addr" -> Output(UInt(32.W)),
    "dma_isax_to_cpu_ch0_isax_addr" -> Output(UInt(32.W)),
    "dma_isax_to_cpu_ch0_length" -> Output(UInt(4.W)),
    "dma_isax_to_cpu_ch0_stride_x" -> Output(UInt(8.W)),
    "dma_isax_to_cpu_ch0_stride_y" -> Output(UInt(8.W)),
    "dma_isax_to_cpu_ch0_ready" -> Input(Bool()),
    "dma_isax_to_cpu_ch0_enable" -> Output(Bool()),
    "dma_poll_for_idle_ch0_" -> Input(Bool()),
    "dma_poll_for_idle_ch0_ready" -> Input(Bool()),
    "dma_cpu_to_isax_ch1_cpu_addr" -> Output(UInt(32.W)),
    "dma_cpu_to_isax_ch1_isax_addr" -> Output(UInt(32.W)),
    "dma_cpu_to_isax_ch1_length" -> Output(UInt(4.W)),
    "dma_cpu_to_isax_ch1_stride_x" -> Output(UInt(8.W)),
    "dma_cpu_to_isax_ch1_stride_y" -> Output(UInt(8.W)),
    "dma_cpu_to_isax_ch1_ready" -> Input(Bool()),
    "dma_cpu_to_isax_ch1_enable" -> Output(Bool()),
    "dma_isax_to_cpu_ch1_cpu_addr" -> Output(UInt(32.W)),
    "dma_isax_to_cpu_ch1_isax_addr" -> Output(UInt(32.W)),
    "dma_isax_to_cpu_ch1_length" -> Output(UInt(4.W)),
    "dma_isax_to_cpu_ch1_stride_x" -> Output(UInt(8.W)),
    "dma_isax_to_cpu_ch1_stride_y" -> Output(UInt(8.W)),
    "dma_isax_to_cpu_ch1_ready" -> Input(Bool()),
    "dma_isax_to_cpu_ch1_enable" -> Output(Bool()),
    "dma_poll_for_idle_ch1_" -> Input(Bool()),
    "dma_poll_for_idle_ch1_ready" -> Input(Bool()),
    "rocc_resp_rocc_resp_to_bus_result_rd" -> Output(UInt(5.W)),
    "rocc_resp_rocc_resp_to_bus_result_rddata" -> Output(UInt(32.W)),
    "rocc_resp_rocc_resp_to_bus_ready" -> Input(Bool()),
    "rocc_resp_rocc_resp_to_bus_enable" -> Output(Bool()),
    "hella_cmd_hella_cmd_to_bus_cmd_addr" -> Output(UInt(32.W)),
    "hella_cmd_hella_cmd_to_bus_cmd_tag" -> Output(UInt(8.W)),
    "hella_cmd_hella_cmd_to_bus_cmd_cmd" -> Output(UInt(5.W)),
    "hella_cmd_hella_cmd_to_bus_cmd_size" -> Output(UInt(2.W)),
    "hella_cmd_hella_cmd_to_bus_cmd_signed" -> Output(Bool()),
    "hella_cmd_hella_cmd_to_bus_cmd_phys" -> Output(Bool()),
    "hella_cmd_hella_cmd_to_bus_cmd_data" -> Output(UInt(32.W)),
    "hella_cmd_hella_cmd_to_bus_cmd_mask" -> Output(UInt(4.W)),
    "hella_cmd_hella_cmd_to_bus_ready" -> Input(Bool()),
    "hella_cmd_hella_cmd_to_bus_enable" -> Output(Bool())
  ) ++ completionIds.map { id =>
    s"instruction_completed_${id}_" -> Output(Bool())
  } ++ csrNames.flatMap { name =>
    val prefix = csrPortPrefix(name)
    Seq(
      s"${prefix}_value_" -> Input(UInt(csrWidth.W)),
      s"${prefix}_value_ready" -> Input(Bool()),
      s"${prefix}_set_${name}_sdata" -> Output(UInt(csrWidth.W)),
      s"${prefix}_set_ready" -> Input(Bool()),
      s"${prefix}_set_enable" -> Output(Bool())
    )
  }

  fields.foreach { case (name, field) => requireIsChiselType(field, name) }
  val elements: ListMap[String, Data] =
    ListMap(fields.map { case (name, field) => name -> chiselTypeClone(field) }: _*)

  private def elem[T <: Data](name: String): T = elements(name).asInstanceOf[T]

  def clk: Clock = elem("clk")
  def rst: Bool = elem("rst")
  def burst_read_0_enable: Bool = elem("burst_read_0_enable")
  def burst_read_0_ready: Bool = elem("burst_read_0_ready")
  def burst_read_0_addr: UInt = elem("burst_read_0_addr")
  def burst_read_1_enable: Bool = elem("burst_read_1_enable")
  def burst_read_1_ready: Bool = elem("burst_read_1_ready")
  def burst_read_1_res0: UInt = elem("burst_read_1_")
  def burst_write_enable: Bool = elem("burst_write_enable")
  def burst_write_ready: Bool = elem("burst_write_ready")
  def burst_write_addr: UInt = elem("burst_write_addr")
  def burst_write_data: UInt = elem("burst_write_data")
  def rocc_cmd_enable: Bool = elem("rocc_cmd_enable")
  def rocc_cmd_ready: Bool = elem("rocc_cmd_ready")
  def rocc_cmd_rocc_cmd_funct: UInt = elem("rocc_cmd_rocc_cmd_funct")
  def rocc_cmd_rocc_cmd_rs1: UInt = elem("rocc_cmd_rocc_cmd_rs1")
  def rocc_cmd_rocc_cmd_rs2: UInt = elem("rocc_cmd_rocc_cmd_rs2")
  def rocc_cmd_rocc_cmd_rd: UInt = elem("rocc_cmd_rocc_cmd_rd")
  def rocc_cmd_rocc_cmd_xs1: Bool = elem("rocc_cmd_rocc_cmd_xs1")
  def rocc_cmd_rocc_cmd_xs2: Bool = elem("rocc_cmd_rocc_cmd_xs2")
  def rocc_cmd_rocc_cmd_xd: Bool = elem("rocc_cmd_rocc_cmd_xd")
  def rocc_cmd_rocc_cmd_opcode: UInt = elem("rocc_cmd_rocc_cmd_opcode")
  def rocc_cmd_rocc_cmd_rs1data: UInt = elem("rocc_cmd_rocc_cmd_rs1data")
  def rocc_cmd_rocc_cmd_rs2data: UInt = elem("rocc_cmd_rocc_cmd_rs2data")
  def hella_resp_enable: Bool = elem("hella_resp_enable")
  def hella_resp_ready: Bool = elem("hella_resp_ready")
  def hella_resp_hella_resp_data: UInt = elem("hella_resp_hella_resp_data")
  def hella_resp_hella_resp_tag: UInt = elem("hella_resp_hella_resp_tag")
  def hella_resp_hella_resp_cmd: UInt = elem("hella_resp_hella_resp_cmd")
  def hella_resp_hella_resp_size: UInt = elem("hella_resp_hella_resp_size")
  def hella_resp_hella_resp_signed: Bool = elem("hella_resp_hella_resp_signed")
  def dma_cpu_to_isax_ch0_cpu_addr: UInt = elem("dma_cpu_to_isax_ch0_cpu_addr")
  def dma_cpu_to_isax_ch0_isax_addr: UInt = elem("dma_cpu_to_isax_ch0_isax_addr")
  def dma_cpu_to_isax_ch0_length: UInt = elem("dma_cpu_to_isax_ch0_length")
  def dma_cpu_to_isax_ch0_stride_x: UInt = elem("dma_cpu_to_isax_ch0_stride_x")
  def dma_cpu_to_isax_ch0_stride_y: UInt = elem("dma_cpu_to_isax_ch0_stride_y")
  def dma_cpu_to_isax_ch0_ready: Bool = elem("dma_cpu_to_isax_ch0_ready")
  def dma_cpu_to_isax_ch0_enable: Bool = elem("dma_cpu_to_isax_ch0_enable")
  def dma_isax_to_cpu_ch0_cpu_addr: UInt = elem("dma_isax_to_cpu_ch0_cpu_addr")
  def dma_isax_to_cpu_ch0_isax_addr: UInt = elem("dma_isax_to_cpu_ch0_isax_addr")
  def dma_isax_to_cpu_ch0_length: UInt = elem("dma_isax_to_cpu_ch0_length")
  def dma_isax_to_cpu_ch0_stride_x: UInt = elem("dma_isax_to_cpu_ch0_stride_x")
  def dma_isax_to_cpu_ch0_stride_y: UInt = elem("dma_isax_to_cpu_ch0_stride_y")
  def dma_isax_to_cpu_ch0_ready: Bool = elem("dma_isax_to_cpu_ch0_ready")
  def dma_isax_to_cpu_ch0_enable: Bool = elem("dma_isax_to_cpu_ch0_enable")
  def dma_poll_for_idle_ch0_res0: Bool = elem("dma_poll_for_idle_ch0_")
  def dma_poll_for_idle_ch0_ready: Bool = elem("dma_poll_for_idle_ch0_ready")
  def dma_cpu_to_isax_ch1_cpu_addr: UInt = elem("dma_cpu_to_isax_ch1_cpu_addr")
  def dma_cpu_to_isax_ch1_isax_addr: UInt = elem("dma_cpu_to_isax_ch1_isax_addr")
  def dma_cpu_to_isax_ch1_length: UInt = elem("dma_cpu_to_isax_ch1_length")
  def dma_cpu_to_isax_ch1_stride_x: UInt = elem("dma_cpu_to_isax_ch1_stride_x")
  def dma_cpu_to_isax_ch1_stride_y: UInt = elem("dma_cpu_to_isax_ch1_stride_y")
  def dma_cpu_to_isax_ch1_ready: Bool = elem("dma_cpu_to_isax_ch1_ready")
  def dma_cpu_to_isax_ch1_enable: Bool = elem("dma_cpu_to_isax_ch1_enable")
  def dma_isax_to_cpu_ch1_cpu_addr: UInt = elem("dma_isax_to_cpu_ch1_cpu_addr")
  def dma_isax_to_cpu_ch1_isax_addr: UInt = elem("dma_isax_to_cpu_ch1_isax_addr")
  def dma_isax_to_cpu_ch1_length: UInt = elem("dma_isax_to_cpu_ch1_length")
  def dma_isax_to_cpu_ch1_stride_x: UInt = elem("dma_isax_to_cpu_ch1_stride_x")
  def dma_isax_to_cpu_ch1_stride_y: UInt = elem("dma_isax_to_cpu_ch1_stride_y")
  def dma_isax_to_cpu_ch1_ready: Bool = elem("dma_isax_to_cpu_ch1_ready")
  def dma_isax_to_cpu_ch1_enable: Bool = elem("dma_isax_to_cpu_ch1_enable")
  def dma_poll_for_idle_ch1_res0: Bool = elem("dma_poll_for_idle_ch1_")
  def dma_poll_for_idle_ch1_ready: Bool = elem("dma_poll_for_idle_ch1_ready")
  def rocc_resp_rocc_resp_to_bus_result_rd: UInt = elem("rocc_resp_rocc_resp_to_bus_result_rd")
  def rocc_resp_rocc_resp_to_bus_result_rddata: UInt = elem("rocc_resp_rocc_resp_to_bus_result_rddata")
  def rocc_resp_rocc_resp_to_bus_ready: Bool = elem("rocc_resp_rocc_resp_to_bus_ready")
  def rocc_resp_rocc_resp_to_bus_enable: Bool = elem("rocc_resp_rocc_resp_to_bus_enable")
  def hella_cmd_hella_cmd_to_bus_cmd_addr: UInt = elem("hella_cmd_hella_cmd_to_bus_cmd_addr")
  def hella_cmd_hella_cmd_to_bus_cmd_tag: UInt = elem("hella_cmd_hella_cmd_to_bus_cmd_tag")
  def hella_cmd_hella_cmd_to_bus_cmd_cmd: UInt = elem("hella_cmd_hella_cmd_to_bus_cmd_cmd")
  def hella_cmd_hella_cmd_to_bus_cmd_size: UInt = elem("hella_cmd_hella_cmd_to_bus_cmd_size")
  def hella_cmd_hella_cmd_to_bus_cmd_signed: Bool = elem("hella_cmd_hella_cmd_to_bus_cmd_signed")
  def hella_cmd_hella_cmd_to_bus_cmd_phys: Bool = elem("hella_cmd_hella_cmd_to_bus_cmd_phys")
  def hella_cmd_hella_cmd_to_bus_cmd_data: UInt = elem("hella_cmd_hella_cmd_to_bus_cmd_data")
  def hella_cmd_hella_cmd_to_bus_cmd_mask: UInt = elem("hella_cmd_hella_cmd_to_bus_cmd_mask")
  def hella_cmd_hella_cmd_to_bus_ready: Bool = elem("hella_cmd_hella_cmd_to_bus_ready")
  def hella_cmd_hella_cmd_to_bus_enable: Bool = elem("hella_cmd_hella_cmd_to_bus_enable")

  def csrValueRes0(name: String): UInt = elem(s"${csrPortPrefix(name)}_value_")
  def csrValueReady(name: String): Bool = elem(s"${csrPortPrefix(name)}_value_ready")
  def csrSetSdata(name: String): UInt = elem(s"${csrPortPrefix(name)}_set_${name}_sdata")
  def csrSetReady(name: String): Bool = elem(s"${csrPortPrefix(name)}_set_ready")
  def csrSetEnable(name: String): Bool = elem(s"${csrPortPrefix(name)}_set_enable")
  def instructionCompleted(id: Int): Bool = elem(s"instruction_completed_${id}_")
}

class MainBlackBox(vsrc: Seq[String], csrNames: Seq[String], csrWidth: Int,
                   completionIds: Seq[Int] = Nil)(implicit p: Parameters)
    extends BlackBox
    with HasBlackBoxPath {
  val io = IO(new MainBlackBoxIO(csrNames, csrWidth, completionIds))

  override def desiredName: String = "main"

  private val chipyardDir = System.getProperty("user.dir")
  vsrc.foreach { file =>
    val absolutePath =
      if (new java.io.File(file).isAbsolute) file else s"$chipyardDir/$file"
    addPath(absolutePath)
  }
}

class ApsRoccWrapper(
  tlParams: TLBundleParameters,
  mainVsrc: Seq[String],
  topModuleName: String,
  csrNames: Seq[String],
  nRoCCCSRs: Int,
  nCh: Int = 2,
  isaxAddrWidth: Int = 32)(implicit val p: Parameters)
    extends Module
    with HasCoreParameters {
  require(nCh == 2, s"Current wrapper wiring assumes 2 DMA channels, got $nCh")
  require(isaxAddrWidth == 32, s"Current main blackbox expects 32-bit ISAX addresses, got $isaxAddrWidth")
  require(csrNames.size == nRoCCCSRs,
    s"APS CSR name count (${csrNames.size}) must match RoCC CSR count ($nRoCCCSRs)")

  val io = IO(new Bundle {
    val rocc = new RoCCCoreIOForAPS(nRoCCCSRs)
    val tlA = Decoupled(new TLBundleA(tlParams))
    val tlD = Flipped(Decoupled(new TLBundleD(tlParams)))
  })

  override def desiredName: String = topModuleName

  def fitWidth(x: UInt, width: Int): UInt = {
    if (x.getWidth == width) x
    else if (x.getWidth > width) x(width - 1, 0)
    else Cat(0.U((width - x.getWidth).W), x)
  }

  // Completion toggles are generated by APS for both void and value CIs.
  // Discover their exported ports in the supplied RTL instead of hardcoding
  // benchmark-specific opcode/funct7 values in the SoC configuration.
  private val completionPort = """\binstruction_completed_(\d+)_\b""".r
  private val completionIds = mainVsrc.flatMap { file =>
    val source = scala.io.Source.fromFile(file)
    try completionPort.findAllMatchIn(source.mkString).map(_.group(1).toInt).toList
    finally source.close()
  }.distinct.sorted
  val main = Module(new MainBlackBox(mainVsrc, csrNames, xLen, completionIds))
  val dma = Module(new TlDmaMultichannel(tlParams, nCh = nCh, isaxAddrWidth = isaxAddrWidth))
  val hellaCmdFifo = Module(new HellaCmdFifo)
  val pendingResponses = RegInit(0.U(8.W))
  val pendingVoid = RegInit(false.B)
  val canAcceptCommand = !pendingVoid && Mux(io.rocc.cmd.bits.inst.xd,
    !pendingResponses.andR, pendingResponses === 0.U)

  main.io.clk := clock
  main.io.rst := reset.asBool

  dma.io.tlA <> io.tlA
  dma.io.tlD <> io.tlD

  dma.io.channels(0).write.cpuAddr := main.io.dma_isax_to_cpu_ch0_cpu_addr
  dma.io.channels(0).write.isaxAddr := main.io.dma_isax_to_cpu_ch0_isax_addr
  dma.io.channels(0).write.length := main.io.dma_isax_to_cpu_ch0_length
  dma.io.channels(0).write.strideX := main.io.dma_isax_to_cpu_ch0_stride_x
  dma.io.channels(0).write.strideY := main.io.dma_isax_to_cpu_ch0_stride_y
  dma.io.channels(0).write.enable := main.io.dma_isax_to_cpu_ch0_enable
  dma.io.channels(0).read.cpuAddr := main.io.dma_cpu_to_isax_ch0_cpu_addr
  dma.io.channels(0).read.isaxAddr := main.io.dma_cpu_to_isax_ch0_isax_addr
  dma.io.channels(0).read.length := main.io.dma_cpu_to_isax_ch0_length
  dma.io.channels(0).read.strideX := main.io.dma_cpu_to_isax_ch0_stride_x
  dma.io.channels(0).read.strideY := main.io.dma_cpu_to_isax_ch0_stride_y
  dma.io.channels(0).read.enable := main.io.dma_cpu_to_isax_ch0_enable

  dma.io.channels(1).write.cpuAddr := main.io.dma_isax_to_cpu_ch1_cpu_addr
  dma.io.channels(1).write.isaxAddr := main.io.dma_isax_to_cpu_ch1_isax_addr
  dma.io.channels(1).write.length := main.io.dma_isax_to_cpu_ch1_length
  dma.io.channels(1).write.strideX := main.io.dma_isax_to_cpu_ch1_stride_x
  dma.io.channels(1).write.strideY := main.io.dma_isax_to_cpu_ch1_stride_y
  dma.io.channels(1).write.enable := main.io.dma_isax_to_cpu_ch1_enable
  dma.io.channels(1).read.cpuAddr := main.io.dma_cpu_to_isax_ch1_cpu_addr
  dma.io.channels(1).read.isaxAddr := main.io.dma_cpu_to_isax_ch1_isax_addr
  dma.io.channels(1).read.length := main.io.dma_cpu_to_isax_ch1_length
  dma.io.channels(1).read.strideX := main.io.dma_cpu_to_isax_ch1_stride_x
  dma.io.channels(1).read.strideY := main.io.dma_cpu_to_isax_ch1_stride_y
  dma.io.channels(1).read.enable := main.io.dma_cpu_to_isax_ch1_enable

  main.io.dma_cpu_to_isax_ch0_ready := dma.io.status(0).idle
  main.io.dma_isax_to_cpu_ch0_ready := dma.io.status(0).idle
  main.io.dma_poll_for_idle_ch0_ready := dma.io.status(0).idle
  main.io.dma_poll_for_idle_ch0_res0 := true.B

  main.io.dma_cpu_to_isax_ch1_ready := dma.io.status(1).idle
  main.io.dma_isax_to_cpu_ch1_ready := dma.io.status(1).idle
  main.io.dma_poll_for_idle_ch1_ready := dma.io.status(1).idle
  main.io.dma_poll_for_idle_ch1_res0 := true.B

  main.io.burst_read_0_addr := dma.io.isax.addr
  main.io.burst_read_0_enable := dma.io.isax.rvalid0
  main.io.burst_read_1_enable := dma.io.isax.rvalid1
  main.io.burst_write_addr := dma.io.isax.addr
  main.io.burst_write_data := dma.io.isax.wdata
  main.io.burst_write_enable := dma.io.isax.wvalid
  dma.io.isax.rdata := main.io.burst_read_1_res0

  main.io.rocc_cmd_rocc_cmd_funct := io.rocc.cmd.bits.inst.funct
  main.io.rocc_cmd_rocc_cmd_opcode := io.rocc.cmd.bits.inst.opcode
  main.io.rocc_cmd_rocc_cmd_rd := io.rocc.cmd.bits.inst.rd
  main.io.rocc_cmd_rocc_cmd_rs1 := io.rocc.cmd.bits.inst.rs1
  main.io.rocc_cmd_rocc_cmd_rs1data := fitWidth(io.rocc.cmd.bits.rs1, 32)
  main.io.rocc_cmd_rocc_cmd_rs2 := io.rocc.cmd.bits.inst.rs2
  main.io.rocc_cmd_rocc_cmd_rs2data := fitWidth(io.rocc.cmd.bits.rs2, 32)
  main.io.rocc_cmd_rocc_cmd_xd := io.rocc.cmd.bits.inst.xd
  main.io.rocc_cmd_rocc_cmd_xs1 := io.rocc.cmd.bits.inst.xs1
  main.io.rocc_cmd_rocc_cmd_xs2 := io.rocc.cmd.bits.inst.xs2
  main.io.rocc_cmd_enable := io.rocc.cmd.valid && canAcceptCommand
  io.rocc.cmd.ready := main.io.rocc_cmd_ready && canAcceptCommand

  csrNames.zipWithIndex.foreach { case (name, index) =>
    main.io.csrValueRes0(name) := fitWidth(io.rocc.csrs(index).value, xLen)
    main.io.csrValueReady(name) := true.B
    main.io.csrSetReady(name) := true.B
    io.rocc.csrs(index).stall := false.B
    io.rocc.csrs(index).set := main.io.csrSetEnable(name)
    io.rocc.csrs(index).sdata := fitWidth(main.io.csrSetSdata(name), xLen)
  }

  io.rocc.resp.valid := main.io.rocc_resp_rocc_resp_to_bus_enable
  io.rocc.resp.bits.rd := main.io.rocc_resp_rocc_resp_to_bus_result_rd
  io.rocc.resp.bits.data := fitWidth(main.io.rocc_resp_rocc_resp_to_bus_result_rddata, io.rocc.resp.bits.data.getWidth)
  main.io.rocc_resp_rocc_resp_to_bus_ready := io.rocc.resp.ready

  main.io.hella_resp_enable := io.rocc.mem.resp.valid
  main.io.hella_resp_hella_resp_data := fitWidth(io.rocc.mem.resp.bits.data, 32)
  main.io.hella_resp_hella_resp_tag := fitWidth(io.rocc.mem.resp.bits.tag, 8)
  main.io.hella_resp_hella_resp_cmd := io.rocc.mem.resp.bits.cmd
  main.io.hella_resp_hella_resp_size := io.rocc.mem.resp.bits.size
  main.io.hella_resp_hella_resp_signed := io.rocc.mem.resp.bits.signed

  hellaCmdFifo.io.in.valid := main.io.hella_cmd_hella_cmd_to_bus_enable
  hellaCmdFifo.io.in.bits.addr := main.io.hella_cmd_hella_cmd_to_bus_cmd_addr
  hellaCmdFifo.io.in.bits.tag := main.io.hella_cmd_hella_cmd_to_bus_cmd_tag
  hellaCmdFifo.io.in.bits.cmd := main.io.hella_cmd_hella_cmd_to_bus_cmd_cmd
  hellaCmdFifo.io.in.bits.size := main.io.hella_cmd_hella_cmd_to_bus_cmd_size
  hellaCmdFifo.io.in.bits.signed := main.io.hella_cmd_hella_cmd_to_bus_cmd_signed
  hellaCmdFifo.io.in.bits.phys := main.io.hella_cmd_hella_cmd_to_bus_cmd_phys
  hellaCmdFifo.io.in.bits.data := main.io.hella_cmd_hella_cmd_to_bus_cmd_data
  hellaCmdFifo.io.in.bits.mask := main.io.hella_cmd_hella_cmd_to_bus_cmd_mask
  main.io.hella_cmd_hella_cmd_to_bus_ready := hellaCmdFifo.io.in.ready

  io.rocc.mem.req.valid := hellaCmdFifo.io.out.valid
  hellaCmdFifo.io.out.ready := io.rocc.mem.req.ready
  io.rocc.mem.req.bits.addr := fitWidth(hellaCmdFifo.io.out.bits.addr, io.rocc.mem.req.bits.addr.getWidth)
  io.rocc.mem.req.bits.tag := fitWidth(hellaCmdFifo.io.out.bits.tag, io.rocc.mem.req.bits.tag.getWidth)
  io.rocc.mem.req.bits.cmd := hellaCmdFifo.io.out.bits.cmd
  io.rocc.mem.req.bits.size := hellaCmdFifo.io.out.bits.size
  io.rocc.mem.req.bits.signed := hellaCmdFifo.io.out.bits.signed
  io.rocc.mem.req.bits.phys := hellaCmdFifo.io.out.bits.phys
  io.rocc.mem.req.bits.data := fitWidth(hellaCmdFifo.io.out.bits.data, io.rocc.mem.req.bits.data.getWidth)
  io.rocc.mem.req.bits.mask := fitWidth(hellaCmdFifo.io.out.bits.mask, io.rocc.mem.req.bits.mask.getWidth)
  io.rocc.mem.req.bits.no_alloc := false.B
  io.rocc.mem.req.bits.no_xcpt := false.B
  io.rocc.mem.req.bits.no_resp := false.B
  io.rocc.mem.req.bits.dprv := "b11".U
  io.rocc.mem.req.bits.dv := io.rocc.cmd.bits.status.dv

  io.rocc.mem.s1_kill := false.B
  io.rocc.mem.s1_data := 0.U.asTypeOf(new HellaCacheWriteData)
  io.rocc.mem.s2_kill := false.B
  io.rocc.mem.keep_clock_enabled := true.B

  val pendingId = Reg(UInt(15.W))
  val initialCompletion = Reg(Bool())
  val commandId = Cat(io.rocc.cmd.bits.inst.opcode, 0.U(1.W), io.rocc.cmd.bits.inst.funct)
  val completionNow = MuxLookup(pendingId, false.B)(completionIds.map { id =>
    id.U -> main.io.instructionCompleted(id)
  })
  val completionAtAdmission = MuxLookup(commandId, false.B)(completionIds.map { id =>
    id.U -> main.io.instructionCompleted(id)
  })
  val hasCompletion = completionIds.map(id => commandId === id.U).foldLeft(false.B)(_ || _)
  val responseCommand = io.rocc.cmd.fire && io.rocc.cmd.bits.inst.xd
  switch(Cat(responseCommand, io.rocc.resp.fire)) {
    is("b10".U) { pendingResponses := pendingResponses + 1.U }
    is("b01".U) {
      assert(pendingResponses =/= 0.U, "Unexpected APS register response")
      pendingResponses := pendingResponses - 1.U
    }
  }
  when(io.rocc.cmd.fire && !io.rocc.cmd.bits.inst.xd) {
    assert(io.rocc.cmd.bits.inst.xd || hasCompletion,
      "Void APS instructions require a generated completion port")
    pendingVoid := true.B
    pendingId := commandId
    initialCompletion := completionAtAdmission
  }.elsewhen(pendingVoid && completionNow =/= initialCompletion) {
    pendingVoid := false.B
  }
  io.rocc.busy := pendingResponses =/= 0.U || pendingVoid || io.rocc.cmd.fire
}
