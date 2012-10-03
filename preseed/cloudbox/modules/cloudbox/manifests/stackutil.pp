class cloudbox::stackutil {
  package { 'git':
    ensure => installed,
  }
  file { "/usr/src/stackutil":
    ensure => directory,
  }
  vcsrepo { "/usr/src/stackutil":
      ensure   => 'bare',
      provider => git,
      source   => 'git://code.seas.harvard.edu/openstack/stackutil.git',
      require  => [Package['git'],File["/usr/src/stackutil"]],
  }
  exec { "stackutil_setup.py":
    path     => "/usr/bin",
    command => "python /usr/src/stackutil/setup.py install",
    unless   => "test -x /usr/local/bin/stackutil",
    require  => Vcsrepo["/usr/src/stackutil"],
  }
}
