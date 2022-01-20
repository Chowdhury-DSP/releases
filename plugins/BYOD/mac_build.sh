#!/bin/bash

set -e

# cd to the directory of this script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Update submodules
git submodule update --init --recursive -- BYOD

# run build script
cd BYOD
bash scripts/mac_builds.sh
