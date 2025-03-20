# CmdManager: A Convenient Tool for Managing VMD Scripts
# Author: duan_zhou@outlook.com
# License: UIUC Open Source License, Full license text can be found in the LICENSE file
# Tip: The variables $OpenFile, $SaveFile and $Dir can trigger button input.

package provide cmdmanager 1.0

proc cmdmanager_tk {} {
    global env
    set root $env(VMDDIR)
    set src "$root/plugins/noarch/tcl/cmdmanager"
    source "$src/state.tcl"
    source "$src/list.tcl"
    source "$src/info.tcl"
    source "$src/data.tcl"
    source "$src/util.tcl"

    CmdMain::new
    return $CmdMain::w
}

namespace eval CmdMain {
    variable w

    proc new {} {
        variable w
        if {[winfo exists .cmdmanager]} {
            wm deiconify .cmdmanager
            raise .cmdmanager
            return
        }
        set w [toplevel .cmdmanager]
        wm title $w "CommandManager"
        wm resizable $w 1 1
        CmdMain::initPosAndSize
        CmdData::init
        CmdState::init
        set f_list [frame $w.f_list -relief groove -borderwidth 2]
        set f_info [frame $w.f_info -relief groove -borderwidth 2]
        grid $f_list -row 0 -column 0 -sticky ewsn -pady 5
        grid $f_info -row 1 -column 0 -sticky ewsn -pady 5
        grid rowconfigure $w 0 -weight 0
        grid rowconfigure $w 1 -weight 1
        grid columnconfigure $w 0 -weight 1
        CmdList::new $f_list
        CmdInfo::new $f_info
        CmdMain::render
    }

    proc initPosAndSize {} {
        variable w
        set w0 [winfo screenwidth $w]
        set h0 [winfo screenheight $w]
        set w1 [expr {round($w0 * 0.33)}]
        set h1 [expr {round($h0 * 0.8)}]
        wm geometry $w "${w1}x${h1}"
    }

    proc render {} {
        variable w
        CmdList::render
        CmdInfo::render
    }
}
