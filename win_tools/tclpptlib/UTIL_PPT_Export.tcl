################################################
# Procedure: createPPT
# Author: ebeling
# Date: 23.07.2008
# Description:
#
# Parameters:
# pptFile - the ppt file to be created
# startPPT - should Powerpoint be started automatically (only on Windows)
# configArray - the name of the configuration array
# Variables:
# pptExportConfig
# Returns:
# none
################################################

################################################
# Procedure: AddHWPageImage 0
# Author: ebeling
# Date: 23.07.2008
# Description:
# inserts the complete page on the given ppt slide
# Parameters:
# slide - the slide object handle of Powerpoint
# pageId - the id of the page to be captures
# Variables:
# none
# Returns:
# none
################################################
package require hwt;


proc AddHWPageImage { slide pageId configVar tmpDir} {
    variable deleteList
    variable list_rezVals

    set resX [getConfigValue $configVar pictureResX]
    set resY [getConfigValue $configVar pictureResY]
    [GetProject] SetActivePage $pageId
    set page [GetPage -page $pageId]
    set numberOfWindows [$page GetNumberOfWindows]
    set layout [$page GetLayout]
    set pos [getConfigValue $configVar picturePos]
    foreach {xPos yPos width height} $pos break
    #drawani
    set session [GetSession]
    set shapeList ""
    for {set winId 1} {$winId <= $numberOfWindows} {incr winId} {
        $page SetActiveWindow $winId
        
        set picName [file join $tmpDir pic_${pageId}_${winId}.png]
        # get the resolution of the window
        set posList [getPositionOfWindow $layout $winId $resX $resY]
        set winResX [lindex $posList 2]
        set winResY [lindex $posList 3]
        # capture the window
        set imageType [getConfigValue $configVar imageType]
        $session CaptureActiveWindow $imageType $picName pixels $winResX $winResY

        lappend deleteList $picName
        # insert the picture in Powerpoint
        set picPos [getPositionOfWindow $layout $winId $width $height]
        foreach {xRel yRel widthRel heightRel} $picPos break
        set x [expr $xPos + $xRel]
        set y [expr $yPos + $yRel-20]
        set widthRel [expr $widthRel*1.0]
        set heightRel [expr $heightRel*1.0]
        lappend shapeList [InsertPicture $slide $picName $x $y $widthRel $heightRel 0]
        
    }
    if {[llength $shapeList]>1} {
        GroupShapes $slide $shapeList
    }
    return 0
    # end proc AddHWPageImage 0 ####################################
}

# # list_rezVals { window1 contour value; window2 contour value; ... }
# # according to node id input, list the return values




################################################
# Procedure: HWGetValue
# Author: Source
# Date: 2nd, Sept., 2011
# Description: 
# Get the Value in the Model
# Parameters:
# 
# Variables:
# none
# Returns:
# 
################################################

proc HWGetContourValue {isovalue args} {

    hwi OpenStack;
    set return_list "";
    hwi ReleaseAllHandles;
    set session [::CSPF::FEUtitlty::mvh::GetSession];
    set page_window_list "";
    $session GetProjectHandle pro;

    # pro SetMeasureNumericFormat "scientific";
    # pro SetMeasureNumericPrecision 8;
    # $session SetMeasureAngleFormat $angleFormat;
    
    ########################################
    # Generate a list {{pageID windowID} {pageID windowID} ...}
    ########################################
    
    for {set x 1} {$x <= [pro GetNumberOfPages]} {incr x} {
	pro GetPageHandle page $x
	for {set y 1} {$y <= [page GetNumberOfWindows]} {incr y} {
	    page GetWindowHandle win $y
	    if {[win GetClientType] == "Animation"} {
		lappend page_window_list [list $x $y]
	    }
	    win ReleaseHandle
	}
	page ReleaseHandle
    }    

    
    hwi OpenStack;
    foreach tmp_page ${page_window_list} {
	foreach {cur_page cur_window} $tmp_page {
	    if { $cur_window == 1 } {
		set page_handle "page_$cur_page";
		set win_handle "window_${cur_page}_${cur_window}";
		pro GetPageHandle ${page_handle} $cur_page;
		pro SetActivePage ${cur_page};
		
		
		${page_handle} GetWindowHandle ${win_handle} 1;
		${page_handle} SetActiveWindow ${cur_window};


		
		${win_handle} GetClientHandle client_${cur_page}_${cur_window};
		${win_handle} GetClientHandle client;
		client_${cur_page}_${cur_window} SetMeasureNumericFormat "Scientific";
		client_${cur_page}_${cur_window} SetMeasureNumericPrecision 3;
		client_${cur_page}_${cur_window} GetMeasureHandle measure_${cur_page}_${cur_window} 1;
		
		client GetModelHandle modelhandle [client GetActiveModel];

		modelhandle GetResultCtrlHandle result
		result GetIsoValueCtrlHandle iso;
		iso SetIsoValue $isovalue;
		
		modelhandle ReleaseHandle;
		iso ReleaseHandle;
		client ReleaseHandle;
		result ReleaseHandle;
		
		set temp_list [measure_${cur_page}_${cur_window} GetEntityList];
		set temp_indicator [measure_${cur_page}_${cur_window} GetItemList];
		set temp_var [measure_${cur_page}_${cur_window} GetValueList];
		


		
		
		
		if {[lindex ${temp_indicator} 0]=="Max"} {
		    lappend return_list  [list $temp_list $temp_var];
		} else {
		    lappend return_list [list [list [lindex ${temp_list} 1] [lindex ${temp_list} 0]] [list [lindex ${temp_var} 1] [lindex ${temp_var} 0]]];
		}
		
		

		# set model_handle [::CSPF::FEUtitlty::mvh::GetModel];
		# ${model_handle} GetResultCtrlHandle result_model;
		# result_model GetContourCtrlHandle contour_model;
		# contour_model GetLegendHandle legend_ctrl;
		
		# contour_model SetAverageMode simple;
		# legend_ctrl SetMinMaxVisibility True min;
		# legend_ctrl SetMinMaxVisibility True max;

		# set max [legend_ctrl GetMax]
		# set min [legend_ctrl GetMin]

		
		

		# lappend return_list [list $max $min];
		

		# result_model ReleaseHandle
		# contour_model ReleaseHandle
		# legend_ctrl ReleaseHandle
		

	    }
	}
    } 


    
    # for {set x 1} {$x <= [pro GetNumberOfPages]} {incr x} {
    # 	hwi OpenStack;
    # 	pro GetPageHandle page $x
    # 	for {set y 1} {$y <= [page GetNumberOfWindows]} {incr y} {
    # 	    hwi OpenStack;
    # 	    page GetWindowHandle win $y
    # 	    win GetViewControlHandle view;
    # 	    win GetClientHandle client;
    # 	    view Fit;
    # 	    client Draw;
    # 	    hwi CloseStack;
    # 	}
    # 	hwi CloseStack;
    # }
    HVResultFitAll;    

    
    hwi CloseStack;
    hwi CloseStack;
    return $return_list;
}

