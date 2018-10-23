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

import re
import subprocess
import json
import os
from urllib import request

TRAVIS_REPO_SLUG = os.environ['TRAVIS_REPO_SLUG']
TRAVIS_PULL_REQUEST = os.environ['TRAVIS_PULL_REQUEST']
TRAVIS_COMMIT_RANGE = os.environ['TRAVIS_COMMIT_RANGE']
GITHUB_TOKEN = os.environ['GITHUB_TOKEN']
HEADERS = {'Authorization': "token " + GITHUB_TOKEN}
print(HEADERS)
LICENSE_BOT_COMMENT_ID = "<!-- license-bot -->"
RAT_PATH = "apache-rat.jar"
TARBALL_NAME = "archive.tgz"
DIFF_FILTER = "A"
RAT_URL = "https://repository.apache.org/content/repositories/snapshots/org" \
          "/apache/rat/apache-rat/0.14-SNAPSHOT/apache-rat-0.14-20181013" \
          ".213930-1.jar "

# # Perform license check only on a PR
# if TRAVIS_PULL_REQUEST == "false":
#     print("Not a PR, exiting")
#     exit(0)

# Download RAT jar file
wget_cmd = "wget {} -O {}".format(RAT_URL, RAT_PATH)
print("Executing: " + wget_cmd)
output = subprocess.check_output(wget_cmd, shell=True).decode()
print(output)

# Get a list of new files added in current PR
added_files_cmd = "git diff --no-commit-id --name-only -r " \
                  "--diff-filter={} {}".format(DIFF_FILTER,
                                               TRAVIS_COMMIT_RANGE)
print("Executing: " + added_files_cmd)
output = subprocess.check_output(added_files_cmd, shell=True).decode()
files = output.splitlines()

# If there are no new files, there is no need to perform license check
if not files:
    print("No new files in this PR, exiting")
    exit(0)

# Combine these files into an archive
# (RAT works only on archives and directories)
tar_cmd = "tar -czf {} {}".format(TARBALL_NAME, ' '.join(files))
print("Executing: " + tar_cmd)
output = subprocess.check_output(tar_cmd, shell=True).decode()
print(output)

# Execute RAT on this archive
rat_cmd = "java -jar {} {}".format(RAT_PATH, TARBALL_NAME)
print("Executing: " + rat_cmd)
output = subprocess.check_output(rat_cmd, shell=True).decode()
print(output)

# Parse RAT summary and get meaningful information
split_summary = re.split("^\*+$", output, flags=re.MULTILINE)
summary = split_summary[1]
# Find info on number of files with unknown licenses
items = re.findall("(\d+) Unknown Licenses", summary, flags=re.MULTILINE)
if not items:
    print("No info on licenses, exiting")
    exit(0)

licenses_count = int(items[0])

if licenses_count == 0:
    print("No unknown licenses, exiting")
    exit(0)

assert(len(split_summary) >= 5)
unapproved_licenses_list = split_summary[2]
file_list = split_summary[4]

# Parse file list to get file names
file_lines = file_list.splitlines()
file_lines = [line.strip() for line in file_lines]
file_lines = [line for line in file_lines if line]

# There are 4 lines of file list header that explain the annotations
assert(len(file_lines) > 4)
file_list_header = file_lines[:4]
files = file_lines[4:]
split_files = [file.split() for file in files]

# Get last commit id
commits = TRAVIS_COMMIT_RANGE.split('...')
last_commit_id = commits[1]

# Format file list to include a link to a file on github
commit_url = "https://github.com/{}/blob/{}/".format(TRAVIS_REPO_SLUG,
                                                     last_commit_id)
formatted_file_list = [
    '{0: <6} <a href=\"{2}\">{1}</a>'.format(file[0], file[1],
                                             commit_url + file[1])
    for file in split_files
]

file_list_string = '\n'.join(file_list_header + formatted_file_list)
noun_ending = 's' if licenses_count > 1 else ''
licenses_count_str = '{} Unknown License{}'.format(licenses_count,
                                                   noun_ending)

comment_format = """
{}
### {}

<details><summary>Details</summary>
<p>

<pre>
{}
------
{}
------
{}
</pre>

</p>
</details>
""".format(LICENSE_BOT_COMMENT_ID,
           licenses_count_str,
           summary, unapproved_licenses_list,
           file_list_string)

# Get list of comments on current PR
comment_url = "https://api.github.com/repos/{}/issues/{}/comments".format(
    TRAVIS_REPO_SLUG, TRAVIS_PULL_REQUEST)
req = request.Request(comment_url, headers=HEADERS)
resp = request.urlopen(req)
print("GET {}".format(comment_url))
print("Status: {} {}".format(resp.status, resp.reason))
json_comments_list = resp.read().decode()
comments_list = json.loads(json_comments_list)


# Find comments with license bot comment id in them
bot_comments = []

for comment in comments_list:
    body = comment['body']
    if LICENSE_BOT_COMMENT_ID in body:
        bot_comments.append(comment['id'])

# Delete these comments
for comment_id in bot_comments:
    comment_url = "https://api.github.com/repos/{}/issues/comments/{}".format(
        TRAVIS_REPO_SLUG, comment_id)
    req = request.Request(comment_url, headers=HEADERS)
    req.get_method = lambda: 'DELETE'

    resp = request.urlopen(req)
    print("DELETE {}".format(comment_url))
    print("Status: {} {}".format(resp.status, resp.reason))

# Post a new comment
comment_url = "https://api.github.com/repos/{}/issues/{}/comments".format(
    TRAVIS_REPO_SLUG, TRAVIS_PULL_REQUEST)
payload = {'body': comment_format}

data = str(json.dumps(payload)).encode('utf-8')
req = request.Request(comment_url, headers=HEADERS, data=data)

resp = request.urlopen(req)
print("POST {}".format(comment_url))
print("Status: {} {}".format(resp.status, resp.reason))

