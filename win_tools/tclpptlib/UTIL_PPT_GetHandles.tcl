### Revision Comments ##########
# $Date: 25.05.09 13:57 $
# $Revision: 7 $
# $Author: Ebeling $    	
########################################
# GetHandles library
# namespace: mvh
# Date: 25-May-2009 -- 10:00:24
########################################
namespace eval mvh {
    # code follows
    # set the library directory
    set curDir [file normalize [file dirname [info script]]]
    # set the library directory if no external was defined!
    if {![info exists libDir]} {
        set libDir [file dirname $curDir]
    }
    variable versionArray
    set versionArray(buildDate) "25-May-2009 -- 10:00:24"
    set versionArray(version) 1.0

    variable curNs [namespace current]
    variable exportprocs
    variable possibleOptions
    variable exclusiveOptions
    variable mandatoryOptions


    ### Revision Comments ##########
    # Date: 18.12.08 15:49 $
    # Revision: 2 $
    # Author: Ebeling $
    # History: animation.tcl $
    # 
    # *****************  Version 2  *****************
    # User: Ebeling      Date: 18.12.08   Time: 15:49
    # Updated in $/Altair/CommonLibs/HyperWorks/gethandles/src
    # improved GetSelectionSet
    # 
    # *****************  Version 1  *****************
    # User: Ebeling      Date: 20.11.08   Time: 15:12
    # Created in $/Altair/CommonLibs/HyperWorks/gethandles/src
    # reorganized gethandles
    #
    ### End History ###############

    ##
    # ::mvh::animation::GetRenderOptions - get a render options handle of a animation client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    # \h1 Returns:
    #
    #     Returns a render options handle of a animation client
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a render options handle of HyperView.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    ##
    set possibleOptions(GetRenderOptions) [list window page]
    lappend exportprocs GetRenderOptions
    #########################################################################
    proc GetRenderOptions {args} {
	variable curNs
	array set opts [checkArgs $args GetRenderOptions]

	set getClientCmd "set ani \[GetClient -type \"animation\""
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getClientCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getClientCmd "\]"
	eval $getClientCmd

	# check if it is an animation client
	if {[$ani GetClassName] != "poIPost"} {
	    error "GetRenderOptions: The requested (active) client is not an animation client!"
	}
	set renderh "${ani}_render"
	Release $renderh
	set render [$ani GetRenderOptionsHandle $renderh]
	if {$render == $renderh} {
	    return $render
	} else {
	    error "Error in GetRenderOptions"
	}
    }
    # end GetRenderOptions


    ##
    # ::mvh::animation::GetH3DOptions - get a h3d options handle of a animation client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    # \h2 None
    # \h1 Returns:
    #
    #     Returns a h3d options handle of a animation client
    #
    # \h1 Description:
    #
    #
    # This procedure returns a h3d options handle of HyperView.
    ##
    lappend exportprocs GetH3DOptions
    ########################################################################
    proc GetH3DOptions {} {
	variable curNs
	set h3dh "${curNs}::h3doptions"
	Release $h3dh
	set h3d [[GetSession] GetH3DExportOptionsHandle $h3dh]
	if {$h3d == $h3dh} {
	    return $h3d
	} else {
	    error "Error in GetH3DOptions"
	}
    }
    # end GetH3DOptions ####################################################




    ##
    # ::mvh::animation::GetModel - get a model handle of a animation client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -clientHandle "client handle"
    #
    #     the client handle, where the model is requested
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    #   \h2 -id "modelID"
    #     the model ID of the requested model
    # \h1 Returns:
    #
    #     Returns a model handle of a animation client
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    # If no model ID is given then it returns the active model of the requested client.
    ##
    set possibleOptions(GetModel) [list window page id clientHandle]
    lappend exportprocs GetModel
    #########################################################################
    proc GetModel {args} {
	variable curNs

	array set opts [checkArgs $args GetModel]

	# get the client Handle
	if {[info exists opts(clientHandle)]} {
	    set clienth $opts(clientHandle)
	} else {

	    set clientCmd "set clienth \[GetClient"
	    foreach opt [list window page] {
		if {[info exists opts($opt)] == 1} {
		    append clientCmd " -$opt \"$opts($opt)\""
		}
	    }
	    append clientCmd "\]"
	    eval $clientCmd
	}
	# check if it is an animation client
	if {[$clienth GetClassName] != "poIPost"} {
	    error "GetModel: The requested (active) client is not an animation client!"
	}
	if {[$clienth GetModelList] == ""} {
	    error "GetModel: The requested (active) client contains no models!"
	}
	set modelId [$clienth GetActiveModel]
	set modelList [$clienth GetModelList]
	if {[info exists opts(id)]} {
	    set modelId $opts(id)
	    if {[lsearch $modelList $modelId] == -1} {
		error "There is no model with id $modelId on client $clienth!"
	    }
	}
	set modelh "${clienth}_model$modelId"
	Release $modelh
	set model [$clienth GetModelHandle $modelh $modelId]
	if {$model == $modelh} {
	    return $model
	} else {
	    error "Error in GetModel"
	}
    }
    # end GetModel ##########################################################


    ##
    # ::mvh::animation::GetComponent - get a component handle of a animation client model
    #
    # \h1 mandatory Arguments:
    #   \h2 -id "componentID"
    #
    #     the component-id
    # \h1 optional Arguments:
    #   \h2 -id "componentID"
    #
    #     the component-id
    #   \h2 -modelId "modelId"
    #
    #     the model-id
    # \h1 Returns:
    #
    #     Returns a component handle of a animation client model
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a component handle of HyperView model.
    ##
    set possibleOptions(GetComponent) [list id modelId]
    set mandatoryOptions(GetComponent) [list id]
    lappend exportprocs GetComponent
    #########################################################################
    proc GetComponent {args} {
	array set opts [checkArgs $args GetComponent]
	if {[info exists opts(modelId)]} {
	    set model [GetModel -id $opts(modelId)]
	} else {
	    set model [GetModel]
	}
	set comph "${model}_comp$opts(id)"
	Release $comph
	set comp [$model GetComponentHandle $comph $opts(id)]
	if {$comp == $comph} {
	    return $comp
	} else {
	    error "Error in GetComponent"
	}
    }
    # end GetComponentHandle ################################################



    ##
    # ::mvh::animation::GetQueryControl - get a query handle of a animation client model
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    # \h2 None
    # \h1 Returns:
    #
    #     Returns a query handle of the active animation client model
    #
    # \h1 Description:
    #
    # This procedure returns a query handle of the active HyperView model.
    #
    ##
    lappend exportprocs GetQueryControl
    #########################################################################
    proc GetQueryControl {} {
	set model [GetModel]
	set queryh "${model}_query"
	Release $queryh
	set query [$model GetQueryCtrlHandle $queryh]
	if {$query == $queryh} {
	    return $query
	} else {
	    error "Error in GetQueryCtrl"
	}
    }
    # end GetQueryControl ###################################################



    ##
    # ::mvh::animation::GetIterator - get a Iterator handle to a query handle
    #
    # \h1 mandatory Arguments:
    #   \h2 -queryHandle "QueryHandle"
    #
    #     the belonging query handle
    # \h1 optional Arguments:
    #   \h2 -queryHandle "QueryHandle"
    #
    #     the belonging query handle
    # \h1 Returns:
    #
    #     Returns a Iterator handle of a animation client model
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a Iterator handle to a belonging Qurey Handle.
    # Gain a Query Handle with help of ::mvh::animation::GetIterator
    ##
    set possibleOptions(GetIterator) [list queryHandle]
    set mandatoryOptions(GetIterator) [list queryHandle]
    lappend exportprocs GetIterator
    #########################################################################
    proc GetIterator {args} {
	array set opts [checkArgs $args GetIterator]
	set queryHandle $opts(queryHandle)
	set iteh "${queryHandle}_iterator"
	Release $iteh
	set ite [$queryHandle GetIteratorHandle $iteh]
	if {$ite == $iteh} {
	    return $ite
	} else {
	    error "Error in GetIterator"
	}
    }
    # end GetIterator #######################################################



    ##
    # ::mvh::animation::GetSelectionSet - get a SelectionSet handle of a animation client model
    #
    # \h1 mandatory Arguments:
    #   \h2 -id "selectionsetID"
    #
    #     the SelectionSet-id
    # \h1 optional Arguments:
    #   \h2 -id "selectionsetID"
    #
    #     the SelectionSet-id
    #
    # \h2 -type "selectionType"
    #     possible selection types are \'id\' or \'label\', default \'id\',
    #     the id or label is submitted using parameter \'id\'
    #
    #   \h2 -modelId "modelId"
    #
    #     the model-id
    # \h1 Returns:
    #
    #     Returns a SelectionSet handle of a animation client model
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    ##
    set possibleOptions(GetSelectionSet) [list id modelId selectionType]
    set mandatoryOptions(GetSelectionSet) [list id]
    lappend exportprocs GetSelectionSet
    #########################################################################
    proc GetSelectionSet {args} {
	array set opts [checkArgs $args GetSelectionSet]
	set id $opts(id)
	if {[info exists opts(modelId)]} {
	    set model [GetModel -id $opts(modelId)]
	} else {
	    set model [GetModel]
	}

	if {[info exists opts(selectionType)] == 1} {
	    set typeList [list id label]
	    if {[lsearch $typeList $opts(selectionType)] == -1} {
		error "Found unsupported selection type $opts(type).\nPossible selection types are \'$typeList\'."
	    }
	    if {$opts(selectionType) == "label"} {
		set selSetIdList [$model GetSelectionSetList]
		#puts "  selSetIdList: $selSetIdList"
		foreach selSetId $selSetIdList {
		    set selseth "${model}_selset$selSetId+[clock clicks]"
		    Release $selseth
		    #puts "   selseth: $selseth"
		    set selset [$model GetSelectionSetHandle $selseth $selSetId]
		    set itemLabel [$selset GetLabel]
		    #puts "   label: $itemLabel"

		    if {[string match "$itemLabel" "$opts(id)"] == 1} {
			#puts "Found selSet for label: $opts(id): $selSetId, handle: $selset"
			return $selset
		    }
		    Release $selset
		} ; ## end foreach

		error "GetSelectionSet: could not find selection set with label \'$opts(id)\'"
	    } ; ## end if selectionType
	}

	## check if id is of type integer, if not -> error
	if {[string is integer $id] == 0 } {
	    error "GetSelectionSet: id must be an integer value, but id was: $id"
	}

	set selseth "${model}_selset${id}+[clock clicks]"
	Release $selseth
	set selset [$model GetSelectionSetHandle $selseth $id]
	return $selset
    }
    # end GetSelectionSet ########################################################



