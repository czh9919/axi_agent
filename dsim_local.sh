#!/bin/bash
# dsim_local.sh
# Bash script to simulate design with Altair® DSim™ on local machine

# Set up environment
set -e

# Analyze and Elaborate design
dsim -top top_tb -genimage image -uvm 1.2 -f /tb/tb.f -f rtl/rtl.f -timescale 1ns/1ps +acc+b

# Simulate design
dsim -image image -uvm 1.2 +UVM_NO_RELNOTES +UVM_TESTNAME=axi_lite_base_test
