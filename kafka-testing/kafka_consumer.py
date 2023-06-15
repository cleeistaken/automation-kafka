from typing import List

from kafka_command import KafkaCommand


class KafkaConsumer(KafkaCommand):
    def __init__(self,
                 bootstrap_servers: List[str],
                 bootstrap_port: int,
                 topic: str,
                 group: str,
                 num_records: int,
                 show_detailed_stats: bool = True):
        super().__init__(bootstrap_servers, bootstrap_port)
        self.binary = "`find /opt/confluent/confluent-* -name kafka-consumer-perf-test`"
        self.topic = topic
        self.group = group
        self.num_records = num_records
        self.show_detailed_stats = show_detailed_stats

    def test_command(self):
        return " ".join([f"{self.binary}",
                         f"--broker-list {self.bootstrap}",
                         f"--topic {self.topic}",
                         f"--group {self.group}",
                         f"--messages {self.num_records}",
                         f"{'--show-detailed-stats' if self.show_detailed_stats else ''}"])