proc HWGetContourshape {args} {

    hwi OpenStack;
    set return_list "";
    hwi ReleaseAllHandles;
    set session [::CSPF::FEUtitlty::mvh::GetSession];
    set page_window_list "";
    $session GetProjectHandle pro;

    # pro SetMeasureNumericFormat "scientific";
    # pro SetMeasureNumericPrecision 8;
    # $session SetMeasureAngleFormat $angleFormat;
    
    ########################################
    # Generate a list {{pageID windowID} {pageID windowID} ...}
    ########################################
    
    for {set x 1} {$x <= [pro GetNumberOfPages]} {incr x} {
	pro GetPageHandle page $x
	for {set y 1} {$y <= [page GetNumberOfWindows]} {incr y} {
	    page GetWindowHandle win $y
	    if {[win GetClientType] == "Animation"} {
		lappend page_window_list [list $x $y]
	    }
	    win ReleaseHandle
	}
	page ReleaseHandle
    }    

    hwi OpenStack;

    HVResultFitAll;    


    hwi CloseStack;
    hwi CloseStack;

    return $return_list;
}

proc HWGetContourdisp {nodelist args} {

    hwi OpenStack;
    set return_list "";
    hwi ReleaseAllHandles;
    set session [::CSPF::FEUtitlty::mvh::GetSession];
    set page_window_list "";
    $session GetProjectHandle pro;

    # pro SetMeasureNumericFormat "scientific";
    # pro SetMeasureNumericPrecision 8;
    # $session SetMeasureAngleFormat $angleFormat;
    
    ########################################
    # Generate a list {{pageID windowID} {pageID windowID} ...}
    ########################################
    
    for {set x 1} {$x <= [pro GetNumberOfPages]} {incr x} {
	pro GetPageHandle page $x
	for {set y 1} {$y <= [page GetNumberOfWindows]} {incr y} {
	    page GetWindowHandle win $y
	    if {[win GetClientType] == "Animation"} {
		lappend page_window_list [list $x $y]
	    }
	    win ReleaseHandle
	}
	page ReleaseHandle
    }    
    

    hwi OpenStack;
    set vnode 0;
    foreach tmp_page ${page_window_list} {
	foreach {cur_page cur_window} $tmp_page {
	    set page_handle "page_$cur_page";
	    set win_handle "window_${cur_page}_${cur_window}";
	    pro GetPageHandle ${page_handle} $cur_page;
	    pro SetActivePage ${cur_page};
	    
	    
	    ${page_handle} GetWindowHandle ${win_handle} 1;
	    ${page_handle} SetActiveWindow ${cur_window};


	    
	    ${win_handle} GetClientHandle client_${cur_page}_${cur_window};
	    client_${cur_page}_${cur_window} SetMeasureNumericFormat "Scientific";
	    client_${cur_page}_${cur_window} SetMeasureNumericPrecision 3;
	    client_${cur_page}_${cur_window} AddMeasure;
	    client_${cur_page}_${cur_window} GetMeasureHandle measure_node_${cur_page} 3;
	    


	    measure_node_${cur_page} SetType "Relative Displacement";
	    measure_node_${cur_page} AddNode [lindex [lindex $nodelist $vnode] 0];
	    measure_node_${cur_page} SetResultSystem [lindex [lindex $nodelist $vnode] 1];
	    
	    client_${cur_page}_${cur_window} Draw;	    




	    # if {[lindex ${temp_indicator} 0]=="Max"} {
	    # 	lappend return_list  [list $temp_list $temp_var];
	    # } else {
	    # 	lappend return_list [list [list [lindex ${temp_list} 1] [lindex ${temp_list} 0]] [list [lindex ${temp_var} 1] [lindex ${temp_var} 0]]];
	    # }

	    lappend return_list [list [measure_node_${cur_page} GetValueList] [lindex [lindex $nodelist $vnode] 1]];
	    

	    # measure_node ReleaseHandle;

	    # set model_handle [::CSPF::FEUtitlty::mvh::GetModel];
	    # ${model_handle} GetResultCtrlHandle result_model;
	    # result_model GetContourCtrlHandle contour_model;
	    # contour_model GetLegendHandle legend_ctrl;
	    
	    # contour_model SetAverageMode simple;
	    # legend_ctrl SetMinMaxVisibility True min;
	    # legend_ctrl SetMinMaxVisibility True max;

	    # set max [legend_ctrl GetMax]
	    # set min [legend_ctrl GetMin]

	    
	    

	    # lappend return_list [list $max $min];
	    

	    # result_model ReleaseHandle
	    # contour_model ReleaseHandle
	    # legend_ctrl ReleaseHandle
	    

	}
    } 

    
    HVResultFitAll;

    hwi CloseStack;
    hwi CloseStack;

    return $return_list;
}

