from pathlib import Path

from asyncssh import SSHCompletedProcess


class KafkaTopicResult:

    def __init__(self, result: SSHCompletedProcess):
        self.result = result

    def save_completed_process(self, folder: Path, filename: str):
        folder.mkdir(parents=True, exist_ok=True)
        with open(file=folder.joinpath(f"topic-{filename}.log"), mode="w") as file:
            file.write(f"command: {self.result.command}\n"
                       f"exit_signal: {self.result.exit_signal}\n"
                       f"exit_status: {self.result.exit_status}\n"
                       f"returncode: {self.result.returncode}\n"
                       f"stderr:\n{self.result.stderr}\n"
                       f"stdout:\n{self.result.stdout}\n")