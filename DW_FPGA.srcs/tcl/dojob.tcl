proc fish4patts {startdir patts} \
     {
	 set hooked {}
	 foreach patt $patts {
	     set dirs $startdir
	     while {[llength $dirs]} {
		 set name [lindex $dirs 0]
		 set dirs [concat [lrange $dirs 1 end] \
			  [glob -nocomplain -directory [lindex $dirs 0] -type d *]]
		 lappend hooked [glob -nocomplain $name/$patt]
	     }
	 }
	 
	 return [join $hooked]
     }


set rootDir [get_property DIRECTORY [current_project]]
set plusDir $rootDir/[lindex [file split $rootDir] end]
set myTop   [lindex [find_top] 0]

foreach {tclfile block} $argv {
    source $plusDir.srcs/tcl/$tclfile
}