proc HWGetContourNVH {args} {
   
    set return_list "";


    hwi ReleaseAllHandles;
    hwi OpenStack;
    hwi GetSessionHandle sess;
    sess GetProjectHandle pro;
    pro GetPageHandle page 1;
    page GetWindowHandle win 1;
    win GetClientHandle client;
    
    client GetModelHandle model [client GetActiveModel]
    
    model GetResultCtrlHandle result;
    
    set listid [result GetSubcaseList];
    
    foreach temp_id $listid {
	lappend return_list [result GetSimulationList $temp_id];
    }
    
    
    hwi CloseStack;
    HVResultFitAll;
    return $return_list;
}


proc HVResultFitAll { args  } {
    hwi OpenStack
    hwi GetSessionHandle sess
    
    sess GetProjectHandle proj
    set page_count [proj GetNumberOfPages ]
    for { set i 1 } { $i<=$page_count } {incr i} {
        proj SetActivePage $i
        proj GetPageHandle page [proj GetActivePage]
        set numberOfWindows [page GetNumberOfWindows]
        for {set winId 1} {$winId <= $numberOfWindows} {incr winId} {
            page SetActiveWindow $winId
            
            page GetWindowHandle win_hdl $winId
            set client_type [win_hdl GetClientType]
            if { $client_type!="Animation" } { 
                win_hdl ReleaseHandle
                continue }
            # fit window
            win_hdl GetViewControlHandle viewctrl
            viewctrl FitAllFrames
            win_hdl Draw
            viewctrl ReleaseHandle
            
            win_hdl ReleaseHandle
        }
        page ReleaseHandle
    }
    
    hwi ReleaseAllHandles
    hwi CloseStack;
    
}





