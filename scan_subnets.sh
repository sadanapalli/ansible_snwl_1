#!/bin/bash

#####################################################################################
##                                                                                 ##
## This script scans the subnet(s) to check which hosts are up and then creates    ##
## or updates the master inventory file with the network name as the host group.   ##
##                                                                                 ##
## If the host group with network name already exists, it adds any new IPs not     ##
## present under that host group.                                                  ##
##                                                                                 ##
#####################################################################################

## VARIABLES

snwl_subnet_string=
snwl_subnet_file=
snwl_subnet_scan_report_temp="/tmp/snwl_subnet_scan_report_temp.txt"
snwl_subnet_scan_report="/tmp/snwl_subnet_scan_report.txt"

snwl_inventory_master=./inventory/hosts
snwl_timestamp=$(date +'%m%d%y_%H%M%S')
snwl_scan_tracker=.snwl_subnet_scan_tracker.txt
snwl_subnet_rescan='no'

snwl_network=
snwl_netmask=



## FUNCTIONS

## Usage info
##
usage() {
    echo "Checks the node(s) login with the username and password provided"
    echo
    echo "Usage: scan_subnets.sh -s <subnet_string> -f <file_path> [-h]"
    echo "       -s <subnet>    Subnet string to scan (Ex: 192.168.10.0/24)"
    echo "       -f <filename>  File with list of subnets to scan, one subnet in each line"
    echo "       -h             Display the usage info"
}

# Check the subnet in master inventory file
#
check_subnet() {
	if grep -Fwq $snwl_network $snwl_inventory_master
	then
		return 0
	else
		return 1
	fi
}

# Add missing IPs to existing subnet in master inventory
#
add_ips_to_subnet() {
	for IP in $(cat $snwl_subnet_scan_report_temp | grep ^Host | awk '{print $2}')
	do
		if ! grep -Fwq $IP $snwl_inventory_master
		then
			sed -i "/^\[$snwl_network\]/a $IP" $snwl_inventory_master
		fi
	done
}

# Add a subnet and ips under that host group
#
add_subnet_and_ips() {
	echo "[$snwl_network]" >> $snwl_inventory_master
	cat $snwl_subnet_scan_report_temp | grep ^Host | awk '{print $2}' >> $snwl_inventory_master
	echo >> $snwl_inventory_master
}

# Scan the given subnet to find the hosts that are up
#
scan_subnet() {
	local this_subnet=$1
	
	snwl_network=${this_subnet%/*}
	snwl_netmask=${this_subnet#*/}
	
	if [ $snwl_subnet_rescan == 'yes' ]; then
		echo "Scanning the subnet $this_subnet on force rescan..."
		nmap -sn -n $this_subnet -oG $snwl_subnet_scan_report_temp > /dev/null
		sleep 2
		if ! grep -Fxq "$this_subnet" $snwl_scan_tracker; then
			# track the subnet that is scanned
			echo $this_subnet >> $snwl_scan_tracker
		fi
	elif ! grep -Fxq "$this_subnet" $snwl_scan_tracker; then
		echo "Scanning the subnet $this_subnet..."
                nmap -sn -n $this_subnet -oG $snwl_subnet_scan_report_temp > /dev/null
                sleep 2

		# track the subnet that is scanned
                echo $this_subnet >> $snwl_scan_tracker
	elif grep -Fxq "$this_subnet" $snwl_scan_tracker; then
		echo "Skipping the scan of subnet $this_subnet as it was already scanned"
		# Emptying the old file due to skipped scan
		echo >  $snwl_subnet_scan_report_temp
	fi
}


## Read the arguments passed
##
while getopts "hs:f:r" OPTS
do
        case $OPTS in
        h)      usage
                exit 1
                ;;
        s)      snwl_subnet_string=$OPTARG;;
        f)      snwl_subnet_file=$OPTARG;;
        r)      snwl_subnet_rescan='yes';;
        \?)     usage
                exit 1
                ;;
        esac
done
shift $((OPTIND -1))


## MAIN
##
[[ -f $snwl_inventory_master ]] && cp -p $snwl_inventory_master ${snwl_inventory_master}_${snwl_timestamp} || touch $snwl_inventory_master

touch $snwl_scan_tracker

if [[ ! -z "$snwl_subnet_file" ]]
then
	echo "The file provided for subnets is $snwl_subnet_file"

	for SUBNET in $(cat $snwl_subnet_file)
	do
		echo "Scanning the subnet $SUBNET..."
		scan_subnet $SUBNET

		echo "Updating inventory master file for subnet $SUBNET..."
		if check_subnet
		then
			add_ips_to_subnet
		else
			add_subnet_and_ips	
		fi
	done
elif [[ ! -z "$snwl_subnet_string" ]]
then
	echo "The subnet provided is $snwl_subnet_string"

	echo "Scanning the subnet $snwl_subnet_string..."
	scan_subnet $snwl_subnet_string

	echo "Updating inventory master file for subnet $snwl_subnet_string..."
	if check_subnet
	then
		add_ips_to_subnet
	else
		add_subnet_and_ips
	fi
else
	echo "ERROR: Either subnet or filename that contains subnets should be provided. Exiting."
	exit 1
fi
