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

package_swift_file_name = 'Package.swift'
package_swift = open(package_swift_file_name, 'r').read()
package_swift_lines = open(package_swift_file_name, 'r').readlines()
for line in package_swift_lines:
    if '.package(name: "MapboxNavigationNative"' in line and nav_native_version:
        package_swift = package_swift.replace(
            line,
            '        .package(name: "MapboxNavigationNative", url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", .exact("' + nav_native_version + '")),\n'
        )
    if '.package(name: "MapboxMaps"' in line and maps_version:
        package_swift = package_swift.replace(
            line,
            '        .package(name: "MapboxMaps", url: "https://github.com/mapbox/mapbox-maps-ios.git", .exact("' + maps_version + '")),\n'
        )
open(package_swift_file_name, 'w').write(package_swift)

subprocess.run('xcodebuild -resolvePackageDependencies -project MapboxNavigation-SPM.xcodeproj', shell=True, check=True)
subprocess.run('swift package resolve', shell=True, check=True)

subprocess.run('git add . && git commit -m "Bump dependencies" && git push -u origin ' + snapshot_branch, shell=True,
               check=True)
