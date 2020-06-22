#! /bin/sh

MAJOR_VERSION=`cat /etc/os-release | grep -w VERSION_ID | cut -d= -f2 | tr -d '"' | cut -d. -f1`

subscription-manager register --serverurl https://subscription.rhsm.qa.redhat.com/subscription --username $USERNAME --password $PASSWORD --auto-attach
if [ "$MAJOR_VERSION" -eq 8 ]
  subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
then
elif [ "$MAJOR_VERSION" -eq 7 ]
  subscription-manager repos --enable rhel-7-server-ansible-2.9-rpms
then
else
  echo "Unsupported version of RHEL $MAJOR_VERSION"
  exit 1
fi
dnf -y install ansible
ansible-galaxy install mkanoor.catalog_receptor_installer

# We need the latest python-dateutil package for the Receptor
pip install --upgrade pip
pip install python-dateutil

# When running in CI environment we need to check the cert
# is signed by Redhat IT ROOT CA
# Needed only if we are connecting to ci.cloud.redhat.com
wget -P /etc/pki/ca-trust/source/anchors/ https://password.corp.redhat.com/RH-IT-Root-CA.crt
update-ca-trust

# Needed because the latest python-dateutil was pip installed
#ENV PYTHONPATH /opt/app-root/lib/python3.6/site-packages:$PYTHON_PATH

# Setup RPM repo for the python receptor & catalog plugin
dnf config-manager --add-repo=http://dogfood.sat.engineering.redhat.com/pulp/repos/Sat6-CI/QA/Satellite_6_8_with_RHEL7_Server/custom/Satellite_6_8_Composes/Satellite_6_8_RHEL7/
dnf config-manager --add-repo=http://file.rdu.redhat.com/mkanoor/

ansible_playbook /playbooks/install_receptor.yml
