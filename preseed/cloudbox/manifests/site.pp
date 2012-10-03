#
# This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#

filebucket { 'main':
  server => 'cloudbox.puppetlabs.vm',
  path   => false,
}
File { backup => 'main' }
####### shared variables ##################


# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments

# assumes that eth0 is the public interface
$public_interface  = 'eth0'
# assumes that eth1 is the interface that will be used for the vm network
# this configuration assumes this interface is active but does not have an
# ip address allocated to it. 
$private_interface = 'wlan0'
# credentials
$admin_email          = 'root@localhost'
$admin_password       = 'puppet'
$keystone_db_password = 'puppet'
$keystone_admin_token = 'puppet'
$nova_db_password     = 'puppet'
$nova_user_password   = 'puppet'
$glance_db_password   = 'puppet'
$glance_user_password = 'puppet'
$rabbit_password      = 'puppet'
$rabbit_user          = 'root'
$fixed_network_range  = '10.0.0.0/24'
# switch this to true to have all service log at verbose
$verbose              = 'true'


#### end shared variables #################

# all nodes whose certname matches openstack_all should be
# deployed as all-in-one openstack installations.
node default {

}
node 'cloudbox.puppetlabs.vm' {
  nova_config {
    #'auto_assign_floating_ip': value       =>'True';
    'dhcp_domain': value                   =>'puppetlabs.vm';
    'fixed_ip_disassociate_timeout': value => '1';
  }
  class { 'openstack::all':
    public_address       => '192.168.2.254',
    public_interface     => $public_interface,
    private_interface    => $private_interface,
    admin_email          => $admin_email,
    admin_password       => $admin_password,
    keystone_db_password => $keystone_db_password,
    keystone_admin_token => $keystone_admin_token,
    nova_db_password     => $nova_db_password,
    nova_user_password   => $nova_user_password,
    glance_db_password   => $glance_db_password,
    glance_user_password => $glance_user_password,
    rabbit_password      => $rabbit_password,
    rabbit_user          => $rabbit_user,
    libvirt_type         => 'kvm',
    fixed_range          => $fixed_network_range,
    verbose              => $verbose,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => '127.0.0.1',
  }
  include cloudbox
}
