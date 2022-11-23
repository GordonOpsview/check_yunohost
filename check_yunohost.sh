#!/usr/bin/env bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

CHECK_STATE=$STATE_OK


if [[ "${1}" == "-h" ]]; then
  cat <<EOF

  This plugin returns the results of the most recent Yunohost diagnostic.

  Usage:
    check_yunohost [-h|<Category>|all|last_diagnosis]

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

  Options:
    -h, --help
        Print this

EOF
  exit
fi

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


# $(( ($(date +%s)-$(yunohost diagnosis show --full | grep timestamp | head -n1 | grep -o '[0-9]*'))/3600 ))

 SHOW=$(mktemp /tmp/XXXXXX)
sudo yunohost diagnosis
# SHOW="show.yml"

OKS=$(cat $SHOW | category "${1}" | grep -Ec "^ *status: (SUCCESS|INFO)")
WARNINGS=$(cat $SHOW | category "${1}" | grep -c "^ *status: WARNING")
ERRORS=$(cat $SHOW | category "${1}" | grep -c "^ *status: ERROR")

if [[ $ERRORS -gt 0 ]]; then
  CHECK_STATE=$STATE_CRITICAL
  cat $SHOW | category "${1}" | grep -A1 "^ *status: ERROR" | grep '^ *summary: ' | sed 's/^ *summary: /ERROR: /'
  cat $SHOW | category "${1}" | grep -A1 "^ *status: WARNING" | grep '^ *summary: ' | sed 's/^ *summary: /WARNING: /'
  echo -e "|'OK'=$OKS 'WARNING'=$WARNINGS 'ERROR'=$ERRORS"
elif [[ $WARNINGS -gt 0 ]]; then
  CHECK_STATE=$STATE_WARNING
  cat $SHOW | category "${1}" | grep -A1 "^ *status: WARNING" | grep '^ *summary: ' | sed 's/^ *summary: /WARNING: /'
  echo -e "|'OK'=$OKS 'WARNING'=$WARNINGS 'ERROR'=$ERRORS"
elif [[ $OKS -eq 0 ]]; then
  CHECK_STATE=$STATE_UNKNOWN
  echo -e "UNKNOWN\nCould not get results from 'yunohost diagnosis show'"
else
  CHECK_STATE=$STATE_OK
  echo "All OK"
  echo -e "|'OK'=$OKS 'WARNING'=$WARNINGS 'ERROR'=$ERRORS"
fi

rm $SHOW

exit $CHECK_STATE