    ##
    # ::mvh::animation::GetResultCtrl - get a ResultCtrl handle of a animation client model
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    #   \h2 -id "modelID"
    #     the model ID of the requested model
    # \h1 Returns:
    #
    #     Returns a ResultCtrl handle of the active animation client model
    #
    # \h1 Description:
    #
    # This procedure returns a ResultCtrl handle of the active HyperView model.
    #
    ##
    set possibleOptions(GetResultCtrl) [list window page id]
    lappend exportprocs GetResultCtrl
    ##############################################################################
    proc GetResultCtrl {args} {
	array set opts [checkArgs $args GetResultCtrl]
	set clientCmd "set clienth \[GetClient"
	foreach opt [list window page] {
	    if {[info exists opts($opt)] == 1} {
		append clientCmd " -$opt \"$opts($opt)\""
	    }
	}
	append clientCmd "\]"
	eval $clientCmd
	# check if it is an animation client
	if {[$clienth GetClassName] != "poIPost"} {
	    error "GetResultCtrl: The requested client is not an animation client!"
	}
	if {[$clienth GetModelList] == ""} {
	    error "GetResultCtrl: The requested client contains no models!"
	}
	set modelId [$clienth GetActiveModel]
	set modelList [$clienth GetModelList]
	if {[info exists opts(id)]} {
	    set modelId $opts(id)
	    if {[lsearch $modelList $modelId] == -1} {
		error "There is no model with id $modelId on client $clienth!"
	    }
	}
	set modelh "${clienth}_model$modelId"
	Release $modelh
	set model [$clienth GetModelHandle $modelh $modelId]
	if {$model == $modelh} {
	    set resulth "${model}_result"
	    Release $resulth
	    set result [$model GetResultCtrlHandle $resulth]
	    if {$result == $resulth} {
		return $result
	    } else {
		error "Error in GetResultCtrl"
	    }
	} else {
	    error "Error in GetResultCtrl"
	}
    }
    # end GetResultCtrl ##########################################################


    ##
    # ::mvh::animation::GetScaleCtrl - get a Scale Control handle of a animation client model
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    # \h2 None
    # \h1 Returns:
    #
    #     Returns a Scale Control handle of the active animation client model
    #
    # \h1 Description:
    #
    # This procedure returns a Scale Control handle of the active HyperView model.
    #
    ##
    lappend exportprocs GetScaleCtrl
    ##############################################################################
    proc GetScaleCtrl {} {
	set result [GetResultCtrl]
	set resulth "${result}_scale"
	Release $resulth
	set result [$result GetScaleCtrlHandle $resulth]
	if {$result == $resulth} {
	    return $result
	} else {
	    error "Error in GetScaleCtrl"
	}
    }
    # end GetScaleCtrl ##########################################################



    ##
    # ::mvh::animation::GetContourCtrl - get a ContourCtrl handle of a animation client model
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    #   \h2 -id "modelID"
    #     the model ID of the requested model
    # \h1 Returns:
    #
    #     Returns a ContourCtrl handle of the active animation client model
    #
    # \h1 Description:
    #
    # This procedure returns a ContourCtrl handle of the active HyperView model.
    #
    ##
    set possibleOptions(GetContourCtrl) [list window page id]
    lappend exportprocs GetContourCtrl
    ##############################################################################
    proc GetContourCtrl {args} {
	array set opts [checkArgs $args GetContourCtrl]
	set resultCmd "set resulth \[GetResultCtrl"
	foreach opt [list window page id] {
	    if {[info exists opts($opt)] == 1} {
		append resultCmd " -$opt \"$opts($opt)\""
	    }
	}
	append resultCmd "\]"
	eval $resultCmd

	set contourh "${resulth}_contour"
	Release $contourh
	set contour [$resulth GetContourCtrlHandle $contourh]
	if {$contour == $contourh} {
	    return $contour
	} else {
	    error "Error in GetContourCtrl"
	}
    }
    # end GetContourCtrl #########################################################


    ##
    # ::mvh::animation::GetComplexCtrl - get a ComplexCtrl handle of a animation client model
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    #   \h2 -id "modelID"
    #     the model ID of the requested model
    # \h1 Returns:
    #
    #     Returns a ComplexCtrl handle of the active animation client model
    #
    # \h1 Description:
    #
    # This procedure returns a ComplexCtrl handle of the active HyperView model.
    #
    ##
    set possibleOptions(GetComplexCtrl) [list window page id]
    lappend exportprocs GetComplexCtrl
    ##############################################################################
    proc GetComplexCtrl {args} {
	array set opts [checkArgs $args GetComplexCtrl]
	set resultCmd "set resulth \[GetResultCtrl"
	foreach opt [list window page id] {
	    if {[info exists opts($opt)] == 1} {
		append resultCmd " -$opt \"$opts($opt)\""
	    }
	}
	append resultCmd "\]"
	eval $resultCmd

	set complexh "${resulth}_complex"
	Release $complexh
	set complex [$resulth GetComplexCtrlHandle $complexh]
	if {$complex == $complexh} {
	    return $complex
	} else {
	    error "Error in GetComplexCtrl"
	}
    }
    # end GetComplexCtrl #########################################################


    ##
    # ::mvh::animation::GetFLDCtrl - get a FLDCtrl handle of a animation client model
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    #   \h2 -id "modelID"
    #
    #     the model ID of the requested model
    # \h1 Returns:
    #
    #     Returns a FLDCtrl handle of the active animation client model
    #
    # \h1 Description:
    #
    # This procedure returns a FLDCtrl handle of the active HyperView model.
    #
    ##
    set possibleOptions(GetFLDCtrl) [list window page id]
    lappend exportprocs GetFLDCtrl
    ##############################################################################
    proc GetFLDCtrl {args} {
	array set opts [checkArgs $args GetFLDCtrl]
	set resultCmd "set resulth \[GetResultCtrl"
	foreach opt [list window page id] {
	    if {[info exists opts($opt)] == 1} {
		append resultCmd " -$opt \"$opts($opt)\""
	    }
	}
	append resultCmd "\]"
	eval $resultCmd

	set fldh "${resulth}_fld"
	Release $fldh
	set fld [$resulth GetFLDCtrlHandle $fldh]
	if {$fld == $fldh} {
	    return $fld
	} else {
	    error "Error in GetFLDCtrl"
	}
    }
    # end GetFLDCtrl #########################################################


    ##
    # ::mvh::animation::GetFLDCase - get a fld case study handle
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    #   \h2 -id "modelID"
    #
    #     the model ID of the requested model
    #   \h2 -fldCase "fldCaseID"
    #
    #     the fld case ID of the requested fld case study
    # \h1 Returns:
    #
    #     Returns a CaseStudy handle
    #
    # \h1 Description:
    #
    # This procedure returns a CaseStudy handle of the choosen HyperView model.
    #
    ##
    set possibleOptions(GetFLDCase) [list window page id fldCase]
    lappend exportprocs GetFLDCase
    ##############################################################################
    proc GetFLDCase {args} {
	array set opts [checkArgs $args GetFLDCase]
	set fldCmd "set fldh \[GetFLDCtrl"
	foreach opt [list window page id] {
	    if {[info exists opts($opt)] == 1} {
		append fldCmd " -$opt \"$opts($opt)\""
	    }
	}
	append fldCmd "\]"
	eval $fldCmd

	set caseList [$fldh GetCaseList]
	if {[llength $caseList] == 0} {
	    error "There is no FLD case in FLD $fldh !"
	} else {
	    if {[info exists opts(fldCase)]} {
        	set caseId $opts(fldCase)
        	if {[lsearch $caseList $caseId] == -1} {
		    error "There is no FLD case with case id $caseId in FLD $fldh !"
		}
	    } else {
		set caseId [$fldh GetActiveCase]
	    }
	}
	set caseh "${fldh}_fldcase${caseId}"
	Release $caseh
	set case [$fldh GetCaseHandle $caseh 1]
	if {$case == $caseh} {
	    return $case
	} else {
	    error "Error in GetFLDCase"
	}
    }
    # end GetFLDCase #########################################################

    ##
    # ::mvh::animation::GetContourLegend - get a ContourLegend handle of a animation client model
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    # \h2 None
    # \h1 Returns:
    #
    #     Returns a ContourLegend handle of the active animation client model
    #
    # \h1 Description:
    #
    # This procedure returns a ContourLegend handle of the active HyperView model.
    #
    ##
    lappend exportprocs GetContourLegend
    ##############################################################################
    proc GetContourLegend {} {
	variable curNs
	set contourh [GetContourCtrl]
	set contourlegendh "${contourh}_legend"
	Release $contourlegendh
	set legend [$resulth GetContourCtrlHandle $contourlegendh]
	if {$legend == $contourlegendh} {
	    return $legend
	} else {
	    error "Error in GetContourLegend"
	}
    }
    # end GetContourLegend #########################################################



    ##
    # ::mvh::animation::GetTensorCtrl - get a TensorCtrl handle of a animation client model
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    # \h2 None
    # \h1 Returns:
    #
    #     Returns a TensorCtrl handle of the active animation client model
    #
    # \h1 Description:
    #
    # This procedure returns a TensorCtrl handle of the active HyperView model.
    #
    ##
    lappend exportprocs GetTensorCtrl
    ##############################################################################
    proc GetTensorCtrl {} {
	set resulth [GetResultCtrl]
	set tensorh "${resulth}_tensor"
	Release $tensorh
	set tensor [$resulth GetTensorCtrlHandle $tensorh]
	if {$tensor == $tensorh} {
	    return $tensor
	} else {
	    error "Error in GetTensorCtrl"
	}
    }
    # end GetTensorCtrl ##########################################################


    ##
    # ::mvh::animation::GetVectorCtrl - get a VectorCtrl handle of a animation client model
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    # \h2 None
    # \h1 Returns:
    #
    #     Returns a VectorCtrl handle of the active animation client model
    #
    # \h1 Description:
    #
    # This procedure returns a VectorCtrl handle of the active HyperView model.
    #
    ##
    lappend exportprocs GetVectorCtrl
    ##############################################################################
    proc GetVectorCtrl {} {
	set resulth [GetResultCtrl]
	set vectorh "${resulth}_vector"
	Release $vectorh
	set vector [$resulth GetVectorCtrlHandle $vectorh]
	if {$vector == $vectorh} {
	    return $vector
	} else {
	    error "Error in GetVectorCtrl"
	}
    }
    # end GetVectorCtrl ##########################################################


    ##
    # ::mvh::animation::GetLocalSystem - get a SystemHandle to the LocalSystem in a animation client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -id "SystemID"
    #
    #     the coordinate System ID.
    # \h1 Returns:
    #
    #     Returns a SystemHandle to the LocalSystem
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    ##
    lappend exportprocs GetLocalSystem
    set possibleOptions(GetLocalSystem) [list id]
    set mandatoryOptions(GetLocalSystem) [list id]
    ##############################################################################
    proc GetLocalSystem {args} {
	array set opts [checkArgs $args GetLocalSystem]
	set model [GetModel]
	set systemh "${model}_sys$opts(id)"
	Release $systemh
	set system [$model GetSystemHandle $systemh $opts(id)]
	if {$system == $systemh} {
	    return $system
	} else {
	    error "Error in GetLocalSystem"
	}
    }
    # end GetLocalSystem #########################################################



    ##
    # ::mvh::animation::GetContourLegend - get a ContourLegend handle of a animation client model
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    # \h2 None
    # \h1 Returns:
    #
    #     Returns a ContourLegend handle of the active animation client model
    #
    # \h1 Description:
    #
    # This procedure returns a ContourLegend handle of the active HyperView model.
    #
    ##
    lappend exportprocs GetContourLegend
    ##############################################################################
    proc GetContourLegend {args} {
	variable curNs
	set contourh [GetContourCtrl]
	set legendh "${contourh}_lengend"
	Release $legendh
	set legend [$contourh GetLegendHandle $legendh]
	if {$legend == $legendh} {
	    return $legend
	} else {
	    error "Error in GetContourLegend"
	}
    }
    # end GetContourLegend #######################################################



    ##
    # ::mvh::animation::GetTensorLegend - get a TensorLegend handle of a animation client model
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    # \h2 None
    # \h1 Returns:
    #
    #     Returns a TensorLegend handle of the active animation client model
    #
    # \h1 Description:
    #
    # This procedure returns a TensorLegend handle of the active HyperView model.
    #
    ##
    lappend exportprocs GetTensorLegend
    ##############################################################################
    proc GetTensorLegend {args} {
	variable curNs
	set tensorh [GetTensorCtrl]
	set legendh "${tensorh}_lengend"
	Release $legendh
	set legend [$tensorh GetLegendHandle $legendh]
	if {$legend == $legendh} {
	    return $legend
	} else {
	    error "Error in GetContourLegend"
	}
    }
    # end GetContourLegend #######################################################


