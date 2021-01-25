#!/bin/bash

## VARIABLES

snwl_username=
snwl_host_group=


## FUNCTIONS

## Usage info
##
usage() {
    echo "Checks the node(s) login with the username and password provided"
    echo
    echo "Usage: check_nodes_login.sh -u <username> -g <host group> [-h]"
    echo "       -h			Display the usage info"
}

check_node_login() {
	ansible $snwl_host_group -m ping -u $snwl_username -k > /tmp/node_login_info.txt
	echo
	cat /tmp/node_login_info.txt | egrep 'SUCCESS|UNREACHABLE' | awk '{print $1,"",$3}'
	echo
	rm -f /tmp/node_login_info.txt
}


## Read the arguments passed
##
while getopts "hu:g:" OPTS
do
        case $OPTS in
        h)      usage
                exit 1
                ;;
        u)      snwl_username=$OPTARG;;
        g)      snwl_host_group=$OPTARG;;
        \?)     usage
                exit 1
                ;;
        esac
done
shift $((OPTIND -1))


## MAIN
##
check_node_login

