if [namespace exist READDATA] {
    namespace delete READDATA;
}
namespace eval READDATA {
    
    proc getDataFromFile {filename} {
	set tag [clock microseconds];
	hwi OpenStack;
	hwi GetSessionHandle sess-$tag;
	sess-$tag GetDatafileHandle datafile-$tag $filename;
	set reqlist [datafile-$tag GetRequstList {Global Variables}];
	set complist [datafile-$tag GetComponentList {Global Variables}];
	
	
	
	hwi CloseStack;
    }
    
    
}



proc test {args} {
    hwi OpenStack
    hwi GetSessionHandle sess1
    sess1 GetDataFileHandle datafile "D:/export.csv"
    set v_name [datafile GetDataTypeList ]
    set v [lindex $v_name 0];
    set reqlist [datafile GetRequestList ${v}]
    set complist [datafile GetComponentList ${v}]
    set metadatalist [datafile GetChannelMetaDataList ${v} [lindex $reqlist 0] [lindex $complist 0]]
    set a [datafile GetChannelMetaDataValue ${v} [lindex $reqlist 0] [lindex $complist 0] [lindex $metadatalist 0]]
    set b [datafile GetChannelMetaDataValue ${v} [lindex $reqlist 0] [lindex $complist 0] [lindex $metadatalist 1]]
    set c [datafile GetChannelMetaDataLabel ${v} [lindex $reqlist 0] [lindex $complist 0] [lindex $metadatalist 0]]
    set d [datafile GetChannelMetaDataType ${v} [lindex $reqlist 0] [lindex $complist 0] [lindex $metadatalist 0] ]
    hwi CloseStack;
    return [list $a $b $c $d];
}
