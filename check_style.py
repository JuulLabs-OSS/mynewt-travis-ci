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

import os
import os.path as path
import re
import requests
import subprocess


TRAVIS_REPO_SLUG = os.environ['TRAVIS_REPO_SLUG']
TRAVIS_COMMIT_RANGE = os.environ['TRAVIS_COMMIT_RANGE']
TRAVIS_PULL_REQUEST = os.environ['TRAVIS_PULL_REQUEST']
STYLE_BOT_ID = "<!-- style-bot -->"
DEBUG = int(os.environ.get('DEBUG', 0))
SOURCE_EXTS = ['.c', '.h']
GH_STATUS_REPORTER_URL = "https://github-status-reporter-eb26h8raupyw.runkit.sh"
GH_COMMENTER_URL = "https://github-commenter-l845aj3j3m9f.runkit.sh"

GH_COMMENT_TITLE = """
{}

## Style check summary"""
GH_COMMENT_EMPTY = """
#### No suggestions at this time!
"""
GH_COMMENT_DIFF = """
#### {}
<details>

```diff
{}
```

</details>"""
IGNORED_DIRS_CFG = ".style_ignored_dirs"
IGNORED_DIRS = []


def load_ignored_dirs():
    regex = re.compile("^\s*#")
    with open(IGNORED_DIRS_CFG) as f:
        lines = f.readlines()
        for line in lines:
            line = line.strip()
            if line != "" and regex.match(line) is not None:
                IGNORED_DIRS.append(line)


def get_changed_files(commit_range):
    '''
    Get a list of new files added in current PR
    '''
    added_files_cmd = "git diff --no-commit-id --name-only -r {}".format(commit_range)
    if DEBUG:
        print("Executing: " + added_files_cmd)
    output = subprocess.check_output(added_files_cmd.split()).decode()
    if DEBUG:
        print("output: " + output)
    return output.splitlines()


def is_package(p):
    return path.exists(path.join(p, "pkg.yml"))


def in_package(f):
    """
    Check that the file is directly inside a package, as in:
    package_root
           |- pkg.yml
           |- src/<file>
           |- include/<file>
           |- include/<some-other-dir>/<file>
    """
    _dir = path.dirname(f)
    base = path.basename(_dir)
    if base == "src" or base == "include":
        return is_package(path.dirname(_dir))
    _dir = path.dirname(_dir)
    base = path.basename(_dir)
    if base == "include":
        return is_package(path.dirname(_dir))
    return False


def is_on_ignored_dir(f):
    for d in IGNORED_DIRS:
        if f.startswith(d):
            return True
    return False


def is_valid(f):
    if not any([f.endswith(ext) for ext in SOURCE_EXTS]):
        return False
    if is_on_ignored_dir(f):
        return False
    return in_package(f)


def get_style_diff(f):
    uncrustify_cmd = "uncrustify -c uncrustify.cfg {}".format(f)
    if DEBUG:
        print("Executing: " + uncrustify_cmd)
    output = subprocess.check_output(uncrustify_cmd.split()).decode()
    if DEBUG:
        print("output: " + output)
    # TODO: check return code and that file was created...
    diff_cmd = "diff -u {} {}".format(f, "{}.uncrustify".format(f))
    output = ""
    if DEBUG:
        print("Executing: " + diff_cmd)
    try:
        subprocess.check_output(diff_cmd.split())
    except subprocess.CalledProcessError as e:
        # files differ
        if e.returncode == 1:
            output = e.output.decode('utf-8')
        else:
            raise Exception("Error generating diff for: {}".format(f))
        # remove initial diff lines with file names
        lines = output.splitlines()[2:]
        output = "\n".join(lines)
    if DEBUG:
        print("output: " + output)
    return output


def new_comment(owner, repo, pr, comment_body):
    json = {
        'owner': owner,
        'repo': repo,
        'number': pr,
        'body': comment_body,
    }
    r = requests.post(GH_COMMENTER_URL, json=json)
    return r.status_code == 200


def main():
    if TRAVIS_PULL_REQUEST == "false":
        print("Not a PR, exiting")
        exit(0)

    load_ignored_dirs()

    changed_files = get_changed_files(TRAVIS_COMMIT_RANGE)
    print(changed_files)

    source_files = [f for f in changed_files if is_valid(f)]
    file_outputs = []
    for source in source_files:
        output = get_style_diff(source)
        if output != "":
            file_outputs.append((source, output))

    comments = []
    comments.append(GH_COMMENT_TITLE.format(STYLE_BOT_ID))
    if len(file_outputs) == 0:
        comments.append(GH_COMMENT_EMPTY)
    else:
        for (file, output) in file_outputs:
            comments.append(GH_COMMENT_DIFF.format(file, output))
    comment = "\n".join(comments)

    if DEBUG:
        print("Comment body: ", comment)
    owner, repo = TRAVIS_REPO_SLUG.split("/")
    if not new_comment(owner, repo, TRAVIS_PULL_REQUEST, comment):
        exit(1)


if __name__ == '__main__':
    main()
