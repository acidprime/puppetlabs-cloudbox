#!/bin/bash
declare -rx keystone='/usr/bin/keystone'
USER_ID="$($keystone --token puppet user-list)"
