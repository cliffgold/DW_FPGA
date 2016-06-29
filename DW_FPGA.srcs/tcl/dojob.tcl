set rootDir [get_property DIRECTORY [current_project]]
set plusDir $rootDir/[lindex [file split $rootDir] end]
set myTop   [lindex [find_top] 0]

foreach {tclfile block} $argv {
    if { [catch {source $plusDir.srcs/tcl/$tclfile}] } {
	puts "***PROBLEM ENCOUNTERED ***"
	break
    }
}

