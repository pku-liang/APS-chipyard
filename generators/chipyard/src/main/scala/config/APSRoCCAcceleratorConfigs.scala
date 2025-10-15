// Copyright 2025 APS
// SPDX-License-Identifier: Apache-2.0

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
    val base = new aps.WithAPSAccel(apsConf)
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
      new freechips.rocketchip.rocket.WithL1DCacheRowBits(32)

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

// =============================================================
// Deprecated configs
// =============================================================

// class APSBOOMConfig extends Config(
//   new aps.WithAPSAccel ++
//   new boom.v4.common.WithNSmallBooms(1) ++
//   new chipyard.config.AbstractConfig
// )

// class APSRocketRV64Config extends Config(
//   new aps.WithAPSAccel ++
//   new freechips.rocketchip.rocket.WithNSmallCores(1) ++
//   new chipyard.config.AbstractConfig
// )

// class APSRocketRV32Config extends Config(
//   new aps.WithAPSAccel ++
//   new freechips.rocketchip.rocket.WithRV32 ++
//   new freechips.rocketchip.rocket.WithNBigCores(1) ++
//   new chipyard.config.AbstractConfig
// )