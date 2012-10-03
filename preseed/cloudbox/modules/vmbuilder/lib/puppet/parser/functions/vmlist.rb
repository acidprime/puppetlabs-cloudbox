require 'puppet'
require 'puppet/face'
module Puppet::Parser::Functions
    newfunction(:vmlist, :type => :rvalue, :doc => "List VMs currently running") do |args|
      arguments = args[0]
      #arguments = { 'identity_username' => 'admin',
      #  'identity_password' => 'puppet',
      #  'tenant_name' => 'students',
      #  'keystone_host' => '10.0.0.1',
      #  'nova_host'     => '10.0.0.1'}
      vm_list = Puppet::Face[:node_openstack, :current].list(arguments)
      array_return = []
      vm_list.each do |vm_host|
        array_return.push(vm_host['name'])
      end
      array_return
    end
end
