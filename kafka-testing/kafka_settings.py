import asyncssh
import os
import yaml

from getpass import getpass
from typing import List


class KafkaSettings:
    def __init__(self, file: str):
        self.settings = {}
        with open(file, 'r') as stream:
            try:
                self.settings = yaml.safe_load(stream)
            except yaml.YAMLError as e:
                print(e)

        keys = ["all", "vars", "kafka_broker_custom_listeners", "broker", "port"]
        self.broker_port = self.__get_value(keys, self.settings)

        keys = ["all", "vars", "ansible_user"]
        self.user = self.__get_value(keys, self.settings)

        keys = ["all", "vars", "ansible_ssh_private_key_file"]
        self.ssh_key_file = self.__get_value(keys, self.settings)

        self.private_key = self.import_private_key(self.ssh_key_file)

    def __get_value(self, keys: List[str], values: dict):
        if len(keys) > 1:
            key = keys.pop(0)
            return self.__get_value(keys=keys, values=values.get(key, {}))
        return values.get(keys[0], None)

    @staticmethod
    def import_private_key(filename):
        """
        Attempts to import a private key from file
        Prompts for a password if needed
        Ref. https://github.com/parmentelat/apssh
        """
        sshkey = None
        basename = os.path.basename(filename)
        fullpath = os.path.expanduser(filename)
        if not os.path.exists(fullpath):
            print("No such key file {}".format(fullpath))
            return
        with open(fullpath) as file:
            data = file.read()
            try:
                sshkey = asyncssh.import_private_key(data)
            except asyncssh.KeyImportError:
                while True:
                    passphrase = getpass("Enter passphrase for key {} : ".format(basename))
                    if not passphrase:
                        print("Ignoring key {}".format(fullpath))
                        break
                    try:
                        sshkey = asyncssh.import_private_key(data, passphrase)
                        break
                    except asyncssh.KeyImportError:
                        print("Wrong passphrase")
            except Exception as e:
                import traceback
                traceback.print_exc()
            return sshkey
