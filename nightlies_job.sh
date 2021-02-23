#!/bin/bash

echo "Running nightlies job at $(date)"

GITHUB_API_HEADER="Accept: application/vnd.github.v3+json"
GITHUB_API_URI="https://api.github.com"

github_get() {
  local -r api="$1"
  body=$(curl -sSL -H "$GITHUB_API_HEADER" "$GITHUB_API_URI/$api")
  echo "$body"
}

declare -a plugins_to_update=()
update_needed=1
for plugin in plugins/*/
do
    plugin=${plugin%*/}
    plugin=${plugin##*/}
    echo "Checking update status for $plugin"

    metadata="plugins/$plugin/metadata.json"
    repo=$(jq -r '.repo' "$metadata")
    hash=$(jq -r '.hash' "$metadata")

    IFS='/' # set delimiter
    read -ra vals <<< "$repo" # split repo url on '/'
    repo_owner=${vals[-2]}
    repo_name=${vals[-1]}
    IFS=' ' # reset delimiter

    repo_info=$(github_get "repos/$repo_owner/$repo_name")
    default_branch=$(echo "$repo_info" | jq -r '.default_branch')

    last_commit=$(github_get "repos/jatinchowdhury18/KlonCentaur/commits/$default_branch")
    last_commit_hash=$(echo "$last_commit" | jq -r '.sha')
    echo "Latest commit: $last_commit_hash"

    if [[ "$hash" == "$last_commit_hash" ]]; then
        echo "$plugin is up to date!"
        continue
    fi

    echo "$plugin requires nightly update!"
    sed -i "s/$hash/$last_commit_hash/g" "$metadata"
    plugins_to_update+=($plugin)
    update_needed=0
done

if [[ "$update_needed" == "1" ]]; then
    echo "All plugins up to date!"
    exit 0
fi

git_commit_msg="Update Nightlies:"
for plugin in $plugins_to_update
do
    git_commit_msg="$git_commit_msg $plugin"
done

echo "Pushing git commit to trigger update..."
git commit -am "Test commit" # "$git_commit_msg"
git push origin main

echo "FINISHED"
