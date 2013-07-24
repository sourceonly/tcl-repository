proc checkSexp {args} {
    set Sexplevel 0;
    
    set content $args
    set i 0;
    
    if ![regexp -- {(^\s*\().*([\)]*\)\s*$)} $content ] {
	return "not available Sexp";
    }
    while {$i<10} {
	incr i
	if [regexp -- {^[^\(\)]*\(} $content] {
	    incr Sexplevel;
	} 
	if [regexp -- {^[^\(\)]*\)} $content] {
	    incr Sexplevel -1
	}
	if {$Sexplevel <  0 } {

	    return "not balance braces";
	} 
	regsub -- {^[^\(\)]*[\(\)]} $content "" content;
	if ![regexp -- {[\(\)]} $content ] {
	    break;
	}
    } 
    if {$Sexplevel != 0} {
	    return "not balance braces";
    }
    return 1;
}

proc cons {a b} {
    return [list $a $b];
}

proc car {args} {
    if {[lindex [join $args] 0]==""} {
	return nil
    }
    return [lindex [join $args] 0]
}
proc cdr {args} {
    set cdrvalue [join [lreplace [join $args] 0 0]]
    if {$cdrvalue == ""} {
	return nil;
    }
    return $cdrvalue;
}

proc lisp_list {args} {
    set args [join $args];
    if {[llength $args] == 1} {
	return [cons $args nil];
    } else {
	return [cons [car $args] [lisp_list [cdr $args]]]
    }
}



proc lisp_pair_puts {args} {
    set pair [join $args];
    if {$pair==""} {
	return nil;
    } elseif {[cdr $pair]=="nil"} {
	return "([car $pair] . [cdr $pair])"
    } else {
	puts "[lisp_pair_puts [cdr $pair]]";
	return "([car $pair] . [lisp_pair_puts [cdr $pair]])"
    }
}






