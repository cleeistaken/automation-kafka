from typing import List

import yaml

from kafka_consumer import KafkaConsumer
from kafka_producer import KafkaProducer
from kafka_topic import KafkaTopic


class KafkaTest:
    def __init__(self,
                 file: str,
                 bootstrap: List[str],
                 bootstrap_port: int = 9092,
                 verbose: bool = False):
        data = []
        with open(file, 'r') as stream:
            try:
                data = yaml.safe_load(stream)
            except yaml.YAMLError as e:
                print(e)

        # Bootstrap servers
        self.bootstrap = bootstrap
        self.bootstrap_port = bootstrap_port

        # General Configuration
        self.name = data.get("name")

        # Topic Configurations
        self.partitions = data.get("partitions")
        self.replication_factor = data.get("replication_factor")
        self.retention_ms = data.get("retention_ms")
        self.min_insync_replicas = data.get("min_insync_replicas")
        self.num_topics = data.get("num_topics")
        self.topic_compression_type = data.get("topic_compression_type")

        # Producer Configuration
        self.acks = data.get("acks")
        self.buffer_memory = data.get("buffer_memory")
        self.batch_size = data.get("batch_size")
        self.compression_type = data.get("compression_type")
        self.record_size = data.get("record_size")
        self.throughput = data.get("throughput")
        self.num_records_producer = data.get("num_records_producer")
        self.num_producers = data.get("num_producers")

        # Consumer Configuration
        self.num_records_consumer = data.get("num_records_consumer")
        self.show_detailed_stats = bool(data.get("show_detailed_stats"))
        self.num_consumers = data.get("num_consumers")

    @staticmethod
    def _is_list_of_str(values: List[str]) -> bool:
        return isinstance(values, list) and (False not in [isinstance(value, str) for value in values])

    @property
    def bootstrap(self):
        return self._bootstrap

    @bootstrap.setter
    def bootstrap(self, values):
        if not self._is_list_of_str(values):
            raise ValueError(f"Input for bootstrap is not a list of strings: {values}")
        self._bootstrap = values

    def get_topics(self) -> List[KafkaTopic]:
        return [KafkaTopic(bootstrap_servers=self.bootstrap,
                           bootstrap_port=self.bootstrap_port,
                           name=f"{self.name}-{topic_num}",
                           partitions=self.partitions,
                           replication_factor=self.replication_factor,
                           retention_ms=self.retention_ms,
                           min_insync_replicas=self.min_insync_replicas,
                           compression_type=self.topic_compression_type)
                for topic_num in range(self.num_topics)]

    def get_producers(self) -> List[KafkaProducer]:
        topic_names = [f"{self.name}-{topic_num}" for topic_num in range(self.num_topics)]
        return [KafkaProducer(bootstrap_servers=self.bootstrap,
                              bootstrap_port=self.bootstrap_port,
                              topic=topic_names[(num % len(topic_names))],
                              acks=self.acks,
                              buffer_memory=self.buffer_memory,
                              batch_size=self.batch_size,
                              compression_type=self.compression_type,
                              client_id=f"{self.name}-producer-{num}",
                              record_size=self.record_size,
                              throughput=self.throughput,
                              num_records=self.num_records_producer)
                for num in range(self.num_producers)]

    def get_consumers(self) -> List[KafkaConsumer]:
        topic_names = [f"{self.name}-{topic_num}" for topic_num in range(self.num_topics)]
        return [KafkaConsumer(bootstrap_servers=self.bootstrap,
                              bootstrap_port=self.bootstrap_port,
                              topic=topic_names[(num % len(topic_names))],
                              group=f"{topic_names[(num % len(topic_names))]}-{num}",
                              num_records=self.num_records_consumer,
                              show_detailed_stats=self.show_detailed_stats)
                for num in range(self.num_consumers)]
