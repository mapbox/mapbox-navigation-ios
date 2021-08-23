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

    if response.status_code != 201 and response.status_code != 200:
        print("Error triggering the CircleCI: %s." % response.json()["message"])
        sys.exit(1)
    else:
        response_dict = json.loads(response.text)
        print("Started run_ios_navigation_benchmark: %s" % response_dict)

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
