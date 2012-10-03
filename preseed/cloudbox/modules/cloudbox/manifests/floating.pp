class cloudbox::floating {
  exec { 'nova-manage_create_ip_range':
    path    => "/usr/bin",
    environment => [ "OS_TENANT_NAME=students",
                     "OS_USERNAME=admin",
                     "OS_PASSWORD=puppet",
                     "OS_AUTH_URL=http://127.0.0.1:5000/v2.0/",
                     "OS_AUTH_STRATEGY=keystone",
                     "SERVICE_TOKEN=puppet",
                     "SERVICE_ENDPOINT=http://127.0.0.1:35357/v2.0/"],
    command => "nova-manage floating create --ip_range=192.168.2.64/26",
    unless  => "nova-manage floating list 2>&1 | awk \'/No floating IP addresses have been defined./{exit 1}\'",
    require => Class['cloudbox::tenant'],
  }
}
