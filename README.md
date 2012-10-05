# Cloudbox setup    
These instructions cover building a new cloudbox   

## Hardware specifications    
+ Qty 1x Mac Mini Server Mid 2011 MC936LL/A (Macmini5,3) with 4GB Ram and Qty 1x 256 SSD upgrade.    
+ 16.0GB (8.0GB x 2 Kit) PC10600 DDR3 1333MHz SO-DIMM 204 Pin    
    
## Software specifications    
+ Ubuntu 12.0.4 (Precise) 64 bit   
+ Openstack 2012.X (ESSEX)    
    
## Introduction     
This solution was built to replace student downloaded virtual machines in the PuppetLabs trainings.    
Multiple things prompted its creation:    
    
1. The lack of interconnectivity on the wireless networks at many of our training sites.      
2. The expensive class time of getting a large number of student virtual machines running.    
3. To demo the Puppet cloud provisioner in the training classes.  
4. Consistancy in the course delivery
 
The solution acts as a wireless access point and allows students to connect to the private openstack network.    
Internet access ( if avaiable ) is provided by the systems built in ethernet port eth0   
Each student simply needs an ssh client and wireless card to complete the class.    
If a student is unable to connect to the wireless due to hardware issues, the horizon interface has a vnc console that runs in most web browsers, this site is accessible on the public interface on port 80 (http).  

### Virtual machines    
The setup process for the hypervisor its self has been automated using puppet modules. The instuctions below    
allow you to build an preseed'ed ubuntu install that will classify the modules. Internet access is required for building the environment but not required once the system is imaged. A public network interface is required but can simply be any active enternet connection with dhcp.
    
## Instructions for building preseeded iso     
These steps are only nessary if you do not already have a cloudbox thumb drive, or would like to update it.   
They are designed to be run from the unit itself, or in a ubuntu 12.0.4 virtual machine    
The default URLs are for faro, these require puppet labs VPN access. You can update these to local servers as well ( such as apache on your system).
`git clone git@github.com:acidprime/puppetlabs-cloudbox.git`      
`cd puppetlabs-cloudbox`      
`rake init`      
A new iso will be automatically created that can be used to image the system. 

### Copying iso to thumb drive     
While you can use dd via vmware's usb bridge, I suggest copying "cloudbox.iso" to your mac and using dd natively there.    
`diskutil unmount /Volumes/cloudbox`  
`dd if=/tmp/cloudbox.iso of=/dev/disk4 bs=1m`   
  
### Imaging the cloudbox 
Ensure ethernet is plugged into a system that supports dhcp ( such as internet sharing off of your laptop).  
Internet access is required for the intial install.
1. Boot system with the option/alt key held down.  
2. Plug the imaged thumbdrive ( can be done before this step ) 
3. An orange USB logo with the name "Windows" should appear  
4. Using the arrow keys or mouse select this icon with return key.  
5. Machine will automatically begin installation after booting from thumb drive 
6. Machine will reboot and configure puppet master & openstack.  
7. You can login now and continue with classroom setup 
    
# Classroom setup    
These instructions cover using a cloudbox in class   

## Provisioning master virtual machine (for use in class) 
1. Connect your laptop to the `Puppet` wireless network
1. Login to the cloudbox using ssh://root@10.0.0.1
  + The username is _root_ and the password is _puppet_.   
2. Export your ruby path (Puppet 2.7.X):    
  + `export RUBYLIB=/cloudbox/modules/node_openstack/lib/`    
3. Provision the master Virtual Machine:    
  + `puppet node_openstack create --identity_username=admin --identity_password=puppet --image=centos-5.7-pe-2.5.2 --type=m1.medium --tenant_name=students --keystone_host=10.0.0.1 --nova_host=10.0.0.1 --name=master --trace`   

4. You can now login to your master using the ip address allocated.
  + You can find the allocated ip using the horizon web interface at http://10.0.0.1
  + The horizon credentials are _admin_ and the password is _puppet_ 

## Provisioning agent virtual machines    
This step is done as a demo in class, I suggest connecting to the horizon web interface prior to this step.
Classify the `vmbuilder` module on the master. It will read from the $students ENC parameter and spin up only instances that are not running.    
The puppet functions do not give real time feedback, so you will want to login to the Horizon web interface to see the virtual machines sping up.    
If you are connected to the systems wireless network this address will be http://10.0.0.1 . The username is _admin_ and the password is _puppet_.    
    
## Known issues    
1. When spin'ing up over 10 VMs, the process may take up to 2 mins longer due to the openstack api limiting requests.    
2. Openstack will sometimes fail on networking when spining up 18 VMs. Simply terminate the instances and re-run `puppet agent -t`    
  + The `vmbuild` function should only rebuild the missing virtual machines
3. Due to the bridging the DHCP server is quite slow, I'm working on this however it takes a moment to get your lease.    
  + The lease time is 7 days so this is normally only an issue in the mornings and takes 1-2 mins at most.
  + Make sure you warn students about this as thier dhcp-client may timeout but then start working 30 seconds later.
