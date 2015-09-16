encoding system gb2312;		
# defining some useful things for MS Office
##################################################################################
# generating a boolean type (At this time I don't know a better way)
set TRUE 1
set FALSE 0
if {$TRUE} {}
if {$FALSE} {}
##################################################################################
proc AddVariableToVBS {var value} {
    variable vbs
    append vbs "\n"
    append vbs "$var = $value \n"
}

proc OpenPowerPoint {} {
    # containing the vbs script
    variable vbs
    variable idCounter
    set idCounter 1
    variable copylist
    variable copycounter

    if [info exists vbs ] { unset vbs  }
    if [info exists copylist ] { unset copylist  }
    set copycounter 1

    set vbs "sub pptGen\n\n"

    # set the current dir in the vb-script
    append vbs "Set fso = CreateObject(\"Scripting.FileSystemObject\")\n"
    append vbs "curdir = fso.GetAbsolutePathname(\".\")\n\n"

    append vbs "Set objPPT = CreateObject(\"PowerPoint.Application\")\n"

    return objPPT
}

################################################
# Procedure: GetUniqueId
# Author: ebeling
# Date: 25.07.2008
# Description:
# returns a unique id
# Parameters:
#
# Variables:
# idCounter
# Returns:
#
################################################
proc GetUniqueId { } {
    variable idCounter
    incr idCounter

    return $idCounter
    # end proc GetUniqueId ####################################
}


proc LoadMaster { pres master } {
    variable vbs

    if { $master != "none" } {
	# copy the pptMaster
	set vbsfilename [addtoCopyListReturnVbsname $master]
	# append vbs "Set newDesign = $pres.ApplyTemplate($vbsfilename)\n"
	# new form to add a master (copied from old toolbar export)
	append vbs "Set newDesign = $pres.Designs.Load($vbsfilename)\n"
	append vbs "newDesign.MoveTo(1)\n"
	# append vbs "If $pres.HasTitleMaster Then \n"
	# append vbs "    $pres.AddTitleMaster\n"
	# append vbs "End If\n"
	append vbs "no = 1\n"
	append vbs "set slides = $pres.Slides\n"
	append vbs "set slide = slides.Add(no,12)\n"
    }
    return $pres
}


# add the file for later copy to the datadir, give a new uniq relative name
proc addtoCopyListReturnVbsname { fname } {
    variable vbs
    variable copylist
    variable copycounter

    set rootname  [file rootname  [file tail $fname]]
    set extension [file extension [file tail $fname]]
    set newfname "${rootname}_${copycounter}${extension}"

    # add an entry for the copylist
    lappend copylist [list $fname $newfname]

    # make relative vbs entry
    set vbsfilename  "filetoload_${copycounter}"
    append vbs "$vbsfilename = fso.BuildPath( curdir , \"\$DATADIR2SUBS\\$newfname\")\n"

    incr copycounter 1

    return $vbsfilename
}


proc PptState { pptApp {Visible 1} {WindowState 3} } {
    variable vbs
    append vbs "$pptApp.Visible = $Visible \n"
    append vbs "$pptApp.WindowState = $WindowState\n"
}

proc ClosePowerPoint { pres pptFile } {

    variable copylist
    variable vbs

    # directoryname where pptFile is stored
    set dirname [file dirname $pptFile]

    # create a directory to place the pictures in
    set picdirname "[file rootname [file tail $pptFile]]_ppt"
    set fppicdirname [file join $dirname $picdirname]
    file mkdir $fppicdirname

    if { [info exist copylist] } {
	# copy all file into the datadir
	foreach pair $copylist {
	    set sourcefile [lindex $pair 0]
	    set targetfile [file join $fppicdirname [lindex $pair 1]]
	    file copy -force $sourcefile $targetfile
	}
    }
    
    if { [file exists $pptFile]==1 } {
	file delete -force $pptFile
    }
    # save ppt
    append vbs "\n\n objPresentation.SaveAs \"\"\"$pptFile\"\"\" \n\n"
    
    #close the pptGen subroutine
    append vbs "\nEnd Sub\n"
    append vbs "\npptGen\n"

    # substitue the datadirname
    set DATADIR2SUBS "$picdirname"
    set vbs [subst -nobackslashes -nocommands $vbs]

    set vbsFile [string map {".ppt" ".vbs"} $pptFile]
    set out [open $vbsFile w]
    puts $out $vbs
    close $out
    return $vbsFile
}

