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
import os
import requests
import json
import tarfile
from datetime import datetime


DEBUG = os.environ.get('DEBUG', 0)
RAT_STYLESHEET = os.environ['HOME'] + '/ci/mynewt-rat-json.xsl'

TRAVIS_REPO_SLUG = os.environ['TRAVIS_REPO_SLUG']
TRAVIS_PULL_REQUEST = os.environ['TRAVIS_PULL_REQUEST']
TRAVIS_COMMIT_RANGE = os.environ['TRAVIS_COMMIT_RANGE']
LICENSE_BOT_ID = "<!-- license-bot -->"
RAT_PATH = "apache-rat.jar"
TARBALL_NAME = "archive.tgz"
RAT_URL = "https://repository.apache.org/content/repositories/releases/org" \
          "/apache/rat/apache-rat/0.13/apache-rat-0.13.jar"

GH_STATUS_REPORTER_URL = "https://github-status-reporter-eb26h8raupyw.runkit.sh"
GH_COMMENTER_URL = "https://github-commenter-l845aj3j3m9f.runkit.sh"


def install_rat():
    '''
    Download RAT
    '''
    r = requests.get(RAT_URL)
    if r.status_code != 200:
        if DEBUG:
            print("RAT download failed with status {}", r.status_code)
        exit(1)
    open(RAT_PATH, 'wb').write(r.content)


def tar_files(tarball, files):
    '''
    Combine files into an archive
    '''
    # RAT works only on archives and directories
    with tarfile.open(TARBALL_NAME, 'w:gz') as tgz:
        for file in files:
            tgz.add(file)


def run_rat(rat_path, tarball):
    '''
    Execute RAT on this archive and return the results
    '''
    rat_cmd = "java -jar {} --stylesheet {} {}".format(
        rat_path, RAT_STYLESHEET, tarball)
    if DEBUG:
        print("Executing: " + rat_cmd)
    output = subprocess.check_output(rat_cmd.split()).decode()
    if DEBUG:
        print(output)
    return output


def get_commit_list(commit_range):
    '''
    Get a list of commits in this PR, from older to newer
    '''
    first, last = commit_range.split('...')
    cmd = "git log --pretty=format:%H {}..{}".format(first+'~', last)
    if DEBUG:
        print("Executing: " + cmd)
    output = subprocess.check_output(cmd.split()).decode()
    if DEBUG:
        print("output: " + output)
    # revert to get from older to newer
    return output.splitlines()[::-1]


def get_files_per_commits(commits):
    '''
    Accepts a list of commits (sha) and returns a map [added file -> sha]
    '''
    file_in_commit = {}
    n = 0
    while n < len(commits) - 1:
        old, new = commits[n], commits[n+1]
        cmd = "git log --no-commit-id --name-only --diff-filter=A {}..{}"\
            .format(old, new)
        if DEBUG:
            print("Executing: " + cmd)
        output = subprocess.check_output(cmd.split()).decode()
        if DEBUG:
            print(output)
        for file in output.splitlines():
            file_in_commit[file] = new
        n += 1
    return file_in_commit


def get_added_files(commit_range):
    '''
    Get a list of new files added in current PR
    '''
    added_files_cmd = "git diff --no-commit-id --name-only -r " \
                      "--diff-filter=A {}".format(commit_range)
    if DEBUG:
        print("Executing: " + added_files_cmd)
    output = subprocess.check_output(added_files_cmd.split()).decode()
    if DEBUG:
        print("output: " + output)
    return output.splitlines()


def send_status(owner, repo, sha, state):
    json = {
        'owner': owner,
        'repo': repo,
        'target_url': os.environ['TRAVIS_BUILD_WEB_URL'],
        'sha': sha,
        'state': state,
    }
    r = requests.post(GH_STATUS_REPORTER_URL, json=json)
    return r.status_code == 200


def new_comment(owner, repo, pr, comment_body):
    json = {
        'owner': owner,
        'repo': repo,
        'number': pr,
        'body': comment_body,
    }
    r = requests.post(GH_COMMENTER_URL, json=json)
    return r.status_code == 200


# Perform license check only on a PR
if TRAVIS_PULL_REQUEST == "false":
    print("Not a PR, exiting")
    exit(0)

added_files = get_added_files(TRAVIS_COMMIT_RANGE)

# If there are no new files, there is no need to perform license check
if not added_files:
    print("No new files in this PR, exiting")
    # TODO: need to send success status as well?
    exit(0)

if DEBUG:
    print("Installing RAT...")
install_rat()
if DEBUG:
    print("Archiving files...")
tar_files(TARBALL_NAME, added_files)
if DEBUG:
    print("Running RAT...")
output = run_rat(RAT_PATH, TARBALL_NAME)
rat = json.loads(output)

commits = get_commit_list(TRAVIS_COMMIT_RANGE)

new_files_amount = int(rat['files_amount'])
if new_files_amount == 0:
    print("No new files were added, exiting")
    exit(0)

unknown_amount = int(rat.get('unknown_amount', 0))

# FIXME: known but category-x should be flagged
if unknown_amount == 0:
    print("No unknown licenses, exiting")
    exit(0)

file_in_commit = get_files_per_commits(commits)

# Under unknown and files, look for each file and add an extra
# key->val for the sha where it was added

unknown_files = rat['unknown']
for file in unknown_files:
    file['sha'] = file_in_commit[file['name']]

new_files = rat['files']
for file in new_files:
    file['sha'] = file_in_commit[file['name']]

commit_url = "https://github.com/{}/blob".format(TRAVIS_REPO_SLUG)
unknown_files_fmt = [
   '* <a href=\"{0}/{1}/{2}\">{2}</a>'.format(
       commit_url, file_in_commit[file['name']], file['name'])
   for file in unknown_files
]

new_files = [
   '| {0: <6} | <a href=\"{1}/{2}/{3}\">{3}</a> |'.format(
       file['type'], commit_url, file_in_commit[file['name']], file['name'])
   for file in rat['files']
]

ts = rat['timestamp']
timestamp = datetime.strptime(ts[:-6], '%Y-%m-%dT%H:%M:%S')

# TODO: is it a good idea to send this formatted comment as text to
#       the backend?

owner, repo = TRAVIS_REPO_SLUG.split("/")

# Post a new comment
comment = """
{}

## RAT Report ({})

## New files with unknown licenses

{}

<details>
  <summary>Detailed analysis</summary>

## New files in this PR

| License | File |
|---------|------|
{}
</details>

""".format(LICENSE_BOT_ID, str(timestamp), "\n".join(unknown_files_fmt),
           "\n".join(new_files))

if DEBUG:
    print("Comment body: ", comment)
if not new_comment(owner, repo, TRAVIS_PULL_REQUEST, comment):
    exit(1)

# FIXME: check category-x?
sha, state = None, None
if unknown_amount == 0:
    sha, state = commits[-1], 'success'
else:
    # FIXME: use oldest commit with unknown when sending status
    for file in unknown_files:
        commit = file_in_commit[file['name']]
        sha, state = commit, 'failure'
        break

if not send_status(owner, repo, sha, state) or state == 'failure':
    exit(1)
