#!/usr/bin/env python3
"""
Semi-automated python script to maintain WIP master branches forked
from third-party tools.

The user needs to provide a location of the git project that needs to be
updated. In case the directory does not exist, the user needs to provide
the URL of the git repository.

This script takes into account all the branches marked under the `wip/`
namespace, rebases them on top of the master branch, and performs an
Octopus Merge on the master+wip-next branch.

In case of conflicts between different branches, the user is given access
to the shell, from which he can solve all the issues.
Once all the conflicting files are fixed, the script automatically performs
the last steps of the conflict solving.

The user can also choose to let the script to push force on the master+wip-next
branch.
"""

import os
import argparse
import git


def yes_or_no_input():
    # raw_input returns the empty string for "enter"
    yes = {'yes', 'y', 'ye', ''}
    no = {'no', 'n'}

    choice = input().lower()
    if choice in yes:
        return True
    elif choice in no:
        return False


def solve_conflicts(g, branch=""):
    need_fix = set(g.diff("--name-only").split("\n"))

    help_msg = """
CONFLICT {}
Entered in conflict-fixing mode, a shell will be spawned.

Solve conflicts in the following files:
""".format(branch)

    for f in need_fix:
        help_msg += "{}/{}\n".format(g.working_dir, f)

    help_msg += """
After having fixed all the conflicts exit the spawned shell the following command

$ exit

"""

    print(help_msg)

    os.system('/bin/bash')
    g.add(".")


def rebase_continue_rec(g):
    try:
        g.rebase("--continue")
    except Exception:
        solve_conflicts(g)
        rebase_continue_rec(g)


def rebase_branch(g, branch):
    g.checkout(branch)
    try:
        g.rebase('origin/master')
    except Exception:
        solve_conflicts(g, branch)
        rebase_continue_rec(g)


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--location', required=True, help="Location of the repository."
    )

    parser.add_argument(
        '--url', required=False, help="Optional url of the repository."
    )

    args = parser.parse_args()
    location = args.location
    url = args.url

    assert os.path.exists(
        location
    ) or url, "The git repository does not exists, and no URL has been provided"

    if not os.path.exists(location):
        git.repo.base.Repo.clone_from(url, location)

    repo = git.Repo("{}/.git".format(location))
    g = git.cmd.Git(location)

    g.fetch("-p")
    all_branches = g.branch("-r")

    # Remove spaces and special characters from branches
    for string in [' ', '*']:
        all_branches = all_branches.replace(string, '')

    all_branches = all_branches.split('\n')

    # Consider only branches in `origin`
    origin_branches = []
    for branch in all_branches:
        if "HEAD" not in branch and "origin/" in branch:
            origin_branches.append(branch.replace('origin/', ''))

    branches = []
    for branch in origin_branches:
        if branch.startswith("wip/"):
            print("Updating branch: ", branch)
            rebase_branch(g, branch)
            branches.append(branch)

    try:
        g.checkout(['-b', 'master+wip-next'])
    except Exception:
        print("Branch master+wip-next already exists!")
        g.checkout('master+wip-next')

    g.reset(['--hard', 'origin/master'])

    os.system(
        "cd {} && git merge {} && cd -".format(location, ' '.join(branches))
    )

    if g.diff():
        solve_conflicts(g)

    repo.index.commit(
        """Octopus merge

This is an Octopus Merge commit of the following branches:
{}
            """.format('\n'.join(branches))
    )

    # Pushing to remote
    print("Push force on remote master+wip-next branch? [Y/n]")
    if yes_or_no_input():
        g.push(['--force', 'origin', 'master+wip-next'])
    else:
        print("Warning: did not push to remote")

    print("Octopus merge ready to be tested!")


if __name__ == "__main__":
    main()