proc GetNewPresentation {ppoint {orientation vertical}} {
    variable vbs

    append vbs "Set objPresentation = $ppoint.Presentations.Add\n"
    append vbs "PageWidth = objPresentation.PageSetup.SlideWidth\n"
    append vbs "PageHeight = objPresentation.PageSetup.SlideHeight\n"
    append vbs "CustomPageWidth = objPresentation.PageSetup.SlideWidth\n"
    append vbs "CustomPageHeight = objPresentation.PageSetup.SlideHeight\n"
    
    if {$orientation=="horizontal"} {
    } else {
	if {$orientation=="horizontal"} {
	    append vbs "objPresentation.PageSetup.SlideOrientation = msoOrientationHorizontal\n"
	} elseif {$orientation=="vertical"} {
	    append vbs "objPresentation.PageSetup.SlideOrientation = msoOrientationVertical\n"
	}
    }

    return objPresentation
}

################################################
# Procedure: setCustomPageSize
# Author: ebeling
# Date: 25.07.2008
# Description:
#
# Parameters:
# width - the custom page width
# height - the custom page height
# Variables:
#
# Returns:
#
################################################
proc setCustomPageSize {width height} {
    variable vbs
    append vbs "CustomPageWidth = $width\n"
    append vbs "CustomPageHeight = $height\n"


    return 1
    # end proc setCustomPageSize ####################################
}


proc GetCurrentPresentation  {ppoint} {
    variable vbs
    append vbs "Set objPresentation = $ppoint.ActivePresentation\n"
    return objPresentation
}

proc GetFirstSlide {pres {style 12} } {
    variable vbs
    append vbs "set Slides = $pres.Slides\n"
    append vbs "set Slide = Slides.Item(1)\n"
    return Slide
}

# Style has to be a PowerPoint Constant of PpSlideLayout see the Help of Ms VisualBasic
proc NewSlide {pres {style 12} {number last}} {
    variable vbs
    append vbs "set Slides = $pres.Slides\n"
    append vbs "no = Slides.Count\n"
    if {$number == "last"} {
	append vbs "no = no +1\n"
    } else {
	append vbs "IF $number <= 0 OR $number > no Then\n"
	append vbs "   no = no +1\n"
	append vbs "Else\n"
	append vbs "   no = $number\n"
	append vbs "Endif\n"
    }
    append vbs "set Slide = Slides.Add(no,$style)\n"
    return Slide
}

# Style has to be a PowerPoint Constant of PpSlideLayout see the Help of Ms VisualBasic
proc NewSlideWithPattern {pres fName firstV lastV {style 12} {number last}} {
    variable vbs
    set vbsfilename [addtoCopyListReturnVbsname $fName ]

    append vbs "set Slides = $pres.Slides\n"
    append vbs "no = Slides.Count\n"
    if {$number == "last"} {
	append vbs "no = no +1\n"
    } else {
	append vbs "IF $number <= 0 OR $number > no Then\n"
	append vbs "   no = no +1\n"
	append vbs "Else\n"
	append vbs "   no = $number\n"
	append vbs "Endif\n"
    }
    append vbs "set Slide = Slides.Add(no,$style)\n"
    append vbs "Slides.InsertFromFile $vbsfilename,0,$firstV,$lastV \n"
    return slide
}

#####################################################################################################
proc InsertAvi {slide fname {left 100} {top 100} {width 600} {height 400} } {
    #puts "InsertAvi only available for windows"
    #          if {[CheckExist $fname]} {
    #           set shapes [$slide Shapes]
    #            set movie [$shapes AddMediaObject [string map {/ \\} $fname] $left $top $width $height]
    #           return $movie
    #        }
    
}

