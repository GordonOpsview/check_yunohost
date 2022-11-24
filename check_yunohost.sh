#!/usr/bin/env bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

LAST_DIAGNOSIS_CRIT=720 # default value
LAST_DIAGNOSIS_WARN=24 # default value

CHECK_STATE=$STATE_OK

function help () {
  cat <<EOF

  This plugin returns the results of the most recent Yunohost diagnostic.

  Usage:
    check_yunohost [-h] -a [<category>|all|last_diagnosis] [-c <Crit>] [-w <Warn>]

  Options:
    -h
      Print this
    -a
      last_diagnosis: Hours since last diagnosis was run.
      all: Check all categories.
      <category>: See below for list of categories.
    -c
      Only applicable to 'last_diagnosis'.
    -w
      Only applicable to 'last_diagnosis'.
    
    Category can be one of the following:
      "Base system"
      "Internet connectivity"
      "DNS records"
      "Ports exposure"
      "Web"
      "Email"
      "Services status check"
      "System resources"
      "System configurations"
      "Applications"

EOF
}

function category () {
  while IFS= read line; do
    if [[ $(echo "$line" | grep -c "^    description: ") -gt 0 ]]; then
      currentcategory="$(echo "${line}" | sed 's/^    description: //')"
      # currentcategory="${line//^    description: /}"
    fi
    # echo "==${currentcategory}==${line}=="
    if [[ "${currentcategory,,}" == "${1,,}" || "${1,,}" == 'all' ]]; then
      echo "$line"
    fi
  done 
}

SHOW=$(mktemp /tmp/XXXXXX)
sudo yunohost diagnosis show --full > $SHOW
# SHOW="show_full.yml"

LAST_DIAGNOSIS=$(( ($(date +%s) - $(cat $SHOW | grep timestamp | tail -n1 | grep -o '[0-9]*') )/3600 ))

OKS=$(cat $SHOW | category "${1}" | grep -Ec "^ *status: (SUCCESS|INFO)")
WARNINGS=$(cat $SHOW | category "${1}" | grep -c "^ *status: WARNING")
ERRORS=$(cat $SHOW | category "${1}" | grep -c "^ *status: ERROR")

CHECK_TYPE='category'

while [[ $# -gt 1 ]]; do
  case "${1}" in
    -h)
      help
      exit
    ;;
    last_diagnosis)
      CHECK_TYPE='last_diagnosis'
    ;;
    -w)
      shift
      LAST_DIAGNOSIS_WARN="$1"
    ;;
    -c)
      shift
      LAST_DIAGNOSIS_CRIT="$1"
    ;;
 esac
 shift
done

case "$CHECK_TYPE" in
  category)
    if [[ $ERRORS -gt 0 ]]; then
      CHECK_STATE=$STATE_CRITICAL
      cat $SHOW | category "${1}" | grep -A1 "^ *status: ERROR" | grep '^ *summary: ' | sed 's/^ *summary: /ERROR: /'
      cat $SHOW | category "${1}" | grep -A1 "^ *status: WARNING" | grep '^ *summary: ' | sed 's/^ *summary: /WARNING: /'
    elif [[ $WARNINGS -gt 0 ]]; then
      CHECK_STATE=$STATE_WARNING
      cat $SHOW | category "${1}" | grep -A1 "^ *status: WARNING" | grep '^ *summary: ' | sed 's/^ *summary: /WARNING: /'
    elif [[ $OKS -eq 0 ]]; then
      CHECK_STATE=$STATE_UNKNOWN
      echo -e "UNKNOWN: Could not get results from 'yunohost diagnosis show'"
    else
      CHECK_STATE=$STATE_OK
      echo "OK: All diagnostics return SUCCESS"
    fi
  ;;
  last_diagnosis)
    if [[ $LAST_DIAGNOSIS -gt $LAST_DIAGNOSIS_CRIT ]]; then
      CHECK_STATE=$STATE_CRITICAL
      echo "CRITICAL: Diagnosis results are more than $LAST_DIAGNOSIS_CRIT hours old."
    elif [[ $LAST_DIAGNOSIS -gt $LAST_DIAGNOSIS_WARN ]]; then
      CHECK_STATE=$STATE_WARNING
      echo "WARNING: Diagnosis results are more than $LAST_DIAGNOSIS_WARN hours old."
    else
      CHECK_STATE=$STATE_OK
      echo "OK: Diagnosis results are less than $LAST_DIAGNOSIS_WARN hours old."
    fi
  ;;
esac

echo -e "|'OK'=$OKS 'WARNING'=$WARNINGS 'ERROR'=$ERRORS 'Last_Diagnosis'=${LAST_DIAGNOSIS}h" # The perfdata

rm $SHOW

exit $CHECK_STATE
