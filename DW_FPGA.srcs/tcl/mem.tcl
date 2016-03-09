 
puts "Generate memory IP $block"

set xci     $plusDir.srcs/IP/$block/$block.xci

generate_target all [get_files  $xci]
export_ip_user_files -of_objects [get_files $xci] -no_script -force -quiet

export_simulation -of_objects [get_files $xci] -directory $plusDir.ip_user_files/sim_scripts -force -quiet