proc ExportH3D {str_saveDir PageList argv} {
    # User options
    # ------------

    # Page / Window list of the animation clients from which h3d files will be created. Add a new line "{1 2} \"  for each page / window pair.
    # set pageWindowList [list    \
    # 			    { 1 1 } \
    #         	 	   ]

    set pageWindowList $PageList;

    # Export all active Modells in the session if set to 1. The pageWindowList will be ignored.
    set exportAllActiveModelsInSession 0

    # Save directory (e.g. [pwd],"D:/home/user", ...) Will not be used when a destination directory will be given as argument in the command line
    set saveDir $str_saveDir

    # File which will be deleted after all h3d are exported
    set fileVar  "run.txt"

    # Overwrite existing H3D files (1) or create new file (0) with name_2.h3d, name_3.h3d , ......
    set overWrite 1

    # Long file names (1) or only Page_1_Window_1 (0)
    set longFileNames 0

    # H3D Export Options
    # ------------------

    # Displayed Components (Default true)
    set writeDisplayedComponents "true"

    # Preview Image (Default true)
    set previewImage "false"

    # HTML (Default true)
    set html "false"

    # Attributes (Default true)
    set attributes "false"

    # Entity IDs (Default true)
    set entityIDs "false"

    # Solids As Faces (Default false)
    set solidAsFaces "false"

    # Write Animation (Default true)
    set writeAnimation "true"

    # Write Results (Default true)
    set writeResults "true"

    # Compress Output (Default false)
    set compressOutput "true"

    # Compression Level (Default 1 = low compression, 6 =  highest compression)
    set compressionLevel 1

    # Max Compression Error (Default 0.001)
    set maxCompressionError 0.001

    # Don't edit below this line
    # ---------------------------


    set tmpDir [lindex $argv end]
    if {[file exists $tmpDir] && [file isdirectory $tmpDir]} {
	set saveDir $tmpDir
    }

    if {$exportAllActiveModelsInSession} {
	set pageWindowList {}
	hwi ReleaseAllHandles
	hwi GetSessionHandle ses
	ses GetProjectHandle pro
	for {set x 1} {$x <= [pro GetNumberOfPages]} {incr x} {
	    pro GetPageHandle page $x
	    for {set y 1} {$y <= [page GetNumberOfWindows]} {incr y} {
		page GetWindowHandle win $y
		if {[win GetClientType] == "Animation"} {
		    lappend pageWindowList [list $x $y]
		}
		win ReleaseHandle
	    }
	    page ReleaseHandle
	}
    }

    if {$saveDir != ""} {
	if {[file exists $saveDir] == 0} {
	    file mkdir $saveDir
	}

	if {[file exists $saveDir] == 0} {
	    # tk_messageBox -title "Error Message" -message "Directory $saveDir doesn't exist"
	} else {
	    hwi ReleaseAllHandles
	    hwi GetSessionHandle ses
	    ses GetProjectHandle pro
	    set currentPage [pro GetActivePage]
	    pro GetPageHandle page [pro GetActivePage]
	    set currentWindow [page GetActiveWindow]
	    page ReleaseHandle
	    

	    foreach pageWindowVar $pageWindowList {
		set j 1
		set activePage   [lindex $pageWindowVar 0]
		set activeWindow [lindex $pageWindowVar 1]
		pro GetPageHandle page $activePage
		page SetActiveWindow $activeWindow
		page GetWindowHandle win $activeWindow
		


		page Draw
		
		if {[win GetClientType] == "Animation"} {
		    win GetClientHandle client
		    if {[client GetModelList] != ""} {
			client GetModelHandle model [client GetActiveModel]
			set modelName [file tail [file root [model GetFileName]]]
			if {$longFileNames == 1} {
			    set totalName "Page_${activePage}_[convertToFileName [page GetTitle]]_Window_${activeWindow}_[convertToFileName $modelName]"
			} else {
			    # set totalName "Page_${activePage}_Window_${activeWindow}"
			    set totalName "Animate_${activePage}";
			}
		    } else {
			set pageTitle [page GetTitle]
			if {[file exists $pageTitle]} {
			    set modelName [file tail [file root $pageTitle]]
			    set totalName "Page_${activePage}_Window_${activeWindow}_[convertToFileName $modelName]"
			} else {
			    set totalName "Page_${activePage}_Window_${activeWindow}"
			}
		    }
		    set h3dFile [file join $saveDir [set totalName].h3d]
		    if { $overWrite == 0 } {
			while { [file exists $h3dFile] == 1 } {
			    incr j
			    set h3dFile [file join $saveDir [set totalName]_${j}.h3d]
			}
		    }
		    page Draw
		    pro SetActivePage $activePage
		    ses GetH3DExportOptionsHandle h3d
		    h3d SetWriteDisplayedComponents 	$writeDisplayedComponents
		    h3d SetWritePreviewImage 			$previewImage
		    h3d SetWriteHTML					$html
		    h3d SetWriteAttributes				$attributes
		    h3d SetWriteEntityIDs				$entityIDs
		    h3d SetWriteSolidsAsFaces			$solidAsFaces
		    h3d SetWriteAnimation				$writeAnimation
		    h3d SetWriteResults					$writeResults
		    h3d SetCompressOutput				$compressOutput
		    h3d SetCompressionLevel				$compressionLevel
		    h3d SetMaxCompressionError 			$maxCompressionError
		    client ExportH3D $h3dFile
		}
		h3d		ReleaseHandle
		if {[client GetModelList] != ""} {
		    model 	ReleaseHandle
		}
		client	ReleaseHandle
		win 	ReleaseHandle
		page 	ReleaseHandle
	    }
	}
	pro GetNumberOfPages
	pro SetActivePage $currentPage
	pro GetPageHandle page [pro GetActivePage]
	page Draw
	page SetActiveWindow $currentWindow
	page ReleaseHandle
    }

    # Wait for 1000 m lliseconds
    after 100

    # Delete file  $fileVar in save directory if exists

    set fileVarPath [file join $saveDir $fileVar]
    if { [file exists $fileVarPath] == 1 } {
	file delete $fileVarPath
    }
    # 	ses Close
}

# proc AddHWPageTable { slide pageId node_id obj_list } {
#     set list_rezVals ""
#     set list_notes ""

#     [GetProject] SetActivePage $pageId
#     set page [GetPage -page $pageId]
#     set numberOfWindows [$page GetNumberOfWindows]
#     set session [GetSession]

#     for {set winId 1} {$winId <= $numberOfWindows} {incr winId} {
#         $page SetActiveWindow $winId
#         set model_handle [GetModel]

