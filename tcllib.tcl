if [namespace exist REPORTGUI] {
    namespace delete REPORTGUI
}
package require tdom;

proc ::getIndex {args} {
    global __frame_index;
    if {[info var ::__frame_index]==""} {
	set ::__frame_index 0;
    }
    set zeros "00000";
    set this_index ${::__frame_index};
    incr ::__frame_index;
    set n [string length $this_index];
    return [string replace $zeros end-$n end $::__frame_index];
}

namespace eval REPORTGUI {
    variable OPT;
    array set OPT [list];
    
    proc initOPT {args} {
	variable OPT;
	array set OPT [list \
			   "PACK,OPT" "-padx 5 -pady 3 "\
			   "TK" "tk"\
			  ]
    }
    proc use {tk_type} {
	variable OPT;
	array set OPT [list TK $tk_type];
    }
    initOPT;
    proc buildGUI {frame domNode} {
	variable OPT;
	regsub -- {^\.\.} $frame . frame
	set type [$domNode nodeName];
	
	set this_index [getIndex];
	set this_widget $frame.e$type$this_index;

	set arg_list [lindex [$domNode asList] 1];
	array set opt_array $arg_list
	switch $type {
	    "pack" {
		createWidget $type $frame;
		return;
	    }
	    default {
	    	set this_widget [createWidget $type $this_widget];
	    }
	}
	
	eval pack $this_widget $OPT(PACK,OPT);
	

	$domNode setAttribute wpath $this_widget
	
	foreach node [$domNode child all] {
	    buildGUI $this_widget $node
	}
	return $domNode
    }
    
