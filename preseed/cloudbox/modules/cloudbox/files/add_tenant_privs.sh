#!/bin/bash
PATH="/usr/bin"
source /root/openrc
declare -x ROLE_ID="$( keystone role-list | 
                         awk -F'[|]' '/admin/{gsub(" ","",$2);print $2}')"
declare -x USER_ID="$( keystone --token puppet user-list |
                        awk -F'[|]' '/admin/{gsub(" ","",$2);print $2}')"
declare -x TENANT_ID="$( keystone --token puppet tenant-list |
                        awk -F'[|]' '/students/{gsub(" ","",$2);print $2}')"
keystone user-role-add --user "${USER_ID:?}" --role "${ROLE_ID:?}" --tenant_id "${TENANT_ID:?}" 

