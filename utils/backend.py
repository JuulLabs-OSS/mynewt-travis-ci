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

import json
import os
import requests
import time
import zlib

GH_COMMENTER_URL = "https://github-commenter-l845aj3j3m9f.runkit.sh"
GH_STATUS_REPORTER_URL = \
    "https://github-status-reporter-eb26h8raupyw.runkit.sh"
MAX_RETRIES = 3
RETRY_WAIT_TIME = 30


class HttpError(Exception):
    def __init__(self, message):
        self.message = message


def do_post(url, data, headers):
    retry = 1
    while retry <= MAX_RETRIES:
        r = requests.post(url, data=data, headers=headers)

        # 413 means payload too large, it happens when we try to submit too
        # much data; in this situation there's not point in retrying
        if r.status_code == 200 or r.status_code == 413:
            break
        else:
            print("FAIL - http status: {}".format(r.status_code))
        time.sleep(RETRY_WAIT_TIME)
        retry += 1
    return r.status_code


def new_comment(owner, repo, pr, comment_body):
    headers = {
        'Content-Encoding': 'deflate',
        'Content-Type': 'application/json',
    }
    payload = zlib.compress(json.dumps({
        'owner': owner,
        'repo': repo,
        'number': pr,
        'body': comment_body,
    }).encode('utf-8'))
    status = do_post(GH_COMMENTER_URL, data=payload, headers=headers)
    if status == 413:
        raise HttpError("Payload was too large")
    elif status != 200:
        # this is for debug, better handling can be added in the future
        raise HttpError("HTTP status {}".format(status))
    return True


def send_status(owner, repo, sha, state):
    headers = {
        'Content-Encoding': 'deflate',
        'Content-Type': 'application/json',
    }
    payload = zlib.compress(json.dumps({
        'owner': owner,
        'repo': repo,
        'target_url': os.environ['TRAVIS_BUILD_WEB_URL'],
        'sha': sha,
        'state': state,
    }).encode('utf-8'))
    status = do_post(GH_STATUS_REPORTER_URL, data=payload, headers=headers)
    return status == 200
