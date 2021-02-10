## Create Ansible Service User and Install packages

- Requires Ansible 2.5 or newer
- Expects CentOS/RHEL or Ubuntu servers
- The ansible log file is at /var/log/ansible.log

These playbooks has to roles.

1. Role "create_ansible_user"
This role creates the Ansible service account on the target Linux nodes
defined in the Ansible inventory file. It then setups the account for 
password-less SSH access and also enables it for SUDO access.

2. Role "install_fe_agent" 
This role installs the required FireEye agent package on the target Linux servers.
It then imports the agent config provided and starts the service.

3. Role "delete_ansible_user" (DO NOT USE this role unless required)
This role deletes the Ansible service account on the target Linux nodes.

4. Script "scan_subnets.sh"
Run this script as below to scan a given subnet to find which hosts are UP. 
The nodes that are UP are put into the inventory file - inventory/hosts.

./scan_subnet.sh -s "172.31.19.0/24" (to provide one subnet)
./scan_subnet.sh -f subnets.txt (to provide multiple subnets in a file, with one subnet per line)




## MAIN ##

1. Scan the subnet(s) as below.

	$ ./scan_subnets.sh -s "172.31.19.0/24" (NOTE: to provide one subnet)
				OR
	$ ./scan_subnet.sh -f subnets.txt       (NOTE: to provide multiple subnets in file, one per line)

	NOTE: Use the correct subnet as required; Also, use -r option to force recan of any subnet

This will create/update master inventory hosts file - inventory/hosts - with 
the list of nodes that are UP.
The host group will be named as the subnet id in the inventory file.

NOTE: 
 -  The master inventory file - inventory/hosts will not be overwritten with subsequent
scans, it will only get updated as required.
 -  Once a subnet is scanned, it will be skipped next time. To force a rescan of that subnet, 
use "-r" option to the script.


2. Create the ansible service account on the target nodes in inventory file
	$ ./run_ansible_playbook.sh -o create -s "172.31.19.0/24"  (NOTE: to provide one subnet)
						OR
	$ ./run_ansible_playbook.sh -o create -f subnets.txt       (NOTE: to provide multiple subnets in file, one per line)


NOTE: You will have to run this twice for different root passwords


3. Install and configure the FireEye agent on the target nodes in inventory file
        $ ./run_ansible_playbook.sh -o install -s "172.31.19.0/24"  (NOTE: to provide one subnet)
                                                OR
        $ ./run_ansible_playbook.sh -o install -f subnets.txt       (NOTE: to provide multiple subnets in file, one per line)

	
NOTE: The "install" option uses the ansible service account, so you only run it once per subnet


4. (DO NOT RUN THIS UNLESS REQUIRED IN FUTURE) 
   Delete the ansible service account on the target nodes in inventory file
        $ ./run_ansible_playbook.sh -o delete -s "172.31.19.0/24"  (NOTE: to provide one subnet)
                                                OR
        $ ./run_ansible_playbook.sh -o delete -f subnets.txt       (NOTE: to provide multiple subnets in file, one per line)

NOTE: You will have to run this twice for different root passwords



## REPORT GENERATION

TO generate a report for a subnet
	$  ./generate_report.sh -s "172.31.31.0/24"

NOTE:
  - This will use the ansible service account "swansible"; If account is not created, do that first
  - This will create the report csv file under reports folder. The report will have subnet and 
timestamp in the file name and this file will not be overwritten.



## Pre-requisites:

1. On the node where these ansible playbooks or scripts are being run (i.e. ANSIBLE SERVER), the user 
account needs to have the SSH keys generated. The public key will be used for the 
ansible service account on target nodes to setup SSH key-based login

To generate the SSH keys for the user, run the below on the ANSIBLE Server`:
$ ssh-keygen -t rsa -b 2048
NOTE: This is needed ONLY on the Ansible server


