#
# This file is automatically generated by the Terraform inventory module
#
---
all:
  vars:
    vcenter:
      host: ${ vsphere_server }
      username: ${ user }
      password: ${ password }
      allow_unverified_ssl: ${ allow_unverified_ssl }

  hosts:
%{ for item in vms ~}%{ for types in item ~}%{ for vm in types ~}
    ${ vm.clone[0].customize[0].network_interface[0].ipv4_address }:
      name: ${ vm.name }
      hostname: ${ vm.clone[0].customize[0].linux_options[0].host_name }.${ vm.clone[0].customize[0].linux_options[0].domain }
      uuid: ${ vm.id }
%{ endfor ~}%{ endfor ~}%{ endfor ~}

  children:
    control_center:
%{ for item in vms ~}
      hosts:
%{ for vm in item.control_center ~}
        ${ vm.clone[0].customize[0].network_interface[0].ipv4_address }:
          hostname: ${ vm.name }
          fqdn: ${ vm.clone[0].customize[0].linux_options[0].host_name }.${ vm.clone[0].customize[0].linux_options[0].domain }
          uuid: ${ vm.id }
          data_disks:
%{ for i in range(1, length(vm.disk)) ~}
            - sd${ ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"][i] }
%{ endfor ~}
%{ endfor ~}%{ endfor ~}

    kafka_broker:
%{ for item in vms ~}
      hosts:
%{ for vm in item.broker ~}
        ${ vm.clone[0].customize[0].network_interface[0].ipv4_address }:
          hostname: ${ vm.name }
          fqdn: ${ vm.clone[0].customize[0].linux_options[0].host_name }.${ vm.clone[0].customize[0].linux_options[0].domain }
          uuid: ${ vm.id }
          data_disks:
%{ for i in range(1, length(vm.disk)) ~}
            - sd${ ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"][i] }
%{ endfor ~}
          kafka_broker:
            datadir:
%{ for i in range(1, length(vm.disk)) ~}
              - /data${ (i - 1) }
%{ endfor ~}
            properties:
              broker.rack: rack_1
              default.replication.factor: 3
            # Leave broker ID unset to have it automatically assigned. Uncomment and set if
            # it needs to be set to a specific value.
            # https://kafka.apache.org/20/documentation.html
            # broker_id: 0
            kafka_broker_custom_listeners:
              broker:
                hostname: ${ vm.clone[0].customize[0].network_interface[0].ipv4_address }
              internal:
                hostname: ${ vm.clone[0].customize[0].network_interface[1].ipv4_address }
%{ endfor ~}%{ endfor ~}

    zookeeper:
%{ for item in vms ~}
      hosts:
%{ for vm in item.zookeeper ~}
        ${ vm.clone[0].customize[0].network_interface[0].ipv4_address }:
          hostname: ${ vm.name }
          fqdn: ${ vm.clone[0].customize[0].linux_options[0].host_name }.${ vm.clone[0].customize[0].linux_options[0].domain }
          uuid: ${ vm.id }
          data_disks:
%{ for i in range(1, length(vm.disk)) ~}
            - sd${ ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n"][i] }
%{ endfor ~}
          # Leave zookeeper ID unset to have it automatically assigned. Uncomment and set if
          # it needs to be set to a specific value.
          # https://kafka.apache.org/20/documentation.html
          # zookeeper_id: -1
%{ endfor ~}%{ endfor ~}

    kafka_connect:
%{ for item in vms ~}
      hosts:
%{ for vm in item.connect ~}
        ${ vm.clone[0].customize[0].network_interface[0].ipv4_address }:
          hostname: ${ vm.name }
          fqdn: ${ vm.clone[0].customize[0].linux_options[0].host_name }.${ vm.clone[0].customize[0].linux_options[0].domain }
          uuid: ${ vm.id }
%{ endfor ~}%{ endfor ~}

#
# EOF
#