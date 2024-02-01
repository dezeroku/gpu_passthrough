#!/usr/bin/env bash

# These values are prepared for Ryzen 3600 and RTX 4070
# Modify these accordingly

# Note:
# We can assume that this script is being sourced when pwd is set to
# the root of this repo.
# This is done in the proper init part in other scripts.

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

# How much memory the VM gets
export VM_MEMORY_KB="16777216"

# CONFIGURATION OPTIONAL
#VM_NAME="win11-install-testing"
export VM_NAME="win11-scsi"
export VM_CONFIG="win11-scsi"
export VM_NETWORK_NAME="default"
# This snippet generates a unique ID that's deterministic given a name
# so unique-per-name
VM_UUID="$(uuidgen --namespace @oid --md5 --name "${VM_NAME}")"
export VM_UUID

# Templating values for the XMLs
# All the values prefixed with XML_TEMPLATE_ can be used within the XMLs
export XML_TEMPLATE_REPO_PATH="${PWD}"
export XML_TEMPLATE_VM_NAME="${VM_NAME}"
export XML_TEMPLATE_VM_UUID="${VM_UUID}"
export XML_TEMPLATE_VM_MEMORY_KB="${VM_MEMORY_KB}"
export XML_TEMPLATE_NETWORK="${VM_NETWORK_NAME}"

export DOCKER_GOMPLATE_IMAGE="hairyhenderson/gomplate:v3.11-alpine"

# Some sanity checks, don't edit
export VM_CONFIG="xmls/${VM_CONFIG}.xml.tmpl"
if [ ! -f "${VM_CONFIG}" ]; then
	echo "${VM_CONFIG} not found, are you sure you chose the proper configuration?"
	exit 1
fi
