import datetime


def is_rc_or_ga(release_name):
    return 'rc' in release_name or release_name.endswith('.0')


def is_patch(release_name):
    return not ('alpha' in release_name or 'beta' in release_name or 'rc' in release_name or release_name.endswith(
        '.0'))


def is_current_week(release_created_date):
    created_date = datetime.date.fromisoformat(release_created_date.partition('T')[0])
    today = datetime.date.today()
    return created_date + datetime.timedelta(days=5) > today


def is_snapshot_week(releases):
    for release in releases:
        if is_current_week(release['created_at']) and is_rc_or_ga(release['name']):
            return False
    return True


def get_dependency_version(releases):
    for release in releases:
        if is_current_week(release['created_at']) and not is_patch(
                release['name']) and not ('private' in release['name']):
            return release['name'].replace('v', '')
    return None


def get_latest_tag(tags):
    for tag in reversed(tags):
        tag_name = tag['ref'].replace('refs/tags/', '')
        if tag_name.startswith('v') and tag_name.partition('-')[0].endswith('.0'):
            return tag_name


# latest tag alpha - future version alpha or beta - main branch
# latest tag beta - future version beta or rc - main branch
# latest tag rc - future version rc or stable - release branch
# latest tag stable - future version alpha or beta - main branch
def get_snapshot_branch(latest_tag):
    if 'beta' in latest_tag or 'alpha' in latest_tag \
            or ('rc' not in latest_tag and 'beta' not in latest_tag and 'alpha' not in latest_tag):
        return 'main'
    else:
        return 'release-' + latest_tag.partition('.0')[0]
