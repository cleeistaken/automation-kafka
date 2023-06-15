from typing import List

from kafka_command import KafkaCommand


class KafkaProducer(KafkaCommand):

    def __init__(self,
                 bootstrap_servers: List[str],
                 bootstrap_port: int,
                 topic: str,
                 acks: str,
                 buffer_memory: int,
                 batch_size: int,
                 compression_type: str,
                 client_id: str,
                 record_size: int,
                 throughput: int,
                 num_records: int):
        super().__init__(bootstrap_servers, bootstrap_port)
        self.binary = "`find /opt/confluent/confluent-* -name kafka-producer-perf-test`"
        self.topic = topic
        self.acks = acks
        self.buffer_memory = buffer_memory
        self.batch_size = batch_size
        self.compression_type = compression_type
        self.client_id = client_id
        self.record_size = record_size
        self.throughput = throughput
        self.num_records = num_records

    @property
    def compression_type(self) -> str:
        return self._compression_type

    @compression_type.setter
    def compression_type(self, value: str):
        valid_types = ["none", "lz4", "gzip", "snappy"]
        if value not in valid_types:
            raise ValueError(f"Invalid compression type {value} not in valid types ({','.join(valid_types)}).")
        self._compression_type = value

    def test_command(self):
        return " ".join([f"{self.binary}",
                         f"--topic {self.topic}",
                         f"--producer-props",
                         f"bootstrap.servers={self.bootstrap}",
                         f"acks={self.acks}",
                         f"buffer.memory={self.buffer_memory}",
                         f"batch.size={self.batch_size}",
                         f"compression.type={self.compression_type}",
                         f"client.id={self.client_id}",
                         f"--record-size={self.record_size}",
                         f"--throughput={self.throughput}",
                         f"--num-records={self.num_records}"])

    @staticmethod
    def kill_command():
        """ This is really hacky but it kills the producer process without
            killing the SSH shell running the command to kill the kafka process.

            For instance `pkill org.apache.kafka.tools.ProducerPerformance`
            kills both the actual process and the shell since the SSH command
            line running the command.

            123 java -XM org.apache.kafka.tools.ProducerPerformance --brokers... <-- process matches
            456 pkill -f org.apache.kafka.tools.ProducerPerformance                 <-- process also matches

            The following macguver command uses grep to filter the proceses then eliminates
            all the processes running grep, which excludes itself.
        """
        name = "org.apache.kafka.tools.ProducerPerformance"
        return (f'ps -ef |'
                f'grep "{name}" |'
                f'grep -v "grep" |'
                f'tr -s " " |'
                f'cut -f 2 -d " " |'
                f'xargs -r kill -9 ')
