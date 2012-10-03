class cloudbox::hostapd {
  $hostapd_interface = 'wlan0'
  $hostapd_bridge    = 'br100'
  $hostapd_ssid      = 'Puppet'
  $hostapd_wpa        = true
  $hostapd_wpa_passphrase = 'puppetlabs'
  include apt
  apt::ppa{ 'ppa:mpodroid/mactel': }

  package { ["b43-fwcutter","firmware-b43-installer","linux-backports-modules-cw-3.3-precise-generic"]:
    ensure  => present,
    require => Apt::Ppa['ppa:mpodroid/mactel'],
  }

  package { "python-software-properties":
    ensure => installed,
  }

  package { "hostapd":
    ensure  => installed,
  }

  service { "hostapd":
    ensure  => running,
    enable  => true,
    subscribe => File["/etc/hostapd/hostapd.conf"],
  }

  file { "/etc/default/hostapd":
    content => template("${module_name}/etc/default/hostapd.erb"),
    require => Package['hostapd'],
  }
  file { "/etc/hostapd/hostapd.conf":
    content => template("${module_name}/etc/hostapd/hostapd.conf.erb"),
    require => File['/etc/default/hostapd'],
    notify  => Service['hostapd'],
  }

  exec { 'brctl_addif_wlan':
    path    => '/sbin:/usr/bin',
    command => "brctl addif ${br_inf} ${wlan_inf}",
    onlyif  => "brctl show ${br_inf} | awk \'/$wlan_inf/{exit 1}\'",
    require => File['/etc/hostapd/hostapd.conf'],
  }
}
