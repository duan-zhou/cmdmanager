namespace eval Util {
    proc cmdValueToCurrent {cmd} {
        set name [dict get $cmd name]
        set desc [dict get $cmd desc]
        set script [dict get $cmd script]
        set status [dict get $cmd status]
        dict set cmd current_name $name
        dict set cmd current_desc $desc
        dict set cmd current_script $script
        dict set cmd current_status $status
        return $cmd
    }

    proc cmdCurrentToValue {cmd} {
        set current_name [dict get $cmd current_name]
        set current_desc [dict get $cmd current_desc]
        set current_script [dict get $cmd current_script]
        set current_status [dict get $cmd current_status]
        dict set cmd name $current_name
        dict set cmd desc $current_desc
        dict set cmd script $current_script
        dict set cmd status $current_status
        return $cmd
    }

    proc cmdValueChanged {cmd} {
        set name [dict get $cmd name]
        set desc [dict get $cmd desc]
        set script [dict get $cmd script]
        set current_name [dict get $cmd current_name]
        set current_desc [dict get $cmd current_desc]
        set current_script [dict get $cmd current_script]
        if {[string trim $name] != [string trim $current_name]} {
            return true
        }
        if {[string trim $desc] != [string trim $current_desc]} {
            return true
        }
        if {[string trim $script] != [string trim $current_script]} {
            return true
        }
        return false
    }

    proc haveMetaVariables {script} {
        set has_openfile false
        set has_savefile false
        set has_dir false
        set pattern "\\\$OpenFile(\[_a-zA-Z0-9\]*)"
        if {[regexp $pattern $script -> postfix]} {
            if {$postfix eq ""} {
                set has_openfile true
            }
        }
        set pattern "\\\$SaveFile(\[_a-zA-Z0-9\]*)"
        if {[regexp $pattern $script -> postfix]} {
            if {$postfix eq ""} {
                set has_savefile true
            }
        }
        set pattern "\\\$Dir(\[_a-zA-Z0-9\]*)"
        if {[regexp $pattern $script -> postfix]} {
            if {$postfix eq ""} {
                set has_dir true
            }
        }
        return [list $has_openfile $has_savefile $has_dir]
    }

    proc shortenPath {path maxLength} {
        if {[string length $path] <= $maxLength} {
            return $path
        }
        set sideLength [expr {($maxLength - 3) / 2}]
        set startPart [string range $path 0 [expr {$sideLength - 1}]]
        set endPart [string range $path end-[expr {$sideLength - 1}] end]
        return "${startPart}...${endPart}"
    }

    proc dictIsEqual {dict1 dict2} {
        if {[dict size $dict1] != [dict size $dict2]} {
            return false
        }
        foreach {key value} [dict getall $dict1] {
            if {![dict exists $dict2 $key] || [dict get $dict2 $key] ne $value} {
                return false
            }
        }
        return true
    }
}