require 'puppet/face/node_openstack'

Puppet::Face.define :node_openstack, '0.0.2' do

  action :list_images do

    summary 'List available images.'
    description <<-EOT
      Obtains a list of images from the ec2 api endpoint
      and displays them on the console output. Only the images being managed
      by the specified api endpoint are listed.
    EOT

    Puppet::OpenStackApi.new.add_connection_options(self)

    when_invoked do |options|
      Puppet::OpenStackApi.new.images(options)
    end

    when_rendering :console do |value|
      value.collect do |image|
        "#{image['id']}" + image.map do |field,val|
          if(val and val != [] and val != {} and field != 'id')
            if(val.is_a?(Array))
              val.each {|v| print v, "#{field} = #{v}" }
            else
              "#{field} = #{val}"
            end
          end
        end.join("\n")
      end.join("\n")
    end
  end
end