proc InsertPicture {slide fname {left 100} {top 100} {width 600} {height 400} {LockAspect 1} {cl 0} {cr 0} {ct 0} {cb 0} {cpcolor true}} {
    variable vbs
    append vbs "tmpleft = ($left * 1.0 * PageWidth) / CustomPageWidth\n"
    append vbs "tmptop = ($top * 1.0 * PageHeight) / CustomPageHeight\n"
    append vbs "tmpwidth = ($width * 1.0 * PageWidth) / CustomPageWidth\n"
    append vbs "tmpheight = ($height * 1.0 * PageHeight) / CustomPageHeight\n"
    set id [GetUniqueId]

    if {[CheckExist $fname]} {
	append vbs "\n"

	# new name of the picture to include
	set vbsfilename [addtoCopyListReturnVbsname $fname ]
	set varName "Picture${id}"

	append vbs "set Shape = $slide.Shapes\n"
	#            append vbs "Set textbox = Shape.AddTextbox(1,tmpleft,tmptop,tmpwidth,tmpheight)\n"
	#            append vbs "Set tr = textbox.TextFrame.TextRange\n"
	#            append vbs "tr.Text = \"\"\n"
	#            append vbs "tr.InsertAfter(tmptop)\n"
	#            append vbs "tr.InsertAfter(\" ; \")\n"
	#            append vbs "tr.InsertAfter(tmpheight)\n"
	# set LockAspect 0
	if {$LockAspect} {
	    append vbs "set ${varName} = Shape.AddPicture($vbsfilename,0,1,tmpleft,tmptop)\n"
	    append vbs  "pwidth = ${varName}.Width\n"
	    append vbs  "pheight = ${varName}.Height\n"
	    append vbs  "pwrel = (1.0 * pwidth) / tmpwidth\n"
	    append vbs  "phrel = (1.0 * pheight) / tmpheight\n"
	    append vbs  "If pwrel/phrel < 0.9 Or pwrel/phrel > 1.1 Then\n"
	    append vbs  "    If pwrel > phrel Then\n"
	    append vbs  "        ${varName}.Width = tmpwidth\n"
	    append vbs  "        Newtop = tmptop + (tmpheight - ((1.0 * pheight) / pwrel)) / 2.0\n"
	    append vbs  "        ${varName}.Top = Newtop\n"
	    append vbs  "    Else\n"
	    append vbs  "        ${varName}.Height = tmpheight\n"
	    append vbs  "        Newleft = tmpleft + (tmpwidth - ((1.0 * pwidth) / phrel)) / 2.0\n"
	    append vbs  "        ${varName}.Left = Newleft\n"
	    append vbs  "    End If\n"
	    append vbs  "Else\n"
	    append vbs  "    ${varName}.Width = tmpwidth\n"
	    append vbs  "    ${varName}.Height = tmpheight\n"
	    append vbs  "End If\n"
	} else {
	    append vbs "set ${varName} = Shape.AddPicture($vbsfilename,0,1,tmpleft,tmptop,tmpwidth,tmpheight)\n"
	}
	# crop the picture
	if { $cl > 0 }  {
	    append vbs "${varName}.PictureFormat.CropLeft = $cl\n"
	}
	if { $cr > 0 }  {
	    append vbs "${varName}.PictureFormat.CropRight = $cr\n"
	}
	if { $cb > 0 }  {
	    append vbs "${varName}.PictureFormat.CropBottom = $cb\n"
	}
	if { $ct > 0 }  {
	    append vbs "${varName}.PictureFormat.CropTop = $ct\n"
	}

	# reposition picture
	#           append vbs "${varName}.Top = tmptop\n"
	#           append vbs "${varName}.Left = tmpleft\n"

	#  make white transparent
	if {$cpcolor=="true"} {
	    append vbs "${varName}.Name = \"$varName\"\n"
	    append vbs "${varName}.PictureFormat.TransparencyColor = RGB(255, 255, 255)\n\n"
	}
	return ${varName}
    }
}

