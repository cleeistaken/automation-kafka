# vmware-lab-work

This project encompasses a terraform and ansible environment to set up Kafka and monitoring tools.

## Prerequisites
* Python 3
* Ansible 2.9
* Terraform v0.13
* CentOS / RHEL 7.6 or above

### Orchestration System
This is the linux system used to invoke Terraform and Ansible in order to create the test environment.

#### Orchestration System Setup
1. Install requirements.
    ```
    # Centos 8
    sudo yum -y install python3 python3-pip git wget unzip libselinux-python3
    ```

2. Install Terraform according to the [instructions here](https://www.terraform.io/downloads.html)
    ```
    # Download terraform package
    # Note. The scripts are using features only available in version 0.13+
    TERRAFORM_VERSION=0.13.3
   
    # wget the binary
    wget https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_$TERRAFORM_VERSION_linux_amd64.zip
    
    # Extract
    unzip terraform_$TERRAFORM_VERSION_linux_amd64.zip
    
    # Install
    sudo mv ./terraform /usr/bin/
    ```

3. Clone git repository
    ```
    cd ~
    git clone https://github.com/cleeistaken/automation-kafka.git
    cd automation-cockroach
    ````

4. Create a Python virtual environment.
    ```
    # Create virtual environment
    python3 -m venv $HOME/.python3-venv
   
    # Activate the virtual environment
    source $HOME/.python3-venv/bin/activate
   
    # (optional) Add VENV to login script
    echo "source $HOME/.python3-venv/bin/activate" >> $HOME/.bashrc
    ```

5. Install required python packages.
    ```
    pip install --upgrade pip
    pip install --upgrade setuptools
    pip install -r python-requirements.txt
    ```

### VM Template
We create a template to address the following requirements and limitations.
1. Need a user account and SSH key for Ansible.

#### VM Template Setup
1. Create a Linux VM with a supported distribution and version 

2. Install the required packages for the Terraform customization.
   ```
   sudo yum install open-vm-tools perl
   ```

3. From the ***orchestration system*** create and upload a ssh key to the template VM.
   ```
   # Check and create a key if none exits
   if [ ! -f ~/.ssh/id_rsa ]; then
     ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
   fi
   
   # Copy to the template VM
   ssh-copy-id confluent@<ip of the vm>
   
   ```

4. In vSphere convert the VM to a template to prevent any changes.


## Terraform
The terraform folder contains a few files:

* `main.tf`: this is the main definition of the environment
* `variables.tf`: this is the variables definition file
* `teraform.tfvars`: this is the file where environment specific settings are made

Alter `terraform.tfvars` to include specific information about the vsphere environment, and the Confluent Platform environment you'd like to build. 

Once everything is set, run `terraform init`, then run `terraform plan` to ensure everything looks good. If everything looks right, then run `terraform apply` to apply the configuration.

After everything is built, there will be outputs of the various components IP addresses. Note this for the Ansible section.

## Ansible
Edit `inventory.yml` and set the ansible user, and private key file for access to the target machines, be to include the ip addresses for each service output by the terraform apply. 

Ensure that wherever you run ansible from can ssh to each of the hosts, it's easiest to test this with the Ansible ping module:

```
ansible -i settings.yml -i inventory.yml -m ping all
```


### Preflight
There's a playbook called `preflight-playbook.yml` which does the follwoing:
 
 * opens up the SELinux ports to allow traffic between services
 * formats the disks and then mounts them (you'll want to make sure that the devices specified in the volumes /dev/sdb1 etc.. are correct for the VMs)

 Edit the `preflight-playbook.yml` file and make sure that the Broker and Zookeeper drives are correct (/dev/sdb, /dev/sdc etc...)
 
 Run it like this:

```
ansible-playbook -i settings.yml -i inventory.yml preflight-playbook.yml
```

### Core services
Make sure that the Kafka brokers section has the correct properties set for the environment: `broker.rack`, `default.replication.factor`, and `log.dirs` property is set in `inventory.yml`:

```
172.20.10.11:
      kafka_broker:
        properties:
          broker.rack: isvlab
          default.replication.factor: 3
          log.dirs: /var/lib/kafka/data0,/var/lib/kafka/data1
```

To install the core Kafka, Zookeeper, Connect and Control Center services run the all.yml playbook like this:

```
ansible-playbook -i settings.yml -i inventory.yml all.yml
```

### Tools host
The `tools-provisioning.yml` playbook installs the following services

* Installs Prometheus on the tools host specified in `inventory.yml`
* Installs [Prometheus node exporter](https://github.com/prometheus/node_exporter) on all hosts
* Installs core kafka commands needed for performance tests on tools host
* Installs Grafana on the tools host
* Installs filebeats on all hosts, which collect from:
    * /var/log/*.log
    * /var/kafka/*.log
    * /var/kafka/*.current
    * /var/zookeeper/*.log
    * /var/zookeeper/*.current
* Installs Kibana, Elasticsearch, and Logstash on the tools host

Install Ansible Galaxy roles:

```
ansible-galaxy install -r ansible-requirements.yml
```


Install tools:

```
ansible-playbook -i settings.yml -i inventory.yml tools-provisioning.yml
```

#### Grafana Configuration
After the `tools-provisioning.yml` playbook runs a Grafana instance will be running on port 3000 of the tools host:

user/pass - confluent/confluent

**Add Prometheus Data Source**
Add a data source in Grafana under the `configuration -> data sources` menu. Set the URL to `http://<tools host>:9090` and set it to default.

**Import Kafka and Host Dashboards**
(Import JSON dashboards)[https://grafana.com/docs/grafana/latest/reference/export_import/#importing-a-dashboard] from the `grafana-dashboards` directory in this repository. 
