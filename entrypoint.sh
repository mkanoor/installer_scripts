#!/bin/sh

FILE=/playbooks/install_receptor.yml
RECEPTOR=/etc/receptor/rh_ansible_1/receptor.sh
UUID_FILE=/etc/receptor/rh_ansible_1/uuid

if [[ -f "$FILE" ]]
then
  ansible-playbook $FILE
  if [[ $? -eq 0 ]]
  then 
    echo "Starting the receptor $RECEPTOR"
    echo -n "Receptor Node id is " && cat $UUID_FILE
    $RECEPTOR
  else
    echo "Install failed for receptor"
    exit 2
  fi
else
  echo "$FILE doesn't exist, please provide a playbook with install parameters"
  exit 1
fi
