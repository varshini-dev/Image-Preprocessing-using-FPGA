# vivado -mode batch -source build_t3.tcl      (run from this folder)
set here [file dirname [file normalize [info script]]]
create_project t3_preproc $here/vivado_t3 -part xc7a35tcpg236-1 -force
add_files [glob $here/../rtl/*.v]
add_files -fileset sim_1 $here/../tb/tb_preproc.v
add_files -fileset constrs_1 $here/../xdc/t3_basys3.xdc
set_property top preproc_board_top [current_fileset]
set_property top tb_preproc [get_filesets sim_1]
update_compile_order -fileset sources_1

launch_simulation ; run all ; close_sim        ;# behavioural simulation

launch_runs synth_1 -jobs 4 ; wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4 ; wait_on_run impl_1
open_run impl_1
report_utilization    -file $here/t3_utilization.rpt
report_timing_summary -file $here/t3_timing.rpt
puts "Bitstream: $here/vivado_t3/t3_preproc.runs/impl_1/preproc_board_top.bit"