#         # get max min value
#         if { $node_id==0 } {
#             $model_handle GetResultCtrlHandle result_model
#             result_model GetContourCtrlHandle contour_model
#             contour_model GetLegendHandle legend_ctrl
#             contour_model SetAverageMode simple
#             set max [legend_ctrl GetMax]
#             set min [legend_ctrl GetMin]

#             if { [expr abs($max)]>[expr abs($min)] } {
#                 lappend list_rezVals $max
#             } else {
#                 lappend list_rezVals $min
#             }

# result_model ReleaseHandle
# contour_model ReleaseHandle
# legend_ctrl ReleaseHandle
#         } else {
#             set selection_set_id [$model_handle AddSelectionSet node]
#             $model_handle GetSelectionSetHandle selection_set_handle $selection_set_id
#             selection_set_handle SetLabel "NodeSelectionSet"
#             selection_set_handle SetSelectMode "all"
#             selection_set_handle Add "id == $node_id";

#             $model_handle GetQueryCtrlHandle query_handle
#             query_handle SetDataSourceProperty result datatype Stress
#             query_handle SetQuery "node.coords contour.value"
#             query_handle SetSelectionSet [selection_set_handle GetID]
#             query_handle GetIteratorHandle iter

#             for {iter First} { [iter Valid] } {iter Next} {
#                 set result [iter GetDataList]
#                 #tk_messageBox -message $result
#                 lappend list_rezVals [lindex $result 1]
#                 break
#             }
#             iter ReleaseHandle
#             query_handle ReleaseHandle

#             $model_handle RemoveSelectionSet $selection_set_id
#             selection_set_handle ReleaseHandle
#         }

#         set note_text ""
#         set t [::post::GetT];
#         set err [::post::GetPostHandle p$t];
#         if { $err != "success" } { 
#             set note_text "failed"
#         }
#         p$t GetNoteHandle n$t 1
#         set note_text [n$t GetText]

#         lappend list_notes $note_text
#     }
# # tk_messageBox -message "$list_notes "
# # tk_messageBox -message " $list_rezVals "
# # tk_messageBox -message "  $obj_list"
#     # insert ppt table control
#     set row_count [expr [llength $obj_list]+1]
#     set table_shape [InsertTable $slide $row_count 3 60 420 660 40]
#     SetTableColumnWidth $table_shape 1 260
#     SetTableColumnWidth $table_shape 2 200
#     SetTableColumnWidth $table_shape 3 200

#     set table_cell [GetCell $table_shape 1 1]
#     InsertTextInCell $table_cell "工况载荷(N)" 16
#     set table_cell [GetCell $table_shape 1 2]
#     InsertTextInCell $table_cell "加载点变形量(mm)" 16
#     set table_cell [GetCell $table_shape 1 3]
#     InsertTextInCell $table_cell "目标参考值(mm)" 16

#     set i 2
#     foreach note $list_notes val $list_rezVals obj $obj_list {
#         set table_cell [GetCell $table_shape $i 1]
#         InsertTextInCell $table_cell $note 16
#         set table_cell [GetCell $table_shape $i 2]
#         InsertTextInCell $table_cell $val 16
#         set table_cell [GetCell $table_shape $i 3]
#         InsertTextInCell $table_cell $obj 16

#         incr i
#     }

#     set ret_list [list $list_notes $list_rezVals $obj_list]
#     return $ret_list
# }

proc AddBigTable { slide list_notes list_rezVals obj_list} {
    
    # set row_count [expr [llength $obj_list]+1]
    # set table_shape [InsertTable $slide $row_count 3 60 80 660 40]
    # SetTableColumnWidth $table_shape 1 260
    # SetTableColumnWidth $table_shape 2 200
    # SetTableColumnWidth $table_shape 3 200
    
    # set table_cell [GetCell $table_shape 1 1]
    # InsertTextInCell $table_cell "工况载荷(N)" 16
    # set table_cell [GetCell $table_shape 1 2]
    # InsertTextInCell $table_cell "加载点变形量(mm)" 16
    # set table_cell [GetCell $table_shape 1 3]
    # InsertTextInCell $table_cell "目标参考值(mm)" 16
    
    # set i 2
    # foreach note $list_notes val $list_rezVals obj $obj_list {
    #     set table_cell [GetCell $table_shape $i 1]
    #     InsertTextInCell $table_cell $note 16
    #     set table_cell [GetCell $table_shape $i 2]
    #     InsertTextInCell $table_cell $val 16
    #     set table_cell [GetCell $table_shape $i 3]
    #     InsertTextInCell $table_cell $obj 16
    
    #     incr i
    # }    
}

