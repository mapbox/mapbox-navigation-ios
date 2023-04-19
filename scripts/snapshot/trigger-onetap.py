#!/usr/bin/env python3
import datetime
import json
import os
import sys

import requests

token = os.getenv("CIRCLE_TOKEN")

if token is None:
    print("Error triggering because CIRCLE_TOKEN is not set")
    sys.exit(1)

snapshot_branch = 'snapshot_' + str(datetime.date.today())
print("Snapshot branch " + snapshot_branch)

url = "https://circleci.com/api/v2/project/github/mapbox/1tap-ios/pipeline"

headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
}

data = {
    "parameters": {
        "run_weekly_snapshot": True,
        "navigation_sdk_snapshot_branch": snapshot_branch
    }
}

response = requests.post(url, auth=(token, ""), headers=headers, json=data)

if response.status_code != 201 and response.status_code != 200:
    print("Error triggering the CircleCI: %s." % response.json()["message"])
    sys.exit(1)
else:
    response_dict = json.loads(response.text)
    print("Started run_weekly_snapshot: %s" % response_dict)
