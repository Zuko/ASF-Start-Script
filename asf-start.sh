#!/bin/bash
# Start script for ArchiSteamFarm
# https://github.com/JustArchi/ArchiSteamFarm
#
# Zuko	https://github.com/Zuko
# v1.0.0  24.09.2017

 ### Config
ASF_DIR="/home/zuko/ASF-Main"
ASF_MAIN_CFGFILE="${ASF_DIR}/config/ASF.json"
ASF_EXEC="ArchiSteamFarm"
SCREEN_NAME="asf-main"
 ### /Config

 ### Functions
# $1 - List of executables to check [eg. checkSystemExecutables "sed grep"]
function checkSystemExecutables {
	[[ $# -eq 1 ]] || { echo -e "rong number of parameters in ${FUNCNAME}"; exit 1; }

	local _LIST __LIST _ERROR
	_LIST="${1}"
	__LIST=()
	_ERROR="0"
 
	for i in ${_LIST}; do
		if ! type ${i} > /dev/null 2>&1; then
			_ERROR="1"
			__LIST+=("${i}")
		fi
	done

	if [[ "${_ERROR}" -eq "1" ]]; then
		echo -e	 "Please install: $(cText "R" "${__LIST[*]}")"
		return 1
	else
		return 0
	fi
}
 ### /Functions

# Do we have everything we need?
if ! checkSystemExecutables "screen jq sponge seq"; then
	# Nope, bye
	exit 1
fi

cat <<- EOF > "/tmp/${SCREEN_NAME}.sh"
#!/bin/bash
while [ -x "${ASF_DIR}/${ASF_EXEC}" ]; do
	if ! ${ASF_DIR}/${ASF_EXEC}; then
		break
	fi
	sleep 1
done
EOF

if [[ ! -x "/tmp/${SCREEN_NAME}.sh" ]]; then
	chmod +x "/tmp/${SCREEN_NAME}.sh"
fi

if [[ -d "${ASF_DIR}" ]]; then
	if ! screen -S ${SCREEN_NAME} -X select . > /dev/null 2>&1; then
		if [[ -f "${ASF_MAIN_CFGFILE}" ]]; then
			# Configure!
			# AutoRestart = fasle
			# AutoUpdates = true
			jq 'if .AutoRestart == true then .AutoRestart = false else . end | if .AutoUpdates == false then .AutoUpdates = true else . end' ${ASF_MAIN_CFGFILE} | sponge ${ASF_MAIN_CFGFILE}
		else
			echo -e "Config file: \"${ASF_MAIN_CFGFILE}\" is missing."
			exit 1
		fi

		if [[ ! -x "${ASF_DIR}/${ASF_EXEC}" ]]; then
			chmod +x ${ASF_DIR}/${ASF_EXEC}
		fi
		
		# Create new one and run ASF on it
		screen -S ${SCREEN_NAME} -dm "/tmp/${SCREEN_NAME}.sh"
	else
		# Resume
		read -e -p "ASF is running. Resume? [y/n] " -i "y" response
		if [[ "${response}" =~ ^(yes|y|YES|Y)$ ]]; then
			screen -r ${SCREEN_NAME}
		fi
	fi
else
	echo -e "Bot dir: \"${ASF_DIR}\" is missing."
	exit 1
fi

# EOF
