#!/bin/bash
export RUBYLIB=/cloudbox/modules/node_openstack/lib/
puppet node_openstack create --identity_username=admin --identity_password=puppet --image=centos-5.7-pe-2.5.2 --type=m1.medium --tenant_name=students --keystone_host=10.0.0.1 --nova_host=10.0.0.1 --name=master --trace

