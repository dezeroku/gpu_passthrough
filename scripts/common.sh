#!/usr/bin/env bash

# A library file

echoerr() { echo "$@" 1>&2; }

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
