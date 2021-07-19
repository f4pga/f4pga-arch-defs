#!/usr/bin/python3

import hashlib
import json

def get_file_hash(path: str):
    with open(path) as f:
        b = f.read()
        return hashlib.sha256(b).hexdigest()

class SymbiCache:
    hashes: 'dict[str, str]'
    status: 'dict[str, str]'
    cachefile_path: str

    def __init__(self, chachefile_path):
        with open(chachefile_path, 'r') as f:
            self.hashes = json.loads(f)
        self.status = {}
        self.new_files = {}
        self.cachefile_path = chachefile_path
    
    def file_changed(self, path: str):
        cached_status = self.status.get(path)
        if cached_status:
            return cached_status == 'changed'
        hash = get_file_hash(path)
        last_hash = self.hashes.get(path)
        if hash != last_hash:
            self.status[path] = 'changed'
            self.hashes[path] = hash
            return True
        else:
            self.status[path] = 'same'
            return False

    def save(self):
        with open(self.cachefile_path, 'w') as f:
            b = json.dumps(self.hashes)
            f.write(b)