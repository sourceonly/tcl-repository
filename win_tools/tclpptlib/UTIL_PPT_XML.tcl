###############################################################################
## File      : UTIL_PPT_XML.tcl
## Purpose   : utility functions for XML
## Comments  :
## History   : 
## Date             Author          Description
## Jun-25-2011     AltairEPM        Initialized
###############################################################################

package require hwt;
#package require tdom

encoding system gb2312;

#***************************************************************************
# Purpose : ParseXMLFile
# Args    : 
#       XMLFile  Define the report frame
#       RepName the report name
# Returns :  mainhandle
# Notes   :
#***************************************************************************    
proc ParseXMLFile { XMLFile RepName args  } {
    # 打开xml文件
    if {![file exist $XMLFile]} {
	tk_messageBox -icon error -message "No xml find！";
	return -code error "No xml find！";
    }
    # 读取xml文件
    set fid [open $XMLFile r];
    set XmlContent [read $fid];
    close $fid;
    
    # 构建dom树
    if {[catch {dom parse $XmlContent} rcode]} {
	return -code error $rcode;
    }
    set DocHandle $rcode;
    set docele [$DocHandle documentElement];
    # 是否有子节点
    if { ![$docele hasChildNodes ]} {
	tk_messageBox -message "No aviable data in xml file!"
	return -99;
    }
    set MainNodeList [$docele childNodes]
    # 获得xml中一层节点的名字
    catch {unset returnarray};
    set returnarray(DocHandle) $DocHandle;

    foreach mnh $MainNodeList {
	set docname [$mnh nodeName ];
	
	switch -exact $docname {
	    "InitConfigValues" {
		set returnarray(InitConfigValues) $mnh;
	    }
	    "RepDef" {
		set trepname [$mnh getAttribute "Name"]
		if {$trepname == $RepName} {
		    set returnarray($RepName) $mnh;
		}
	    }
	    default {}
	}
    }
#     puts [array get returnarray]
    return [array get returnarray];
}
proc XmlToPpt {pptFile xml_file valuelist RepName num args } {
    variable arrayInitvalue;
    set d_index 0;
    catch {unset ArrayHandle};
    array set ArrayHandle [ParseXMLFile $xml_file $RepName];
    
    # start Generate ppt slide from the information in xml
    set rephandle $ArrayHandle($RepName);
    # get childe
    if { ![$rephandle hasChildNodes ]} {
	tk_messageBox -message "No aviable data in xml file!"
	return -99;
    }
    # get init values and master file;
    # xml file should define InitConfigValues
    set cfg_node $ArrayHandle(InitConfigValues);
    set configVar [namespace current]::pptExportConfig

    catch {unset $configVar }
    array set $configVar [$cfg_node getAttribute "configArray"]
    
    # set default values if they don't exist
    initConfigValues $configVar
    
    set pptDir [createDirectory $pptFile]
    
    ########################################################################
    # open PowerPoint
    set ppoint [OpenPowerPoint]
    set pres   [GetNewPresentation $ppoint]
    set width [getConfigValue $configVar slideResX]
    set height [getConfigValue $configVar slideResY]
    if {$width != "" && $height != ""} {
        setCustomPageSize $width $height
    }
    # Powerpoint Master
    set master [getConfigValue $configVar "master"]

    # should have master file
    set xmldir [file dirname $xml_file]
    set abspath [file join $xmldir $master];
    
    
    if { [file exist $abspath]} {
        LoadMaster $pres $abspath
    }
    
    set slidelist [$rephandle childNodes]
    
    
    
    for {set k 1} {$k <= $num} {incr k } {
	
	foreach n $slidelist {
	    set slidetype "";
	    if {[$n hasAttribute "type"]} {
		set slidetype [$n getAttribute "type"];
	    }
	    if {"$slidetype" == "summary"} {
		continue;
	    }
	    if {"$slidetype" == "animate"} {
		continue;
	    }
	    if {$k != 1 && $slidetype != "repeatable"} {
		continue;
	    }
	    
	    
	    # fill first slide
	    if {$n == [lindex $slidelist 0]} {
		set slide_handle [GetFirstSlide $pres 11]
	    } else {
		set slide_handle [NewSlide $pres 11]
	    }

	    # get n child
	    set e_list [$n childNodes];
	    foreach e $e_list {
		set e_name [$e nodeName]
		switch $e_name {
		    "title" {
			#get title value
			set t_content [$e getAttribute "content"]
			SetTitle $slide_handle $t_content
		    }
		    "textbox" {
			set d_value [GetNextValue $valuelist d_index];
			if {$d_value == ""} {
			    set d_value [$e getAttribute "D_content"];
			}
	
			if {[catch {set islist_ind [$e getAttribute "linebreak"]}]} {
			    set islist 0;
			} else {
			    set islist_ind [$e getAttribute "linebreak"];
			    if {"$islist_ind" == "yes"} {
				set islist 1;
			    } else {
				set islist 0;
			    }
			};
			set posion [$e getAttribute "posion"];
			set style [$e getAttribute "style"]
			eval InsertTextBox $slide_handle \"$d_value\" $posion $style $islist
		    }
		    "picture" {
			set d_value [GetNextValue $valuelist d_index];
			if {$d_value == ""} {
			    set d_value [$e getAttribute "D_pfile"];
			}
			set posion [$e getAttribute "posion"];
			set type [$e getAttribute "type"];
			if {$type == "hw"} {
			    AddHWPageImage $slide_handle $d_value $configVar $pptDir
			} elseif {$type == "file"} {
			    set abspfile [file join $pptDir $d_value];
			    if {[file exist $abspfile]} {
				foreach {posT posB posL posR} $posion {}
				# dont use the $posion in the Insert picture, it would generate an error in *.vbs file
				InsertPicture $slide_handle $abspfile $posT $posB $posL $posR 1 
			    }
			    
			}
		    }
		    "table" {
			# only support simple table currently!
			set d_value [GetNextValue $valuelist d_index];
			if {$d_value == ""} {
			    set d_value [$e getAttribute "D_valuelist"];
			}
			set posion [$e getAttribute "posion"];
			set titlelist [$e getAttribute "titlelist"];
			set widthlist [$e getAttribute "widthlist"];
			set tsize [$e getAttribute "tsize"];
			set vsize [$e getAttribute "vsize"];
			
			set linebreak 15;
			set col_count [llength $titlelist];

			set pbreak 0;
			set row_count_g [expr 1+ceil(double([llength $d_value])/$col_count)];


			while {1} {
			    
			    set d_value_temp [lrange $d_value [expr $pbreak*$col_count] [expr ($pbreak+ $linebreak)*$col_count-1]];
			    set row_count [expr 1+ceil(double([llength $d_value_temp])/$col_count)];
			    set table_shape [eval InsertTable $slide_handle $row_count $col_count $posion]

			    # tk_messageBox -message "$row_count\n $d_value_temp";    
			    incr pbreak $linebreak;
			    set allvlist [concat $titlelist $d_value_temp];
			    
			    # i for row;j for colum
			    for {set j 1} {$j <= $col_count} {incr j} {
				SetTableColumnWidth $table_shape $j [lindex $widthlist [expr $j-1]];
				for {set i 1} {$i <= $row_count} {incr i} {
				    set table_cell [GetCell $table_shape $i $j]
				    if {$i == 1 } {
					set textsize $tsize
				    } else {
					set textsize $vsize
				    }
				    InsertTextInCell $table_cell [lindex $allvlist [expr ($j-1)+($i-1)*$col_count]] $textsize
				    
				}
			    }
			    

			    if {$row_count_g > $linebreak} {
				set slide_handle [NewSlide $pres 11]

			    }
			    set  row_count_g [expr $row_count_g-$linebreak];
			    if {$row_count_g <= 0 } {break;}
			}
		    }
		    default {}
		    
		    
		}
	    }
	    if {$slidetype == "repeatable"} {
		for {set k_temp 1} {$k_temp <= $args} {incr k_temp } {
		    foreach n $slidelist {
			set slidetype "";
			if {[$n hasAttribute "type"]} {
			    set slidetype [$n getAttribute "type"];
			}
			if {"$slidetype" == "animate"} {
			    # fill first slide
			    if {$n == [lindex $slidelist 0]} {
				set slide_handle [GetFirstSlide $pres 11]
			    } else {
				set slide_handle [NewSlide $pres 11]
			    }

			    # get n child
			    set e_list [$n childNodes];
			    foreach e $e_list {
				set e_name [$e nodeName]
				switch $e_name {
				    "title" {
					#get title value
					set t_content [$e getAttribute "content"]
					SetTitle $slide_handle $t_content
				    }
				    "textbox" {
					set d_value [GetNextValue $valuelist d_index];
					if {$d_value == ""} {
					    set d_value [$e getAttribute "D_content"];
					}
					
					if {[catch {set islist_ind [$e getAttribute "linebreak"]}]} {
					    set islist 0;
					} else {
					    set islist_ind [$e getAttribute "linebreak"];
					    if {"$islist_ind" == "yes"} {
						set islist 1;
					    } else {
						set islist 0;
					    }
					};
					set posion [$e getAttribute "posion"];
					set style [$e getAttribute "style"]
					eval InsertTextBox $slide_handle \"$d_value\" $posion $style $islist 
				    }
				    "picture" {
					set d_value [GetNextValue $valuelist d_index];
					if {$d_value == ""} {
					    set d_value [$e getAttribute "D_pfile"];
					}
					set posion [$e getAttribute "posion"];
					set type [$e getAttribute "type"];
					if {$type == "hw"} {
					    AddHWPageImage $slide_handle $d_value $configVar $pptDir
					} elseif {$type == "file"} {
					    set abspfile [file join $pptDir $d_value];
					    if {[file exist $abspfile]} {
						foreach {posT posB posL posR} $posion {}
						# dont use the $posion in the Insert picture, it would generate an error in *.vbs file
						InsertPicture $slide_handle $abspfile $posT $posB $posL $posR 1 
					    }
					}
				    }
				    "table" {
					# only support simple table currently!
					set d_value [GetNextValue $valuelist d_index];
					if {$d_value == ""} {
					    set d_value [$e getAttribute "D_valuelist"];
					}
					set posion [$e getAttribute "posion"];
					set titlelist [$e getAttribute "titlelist"];
					set widthlist [$e getAttribute "widthlist"];
					set tsize [$e getAttribute "tsize"];
					set vsize [$e getAttribute "vsize"];

					
					set linebreak 15;
					
					
					set col_count [llength $titlelist];
					set row_count_g [expr 1+ceil(double([llength $d_value])/$col_count)];	
					set pbreak 0;
					while {1} {
					    
					    set d_value_temp [lrange $d_value [expr $pbreak*$col_count] [expr ($pbreak+ $linebreak)*$col_count-1]];
					    set row_count [expr 1+ceil(double([llength $d_value_temp])/$col_count)];
					    set table_shape [eval InsertTable $slide_handle $row_count $col_count $posion]

					    # tk_messageBox -message "$row_count\n $d_value_temp";    
					    incr pbreak $linebreak;
					    set allvlist [concat $titlelist $d_value_temp];
					    
					    # i for row;j for colum
					    for {set j 1} {$j <= $col_count} {incr j} {
						SetTableColumnWidth $table_shape $j [lindex $widthlist [expr $j-1]];
						for {set i 1} {$i <= $row_count} {incr i} {
						    set table_cell [GetCell $table_shape $i $j]
						    if {$i == 1 } {
							set textsize $tsize
						    } else {
							set textsize $vsize
						    }
						    InsertTextInCell $table_cell [lindex $allvlist [expr ($j-1)+($i-1)*$col_count]] $textsize
						    
						}
					    }
					    

					    if {$row_count_g > $linebreak} {
						set slide_handle [NewSlide $pres 11]

					    }
					    set  row_count_g [expr $row_count_g-$linebreak];
					    if {$row_count_g <= 0 } {break;}
					}


					
				    }
				    "h3d" {

					set d_value [GetNextValue $valuelist d_index];
					if {$d_value == ""} {
					    set d_value [$e getAttribute "D_pfile"];
					}
					set posion [$e getAttribute "posion"];
					set type [$e getAttribute "type"];
					set abspfile [file join $pptDir $d_value];

					if {[file exist $abspfile]} {
					    foreach {posT posB posL posR} $posion {}
					    InsertH3DInSlideHW10 $slide_handle $abspfile $posT $posB $posL $posR
					}
				    }
				    default {}
				    
				}
			    }
			}
			
		    }
		}
	    }
	}
	
    }


    foreach n $slidelist {
	set slidetype "";
	if {[$n hasAttribute "type"]} {
	    set slidetype [$n getAttribute "type"];
	}
	if {"$slidetype" == "summary"} {
	    # fill first slide
	    if {$n == [lindex $slidelist 0]} {
		set slide_handle [GetFirstSlide $pres 11]
	    } else {
		set slide_handle [NewSlide $pres 11]
	    }

	    # get n child
	    set e_list [$n childNodes];
	    foreach e $e_list {
		set e_name [$e nodeName]
		switch $e_name {
		    "title" {
			#get title value
			set t_content [$e getAttribute "content"]
			SetTitle $slide_handle $t_content
		    }
		    "textbox" {
			set d_value [GetNextValue $valuelist d_index];
			if {$d_value == ""} {
			    set d_value [$e getAttribute "D_content"];
			}
	
			if {[catch {set islist_ind [$e getAttribute "linebreak"]}]} {
			    set islist 0;
			} else {
			    set islist_ind [$e getAttribute "linebreak"];
			    if {"$islist_ind" == "yes"} {
				set islist 1;
			    } else {
				set islist 0;
			    }
			};
			set posion [$e getAttribute "posion"];
			set style [$e getAttribute "style"]
			eval InsertTextBox $slide_handle \"$d_value\" $posion $style  $islist
		    }
		    "picture" {
			set d_value [GetNextValue $valuelist d_index];
			if {$d_value == ""} {
			    set d_value [$e getAttribute "D_pfile"];
			}
			set posion [$e getAttribute "posion"];
			set type [$e getAttribute "type"];
			if {$type == "hw"} {
			    AddHWPageImage $slide_handle $d_value $configVar $pptDir
			} elseif {$type == "file"} {
			    set abspfile [file join $pptDir $d_value];
			    if {[file exist $abspfile]} {
				foreach {posT posB posL posR} $posion {}
				# dont use the $posion in the Insert picture, it would generate an error in *.vbs file
				InsertPicture $slide_handle $abspfile $posT $posB $posL $posR 1 
			    }
			    
			    
			} 			

		    }
		    "table" {
			# only support simple table currently!
			set d_value [GetNextValue $valuelist d_index];
			if {$d_value == ""} {
			    set d_value [$e getAttribute "D_valuelist"];
			}
			set posion [$e getAttribute "posion"];
			set titlelist [$e getAttribute "titlelist"];
			set widthlist [$e getAttribute "widthlist"];
			set tsize [$e getAttribute "tsize"];
			set vsize [$e getAttribute "vsize"];

			set linebreak 15;
			
			set row_count_g [expr 1+ceil(double([llength $d_value])/$col_count)];
			set col_count [llength $titlelist];
			
			set pbreak 0;
			while {1} {
			    
			    set d_value_temp [lrange $d_value [expr $pbreak*$col_count] [expr ($pbreak+ $linebreak)*$col_count-1]];
			    set row_count [expr 1+ceil(double([llength $d_value_temp])/$col_count)];
			    set table_shape [eval InsertTable $slide_handle $row_count $col_count $posion]

			    # tk_messageBox -message "$row_count\n $d_value_temp";    
			    incr pbreak $linebreak;
			    set allvlist [concat $titlelist $d_value_temp];
			    
			    # i for row;j for colum
			    for {set j 1} {$j <= $col_count} {incr j} {
				SetTableColumnWidth $table_shape $j [lindex $widthlist [expr $j-1]];
				for {set i 1} {$i <= $row_count} {incr i} {
				    set table_cell [GetCell $table_shape $i $j]
				    if {$i == 1 } {
					set textsize $tsize
				    } else {
					set textsize $vsize
				    }
				    InsertTextInCell $table_cell [lindex $allvlist [expr ($j-1)+($i-1)*$col_count]] $textsize
				    
				}
			    }
			    

			    if {$row_count_g > $linebreak} {
				set slide_handle [NewSlide $pres 11]

			    }
			    set  row_count_g [expr $row_count_g-$linebreak];
			    if {$row_count_g <= 0 } {break;}
			}
		    }
		    
		    default {}
		    
		    
		}
	    }
	}
    }
    PptState $ppoint
    set vbsFile [ClosePowerPoint $pres $pptFile]
    # save mvw file under the same folder with ppt
    set str_mvwFile [file rootname $pptFile]
    append str_mvwFile ".mvw"
    set sess [GetSession]
    $sess SaveSessionFile $str_mvwFile
}
proc GetNextValue {vlist index args} {
    upvar $index count;
    set c_value [lindex $vlist $count];
    incr count
    set c_value;
}


