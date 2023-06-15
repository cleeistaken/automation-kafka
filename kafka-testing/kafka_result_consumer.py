import numpy as np
import re

from asyncssh import SSHCompletedProcess
from datetime import datetime
from matplotlib import pyplot as plt
from pathlib import Path
from typing import List

from kafka_result import KafkaResult


class KafkaConsumerResult(KafkaResult):

    # This matches consumer summary
    match_1 = re.compile(r"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{1,2}:\d{1,3}), "
                         r"(\d+), "
                         r"(\d+.\d+), "
                         r"(\d+.\d+), "
                         r"(\d+), "
                         r"(\d+.\d+), "
                         r"(-{0,1}\d+), "
                         r"(-{0,1}\d+), "
                         r"(\d+.\d+), "
                         r"(\d+.\d+)$")
    time_format = "%Y-%m-%d %H:%M:%S:%f"

    def __init__(self, results: List[SSHCompletedProcess]):
        super().__init__(results=results)

        self.consumer = []
        self.consumer_data = []

        for result in self.results:
            data = {
                "time": [],
                "thread_id": [],
                "data_consumed_mb": [],
                "mb_sec": [],
                "data_consumer_msg": [],
                "msg_sec": [],
                "rebalance_time_ms": [],
                "fetch_time_ms": [],
                "fetch_mb_sec": [],
                "fetch_msg_sec": [],
            }

            lines = result.stdout.splitlines()

            for line in lines[1:len(lines)]:
                found = self.match_1.match(line)
                if found:
                    data["time"].append(datetime.strptime(found.group(1), self.time_format))
                    data["thread_id"].append(int(found.group(2)))
                    data["data_consumed_mb"].append(float(found.group(3)))
                    data["mb_sec"].append(float(found.group(4)))
                    data["data_consumer_msg"].append(int(found.group(5)))
                    data["msg_sec"].append(float(found.group(6)))
                    data["rebalance_time_ms"].append(int(found.group(7)))
                    data["fetch_time_ms"].append(int(found.group(8)))
                    data["fetch_mb_sec"].append(float(found.group(9)))
                    data["fetch_msg_sec"].append(float(found.group(10)))
                else:
                    print(f"ERROR: Could not parse data line: {line}")

            # Append data
            self.consumer_data.append(data)

    def save_completed_process(self, folder: Path, file_prefix: str):
        super().save_completed_process(folder=folder, file_prefix=file_prefix)
        folder.mkdir(parents=True, exist_ok=True)

    def create_plots(self, folder: Path, file_prefix: str):

        # Call parent
        super().create_plots(folder, file_prefix)

        # Individual plots
        plots = [
            {
                'filename': f'{file_prefix}_mb_sec.png',
                'field': 'mb_sec',
                'title': 'MB per Second',
                'y_axis': 'MB/Sec',
                'x_axis': 'time'
            },
            {
                'filename': f'{file_prefix}_msg_sec.png',
                'field': 'msg_sec',
                'title': 'Messages per Second',
                'y_axis': 'Messages/Sec',
                'x_axis': 'time'
            },
            {
                'filename': f'{file_prefix}_fetch_time_ms.png',
                'field': 'fetch_time_ms',
                'title': 'Fetch Time Milliseconds',
                'y_axis': 'Milliseconds',
                'x_axis': 'time'
            },
            {
                'filename': f'{file_prefix}_fetch_mb_sec.png',
                'field': 'fetch_mb_sec',
                'title': 'Fetch MB per Second',
                'y_axis': 'MB/Sec',
                'x_axis': 'time'
            },
            {
                'filename': f'{file_prefix}_fetch_msg_sec.png',
                'field': 'fetch_msg_sec',
                'title': 'Fetch Messages per Second',
                'y_axis': 'Messages/Sec',
                'x_axis': 'time'
            }
        ]

        for plot in plots:

            # Configure plot
            plt.figure(figsize=(11, 8))
            plt.title(f"Consumer - {plot['title']}")
            plt.xlabel(plot['x_axis'])
            plt.ylabel(plot['y_axis'])

            # Add data points
            for i, p in enumerate(self.consumer_data):
                x = p['time']
                y = p[plot['field']]
                plt.plot(x, y, label=f'consumer_{i}')

            # Add legend
            plt.legend()

            # Save the plot
            plt.savefig(folder.joinpath(plot['filename']))

            # Close
            plt.close()


        # Aggregate plots
        plots = [
            {
                'filename': f'{file_prefix}_total_mb_sec.png',
                'field': 'mb_sec',
                'title': 'MB per Second',
                'y_axis': 'MB/Sec',
                'x_axis': 'time'
            },
            {
                'filename': f'{file_prefix}_total_msg_sec.png',
                'field': 'msg_sec',
                'title': 'Messages per Second',
                'y_axis': 'Messages/Sec',
                'x_axis': 'time'
            }
        ]

        # Create dataframe for data manipulation
        for plot in plots:

            # Configure plot
            plt.figure(figsize=(11, 8))
            plt.title(f"Consumer - {plot['title']}")
            plt.xlabel(plot['x_axis'])
            plt.ylabel(plot['y_axis'])

            # Add data points
            rows = [p[plot['field']] for p in self.consumer_data]

            # Make all the rows the same length,
            row_lengths = []
            for row in rows:
                row_lengths.append(len(row))
            max_length = max(row_lengths)

            for row in rows:
                while len(row) < max_length:
                    row.append(0)

            y = np.array(rows).sum(axis=0)
            x = range(len(y))

            if len(x) > 1:
                plt.plot(x, y, label=f'Total')
            else:
                fig, ax = plt.subplots(1, 1)
                ax.bar(['Total'], y, label=f'Total')
                ax.set_xlim(0, 5)

            # Add legend
            plt.legend()

            # Save the plot
            plt.savefig(folder.joinpath(plot['filename']))

            # Close
            plt.close()


