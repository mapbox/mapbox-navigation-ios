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

snapshot_branch = f'snapshot_{str(datetime.date.today())}'
print(f"Snapshot branch {snapshot_branch}")

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

if response.status_code in {201, 200}:
    response_dict = json.loads(response.text)
    print(f"Started run_weekly_snapshot: {response_dict}")

else:
    print(f'Error triggering the CircleCI: {response.json()["message"]}.')
    sys.exit(1)
