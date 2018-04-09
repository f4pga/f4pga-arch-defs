#!/usr/bin/env python3
import sys

collect_ignore = [
    "icebox-rr_graph-import.py", # ImportError: No Module named 'icebox'
    "vlog/vlog_to_model.py",  # Can't be imported - Issue #61
    "vlog/vlog_to_pbtype.py", # Can't be imported - Issue #61
]
