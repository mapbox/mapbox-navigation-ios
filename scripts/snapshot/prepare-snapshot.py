import datetime
import os
import subprocess
import sys

import requests

from utils import get_latest_tag, get_snapshot_branch, is_snapshot_week, get_dependency_version

github_token = os.getenv("GITHUB_TOKEN")
headers = {"Authorization": "Bearer " + github_token}

releases = requests.get('https://api.github.com/repos/mapbox/mapbox-navigation-android/releases').json()
if not is_snapshot_week(releases):
    print('Navigation SDK snapshot must not be released today (rc or GA release was released this week).')
    sys.exit(1)

tags = requests.get('https://api.github.com/repos/mapbox/mapbox-navigation-android/git/refs/tags').json()
latest_tag = get_latest_tag(tags)
print('Latest no-patch release is ' + latest_tag)

snapshot_base_branch = get_snapshot_branch(latest_tag)
print('Snapshot base branch is ' + snapshot_base_branch)
subprocess.run("git checkout " + snapshot_base_branch, shell=True, check=True)

snapshot_branch = 'snapshot_' + str(datetime.date.today())
print('Snapshot branch is ' + snapshot_branch)
subprocess.run("git checkout -b " + snapshot_branch, shell=True, check=True)

maps_releases = requests.get(
    'https://api.github.com/repos/mapbox/mapbox-maps-android-internal/releases',
    headers=headers
).json()
maps_version = get_dependency_version(maps_releases)

nav_native_releases = requests.get(
    'https://api.github.com/repos/mapbox/mapbox-navigation-native/releases',
    headers=headers
).json()
nav_native_version = get_dependency_version(nav_native_releases)

# TODO update dependencies

subprocess.run('git add . && git commit -m "Bump dependencies" && git push -u origin ' + snapshot_branch, shell=True,
               check=True)
