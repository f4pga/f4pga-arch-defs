#!/usr/bin/env python3

import re
from os import environ, path
from github import Github
from stdm import get_latest_artifact_url

def check_status():
    gh_ref = environ['GITHUB_REPOSITORY']
    gh_sha = environ['INPUT_SHA']

    MAIN_CI = "Architecture Definitions"

    print('Getting status of %s @ %s...' % (gh_ref, gh_sha))

    status = Github(
        environ['INPUT_TOKEN']
    ).get_repo(gh_ref).get_commit(sha=gh_sha).get_combined_status()

    for item in status.statuses:
        print('· %s: %s' % (item.context, item.state))

    if status.state != 'success':
        print('Status not successful. Skipping...')
        exit(1)

    if not any([item.context == MAIN_CI for item in status.statuses]):
        print('Main CI has not completed. Skipping...')
        exit(1)

    artifacts, _ = get_latest_artifact_url()

    PACKAGE_RE = re.compile("symbiflow-arch-defs-([a-zA-Z0-9_-]+)-([a-z0-9])")

    for artifact in artifacts:
        name = artifact["name"].split(".")[0]
        url = artifact["url"]

        m = PACKAGE_RE.match(name)
        assert m, "Package name not recognized! {}".format(name)

        package_name = m.group(1)

        if package_name == "install":
            file_name = "symbiflow-toolchain-latest"
        elif package_name == "benchmarks":
            file_name = "symbiflow-benchmarks-latest"
        else:
            file_name = "symbiflow-{}-latest".format(package_name)

        with open(path.join("install", file_name), "w") as f:
            f.write(url)


try:
    check_status()
except Exception:
    print('::set-output name=skip::true')
