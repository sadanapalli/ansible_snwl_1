## Create Ansible Service User and Install packages

- Requires Ansible 2.5 or newer
- Expects CentOS/RHEL or Ubuntu servers

These playbooks has to roles.

1. Role "createuser"
This role creates the Ansible service account on the target Linux nodes
defined in the Ansible inventory file. It then setups the account for 
password-less SSH access and also enables it for SUDO access.

2. Role "installpkg" (work-in-progress)
This role installs the required packages on the target Linux servers.

Run the playbook, like below:

1. Just to run the "createuser" role
       # ansible-playbook snwl_test.yml --tags createuser

2. Just to run the "installpkg" role
       # ansible-playbook snwl_test.yml --tags installpkg

NOTE: When no tag is supplied, it will run both the roles.

3. When the host group name in the ansible inventory file is different, say "linux_servers", then run the playbook as below to input that host group name
       # ansible-playbook snwl_test.yml --tags createuser -e "hostgrp=linux_servers"

## Pre-requisites:

1. Modify the ansible hosts inventory file (inventory/hosts) as required with target servers
2. Modify the Ansible service account details as required in roles/createuser/vars/main.yml
3. Modify ansible.cfg file with the initial remote-user name that will be used to create the Ansible service account name; Later, it can be changed to the Ansible service account name
4. Modify the file roles/createuser/files/authorized_keys with the actual SSH public key from the central server from where the playbook will be run
