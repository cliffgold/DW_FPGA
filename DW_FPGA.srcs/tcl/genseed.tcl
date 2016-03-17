#Generate file containing 64 544-bit random numers
#

set rootDir [get_property DIRECTORY [current_project]]
set hdlDir $rootDir/[lindex [file split $rootDir] end].srcs/HDL

set f1 [open "$hdlDir/seeds.svh" w]
puts $f1 "// Random numbers used for seeds"
puts $f1 "\nparameter \[543:0\] SEED \[63:0\] = \{ \n   {"

for {set i 0} {$i<64} {set i [expr $i+1]} {
    for {set j 0} {$j<16} {set j [expr $j+1]} {
	puts $f1 "    32\'d[format %.0f [expr (rand()*((2**32)-1))]],"
    }
    puts $f1 "    32\'d[format %.0f [expr (rand()*((2**32)-1))]]"
    if {$i == 63} {
	puts $f1 "   \}"
    } else {
	puts $f1 "   \},\{"
    }
}
puts $f1 "\};"

close $f1
