# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Authors:
# - Philippe Sauter <phsauter@iis.ee.ethz.ch>

# Tools
OPENROAD 		?= openroad

# Directories
# directory of the path to the last called Makefile (this one)
OR_DIR    := $(realpath $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
OR_PROJ_DIR    := $(realpath $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))/$(ISAX_NAME)

# Project variables
# if you are running the entire flow these are set by the top level Makefile
# in that case do not change them here
TOP_DESIGN 	?= croc_chip
PROJ_NAME	?= RocketTile
NETLIST		?= $(realpath $(OR_DIR)/../yosys/$(ISAX_NAME)/out/$(PROJ_NAME)_yosys.v)

SAVE	 	 ?= $(OR_PROJ_DIR)/save
REPORTS	 	 ?= $(OR_PROJ_DIR)/reports
OR_OUT  	 ?= $(OR_PROJ_DIR)/out
OR_OUT_FILES  = $(OR_OUT)/$(PROJ_NAME).def $(OR_OUT)/$(PROJ_NAME).v $(OR_OUT)/$(PROJ_NAME).sdc $(OR_OUT)/$(PROJ_NAME).odb

backend: $(OR_OUT)/$(PROJ_NAME).def

openroad: $(OR_OUT)/$(PROJ_NAME).def

## Place & Route flow using OpenROAD
$(OR_OUT_FILES): $(NETLIST) $(OR_DIR)/scripts/*.tcl $(OR_DIR)/src/*.tcl $(OR_DIR)/src/*.sdc
	mkdir -p $(SAVE)
	mkdir -p $(REPORTS)
	mkdir -p $(OR_OUT)
	mkdir -p $(OR_PROJ_DIR)
	echo $(CROC_ROOT)
	cd $(OR_PROJ_DIR) && \
	NETLIST="$(NETLIST)" \
	TOP_DESIGN="$(TOP_DESIGN)" \
	PROJ_NAME="$(PROJ_NAME)" \
	SAVE="$(SAVE)" \
	REPORTS="$(REPORTS)" \
	PDK="$(CROC_ROOT)/ihp13/pdk" \
	QT_QPA_PLATFORM=$$(if [ -z "$$DISPLAY" ]; then echo "offscreen"; else echo "$$QT_QPA_PLATFORM"; fi) \
	$(OPENROAD) ../scripts/chip.tcl \
		$$(if [ "$(gui)" = "1" ]; then echo "-gui"; fi) \
		-log $(PROJ_NAME).log \
		2>&1 | TZ=UTC gawk '{ print strftime("[%Y-%m-%d %H:%M %Z]"), $$0 }';

or_clean:
	rm -rf $(SAVE)
	rm -rf $(REPORTS)
	rm -rf $(OR_OUT)
	rm -f $(PROJ_NAME).log

start_openroad:
	cd $(OR_PROJ_DIR) && \
	PROJ_NAME="$(PROJ_NAME)" \
	SAVE="$(SAVE)" \
	REPORTS="$(REPORTS)" \
	$(OPENROAD) scripts/startup.tcl

start_openroad_gui:
	cd $(OR_PROJ_DIR) && \
	PROJ_NAME="$(PROJ_NAME)" \
	SAVE="$(SAVE)" \
	REPORTS="$(REPORTS)" \
	$(OPENROAD) -gui scripts/startup.tcl

.PHONY: backend openroad or_clean start_openroad start_openroad_gui
