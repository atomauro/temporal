#!/bin/sh

. /lib/functions.sh

breathing_light_supported() {
	[ ! -f "/etc/config/einfo" ] && return 1

	uci get -q einfo.dev.caps | grep -q 'breathing_light'
	if [ $? -eq 0 ]; then
		return 0
	else
		uci get einfo.dev.name | grep -qe '^RAK7268'
		return $?
	fi
}

breathing_light_status() {
        mwan3 status | tee | grep -q online
        [ $? -eq 0 ] || return 1
        if [ "`uci get lorawan.network.mode`" == "basic_station" ]; then
                [ -n "`pidof station`" ] || return 1
        elif [ "`uci get lorawan.network.mode`" == "network_server" ]; then
                [ -n "`pidof lorasrv`" ] || return 1
        else
            [ -n "`pidof lora_pkt_fwd`" ] || return 1
        fi
        return 0
}

breathing_light_off() {
	breathing_led --setc off
}

breathing_light_set_normal() {
	mode="`uci get -q system.breathing_light.mode`"
	[ -z $mode ] && mode="all"
	if [ $mode != "all" ]; then
		breathing_light_off
		return
	fi

	logger -t breathing_light "set breathing light to NORMAL"

	color="`uci get -q system.breathing_light.normal_color`"
	[ -z $color ] && color="green"

	freq="`uci get -q system.breathing_light.normal_freq`"
	case $freq in
	"slow")
		breathing_led --sett "${color:0:1}" 3 3 3 3
		;;
	"fast")
		breathing_led --sett "${color:0:1}" 1 1 1 1
		;;
	*)
		breathing_led --setm ${color:0:1} 0
		;;
	esac
}

breathing_light_set_abnormal() {
	mode="`uci get -q system.breathing_light.mode`"
	[ -z $mode ] || mode="all"
	if [ $mode == "disable" ]; then
		breathing_light_off
		return
	fi

	logger -t breathing_light "set breathing light to ABNORMAL"

	color="`uci get -q system.breathing_light.abnormal_color`"
	[ -z $color ] && color="red"

	breathing_led --sett "${color:0:1}" 3 3 3 3
}
