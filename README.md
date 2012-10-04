# Cloudbox setup
These instructions cover building a new cloudbox
## Hardware specifications
+ Qty 1x Mac Mini Server Mid 2011 MC936LL/A (Macmini5,3) with 4GB Ram and Qty 1x 256 SSD upgrade.
+ 16.0GB (8.0GB x 2 Kit) PC10600 DDR3 1333MHz SO-DIMM 204 Pin

## Software specifications
+ Ubuntu 12.0.4 (Precise)
+ Openstack 2012.X (ESSEX)

## Introduction 
This solution was built to replace student virtual machines in the puppet training labs.
The solution acts as a wireless access point and allows students to connect to the private openstack network.
Internet access ( if avaiable is provided by the systems built in ethernet port eth0 )

### Virtual machines
Virtual machines are automatically allocated using a puppet enterprise console parameter.
The setup process for the hypervisor has been automated using puppet modules. The instuctions below
allow you to build an preseed'ed ubuntu install that will classify the modules.

## Instructions for building preseeded iso 
These steps are only nessary if you do not already have a cloudbox thumb drive, or would like to update it.
`git clone git@github.com:acidprime/puppetlabs-cloudbox.git`  
`cd puppetlabs-cloudbox`  
`rake init`  

### Copying iso to thumb drive 
While you can use dd via vmware's usb bridge, I suggest coping "cloudbox.iso" to your mac and using dd natively there.
`diskutil unmount /Volumes/cloudbox;dd if=/tmp/cloudbox.iso of=/dev/disk4 bs=1m`  

# Classroom setup

## Provisioning master virtual machine
1. Login to the cloudbox using ssh. The username is _root_ and the password is _puppet_.
2. Export your ruby path (Puppet >3.1):
  + `export RUBYLIB=/cloudbox/modules/node_openstack/lib/`
3. Provision the master Virtual Machine:
  + `puppet node_openstack create --identity_username=admin --identity_password=puppet --image=centos-5.7-pe-2.5.2 --type=m1.medium --tenant_name=students --keystone_host=10.0.0.1 --nova_host=10.0.0.1 --name=master --trace`

## Provisioning agent virtual machines
Classify the vmbuilder module on the master. It will read from the $students ENC parameter and spin up only instances that are not running.

## Common issues
1. When spin'ing up over 10 VMs, the process may take up to 2 mins longer due to the openstack api limiting requests.
2. Openstack will sometimes fail on networking when spining up 18 VMs. Simply terminate the instances and re-run `puppet agent -t`

## Shutting the system down 
Each night you will need to suspend the student vms if you are not going to leave the cloudbox running overnight.
__working on script/face for this__
Once all virtual machines are suspended ( not paused ) you can issue a `shutdown -h now` command.

