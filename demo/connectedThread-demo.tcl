#! /bin/sh
# \
exec tclsh "$0" ${1+"$@"}

tcl::tm::path add ../lib

package require connectedThread


connectedThread cth {
    set storage [list]
    while 1 {
        lassign [thread::receive] tid data
        set rest [lassign $data action]
        switch -- $action {
            create {
                lappend storage $rest
                thread::send [list ok [llength $storage]]
            }
            read {
                switch -- [llength $rest] {
                    0 {
                        thread::send [list ok $storage]
                    }
                    1 {
                        thread::send [list ok [lindex $storage $rest]]
                    }
                    2 {
                        thread::send [list ok [lrange $storage {*}$rest]]
                    }
                    default {
                        thread::send [list error "invalid number of indexes for read. should be >= 0 and <= 2"]
                    }
                }
            }
            update {
            }
            delete {
                switch -- [llength $rest] {
                    1 {
                        set storage [lreplace $storage $rest $rest]
                        thread::send [list ok $storage]
                    }
                    2 {
                        set storage [lreplace $storage {*}$rest]
                        thread::send [list ok $storage]
                    }
                    default {
                        thread::send [list error "invalid number of indexes for delete. should be >= 1 and <= 2"]
                    }
                }
            }
            default {
                puts stderr "invalid action \"$action\" $rest"
            }
        }
    }
}

proc showResponse {args} {
    lassign [cth receive] tid rest
    lassign $rest code data
    puts "[info level 0] :: $code -> $data"
}

set forever 0
cth readable showResponse
cth send {create a1}
cth send {create a2}
cth send {create a3}
cth send {read}
cth send {read 0}
cth send {read 1 end}
cth send {delete end}
cth send {delete 0}
cth send {read}
vwait forever
