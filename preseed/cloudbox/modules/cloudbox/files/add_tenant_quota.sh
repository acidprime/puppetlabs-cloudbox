#!/bin/bash
PATH="/usr/bin"
source /root/openrc

declare -ix QUOTA_INSTANCES=100
declare -ix QUOTA_FLOATING=254
declare -x TENANT_ID="$( keystone --token puppet tenant-list |
                        awk -F'[|]' '/students/{gsub(" ","",$2);print $2}')"

nova-manage project quota \
--project="${TENANT_ID:?}" \
--key=instances \
--value="${QUOTA_INSTANCES:?}"

nova-manage project quota \
--project="${TENANT_ID:?}" \
--key=floating_ips \
--value="${QUOTA_FLOATING:?}"

