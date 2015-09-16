
namespace eval :: {
    proc getPPTPath {{up_search_level 3}} {
	global tcl_platform
	set LIBS libs
	set PATH [file normalize [info script]];
	set CUR_PATH $PATH
	set PREV_SEARCH_LEVEL $up_search_level
	while {$PREV_SEARCH_LEVEL>=0} {
	    incr PREV_SEARCH_LEVEL -1;
	    set CUR_PATH [file dir $CUR_PATH];
	    set cur_lib_dir [glob -directory $CUR_PATH -nocomplain -types d CreatePPT];
	    if {$cur_lib_dir==""} {
		continue
	    }
	    foreach lib_dir $cur_lib_dir {
		catch {source [file join $lib_dir CreatePPT.tcl]}
		catch {source [file join $lib_dir CreatePPT.tbc]}
	    }
	}
    }
    ::getPPTPath 6
}


namespace eval :: {
    proc getLibPath {{up_search_level 3}} {
	global tcl_platform
	set LIBS libs
	set PATH [file normalize [info script]];
	set CUR_PATH $PATH
	set PREV_SEARCH_LEVEL $up_search_level
	while {$PREV_SEARCH_LEVEL>=0} {
	    incr PREV_SEARCH_LEVEL -1;
	    set CUR_PATH [file dir $CUR_PATH];
	    set cur_lib_dir [glob -directory $CUR_PATH -nocomplain -types d $LIBS];
	    if {$cur_lib_dir==""} {
		continue
	    }
	    foreach lib_dir $cur_lib_dir {
		lappend ::auto_path [file join $lib_dir common];
		switch $tcl_platform(platform) {
		    "windows" {
			switch $tcl_platform(machine) {
			    "amd64" {
				lappend ::auto_path [file join $lib_dir win64];
			    }
			    "intel" {
				lappend ::auto_path [file join $lib_dir win32];
			    }
			    default {
			    }
			}
		    }
		    "unix" {
		    }
		    default {
		    }
		}
	    }
	}
    }
    ::getLibPath 6
}
if [namespace exist ::CRASHREPORT] {
    namespace delete ::CRASHREPORT
}

namespace eval ::CRASHREPORT {
    variable OPT;
    set OPT(PATH,SCRIPT) [file dir [file normalize [info script]]];
    set OPT(PATH,REPORTINFO) [file join $OPT(PATH,SCRIPT) hsd];
    set OPT(PATH,TEMPLATE) [file join $OPT(PATH,SCRIPT) config Chery.pot];
    set OPT(PATH,RESOURCE) [file join $OPT(PATH,SCRIPT) config];
    set OPT(RATEFLAG) off
    set OPT(DUMMYFLAG) off
    set OPT(STRUCTFLAG) off

    catch {namespace eval :: [list source [file join $OPT(PATH,SCRIPT) libs pkgIndex.tcl]]}
    catch {namespace eval :: [list source [file join $OPT(PATH,SCRIPT) CreatePPT CreatePPT.tcl]]}
    catch {namespace eval :: [list source [file join $OPT(PATH,SCRIPT) CreatePPT CreatePPT.tbc]]}
    # puts [file join $OPT(PATH,SCRIPT) CreatePPT CreatePPT.tcl]

