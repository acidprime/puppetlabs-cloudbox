class cloudbox {
  include cloudbox::network
  include cloudbox::hostapd
  include cloudbox::stackutil
  include cloudbox::dhcpd
  include cloudbox::tenant
  include cloudbox::keypair
  include cloudbox::floating
  include cloudbox::image
}
