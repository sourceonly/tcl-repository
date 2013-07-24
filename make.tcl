proc make {args} {
    array set OPT [list];
    set fch [open Makefile r];
    set THIS_TAG [list];
    while {[gets $fch line]!=-1} {
	if [isBlank $line] {
	    continue;
	}
	if [isAssignLine $line] {
	    set value [getAssign $line];
	    array set OPT [list VALUE,[lindex $value 0] [lindex $value 1]];
	    continue;
	}
	if [isTagLine $line] {
	    set TAG [getTag $line];
	    array set OPT [list TAG,[lindex $TAG 0],DEP [lindex $TAG 1]];
	    set THIS_TAG [lindex $TAG 0];
	    continue;
	}
	if [isCommandLine $line] {
	    if {$THIS_TAG!=""} {
		append OPT(TAG,$THIS_TAG,COMMAND) "[getCommand $line]\n"
	    }
	    continue
	}
    }
    return [array get OPT];
}
proc isBlank {line} {
    if [regexp -- {^/s+$} $line] {
	return 1;
    }
    return 0;
}

proc isAssignLine {line} {
    if {[regexp -all -- = $line]==1} {
	return 1;
    }
    return 0;
}
proc getAssign {line} {
    return [split $line =];
}

proc isCommandLine {line} {
    if [regexp -- {^\t} $line] {
	return 1;
    } 
    return 0;
}
proc getCommand {line} {
    regsub -- {^\t} $line "" line;
    set catchflag 0;
    if [regexp -- {^-} $line] {
	set catchflag 1 ;
	regsub -- {^-} $line "" line;
    } 
    
    if {$catchflag} {
	return "catch \{$line\};";
    }
    return "$line;";
}


proc isTagLine {line} {
    if [regexp -- {^[^\s]+:} $line ] {
	return 1;
    }
    return 0;
}
proc getTag {line} {
    return [split $line :];
}

