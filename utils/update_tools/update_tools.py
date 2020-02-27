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
import subprocess
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


def merge_branches(location, branches):
    """
    Merge one or more branches into the current branch.
    The branches have to be in string format

    Returns:
        - True: if merge was successful
        - False: if merge was unsuccessful
    """

    try:
        subprocess.check_call(
            "cd {} && git merge {} && cd -".format(location, branches),
            shell=True
        )
    except subprocess.CalledProcessError:
        print("Something went wrong during the merge!")
        return False
        pass

    return True


def rebase_continue_rec(g):
    try:
        g.rebase("--continue")
    except Exception:
        solve_conflicts(g)
        rebase_continue_rec(g)


def rebase_branch(g, branch):
    g.checkout(branch)
    try:
        g.rebase('master')
    except Exception:
        solve_conflicts(g, branch)
        rebase_continue_rec(g)


def revert_to_master(g, repo, remote):
    """ Preserving history, revert {remote}/master+wip to {remote}/master
    """
    g.reset(['--hard', '{}/master'.format(remote)])
    g.reset(['{}/master+wip'.format(remote)])
    g.add(['.'])
    g.commit(
        [
            '-sm', 'Revert master+wip to master ({})'.format(
                repo.commit('{}/master'.format(remote)).hexsha
            )
        ]
    )

    # This removes files that got left behind during the reset's above.
    # Without this, some stray files may cause git to error when attempting
    # the merge.
    g.clean(['-fx'])
    g.merge(['master'])


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--location',
        required=True,
        help="Absolute path to the git repository."
    )

    parser.add_argument('--url', help="Optional url of the repository.")

    parser.add_argument(
        '--remote', help="Optional remote repository to use instead of origin"
    )

    parser.add_argument(
        '--branch_name',
        required=True,
        help="Name of branch to push to github with new master+wip"
    )

    args = parser.parse_args()
    location = args.location
    url = args.url
    remote = args.remote

    assert os.path.exists(
        location
    ) or url, "The git repository does not exists, and no URL has been provided"

    if not os.path.exists(location):
        git.repo.base.Repo.clone_from(url, location)

    if not remote:
        remote = 'origin'

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
        if "HEAD" not in branch and "{}/".format(remote) in branch:
            origin_branches.append(branch.replace('{}/'.format(remote), ''))

    # Create new integration point on master.
    g.checkout(['master'])
    g.commit(['--allow-empty', '-sm', 'New integration point for master+wip.'])

    branches = []
    for branch in origin_branches:
        if branch.startswith("wip/"):
            print("Updating branch: ", branch)
            rebase_branch(g, branch)
            branches.append(branch)

    assert args.branch_name not in ['master+wip', 'master'], \
        ('Branch name "{}" should not be "master+wip" nor "master"')

    try:
        g.checkout(['-b', args.branch_name])
    except Exception:
        print("Branch {} already exists!".format(args.branch_name))
        g.checkout(args.branch_name)

    revert_to_master(g, repo, remote)

    branches_string = ' '.join(branches)
    result = merge_branches(location, branches_string)

    if not result:
        revert_to_master(g, repo, remote)
        for branch in branches:
            result = merge_branches(location, branch)

            if not result:
                solve_conflicts(g, branch)

                g.commit(
                    "-sm \"Sequential merge of conflicting branch {}\"".
                    format(branch)
                )
    else:
        repo.index.commit(
            """Octopus merge

This is an Octopus Merge commit of the following branches:

{branches}

Signed-off-by: {user} <{email}>
""".format(
                branches='\n'.join(branches),
                user=repo.config_reader().get_value('user', 'name'),
                email=repo.config_reader().get_value('user', 'email')
            ),
        )

    # Pushing to remote
    print(
        "Push on remote {} {} branch? [Y/n]".format(remote, args.branch_name)
    )
    if yes_or_no_input():
        g.push(['{}'.format(remote), args.branch_name])
    else:
        print("Warning: did not push to {}".format(remote))

    print("Octopus merge ready to be tested!")


if __name__ == "__main__":
    main()
