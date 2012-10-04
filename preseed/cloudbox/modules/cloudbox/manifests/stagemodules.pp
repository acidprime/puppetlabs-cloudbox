class cloudbox::stagemodules {
  File {
    owner => 'root',
    group => 'root',
  }
  
  file { '.puppet':
    ensure => directory,
    path   => '/root/.puppet',
  }

  file { '.puppet/modules':
    ensure => directory,
    path   => '/root/.puppet/modules'
  }

  #file { 'concat-module':
  #  ensure => directory,
  #  path   => '/opt/puppet/share/puppet/modules/concat',
  #  source => '/cloudbox/modules/concat',
  #}

  #file { 'fundamentals-module':
  #  ensure => directory,
  #  path   => '/opt/puppet/share/puppet/modules/fundamentals',
  #  source => '/cloudbox/modules/fundamentals',
  #}

  file { 'node_openstack-module':
    ensure => directory,
    path   => '/root/.puppet/modules/node_openstack',
    source => '/cloudbox/modules/node_openstack',
  }

  file { 'vmbuilder-module':
    ensure => directory,
    path   => '/root/.puppet/modules/vmbuilder',
    source => '/cloudbox/modules/vmbuilder',
  }
}
