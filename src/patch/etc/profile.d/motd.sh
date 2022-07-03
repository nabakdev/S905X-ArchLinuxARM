#!/bin/sh
#
# ufetch-arch - tiny system info for arch

## INFO

# user is already defined
host="$(cat /etc/hostname)"
os='Arch Linux ARM'
kernel="$(uname -sr)"
uptime="$(uptime -p | sed 's/up //')"
packages="$(pacman -Q | wc -l)"
shell="$(basename "${SHELL}")"
local_ip="$(ip -o -4 addr list eth0 | awk '{print $4}')"

mem="$(free | grep Mem)"
mem_total="$(printf "%.2f" $(echo "$mem" | awk '{print $2 / (1024 * 1024)}'))"
mem_used_percentage="$(printf "%.1f" $(echo "$mem" | awk '{print $3/$2 * 100.0}'))"

cpu_temp="$(printf "%.0f" $(cat /sys/class/thermal/thermal_zone*/temp | sed 's/\(.\)..$/.\1/'))"

loadval5="$(awk '{print $2}' < /proc/loadavg)"
system_load="$(echo "${loadval5} * 100 / $(getconf _NPROCESSORS_ONLN)" | bc)"

disk="$(df -h / | tail -n1)"
disk_used="$(echo $disk | awk '{print $5}')"
disk_size="$(echo $disk | awk '{print $2}')"

## UI DETECTION

parse_rcs() {
	for f in "${@}"; do
		wm="$(tail -n 1 "${f}" 2> /dev/null | cut -d ' ' -f 2)"
		[ -n "${wm}" ] && echo "${wm}" && return
	done
}

rcwm="$(parse_rcs "${HOME}/.xinitrc" "${HOME}/.xsession")"

ui='unknown'
uitype='UI'
if [ -n "${DE}" ]; then
	ui="${DE}"
	uitype='DE'
elif [ -n "${WM}" ]; then
	ui="${WM}"
	uitype='WM'
elif [ -n "${XDG_CURRENT_DESKTOP}" ]; then
	ui="${XDG_CURRENT_DESKTOP}"
	uitype='DE'
elif [ -n "${DESKTOP_SESSION}" ]; then
	ui="${DESKTOP_SESSION}"
	uitype='DE'
elif [ -n "${rcwm}" ]; then
	ui="${rcwm}"
	uitype='WM'
elif [ -n "${XDG_SESSION_TYPE}" ]; then
	ui="${XDG_SESSION_TYPE}"
fi

ui="$(basename "${ui}")"

## DEFINE COLORS

# probably don't change these
if [ -x "$(command -v tput)" ]; then
	bold="$(tput bold)"
	black="$(tput setaf 0)"
	red="$(tput setaf 1)"
	green="$(tput setaf 2)"
	yellow="$(tput setaf 3)"
	blue="$(tput setaf 4)"
	magenta="$(tput setaf 5)"
	cyan="$(tput setaf 6)"
	white="$(tput setaf 7)"
	reset="$(tput sgr0)"
fi

# you can change these
#lc="${reset}${bold}${white}"         # labels
lc="${reset}"         # labels
nc="${reset}${bold}${cyan}"         # user and hostname
ic="${reset}${white}"                       # info
c0="${reset}${cyan}"                # first color

## OUTPUT

cat <<EOF

${c0}        /\\         ${nc}${USER}${ic}@${nc}${host}${reset}
${c0}       /  \\        ${lc}OS:        ${cyan}${os}${reset}
${c0}      /\\   \\       ${lc}KERNEL:    ${ic}${kernel}${reset}
${c0}     /  __  \\      ${lc}UPTIME:    ${green}${uptime}${reset}
${c0}    /  (  )  \\     ${lc}PACKAGES:  ${ic}${packages}${reset}
${c0}   / __|  |__\\\\    ${lc}SHELL:     ${ic}${shell}${reset}
${c0}  /.\`        \`.\\   ${lc}IP:${reset}        ${green}${local_ip}${reset}
${lc}System Load:${reset} ${system_load}%		${lc}Memory Usage:${reset} ${mem_used_percentage}% of ${mem_total}G
${lc}CPU Temp:${reset}    ${cpu_temp} C	${lc}Disk Usage:${reset}   ${disk_used} of ${disk_size}

EOF