proc AddMultiTable { slide title tby list_rezVals obj_list} {
    
    # set row_count [expr [llength $obj_list]+1]
    # set table_shape [InsertTable $slide $row_count 3 60 $tby 660 40]
    # SetTableColumnWidth $table_shape 1 260
    # SetTableColumnWidth $table_shape 2 200
    # SetTableColumnWidth $table_shape 3 200
    
    # set table_cell [GetCell $table_shape 1 1]
    # InsertTextInCell $table_cell $title 16
    # set table_cell [GetCell $table_shape 1 2]
    # InsertTextInCell $table_cell "实际值" 16
    # set table_cell [GetCell $table_shape 1 3]
    # InsertTextInCell $table_cell "目标参考值" 16
    
    # set list_notes [list "最大变形量(mm)" "最大应力(GPa)"]
    # set i 2
    # foreach note $list_notes val $list_rezVals obj $obj_list {
    #     set table_cell [GetCell $table_shape $i 1]
    #     InsertTextInCell $table_cell $note 16
    #     set table_cell [GetCell $table_shape $i 2]
    #     InsertTextInCell $table_cell $val 16
    #     set table_cell [GetCell $table_shape $i 3]
    #     InsertTextInCell $table_cell $obj 16
    
    #     incr i
    # }
}

proc GetCurrentPageExtremeVals { pageId } {
    #     set list_rezVals ""
    #     set list_notes ""

    #     [GetProject] SetActivePage $pageId
    #     set page [GetPage -page $pageId]
    #     set numberOfWindows [$page GetNumberOfWindows]
    #     set session [GetSession]
    
    #     for {set winId 1} {$winId <= $numberOfWindows} {incr winId} {
    #         $page SetActiveWindow $winId
    #         set model_handle [GetModel]
    
    #         # get max min value
    #         $model_handle GetResultCtrlHandle result_model
    #         result_model GetContourCtrlHandle contour_model
    #         contour_model GetLegendHandle legend_ctrl
    #         contour_model SetAverageMode simple
    #         set max [legend_ctrl GetMax]
    #         set min [legend_ctrl GetMin]
    
    #         if { [expr abs($max)]>[expr abs($min)] } {
    #             lappend list_rezVals $max
    #         } else {
    #             lappend list_rezVals $min
    #         }
    
    #         result_model ReleaseHandle
    #         contour_model ReleaseHandle
    #         legend_ctrl ReleaseHandle

    # #         set note_text ""
    # #         set t [::post::GetT];
    # #         set err [::post::GetPostHandle p$t];
    # #         if { $err != "success" } { 
    # #             set note_text "failed"
    # #         }
    # #         p$t GetNoteHandle n$t 1
    # #         set note_text [n$t GetText]
    # #         
    # #         lappend list_notes $note_text
    #     }
    
    #     return $list_rezVals
}

proc AddSlamTable { slide list_rezVals obj_list} {
    # # insert ppt table control
    # set row_count [expr [llength $obj_list]+1]
    # set table_shape [InsertTable $slide $row_count 3 60 420 660 40]
    # SetTableColumnWidth $table_shape 1 260
    # SetTableColumnWidth $table_shape 2 200
    # SetTableColumnWidth $table_shape 3 200
    
    # set table_cell [GetCell $table_shape 1 1]
    # InsertTextInCell $table_cell "" 16
    # set table_cell [GetCell $table_shape 1 2]
    # InsertTextInCell $table_cell "实际值" 16
    # set table_cell [GetCell $table_shape 1 3]
    # InsertTextInCell $table_cell "目标参考值" 16
    
    # set list_notes [list "最大变形量(mm)" "最大应力(GPa)"]
    # set i 2
    # foreach note $list_notes val $list_rezVals obj $obj_list {
    #     set table_cell [GetCell $table_shape $i 1]
    #     InsertTextInCell $table_cell $note 16
    #     set table_cell [GetCell $table_shape $i 2]
    #     InsertTextInCell $table_cell $val 16
    #     set table_cell [GetCell $table_shape $i 3]
    #     InsertTextInCell $table_cell $obj 16
    
    #     incr i
    # }
}


proc AddHWPageTableSlam { slide pageId obj_list } {
    # # get extreme values
    # set list_rezVals [GetCurrentPageExtremeVals $pageId]
    # AddSlamTable $slide $list_rezVals $obj_list
    
    # set ret_list [list $list_rezVals $obj_list]
    # return $ret_list    
}


# proc AddSingeRowTable { slide list_title list_val} {
#     # insert ppt table control
#     set table_shape [InsertTable $slide 2 3 60 420 660 40]
#     SetTableColumnWidth $table_shape 1 260
#     SetTableColumnWidth $table_shape 2 200
#     SetTableColumnWidth $table_shape 3 200

#     set table_cell [GetCell $table_shape 1 1]
#     InsertTextInCell $table_cell [lindex $list_title 0] 16
#     set table_cell [GetCell $table_shape 1 2]
#     InsertTextInCell $table_cell [lindex $list_title 1] 16
#     set table_cell [GetCell $table_shape 1 3]
#     InsertTextInCell $table_cell [lindex $list_title 2] 16

#     set table_cell [GetCell $table_shape 2 1]
#     InsertTextInCell $table_cell [lindex $list_val 0] 16
#     set table_cell [GetCell $table_shape 2 2]
#     InsertTextInCell $table_cell [lindex $list_val 1] 16
#     set table_cell [GetCell $table_shape 2 3]
#     InsertTextInCell $table_cell [lindex $list_val 2] 16

