namespace eval ::SCHEME {
    proc typep {type symbol} {
	set ns [uplevel 2 namespace current];
	set array_name [array name ${ns}::$type];
	if {[lsearch $array_name $symbol]>=0} {
	    return 1
	}  
	set p_ns [namespace parent $ns];
	if {$p_ns=="::"} {
	    return 0;
	}
	return [namespace eval $p_ns "::SCHEME::typep $type $symbol"];
    }
    proc valuep {symbol} {
	return [typep ENTRYTABLE $symbol];
    }
    proc procedurep {symbol} {
	return [typep PROCEDURETABLE $symbol];
    }
    proc symbolp {symbol} {
	return [expr [valuep $symbol]||[procedurep $symbol]];
    }
    proc get-type {type symbol} {
	set ns [uplevel 2 namespace current];
	set array_name [array name ${ns}::$type];
	if {[lsearch $array_name $symbol]>=0} {
	    return [lindex [array get ${ns}::$type $symbol] 1];
	}  
	set p_ns [namespace parent $ns];
	if {$p_ns=="::"} {
	    return [list];
	}
	return [namespace eval $p_ns "::SCHEME::get-type $type $symbol"];
    }
    proc get-value {symbol} {
	return [get-type ENTRYTABLE $symbol];
    }
    proc get-proc {symbol} {
	return [get-type PROCEDURETABLE $symbol];
    }
    proc callFrame {name} {
	namespace eval $name {
	    variable ENTRYTABLE;
	    variable PROCEDURETABLE;
	    array set ENTRYTABLE [list];
	    array set PROCEDURETABLE [list];
	}
    }
    
    proc TopFrame {args} {
	callFrame ::SCHEME;
	variable ENTRYTABLE;
	variable PROCEDURETABLE;
	array set ENTRYTABLE [list t 1];
    }
    TopFrame;
}

#for test
namespace eval ::SCHEME {
    proc test {args} {
	puts [symbolp t];
	puts [get-value t];
    }
    callFrame AAA
    namespace eval AAA {array set ENTRYTABLE [list fuck "abc"]}
    proc AAA::testframe {args} {
	puts [::SCHEME::valuep fuck];
	puts [::SCHEME::symbolp fuck];
	puts [::SCHEME::get-value fuck];
    }
}
