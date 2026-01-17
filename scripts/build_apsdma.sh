#!/bin/bash
# ApsDMA 构建脚本
# 用法: ./scripts/build_apsdma.sh [config_file]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查环境
check_environment() {
    info "Checking environment..."

    # 检查是否在正确的目录
    if [ ! -f "apsdma_config.json" ] && [ ! -f "aps_config.json" ]; then
        error "Not in chipyard root directory"
        error "Please run this script from /home/xys/aps-env-v2/aps-chipyard"
        exit 1
    fi

    # 检查verilator
    if ! command -v verilator &> /dev/null; then
        error "Verilator not found in PATH"
        error "Please source env.sh first: source env.sh"
        exit 1
    fi

    info "Environment OK"
}

# 配置文件管理
setup_config() {
    local config_file="${1:-apsdma_config.json}"

    if [ ! -f "$config_file" ]; then
        warn "Config file not found: $config_file"
        warn "Creating default apsdma_config.json..."

        cat > apsdma_config.json <<EOF
{
  "backend": "verilator",
  "arch": "rv64",
  "core_count": 1,
  "top_module": "tilelink_only_dma",
  "name": "tl_dma",
  "vsrc": [
    "generators/apsdma/example/tilelink_only_dma.sv"
  ],
  "max_burst_bytes": 256,
  "n_xacts": 1
}
EOF
        info "Created default apsdma_config.json"
    else
        info "Using config file: $config_file"

        # 如果使用非默认配置，复制为apsdma_config.json
        if [ "$config_file" != "apsdma_config.json" ]; then
            cp "$config_file" apsdma_config.json
            info "Copied $config_file to apsdma_config.json"
        fi
    fi

    # 显示配置内容
    info "Configuration:"
    cat apsdma_config.json | grep -v "^[[:space:]]*$"
}

# 验证SystemVerilog文件
verify_verilog() {
    info "Verifying SystemVerilog files..."

    # 从JSON中提取vsrc列表
    local vsrc_files=$(grep '"vsrc"' apsdma_config.json -A 10 | grep '\.sv"' | sed 's/.*"\(.*\)".*/\1/')

    local missing=0
    for file in $vsrc_files; do
        if [ ! -f "$file" ]; then
            error "SystemVerilog file not found: $file"
            missing=1
        else
            info "Found: $file"
        fi
    done

    if [ $missing -eq 1 ]; then
        error "Some SystemVerilog files are missing"
        exit 1
    fi

    info "All SystemVerilog files found"
}

# 清理之前的构建
clean_build() {
    if [ "$1" == "--clean" ]; then
        info "Cleaning previous build..."
        cd sims/verilator
        make clean 2>/dev/null || true
        cd ../..
        info "Clean completed"
    fi
}

# 构建仿真器
build_simulator() {
    local config="${1:-ApsDMARocketConfig}"
    local debug="${2:-0}"

    info "Building simulator with config: $config"

    cd sims/verilator

    if [ "$debug" == "1" ]; then
        info "Building with debug support (waveform enabled)..."
        make debug CONFIG=$config
    else
        info "Building optimized version..."
        make CONFIG=$config
    fi

    local build_status=$?
    cd ../..

    if [ $build_status -eq 0 ]; then
        info "Build completed successfully!"
        return 0
    else
        error "Build failed with status $build_status"
        return 1
    fi
}

# 显示构建结果
show_results() {
    local config="${1:-ApsDMARocketConfig}"

    info "Build artifacts:"

    local sim_path="sims/verilator/simulator-chipyard-$config"
    local sim_debug_path="sims/verilator/simulator-chipyard-$config-debug"

    if [ -f "$sim_path" ]; then
        ls -lh "$sim_path"
        info "Simulator ready: $sim_path"
    fi

    if [ -f "$sim_debug_path" ]; then
        ls -lh "$sim_debug_path"
        info "Debug simulator ready: $sim_debug_path"
    fi

    info ""
    info "Generated sources:"
    local gen_dir="sims/verilator/generated-src/chipyard.$config"
    if [ -d "$gen_dir" ]; then
        ls -lh "$gen_dir/gen-collateral/" | grep "\.sv$" | head -5
    fi
}

