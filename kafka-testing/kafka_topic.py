from typing import List, Union

from kafka_command import KafkaCommand


class KafkaTopic(KafkaCommand):

    ALLOWED_COMPRESSION = ["gzip", "snappy", "lz4", "zstd"]

    def __init__(self,
                 bootstrap_servers: List[str],
                 bootstrap_port: int,
                 name: str,
                 partitions: int,
                 replication_factor: int,
                 retention_ms: int,
                 min_insync_replicas: int,
                 compression_type: str = None):
        super().__init__(bootstrap_servers, bootstrap_port)
        self.binary = "`find /opt/confluent/confluent-* -name kafka-topics`"
        self.name = name
        self.partitions = partitions
        self.replication_factor = replication_factor
        self.retention_ms = retention_ms
        self.min_insync_replicas = min_insync_replicas
        self.compression_type = compression_type

    def create_command(self):
        command = " ".join([f"{self.binary}",
                            f"--bootstrap-server {self.bootstrap}",
                            f"--topic {self.name}",
                            f"--create --partitions {self.partitions}",
                            f"--replication-factor {self.replication_factor}",
                            f"--config retention.ms={self.retention_ms}",
                            f"--config min.insync.replicas={self.min_insync_replicas}"])

        if self.compression_type:
            command = f"{command} --config compression_type={self.compression_type}"

        return command

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

    @property
    def compression_type(self) -> Union[str, None]:
        return self._compression_type

    @compression_type.setter
    def compression_type(self, value: Union[str, None]):
        if value is None:
            self._compression_type = None
        elif isinstance(value, str):
            if value.lower() not in self.ALLOWED_COMPRESSION:
                raise ValueError(f"Specified compression type {value} is not in {self.ALLOWED_COMPRESSION}.")
            self._compression_type = value.lower()
        else:
            raise ValueError(f"Compression type must be 'None' or 'str' in {self.ALLOWED_COMPRESSION}.")
