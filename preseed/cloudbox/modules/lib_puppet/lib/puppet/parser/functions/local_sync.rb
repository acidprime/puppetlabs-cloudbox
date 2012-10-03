module Puppet::Parser::Functions
  newfunction(:local_sync) do |args|
    Puppet[:pluginsource] = 'puppet:///plugins'
  end
end
