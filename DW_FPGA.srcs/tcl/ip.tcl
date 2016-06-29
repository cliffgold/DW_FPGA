 
puts "Generate IP $block"

set xci     $plusDir.srcs/IP/$block/$block.xci

reset_target all [get_files  $xci]
export_ip_user_files -of_objects  [get_files  $xci] -sync -no_script -force -quiet
generate_target all [get_files  $xci]
export_ip_user_files -of_objects [get_files $xci] -no_script -force -quiet
create_ip_run [get_files -of_objects [get_fileset $block] $xci]
launch_run -jobs 4 ${block}_synth_1

wait_on_run ${block}_synth_1

export_simulation -of_objects [get_files $xci] -directory $plusDir.ip_user_files/sim_scripts -ip_user_files_dir $plusDir.ip_user_files -ipstatic_source_dir $plusDir.ip_user_files/ipstatic -force -quiet

