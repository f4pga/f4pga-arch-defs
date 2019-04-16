#!/usr/bin/env python3

import argparse
import csv
import hashlib
import json
import os.path
import pprint
import textwrap
import urllib.request

import flipflop


def download_goog_sheet(gid, outfile):
    url = "https://docs.google.com/spreadsheets/d/e/2PACX-1vRxRhk3fCxPMh0yUSXorkA_FCdqDguW0JNKV5-Q64Xyi_Q9bI9mCc_Vfaw6DeBHFnd9MKsRZy2SrCgP/pub?output=csv&gid={}&single=true".format(gid)

    dirname = os.path.dirname(outfile)
    if not os.path.exists(dirname):
        os.makedirs(dirname)

    data = urllib.request.urlopen(url).read().decode('utf-8')
    with open(outfile, 'w') as f:
        f.write(data)


def update_csv():
    for name, gid in flipflop.SHEETS.items():
        outfile = flipflop.csv_file(name)
        print("Downloading {:5s} into {}".format(name, outfile))
        download_goog_sheet(gid, outfile)


def main():
    update_csv()


if __name__ == "__main__":
    main()
