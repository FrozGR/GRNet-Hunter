# Hunter Version 1 
# by Frozen @ GRNet (darkness.irc.gr) - Frozen@hack.gr
# Last Upgraded: 27/12/2006
#
#	H Basikh idea tou script einai to na vazei nicks
#	notify kai afou entwpistoun online na enhmerwnei
#	sto Basiko tou kanali kai me Locops localy ston
#	server oti entwpisthkan k ekdiwxthikan.
#

# Main Channel tou Hunter
set chan_enforce "&Jersey"

# Nick list, kalytera einai na paramenei kenh apton configuration.
# Proteinete gia functional logous na prosthetonte ta nicks mesw DCC panel. 

set allnicks 0
set ban_names($allnicks) "NONE"

# Afou syndethei ston server, prosthetei ta nicknames sthn watch list.
# (Server Side Notify list)

proc on_connect_server { eType } {

	global allnicks ban_names
	set atNow 0

	putlog "Prosthetw ta BANNED Nicks sthn Notify List."

	while { $atNow < $allnicks } {
		putserv "WATCH +$ban_names($atNow)"
		incr atNow
	}
}

proc on_notify_user { from keyword pre } {

	global chan_enforce

	set on_nick [lindex $pre 1]
	set nick_host [lindex $pre 3]

	dccbroadcast "O user $on_nick einai online. Ton dagkwnw."

	foreach channels $chan_enforce {
		pushmode $channels +b "*!*@$nick_host"
	}
}

proc on_notify_leave { from keyword pre } {

	global chan_enforce

	set on_nick [lindex $pre 1]
	set nick_host [lindex $pre 3]

	dccbroadcast "$on_nick has gone offline. Unbanning that person."

	foreach channels $chan_enforce {
		timer [rand 25] [split "pushmode $channels -b *!*@$nick_host"]
	}
}

proc add_a_new_ban_nick {handle idx arg} {

	global allnicks ban_names
	set newnick [lindex $arg 0]

	if {$arg == ""} { 

		putdcc $idx "\[$handle\]: .addbannick <nick>" 
	} else {
		
		putdcc $idx "\[$handle\]: Adding $newnick to banlist."
		set ban_names($allnicks) $newnick
		incr allnicks

		putserv "WATCH +$newnick"
	}
}

proc del_a_ban_nick {handle idx arg} {

	global allnicks ban_names
	set delnick [lindex $arg 0]
	set counters 0
	set countP 0
	set temp_list($counters) ""

	if {$arg == ""} {

		putdcc $idx "\[$handle\]: .delbannick <nick>" 		
	} else {

		putdcc $idx "Deleting $delnick from banlist." 
		
		while {$counters < $allnicks} {

			if {$ban_names($counters) != $delnick} {
				set temp_list($countP) $ban_names($counters)
				incr countP
			}
			incr counters
		}

		if { $countP == $counters } {
			putdcc $idx "\[$handle\]: I didn't find that nick in the LIST." 
			return 0
		}

		set allnicks 0
		unset ban_names
		set ban_names($allnicks) ""
		
		while {$allnicks < $countP} {

			set ban_names($allnicks) $temp_list($allnicks)
			incr allnicks
		}
		putserv "WATCH c"
		on_connect_server "NONE"
	}
}

proc save_all_bans {handle idx arg} {

	global allnicks ban_names
	set nowNow 0

	putdcc $idx "\[$handle\]: Saving all ($allnicks) ban nicks to file..." 

	file del "mark/bannick.db"
	set dbFile [open "mark/bannick.db" w]

	while {$nowNow < $allnicks} {

		if { $ban_names($nowNow) != "" } {
			if { $ban_names($nowNow) != " " } {
				puts $dbFile $ban_names($nowNow)
			}
		}
		incr nowNow
	}
	close $dbFile
}

proc show_all_bans {handle idx arg} {

	global ban_names allnicks
	set temps 0
	set nick_list ""

	putdcc $idx "\[$handle\]: Listing all banned nicks now. I have $allnicks in my list."

	while {$temps < $allnicks} {

		set nick_list "$nick_list $ban_names($temps)"
		incr temps
	}

	putdcc $idx "\[$handle\]: $nick_list" 
}

proc init_bannick {} {

	global allnicks ban_names
	set dbFile [open "mark/bannick.db" r]

	unset ban_names
	set allnicks 0
	set ban_names(allnicks) ""

	while {![eof $dbFile]} {
		
		set ban_names($allnicks) [gets $dbFile]
		incr allnicks
	}
	close $dbFile
}

bind raw - 600 on_notify_user
bind raw - 601 on_notify_leave
bind raw - 604 on_notify_nick_change

bind dcc o|- addbannick add_a_new_ban_nick
bind dcc o|- delbannick del_a_ban_nick
bind dcc o|- savebans save_all_bans
bind dcc o|- showbans show_all_bans

bind evnt - init-server on_connect_server

init_bannick

putlog "Hunter Version 1 by Frozen loaded."