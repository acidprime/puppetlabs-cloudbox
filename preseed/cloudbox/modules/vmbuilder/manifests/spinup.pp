define vmbuilder::spinup ($currently_running = []) {
  if $name in $currently_running {
    notify {"$name virtual machine is already running":}
  }
  else {
    $vm_id = vmbuild($name)
  } 
}
