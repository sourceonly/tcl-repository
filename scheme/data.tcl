namespace eval ::SCHEME {
    proc CONS {a b} {
	return [list $a $b];
    }
    proc CAR {listObj} {
	return [lindex $listObj 0]
    }
    proc CDR {listObj} {
	return [lindex $listObj 1]
    }
    proc LIST {args} {
	if {[llength $args]==1} {
	    return [list $args [list]];
	}
	return [CONS [lindex $args 0] [eval LIST [lrange $args 1 end]]];
    }
    proc LISTP {listObj1} {
	if {[llength $listObj1] == 2} {
	    return 1
	} else {
	    return 0
	}
    }
    proc APPENDTWO {obj1 obj2} {
	if {[llength $obj1]==0} {
	    return $obj2;
	}

	if {[llength [CDR $obj1]]==0} {
	    return [CONS [CAR $obj1] $obj2];
	}
	return [CONS [CAR $obj1] [APPENDTWO [CDR $obj1] $obj2]]
    }
    # proc APPEND {lispOBJ} {
    # 	if {[CDR $lispOBJ]==""} {
    # 	    return $lispOBJ;
    # 	}
    # 	return [APPEND [CONS [APPENDTWO [CAR $lispOBJ] [CAR [CDR $lispOBJ]]] [CDR [CDR $lispOBJ]]]];
    # }

    proc PAIRP {lispObj} {
	if [symbolp $lispObj] {
	    set value [get-symbol $lispObj];
	} else {
	    set value $lispObj
	}
	if {[llength $value]==2} {
	    return 1 ;
	}
	return 0
    }
    
    proc DOUBLEP {lispObj} {
	if [symbolp $lispObj] {
	    set value [get-symbol $lispObj];
	} else {
	    set value $lispObj
	}
	if {[llength $value]==1} {
	    return [string is double -strict $value]
	}
	return 0;
    }
    proc STRINGP {lispObj} {
	if [symbolp $lispObj] {
	    set value [get-symbol $lispObj];
	} else {
	    set value $lispObj
	}
	if {[llength $value]==1} {
	    return [regexp -- ^\".*\"$ $value];
	}
	return 0;
    }
    proc QUOTE {listObj} {
	return $listObj
    }
}

# test ISSUE
