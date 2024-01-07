#!/usr/bin/env bash

# A library file

echoerr() { echo "$@" 1>&2; }

# This function is just for a prettier sudo prompt
check_sudo() { sudo true; }

sudo_quiet_tee() { sudo tee "$@" 1>/dev/null; }

quiet_tee() { tee "$@" 1>/dev/null; }

check_tool() {
	local tool
	tool="$1"
	if ! command -v "${tool}" >/dev/null; then
		echoerr "${tool} command not found"
		return 1
	fi
}

run_user_script() {
	local userscript
	userscript="$1"
	if [ -f "$userscript" ]; then
		$userscript
	else
		echoerr "User script $userscript not found"
	fi
}

template_xml() {
	local xml_file
	local target_file
	xml_file="$1"
	target_file="$2"

	local tmp_file
	tmp_file="$(mktemp)"

	# A fancy one liner to get a list of env variables that start with XML_TEMPLATE_
	# and add a $ sign at the beginning of every one, so they are understood by envsubst
	template_variables="$(env | grep "^XML_TEMPLATE_" | cut -d "=" -f1 | sed -e 's/^/$/' | xargs)"
	envsubst "\'${template_variables}\'" <"${xml_file}" >"${tmp_file}"
	if ! command_output="$(virt-xml-validate "${tmp_file}" 2>&1)"; then
		echo "templated XML validation failed"
		echo "${command_output}"
		exit 1
	fi

	mv "${tmp_file}" "${target_file}"
}

function get_vm_config() {
	local vm_name
	local file_location
	vm_name="$1"
	file_location="${2:-$(mktemp)}"
	if ! sudo virsh dumpxml "${vm_name}" | quiet_tee "${file_location}"; then
		return 1
	fi
}

function check_vm_config_matches_template() {
	local vm_name
	local vm_config
	vm_name="$1"
	vm_config="$2"

	local vm_config_real
	vm_config_real="$(mktemp)"
	get_vm_config "${vm_name}" "${vm_config_real}"

	local templated_vm_config
	templated_vm_config="$(mktemp)"
	template_xml "${vm_config}" "${templated_vm_config}"

	if ! diff --ignore-blank-lines "${templated_vm_config}" "${vm_config_real}"; then
		echo "${vm_config} does not match with the config of ${vm_name}"
		return 1
	fi
}

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

	if [[ "${current_driver}" == "${driver_name}" ]]; then
		echo "A correct driver is already bound"
	else
		if [ -n "${current_driver}" ]; then
			echoerr "Unbinding from the current driver: ${current_driver}"
			echo "${pci_id}" | sudo_quiet_tee "/sys/bus/pci/devices/${pci_id}/driver/unbind"

			wait_for_driver_bind "${device_id}" ""
		fi

		if ! lsmod | grep -q "${driver_name}"; then
			sudo modprobe "${driver_name}"
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
	fi

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
