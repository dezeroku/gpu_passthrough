#!/usr/bin/env bash

. "${SCRIPTS_DIR}/common.sh"
. "${SCRIPTS_DIR}/values.sh"

# Tooling sanity checks
if ! check_tool "autorandr"; then
	if [[ "${AUTORANDR_ENABLE}" == "true" ]]; then
		echoerr "Overriding AUTORANDR_ENABLE=false"
		AUTORANDR_ENABLE="false"
	fi
fi

check_tool virsh
check_tool uuidgen