proc InsertTextBox {slide stext {left 50} {top 20} {width 600} {height 70} {align center} {orientation 1} {font "New Times Roman&ËÎÌו"} {fontSize 12} {fontStyle regular} {fontcolor vbBlack} {islist 0} {lineskip 0.33} {bgColor ""} {linestyle ""} } {
    variable vbs
    append vbs "tmpleft = $left * PageWidth / CustomPageWidth\n"
    append vbs "tmptop = $top * PageHeight / CustomPageHeight\n"
    append vbs "tmpwidth = $width * PageWidth / CustomPageWidth\n"
    append vbs "tmpheight = $height * PageHeight / CustomPageHeight\n"
    switch -glob $align {
	right {set al 3}
	center {set al 2}
	justity {set al 4}
	distribute {set al 6}
	# default is equal to left (these are MS Powerpoint Constants (PpParagraphAlignment))
	default {set al 1}
    }
    switch -glob [string tolower $fontStyle] {
	regular {
	    set bold 0
	    set italic 0
	}
	italic {
	    set bold 0
	    set italic 1
	}
	bold {
	    set bold 1
	    set italic 0
	}
	"bold italic" {
	    set bold 1
	    set italic 1
	}
	default {
	    set bold 0
	    set italic 0
	}

    }
    # font color
    # vbBlack vbRed vbGreen vbYellow vbBlue vbMagenta vbCyan vbWhite

    # make it a integer
    incr fontSize 0
    incr orientation 0
    incr al 0
    append vbs "Set Shape = $slide.Shapes\n"
    append vbs "Set textbox = Shape.AddTextbox($orientation,tmpleft,tmptop,tmpwidth,tmpheight)\n"
    if {$bgColor!=""} {
	append vbs "textbox.Fill.BackColor.RGB=$bgColor\n"
    }
    if {$linestyle!=""} {
	append vbs "textbox.Line.Weight = 10\n"
	append vbs "textbox.Line.Visible = msoTrue\n"
	append vbs "textbox.Line.ForeColor.RGB = $linestyle\n"
	append vbs "textbox.Line.BackColor.RGB = RGB(255, 255, 255)\n"
    }

    append vbs "Set tr = textbox.TextFrame.TextRange\n"
    if {"$islist" == "0"} {
	if [regexp -- ^@ $stext ] {
	    append vbs "tr.Text = [string map {@ ""} $stext]\n"
	} else {
	    append vbs "tr.Text = \"$stext\"\n"
	}
    } else {
	set vbstext \"[lindex $stext 0]\";
	for {set i 1} {$i<[llength $stext] } {incr i} {
	    set vbstext "$vbstext & vbcrlf & \"[lindex $stext $i]\""
	}
	append vbs "tr.Text = $vbstext\n"
    }
    append vbs "tr.ParagraphFormat.Alignment = $al\n"
    append vbs "tr.ParagraphFormat.Bullet.Visible = msoFalse\n"
    append vbs "tr.Font.Size = $fontSize\n"
    set font_list [split $font &]
    
    set font [lindex $font_list 0]
    append vbs "tr.Font.Nameascii = \"$font\"\n"
    set font [lindex $font_list 1]
    append vbs "tr.Font.NameFarEast = \"$font\"\n"

    append vbs "tr.Font.Bold = $bold\n"
    append vbs "tr.Font.Italic = $italic\n"
    append vbs "tr.Font.Color = $fontcolor\n"
    append vbs "tr.ParagraphFormat.SpaceWithin = $lineskip\n"
    
    return textbox
}


################################################
# Procedure: setTitle
# Author: ebeling
# Date: 18.08.2008
# Description:
#
# Parameters:
# slide - the slide object
# titleText - the title to be set
# Variables:
# vbs
# Returns:
#
################################################
proc SetTitle {slide titleText } {
    variable vbs
    append vbs "Set Shape = $slide.Shapes\n"
    append vbs "Set textbox = Shape.Title\n"
    append vbs "Set tr = textbox.TextFrame.TextRange\n"
    append vbs "tr.Text = \"$titleText\"\n"
    return textbox

    # end proc setTitle ####################################
}

# inserts a H3D player with a link to the given file "fname" into slide of Powerpoint
proc InsertH3DInSlide {slide fname {left 100} {top 100} {width 600} {height 400}} {
    variable vbs
    append vbs "tmpleft = $left * PageWidth / CustomPageWidth\n"
    append vbs "tmptop = $top * PageHeight / CustomPageHeight\n"
    append vbs "tmpwidth = $width * PageWidth / CustomPageWidth\n"
    append vbs "tmpheight = $height * PageHeight / CustomPageHeight\n"
    if {[CheckExist $fname]} {
	append vbs "\n"
	# add file to copy list and get the new name
	set vbsfilename [addtoCopyListReturnVbsname $fname ]
	append vbs "set Shape = $slide.Shapes\n"
	#set shapes [$slide Shapes]
	#set oleShape [$shapes AddOLEObject $left $top $width $height "HVPControl.HVPControl.1"]
	append vbs "set oleShape = Shape.AddOLEObject(tmpleft,tmptop,tmpwidth,tmpheight,\"HVPControl.HVPControl.1\")\n"
	append vbs "set oleFormat = oleShape.OLEFormat\n"
	# set oleFormat [$oleShape OLEFormat]
	append vbs "oleFormat.Object.src = $vbsfilename\n"
	#[$oleFormat Object] src $fname
	return oleShape
    }
    return ""
}

