#!/usr/bin/python3

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

    def __init__(self, cachefile_path):
        try:
            with open(cachefile_path, 'r') as f:
                self.hashes = json.loads(f.read())
        except IOError:
            print('Couldn\'t open Symbiflow cache file.')
            self.hashes = {}
        self.status = {}
        self.cachefile_path = cachefile_path
    
    def update(self, path: str):
        if not (os.path.isfile(path) or os.path.islink(path)):
            if self.status.get(path):
                self.status.pop(path)
            if self.hashes.get(path):
                self.hashes.pop(path)
            return
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
    
    def get_status(self, path: str):
        s = self.status.get(path)
        if not s:
            return 'untracked'
        return s

    def save(self):
        with open(self.cachefile_path, 'w') as f:
            b = json.dumps(self.hashes, indent=4)
            f.write(b)