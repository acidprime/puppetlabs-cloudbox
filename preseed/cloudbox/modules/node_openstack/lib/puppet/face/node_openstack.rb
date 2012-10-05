require 'puppet/face'
require 'puppet/open_stack_api'
Puppet::Face.define(:node_openstack, '0.0.2') do
  copyright "Puppet Labs", 2011
  license   "Apache 2 license; see COPYING"
  summary "View and manage openstack nodes."

  description <<-'EOT'
    This subcommand provides a command line interface to manage Openstack
    machine instances. The goal of these actions is to easily create new
    machine and tear them down when they're no longer
    required.
  EOT
end
