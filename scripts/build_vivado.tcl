#=====================================================================
# scripts/build_vivado.tcl -- non-project (batch) build for the Basys 3
#
#   cd <repo root>
#   vivado -mode batch -source scripts/build_vivado.tcl
#
# Produces build/top_basys3.bit plus timing and utilization reports.
# Non-project mode is used deliberately: the whole build is reproducible
# from source control, with no .xpr to check in.
#=====================================================================

set part      xc7a35tcpg236-1
set top       top_basys3
set root      [file normalize [file dirname [info script]]/..]
set outdir    $root/build

file mkdir $outdir
cd $outdir

#------------------------------- sources ------------------------------
read_verilog [glob $root/rtl/*.v]
set_property include_dirs $root/rtl [current_fileset]

read_xdc $root/constr/Basys3.xdc

# Memory images. Vivado resolves $readmemh paths relative to the
# working directory during synthesis, so copy them next to the build.
foreach f {imem.hex dmem.hex} {
    if {[file exists $root/sw/$f]} {
        file copy -force $root/sw/$f $outdir/$f
    } else {
        puts "ERROR: $root/sw/$f is missing. Run 'make' in sw/ first."
        exit 1
    }
}

#------------------------------ synthesis -----------------------------
synth_design -top $top -part $part -flatten_hierarchy none
write_checkpoint -force post_synth.dcp
report_utilization -file post_synth_util.rpt

#--------------------------- implementation ---------------------------
opt_design
place_design
phys_opt_design
route_design

write_checkpoint -force post_route.dcp
report_timing_summary -file post_route_timing.rpt
report_utilization    -file post_route_util.rpt
report_drc            -file post_route_drc.rpt

#------------------------------ bitstream -----------------------------
write_bitstream -force $top.bit

puts "----------------------------------------------------------"
puts " bitstream written: $outdir/$top.bit"
puts " check post_route_timing.rpt for WNS before you trust it"
puts "----------------------------------------------------------"
