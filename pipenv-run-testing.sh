#! /bin/bash

# Nasty bug
# Ref. https://github.com/pypa/pipenv/issues/5075
echo "Exporting SETUPTOOLS_USE_DISTUTILS"
export SETUPTOOLS_USE_DISTUTILS=stdlib
export ANSIBLE_CONFIG=./config/ansible.cfg

echo "Running tests"
pipenv run python kafka-testing/main.py \
	 --inventory ./config/inventory.yml \
	 --results /opt/automation/automation-templates/data/results \
	 --tests ./config/tests/test-01.yml \
	         ./config/tests/test-02.yml \
		 ./config/tests/test-03.yml \
		 ./config/tests/test-04.yml \
		 ./config/tests/test-05.yml \
		 ./config/tests/test-06.yml \
		 ./config/tests/test-07.yml

echo "Testing complete"
