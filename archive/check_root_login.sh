#!/bin/bash

## VARIABLES

snwl_username=root
snwl_host_group=
snwl_subnet=


## FUNCTIONS

## Usage info
##
usage() {
    echo "Checks the node(s) login with the username and password provided"
    echo
    echo "Usage: check_root_login.sh [-h]"
    echo "       -h			Display the usage info"
}

check_login() {
	ansible $snwl_host_group -m ping -u $snwl_username -k > /tmp/node_login_info.txt

	echo
	cat /tmp/node_login_info.txt | egrep 'SUCCESS|UNREACHABLE' | awk '{print $1,"",$3}'

	echo
	echo "Updating the inventory file ./inventory/hosts with nodes reachable"

	[[ -f ./inventory/hosts ]] && mv ./inventory/hosts ./inventory/hosts.bkup2
	echo "[main]" > ./inventory/hosts
	cat /tmp/node_login_info.txt | grep 'SUCCESS' |  awk '{print $1}' >> ./inventory/hosts
}


## Read the arguments passed
##
while getopts "hu:s:" OPTS
do
        case $OPTS in
        h)      usage
                exit 1
                ;;
        u)      snwl_username=$OPTARG;;
        s)      snwl_subnet=$OPTARG;;
        \?)     usage
                exit 1
                ;;
        esac
done
shift $((OPTIND -1))


## MAIN
##

snwl_host_group=${snwl_subnet%/*}

check_node_login

