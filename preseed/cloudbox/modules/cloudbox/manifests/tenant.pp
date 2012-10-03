class cloudbox::tenant {
  exec { "tenant-create":
    path    => "/usr/bin",
    environment => [ "OS_TENANT_NAME=openstack",
                     "OS_USERNAME=admin",
                     "OS_PASSWORD=puppet",
                     "OS_AUTH_URL=http://127.0.0.1:5000/v2.0/",
                     "OS_AUTH_STRATEGY=keystone",
                     "SERVICE_TOKEN=puppet",
                     "SERVICE_ENDPOINT=http://127.0.0.1:35357/v2.0/"],
    command => "keystone --token puppet tenant-create --name students --description students --enabled true",
    onlyif  => "keystone --token puppet tenant-list | awk \'/students/{exit 1}\'",
    notify  => [Exec['add_tenant_quota.sh'],Exec['add_tenant_privs.sh']],
  }
  file { '/tmp/add_tenant_quota.sh':
    ensure  => file,
    source  => "puppet:///modules/${module_name}/add_tenant_quota.sh",
  }
  exec { 'add_tenant_quota.sh':
    path        => '/bin',
    refreshonly => true,
    command     => "bash /tmp/add_tenant_quota.sh",
    require     => File['/tmp/add_tenant_quota.sh'],
  }

  file { '/tmp/add_tenant_privs.sh':
    ensure  => file,
    source  => "puppet:///modules/${module_name}/add_tenant_privs.sh",
  }
  exec { 'add_tenant_privs.sh':
    path        => '/bin',
    refreshonly => true,
    command     => "bash /tmp/add_tenant_privs.sh",
    require     => File['/tmp/add_tenant_privs.sh'], 
  }

}
