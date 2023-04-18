import unittest

from freezegun import freeze_time

import utils


class TestUtils(unittest.TestCase):

    def test_get_latest_tag(self):
        tags = [
            {'ref': 'refs/tags/v2.12.0-beta.3'},
            {'ref': 'refs/tags/v2.12.0-rc.1'},
            {'ref': 'refs/tags/androidauto-v0.22.0'},
            {'ref': 'refs/tags/v2.11.1'},
        ]
        self.assertEqual(utils.get_latest_tag(tags), 'v2.12.0-rc.1')

    def test_get_snapshot_branch_with_latest_alpha_tag(self):
        self.assertEqual(utils.get_snapshot_branch('v2.12.0-alpha.1'), 'main')

    def test_get_snapshot_branch_with_latest_beta_tag(self):
        self.assertEqual(utils.get_snapshot_branch('v2.12.0-beta.1'), 'main')

    def test_get_snapshot_branch_with_latest_rc_tag(self):
        self.assertEqual(utils.get_snapshot_branch('v2.12.0-rc.1'), 'release-v2.12')

    def test_get_snapshot_branch_with_latest_stable_tag(self):
        self.assertEqual(utils.get_snapshot_branch('v2.12.0'), 'main')

    def test_is_rc_or_ga_true_rc(self):
        self.assertEqual(utils.is_rc_or_ga('v1.1.0-rc.100'), True)

    def test_is_rc_or_ga_true_ga(self):
        self.assertEqual(utils.is_rc_or_ga('v1.1.0'), True)

    def test_is_rc_or_ga_false_beta(self):
        self.assertEqual(utils.is_rc_or_ga('v1.1.0-beta.123'), False)

    def test_is_patch_true(self):
        self.assertEqual(utils.is_patch('v1.1.100'), True)

    def test_is_patch_false_ga(self):
        self.assertEqual(utils.is_patch('v1.1.0'), False)

    def test_is_patch_false_rc(self):
        self.assertEqual(utils.is_patch('v1.1.0-rc.1'), False)

    @freeze_time("2023-04-14")
    def test_is_current_week_true(self):
        self.assertEqual(utils.is_current_week('2023-04-12T12:24:15Z'), True)

    @freeze_time("2023-04-14")
    def test_is_current_week_false(self):
        self.assertEqual(utils.is_current_week('2023-03-12T12:24:15Z'), False)

    @freeze_time("2023-04-14")
    def test_is_snapshot_week_alpha_true(self):
        releases = [
            {'name': '1.1.0-alpha.1', 'created_at': '2023-04-12T12:24:15Z'},
            {'name': '1.0.0', 'created_at': '2023-04-02T12:24:15Z'},
        ]
        self.assertEqual(utils.is_snapshot_week(releases), True)

    @freeze_time("2023-04-14")
    def test_is_snapshot_week_beta_true(self):
        releases = [
            {'name': '1.1.0-beta.1', 'created_at': '2023-04-12T12:24:15Z'},
            {'name': '1.0.0', 'created_at': '2023-04-02T12:24:15Z'},
            {'name': '1.0.0-rc.1', 'created_at': '2023-04-01T12:24:15Z'},
        ]
        self.assertEqual(utils.is_snapshot_week(releases), True)

    @freeze_time("2023-04-14")
    def test_is_snapshot_week_patch_true(self):
        releases = [
            {'name': '1.1.1', 'created_at': '2023-04-12T12:24:15Z'},
            {'name': '2.0.0', 'created_at': '2023-04-02T12:24:15Z'},
        ]
        self.assertEqual(utils.is_snapshot_week(releases), True)

    @freeze_time("2023-04-14")
    def test_is_snapshot_week_rc_false(self):
        releases = [
            {'name': '1.1.0-rc.1', 'created_at': '2023-04-12T12:24:15Z'},
            {'name': '1.0.0', 'created_at': '2023-04-02T12:24:15Z'},
        ]
        self.assertEqual(utils.is_snapshot_week(releases), False)

    @freeze_time("2023-04-14")
    def test_is_snapshot_week_ga_false(self):
        releases = [
            {'name': '1.1.0', 'created_at': '2023-04-12T12:24:15Z'},
            {'name': '1.0.0', 'created_at': '2023-04-02T12:24:15Z'},
        ]
        self.assertEqual(utils.is_snapshot_week(releases), False)

    @freeze_time("2023-04-14")
    def test_get_dependency_version_beta(self):
        releases = [
            {'name': '1.2.0-beta.1-private', 'created_at': '2023-04-13T12:24:15Z'},
            {'name': '1.1.0-beta.1', 'created_at': '2023-04-12T12:24:15Z'},
        ]
        self.assertEqual(utils.get_dependency_version(releases), '1.1.0-beta.1')

    @freeze_time("2023-04-14")
    def test_get_dependency_version_rc(self):
        releases = [
            {'name': '1.1.1', 'created_at': '2023-04-13T12:24:15Z'},
            {'name': '1.1.0-rc.1', 'created_at': '2023-04-12T12:24:15Z'},
        ]
        self.assertEqual(utils.get_dependency_version(releases), '1.1.0-rc.1')

    @freeze_time("2023-04-14")
    def test_get_dependency_version_ga(self):
        releases = [
            {'name': '1.2.0', 'created_at': '2023-04-12T12:24:15Z'},
            {'name': '1.1.0', 'created_at': '2023-04-03T12:24:15Z'},
        ]
        self.assertEqual(utils.get_dependency_version(releases), '1.2.0')

    @freeze_time("2023-04-14")
    def test_get_dependency_version_no_release(self):
        releases = [
            {'name': '1.2.0-beta.1-private', 'created_at': '2023-03-13T12:24:15Z'},
            {'name': '1.1.0-beta.1', 'created_at': '2023-03-12T12:24:15Z'},
        ]
        self.assertEqual(utils.get_dependency_version(releases), None)


if __name__ == "__main__":
    unittest.main()
