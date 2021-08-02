#!/usr/bin/python3

# This is "SymbiCache". It's used to track changes among dependencies and keep
# the status of the files on a persistent storage.
# Files which are tracked get their checksums calculated and stored in a file.
# If file's checksum differs from the one saved in a file, that means, the file
# has changed.

import os
import zlib
import json

def get_file_hash(path: str):
    with open(path, 'rb') as f:
        b = f.read()
        return str(zlib.adler32(b))

class SymbiCache:
    hashes: 'dict[str, str]'
    status: 'dict[str, str]'
    cachefile_path: str

    # `chachefile_path` - path to a file used for persistent storage of
    # checksums.
    def __init__(self, cachefile_path):
        try:
            with open(cachefile_path, 'r') as f:
                self.hashes = json.loads(f.read())
        except IOError:
            print('Couldn\'t open Symbiflow cache file.')
            self.hashes = {}
        self.status = {}
        self.cachefile_path = cachefile_path
    
    # Add/remove a file to.from the tracked files, update checksum
    # if necessary and calculate status.
    def update(self, path: str):
        isdir = os.path.isdir(path)
        if not (os.path.isfile(path) or os.path.islink(path) or isdir):
            if self.status.get(path):
                self.status.pop(path)
            if self.hashes.get(path):
                self.hashes.pop(path)
            return True
        hash = 0 # Directories always get '0' hash.
        if not isdir:
            hash = get_file_hash(path)
        last_hash = self.hashes.get(path)
        if hash != last_hash:
            print(f'{path} changed')
            self.status[path] = 'changed'
            self.hashes[path] = hash
            return True
        else:
            self.status[path] = 'same'
            return False
    
    # Get status for a file with a given path.
    # returns 'untracked' if the file is not tracked or hasn't been
    # treated with `update` procedure before calling `get_status`.
    def get_status(self, path: str):
        s = self.status.get(path)
        if not s:
            return 'untracked'
        return s

    # Saves cache's state to the persistent storage
    def save(self):
        with open(self.cachefile_path, 'w') as f:
            b = json.dumps(self.hashes, indent=4)
            f.write(b)