#!/bin/bash
# Setup our self destructing rc.local file
if [ -f /cloudbox/rc.local ] ; then
  cp -fv /cloudbox/rc.local /etc/rc.local
fi
exit 0


