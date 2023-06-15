import yaml

from typing import List


class KafkaInventory:
    def __init__(self, file: str):
        self.inventory = {}
        with open(file, 'r') as stream:
            try:
                self.inventory = yaml.safe_load(stream)
            except yaml.YAMLError as e:
                print(e)

        self.kafka_brokers = self._get_servers("kafka_broker")
        self.control_centers = self._get_servers("control_center")
        self.kafka_connects = self._get_servers("kafka_connect")
        self.zookeepers = self._get_servers("zookeeper")

    def _get_servers(self, name: str):
        return [k1 for k1 in self.inventory.get(name, {}).get("hosts", {}).keys()]

    @staticmethod
    def _is_list_of_str(values: List[str]) -> bool:
        return isinstance(values, list) and (False not in [isinstance(value, str) for value in values])

    @property
    def kafka_brokers(self) -> List[str]:
        return self._kafka_brokers

    @kafka_brokers.setter
    def kafka_brokers(self, values: list[str]):
        if not self._is_list_of_str(values):
            raise ValueError(f"Input for kafka_brokers is not a list of strings: {values}")
        self._kafka_brokers = values

    @property
    def control_centers(self) -> List[str]:
        return self._control_centers

    @control_centers.setter
    def control_centers(self, values: list[str]):
        if not self._is_list_of_str(values):
            raise ValueError(f"Input for control_centers is not a list of strings: {values}")
        self._control_centers = values

    @property
    def kafka_connects(self) -> List[str]:
        return self._kafka_connects

    @kafka_connects.setter
    def kafka_connects(self, values: list[str]):
        if not self._is_list_of_str(values):
            raise ValueError(f"Input for kafka_connects is not a list of strings: {values}")
        self._kafka_connects = values

    @property
    def zookeepers(self) -> List[str]:
        return self._zookeepers

    @zookeepers.setter
    def zookeepers(self, values: list[str]):
        if not self._is_list_of_str(values):
            raise ValueError(f"Input for zookeepers is not a list of strings: {values}")
        self._zookeepers = values

    @property
    def bootstrap(self) -> List[str]:
        return self.kafka_brokers[0:3]
