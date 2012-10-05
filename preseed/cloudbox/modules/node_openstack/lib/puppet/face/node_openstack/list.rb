require 'puppet/cloudpack'
require 'puppet/face/node_openstack'

Puppet::Face.define :node_openstack, '0.0.2' do

  action :list do

    summary 'List machine instances.'
    description <<-EOT
      Obtains a list of instances from the specified endpoint and
      displays them on the console. Only the instances being managed
      by that endpoint are listed.
    EOT

    Puppet::OpenStackApi.new.add_connection_options(self)

    when_invoked do |options|
      Puppet::OpenStackApi.new.list(options)
    end

  end
end
