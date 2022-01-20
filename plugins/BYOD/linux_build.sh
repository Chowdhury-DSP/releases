#!/bin/bash

set -e

# cd to the directory of this script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

# Update submodules
git submodule update --init --recursive -- BYOD

# run build script
cd BYOD

# @TODO: move all this to a build script in the repo
cmake -Bbuild -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release --parallel 4