proc InsertObjectInSlide {slide fname {left 100} {top 100} {width 600} {height 400}} {
    variable vbs
    append vbs "tmpleft = $left * PageWidth / CustomPageWidth\n"
    append vbs "tmptop = $top * PageHeight / CustomPageHeight\n"
    append vbs "tmpwidth = $width * PageWidth / CustomPageWidth\n"
    append vbs "tmpheight = $height * PageHeight / CustomPageHeight\n"
    if {[CheckExist $fname]} {
	append vbs "\n"
	append vbs "\n"
	# add file to copy list and get the new name
	set vbsfilename [addtoCopyListReturnVbsname $fname ]
	append vbs "set Shape = $slide.Shapes\n"
	#set shapes [$slide Shapes]
	#set oleShape [$shapes AddOLEObject $left $top $width $height "HVPControl.HVPControl.1"]
	append vbs "set oleShape=Shape.AddOLEObject(tmpleft,tmptop,tmpwidth,tmpheight,,$vbsfilename,msoFalse,msoTrue)\n"
	return oleShape
    }
    return ""
}



proc InsertTable {slide {rows 1} {columns 6} {left 60} {top 75} {width 600} {height 40}} {
    variable vbs
    append vbs "tmpleft = $left * PageWidth / CustomPageWidth\n"
    append vbs "tmptop = $top * PageHeight / CustomPageHeight\n"
    append vbs "tmpwidth = $width * PageWidth / CustomPageWidth\n"
    append vbs "tmpheight = $height * PageHeight / CustomPageHeight\n"
    #append vbs "Set Shape = $slide.Shapes\n"
    append vbs "set tableShape = slide.Shapes.AddTable($rows,$columns,tmpleft,tmptop,tmpwidth,tmpheight)\n"
    append vbs "set table = tableShape.Table\n"
    append vbs "tableStyle = table.ApplyStyle(\"{5940675A-B579-460E-94D1-54222C63F5DA}\",true)\n"
    # append vbs "set table = Shape.AddTable($rows,$columns,$left,$top,$width,$height)\n"
    # set table [$shapes AddTable $rows $columns $left $top $width $height]
    return table
}

# returns the cellhandle
#
#  change: 04/18/2006 1:36
#  tabel cell is correged now!
#
proc GetCell {tableshape irow icolumn} {
    variable vbs
    set cellname "${tableshape}_cell_${irow}_${icolumn}"
    append vbs "Set $cellname = $tableshape.Cell($irow,$icolumn)\n"
    return $cellname
}
proc MergeTable {table args} {
    variable vbs;
    foreach item $args {
	foreach {start_cell end_cell} $item {
	    set s [eval GetCell $table $start_cell];
	    set e [eval GetCell $table $end_cell];
	    append vbs "${e}.Merge ${s}\n"
	}
    }
}
proc MergeCell {targetcell cell} {
    variable vbs
    append vbs "${targetcell}.Merge $cell\n"
}

proc InsertTextInCell {cell text textsize {font "Arial&ËÎÌו"} {bold 0} {alignment 1} {horizontalp 1} {verticalp 3} } {
    variable vbs
    append vbs "set tashape = $cell.Shape\n"
    append vbs "set tframe = tashape.TextFrame\n"
    # set vertical position to middle (3) ( bottom (4); top (1) )
    append vbs "tframe.VerticalAnchor = $verticalp\n"
    # set horizontal position to center (2) ( none (1) )
    append vbs "tframe.HorizontalAnchor = $horizontalp\n"
    append vbs "set trange = tframe.TextRange\n"
    append vbs "trange.Text = \"$text\"\n"
    # set alignment (left (1) center (2) right (3) distribute (5) see PpParagraphAlignment)
    append vbs "trange.ParagraphFormat.Alignment = $alignment\n"
    # set textsize
    append vbs "trange.Font.Size = $textsize\n"
    # set bold ( false (0) true (-1) see MsoTriState)
    append vbs "trange.Font.Bold = $bold\n"
    set font_list [split $font &]
    set font [lindex $font_list 0]
    append vbs "trange.Font.Nameascii = \"$font\"\n"
    set font [lindex $font_list 1]
    append vbs "trange.Font.NameFarEast = \"$font\"\n"
    
}

