package chipyard

import org.chipsalliance.cde.config.Config
import org.json4s._
import org.json4s.native.JsonMethods._
import org.json4s.{DefaultFormats, Formats}
import scala.io.Source
import aps.APSConfig

object APSConfigParser {
  implicit val formats: Formats = DefaultFormats

  def parseConfig(path: String = "aps_config.json"): APSConfig = {
    val jsonStr = Source.fromFile(path).getLines().mkString
    val json = parse(jsonStr)
    json.extract[APSConfig]
  }
}

class APSRocketConfig extends Config(
  {
    val apsConf = APSConfigParser.parseConfig()
    val base = new freechips.rocketchip.subsystem.WithCacheBlockBytes(128) ++
               new freechips.rocketchip.rocket.WithL1DCacheSets(32) ++  // Reduce sets to satisfy 4KiB constraint
               new freechips.rocketchip.rocket.WithL1ICacheSets(32) ++  // Keep I$ sets in sync
               new aps.WithAPSAccel(apsConf)
    val base_with_arch = if (apsConf.arch == "rv32") {
      base ++ new freechips.rocketchip.rocket.WithRV32
    } else if (apsConf.arch == "rv64") {
      base
    } else {
      throw new Exception(s"Unsupported arch: ${apsConf.arch} in aps_config.json")
    }
    base_with_arch ++ new freechips.rocketchip.rocket.WithNBigCores(apsConf.core_count) ++ new chipyard.config.AbstractConfig
  }
)

class APSRocketASICConfig extends Config(
  {
    val apsConf = APSConfigParser.parseConfig()
    val base = new aps.WithAPSAccel(apsConf) ++
      new chipyard.harness.WithDontTouchChipTopPorts(false) ++        // TODO FIX: Don't dontTouch the ports
      new testchipip.soc.WithNoScratchpads ++                         // All memory is the Rocket TCMs
      new freechips.rocketchip.subsystem.WithIncoherentBusTopology ++ // use incoherent bus topology
      new freechips.rocketchip.subsystem.WithNBanks(0) ++             // remove L2$
      new freechips.rocketchip.subsystem.WithNoMemPort ++             // remove backing memory
      new freechips.rocketchip.rocket.WithL1ICacheRowBits(32) ++
      new freechips.rocketchip.rocket.WithL1DCacheRowBits(32) ++ 
      new freechips.rocketchip.subsystem.WithoutTLMonitors

    val base_with_arch = if (apsConf.arch == "rv32") {
      base ++ new freechips.rocketchip.rocket.WithRV32
    } else if (apsConf.arch == "rv64") {
      base
    } else {
      throw new Exception(s"Unsupported arch: ${apsConf.arch} in aps_config.json")
    }
    base_with_arch ++ new freechips.rocketchip.rocket.With1TinyCore ++ new chipyard.config.AbstractConfig
  }
)


class APSRocketFPGABaseConfig extends Config(
  // Memory configuration - 2GB max for 32-bit
  new freechips.rocketchip.subsystem.WithExtMemSize(0x80000000L) ++      // 2GB external memory

  // Enable AXI4 ports instead of default TL ports
  new freechips.rocketchip.subsystem.WithDefaultMMIOPort ++              // Enable AXI4 MMIO master port for peripherals
  new freechips.rocketchip.subsystem.WithDefaultSlavePort ++             // Enable AXI4 slave port

  // Debug and interrupts
  new freechips.rocketchip.subsystem.WithDebugSBA ++                     // Enable system bus access for debug
  new freechips.rocketchip.subsystem.WithNExtTopInterrupts(8) ++         // 8 external interrupts

  // Memory system
  new freechips.rocketchip.subsystem.WithNMemoryChannels(1) ++           // Single memory channel
  new freechips.rocketchip.subsystem.WithNBanks(1) ++                    // Single bank
  new testchipip.soc.WithNoScratchpads ++
  
  // Device tree settings
  new freechips.rocketchip.subsystem.WithDTS("chipyard,rocket32", Nil) ++

  new freechips.rocketchip.subsystem.WithoutTLMonitors ++
  new testchipip.serdes.WithNoSerialTL ++
  new chipyard.config.WithNoUART ++ // use UART for the UART-TSI thing instad
  new testchipip.tsi.WithUARTTSIClient ++

  // clock settings
  new chipyard.config.WithUniformBusFrequencies(80.0) ++

  // Base configuration
  new chipyard.config.AbstractConfig
)

/**
 * Single small 32-bit Rocket core with AXI ports
 * Suitable for embedded applications and FPGAs
 */
class APSRocketFPGAConfig extends Config(
  {
  val apsConf = APSConfigParser.parseConfig()
  val base = new freechips.rocketchip.subsystem.WithCacheBlockBytes(128) ++
              new freechips.rocketchip.rocket.WithL1DCacheSets(32) ++  // Reduce sets to satisfy 4KiB constraint
              new freechips.rocketchip.rocket.WithL1ICacheSets(32) ++  // Keep I$ sets in sync
              new aps.WithAPSAccel(apsConf)
  val base_with_arch = if (apsConf.arch == "rv32") {
    base ++ new freechips.rocketchip.rocket.WithRV32
  } else if (apsConf.arch == "rv64") {
    base
  } else {
    throw new Exception(s"Unsupported arch: ${apsConf.arch} in aps_config.json")
  }
  base_with_arch ++ 
  new freechips.rocketchip.rocket.WithNSmallCores(apsConf.core_count) ++ 
  new freechips.rocketchip.rocket.WithNBreakpoints(4) ++
  new chipyard.APSRocketFPGABaseConfig
  }
)
