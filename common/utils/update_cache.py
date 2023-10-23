""" Tool for implementing a simple cache

Tool returns 0 if cache is valid, returns non-zero is cache is invalid.

check_cache.py <args> || (<build_cache> && update_cache.py <args>)
"""
import argparse
import hashlib


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('cache_input')
    parser.add_argument('cache_value')

    args = parser.parse_args()

    with open(args.cache_input, 'rb') as f:
        m = hashlib.sha1()
        m.update(f.read())
        h = m.hexdigest()

    with open(args.cache_value, 'w') as f:
        print(h, file=f)


if __name__ == "__main__":
    main()
