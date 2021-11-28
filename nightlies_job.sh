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
    default_branch=$(jq -r '.branch' "$metadata")

    IFS='/' # set delimiter
    read -ra vals <<< "$repo" # split repo url on '/'
    repo_owner=${vals[-2]}
    repo_name=${vals[-1]}
    IFS=' ' # reset delimiter

    last_commit=$(github_get "repos/$repo_owner/$repo_name/commits/$default_branch")
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
for plugin in "${plugins_to_update[@]}"
do
    git_commit_msg="$git_commit_msg $plugin"
done

echo "Pushing git commit to trigger update..."
pat=$(cat ~/git_pat)
git commit -am "$git_commit_msg"
git push -u https://jatinchowdhury18:$pat@github.com/Chowdhury-DSP/releases.git main

sleep 120m

password=$(cat ~/ccrma_pass)
ssh_cmd="sshpass -p $password ssh -q -o StrictHostKeyChecking=no jatin@ccrma-gate.stanford.edu"
scp_cmd="sshpass -p $password scp -o StrictHostKeyChecking=no jatin@ccrma-gate.stanford.edu:"
ssh_dir="~/Library/Web/chowdsp/nightly_plugins"
nightly_dir=~/Web/chowdsp/nightly_plugins

for p in "${plugins_to_update[@]}"; do
    update=1
    if $ssh_cmd stat $ssh_dir/$p*-Mac* \> /dev/null 2\>\&1
        then
            echo "Nightly update found for $p Mac"
            rm -f $nightly_dir/$p*-Mac*
            $scp_cmd$ssh_dir/$p*-Mac* $nightly_dir/
            $ssh_cmd "rm $ssh_dir/$p*-Mac*"
            update=0
        else
            echo "No Nightly update found for $p Mac"
    fi

    if $ssh_cmd stat $ssh_dir/$p*-Win* \> /dev/null 2\>\&1
        then
            echo "Nightly update found for $p Win"
            rm -f $nightly_dir/$p*-Win*
            $scp_cmd$ssh_dir/$p*-Win* $nightly_dir/
            $ssh_cmd "rm $ssh_dir/$p*-Win*"
            update=0
        else
            echo "No Nightly update found for $p Win"
    fi

    if $ssh_cmd stat $ssh_dir/$p*-Linux* \> /dev/null 2\>\&1
        then
            echo "Nightly update found for $p Linux"
            rm -f $nightly_dir/$p*-Linux*
            $scp_cmd$ssh_dir/$p*-Linux* $nightly_dir/
            $ssh_cmd "rm $ssh_dir/$p*-Linux*"
            update=0
        else
            echo "No Nightly update found for $p Linux"
    fi

    if [[ "$update" -eq 0 ]]; then
        echo "Latest build created on $(date)" > $nightly_dir/${p}_Info.txt
        win_exe=$(cd $nightly_dir && ls $p*-Win*)
        mac_dmg=$(cd $nightly_dir && ls $p*-Mac*)
        lin_deb=$(cd $nightly_dir && ls $p*-Linux*)

        sed -i -e "s/${p}.*Win.*.exe/$win_exe/g" ~/Web/chowdsp/nightly.js
        sed -i -e "s/${p}.*Mac.*.dmg/$mac_dmg/g" ~/Web/chowdsp/nightly.js
        sed -i -e "s/${p}.*Linux.*.deb/$lin_deb/g" ~/Web/chowdsp/nightly.js
    fi
done

echo "FINISHED"