    ##
    # ::mvh::animation::GetMeasure - get a Measure handle of a animation client model
    #
    # \h1 mandatory Arguments:
    # 	\h2 -id "MeasureID"
    #
    #     the HyperView internal id of the measure.
    # \h1 optional Arguments:
    #   \h2 -clientHandle "client handle"
    #
    #     a client handle to improve the performance.
    #   \h2 -page "page id"
    #
    #     the page where the section is placed (can not be used with the option
    #     clientHandle).
    #   \h2 -window "window id"
    #
    #     the window where the section is placed (can not be used with the option
    #     clientHandle).
    # \h1 Returns:
    #
    #     Returns a Measure handle to the belonging MeasureID
    #
    # \h1 Description:
    #
    # This procedure returns a Measure handle to the belonging MeasureID.
    #
    ##
    set possibleOptions(GetMeasure) [list id page window clientHandle]
    set mandatoryOptions(GetMeasure) [list id]
    lappend exportprocs GetMeasure
    ##############################################################################
    proc GetMeasure {args} {
	array set opts [checkArgs $args GetMeasure]
	# get the client handle
	if {[info exists opts(clientHandle)]} {
	    set client $opts(clientHandle)
	} else {
	    set clientCmd "GetClient"
	    foreach opt [list page window] {
		if {[info exists opts($opt)]} {
		    append clientCmd " -$opt \"$opts($opt)\""
		}
	    }
	    set client [eval $clientCmd]
	}

	# check the client type (It must be the Animation client!)
	if {[IsAnimationClient $client] == 0} {
	    error "GetSection $args:\nThe given client is not an animation client!"
	}
	set ani $client
	set measureh "${ani}_measure$opts(id)"
	Release $measureh
	set measure [$ani GetMeasureHandle $measureh $opts(id)]
	if {$measure == $measureh} {
	    return $measure
	} else {
	    error "Error in GetMeasure"
	}
    }
    # end GetMeasure #############################################################

    ##
    # ::mvh::animation::GetSection - get a section handle of a animation client model
    #
    # \h1 mandatory Arguments:
    #   \h2 -id "SectionID"
    #
    #     The HyperView internal id of the section
    # \h1 optional Arguments:
    #   \h2 -clientHandle "client handle"
    #
    #     a client handle to improve the performance
    #   \h2 -page "page id"
    #
    #     the page where the section is placed (can not be used with the option
    #     clientHandle).
    #   \h2 -window "window id"
    #
    #     the window where the section is placed (can not be used with the option
    #     clientHandle).
    # \h1 Returns:
    #
    #     Returns a Section handle to the belonging section id.
    #
    # \h1 Description:
    #
    # This procedure returns a Section handle to the belonging section id.
    #
    ##
    set possibleOptions(GetSection) [list id page window clientHandle]
    set mandatoryOptions(GetSection) [list id]
    lappend exportprocs GetSection
    ##############################################################################
    proc GetSection {args} {
	array set opts [checkArgs $args GetMeasure]

	# get the client handle
	if {[info exists opts(clientHandle)]} {
	    set client $opts(clientHandle)
	} else {
	    set clientCmd "GetClient"
	    foreach opt [list page window] {
		if {[info exists opts($opt)]} {
		    append clientCmd " -$opt \"$opts($opt)\""
		}
	    }
	    set client [eval $clientCmd]
	}

	# check the client type (It must be the Animation client!)
	if {[IsAnimationClient $client] == 0} {
	    error "GetSection $args:\nThe given client is not an animation client!"
	}

	set ani $client
	set sectionList [$ani GetSectionList]
	if {[lsearch $sectionList $opts(id)] == -1} {
	    error "GetSection $args:\nThe given section id doesn't exist!"
	}
	set sectionh "${ani}_section$opts(id)"
	Release $sectionh
	set section [$ani GetSectionHandle $sectionh $opts(id)]
	if {$section == $sectionh} {
	    return $section
	} else {
	    error "Error in GetSection $args ???"
	}
    }
    # end GetMeasure #############################################################

    ##
    # ::mvh::animation::GetTrackingSystem - get a tracking system handle of a animation client model
    #
    # \h1 mandatory Arguments:
    #   \h2 -id "ID of the system"
    #
    #     the HyperView internal id of the tracking system
    # \h1 optional Arguments:
    #   \h2 -clientHandle "client handle"
    #
    #     a client handle to improve the performance.
    #   \h2 -page "page id"
    #
    #     the page where the section is placed (can not be combined with the option
    #     clientHandle).
    #   \h2 -window "window id"
    #
    #     the window where the section is placed (can not be combined with the option
    #     clientHandle).
    # \h1 Returns:
    #
    #     Returns a tracking system handle to the belonging ID
    #
    # \h1 Description:
    #
    # This procedure returns a tracking system handle to the belonging ID.
    #
    ##
    set possibleOptions(GetTrackingSystem) [list id page window clientHandle]
    set mandatoryOptions(GetTrackingSystem) [list id]
    lappend exportprocs GetTrackingSystem
    ##############################################################################
    proc GetTrackingSystem {args} {
	array set opts [checkArgs $args GetMeasure]
	# get the client handle
	if {[info exists opts(clientHandle)]} {
	    set client $opts(clientHandle)
	} else {
	    set clientCmd "GetClient"
	    foreach opt [list page window] {
		if {[info exists opts($opt)]} {
		    append clientCmd " -$opt \"$opts($opt)\""
		}
	    }
	    set client [eval $clientCmd]
	}

	# check the client type (It must be the Animation client!)
	if {[IsAnimationClient $client] == 0} {
	    error "GetTrackingSystem $args:\nThe given client is not an animation client!"
	}
	set ani [GetModel -clientHandle $client]
	#    set ani $client
	set trackh "${ani}_tracking$opts(id)"
	Release $trackh
	set track [$ani GetTrackingSystemHandle $trackh $opts(id)]
	if {$track == $trackh} {
	    return $track
	} else {
	    error "Error in GetTrackingSystem"
	}
    }
    # end GetTrackingSystem #############################################################

    ##
    # ::mvh::animation::GetSystem - get a section handle of a animation client model
    #
    # \h1 mandatory Arguments:
    #   \h2 -id "SystemID"
    #
    #     The HyperView internal id of the section
    # \h1 optional Arguments:
    #   \h2 -clientHandle "client handle"
    #
    #     a client handle to improve the performance
    #   \h2 -modelHandle "model handle"
    #
    #     a model handle to improve the performance
    #   \h2 -page "page id"
    #
    #     the page where the section is placed (can not be used with the option
    #     clientHandle).
    #   \h2 -window "window id"
    #
    #     the window where the section is placed (can not be used with the option
    #     clientHandle).
    # \h1 Returns:
    #
    #     Returns a Section handle to the belonging section id.
    #
    # \h1 Description:
    #
    # This procedure returns a Section handle to the belonging section id.
    #
    ##
    set possibleOptions(GetSystem) [list id page window clientHandle modelHandle]
    set mandatoryOptions(GetSystem) [list id]
    lappend exportprocs GetSystem
    ##############################################################################
    proc GetSystem {args} {
	array set opts [checkArgs $args GetSystem]

	# get the model handle
	if {[info exists opts(modelHandle)]} {
	    set model $opts(modelHandle)
	} else {
	    # get the client handle
	    if {[info exists opts(clientHandle)]} {
		set client $opts(clientHandle)
	    } else {
		set clientCmd "GetClient"
		foreach opt [list page window] {
		    if {[info exists opts($opt)]} {
			append clientCmd " -$opt \"$opts($opt)\""
		    }
		}
		set client [eval $clientCmd]
	    }
	    set model [GetModel -clientHandle $client]

	}

	set systemList [$model GetSystemList]

	if {[lsearch $systemList $opts(id)] == -1} {
	    error "GetSysten $args:\nThe given system id $opts(id) doesn't exist!"
	}
	set systemh "${model}_system_$opts(id)"
	Release $systemh
	set system [$model GetSystemHandle $systemh $opts(id)]
	if {$system == $systemh} {
	    return $system
	} else {
	    error "Error in GetSystem $args ???"
	}
    }
    # end GetMeasure #############################################################


    ###############################################################################
    #
    #  Procedure:  IsAnimationClient
    #  Created:    03/30/2006 9:21
    #  Author:     Matthias Ebeling
    #  Comments:   This is a internal procedure to check, if the given client is of
    #              type Animation
    #
    #  Arguments:  clientHandle - the client handle to check
    #
    #  Returns:    1 - if it is an Animation client
    #              0 - if not
    #
    ###############################################################################
    lappend exportprocs IsAnimationClient
    proc IsAnimationClient {clientHandle} {
	set returnValue 0
	catch {
	    if {[$clientHandle GetClassName] == "poIPost"} {
		set returnValue 1
	    }
	}
	return $returnValue
    }
    # end IsAnimationClient


    ##
    # ::mvh::animation::GetExplosion - get a explosion handle of a animation client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -id "explosionID"
    #
    #     the explosion ID of the requested explosion (default is the active explosion)
    #   \h2 -modelHandle "model handle"
    #
    #     the model handle, where the explosion is requested
    #   \h2 -id "modelID"
    #
    #     the model ID of the requested model (of explosion) (default is the active model)
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    # \h1 Returns:
    #
    #     Returns a explosion handle of a animation client (based on a model)
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    # If no model ID is given then it returns the active model of the requested client.
    ##
    set possibleOptions(GetExplosion) [list window page id modelHandle modelId]
    lappend exportprocs GetExplosion
    #########################################################################
    proc GetExplosion {args} {
	variable curNs

	array set opts [checkArgs $args GetExplosion]

	# get the client Handle
	if {[info exists opts(modelHandle)]} {
	    set modelh $opts(modelHandle)
	} else {

	    set modelCmd "set modelh \[GetModel"
	    foreach opt [list window page ] {
		if {[info exists opts($opt)] == 1} {
		    append modelCmd " -$opt \"$opts($opt)\""
		}
	    }
	    if {[info exists opts(modelId)]} {
		append modelCmd " -id \"$opts(modelId)\""
	    }
	    append modelCmd "\]"
	    eval $modelCmd
	}
	if {[$modelh GetExplosionList] == ""} {
	    error "GetModel: The requested (active) client contains no models!"
	}
	set explosionId [$modelh GetActiveExplosion]
	set explosionList [$modelh GetExplosionList]
	if {[info exists opts(id)]} {
	    set explosionId $opts(id)
	    if {[lsearch $explosionList $explosionId] == -1} {
		error "There is no model with id $explosionId on model $clienth!"
	    }
	}
	if {$explosionId == 0} {
	    error "There is no active explosion and no other explosion was requested!"
	}

	set explosionh "${modelh}_explosion$explosionId"
	Release $explosionh
	set explosion [$modelh GetExplosionHandle $explosionh $explosionId]
	if {$explosion == $explosionh} {
	    return $explosion
	} else {
	    error "Error in GetExplosion"
	}
    }
    # end GetExplosion ##########################################################

    lappend exportprocs GetVectorLegend
    ##############################################################################
    proc GetVectorLegend {args} {
	variable curNs
	set vectorh [GetVectorCtrl]
	set legendh "${vectorh}_lengend"
	Release $legendh
	set legend [$vectorh GetLegendHandle $legendh]
	if {$legend == $legendh} {
	    return $legend
	} else {
	    error "Error in GetContourLegend"
	}
    }

