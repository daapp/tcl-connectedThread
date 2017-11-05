# (c) 2017 Alexander Danilov <alexander.a.danilov@gmail.com>
#
# This module provide connectedThread command, which create new
# thread, connected with calling thread using 2 channels. Simular to Erlang
# interprocess communication.
# connectedThread command has 1 argument - code to execute inside thread.
# Parent thread has following subcommands:
#     - id -- return identifier of calling thread
#     - send message -- send message to thread
#     - sendCode tclCode -- evaluate Tcl code into calling thread
#     - receive -- receive message from channel
#     - readable command -- bind command to channel, so command will be invoked when new message available

package require Thread
package require snit


snit::type connectedThread {
    variable threadId
    variable thisThreadId
    variable rc1
    variable wc1
    variable rc2
    variable wc2

    constructor {{code ""}} {
        set thisThreadId  [thread::id]

        set threadId [thread::create]
        lassign [chan pipe] rc1 wc1
        lassign [chan pipe] rc2 wc2

        foreach ch [list $rc1 $wc1 $rc2 $wc2] {
            chan configure $ch -buffering line
        }

        thread::transfer $threadId $rc1
        thread::transfer $threadId $wc2

        thread::send -async $threadId [format {
            proc thread::receive {} {
                return [chan gets %1$s]
            }

            proc thread::send {message} {
                chan puts %2$s [list [thread::id] $message]
            }
        } $rc1 $wc2]

        if {$code ne ""} {
            $self sendCode $code
        }
    }

    method id {} {
        return $threadId
    }

    method send {message} {
        chan puts $wc1 [list $thisThreadId $message]
    }

    method receive {} {
        return [chan get $rc2]
    }

    method sendCode {code} {
        thread::send -async $threadId $code
    }

    method readable {command} {
        chan event $rc2 readable $command
    }
}