    proc createWidget {type widget args} {
	set return_widget $widget;
	upvar opt_array opt_array;
	variable OPT;
	
	set ignore_list [list "tag" "wpath"]
	proc get_real_opt {args} {
	    upvar ignore_list ignore_list;
	    upvar opt_array opt_array
	    
	    set return_list "";
	    foreach name [array name opt_array] {
		if {$name!=""} {
		    if {[lsearch $ignore_list $name]==-1} {
			append return_list "\"-$name\" \"$opt_array($name)\" "
		    }
		}
	    }
	    return $return_list;
	}
	switch $type {
	    "pack" {
		uplevel \#0 $type $widget [get_real_opt];
		return $widget
	    }
	    "Collector" {
		uplevel \#0 ::esgCN::HmCollector new $widget [get_real_opt]
		return $widget
	    }
	    "LabeledFrame" {
		lappend ignore_list "text";
		append arg_list "$opt_array(text) ";
		append arg_list [get_real_opt];
		set widget [uplevel \#0 [concat "hwt::$type" $widget $arg_list]]
		return $widget
	    }
	    "CanvasButton" {
		foreach key [list "width" "height"] {
		    lappend ignore_list $key
		    append arg_list "$opt_array($key) "
		}
		append arg_list [get_real_opt];
		set widget [uplevel \#0 [concat "hwt::$type" $widget $arg_list]]
		return $widget
	    }
	    "AddEntry" {
		foreach key [list "asButton" "asPassword" "iconLoc" "listProc" "listVar"] {
		    lappend ignore_list $key
		}
		
		foreach key [list "asButton" "asPassword"] {
		    if {[array name opt_array $key]!=""} {
			if [$opt_array($key)] {
			    append arg_list "$key "
			}
		    }
		}
		foreach key [list "iconLoc" "listProc" "listVar"] {
		    if {[array name opt_array $key]!=""} {
			set string "$key $opt_array($key) "
			append arg_list $string
		    }
		}
		append arg_list [get_real_opt];

		set widget [uplevel \#0 [concat "hwt::$type" $widget $arg_list]]
		return $widget
		
	    }
	    default {
		set widget [uplevel \#0 [concat $OPT(TK)::$type $widget [get_real_opt]]]
		return $widget;
	    }
	}
	
    }

    proc compileTK {frame domNode fch} {
	variable OPT;
	
	regsub -- {^\.\.} $frame . frame
	set type [$domNode nodeName];
	
	set this_index [getIndex];
	set this_widget $frame.e$type$this_index;

	set arg_list [lindex [$domNode asList] 1];
	array set opt_array $arg_list
	switch $type {
	    "pack" {
		compileWidget $type $frame;
		return;
	    }
	    default {
	    	set this_widget [compileWidget $type $this_widget];
	    }
	}
	
	
	puts $fch "pack $this_widget $OPT(PACK,OPT);"
	eval pack $this_widget $OPT(PACK,OPT);

	$domNode setAttribute wpath $this_widget
	
	foreach node [$domNode child all] {
	    compileTK $this_widget $node $fch
	}
	return $domNode
    }


    proc compileWidget {type widget} {
	upvar fch fch
	set return_widget $widget;
	upvar opt_array opt_array;
	variable OPT;
	
	set ignore_list [list "tag" "wpath"]
	proc get_real_opt {args} {
	    upvar ignore_list ignore_list;
	    upvar opt_array opt_array
	    
	    set return_list "";
	    foreach name [array name opt_array] {
		if {$name!=""} {
		    if {[lsearch $ignore_list $name]==-1} {
			append return_list "\"-$name\" \"$opt_array($name)\" "
		    }
		}
	    }
	    return $return_list;
	}
	
	switch $type {
	    "pack" {
		puts $fch "$type $widget [get_real_opt]"
		uplevel \#0 $type $widget [get_real_opt]
		return $widget
	    }
	    "Collector" {
		puts $fch "::esgCN::HmCollector new $widget [get_real_opt]"
		uplevel \#0 ::esgCN::HmCollector new $widget [get_real_opt]
		return $widget
	    }
	    "LabeledFrame" {
		lappend ignore_list "text";
		append arg_list "$opt_array(text) ";
		append arg_list [get_real_opt];
		puts $fch "[concat "hwt::$type" $widget $arg_list]"
		set widget [uplevel \#0 [concat "hwt::$type" $widget $arg_list]]
		return $widget
	    }
	    "CanvasButton" {
		foreach key [list "width" "height"] {
		    lappend ignore_list $key
		    append arg_list "$opt_array($key) "
		}
		append arg_list [get_real_opt];
		puts $fch "[concat "hwt::$type" $widget $arg_list]"
		set widget [uplevel \#0 [concat "hwt::$type" $widget $arg_list]]
		return $widget
	    }
	    "AddEntry" {
		foreach key [list "asButton" "asPassword" "iconLoc" "listProc" "listVar"] {
		    lappend ignore_list $key
		}
		
		foreach key [list "asButton" "asPassword"] {
		    if {[array name opt_array $key]!=""} {
			if [$opt_array($key)] {
			    append arg_list "$key "
			}
		    }
		}
		foreach key [list "iconLoc" "listProc" "listVar"] {
		    if {[array name opt_array $key]!=""} {
			set string "$key $opt_array($key) "
			append arg_list $string
		    }
		}
		append arg_list [get_real_opt];

		puts $fch "[concat \"hwt::$type\" $widget $arg_list]"
		set widget [uplevel \#0 [concat "hwt::$type" $widget $arg_list]]
		return $widget
		
	    }
	    default {
		puts $fch "[concat $OPT(TK)::$type $widget [get_real_opt]]"
		set widget [uplevel \#0 [concat $OPT(TK)::$type $widget [get_real_opt]]]
		return $widget;
	    }
	}
    }

}

proc ::abc {args} {
    puts abc
}


proc test {filename} {
    catch {destroy .xxx}
    toplevel .xxx
    
    set fch [open $filename r];
    set content [read $fch];
    close $fch;
    set doc [dom parse $content];
    puts [::REPORTGUI::buildGUI .xxx [$doc documentElement]];
}

proc testcompile {xmlfile tkfile} {
    catch {destroy .xxx}
    toplevel .xxx
    
    set fch [open $xmlfile r];
    set content [read $fch];
    close $fch;
    set doc [dom parse $content];
    
    set fch [open $tkfile w];
    ::REPORTGUI::compileTK .xxx [$doc documentElement] $fch
    close $fch;
    
}
