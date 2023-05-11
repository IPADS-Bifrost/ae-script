#!/bin/bash

set -e

echo "ending ovs process"

sudo /usr/local/share/openvswitch/scripts/ovs-ctl stop

echo "all done"
