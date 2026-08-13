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
END
}

create_phone_numbers_script() {
  cat << END > ${TMP_DIR}/my_phone_number.sh
#!/bin/bash
phone_num1="(123) 456-7890"
phone_num2="(123)-456-7890"
phone_num3="123-456-7890"
phone_num4="123 456 7890"
phone_num5="1234567890"
phone_num6="123.456.7890"
END
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
    && "${output}" == *"(123) 456-7890"* && "${output}" == *"(123)-456-7890" \
    && "${output}" == *"123 456 7890"* && "${output}" == *"1234567890"* \
    && "${output}" == *"123-456-7890"* && "${output}" == *"123.456.7890"* ]]; then
    pass "${FUNCNAME}"
  else
    fail "${FUNCNAME}" "Did not find the expected number of phone numbers. Output: \n${output}"
  fi

  teardown
}

test_check_phone_numbers_not_found() {
  fail "${FUNCNAME}" "Test is not implemented!"
}

test_check_data_transfer_found(){
  fail "${FUNCNAME}" "Test is not implemented!"
}

test_check_data_transfer_not_found(){
  fail "${FUNCNAME}" "Test is not implemented!"
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
