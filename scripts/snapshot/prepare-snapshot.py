import datetime
import os
import subprocess
import sys

import requests

from utils import get_latest_tag, get_snapshot_branch, is_snapshot_week, get_dependency_version, \
    get_dependency_version_from_tags

github_token = os.getenv("GITHUB_TOKEN")
headers = {"Authorization": f"Bearer {github_token}"}

releases = requests.get('https://api.github.com/repos/mapbox/mapbox-navigation-ios/releases', headers=headers).json()
ignore_snapshot_week = sys.argv[2]
if not is_snapshot_week(releases) and ignore_snapshot_week == 'false':
    print('Navigation SDK snapshot must not be released today (rc or GA release was released this week).')
    sys.exit(1)

tags = requests.get('https://api.github.com/repos/mapbox/mapbox-navigation-ios/tags', headers=headers).json()
latest_tag = get_latest_tag(tags)
print(f'Latest no-patch release is {latest_tag}')

snapshot_base_branch = get_snapshot_branch(latest_tag)
print(f'Snapshot base branch is {snapshot_base_branch}')
subprocess.run(f"git checkout {snapshot_base_branch}", shell=True, check=True)

snapshot_branch = f'snapshot_{str(datetime.date.today())}'
print(f'Snapshot branch is {snapshot_branch}')
subprocess.run(f"git checkout -b {snapshot_branch}", shell=True, check=True)

maps_releases = requests.get(
    'https://api.github.com/repos/mapbox/mapbox-maps-ios/releases',
    headers=headers
).json()
maps_version = get_dependency_version(maps_releases)

nav_native_tags = requests.get(
    'https://api.github.com/repos/mapbox/mapbox-navigation-native-ios/tags',
    headers=headers
).json()
nav_native_version = get_dependency_version_from_tags(nav_native_tags)

ignore_snapshot_dependencies = sys.argv[1]
if (not maps_version or not nav_native_version) and ignore_snapshot_dependencies == 'false':
    print('Cancel workflow. Not all dependencies are ready')
    sys.exit(1)

package_swift_file_name = 'Package.swift'
package_swift = open(package_swift_file_name, 'r').read()
package_swift_lines = open(package_swift_file_name, 'r').readlines()
for line in package_swift_lines:
    if '.package(name: "MapboxNavigationNative"' in line and nav_native_version:
        print(f'Bumping Nav Native to {nav_native_version}')
        package_swift = package_swift.replace(
            line,
            f'        .package(name: "MapboxNavigationNative", url: "https://github.com/mapbox/mapbox-navigation-native-ios.git", .exact("{nav_native_version}'
            + '")),\n',
        )
    if '.package(name: "MapboxMaps"' in line and maps_version:
        print(f'Bumping Maps to {maps_version}')
        package_swift = package_swift.replace(
            line,
            f'        .package(name: "MapboxMaps", url: "https://github.com/mapbox/mapbox-maps-ios.git", .exact("{maps_version}'
            + '")),\n',
        )
open(package_swift_file_name, 'w').write(package_swift)

subprocess.run('xcodebuild -resolvePackageDependencies -project MapboxNavigation-SPM.xcodeproj', shell=True, check=True)
subprocess.run('swift package resolve', shell=True, check=True)

subprocess.run(
    f'git add . && git commit -m "Bump dependencies" && git push -u origin {snapshot_branch}',
    shell=True,
    check=True,
)