# 运行快速测试
quick_test() {
    local config="${1:-ApsDMARocketConfig}"
    local sim_path="sims/verilator/simulator-chipyard-$config"

    if [ ! -f "$sim_path" ]; then
        warn "Simulator not found, skipping test"
        return
    fi

    info "Running quick test..."

    # 查找一个简单的测试程序
    local test_binary=""
    if [ -f "tests/hello.riscv" ]; then
        test_binary="tests/hello.riscv"
    elif [ -f "tests/rv64ui-p-add.riscv" ]; then
        test_binary="tests/rv64ui-p-add.riscv"
    else
        warn "No test binary found, skipping test"
        return
    fi

    info "Running: $test_binary"
    cd sims/verilator
    ./"simulator-chipyard-$config" "../../$test_binary" 2>&1 | head -20
    local test_status=$?
    cd ../..

    if [ $test_status -eq 0 ]; then
        info "Quick test PASSED"
    else
        warn "Quick test exit status: $test_status"
    fi
}

# 显示使用说明
show_usage() {
    cat <<EOF
ApsDMA Build Script

Usage:
  $0 [OPTIONS] [config_file]

Options:
  --clean          Clean previous build before starting
  --debug          Build with debug support (waveform enabled)
  --test           Run quick test after build
  --config=NAME    Use specific Scala config class (default: ApsDMARocketConfig)
  --help           Show this help message

Examples:
  # Basic build with default config
  $0

  # Use custom JSON config
  $0 my_config.json

  # Clean build with debug
  $0 --clean --debug

  # Build and test
  $0 --test

  # Use custom Scala config
  $0 --config=MyCustomConfig

Configuration:
  The script looks for apsdma_config.json in the current directory.
  If not found, it creates a default configuration.

  JSON format:
  {
    "backend": "verilator",
    "arch": "rv64",
    "core_count": 1,
    "top_module": "tilelink_only_dma",
    "name": "tl_dma",
    "vsrc": ["path/to/dma.sv"],
    "max_burst_bytes": 256,
    "n_xacts": 1
  }

After Build:
  # Run tests
  cd sims/verilator
  ./simulator-chipyard-ApsDMARocketConfig tests/hello.riscv

  # Generate waveform
  ./simulator-chipyard-ApsDMARocketConfig-debug +vcdfile=wave.vcd tests/hello.riscv

For more information, see APSDMA_USAGE.md

EOF
}

# 主函数
main() {
    local config_file=""
    local scala_config="ApsDMARocketConfig"
    local do_clean=0
    local do_debug=0
    local do_test=0

    # 解析参数
    while [ $# -gt 0 ]; do
        case "$1" in
            --clean)
                do_clean=1
                shift
                ;;
            --debug)
                do_debug=1
                shift
                ;;
            --test)
                do_test=1
                shift
                ;;
            --config=*)
                scala_config="${1#*=}"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                config_file="$1"
                shift
                ;;
        esac
    done

    # 显示横幅
    echo "=========================================="
    echo "  ApsDMA Build Script"
    echo "=========================================="
    echo ""

    # 执行构建流程
    check_environment
    setup_config "$config_file"
    verify_verilog

    if [ $do_clean -eq 1 ]; then
        clean_build "--clean"
    fi

    if build_simulator "$scala_config" "$do_debug"; then
        show_results "$scala_config"

        if [ $do_test -eq 1 ]; then
            quick_test "$scala_config"
        fi

        echo ""
        info "Build successful!"
        info "Next steps:"
        echo "  cd sims/verilator"
        echo "  ./simulator-chipyard-$scala_config ../../tests/hello.riscv"

        if [ $do_debug -eq 1 ]; then
            echo "  ./simulator-chipyard-$scala_config-debug +vcdfile=wave.vcd ../../tests/hello.riscv"
        fi

        exit 0
    else
        error "Build failed!"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check apsdma_config.json for correct paths"
        echo "  2. Verify SystemVerilog files exist"
        echo "  3. Check build log above for errors"
        echo "  4. See APSDMA_USAGE.md for more details"
        exit 1
    fi
}

# 运行主函数
main "$@"
