#!/bin/bash
#
# Bash curses/dialog driven xorg window manager launcher
#
# Copyright (C) 2013 Marcus Hoffren <marcus.hoffren@gmail.com>.
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
# This is free software: you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.
#

scrname="Bash Desktop Launcher"
scrver="0.6"
scrauth="Marcus Hoffren"
authnick="dMG/Up Rough"
scrcontact="marcus.hoffren@gmail.com"

usage() {
    echo "Usage: ${0} [--help|-h] [--version|-v] [--sessions|-s] [arg]"
    echo ""
    echo "-h, --help        Display this help."
    echo "-v, --version     Display version and exit."
    echo "-s, --sessions    View installed window managers."
    echo ""
    echo "Enter numerical value as argument. No argument launches menu."
    echo ""
}

version() {
    echo "${scrname} v${scrver}"
    echo "Copyright (C) 2013 ${scrauth} <${authnick}>."
    echo "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>."
    echo "This is free software: you are free to change and redistribute it."
    echo "There is NO WARRANTY, to the extent permitted by law."
    echo ""
    echo "Written by ${scrauth}. <${scrcontact}>"
    echo ""
}

args() {
    case ${1} in
	--version|-v)
		version # fc
		exit 0;;
	--help|-h)
		usage # fc
		exit 0;;
	--sessions|-s)
		echo "Installed window managers:"
		echo "$(xsessions "${sessions[@]}" "Default")" # fc
		exit 0;;
	*)
		usage # fc
		exit 1;;
    esac
}

menu() {
    dialog --hfile "bdl-help.txt" --stdout --no-cancel --no-ok --no-tags --backtitle "(F1) ${scrname} v${scrver}" \
	--menu "Window Managers:" 30 40 20 $(xsessions "$@") # ec, fc
}

# Echo numbered list of arguments
xsessions() {
    local count="1"
    for arg in ${@}; do
	echo "${count} $(collapse "${arg}")" # fc
	let count++
    done
}

# Collapse argument. Same as basename *stub
collapse() {
    local name="${1##*/}"
    echo "${name%${2}}"
}

# Expand argument. Reversed basename *stub
expand() {
    type -p "${1}"
}

# Expands first of found arguments. Accept any, return first
expand_either() {
    for arg in ${@}; do
	local result=$(expand "${arg}") # fc
	[[ "${result}" != "" ]] && { echo "${result}"; return 0; }
    done
    return 1
}

gtoe() {
    [[ "${1}" > "${2}" || "${1}" == "${2}" ]]
}

# Void
sanity_check() {
    # Do we run this on Bash v4.1+?
    [[ "${BASH_VERSION}" < 4.1 ]] && { echo -e "${scrname} requires \033[1mbash v4.1 or newer\033[m."; exit 1; }
    # Is dialog installed?
    local dialog_path=$(expand dialog) # fc
    [[ ${dialog_path} == "" ]] && { echo -e "dialog v1.2 or newer \033[1mrequired.\033[m"; exit 1; }
    # Dialog version check
    gtoe "$(dialog --version | head -c12)" "Version: 1.2" || { # fc, ec
    echo -e "\033[1mdialog\033[m version requirement \033[1m>= 1.2\033[m not met. Aborting."; exit 1;
    }
    # Does startx or xinit exist?
    start=$(expand_either startx xinit) # fc, gvd
    [[ "${start}" == "" ]] && { echo -e "startx or xinit \033[1mnot found.\033[m Is Xorg installed?"; exit 1; }
    # Do we have any sessions?
    sessions=(/etc/X11/Sessions/*) # Expand path into array, gvd
    (( "${#sessions[@]}" == "0" )) && { echo -e "No sessions found. Is /etc/X11/Sessions empty?"; exit 1; }
}

sanity_check # fc
case ${#} in # Number of arguments
    0)
	index=$(menu "${sessions[@]}" "Default" "Quit") # gvd, fc
	(( "${index}" == "${#sessions[@]}" + 2 )) && exit 0;; # Number of array elements + 2 = Quit
    1)
	if [[ "${1}" =~ ^- ]]; then # Does the first argument start with a - ?
	    args "${1}" # fc
	elif [[ "${1}" =~ ^[[:digit:]]+$ ]]; then # Is the first argument a number?
	    index="${1}" # gvd
	    if (( "${index}" >= "${#sessions[@]}" + 2 )); then # Limit arg
		echo -e "\033[1m${1}\033[m is not a valid argument. \033[1m${0} --sessions\033[m to list sessions."
		exit 1
	    fi
	else
	    usage # fc
	    exit 1
        fi;;
    *)
	usage # fc
	exit 1;;
esac

let index-- # Make index zero based
echo "${start}" "${sessions[${index}]}" # Launch Xorg
