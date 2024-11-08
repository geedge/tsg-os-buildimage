#!/usr/bin/env bash

interface=$1
event=$2

if [[ $interface == "br_dign_c" ]] && [[ $event == "up" ]]
then
	iptables -t raw -I PREROUTING -i br_dign_c -j NOTRACK
fi

if [[ $interface == "br_dign_s" ]] && [[ $event == "up" ]]
then
	iptables -t raw -I PREROUTING -i br_dign_s -j NOTRACK
fi

