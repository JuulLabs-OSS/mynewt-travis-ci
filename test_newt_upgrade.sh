#!/bin/bash

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

# Ensure newt checks out the expected commit for each repo.

printf '*** Testing `newt upgrade`\n'

status=0

check_status() {
    local rc=$?

    # Remember failure.
    if [ "$rc" -ne 0 ]
    then
        echo "rc=$rc"
        status="$rc"
    fi

    return $rc
}

checkout_master() {
    local projdir=$1

    local dir
    for dir in "$projdir"/repos/*
    do
        git -C "$dir" checkout -q origin/master
        check_status || return
    done
}

upgrade_success() {
    local dir=$1

    (
        cd "$dir"
        check_status || return

        newt upgrade
        check_status || return

        newt info | grep mynewt-dummy | diff -w expected.txt -
        check_status || return
    )
}

upgrade_fail() {
    local dir=$1

    (
        cd "$dir"
        check_status || return

        local output
        output=$(newt upgrade 2>&1 1>&-)
        if [ $? -eq 0 ]
        then
            printf 'upgrade succeeded; expected failure\n'
            return 1
        fi

        # Diff the tail of the output to ensure no unexpected lines follow.
        local num_lines=$(wc -l expected.txt)
        diff -w <(tail -n $num_lines) <(echo "$output")
        check_status || return
    )
}

for dir in newt_upgrade/success/*
do
    printf "testing \`newt upgrade\` on project \"$dir\" (expect success)\n"

    # Test initial install.
    upgrade_success "$dir"
    check_status || continue

    # Test upgrade.
    checkout_master "$dir"
    check_status || continue

    upgrade_success "$dir"
    check_status || continue
done

for dir in newt_upgrade/fail/*
do
    printf "testing \`newt upgrade\` on project \"$dir\" (expect failure)\n"

    upgrade_fail "$dir"
    check_status || continue
done

exit "$status"
