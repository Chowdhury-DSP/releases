#!/bin/bash

set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
SDK_PATH="$(pwd)/SDKs"
VST_SDK="D:${SDK_PATH:2}/VST2_SDK"
ASIO_SDK="D:${SDK_PATH:2}/ASIO_SDK"

# clone git repo
name=$(jq -r '.name' "$DIR/metadata.json")
repo=$(jq -r '.repo' "$DIR/metadata.json")
hash=$(jq -r '.hash' "$DIR/metadata.json")
echo "Pulling $name from $repo at commit $hash"

git clone "$repo" "$name"
cd "$name"
git checkout "$hash"
git submodule update --init --recursive

# Clone add-on modules
USERNAME="jatinchowdhury18"
PASSWORD="$OUR_GITHUB_PAT"
add_ons_repo="https://github.com/Chowdhury-DSP/BYOD-add-ons"

add_ons_repo_with_pass="${add_ons_repo:0:8}$USERNAME:$PASSWORD@${add_ons_repo:8}"
git clone $add_ons_repo_with_pass modules/BYOD-add-ons

# set up SDK paths
sed -i -e "s~# juce_set_vst2_sdk_path.*~juce_set_vst2_sdk_path(${VST_SDK})~" CMakeLists.txt

# build Win64
cmake -Bbuild -G"Visual Studio 16 2019" -A x64 -DBYOD_BUILD_ADD_ON_MODULES=ON -DBUILD_RELEASE=ON -DASIOSDK_DIR="${ASIO_SDK}"
cmake --build build --config Release --parallel 4

# build Win32
cmake -Bbuild32 -G"Visual Studio 16 2019" -A Win32 -DBYOD_BUILD_ADD_ON_MODULES=ON -DBUILD_RELEASE=ON -DASIOSDK_DIR="${ASIO_SDK}"
cmake --build build32 --config Release --parallel 4

# copy builds to bin
echo "Copying builds..."
mkdir -p bin/Win64
mkdir -p bin/Win32

cp -R "build/${name}_artefacts/Release/Standalone/${name}.exe" "bin/Win64/${name}.exe"
cp -R "build/${name}_artefacts/Release/VST/${name}.dll" "bin/Win64/${name}.dll"
cp -R "build/${name}_artefacts/Release/VST3/${name}.vst3" "bin/Win64/${name}.vst3"
cp -R "build/${name}_artefacts/Release/CLAP/${name}.clap" "bin/Win64/${name}.clap"
echo y | pscp -pw "$CCRMA_PASS" -r jatin@ccrma-gate.stanford.edu:/user/j/jatin/aax_builds/Win64/${name}.aaxplugin "bin/Win64/${name}.aaxplugin"

cp -R "build32/${name}_artefacts/Release/Standalone/${name}.exe" "bin/Win32/${name}.exe"
cp -R "build32/${name}_artefacts/Release/VST/${name}.dll" "bin/Win32/${name}.dll"
cp -R "build32/${name}_artefacts/Release/VST3/${name}.vst3" "bin/Win32/${name}.vst3"
cp -R "build32/${name}_artefacts/Release/CLAP/${name}.clap" "bin/Win32/${name}.clap"

# extract version for installer
version=$(cut -f 2 -d '=' <<< "$(grep 'CMAKE_PROJECT_VERSION:STATIC' build/CMakeCache.txt)")
echo "Setting app version: $version..."

# create installer
echo "Creating 64-bit installer..."
script_file=Installers/windows/BYOD_Install_Script.iss
sed -i "s/##APPVERSION##/${version}/g" $script_file
iscc $script_file

# create installer (32-bit)
echo "Creating 32-bit installer..."
script_file=Installers/windows/BYOD_Install_Script_32bit.iss
sed -i "s/##APPVERSION##/${version}/g" $script_file
iscc $script_file

# copy installer to products
cp installers/windows/"BYOD-Win-64bit-$version.exe" ../products/
cp installers/windows/"BYOD-Win-32bit-$version.exe" ../products/
