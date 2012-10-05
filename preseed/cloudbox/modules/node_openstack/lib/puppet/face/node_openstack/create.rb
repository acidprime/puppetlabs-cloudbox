require 'puppet/face/node_openstack'
Puppet::Face.define :node_openstack, '0.0.2' do

  action :create do
    summary 'Create a new machine instance.'
    description <<-EOT
      Launches a new OpenStack machine instance and returns the
      machine's identifier.

      A newly created system may not be immediately ready after launch while
      it boots.

      If creation of the instance fails, Puppet will automatically clean up
      after itself and tear down the instance.
    EOT

    Puppet::OpenStackApi.new.add_connection_options(self)

    option '--name=' do
      summary 'The name of your new instance'
      description <<-EOT
        The name of the instance to launch
      EOT

      required
    end

    option '--type=' do
      summary 'Type / Flavor of instance.'
      description <<-EOT
        Type of instance to be launched. The type specifies characteristics that
        a machine will have, such as memory, processing power, storage,
        and IO performance.
      EOT

      required
    end

    option '--image=' do
      summary 'Open stack image name'
      description <<-EOT
        The name of the image that exists on the system
      EOT
     required
    end

    option '--keyname=' do
      summary 'The SSH key name that identifies the public key to be injected into the created instance.'
      description <<-EOT
        The identifier of the SSH public key to inject into the instance's
        authorized_keys file when the instance is created.

        This keyname should identify the public key that corresponds with the
        private key identified by the --keyfile option of the `node` subcommand's
        `install` action.

        You can use the `list_keynames` action to get a list of valid key pairs for the
        specified endpoint.
      EOT

      #required

      before_action do |action, args, options|
        if not Puppet::OpenStackApi.new.key_pairs(options).include?(options[:keyname])
          raise ArgumentError, "Unrecognized key name: #{options[:keyname]} (Suggestion: use the puppet node_openstack list_keynames action to find a list of valid key names for your account.)"
        end
      end
    end

    when_invoked do |options|
      Puppet::OpenStackApi.new.create_connection(options).create(options)
    end
  end
end
