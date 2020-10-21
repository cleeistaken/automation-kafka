#
# This file is automatically generated by the Terraform inventory module
#
---
all:
  hosts:
%{ for item in kafka ~}%{ for types in item.kafka.cluster ~}%{ for vm in types ~}
    ${ vm.clone[0].customize[0].network_interface[0].ipv4_address }:
      name: ${ vm.name }
      hostname: ${ vm.clone[0].customize[0].linux_options[0].host_name }.${ vm.clone[0].customize[0].linux_options[0].domain }
%{ endfor ~}%{ endfor ~}%{ endfor ~}

  children:
    kafka_broker:
      children:
%{ for item in kafka ~}
        kafka_broker_${ item.kafka.cluster_id }:
          hosts:
%{ for vm in item.kafka.cluster.broker ~}
            ${ vm.clone[0].customize[0].network_interface[0].ipv4_address }:
              kafka_broker:
                datadir:
%{ for i in range(1, length(vm.disk)) ~}
                  - /var/lib/kafka/data${ (i - 1) }
%{ endfor ~}
                properties:
                  broker.rack: rack_${ item.kafka.cluster_id }
                  default.replication.factor: 3
              # Leave broker ID unset to have it automatically assigned. Uncomment and set if
              # it needs to be set to a specific value.
              # https://kafka.apache.org/20/documentation.html
              # broker_id: 0
              kafka_broker_custom_listeners:
                external:
                  hostname: ${ vm.clone[0].customize[0].network_interface[0].ipv4_address }
                internal:
                  hostname: ${ vm.clone[0].customize[0].network_interface[1].ipv4_address }
%{ endfor ~}
%{ endfor ~}

    zookeeper:
      children:
%{ for item in kafka ~}
        zookeeper_${ item.kafka.cluster_id }:
          hosts:
%{ for vm in item.kafka.cluster.zookeeper ~}
            ${ vm.clone[0].customize[0].network_interface[0].ipv4_address }:
              # Leave zookeeper ID unset to have it automatically assigned. Uncomment and set if
              # it needs to be set to a specific value.
              # https://kafka.apache.org/20/documentation.html
              # zookeeper_id: -1
%{ endfor ~}
%{ endfor ~}

    control_center:
      children:
%{ for item in kafka ~}
        control_center_${ item.kafka.cluster_id }:
          hosts:
%{ for vm in item.kafka.cluster.control_center ~}
            ${ vm.clone[0].customize[0].network_interface[0].ipv4_address }:
%{ endfor ~}
%{ endfor ~}

    kafka_connect:
      children:
%{ for item in kafka ~}
        kafka_connect_${ item.kafka.cluster_id }:
          hosts:
%{ for vm in item.kafka.cluster.connect ~}
            ${ vm.clone[0].customize[0].network_interface[0].ipv4_address }:
%{ endfor ~}
%{ endfor ~}

#
# EOF
#

