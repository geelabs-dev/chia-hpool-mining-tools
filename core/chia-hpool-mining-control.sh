#!/usr/bin/env bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

Init_Env(){
	MINER_BASE_DIR='/opt/chia/miner'
	MINER_DATA_MOUNTPOINT='/chia-point'
	type sensors jq screen ifconfig sshpass >/dev/null 2>&1 || apt install lm-sensors jq screen net-tools sshpass -y >/dev/null 2>&1

	# Change machine id
	# cp -f /dev/null /etc/machine-id >/dev/null 2>&1
	# systemd-machine-id-setup >/dev/null 2>&1

	rm -rf ~/.ssh/known_hosts
	# rm -rf /opt/chia
}

##################################################################################################################


Get_System_Info(){
	# Host Name
	System_Hostname=`cat /etc/hostname`

	# Machine Id
	System_MachineId=`cat /etc/machine-id`

	# Board Manufacturer
	Board_Manufacturer=`dmidecode | grep -A4 "^Base Board Information" | grep "Manufacturer" | sed 's/.*.Manufacturer: //'`

	# Board Product Name
	Board_ProductName=`dmidecode | grep -A4 "^Base Board Information" | grep "Product Name" | sed 's/.*.Product Name: //'`

	# Board Version
	Board_Verison=`dmidecode | grep -A4 "^Base Board Information" | grep "Version:" | sed 's/.*.Version: //'`

	# Board Version
	Board_SerialNumber=`dmidecode | grep -A4 "^Base Board Information" | grep "Serial Number" | sed 's/.*.Serial Number: //'`

	# Bios Vendor
	Bios_Vendor=`dmidecode | grep -A3 "^BIOS Information" | grep "Vendor" | sed 's/.*.Vendor: //'`

	# Bios Version
	Bios_Verison=`dmidecode | grep -A3 "^BIOS Information" | grep "Version" | sed 's/.*.Version: //'`

	# Bios Release Date
	Bios_ReleaseDate=`dmidecode | grep -A3 "^BIOS Information" | grep "Release Date" | sed 's/.*.Release Date: //'`

	# CPU Model
	CPU_Model=`lscpu | grep "^Model name:" | awk -F ':' '{print $2}' | sed 's/^\s*//'`

	# CPU Sockets
	CPU_Sockets=`lscpu | grep "^Socket(s):" | awk -F ':' '{print $2}' | sed 's/^\s*//'`

	# CPU Cores
	CPU_Cores=`lscpu | grep "^Core(s) per socket:" | awk -F ':' '{print $2}' | sed 's/^\s*//'`

	# CPU Threads
	CPU_Threads=`lscpu | grep "^CPU(s):" | awk -F ':' '{print $2}' | sed 's/^\s*//'`

	# CPU Arch
	CPU_Arch=`lscpu | grep "^Architecture:" | awk -F ':' '{print $2}' | sed 's/^\s*//'`

	# CPU Bit
	CPU_Bit=`getconf LONG_BIT`

	# CPU Cur Freq
	CPU_Cur_Freq=`lscpu | grep "^CPU MHz:" | awk '{print $NF}'`

	# CPU Max Freq
	CPU_Max_Freq=`lscpu | grep "^CPU max MHz:" | awk '{print $NF}'`

	# CPU Min Freq
	CPU_Min_Freq=`lscpu | grep "^CPU min MHz:" | awk '{print $NF}'`

	# 获取CPU负载
	read CPU_LoadAverage_1 CPU_LoadAverage_5 CPU_LoadAverage_15 CPU_LoadAverage_Task CPU_LoadAverage_Process <<< "$(cat /proc/loadavg)"
	# cat /proc/loadavg
	# $1 1分钟内的平均进程数
	# $2 5分钟内的平均进程数
	# $3 15分钟内的平均进程数
	# $4 正在运行的进程数/进程总数
	# $5 最后一个最近运行的进程ID号

	# CPU Usage
	CPU_Usage=`top -bn1 | grep "^\%Cpu(s):" | sed 's/%Cpu(s)://' | sed 's/^\s*//' | awk '{print $1}'`

	# CPU Temp
	CPU_Temp=`sensors | grep "^Package id 0:" | sed 's/Package id 0://' | sed 's/^\s*.+//' | awk '{print $1}' | sed 's/°C//'`

	# Total Task
	Task_Total=`top -bn1 | grep "Tasks:" | awk -F ',' '{print $1}' | sed 's/Tasks://' | awk '{print $1}'`

	# Running Task
	Task_Running=`top -bn1 | grep "Tasks:" | awk -F ',' '{print $2}' | awk '{print $1}'`

	# Sleeping Task
	Task_Sleeping=`top -bn1 | grep "Tasks:" | awk -F ',' '{print $3}' | awk '{print $1}'`

	# Stopped Task
	Task_Stopped=`top -bn1 | grep "Tasks:" | awk -F ',' '{print $4}' | awk '{print $1}'`

	# Zombie Task
	Task_Zombie=`top -bn1 | grep "Tasks:" | awk -F ',' '{print $5}' | awk '{print $1}'`

	# Memory Status
	read Memory_Total Memory_Used Memory_Free Memory_Shared Memory_Cache Memory_Avail Memory_Usage <<< "$(free -m | grep "^Mem" | sed 's/^Mem://' | awk '{print $1,$2,$3,$4,$5,$6,($1-$6)/$1*100}')"

	# Swap Status
	read Swap_Total Swap_Used Swap_Free <<< "$(free -m | grep "^Swap" | sed 's/^Swap://' | awk '{print $1,$2,$3}')"

	# Disk Status
	read Disk_Root_Filesystem Disk_Root_Total Disk_Root_Used Disk_Root_Avail Disk_Root_Usage Disk_Root_Mounted <<< "$(df -h | grep "/$" | awk '{print $1,$2,$3,$4,$5,$6}')"
	
	unset Disk_Data_Disk_Arr
	unset Disk_Data_Part_Arr
	unset Disk_Data_Mount_Arr
	Disk_Data_Disk_Arr=($(lsblk -l | grep disk | grep T | grep -v "/$" | grep "^sd*" | awk '{print $1}'))
	for i in ${Disk_Data_Disk_Arr[*]}; do
		if [[ -n "$(lsblk -l | grep part | grep T | grep -v "/$" | grep "^${i}[0-9]*" | awk '{print $1}')" ]]; then
			Disk_Data_Part_Arr[${#Disk_Data_Part_Arr[@]}]=$(lsblk -l | grep part | grep T | grep -v "/$" | grep "^${i}[0-9]*" | awk '{print $1}')
		else
			Disk_Data_Part_Arr[${#Disk_Data_Part_Arr[@]}]=$i
		fi
	done
	Disk_Data_Mount_Arr=($(df -h | grep "$MINER_DATA_MOUNTPOINT" | grep T | awk '{print $1}' | sed 's/\/dev\///'))
	# lsblk -l | grep T | grep "^sd[a-z]\{1,2\}[0-9]"

	# Network
	read Network_MacAddress Network_LanIp <<< "$(ip addr | grep "state UP" -A2 | grep -v "state UP" | awk '{print $2}' | xargs)"
	Network_WanIp=`curl -s cip.cc | grep "^IP" | awk '{print $NF}'`
}

Get_Miner_Info(){
	# Miner Screen
	Get_Miner_Screen
	if [[ "${#Miner_Screen_Arr[*]}" != "0" ]]; then
		Miner_Screen=1
	else
		Miner_Screen=0
	fi

	# Miner Process
	Get_Miner_Process
	if [[ "${#Miner_Process_Arr[*]}" != "0" ]]; then
		Miner_Process=1
	else
		Miner_Process=0
	fi

	# Miner Bin
	if [[ -f "$MINER_BASE_DIR/hpool-miner-chia-linux-amd64" ]]; then
		Miner_Bin=1
	else
		Miner_Bin=0
	fi

	# Miner Config
	if [[ -f "$MINER_BASE_DIR/config.yaml" ]]; then
		Miner_Config=1
	else
		Miner_Config=0
	fi

	# Miner Yaml
	Miner_Config_Json=$(cat $MINER_BASE_DIR/config.yaml 2>/dev/null | yq -o j)
	Miner_Config_Name=`echo $Miner_Config_Json | jq -r '.minerName'`
	Miner_Config_Apikey=`echo $Miner_Config_Json | jq -r '.apiKey'`
	Miner_Config_Disk=`echo $Miner_Config_Json | jq -r '.path[]'`
	Miner_Config_Proxy=`echo $Miner_Config_Json | jq -r '.url.proxy'`
	Miner_Running_Power=$(cat ${MINER_BASE_DIR}/log/miner.log.log 2>/dev/null| grep "capacity=" | tail -n 1 | sed 's/^.*.capacity=//' | awk -F '"' '{print $2}' | sed 's/[[:space:]]//g')
	if [[ -z "$Miner_Running_Power" ]]; then
		Miner_Running_Power=0
	fi
}

Get_Miner_Screen(){
	Miner_Screen_Arr=($(ps -ef | grep chia-miner-screen | grep -v grep | awk '{print $2}'))
}

Get_Miner_Process(){
	Miner_Process_Arr=($(ps -ef | grep hpool-miner* | grep -v grep | awk '{print $2}'))
}

Get_Miner_Mount(){
	Get_System_Info
	for i in ${Disk_Data_Part_Arr[@]}; do
		local Miner_Disk_Point=${MINER_DATA_MOUNTPOINT}/$i

		if [[ -z "$(df -h | grep "$Miner_Disk_Point")" ]]; then
			mkdir -p ${Miner_Disk_Point}
			# ntfsfix /dev/${i} >/dev/null 2>&1
			mount /dev/${i} ${Miner_Disk_Point}
			# echo "mount /dev/${i} -> ${Miner_Disk_Point}"
		fi
	done
}

##################################################################################################################

Control_Miner_Info(){
	Get_System_Info
	Get_Miner_Info
# 生成报告 json
cat << _END_
{
	"device": {
		"system": {
			"datatime": "$(date "+%Y-%m-%d %H:%M:%S")",
			"hostname": "${System_Hostname}",
			"machineId": "${System_MachineId}"
		},
		"board": {
			"manufacturer": "${Board_Manufacturer}",
			"product": "${Board_ProductName}",
			"verison": "${Board_Verison}",
			"Serial": "${Board_SerialNumber}",
			"bios": {
				"vendor": "${Bios_Vendor}",
				"verison": "${Bios_Verison}",
				"releaseDate": "${Bios_ReleaseDate}"
			}
		},
		"cpu": {
			"model": "${CPU_Model}",
			"sockets": "${CPU_Sockets}",
			"cores": "${CPU_Cores}",
			"threads": "${CPU_Threads}",
			"arch": "${CPU_Arch}",
			"bit": "${CPU_Bit}",
			"freq": {
				"cur": "${CPU_Cur_Freq}",
				"max": "${CPU_Max_Freq}",
				"min": "${CPU_Min_Freq}"
			},
			"loadAvg": {
				"avg1": "${CPU_LoadAverage_1}",
				"avg5": "${CPU_LoadAverage_5}",
				"avg15": "${CPU_LoadAverage_15}",
				"task": "${CPU_LoadAverage_Task}",
				"process": "${CPU_LoadAverage_Process}"
			},
			"usage": "${CPU_Usage}",
			"temp": "${CPU_Temp}"
		},
		"task": {
			"total": "${Task_Total}",
			"running": "${Task_Running}",
			"sleeping": "${Task_Sleeping}",
			"stopped": "${Task_Stopped}",
			"zombie": "${Task_Zombie}"
		},
		"memory": {
			"total": "${Memory_Total}",
			"used": "${Memory_Used}",
			"free": "${Memory_Free}",
			"shard": "${Memory_Shared}",
			"cache": "${Memory_Cache}",
			"avail": "${Memory_Avail}",
			"usage": "${Memory_Usage}"
		},
		"swap": {			
			"total": "${Swap_Total}",
			"used": "${Swap_Used}",
			"free": "${Swap_Free}"
		},
		"disk": {
			"root": {
				"filesystem": "${Disk_Root_Filesystem}",
				"mounted": "${Disk_Root_Mounted}",
				"total": "${Disk_Root_Total}",
				"used": "${Disk_Root_Used}",
				"avail": "${Disk_Root_Avail}",
				"usage": "${Disk_Root_Usage}"
			},
			"data": {
				"disk": "${Disk_Data_Disk_Arr[*]}",
				"part": "${Disk_Data_Part_Arr[*]}",
				"mount": "${Disk_Data_Mount_Arr[*]}",
				"path": "${MINER_DATA_MOUNTPOINT}",
				"total": "${Disk_Data_Total_Arr[*]}"
			}
			
		},
		"network": {
			"wanIp": "${Network_WanIp}",
			"lanIp": "${Network_LanIp}",
			"macAddress": "${Network_MacAddress}"
		}
	},
	"miner": {
		"screen": "${Miner_Screen}",
		"process": "${Miner_Process}",
		"bin": "${Miner_Bin}",
		"config": "${Miner_Config}",
		"configYaml": {
			"name": "${Miner_Config_Name}",
			"apikey": "${Miner_Config_Apikey}",
			"disk": "${Miner_Config_Disk}",
			"proxy": "${Miner_Config_Proxy}"
		},
		"logs": {
			"power": "${Miner_Running_Power}"
		}
	},
	"code": 200,
	"message": "OK"
}
_END_
}

Control_Miner_Start(){
	Control_Miner_Stop

	Get_Miner_Mount
	
	# Create config file
	local Miner_Apikey=$2
	local Miner_Proxy=$3
	local Miner_Mount_Point=($(find ${MINER_DATA_MOUNTPOINT}/sd* -name "plot-*.plot" | egrep "plot-k.*.plot$" | sed 's/\/plot-k.*.plot$//g' | uniq))
	# # Debug
	# echo "Miner_Mount_Point : $Miner_Apikey $Miner_Proxy"
	# for i in ${Miner_Mount_Point[*]}; do
	# 	echo $i
	# done

	# Init Env
	local Miner_Config_File=$MINER_BASE_DIR/config.yaml
	rm -rf $Miner_Config_File && touch $Miner_Config_File

	# Create miner config file
	yq -i '.token = ""' $Miner_Config_File
	yq -i '.path[] = ""' $Miner_Config_File
	yq -i '.minerName = "'${System_Hostname}'"' $Miner_Config_File
	yq -i '.apiKey = "'${Miner_Apikey}'"' $Miner_Config_File
	yq -i '.cachePath = ""' $Miner_Config_File
	yq -i '.deviceId = ""' $Miner_Config_File
	yq -i '.extraParams = {}' $Miner_Config_File
	yq -i '.log.lv = "info"' $Miner_Config_File
	yq -i '.log.path = "./log"' $Miner_Config_File
	yq -i '.log.name = "miner.log"' $Miner_Config_File
	yq -i '.url.info = ""' $Miner_Config_File
	yq -i '.url.submit = ""' $Miner_Config_File
	yq -i '.url.line = ""' $Miner_Config_File
	yq -i '.url.ws = ""' $Miner_Config_File
	yq -i '.url.proxy = "'${Miner_Proxy}'"' $Miner_Config_File
	yq -i '.proxy.url = ""' $Miner_Config_File
	yq -i '.proxy.username = ""' $Miner_Config_File
	yq -i '.proxy.password = ""' $Miner_Config_File
	yq -i '.scanPath = false' $Miner_Config_File
	yq -i '.proxy.password = ""' $Miner_Config_File
	yq -i '.proxy.password = ""' $Miner_Config_File
	yq -i '.scanMinute = "0"' $Miner_Config_File
	yq -i '.debug = ""' $Miner_Config_File
	yq -i '.language = "cn"' $Miner_Config_File
	yq -i '.line = "cn"' $Miner_Config_File
	yq -i '.multithreadingLoad = false' $Miner_Config_File
	for i in ${!Miner_Mount_Point[@]}; do
		yq -i '.path["'$i'"] = "'${Miner_Mount_Point[$i]}'"' $Miner_Config_File
	done

	# Start miner bin
	if [[ -f "$Miner_Config_File" ]]; then
		screen -dmS chia-miner-screen
		screen -x -S chia-miner-screen -p 0 -X stuff $'cd '"${MINER_BASE_DIR}"'\n'
		screen -x -S chia-miner-screen -p 0 -X stuff $'clear && ls\n'
		screen -x -S chia-miner-screen -p 0 -X stuff $'./hpool-miner*\n'
	fi
}

Control_Miner_Stop(){
	Get_Miner_Screen
	if [[ "${#Miner_Screen_Arr[*]}" != "0" ]]; then
		for i in ${Miner_Screen_Arr[*]}; do
			kill -9 $i >/dev/null 2>&1
		done
	fi
	screen -wipe >/dev/null 2>&1
}

Control_Miner_Restart(){
	Control_Miner_Stop
	Control_Miner_Start
}

Control_Miner_Reboot(){
	reboot
}

Control_Miner_Mount(){
	Get_Miner_Mount
}

Control_Miner_Init(){

	Control_Miner_Stop

	local Server_SSH_Ip=$2
	local Server_SSH_Port=$3
	local Server_SSH_User=$4
	local Server_SSH_Pwd=$5
	local Server_SSH_Path=$6

	# Debug
	# echo "Server_SSH_Ip   : $Server_SSH_Ip"
	# echo "Server_SSH_Port : $Server_SSH_Port"
	# echo "Server_SSH_User : $Server_SSH_User"
	# echo "Server_SSH_Pwd  : $Server_SSH_Pwd"
	# echo "Server_SSH_Path : $Server_SSH_Path"
	# echo "Miner_Apikey    : $Miner_Apikey"
	# echo "Miner_Proxy     : $Miner_Proxy"

	# # Create chia miner base dir
	rm -rf $MINER_BASE_DIR && mkdir -p $MINER_BASE_DIR && cd $MINER_BASE_DIR

	# Get miner bin
	sshpass -p "${Server_SSH_Pwd}" scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 -P ${Server_SSH_Port} -r ${Server_SSH_User}@${Server_SSH_Ip}:${Server_SSH_Path}/hpool-miner* ${MINER_BASE_DIR}
	# echo "install hpool"

	# Get yq bin
	if ! type yq >/dev/null 2>&1; then
		sshpass -p "${Server_SSH_Pwd}" scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 -P ${Server_SSH_Port} -r ${Server_SSH_User}@${Server_SSH_Ip}:${Server_SSH_Path}/yq* ${MINER_BASE_DIR}
		chmod +x yq*
		mv yq* /usr/bin/yq
	fi
	# echo "install yq"

}

Control_Miner_CMD(){
	Get_System_Info
	# # Get_Miner_Mount
	# Control_Miner_Stop
	cat /etc/hostname
	# echo "${Disk_Data_Part_Arr[*]}"
	for i in ${Disk_Data_Disk_Arr[*]}; do
		$i
	done

	# unset Disk_Data_Disk_Arr
	# unset Disk_Data_Part_Arr
	# unset Disk_Data_Mount_Arr
	# Disk_Data_Disk_Arr=($(lsblk -l | grep disk | grep T | grep -v "/$" | grep "^sd*" | awk '{print $1}'))
	# for i in ${Disk_Data_Disk_Arr[*]}; do
	# 	if [[ -n "$(lsblk -l | grep part | grep T | grep -v "/$" | grep "^${i}[0-9]*" | awk '{print $1}')" ]]; then
	# 		Disk_Data_Part_Arr[${#Disk_Data_Part_Arr[@]}]=$(lsblk -l | grep part | grep T | grep -v "/$" | grep "^${i}[0-9]*" | awk '{print $1}')
	# 	else
	# 		Disk_Data_Part_Arr[${#Disk_Data_Part_Arr[@]}]=$i
	# 	fi
	# done
	# Disk_Data_Mount_Arr=($(df -h | grep "$MINER_DATA_MOUNTPOINT" | grep T | awk '{print $1}' | sed 's/\/dev\///'))
	# # lsblk -l | grep T | grep "^sd[a-z]\{1,2\}[0-9]"


}

##################################################################################################################

Init_Env
case $1 in
	minerinfo )
		Control_Miner_Info
		;;
	minerstart )
		Control_Miner_Start $*
		;;
	minerstop )
		Control_Miner_Stop
		;;
	minerrestart )
		Control_Miner_Restart
		;;
	minerreboot )
		Control_Miner_Reboot
		;;
	minermount )
		Control_Miner_Mount
		;;
	minerinit )
		Control_Miner_Init $*
		;;
	minercmd )
		Control_Miner_CMD
		;;
esac
