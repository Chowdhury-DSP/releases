#!/bin/bash

set -e

# cd to the directory of this script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

git submodule update --init --recursive -- BYOD
bash BYOD/scripts/mac_builds.sh
