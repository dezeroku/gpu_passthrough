#!/usr/bin/env bash

# These values are prepared for Ryzen 3600 and RTX 4070
# Modify these accordingly

# CONFIGURATION MUST-HAVES
# lspci -nn to get the PCI_IDs and DEVICE_IDs
export GPU_PCI_ID="0000:26:00.0"
export GPU_AUDIO_PCI_ID="0000:26:00.1"

export GPU_DEVICE_ID="10de:2786"
export GPU_AUDIO_DEVICE_ID="10de:22bc"

export GPU_DRIVER="nvidia"
export GPU_AUDIO_DRIVER="snd_hda_intel"

# Use lcpu -e to find correct IDs
# This has to be matched with the XML
export HOST_CPUS="0,1,2,6,7,8"
export ALL_CPUS="0-11"

# CONFIGURATION OPTIONAL
#VM_NAME="win11-install-testing"
export VM_NAME="win11-scsi"
export VM_CONFIG="win11-scsi"
export VM_NETWORK_NAME="default"

# Autorandr is used here as it's easier to write hooks for it
# The presets have to be defined manually
export AUTORANDR_ENABLE="true"
export AUTORANDR_DEFAULT="default"
export AUTORANDR_PASSTHROUGH="gpu_passthrough"

# Some sanity checks, don't edit
export VM_CONFIG="xmls/${VM_CONFIG}.xml"
if [ ! -f "${VM_CONFIG}" ]; then
	echo "${VM_CONFIG} not found, are you sure you chose the proper configuration?"
	exit 1
fi
