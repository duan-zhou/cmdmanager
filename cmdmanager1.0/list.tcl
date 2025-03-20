namespace eval CmdList {
    variable f
    variable last_search

    proc new {f_list} {
        variable f
        variable last_search
        set f $f_list
        set last_search ""

        menubutton $f.list_button -text "List" -underline 0 -anchor center -padx 5 -pady 5 -menu $f.list_button.menu
        set m [menu $f.list_button.menu -tearoff no]
        $m add checkbutton -label "Saved" -variable CmdState::show_saved -command CmdState::onListShowChanged
        $m add checkbutton -label "Unsaved" -variable CmdState::show_unsaved -command CmdState::onListShowChanged
        $m add checkbutton -label "Deleted" -variable CmdState::show_deleted -command CmdState::onListShowChanged
        $m add checkbutton -label "LogDeleted" -variable CmdState::show_log_deleted -command CmdState::onListShowChanged
        $m add separator
        $m add command -label "Erase Deleted" -command CmdList::onListEraseDeleted
        $m add command -label "Erase LogDeleted" -command CmdList::onListEraseLogDeleted
        button $f.new_button -text "New" -padx 5 -pady 5 -command CmdList::onClickNewButton
        set search_entry [entry $f.search_entry -width 6]
        set placeholder "Search"
        $search_entry insert 0 $placeholder
        $search_entry configure -fg "gray"
        bind $search_entry <FocusIn> CmdList::onSearchFocusIn
        bind $search_entry <FocusOut> CmdList::onSearchFocusOut
        bind $search_entry <KeyRelease> CmdList::onSearchInput
        button $f.file_button -text "File: $CmdData::filepath" -padx 5 -pady 5 -command CmdList::onClickFileButton
        button $f.about_button -text "About" -padx 5 -pady 5 -command CmdList::onClickAboutButton
        frame $f.flist -relief groove -borderwidth 2
        CmdList::initList
        grid $f.list_button -row 0 -column 0 -sticky ew
        grid $f.search_entry -row 0 -column 1 -sticky ewns -padx 2 -pady 2
        grid $f.new_button -row 0 -column 2 -sticky ew
        grid $f.file_button -row 0 -column 3 -sticky ew
        grid $f.about_button -row 0 -column 4 -sticky ew
        grid $f.flist -row 1 -column 0 -columnspan 5 -sticky nsew
        grid columnconfigure $f 0 -weight 1
        grid columnconfigure $f 1 -weight 1
        grid columnconfigure $f 2 -weight 1
        grid columnconfigure $f 3 -weight 1
        grid columnconfigure $f 4 -weight 1
        grid rowconfigure $f 1 -weight 1
    }

    proc render {} {
        variable f
        $f.file_button configure -text [Util::shortenPath "File: $CmdData::filepath" 24]
        CmdList::renderList
    }

    proc initList {} {
        variable f
        set f1 $f.flist
        ttk::treeview $f1.treeview -columns {col1 col2 col3 col4} -show headings -yscrollcommand "$f1.scrollbar set"
        grid $f1.treeview -column 0 -row 0 -sticky ew
        scrollbar $f1.scrollbar -orient vertical -command "$f1.treeview yview"
        grid $f1.scrollbar -column 1 -row 0 -sticky ns
        grid columnconfigure $f1 0 -weight 1
        grid columnconfigure $f1 1 -weight 0
        $f1.treeview heading col1 -text "Id"
        $f1.treeview heading col2 -text "Name"
        $f1.treeview heading col3 -text "Script"
        $f1.treeview heading col4 -text "Status"
        $f1.treeview column col1 -width 20 -anchor center
        $f1.treeview column col2 -width 100 -anchor w
        $f1.treeview column col3 -width 100 -anchor w
        $f1.treeview column col4 -width 30 -anchor center
        bind $f1.treeview <<TreeviewSelect>> { CmdList::onSelectCmdTreeView %W }
    }

    proc renderList {} {
        variable f
        set f1 $f.flist
        $f1.treeview tag configure orange_color -foreground "orange"
        $f1.treeview tag configure gray_color -foreground "gray"
        $f1.treeview delete [$f1.treeview children ""]
        set show_list [CmdState::checkAndGetShowList]
        foreach cmd $show_list {
            set id [dict get $cmd id]
            set name [dict get $cmd current_name]
            set script [dict get $cmd current_script]
            set script [string map [list "\n" ";"] $script]
            set status [dict get $cmd current_status]
            set color ""
            if {$status == $CmdData::STATUS_DELETED} {
                set color "gray_color"
            } elseif {$status == $CmdData::STATUS_LOG_DELETED} {
                set color "gray_color"
            } elseif {$status == $CmdData::STATUS_TEMP} {
                set color "orange_color"
            } elseif {$status == $CmdData::STATUS_UNSAVED} {
                set color "orange_color"
            }
            $f1.treeview insert "" end -id $id -values [list $id $name $script $status] -tags $color
        }
        $f1.treeview selection set $CmdState::selected_id
        $f1.treeview see $CmdState::selected_id
    }

    proc onClickNewButton {} {
        variable f
        CmdState::onListNew
    }

    proc onClickFileButton {} {
        set filetypes {
            {"Text and Log files" {.txt .log}}
            {"Text files" {.txt}}
            {"Log files" {.log}}
            {"All files" {*}}
        }
        set filepath [tk_getOpenFile -filetypes $filetypes]
        if {$filepath ne ""} {
            CmdState::onListOpenFile $filepath
        }
    }

    proc onClickAboutButton {} {
        set message "CmdManager: A Convenient Tool for Managing VMD Scripts
Author: duan_zhou@outlook.com
GitHub: https://github.com/duan-zhou/cmdmanager
License: UIUC Open Source License
Tip: The meta variables \$OpenFile, \$SaveFile and \$Dir can trigger button input."
        tk_messageBox -message $message
    }

    proc onSelectCmdTreeView {tv} {
        set selected_id [$tv focus]
        if {$selected_id eq ""} {
            return
        }
        if {$selected_id eq $CmdState::selected_id} {
            return
        }
        CmdState::onListSelect $selected_id
    }

    proc onListEraseDeleted {} {
        set result [tk_messageBox -message "Erase the deleted data permanently" -type yesno]
        if {$result eq "yes"} {
            CmdState::onListEraseDeleted
        }
    }

    proc onListEraseLogDeleted {} {
        set result [tk_messageBox -message "Erase the deleted log data permanently" -type yesno]
        if {$result eq "yes"} {
            CmdState::onListEraseLogDeleted
        }
    }

    proc onSearchFocusIn {} {
        variable f
        set placeholder "Search"
        set search_entry $f.search_entry
        set val [$search_entry get]
        if { $val eq $placeholder} {
            $search_entry delete 0 end
            $search_entry configure -fg "black"
        }
    }

    proc onSearchFocusOut {} {
        variable f
        set placeholder "Search"
        set search_entry $f.search_entry
        set text [$search_entry get]
        if {$text eq ""} {
            $search_entry insert 0 $placeholder
            $search_entry configure -fg "gray"
        }
    }

    proc onSearchInput {} {
        variable f
        variable last_search
        set search_entry $f.search_entry
        set text [string trim [$search_entry get]]
        if {$text ne "" || $text ne $last_search} {
            set last_search $text
            CmdState::onListSearch $text
        }
    }
}