namespace eval ::SCHEME {
    
    proc removeBraceSpace {string} {
	regsub -all -- {\(\s+} $string "(" string;
	regsub -all -- {\s+\)} $string ")" string;
	return $string
    }
    proc parseSexp {string} {
	set string [removeBraceSpace $string];
	set rest_string "";
	set car "";
	set brace_lv 0;
	for {set i 0} {$i < [string length $string]} {incr i} {
	    set c [string index $string $i];
	    switch $c {
		"(" {
		    incr brace_lv;
		    if {$brace_lv>1} {
			append car "(";
		    }
		}
		")" {
		    incr brace_lv -1;
		    if {$brace_lv>=1} {
			append car ")"
		    }
		    if {$brace_lv==1} {
			set rest_string [removeBraceSpace "([string range $string [expr $i+1] end]"];
			break;
		    }
		}
		"\t" -
		" " -
		"\n" {
		    if {$brace_lv> 1} {
			append car $c 
		    } else {
			set rest_string [removeBraceSpace "([string range $string $i end]"];
			break;
		    }
		}
		default {
		    append car $c;
		}
	    }
	}
	
	if {$string=="()"} {
	    return [list];
	}

	if ![regexp -- {\(.*\)} $string] {
	    return $string
	}
	return [CONS [parseSexp $car] [parseSexp $rest_string]];
    }
}



