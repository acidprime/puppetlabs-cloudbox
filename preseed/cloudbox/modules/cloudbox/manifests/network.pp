class cloudbox::network {

  $br_inf     = 'br100'
  $wlan_inf   =  'wlan0'

  if ! defined(Package['bridge-utils']){
    package { 'bridge-utils':
      ensure => installed,
    }
  }
  # Configure the bridge
  exec { 'brctl_addbr':
    path    => '/sbin:/usr/bin',
    command => "brctl addbr ${br_inf}",
    unless  => "brctl show ${br_inf} 2>&1 | awk '/No such device/{exit 1}'",
    require => Package['bridge-utils'],
  }
  file { '/etc/network/interfaces':
    ensure  => file,
    content => template("${module_name}/etc/network/interfaces.erb"),
    notify  => Service['networking'],
    require => Exec['brctl_addbr'],
  }
  service { 'networking' :
    ensure => running,
  }
}
