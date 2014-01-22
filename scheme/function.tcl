namespace eval ::SCHEME {
    proc EVAL {lispObj} {
	if {[llength $lispObj] > 2} {
	    error "synatics error" 
	} else {
	    if [LISTP $lispObj] {
		return [APPLY [get-proc [CAR $lispObj]] [CDR $lispObj]];
	    } else {
		return [get-value $lispObj];
	    }
	}
    }
    proc APPLY {expr listObj2} {

	
	
    }

    
}
