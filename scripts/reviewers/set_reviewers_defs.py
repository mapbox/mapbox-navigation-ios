import datetime

import requests


def parse_users(teams, author):
    users = []
    for team in teams:
        team_name = team['name']
        for user in team['users']:
            if user == author:
                continue
            users.append({
                'login': user,
                'team': team_name,
                'reviews': 0,
                'done_reviews': 0
            })
    return users


def get_current_reviews(users, pulls):
    for pull in pulls:
        reviewers = pull['requested_reviewers']
        for reviewer in reviewers:
            for user in users:
                if user['login'] == reviewer['login']:
                    user['reviews'] += 1
    return users


def get_fresh_pulls(all_pulls, today):
    fresh_pulls = []
    for pull in all_pulls:
        if pull['closed_at'] is None:
            created_date = datetime.date.fromisoformat(pull['created_at'].partition('T')[0])
            if created_date + datetime.timedelta(days=7) < today:
                continue
        else:
            closed_date = datetime.date.fromisoformat(pull['closed_at'].partition('T')[0])
            if closed_date + datetime.timedelta(days=7) < today:
                continue
        fresh_pulls.append(pull)
    return fresh_pulls


def get_done_reviews(prs_url, headers, users, fresh_pulls):
    for pull in fresh_pulls:
        pull_number = pull['number']
        reviews_url = prs_url + "/" + str(pull_number) + "/reviews"
        reviews = requests.get(reviews_url, headers=headers).json()
        for review in reviews:
            if review['state'] == 'APPROVED':
                for user in users:
                    if user['login'] == review['user']['login']:
                        user['done_reviews'] += 1
    return users


def sort_users(users):
    return sorted(users, key=lambda x: (x['reviews'], x['done_reviews']))


def get_changed_modules(pr_files):
    return set(map(lambda file: get_module(file['filename']), pr_files))


def get_module(filename):
    if filename.startswith('Sources/MapboxCoreNavigation'):
        return 'Sources/MapboxCoreNavigation'
    elif filename.startswith('Sources/MapboxNavigation'):
        return 'Sources/MapboxNavigation'
    else:
        return filename.split('/')[0]


def get_owners_of_changes(owners, changed_modules):
    found_owners = set()
    for changed_module in changed_modules:
        for owner in owners:
            if changed_module in owner['modules']:
                for team in owner['teams']:
                    found_owners.add(team)
    return found_owners


def get_reviewers(users, found_owners, current_reviewers):
    found_reviewers = []

    for user in users:
        if user['team'] in found_owners:
            found_reviewers.append(user['login'])
            break

    if len(current_reviewers) + len(found_reviewers) < 2:
        for user in users:
            if user['login'] not in found_reviewers or user['team'] == "any":
                found_reviewers.append(user['login'])
                if len(current_reviewers) + len(found_reviewers) == 2:
                    break

    return found_reviewers
