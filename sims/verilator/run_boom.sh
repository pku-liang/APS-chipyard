#!/bin/bash

CHIPYARD_ROOT="/home/zyy/aps-mlir/aps-mlir-chipyard"
TEST_CASE="hello"
CONFIG_SHORT="SmallBoomV3Config"

VERILATOR_DIR="${CHIPYARD_ROOT}/sims/verilator"
DRAMSIM2_DIR="${CHIPYARD_ROOT}/tools/DRAMSim2"
CONFIG_NAME="chipyard.harness.TestHarness.${CONFIG_SHORT}"
GENERATED_SRC="${VERILATOR_DIR}/generated-src/${CONFIG_NAME}"
DRAMSIM2_INI="${CHIPYARD_ROOT}/generators/testchipip/src/main/resources/dramsim2_ini"
OUTPUT_DIR="${VERILATOR_DIR}/output/${CONFIG_NAME}"
TEST_BINARY="${CHIPYARD_ROOT}/tests/${TEST_CASE}.riscv"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd ${SCRIPT_DIR}

# Parse options
REBUILD=false
if [[ "$1" == "-b" ]]; then
  REBUILD=true
  shift
fi

rm -r generated-src/chipyard.harness.TestHarness.${CONFIG_SHORT}/
BUILD_DIR="../../tests/build"

if [ ! -d "$BUILD_DIR" ]; then
  mkdir -p "$BUILD_DIR"
  cd "$BUILD_DIR"
  cmake ..
else
  cd "$BUILD_DIR"
fi

make -j$(nproc)
cd -

if [ "$REBUILD" = true ]; then
  make CONFIG=${CONFIG_SHORT} run-binary-debug BINARY=${TEST_BINARY} LOADMEM=1 -j32 2>&1 | tee run.log
else 
  (set -o pipefail &&  ${VERILATOR_DIR}/simulator-chipyard.harness-${CONFIG_SHORT}-debug \
          +permissive \
          +dramsim +dramsim_ini_dir=${DRAMSIM2_INI} +max-cycles=10000000   +loadmem=${TEST_BINARY}  \
          +vcdfile=${OUTPUT_DIR}/${TEST_CASE}.vcd \
          +verbose \
          +permissive-off \
          ${TEST_BINARY} \
          \
          </dev/null 2> >(spike-dasm > ${OUTPUT_DIR}/${TEST_CASE}.out) | tee ${OUTPUT_DIR}/${TEST_CASE}.log)
fi

# python vcd_extractor.py output/chipyard.harness.TestHarness.APSRocketConfig/bug_struc.vcd out_bug_struc.vcd TestDriver.testHarness.chiptop0.system.tile_prci_domain.element_reset_domain_rockettile.rocc_blackbox.u_aps_module --submodules
