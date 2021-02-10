#!/bin/bash

# Variables

snwl_subnet_string=
snwl_subnet_file=
snwl_network=

snwl_reports_folder="./reports"
snwl_timestamp=$(date +'%m%d%y_%H%M%S')
snwl_reports_file=


# Functions

usage() {
    echo "Generates the FE agent info report for the given subnet(s)"
    echo
    echo "Usage: generate_report.sh -s <subnet_string> -f <file_path> [-h]"
    echo "       -s <subnet>    Subnet string to scan (Ex: 192.168.10.0/24)"
    echo "       -f <filename>  File with list of subnets to generate report, one subnet in each line"
    echo "       -h             Display the usage info"
}

generate_report() {
        local this_subnet=$1

        snwl_network=${this_subnet%/*}
	snwl_timestamp=$(date +'%m%d%y_%H%M%S')
	snwl_reports_file="${snwl_reports_folder}/${snwl_network}_fe_agent_info_${snwl_timestamp}.csv"

	echo "HOSTNAME, OS DIST, OS VERSION, ANSBL SVC ACCT, FE PKG, FE SVC" > /tmp/fireeye_agent_info.csv

	ansible-playbook generate_report.yml -u swansible -e "hostgrp=$snwl_network"

	echo
	echo "FE AGENT INFO ON TARGET NODES: "
	echo "=============================="
	echo

	mv /tmp/fireeye_agent_info.csv $snwl_reports_file
	echo "The generated report is in file $snwl_reports_file."
	echo
	cat $snwl_reports_file
	echo
}

## Read the arguments passed
##
while getopts "hs:f:" OPTS
do
        case $OPTS in
        h)      usage
                exit 1
                ;;
        s)      snwl_subnet_string=$OPTARG;;
        f)      snwl_subnet_file=$OPTARG;;
        \?)     usage
                exit 1
                ;;
        esac
done
shift $((OPTIND -1))


## MAIN
##

if [[ ! -z "$snwl_subnet_file" ]]
then
        echo "The file provided for subnets is $snwl_subnet_file"

        for SUBNET in $(cat $snwl_subnet_file)
        do
                echo "Generating the report for subnet $SUBNET..."
                generate_report $SUBNET
        done
elif [[ ! -z "$snwl_subnet_string" ]]
then
        echo "The subnet provided is $snwl_subnet_string"

        echo "Generating the report for subnet $snwl_subnet_string..."
        generate_report $snwl_subnet_string
else
        echo "ERROR: Either subnet or filename that contains subnets should be provided. Exiting."
        exit 1
fi

