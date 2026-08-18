#!/bin/bash

pass() {
  echo -e "${GREEN}PASS:${NC} $1"
  ((PASSED++))
}

fail() {
    echo -e "${RED}FAIL:${NC} $1\n    -> $2\n"
    ((FAILED++))
}

create_ip_addresses_script() {
  cat << END > ${TMP_DIR}/my_ip.sh
#!/bin/bash
my_ip=192.168.1.1
another_ip=192.168.0.1
false_positive1="intel_ver=19.1.3.304"
false_positive2="/path/to/software/intel/19.1.3.304"
END

  mkdir -p ${TMP_DIR}/.git
  cp ${TMP_DIR}/my_ip.sh ${TMP_DIR}/.git/
}

create_phone_numbers_script() {
  cat << END > ${TMP_DIR}/my_phone_number.sh
#!/bin/bash
phone_num1="(123) 456-7890"
phone_num2="(123)-456-7890"
phone_num3="123-456-7890"
phone_num4="123 456 7890"
phone_num5="123.456.7890"
END

  mkdir -p ${TMP_DIR}/.git
  cp ${TMP_DIR}/my_phone_number.sh ${TMP_DIR}/.git/
}

create_data_transfer_files() {
  for prtcl in "rsync" "ssh" "ftp" "hsi" "scp"; do
    echo ${prtcl} '${SRC} ${DEST}' >> ${TMP_DIR}/data_transfer1.sh
    echo ${prtcl} '${SECRET_SRC} ${SECRET_DEST}' >> ${TMP_DIR}/data_transfer2.sh
  done

  echo "SRC=login01" >> ${TMP_DIR}/src.txt
  echo "DEST=login02" >> ${TMP_DIR}/dest.txt

  mkdir -p ${TMP_DIR}/.git
  cp ${TMP_DIR}/{data_transfer1.sh,data_transfer2.sh,src.txt,dest.txt} ${TMP_DIR}/.git/
}

setup() {
  source "${SCRIPT_UNDER_TEST}"

  export TMP_DIR=$( mktemp -d )
}

teardown() {
  unset TMP_DIR
  rm -rf "${TMP_DIR}"
}

test_check_ip_addresses_found() {
  setup

  create_ip_addresses_script

  output=$( check_ip_addresses "${TMP_DIR}" )

  if [[ "${output}" == *"WARNING: found 2 IP address match(es):"* \
    && "${output}" == *"192.168.1.1"* \
    && "${output}" == *"192.168.0.1"* ]]; then
    pass "${FUNCNAME}"
  else
    fail "${FUNCNAME}" "Did not find the expected number of IP addresses. Output: \n${output}"
  fi

  teardown
}

test_check_ip_addresses_not_found() {
  setup

  create_phone_numbers_script

  output=$( check_ip_addresses "${TMP_DIR}" )

  if [[ -z "${output}" ]]; then
    pass "${FUNCNAME}"
  else
    fail "${FUNCNAME}" "Found one or more IP addresses, but expected none. Output: \n${output}"
  fi

  teardown
}

test_check_phone_numbers_found() {
  setup

  create_phone_numbers_script

  output=$( check_phone_numbers "${TMP_DIR}" )

  if [[ "${output}" == *"WARNING: found 5 phone number match(es):"* \
    && "${output}" == *"(123) 456-7890"* && "${output}" == *"(123)-456-7890"* \
    && "${output}" == *"123 456 7890"* && "${output}" != *"1234567890"* \
    && "${output}" == *"123-456-7890"* && "${output}" == *"123.456.7890"* ]]; then
    pass "${FUNCNAME}"
  else
    fail "${FUNCNAME}" "Did not find the expected number of phone numbers. Output: \n${output}"
  fi

  teardown
}

test_check_phone_numbers_not_found() {
  setup

  create_ip_addresses_script

  local output=$( check_phone_numbers "${TMP_DIR}" )

  if [[ -z "${output}" ]]; then
    pass "${FUNCNAME}"
  else
    fail "${FUNCNAME}" "Found one or more phone numbers, but expected none. Output: \n${output}"
  fi

  teardown
}

test_check_data_transfer_found(){
  setup

  create_data_transfer_files

  local output=$( check_data_transfer "${TMP_DIR}" )

  if [[ "${output}" == *"WARNING: found 2 data transfer instance(s) with hard-coded sources or destinations:"* \
      && "${output}" == *"${TMP_DIR}/src.txt:SRC"* \
      && "${output}" == *"${TMP_DIR}/dest.txt:DEST"* ]]; then
    pass "${FUNCNAME}"
  else
    fail "${FUNCNAME}" "Did not find the expected number of data transfer instances. Output: \n${output}"
  fi

  teardown
}

test_check_data_transfer_not_found(){
  setup

  create_ip_addresses_script
  create_phone_numbers_script

  local output=$( check_data_transfer "${TMP_DIR}" )

  if [[ -z "${output}" ]]; then
    pass "${FUNCNAME}"
  else
    fail "${FUNCNAME}" "Found one or more data transfer instances, but expected none. Output: \n${output}"
  fi

  teardown
}

test_main() {
  setup

  create_ip_addresses_script
  create_phone_numbers_script
  create_data_transfer_files

  local output=$( main "${TMP_DIR}" )

  if [[ \
    "${output}" == *"WARNING: found 2 IP address match(es):"* \
    && "${output}" == *"${TMP_DIR}/my_ip.sh:my_ip=192.168.1.1"* \
    && "${output}" == *"${TMP_DIR}/my_ip.sh:another_ip=192.168.0.1"* \
    && "${output}" == *"WARNING: found 5 phone number match(es):"* \
    && "${output}" == *"${TMP_DIR}"'/my_phone_number.sh:phone_num1="(123) 456-7890"'* \
    && "${output}" == *"${TMP_DIR}"'/my_phone_number.sh:phone_num2="(123)-456-7890"'* \
    && "${output}" == *"${TMP_DIR}"'/my_phone_number.sh:phone_num3="123-456-7890"'* \
    && "${output}" == *"${TMP_DIR}"'/my_phone_number.sh:phone_num4="123 456 7890"'* \
    && "${output}" == *"${TMP_DIR}"'/my_phone_number.sh:phone_num5="123.456.7890"'* \
    && "${output}" == *"WARNING: found 2 data transfer instance(s) with hard-coded sources or destinations:"* \
    && "${output}" == *"${TMP_DIR}/dest.txt:DEST=login02"* \
    && "${output}" == *"${TMP_DIR}/src.txt:SRC=login01"* \
    ]]; then
    pass "${FUNCNAME}"
  else
    fail "${FUNCNAME}" "One or more checks did not behave as expected. Output: \n${output}"
  fi

  teardown
}

main() {
  TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  SCRIPT_UNDER_TEST=$( realpath "${TEST_DIR}/../ush/check_pii_security.sh" )

  # Colors for output
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  NC='\033[0m' # No Color

  PASSED=0
  FAILED=0

  echo "Running tests..."
  echo "---------------------------------------------------"
  
  test_check_ip_addresses_found
  test_check_ip_addresses_not_found
  test_check_phone_numbers_found
  test_check_phone_numbers_not_found
  test_check_data_transfer_found
  test_check_data_transfer_not_found
  test_main

  echo "---------------------------------------------------"
  echo "Test run complete: ${PASSED} passed, ${FAILED} failed."

  if [[ ${FAILED} -ne 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
