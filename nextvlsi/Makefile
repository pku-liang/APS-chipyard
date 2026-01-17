#########################################################################################
# vlsi makefile
#########################################################################################

#########################################################################################
# general path variables
#########################################################################################
base_dir=$(abspath ..)
vlsi_dir=$(abspath .)
sim_dir=$(abspath .)

CONFIG            ?= APSRocketASICConfig
ENABLE_YOSYS_FLOW = 1

include $(base_dir)/variables.mk

#########################################################################################
# vlsi types and rules
#########################################################################################
sim_name           ?= vcs # needed for GenerateSimFiles, but is unused

VLSI_TOP           ?= $(TOP)
VLSI_MODEL_DUT_NAME ?= chiptop0
# If overriding, this should be relative to $(vlsi_dir)
VLSI_OBJ_DIR       ?= build
export USE_CHISEL6        = 1
OBJ_DIR          ?= $(vlsi_dir)/$(VLSI_OBJ_DIR)/$(long_name)-$(TOP)
APS_CONFIG ?= $(base_dir)/aps_config.json
ISAX_NAME ?= default

#########################################################################################
# general rules
#########################################################################################
.PHONY: default
default: openroad

#########################################################################################
# import other necessary rules and variables
#########################################################################################
include $(base_dir)/common.mk

#########################################################################################
# process RTL
#########################################################################################

VLSI_RTL = $(vlsi_dir)/yosys/$(ISAX_NAME)/syn.f

RTL_DEPS = $(TOP_MODS_FILELIST) $(TOP_SMEMS_FILE) $(EXT_FILELISTS)

$(VLSI_RTL): $(RTL_DEPS) $(APS_CONFIG)
	mkdir -p $(vlsi_dir)/yosys/$(ISAX_NAME)
	cat $(TOP_MODS_FILELIST) | sort -u > $@
	echo $(realpath $(vlsi_dir)/ihp13/tc_sram.sv) >> $@
	echo $(realpath $(vlsi_dir)/yosys/src/sram_conf.v) >> $@
	cd $(base_dir) && cat "$(APS_CONFIG)" | jq -r '.vsrc[]' | xargs -I {} realpath {} >> "$@"

YOSYS_FILELIST = $(vlsi_dir)/yosys/$(ISAX_NAME)/syn.tcl

YOSYS_LOAD_VERILOG_PREFIX = yosys read_verilog -sv -overwrite 

$(YOSYS_FILELIST) : $(VLSI_RTL) $(APS_CONFIG)
	sed 's/^/$(YOSYS_LOAD_VERILOG_PREFIX) /' $< > $@

include yosys/yosys.mk
include openroad/openroad.mk

#########################################################################################
# general cleanup rule
#########################################################################################
.PHONY: clean clean-yosys

clean-yosys:
	rm -r $(NETLIST) $(NETLIST_DEBUG) yosys/reports/ yosys/out/ yosys/tmp/
clean:
	rm -r generated-src/ $(NETLIST) $(NETLIST_DEBUG)