#!/bin/bash

# Parse options
SKIP_BUILD=false
if [[ "$1" == "-d" ]]; then
  SKIP_BUILD=true
  shift
fi

# Chipyard base directory - modify this path to make the script portable
CHIPYARD_ROOT="/home/zyy/aps-mlir/aps-mlir-chipyard"
RISCV_TOOLCHAIN_ROOT="/home/share/zyy-riscv-toolchain/root"

# Configuration name - modify this to use different Chipyard configurations
CONFIG_SHORT="APSRocketConfig"

# Test case name - modify this to run different tests
# TEST_CASE="test_v3ddist_vs"
# TEST_CASE="test_v3ddist_vv"
# TEST_CASE="test_vcovmat3d"
# TEST_CASE="test_vfpsmax"
# TEST_CASE="test_vgemv3d"
# TEST_CASE="test_deca_decompress"
# TEST_CASE="test_gemm"
# TEST_CASE="test_vcovmat3d_vs"
# TEST_CASE="cy_vcovmat3d_vs"
TEST_CASE="pcl_e2e"

# Derived paths
VERILATOR_DIR="${CHIPYARD_ROOT}/sims/verilator"
DRAMSIM2_DIR="${CHIPYARD_ROOT}/tools/DRAMSim2"
CONFIG_NAME="chipyard.harness.TestHarness.${CONFIG_SHORT}"
GENERATED_SRC="${VERILATOR_DIR}/generated-src/${CONFIG_NAME}"
DRAMSIM2_INI="${CHIPYARD_ROOT}/generators/testchipip/src/main/resources/dramsim2_ini"
OUTPUT_DIR="${VERILATOR_DIR}/output/${CONFIG_NAME}"
TEST_BINARY="${CHIPYARD_ROOT}/tests/${TEST_CASE}.riscv"

if [ "$SKIP_BUILD" = false ]; then
  verilator --main --timing --cc --exe -CFLAGS " -O3 -std=c++17 -I${RISCV_TOOLCHAIN_ROOT}/include -I${DRAMSIM2_DIR} -I${GENERATED_SRC}/gen-collateral   -DVERILATOR" -LDFLAGS " -L${RISCV_TOOLCHAIN_ROOT}/lib -Wl,-rpath,${RISCV_TOOLCHAIN_ROOT}/lib -L${VERILATOR_DIR} -L${DRAMSIM2_DIR} -lriscv -lfesvr -ldramsim "   --threads 32 --threads-dpi all -O3 --x-assign fast --x-initial fast --output-split 10000 --output-split-cfuncs 100 --assert -Wno-fatal --timescale 1ns/1ps --max-num-width 1048576 +define+CLOCK_PERIOD=1.0 +define+RESET_DELAY=777.7 +define+PRINTF_COND=TestDriver.printf_cond +define+STOP_COND=\!TestDriver.reset +define+MODEL=TestHarness +define+RANDOMIZE_MEM_INIT +define+RANDOMIZE_REG_INIT +define+RANDOMIZE_GARBAGE_ASSIGN +define+RANDOMIZE_INVALID_ASSIGN +define+VERILATOR --top-module TestDriver --vpi  -f ${GENERATED_SRC}/sim_files.common.f +define+DEBUG  -o ${VERILATOR_DIR}/simulator-chipyard.harness-${CONFIG_SHORT}-debug  --trace -Mdir ${GENERATED_SRC}/${CONFIG_NAME}.debug --trace-underscore

  touch ${GENERATED_SRC}/${CONFIG_NAME}.debug/VTestDriver.mk

  make VM_PARALLEL_BUILDS=1 -C ${GENERATED_SRC}/${CONFIG_NAME}.debug -f VTestDriver.mk -j
else
  echo "Skipping build (-d flag)"
fi

# Function to run Python script - will be called on normal exit or interrupt
run_python_extractor() {
  echo "Running VCD extractor..."
  python vcd_extractor.py ${OUTPUT_DIR}/${TEST_CASE}.vcd ${VERILATOR_DIR}/${TEST_CASE}_slim.vcd TestDriver.testHarness.chiptop0.system.tile_prci_domain.element_reset_domain_rockettile.rocc --submodules
}

# Set trap to ensure Python runs even on Ctrl+C
trap 'echo "Caught interrupt, running Python extractor..."; run_python_extractor; exit 130' INT TERM

# Run simulator
(set -o pipefail &&  ${VERILATOR_DIR}/simulator-chipyard.harness-${CONFIG_SHORT}-debug \
        +permissive \
        +dramsim +dramsim_ini_dir=${DRAMSIM2_INI} +max-cycles=10000000   +loadmem=${TEST_BINARY}  \
        +verbose \
        +permissive-off \
        ${TEST_BINARY} \
         \
        </dev/null 2> >(spike-dasm > ${OUTPUT_DIR}/${TEST_CASE}.out) | tee ${OUTPUT_DIR}/${TEST_CASE}.log)

# Run Python extractor on normal completion
run_python_extractor


        # +vcdfile=${OUTPUT_DIR}/${TEST_CASE}.vcd \