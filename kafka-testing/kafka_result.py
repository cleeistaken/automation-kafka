import abc
from pathlib import Path
from typing import List

from asyncssh import SSHCompletedProcess


class KafkaResult:

    def __init__(self, results: List[SSHCompletedProcess]):
        self.results = results

    def save_completed_process(self, folder: Path, file_prefix: str):
        folder.mkdir(parents=True, exist_ok=True)
        for i, result in enumerate(self.results):
            with open(file=folder.joinpath(f"{file_prefix}-{i}.log"), mode="w") as file:
                file.write(f"command: {result.command}\n"
                           f"exit_signal: {result.exit_signal}\n"
                           f"exit_status: {result.exit_status}\n"
                           f"returncode: {result.returncode}\n"
                           f"stderr:\n{result.stderr}\n"
                           f"stdout:\n{result.stdout}\n")

    @abc.abstractmethod
    def create_plots(self, folder: Path, file_prefix: str):

        # Make sure result folder exists
        folder.mkdir(parents=True, exist_ok=True)