# }

# proc AddHWPageTableSeal { slide pageId list_title list_val } {
#     # get extreme values
#     set list_rezVals [GetCurrentPageExtremeVals $pageId]
#     AddSingeRowTable $slide $list_title $list_val
# }

# proc AddHingeTable { slide title tby note list_vals } {
#     # insert ppt table control
#     set table_shape [InsertTable $slide 2 3 60 $tby 660 40]
#     SetTableColumnWidth $table_shape 1 260
#     SetTableColumnWidth $table_shape 2 200
#     SetTableColumnWidth $table_shape 3 200

#     set table_cell [GetCell $table_shape 1 1]
#     InsertTextInCell $table_cell $title 16
#     set table_cell [GetCell $table_shape 1 2]
#     InsertTextInCell $table_cell "上铰链" 16
#     set table_cell [GetCell $table_shape 1 3]
#     InsertTextInCell $table_cell "下铰链" 16

#     set table_cell [GetCell $table_shape 2 1]
#     InsertTextInCell $table_cell $note 16
#     set table_cell [GetCell $table_shape 2 2]
#     InsertTextInCell $table_cell [lindex $list_vals 0] 16
#     set table_cell [GetCell $table_shape 2 3]
#     InsertTextInCell $table_cell [lindex $list_vals 1] 16
# }


################################################
# Procedure: getConfigValue
# Author: ebeling
# Date: 23.07.2008
# Description:
# returns the configuration value
# Parameters:
# arrayName - the array that contains the configuration (complete namespace path)
# configId - the  array index storing the info
# Variables:
# none
# Returns:
# the value stored in the array or an empty string
################################################
proc getConfigValue {arrayName configId} {

    set returnValue ""
    if {[info exists ${arrayName}($configId)]} {
	set returnValue [set ${arrayName}($configId)]
    }

    return $returnValue
    # end proc getConfigValue ####################################
}

################################################
# Procedure: initConfigValues
# Author: ebeling
# Date: 23.07.2008
# Description:
# initializes the configuration array using the
# default values (only if they are not defined)
# Parameters:
# configArray - the array name (complete namespace path)
# Variables:
# none
# Returns:
# none
################################################
proc initConfigValues {configArray } {
    set defaultValues(master) "none"
    set defaultValues(pictureResX) "800"
    set defaultValues(pictureResY) "600"
    set defaultValues(picturePos) "60 120 600 400"
    set defaultValues(textboxPos) "60 20 600 50"
    set defaultValues(textboxFont) "Times New Roman"
    set defaultValues(textboxAlign) "Left"
    set defaultValues(textboxStyle) "Regular"
    set defaultValues(textboxFontSize) "16"
    set defaultValues(imageType) "PNG"
    set defaultValues(slideResX) "800"
    set defaultValues(slideResY) "600"

    foreach ind [array names defaultValues] {
	if {![info exists ${configArray}($ind)]} {
	    set ${configArray}($ind) $defaultValues($ind)
	}
    }

    return 1
    # end proc initConfigValues ####################################
}

proc createDirectory {fileName} {
    set dirname [file dirname $fileName]
    set i 0
    while {[file isfile $dirname]} {
	incr i
	if {$i>1000} {error "Can't create Directory $dirname"}
	set dirname "[file dirname $fileName]$i"
    }
    if {[file exists $dirname]} {
	if {[file isdirectory $dirname]} {
	    return $dirname
	}
    }
    if {[catch {file mkdir $dirname} err]} {
	error "Can't create Directory $dirname\n$err"
    }
    return $dirname
}


# proc AddHWPageImageX {slide pageId configVar tmpDir} {
#     variable deleteList
#     variable list_rezVals

#     set resX [getConfigValue $configVar pictureResX]
#     set resY [getConfigValue $configVar pictureResY]
#     [GetProject] SetActivePage $pageId
#     set page [GetPage -page $pageId]
#     set numberOfWindows [$page GetNumberOfWindows]
#     set layout [$page GetLayout]
#     set pos [getConfigValue $configVar picturePos]
#     foreach {xPos yPos width height} $pos break
#     set width 680
#     set height 420
#     #drawani
#     set session [GetSession]
#     set shapeList ""
#     for {set winId 1} {$winId <= $numberOfWindows} {incr winId} {
#         $page SetActiveWindow $winId

# # fit window
# #         $winId GetViewControlHandle viewctrl
# #         viewctrl FitAllFrames
# #         $winId Draw
# #         viewctrl ReleaseHandle

#         set picName [file join $tmpDir pic_${pageId}_${winId}.png]
#         # get the resolution of the window
#         set posList [getPositionOfWindow $layout $winId $resX $resY]
#         set winResX [lindex $posList 2]
#         set winResY [lindex $posList 3]
#         # capture the window
#         set imageType [getConfigValue $configVar imageType]
#         $session CaptureActiveWindow $imageType $picName pixels $winResX $winResY

