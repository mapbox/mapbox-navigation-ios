import datetime
import json
import os

import requests

from set_reviewers_defs import get_owners_of_changes, get_changed_modules, get_reviewers, sort_users, get_current_reviews, \
    get_fresh_pulls, get_done_reviews, parse_users

pr_number = os.environ['PR_NUMBER']
token = os.environ['GITHUB_TOKEN']

prs_url = "https://api.github.com/repos/mapbox/mapbox-navigation-ios/pulls"
pr_url = prs_url + "/" + pr_number

headers = {"Authorization": "Bearer " + token}
pr = requests.get(pr_url, headers=headers).json()

if pr['draft']:
    print("It is draft pr")
    exit()

author = pr['user']['login']
current_reviewers = list(map(lambda reviewer: reviewer['login'], pr['requested_reviewers']))

# check existing approvals on pr

reviews_url = pr_url + "/reviews"
reviews = requests.get(reviews_url, headers=headers).json()
for review in reviews:
    if review['state'] == 'APPROVED':
        current_reviewers.append(review['user']['login'])

if len(current_reviewers) >= 2:
    print("2 or more reviewers already assigned")
    exit()

# parse users from config

with open('scripts/reviewers/teams.json') as json_file:
    teams = json.load(json_file)
    users = parse_users(teams, author)

# get users reviews

pulls = requests.get(prs_url, headers=headers).json()

users = get_current_reviews(users, pulls)

# get users done reviews

closed_pulls_url = prs_url + "?state=closed&per_page=100"
closed_pulls = requests.get(closed_pulls_url, headers=headers).json()

today = datetime.date.today()
fresh_pulls = get_fresh_pulls(list(closed_pulls + pulls), today)

users = get_done_reviews(prs_url, headers, users, fresh_pulls)

# sort by reviews

users = sort_users(users)

print("Available reviewers")
for user in users:
    print(user)

# get changes

pr_files_url = pr_url + '/files'
pr_files = requests.get(pr_files_url, headers=headers).json()
changed_modules = get_changed_modules(pr_files)

# find owners

with open('scripts/reviewers/owners.json') as json_file:
    owners = json.load(json_file)
    found_owners = get_owners_of_changes(owners, changed_modules)

print("Owners of changes")
print(found_owners)

# find reviewers

found_reviewers = get_reviewers(users, found_owners, current_reviewers)

print("Reviewers to assign")
print(found_reviewers)

# assign reviewers

pr_url = prs_url + '/%s/requested_reviewers'
requests.post(pr_url % pr_number, json={'reviewers': found_reviewers}, headers=headers)
