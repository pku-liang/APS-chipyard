SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd ${SCRIPT_DIR}

rm -r generated-src/chipyard.harness.TestHarness.APSRocketConfig/
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

make CONFIG=APSRocketConfig run-binary-debug BINARY=../../tests/hello.riscv LOADMEM=1 -j32 2>&1 | tee run.log

# python vcd_extractor.py output/chipyard.harness.TestHarness.APSRocketConfig/bug_struc.vcd out_bug_struc.vcd TestDriver.testHarness.chiptop0.system.tile_prci_domain.element_reset_domain_rockettile.rocc_blackbox.u_aps_module --submodules
