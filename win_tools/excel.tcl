catch {xlsOBJs destroy}
package require TclOO;
oo::class create xlsOBJs {
    variable vbsBOM sheetIndex;
    set vbsBOM "";
    set sheetIndex 1;
    constructor {{filename new} args} {
	my init;
	my createhead;
	my createXls [file native $filename];
	my selectSheet;
    }
    method init {args} {
	set vbsBOM "";
	set list_part [list "init" "createSheet" "selectSheet" "body1" "body2" "body3" "config"]
	foreach part $list_part {
	    append vbsBOM "''${part}''\n''end${part}''\n"
	}
    }


    method createhead {{visible 1} args} {
	append header "''init''\n"
	append header "Set objExcel = CreateObject(\"Excel.Application\")\n"
	append header "objExcel.DisplayAlerts = False\n"
	if {$visible!=0} {
	    append header "objExcel.Visible = True\n"
	} else {
	    append header "objExcel.Visible = False\n"
	}
	append header "''endinit''\n";
	regsub -- {''init''.*''endinit''} $vbsBOM $header vbsBOM;
    }

    method createXls {{pathToXls new} args} {
	append createSheet "''createSheet''\n"
	if ![file exist $pathToXls] {
	    append createSheet "Set objXls = objExcel.Workbooks.Add\n"
	} else {
	    append createSheet "Set objXls = objExcel.Workbooks.Open(\"$pathToXls\")\n";
	}
	append createSheet "''endcreateSheet''\n";
	regsub -- {''createSheet''.*''endcreateSheet''} $vbsBOM $createSheet vbsBOM;
    }
    method selectSheet {{index 1} args} {
	set sheetIndex $index;
	append selectSheet "''selectSheet''\n"
	append selectSheet "objExcel.WorkSheets($index).Activate\n"
	append selectSheet "set objSheet$index=objExcel.WorkSheets($index)\n"
	append selectSheet "''endselectSheet''\n"
	append selectSheet "''body$sheetIndex''\n"
	if {![regexp -- "''body$sheetIndex''.*''endbody$sheetIndex''" $vbsBOM]} {
	    append vbsBOM "''body$sheetIndex''\n''endbody$sheetIndex''\n"
	}
	regsub -- "''body$sheetIndex''" $vbsBOM $selectSheet vbsBOM;
    }

    method setCellValue {row col value} {
	append cellscript "\n";
	append cellscript "objExcel.Cells($row,$col).Value=\"$value\"\n"
	append cellscript "''endbody$sheetIndex''";
	regsub -- "''endbody$sheetIndex''" $vbsBOM $cellscript vbsBOM;
    }
    method setCellBackground {row col colorIndex} {
	append cellscript "\n";
	append cellscript "objExcel.Cells($row,$col).Interior.colorIndex=$colorIndex\n"
	append cellscript "''endbody$sheetIndex''";
	regsub -- "''endbody$sheetIndex''" $vbsBOM $cellscript vbsBOM;
    }
    method setColumnWidth {col {width 5}} {
	append configscript "\n"
	append configscript "objSheet$sheetIndex.Columns($col).ColumnWidth = $width \n"
	append configscript "''endconfig''";
	regsub -- "''endconfig''" $vbsBOM $configscript vbsBOM;
    }

    method setRowHeight {row {height 2}} {
	append configscript "\n"
	append configscript "objSheet$sheetIndex.Rows($col).RowHeight = $height \n"
	append configscript "''endconfig''";
	regsub -- {''endconfig''} $vbsBOM $configscript vbsBOM;
    }

    method run {args} {
	set file_dir .
	if [info exist ::env(TEMP)] {
	    set file_dir $::env(TEMP);
	}
	set code [encoding system];


	set file_name [file join $file_dir "xls-[clock seconds].vbs"] ;
	set fch [open $file_name w];
	puts $fch $vbsBOM;
	close $fch;
	exec wscript "$file_name";
	# catch {file delete -force $file_name;}
    }



    method showBOM {args} {
	puts $vbsBOM;
    }
}


proc Exceltest {args} {
    set excel [xlsOBJs new];
    foreach k {1 2 3} {
	$excel selectSheet $k
	for {set i 1} {$i<11} {incr i} {
	    for {set j 1} {$j<11} {incr j} {
		$excel setCellValue $i $j [expr $i + $j];
		$excel setCellBackground $i $j [expr ($i+$j)%4+5];
	    }
	}
    }
    $excel run;
}



