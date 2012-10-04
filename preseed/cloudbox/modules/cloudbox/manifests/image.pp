class cloudbox::image {
  glance_image { 'training_image':
    ensure           => present,
    name             => "centos-5.7-pe-2.5.2",
    is_public        => true,
    container_format => bare,
    disk_format      => qcow2,
    source           => '/cloudbox/preseed/cloudbox/centos-5.7-pe-2.5.2.img',
  }
  #exec { 'add_image':
  #  path    => '/usr/bin',
  #  command => 'glance \
  #    add -I admin \
  #    -K puppet \
  #    name=centos-5.7-pe-2.5.2  \
  #    is_public=true \
  #    container_format=bare \
  #    disk_format=qcow2 <centos-5.7-pe-2.5.2.img',
  #}
} 
