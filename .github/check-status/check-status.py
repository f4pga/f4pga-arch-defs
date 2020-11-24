#!/usr/bin/env python3

from os import environ, path
from github import Github
from stdm import get_latest_artifact_url

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

artifacts, _ = get_latest_artifact_url()

for artifact in artifacts:
    name = artifact["name"].split(".")[0]
    url = artifact["url"]

    if name.startswith("symbiflow-arch-defs-install"):
        file_name = "symbiflow-toolchain-latest"
    elif name.startswith("symbiflow-arch-defs-benchmarks"):
        file_name = "symbiflow-benchmarks-latest"
    else:
        file_name = name + "-latest"

    with open(path.join("install", file_name), "w") as f:
        f.write(url)
