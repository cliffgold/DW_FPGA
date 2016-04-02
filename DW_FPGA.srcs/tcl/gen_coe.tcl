#Generate init file for RAM simulation
#Run under Vivado

set memDir $argv

set f1 [open "$memDir/coef_inc.coe" w]
puts $f1 "; Coef Mem incrementing pattern"
puts $f1 "memory_initialization_radix=10;"
puts $f1 "memory_initialization_vector= "

set f2 [open "$memDir/coef_dec.coe" w]
puts $f2 "; Coef Mem decrementing pattern"
puts $f2 "memory_initialization_radix=10;"
puts $f2 "memory_initialization_vector= "

set f3 [open "$memDir/coef_alt.coe" w]
puts $f3 "; Coef Mem alternating pattern"
puts $f3 "memory_initialization_radix=10;"
puts $f3 "memory_initialization_vector= "

set f4 [open "$memDir/coef_val.coe" w]
puts $f4 "; Coef Mem Valley pattern"
puts $f4 "memory_initialization_radix=10;"
puts $f4 "memory_initialization_vector= "

set f5 [open "$memDir/coef_mtn.coe" w]
puts $f5 "; Coef Mem Mountain pattern"
puts $f5 "memory_initialization_radix=10;"
puts $f5 "memory_initialization_vector= "

set max 2047
set min -2048

for {set i 0} {$i<1024} {set i [expr $i+1]} {
    if [expr $i < 1023] {
	puts $f1 "$i, "
	puts $f2 "[expr -1 -$i],"
	if [expr fmod($i,2) == 0] {
	    puts $f3 "$max,"
	} else {
	    puts $f3 "$min,"
	}
	if [expr $i < 512] {
	    puts $f4 "[expr $max - $i],"
	    puts $f5 "[expr $min + (8*$i)],"
	} else {
	    puts $f4 "[expr $max -1024 + $i],"
	    puts $f5 "[expr $min +8191 - (8*$i)],"
	}
    } else {
	puts $f1 "$i; "
	puts $f2 "[expr -1 -$i];"
	puts $f3 "$min;"
	puts $f4 "$max;"
	puts $f5 "$min;"
	
    }
}
close $f1
close $f2
close $f3
close $f4
close $f5