proc SetTableColumnWidth {tableshape {columnId 1} {width 100}} {
    variable vbs
    append vbs "tmpwidth = $width * PageWidth / CustomPageWidth\n"
    append vbs "${tableshape}.Columns.Item(${columnId}).Width = tmpwidth\n"
}

# procedure to insert legend which look like the one in HyperView
proc InsertLegend2 {slide colorList valueList left top width height font} {

    variable vbs
    # get the shape handle
    #append vbs "set shapes = $slide.Shapes\n"
    append vbs "set tableShape = $slide.Shapes.AddTable([llength $valueList],2,$left,$top,$width,$height)\n"
    append vbs "set table_legend = tableShape.Table\n"
    # first delete all borders and set a small font
    for {set i 1} { $i <= [llength $valueList] } {incr i} {
	append vbs "set cell = table_legend.Cell($i,1)\n"
	# delete all borders from that cell
	append vbs "set borders = cell.Borders\n"
	# there are 6 borders on every cell (see PpBorderType)
	for {set j 1} {$j <= 6} {incr j} {
	    append vbs "set lineStyle = borders.Item($j)\n"
	    append vbs "lineStyle.Visible = FALSE \n"
	}
	append vbs "set cell = table_legend.Cell($i,2)\n"
	InsertTextInCell cell [lindex $valueList [expr [llength $valueList]-$i]] $font 0 1 1 3
	# delete all borders from that cell
	append vbs "set borders = cell.Borders\n"
	# there are 6 borders on every cell (see PpBorderType)
	for {set j 1} {$j <= 6} {incr j} {
	    append vbs "set lineStyle = borders.Item($j)\n"
	    append vbs "lineStyle.Visible = FALSE \n"
	}
    }
    # end delete borders

    # now spliting the rows in the first column
    # starting at row <startrow> and stoping at <endrow>
    set valueLength [llength $valueList]
    set startrow 1
    set endrow [expr $startrow + [llength $valueList]]
    for {set i 0} {$i <= [expr $endrow - $startrow - 1]} {incr i} {
	append vbs "set cell = table_legend.Cell([expr $startrow + 2*$i],1)\n"
	append vbs "cell.Split 2, 1 \n"
	#delete lower border
	append vbs "set borders = cell.Borders\n"
	append vbs "set lineStyle = borders.Item(3) \n"
	append vbs "lineStyle.Visible = FALSE \n"

	append vbs "set cell2 = table_legend.Cell([expr $startrow + 2*$i + 1],1)\n"
	#delete upper border
	append vbs "set borders = cell2.Borders\n"
	append vbs " set lineStyle = borders.Item(1)\n"
	append vbs "lineStyle.Visible = TRUE \n"
    }
    # end spliting the rows


    append vbs "set cellStart = table_legend.Cell(1,1)\n"
    InsertTextInCell cellStart " " $font 0 1 1 3
    append vbs "set cellEnd = table_legend.Cell([expr 2*[llength $valueList]],1)\n"
    InsertTextInCell cellEnd " " $font 0 1 1 3

    # now insert the colors and the text
    for {set i 0} { $i < [llength $colorList]} { incr i } {
	#set the color
	set rgbcolor [lindex $colorList [expr [llength $colorList]-1-$i]]
	#set wincolor [list [expr [lindex $rgbcolor 2]] [expr [lindex $rgbcolor 1]] [expr [lindex $rgbcolor 0]]]
	# first cell
	append vbs "set cell = table_legend.Cell([expr $startrow + 2*$i + 1],1)\n"
	append vbs "set cellShape = cell.Shape\n"
	# set font size
	InsertTextInCell cell " " $font 0 1 1 3
	# set color
	append vbs "set fillFormat = cellShape.Fill\n"
	append vbs "fillFormat.Solid\n"
	append vbs "set foreColor = fillFormat.ForeColor\n"
	append vbs "foreColor.RGB = RGB([lindex $rgbcolor 0],[lindex $rgbcolor 1],[lindex $rgbcolor 2])\n"

	# second shell
	append vbs "set cell = table_legend.Cell([expr $startrow + 2*$i + 2],1)\n"
	append vbs "set cellShape = cell.Shape\n"
	# set font size
	InsertTextInCell cell " " $font 0 1 1 3
	# color
	append vbs "set fillFormat = cellShape.Fill\n"
	append vbs "fillFormat.Solid\n"
	append vbs "set foreColor = fillFormat.ForeColor\n"
	append vbs "foreColor.RGB = RGB([lindex $rgbcolor 0],[lindex $rgbcolor 1],[lindex $rgbcolor 2])\n"

    }
    # end spliting and setting the colors

    return $vbs

}
proc setColourPPT { cell rgbcolor } {

    variable vbs
    append vbs "set cellShape = $cell.Shape\n"
    append vbs "set fillFormat = cellShape.Fill\n"
    append vbs "fillFormat.Solid\n"
    append vbs "set foreColor = fillFormat.ForeColor\n"
    append vbs "foreColor.RGB = RGB([lindex $rgbcolor 0],[lindex $rgbcolor 1],[lindex $rgbcolor 2])\n"

    # end of proc setColour
}





