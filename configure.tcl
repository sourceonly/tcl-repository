package provide Configurefile 2.0

if [namespace exist CONFIGUREFILE] {
    namespace delete CONFIGUREFILE;
}


namespace eval CONFIGUREFILE {

    variable REGEX_TAG_BLOCK {\[([^\]]*)\]([^\[]*)};
    variable REGEX_NEWLINE {[^\n]*\n};

    proc parseConfigureFile {filename} {
	set fch [open $filename r];
	set content [read $fch];
	set result [parseContent $content;]
	close $fch;
	return $result;
    }

    proc parseContent {content} {
	set result_list [list];
	variable REGEX_TAG_BLOCK;
	set tag_block "";
	while {[regexp $REGEX_TAG_BLOCK $content tag_block]} {
	    lappend result_list [parseTag $tag_block];
	    regsub $REGEX_TAG_BLOCK $content "" content;
	    set tag_block "";
	}
	return $result_list
    }
    
    proc parseContentByTag {content tag} {
	regsub @tag@ {\[@tag@\]([^\[]*)} $tag matchTAG;o
	if [regexp $matchTAG $content tag_block] {
	    return [parseTag $tag_block];
	} 
	return ""
    }
    
    proc parseTag {tag_block} {
	set tag "";
	set tag_value "";
	while {1} {
	    set line ""
	    regexp -- {^[^\n]*\n} $tag_block line;
	    regsub -- {^[^\n]*\n} $tag_block "" tag_block;
	    if {$line==""} {
		break;
	    }
	    set block_tag [getTag $line];
	    if {$block_tag!=""} {
		set tag $block_tag; 
		continue
	    }
	    
	    set pair [getPair $line];
	    if {$pair!=""} {
		foreach item $pair {
		    lappend tag_value $item
		}
	    }
	}
	return [list $tag $tag_value];
    }
    proc getTag {line} {
	if [regexp -- {\[([^\]]*)\]} $line tag1 tag] {
	    return $tag;
	} 
	return ""
    }
    
    proc getPair {line} {
	regsub -- {^\s*} $line "" line;
	regsub -- {\n*$} $line "" line;
	regsub -- {\s*=\s*} $line = line;
	return [split $line "="]
    }

    
    proc createTagBlock {tag tag_value} {
	set block [list];
	
	append block "\[$tag\]\n";
	foreach {key value} $tag_value {
	    append block "$key=$value\n";
	}
	return $block;
    }
    
    proc updateConfigureContent {content tag tag_value} {
	regsub @tag@ {\[@tag@\]([^\[]*)} $tag matchTAG;
	if {![regexp -- $matchTAG $content]} {
	    set block [createTagBlock $tag $tag_value];
	    append content $block;
	} else {
	    regsub @tag@ {\[@tag@\]([^\[]*)} $tag matchTAG;
	    set old_tag [parseContentByTag $content $tag];
	    array set [lindex $old_tag 0] [lindex $old_tag 1];
	    array set $tag $tag_value;
	    set block [createTagBlock $tag [array get $tag];];
	    regsub $matchTAG $content $block content;
	}
	return $content;
    }
    
    proc updateFile {filename tag tag_value} {
	set fch [open $filename r];
	set content [read $fch];
	close $fch;
	set vcont [updateConfigureContent $content $tag $tag_value;]
	set fch [open $filename w];
	puts $fch $vcont;
	close $fch;
    }
    namespace export *
}



