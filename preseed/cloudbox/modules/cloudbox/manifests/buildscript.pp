class cloudbox::buildscript {
  file { 'build-master.sh':
    ensure => file,
    mode   => 755,  
    path   => '/root/build-master.sh',
    source => "puppet:///modules/${module_name}/build-master.sh",
  }
}
