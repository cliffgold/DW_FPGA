 
puts "Generate clock IP $block"

set xci     $plusDir.srcs/IP/$block/$block.xci

generate_target all [get_files  $xci]
export_ip_user_files -of_objects [get_files $xci] -no_script -force -quiet

if [file exists $plusDir.runs/${block}_synth_1/$block.dcp] {
    reset_run ${block}_synth_1
}

launch_runs ${block}_synth_1
wait_on_run ${block}_synth_1

export_simulation -of_objects [get_files $xci] -directory $plusDir.ip_user_files/sim_scripts -force -quiet