    ### Revision Comments ##########
    # Date: 20.11.08 15:12 $
    # Revision: 1 $
    # Author: Ebeling $
    # History: checkargs.tcl $
    # 
    # *****************  Version 1  *****************
    # User: Ebeling      Date: 20.11.08   Time: 15:12
    # Created in $/Altair/CommonLibs/HyperWorks/gethandles/src
    # reorganized gethandles
    #
    ### End History ###############

    # This file contains the procedure for checking arguments to procedures
    proc putWarning {text} {
        [GetSession] PostMessageToLog "Warning: $text"
    }

    proc putError {text} {
        error $text
    }


    proc errormsg {msg procedure} {
        variable possibleOptions
        variable mandatoryOptions
        variable exclusiveOptions
        set outmsg "$msg in procedure ${procedure}!\n"
        set outmsg "${outmsg}Possible options are: $possibleOptions($procedure).\n"
        if {[info exists mandatoryOptions($procedure)]} {
            set outmsg "${outmsg}Mandatory options are: $mandatoryOptions($procedure).\n"
        }
        if {[info exists exclusiveOptions($procedure)]} {
            set outmsg "${outmsg}There must be one mutually exclusive option(s) out of:\n"
            foreach exoptlist $exclusiveOptions($procedure) {
                set outmsg "${outmsg} *  $exoptlist\n"
            }
        }
        return $outmsg
    }

    proc checkArgs {args procedure} {
        variable possibleOptions
        variable mandatoryOptions
        variable exclusiveOptions
        set args2 $args
        set tmp [split $args ""]
        if {[lsearch $tmp "\{"] != -1} {
            return [checkArgs2 $args $procedure]
        }
        set first [expr [string first "-" $args] + 1]
        set args [string range $args $first end]
        #regsub "^ *-" $args "" args
        foreach arg  [ split $args "-" ] {
            # check, if the option is allowed
            set option [lindex $arg 0]
            if {[lsearch -exact $possibleOptions($procedure) $option] == -1} {
                return [checkArgs2 $args2 $procedure]
            }
            set opts($option) [lrange $arg 1 [llength $arg]]
        }

        foreach option [array names opt] {
            if {$opts($option) == ""} {
                set emsg [errormsg "Found no argument for option $option" $procedure]
                error $emsg
            }
        }
        # check, if all mandatory options are present
        if {[info exists mandatoryOptions($procedure)]} {
            foreach option $mandatoryOptions($procedure) {
                if {!([info exists opts($option)])} {
                    set emsg [errormsg "Option $option is missing" $procedure]
                    error $emsg
                }
            }
        }

        if {[info exists exclusiveOptions($procedure)]} {
            set foundex 0
            set err 0
            foreach exoptlist $exclusiveOptions($procedure) {
                if {[llength $exoptlist] == 0} {
                    set foundex 1
                }
                set first 1
                set notfound 1
                foreach exopt $exoptlist {
                    if {([info exists opts($exopt)]) && $first} {
                        set notfound 0
                        if {$foundex} {
                            set err 1
                        }
                        set foundex 1
                    }
                    set first 0
                    if {([info exists opts($exopt)]) && $notfound} {
                        set err 1
                    }
                }
            }
            if {!($foundex) || $err} {
                set emsg [errormsg "Can't find all necessary options" $procedure]
                error $emsg
            }
        }
        # set the output
        set outlist [array get opts]
        return $outlist
    }

    proc checkArgs2 {args procedure} {
        variable possibleOptions
        variable mandatoryOptions
        variable exclusiveOptions
        set no_args [llength $args]
        for {set i 0} {$i < $no_args} {set i [expr {$i + 2}]} {
            set first [expr [string first "-" [lindex $args $i]] + 1]
            set opt [string range [lindex $args $i] $first end]
            #regsub "^ *-" [lindex $args $i] "" opt
            if {[lsearch -exact $possibleOptions($procedure) $opt] == -1} {
                set emsg [errormsg "Found unknown option $opt" $procedure]
                error $emsg
            }
            set value [lindex $args [expr {$i + 1}]]
            set opts($opt) $value
            if {$opts($opt) == ""} {
                set emsg [errormsg "Found no argument for option $opt" $procedure]
                error $emsg
            }
        }

        # check, if all mandatory options are present
        if {[info exists mandatoryOptions($procedure)]} {
            foreach option $mandatoryOptions($procedure) {
                if {!([info exists opts($option)])} {
                    set emsg [errormsg "Option $option is missing" $procedure]
                    error $emsg
                }
            }
        }

        if {[info exists exclusiveOptions($procedure)]} {
            set foundex 0
            set err 0
            foreach exoptlist $exclusiveOptions($procedure) {
                if {[llength $exoptlist] == 0} {
                    set foundex 1
                }
                set first 1
                set notfound 1
                foreach exopt $exoptlist {
                    if {([info exists opts($exopt)]) && $first} {
                        set notfound 0
                        if {$foundex} {
                            set err 1
                        }
                        set foundex 1
                    }
                    set first 0
                    if {([info exists opts($exopt)]) && $notfound} {
                        set err 1
                    }
                }
            }
            if {!($foundex) || $err} {
                set emsg [errormsg "Can't find all necessary options" $procedure]
                error $emsg
            }
        }
        # set the output
        set outlist [array get opts]
        return $outlist
    }


    ### Revision Comments ##########
    # Date: 20.11.08 15:12 $
    # Revision: 1 $
    # Author: Ebeling $
    # History: global.tcl $
    # 
    # *****************  Version 1  *****************
    # User: Ebeling      Date: 20.11.08   Time: 15:12
    # Created in $/Altair/CommonLibs/HyperWorks/gethandles/src
    # reorganized gethandles
    #
    ### End History ###############

    ########################################################################
    # Global command to show only GetHandle commands ro reach the next level

    proc ::NextHandles { handle  } {
	set listMethodsTextList [split [$handle ListMethods] \n]
	set getHandleList ""
	foreach line $listMethodsTextList {
	    if { [string match "*Get*Handle*" $line] } {
		lappend getHandleList "${line}"
	    }
	}
	set getHandleList [lsort -increasing -ascii $getHandleList]
	set getHandleString ""
	foreach line $getHandleList {
	    append getHandleString "$line\n"
	}
	if {[string length $getHandleString] == 0} {
	    return "You reached the last step of the object hierarchy!"
	} else {
	    set getHandleString [string replace $getHandleString end end]
	    return $getHandleString
	}
    }
    # end NextHandles ######################################################

    ########################################################################
    # Global command to show only list methods options in alphabetical order

    proc ::SortMethods { handle  } {
	set listMethodsTextList [split [$handle ListMethods] \n]
	set methodsList ""
	foreach line $listMethodsTextList {
	    if {	![string match "*Methods*" $line] \
			    && 	![string match "*from*" $line] \
			    && 	![string match "*----------*" $line] \
			    && [string length $line] > 0} {
		lappend methodsList "${line}"
	    }
	}
	set methodsList [lsort -increasing -ascii $methodsList]
	set getHandleString ""
	foreach line $methodsList {
	    append getHandleString "$line\n"
	}
	if {[string length $getHandleString] == 0} {
	    return "No Options for this handle!"
	} else {
	    set getHandleString [string replace $getHandleString end end]
	    return $getHandleString
	}
    }
    # end SortMethods ######################################################

    ########################################################################
    # Global command to combine Sort Methods and Next Handles

    proc ::HandleInfo { handle  } {
	set getHandleString ""
	set tmpString "All sorted methods of \"$handle\":\n"
	append  getHandleString $tmpString
	for {set i 1} {$i < [string length $tmpString]} {incr i} {append tmpUnderlineString "-"}
	append  getHandleString "${tmpUnderlineString}\n"
	append  getHandleString "[::SortMethods $handle]\n\n"
	set tmpUnderlineString ""
	set tmpString "Get*Handle methods of \"$handle\":\n"
	append  getHandleString $tmpString
	for {set i 1} {$i < [string length $tmpString]} {incr i} {append tmpUnderlineString "-"}
	append  getHandleString "${tmpUnderlineString}\n"
	append  getHandleString [::NextHandles $handle]
	return $getHandleString
    }

    # end HandleInfo #######################################################

    ########################################################################
    # Global command to get System Information

    proc ::SystemInfo {{infoVar 0}} {
	global tcl_platform
	global env
	set totalString ""
	if {$infoVar == 0 || $infoVar == 1} {
	    set totalString		"Environment Variables (command \"puts \$env(<EnvironmentVariable>)\")\n"
	    append totalString	"==================================================================\n"
	    set envNameList [lsort -dictionary [array names env]]
	    set maxNameLength 0
	    foreach envName $envNameList {
		set nameLength [string length $envName]
		if {$nameLength > $maxNameLength} {
		    set maxNameLength $nameLength
		}
	    }
	    set prefixString "\n[format %-${maxNameLength}s ""]   "
	    if {[string tolower $tcl_platform(platform)] == "windows"} {
		set separatorString "\;"
	    } else {
		set separatorString ":"
	    }
	    foreach envName $envNameList {
		set evalString "append totalString \[format %-${maxNameLength}s $envName\] \" = \" \[string map \{ \\\\ \/ [set separatorString] \"[set prefixString]\" \} \[set env($envName)\]\]\\n"
		eval $evalString
	    }
	}
	if {$infoVar == 0} {
	    append totalString "\n"
	}
	if {$infoVar == 0 || $infoVar == 2} {
	    append totalString	"System Variables (command \"sessionHandle GetSystemVariable <SystemVariable>\")\n"
	    append totalString	"=============================================================================\n"
	    set sessionHandle [hwi GetSessionHandle ses_[clock seconds]_[expr rand()]]
	    set systemNameList [lsort -dictionary [list \
						       ALTAIR_HOME \
						       NAME \
						       TITLE \
						       VERSION \
						       CURRENTWORKINGDIR \
						       ECECUTABLEPATH \
						       EXECUTABLEDIR \
						       hw_tcl_common \
						       tcl_lib \
						       tk_lib \
						       hw_readers \
						       hm_feinput_readers \
						       hm \
						       hm_mac \
						       TEMPLATES_DIR \
						       hm_user_profiles \
						       HSTBIN_DIR \
						       study_proxy_path \
						       PREFERENCES_HYPERSTUDY \
						       DOE_DESIGNS_DIR \
						       mv_solver_writers \
						       hw_old_readers \
						       altair_lic.dat \
						       hm_dll_readers \
						       hm_scripts_dir \
						       hyperbeam_dir \
						       wish \
						       PREFERENCES_HG \
						       PREFERENCES_HYPERVIEW \
						       PREFERENCES_MVIEW_PRE \
						       EXTERNALREADERS_DIR \
						       EXTERNALWRITERS_DIR \
						       EXTERNALFUNCS_DIR \
						       export_templates_dir \
						       standard_statistics_template \
						       hw_help_dir \
						       nastran_to_abaqus_converter \
						       jre_path \
						       epic_path \
						       hws_path ARCHITECTURE \
						       XDISPLAYNAME \
						      ]]
	    set maxNameLength 0
	    foreach systemName $systemNameList {
		set nameLength [string length $systemName]
		if {$nameLength > $maxNameLength} {
		    set maxNameLength $nameLength
		}
	    }
	    foreach systemName $systemNameList {
		append totalString "[format %-${maxNameLength}s $systemName] = [string map {\\ /} [$sessionHandle GetSystemVariable $systemName]]\n"
	    }
	    $sessionHandle ReleaseHandle
	}
	if {$infoVar == 0} {
	    append totalString "\n"
	}
	if {$infoVar == 0 || $infoVar == 3} {
	    append totalString "Tcl Platform Variables (command \"puts \$tcl_platform(<platformVariable>)\")\n"
	    append totalString "=========================================================================\n"
	    set platformNameList [lsort -dictionary [array names tcl_platform]]
	    set maxNameLength 0
	    foreach platformName $platformNameList {
		set nameLength [string length $platformName]
		if {$nameLength > $maxNameLength} {
		    set maxNameLength $nameLength
		}
	    }
	    set prefixString "\n[format %-${maxNameLength}s ""]   "
	    if {[string tolower $tcl_platform(platform)] == "windows"} {
		set separatorString "\;"
	    } else {
		set separatorString ":"
	    }
	    foreach platformName $platformNameList {
		set evalString "append totalString \[format %-${maxNameLength}s $platformName\] \" = \" \[string map \{ \\\\ \/ [set separatorString] \"[set prefixString]\" \} \[set tcl_platform($platformName)\]\]\\n"
		eval $evalString
	    }
	}
	return $totalString
    }

