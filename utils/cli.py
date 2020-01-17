#!/usr/bin/env python3

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.


import subprocess


def run_git_command(cmd, log):
    if log:
        print("Executing: " + cmd)
    output = subprocess.check_output(cmd.split()).decode()
    if log:
        print("output: " + output)
    return output


def get_added_files(commit_range, log=False):
    '''
    Get a list of new files added in the current PR
    '''
    cmd = "git diff --no-commit-id --name-only -r --diff-filter=A {}".format(
        commit_range)
    output = run_git_command(cmd, log)
    return output.splitlines()


def get_changed_files(commit_range, log=False):
    '''
    Get a list of existing files changed in current PR
    '''
    cmd = "git diff --no-commit-id --name-only -r --diff-filter=M {}".format(
        commit_range)
    output = run_git_command(cmd, log)
    return output.splitlines()


def get_commit_list(commit_range, log=False):
    '''
    Get a list of commits in this PR, from older to newer
    '''
    first, last = commit_range.split('...')
    cmd = "git log --pretty=format:%H {}..{}".format(first+'~', last)
    output = run_git_command(cmd, log)
    # revert to get from older to newer
    return output.splitlines()[::-1]