4. While openstack is providing DNS records for puppetlabs.vm , DNS records will be removed on reboot of the hypervisor.    
  + The fundamentals class currently uses /etc/hosts files, think of this as a backup for this problem  
  + if you want to only use the `dns-masq` DNS you will need to shutdown and start the VMs each day rather then resume them.
5. The wireless network defaults to open as WPA has a timeout bug that disconnects students after 2/3 hours. 
6. Store configs are not enabled and show as warnings during the puppet run.
  + Single host so they are not needed. I am going to fix this later.
7. The Nova Volume service fails during startup.
  + its not needed and will be fixed later.

## Shutting the system down     
Each night you will need to suspend the student vms if you are not going to leave the cloudbox running overnight.    
__working on script/face for this__    
Once all virtual machines are suspended ( not paused ) you can issue a `shutdown -h now` to the hypervisor. 
    
## Handy commands to know    
`source /root/openrc`      
This command store the credentials used for the command line utils.    
`nova-manage vm list`      
Get a list of the current running virtual machines.    
`nova suspend _instanceid_`      
Suspend the specified instance    
`nova resume _instanceid_`      
Resume the specified instance    
`nova reboot _instanceid_`      
Reboot the specified instance    
`keystone --token puppet user-list`      
View the user list in keystone    
`keystone --token puppet tenant-list`      
View the tenant (group) list in keystone   

# Technical overview    
This section is a technial overview of the software setup.    
    
## Openstack setup
Openstack is being configured using the [puppetlabs/openstack](https://github.com/puppetlabs/puppetlabs-openstack) modules.
I am keeping a local copy in this repo as to not cause build failures as these modules are updated.

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
Note: this interface may loose its ipaddress to the bridge, do not use wlan0\_ facts as they will not work.  
I belive this is why dhcp is slow as this IP address migration causes isc-dhcp to lose track of its interface.  
    
## Bridge creation    
`cloudbox::network` configured the general network and bridge configuration. As mentioned the wireless    
configuration and the openstack system share a bridge. The preseed configuration file attempts to use dhcp    
if its unsuccessful, it will configure the system with 192.168.2.254/24 which will be reset at this step.    
Internet access is required for intial setup (currently) working on a offline mode  
    
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
This does not conflict with `dns-masq` due to `isc-dhcpd-server` listing on `wlan0`  
Effectively what happens is `dns-masq` allocates the ipaddresses for the Virtual machines using the 
bridge and `isc-dhcpd-server` allocates the ipaddress for the students laptops  using the `wlan0` interface.
 
## SSH keypair creation    
The ssh keys are automatically generated for the tenant using the `cloudbox::keypair` class.    
Note: This key is currently not retrieved on our centos training images, but is in meta data.    
You can find the pem file at `/root/.ssh/students.pem`    
    
## Student vitural machine upload.    
The student virtual machine (`qcow2` kvm image) is automatically copied during the rake process and copied to the /cloudbox build directory.    
This VM is automatically uploaded to glance by the `cloudbox::image` class.    
I am working on automating the creation of these `qcow2` images using a rake file.
However currently the [old](https://github.com/puppetlabs/puppetlabs-training-bootstrap) build process is able to easily build them:    
    
1. `kvm-img create -f qcow2 centos-5.7-pe-2.5.2.img 4G`    
2. `kvm -m 1024 -cdrom boot.iso -drive file=centos-5.7-pe-2.5.2.img,if=virtio,index=0 -boot d -net nic -net user -nographic -vnc :1`  
3. Connect to the VNC console running on port 5901    
4. Run through standard kickstart procedure we use with vmware.    
5. Shut down the VM when installation complete.    
6. ` glance add -I admin -K puppet name=centos-5.7-pe-2.5.2 is_public=true container_format=bare disk_format=qcow2 <centos-5.7-pe-2.5.2.img`      

Note: The final step is take care of using the `cloudbox::image` class if the image is stored in the /cloudbox directory.
    
## Student Virtual machines    
The students virtual machines are built using the `vmbuilder` class. It comprises a simple set of wrapper functions for my fork of `node_openstack`.    
The reason I needed to fork `node_openstack` was to have it use the native [openstack api](http://api.openstack.org/). With the native api we are able to specify the name    
of the instances that we are building. The `vmbuilder` class calls two functions `vmbuild` and `vmlist` , it looks to see if an instance with the same    
name already is listed in the openstack configuration and if so, it does not create that instance. This allows you to terminate any of the student    
instances and rebuild them ( you will have to reinstall puppet ). The VMs normally only spike the CPU during reboot, after that they sit around 20%    
    
## Tenant creation    
Openstack uses tenants (groups) to restrict access to virtual machines. A "students" tenant is created automatically using the `cloudbox::tenant` class.    
This is where all virtual machines live. I have also set up some execs that will automate the quota setups as they need to be raised to allow for more the 10 instances per quota    
