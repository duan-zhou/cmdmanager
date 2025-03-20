namespace eval CmdData {
    variable filepath
    variable max_id
    variable commands {}
    variable STATUS_SAVED
    variable STATUS_TEMP
    variable STATUS_DELETED
    variable STATUS_LOG_DELETED
    variable STATUS_ERASED
    set max_id 0
    set STATUS_SAVED "Saved"
    set STATUS_UNSAVED "Unsaved"
    set STATUS_TEMP "Temp"
    set STATUS_DELETED "Deleted"
    set STATUS_LOG_DELETED "LogDeleted"
    set STATUS_ERASED "Erased"

    proc init {} {
        variable filepath
        variable commands
        set dir [file normalize "~"]
        set filepath "$dir/commands.txt"
        CmdData::loadData  $filepath
    }

    proc getOne {id} {
        variable commands
        foreach cmd $commands {
            if {$id == [dict get $cmd id]} {
                return $cmd
            }
        }
        return
    }

    proc getFirst {} {
        variable commands
        return [lindex $commands 0]
    }

    proc maxNameLength {} {
        variable commands
        set maxLength 0
        foreach cmd $commands {
            set name [dict get $cmd name]
            set length [string length $name]
            if {$length > $maxLength} {
                set maxLength $length
            }
        }
        return $maxLength
    }

    proc loadData {path} {
        variable filepath
        variable commands
        set commands {}
        CmdData::addEmptyCommand
        if {[info exists path]} {
            set filepath $path
        }
        set tag "__vmd_cmd"
        set name_tag "__name__:"
        set desc_tag "__desc__:"
        set status_tag "__status__:"
        set script_tag "__script__:"
        set unsaved_tag "__unsaved_script__:"
        if {[catch {open $filepath r} file]} {
            return -1
        }
        set content [read $file]
        close $file
        set flag "\u0001"
        set tmp_text [string map [list $tag $flag] $content]
        set blocks [split $tmp_text $flag]
        set name ""
        set desc ""
        set status ""
        set script ""
        set unsaved_script ""
        foreach block $blocks {
            if {[string trim $block] eq ""} {
                continue
            }
            if {[regexp "${name_tag}(.*)" $block -> name]} {
                set name [string trim $name]
                set desc ""
                set status ""
                set script ""
                set unsaved_script ""
            }
            if {[regexp "${desc_tag}(.*)" $block -> desc]} {
                set desc [string trim $desc]
                set status ""
                set script ""
                set unsaved_script ""
            }
            if {[regexp "${status_tag}(.*)" $block -> status]} {
                set status [string trim $status]
                set unsaved_script ""
                set script ""
            }
            if {[regexp "${unsaved_tag}(.*)" $block -> unsaved_script]} {
                set unsaved_script [string trim $unsaved_script]
                set script ""
            }
            if {[regexp "${script_tag}(.*)" $block -> script]} {
                if {$status eq $CmdData::STATUS_TEMP && $unsaved_script eq ""} {
                    continue
                }
                if {$status eq ""} {
                    set status $CmdData::STATUS_SAVED
                }
                set script [string trim $script]
                if {$name ne "" && $script ne ""} {
                    set cmd [CmdData::addEmptyCommand]
                    dict set cmd name $name
                    dict set cmd desc $desc
                    dict set cmd script $script
                    dict set cmd status $status
                    set cmd [Util::cmdValueToCurrent $cmd]
                    if {$unsaved_script ne ""} {
                        dict set cmd current_status $CmdData::STATUS_UNSAVED
                        dict set cmd current_script $unsaved_script
                    }
                    CmdData::replaceCommand $cmd
                }
            }
        }
    }

    proc saveData {} {
        variable filepath
        variable commands
        set tag "__vmd_cmd"
        set name_tag "__name__:"
        set desc_tag "__desc__:"
        set status_tag "__status__:"
        set script_tag "__script__:"
        set unsaved_tag "__unsaved_script__:"
        set file [open $filepath w]
        foreach cmd $commands {
            set current_status [string trim [dict get $cmd current_status]]
            if {$current_status == $CmdData::STATUS_TEMP} {
                continue
            }
            if {$current_status == $CmdData::STATUS_ERASED} {
                continue
            }
            set name [string trim [dict get $cmd name]]
            set desc [string trim [dict get $cmd desc]]
            set status [string trim [dict get $cmd status]]
            set script [string trim [dict get $cmd script]]
            set block "${tag}${name_tag}${name}\n"
            append block "${tag}${desc_tag}${desc}\n"
            append block "${tag}${status_tag}${status}\n"
            if {$current_status eq $CmdData::STATUS_UNSAVED} {
                set unsaved_script [dict get $cmd current_script]
                append block "${tag}${unsaved_tag}${unsaved_script}\n"
            }
            append block "${tag}${script_tag}${script}\n"
            puts -nonewline $file $block
        }
        close $file
        return 1
    }

    proc newEmptyCommand {} {
        set cmd [dict create]
        dict set cmd id 0
        dict set cmd name "name"
        dict set cmd desc "description"
        dict set cmd script "puts \"hello\""
        dict set cmd status $CmdData::STATUS_TEMP
        dict set cmd input_openfile ""
        dict set cmd input_savefile ""
        dict set cmd input_dir ""
        dict set cmd output ""
        set cmd [Util::cmdValueToCurrent $cmd]
        return $cmd
    }

    proc addEmptyCommand {} {
        variable commands
        variable max_id
        set cmd [CmdData::newEmptyCommand]
        dict set cmd id $max_id
        lappend commands $cmd
        incr max_id 1
        return $cmd
    }

    proc replaceCommand {cmd} {
        variable commands
        set i 0
        set id [dict get $cmd id]
        foreach item $commands {
            if {$id == [dict get $item id]} {
                set commands [lreplace $commands $i $i $cmd]
                break
            }
            incr i
        }
    }

    proc saveCommand {cmd} {
        variable commands
        set status [dict get $cmd status]
        set changed [Util::cmdValueChanged $cmd]
        if {!$changed} {
            dict set cmd status $CmdData::STATUS_SAVED
            set cmd [Util::cmdValueToCurrent $cmd]
            CmdData::replaceCommand $cmd
            CmdData::saveData
            return $cmd
        }
        set new_cmd [CmdData::addEmptyCommand]
        set new_id [dict get $new_cmd id]
        set new_cmd $cmd
        dict set new_cmd id $new_id
        dict set new_cmd status $CmdData::STATUS_SAVED
        set new_cmd [Util::cmdCurrentToValue $new_cmd]
        CmdData::replaceCommand $new_cmd
        if {$status ne $CmdData::STATUS_DELETED} {
            dict set cmd status $CmdData::STATUS_LOG_DELETED
        }
        set cmd [Util::cmdValueToCurrent $cmd]
        CmdData::replaceCommand $cmd
        CmdData::saveData
        return $new_cmd
    }

    proc duplicateCommand {id} {
        variable commands
        set cmd [CmdData::getOne $id]
        set empty_cmd [CmdData::addEmptyCommand]
        dict set cmd id [dict get $empty_cmd id]
        set name [dict get $cmd name]
        dict set cmd name "$name duplicate"
        dict set cmd status $CmdData::STATUS_UNSAVED
        set cmd [Util::cmdValueToCurrent $cmd]
        CmdData::replaceCommand $cmd
        return $cmd
    }

    proc deleteCommand {id} {
        variable commands
        if {$id == 0} {
            return
        }
        set cmd [CmdData::getOne $id]
        dict set cmd status $CmdData::STATUS_DELETED
        set cmd [Util::cmdValueToCurrent $cmd]
        CmdData::replaceCommand $cmd
        CmdData::saveData
        return
    }

    proc eraseCommand {erase_id} {
        variable commands
        if {$erase_id == 0} {
            set cmd [Util::cmdValueToCurrent $cmd]
            CmdData::replaceCommand $cmd
            return
        }
        set cmd [CmdData::getOne $erase_id]
        if {![info exists cmd]} {
            return
        }
        set status [dict get $cmd status]
        set current_status [dict get $cmd current_status]
        set keep false
        if {$current_status == $CmdData::STATUS_UNSAVED} {
            set cmd [Util::cmdValueToCurrent $cmd]
            if {$status != $CmdData::STATUS_TEMP} {
                set keep true
            }
        }
        if {!$keep} {
            dict set cmd status $CmdData::STATUS_ERASED
            dict set cmd current_status $CmdData::STATUS_ERASED
        }
        CmdData::replaceCommand $cmd
        CmdData::saveData
        return $cmd
    }

    proc eraseCommands {erase_status commands} {
        foreach cmd $commands {
            set status [dict get $cmd current_status]
            if {$status ne $erase_status} {
                continue
            }
            set id [dict get $cmd id]
            CmdData::eraseCommand $id
        }
        CmdData::saveData
        return
    }

    proc eraseDeletedCommands {commands} {
        CmdData::eraseCommands $CmdData::STATUS_DELETED $commands
    }

    proc eraseLogDeletedCommands {commands} {
        CmdData::eraseCommands $CmdData::STATUS_LOG_DELETED $commands
    }
}