namespace eval CmdState {
    variable show_saved
    variable show_unsaved
    variable show_deleted
    variable show_log_deleted
    variable search
    variable selected_id

    proc init {} {
        variable show_saved
        variable show_unsaved
        variable show_deleted
        variable show_log_deleted
        variable search
        variable selected_id
        set show_log_deleted 0
        set show_deleted 0
        set show_unsaved 1
        set show_saved 1
        set search ""
        set selected_id 1
        set show_list [CmdState::getShowList]
        set cmd [lindex $show_list 0]
        set selected_id [dict get $cmd id]
    }

    proc setSelectedId {id} {
        variable selected_id
        set selected_id $id
    }

    proc checkSelectedId {} {
        variable selected_id
        set show_list [CmdState::getShowList]
        set has_selected_id 0
        foreach cmd $show_list {
            if {$selected_id == [dict get $cmd id]} {
                set has_selected_id 1
            }
        }
        if {$has_selected_id == 0} {
            set cmd [lindex $show_list 0]
            CmdState::setSelectedId [dict get $cmd id]
        }
    }

    proc getShowList {} {
        variable selected_id
        variable show_saved
        variable show_unsaved
        variable show_deleted
        variable show_log_deleted
        variable search

        set show_list {}
        set n [llength $CmdData::commands]
        foreach cmd $CmdData::commands {
            set id [dict get $cmd id]
            set name [dict get $cmd current_name]
            set status [dict get $cmd current_status]
            if {$id == 0 && $id != $selected_id} {
                continue
            }
            if {$status eq $CmdData::STATUS_ERASED} {
                continue
            }
            if {$search ne "" && [string first $search $name] == -1} {
                continue
            }
            if {$status == $CmdData::STATUS_TEMP} {
                lappend show_list $cmd
                continue
            }
            if {$show_deleted == 1 && $status == $CmdData::STATUS_DELETED} {
                lappend show_list $cmd
                continue
            }
            if {$show_log_deleted == 1 && $status == $CmdData::STATUS_LOG_DELETED} {
                lappend show_list $cmd
                continue
            }
            if {$show_saved == 1 && $status == $CmdData::STATUS_SAVED} {
                lappend show_list $cmd
                continue
            }
            if {$show_unsaved == 1 && $status == $CmdData::STATUS_UNSAVED} {
                lappend show_list $cmd
                continue
            }
        }
        if {[llength $show_list] == 0} {
            lappend show_list [CmdData::newEmptyCommand]
        }
        proc compareFn {a b} {
            set name_a [dict get $a name]
            set name_b [dict get $b name]
            return [string compare $name_a $name_b]
        }
        set sorted_list [lsort -command compareFn $show_list]
        return $sorted_list
    }

    proc checkAndGetShowList {} {
        set show_list [CmdState::getShowList]
        CmdState::checkSelectedId
        return $show_list
    }

    proc checkAndGetSelectedIndex {} {
        variable selected_id
        set show_list [CmdState::checkAndGetShowList]
        set index 0
        foreach cmd $show_list {
            if {[dict get $cmd id] == $selected_id} {
                return $index
            }
            incr index
        }
        return $index
    }

    proc getSelectedCmd {} {
        variable selected_id
        return [CmdData::getOne $selected_id]
    }

    proc getCmdByIndex {index} {
        set show_list [CmdState::checkAndGetShowList]
        set n [llength $show_list]
        return [lindex $show_list $index]
    }

    proc onListOpenFile {filename} {
        CmdData::saveData
        CmdData::loadData $filename
        CmdMain::render
    }

    proc onListNew {} {
        set cmd [CmdData::addEmptyCommand]
        set id [dict get $cmd id]
        CmdState::setSelectedId $id
        CmdMain::render
    }

    proc onListSelect {id} {
        CmdState::setSelectedId $id
        CmdInfo::render
    }

    proc onListShowChanged {} {
        CmdMain::render
    }

