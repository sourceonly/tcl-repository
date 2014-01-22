
package provide tcllisp 2.0

# Macros defined for Tcl

# dolist {var list} {something todo}
# e.g 
#   dolist {i {a b c d e}} {puts $i}
#   would print a b c d e through the list 
proc dolist {parm body} {
    uplevel foreach $parm [list	$body];
}
# dolist {var times} {something todo}
# e.g 
#   dotimes {i 100} {puts $i} 
#   would print 0-99 respectively
# 
proc dotimes {parm body} {
    set script [list];
    set var [lindex $parm 0];
    set times [lindex $parm 1];
    
    set forparm [list];
    lappend forparm [list set $var 0];
    append crit "\[set $var\] < $times"
    lappend forparm $crit;
    lappend forparm [list incr $var];
    lappend forparm $body;
    uplevel for $forparm
}

# loop through list, if *expr* is a lambda expr, then apply the expr to the member of the list one by one 
# return the original list
proc mapc {expr list} {
    if [regexp {^\{} $expr ] {
	foreach i $list {
	    apply $expr $i
	}
    } else {
	foreach i $list {
	    $expr $i
	}
    }
    return $list
}
# loop through list, if *expr* is a lambda expr, then apply the expr to the member of the list one by one 
# return the changed_list
proc mapcar {expr list} {
    set return_list [list];
    if [regexp {^\{} $expr ] {

	foreach i $list {
	    lappend return_list [apply $expr $i]
	}
    } else {
	foreach i $list {
	    lappend return_list [$expr $i]
	}
    }
    return $return_list
}
proc define {var value} {
    if [llength $var]==1 {
	uplevel set $var $value
    } else {
	uplevel proc [list [lindex $var 0]] [list [lrange $var 1 end]] [list $value]
    }
}
proc defvar {var value} {
    if [llength $value]!=1 {
	error "error: should be $var $vale";
    }
    uplevel variable $var $value;
}

proc getvar {var value} {
    uplevel variable $var
    set $var
}

proc defmacro {macroname arglist body} {
    interp alias {} $macroname {} evalmacro $macroname $arglist $body;
}

proc evalmacro {macroname arglist body args} {
    if {[llength $arglist] != [llength $args]} {
	error "wrong args: should be $macroname $arglist"
    }
    foreach i $arglist j $args {
	set $i $j
    }

    dolist {i $arglist} {
	regsub -all -- \\$$i $body "[set $i]" body;
    }
    uplevel $body;
}



#test area 
define {print args} {
    puts $args
};
define {printlist args} { 
    dolist {i $args} {
	if {[llength $i] >1} {
	    dolist {j $i} {
		
	    }
	} else {
	    print $i
	}
    }
}
defmacro testputs {a b} {puts $a; puts $b};





defmacro echo {args} {
    puts $args
}

