# Copyright 2024 ETH Zurich and University of Bologna.
# Copyright 2025 APS
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51 AND Apache-2.0
#
# Authors:
# - Philippe Sauter <phsauter@iis.ee.ethz.ch>

# Backend constraints

############
## Global ##
############

source ../src/instances.tcl


#############################
## Driving Cells and Loads ##
#############################

# As a default, drive multiple GPIO pads and be driven by one.
# accomodate for driving up to 2 74HC pads plus a 5pF trace
# set_load [expr 2 * 5.0 + 5.0] [all_outputs]
# set_driving_cell [all_inputs] -lib_cell sg13g2_IOPadOut16mA -pin pad


##################
## Input Clocks ##
##################
puts "Clocks..."

# Get target period from environment variable, default to 6.0 ns (166.67 MHz)
if {[info exists ::env(TARGET_PERIOD)]} {
    set TCK_SYS $::env(TARGET_PERIOD)
} else {
    set TCK_SYS 6.0
}
puts "Target clock period: $TCK_SYS ns"
create_clock -name clk_sys -period $TCK_SYS [get_ports clock]

##################################
## Clock Groups & Uncertainties ##
##################################

# We set reasonable uncertainties in their transistion timing
# and transition (rise/fall) times for all clocks (ns)
# set_clock_uncertainty 0.1 [all_clocks]
# set_clock_transition  0.2 [all_clocks]

# set non_clock_inputs [lsearch -inline -all -not -exact [all_inputs] clk_sys]
# set_input_delay  [expr $TCK_SYS * 0.3 ] -clock clk_sys $non_clock_inputs 
# set_output_delay [expr $TCK_SYS * 0.3 ] -clock clk_sys [all_outputs]