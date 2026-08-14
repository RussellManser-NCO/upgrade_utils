#!/bin/bash

# Check a software package for potential PII and security issues

check_ip_addresses() {
  local path_to_check="$1"

  # Ignore false positives for <software>_ver and paths to software
  local check=$( grep -rP --exclude-dir=".git" \
    "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" "${path_to_check}" \
      | grep -v "_ver" \
      | grep -vE ".*:.*\/[a-z]+\/.*"
  )

  if [[ -n "${check}" ]]; then
    echo "WARNING: found $( echo "${check}" | wc -l ) IP address match(es):"
    echo "${check}"
  fi
}

check_phone_numbers() {
  local path_to_check="$1"

  local check=$( grep -rP --exclude-dir=".git" \
    '\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}' "${path_to_check}" )

  if [[ -n "${check}" ]]; then
    echo "WARNING: found $( echo "${check}" | wc -l ) phone number match(es):"
    echo "${check}"
  fi
}

check_data_transfer() {
  local path_to_check="$1"

  for prtcl in "rsync" "ssh" "ftp" "scp" "hsi"; do
    hits=$( grep -r --exclude-dir=".git" "${prtcl} " "${path_to_check}" )

    # Find all unique variable names used in function calls
    vrs=( $( echo "${hits}" | grep -Eo '(\ ?\$\{?[a-zA-Z0-9_]+\}?)+' ) )
    sorted_vrs=( $( printf "%s\n" "${vrs[@]}" | sort | uniq ) )

    # Search for variable assignment within the code
    checks=()
    for vr in "${sorted_vrs[@]}"; do
      pat=$( echo ".*${vr}(\ +)?=" | sed -e 's/\$//' -e 's/{//' -e 's/}//' )
      check=$( grep -rE --exclude-dir=".git" "${pat}" "${path_to_check}" )
      if [[ -n "${check}" ]]; then
        checks+=("${check}")
      fi
    done
  done

  if [[ -n "${checks[@]}" ]]; then
    echo "WARNING: found ${#checks[@]} data transfer instance(s) with hard-coded sources or destinations:"
    printf "%s\n" "${checks[@]}"
  fi
}

main() {
  pkg_path=$1

  if [[ -z "${pkg_path}" ]]; then
    echo "$0 usage: pkg_path"
    exit 1
  fi

  ip_result=$( check_ip_addresses "${pkg_path}" )
  phone_result=$( check_phone_numbers "${pkg_path}" )
  data_xfer_result=$( check_data_transfer "${pkg_path}" )

  err=0
  if [[ -n "${ip_result}" ]]; then
    err=1
    echo "${ip_result}"
  fi
  if [[ -n "${phone_result}" ]]; then
    err=1
    echo "${phone_result}"
  fi
  if [[ -n "${data_xfer_result}" ]]; then
    err=1
    echo "${data_xfer_result}"
  fi

  exit ${err}
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
