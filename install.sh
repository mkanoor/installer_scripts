#! /bin/sh

REDHAT_RELEASE_FILE=/etc/redhat-release

if [[ ! -f "$REDHAT_RELEASE_FILE" ]]
then
  echo "This installer can only be run on RHEL systems"
  exit 1
fi

MAJOR_VERSION=`cat /etc/os-release | grep -w VERSION_ID | cut -d= -f2 | tr -d '"' | cut -d. -f1`

FILE=/etc/pki/consumer/cert.pem
if [[ ! -f "$FILE" ]]
then
subscription-manager register --serverurl https://subscription.rhsm.qa.redhat.com/subscription --username $USERNAME --password $PASSWORD --auto-attach
fi

if [[ "$MAJOR_VERSION" -eq 8 ]]
then
  subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
elif [[ "$MAJOR_VERSION" -eq 7 ]]
then
  subscription-manager repos --enable rhel-7-server-ansible-2.9-rpms
else
  echo "Unsupported version of RHEL $MAJOR_VERSION"
  exit 1
fi

yum -y install yum-utils
yum -y install wget
yum -y install ansible
ansible-galaxy install mkanoor.catalog_receptor_installer

# We need the latest python-dateutil package for the Receptor
pip install python-dateutil==2.8.1

# When running in CI environment we need to check the cert
# is signed by Redhat IT ROOT CA
# Needed only if we are connecting to ci.cloud.redhat.com
wget -P /etc/pki/ca-trust/source/anchors/ https://password.corp.redhat.com/RH-IT-Root-CA.crt
update-ca-trust

# Setup RPM repo for the python receptor & catalog plugin
yum-config-manager --nogpgcheck --add-repo=http://dogfood.sat.engineering.redhat.com/pulp/repos/Sat6-CI/QA/Satellite_6_8_with_RHEL7_Server/custom/Satellite_6_8_Composes/Satellite_6_8_RHEL7/
yum-config-manager --nogpgcheck --add-repo=http://file.rdu.redhat.com/mkanoor/

ansible-playbook sample_playbooks/install_receptor.yml
