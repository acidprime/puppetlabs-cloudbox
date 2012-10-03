class cloudbox::keypair {
  file { '/root/.ssh':
    ensure => directory,
  }
  exec { 'students':
    path        => '/usr/bin',
    environment => [ "OS_TENANT_NAME=students",
                     "OS_USERNAME=admin",
                     "OS_PASSWORD=puppet",
                     "OS_AUTH_URL=http://127.0.0.1:5000/v2.0/",
                     "OS_AUTH_STRATEGY=keystone",
                     "SERVICE_TOKEN=puppet",
                     "SERVICE_ENDPOINT=http://127.0.0.1:35357/v2.0/"],
    command     => 'nova keypair-add students > /root/.ssh/students.pem',
    unless      => 'test -f /root/.ssh/students.pem',
    require     => [ File['/root/.ssh'],Class['cloudbox::tenant']]
  }
}
