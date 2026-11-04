package chipyard

import org.chipsalliance.cde.config.Config
import org.yaml.snakeyaml.Yaml
import scala.jdk.CollectionConverters._
import scala.io.Source
import aps.{APSCSRConfig, APSConfig}

object APSConfigParser {
  private def loadYaml(path: String): Map[String, Any] = {
    val source = Source.fromFile(path)
    try {
      asMap(new Yaml().load[Any](source.mkString), path)
    } finally {
      source.close()
    }
  }

  private def asMap(value: Any, path: String): Map[String, Any] = value match {
    case map: java.util.Map[_, _] =>
      map.asScala.toMap.map { case (key, value) => key.toString -> value }
    case null =>
      throw new IllegalArgumentException(s"Missing YAML map at $path")
    case other =>
      throw new IllegalArgumentException(s"Expected YAML map at $path, got ${other.getClass.getSimpleName}")
  }

  private def asList(value: Any, path: String): List[Any] = value match {
    case list: java.util.List[_] => list.asScala.toList
    case null => Nil
    case other =>
      throw new IllegalArgumentException(s"Expected YAML list at $path, got ${other.getClass.getSimpleName}")
  }

  private def required(root: Map[String, Any], name: String): Any =
    root.getOrElse(name, throw new IllegalArgumentException(s"Missing required APS config field '$name'"))

  private def asString(value: Any, path: String): String = value match {
    case s: String => s
    case null => throw new IllegalArgumentException(s"Missing string at $path")
    case other => other.toString
  }

  private def asStringList(value: Any, path: String): List[String] =
    asList(value, path).zipWithIndex.map { case (item, index) => asString(item, s"$path[$index]") }

  private def asInt(value: Any, path: String): Int =
    asBigInt(value, path).toInt

  private def asBigInt(value: Any, path: String): BigInt = value match {
    case i: java.lang.Integer => BigInt(i.intValue)
    case l: java.lang.Long => BigInt(l.longValue)
    case bi: java.math.BigInteger => BigInt(bi)
    case bd: java.math.BigDecimal => BigInt(bd.toBigInteger)
    case s: String =>
      val clean = s.replace("_", "")
      if (clean.startsWith("0x") || clean.startsWith("0X")) BigInt(clean.drop(2), 16)
      else BigInt(clean)
    case null =>
      throw new IllegalArgumentException(s"Missing integer at $path")
    case other =>
      throw new IllegalArgumentException(s"Expected integer at $path, got ${other.getClass.getSimpleName}")
  }

  private def parseCsrs(value: Any): List[APSCSRConfig] =
    asList(value, "csrs").zipWithIndex.map { case (item, index) =>
      val path = s"csrs[$index]"
      val csr = asMap(item, path)
      APSCSRConfig(
        id = asInt(required(csr, "id"), s"$path.id"),
        name = asString(required(csr, "name"), s"$path.name"),
        mask = asBigInt(required(csr, "mask"), s"$path.mask"),
        init = csr.get("init").map(asBigInt(_, s"$path.init")).getOrElse(BigInt(0))
      )
    }

  def parseConfig(path: String = sys.env.getOrElse("APS_CONFIG", "aps_config.yaml")): APSConfig = {
    val root = loadYaml(path)
    APSConfig(
      backend = asString(required(root, "backend"), "backend"),
      arch = asString(required(root, "arch"), "arch"),
      core_count = asInt(required(root, "core_count"), "core_count"),
      top_module = asString(required(root, "top_module"), "top_module"),
      name = asString(required(root, "name"), "name"),
      vsrc = asStringList(required(root, "vsrc"), "vsrc"),
      maxBurstBytes = root.get("maxBurstBytes").map(asInt(_, "maxBurstBytes")).getOrElse(256),
      nXacts = root.get("nXacts").map(asInt(_, "nXacts")).getOrElse(1),
      csrs = root.get("csrs").map(parseCsrs).getOrElse(Nil)
    )
  }
}

class APSRocketBaselineConfig extends Config(
  {
    val apsConf = APSConfigParser.parseConfig()
    val base = new freechips.rocketchip.subsystem.WithCacheBlockBytes(128) ++
               new freechips.rocketchip.rocket.WithL1DCacheSets(32) ++  // Reduce sets to satisfy 4KiB constraint
               new freechips.rocketchip.rocket.WithL1ICacheSets(32) ++  // Keep I$ sets in sync
              new freechips.rocketchip.rocket.WithL1ICacheRowBits(32) ++
              new freechips.rocketchip.rocket.WithL1DCacheRowBits(32)
    val base_with_arch = if (apsConf.arch == "rv32") {
      base ++ new freechips.rocketchip.rocket.WithRV32
    } else if (apsConf.arch == "rv64") {
      base
    } else {
      throw new Exception(s"Unsupported arch: ${apsConf.arch} in aps_config.yaml")
    }
    base_with_arch ++ new freechips.rocketchip.rocket.WithNBigCores(apsConf.core_count) ++ new chipyard.config.AbstractConfig
  }
)

class APSRocketConfig extends Config(
  {
    val apsConf = APSConfigParser.parseConfig()
    val base = new freechips.rocketchip.subsystem.WithCacheBlockBytes(128) ++
               new freechips.rocketchip.rocket.WithL1DCacheSets(32) ++  // Reduce sets to satisfy 4KiB constraint
               new freechips.rocketchip.rocket.WithL1ICacheSets(32) ++  // Keep I$ sets in sync
              new freechips.rocketchip.rocket.WithL1ICacheRowBits(32) ++
              new freechips.rocketchip.rocket.WithL1DCacheRowBits(32) ++ 
               new aps.WithAPSAccel(apsConf)
    val base_with_arch = if (apsConf.arch == "rv32") {
      base ++ new freechips.rocketchip.rocket.WithRV32
    } else if (apsConf.arch == "rv64") {
      base
    } else {
      throw new Exception(s"Unsupported arch: ${apsConf.arch} in aps_config.yaml")
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
      throw new Exception(s"Unsupported arch: ${apsConf.arch} in aps_config.yaml")
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
    throw new Exception(s"Unsupported arch: ${apsConf.arch} in aps_config.yaml")
  }
  base_with_arch ++ 
  new freechips.rocketchip.rocket.WithNSmallCores(apsConf.core_count) ++ 
  new freechips.rocketchip.rocket.WithNBreakpoints(4) ++
  new chipyard.APSRocketFPGABaseConfig
  }
)
