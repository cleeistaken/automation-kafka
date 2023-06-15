import numpy as np
import pandas as pd
import re

from asyncssh import SSHCompletedProcess
from matplotlib import pyplot as plt
from pathlib import Path
from typing import List

from kafka_result import KafkaResult


class KafkaProducerResult(KafkaResult):

    # This matches the data while the producer is running
    match_1 = re.compile(r"^(\d+) records sent, "
                         r"(\d+.\d+) records\/sec "
                         r"\((\d+.\d+) ((?:K|M|G|T)B\/sec)\), "
                         r"(\d+.\d+) ms avg latency, "
                         r"(\d+.\d+) ms max latency.$")

    # This matches the final summary line
    match_2 = re.compile(r"^(\d+) records sent, "
                         r"(\d+.\d+) records\/sec "
                         r"\((\d+.\d+) ((?:K|M|G|T)B\/sec)\), "
                         r"(\d+.\d+) ms avg latency, "
                         r"(\d+.\d+) ms max latency, "
                         r"(\d+) ms 50th, "
                         r"(\d+) ms 95th, "
                         r"(\d+) ms 99th, "
                         r"(\d+) ms 99.9th.$")

    def __init__(self, results: List[SSHCompletedProcess]):
        super().__init__(results=results)

        # Reset
        self.producer_data = []
        self.producer_summary = []

        # Process runtime data line by line
        for result in results:
            lines = result.stdout.splitlines()
            data = {
                "records": [],
                "records_sec": [],
                "throughput": [],
                "throughput_unit": [],
                "avg_lat": [],
                "max_lat": [],
            }

            # Process everything except the last line (summary)
            for line in lines[0:len(lines) - 1]:
                found = self.match_1.match(line)
                if found:
                    data["records"].append(int(found.group(1)))
                    data["records_sec"].append(float(found.group(2)))
                    data["throughput"].append(float(found.group(3)))
                    data["throughput_unit"].append(found.group(4))
                    data["avg_lat"].append(float(found.group(5)))
                    data["max_lat"].append(float(found.group(6)))
                else:
                    print(f"ERROR: Could not parse data line: {line}")

            # Append data
            self.producer_data.append(data)

            # Process summary line
            found = self.match_2.match(lines[len(lines) - 1])
            if found:
                self.producer_summary.append({
                    "records": int(found.group(1)),
                    "records_sec": float(found.group(2)),
                    "throughput": float(found.group(3)),
                    "throughput_unit": found.group(4),
                    "avg_lat": float(found.group(5)),
                    "max_lat": float(found.group(6)),
                    "lat_50th": float(found.group(7)),
                    "lat_95th": float(found.group(8)),
                    "lat_99th": float(found.group(9)),
                    "lat_99_9th": float(found.group(10)),
                })
            else:
                print(f"ERROR: Could not parse summary line: {lines[len(lines) - 1]}")

    def save_completed_process(self, folder: Path, file_prefix: str):
        super().save_completed_process(folder=folder, file_prefix=file_prefix)
        folder.mkdir(parents=True, exist_ok=True)

        # Create dataframe for data manipulation
        df = pd.DataFrame(self.producer_summary)

        # Calculate values
        records = df["records"].sum()
        records_sec = df["records_sec"].sum()
        throughput = df["throughput"].sum()
        avg_lat = df["avg_lat"].mean()
        max_lat = df["max_lat"].max()
        lat_50th = df["lat_50th"].mean()
        lat_95th = df["lat_95th"].mean()
        lat_99th = df["lat_99th"].mean()
        lat_99_9th = df["lat_99_9th"].mean()

        with open(file=folder.joinpath(f"{file_prefix}-summary.log"), mode="w") as file:
            file.write(f"records: {records}\n"
                       f"records_sec: {records_sec:0.2f}\n"
                       f"throughput: {throughput:0.2f}\n"
                       f"avg_lat: {avg_lat:0.2f}\n"
                       f"max_lat: {max_lat:0.2f}\n"
                       f"lat_50th: {lat_50th:0.2f}\n"
                       f"lat_95th: {lat_95th:0.2f}\n"
                       f"lat_99th: {lat_99th:0.2f}\n"
                       f"lat_99_9th: {lat_99_9th:0.2f}")

    def create_plots(self, folder: Path, file_prefix: str):

        # Call parent
        super().create_plots(folder, file_prefix)

        # Individual plots
        plots = [
            {
                'filename': f'{file_prefix}_records_sec.png',
                'field': 'records_sec',
                'title': 'Records per Second',
                'y_axis': 'Records/Sec',
                'x_axis': 'Interval'
            },
            {
                'filename': f'{file_prefix}_avg_lat.png',
                'field': 'avg_lat',
                'title': 'Average Latency',
                'y_axis': 'Milliseconds',
                'x_axis': 'Interval'
            },
            {
                'filename': f'{file_prefix}_max_lat.png',
                'field': 'max_lat',
                'title': 'Maximum Latency',
                'y_axis': 'Milliseconds',
                'x_axis': 'Interval'
            },
            {
                'filename': f'{file_prefix}_throughput.png',
                'field': 'throughput',
                'title': 'Throughput',
                'y_axis': 'MB/s',
                'x_axis': 'Interval'
            }
        ]

        # Create dataframe for data manipulation
        for plot in plots:

            # Configure plot
            plt.figure(figsize=(11, 8))
            plt.title(f"Producer - {plot['title']}")
            plt.xlabel(plot['x_axis'])
            plt.ylabel(plot['y_axis'])

            # Add data points
            for i, p in enumerate(self.producer_data):
                y = p[plot['field']]
                x = range(len(y))
                plt.plot(x, y, label=f'producer_{i}')

            # Add legend
            plt.legend()

            # Save the plot
            plt.savefig(folder.joinpath(plot['filename']))

            # Close
            plt.close()

        # Aggregate plots
        plots = [
            {
                'filename': f'{file_prefix}_total_records_sec.png',
                'field': 'records_sec',
                'title': 'Total Records per Second',
                'y_axis': 'Records/Sec',
                'x_axis': 'Interval'
            },
            {
                'filename': f'{file_prefix}_total_throughput.png',
                'field': 'throughput',
                'title': 'Total Throughput',
                'y_axis': 'MB/s',
                'x_axis': 'Interval'
            }
        ]

        # Create dataframe for data manipulation
        for plot in plots:

            # Configure plot
            plt.figure(figsize=(11, 8))
            plt.title(f"Producer - {plot['title']}")
            plt.xlabel(plot['x_axis'])
            plt.ylabel(plot['y_axis'])

            # Add data points
            rows = [p[plot['field']] for p in self.producer_data]

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
            plt.plot(x, y, label=f'Total')

            # Add legend
            plt.legend()

            # Save the plot
            plt.savefig(folder.joinpath(plot['filename']))

            # Close
            plt.close()
