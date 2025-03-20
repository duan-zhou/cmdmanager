namespace eval CmdInfo {
    variable f
    variable fmenu
    variable fname_desc
    variable fscript
    variable render_cmd
    variable rerender
    variable forget_output

    proc new {f_info} {
        variable f
        variable fmenu
        variable fname_desc
        variable fscript
        variable render_cmd
        variable rerender
        variable forget_output
        set f $f_info
        set render_cmd [dict create]
        set rerender false
        set forget_output true
        set fmenu [frame $f.fmenu -relief groove -borderwidth 2]
        grid $fmenu -row 0 -column 0 -sticky ew
        set fname_desc [frame $f.fname_desc -relief groove -borderwidth 2]
        grid $fname_desc -row 1 -column 0 -sticky ew
        set fscript [frame $f.fscript -relief groove -borderwidth 2]
        grid $fscript -row 2 -column 0 -sticky ewsn
        grid columnconfigure $f 0 -weight 1
        grid rowconfigure $f 0 -weight 0
        grid rowconfigure $f 1 -weight 0
        grid rowconfigure $f 2 -weight 1
        CmdInfo::initMenu
        CmdInfo::initNameDesc
        CmdInfo::initScript
    }

    proc render {} {
        variable render_cmd
        variable rerender
        set cmd [CmdState::getSelectedCmd]
        if {$render_cmd eq $cmd} {
            set rerender false
            return
        }
        set render_cmd $cmd
        set rerender true
        CmdInfo::renderNameDesc
        CmdInfo::renderScript
    }

    proc initMenu {} {
        variable fmenu
        label $fmenu.name_label -text "Command" -anchor w -padx 5 -pady 5
        button $fmenu.save_button -text "Save" -padx 5 -pady 5 -command CmdInfo::onClickSaveButton
        button $fmenu.delete_button -text "Delete" -padx 5 -pady 5 -command CmdInfo::onClickDeleteButton
        button $fmenu.duplicate_button -text "Duplicate" -padx 5 -pady 5 -command CmdInfo::onClickDuplicateButton
        button $fmenu.run_button -text "Erase" -padx 5 -pady 5 -command CmdInfo::onClickEraseButton
        grid $fmenu.name_label -row 0 -column 0 -sticky ew
        grid $fmenu.save_button -row 0 -column 1 -sticky ew
        grid $fmenu.delete_button -row 0 -column 2 -sticky ew
        grid $fmenu.duplicate_button -row 0 -column 3 -sticky ew
        grid $fmenu.run_button -row 0 -column 4 -sticky ew
        grid columnconfigure $fmenu 0 -weight 1
        grid columnconfigure $fmenu 1 -weight 1
        grid columnconfigure $fmenu 2 -weight 1
        grid columnconfigure $fmenu 3 -weight 1
        grid columnconfigure $fmenu 4 -weight 1
    }

    proc initNameDesc {} {
        variable fname_desc
        set cmd [CmdState::getSelectedCmd]
        set name [dict get $cmd current_name]
        set desc [dict get $cmd current_desc]
        label $fname_desc.name_label -text "Name" -anchor w -padx 5 -pady 5
        grid $fname_desc.name_label -row 0 -column 0 -sticky ew
        entry $fname_desc.name_entry -width 40
        $fname_desc.name_entry insert 0 $name
        grid $fname_desc.name_entry -row 0 -column 1 -sticky ew
        bind $fname_desc.name_entry <KeyRelease> {
            CmdInfo::onValueInput
        }
        bind $fname_desc.name_entry <FocusOut> {
            CmdInfo::onFocusOut
        }
        label $fname_desc.desc -text "Description" -anchor w -padx 5 -pady 5
        grid $fname_desc.desc -row 1 -column 0 -sticky ew
        text $fname_desc.desc_text -width 40  -height 1 -wrap word
        $fname_desc.desc_text insert 1.0 $desc
        grid $fname_desc.desc_text -row 1 -column 1 -sticky ew
        bind $fname_desc.desc_text <KeyRelease> {
            CmdInfo::onValueInput
        }
        bind $fname_desc.desc_text <FocusOut> {
            CmdInfo::onFocusOut
        }
        grid columnconfigure $fname_desc 0 -weight 1
        grid columnconfigure $fname_desc 1 -weight 3
    }

    proc renderNameDesc {} {
        variable fname_desc
        variable render_cmd
        variable rerender
        if {!$rerender} {
            return
        }
        set cmd [CmdState::getSelectedCmd]
        set name [dict get $cmd current_name]
        if {$name ne [CmdInfo::getName]} {
            $fname_desc.name_entry delete 0 end
            $fname_desc.name_entry insert 0 $name
        }
        set desc [dict get $cmd current_desc]
        if {$desc ne [CmdInfo::getDesc]} {
            $fname_desc.desc_text delete 1.0 end
            $fname_desc.desc_text insert 1.0 $desc
        }
    }

    proc initScript {} {
        variable fscript
        set fmenu [frame $fscript.fmenu -relief groove -borderwidth 2]
        grid $fmenu -row 0 -column 0 -sticky ew
        set fbody [frame $fscript.fbody -relief groove -borderwidth 2]
        grid $fbody -row 1 -column 0 -sticky ew
        grid columnconfigure $fscript 0 -weight 1
        grid rowconfigure $fscript 0 -weight 1
        grid rowconfigure $fscript 1 -weight 20
        CmdInfo::initScriptMenu
        CmdInfo::initScriptBody
    }

    proc renderScript {} {
        CmdInfo::renderScriptMenu
        CmdInfo::renderScriptBody
        CmdInfo::renderScriptOutput
    }

    proc initScriptMenu {} {
        variable fscript
        set fmenu $fscript.fmenu
        set cmd [CmdState::getSelectedCmd]
        set input_openfile [dict get $cmd input_openfile]
        set input_savefile [dict get $cmd input_savefile]
        set input_dir [dict get $cmd input_dir]
        set script [dict get $cmd current_script]
        label $fmenu.script_label -text "Script" -anchor w -padx 5 -pady 5
        grid $fmenu.script_label -row 0 -column 0 -sticky ew
        button $fmenu.run_button -text "Run" -padx 5 -pady 5 -command CmdInfo::onClickRunButton
        grid $fmenu.run_button -row 0 -column 4 -sticky ew
        grid rowconfigure $fmenu 0 -weight 1
        grid columnconfigure $fmenu 0 -weight 1
        grid columnconfigure $fmenu 1 -weight 1
        grid columnconfigure $fmenu 2 -weight 1
        grid columnconfigure $fmenu 3 -weight 1
        grid columnconfigure $fmenu 4 -weight 1
    }

    proc renderScriptMenu {} {
        variable fscript
        variable render_cmd
        variable rerender
        set fmenu $fscript.fmenu
        set cmd [CmdState::getSelectedCmd]
        set input_openfile [dict get $cmd input_openfile]
        set input_savefile [dict get $cmd input_savefile]
        set input_dir [dict get $cmd input_dir]
        set script [dict get $cmd current_script]
        lassign [Util::haveMetaVariables $script] has_openfile has_savefile has_dir
        if {$has_openfile}  {
            if {[winfo exists $fmenu.openfile_button] == 0} {
                button $fmenu.openfile_button -padx 1 -pady 5  -command CmdInfo::onClickOpenFileButton
            }
            $fmenu.openfile_button configure -text "Open: Browse.."
            if {[llength $input_openfile]} {
                set label [Util::shortenPath "Open: $input_openfile" 24]
                $fmenu.openfile_button configure -text "$label"
            }
        } else {
            catch {destroy $fmenu.openfile_button}
        }
        if {$has_savefile} {
            if {[winfo exists $fmenu.savefile_button] == 0} {
                button $fmenu.savefile_button -padx 1 -pady 5  -command CmdInfo::onClickSaveFileButton
            }
            $fmenu.savefile_button configure -text "Save: Browse.."
            if {[llength $input_savefile]} {
                set label [Util::shortenPath "Save: $input_savefile" 24]
                $fmenu.savefile_button configure -text "$label"
            }
        } else {
            catch {destroy $fmenu.savefile_button}
        }
        if {$has_dir} {
            if {[winfo exists $fmenu.dir_button] == 0} {
                button $fmenu.dir_button -text "Dir: Browse.." -padx 1 -pady 5 -command CmdInfo::onClickDirButton
            }
            if {[llength $input_dir]} {
                set label [Util::shortenPath "Dir: $input_dir" 24]
                $fmenu.dir_button configure -text "$label"
            }
        } else {
            catch {destroy $fmenu.dir_button}
        }
        if {$has_openfile && $has_savefile && $has_dir} {
            grid $fmenu.openfile_button -row 0 -column 1 -sticky ew
            grid $fmenu.savefile_button -row 0 -column 2 -sticky ew
            grid $fmenu.dir_button -row 0 -column 3 -sticky ew
        } elseif {$has_openfile && $has_dir} {
            grid $fmenu.openfile_button -row 0 -column 2 -sticky ew
            grid $fmenu.dir_button -row 0 -column 3 -sticky ew
        } elseif {$has_savefile && $has_dir} {
            grid $fmenu.savefile_button -row 0 -column 2 -sticky ew
            grid $fmenu.dir_button -row 0 -column 3 -sticky ew
        } elseif {$has_openfile && $has_dir} {
            grid $fmenu.openfile_button -row 0 -column 2 -sticky ew
            grid $fmenu.savefile_button -row 0 -column 3 -sticky ew
        } elseif {$has_openfile} {
            grid $fmenu.openfile_button -row 0 -column 3 -sticky ew
        } elseif {$has_savefile} {
            grid $fmenu.savefile_button -row 0 -column 3 -sticky ew
        } elseif {$has_dir} {
            grid $fmenu.dir_button -row 0 -column 3 -sticky ew
        }
    }

    proc initScriptBody {} {
        variable fscript
        set fbody $fscript.fbody
        set cmd [CmdState::getSelectedCmd]
        set script [dict get $cmd current_script]
        text $fbody.script_text -width 40 -font {"Courier New" 12} -wrap word -yscrollcommand "$fbody.scrollbar set"
        $fbody.script_text insert 1.0 $script
        grid $fbody.script_text -row 0 -column 0 -sticky ewns
        scrollbar $fbody.scrollbar -orient vertical -command "$fbody.script_text yview"
        grid $fbody.scrollbar -row 0 -column 1 -sticky ns
        grid rowconfigure $fbody 0 -weight 1
        grid columnconfigure $fbody 0 -weight 1
        grid columnconfigure $fbody 1 -weight 0
        bind $fbody.script_text <KeyRelease> {
            CmdInfo::onValueInput
        }
        bind $fbody.script_text <FocusOut> {
            CmdInfo::onFocusOut
        }
        bind $fbody.script_text <Tab> {
            CmdInfo::onKeyTabInput
        }
    }

    proc renderScriptBody {} {
        variable fscript
        variable render_cmd
        variable rerender
        if {!$rerender} {
            return
        }
        set fbody $fscript.fbody
        set cmd [CmdState::getSelectedCmd]
        set script [dict get $cmd current_script]
        if {$script ne [CmdInfo::getScript]} {
            $fbody.script_text delete 1.0 end
            $fbody.script_text insert 1.0 $script
        }
    }

    proc renderScriptOutput {} {
        variable fscript
        variable forget_output
        set foutput $fscript.foutput
        set cmd [CmdState::getSelectedCmd]
        set output [dict get $cmd output]
        if {$output eq ""} {
            catch {destroy $foutput}
            return
        }
        if {![winfo exists $foutput]} {
            set foutput [frame $fscript.foutput -relief groove -borderwidth 2]
            text $foutput.output_text -width 40  -font {"Courier New" 12} -wrap word -background darkgray -yscrollcommand "$foutput.scrollbar set"
            scrollbar $foutput.scrollbar -orient vertical -command "$foutput.output_text yview"
            grid $foutput.output_text -row 0 -column 0 -sticky ew
            grid $foutput.scrollbar -row 0 -column 1 -sticky ns
            grid rowconfigure $foutput 0 -weight 1
            grid columnconfigure $foutput 0 -weight 1
            grid columnconfigure $foutput 1 -weight 0
        }
        if {$forget_output} {
            return
        }
        grid $foutput -row 2 -column 0 -sticky ew
        grid rowconfigure $fscript 2 -weight 40
        $foutput.output_text configure -state normal
        $foutput.output_text delete 1.0 end
        $foutput.output_text insert 1.0 $output
        $foutput.output_text configure -state disabled
        bind $foutput.output_text <Double-1> CmdInfo::onDoubleClickOutput
    }

    proc getName {} {
        variable fname_desc
        set value [$fname_desc.name_entry get]
        return [string trim $value]
    }
    proc getDesc {} {
        variable fname_desc
        set value [$fname_desc.desc_text get 1.0 end]
        return [string trim $value]
    }
    proc getScript {} {
        variable fscript
        set fbody $fscript.fbody
        set value [$fbody.script_text get 1.0 end]
        return [string trim $value]
    }

    proc onClickSaveButton {} {
        set cmd [CmdState::getSelectedCmd]
        set script [CmdInfo::getScript]
        dict set cmd current_name [CmdInfo::getName]
        dict set cmd current_desc [CmdInfo::getDesc]
        dict set cmd current_script [CmdInfo::getScript]
        dict set cmd current_status $CmdData::STATUS_SAVED
        CmdState::onInfoSave $cmd
    }

    proc onClickDuplicateButton {} {
        CmdState::onInfoDuplicate
    }

    proc onClickDeleteButton {} {
        set result [tk_messageBox -message "Delete the data with log" -type yesno]
        if {$result eq "yes"} {
            CmdState::onInfoDelete
        }
    }

    proc onClickEraseButton {} {
        set result [tk_messageBox -message "Erase the data permanently without log" -type yesno]
        if {$result eq "yes"} {
            CmdState::onInfoErase
        }
    }

    proc onValueInput {} {
        set cmd [CmdState::getSelectedCmd]
        dict set cmd current_name [CmdInfo::getName]
        dict set cmd current_desc [CmdInfo::getDesc]
        dict set cmd current_script [CmdInfo::getScript]
        CmdState::onInfoValueInput $cmd
    }

    proc onClickOpenFileButton {} {
        set cmd [CmdState::getSelectedCmd]
        set input_openfile [dict get $cmd input_openfile]
        set init_file "[pwd]/*"
        if {$input_openfile != ""} {
            set init_file $input_openfile
        }
        set filepath [tk_getOpenFile -initialfile $init_file]
        if {$filepath ne ""} {
            dict set cmd input_openfile $filepath
            CmdData::replaceCommand $cmd
            CmdInfo::renderScript
        }
    }

    proc onClickSaveFileButton {} {
        set cmd [CmdState::getSelectedCmd]
        set input_savefile [dict get $cmd input_savefile]
        set init_file "[pwd]/*"
        if {$input_savefile != ""} {
            set init_file $input_savefile
        }
        set filepath [tk_getSaveFile -initialfile $init_file]
        if {$filepath ne ""} {
            dict set cmd input_savefile $filepath
            CmdData::replaceCommand $cmd
            CmdInfo::renderScript
        }
    }

    proc onClickDirButton {} {
        set cmd [CmdState::getSelectedCmd]
        set input_dir [dict get $cmd input_dir]
        set init_dir "~"
        if {$input_dir != ""} {
            set init_dir $input_dir
        }
        set folder [tk_chooseDirectory  -initialdir  $init_dir -mustexist true ]
        if {$folder ne ""} {
            dict set cmd input_dir $folder
            CmdData::replaceCommand $cmd
            CmdInfo::renderScript
        }
    }

    proc onClickRunButton {} {
        variable forget_output
        set cmd [CmdState::getSelectedCmd]
        set input_openfile [dict get $cmd input_openfile]
        set input_savefile [dict get $cmd input_savefile]
        set input_dir [dict get $cmd input_dir]
        set script [CmdInfo::getScript]
        lassign [Util::haveMetaVariables $script] has_openfile has_savefile has_dir
        if {$has_openfile && $input_openfile eq ""} {
            tk_messageBox -message "No OpenFile Chosen"
            return
        }
        if {$has_savefile && $input_savefile eq ""} {
            tk_messageBox -message "No SaveFile Chosen"
            return
        }
        if {$has_dir && $input_dir eq ""} {
            tk_messageBox -message "No Directory Chosen"
            return
        }
        set forget_output false
        CmdState::onInfoRun
    }

    proc onFocusOut {} {
        CmdData::saveData
    }
    
    proc onDoubleClickOutput {} {
        variable fscript
        variable forget_output
        set foutput $fscript.foutput
        grid forget $foutput
        set forget_output true
    }

    proc onKeyTabInput {} {
        variable fscript
        set fbody $fscript.fbody
        set insertPos [$fbody.script_text index insert]
        $fbody.script_text insert insert "    "
        return "break"
    }
}