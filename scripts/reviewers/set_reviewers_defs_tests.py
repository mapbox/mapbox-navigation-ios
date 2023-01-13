import datetime
import unittest

import responses

from scripts.reviewers.set_reviewers_defs import get_changed_modules, parse_users, get_current_reviews, \
    get_fresh_pulls, sort_users, get_owners_of_changes, get_reviewers, get_done_reviews, get_module


class SetReviewersDefsTest(unittest.TestCase):
    def test_parse_users(self):
        teams = [
            {"name": "team1", "users": ["user1", "user5"]},
            {"name": "team2", "users": ["user2", "user3", "user4"]}
        ]
        author = "user2"
        actual_users = parse_users(teams, author)
        expected_users = [
            {'login': 'user1', 'team': 'team1', 'reviews': 0, 'done_reviews': 0},
            {'login': 'user5', 'team': 'team1', 'reviews': 0, 'done_reviews': 0},
            {'login': 'user3', 'team': 'team2', 'reviews': 0, 'done_reviews': 0},
            {'login': 'user4', 'team': 'team2', 'reviews': 0, 'done_reviews': 0},
        ]
        self.assertEqual(actual_users, expected_users)

    def test_get_current_reviews(self):
        users = [
            {'login': 'user1', 'team': 'team1', 'reviews': 0, 'done_reviews': 0},
            {'login': 'user2', 'team': 'team2', 'reviews': 0, 'done_reviews': 0},
        ]
        pulls = [
            {
                'requested_reviewers': [
                    {'login': 'user2'},
                    {'login': 'user4'},
                ]
            },
            {
                'requested_reviewers': [
                    {'login': 'user1'},
                    {'login': 'user2'}
                ]
            }
        ]
        actual_reviews = get_current_reviews(users, pulls)
        expected_reviews = [
            {'login': 'user1', 'team': 'team1', 'reviews': 1, 'done_reviews': 0},
            {'login': 'user2', 'team': 'team2', 'reviews': 2, 'done_reviews': 0},
        ]
        self.assertEqual(actual_reviews, expected_reviews)

    def test_get_fresh_pulls(self):
        today = datetime.date.fromisoformat('2022-11-30')
        pulls = [
            {'created_at': '2022-11-25T00:00:00Z', 'closed_at': '2022-11-26T00:00:00Z'},
            {'created_at': '2022-10-14T00:00:00Z', 'closed_at': '2022-10-15T00:00:00Z'},
            {'created_at': '2022-11-27T00:00:00Z', 'closed_at': None},
            {'created_at': '2022-10-10T00:00:00Z', 'closed_at': None},
        ]
        actual_fresh_pulls = get_fresh_pulls(pulls, today)
        expected_fresh_pulls = [
            {'created_at': '2022-11-25T00:00:00Z', 'closed_at': '2022-11-26T00:00:00Z'},
            {'created_at': '2022-11-27T00:00:00Z', 'closed_at': None},
        ]
        self.assertEqual(actual_fresh_pulls, expected_fresh_pulls)

    @responses.activate
    def test_get_done_reviews(self):
        prs_url = 'https://api.github.com/repos/mapbox/mapbox-navigation-android/pulls'
        headers = {}
        users = [
            {'login': 'user1', 'done_reviews': 0},
            {'login': 'user2', 'done_reviews': 0}
        ]
        fresh_pulls = [
            {'number': 1},
            {'number': 2},
        ]
        reviews_1 = [
            {'state': 'APPROVED', 'user': {'login': 'user1'}},
            {'state': 'APPROVED', 'user': {'login': 'user5'}},
        ]
        reviews_2 = [
            {'state': 'APPROVED', 'user': {'login': 'user1'}},
            {'state': 'APPROVED', 'user': {'login': 'user2'}},
        ]
        responses.add(responses.GET, prs_url + '/1/reviews', json=reviews_1)
        responses.add(responses.GET, prs_url + '/2/reviews', json=reviews_2)
        expected_reviews = [
            {'login': 'user1', 'done_reviews': 2},
            {'login': 'user2', 'done_reviews': 1}
        ]
        actual_done_reviews = get_done_reviews(prs_url, headers, users, fresh_pulls)
        self.assertEqual(actual_done_reviews, expected_reviews)

    def test_sort_users(self):
        users = [
            {'login': 'user1', 'reviews': 4, 'done_reviews': 1},
            {'login': 'user2', 'reviews': 1, 'done_reviews': 3},
            {'login': 'user3', 'reviews': 2, 'done_reviews': 0},
            {'login': 'user4', 'reviews': 2, 'done_reviews': 1},
            {'login': 'user5', 'reviews': 0, 'done_reviews': 1},
            {'login': 'user6', 'reviews': 0, 'done_reviews': 0},
        ]
        actual_users = sort_users(users)
        expected_users = [
            {'login': 'user6', 'reviews': 0, 'done_reviews': 0},
            {'login': 'user5', 'reviews': 0, 'done_reviews': 1},
            {'login': 'user2', 'reviews': 1, 'done_reviews': 3},
            {'login': 'user3', 'reviews': 2, 'done_reviews': 0},
            {'login': 'user4', 'reviews': 2, 'done_reviews': 1},
            {'login': 'user1', 'reviews': 4, 'done_reviews': 1},
        ]
        self.assertEqual(actual_users, expected_users)

    def test_get_changed_modules(self):
        pr_files = [
            {'filename': 'module1/file1'},
            {'filename': 'module2/file2'},
        ]
        actual_modules = get_changed_modules(pr_files)
        expected_modules = {'module1', 'module2'}
        self.assertEqual(actual_modules, expected_modules)

    def test_get_module(self):
        filename = 'module1/file1'
        actual_module = get_module(filename)
        expected_module = 'module1'
        self.assertEqual(actual_module, expected_module)

    def test_get_module_for_mapbox_core_navigation(self):
        filename = 'Sources/MapboxCoreNavigation/Accounts.swift'
        actual_module = get_module(filename)
        expected_module = 'Sources/MapboxCoreNavigation'
        self.assertEqual(actual_module, expected_module)

    def test_get_module_for_mapbox_navigation(self):
        filename = 'Sources/MapboxNavigation/AVAudioSession.swift'
        actual_module = get_module(filename)
        expected_module = 'Sources/MapboxNavigation'
        self.assertEqual(actual_module, expected_module)

    def test_get_owners(self):
        owners = [
            {'teams': ['team1'], 'modules': ['module1', 'module2']},
            {'teams': ['team2', 'team3'], 'modules': ['module3', 'module4']},
            {'teams': ['team4', 'team5'], 'modules': ['module6']},
        ]
        changed_modules = ['module6', 'module2']
        actual_owners_of_changes = get_owners_of_changes(owners, changed_modules)
        expected_owners_of_changes = {'team4', 'team5', 'team1'}
        self.assertEqual(actual_owners_of_changes, expected_owners_of_changes)

    def test_get_reviewers(self):
        users = [
            {'login': 'user6', 'team': 'team4', 'reviews': 0, 'done_reviews': 0},
            {'login': 'user5', 'team': 'team1', 'reviews': 0, 'done_reviews': 1},
            {'login': 'user2', 'team': 'team3', 'reviews': 1, 'done_reviews': 3},
            {'login': 'user3', 'team': 'team2', 'reviews': 2, 'done_reviews': 0},
            {'login': 'user4', 'team': 'team2', 'reviews': 2, 'done_reviews': 1},
        ]
        owners = ['team3']
        current_reviewers = []
        actual_reviewers = get_reviewers(users, owners, current_reviewers)
        expected_reviewers = ['user2', 'user6']
        self.assertEqual(actual_reviewers, expected_reviewers)

    def test_get_reviewers_without_owners(self):
        users = [
            {'login': 'user6', 'team': 'team4', 'reviews': 0, 'done_reviews': 0},
            {'login': 'user5', 'team': 'team1', 'reviews': 0, 'done_reviews': 1},
            {'login': 'user2', 'team': 'team3', 'reviews': 1, 'done_reviews': 3},
            {'login': 'user3', 'team': 'team2', 'reviews': 2, 'done_reviews': 0},
            {'login': 'user4', 'team': 'team2', 'reviews': 2, 'done_reviews': 1},
        ]
        owners = []
        current_reviewers = []
        actual_reviewers = get_reviewers(users, owners, current_reviewers)
        expected_reviewers = ['user6', 'user5']
        self.assertEqual(actual_reviewers, expected_reviewers)

    def test_get_reviewers_without_owners_in_users(self):
        users = [
            {'login': 'user6', 'team': 'team4', 'reviews': 0, 'done_reviews': 0},
            {'login': 'user5', 'team': 'team1', 'reviews': 0, 'done_reviews': 1},
            {'login': 'user2', 'team': 'team3', 'reviews': 1, 'done_reviews': 3},
            {'login': 'user3', 'team': 'team2', 'reviews': 2, 'done_reviews': 0},
            {'login': 'user4', 'team': 'team2', 'reviews': 2, 'done_reviews': 1},
        ]
        owners = ['team11']
        current_reviewers = []
        actual_reviewers = get_reviewers(users, owners, current_reviewers)
        expected_reviewers = ['user6', 'user5']
        self.assertEqual(actual_reviewers, expected_reviewers)

    def test_get_reviewers_with_current_reviewer(self):
        users = [
            {'login': 'user6', 'team': 'team4', 'reviews': 0, 'done_reviews': 0},
            {'login': 'user5', 'team': 'team1', 'reviews': 0, 'done_reviews': 1},
            {'login': 'user2', 'team': 'team3', 'reviews': 1, 'done_reviews': 3},
            {'login': 'user3', 'team': 'team2', 'reviews': 2, 'done_reviews': 0},
            {'login': 'user4', 'team': 'team2', 'reviews': 2, 'done_reviews': 1},
        ]
        owners = ['team3']
        current_reviewers = [
            {'login': 'user10', 'team': 'team10', 'reviews': 2, 'done_reviews': 1},
        ]
        actual_reviewers = get_reviewers(users, owners, current_reviewers)
        expected_reviewers = ['user2']
        self.assertEqual(actual_reviewers, expected_reviewers)
