# == Define: lib_puppet
#
# lib_puppet is to assist file management under the ruby lib puppet directory.
#
# === Parameters
#
# [*ensure*]
#   state of file, present/absent
# [*lib_puppet*]
#   The target directory to copy files to.
# [*recurse*]
#   Whether to recurse into a directory.
#
# === Examples
#
#  lib_puppet { 'puppet_face.rb':
#    ensure => present,
#  }
#
define lib_puppet (
  $ensure     = present,
  $lib_puppet = "${::puppet_install_dir}/puppet",
  $recurse    = false
) {
  case $ensure {
    'present','installed':  { $ensure_safe = file   }
    'absent','uninstalled': { $ensure_safe = absent }
    default: {
      fail "Unknown value ${ensure} of 'ensure' parameter, Accepted values are ['present','absent']"
    }
  }

  if $caller_module_name {
    $mod = $caller_module_name
  } else {
    $mod = $module_name
  }

  file { "${lib_puppet}/${name}":
    ensure  => $ensure_safe,
    source  => "puppet:///modules/${mod}/lib/puppet/${name}",
    mode    => '0644',
    recurse => $recurse,
    links   => follow,
  }
}
