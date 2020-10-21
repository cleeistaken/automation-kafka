#! /bin/bash

echo "This test creates performs the following:"
echo "  - Create one topic per producer"
echo "  - Have each producer write to its own topic"
echo "  - Have each consumers read from one topic"
echo " "

echo "Killing any running tests"
ansible-playbook -i settings.yml -i inventory.yml kill-tests.yml

echo "Waiting 1 minute"
sleep 60

echo "Running RF3 producer consumer test with GZIP compression"
ansible-playbook -i settings.yml -i inventory.yml test-producer-consumer-2.yml \
-e test_prefix=testtopic \
-e partitions=16 \
-e replication=3 \
-e retention=3600000 \
-e throughput=-1 \
-e record_size=100 \
-e num_records=2500000000 \
-e acks=-1 \
-e compression=gzip

echo "Waiting 10 minutes"
sleep 600

echo "Running RF3 producer consumer test with NO compression"
ansible-playbook -i settings.yml -i inventory.yml test-producer-consumer-2.yml \
-e test_prefix=testtopic \
-e partitions=16 \
-e replication=3 \
-e retention=3600000 \
-e throughput=-1 \
-e record_size=100 \
-e num_records=2500000000 \
-e acks=-1 \
-e compression=none

echo "Waiting 10 minutes"
sleep 600

echo "Running RF4 with producer consumer test with GZIP compression"
ansible-playbook -i settings.yml -i inventory.yml test-producer-consumer-2.yml \
-e test_prefix=testtopic \
-e partitions=16 \
-e replication=4 \
-e retention=3600000 \
-e throughput=-1 \
-e record_size=100 \
-e num_records=2500000000 \
-e acks=-1 \
-e compression=gzip

echo "Waiting 10 minutes"
sleep 600

echo "Running RF4 with producer consumer test with NO compression"
ansible-playbook -i settings.yml -i inventory.yml test-producer-consumer-2.yml \
-e test_prefix=testtopic \
-e partitions=16 \
-e replication=4 \
-e retention=3600000 \
-e throughput=-1 \
-e record_size=100 \
-e num_records=2500000000 \
-e acks=-1 \
-e compression=none

echo "All testing complete"
