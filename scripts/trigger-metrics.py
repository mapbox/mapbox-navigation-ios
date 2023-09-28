#!/usr/bin/env python3

import os
import json
import requests
import sys

def TriggerPipeline(token, commit, ci_ref):
    url = "https://circleci.com/api/v2/project/github/mapbox/mobile-metrics/pipeline"

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    data = {
        "parameters": {
          "run_ios_navigation_benchmark": True,
          "target_branch": commit,  
          "ci_ref": int(ci_ref),
        }
    }

    # Branch in mobile-metrics repo if you want to trigger a custom pipeline
    # data["branch"] = "test"

    response = requests.post(url, auth=(token, ""), headers=headers, json=data)

    print(response.request.url)

    if response.status_code in {201, 200}:
        response_dict = json.loads(response.text)
        print(f"Started run_ios_navigation_benchmark: {response_dict}")

    else:
        print(f'Error triggering the CircleCI: {response.json()["message"]}.')
        sys.exit(1)

def main():
    token = os.getenv("MOBILE_METRICS_TOKEN")
    commit = os.getenv("CIRCLE_SHA1")
    ci_ref = os.getenv("CIRCLE_BUILD_NUM")

    if token is None:
        print("Error triggering because MOBILE_METRICS_TOKEN is not set")
        sys.exit(1)

    TriggerPipeline(token, commit, ci_ref)

    return 0

if __name__ == "__main__":
    main()
