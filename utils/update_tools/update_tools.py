#!/usr/bin/env python3

import os
import argparse
import git

EDITOR = os.getenv('EDITOR', 'vim')


def solve_conflicts(g, branch=None):
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

    parser.add_argument('repo_url', help="Url of the repository to update.")

    parser.add_argument(
        'repo_name', help="Name given to the repository directory."
    )

    args = parser.parse_args()
    repo_name = args.repo_name
    repo_url = args.repo_url

    try:
        git.repo.base.Repo.clone_from(repo_url, repo_name)
    except Exception:
        print("Warning: Repo already cloned.")

    repo = git.Repo("{}/.git".format(repo_name))
    g = git.cmd.Git(repo_name)

    all_branches = g.branch("-r")

    # Remove spaces and special characters from branches
    for string in [' ', '*', 'origin/']:
        all_branches = all_branches.replace(string, '')

    # Do not consider HEAD branch
    all_branches = all_branches.split('\n')[1:]

    branches = []
    for branch in all_branches:
        if branch.startswith("wip/"):
            print("Updating branch: ", branch)
            rebase_branch(g, branch)
            branches.append(branch)

    try:
        g.checkout(['-b', 'master+wip-next'])
    except Exception:
        print("Branch master+wip-next already exists!")
    g.reset(['--hard', 'origin/master'])

    os.system(
        "cd {} && git merge {} && cd -".format(repo_name, ' '.join(branches))
    )

    if g.diff():
        solve_conflicts(g)

    repo.index.commit(
        """Octopus merge

This is an Octopus Merge commit of the following branches:
{}
            """.format('\n'.join(branches))
    )

    g.push(['--force', 'origin', 'master+wip-next'])
    print("Octopus merge ready to be tested!")


if __name__ == "__main__":
    main()
