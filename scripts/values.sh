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

export XML_TEMPLATE_PIPEWIRE_RUNTIME_DIR="/run/user/1000"
export XML_TEMPLATE_PIPEWIRE_LATENCY="128/48000"
# ls /dev/input/by-id/ , cat one of the files and see if it prints something when you use the input device
# then you'll know that's the correct one
export XML_TEMPLATE_MICE="usb-Razer_Razer_Viper_V2_Pro_000000000000-event-mouse"
# Pass the wired connection and wireless adapter at the same time
# as the USB connector has a tendency to disconnect from time to time
export XML_TEMPLATE_KEYBOARDS="usb-Corsair_CORSAIR_K100_RGB_AIR_WIRELESS_Ultra-Thin_Mechanical_Gaming_Keyb_F5001904603E77D2AA1B84290A00A01F-event-kbd usb-Corsair_CORSAIR_SLIPSTREAM_WIRELESS_USB_Receiver_A7A0A0AE02C6DDC3-if03-event-kbd"
export XML_TEMPLATE_AUDIO_CLIENT_NAME="vm-win"
export XML_TEMPLATE_AUDIO_INPUT_REGEX="HyperX Cloud III.*"
export XML_TEMPLATE_AUDIO_OUTPUT_REGEX="HyperX Cloud III.*"
export XML_TEMPLATE_MAC_ADDRESS="52:54:00:18:bf:5a"
export XML_TEMPLATE_NETWORK="${VM_NETWORK_NAME}"
# ls /dev/disk/by-id/
export XML_TEMPLATE_MAIN_DISK_ID="ata-Samsung_SSD_860_EVO_1TB_S4X6NF0N312956V"
export XML_TEMPLATE_SECONDARY_DISK_ID="ata-Samsung_SSD_870_EVO_1TB_S75CNX0W352009E"
# lsusb
# TP-Link UB500 Bluetooth Adapter
export XML_TEMPLATE_USB_DEVICES="2357:0604"

export DOCKER_GOMPLATE_IMAGE="hairyhenderson/gomplate:v3.11-alpine"

# Some sanity checks, don't edit
export VM_CONFIG="xmls/${VM_CONFIG}.xml.tmpl"
if [ ! -f "${VM_CONFIG}" ]; then
	echo "${VM_CONFIG} not found, are you sure you chose the proper configuration?"
	exit 1
fi
