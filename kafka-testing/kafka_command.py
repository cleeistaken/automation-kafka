from typing import List

MIN_TCP_PORT = 1
MAX_TCP_PORT = 65535


class KafkaCommand:
    def __init__(self,
                 bootstrap_servers: List[str],
                 bootstrap_port: int):
        self.bootstrap_servers = bootstrap_servers
        self.bootstrap_port = bootstrap_port
        self.bootstrap = ",".join([f"{x}:{self.bootstrap_port}" for x in self.bootstrap_servers])

    @property
    def bootstrap_port(self) -> int:
        return self._bootstrap_port

    @bootstrap_port.setter
    def bootstrap_port(self, value):
        if value < MIN_TCP_PORT or value > MAX_TCP_PORT:
            raise ValueError(f"Invalid port number {value} not in valid range ([{MIN_TCP_PORT}, {MAX_TCP_PORT}]).")
        self._bootstrap_port = value
