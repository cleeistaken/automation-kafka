#! /bin/bash

echo "Killing any running tests"
ansible-playbook -i hosts-3-cluster.yml kill-tests.yml

echo "Waiting 1 minute"
sleep 60

echo "Running RF3 producer consumer test with GZIP compression"
ansible-playbook -i settings.yml -i hosts.yml test-producer-consumer.yml \
-e test_prefix=testtopic \
-e partitions=16 \
-e replication=3 \
-e bootstrap="172.17.3.101:9092" \
-e retention=3600000 \
-e throughput=-1 \
-e record_size=100 \
-e num_records=2500000000 \
-e acks=-1 \
-e compression=gzip

echo "Waiting 10 minutes"
sleep 600

echo "Running RF3 producer consumer test with NO compression"
ansible-playbook -i settings.yml -i hosts.yml test-producer-consumer.yml \
-e test_prefix=testtopic \
-e partitions=16 \
-e replication=3 \
-e bootstrap="172.17.3.101:9092" \
-e retention=3600000 \
-e throughput=-1 \
-e record_size=100 \
-e num_records=2500000000 \
-e acks=-1 \
-e compression=none

#echo "Waiting 10 minutes"
sleep 600

echo "Running RF4 with producer consumer test with GZIP compression"
ansible-playbook -i settings.yml -i hosts.yml test-producer-consumer.yml \
-e test_prefix=testtopic \
-e partitions=16 \
-e replication=4 \
-e bootstrap="172.17.3.101:9092" \
-e retention=3600000 \
-e throughput=-1 \
-e record_size=100 \
-e num_records=2500000000 \
-e acks=-1 \
-e compression=gzip

echo "Waiting 10 minutes"
sleep 600

echo "Running RF4 with producer consumer test with NO compression"
ansible-playbook -i settings.yml -i hosts.yml test-producer-consumer.yml \
-e test_prefix=testtopic \
-e partitions=16 \
-e replication=4 \
-e bootstrap="172.17.3.101:9092" \
-e retention=3600000 \
-e throughput=-1 \
-e record_size=100 \
-e num_records=2500000000 \
-e acks=-1 \
-e compression=none

echo "All testing complete"
