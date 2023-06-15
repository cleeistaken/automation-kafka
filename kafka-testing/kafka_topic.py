from typing import List

from kafka_command import KafkaCommand


class KafkaTopic(KafkaCommand):
    def __init__(self,
                 bootstrap_servers: List[str],
                 bootstrap_port: int,
                 name: str,
                 partitions: int,
                 replication_factor: int,
                 retention_ms: int,
                 min_insync_replicas: int):
        super().__init__(bootstrap_servers, bootstrap_port)
        self.binary = "`find /opt/confluent/confluent-* -name kafka-topics`"
        self.name = name
        self.partitions = partitions
        self.replication_factor = replication_factor
        self.retention_ms = retention_ms
        self.min_insync_replicas = min_insync_replicas

    def create_command(self):
        return " ".join([f"{self.binary}",
                         f"--bootstrap-server {self.bootstrap}",
                         f"--topic {self.name}",
                         f"--create --partitions {self.partitions}",
                         f"--replication-factor {self.replication_factor}",
                         f"--config retention.ms={self.retention_ms}",
                         f"--config min.insync.replicas={self.min_insync_replicas}"])

    def delete_command(self):
        return " ".join([f"{self.binary}",
                         f"--bootstrap-server {self.bootstrap}",
                         f"--topic {self.name}",
                         f"--delete"])

    def list_command(self):
        return " ".join([f"{self.binary}",
                         f"--bootstrap-server {self.bootstrap}",
                         f"--topic {self.name}",
                         f"--list"])

    def list_all_command(self):
        return " ".join([f"{self.binary}",
                         f"--bootstrap-server {self.bootstrap}",
                         f"--list"])
