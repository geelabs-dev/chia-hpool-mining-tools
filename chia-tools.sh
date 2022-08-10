#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
# set -e

Init_Env(){

	# Check running env
	if [[ "$(cat /etc/os-release | grep "^NAME" | awk -F '"' '{print $2}')" != "Ubuntu" ]]; then
	    echo "Error: You must be ubuntu system to run this script !"
	    exit 1
	# elif [ $(id -u) != "0" ]; then
	#     echo "Error: You must be root to run this script !"
	#     exit 1
	fi

	# Tool Info
	CONFIG_TOOL_VER='v1.0.1'
	CONFIG_TOOL_NAME='chia-hpool-mining-tool'
	CONFIG_TOOL_Powered='Gee.Labs - 极数实验室'
	CONFIG_TOOL_Website='www.gee-labs.com'
	CONFIG_TOOL_Discord='https://discord.gg/za8gAUGdpT'
	CONFIG_TOOL_Powered='本工具开源发布，欢迎大家二次修改使用，使用中如遇任何问题，请加入Discord官方群组，联系技术人员排查问题'

	# Tool Config
	CONFIG_BASE_DIR=$(cd $(dirname $0); pwd)
	CONFIG_CORE_DIR=${CONFIG_BASE_DIR}/core
	CONFIG_TOOL_DIR=${CONFIG_BASE_DIR}/tool
	CONFIG_LOGS_DIR=${CONFIG_BASE_DIR}/logs
	CONFIG_CONF_DIR=${CONFIG_BASE_DIR}/config
	CONFIG_TEMP_DIR=${CONFIG_BASE_DIR}/temp
	CONFIG_CONF_FILE=${CONFIG_CONF_DIR}/config.json
	CONFIG_Miner_Shell=${CONFIG_CORE_DIR}/chia-hpool-mining-control.sh
	CONFIG_Miner_Bin=${CONFIG_TOOL_DIR}/hpool-miner-chia-linux-amd64
	CONFIG_proxy_Bin=${CONFIG_TOOL_DIR}/x-proxy-og-linux-amd64
	CONFIG_Yq_Bin=${CONFIG_TOOL_DIR}/yq

	# Check Tool Files
	if [[ ! -f "$CONFIG_Miner_Shell" ]] || [[ ! -f "$CONFIG_Miner_Bin" ]] || [[ ! -f "$CONFIG_proxy_Bin" ]] || [[ ! -f "$CONFIG_Yq_Bin" ]]; then
		echo "ERROR : the tool core files are missing, please reinstall it !"
		exit 1
	fi

	# Check Tool Dependencies
	if ! type sshpass >/dev/null 2>&1; then
		echo "ERROR : the tool depends on 'sshpass', please run 'sudo apt install sshpass' to install it !"
		exit 1
	elif ! type figlet >/dev/null 2>&1; then
		echo "ERROR : the tool depends on 'figlet', please run 'sudo apt install figlet' to install it !"
		exit 1
	elif ! type jq >/dev/null 2>&1; then
		echo "ERROR : the tool depends on 'jq', please run 'sudo apt install jq' to install it !"
		exit 1
	elif ! type screen >/dev/null 2>&1; then
		echo "ERROR : the tool depends on 'screen', please run 'sudo apt install screen' to install it !"
		exit 1
	fi

	# Init dirs
	rm -rf $CONFIG_LOGS_DIR $CONFIG_TEMP_DIR
	mkdir -p $CONFIG_LOGS_DIR $CONFIG_TEMP_DIR

	# Del ssh host
	rm -rf ~/.ssh/known_hosts

	# Fix maxSessions
	if [[ -n "$(cat /etc/ssh/sshd_config | egrep -i "#maxSessions")" ]] || [[ "$(cat /etc/ssh/sshd_config | egrep -i "maxSessions" | awk '{print $NF}')" != "10" ]]; then
		sudo sed -i 's/^.*.xSessions.*.$/MaxSessions 10/' /etc/ssh/sshd_config
		sudo service ssh restart >/dev/null 2>&1
	fi
}

Show_Banner(){
	clear
	figlet -f slant CHIA-Mining
	echo "  Chia mining tool for hpool $CONFIG_TOOL_VER"
	echo "  Powered : Gee.Labs"
	echo "  Discord : https://discord.gg/za8gAUGdpT"
	echo "_________________________________________________________"
	echo
}

Load_Config(){

	# Load config json
	CONFIG_JSON=`cat $CONFIG_CONF_FILE`

	# Load server
	read Server_Config_Name Server_Config_Ip Server_Config_Port Server_Config_User Server_Config_Pwd <<<"$(echo $CONFIG_JSON | jq -r '.server|.remark,.sshIp,.sshPort,.sshUser,.sshPwd' | xargs)"
	# echo "$Server_Config_Name $Server_Config_Ip $Server_Config_Port $Server_Config_User $Server_Config_Pwd"

	# Load apikey
	Miner_Config_Apikey_Arr=($(echo $CONFIG_JSON | jq -r '.miner[].apikey'))
	# echo "${#Miner_Config_Apikey_Arr[*]} : ${Miner_Config_Apikey_Arr[*]}"

	# Load miner
	Miner_Config_Ip_Arr=($(echo $CONFIG_JSON | jq -r '.miner[].device[].sshIp'))
	# echo "${#Miner_Config_Ip_Arr[*]} : ${Miner_Config_Ip_Arr[*]}"

	# Load server
	read Server_SSH_Remark Server_SSH_Ip Server_SSH_Port Server_SSH_User Server_SSH_Pwd <<<"$(echo $CONFIG_JSON | jq -r '.server|.remark,.sshIp,.sshPort,.sshUser,.sshPwd' | xargs)"
}

Get_Miner_SSH_Info(){
	Miner_SSH_Ip=$1
	read Miner_SSH_Port Miner_SSH_User Miner_SSH_Pwd <<<"$(echo $CONFIG_JSON | jq -r '.miner[].device[]|select(.sshIp == "'${Miner_SSH_Ip}'")|.sshPort,.sshUser,.sshPwd' | xargs)" 
}

Verify_IP_Validity(){
	if [[ -z "$(echo $CONFIG_JSON | jq -r '.miner[].device[]|select(.sshIp == "'${1}'")')" ]]; then
		echo "ERROR : IP error !"
		exit 1
	fi
}

Get_Miner_Info(){
	for i in ${Miner_Config_Ip_Arr[*]}; do
		{
			local Miner_Info_Json=$(Remote_Miner_Info $i)
			if [[ "$(echo $Miner_Info_Json | jq -r .code)" = 200 ]]; then
				echo $Miner_Info_Json | jq > $CONFIG_LOGS_DIR/miner-info-$i.log
			fi
		}&
	done
	wait

	unset Miner_Online_Ip_Arr
	unset Miner_Offline_Ip_Arr
	for i in ${Miner_Config_Ip_Arr[*]}; do
		if [[ -f "$CONFIG_LOGS_DIR/miner-info-$i.log" ]]; then
			Miner_Online_Ip_Arr[${#Miner_Online_Ip_Arr[@]}]=$i
		else
			Miner_Offline_Ip_Arr[${#Miner_Offline_Ip_Arr[@]}]=$i
		fi
	done

	# Debug
	echo "Total   : ${#Miner_Config_Ip_Arr[*]}"
	echo "Online  : ${#Miner_Online_Ip_Arr[*]}"
	echo "Offline : ${#Miner_Offline_Ip_Arr[*]}"
}


######################################################################

Remote_Miner_Info(){
	Get_Miner_SSH_Info $1
	sshpass -p ${Miner_SSH_Pwd} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p ${Miner_SSH_Port} ${Miner_SSH_User}@${Miner_SSH_Ip} bash -s < $CONFIG_Miner_Shell minerinfo 2>/dev/null
}

Remote_Miner_Start(){

	local Miner_Apikey=$(echo $CONFIG_JSON | jq -r '.miner[]|select(.device[].sshIp == "'${1}'")|.apikey')
	# local Miner_Proxy_Ip=$(echo $CONFIG_JSON | jq -r '.miner[]|select(.device[].sshIp == "'${1}'")|.proxy.ip')
	# echo $Miner_Apikey $Miner_Proxy_Ip

	Get_Miner_SSH_Info $1
	sshpass -p ${Miner_SSH_Pwd} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p ${Miner_SSH_Port} ${Miner_SSH_User}@${Miner_SSH_Ip} bash -s < $CONFIG_Miner_Shell minerstart $Miner_Apikey $Miner_Proxy 2>/dev/null
}

Remote_Miner_Stop(){
	Get_Miner_SSH_Info $1
	sshpass -p ${Miner_SSH_Pwd} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p ${Miner_SSH_Port} ${Miner_SSH_User}@${Miner_SSH_Ip} bash -s < $CONFIG_Miner_Shell minerstop 2>/dev/null
}

Remote_Miner_Reboot(){
	Get_Miner_SSH_Info $1
	sshpass -p ${Miner_SSH_Pwd} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p ${Miner_SSH_Port} ${Miner_SSH_User}@${Miner_SSH_Ip} bash -s < $CONFIG_Miner_Shell minerreboot 2>/dev/null
}

Remote_Miner_Mount(){
	Get_Miner_SSH_Info $1
	sshpass -p ${Miner_SSH_Pwd} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p ${Miner_SSH_Port} ${Miner_SSH_User}@${Miner_SSH_Ip} bash -s < $CONFIG_Miner_Shell minermount 2>/dev/null
}

Remote_Miner_Init(){
	Get_Miner_SSH_Info $1
	sshpass -p ${Miner_SSH_Pwd} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p ${Miner_SSH_Port} ${Miner_SSH_User}@${Miner_SSH_Ip} bash -s < $CONFIG_Miner_Shell minerinit $Server_SSH_Ip $Server_SSH_Port $Server_SSH_User $Server_SSH_Pwd $CONFIG_TOOL_DIR 2>/dev/null
}

Remote_Miner_CMD(){
	Get_Miner_SSH_Info $1
	sshpass -p ${Miner_SSH_Pwd} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p ${Miner_SSH_Port} ${Miner_SSH_User}@${Miner_SSH_Ip} bash -s < $CONFIG_Miner_Shell minercmd 2>/dev/null
}

######################################################################

Action_Miner_Status(){
		for Miner_Account_Apikey in ${Miner_Config_Apikey_Arr[*]}; do
		local Miner_Account_Name=$(echo $CONFIG_JSON | jq -r '.miner[]|select(.apikey == "'${Miner_Account_Apikey}'")|.remark')

		# Get account info
		local Miner_Account_Ip_Total_Arr=($(echo $CONFIG_JSON | jq -r '.miner[]|select(.apikey == "'${Miner_Account_Apikey}'")|.device[].sshIp'))

		unset Miner_Account_Ip_Online_Arr
		unset Miner_Account_Ip_Offline_Arr
		for i in ${Miner_Account_Ip_Total_Arr[*]}; do
			if [[ -f "$CONFIG_LOGS_DIR/miner-info-$i.log" ]]; then
				Miner_Account_Ip_Online_Arr[${#Miner_Account_Ip_Online_Arr[@]}]=$i
			else
				Miner_Account_Ip_Offline_Arr[${#Miner_Account_Ip_Offline_Arr[@]}]=$i
			fi
		done

		echo "______________________________________________________________________________________________________________________________"
		printf "%-26s %-45s %s\n" Name=$Miner_Account_Name Apikey=$Miner_Account_Apikey "Online=${#Miner_Account_Ip_Online_Arr[*]}/${#Miner_Account_Ip_Offline_Arr[*]}/${#Miner_Account_Ip_Total_Arr[*]}"
		echo

		# Output online miner
		printf "%-12s %-4s %-6s %-5s %-5s %-5s %-6s %-6s %-11s %-4s %-4s %-5s %-9s %-37s %s\n" IP SSH HOST AVG CPU TEMP MEM USAGE MOUNT/PART BIN S/P DISK POWER APIKEY PROXY
		for i in ${Miner_Account_Ip_Online_Arr[*]}; do
			{
				local Miner_Account_Ip_Json=$(cat $CONFIG_LOGS_DIR/miner-info-$i.log | jq -r '.')

				# Hostname
				local Miner_Hostname=$(echo $Miner_Account_Ip_Json | jq -r '.device.system.hostname')
				# MachineId
				# local Miner_MachineId=$(echo $Miner_Account_Ip_Json | jq -r '.device.system.machineId')
				# CPU loadAvg
				local Miner_LoadAvg15=$(echo $Miner_Account_Ip_Json | jq -r '.device.cpu.loadAvg.avg15')			
				# CPU usage
				local Miner_CPU_Usage=$(echo $Miner_Account_Ip_Json | jq -r '.device.cpu.usage')
				# CPU temp
				local Miner_CPU_Temp=$(echo $Miner_Account_Ip_Json | jq -r '.device.cpu.temp')
				# Memory total
				local Miner_Memory_Total=$(echo $Miner_Account_Ip_Json | jq -r '.device.memory.total')
				# Memory usage
				local Miner_Memory_Usage=$(echo $Miner_Account_Ip_Json | jq -r '.device.memory.usage')
				# Disk info : Mounted Total
				local Miner_Disk_Disk_Arr=($(echo $Miner_Account_Ip_Json | jq -r '.device.disk.data.disk'))
				local Miner_Disk_Part_Arr=($(echo $Miner_Account_Ip_Json | jq -r '.device.disk.data.part'))
				local Miner_Disk_Mount_Arr=($(echo $Miner_Account_Ip_Json | jq -r '.device.disk.data.mount'))
				# Miner info : Name Screen Process Disk Power Apikey Proxy
				local Miner_Running_Screen=$(echo $Miner_Account_Ip_Json | jq -r '.miner.screen')
				local Miner_Running_Process=$(echo $Miner_Account_Ip_Json | jq -r '.miner.process')
				local Miner_Running_Bin=$(echo $Miner_Account_Ip_Json | jq -r '.miner.bin')
				local Miner_Config_File=$(echo $Miner_Account_Ip_Json | jq -r '.miner.config')
				local Miner_Config_Name=$(echo $Miner_Account_Ip_Json | jq -r '.miner.configYaml.name')
				local Miner_Config_Apikey=$(echo $Miner_Account_Ip_Json | jq -r '.miner.configYaml.apikey')
				local Miner_Config_Proxy=$(echo $Miner_Account_Ip_Json | jq -r '.miner.configYaml.proxy')
				local Miner_Config_Disk_Arr=($(echo $Miner_Account_Ip_Json | jq -r '.miner.configYaml.disk'))
				local Miner_Logs_Power=$(echo $Miner_Account_Ip_Json | jq -r '.miner.logs.power')

				printf "%-13s %-3s %-6s %-5s %-5s %-5s %-6s %-8.1f %-10s %-3s %-5s %-4s %-9s %-37s %-28s\n" $i 1 $Miner_Hostname $Miner_LoadAvg15 ${Miner_CPU_Usage}% $Miner_CPU_Temp ${Miner_Memory_Total} ${Miner_Memory_Usage} ${#Miner_Disk_Mount_Arr[*]}/${#Miner_Disk_Part_Arr[*]} ${Miner_Running_Bin} ${Miner_Running_Screen}/${Miner_Running_Process} ${#Miner_Config_Disk_Arr[*]} ${Miner_Logs_Power} ${Miner_Config_Apikey} ${Miner_Config_Proxy}
				# echo ${Miner_Disk_Disk_Arr[*]}
			}&
		done
		wait

		# Output offline miner
		for i in ${Miner_Account_Ip_Offline_Arr[*]}; do
			echo "$i 0"
		done

	done


	unset Miner_Account_Ip_Online_Arr
	unset Miner_Account_Ip_Offline_Arr

	echo ok
}

Action_Miner_Start(){
	if [[ -n "$1" ]]; then
		Verify_IP_Validity $1
		Miner_Online_Ip_Arr=($1)
	fi
	for i in ${Miner_Online_Ip_Arr[*]}; do
		{
			echo "$i miner starting ... $(Remote_Miner_Start $i)"
		}&
	done
	wait
}

Action_Miner_Stop(){
	if [[ -n "$1" ]]; then
		Verify_IP_Validity $1
		Miner_Online_Ip_Arr=($1)
	fi
	for i in ${Miner_Online_Ip_Arr[*]}; do
		{
			echo "$i miner stopping ... $(Remote_Miner_Stop $i)"
		}&
	done
	wait
}

Action_Miner_Reboot(){
	if [[ -n "$1" ]]; then
		Verify_IP_Validity $1
		Miner_Online_Ip_Arr=($1)
	fi
	for i in ${Miner_Online_Ip_Arr[*]}; do
		{
			echo "$i miner rebooting ... $(Remote_Miner_Reboot $i)"
		}&
	done
	wait
}

Action_Miner_Mount(){
	if [[ -n "$1" ]]; then
		Verify_IP_Validity $1
		Miner_Online_Ip_Arr=($1)
	fi
	for i in ${Miner_Online_Ip_Arr[*]}; do
		{
			echo "$i miner mounting ... $(Remote_Miner_Mount $i)"
		}&
	done
	wait
}


Action_Miner_Init(){
	if [[ -n "$1" ]]; then
		Verify_IP_Validity $1
		Miner_Online_Ip_Arr=($1)
	fi
	for i in ${Miner_Online_Ip_Arr[*]}; do
		echo "$i miner initing ... $(Remote_Miner_Init $i)"
	done
}

Action_Miner_CMD(){
	
	if [[ -n "$1" ]]; then
		Verify_IP_Validity $1
		Miner_Online_Ip_Arr=($1)
	fi
	for i in ${Miner_Online_Ip_Arr[*]}; do
		{
			echo "$i : $(Remote_Miner_CMD $i)"
		}&
	done
	wait
}

Action_Config_Show(){
	echo
}
Action_Config_Add(){
	echo
}
Action_Config_Del(){
	echo
}
Action_Config_Import(){
	echo
}
Action_Config_Export(){
	echo
}

# Action_Config_Import(){

# 	# Check import config file path
# 	if [[ -n "$1" ]]; then
# 		local Temp_Config_Path=$(readlink -f $1)
# 	else
# 		echo "ERROR : please input the config file path !"
# 		exit 1
# 	fi

# 	# Check import config file exist
# 	if [[ ! -f "$Temp_Config_Path" ]]; then
# 		echo "ERROR : the config file '$Temp_Config_Path' does not exist !"
# 		exit 1
# 	fi

# 	# Check import config file JSON data
# 	local Temp_Config_Json=`cat $Temp_Config_Path 2>/dev/null | jq  2>/dev/null`
# 	if [[ -z "$Temp_Config_Json" ]]; then
# 		echo "ERROR : there are errors in the config '$Temp_Config_Path' !"
# 		exit 1
# 	fi

# 	# Check import config file data validity
# 	# Check server data validity
# 	read Temp_Server_Remark Temp_Server_Ip Temp_Server_Port Temp_Server_User Temp_Server_Pwd <<<"$(cat $Temp_Config_Path | jq -r '.server|.remark,.sshIp,.sshPort,.sshUser,.sshPwd' | xargs)"
# 	if [[ -z "$Temp_Server_Remark" ]] || [[ -z "$Temp_Server_Ip" ]] || [[ -z "$Temp_Server_Port" ]] || [[ -z "$Temp_Server_User" ]] || [[ -z "$Temp_Server_Pwd" ]]; then
# 		echo "ERROR : there are errors in the config '$Temp_Config_Path' about server !"
# 		cat $Temp_Config_Path | jq .server
# 		exit 1
# 	fi
# 	# Check miner data validity

# 	# Import config json
# 	if [[ ! -d $CONFIG_CONF_DIR ]]; then
# 		mkdir -p $CONFIG_CONF_DIR
# 	fi
# 	echo $Temp_Config_Json | jq > $CONFIG_CONF_FILE
# 	echo "Import config successful !"


# 	# echo $Temp_Server_Ip $Temp_Server_Port $Temp_Server_User $Temp_Server_Pwd

# 	# cat $Temp_Config_Path | jq -r '.server|.remark,.sshIp,.sshPort,.sshUser,.sshPwd' | xargs

# 	# # Verify server ssh login
# 	# 
# 	# if [[ -z "$Temp_Server_Port" ]]; then
# 	# 	Temp_Server_Port='22'
# 	# fi
# 	# Check_SSH_Validity $Temp_Server_Ip $Temp_Server_Port $Temp_Server_User $Temp_Server_Pwd
# 	# if [[ "$?" = "1" ]]; then
# 	# 	echo -e "      => Chia server ssh status : \033[32mSuccessful\033[0m"
# 	# else
# 	# 	echo -e "      => Chia server ssh status : \033[31mFailed\033[0m"
# 	# 	exit 1
# 	# fi
# }

Action_Server_Status(){
	echo
}
Action_Server_Start(){
	echo
}
Action_Server_Stop(){
	echo
}
Action_Server_Restart(){
	echo
}
Action_Server_Reboot(){
	echo
}
Action_Server_Init(){
	echo
}

######################################################################

Init_Env
Show_Banner
Load_Config
Get_Miner_Info
case $1 in
	miner )
		case $2 in
			status )
				Get_Miner_Info
				Action_Miner_Status
				;;
			start )
				Get_Miner_Info
				Action_Miner_Start $3
				;;
			stop )
				Get_Miner_Info
				Action_Miner_Stop $3
				;;
			reboot )
				Get_Miner_Info
				Action_Miner_Reboot $3
				;;
			mount )
				Get_Miner_Info
				Action_Miner_Mount $3
				;;
			init )
				Get_Miner_Info
				Action_Miner_Init $3
				;;
			cmd )
				Get_Miner_Info
				Action_Miner_CMD $3
				;;
		esac
		;;
	config )
		case $2 in
			show )
				Action_Config_Show
				;;
			add )
				Action_Config_Add $3
				;;
			del )
				Action_Config_Del $3
				;;
			import )
				Action_Config_Import $3
				;;
			export )
				Action_Config_Export $3
				;;
		esac
		;;
	server )
		case $2 in
			status )
				Get_Miner_Info
				Action_Server_Status
				;;
			start )
				Get_Miner_Info
				Action_Server_Start $3
				;;
			stop )
				Get_Miner_Info
				Action_Server_Stop $3
				;;
			restart )
				Get_Miner_Info
				Action_Server_Restart $3
				;;
			reboot )
				Get_Miner_Info
				Action_Server_Reboot $3
				;;
			init )
				Get_Miner_Info
				Action_Server_Init $3
				;;
		esac
		;;
esac

exit
