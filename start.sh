#!/usr/bin/env bash

set -euo pipefail

# Start up the VM with GPU passthrough
# Takes care of:
# * isolating GPU and enabling it back
# * isolating CPU cores from the host
# * getting required ISOs from the web

# The values are prepared for Ryzen 3600 and RTX 4070
# Modify these accordingly

# CONFIGURATION MUST-HAVES
# lspci -nn to get the PCI_IDs and DEVICE_IDs
GPU_PCI_ID="0000:26:00.0"
GPU_AUDIO_PCI_ID="0000:26:00.1"

GPU_DEVICE_ID="10de:2786"
GPU_AUDIO_DEVICE_ID="10de:22bc"

GPU_DRIVER="nvidia"
GPU_AUDIO_DRIVER="snd_hda_intel"

# Use lcpu -e to find correct IDs
# This has to be matched with the XML
HOST_CPUS="0,1,2,6,7,8"
ALL_CPUS="0-11"

# CONFIGURATION OPTIONAL
VM_NAME="win11-install-testing"
VM_NETWORK_NAME="default"

echoerr() { echo "$@" 1>&2; }

sudo_quiet_tee() { sudo tee "$@" 1>/dev/null; }

function get_used_driver() {
    local device_id
    device_id="$1"
    
    lspci -nnk -d "${device_id}" | grep "driver in use" | cut -d ":" -f2 | tr -d "[:blank:]" || true
}

function wait_for_driver_bind() {
    local device_id
    local expected_driver

    device_id="$1"
    expected_driver="$2"

    local current_driver
    current_driver="$(get_used_driver "${device_id}")"

    while [[ "${current_driver}" != "${expected_driver}" ]]; do
        echo "|${current_driver}|"
        current_driver="$(get_used_driver "${device_id}")"
    done
}

function driver_bind() {
    local driver_name
    local pci_id
    local device_id
    driver_name="$1"
    pci_id="$2"
    device_id="$3"

    echoerr "Binding ${pci_id} [${device_id}] to ${driver_name}"

    local current_driver
    current_driver="$(get_used_driver "${device_id}")"

    if [ -n "${current_driver}" ]; then
        echoerr "Unbinding from the current driver: ${current_driver}"
        echo "${pci_id}" | sudo_quiet_tee "/sys/bus/pci/devices/${pci_id}/driver/unbind"

        wait_for_driver_bind "${device_id}" ""
    fi

    # TODO: remove the top if, snd_hda_intel needs some more work with the new_id file it seems
    if [[ "${device_id}" != "${GPU_AUDIO_DEVICE_ID}" ]]; then
        local adding_driver_log
        if ! adding_driver_log="$(echo "${device_id}" | tr ":" " " | sudo_quiet_tee "/sys/bus/pci/drivers/${driver_name}/new_id" 2>&1)"; then
            if ! echo "${adding_driver_log}" | grep -q "File exists"; then
                echo "Failed during calling new_id for the device"
                echo "${adding_driver_log}"
                exit 1
            fi
        fi
    fi

    echo "${pci_id}" | sudo_quiet_tee "/sys/bus/pci/drivers/${driver_name}/bind"

    wait_for_driver_bind "${device_id}" "${driver_name}"

    echoerr "Binding successful"
}

function set_cpus_for_systemd() {
    # Isolate CPUs, so they are only used by the guest (not scheduled by host)
    local cores
    cores="$1"

    echoerr "Setting cpus for host: ${cores}"
    sudo systemctl set-property --runtime -- system.slice AllowedCPUs="${cores}"
    sudo systemctl set-property --runtime -- user.slice AllowedCPUs="${cores}"
    sudo systemctl set-property --runtime -- init.scope AllowedCPUs="${cores}"
}

function pre_vm() {
    # Isolate GPU
    driver_bind "vfio-pci" "${GPU_PCI_ID}" "${GPU_DEVICE_ID}"
    driver_bind "vfio-pci" "${GPU_AUDIO_PCI_ID}" "${GPU_AUDIO_DEVICE_ID}"

    # Isolate CPU cores
    set_cpus_for_systemd "${HOST_CPUS}"

    # Start the network
    if ! sudo virsh net-info "${VM_NETWORK_NAME}" | grep Active | grep -q yes; then
        sudo virsh net-start "${VM_NETWORK_NAME}"
    fi
}

function post_vm() {
    echoerr "Cleaning up"

    # Is "Unisolate" even a word? :D
    # Unisolate GPU
    driver_bind "${GPU_DRIVER}" "${GPU_PCI_ID}" "${GPU_DEVICE_ID}"
    driver_bind "${GPU_AUDIO_DRIVER}" "${GPU_AUDIO_PCI_ID}" "${GPU_AUDIO_DEVICE_ID}"

    # Unisolate CPU cores
    set_cpus_for_systemd "${ALL_CPUS}"

    # Stop the network
    sudo virsh net-destroy "${VM_NETWORK_NAME}"
}

function start_vm() {
    sudo virsh start "${VM_NAME}"
}

function wait_for_vm_to_shut_down() {
    while true; do
        sudo virsh dominfo "${VM_NAME}" | grep State | grep -q "shut off" && return
        sleep 5
    done
}

pre_vm
start_vm

wait_for_vm_to_shut_down
echo
post_vm
