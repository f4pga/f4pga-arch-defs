#!/usr/bin/env python3

from os import environ
from github import Github

gh_ref = environ['GITHUB_REPOSITORY']
gh_sha = environ['INPUT_SHA']

print('Getting status of %s @ %s...' % (gh_ref, gh_sha))

status = Github(environ['INPUT_TOKEN']
                ).get_repo(gh_ref).get_commit(sha=gh_sha).get_combined_status()

for item in status.statuses:
    print('· %s: %s' % (item.context, item.state))

if status.state != 'success':
    print('Status not successful. Skipping...')
    exit(1)
