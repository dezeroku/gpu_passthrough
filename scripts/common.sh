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
		echo "Failed to check the XML of ${vm_name}"
		echo "Did you remember to run scripts/setup first?"
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