    # end SystemInfo #######################################################

    ########################################################################
    # To check if handle already exists,
    #
    # Return:
    #    Success/exists   = 0
    #    Error/not exists = 1

    lappend exportprocs Exist
    proc Exist { handle } {
	set handles [hwi ListAllHandles]
	if { [string match "*$handle*" $handles] } {
	    return 0
	}
	return 1
    }
    # end Exist ############################################################



    ########################################################################
    # To delete handle, if it exists, Sucess(0), NotExist(1)

    lappend exportprocs Release
    proc Release { handle } {
	catch {$handle ReleaseHandle}
    }
    # end Release ##########################################################


    ##
    # ::mvh::GetPageID - get page id from any handle except session and project
    #
    # description tbd.
    ##
    lappend exportprocs GetPageID
    ########################################################################
    proc GetPageID { handle } {
	set tmpStr [string replace $handle 0 [expr [string first "_page" $handle] + 4]]
	if {[string first "_" $tmpStr] != -1} {
	    set pageId [string replace $tmpStr [string first "_" $tmpStr] end]
	} else {
	    set pageId $tmpStr
	}
	return $pageId
    }
    # end GetPageID #######################################################


    ##
    # ::mvh::GetWindowID - get page id from any handle except session, project
    # or page handle
    #
    # description tbd.
    ##
    lappend exportprocs GetWindowID
    ########################################################################
    proc GetWindowID { handle } {
	set tmpStr [string replace $handle 0 [expr [string first "_window" $handle] + 6]]
	if {[string first "_" $tmpStr] != -1} {
	    set windowId [string replace $tmpStr [string first "_" $tmpStr] end]
	} else {
	    set windowId $tmpStr
	}
	return $windowId
    }
    # end GetWindowID #######################################################


    ##
    # ::mvh::GetCurveID - get curve id from any curve handle
    #
    # description tbd.
    ##
    lappend exportprocs GetCurveID
    ########################################################################
    proc GetCurveID { handle } {
	set tmpStr [string replace $handle 0 [expr [string first "_curve" $handle] + 5]]
	if {[string first "_" $tmpStr] != -1} {
	    set curveId [string replace $tmpStr [string first "_" $tmpStr] end]
	} else {
	    set curveId $tmpStr
	}
	return $curveId
    }
    # end GetCurveID #######################################################


    ##
    # ::mvh::GetUniquePageID - get sorted unique page list from handle list
    # or page handle
    #
    # description tbd.
    ##
    lappend exportprocs GetUniquePageID
    ########################################################################
    set possibleOptions(GetUniquePageID)  [list handleList]
    set mandatoryOptions(GetUniquePageID) [list handleList]

    proc GetUniquePageID { args } {
	array set opts [checkArgs $args GetUniquePageID]
	set handleList $opts(handleList)
	set pageList {}
	foreach handle $handleList {
	    set page   [GetPageID   $handle]
	    lappend pageList $page
	}
	set pageList [lsort -unique $pageList]
	return $pageList
    }
    # end GetUniquePageID #######################################################


    ##
    # ::mvh::GetPageWindowID - get page and window id from sorted handle list
    # or page handle
    #
    # description tbd.
    ##
    lappend exportprocs GetPageWindowID
    ########################################################################
    set possibleOptions(GetPageWindowID)  [list handleList uniqueWin]
    set mandatoryOptions(GetPageWindowID) [list handleList]

    proc GetPageWindowID { args } {
	array set opts [checkArgs $args GetPageWindowID]
	if { ![info exist opts(uniqueWin)] } {
	    set uniqueWin 0
	} else {
	    set uniqueWin $opts(uniqueWin)
	}
	set handleList $opts(handleList)
	set pageWinList {}
	set tmpWinList {}
	set pageCount [GetPageID [lindex $handleList 0]]
	set count 0
	foreach handle $handleList {
	    incr count
	    set page   [GetPageID   $handle]
	    set window [GetWindowID $handle]
	    if {$count == 1} {
		set tmpList  $page
		set tmpWinList $window
	    }
	    if {$page != $pageCount && $count > 1} {
		if {!$uniqueWin} {
		    lappend pageWinList [list $tmpList $tmpWinList]
		} elseif {$uniqueWin} {
		    lappend pageWinList [list $tmpList [lsort -unique $tmpWinList]]
		}
		set tmpList $page
		set tmpWinList {}
		set pageCount $page
	    }
	    if {$count > 1} {
		lappend tmpWinList $window
	    }
	}
	if {!$uniqueWin} {
	    lappend pageWinList [list $tmpList $tmpWinList]
	} elseif {$uniqueWin} {
	    lappend pageWinList [list $tmpList [lsort -unique $tmpWinList]]
	}
	return $pageWinList
    }
    # end GetPageWindowID #######################################################


    ##
    # ::mvh::GetSession - get the session handle
    #
    # \h1 Arguments:
    # \h2 mandatory Arguments:
    #
    #       None
    # \h2 optional Arguments:
    #
    #       None
    # \h1 Returns:
    #
    #       Returns the session handle
    #
    # \h1 Description:
    #
    # This procedure returns the session handle of HyperGraph \/ HyperView \/ MotionView.
    # No arguments are applied to this procedure.
    ##
    lappend exportprocs GetSession
    ########################################################################
    proc GetSession { } {
	variable curNs
	set ses "${curNs}::handle_session"
	Release $ses
	set session [hwi GetSessionHandle $ses]
	# result
	if { $ses == $session } {
	    return $session
	} else {
	    error "Error in GetSession"
	}
    }
    # end GetSession #######################################################


    ##
    # ::mvh::GetProject - get the project handle
    #
    # \h1 Arguments:
    # \h2 mandatory Arguments:
    #
    #       None
    # \h2 optional Arguments:
    #
    #       None
    # \h1 Returns:
    #
    #       Returns the project handle
    #
    # \h1 Description:
    #
    # This procedure returns the project handle of HyperGraph \/ HyperView \/ MotionView.
    # No arguments are applied to this procedure.
    ##
    lappend exportprocs GetProject
    ########################################################################
    proc GetProject { } {

	variable curNs
	set proj "${curNs}::handle_project"
	Release $proj
	set session [GetSession]
	set result [$session GetProjectHandle $proj]
	if { $result == $proj } {
	    return $result
	} else {
	    error "Error in GetProject"
	}
    }
    # end GetProject #######################################################


    ##
    # ::mvh::GetPage - get a page handle
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    # \h2 -page "pageID"
    #
    # the page ID of the requested page.
    # \h2 -byHandle "handle"
    #
    # a handle created with this tools and which contains a page id
    # \h1 Returns:
    #
    #       Returns a page handle
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a page handle of HyperGraph \/ HyperView \/ MotionView.
    # If no page is requested then it returns the page handle of the current \/ active
    # page.
    #
    # The option "-byHandle" is an exclusiv option (no other minus options are allowed)
    ##
    set possibleOptions(GetPage) [list page byHandle]
    set exclusiveOptions(GetPage) [list [list page] [list byHandle] [list ]]
    lappend exportprocs GetPage
    ########################################################################
    proc GetPage { args } {

	variable curNs
	array set opts [checkArgs $args GetPage]

	set pro [GetProject]
	set numberOfPages [$pro GetNumberOfPages]
	set pIndex [$pro GetActivePage]
	if { [info exists opts(page)] }  {
	    set pIndex $opts(page)
	}
	if { [info exists opts(byHandle)] }  {
	    set pIndex [GetPageID $opts(byHandle)]
	}
	if { $pIndex > $numberOfPages } {
	    error "Page $opts(page) doesn't exist"
	}
	set page "${curNs}::handle_page$pIndex"
	Release $page
	## result
	set result [$pro GetPageHandle $page $pIndex]
	if { $result == $page } {
	    return $result
	} else {
	    error "Error in GetPage"
	}
    }
    # end GetPage #######################################################

    ##
    # ::mvh::GetWindow - get a window handle
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    # \h2 -page "pageID"
    #
    # the page ID of the requested page.
    # \h2 -window "windowID"
    #
    # the window ID of the requested window
    # \h2 -byHandle "handle"
    #
    # a handle created with this tools and which contains a page and window id
    # \h1 Returns:
    #
    #       Returns a window handle
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a window handle of HyperGraph \/ HyperView \/ MotionView.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it retrun the active window of the requested
    # (or active) page.
    #
    # The option "-byHandle" is an exclusiv option (no other minus options are allowed)
    ##
    set possibleOptions(GetWindow) [list window page byHandle]
    set exclusiveOptions(GetWindow) [list [list ]]
    set mandatoryOptions(GetWindow) [list ]
    lappend exportprocs GetWindow
    ########################################################################
    proc GetWindow { args } {

	variable curNs
	array set opts [checkArgs $args GetWindow]
	# Get projecthandle
	set pro [GetProject]
	# Check if opts page exist and if it right
	set pIndex [$pro GetActivePage]
	if { [info exists opts(page)] } {
	    set pIndex $opts(page)
	}
	if {[info exists opts(byHandle)]} {
	    set pIndex [GetPageID $opts(byHandle)]
	}
	set nOfP [$pro GetNumberOfPages]
	if { $pIndex > $nOfP } {
	    error "Page $pIndex doesn't exist"
	}

	# get pagehandle
	set page [GetPage -page $pIndex]
	# Check if opts window exist and if it is right
	set wIndex [$page GetActiveWindow]
	if { [info exists opts(window)] } {
	    set wIndex $opts(window)
	    
	}
	if { [info exists opts(byHandle)] }  {
	    set wIndex [GetWindowID $opts(byHandle)]
	}
	set nOfW [$page GetNumberOfWindows]
	if { $wIndex > $nOfW } {
	    error "Window $opts(window) doesn't exist in page $pIndex" 
	}

	set winT "$page"
	append winT "_window$wIndex"
	Release $winT
	# result
	set result [$page GetWindowHandle $winT $wIndex]
	if { $result == $winT } {
	    return $result
	} else { error "error in GetWindow" }
    }
    # end GetWindow #####################################################


