#! /bin/bash

# Nasty bug
# Ref. https://github.com/pypa/pipenv/issues/5075
echo "Exporting SETUPTOOLS_USE_DISTUTILS"
export SETUPTOOLS_USE_DISTUTILS=stdlib
export ANSIBLE_CONFIG=./config/ansible.cfg

echo "Validate hosts..."
pipenv run ansible-playbook -i ./config/inventory.yml confluent.platform.validate_hosts
