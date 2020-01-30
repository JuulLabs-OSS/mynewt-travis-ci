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

from utils import cli, backend
import difflib
import os
import os.path as path
import re
import requests
import subprocess


TRAVIS_REPO_SLUG = os.environ['TRAVIS_REPO_SLUG']
TRAVIS_COMMIT_RANGE = os.environ['TRAVIS_COMMIT_RANGE']
TRAVIS_PULL_REQUEST = os.environ['TRAVIS_PULL_REQUEST']
STYLE_BOT_ID = "<!-- style-bot -->"
DEBUG = bool(os.environ.get('DEBUG', False))
SOURCE_EXTS = ['.c', '.h']

GH_COMMENT_TITLE = """
{}

## Style check summary"""
GH_COMMENT_EMPTY = """
#### No suggestions at this time!
"""
GH_CODING_STYLE_URL = """
### Our coding style is [here!](https://github.com/apache/mynewt-core/blob/master/CODING_STANDARDS.md)
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


def diff_files(old_name, new_name):
    with open(old_name) as f:
        new = f.readlines()
    with open(new_name) as f:
        old = f.readlines()
    lines = [line.strip("\n") for line in difflib.unified_diff(new, old)]
    return lines[2:]


def get_added_style_diff(f):
    '''
    Run uncrustify for files that are new, can run on whole file.
    '''
    uncrustify_cmd = "uncrustify -c uncrustify.cfg {}".format(f)
    if DEBUG:
        print("Executing: " + uncrustify_cmd)
    output = subprocess.check_output(uncrustify_cmd.split()).decode()
    if DEBUG:
        print("output: " + output)
    return "\n".join(diff_files(f, "{}.uncrustify".format(f)))


def get_changed_style_diff(f, commit_range):
    '''
    Run uncrustify for files that were changed in this PR.

    First get all changes from the original file to the committed file,
    then find the ranges where changes happened; later exclude from the
    styled file any suggestions that apply to lines that were not
    touched by the commits in the PR.
    '''

    # First get differences between new and old version, to later isolate
    # only the style checks in this range.

    first, last = commit_range.split('...')
    diff_cmd = "git diff -u {}..{} {}".format(first, last, f)
    if DEBUG:
        print("Executing: " + diff_cmd)
    output = subprocess.check_output(diff_cmd.split()).decode()
    if DEBUG:
        print("output: " + output)

    # In the unified diff format each segment is preceeded by a header:
    # "@@ -[line-number],[number-of-lines] +[line-number],[number-of-lines] @@"

    DIFF_RANGE = '^@@ -[0-9]+,[0-9]+ \+([0-9]+),[0-9]+ @@'

    # TODO: if it can be assumed that a diff range always begins and ends
    #       with 3 non-changed lines, it would be better to just parse the
    #       number of lines in the regex and subtract 6!

    range_re = re.compile(DIFF_RANGE)
    ranges = []
    n = 0
    first_p = last_p = 0
    for line in output.splitlines()[4:]:
        m = range_re.match(line)
        if m:
            n = int(m.group(1))
            if first_p != 0 and last_p != 0:
                ranges.append((first_p, last_p - first_p + 1))
            first_p = last_p = 0
        else:
            if n == 0:
                # Check that we are starting in the right place.
                raise Exception("Invalid diff file")
            elif line.startswith("+"):
                if first_p == 0:
                    first_p = n
                    last_p = n
                else:
                    last_p = n
                n += 1
            elif not line.startswith("-"):
                n += 1

    # Add last range
    if first_p != 0 and last_p != 0:
        ranges.append((first_p, last_p - first_p + 1))

    uncrustify_cmd = "uncrustify -c uncrustify.cfg {}".format(f)
    if DEBUG:
        print("Executing: " + uncrustify_cmd)
    output = subprocess.check_output(uncrustify_cmd.split()).decode()
    if DEBUG:
        print("output: " + output)

    # TODO: check return code and that file was created...
    lines = diff_files(f, "{}.uncrustify".format(f))

    # FIXME: if there were no changes, output here will be == "", and
    #        the lines below will fail. But could this ever happen?

    # Use range of file before uncrustify was run, to check if the style
    # suggestion only exists in the new file

    DIFF_RANGE = '^@@ -([0-9]+),([0-9]+) \+[0-9]+,[0-9]+ @@'

    range_re = re.compile(DIFF_RANGE)

    if len(lines) > 0:
        valid_lines = []
        valid = False
        for line in lines:
            m = range_re.match(line)
            if m:
                valid = False
                # use the original file's range data
                ln, n = int(m.group(1)), int(m.group(2))
                for r in ranges:
                    # does the current chunk intesect with some range?
                    if ln + n > r[0] and ln < (r[0] + r[1]):
                        valid = True
                        break
            if valid:
                valid_lines.append(line)
        output = "\n".join(valid_lines)
    else:
        output = "\n".join(lines)

    return output


def main():
    if TRAVIS_PULL_REQUEST == "false":
        print("Not a PR, exiting")
        exit(0)

    load_ignored_dirs()

    added_files = cli.get_added_files(TRAVIS_COMMIT_RANGE, DEBUG)
    if DEBUG:
        print(added_files)

    changed_files = cli.get_changed_files(TRAVIS_COMMIT_RANGE, DEBUG)
    if DEBUG:
        print(changed_files)

    file_outputs = []

    source_files = [f for f in added_files if is_valid(f)]
    for source in source_files:
        output = get_added_style_diff(source)
        if output != "":
            file_outputs.append((source, output))

    source_files = [f for f in changed_files if is_valid(f)]
    for source in source_files:
        output = get_changed_style_diff(source, TRAVIS_COMMIT_RANGE)
        if output != "":
            file_outputs.append((source, output))

    comments = []
    comments.append(GH_COMMENT_TITLE.format(STYLE_BOT_ID))
    if len(file_outputs) == 0:
        comments.append(GH_COMMENT_EMPTY)
    else:
        comments.append(GH_CODING_STYLE_URL)
        for (file, output) in file_outputs:
            comments.append(GH_COMMENT_DIFF.format(file, output))
    comment = "\n".join(comments)

    if DEBUG:
        print("Comment body: ", comment)
    owner, repo = TRAVIS_REPO_SLUG.split("/")
    if not backend.new_comment(owner, repo, TRAVIS_PULL_REQUEST, comment):
        exit(1)


if __name__ == '__main__':
    main()
