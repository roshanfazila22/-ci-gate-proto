#!/usr/bin/env bash
# Prototype readiness decision. Reads PR state live from the API; prints ready=true|false.
# Inputs via env only: GH_TOKEN, REPO, PR_NUMBER, READY_LABEL
set -euo pipefail
reviews=$(gh api "repos/$REPO/pulls/$PR_NUMBER/reviews" --paginate) || { echo "ready=unknown"; exit 2; }
# latest decisive review per reviewer (COMMENTED is ignored)
states=$(echo "$reviews" | jq -s '[.[][] | select(.state!="COMMENTED" and .state!="PENDING")] | group_by(.user.login) | map(last | .state)')
approved=$(echo "$states" | jq '[.[] | select(.=="APPROVED")] | length')
changes=$(echo "$states" | jq '[.[] | select(.=="CHANGES_REQUESTED")] | length')
labelled=$(gh api "repos/$REPO/issues/$PR_NUMBER/labels" --jq "[.[].name] | index(\"$READY_LABEL\") != null") || { echo "ready=unknown"; exit 2; }
echo "approved=$approved changes_requested=$changes labelled=$labelled"
if { [ "$approved" -ge 1 ] && [ "$changes" -eq 0 ]; } || [ "$labelled" = "true" ]; then echo "ready=true"; else echo "ready=false"; fi
