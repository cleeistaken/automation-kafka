import argparse

from kafka_test_runner import KafkaTestRunner


def get_args():
    parser = argparse.ArgumentParser(description='kafka Test Parameters')
    parser.add_argument('--inventory', action="store", dest="inventory", required=True)
    parser.add_argument('--results', action="store", dest="results", required=True)
    parser.add_argument('--tests', nargs='+', dest="tests", required=True)
    return vars(parser.parse_args())


def main():

    # Parse arguments
    args = get_args()

    # Start test
    print("Starting")

    # Create test runner
    print("Creating test runner...")
    ktr = KafkaTestRunner(inventory_file=args['inventory'],
                          settings_file=args['inventory'],
                          test_files=args['tests'],
                          results_folder=args['results'])

    # Execute tests
    print("Executing tests...")
    ktr.execute()

    # End test
    print("Complete")


if __name__ == '__main__':
    main()
