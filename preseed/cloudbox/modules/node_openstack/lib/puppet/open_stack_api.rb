require 'net/http'
require 'puppet'
# Zack Smith
# zack.smith@puppetlabs.com
# Open stack native API calls
# http://api.openstack.org/

module Puppet
  class OpenStackApi
   attr_accessor :identity_username
   attr_accessor :identity_password
   attr_accessor :nova_port
   attr_accessor :nova_host
   attr_accessor :keystone_port
   attr_accessor :keystone_host
   attr_accessor :tenant_name
   attr_accessor :debug
   attr_accessor :image_name
   attr_accessor :flavor_name
   attr_accessor :security_group

   def api_detect(options)
     # Default to using a token if we have one
     options['header'] = {
         'X-Auth-Token' => @token,
         'Content-Type' =>'application/json',}

     case options['api']
       when 'nova'
         options['port'] = @nova_port
         options['host'] = @nova_host

       when 'keystone'
         options['port'] = @keystone_port
         options['host'] = @keystone_host
         unless defined?(@token)
           options['header'] = {
                    'Content-Type' =>'application/json',}
         end
     end
     return options
   end

   def http_request(path, options = {},action = nil, expected_code = '200',data = nil)
     options = options.merge(api_detect(options))
     case options['type']
       when 'post'
         http = Net::HTTP::Post
       when 'get'
         http = Net::HTTP::Get
       when 'put'
         http = Net::HTTP::Put
       when 'delete'
         http = Net::HTTP::Delete
     end
     req = http.new(path,initheader = options['header'])

     # Set the form data
     req.body = data.to_pson if data

     # Wrap the request in an exception handler
     begin
       response = Net::HTTP.new(options['host'], options['port']).start {|http| http.request(req) }
     rescue Errno::EHOSTUNREACH => e
       Puppet.warning 'Host unreachable'
       Puppet.err "Could not connect to host #{options['host']} on port #{options['port']}"
       ex = Puppet::Error.new(e)
       ex.set_backtrace(e.backtrace)
       raise ex
     rescue Errno::ECONNREFUSED => e
       Puppet.warning 'Connection denied'
       Puppet.err "Could not connect to host #{options['host']} on port #{options['port']}"
       ex = Puppet::Error.new(e)
       ex.set_backtrace(e.backtrace)
       raise ex
     end
     # Return the parsed JSON response
     return handle_json_response(response, action, expected_code)
   end

   def handle_json_response(response, action, expected_code='200')
     #Puppet.info "#{response.body}"
     if response.code == expected_code
       Puppet.info "#{action} ... Done"
       PSON.parse response.body
     else
       Puppet.warning "#{action} ... Failed"
       Puppet.info("Body: #{response.body}")
       Puppet.warning "Server responded with a #{response.code} status"
       case response.code
         when /401/
           Puppet.notice "A 401 response is the HTTP code for an Unauthorized request"
         when /413/
           Puppet.notice "Server is rate limiting our requests"
           sleep(10)
           return nil
         end
       raise Puppet::Error, "Could not: #{action}, got #{response.code} expected #{expected_code} #{response.body}"
       end
   end

   # API Calls

   def delete_terminate_instance_by_name(name)
     delete_terminate_instance_by_id(get_server_id(name))
   end

   def delete_terminate_instance_by_id(server_id)
     path    = "/v2/#{@tenant_id}/servers/#{server_id}" 
     options = {
       'api'       => 'nova',
       'type'      => 'delete',}
     json_response = http_request(path,options,'Terminate Instance','204')
   end

   def post_xauthkey(username,password)
     path    = '/v2.0/tokens'
     body    = {
       'auth' => {"passwordCredentials" => {
       'username' => username,
       'password' => password,},
       'tenantName' => @tenant_name,},}
     options = {
       'api'       => 'keystone',
       'type'      => 'post',}
     json_response = http_request(path,options,'Generating Auth Key','200',body)
     return json_response['access']['token']['id']
   end

   def post_new_server(name)
     path = "/v2/#{@tenant_id}/servers"
     body = { 'server' =>{
       'name'              => name,
       'tenant_id'         => @tenant_id,
       'imageRef'          => @image_id,
       'flavorRef'         => @flavor_id,
     },}
     options = {
       'api'       => 'nova',
       'type'      => 'post',}
     json_response = http_request(path,options,'Creating new instance','202',body)
     begin
       return true
     rescue
       return false
     end
     return false
   end

   def post_security_group_rule(hash)
     path = "/v2/#{@tenant_id}/os-security-group-rules"
     body = { 'security_group_rule' => hash }
     options = {
       'api'       => 'nova',
       'type'      => 'post',}
     json_response = http_request(path,options,'Creating Security Group','200',body)
     return json_response
   end

   def post_gen_key(name)
     path = "/v2/#{@tenant_id}/os-keypairs"
     body = { 'keypair' =>{'name' => name,}}
     options = {
       'api'       => 'nova',
       'type'      => 'post',}
     json_response = http_request(path,options,'Generate SSH Key','202',body)
     return json_response['keypair']['fingerprint']
   end

   def get_tenant_id(name)
     path    = '/v2.0/tenants'
     options = {
       'api'       => 'keystone',
       'type'      => 'post',}
     json_response = http_request(path,options,'Get tenant ID','200')
     tenant_hash = json_response['tenants'].select do |tenant|
        if tenant['name'] == name
          return tenant['id']
        end
     end
   end

   def get_servers(servers_tenant_id)
     path    = "/v2/#{servers_tenant_id}/servers"
     options = {
       'api'       => 'nova',
       'type'      => 'get',}
     json_response = http_request(path,options,'Get server ID','200')
     json_response['servers']
   end

   def get_server_id(name)
     path    = "/v2/#{@tenant_id}/servers"
     options = {
       'api'       => 'nova',
       'type'      => 'get',}
     json_response = http_request(path,options,'Get server ID','200')
     server_hash = json_response['servers'].select do |server|
       if server['name'] == name
         return server['id']
       end
     end
   end

   def get_image_id(name)
     path    = "/v2/#{@tenant_id}/images"
     options = {
       'api'       => 'nova',
       'type'      => 'get',}
     json_response = http_request(path,options,'Get image ID','200')
     image_hash = json_response['images'].select do |image|
       if image['name'] == name
         return image['id']
       end
     end
   end

   def get_security_group_id(name)
       path    = "/v2/#{@tenant_id}/os-security-groups"
       options = {
       'api'       => 'nova',
       'type'      => 'get' ,}
       json_response = http_request(path,options,'Get security group ID','200')
       security_groups = json_response['security_groups'].select do |security_group|
       if security_group['name'] == name
         return Integer(security_group['id'])
       end
     end
   end

   def get_flavor_id(name)
     path    = "/v2/#{@tenant_id}/flavors"
     options = {
       'api'       => 'nova',
       'type'      => 'get',}
     json_response = http_request(path,options,'Get flavor ID','200')
     flavors_hash = json_response['flavors'].select do |flavor|
       if flavor['name'] == name
         return flavor['id']
       end
     end
   end

   def get_flavor_names(flavor_tenant_id = nil)
     path    = "/v2/#{flavor_tenant_id}/flavors"
     options = {
      'api'  => 'nova',
      'type' => 'get', }
      json_response = http_request(path,options,'Get flavors','200')
      flavor_names = []
      flavors_hash = json_response['flavors'].select do |flavor|
        flavor_names.push(flavor['name'])
     end
     return flavor_names
   end

   def get_key_hashes(flavor_tenant_id)
     path    = "/v2/#{flavor_tenant_id}/os-keypairs"
     options = {
      'api'  => 'nova',
      'type' => 'get', }
     json_response = http_request(path,options,'Get Keyhashes','200')
     key_hash = json_response['keypairs']
     return key_hash
   end

   def get_key_names(flavor_tenant_id)
     path    = "/v2/#{flavor_tenant_id}/os-keypairs"
     options = {
      'api'  => 'nova',
      'type' => 'get', }
     json_response = http_request(path,options,'Get Keynames','200')
     key_names = []
     key_hash = json_response['keypairs'].select do |keypair|
       key_names.push(keypair['keypair']['name'])
     end
     Puppet.info key_names
     return key_names
   end

   def get_image_details(image_tenant_id)
     path    = "/v2/#{image_tenant_id}/images/detail"
     options = {
      'api'  => 'nova',
      'type' => 'get', }
     json_response = http_request(path,options,'Get Image details','200')
     return json_response['images']
   end

   def put_rename(name)
     path = "/v2/#{@tenant_id}/servers/#{@server}"
     body = {"server" =>
       {"name" => name,},}
     options = {
       'api'       => 'nova',
       'type'      => 'put',}
       json_response = http_request(path,options,'Rename instance','200',body)
   end

   def create_connection(options)
    process_options(options)
    @token = post_xauthkey(@identity_username,@identity_password)
    @tenant_id = get_tenant_id(@tenant_name)
    return self
   end

   def process_options(options)
     options.each do |k,v|
        instance_variable_set("@#{k}",v)
        Puppet.info "#{k} = #{v}"
     end
   end

   def rename(name,new_name)
     #@server = get_server_id('zack')
     #  #put_rename('bob')
   end

   def create(options)
     process_options(options)
     @image_id  = get_image_id(@image)
     @flavor_id = get_flavor_id(@type)
     @security_group_id = get_security_group_id(@security_group)
     until post_new_server(@name)
     end
     return get_server_id(@name)
   end

   def list(options)
     create_connection(options)
     get_servers(@tenant_id)
   end

   def rule(hash = {}, name = 'default')
     hash['parent_group_id'] = get_security_group_id(name)
     post_security_group_rule(hash)
   end

   def terminate(instance_name)
     delete_terminate_instance_by_id(instance_name)
   end

   def key_pairs(options)
     create_connection(options)
     get_key_names(@tenant_id)
   end

   def list_keynames(options)
     create_connection(options)
     get_key_hashes(@tenant_id)
   end

   def images(options)
     create_connection(options)
     get_image_details(@tenant_id)
   end

   def flavors()
     get_flavor_names(@tenant_id)
   end

   def add_connection_options(action)
      action.option '--identity_username=' do
        summary 'Open stack username'
        description <<-EOT
          Username to use with the Identity API
          used to create an authentication token
        EOT
        required
      end

      action.option '--identity_password=' do
        summary 'Open stack password'
        description <<-EOT
          Password to use with the Identity API
          used to create an authentication token
        EOT
        required
      end

      action.option '--nova_port=' do
        summary 'Nova compute port'
        description <<-EOT
          The nova computer API port
          defaults to 8774
        EOT
        default_to { '8774' }
      end

      action.option '--nova_host=' do
        summary 'The nova compute host'
        description <<-EOT
          The hostname or IP address of the nova compute host
        EOT
        required
      end

      action.option '--keystone_host=' do
        summary 'The keystone indentity api host'
        description <<-EOT
          The hostname or IP address of the keystone indentity host
        EOT
        required
      end

      action.option '--keystone_port=' do
        summary 'Open stack password'
        description <<-EOT
          Password to use with the Identity API
          used to create an authentication token
        EOT
        default_to { '5000' }
      end

      action.option '--tenant_name=' do
        summary 'Tenant / Group name'
        description <<-EOT
          The name of the tenant (group) name to use
        EOT
       required
      end

      action.option '--security_group=' do
        summary 'Security Group'
        description <<-EOT
          The name of the  flavor to create the instance with
        EOT
        default_to { 'default' }
      end
    end
  end
end
