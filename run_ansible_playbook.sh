#!/bin/bash


## VARIABLES

snwl_option=
snwl_init_user=test1
snwl_main_user=swansible

snwl_subnet_string=
snwl_subnet_file=
snwl_network=


## FUNCTIONS

## Usage info
##
usage() {
    echo "Run the main ansible playbook to create/delete ansible user or install/configure FE agent"
    echo
    echo "Usage: run_ansible_playbook.sh -o <option> -s <subnet_string> -f <file_path> [-h]"
    echo "       -o <option>    Tell which task to run (create/delete/install)"
    echo "       -s <subnet>    Subnet string to scan (Ex: 192.168.10.0/24)"
    echo "       -f <filename>  File with list of subnets to scan, one subnet in each line"
    echo "       -h             Display the usage info"

}

# Run the ansibleplaybook with options selected
#
run_ansible_playbook() {
	local this_subnet=$1

        snwl_network=${this_subnet%/*}

	if [ ! -f ~/.ssh/id_rsa.pub ]; then
		echo "SSH Public Key file ~/.ssh/id_rsa.pub does not exist, please create. Exiting."
	else
		cat ~/.ssh/id_rsa.pub > roles/create_ansible_user/files/authorized_keys
	fi

	if [ "$snwl_option" == "create" ]; then
		echo "Proceeding to create ansible service account..."
		echo
		ansible-playbook snwl_main.yml --tags create_ansible_user -u $snwl_init_user -k -e "hostgrp=$snwl_network"
	elif [ "$snwl_option" == "delete" ]; then
		echo "Proceeding to delete the ansible service user account..."
		echo
		ansible-playbook snwl_main.yml --tags delete_ansible_user -u $snwl_init_user -k -e "hostgrp=$snwl_network"
	elif [ "$snwl_option" == "install" ]; then
		echo "Proceeding to install and configure FireEye Agent..."
		ansible-playbook snwl_main.yml --tags install_fe_agent -u $snwl_main_user -e "hostgrp=$snwl_network"
	fi
}


## Read the arguments passed
##
while getopts "ho:s:f:" OPTS
do
        case $OPTS in
        h)      usage
                exit 1
                ;;
        o)      snwl_option=$OPTARG;;
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

[[ -z "$snwl_option" ]] && { echo "No value provided for option, exiting."; exit 1; }

echo
echo "****** READ and CONFIRM *******"
echo
echo "This script should be used to perform one of the below actions.
  1. <create>  Create ansible service account (required)
  2. <install> Install FireEye Agent and configure (required)
  3. <delete>  Delete ansible service account (DO NOT USE unless needed)

  NOTE: The inventory file used for hosts is: inventory/hosts
"
echo

echo "The option selected in: $snwl_option"
if [ $snwl_option == "create" -o $snwl_option == "delete" ]; then
	echo "You need to enter the password for root user on target nodes when prompted"
fi

echo
read -p "DO YOU WANT TO PROCEED? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi


if [[ ! -z "$snwl_subnet_file" ]]
then
        echo "The file provided for subnets is $snwl_subnet_file"

        for SUBNET in $(cat $snwl_subnet_file)
        do
                echo "Running the ansible playbok for subnet $SUBNET..."
                run_ansible_playbook $SUBNET
        done
elif [[ ! -z "$snwl_subnet_string" ]]
then
        echo "The subnet provided is $snwl_subnet_string"

	echo "Running the ansible playbok for subnet $snwl_subnet_string..."
        run_ansible_playbook $snwl_subnet_string
else
        echo "ERROR: Either subnet or filename that contains subnets should be provided. Exiting."
	exit 1
fi

