################################################
# Procedure: getPositionOfWindow
# Author: ebeling
# Date: 23.07.2008
# Description:
# calculates the resolution of the window based on the desired
# page res and the selected layout
# Parameters:
# layout - the HW page layout (as integer)
# window - the requested
# Variables:
# none
# Returns:
# the resolution as list "xPos yPos xRes yRes"
# (xPos,yPos) is the upper left corner of the window
################################################
proc getPositionOfWindow {layout window xPageRes yPageRes} {
    if {![string is double $yPageRes ]} {
        error "The argument yPageRes ($yPageRes) must be double value!"
    }
    if {![string is double $xPageRes ]} {
        error "The argument xPageRes ($xPageRes) must be double value!"
    }

    set posList [getWindowConfig page $layout $window]
    
    set windowPos [getWindowConfig window $layout $window]

    # calc the real values of the relative positions
    set xPosList ""
    foreach relPos [lindex $posList 0] {
        set tmp [expr floor($relPos*$xPageRes)]
        lappend xPosList $tmp
    }
    set yPosList ""
    foreach relPos [lindex $posList 1] {
        set tmp [expr ($relPos*$yPageRes)]
        lappend yPosList $tmp
    }

    foreach {x0 y0 x1 y1} $windowPos break
    set posX0 [lindex $xPosList $x0]
    set posY0 [lindex $yPosList $y0]
    set posX1 [lindex $xPosList $x1]
    set posY1 [lindex $yPosList $y1]
    #    if {$posX0 > 0.1} {
    #        set posX0 [expr $posX0 + 1]
    #    }
    #    if {$posY0 > 0.1} {
    #        set posY0 [expr $posY0 + 1]
    #    }
    #    set posX1 [expr $posX1 - 1]
    #    set posY1 [expr $posY1 - 1]
    
    set xRes [expr $posX1 - $posX0]
    set yRes [expr $posY1 - $posY0]

    return [list $posX0 $posY0 $xRes $yRes]
    # end proc getPositionOfWindow ####################################
}


