class vmbuilder {
  $student_array = split($::students, ',')

  $vm_list_args = { 'identity_username' => 'admin',
        'identity_password' => 'puppet',
        'tenant_name' => 'students',
        'keystone_host' => '10.0.0.1',
        'nova_host'     => '10.0.0.1'}
  $vm_list = vmlist($vm_list_args)
  vmbuilder::spinup {$student_array:
    currently_running => $vm_list,
  }
}
