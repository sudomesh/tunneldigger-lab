#!/bin/sh
#
# logs incoming up hook requests from clients

echo "$(date) [td-hook] $*" >> "$0.log"