################################################
# Procedure: getWindowConfig
# Author: ebeling
# Date: 22.07.2008
# Description:
# get page / window configuration of the given layout / window
# Parameters:
# configType - the requested configuration type (page or window)
#              page - return how many windows in x and y direction
#                     can occur
#              window - the relative start point (x,y) and the relative
#                       end point of the window
# layout - the layout where the info is requested
# window - the window which info is requested (only used with configType
# Variables:
# 
# Returns:
#
################################################
proc getWindowConfig {configType layout {window none}} {
    
    set configType [string tolower $configType]

    if {$configType != "page" && $configType != "window"} {
        set msg "The config type $configType is not supported!"
        error "$msg\npossible are: page or window" 
    }
    
    # define the maximum number of windows per direction (per layout)
    set configArray(0) [list 1 1]
    set configArray(1) [list 2 1]
    set configArray(2) [list 1 2]
    set configArray(3) [list 2 2]
    set configArray(4) [list 2 2]
    set configArray(5) [list 2 2]
    set configArray(6) [list 2 2]
    set configArray(7) [list 3 1]
    set configArray(8) [list 1 3]
    set configArray(9) [list 2 2]
    set configArray(10) [list 2 3]
    set configArray(11) [list 3 2]
    set configArray(12) [list 3 3]
    set configArray(13) [list 3 4]
    set configArray(14) [list 4 3]
    set configArray(15) [list 4 4]
    set configArray(16) [list 1 4]
    set configArray(17) [list 2 4]
    set configArray(18) [list 4 1]
    set configArray(19) [list 4 2]
    # define the window range (per window and layout)
    # (layout,window) [list xStart yStart xEnd yEnd]
    # begin is the top left corner
    # layout 0
    set configArray(0,1) [list 0 0 1 1]
    # layout 1
    set configArray(1,1) [list 0 0 1 1]
    set configArray(1,2) [list 1 0 2 1]
    # layout 2
    set configArray(2,1) [list 0 0 1 1]
    set configArray(2,2) [list 0 1 1 2]
    # layout 3
    set configArray(3,1) [list 0 0 1 2]
    set configArray(3,2) [list 1 0 2 1]
    set configArray(3,3) [list 1 1 2 2]
    # layout 4
    set configArray(4,1) [list 0 0 1 1]
    set configArray(4,2) [list 1 0 2 2]
    set configArray(4,3) [list 0 1 1 2]
    # layout 5
    set configArray(5,1) [list 0 0 1 1]
    set configArray(5,2) [list 1 0 2 1]
    set configArray(5,3) [list 0 1 2 2]
    # layout 6
    set configArray(6,1) [list 0 0 2 1]
    set configArray(6,2) [list 0 1 1 2]
    set configArray(6,3) [list 1 1 2 2]
    # layout 7
    set configArray(7,1) [list 0 0 1 1]
    set configArray(7,2) [list 1 0 2 1]
    set configArray(7,3) [list 2 0 3 1]
    # layout 8
    set configArray(8,1) [list 0 0 1 1]
    set configArray(8,2) [list 0 1 1 2]
    set configArray(8,3) [list 0 2 1 3]
    # layout 9
    set configArray(9,1) [list 0 0 1 1]
    set configArray(9,2) [list 1 0 2 1]
    set configArray(9,3) [list 0 1 1 2]
    set configArray(9,4) [list 1 1 2 2]
    # layout 10
    set configArray(10,1) [list 0 0 1 1]
    set configArray(10,2) [list 1 0 2 1]
    set configArray(10,3) [list 0 1 1 2]
    set configArray(10,4) [list 1 1 2 2]
    set configArray(10,5) [list 0 2 1 3]
    set configArray(10,6) [list 1 2 2 3]
    # layout 11
    set configArray(11,1) [list 0 0 1 1]
    set configArray(11,2) [list 1 0 2 1]
    set configArray(11,3) [list 2 0 3 1]
    set configArray(11,4) [list 0 1 1 2]
    set configArray(11,5) [list 1 1 2 2]
    set configArray(11,6) [list 2 1 3 2]
    # layout 12
    set configArray(12,1) [list 0 0 1 1]
    set configArray(12,2) [list 1 0 2 1]
    set configArray(12,3) [list 2 0 3 1]
    set configArray(12,4) [list 0 1 1 2]
    set configArray(12,5) [list 1 1 2 2]
    set configArray(12,6) [list 2 1 3 2]
    set configArray(12,7) [list 0 2 1 3]
    set configArray(12,8) [list 1 2 2 3]
    set configArray(12,9) [list 2 2 3 3]
    # layout 13
    set configArray(13,1) [list 0 0 1 1]
    set configArray(13,2) [list 1 0 2 1]
    set configArray(13,3) [list 2 0 3 1]
    set configArray(13,4) [list 0 1 1 2]
    set configArray(13,5) [list 1 1 2 2]
    set configArray(13,6) [list 2 1 3 2]
    set configArray(13,7) [list 0 2 1 3]
    set configArray(13,8) [list 1 2 2 3]
    set configArray(13,9) [list 2 2 3 3]
    set configArray(13,10) [list 0 3 1 4]
    set configArray(13,11) [list 1 3 2 4]
    set configArray(13,12) [list 2 3 3 4]
    # layout 14
    set configArray(14,1) [list 0 0 1 1]
    set configArray(14,2) [list 1 0 2 1]
    set configArray(14,3) [list 2 0 3 1]
    set configArray(14,4) [list 3 0 4 1]
    set configArray(14,5) [list 0 1 1 2]
    set configArray(14,6) [list 1 1 2 2]
    set configArray(14,7) [list 2 1 3 2]
    set configArray(14,8) [list 3 1 4 2]
    set configArray(14,9) [list 0 2 1 3]
    set configArray(14,10) [list 1 2 2 3]
    set configArray(14,11) [list 2 2 3 3]
    set configArray(14,12) [list 3 2 4 3]
    # layout 15
    set configArray(15,1) [list 0 0 1 1]
    set configArray(15,2) [list 1 0 2 1]
    set configArray(15,3) [list 2 0 3 1]
    set configArray(15,4) [list 3 0 4 1]
    set configArray(15,5) [list 0 1 1 2]
    set configArray(15,6) [list 1 1 2 2]
    set configArray(15,7) [list 2 1 3 2]
    set configArray(15,8) [list 3 1 4 2]
    set configArray(15,9) [list 0 2 1 3]
    set configArray(15,10) [list 1 2 2 3]
    set configArray(15,11) [list 2 2 3 3]
    set configArray(15,12) [list 3 2 4 3]
    set configArray(15,13) [list 0 3 1 4]
    set configArray(15,14) [list 1 3 2 4]
    set configArray(15,15) [list 2 3 3 4]
    set configArray(15,16) [list 3 3 4 4]
    # layout 16
    set configArray(16,1) [list 0 0 1 1]
    set configArray(16,2) [list 0 1 1 2]
    set configArray(16,3) [list 0 2 1 3]
    set configArray(16,4) [list 0 3 1 4]
    # layout 17
    set configArray(17,1) [list 0 0 1 1]
    set configArray(17,2) [list 1 0 2 1]
    set configArray(17,3) [list 0 1 1 2]
    set configArray(17,4) [list 1 1 2 2]
    set configArray(17,5) [list 0 2 1 3]
    set configArray(17,6) [list 1 2 2 3]
    set configArray(17,7) [list 0 3 1 4]
    set configArray(17,8) [list 1 3 2 4]
    # layout 18
    set configArray(18,1) [list 0 0 1 1]
    set configArray(18,2) [list 1 0 2 1]
    set configArray(18,3) [list 2 0 3 1]
    set configArray(18,4) [list 3 0 4 1]
    # layout 19
    set configArray(19,1) [list 0 0 1 1]
    set configArray(19,2) [list 1 0 2 1]
    set configArray(19,3) [list 2 0 3 1]
    set configArray(19,4) [list 3 0 4 1]
    set configArray(19,5) [list 0 1 1 2]
    set configArray(19,6) [list 1 1 2 2]
    set configArray(19,7) [list 2 1 3 2]
    set configArray(19,8) [list 3 1 4 2]

    set returnList ""
    if {$configType == "page"} {
        if {![info exists configArray($layout)]} {
            set msg "Unknown layout $layout!\n"
            append msg "Possible are: 0...19"
            error $msg
        }
        # create a list containing the relative positions
        foreach val $configArray($layout) {
            set tmpList ""
            for {set i 0} {$i <= $val} {incr i} {
                lappend tmpList [expr (1.0*$i)/(1.0*$val)]
            }
            lappend returnList $tmpList
        }
    } elseif {$configType == "window"} {
        if {![info exists configArray($layout,$window)]} {
            error "The combination of (layout,window) ($layout,$window) is unknown!"
        }
        set returnList $configArray($layout,$window)
    }

    return $returnList
    # end proc getWindowConfig ####################################
}
