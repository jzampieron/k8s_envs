#!/bin/bash
#
# Adds an alias for the network interface setup in the vagrant file.
#
# Allows direct access from the host to the kubernetes network.
#
NETWORK_ADAPTER_NAME = "en0"

source settings.inc

sudo ifconfig ${NETWORK_ADAPTER_NAME} alias 10.240.0.1/24 up

