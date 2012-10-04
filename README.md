# Cloudbox setup  
These instructions cover building a new cloudbox  
## Hardware specifications  
+ Qty 1x Mac Mini Server Mid 2011 MC936LL/A (Macmini5,3) with 4GB Ram and Qty 1x 256 SSD upgrade.  
+ 16.0GB (8.0GB x 2 Kit) PC10600 DDR3 1333MHz SO-DIMM 204 Pin  
  
## Software specifications  
+ Ubuntu 12.0.4 (Precise) 64 bit 
+ Openstack 2012.X (ESSEX)  
  
## Introduction   
This solution was built to replace student virtual machines in the puppet training labs.  
Multiple things prompted its creation:  
  
1. The lack of interconnectivity on the wireless networks at microtek training sites.    
2. The expensive class time of getting a large number of student virtual machines running.  
3. To show off the puppet cloud provisioner in the training classes.  
  
The solution acts as a wireless access point and allows students to connect to the private openstack network.  
Internet access ( if avaiable is provided by the systems built in ethernet port eth0 )  
Each student simply needs an ssh client and wireless card to complete the class.  
If a student is unable to connect to the wireless due to hardware issues, the horizon interface has a vnc console that runs in most web browsers.  
  
### Virtual machines  
Virtual machines are automatically allocated using a puppet enterprise console parameter.  
The setup process for the hypervisor has been automated using puppet modules. The instuctions below  
allow you to build an preseed'ed ubuntu install that will classify the modules.  
  
## Instructions for building preseeded iso   
These steps are only nessary if you do not already have a cloudbox thumb drive, or would like to update it. 
They are designed to be run from the unit itself, or in a ubuntu 12.0.4 virtual machine  
`git clone git@github.com:acidprime/puppetlabs-cloudbox.git`    
`cd puppetlabs-cloudbox`    
`rake init`    
  
### Copying iso to thumb drive   
While you can use dd via vmware's usb bridge, I suggest coping "cloudbox.iso" to your mac and using dd natively there.  
`diskutil unmount /Volumes/cloudbox;dd if=/tmp/cloudbox.iso of=/dev/disk4 bs=1m`    
  
# Classroom setup  
These instructions cover using a cloudbox in class  
## Provisioning master virtual machine  
1. Login to the cloudbox using ssh. The username is _root_ and the password is _puppet_.  
2. Export your ruby path (Puppet 2.7.X):  
  + `export RUBYLIB=/cloudbox/modules/node_openstack/lib/`  
3. Provision the master Virtual Machine:  
  + `puppet node_openstack create --identity_username=admin --identity_password=puppet --image=centos-5.7-pe-2.5.2 --type=m1.medium --tenant_name=students --keystone_host=10.0.0.1 --nova_host=10.0.0.1 --name=master --trace`  
  
## Provisioning agent virtual machines  
Classify the vmbuilder module on the master. It will read from the $students ENC parameter and spin up only instances that are not running.  
The puppet functions do not give real time feedback, so you will want to login to the Horizon web interface to see the virtual machines sping up.  
If you are connect to the systems wireless network this address will be http://10.0.0.1 . The username is _admin_ and the password is _puppet_.  
  
## Common issues  
1. When spin'ing up over 10 VMs, the process may take up to 2 mins longer due to the openstack api limiting requests.  
2. Openstack will sometimes fail on networking when spining up 18 VMs. Simply terminate the instances and re-run `puppet agent -t`  
3. Due to the bridging the DHCP server is quite slow, I'm working on this however it takes a moment to get your lease.  
  + The lease time is 7 days so this is normally only an issue in the mornings and takes 1-2 mins at most.  
4. While openstack is providing DNS records for puppetlabs.vm , DNS records will be removed on reboot of the hypervisor.  
  + The class currently uses /etc/hosts files, think of this as a backup.  
  + if you want to only use the `dns-masq` DNS you will need to shutdown and start the VMs each day rather then resume them  
  
## Shutting the system down   
Each night you will need to suspend the student vms if you are not going to leave the cloudbox running overnight.  
__working on script/face for this__  
Once all virtual machines are suspended ( not paused ) you can issue a `shutdown -h now` command.  
  
## Handy commands to know  
`source /root/openrc`    
This command store the credentials used for the command line utils.  
`nova-manage vm list`    
Get a list of the current running virtual machines.  
`nova suspend _instanceid_`    
Suspend the specified instance  
`nova resume`    
Resume the specified instance  
`nova reboot`    
Reboot the specified instance  
`keystone --token puppet user-list`    
View the user list in keystone  
`keystone --token puppet tenant-list`    
View the tenant (group) list in keystone  
# Technical overview  
This section is a technial overview of the software setup.  
  
