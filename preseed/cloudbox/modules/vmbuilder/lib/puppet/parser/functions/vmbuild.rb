require 'puppet'
require 'puppet/face'
module Puppet::Parser::Functions
    newfunction(:vmbuild, :type => :rvalue, :doc => "Build VMs for Puppet Training") do |args|
      vm_hostname = args[0]
      arguments = { 'identity_username' => 'admin',
        'identity_password' => 'puppet',
        'image' => 'centos-5.7-pe-2.5.2',
        'type'  =>  'm1.tiny',
        'tenant_name' => 'students',
        'keystone_host' => '10.0.0.1',
        'nova_host'     => '10.0.0.1',
        'name'         => vm_hostname }
      vm_id = Puppet::Face[:node_openstack, :current].create(arguments)
    end
end
