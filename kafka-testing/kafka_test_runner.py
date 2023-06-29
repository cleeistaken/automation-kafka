import asyncio
import pathlib
import shutil
import sys
import time
from pathlib import Path
from typing import List, Tuple

import asyncssh

from kafka_inventory import KafkaInventory
from kafka_producer import KafkaProducer
from kafka_result_consumer import KafkaConsumerResult
from kafka_result_producer import KafkaProducerResult
from kafka_result_topic import KafkaTopicResult
from kafka_settings import KafkaSettings
from kafka_test import KafkaTest


class KafkaTestRunner:

    @staticmethod
    def _copy(source: str, target: str):
        assert Path(source).is_file()
        shutil.copy(source, target)

    def __init__(self, inventory_file: str, settings_file: str, test_files: List[str], results_folder: str):

        # This will be used to create the tests sub-folder
        self.test_epoch = int(time.time())
        self.result_folder = pathlib.Path(results_folder, f"kafka-{str(self.test_epoch)}")
        self.result_folder.mkdir(parents=True, exist_ok=False)

        # This assumes our current file structure. This should be generalized
        self.inventory = KafkaInventory(inventory_file)
        self.settings = KafkaSettings(settings_file)

        # Test(s) that we want to run
        self.tests = [KafkaTest(file=test_file,
                                bootstrap=self.inventory.bootstrap,
                                bootstrap_port=self.settings.broker_port)
                      for test_file in test_files]

        # Copy settings to file
        test_config = self.result_folder.joinpath('config.txt')
        with test_config.open("a") as file:
            file.write(f"inventory: {inventory_file}\n", )
            file.write(f"settings: {settings_file}\n")
            file.write(f"tests: [{', '.join(test_files)}]\n")

        self._copy(inventory_file, str(self.result_folder))
        self._copy(settings_file, str(self.result_folder))
        for test_file in test_files:
            self._copy(test_file, str(self.result_folder))

    def run_command(self, server: str, command: str):

        async def run_client(host: str, cmd: str):
            async with asyncssh.connect(host, username=self.settings.user, client_keys=self.settings.private_key, known_hosts=None) as conn:
                return await conn.run(cmd, check=True)

        try:
            return asyncio.get_event_loop().run_until_complete(run_client(host=server, cmd=command))
        except (OSError, asyncssh.Error) as exc:
            sys.exit('SSH connection failed: ' + str(exc))

    def run_commands(self, servers: List[str], commands: List[str]):

        async def run_client(host: str, cmd: str):
            async with asyncssh.connect(host, username=self.settings.user, client_keys=self.settings.private_key, known_hosts=None) as conn:
                return await conn.run(cmd, check=True)

        async def run_multiple_clients():

            tasks = (run_client(servers[num % len(servers)], command) for num, command in enumerate(commands))
            results = await asyncio.gather(*tasks, return_exceptions=True)

            for i, result in enumerate(results, 1):
                if isinstance(result, Exception):
                    print('Task %d failed: %s' % (i, str(result)))
                elif result.exit_status != 0:
                    print('Task %d exited with status %s:' % (i, result.exit_status))
                    print(result.stderr, end='')
                else:
                    print('Task %d succeeded:' % i)
                    print(result.stdout, end='')

                print(75 * '-')

            return results

        return asyncio.get_event_loop().run_until_complete(run_multiple_clients())

    def execute(self):
        for test in self.tests:
            print(f"Running tests: {test.name}")
            kpr, kcr = self._run_test(test=test)
        print("Done")

    def _run_test(self, test: KafkaTest) -> Tuple[KafkaProducerResult, KafkaConsumerResult]:

        test_time = int(time.time())
        test_result_folder = self.result_folder.joinpath(f"{str(test_time)}-{test.name}")

        print("Killing any existing producers")
        for connect in self.inventory.kafka_connects:
            res = self.run_command(server=connect, command=KafkaProducer.kill_command())

        print("Preparing topics")
        for topic in test.get_topics():

            print(f"Checking topic {topic.name}")
            res = self.run_command(self.inventory.kafka_connects[0], topic.list_command())

            if topic.name in res.stdout:
                print(f"Deleting topic {topic.name}")
                res = self.run_command(self.inventory.kafka_connects[0], topic.delete_command())

            print(f"Creating topic {topic.name}")
            res = self.run_command(server=self.inventory.kafka_connects[0], command=topic.create_command())

            print("Saving topic creation result to file.")
            kafka_consumer_results = KafkaTopicResult(result=res)
            kafka_consumer_results.save_completed_process(folder=test_result_folder, filename=topic.name)

        print("Waiting 3 minutes")
        time.sleep(180)

        print("Running producers.")
        commands = [x.test_command() for x in test.get_producers()]
        results = self.run_commands(servers=self.inventory.kafka_connects, commands=commands)

        print("Saving producer results to file.")
        kafka_producer_results = KafkaProducerResult(results=results)
        kafka_producer_results.save_completed_process(folder=test_result_folder, file_prefix="producer")

        print("Generating producer plots.")
        kafka_producer_results.create_plots(folder=test_result_folder, file_prefix="producer")

        print("Waiting 3 minutes")
        time.sleep(180)

        print("Running consumers.")
        commands = [x.test_command() for x in test.get_consumers()]
        results = self.run_commands(servers=self.inventory.kafka_connects, commands=commands)

        print("Saving consumer results to file.")
        kafka_consumer_results = KafkaConsumerResult(results=results)
        kafka_consumer_results.save_completed_process(folder=test_result_folder, file_prefix="consumer")

        print("Generating consumer plots.")
        kafka_consumer_results.create_plots(folder=test_result_folder, file_prefix="consumer")

        print("Clean up topics")
        for topic in test.get_topics():

            print(f"Deleting topic {topic.name}")
            self.run_command(self.inventory.kafka_connects[0], topic.delete_command())

        print("Waiting 5 minutes")
        time.sleep(300)

        print(f"Test {test.name} complete")

        # Return results
        return kafka_producer_results, kafka_consumer_results