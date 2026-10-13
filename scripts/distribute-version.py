import json
import subprocess
import time
import urllib.error
import urllib.request

TRUNK_API_URL = 'https://trunk.cocoapods.org/api/v1/pods/'


def local_spec(name):
    output = subprocess.run('pod ipc spec ' + name + '.podspec', shell=True, check=True, capture_output=True, text=True)
    return json.loads(output.stdout)


def fetch_json(url):
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.loads(response.read().decode('utf-8'))


def published_spec(name, version):
    try:
        version_info = fetch_json(TRUNK_API_URL + name + '/versions/' + version)
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return None
        raise
    return fetch_json(version_info['data_url'])


def is_already_published(name):
    """
    Returns True if the version is already on trunk with exactly the local podspec.
    It happens when `pod trunk push` reports a failure (e.g. a timeout) although the push has succeeded.
    Raises if the version is on trunk with a different podspec.
    """
    spec = local_spec(name)
    try:
        remote_spec = published_spec(name, spec['version'])
    except (urllib.error.URLError, KeyError, ValueError) as error:
        print('Unable to check trunk for ' + name + ' ' + spec['version'] + ': ' + str(error))
        return False

    if remote_spec is None:
        return False
    if remote_spec != spec:
        raise Exception(name + ' ' + spec['version'] + ' is already published on trunk with a different podspec')
    print(name + ' ' + spec['version'] + ' is already published on trunk with the same podspec, skipping')
    return True


def push_pod(name, max_attempts):
    for attempt in range(0, max_attempts):
        if is_already_published(name):
            return
        status = subprocess.run('pod repo update && pod trunk push ' + name + '.podspec --allow-warnings', shell=True)
        if status.returncode == 0:
            return
        time.sleep(60 * pow(2, attempt))
    if is_already_published(name):
        return
    raise Exception('Maximum number of attempts have been made for ' + name)


if __name__ == '__main__':
    push_pod('MapboxCoreNavigation', 5)
    time.sleep(60)
    push_pod('MapboxNavigation', 5)
