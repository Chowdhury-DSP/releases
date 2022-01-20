#!/bin/bash

set -e

git submodule update --init --recursive -- BYOD
bash BYOD/scripts/mac_builds.sh