proc CheckExist {fname} {
    if {[file exists $fname]} {
        return 1
    } else {
        return 0
    }
}

################################################
# Procedure: GroupShapes
# Author: ebeling
# Date: 25.07.2008
# Description:
#
# Parameters:
# shapeList
# Variables:
#
# Returns:
#
################################################
proc GroupShapes {slide shapeList } {

    variable vbs
    #    append vbs "${slide}.Application.ActiveWindow.Selection.Unselect\n"
    set txt "Array("
    foreach shape $shapeList {
        append txt "\"$shape\", "
    }
    set txt [string range $txt 0 end-2]
    append txt ")"
    append vbs "${slide}.Shapes.Range($txt).Group\n"
    #    append vbs "${slide}.Application.ActiveWindow.Selection.ShapeRange.Group.Select\n"

    return 1
    # end proc GroupShapes ####################################
}

proc RemoveAllShapes {slide} {
    variable vbs
    
    #append vbs "${slide}.Shapes.Range(Array(1, 2)).Delete \n"
    
}


proc InsertH3DInSlideHW10 { slide fname {left 100} {top 100} {width 600} {height 400} } {
    variable vbs
    # create unique variable id, 
    # this variable can be used durring the complete export
    # for setting also other things
    # This procedure is also used for the H3D file support in HyperWorks 10.0
    set id [GetUniqueId]
    set varName "object${id}"
    append vbs "tmpleft = $left * PageWidth / CustomPageWidth\n"
    append vbs "tmptop = $top * PageHeight / CustomPageHeight\n"
    append vbs "tmpwidth = $width * PageWidth / CustomPageWidth\n"
    append vbs "tmpheight = $height * PageHeight / CustomPageHeight\n"
    set vbsfilename [addtoCopyListReturnVbsname $fname ]
    append vbs "Set shapes = $slide.Shapes\n"
    append vbs "Set $varName = shapes.AddOLEObject(tmpleft,tmptop,tmpwidth,tmpheight,\"\",$vbsfilename,0,\"\",0,\"\",0)\n"
    # append vbs "Set object = shapes.AddOLEObject Left:=tmpleft, Top:=tmptop, FileName:=$vbsfilename, Link:=msoFalse\n"
    # append vbs "object.Width = tmpwidth\n"
    # set the mouse click action
    append vbs "${varName}.ActionSettings.Item(1).Action = 11\n"
    append vbs "${varName}.ActionSettings.Item(1).AnimateAction = 0\n"
    # set the mouse over action
    append vbs "${varName}.ActionSettings.Item(2).Action = 0\n"
    append vbs "${varName}.ActionSettings.Item(2).AnimateAction = 0\n"
    return $varName

}
