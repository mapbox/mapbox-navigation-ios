# Auto-assigning reviewers

The auto-assigning reviewers script assign reviewers to your PR when you:

- open PR
- reopen PR
- make PR ready for review

The script will assign 2 reviewers.
If you assign 1 reviewer by yourself, the script will assign 1 more reviewer.
If you assign 2 reviewers by yourself, the script will assign nobody.

## Implementation

The script is powered by Python and located in `scripts/set_reviewers.py`.

The script runs by GitHub actions. The GitHub action config is located in `.github/workflows/set_reviewers.yml`.

### Algorithm

1. Get pull request info
2. Check `draft` field. Exit if it is true
3. Get reviews and reviewers info for this pull request
4. Exit if this pull request has 2 assigned reviewers or 2 finished reviews
5. Get potential reviewers from the teams config `scripts/teams.json`
6. Get information about current reviews for every potential reviewers from opened pull requests
7. Get information about finished reviews for every potential reviewers from closed pull requests for the last working
   week
8. Sort potential reviewers list by current and finished reviews
9. Get information about changed files in the pull request
10. Define affected modules by changed files
11. Define owners of affected modules by the owners config `scripts/owners.json`
12. Choose the first reviewer from the sorted potential reviewers list which is owner of changed modules
13. Choose the second reviewer from the sorted potential reviewers list from any team if no assigned reviewers and no
    finished reviews