import json
import os

import requests

from utils import is_snapshot_week, get_dependency_version, get_latest_tag, get_snapshot_branch, \
    get_dependency_version_from_tags

github_token = os.getenv("GITHUB_TOKEN")
headers = {"Authorization": f"Bearer {github_token}"}


def build_message():
    message = '@navigation-ios '

    releases_url = "https://api.github.com/repos/mapbox/mapbox-navigation-ios/releases"
    releases = requests.get(releases_url, headers=headers).json()
    if is_snapshot_week(releases):
        message += 'Navigation SDK snapshot must be released today (rc or GA release was not released this week).\n'
    else:
        message += 'Navigation SDK snapshot must not be released today (rc or GA release was released this week).\n'
        return message

    maps_releases = requests.get(
        'https://api.github.com/repos/mapbox/mapbox-maps-ios/releases',
        headers=headers
    ).json()
    if maps_version := get_dependency_version(maps_releases):
        message += f':white_check_mark: Maps {maps_version}' + ' is ready.\n'
    else:
        message += ':siren: Expected Maps release was not released.\n'

    nav_native_tags = requests.get(
        'https://api.github.com/repos/mapbox/mapbox-navigation-native-ios/tags',
        headers=headers
    ).json()
    if nav_native_version := get_dependency_version_from_tags(nav_native_tags):
        message += (
            f':white_check_mark: Nav Native {nav_native_version}'
            + ' is ready.\n'
        )
    else:
        message += ':siren: Expected Nav Native release was not released.\n'

    tags = requests.get('https://api.github.com/repos/mapbox/mapbox-navigation-ios/tags', headers=headers).json()
    latest_tag = get_latest_tag(tags)
    snapshot_branch = get_snapshot_branch(latest_tag)

    message += f'Snapshot branch is *{snapshot_branch}' + '*.\n'

    message += '*Release time is today night.*\n'

    return message


def send_message(message):
    payload = {'text': message, 'link_names': 1}
    slack_url = os.getenv("SLACK_WEBHOOK")
    requests.post(slack_url, data=json.dumps(payload))


message = build_message()
send_message(message)