#         lappend deleteList $picName
#         # insert the picture in Powerpoint
#         set picPos [getPositionOfWindow $layout $winId $width $height]
#         foreach {xRel yRel widthRel heightRel} $picPos break
#         set x [expr $xPos + $xRel]
#         set y [expr $yPos + $yRel-20]
#         set widthRel [expr $widthRel]
#         set heightRel [expr $heightRel]
#         lappend shapeList [InsertPicture $slide $picName $x $y $widthRel $heightRel 0]

#     }
#     if {[llength $shapeList]>1} {
#         GroupShapes $slide $shapeList
#     }
#     return 0
# }


# proc GetSummaryInfo { file_path } {
#     set list_text ""
#     set fp_chan 0;

#     if { [catch {
#         set fp_chan [open $file_path r];
#         seek $fp_chan 0 start;

#         set line_num 0
#         while {[gets $fp_chan str_line]>=0} {
#             if { $line_num>5 } { break }
#             if { [llength $str_line]!=0 } {
#                 incr line_num
#             }

#             set comma_index [string first "," $str_line];
#             if {$comma_index > 0} {                 
#                 # extract that string at the front of the comma separator
#                 set text_name [string range $str_line 0 [expr $comma_index-1]];
#                 set text_val [string range $str_line [expr $comma_index+1] end];

#                 lappend list_text [list $text_name $text_val]
#             }
#         }
#     }] } {
#         tk_messageBox -message "Fail to read file: $file_path."
#         return
#     }

#     if { $fp_chan!=0 } {
#         catch {close $fp_chan} 
#     }

#     set text_info "模型信息 \" & vbCrLf & vbCrLf & \""
#     foreach text_item $list_text {
#         set text_itemval [lindex $text_item 1]
#         set text_chs ""
#         switch -exact [lindex $text_item 0] {
#             "nodes" { set text_chs "节点数量"  }
#             "elems" { set text_chs "单元数量"  }
#             "comps" { set text_chs "零部件数量"  }
#             "mats" { set text_chs "材料种类"  }
#             "props" { set text_chs "属性种类"  }
#             "mass" { 
#                 set text_chs "模型质量"  
#                 set text_itemval [format "%.2e吨" $text_itemval]
#             }
#         }

#         append text_info [format "%s:%s \" & vbCrLf & \"" $text_chs $text_itemval ]
#     }

#     return $text_info
# }

# proc GetOutputNode { file_path } {
#     set list_text ""
#     set fp_chan 0;

#     if { [catch {
#         set fp_chan [open $file_path r];
#         seek $fp_chan 0 start;

#         set fini 0
#         while {[gets $fp_chan str_line]>=0} {
#             if { [string index $str_line 0]==";" } { incr fini 1;continue }
#             if { $fini==1 } {
#                 set comma_index [string first "," $str_line];
#                 if {$comma_index > 0} {                 
#                     set text_name [string range $str_line 0 [expr $comma_index-1]];
#                     set text_val [string range $str_line [expr $comma_index+1] end];

#                     lappend list_text [list $text_name $text_val]
#                 }
#             }
#         }
#     }] } {
#         tk_messageBox -message "Fail to read file: $file_path."
#         return
#     }

#     if { $fp_chan!=0 } {
#         catch {close $fp_chan} 
#     }

#     return $list_text
# }

# proc GetOutputNodeEx { file_path } {
#     set output_list ""
#     set fp_chan 0;

#     if { [catch {
#         set fp_chan [open $file_path r];
#         seek $fp_chan 0 start;

#         set fini 0
#         while {[gets $fp_chan str_line]>=0} {
#             if { [string index $str_line 0]==";" } { incr fini 1;continue }
#             if { $fini==1 } {
#                 set comma_list [split $str_line ","]
#                 lappend output_list [list [lindex $comma_list 1] [lindex $comma_list 3]]
#             }
#         }
#     }] } {
#         tk_messageBox -message "Fail to read file: $file_path."
#         return
#     }

#     if { $fp_chan!=0 } {
#         catch {close $fp_chan} 
#     }

#     return $output_list
# }

# proc GetOutputNodeSlam { file_path } {
#     set output_list ""
#     set fp_chan 0;

#     if { [catch {
#         set fp_chan [open $file_path r];
#         seek $fp_chan 0 start;

#         set fini 0
#         while {[gets $fp_chan str_line]>=0} {
#             if { [string index $str_line 0]==";" } { incr fini 1;continue }
#             if { $fini==1 } {
#                 set comma_list [split $str_line ","]
#                 lappend output_list [lindex $comma_list 0]
#             }
#         }
#     }] } {
#         tk_messageBox -message "Fail to read file: $file_path."
#         return
#     }

#     if { $fp_chan!=0 } {
#         catch {close $fp_chan} 
#     }

#     return $output_list
# }





proc convertToFileName {text} {
    set tmp $text
    set tmp2 [split $tmp {}]
    set tmp ""
    for {set i 0} {$i < [llength $tmp2]} {incr i} {
	if {([string is alnum [lindex $tmp2 $i]]) || ([lindex $tmp2 $i] == "_")} {
	    set tmp "$tmp[lindex $tmp2 $i]"
	}
    }
    return $tmp
}
