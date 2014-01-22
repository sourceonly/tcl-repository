if [namespace exist ::SCHEME] {
    namespace delete ::SCHEME;
}

source parse.tcl
source frame.tcl
source data.tcl
source function.tcl

namespace eval ::SCHEME {
    proc testeval {} {
	return [EVAL t]
    }
}