    proc createPPT {template_path report_data_path report_path} {
	variable OPT
	set OPT(STRUCTFLAG) off
	set OPT(RATEFLAG) off
	set OPT(DUMMYFLAG) off
	if {$::CRASHREP::WithDummy||$CRASHREP::WithDummyTest} {
	    set OPT(RATEFLAG) on
	}
	if {$::CRASHREP::WithDummyTest} {
	    set OPT(DUMMYFLAG) on
	}
	if {$::CRASHREP::StructResult} {
	    set OPT(STRUCTFLAG) on
	}

	set dir $::env(TEMP);
	set tag [clock seconds];
	file mkdir [file join $dir report$tag];
	file mkdir [file join $dir report$tag resources];

	foreach file [glob  -directory ${report_data_path} -nocomplain *] {
	    set tail_file [file tail $file];
	    file copy -force $file [file join $dir report$tag resources $tail_file];
	}

	foreach file [glob -directory $OPT(PATH,RESOURCE) -nocomplain *.png] {
	    set tail_file [file tail $file];
	    file copy -force $file [file join $dir report$tag resources $tail_file];
	}

	set doc [dom createDocument analysis];
	set root [$doc documentElement];
	proc AddNode {parent name args} {
	    upvar doc doc
	    set newNode [$doc createElement $name];
	    $parent appendChild $newNode;
	    if {$args != ""} {
		foreach {attr value} $args {
		    $newNode setAttribute $attr $value
		}
	    }
	    return $newNode;
	}

	proc FirstSlide {root} {
	    upvar doc doc
	    set newSlideNode [AddNode $root slide];
	    set newGroupNode [AddNode $newSlideNode group type "text" title "XXXX(XXX+XXX) C-NCAP偏置碰分析报告" x "40" y "150" w "600" h "40" font "Times New Roman&宋体" fontSize "28" align "center";]

	    set cur_x 30
	    incr cur_x 150
	    AddNode $newGroupNode part type "text" content "编号：________" x $cur_x y 30 w 150 h 10 font "Times New Roman&宋体" fontSize "14" align "left"
	    incr cur_x 160
	    AddNode $newGroupNode part type "text" content "版本：____X.X______" x $cur_x y 30 w 180 h 10 font "Times New Roman&宋体" fontSize "14" align "left"
	    incr cur_x 190
	    AddNode $newGroupNode part type "text" content "密级： __秘密★__" x $cur_x y 30 w 150 h 10 font "Times New Roman&宋体" fontSize "14" align "left"


	    AddNode $newGroupNode part type "text" content "@\"编制/日期：________________\" & vbcrlf &\"校对/日期：________________\" & vbcrlf & \"审核/日期：________________\" & vbcrlf & \"批准/日期：________________\"" x 250 y 250 w 300 h 50 font "Times New Roman&宋体" fontSize "16" align "left" lineskip "1.0"


	    AddNode $newGroupNode part type "text" content "@\"试验和整车技术工程院\"&vbcrlf&\"安全设计仿真部\"" x 200 y 450 w 400 h 20 font "Times New Roman&宋体" fontSize "16" align "center" lineskip "0.5"
	    set time [clock format [clock seconds] -format "%Y年%m月%d日"]
	    AddNode $newGroupNode part type "text" content "$time" x 250 y 480 w 300 h 20 font "Times New Roman&宋体" fontSize "16" align "center"
	}


	proc IsAssemFile {file} {
	    if ![file exist $file] {
		return 0
	    }

	    set fch [open $file r];
	    set content [read $fch] ;
	    close $fch;
	    if [regexp -- ^Assem $content] {
		return 1
	    }
	    return 0
	}

	proc getRateColor {domain value } {
	    #rbg value
	    set red [list 255 0 0 ]
	    set green [list 0 185 0]
	    set yellow [list 200 200 0]

	    set d_list [lsort -real -increasing $domain];
	    set upper [lindex $domain 1];
	    set lower [lindex $domain 0];
	    if {$upper<=$value } {
		return $red
	    }
	    if {$lower>=$value} {
		return $green
	    }
	    if {$upper>=$value && $value>=$lower} {
		return $yellow
	    }
	}
	proc getRate {domain value {maxrate 5}} {
	    set d_list [lsort -real -increasing $domain];
	    set upper [lindex $domain 1];
	    set lower [lindex $domain 0];

	    if {$value < $lower } {
		set value $lower
	    } elseif {$value > $upper} {
		set value $upper
	    }

	    return [format %.2f [expr $maxrate - 1.0*$maxrate/($upper-$lower)*($value-$lower)]]
	}
	proc getEnergy {args} {
	    upvar tag tag
	    upvar dir dir
	    set file_dir [file join $dir report$tag resources];
	    touch "[file join $file_dir p1w3.data]"
	    set fch2 [open [file join $file_dir p1w3.data] r];
	    gets $fch2 line
	    foreach item {1 2} {
		set line ""
		set getline 0
		while {$getline==0} {
		    set getline [gets $fch2 line]
		    if {$getline!=0} {break}
		}
		set result [split $line ,]
		set calvar [lindex $result 0]
		set thevar [lindex $result 1]
	    }


	    set e $calvar
	    return $e
	}
	proc getAssem {args} {
	    upvar tag tag
	    variable OPT;
	    set dir $::env(TEMP)
	    set file_dir [file join $dir report$tag resources];
	    set file_list [glob -directory $file_dir -nocomplain *.data]
	    catch {unset OPT(ASSEM,NAME)}
	    catch {unset OPT(ASSEM,VALUE)}
	    set OPT(ASSEM,NAME) [list];
	    set OPT(ASSEM,VALUE) [list];
	    set OPT(ASSEM,FILE) [list];
	    foreach file $file_list {
		if ![IsFileType $file {^Assem}] {
		    continue
		}
		set fch [open $file r];
		gets $fch line
		close $fch
		set split_list [split $line ,]
		lappend OPT(ASSEM,NAME) [lindex $split_list 1];
		lappend OPT(ASSEM,VALUE) [lindex $split_list 2];
		lappend OPT(ASSEM,FILE) $file;
	    }
	}
	proc getRateFile {args} {
	    upvar tag tag
	    variable OPT;

	    set dir $::env(TEMP)
	    set file_dir [file join $dir report$tag resources];
	    set file_list [glob -directory $file_dir -nocomplain *.data]
	    foreach file $file_list {
		if [IsFileType $file ^Head] {
		    return $file
		}
	    }
	    return ""
	}
	proc IsFileType {filename matchstring} {
	    set fch [open $filename r]
	    set content [read $fch];
	    close $fch
	    return [regexp -- $matchstring $content]
	}

	proc InsertCross {newGroupNode} {
	    # upvar doc doc
	    # AddNode $newGroupNode part type "image" title "" content "vline.png" x 350 y 70 w 5 h 400 lockaspect 0
	    # AddNode $newGroupNode part type "image" title "" content "hline.png" x 50 y 250 w 600 h 7 lockaspect 0
	}
	proc InsertLabelStyle1 {newGroupNode} {
	    upvar doc doc
	    AddNode $newGroupNode part type text content "Left View" title "Left View" x 240 y 220 w 100 h 100  font "Times New Roman&宋体" fontSize "16" align "left" fontStyle "Bold" bgColor RGB(222,222,222) lineskip 1.0 linestyle RGB(255,255,255)
	    AddNode $newGroupNode part type text content "ISO View" title "Left View" x 370 y 220 w 100 h 100  font "Times New Roman&宋体" fontSize "16" align "left" fontStyle "Bold" bgColor RGB(222,222,222) lineskip 1.0
	    AddNode $newGroupNode part type text content "Top View" title "Left View" x 240 y 260 w 100 h 100  font "Times New Roman&宋体" fontSize "16" align "left" fontStyle "Bold" bgColor RGB(222,222,222) lineskip 1.0
	    AddNode $newGroupNode part type text content "Bottom View" title "Left View" x 370 y 260 w 150 h 100 font "Times New Roman&宋体" fontSize "16" align "left" fontStyle "Bold" bgColor RGB(222,222,222) lineskip 1.0
	}

	proc InsertLabelStyle2 {newGroupNode} {
	    upvar doc doc
	    AddNode $newGroupNode part type text content "Left View" title "Left View" x 240 y 220 w 100 h 100  font "Times New Roman&宋体" fontSize "16" align "left" fontStyle "Bold" bgColor RGB(222,222,222) lineskip 1.0
	    AddNode $newGroupNode part type text content "Top View" title "Left View" x 370 y 220 w 100 h 100  font "Times New Roman&宋体" fontSize "16" align "left" fontStyle "Bold" bgColor RGB(222,222,222) lineskip 1.0
	    AddNode $newGroupNode part type text content "ISO View" title "Left View" x 240 y 260 w 100 h 100  font "Times New Roman&宋体" fontSize "16" align "left" fontStyle "Bold" bgColor RGB(222,222,222) lineskip 1.0
	}

	proc InsertSubfigure {newGroupNode resourcename xsub ysub {x_scale 1} {y_scale 1}} {
	    upvar doc doc
	    set cur_x [expr 40 + ($xsub -1) * 330]
	    set cur_y [expr 70 + ($ysub -1) * 220]
	    set width [expr $x_scale * 300]
	    set height [expr $y_scale * 180]
	    AddNode $newGroupNode part type image content $resourcename x $cur_x y $cur_y w $width h $height lockaspect 1}
	proc InsertSubtable {newGroupNode resourcename xsub ysub {x_scale 1} {font_size 12} {column ""} {merge ""}} {
	    upvar doc doc
	    set cur_x [expr 40 + ($xsub -1) * 350]
	    set cur_y [expr 70 + ($ysub -1) * 220]
	    set width [expr $x_scale * 300]

	    AddNode $newGroupNode part type table content $resourcename x $cur_x y $cur_y w $width h 3 lockaspect 0 fontSize $font_size column $column Merge $merge
	}
	proc InsertFigureLabel {newGroupNode text xsub ysub} {
	    upvar doc doc
	    set cur_x [expr 160 + ($xsub -1) *300]
	    set cur_y [expr 60 + ($ysub -1) * 200]
	    set width 100
	    AddNode $newGroupNode part type text content "$text" title "$text" x $cur_x y $cur_y w $width h 10 font "Tohamo" fontSize "16" align "center" fontStyle "Bold"

	}

	proc createTableForModelCheck {args} {
	    set dir $::env(TEMP)
	    upvar tag tag
	    set file_dir [file join $dir report$tag resources];
	    set fch [open [file join $file_dir modelcheck.csv] w];
	    puts $fch ",理论值,计算值,百分率"
	    set item_list [list "动力总成动能（kJ）" "总动能 （kJ）" "滑移能（kJ）" "沙漏能（kJ）" "能量比" "质量增加 (kg)"];
	    touch "[file join $file_dir p1w3.data]"
	    set fch2 [open [file join $file_dir p1w3.data] r];
	    gets $fch2 line
	    foreach item $item_list {
		set line ""
		set getline 0
		while {$getline==0} {
		    set getline [gets $fch2 line]
		    if {$getline!=0} {break}
		}
		set result [split $line ,]
		set calvar [lindex $result 0]
		set thevar [lindex $result 1]
		if {[lsearch $item_list $item]==0 || [lsearch $item_list $item]==1 } {
		    set t_value "";
		} else {
		    set t_value -;
		}
		if {[lsearch $item_list $item]==4} {
		    set t_value 1;
		    set format_string %.3f;
		} else {
		    set format_string %.1f;
		}


		puts $fch "$item,&[formatF $t_value],&[formatF $calvar $format_string],&[formatF $thevar]"
	    }
	    close $fch
	    close $fch2
	}
	proc createTableForInvader {args} {
	    set dir $::env(TEMP)
	    upvar tag tag
	    set file_dir [file join $dir report$tag resources];
	    set fch [open [file join $file_dir invader.csv] w];
	    puts $fch "测量,说明,方向,仿真结果,仿真结果"
	    puts $fch "测量,说明,方向,&reference,&result"


	    set name_id_list [list "围板-ECU前端"       "93000001"\
				  "围板-HVAC后部"       "93000002" \
				  "围板-纵梁根部-左侧"   "93000003"\
				  "围板-纵梁根部-右侧"   "93000004"\
				  "围板- 离合踏板前端"   "93000005"\
				  "围板- 刹车踏板前端"   "93000006"\
				  "围板- 油门踏板前端"   "93000007"\
				  "A柱向后位移量-左侧"   "94000001"\
				  "A柱向后位移量-右侧"   "94000002"\
				  "CCB-管柱连接处"      "93000017"\
				  "驾驶员搁脚板-脚趾-左脚" "93000008"\
				  "驾驶员搁脚板-脚跟-左脚" "93000009"\
				  "驾驶员脚跟，右脚，油门" "93000010"\
				  "乘员搁脚板-脚趾，左脚"  "93000011"\
				  "乘员搁脚板-脚趾，右脚"  "93000012"\
				  "离合踏板"             "93000013"\
				  "制动踏板"             "93000014"\
				  "加速踏板"             "93000015"\
				  "管柱末端"             "93000016" ]

	    array set arr_name_id $name_id_list



	    set ref_list [list "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "<10" \
			      "-" \
			      "<10" \
			      "<10" \
			      "-" \
			      "<10" \
			      "<10" \
			      "-" \
			      "<10" \
			      "<10" \
			      "-" \
			      "<10" ]


	    touch "[file join $file_dir p4w1.data]"
	    set fch2 [open [file join $file_dir p4w1.data] r];
	    foreach t [array name arr_name_id] {
		set result($arr_name_id($t)) -;
	    }
	    set content [read $fch2]
	    if {$content!=""} {
		foreach {x y} $content {
		    array set result [list $x $y]
		}
	    }

	    close $fch2

	    for {set i 0} {$i<15} {incr i} {
		set index [lindex $name_id_list [expr $i*2]];
		set id $arr_name_id($index);
		set value $result($id);
		set value [lindex $result($id) 0 0]
		if {$i==7||$i==8} {
		    set value [lindex $result($id) 0 1];
		}
		puts $fch "[expr $i+1],&$index,&X,&[formatF [lindex $ref_list $i]],&[formatF $value %.0f]"
	    }
	    for {set i 0} {$i<12} {incr i} {
		set index [lindex $name_id_list [expr ($i/3)*2+30]];
		set id $arr_name_id($index);
		set value [lindex $result($id) [expr $i%3] 0];
		if {$i%3==1} {
		    set value1 [lindex $result($id) [expr $i%3] 1];
		    set value2 [lindex $result($id) [expr $i%3] 0];
		    if {[string is double $value2] && [string is double $value1] && $value1!="" &&$value2 !=""} {
			set value [expr max(abs($value1),abs($value2))];
		    }

		}
		puts $fch "[expr $i/3+16],&$index,[lindex {X Y Z} [expr $i%3]],&[formatF [lindex $ref_list $i+15]],&[formatF $value %.0f ]"
	    }
	    close $fch
	}
	proc createTableForBox {args} {
	    set dir $::env(TEMP)
	    upvar tag tag
	    set file_dir [file join $dir report$tag resources];
	    set fch [open [file join $file_dir boxforce.csv] w];

	    puts $fch "序号,位置,左侧,左侧,右侧,右侧"
	    puts $fch "序号,位置,截面力（kN）,时间(ms),截面力（kN）,时间(ms)"

	    # set type_list [list "A-pillar"\
		#        "Rocker"\
		#        "Floor rail"\
		#        "Tunnel rail"\
		#        "Tunnel frt"]
	    # set id_list [list 9540001\
		#      9540002\
		#      9510031\
		#      9510032\
		#      9510001\
		#      9510002\
		#      9510081\
		#      9510082\
		#      9510011]

	    touch "[file join $file_dir p9w1.data]"
	    set fch2 [open [file join $file_dir p9w1.data] r]

	    set index -1
	    while {1} {
		incr index
		set line ""
		set getline 0
		while {$getline==0} {
		    set getline [gets $fch2 line]
		    if {$getline!=0} {break}
		}
		if {$getline==-1} {
		    break
		}

		set value [split $line ,]
		set outputflag [lindex $value 0]
		set name [lindex $value 1]
		set value_left [lindex $value 2]
		set time_left [lindex $value 3];
		set value_right [lindex $value 4]
		set time_right [lindex $value 5]

		if {$outputflag==0} {
		    incr index -1
		    continue
		}

		set a_index [getLetter $index]
		puts $fch "$a_index,&$name,&[formatF $value_left],&[formatF $time_left],&[formatF $value_right],&[formatF $time_right]"

	    }

	    close $fch
	    close $fch2;

	}
	proc getLetter {index} {
	    set ALPHABETA "ABCDEFGHIJKLMNOPQ"
	    return [string index $ALPHABETA $index];
	}

	proc createTableForFront {args} {
	    set dir $::env(TEMP)
	    upvar tag tag
	    set file_dir [file join $dir report$tag resources];
	    set fch [open [file join $file_dir frontforce.csv] w];

	    puts $fch "序号,位置,左侧,左侧,右侧,右侧"
	    puts $fch "序号,位置,截面力（kN）,时间（ms）,截面力（kN）,时间（ms）"

	    # set type_list [list "Crash box"\
		#        "Frt-rail frt"\
		#        "Mid-rail frt"\
		#        "Rr-rail frt"\
		#        "Flr rail"\
		#        "A pillar"\
		#        "shotgun"\
		#        "Rocker"]
	    # set id_list [list 9280311 9280312 9840001 9840002 9840011 9840012 9840021 9840022 9510011 9510012 9540001 9540002 9840301 9840302 9510031 9510032]

	    touch "[file join $file_dir p8w1.data]"
	    set fch2 [open [file join $file_dir p8w1.data] r]


	    set index -1
	    while {1} {
		incr index
		set line ""
		set getline 0
		while {$getline==0} {
		    set getline [gets $fch2 line]
		    if {$getline!=0} {break}
		}
		if {$getline==-1} {
		    break;
		}
		set value [split $line ,]
		set outputflag [lindex $value 0]
		set name [lindex $value 1]
		set value_left [lindex $value 2];
		set time_left [lindex $value 3];
		set value_right [lindex $value 4];
		set time_right [lindex $value 5];
		if {$outputflag==0} {
		    incr index -1
		    continue
		}
		set a_index [getLetter $index]
		puts $fch "$a_index,&$name,&[formatF $value_left],&[formatF $time_left],&[formatF $value_right],&[formatF $time_right]"
	    }
	    close $fch
	    close $fch2;
	}
	proc createTableForAccelerator {args} {

	    set dir $::env(TEMP)
	    upvar tag tag
	    set file_dir [file join $dir report$tag resources];
	    set fch [open [file join $file_dir accelerator.csv] w];
	    puts $fch " ,整体峰值,整体峰值,第三阶段峰值,第三阶段峰值"
	    puts $fch " ,Reference,Result,Reference,Result"
	    set item_list [list "LH" "RH"]

	    touch "[file join $file_dir p5w1.data]"
	    set fch2 [open [file join $file_dir p5w1.data] r]

	    set index -1

	    while {1} {
		incr index
		set line ""
		set getline 0
		while {$getline==0} {
		    set getline [gets $fch2 line]
		    if {$getline!=0} {break}
		}
		if {$getline==-1} {
		    break;
		}
		set value [split $line ,]
		set name_tag [lindex $item_list $index];
		set value1 [lindex $value 0];
		set value2 [lindex $value 1];

		puts $fch "&$name_tag,&<10g,&[formatF $value1],&<10g,&[formatF $value2]"
	    }
	    close $fch2
	    close $fch
	}

	proc createTableForRate {args} {
	    set dir $::env(TEMP)
	    upvar tag tag
	    set file_dir [file join $dir report$tag resources];
	    set fch [open [file join $file_dir rate.csv] w];
	    set header1 "&Injury Criteria,&,&, Performance,Case2（Driver）,Case2（Driver）,Case2（Driver）,M2EM（Driver）,M2EM（Driver）,M2EM（Driver）"
	    set header2 "&,&,&, Performance,伤害值,单项得分,总得分,伤害值,单项得分,总得分"

	    variable OPT
	    set score_file [file join $OPT(PATH,SCRIPT) config rate.conf]
	    set fz [open $score_file r];
	    set sf [read $fz]
	    close $fz
	    eval set score_domain $sf


	    array set TABLE_LIST [list];

	    for {set i 0} {$i< [expr [llength $score_domain]+3]} {incr i} {
		if {$i==0} {
		    set data $header1
		} elseif {$i==1} {
		    set data $header2
		} elseif {$i>=2&&$i<=6} {
		    set data "头颈部,&,&,&\[[lindex $score_domain [expr $i-2]]\],&,&,&,&,&,&,&"
		} elseif {$i==7||$i==8} {
		    set data "胸部,&,&,&\[[lindex $score_domain [expr $i-2]]\],&,&,&,&,&,&,&"
		} elseif {$i>=9&&$i<=12} {
		    if {$i<=10} {
			set subtitle "左侧大腿"
		    } else {
			set subtitle "右侧大腿"
		    }
		    set data "大腿,$subtitle,&,&\[[lindex $score_domain [expr $i-2]]\],&,&,&,&,&,&,&"
		} elseif {$i>=13&&$i<=20} {

		    if {$i==13||$i==14||$i==17||$i==18} {
			set ud "上腿"
		    } else {
			set ud "下腿"
		    }
		    if {$i<=16} {
			set ld "左侧"
		    } else {
			set ld "右侧"
		    }
		    set data "小腿,${ld}${ud},&,&\[[lindex $score_domain [expr $i-2]]\],&,&,&,&,&,&,&"
		} elseif {$i>=21} {
		    set data "总分,C-NCAP评分,C-NCAP评分,C-NCAP评分,&,&,&,&,&,&,&"
		}
		for {set j 0} {$j< 10} {incr j} {
		    set TABLE_LIST($i,$j) [lindex [split $data ,] $j]
		}
	    }

	    set rate_file [getRateFile]
	    if {$rate_file==""} {
		variable OPT
		set OPT(RATEFLAG) off
		touch "[file join $file_dir rate.data]"
		set fch2 [open [file join $file_dir rate.data] r]
	    } else {
		set fch2 [open $rate_file r];
	    }



	    set line "" ;
	    while {[gets $fch2 line]!=-1} {
		set value_list [split $line ,];
		set row [getRateRow $line];

		if {$row==""} {
		    continue
		}
		set value [lindex $value_list 2];
		set dummyvalue [lindex $value_list 3];
		set name [lindex $value_list 1];
		set TABLE_LIST($row,2) &$name

		set domain $TABLE_LIST($row,3);
		set domain [string map "\[ {}" $domain]
		set domain [string map "\] {}" $domain]
		set domain [string map "\& {}" $domain]


		set TABLE_LIST($row,4) "&$value"
		set rate [getRate $domain $value 4.0];
		set color [getRateColor $domain $value];
		set TABLE_LIST($row,5) "&$rate@#{$color}"



		if {$OPT(DUMMYFLAG)=="on"} {
		    set TABLE_LIST($row,7) "&$dummyvalue"
		    set drate [getRate $domain $dummyvalue 4.0]
		    set dcolor [getRateColor $domain $dummyvalue]
		    set TABLE_LIST($row,8) "&$drate@#{$dcolor}"
		    set TABLE_LIST($row,9) ""
		}
	    }
	    close $fch2

	    if {$rate_file==""} {
		return
	    }

	    # calculate color for summary
	    proc setMinRate {start end} {
		variable OPT
		upvar TABLE_LIST TABLE_LIST
		set min_rate 4.1
		for {set i $start}  {$i<=$end} {incr i} {
		    set rate "";
		    regexp -- {&([\d\.]+)@#} $TABLE_LIST($i,5) match rate;
		    if ![string is double $rate] {
			continue
		    }

		    if {$min_rate>$rate} {
			set min_rate $rate
			set TABLE_LIST($start,6) $TABLE_LIST($i,5)
		    }
		}

		if {$OPT(DUMMYFLAG)=="on"} {
		    set min_rate 4.1;
		    for {set i $start}  {$i<=$end} {incr i} {
			set drate ""
			regexp -- {&([\d\.]+)@#} $TABLE_LIST($i,8) match drate;
			if ![string is double $drate] {
			    continue
			}

			if {$min_rate>$drate} {
			    set min_rate $drate
			    set TABLE_LIST($start,9) $TABLE_LIST($i,8)
			}
		    }
		}
	    }

	    setMinRate 2 6
	    setMinRate 7 8
	    setMinRate 9 12
	    setMinRate 13 20

	    set rate_sum 0;
	    foreach i {2 7 9 13} {
		regexp -- {^&([\d\.]+)@#} $TABLE_LIST($i,6) match rate;
		set rate_sum [expr $rate_sum + $rate];
	    }
	    set TABLE_LIST(21,6) &$rate_sum;
	    if {$OPT(DUMMYFLAG)=="on"} {
		set drate_sum 0;
		foreach i {2 7 9 13} {
		    regexp -- {^&([\d\.]+)@#} $TABLE_LIST($i,9) match rate;
		    set drate_sum [expr $drate_sum + $rate];
		}
		set TABLE_LIST(21,9) &$drate_sum;
	    }



	    for {set i 0} {$i<[expr [llength $score_domain]+3]} {incr i} {
		for {set j 0} {$j<9} {incr j} {
		    puts $fch $TABLE_LIST($i,$j), nonewline
		}
		puts $fch $TABLE_LIST($i,9) nonewline
		puts $fch \n nonewline
	    }
	    close $fch
	}
	proc formatF {string {formatstring %.1f}} {
	    if [string is double -strict $string] {
		return [format $formatstring $string]
	    }
	    return $string;
	}
	proc getRateRow {line} {
	    switch -regexp $line {
		"Head,HIC36" {
		    set row 2
		}
		"Head,A3ms" {
		    set row 3
		}
		"Neck,Fx" {
		    set row 4
		}
		"Neck,Fz" {
		    set row 5
		}
		"Neck,My" {
		    set row 6
		}
		"Chest,A3ms" {
		    set row 7
		}
		"Chest,THPC" {
		    set row 8
		}
		"Femur_L,FFC" {
		    set row 9
		}
		"Femur_L,Slid" {
		    set row 10
		}
		"Femur_R,FFC" {
		    set row 11
		}
		"Femur_R,Slid" {
		    set row 12
		}
		"Leg_lh,TCFC" {
		    set row 13
		}
		"Leg_lh,TI" {
		    set row 14
		}
		"Leg_ll,TCFC" {
		    set row 15
		}
		"Leg_ll,TI" {
		    set row 16
		}
		"Leg_rh,TCFC" {
		    set row 17
		}
		"Leg_rh,TI" {
		    set row 18
		}
		"Leg_rl,TCFC" {
		    set row 19
		}
		"Leg_rl,TI" {
		    set row 20
		}
		default {
		    set row ""
		}
	    }
	    return $row
	}

	proc createTableForEdistr {args} {
	    variable OPT
	    upvar tag tag
	    upvar dir dir

	    array set TABLE_LIST [list];


	    set TABLE_LIST(0,0) " "
	    set TABLE_LIST(1,0) "吸能(kJ)"
	    set TABLE_LIST(2,0) "百分比(%)"

	    set e [getEnergy]

	    set TABLE_LIST(0,1) "总能"
	    set TABLE_LIST(1,1) "$e"
	    set TABLE_LIST(2,1) "100"

	    set cols 1

	    if [catch {set OPT(ASSEM,NAME)}] {
		return;
	    }
	    foreach iname $OPT(ASSEM,NAME) ivalue $OPT(ASSEM,VALUE) {
		incr cols;
		set TABLE_LIST(0,$cols) $iname
		set TABLE_LIST(1,$cols) $ivalue

		if [catch    { set TABLE_LIST(2,$cols) [format %.2f [expr 1.0*$ivalue/$e*100]]}] {
		    set TABLE_LIST(2,$cols) -
		}
	    }

	    set file_dir [file join $dir report$tag resources];
	    set fch [open [file join $file_dir edistr.csv] w];


	    set col_name [array name TABLE_LIST 0,*]
	    set row_name [array name TABLE_LIST *,1]

	    for {set i 0} {$i<[llength $row_name]} {incr i} {
		for {set j 0} {$j<[expr [llength $col_name] -1 ]} {incr j} {
		    puts $fch "&[formatF $TABLE_LIST($i,$j)]," nonewline
		}
		puts $fch "&[formatF $TABLE_LIST($i,[expr [llength $col_name]-1])]" nonewline
		puts $fch "\n"  nonewline
	    }
	    close $fch
	}
	getAssem;
	createTableForModelCheck
	createTableForInvader

	createTableForFront
	createTableForBox
	createTableForAccelerator
	createTableForEdistr
	createTableForRate
	proc 模型确认 {root} {
	    upvar doc doc


	    set newSlideNode [AddNode $root slide];
	    set newGroupNode [AddNode $newSlideNode group type "text" title "模型确认" x "120" y "10" w "600" h "40" font "Times New Roman&宋体" fontSize "32" align "left";]
	    InsertCross $newGroupNode
	    InsertSubfigureArray $newGroupNode p1w1.png 1 1 2 2
	    InsertSubfigureArray $newGroupNode p1w2.png 2 1 2 2
	    InsertSubfigureArray $newGroupNode p1w4.png 2 2 2 2
	    InsertSubtable $newGroupNode modelcheck.csv 1 2 1.2 9 {1 120 2 60 3 60 4 60}

	}
	proc 整车变形 {root} {
	    upvar doc doc
	    set newSlideNode [AddNode $root slide];
	    set newGroupNode [AddNode $newSlideNode group type "text" title "整车变形图" x "120" y "10" w "600" h "40" font "Times New Roman&宋体" fontSize "32" align "left";]
	    InsertSubfigureArray $newGroupNode p2w1.png 1 1 2 2
	    InsertSubfigureArray $newGroupNode p2w2.png 1 2 2 2
	    InsertSubfigureArray $newGroupNode p2w3.png 2 1 2 2
	    InsertSubfigureArray $newGroupNode p2w4.png 2 2 2 2
	    InsertCross $newGroupNode
	    InsertLabelStyle1 $newGroupNode

	}
	proc 乘员舱变形 {root} {
	    upvar doc doc
	    set newSlideNode [AddNode $root slide];
	    set newGroupNode [AddNode $newSlideNode group type "text" title "乘员舱变形图" x "120" y "10" w "400" h "40" font "Times New Roman&宋体" fontSize "32" align "left";]
	    InsertSubfigureArray $newGroupNode p3w1.png 1 1 2 2
	    InsertSubfigureArray $newGroupNode p3w2.png 1 2 2 2
	    InsertSubfigureArray $newGroupNode p3w3.png 2 1 2 2
	    InsertSubfigureArray $newGroupNode p3w4.png 2 2 2 2

	    InsertCross $newGroupNode
	    InsertLabelStyle2 $newGroupNode

	}
	proc 围板侵入量 {root} {
	    upvar doc doc
	    set newSlideNode [AddNode $root slide];
	    set newGroupNode [AddNode $newSlideNode group type "text" title "围板侵入量" x "120" y "10" w "600" h "40" font "Times New Roman&宋体" fontSize "32" align "left";]

	    InsertSubfigureArray $newGroupNode p4w1.png 1 1 2 2 1.3 1.3
	    InsertSubfigure $newGroupNode p4w2.png 1 2 1
	    InsertSubtable $newGroupNode invader.csv 2 0.72 1.5 8 {1 30 2 150 3 10 4 50 5 50}
	}

	proc 加速度分析 {root} {
	    upvar doc doc
	    set newSlideNode [AddNode $root slide];
	    set newGroupNode [AddNode $newSlideNode group type "text" title "加速度分析" x "120" y "10" w "400" h "40" font "Times New Roman&宋体" fontSize "32" align "left";]
	    InsertSubfigure $newGroupNode p5w2.png 1 1
	    InsertSubfigure $newGroupNode p5w3.png 2 1
	    InsertSubtable $newGroupNode accelerator.csv 1 2 1.0 9 {1 20}
	    # InsertFigureLabel $newGroupNode LH 1 1
	    # InsertFigureLabel $newGroupNode RH 2 1
	    AddNode $newGroupNode part type "object" content abc.data x 50 y 50 w 50 h 50

	}
	proc InsertSubfigureArray {newGroupNode resourcename xsub ysub xmax ymax {scale_x 1} {scale_y 1} {lockaspect 0}} {
	    upvar doc doc

	    set x_ratio [expr 1.0*($xsub-1)/$xmax];
	    set y_ratio [expr 1.0*($ysub-1)/$ymax];
	    set cur_x [expr 40 + 1.0*$x_ratio*600]
	    set cur_y [expr 70 + 1.0*$y_ratio*400]
	    set width [expr 1.0/$xmax*600*$scale_x]
	    set height [expr 1.0/$ymax*400*$scale_y]
	    AddNode $newGroupNode part type image content $resourcename x $cur_x y $cur_y w $width h $height lockaspect $lockaspect
	}
	proc InsertSubfigureLabelArray {newGroupNode label xsub ysub xmax ymax} {
	    upvar doc doc
	    set x_ratio [expr 1.0*($xsub-1)/$xmax];
	    set y_ratio [expr 1.0*($ysub-1)/$ymax];
	    set cur_x [expr 0 + $x_ratio*600]
	    set cur_y [expr 100 + $y_ratio*400]
	    set width 200
	    set height [expr 1.0/$xmax*400]
	    AddNode $newGroupNode part type text title "" content $label x $cur_x y $cur_y w $width h $height font "Tomaha" fontSize "16" align "left" fontStyle bold
	}
	proc 前纵梁分析 {root} {
	    upvar doc doc
	    set dir $::env(TEMP)
	    set newSlideNode [AddNode $root slide];
	    set newGroupNode [AddNode $newSlideNode group type "text" title "附录-前纵梁变形分析" x "120" y "10" w "600" h "40" font "Times New Roman&宋体" fontSize "32" align "left";]

	    upvar tag tag
	    set file_dir [file join $dir report$tag resources];
	    # puts $file_dir
	    set left_file_list [glob -directory $file_dir -nocomplain p6w1_L_*.png]
	    set right_file_list [glob -directory $file_dir -nocomplain p6w1_R_*.png]
	    proc getTime {filename} {
		set root [file tail [file root $filename]];
		regsub {^p6w1_[LR]_} $root "" root
		regsub {\.png} $root "" root
		return $root
	    }
	    set left_time_list [list]
	    set right_time_list [list]
	    foreach file $left_file_list {
		lappend left_time_list [getTime $file];
	    }
	    foreach file $right_file_list {
		lappend right_time_list [getTime $file];
	    }


	    set s_left_time_list [lsort -increasing -real $left_time_list];
	    set s_right_time_list [lsort -increasing -real $right_time_list];

	    for {set i 1} {$i<=[llength $s_left_time_list]} {incr i} {
		set time [lindex $s_left_time_list [expr $i-1]]
		InsertSubfigureArray $newGroupNode p6w1_L_$time.png 2 [expr $i -1.5] 10 [llength $s_left_time_list] 4.0 4.0  1;
		InsertSubfigureLabelArray $newGroupNode "  ${time}ms" 1 $i 3 [llength $s_left_time_list];
	    }


	    for {set i 1} {$i<=[llength $s_right_time_list]} {incr i} {
		set time [lindex $s_right_time_list [expr $i-1]]
		InsertSubfigureArray $newGroupNode p6w1_R_$time.png 8 [expr $i -1.5] 10 [llength $s_right_time_list] 4.0 4.0  1;
		InsertSubfigureLabelArray $newGroupNode ${time}ms 3 $i 3 [llength $s_right_time_list];
	    }
	    AddNode $newGroupNode part type text title "" content "LEFT VIEW" x 160 y 490 w 100 h 20 font "Tomaha" fontSize "16" align "left" fontStyle bold bgColor RGB(222,222,222) lineskip 1.0
	    AddNode $newGroupNode part type text title "" content "RIGHT VIEW" x 460 y 490 w 150 h 20 font "Tomaha" fontSize "16" align "left" fontStyle bold bgColor RGB(222,222,222) lineskip 1.0

	}

	proc 运动特性分析 {root} {
	    upvar doc doc
	    set newSlideNode [AddNode $root slide];
	    set newGroupNode [AddNode $newSlideNode group type "text" title "附录-运动特性分析" x "120" y "10" w "600" h "40" font "Times New Roman&宋体" fontSize "32" align "left";]
	    InsertSubfigureArray $newGroupNode p7w1.png 1 1 2 2
	    InsertSubfigureArray $newGroupNode p7w2.png 2 1 2 2
	    InsertSubfigureArray $newGroupNode p7w3.png 1 2 2 2
	    InsertSubfigureArray $newGroupNode p7w4.png 2 2 2 2

	}
	proc 关键力截面力前结构 {root} {
	    upvar doc doc
	    set newSlideNode [AddNode $root slide];
	    set newGroupNode [AddNode $newSlideNode group type "text" title "附录-运动特性分析-前结构" x "120" y "10" w "600" h "40" font "Times New Roman&宋体" fontSize "32" align "left";]
	    InsertSubfigure $newGroupNode p8w0.png 1 1
	    InsertSubtable $newGroupNode frontforce.csv 1 2 1.4 9 {1 20 2 120 3 50 4 50 5 50 6 50}
	    InsertSubfigureArray $newGroupNode p8w2.png 2.8 1 3 3 1.3 1.3
	    InsertSubfigureArray $newGroupNode p8w3.png 2.8 2.5 3 3 1.3 1.3

	}
	proc 关键力截面力乘员舱 {root} {
	    upvar doc doc
	    set newSlideNode [AddNode $root slide];
	    set newGroupNode [AddNode $newSlideNode group type "text" title "附录-运动特性分析-乘员舱" x "120" y "10" w "600" h "40" font "Times New Roman&宋体" fontSize "32" align "left";]
	    InsertSubfigure $newGroupNode p9w0.png 1 1
	    InsertSubtable $newGroupNode boxforce.csv 1 2 1.4 9 {1 20 2 120 3 50 4 50 5 50 6 50}
	    InsertSubfigureArray $newGroupNode p9w2.png 2.8 1 3 3 1.3 1.3
	    InsertSubfigureArray $newGroupNode p9w3.png 2.8 2.5 3 3 1.3 1.3
	}

	proc 能量分布分析 {root} {
	    upvar doc doc
	    variable OPT;
	    set newSlideNode [AddNode $root slide];
	    set newGroupNode [AddNode $newSlideNode group type "text" title "附录-能量分布分析" x "120" y "10" w "600" h "40" font "Times New Roman&宋体" fontSize "32" align "left";]
	    proc getPicListFromFile {args} {
		variable OPT;
		for {set i 0} {$i<8} {incr i} {
		    lappend emptylist nopic.png
		}
		foreach name $OPT(ASSEM,FILE) {
		    lappend piclist [regsub 1$ [file tail [file root $name]] 3].png
		}

		for {set i 0} {$i<8} {incr i} {
		    if {$i<[llength $piclist]} {
			lappend real_pic_list [lindex $piclist $i]
		    } else {
			lappend real_pic_list [lindex $emptylist $i]
		    }

		}

		return $real_pic_list

	    }
	    set piclist [getPicListFromFile;]
	    foreach {file1 file2 file3 file4 file5 file6 file7 file8}  $piclist  {
	    }
	    foreach {label1 label2 label3 label4 label5 label6 label7 label8} $OPT(ASSEM,NAME) {
	    }
	    InsertSubfigureArray $newGroupNode $file1 1 1 4 3
	    InsertSubfigureLabelArray $newGroupNode "      $label1" 1 2 4 3
	    InsertSubfigureArray $newGroupNode $file2 2 1 4 3
	    InsertSubfigureLabelArray $newGroupNode "      $label2" 2 2 4 3
	    InsertSubfigureArray $newGroupNode $file3 3 1 4 3
	    InsertSubfigureLabelArray $newGroupNode "      $label3" 3 2 4 3
	    InsertSubfigureArray $newGroupNode $file4 4 1 4 3
	    InsertSubfigureLabelArray $newGroupNode "      $label4" 4 2 4 3
	    InsertSubfigureArray $newGroupNode $file5 1 2 4 3
	    InsertSubfigureLabelArray $newGroupNode "      $label5" 1 3 4 3
	    InsertSubfigureArray $newGroupNode $file6 2 2 4 3
	    InsertSubfigureLabelArray $newGroupNode "      $label6" 2 3 4 3
	    InsertSubfigureArray $newGroupNode $file7 3 2 4 3
	    InsertSubfigureLabelArray $newGroupNode "      $label7" 3 3 4 3
	    InsertSubfigureArray $newGroupNode $file8 4 2 4 3
	    InsertSubfigureLabelArray $newGroupNode "      $label8" 4 3 4 3

	    AddNode $newGroupNode part type table content edistr.csv x 50 y 350 w 600 h 10

	}

	proc 伤害值评估 {root} {
	    upvar doc doc
	    set newSlideNode [AddNode $root slide];
	    set newGroupNode [AddNode $newSlideNode group type "text" title "伤害值评估" x "120" y "10" w "600" h "40" font "Times New Roman&宋体" fontSize "32" align "left";]
	    InsertSubtable $newGroupNode rate.csv 1 1 2.0 9 {4 70} [list {1 1} {2 3} \
									{3 7} {7 7} \
									{3 10} {7 10} \
									{8 7} {9 7} \
									{8 10} {9 10} \
									{10 7} {13 7} \
									{10 10} {13 10} \
									{14 7} {21 7} \
									{14 10} {21 10} \
									{22 5} {22 7} \
									{22 8} {22 10} \
									{3 2} {3 3} \
									{4 2} {4 3} \
									{5 2} {5 3} \
									{6 2} {6 3} \
									{7 2} {7 3} \
									{8 2} {8 3} \
									{9 2} {9 3} ]

	}

	proc 时间历程图 {root} {
	    upvar doc doc
	    variable OPT
	    if {$OPT(STRUCTFLAG)=="on"} {
		set start_page 10
	    } else {
		set start_page 1;
	    }
	    set pic_list [list "头部" "颈部" "胸部" "髋部" "大腿" "小腿" "小腿" "安全带及压缩量"]
	    for {set i 0} {$i<[llength $pic_list]} {incr i} {
		set newSlideNode [AddNode $root slide];
		set newGroupNode [AddNode $newSlideNode group type "text" title "时间历程图: [lindex $pic_list $i]" x "50" y "10" w "600" h "40" font "Times New Roman&宋体" fontSize "32" align "center";]
		# for {set j 1} {$j<=4} {incr j} {
		#     InsertSubfigureArray $newGroupNode p[expr $start_page+$i]w$j.png [expr $j/2 -($j+1)%2+1] [expr ($j+1)%2+1] 2 2
		# }
		InsertSubfigureArray $newGroupNode p[expr $start_page+$i].png 1 1 1 1
	    }

	}

	FirstSlide $root

	if {$OPT(STRUCTFLAG)=="on"} {
	    模型确认 $root
	    整车变形 $root
	    乘员舱变形 $root
	    围板侵入量 $root
	    加速度分析 $root
	    前纵梁分析 $root
	    运动特性分析 $root
	    关键力截面力前结构 $root
	    关键力截面力乘员舱 $root
	    能量分布分析 $root
	}
	if {$OPT(RATEFLAG)=="on"} {
	    时间历程图 $root
	    伤害值评估 $root
	}

	set xmlfile [file join $dir report$tag xml$tag]
	# puts $xmlfile
	set fch [open $xmlfile w];
	# puts $doc
	$doc asXML -channel $fch
	close $fch
	::CREATEPPT::SaveReportByXml $template_path $report_path $xmlfile
    }
    proc touch {filename} {
	set fch [open $filename a]
	close $fch;
    }
    #    createPPT {D:/CheryProject/source_code/crash/config/Chery.pot} {D:/crash} D:/abc.ppt
}
