#!/bin/bash

set -e

DIR=$(dirname "${BASH_SOURCE[0]}")
SDK_PATH="$(pwd)/SDKs"
VST_SDK="D:${SDK_PATH:2}/VST2_SDK"

# clone git repo
name=$(jq -r '.name' "$DIR/metadata.json")
repo=$(jq -r '.repo' "$DIR/metadata.json")
hash=$(jq -r '.hash' "$DIR/metadata.json")
echo "Pulling $name from $repo at commit $hash"

git clone "$repo" "$name"
cd "$name"
git checkout "$hash"
git submodule update --init --recursive

# set up SDK paths
cd Plugin
sed -i -e "s~# juce_set_vst2_sdk_path.*~juce_set_vst2_sdk_path(${VST_SDK})~" CMakeLists.txt

# build Win64
cmake -Bbuild -G"Visual Studio 16 2019" -A x64
cmake --build build --config Release --parallel 4

# build Win32
cmake -Bbuild32 -G"Visual Studio 16 2019" -A Win32
cmake --build build32 --config Release --parallel 4

# copy builds to bin
echo "Copying builds..."
mkdir -p bin/Win64
mkdir -p bin/Win32

plugin=CHOWTapeModel
cp -R "build/${plugin}_artefacts/Release/Standalone/${plugin}.exe" "bin/Win64/${plugin}.exe"
cp -R "build/${plugin}_artefacts/Release/VST/${plugin}.dll" "bin/Win64/${plugin}.dll"
cp -R "build/${plugin}_artefacts/Release/VST3/${plugin}.vst3" "bin/Win64/${plugin}.vst3"

cp -R "build32/${plugin}_artefacts/Release/Standalone/${plugin}.exe" "bin/Win32/${plugin}.exe"
cp -R "build32/${plugin}_artefacts/Release/VST/${plugin}.dll" "bin/Win32/${plugin}.dll"
cp -R "build32/${plugin}_artefacts/Release/VST3/${plugin}.vst3" "bin/Win32/${plugin}.vst3"

# create installer
echo "Creating installer..."
script_file=Installers/windows/ChowTapeModel_Install_Script.iss

version=$(cut -f 2 -d '=' <<< "$(grep 'CMAKE_PROJECT_VERSION:STATIC' build/CMakeCache.txt)")
echo "Setting app version: $version..."
sed -i "s/##APPVERSION##/${version}/g" $script_file

# build installer
echo "Building..."
iscc $script_file

# copy installer to products
cp Installers/windows/"ChowTapeModel-Win-$version.exe" ../../products/
