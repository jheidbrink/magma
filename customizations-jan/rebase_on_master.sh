#!/usr/bin/env bash

# Script to rebase on master, using the other scripts in this folder
# to programatically apply some changes. This should make maintaining
# some local changes easier.

set -euo pipefail

scripts=$(mktemp -d)
cp on_workflow_dispatch.py "${scripts}"/
chmod a+x "${scripts}"/on_workflow_dispatch.py

git fetch upstream
git checkout upstream/master
git switch --force-create tmp_rebase
"${scripts}"/on_workflow_dispatch.py

git add -u
git commit -m "local (auto): Replace workflow triggers by workflow_dispatch"
git rebase tmp_rebase local
git branch --delete tmp_rebase