## Wireless access point  
Currently the system will automatically create an ESSID of _Puppet_. This is configured using the `cloudbox::hostapd` class.  
This class installs the following packages from `ppa:mpodroid/mactel`  
1. `b43-fwcutter`  
2. `firmware-b43-installer`  
3. `linux-backports-modules-cw-3.3-precise-generic`  
Addtionally we install `hostapd` and configure it using an erb template  
`  
  file { "/etc/default/hostapd":  
    content => template("${module_name}/etc/default/hostapd.erb"),  
    ...  
  file { "/etc/hostapd/hostapd.conf":  
    content => template("${module_name}/etc/hostapd/hostapd.conf.erb"),  
    ...  
`  
Openstack and hostapd share a bridge `br100` and `wlan0` becomes the private network interface for openstack.  
This class will automatically add `wlan0` as a member of this bridge.  
Note this interface may loose its ipaddress to the bridge, do not use wlan0\_ facts as they will not work.  
  
## Bridge creation  
`cloudbox::network` configured the general network and bridge configuration. As mentioned the wireless  
configuration and the openstack system share a bridge. The preseed configuration file attempts to use dhcp  
if its unsuccessful, it will configure the system with 192.168.2.254/24 which will be reset at this step.  
  
## DHCP Server configuration  
Openstack maintains `dns-masq` configurations in its `mysql-server` database.  
This providers the DNS hostnames and ipaddress for the host virtual machines.  
`isc-dhcp-server` is installed and configured using the `cloudbox::dhcpd` class.  
`  
  file {"/etc/dhcp/dhcpd.conf":  
    content => template("${module_name}/etc/dhcp/dhcpd.conf.erb"),  
    ...  
  file {"/etc/default/isc-dhcp-server":  
    content => template("${module_name}/etc/default/isc-dhcp-server.erb"),  
    ...  
`  
This does not conflict with dns-masq due to listing on `wlan0`  
However given the bridge be aware the DHCP server is very slow the first time clients connect.  
  
## SSH keypair creation  
The ssh keys are automatically generated for the tenant using the `cloudbox::keypair` class.  
Note: This key is currently not retrieved on our centos training images, but is in meta data.  
You can find the pem file at `/root/.ssh/students.pem`  
  
## Student vitural machine upload.  
The student virtual machine is automatically copied during the rake process and copied to the /cloudbox build directory.  
This VM is automatically uploaded to glance by the `cloudbox::image` class.  
I am working on automating the creation of these `qcow2` images using a rake file. However currently the [old](https://github.com/puppetlabs/puppetlabs-training-bootstrap) build process is able to easily build them:  
  
1. ` kvm-img create -f qcow2 centos-5.7-pe-2.5.2.img 4G`  
2. `kvm \    
-m 1024 \    
-cdrom boot.iso \    
-drive file=centos-5.7-pe-2.5.2.img,if=virtio,index=0 \    
-boot d \    
-net nic \    
-net user \    
-nographic -vnc :1`    
3. Connect to the VNC console running on port 5901  
4. Run through standard kickstart procedure we use with vmware.  
5. Shut down the VM when installation complete.  
6. ` glance add \    
-I admin \    
-K puppet \    
name=centos-5.7-pe-2.5.2  \    
is_public=true \    
container_format=bare \    
disk_format=qcow2 <centos-5.7-pe-2.5.2.img`    
Note: The final step is take care of using the `cloudbox::image` class    
  
## Student Virtual machines  
The students virtual machines are built using the `vmbuilder` class. It comprises a simple set of wrapper functions for my fork of `node_openstack`.  
The reason I needed to fork `node_openstack` was to have it use the native openstack api. With the native api we are able to specify the name  
of the instances that we are building. The `vmbuilder` class calls two functions `vmbuild` and `vmlist` , it looks to see if an instance with the same  
name already is listed in the openstack configuration and if so, it does not create that instance. This allows you to terminate any of the student  
instances and rebuild them ( you will have to reinstall puppet ). The VMs normally only spike the CPU during reboot, after that they sit around 20%  
  
## Tenant creation  
Openstack uses tenants (groups) to restrict access to virtual machines. A "students" tenant is created automatically using the `cloudbox::tenant` class.  
This is where all virtual machines live. I have also set up some execs that will automate the quota setups as they need to be raised to allow for more the 10 instances per quota  
