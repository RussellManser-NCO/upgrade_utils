#!/bin/bash

# Check a software package for potential PII and security issues

check_ip_addresses() {
  local path_to_check="$1"
  local check=$( grep -rE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" "${path_to_check}" )

  if [[ -n "${check}" ]]; then
    echo "WARNING: found $( echo "${check}" | wc -l ) IP address match(es):"
    echo "${check}"
  fi
}

check_phone_numbers() {
  local path_to_check="$1"
  local check=$( grep -rP '\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}' "${path_to_check}" )

  if [[ -n "${check}" ]]; then
    echo "WARNING: found $( echo "${check}" | wc -l ) phone number match(es):"
    echo "${check}"
  fi
}

check_data_transfer() {
  echo "Function ${FUNCNAME} is not implemented!"
}

main() {
  pkg_path=$1

  if [[ -z "${pkg_path}" ]]; then
    echo "$0 usage: pkg_path"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