    proc onListEraseDeleted {} {
        set commands [CmdState::checkAndGetShowList]
        CmdData::eraseDeletedCommands $commands
        CmdMain::render
    }

    proc onListEraseLogDeleted {} {
        set commands [CmdState::checkAndGetShowList]
        CmdData::eraseLogDeletedCommands $commands
        CmdMain::render
    }

    proc onListSearch {text} {
        variable search
        set search $text
        CmdMain::render
    }

    proc onInfoSave {cmd} {
        variable selected_id
        set cmd [CmdData::saveCommand $cmd]
        CmdState::setSelectedId [dict get $cmd id]
        CmdMain::render
    }

    proc onInfoDelete {} {
        variable selected_id
        set deleted_index [CmdState::checkAndGetSelectedIndex]
        CmdData::deleteCommand $selected_id
        set show_list [CmdState::checkAndGetShowList]
        set n [llength $show_list]
        if {$deleted_index == $n} {
            incr deleted_index -1
        }
        set cmd [CmdState::getCmdByIndex $deleted_index]
        CmdState::setSelectedId [dict get $cmd id]
        CmdMain::render
    }

    proc onInfoDuplicate {} {
        variable selected_id
        set cmd [CmdData::duplicateCommand $selected_id]
        CmdState::setSelectedId [dict get $cmd id]
        CmdMain::render
    }

    proc onInfoErase {} {
        variable selected_id
        set focus_index [CmdState::checkAndGetSelectedIndex]
        CmdData::eraseCommand $selected_id
        set show_list [CmdState::checkAndGetShowList]
        set n [llength $show_list]
        if {$focus_index == $n} {
            incr focus_index -1
        }
        set cmd [CmdState::getCmdByIndex $focus_index]
        CmdState::setSelectedId [dict get $cmd id]
        CmdMain::render
    }

    proc onInfoValueInput {cmd} {
        set status [dict get $cmd status]
        set current_status [dict get $cmd current_status]
        set changed [Util::cmdValueChanged $cmd]
        if {$changed} {
            dict set cmd current_status $CmdData::STATUS_UNSAVED
        } else {
            dict set cmd current_status $status
        }
        if {$changed || $current_status != [dict get $cmd current_status]} {
            CmdData::replaceCommand $cmd
            CmdList::render
            CmdInfo::renderScript
        }
    }

    proc onInfoRun {} {
        namespace eval RunCommand {
            variable output
            proc run {} {
                variable output
                set output ""
                proc puts {args} {
                    variable output
                    if {[llength $args] > 1 && [lindex $args 0] eq "-nonewline"} {
                        set text [lindex $args 1]
                        append output "\n$text"
                    } else {
                        set text [lindex $args 0]
                        append output "\n$text"
                    }
                }
                lassign [run_script] res err
                set output "Output(double click to hide):$output"
                if {$err != 0} {
                    append output "\n$res"
                }
                return $output
            }

            proc run_script {} {
                set cmd [CmdState::getSelectedCmd]
                set input_openfile [dict get $cmd input_openfile]
                set input_savefile [dict get $cmd input_savefile]
                set input_dir [dict get $cmd input_dir]
                set prefix "proc __cmd_manager_run__ {} {"
                if {$input_openfile ne ""} {
                    append prefix "\nset OpenFile \"$input_openfile\"\n"
                }
                if {$input_savefile ne ""} {
                    append prefix "\nset SaveFile \"$input_savefile\"\n"
                }
                if {$input_dir ne ""} {
                    append prefix "set Dir \"$input_dir\"\n"
                }
                set script "$prefix[CmdInfo::getScript]}; __cmd_manager_run__"
                set err [catch {eval $script} res]
                return [list $res $err]
            }
        }
        set output [RunCommand::run]
        set cmd [CmdState::getSelectedCmd]
        dict set cmd output $output
        CmdData::replaceCommand $cmd
        CmdInfo::renderScriptOutput
    }
}