class cloudbox::reset {
  exec {"security_group_instance_association":
    path    => "/usr/bin"
    command => "mysql -e \'USE nova; DELETE FROM security_group_instance_association\'"
  }
}
