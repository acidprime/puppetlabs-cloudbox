class cloudbox::dhcpd{
  package {"isc-dhcp-server":
    ensure => installed,
    require => Class["cloudbox::network"],
  }
  file {"/etc/dhcp/dhcpd.conf":
    content => template("${module_name}/etc/dhcp/dhcpd.conf.erb"),
    require => File["/etc/default/isc-dhcp-server"],
  }
  file {"/etc/default/isc-dhcp-server":
    content => template("${module_name}/etc/default/isc-dhcp-server.erb"),
    require => Package["isc-dhcp-server"],
  }
  service {"isc-dhcp-server":
    ensure => running,
    enable => true,
    subscribe => File["/etc/dhcp/dhcpd.conf"],
  }
}