    ##
    # ::mvh::GetClient - get a client handle
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    # \h2 -page "pageID"
    #
    # the page ID of the requested page.
    # \h2 -window "windowID"
    #
    # the window ID of the requested window
    # \h2 -type "client type"
    #
    # a client type. The requested client will be checked for this
    # client type. If this check fails, an error will raised.
    # \h2 -byHandle "handle"
    #
    # a handle created with this tools and which contains a page and window id
    # \h1 Returns:
    #
    #       Returns a client handle
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a client handle of HyperGraph \/ HyperView \/ MotionView.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns the client of the active window.
    #
    # The GetClient function can check for a particular client type. To do this use the
    # option "-type". If the check fails then an error will be produced.
    #
    # The option "-byHandle" is an exclusiv option (no other minus options are allowed)
    ##
    set possibleOptions(GetClient) [list window page type byHandle]
    set exclusiveOptions(GetClient) [list [list ]]
    set mandatoryOptions(GetClient) [list ]
    lappend exportprocs GetClient
    ########################################################################
    proc GetClient { args } {

	variable curNs
	array set opts [checkArgs $args GetClient]

	# get windowhandle
	if { [info exists opts(byHandle)] }  {
	    set pIndex [GetPageID $opts(byHandle)]
	    set wIndex [GetWindowID $opts(byHandle)]
	    set getWinCmd "set window \[GetWindow -page $pIndex -window $wIndex\]"
	} else {
	    set getWinCmd "set window \[GetWindow"
	    foreach opt [list "window" "page"] {
		if {[info exists opts($opt)]} {
		    append getWinCmd " -${opt} \"$opts($opt)\""
		}
	    }
	    append getWinCmd "\]"
	}
	eval $getWinCmd

	set type [$window GetClientType]
	if {[info exists opts(type)]} {
	    if {[string tolower $type] != [string tolower $opts(type)]} {
		error "GetClient: The window $window has the wrong client type $type.\nThe expected client type was $opts(type)."
	    }
	}
	set clientT "$window"
	append clientT "_[string tolower $type 0 end]"
	Release $clientT
	# result
	set result [$window GetClientHandle $clientT]
	if { $result == $clientT } {
	    return $result
	} else {
	    error "error in GetClient"
	}
    }
    # end GetClient #####################################################


    ##
    # ::mvh::GetMovie - get a movie handle
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    # \h2 -page "pageID"
    #
    # the page ID of the requested page.
    # \h2 -window "windowID"
    #
    # the window ID of the requested window
    # \h2 -id "the movie id"
    #
    # default 1
    # \h1 Returns:
    #
    #       Returns a movie handle
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a movie handle of HyperGraph \/ HyperView \/ MotionView.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns the client of the active window.
    #
    # The GetClient function can check for a particular client type. To do this use the
    # option "-type". If the check fails then an error will be produced.
    #
    # The option "-byHandle" is an exclusiv option (no other minus options are allowed)
    ##
    set possibleOptions(GetMovie) [list window page id]
    set exclusiveOptions(GetMovie) [list [list ]]
    set mandatoryOptions(GetMovie) [list ]
    lappend exportprocs GetMovie
    ########################################################################
    proc GetMovie { args } {

	variable curNs
	array set opts [checkArgs $args GetMovie]

	# get windowhandle
	set getClientCmd "set client \[GetClient"
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getClientCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getClientCmd "\]"
	eval $getClientCmd
	
	if {![info exists opts(id)]} {
	    set opts(id) 1
	}

	# check the number of movies
	set numberOfMovies [$client GetNumberOfMovies]
	if {$opts(id) > $numberOfMovies} {
	    set msg "There is no movie with number $opts(id) in client $client"
	    error msg
	}
	set movieT "$client"
	append movieT "_movie$opts(id)"
	Release $movieT
	# result
	set result [$client GetMovieHandle $movieT $opts(id)]
	if { $result == $movieT } {
	    return $result
	} else {
	    error "error in GetMovie"
	}
    }
    # end GetMovie #####################################################

    ##
    # ::mvh::GetViewControl - get a ViewControl handle of a window
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    # \h1 Returns:
    #
    #       Returns a ViewControl handle of a window
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a ViewControl handle of HyperGraph \/ HyperView \/ MotionView.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns the ViewControl of the active window.
    ##
    lappend exportprocs GetViewControl
    set possibleOptions(GetViewControl) [list window page]
    ########################################################################
    proc GetViewControl { args } {

	variable curNs
	array set opts [checkArgs $args GetViewControl]

	# get windowhandle
	set getWinCmd "set window \[GetWindow"
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getWinCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getWinCmd "\]"
	eval $getWinCmd

	set view "$window"
	append view "_viewControll"
	Release $view
	## result
	set result [$window GetViewControlHandle $view]
	if { $result == $view } {
	    return  $result
	} else { error "error in GetViewControl" }
    }
    # end GetViewControl #####################################################



    ##
    # ::mvh::GetDataFileHandle - get a File handle
    #
    # \h1 mandatory Arguments:
    #   \h2 -file "Filename"
    #
    #     the requested Filename to the handle
    # \h1 optional Arguments:
    #   \h2 -unique "true/false"
    #
    #     create unique handle name
    #
    # \h1 Returns:
    #
    #       Returns a File handle
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    #
    ##
    set possibleOptions(GetDataFileHandle)  [list file unique]
    set mandatoryOptions(GetDataFileHandle) [list file]
    lappend exportprocs GetDataFileHandle
    ########################################################################
    proc GetDataFileHandle { args } {

	variable curNs
	array set opts [checkArgs $args GetDataFileHandle]
	if { [info exists opts(unique)] }  {
	    if {$opts(unique)} {
		set handleExtension "_[delSpecialCharacters -text [file tail $opts(file)]]_[string range [clock clicks] 1 end]"
	    } else {
		set handleExtension ""
	    }
	} else {
	    set handleExtension ""
	}
	set fileH "${curNs}::handle_file${handleExtension}"
	Release $fileH
	set ses [GetSession]
	## result
	set result [$ses GetDataFileHandle $fileH $opts(file)]
	if { $result == $fileH } {
	    return $result
	} else { error "error in GetDataFileHandle" }
    }
    # end GetDataFileHandle #####################################################



    ##
    # ::mvh::GetNote - get a note handle of a window
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    #   \h2 -note "noteID"
    #
    #     the note ID of the requested note
    # \h1 Returns:
    #
    #       Returns a note handle of a window
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a note handle of HyperGraph.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    ##
    lappend exportprocs GetNote
    set possibleOptions(GetNote) [list note window page clientHandle]
    ########################################################################
    proc GetNote { args } {
	variable curNs
	array set opts [checkArgs $args GetNote]

	if {[info exists opts(clientHandle)]} {
	    set client $opts(clientHandle)
	} else {
	    set getClientCmd "set client \[GetClient "
	    foreach opt [list "window" "page"] {
		if {[info exists opts($opt)]} {
		    append getClientCmd " -${opt} \"$opts($opt)\""
		}
	    }
	    append getClientCmd "\]"
	    eval $getClientCmd
	}
	set type [lindex [split $client "_"] end]
	if { $type == "animation" } {
	    set num [llength [$client GetNoteList]]
	} elseif { $type == "plot" || $type == "video"} {
	    set num [$client GetNumberOfNotes]
	} else {
	    error "note option doesn't exist in $client"
	}

	# Check opts note
	if { ![info exist opts(note)] } {   set opts(note) 1 }
	if { $opts(note) < 0 } {
            error "note id $opts(note) doesn't exist."
	}

	set noteT "$client"
	append noteT "_note$opts(note)"
	Release $noteT
	## result
	set result [$client GetNoteHandle $noteT $opts(note)]
	if { $result == $noteT } {
	    return $result
	} else { error "error in GetNote" }
    }
    # end GetNote #####################################################

