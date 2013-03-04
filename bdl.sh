#!/bin/bash
#
# Bash curses/dialog driven xorg window manager launcher
#
# Copyright (C) 2013 Marcus Hoffren <marcus.hoffren@gmail.com>.
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.
#

usage() {
    echo "Usage: ${0##*/} [--help|-h] [--version|-v] [--sessions|-s] [arg]"
    echo ""
    echo "-h, --help        Display this help."
    echo "-v, --version     Display version and exit."
    echo "-s, --sessions    View installed window managers."
    echo ""
    echo "Enter numerical value as argument. No argument launches menu."
    echo ""
}

version() {
    local scrname="Bash Desktop Launcher"
    local scrver="0.7"
    local scrauth="Marcus Hoffren"
    local authnick="dMG/Up Rough"
    local scrcontact="marcus.hoffren@gmail.com"
    echo "${scrname} v${scrver}"
    echo "Copyright (C) 2013 ${scrauth} <${authnick}>."
    echo "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>."
    echo "This is free software: you are free to change and redistribute it."
    echo "There is NO WARRANTY, to the extent permitted by law."
    echo ""
    echo "Written by ${scrauth}. <${scrcontact}>"
    echo ""
}

error() {
    { echo -e "${@}" 1>&2; usage; exit 1; }
}

args() {
    case ${1} in
	--version|-v)
		version
		exit 0;;
	--help|-h)
		usage
		exit 0;;
	--sessions|-s)
		echo "Installed window managers:"
		echo "$(xsessions "${sessions[@]}" "Default")"
		exit 0;;
	*)
		error;;
    esac
}
menu() {
    dialog --hfile "bdl-help.txt" --stdout --no-cancel --no-ok --no-tags --backtitle "(F1) ${scrname} v${scrver}" \
	--menu "Window Managers:" 30 40 20 $(xsessions "$@")
}

# Echo numbered list of arguments
xsessions() {
    local count="1"
    for arg in ${@}; do
	echo "${count} ${arg##*/}"
	(( count++ ))
    done
}

# Expands first of found arguments. Accept any, return first
expand_either() {
    for arg in ${@}; do
	local result=$(type -p "${arg}")
	[[ ${result} != "" ]] && { echo "${result}"; return 0; }
    done
    return 1
}

gtoe() {
    [[ "${1}" > "${2}" || "${1}" == "${2}" ]]
}

# Void
sanity_check() {
    [[ "${BASH_VERSION}" < 4.1 ]] && error "${0##*/} requires \033[1mbash v4.1 or newer\033[m."
    [[ $(type -p dialog) == "" ]] && error "dialog v1.2 or newer \033[1mrequired.\033[m"
    gtoe "$(dialog --version | head -c12)" "Version: 1.2" || error "\033[1mdialog\033[m version requirement \033[1m>= 1.2\033[m not met. Aborting."
    start=$(expand_either startx xinit)
    [[ "${start}" == "" ]] && error "startx or xinit \033[1mnot found.\033[m Is Xorg installed?"
    sessions=(/etc/X11/Sessions/*) # Expand path into array
    (( "${#sessions[@]}" == "0" )) && error "No sessions found. Is /etc/X11/Sessions empty?"
}

sanity_check
case ${#} in # Number of arguments
    0)
	index=$(menu "${sessions[@]}" "Default" "Quit")
	(( "${index}" == "${#sessions[@]}" + 2 )) && exit 0;; # Number of array elements + 2 = Quit
    1)
	if [[ "${1}" =~ ^- ]]; then # Does the first argument start with a - ?
	    args "${1}"
	elif [[ "${1}" =~ ^[[:digit:]]+$ ]]; then # Is the first argument a number?
	    index="${1}"
	    if (( "${index}" >= "${#sessions[@]}" + 2 )); then # Limit arg
		error "\033[1m${1}\033[m is not a valid argument. \033[1m${0} --sessions\033[m to list sessions."
	    fi
	else
	    error
        fi;;
    *)
	error;;
esac

let index-- # Make index zero based
exec "${start}" "${sessions[${index}]}" # Launch Xorg