    ##
    # ::mvh::GetAnimatorCtrl - get an animator handle of a page
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    # \h1 Returns:
    #
    #       Returns an animator handle of a page
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a note handle of HyperGraph / HyperView.
    # If no page ID is requested then it operates on the current \/ active
    # page.
    ##
    lappend exportprocs GetAnimatorCtrl
    set possibleOptions(GetAnimatorCtrl) [list page]
    ########################################################################
    proc GetAnimatorCtrl { args } {
	variable curNs
	array set opts [checkArgs $args GetNote]

	set getPageCmd "set page \[GetPage "
	foreach opt [list "page"] {
	    if {[info exists opts($opt)]} {
		append getPageCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getPageCmd "\]"
	eval $getPageCmd

	set animatorh "${page}_animator"

	# Check opts note

	Release $animatorh
	## result
	set result [$page GetAnimatorHandle $animatorh]
	if { $result == $animatorh } {
	    return $result
	} else {
	    error "error in GetNote"
	}
    }
    # end GetAnimatorCtrl #####################################################


    ### Revision Comments ##########
    # Date: 20.11.08 15:12 $
    # Revision: 1 $
    # Author: Ebeling $
    # History: plot.tcl $
    # 
    # *****************  Version 1  *****************
    # User: Ebeling      Date: 20.11.08   Time: 15:12
    # Created in $/Altair/CommonLibs/HyperWorks/gethandles/src
    # reorganized gethandles
    #
    ### End History ###############

    ##
    # ::mvh::plot::GetCurve - get a curve handle
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -clientHandle "plot client handle"
    #
    #     the handle (object reference to a plot client
    #   \h2 -curve "curveID"
    #
    #     the curve ID of the requested curve
    #   \h2 -mathRef "mathRef"
    #
    #     the math reference of the requested curve.
    #
    #     If this option is applied, then all other options will be ignored!
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    # \h1 Returns:
    #
    #       Returns a curve handle
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a curve handle of HyperGraph.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    #
    # If the option "mathRef" is applied, then it overrides all other options!
    ##
    set possibleOptions(GetCurve) [list curve window page mathRef clientHandle]
    lappend exportprocs GetCurve
    ########################################################################
    proc GetCurve { args } {
	variable curNs
	array set opts [checkArgs $args GetCurve]

	# process the mathRef option
	if { [info exist opts(mathRef)] } {
	    set pIndex [string first "p" $opts(mathRef)]
	    if { $pIndex == -1 } { error "error in mathRef $opts(mathRef)"  }
	    set wIndex [string first "w" $opts(mathRef)]
	    if { $wIndex == -1 || $pIndex > $wIndex} { error "error in mathRef $opts(mathRef)"  }
	    set cIndex [string first "c" $opts(mathRef)]
	    if { $cIndex == -1 || $wIndex > $cIndex} { error "error in mathRef $opts(mathRef)"  }
	    set endIndex [string first "." $opts(mathRef)]
	    if {$endIndex == -1} {
		set endIndex [string length $opts(mathRef)]
	    }
	    if { $endIndex == -1 || $cIndex > $endIndex} { error "error in mathRef $opts(mathRef)"  }
	    set opts(page) [string range $opts(mathRef) [expr $pIndex + 1] [expr $wIndex - 1]]
	    set opts(window) [string range $opts(mathRef) [expr $wIndex + 1] [expr $cIndex - 1]]
	    set opts(curve) [string range $opts(mathRef) [expr $cIndex + 1] [expr $endIndex - 1]]
	}

	if {[info exists opts(clientHandle)]} {
	    set client $opts(clientHandle)
	} else {
	    # get the client handle
	    set getClientCmd "set client \[GetClient -type \"plot\""
	    foreach opt [list "window" "page"] {
		if {[info exists opts($opt)]} {
		    append getClientCmd " -${opt} \"$opts($opt)\""
		}
	    }
	    append getClientCmd "\]"
	    eval $getClientCmd
	}
	set cIndex 1
	if { [info exist opts(curve)] } {
	    set nOfC [$client GetNumberOfCurves]
	    if { $opts(curve) <= $nOfC } {
		set cIndex $opts(curve)
	    } else { error "curve $opts(curve) doesn't exist" }
	}

	append curveT "$client"
	append curveT "_curve$cIndex"
	Release $curveT
	## result
	set result [$client GetCurveHandle $curveT $cIndex]
	if { $result == $curveT } {
	    return $result
	} else { error "error in GetCurve" }
    }
    # end GetCurve #####################################################



    ##
    # ::mvh::plot::GetVector - get a vector handle
    #
    # \h1 mandatory Arguments:
    #   \h2 -vector "vector type"
    #
    #     the vector type of the requested vector.
    #     Possible are "x" " " "time" and "category".
    # \h1 optional Arguments:
    #   \h2 -curve "curveID"
    #
    #     the curve ID of the requested curve
    #   \h2 -curveHandle "curve handle"
    #
    #     the curve handle of the requested curve
    #   \h2 -mathRef "mathRef"
    #
    #     the math reference of the requested curve.
    #
    #     If this option is applied, then all other options will be ignored!
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    # \h1 Returns:
    #
    #       Returns a vector handle of a specified curve
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a vector handle of HyperGraph.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    #
    # If the option "mathRef" is applied, then it overrides the options window and page!
    # There must be exact one of the options "curve" "mathRef" or "curveHandle" present.
    ##
    set possibleOptions(GetVector) [list vector curve window page mathRef curveHandle]
    set mandatoryOptions(GetVector) [list vector]
    set exclusiveOptions(GetVector) [list [list curve] [list mathRef] [list curveHandle]]
    lappend exportprocs GetVector
    ########################################################################
    proc GetVector { args } {
	variable curNs
	array set opts [checkArgs $args GetVector]
	# Check if option vector exists

	if { [info exist opts(vector)] } {
	    if { [string tolower $opts(vector)] == "x" ||    [string tolower $opts(vector)] == "y" || \
		     [string tolower $opts(vector)] == "time" || [string tolower $opts(vector)] == "category" ||\
		     [string tolower $opts(vector)] == "ym" || [string tolower $opts(vector)] == "yp" || \
		     [string tolower $opts(vector)] == "yr" || [string tolower $opts(vector)] == "yi" \
		 } {
		set vector [string toupper $opts(vector)]
	    } else {
		error "Unknown type $opts(vector) in GetVector"
	    }
	}

	if { [info exists opts(mathRef)] } {
	    set curve [GetCurve -mathRef "$opts(mathRef)"]
	}
	if { [info exists opts(curve)] } {
	    # First ini
	    set getCurveCmd "set curve \[GetCurve -curve \"$opts(curve)\""
	    foreach opt [list "window" "page"] {
		if {[info exists opts($opt)]} {
		    append getCurveCmd " -${opt} \"$opts($opt)\""
		}
	    }
	    append getCurveCmd "\]"
	    eval $getCurveCmd
	}
	if { [info exists opts(curveHandle)] } {
	    set curve $opts(curveHandle)
	}

	# Ini the curveHandle
	if { ![info exist vector] } {
	    set vector "x"
	}
	# ini name of handle
	set vectorT "$curve"
	append vectorT "_vector$vector"
	Release $vectorT
	## result
	set result [$curve GetVectorHandle $vectorT $vector]
	if { $result == $vectorT } {
	    return $result
	} else { error "error in GetVector" }
    }
    # end GetVector #####################################################





    ##
    # ::mvh::plot::GetPlotLegend - get a legend handle of a plot client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    # \h1 Returns:
    #
    #       Returns a legend handle of a plot client
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a legend handle of HyperGraph.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    ##
    lappend exportprocs GetPlotLegend
    set possibleOptions(GetPlotLegend) [list window page]
    ########################################################################
    proc GetPlotLegend { args } {
	variable curNs
	array set opts [checkArgs $args GetPlotLegend]

	set getClientCmd "set client \[GetClient -type \"plot\""
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getClientCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getClientCmd "\]"
	eval $getClientCmd

	set legend "$client"
	append legend "_legend"
	Release $legend

	## result
	set result [$client GetLegendHandle $legend]
	if { $result == $legend } {
	    return $result
	} else {
	    error "error in GetLegend"
	}
    }
    # end GetPlotLegend #####################################################


    ##
    # ::mvh::plot::GetVerticalDatum - get a header handle of a plot client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested datum line.
    #   \h2 -id "datumID"
    #
    #     the datum ID of the requested datum line.
    #
    # \h1 Returns:
    #
    #     Returns a header handle of a plot client
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a vertical datum handle of HyperGraph.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    ##
    lappend exportprocs GetVerticalDatum
    set possibleOptions(GetVerticalDatum) [list window page id]
    set mandatoryOptions(GetVerticalDatum) [list id]
    ########################################################################
    proc GetVerticalDatum { args } {
	variable curNs
	array set opts [checkArgs $args GetVerticalDatum]

	set getClientCmd "set client \[GetClient -type \"plot\""
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getClientCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getClientCmd "\]"
	eval $getClientCmd

	set vdatum "$client"
	append vdatum "_vdatum_$opts(id)"
	Release $vdatum

	## result
	set result [$client GetVerticalDatumHandle  $vdatum $opts(id)]
	if { $result == $vdatum } {
	    return $result
	} else {
	    error "error in GetVerticalDatum"
	}
    }
    # end GetVerticalDatum #####################################################


    ##
    # ::mvh::plot::GetHorizontalDatum - get a header handle of a plot client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested datum line.
    #   \h2 -id "datumID"
    #
    #     the datum ID of the requested datum line.
    #
    # \h1 Returns:
    #
    #     Returns a header handle of a plot client
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a vertical datum handle of HyperGraph.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    ##
    lappend exportprocs GetHorizontalDatum
    set possibleOptions(GetHorizontalDatum) [list window page id]
    set mandatoryOptions(GetHorizontalDatum) [list id]
    ########################################################################
    proc GetHorizontalDatum { args } {
	variable curNs
	array set opts [checkArgs $args GetHorizontalDatum]

	set getClientCmd "set client \[GetClient -type \"plot\""
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getClientCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getClientCmd "\]"
	eval $getClientCmd

	set vdatum "$client"
	append vdatum "_hdatum_$opts(id)"
	Release $vdatum

	## result
	set result [$client GetHorizontalDatumHandle  $vdatum $opts(id)]
	if { $result == $vdatum } {
	    return $result
	} else {
	    error "error in GetHorizontalDatum"
	}
    }
    # end GetHorizontalDatum #####################################################




    ##
    # ::mvh::plot::GetPlotHeader - get a header handle of a plot client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    # \h1 Returns:
    #
    #       Returns a header handle of a plot client
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a header handle of HyperGraph.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a plot header handle of the active window.
    ##
    lappend exportprocs GetPlotHeader
    set possibleOptions(GetPlotHeader) [list window page]
    ########################################################################
    proc GetPlotHeader { args } {
	variable curNs
	array set opts [checkArgs $args GetPlotHeader]

	set getClientCmd "set client \[GetClient -type \"plot\""
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getClientCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getClientCmd "\]"
	eval $getClientCmd

	set header "$client"
	append header "_header"
	Release $header

	## result
	set result [$client GetHeaderHandle $header]
	if { $result == $header } {
	    return $result
	} else {
	    error "error in GetPlotHeader"
	}
    }
    # end GetPlotHeader #####################################################


    ##
    # ::mvh::plot::GetPlotHeaderFont - get a header font handle of a plot client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -headerHandle "header handle"
    #
    #     an already existing handle of a plot header
    #   \h2 -line "line number"
    #
    #     the line number of the header must be one of {1, 2, 3}
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    # \h1 Returns:
    #
    #       Returns a header handle of a plot client
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a header font handle of HyperGraph.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    ##
    set possibleOptions(GetPlotHeaderFont) [list line headerHandle window page]
    lappend exportprocs GetPlotHeaderFont
    proc GetPlotHeaderFont {args } {
	variable curNs
	array set opts [checkArgs $args GetPlotHeaderFont]

	if {[info exists opts(headerHandle)]} {
	    set header $opts(headerHandle)
	} else {
	    set getHeaderCmd "set header \[GetPlotHeader"
	    foreach opt [list "window" "page"] {
		if {[info exists opts($opt)]} {
		    append getHeaderCmd " -${opt} \"$opts($opt)\""
		}
	    }
	    append getHeaderCmd "\]"
	    eval $getHeaderCmd
	}

	if {[info exists opts(line)]} {
	    set line $opts(line)
	} else {
	    set line 1
	}
	set fontHandle "${header}_font$line"
	Release $fontHandle

	if {$line == 1} {
	    set fonth [$header GetPrimaryFontHandle $fontHandle]
	} elseif {$line == 2} {
	    set fonth [$header GetSecondaryFontHandle $fontHandle]
	} elseif {$line == 3} {
	    set fonth [$header GetTertiaryFontHandle $fontHandle]
	} else {
	    error "GetPlotHeaderFont: the option line support only the arguments 1, 2 or 3! $line is not allowed"
	}

	return $fonth
    }
    ## end proc GetPlotHeaderFont


    ##
    # ::mvh::plot::GetPlotFooter - get a footer handle of a plot client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    # \h1 Returns:
    #
    #       Returns a header handle of a plot client
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a header handle of HyperGraph.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a plot footer handle of the active window.
    ##
    lappend exportprocs GetPlotFooter
    set possibleOptions(GetPlotFooter) [list window page]
    ########################################################################
    proc GetPlotFooter { args } {
	variable curNs
	array set opts [checkArgs $args GetPlotFooter]

	set getClientCmd "set client \[GetClient -type \"plot\""
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getClientCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getClientCmd "\]"
	eval $getClientCmd

	set footer "$client"
	append footer "_footer"
	Release $footer

	## result
	set result [$client GetFooterHandle $footer]
	if { $result == $footer } {
	    return $result
	} else {
	    error "error in GetPlotFooter"
	}
    }
    # end GetPlotFooter #####################################################


    ##
    # ::mvh::plot::GetPlotFooterFont - get a footer font handle of a plot client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -footerHandle "footer handle"
    #
    #     an already existing handle of a plot header
    #   \h2 -line "line number"
    #
    #     the line number of the header must be one of {1, 2, 3}
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    # \h1 Returns:
    #
    #       Returns a header handle of a plot client
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a header font handle of HyperGraph.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    ##
    set possibleOptions(GetPlotFooterFont) [list line footerHandle window page]
    lappend exportprocs GetPlotFooterFont
    proc GetPlotFooterFont {args } {
	variable curNs
	array set opts [checkArgs $args GetPlotFooterFont]

	if {[info exists opts(footerHandle)]} {
	    set footer $opts(footerHandle)
	} else {
	    set getFooterCmd "set footer \[GetPlotHeader"
	    foreach opt [list "window" "page"] {
		if {[info exists opts($opt)]} {
		    append getFooterCmd " -${opt} \"$opts($opt)\""
		}
	    }
	    append getFooterCmd "\]"
	    eval $getFooterCmd
	}

	if {[info exists opts(line)]} {
	    set line $opts(line)
	} else {
	    set line 1
	}
	set fontHandle "${footer}_font$line"
	Release $fontHandle

	if {$line == 1} {
	    set fonth [$footer GetPrimaryFontHandle $fontHandle]
	} elseif {$line == 2} {
	    set fonth [$footer GetSecondaryFontHandle $fontHandle]
	} elseif {$line == 3} {
	    set fonth [$footer GetTertiaryFontHandle $fontHandle]
	} else {
	    error "GetPlotFooterFont: the option line support only the arguments 1, 2 or 3! $line is not allowed"
	}

	return $fonth
    }
    ## end proc GetPlotFooterFont

    ##
    # ::mvh::plot::GetHorizontalAxis - get a axis handle of a plot client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    #   \h2 -axis "axisID"
    #
    #     the axis ID of the requested note
    # \h1 Returns:
    #
    #     Returns a horizontal axis handle of a plot client
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a horizontal axis handle of HyperGraph.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    # If no axis id specified, then the primary axis will be returned.
    ##
    lappend exportprocs GetHorizontalAxis
    set possibleOptions(GetHorizontalAxis) [list axis window page]
    ########################################################################
    proc GetHorizontalAxis { args } {
	variable curNs
	array set opts [checkArgs $args GetHorizontalAxis]

	set getClientCmd "set client \[GetClient -type \"plot\""
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getClientCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getClientCmd "\]"
	eval $getClientCmd

	# initialization
	set axisId 1
	# check axis option
	if { [info exist opts(axis)]  } {
	    if { $opts(axis) <= [$client GetNumberOfHorizontalAxes] } {
		set axisId $opts(axis)
	    } elseif { [$client GetNumberOfHorizontalAxes] <= $opts(axis) || $opts(axis) <= 0 } {
		error "Error in GetHorizontalAxis, axisId wrong"
	    }
	}

	set axisHandle "$client"
	append axisHandle "_horizontalAxis$axisId"
	Release $axisHandle

	# result
	set result [$client GetHorizontalAxisHandle $axisHandle $axisId]

	if { $result == $axisHandle } {
	    return  $result
	} else { error "error in GetHorizontalAxis" }
    }
    # end GetHorizontalAxis #####################################################




    ##
    # ::mvh::plot::GetVerticalAxis - get a axis handle of a plot client
    #
    # \h1 mandatory Arguments:
    # \h2 None
    # \h1 optional Arguments:
    #   \h2 -page "pageID"
    #
    #     the page ID of the requested page.
    #   \h2 -window "windowID"
    #
    #     the window ID of the requested window
    #   \h2 -axis "axisID"
    #
    #     the axis ID of the requested note
    # \h1 Returns:
    #
    #     Returns a vertical axis handle of a plot client
    #
    # \h1 Description:
    #
    # This procedure implements minus options!
    #
    # This procedure returns a vertical axis handle of HyperGraph.
    # If no page ID is requested then it operates on the current \/ active
    # page. If no window ID is given then it returns a note handle of the active window.
    # If no axis id specified, then the primary axis will be returned.
    ##
    lappend exportprocs GetVerticalAxis
    set possibleOptions(GetVerticalAxis) [list axis window page]
    ########################################################################
    proc GetVerticalAxis { args } {

	variable curNs
	array set opts [checkArgs $args GetVerticalAxis]

	set getClientCmd "set client \[GetClient -type \"plot\""
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getClientCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getClientCmd "\]"
	eval $getClientCmd

	# initialization
	set axisId 1
	# check axis option
	if { [info exist opts(axis)]  } {
	    if { $opts(axis) <= [$client GetNumberOfVerticalAxes] } {
		set axisId $opts(axis)
	    } elseif { [$client GetNumberOfVerticalAxes] <= $opts(axis) || $opts(axis) <= 0 } {
		error "Error in GetVerticalAxis, axisId wrong"
	    }
	}

	set axisHandle "$client"
	append axisHandle "_verticalAxis$axisId"
	Release $axisHandle
	## result
	set result [$client GetVerticalAxisHandle $axisHandle $axisId]

	if { $result == $axisHandle } {
	    return  $result
	} else { error "error in GetVerticalAxis" }
    }
    # end GetVerticalAxis #####################################################

    ### Revision Comments ##########
    # Date: 20.11.08 15:12 $
    # Revision: 1 $
    # Author: Ebeling $
    # History: plot3d.tcl $
    # 
    # *****************  Version 1  *****************
    # User: Ebeling      Date: 20.11.08   Time: 15:12
    # Created in $/Altair/CommonLibs/HyperWorks/gethandles/src
    # reorganized gethandles
    #
    ### End History ###############

    set possibleOptions(GetSurface) [list surf window page mathRef]
    lappend exportprocs GetSurface
    ########################################################################
    proc GetSurface { args } {

	variable curNs
	array set opts [checkArgs $args GetSurface]

	# process the mathRef option
	if { [info exist opts(mathRef)] } {
	    set pIndex [string first "p" $opts(mathRef)]
	    if { $pIndex == -1 } { error "error in mathRef $opts(mathRef)"  }
	    set wIndex [string first "w" $opts(mathRef)]
	    if { $wIndex == -1 || $pIndex > $wIndex} { error "error in mathRef $opts(mathRef)"  }
	    set sIndex [string first "s" $opts(mathRef)]
	    if { $sIndex == -1 || $wIndex > $sIndex} { error "error in mathRef $opts(mathRef)"  }
	    set endIndex [string first "." $opts(mathRef)]
	    if {$endIndex == -1} {
		set endIndex [string length $opts(mathRef)]
	    }
	    if { $endIndex == -1 || $sIndex > $endIndex} { error "error in mathRef $opts(mathRef)"  }
	    set opts(page) [string range $opts(mathRef) [expr $pIndex + 1] [expr $wIndex - 1]]
	    set opts(window) [string range $opts(mathRef) [expr $wIndex + 1] [expr $sIndex - 1]]
	    set opts(surf) [string range $opts(mathRef) [expr $sIndex + 1] [expr $endIndex - 1]]
	}

	# get the client handle
	set getClientCmd "set client \[GetClient -type \"plot3d\""
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getClientCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getClientCmd "\]"
	eval $getClientCmd

	set sIndex 1
	if { [info exist opts(surf)] } {
	    set nOfC [$client GetNumberOfSurfaces]
	    if { $opts(surf) <= $nOfC } {
		set sIndex $opts(surf)
	    } else { error "surf $opts(surf) doesn't exist" }
	}

	append surfT "$client"
	append surfT "_surf$sIndex"
	Release $surfT

	## result
	set result [$client GetSurfaceHandle $surfT $sIndex]
	if { $result == $surfT } {
	    return $result
	} else { error "error in GetSurf" }
    }
    # end GetSurf #####################################################

    set mandatoryOptions(GetSurfaceData) [list vector]
    set possibleOptions(GetSurfaceData)  [list vector surf window page mathRef]
    lappend exportprocs GetSurfaceData
    ########################################################################
    proc GetSurfaceData { args } {

	variable curNs
	array set opts [checkArgs $args GetSurfaceData]

	# process the mathRef option
	if { [info exist opts(mathRef)] } {
	    set pIndex [string first "p" $opts(mathRef)]
	    if { $pIndex == -1 } { error "error in mathRef $opts(mathRef)"  }
	    set wIndex [string first "w" $opts(mathRef)]
	    if { $wIndex == -1 || $pIndex > $wIndex} { error "error in mathRef $opts(mathRef)"  }
	    set sIndex [string first "s" $opts(mathRef)]
	    if { $sIndex == -1 || $wIndex > $sIndex} { error "error in mathRef $opts(mathRef)"  }
	    set endIndex [string first "." $opts(mathRef)]
	    if {$endIndex == -1} {
		set endIndex [string length $opts(mathRef)]
	    }
	    if { $endIndex == -1 || $sIndex > $endIndex} { error "error in mathRef $opts(mathRef)"  }
	    set opts(page) [string range $opts(mathRef) [expr $pIndex + 1] [expr $wIndex - 1]]
	    set opts(window) [string range $opts(mathRef) [expr $wIndex + 1] [expr $sIndex - 1]]
	    set opts(surf) [string range $opts(mathRef) [expr $sIndex + 1] [expr $endIndex - 1]]
	}

	# get the client handle
	set getClientCmd "set client \[GetClient -type \"plot3d\""
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getClientCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getClientCmd "\]"
	eval $getClientCmd

	set sIndex 1
	if { [info exist opts(surf)] } {
	    set nOfC [$client GetNumberOfSurfaces]
	    if { $opts(surf) <= $nOfC } {
		set sIndex $opts(surf)
	    } else { error "surf $opts(surf) doesn't exist" }
	}

	append surfT "$client"
	append surfT "_surf$sIndex"
	Release $surfT

	# get surface handle
	set surface [$client GetSurfaceHandle $surfT $sIndex]

	append datahandle "$surfT"
	append datahandle "_vector$opts(vector)"
	Release $datahandle
	## result
	set result [$surfT GetDataSourceHandle $datahandle $opts(vector)]
	if { $result == $datahandle } {
	    return $result
	} else { error "error in GetSurfaceData" }
    }
    # end GetSurfData #####################################################

    set mandatoryOptions(GetAxis) [list type]
    set possibleOptions(GetAxis)  [list type window page]
    lappend exportprocs GetAxis
    ########################################################################
    proc GetAxis { args } {

	variable curNs
	array set opts [checkArgs $args GetAxis]

	# get the client handle
	set getClientCmd "set client \[GetClient -type \"plot3d\""
	foreach opt [list "window" "page"] {
	    if {[info exists opts($opt)]} {
		append getClientCmd " -${opt} \"$opts($opt)\""
	    }
	}
	append getClientCmd "\]"
	eval $getClientCmd

	if { ![info exist opts(type)] } {
	    error "Axis type not given. Error in GetAxis"
	} else {
	    if { [lsearch [list x y z] $opts(type)] == -1 } {
		error "Error in GetAxis. Wrong type"
		#if
	    }
	    set type $opts(type)
	}

	append axisT "$client"
	append axisT "_axis$type"
	Release $axisT

	## result
	set result [$client GetAxisHandle $axisT $type]
	if { $result == $axisT } {
	    return $result
	} else { error "error in GetAxis" }
    }
    # end GetAxis #####################################################



    ### Revision Comments ##########
    # Date: 20.11.08 15:12 $
    # Revision: 1 $
    # Author: Ebeling $
    # History: string_functions.tcl $
    # 
    # *****************  Version 1  *****************
    # User: Ebeling      Date: 20.11.08   Time: 15:12
    # Created in $/Altair/CommonLibs/HyperWorks/gethandles/src
    # reorganized gethandles
    #
    ### End History ###############

    set possibleOptions(delSpecialCharacters)  [list text]
    set mandatoryOptions(delSpecialCharacters) [list text]
    lappend exportprocs delSpecialCharacters
    proc delSpecialCharacters { args } {
	array set opts [checkArgs $args delSpecialCharacters]
	set tmp $opts(text)
	#	set tmp [string map -nocase { ( "" ) "" : "" \\ _ / _ ~ ""   ae   oe   ue \" "" \' "" # "" * "" \  "" \` "" " " _   ss ? "" @ _at_ ; _ , _} $text]
	# map some characters
	set tmp [string map -nocase { \\ _ / _   ae   oe   ue   ss @ _at_ ; _ , _} $tmp]
	# puts $tmp
	# remove all special characters
	set tmp [regsub -all {[^a-zA-Z0-9_\s]} $tmp ""]
	# puts $tmp
	# replace empty spaces by under scores
	set tmp [regsub -all {\s+} $tmp "_"]
	#	set tmp2 [split $tmp {}]
	#	set tmp ""
	#	for {set i 0} {$i < [llength $tmp2]} {incr i} {
	#	    if {([string is alnum [lindex $tmp2 $i]]) || ([lindex $tmp2 $i] == "_")} {
	#	        set tmp "$tmp[lindex $tmp2 $i]"
	#	    }
	#	}
	return $tmp
    }



    foreach function $exportprocs {
        namespace export $function
    }

}

if {1 == 1} {
    # insert the following lines to import all functions to your current namespace

    set procs [info procs]
    foreach function $mvh::exportprocs {
        if {[lsearch $procs $function] == -1} {
            namespace import -force mvh::$function
        }
    }
}
